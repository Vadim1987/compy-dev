# S18 — option-E execution record (input lifecycle un-forking)

Executed per `../prompts/S18-optionE-execution.md`, with two owner corrections mid-flight (see
below). A Sonnet worker did units 2-3 under the *original* spec; the orchestrator stopped it, applied
the owner's corrected formulation, and finished units 3 (flag mechanism) + 4 (rename) + the test fixes
by hand. Nothing committed yet — presented to owner for review first.

## Owner corrections to the spec (both adopted)
1. **Editor block** — NOT a combined guard `(is_enter and not shift) or (escape and not ctrl)` in
   `_normal_mode_keys` (that made the editor re-encode UIC's own trigger logic — a cross-layer leak).
   Instead: a plain `block_input()` at the end of each handled branch of `submit()` and `load()`. A
   key the editor does not handle (Alt+Enter, etc.) falls through to UIC's uniform `submit_flow`,
   which is a **harmless no-op** because the editor sets no callbacks (verified: no callback wiring in
   `editorController.lua`; `deliver()` with `result=nil` + no `on_text_entered` does nothing) — the
   same no-op console already relies on.
2. **`allow_modify`** — a **constructor parameter** (`new(model, result, disable_selection,
   allow_modify)`), not a fluent `:allow_line_modify()` method (the variant is known at construction,
   like `disable_selection`). Editor sets it: `UserInputController(M.input, nil, true, true):always_shown()`.

## Changes landed (working tree, uncommitted)
- `src/controller/userInputController.lua`:
  - Deleted the `if love.state.app_state == 'editor' … else … end` fork in `keypressed` (and its
    obsolete `REVIEW:` at former :724). One uniform sequence now: `removers → vertical → horizontal →
    newline → (modify if allow_modify) → copypaste → selection`, then uniform lifecycle
    `is_enter&¬shift → submit_flow`, `escape&¬ctrl → cancel_flow`.
  - `allow_modify` added as 4th constructor param (default nil), gated at the `modify()` call.
  - Renamed `_submit_default`→`submit_flow`, `_cancel_default`→`cancel_flow` (defs :456/:473, call
    sites :744/:746, doc-comment at :202; "default"→"flow" in the method doc prose). `submit`/`cancel`
    were unavailable (`:cancel()` exists at :200).
- `src/controller/editorController.lua`:
  - `input` constructed with `allow_modify=true` (4th arg).
  - `block_input()` added to the end of `submit()`'s two Enter branches and `load()`'s two Escape
    branches (4 calls). No combined guard.
- `tests/input/input_lifecycle_unfork_spec.lua` (new, from the worker; orchestrator fixed test #4 +
  a stale comment):
  - Test #4 (Alt+Enter) rewritten: the original set `on_text_entered` and asserted not-fired, which
    only held because the input was *empty* (submit_flow short-circuits at its empty-guard). Under the
    owner's formulation Alt+Enter reaches submit_flow; it is a no-op only because the editor sets no
    callbacks. Rewrote to load a non-empty selection and assert the input is left untouched — the
    honest guard.

## Verification
- `busted tests` → **838 / 0 / 0 / 4** (827 baseline + 11 new; 4 pre-existing pendings unchanged).
- grep: zero surviving `_submit_default` / `_cancel_default` / `allow_line_modify`; zero `app_state`
  in `userInputController.lua`; `submit_flow`/`cancel_flow` present at the expected sites.
- The new spec covers the breaking assertion (uniform lifecycle regardless of `app_state`) + the
  preservation set: editor Escape reloads and is not wiped; editor plain/Ctrl Enter don't double-fire
  through UIC; Alt+Enter no-op; Shift+Enter-nonempty still line-feeds through; console evaluates once
  + Escape clears; overlay flows fire; `modify` flag gates Ctrl+D both ways.
- LSP diagnostics not run (this repo's lua-lsp is returning phantom results this session); suite +
  grep are the verification of record.

## Not done here (deliberately)
- No commit yet (owner review gate).
- Docs retrofit (unit 5) — the discovered paradigms (search/reorg own their keys, never delegate to
  UIC; per-frame-draw render workaround; uniform lifecycle; modify flag) into the persistent corpus.
  Orchestrator does this next.
