# session59 — revalidate `FEAT-02` at the delivery level

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session58/report.md`](../session58/report.md).

Baseline: **1023 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover

Session58 executed **`FEAT-02`**, the last surface change of this feature. `oneshot` became
**`auto_hide`** and stopped being a `show`-only key: project-owned, settable at `show` **and**
`configure`, `false` to unset, **persistent until replaced** — a mode, not a one-off. The ledger
gate ran first (Decisions 36 and 35 amended, not reinterpreted), the rename was token-only, the
category move landed with four breaking tests, and the docs, CHANGELOG and debt register followed.
`turtle` was converted to the key and given its own smoke checklist. One collision was ruled by the
owner mid-sprint; the report explains it.

With `FEAT-02` done, the sequence stands at
**`{ BUG-01 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01`**.

## Your task — revalidation, and it is deliberately NOT a code review

`agents/rules/revalidation.md` applies (session58 exercised judgment). **A cold code review of that
work already ran and its findings were acted on** —
[`../../../validation/outcomes/FEAT-02-peer-review.md`](../../../validation/outcomes/FEAT-02-peer-review.md),
Opus, verdict *approve with comments*, six findings, fixes in `23e4a05a`. It walked the
implementation, the tests, the diff and the changed documents, mutating the source to check the
cases discriminate. **Do not repeat it.** Re-deriving whether `configure_core` is correct is
spending the session's best hours on a question already answered by someone cold.

**Work one level up: was the work delivered as planned, is anything forgotten, is anything
drifting?** (Owner's scoping, 2026-08-30.) In particular:

- **Delivery against the ledger.** `ROADMAP.md`'s `FEAT-02` has five rows and each carries
  conditions in its notes cell — the persistence must be *ruled* and *said*, `-01` must amend two
  things, `-03` "must not smuggle in a clearing step". Walk each row against what actually landed.
  A row marked done whose condition was quietly dropped is exactly what this pass is for.
- **Nothing forgotten in the blast radius.** The sprint claimed a specific reach: three production
  sites, eight tests, four documents, two ledgers, one example. Is that the real reach? The
  persistent corpus is the part that outlives `wip/77` — `doc/input_api.md`,
  `internals/user_input.md`, `decisions/input.md`, `technical_debt/{input,general}.md`,
  `tests.md`, `smoke_checklists.md`, `CHANGELOG.md` — and a key list missing the key, or a sentence
  describing the retired shape, is the failure mode this feature keeps repeating. Two instances were
  already found this way (the seven documents at `FEAT-01`, the guide's worked example at
  `FEAT-02`); assume a third.
- **Drift.** Vocabulary the sprint minted and began reasoning on; ids cited from places that no
  longer resolve, or that resolve to something that changed meaning (`agents/rules/roadmap.md` §5);
  new rows filed out of order without the note that licenses it; the suite count's arithmetic
  reconciling with what the commits say.
- **Coherence of the ledgers with each other.** Decisions 35/36, `T-ONESHOT-SCOPE` (retired),
  `T-ONESHOT` (retired, marked as history), `T-MERMAID-MODEL` (new), `FIX-02-24`, `ACC-02-08`,
  `FIX-02-09` and `FIX-02-22` were all touched. They should tell one story.
- **Scope discipline.** Did the sprint stay inside `FEAT-02`, or did it widen? Three things were
  added beyond the five rows — a debt entry with its roadmap row, an example conversion, a smoke
  checklist. Two were owner-directed and one (`T-MERMAID-MODEL`) was found in passing. Judge whether
  each belongs, and say so either way.

`agents/rules/revalidation.md`'s checklist is the instrument; the checks above are where to point
it. **Report findings, propose corrections, and do not start the next sprint** — errors here
propagate into the defect sprints, which are next and are sized against this tree.

## Facts worth having up front (verified 2026-08-30 — re-verify before relying on them)

- The suite is **1023**: two cases replaced in place (the ones pinning the retired category) and two
  added (the `configure` disarm that keeps the draft, and `false` as the unset).
- **Two follow-up shapes are deliberately unpinned** — a plain forced follow-up and one that passes
  `auto_hide = true` are both closed by the submit in progress. A generation-token fix would change
  both; Decision 36's Amendment records it as considered and declined, and the test comment says so.
  Do not file the absence of those tests as a gap without reading that reasoning.
- **`oneshot` still legitimately appears in-tree** — the profiler (`Prof.start_oneshot`,
  `love.PROFILE.oneshot`, a pending reserved-combo case), vendored metalua, and two comments in
  `userInputView.lua` / `userInputModel.lua` that say *"oneshot is gone"* about the **base's model
  argument**. Renaming those would make them false.
- One loose finding stays parked and is **not** yours unless the owner says so: `ROADMAP.md`'s
  status table cites `FIX-02-01` for a `doc/`-markers concern that has no row anywhere.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push**.
- A behaviour change is **never** documented in the commit message alone.
- Say **widget**, not "field" or "overlay".
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.
