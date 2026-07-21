# Sonnet worker prompt — S18 option-E execution (input lifecycle un-forking)

You are a Sonnet worker under the session18 orchestrator, feat #77, LÖVE2D project at `/repo` (cwd
`/repo`). This is a **tests-first, behaviour-preserving refactor**. The design is fully settled by
the orchestrator + owner; your job is precise execution, unit by unit, suite green after each.

## Standing rules (you do NOT inherit repo CLAUDE.md — restated)
- **(a) `lua-lsp` MCP server** (defs/refs/diagnostics/rename over a real AST of `/repo`) is available
  — the correctness tool for Lua. BUT this repo's LSP is currently returning **phantom out-of-range
  references** (verified this session); treat LSP as a hint and **use grep as ground truth** for
  completeness/rename sweeps. After any `.lua` edit, `sleep 1` before querying LSP diagnostics.
- **(b) You are the executor** — follow this spec exactly; do not redesign. If something in the spec
  contradicts the code, STOP and report back rather than improvising.
- **(c) Write a deliverable to disk**: `doc/development/wip/77-new-input-api/validation/outcomes/S18-optionE-execution.md`
  — record each unit, the diff summary, suite counts, and anything surprising. Chat reply is secondary.
- Conventions: `agents/rules.md` (line ≤64, fn body ≤14, params ≤4, nesting ≤4). Commit style is the
  orchestrator's job — **do NOT commit**; leave the tree dirty for review after each unit and tell the
  orchestrator the suite is green.

## Baseline
`busted tests` must read **827 / 0 / 0 / 4** before you start. If not, STOP and report.

## Background (what and why — read once)
`UserInputController:keypressed` (`src/controller/userInputController.lua:533`) currently forks on a
GLOBAL read `if love.state.app_state == 'editor'` (`:725`). We are DELETING that fork entirely so UIC
runs one uniform path, and pushing the two real differences to their honest homes:
- **Lifecycle keys (Enter/Escape → submit/cancel):** currently only the `else` branch runs them. We
  make UIC run them **uniformly**, and make the **editor consume Enter/Escape upstream** so UIC never
  sees them in editor mode (the editor already owns those keys — it just wasn't blocking them).
- **`modify()` (Ctrl+D duplicate-line, editor-only):** currently only the editor branch calls it. We
  keep it in the widget but gate it on a **per-instance flag** the editor sets (like `disable_selection`).
- **Key-order swap (vert/horiz):** coincidental (disjoint key sets, one acts per press) — unify freely.

Verified facts you can rely on (do not re-derive, but do not contradict either):
- Only two callers of a UIC's `keypressed`: `consoleController.lua:1269`, `editorController.lua:804`.
  Search (`SearchController:keypressed`) and editor reorg mode never reach UIC:keypressed — **do not
  touch them**.
- Editor Escape today: `load()` (`editorController.lua:716`) → `load_selection()` reloads the selected
  block into the input; it must NOT be followed by a widget cancel (which would wipe it).
- Console calls `input:keypressed(k)` then its own `evaluate_input` on plain Enter; it sets no
  submit/cancel callbacks, so uniform UIC `submit_flow` is a **no-op** for it (preserved).

## UNIT 1 — tests first (must be RED where noted, then stay green through units 2-4)
Add a new spec file `tests/input/input_lifecycle_unfork_spec.lua` (mock_love; mirror the style of
`tests/input/input_redesign_ac_spec.lua`). Cover:

1. **[RED→GREEN] Uniform lifecycle, no app_state gate.** Construct a bare UIC (not the overlay), set
   `love.state.app_state = 'editor'`, show it, put text in, send plain Enter → `submit_flow` fires
   (assert via an `on_text_entered` spy or `after_submit` spy). This FAILS today (editor branch skips
   it) and PASSES after unit 3. Same for Escape → `cancel_flow` clears. This is the breaking test.
2. **[GREEN throughout] Editor Escape preserves the load.** Drive `EditorController` normal-mode
   Escape after a `load_selection`, assert the input text is the loaded block and is **not** wiped
   (i.e. no `model:cancel()` ran). (Use the editor test harness in `tests/editor/` as reference.)
3. **[GREEN] Editor plain Enter / Ctrl+Enter** submit via the editor's own `_handle_submit`, and do
   **not** double-fire through UIC (`on_text_entered` on the editor's input is not invoked). 
4. **[GREEN] Editor Alt+Enter does nothing** (regression guard for the exact-trigger block — this is
   the case a naive block would miss).
5. **[GREEN] Shift+Enter on a NON-empty editor input** still reaches UIC and inserts a line-feed
   (multiline), i.e. it is NOT blocked.
6. **[GREEN] Console** plain Enter → `evaluate_input` runs exactly once, text not wiped; Escape clears
   the console line. Overlay: submit/cancel flows fire (already covered by AC spec — a light re-assert
   is fine, don't duplicate heavily).
7. **[GREEN] `modify` flag.** A UIC with the modify flag ON: Ctrl+D duplicates the current line. A UIC
   with it OFF: Ctrl+D does nothing.

Run `busted tests`. Expect the suite to rise by your new test count with **exactly one failing** (the
1 breaking assertion). Report the count. If more than the intended one fails, STOP and report.

## UNIT 2 — editor consumes the lifecycle keys (`editorController.lua`, `_normal_mode_keys`)
After the existing handler calls (`submit(); load(); delete(); navigate(); clear()`, ~`:797-801`) and
BEFORE `if passthrough then input:keypressed(k) end` (`:803`), add a single precise block matching
UIC's uniform triggers exactly:

```lua
-- The editor owns Enter/Escape (submit()/load() above); stop them reaching
-- the widget's uniform submit/cancel flow, which would double-act or wipe the
-- just-loaded block. Shift+Enter (non-empty line-feed) is deliberately NOT
-- blocked — it falls through to the widget. Matches UserInputController's own
-- submit_flow/cancel_flow guards.
if (Key.is_enter(k) and not Key.shift())
    or (k == 'escape' and not Key.ctrl()) then
  block_input()
end
```

Do NOT modify `submit()`/`load()` internals. Suite: the breaking test from unit 1 is still red (UIC
not changed yet); everything else green. Report.

## UNIT 3 — UIC uniform (`userInputController.lua:keypressed`, delete the app_state fork)
Replace the whole `if love.state.app_state == 'editor' then … else … end` block (`:725-756`) with a
single uniform sequence (drop the coincidental order difference; keep the `else`-branch order):

```lua
removers()
vertical()
horizontal()
newline()
if self.allow_modify then modify() end
copypaste()
selection()

-- The widget's own submit/cancel flow (Decision 6 revised): plain Enter
-- submits, plain Escape cancels — ordinary widget behaviour, out through
-- callbacks. Shift+Enter is a newline (newline() above); Ctrl+Escape is not a
-- cancel. Editor/console callers that must not run these consume the key
-- upstream (editor) or set no callbacks (console no-op).
if Key.is_enter(k) and not Key.shift() then
  self:submit_flow(keys_pressed)
elseif k == 'escape' and not Key.ctrl() then
  self:cancel_flow(keys_pressed)
end
```

Remove the now-obsolete REVIEW at `:724` (the fork it flagged is gone; note its resolution in your
deliverable). Add the `allow_modify` per-instance flag: default `false` in the constructor `new`
(`:24-41`), plus a chained setter mirroring `always_shown()`:

```lua
function UserInputController:allow_line_modify()
  self.allow_modify = true
  return self
end
```

(Name provisional — a future combo-table would supersede it; add a one-line REVIEW pointing at that
endgame.) Then in `editorController.lua:12`, the main input becomes
`UserInputController(M.input, nil, true):always_shown():allow_line_modify()`. The search instance
(`:16`) and console/overlay do NOT get it.

`sleep 1`, LSP-diagnose the two files, run `busted tests`: the unit-1 breaking test now PASSES; whole
suite green (827 + your new tests, 0 failures). If anything else moved, STOP and report.

## UNIT 4 — rename `_submit_default`/`_cancel_default` → `submit_flow`/`cancel_flow`
Grep both names across `src/` + `tests/` (LSP as secondary). Definitions at
`userInputController.lua:450`/`:467`; call sites now in the uniform block (unit 3). Rename defs, calls,
and every doc-comment mention. `submit`/`cancel` are NOT available (`UserInputController:cancel()`
already exists at `:200`) — use `submit_flow`/`cancel_flow` exactly. Grep must show zero surviving
`_submit_default`/`_cancel_default`. Suite green. Report.

## Final
Report in the deliverable: per-unit suite counts, final `busted tests` count, grep proof the old names
are gone and `love.state.app_state` no longer appears in `userInputController.lua`, and LSP-diagnostics
status on the two touched src files. Do NOT commit. Do NOT touch `decisions/input.md` or other docs
(the orchestrator handles the doc retrofit separately). Do NOT start anything beyond these 4 units.
