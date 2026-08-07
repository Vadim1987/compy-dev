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

**Follow-up (owner, 2026-08-07): "paint had a hope that singleclick would be
counted separately for btn1 and btn2, and it never materialized."** Checked, and
the code says something sharper than a hope: `useCanvas(x, y, btn)` is called
from **both** paths, and `btn` means a different thing in each — a real mouse
button from the drag path, and on the click path a literal paint writes itself.
So the function is button-aware and half its callers cannot supply a button.

**Not a receiver misreading a sent value** (owner's question, 2026-08-07). The
framework passes the click hooks `(x, y)` and nothing else, at the PR base and
now: `function compy.singleclick(x, y) point(x, y, 1) end` — the `1` and the `2`
are written in paint's own handler bodies. Nothing hands paint a count that it
mistakes for a button, so there is no defect of that shape. What is left is the
latent trap, where the two meanings agree only by luck (`2` reads as "secondary"
either way). Recorded as technical
debt: `doc/development/technical_debt/input.md`, "paint's `useCanvas(btn)` means
a mouse button on one path and a click count on the other (pre-existing)". The
entry states why binding the button is not the fix — the derived clicks name no
button by Decision 27 — and that the honest fix, if ever taken, is to split the
parameter rather than to add a gesture.

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

---

## SM3a — maze: nav symbols glitch when launched from another project. **UNRESOLVED from code.**

Sub-agent analysis (`../outcomes/S28-smoke-analysis.md`): the owner's font
hypothesis could not be confirmed or refuted by reading. It checked
font-recreation-at-require, `evacuate_required`'s `package.loaded` scoping, and
the path between `stop_project_run` and the next project's run, and found **no
explicit font or graphics-state reset between two consecutive project runs** —
which is consistent with the hypothesis without demonstrating it.

What it did surface is a **precedent for the failure shape**: `S24-W7-A1`, a
previously fixed "works for the first project, breaks for every later one" bug
caused by a flag that stop did not reset. That makes the owner's instinct a
known class of defect here rather than a guess, but it is not evidence about
this instance.

**Left open deliberately.** Fixing state-reset code on a hypothesis nobody has
reproduced is how the `wrap_handler` mistake happened (session26): machinery
removed or added because it *looked* like the cause. The next step is a runtime
check — print the font identity at the start of two consecutive maze runs — and
that needs the app, which this pass excluded by instruction.

## SM3b — maze: Ctrl dims the screen. **EXPLAINED. Not a platform issue, no change.**

The dim overlay is **Shift-gated by design** in maze's own `macro.lua`
(`SHIFT_KEYS`, `handle_key`, `release_shift`). No path in the example ties it to
Ctrl, and nothing in the platform dims anything. The likeliest reading is a
Shift/Ctrl mix-up while smoke-testing — the note itself quotes `"Ctrl"` with
uncertain punctuation.

**Pinned rather than fixed**, per the owner's instruction not to leave it
unexplained: the behaviour is intended, the modifier in the report is probably
misremembered, and confirming it costs one keypress at the next smoke pass.

## SM4 — keyboard: Ctrl+Alt+arrow does nothing. **NOT A PLATFORM DEFECT. Coverage added.**

Traced end to end through `key.lua` (registration, canonicalisation) and the
dispatcher: an exact two-modifier combo works. Now pinned by a suite row —
`tests/input/input_events_spec.lua`, "a two-modifier combo fires on the real
chord" (`73dae3f5`), which registers `'ctrl+alt+up'` and presses the real chord
through the production gate.

The row is a **pin, not a proof of a fix** — it passed before it was written.
Its reach was mutation-checked: reordering `mod_order` in `key.lua`, so that
registration canonicalises modifiers in a different order than dispatch emits
them, fails it. That asymmetry is precisely what SM4 suspected, and nothing in
the suite could previously catch it: the neighbouring rows bind one modifier
plus a trigger, or two modifiers plus the class marker.

**What remains as the likely cause, and it is not ours:** the window manager.
Ctrl+Alt+Arrow is a desktop-level shortcut on most Linux environments
(workspace switching), so the chord may never reach the app at all. Cheap to
confirm at the next smoke pass — try the same binding on a chord the WM does not
claim.

## SM5 — keyboard: subgame 4 accepts no glyph. **EXAMPLE DEFECT. FIXED** (`3a9d48c`, nested repo).

`inputStale` dropped a `textinput` glyph whose producing key was **held**. On
desktop LÖVE the keypress arrives before the glyph, so a key is *always* held at
its own first `textinput` — every fresh target was discarded as a repeat. Shift
kept working because the key-cap renderer reads the held set live at draw time,
a different mechanism, which is exactly the clue in the owner's report.

The file's own header asserted the opposite ordering as if it were the only one
("the IDE delivers textinput BEFORE the matching keypress"), and built the gate
on it. The platform documents that there is **no ordering guarantee** between
the two channels (`internals/user_input.md`, "Data flow"), so the held set
answers the environment rather than the question.

**Fix:** a glyph is *claimed* — one per press, claim released at keyup. "Has
this key's glyph been judged since its last release" reads the same in both
orders. The post-keyup grace window is unchanged. The stale header reasoning was
rewritten with it, since that reasoning is what produced the bug.

**Not covered by any test:** the keyboard project is a nested repo with no
suite. Reasoned from the code and from the platform's ordering rule; wants a
smoke pass on the device.
