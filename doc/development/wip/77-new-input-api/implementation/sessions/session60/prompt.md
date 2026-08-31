# session60 — awaiting instructions

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session59/report.md`](../session59/report.md).

Baseline: **1023 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover

Session59 **revalidated `FEAT-02` at the delivery level** — not a code review; the cold peer review
had already run and its findings were fixed. All five rows were delivered with their conditions
intact, the suite arithmetic reconciles, and nothing in the delivery was reopened. Six findings,
all in the *surroundings* rather than the work, were applied one commit each. The one that matters
downstream: **`FIX-02-20`'s site inventory was under-sizing its own row** — it declared "draft"
hits in `input_widget_control_spec.lua` fixture noise, and `FEAT-02` had since put "draft" into a
test **description** there. Corrected and re-dated.

**One convention was ruled and it applies from now on.** *A slug is added when debt is planned for
fixing* — it is the commitment, not an id for citability, so the choice is binary: fix before
release or not. Under it, F4 was promoted from BACKLOG to ACTIVE as **`T-KEYSET-SPLIT`** with
**`FIX-02-25`**, scoped to *pin the agreement with a test*, not *unify the lists*. Full reasoning
in the report §4 and in
[`../../../validation/reviews/FEAT-02-delivery-revalidation.md`](../../../validation/reviews/FEAT-02-delivery-revalidation.md) §8.

Sequence unchanged, with `FIX-02` now at 25 rows:
**`{ BUG-01 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01`**.

## Your task

**None yet — this is a wait-for-human placeholder** (`agents/sessions.md` §5: a revalidation task is
followed by one). Session59's work was checked and closed; the defect sprints are next and are the
owner's to open.

**Boot, confirm the baseline, then ask the owner what this session is for.** Do not start a sprint
on your own reading of the roadmap — the sequence above says what is *next*, not what is
*authorised*, and the ordering is co-owned and revisable.

Two things to have in hand before that conversation, because they change how the next cluster is
sized:

- **`FIX-02-20` was re-sized twice** and its inventory now says to re-count rather than trust its
  numbers. Do that before working it.
- **`FIX-02-25` is new and out of execution order**, like `FIX-02-24` and `ACC-02-08`. It is a test,
  not a refactor, and its entry names the refactor as deliberately not done — do not widen it.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push**.
- A behaviour change is **never** documented in the commit message alone.
- Say **widget**, not "field" or "overlay".
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. `src/` and `tests/`
  currently carry **zero** `wip/77` roadmap ids — keep it that way.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.
