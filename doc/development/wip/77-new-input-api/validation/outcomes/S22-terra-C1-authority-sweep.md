# S22 Terra C1 authority/provenance sweep — outcome

## Method

Cold evidence-only audit on 2026-07-30. I inspected the persistent corpus,
tracked example sources, current controller implementation, acceptance tests,
and commits `2e0d93f`, `09eb143`, and `3e93e8e`. No product or persistent
documentation was edited. The frozen design input was not used.

The shipping contract is confirmed: project `show` accepts `highlighter`,
`validator`, and `on_text_entered`; submissions are line arrays; the exported
helpers are `LuaHighlighter`, `LuaSyntaxValidator`, and `LineValidators`; and
unsupported show keys, including `eval`, `result`, and `after_submit`, warn
and are ignored.

## Findings, highest severity first

### P0 — Turtle example is broken by the line-array migration

`src/examples/turtle/main.lua:12-17` defines `eval(input)` and indexes
`actions[input]`; its `on_text_entered = eval` at line 51 now receives a
`string[]`, so a submitted command no longer selects an action.
`doc/development/internals/examples/turtle.md:34` likewise promises a string.

**Minimal correction:** consume `lines[1]` in Turtle, add a real-path example
regression if that convention is available, and update the Turtle narrative.

### P1 — Two canonical internals claims retain the removed `result` parameter

`decisions/input.md:282-283` and `internals/user_input.md:318` both state
`UserInputController(model, result, disable_selection, allow_modify)`. The
actual constructor after `2e0d93f` is
`UserInputController(model, disable_selection, allow_modify)`.

**Minimal correction:** remove `result,` in both locations.

### P1 — One decision example contradicts the line-array contract

`decisions/input.md:630` passes `function(text) greet(text) end` to
`on_text_entered`, immediately before prose that says submissions are line
arrays.

**Minimal correction:** use an explicitly line-aware callback, for example
`function(lines) greet(string.unlines(lines)) end`.

### P1 — Decision 17's status is stale

`decisions/input.md:565-584` says targeted D4 execution is pending and tells
the reader to review fixture markers. Commit `8dbe702` completed that bounded
review.

**Minimal correction:** mark Decision 17 implemented and summarize the
completed bounded fixture correction instead of a future imperative.

### P1 — The test-suite guide describes obsolete state

`doc/development/tests.md:17` exposes removed `F.running_project` and says
reset manually tears down handler/widget fields, though the fixture now stops
the real route. Its contract-suite inventory is stale; its count is
`856 / 0 / 0 / 3` rather than current `862 / 0 / 0 / 3`; and its `#m8`
summary says `after_submit` re-shows instead of clearing the continuing draft.

**Minimal correction:** update the fixture paragraph, inventory/count, and
continuous-session wording before review navigation is generated.

### P2 — Retired silent-show-key debt remains open

`technical_debt/input.md:174-190` still lists silent unknown `show{}` keys as
an open decision, contradicted by implemented Decision 15 and `09eb143`.

**Minimal correction:** remove that obsolete open-debt entry.

### P2 — Inspect authority is described inconsistently

`internals/user_input.md:181` calls inspect unratified characterized status
quo, while canonical Decision 12 prescribes its route/environment shape.

**Minimal correction:** make the internals description implementation facts
under Decision 12; leave only future console/editor migration open.

## Authority and TF2 verdict

Decision 15 is implemented; Decision 16 explicitly defers implementation;
Decision 17 needs only its status updated. R2's retired `eval`/`result` path
and separated line-array policies are canonical in the guide and changelog.

**Not yet stand-alone for stakeholder TF2.** The public guide is coherent, but
the Turtle example is demonstrably broken and the P1 drift makes the persistent
corpus internally inconsistent. Apply the listed minimal corrections, then
continue with the already-planned review-navigation batch. No new ruling or
design reconsideration is indicated.
