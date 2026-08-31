# session59 — report

**Date:** 2026-08-31 · **Suite:** **1023 / 0 / 0 / 10** throughout — no test added or removed,
green at every commit
**Mode:** revalidation (research + analysis) → owner ruling → execution of the corrections →
owner ruling at design level → one debt promotion.

---

## 1. What this session was

**The delivery-level revalidation of `FEAT-02`**, deliberately not a code review — the cold peer
review had already walked the implementation and its findings were fixed at `23e4a05a`. The
question was one level up: *was it delivered as planned, is anything forgotten, is anything
drifting.* Six findings, all applied on the owner's instruction, plus one debt entry promoted after
the owner reopened the category it had been filed in.

Deliverable: [`validation/reviews/FEAT-02-delivery-revalidation.md`](../../../validation/reviews/FEAT-02-delivery-revalidation.md)
— findings in §4, resolutions in §7, the promotion in §8.

## 2. Outcomes

**`FEAT-02` delivered all five rows with their conditions intact.** Each row's notes cell was
walked individually, including `-03`'s *negative* condition: `self.auto_hide` has exactly one write
and one read in the whole tree, so no clearing step was smuggled in. The suite arithmetic
reconciles by counting `it(…)` in the diff (−3 / +5 = net +2, 1021 → 1023), and all eighteen commits
state a count. **Nothing in the delivery was reopened** — every finding was rot in the
*surroundings*, which is what this pass exists to catch and what a code review would not have.

**Six findings, six commits, one concern each.** F3 `61dc75fe` (the only tracked code, and the only
one under the comment gate) · F2 `712b9ec5` · F1 `0b260e1b` · F5 `160cf9f8` · F4 `e3636668` ·
F6 `53d56f6a`.

**F2 is the one that mattered.** `FIX-02-20`'s site inventory told its future executor that "draft"
hits in `input_widget_control_spec.lua` were fixture noise and *"should not be counted as a
citation"* — and `FEAT-02` had since put "draft" into an `it(…)` **description** in that exact
file. The row is in the next cluster and is sized against this tree, so a stale sizing note was
about to under-scope real work.

**F4 was reopened at design level and became `T-KEYSET-SPLIT` / `FIX-02-25`** (`265b714d`). See §4.

**A side effect worth keeping true:** `src/` and `tests/` now carry **zero `wip/77` roadmap ids**,
which is a precondition for deleting the feature's scratch tree without orphaning citations.

## 3. Non-obvious points worth carrying

- **Two of the six were fixed by deleting a duplicate, not by updating it** — `tests.md`'s copy of
  the example list, and `FIX-02-20`'s inventory clause. Both rotted for the same reason: a set
  written down in two places with only one maintained. The defect cluster next touches several
  documents that restate each other; expect a third.
- **A "revisit when X changes" trigger is not a schedule.** `T-KEYSET-SPLIT`'s predecessor carried
  exactly that, X happened during `FEAT-02`, and nobody looked. That failure is the argument for a
  roadmap row over a Revisit line, and it generalises to every entry whose only forward mechanism
  is someone remembering.
- **Prefix citations survive renames.** All three code comments citing the guide's *"Asking one
  question"* still resolve after `FEAT-02` renamed that heading's suffix, because they quoted the
  stable prefix rather than the whole title. Cheap habit, and it is why the rename cost zero
  citations where an earlier heading rename cost 31.
- **`--include=*.lua` filters explicitly-named `.md` arguments too.** Two sweeps silently returned
  almost nothing before I noticed. Also: `implementation/docker/docker-data/` is the container's
  gitignored home mirror inside the repo, so `grep -rn … doc/` returns this session's own
  transcripts — exclude it.

## 4. The one ruling that changed a convention

**A slug is added when debt is PLANNED for fixing** (owner, 2026-08-31) — it is the commitment, not
an id handed out to make an entry citable. So the decision is binary: fix before release or not.
I had proposed "slug it, don't row it", which is incoherent under that rule. The owner's test for
which side it falls on is *is it a code-quality defect — drift source, readability, smelly code that
raises questions on PR review* — and release-blocking is a **separate axis**: this one is fixed
before the PR and explicitly does not block the release, because the question it answers is a
reviewer's rather than a user's.

Judged yes, and the entry was **rewritten rather than moved**, because reading the code showed it
conflated two defects of different strength: `CALLBACK_KEYS` ↔ `CONFIG_CALLBACKS` is a real list
duplication, while `WIDGET_KEYS` ↔ `configure_core` is **membership** duplication — `prompt` and
`auto_hide` reach different destinations, so there is no list to share. My own F4 wording had
implied a symmetry that is not there; harmless in a findings report, not harmless once an entry
reads as a work order. **A BACKLOG note is prose; an ACTIVE entry is a work order, and imprecision
in it becomes scope.**

`FIX-02-25` is scoped to **pin the agreement with a test**, not unify the lists — the refactor
crosses the surface/widget boundary the architecture keeps separate, and would read worse on review
than the duplication does. It is named in the entry as deliberately not done. Verified first that
no agreement test exists: every key is covered behaviourally and individually, nothing asserts the
set is closed.

## 5. What this session got wrong

- **I wrote a commit hash into a resolution table before the commit existed**, and had to correct
  it. Write hashes only after `git log` confirms them.
- **I proposed a middle option that the register's own structure forbids** (slug without a row).
  The header defines its sections by release scope; a slug on a deferred entry would make them mean
  nothing. I had not re-read the header before proposing.
- **My F4 wording overstated a symmetry**, caught only because promoting the entry forced a closer
  read of the code than filing the finding had.

## 6. Artifacts

- Track: `session59/track.md`
- `validation/reviews/FEAT-02-delivery-revalidation.md` — findings, resolutions, the promotion
- Persistent corpus: `tests.md` (manual-smoke scope), `input_api.md` (persistence list),
  `technical_debt/input.md` (**`T-KEYSET-SPLIT`** ACTIVE; the old BACKLOG entry removed),
  `tests/input/input_widget_callbacks_spec.lua` (the one code comment)
- Roadmap: `FIX-02-20`'s inventory corrected and re-dated, **`FIX-02-25`** filed, FIX-02 count
  24 → 25, `FEAT-02`'s DONE line completed
