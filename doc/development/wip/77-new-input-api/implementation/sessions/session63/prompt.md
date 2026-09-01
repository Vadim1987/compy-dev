# session63 — back to the roadmap: the defect brace

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session62/report.md`](../session62/report.md).

Baseline: **1032 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover — session62 was a side-track, and it is closed

Session62 spent itself on an architecture discussion the project owner opened: the relationship
between the console's environment and a running program. It produced **no roadmap execution, no
production code and no test changes**, and its entire output is a **side-draft** under
`validation/`, banner-marked in every file as outside `#77`'s delivery. It is expected to become its
own ticket **after** the release. Read the report for what it concluded; you do not need the draft
itself unless the owner reopens the topic.

**Why this prompt is not a revalidation.** A cognitive-heavy session ordinarily hands over a
revalidation task (`agents/sessions.md` §5). The owner directed otherwise: the successor continues
normal roadmap work. There is nothing inside `#77`'s scope to revalidate — the side-draft changed
nothing the feature ships — and the roadmap has been paused for a day.

**Four things from it that do touch this feature**, and only these:

- **`#77` needs no rework to ship.** The environment question sits below the input feature's
  boundary, which is route plus lifecycle state, not environment identity.
- **The collision line moved**: it is now *documentation-only, plus two pre-release surface
  decisions*. Neither `compy.input.hooks` nor `compy.before_exit` exists at the PR base
  (`3256aac`), so settling either is choosing an API before it is public, not deprecating one.
  **These are owner calls and none has been made** — do not act on them unprompted. If the PR
  description or `CHG-01` forces the question, raise it rather than deciding it.
- **Two persistent-corpus corrections were identified and deliberately not made** — `internals/console.md`
  states the opposite of the code about `base_env` (not write-protected; the reset/restart rationale
  inverted), and `_set_base_env` is a second site of the already-filed `table.protect` no-op entry in
  `technical_debt/general.md`. Both are proposals awaiting the owner, recorded in
  `validation/reviews/env-lifecycle-inquiry-assessment.md`.
- **`conventions/code.md` already states "File = console equivalence"** — relevant only if a
  documentation row cites it.

## Your task — resume the sequence

**`{ BUG-02 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01`**

The live roadmap is `doc/development/wip/77-new-input-api/ROADMAP.md` — read it for *what next*,
`validation/plan.md` for *why*, and `agents/rules/roadmap.md` for how it is shaped if you need to
change it.

**`BUG-02-01` is the first unstarted row and it is a weighing, not a fix.** `set_text`'s list branch
does not split embedded newlines while the string branch now does. The row's own text carries the
arguments on both sides and the constraint that rides with it: **if the weighing goes to *fix*, the
sprint finishes before `CHG-01`.** The weighing is the owner's call — gather what it needs, present
it, wait. Do not reach for the fix because it is small; `UserInputModel:set_text` is the content path
every activation runs through, and `BUG-01-09` has just rewritten it.

After that the brace interleaves; order within it by blast radius, not severity. Two hard
constraints stand: **`DEC-01` and `CHG-01` finish before any slice is cut**, and **`CHG-01` gates
`ACC-02`**.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- Stage explicit paths. `git add -A` in `/repo` commits the nested example repos as gitlinks.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before citing it.
- **`FIX-02-09` must run LATE** and its scope includes comments in `src`, `tests` and the examples.
- Re-derive any sizing a row states before working it: two were found stale a day after they were
  written.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.
