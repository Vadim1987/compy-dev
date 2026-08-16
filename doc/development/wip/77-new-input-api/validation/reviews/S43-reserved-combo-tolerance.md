# P-20-04 — the gate's tolerant reservation: what is true, and three options

Raised by the owner (2026-08-16) on the P-20-02 finding: *"maze cannot get back
to menu, it will get the framework exit if keys are released in a specific
order — that sounds very fragile and needs a solution if true."*

## What is true, precisely

**It is true, with two corrections to the framing.**

1. **It is not the framework *exit*.** In dev mode with a project running,
   `love.quit` returns truthy and the OS quit is aborted; what happens is
   `CC:stop_project_run()` — the project is torn down **back to the console**
   (`src/controller/controller.lua:653-684`). In `play` mode (a packaged
   build) the same path calls `CC:quit_project()` and sets `shutdown`, so there
   it *is* an exit. The severity therefore depends on how the thing is shipped.
2. **It is not order-*fragile* so much as order-*conditional*.** The gate fires
   on the `escape` **release** while `Key.ctrl()` still reads true. Release
   Escape first, or everything together: it fires. Lift Ctrl before Escape: it
   does not. So the ordinary release hits it and a deliberate one escapes it —
   which is worse than a plain rule, because the same gesture behaves two ways.

**And it is pre-existing, not something this feature introduced.** The release
gate has exactly this shape at the PR base (`git show
3256aac:src/controller/controller.lua`, the `handlers.keyreleased` block). Maze
has always run under the gateway; before the P-17 migration it tested modifiers
by hand and the same teardown followed. What the migration changed is
**visibility**: the project now *states* an intent the platform overrides.

## The general shape — the asymmetry

The gate tests only the modifiers it names and ignores the rest, while a
project's combo is its modifier set **exactly** (Decision 21). The platform
reserves tolerantly; projects must register exactly. Consequences beyond maze,
all verified:

- `quickswitch` excludes Alt but not Shift, so Ctrl+Shift+T quickswitches.
- `f10` names no modifier at all — already noted in the P15 suite.
- **Ctrl+Alt+Shift+R fires `restart` *and* `reset`** in one event: one gate
  tests ctrl+alt, the other ctrl+shift, and both run
  (`../notes/S43-ctrl-alt-shift-r-probe.lua`).

Recorded in `doc/development/technical_debt/input.md`, "The gate reserves
tolerantly; projects must register exactly".

## Three options

**A — tighten the reservation (surgical).** Make the release gate exact:
`Key.ctrl() and not Key.alt() and not Key.shift() and k == 'escape'`. This is
the idiom `quickswitch` already uses for Alt, so it introduces no new concept.
Ctrl+Shift+Escape then belongs to the project, and maze's four registrations all
work as upstream did.
*For:* the platform's reservation would mean what the combo vocabulary says it
means, which is the feature's own model applied to the one layer that ignores
it; the plain Ctrl+Escape escape hatch is untouched, so nothing about recovery
changes; one condition, one live test (converting the `ctrl+escape` pending
outline in `tests/input/input_global_shortcuts_spec.lua:95`), no test currently
asserts the tolerant behaviour.
*Against:* it is a framework behaviour change in a PR whose mandate is the input
API, so it owes a justification line; and it fixes one gate while `quickswitch`,
`f10` and the R pair keep the same looseness — a half-swept floor.

**B — the privileged combo table.** Give the gate its own reserved-combo table
so reservations are exact by construction and listable.
*Against:* Decision 30 point 3 names this layer and **explicitly declines to
commit to building it**, and it is much larger than the problem. Out of scope
for this PR; the right home is a later feature.

**C — change nothing; drop the two registrations.** Maze and draw keep
`shift+escape` and `alt+shift+escape`, drop the two ctrl variants with a comment
saying the platform owns that chord, and the debt entry carries the asymmetry.
*For:* zero platform risk, and the PR stays inside its mandate.
*Against:* the P-17 step existed to restore upstream's gesture family, and this
concedes half of it permanently; the trap stays armed for the next project.

## Recommendation

**A, with C as the fallback** — and the debt entry either way, which is already
written.

The reason to prefer A is not the maze gesture, it is the frame: *does this make
the system more predictable, or merely more elaborate?* A reservation that
claims chords it does not name is the least predictable thing in the input path,
and it is the one layer this feature left untouched while making every other
layer exact. One condition and one test is a small price for the model being
true everywhere. If that reads as scope creep at PR time, C is honest and cheap
— but then the maze registrations should go, because a binding the platform
overrides is worse than no binding: it looks like the code being right.

Not mine to pick. **A and C are both owner rulings**; B is a recommendation
against.
