# P-23-02 — the editor's Ctrl+S meanings leave the gate (outcome)

Commit: `cb6b867e1a82c278debd343dd16eaaa83dfc5a09`.
Branch `feature/77-newapi-analysis-s20260615`. Not pushed.
Option A from `../reviews/S43-P-23-00b-liveness-and-boundary.md`
(Amendment). `ProjectInputController` untouched, as instructed.

## What moved

`src/controller/editorController.lua`, `EditorController:keypressed`,
beside the existing `ctrl+m`/`ctrl+f` block:

```lua
    if k == "s" and not Key.alt() then
      if Key.shift() then
        self.console:finish_edit()
      else
        self.console:close_buffer()
      end
    end
```

Semantics preserved exactly: Alt excluded, Shift selects finish-edit
vs close-buffer. Reached through `self.console` — the file's own
idiom already in use one method up (`EditorController:close_buffer`
calls `self.console:finish_edit()` at line 126) — not through a new
path, and not through `self:close_buffer()` directly (that would
bypass `ConsoleController:close_buffer`/`finish_edit`, which is what
the existing P-21-06 tests stub; confirmed by driving the design off
those stubs, see below).

`lua-lsp` references confirmed the wiring before and after: `finish_edit`
is called from `controller.lua`'s `quickswitch` (unrelated,
untouched) and now from `editorController.lua:826`; `close_buffer` is
called only from `consoleController.lua:1395`
(`ConsoleController:close_buffer` → `self.editor:close_buffer()`) and
now `editorController.lua:828`. No other caller of either exists.
`diagnostics` on both changed files: clean (editorController.lua no
findings; controller.lua's findings are all pre-existing, on
unrelated lines).

## What the gate now claims

`src/controller/controller.lua`, the `k == "s"` block in
`project_state_change()` reduces to a single, exact reservation:

```lua
        if only_mods(true, false, false) and k == "s" then
          if love.state.app_state == 'running' then
            CC:stop_project_run()
          end
        end
```

The editor `elseif` branch and the "Shift stays meaningful here"
comment are gone — the comment no longer applies to this scope. The
gate now claims exactly one thing on this key: stop a running project
on an exact, unmodified Ctrl+S. `app_state == 'project_open'`
(pen-and-paper projects) was already outside this block before the
change and stays outside it now — nothing about that path was
touched, consistent with P-23-00b finding 1.

## The one behaviour change, and its failing output before

New test, `tests/input/input_global_shortcuts_spec.lua`, added and
run against the pre-change tree first:

```lua
it('ctrl+shift+s no longer stops the run; the'
  .. ' project binding runs instead', function()
    local project_ran = false
    local input = F.activate_project()
    input.shortcuts.keypressed['ctrl+shift+s'] =
        function() project_ran = true; return true end
    love.state.app_state = 'running'
    F.session.press('lctrl')
    F.session.press('lshift')
    F.session.press('s')
    assert.equal('running', love.state.app_state)
    assert.is_true(project_ran)
  end)
```

Failing output (pre-change tree, `busted
tests/input/input_global_shortcuts_spec.lua`):

```
Failure -> tests/input/input_global_shortcuts_spec.lua @ 212
input surface: inbound events — global platform shortcuts #input a
reservation matches its modifier set exactly ctrl+shift+s no longer
stops the run; the project binding runs instead
tests/input/input_global_shortcuts_spec.lua:222: Expected objects to
be equal.
Passed in:
(string) 'project_open'
Expected:
(string) 'running'
```

i.e. pre-change, Ctrl+Shift+S still stopped the run (loose modifier
match). Post-change it passes: the reservation is exact, so Shift
takes the combo out of it and the project's own `ctrl+shift+s`
binding fires instead — the same shape as the existing
`ctrl+alt+s`/`ctrl+shift+t`/`ctrl+shift+q` "no longer" siblings in
that file.

## P-21-06 cases

Both untouched, byte-identical, and green after the move:

- `ctrl+shift+s finishes the edit in the editor branch` (line 216) —
  stubs `F.cc.finish_edit`, drives real keystrokes through the full
  gateway → `love.keypressed` → `ConsoleController:keypressed` →
  `EditorController:keypressed` chain (confirmed via
  `tests/helpers/input_session.lua` and `F.setup`'s
  `Controller.set_default_handlers`), asserts the stub ran.
- `ctrl+s closes the buffer in the editor branch` (line 232) — same
  shape, stubs `F.cc.close_buffer`.

Both assert *behaviour* (which `CC` method fired), not layering, so
routing the call through `self.console:X()` from
`EditorController:keypressed` instead of from the gate satisfies them
unchanged, as the prompt anticipated. No uncovered surface was left
by the move: these two cases already exercised both editor branches
through the real dispatch chain, and continue to.

## Suite arithmetic

Before: 967 successes / 0 failures / 0 errors / 10 pending.
After: **968 / 0 / 0 / 10** (967 + the one new case). Pending count
unchanged; none of the seven `pending(...)` outlines were touched.

## Hard limits

Line length, params, nesting: all clear. The new
`EditorController:keypressed` block reaches nesting depth 3 (`if
Key.ctrl()` → `if k == "s"` → `if Key.shift()`), within the ≤4 limit;
longest touched line is 58 chars (the gate's `only_mods` line).

**Body length is pre-existing debt that grew, not a new breach.**
`EditorController:keypressed`'s body was already 28 lines (814–841)
before this change — already past the 14-line limit and the 16-line
tolerance. The addition is 7 lines, taking it to 35 (814–848). Per
the prompt's instruction this was not restructured and no
surrounding code was "improved"; flagging it here rather than fixing
it, per `agents/development.md`'s tech-debt-reporting convention.
The function was already over the limit for reasons unrelated to
this step (the `reorder`/`search`/`normal` mode dispatch and the
`love.debug`/`f5` block account for most of it); this step's own
addition is the minimum needed to carry the two moved meanings and
does not itself invent any complexity.

## Commit

`cb6b867e1a82c278debd343dd16eaaa83dfc5a09` — `refactor(input): move
editor's Ctrl+S meanings out of the gate`. Files: `src/controller/
controller.lua`, `src/controller/editorController.lua`,
`tests/input/input_global_shortcuts_spec.lua`. Nothing else staged;
no `doc/` changes committed; not pushed.

---

## P-23-02b — extracting our seven lines back out (addendum)

Prompt: `../prompts/S43-P-23-02b-extract-save-keys.md`, commissioned
immediately after the above, because the 7 lines this step added
took `EditorController:keypressed`'s pre-existing 28-line body (a
debt this step correctly did not restructure) to 35. Per the standing
rule — a function *we* bloated is ours to split, one that arrived
long stays long — those seven lines came back out into a new private
method, `EditorController:_save_keys(k)`, following the file's
existing `_reorg_mode_keys`/`_search_mode_keys`/`_normal_mode_keys`
idiom (`--- @private`/`--- @param k string` annotations, method
placed right after `_normal_mode_keys`, its nearest sibling).

**Line counts.**
- `EditorController:_save_keys` (new): body is the 7 lines moved
  verbatim (the exact block `cb6b867e` added), well under the
  14-line limit.
- `EditorController:keypressed`: 35 → **29** lines (the pre-existing
  28 plus the one new call), exactly matching the gate.

**The `Key.ctrl()` decision.** Left at the call site, not moved into
the new method. `keypressed`'s outer `if Key.ctrl() then ... end`
already gates `ctrl+m` and `ctrl+f` the same way; `_save_keys(k)` is
called as a third statement inside that same block, parallel in
shape to its two siblings:

```lua
  if Key.ctrl() then
    if k == "m" then
      self:set_mode('reorder')
    end
    if k == "f" then
      self:set_mode('search')
    end
    self:_save_keys(k)
  end
```

This keeps the call site reading correctly beside `ctrl+m`/`ctrl+f`
(the prompt's explicit requirement) and matches how the *other*
extracted methods are dispatched too: `_reorg_mode_keys`,
`_search_mode_keys`, and `_normal_mode_keys` are each called from a
mode-dispatch `if`/`elseif` in `keypressed` rather than re-testing
their own gating condition internally. `_save_keys` itself keeps the
`k == "s" and not Key.alt()` test as its first line (unchanged from
the moved block) — that is not the `Key.ctrl()` gate itself, just the
key/modifier check that was already inside the seven lines.

**Semantics.** Byte-identical to the moved block: Ctrl+S closes the
buffer, Ctrl+Shift+S finishes the edit, Alt excluded, both still
reached only when `Key.ctrl()` holds. No branch changed.

**Diagnostics.** `lua-lsp` `diagnostics` on
`src/controller/editorController.lua` after the edit: clean, no
findings.

**Suite.** `busted tests` → **968 successes / 0 failures / 0 errors /
10 pending** — unchanged from before this step, as required. No new
test added: the existing P-21-06 cases (`ctrl+shift+s finishes the
edit`, `ctrl+s closes the buffer`) already exercise both branches
through the real `love.keypressed` → `ConsoleController:keypressed`
→ `EditorController:keypressed` chain and are agnostic to which
private method inside `EditorController` does the dispatching, so
they cover the refactor without modification.

**Commit.** `5e6ad8c2` —
`refactor(input): extract editor's save-keys block`. Staged by path:
only `src/controller/editorController.lua`. Nothing else touched;
this outcome file was appended but not committed, per the prompt.
