# S28 — smoke findings SM1–SM5, diagnosed from code

The owner's instruction (2026-08-07): analyse the smoke findings **from the
description and the code**, without running the app; fix in good faith; they
will smoke-test the results separately. Source of the findings:
`../reviews/S26-TF2-smoketest-results.txt`, triaged in
`../reviews/S27-triage-and-plan.md` §W11.

SM3a, SM3b, SM4 and SM5 are in the nested example repos and were analysed by a
sub-agent — see `../outcomes/S28-smoke-analysis.md`.

---

## SM1 — paint: right-clicking a colour does nothing. **NOT A DEFECT. No change.**

**What the code does.** `src/examples/paint/main.lua` binds two channels and no
others: `hooks.singleclick` → `point(x, y, 1)` and `hooks.doubleclick` →
`point(x, y, 2)`. The derived clicks are synthesised by the framework's click
timer, which counts **left-button releases only**
(`src/controller/controller.lua`, `handlers.mousereleased`: `if btn == 1 then
click_count = click_count + 1`). A right-click therefore produces no derived
click at all, and paint binds no `mousepressed`, so nothing runs. That is the
whole of the observed behaviour.

**The `btn` parameter is not a mouse button.** `setColor(x, y, btn)` and
`useCanvas(x, y, btn)` take `1` for the foreground colour and `2` for the
background. Paint feeds those from *single* versus *double* click. It is an
action selector that happens to be spelled like a button number.

**Checked against the PR base** (`git show 3256aac:src/examples/paint/main.lua`):
the base bound `compy.singleclick` / `compy.doubleclick` with the identical
`btn` 1/2 convention. **Right-click did nothing there either** — the migration
to `compy.input.hooks.*` is faithful and this feature never regressed.

**Owner ruling, 2026-08-07: leave it.** The suggestion to bind
`shortcuts.mousepressed['mouse2']` (which Decision 27 now makes expressible)
came from the smoke test, not from the example's intent. Secondary-button
availability is not uniform across environments, so mapping the secondary action
onto a double-click may well be a deliberate UX choice. Changing it would be
this session inventing a requirement.

**Nuance worth keeping.** The right button *is* used, for dragging:
`love.mousemoved` polls `love.mouse.isDown(btn)` for `btn = 1, 2` and paints
with the background colour while the right button is held — at the base as well
as now. So right-**drag** paints and right-**click** does nothing, which is
likely what made the smoke test read as a bug.

## SM2 — sapper: the inactive console prompt at the bottom. **CAUSE FOUND. Ruled to keep.**

**What the code does.** Sapper defines no `love.draw`; it renders the minefield
as console terminal output. The gateway's draw wrapper only replaces the console
draw path when a project supplies its own `love.draw`
(`controller.lua`, `set_love_update`), so for sapper the console's path stays
installed, and `ConsoleView:draw` paints the console's input strip whenever the
screen mode is not `editor` (`src/view/consoleView.lua`, `drawConsole`). The
strip is inert during the run: the input route belongs to the project.

This also explains the owner's other observation — *"output not seen under the
game field"* — the same terminal surface is carrying both.

**Owner ruling, 2026-08-07: do not change the console's drawing logic for the
cosmetic benefit of one pen-and-paper example.** Recorded instead as
**disputable technical debt**: `doc/development/technical_debt/input.md`, "The
console's prompt is drawn under a project that never takes over `love.draw`".
Revisit only if a project owner asks.

**Why it would not have been provable anyway.** The input fixture stubs the
`view.view` module wholesale, so `ConsoleView:draw` is exercised by no row in
the suite. Any fix here is verifiable only by a human smoke test — which is a
second, independent reason not to spend a change on it now.
