# session48 — execute ARC-01: give the project widget a run lifetime

Read `agents/sessions.md` and `agents/validation.md` first, then **`../session47/report.md`**. The
report is the handover; session47's track is long and you do not need it.

Then read **`doc/development/wip/77-new-input-api/ROADMAP.md`**, specifically the **`ARC-01`**
section — it is new, it leads the sequence, and it already carries the evidence you would otherwise
spend a session gathering: the seam answer, the ordering constraint, the measured blast radius, four
folded review findings, and three named risks.

Baseline: **970 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Where this came from, one level up

Session47 fixed two defects of one shape — a store on an application-lifetime object holding
something a *project* put there, surviving that project's stop. Both fixes are hand-maintained wipes
at teardown, and a third store was missed for months because that wipe list is maintained by hand.

The owner named the class — *a hidden persistent mutable store which pretends to be ephemeral* — and
then found the fact that dissolves it: **Decision 3's NFR forbids allocating per input SESSION**, for
the stated reason of repeated prompting, and **a project run is a far coarser boundary that was never
examined**. At the PR base the widget was built **per activation**, so the singleton is this feature's
own invention and per-run allocation is *strictly less* than what shipped before.

`ARC-01` is that fix: construct the project widget when a project runs, destroy it when the project
stops, and delete the teardown machinery that existed to fake the lifetime.

## Your task — execute ARC-01, starting with the step that is not code

**This is an execution session.** The workflow's default successor for a cognitive-heavy session is a
revalidation (`agents/rules/revalidation.md`); the owner directed execution instead — as they did for
session47 — so the revalidation instinct is folded into the first step rather than discarded.

### Start at `ARC-01-01`, and do not write code in it

Two questions decide the shape, and both are **verification, not implementation**:

1. **The nil audit.** `love.state.user_input_controller` becomes nil between runs. Four consumers
   resolve it dynamically; three *appear* to guard. **Confirm each one, do not assume** — session47
   read them, it did not test them.
2. **Pen-and-paper projects** (sapper-like: they live in `project_open` and never stay in
   `'running'`). The row argues from code that they are safe because they still pass *through*
   `run_project`. **Confirm with a real project, not by reading.**

> **The trap, stated precisely:** bind destruction to `stop_project_run`, **never** to the
> `running → project_open` transition. That transition is exactly where `release_keyboard_route`
> once fired, and pointer had to be exempted *because pen-and-paper projects broke* — the asymmetry
> Decision 11 was amended to delete. Rebuilding that mistake with a widget instead of a route is the
> live hazard.

**If `ARC-01-01` opens a can of worms, pivot before writing code.** The owner said so explicitly.
That is what the step is for, and reporting "this is worse than we thought" is a success condition,
not a failure.

### Then work the remaining steps in order

`ARC-01-02` (dynamic resolution) **must land before** `ARC-01-03` (construction moves) —
`get_compy_input` runs at application boot, before any project exists, so the current by-reference
capture would index nil. Then `ARC-01-04` deletes the machinery, and `ARC-01-05` takes the fixture
seam and the spec fallout.

**Two obligations the row records and you must honour:**

- **Decision 3 gets a written amendment**, not a silent reinterpretation. Its literal text says
  *"created once at load"* and names four instances. The base check makes this easy to write — say
  that the singleton was introduced by this branch and that per-run is still less allocation than
  the base did — but it must be *written*, because it is the part a stakeholder sees.
- **Owner ruling 2026-07-20 softens** (`compy.input.callbacks` *is* the widget's table → *resolves
  to* the current widget's table). Observably identical to a project; still the owner's ruling to
  re-make. **Raise it, do not assume it.**

Only 4 of the 101 test touchpoints call `run_project`, so most existing churn will **not** exercise
the new lifetime. Expect to write tests *for* it, not merely to repair tests around it.

## Standing cautions, carried forward

- **Verify before acting.** Session44's lesson, 45's, 46's, and 47's twice over — a cold reviewer's
  claim and a handover's claim are both strong hints, not facts. Two verdicts this phase were
  overturned by checking, and **both times the check that settled it was against the PR base
  `3256aac`.** Make that check yourself; nobody else reliably does.
- **The `lua-lsp` MCP is DOWN** — its language server died 2026-08-25 and the bridge was killed;
  Claude Code did not respawn it. **Ask the owner to `/mcp` reconnect before starting.** ARC-01 is
  the highest-value LSP row left in the roadmap: it is a "who caches this object" question across
  101 test touchpoints, and grep alone will make you slower and less certain.
- **Fable is retired** — unavailable on this account. Hard judgment calls are Opus, and are better
  done in the main session than spawned. Always pass `model` explicitly.
- `| head` on a counting grep lies. Never `git add <directory>` — name files. The marker gate covers
  `src/` and `tests/` only, never `doc/`.
- The example repos are separate repositories with their own remotes and PRs. Commit as the work
  demands; **never push** any of them, or the platform.
