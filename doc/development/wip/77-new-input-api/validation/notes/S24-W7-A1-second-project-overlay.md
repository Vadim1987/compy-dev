# W7 / A1 — "no overlay when a project starts after Ctrl+Q from another project"

**Date:** 2026-07-31 · **Session:** 24 · **Verdict:** genuine regression,
**reproduced headlessly, fixed** (`d6b3db4` — `fix(input): lower the widget's
shown flag on project stop`).

Reports covered: tixy (3), turtle (8), valid (9 — "runs inconsistently — first
project after boot", and the black-instead-of-blue input bar in the same
report, which is the console's own input line showing because no overlay was
raised).

## What is wrong

`ConsoleController:stop_project_run` took the overlay down by clearing the
**published handle** and nothing else:

```lua
love.state.user_input = nil
```

The widget's own `shown` flag (`UserInputController.shown`, the flag
`is_shown()` reads and `show()` guards on) was never lowered. After any project
stop the widget therefore believed it was still active, while the framework
believed no overlay existed — the two halves of "the overlay is up" had drifted
apart.

The next project's `compy.input.show{}` then met the already-active guard
(`userInputController.lua:299-306`, Decision 3's warn-don't-swallow rule),
logged `overlay already active (pass force=true to override)`, and no-opped.
Nothing was drawn, and the widget still held the **previous** project's text.

## Why it looked intermittent

The flag starts down at boot, so the **first** project of a session always
works and every later one fails — exactly report (9)'s wording. Any stop path
arms it, because they all route through `stop_project_run`: Ctrl+Q
(`quit_project`), Ctrl+S, Ctrl+T into the editor, Ctrl+Esc (`love.quit`), and
`restart`.

## Why the suite was green

Two independent reasons, both worth keeping in mind for the rest of W7:

1. The nearest teardown row — `input_route_lifecycle_spec.lua`, "re-seeds the
   default callbacks for the next project" — starts its first project **without
   an overlay**, so the flag is never raised and the row cannot see the fault.
   The sibling row "silently hides a shown widget" *does* show one, but asserts
   only `love.state.user_input`, i.e. exactly the half that was correct.
2. `F.reset()` forced `widget.shown = false` on every test, under a comment
   claiming it was "fixture-owned state that production neither creates nor
   observes". It was production state that production failed to reset — the
   fixture was compensating for the bug and hiding it suite-wide.

## Evidence

- Unit-level (in the shared fixture, no stubs): show → `stop_project_run` →
  activate → show now yields a visible overlay carrying the **second**
  project's text. Red before the fix, green after.
- End-to-end, through the real lifecycle: a scratch probe stubbed only the
  project *service* (`P.current` / `P:run`, so no filesystem is involved) and
  drove `run_project` → `quit_project` → `run_project` with two real chunks
  calling `compy.input.show{}`. Before: run 1 `user_input=true`, run 2
  `user_input=false`, widget text `one`. After: run 2 `user_input=true`, widget
  text `two`.

## Fix

`hide_overlay()` in `consoleController.lua`, called from `stop_project_run` in
place of the direct assignment: it takes the overlay down **through the
widget** (`widget:hide()`), so the flag and the handle come down together.
`hide()` fires no cancel chain (Decision 6), so teardown stays silent as
Decision 11 requires. The fallback assignment is kept for the case where no
widget is provisioned (never true in production — `main.lua` provisions it
before the console).

## Follow-ups

- The class of bug — a widget's internal flag and the framework's published
  state maintained by two different writers — is worth one look during the W9
  sitting; the fix removes today's only known divergence but not the
  possibility of another.
- `technical_debt/input.md`, "`F.reset()` test helper exceeds the 14-line
  function-body limit" describes a version of the helper that no longer exists
  (18 lines, native-slot restores). Corrected separately.
