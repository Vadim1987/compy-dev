# S40 P16 cold review

Reviewed `d77be355` and `b33f9521` independently and read-only.

## Verdict

No runtime or code-style defect was found in either change. The dispatch
and Ctrl+Escape claims are supported by the code. Three documentation/plan
findings remain and should be reconciled before P16 is treated as fully
documented.

## Findings

### S2 — turtle's persistent internals page still says it quits on Ctrl+Escape

`doc/development/internals/examples/turtle.md:19` says the captured path
could instead use a `ctrl+escape` release shortcut. Line 52 says
`love.keyreleased` quits on Ctrl+Escape. `b33f9521` removed that block from
`src/examples/turtle/main.lua`; its remaining release handler only opens
the prompt for `i` and may consume that key. The framework owns the quit in
`src/controller/controller.lua:883-891`.

Update the page to retain the captured-handler explanation while removing
the deleted turtle behaviour and shortcut suggestion.

### S2 — P16's operative detail still says turtle is pending and unchanged

The authoritative table row at
`validation/reviews/S27-triage-and-plan.md:605` correctly marks P16 DONE
and records both outcomes. But the same plan labels section 15.2 as
OPERATIVE, then at lines 1929-1931 says turtle remains and has "no change".
The older plan summary at lines 2369-2370 likewise presents the deletion as
an unresolved ruling. This conflicts with `b33f9521` and makes the plan's
own operative detail disagree with its row.

Amend the P16 detail (and the still-live summary if it is intended as a
current state) to record the accepted deletion, while preserving that turtle
remains the captured-`love.*` example for its other callbacks.

### S3 — paint's persistent documentation retains old handler spellings

`d77be355` correctly changed the source to
`compy.input.hooks.mousemoved` and `.keypressed`. Three persistent-doc
claims do not match it:

- `doc/development/internals/examples/paint.md:28` calls the handler
  `hooks.mousemoved`, but paint defines no `hooks` alias.
- `doc/development/internals/examples/index.md:23` still lists
  `love.mousemoved` and `love.keypressed`.
- `doc/development/technical_debt/input.md:1426` still calls the current
  drag handler `love.mousemoved`.

Use the explicit `compy.input.hooks.*` spelling in each. The state caveat
itself remains correct: `src/examples/paint/main.lua:364-375` still polls
`love.mouse.isDown(btn)` while handling a movement event, and no keyboard
held-state mechanism has replaced that mouse query.

## Verified implementation facts

- The explicit paint assignments preserve the old captured-callback result.
  On activation, `ProjectInputController:activate` seeds only a nil hook
  (`src/controller/projectInputController.lua:65-70,166-169`). Before the
  change, the captured `love.mousemoved`/`love.keypressed` functions seeded
  those empty slots. After it, the explicit functions already occupy the
  same slots, so seeding leaves them intact. Dispatch calls that hook after
  a shortcut and before the widget, consuming only on a truthy return
  (`:135-145`), in both cases.
- Paint's existing `singleclick` and `doubleclick` hooks also still mark it
  pointer-live (`src/controller/controller.lua:252-270`), so moving the raw
  movement callback did not alter the `project_open` liveness condition.
- Turtle's deleted handler did nothing beyond the framework's release-side
  `Ctrl+Escape` quit. The global handler calls `love.event.quit()` and then
  forwards to the active route without consuming the event
  (`src/controller/controller.lua:883-891`). Removing turtle's duplicate
  call therefore leaves framework ownership and the captured callbacks
  intact.
- The changed Lua lines add no new function-body, parameter, nesting, or
  line-length breach. Existing wider lines are outside these two diffs.

## Validation and method

- Grep was used as the completeness backstop for source, plan, and
  persistent-document references.
- No callable Lua MCP-LSP tool was exposed in this review environment, so
  AST queries were unavailable.
- Focused check passed:
  `busted tests/input/project_open_liveness_spec.lua
  tests/input/input_global_shortcuts_spec.lua` ->
  **7 successes / 0 failures / 0 errors / 7 pending**. The seven pending
  global-shortcut outlines are the sanctioned cases.

No S0/S1 runtime findings were identified.
