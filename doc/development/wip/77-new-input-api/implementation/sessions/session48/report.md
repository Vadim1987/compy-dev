# session48 report — the widget got a lifetime, and the class went with it

Booted to execute `ARC-01`. **Six of its seven steps are done**; the seventh is a fresh question
handed to a cold session. **11 commits, suite green at every one (970 → 979), nothing pushed.**

## What landed

**The lifetime itself.** The project's input widget is constructed when a run starts and destroyed
when it stops. Between runs `love.state.user_input_controller` is nil. A store a project leaves on
its widget cannot reach the next project, because the object it lived on is gone — the defect class
session47 was patching is now structurally impossible rather than defended against.

Order mattered and was verified, not assumed: `compy.input` had to stop **capturing**
`callbacks`/`pending` before construction could move (`e684458b`), because `get_compy_input` runs at
boot and would have indexed nil. The proof that the constraint was real, and then that it was gone,
was the same probe failing in opposite directions.

**The ledger caught up first** (`e28a20f6`, owner-ratified verbatim). Decision 3 substantively
changes and took Decision 11's `AMENDED IN PART` shape. **Decision 7 does not change** and took the
lighter *"amended in place"* note — what it forbids is a *project* replacing a sub-table, and a
project cannot observe a resolution that only moves between runs. Filing the first amendment is what
surfaced the second; nobody had noticed Decision 7 was in scope.

**The payoff** (`55f9edd4`): `reset_widget_outputs`, `reset_callbacks` and `clear_pending` deleted.

**Two defects found on the way, both fixed:**

- **The highlighter would still have leaked.** A test that should have passed did not, and it was
  right: `apply_config` writes the highlighter onto the **evaluator**, and `InputEvalText` is a
  module-level singleton shared by every widget built from it. Per-run construction alone would have
  left the leak intact while every other test looked green. The widget now owns its evaluator.
- **`close_project` kept the widget** (`e13ef346`). It sets `app_state = 'ready'` and returns
  without calling `stop_project_run`, so a closed project's widget outlived it — reachable from a
  running project's env and from the console during `inspect`. Fixed narrowly, widget only, at the
  owner's direction; the rest of that exit path is now a debt entry with a decision owed.

## What was verified rather than believed

`ARC-01-01` was mandated as verification, and both questions came back clean: **every consumer
survives a nil widget** (each guard mutation-tested), and **sapper was run in the real app** —
through `run_project`, playable at `project_open`, stopped once from there. Details:
[`validation/notes/ARC-01-01-verification.md`](../../../validation/notes/ARC-01-01-verification.md).

**The near-miss worth carrying forward:** mutating the dispatch guard produced a GREEN run, which
reads as "the guard is idle" and is the opposite of the truth — `with_canvas_and_errors` xpcalls the
walk, so the raise was swallowed and printed. **On that path, suite-green is not evidence.** Any
future nil-safety assertion there must observe the error channel.

A suspected sibling defect was checked and found to be a **phantom**: `compy.input`'s own
`shortcuts`/`hooks` are still application-lifetime, but their wipe walks the dispatcher's own
channel list and cannot drift. Recorded as a deliberate boundary, because a reviewer will ask.

## The cold review

**Approve** ([`validation/outcomes/ARC-01-cold-review-s48.md`](../../../validation/outcomes/ARC-01-cold-review-s48.md)).
It walked every seam, mutation-tested both headline claims (4 and 17 tests fail when reverted), and
independently found the dead teardown function — the payoff step reached from the code alone by
someone who never read the plan. It **missed `close_project`**: it verified everything it looked at,
and the gap was in what it chose to look at. It also caught a miscount in a commit message of mine
(12 citations, not 13 — my grep matched `Decision 30`/`32`/`33`).

## Non-obvious points for the successor

- **`ARC-01-06`/`-07` were swapped** so ids match execution order (owner). The fixture seam ran as
  `-06`; the reconfiguration-policy question is `-07`. Session48's own `prompt.md` uses the ORIGINAL
  numbers — the crosswalk in the row maps both hops.
- **Most of `-06` landed inside `-04`.** Suite-green-at-every-commit does not let a fixture move
  separately from the behaviour it fixtures; sizing them as separate steps was optimistic.
- **`F.widget` is no longer a field** — it resolves to the current widget, so every touchpoint
  follows the lifetime. `F.run_project` drives a real run with a stubbed loader.
- Two debt entries filed, both base-checked and neither ours: a raise at `project_open` is swallowed
  whole, and `close_project` bypasses the run's exit path. One editor defect filed in `general.md`
  (`get_active_buffer` returns nil, three call sites index it unguarded) — found by the harmony
  suite, confirmed pre-existing by running it against the pre-change tree.
