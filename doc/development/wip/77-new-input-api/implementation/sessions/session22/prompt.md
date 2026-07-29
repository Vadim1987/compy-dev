# session22 — prompt

Read and strictly respect `agents/sessions.md`. You are inside `agents/validation.md`'s flow — do
the **boot ritual first** (read it end-to-end; confirm the suite baseline; run the re-entrance
guardrail).

Baseline to confirm on boot: `busted tests` → **854 / 0 / 0 / 4** (the 4 pending are intentional;
do not "fix" them, and do not add a fifth without saying so). A different count is a finding —
record it and raise it before proceeding.

## Where the feature stands (one level up)

The **pre-TF2 noise-cleanup mop-up is CLOSED** — `tests/` is swept. Every `tests/` REVIEW marker
is dispositioned; the batches (B-E, B-I, B-F, B-COV) are all complete. What remains before the PR
is the phase list in `validation/plan.md`: **TF2 → TF3 → the owner's DI+TF+R acceptance gate →
B/C/D (a live collapse candidate — one sitting, not three) → E execution → F final revalidation →
G PR assembly.**

**Predecessor (session21) — read `../session21/report.md` end-to-end; don't re-derive it.** It
revalidated the S20 version-tag migration, then finished the mop-up: B-F (14 markers, incl. the
editor block-nav relocation) and B-COV (22 markers). Along the way a coverage marker uncovered a
**live production bug** (`5ad2ce2`, own commit, breaking test first), the version-tag convention
gained per-file `-- Availability:` lines by owner ruling, and a new standing rule landed —
**commit granularity**, in `agents/validation.md`.

Durable artifacts you will need (under `../../../validation/`):
- `reviews/S21-revalidation-version-tag-migration.md` — the revalidation + its dispositions.
- `reviews/S20-version-tag-migration-key.md` — the convention, incl. the **S21 amendment** (the
  availability-line rule and the per-file classification table).
- `reviews/S19-tests-triage-plan.md` — batch map, now **all batches COMPLETE**.
- `notes/collapsed-gate-ledger.md` — **the forward agenda; this is your Part 1's subject.**
  OPEN: **G-1** (console-as-hidden-sink; evidence + narrowed scope added S21) and **G-2**
  (the `compy.singleclick` callback vs `compy.input.hooks[event]` API asymmetry).
- `notes/review-marker-inventory.md` — the per-marker ledger, now fully dispositioned for `tests/`.

## Your task — PART 1 (do first, and do NOT skip to Part 2): the back-filter

**The owner's instruction, verbatim in substance:** *check with me whether there are any decisions
that could be ruled BEFORE the code review — i.e. things we accumulated for the sitting. I would
hate to do the code review twice if it can be done once.*

So: **do not start TF2 by reviewing anything.** Start by putting a short, concrete list in front of
the owner of everything currently parked for the later collapsed sitting, each with an explicit
judgment from you on **whether ruling it up-front would change what TF2 reads**. That is the filter
— not "is it important?", but "would ruling this later force a second pass over the same files?".

Assemble the candidate set from (do not invent a new taxonomy):
- `notes/collapsed-gate-ledger.md` — **G-1**, **G-2**, plus the already-enumerated category (a)
  rows (R2/R4/R5/C1, in `reviews/S18-post-R-replan-reconciliation.md`) and the postponed jargon
  cluster.
- **D4** — the testing-philosophy cluster deliberately deferred *into* TF2/TF3
  (`reviews/S19-tests-triage-plan.md` §D4). This one is the most likely genuine up-front
  candidate: it is about how the tests the owner is about to read are written.
- Any marker dispositioned **KEPT-for-TF2** or **OWED** in the inventory (e.g. RVW-023, RVW-087,
  and the RVW-020 deviation session21 flagged for a ruling).
- `technical_debt/input.md`'s CONTESTED entry (inspect-mode console-owns-surface) insofar as G-1
  turns on it.

Present it as **one table**: item · what it is in one line · what ruling it up-front would cost ·
**what re-reading it would cost if deferred** · your recommendation (rule now / safe to defer).
Then **STOP and let the owner rule.** Per `agents/rules/revalidation.md`'s closing discipline and
this workflow's owner-gate rule: gather evidence, present, wait. Where the owner rules something
now, execute it (suite green, unit-sized commits per the new commit-granularity rule) before TF2
begins.

## Your task — PART 2 (only once Part 1 is settled): open TF2 properly

Once either (a) the owner rules that nothing needs carrying forward, or (b) the back-filtered
decisions are ruled **and executed**, TF2 starts — and the owner has specified how it starts:

> **Generate a fresh PR batch in the workspace, per the PR-batch generation rules, and hand it to
> the owner as the review navigation/source for TF2.**

The procedure is `implementation/pr-assembly-guide.md` §1 ("Regenerate the slices"), which is
re-runnable and git-only; the guide calls them **slices**, the owner calls them **batches** — same
artifact. Note `BASE=3256aac` is fixed and `TIP` is substituted with the current tip; the existing
`implementation/pr-slices/3*.patch` are **STALE** vs the tree and must be regenerated, not read.

**One thing to raise with the owner before you run it:** `agents/validation.md` guardrail 2 and
`plan.md` both say *slice regeneration is always LAST, after the tree settles*. The owner's request
is not a contradiction — this batch is for **review navigation**, not final PR assembly — but say
so out loud when you deliver it, so nobody later mistakes a navigation batch for the assembled PR.
The final regeneration still happens last, in Phase G.

## Standing constraints (unchanged)

**Do NOT** re-run the sweep or "re-verify" the feature; the suite baseline is the only unprompted
re-check. Parked and not to be pursued unprompted: the `src/` marker sweep (RVW-115..138, owner
confirms only after `tests/` — which is now true, so it is *askable*, not assumable); the deferred
vocab phases (TD-actualize, reference-doc completeness). Known anomalies to leave alone:
`agents/validation.md` guardrail 3. Never sweep the owner's unrelated working-tree changes into a
commit. A real wrap is the full ritual (track → report → successor prompt → repointed pointer).

## Side-track anchor (keep the primary thread live)

The last substantive outcome is the **completed mop-up**: B-F (`64e5af4`) + B-COV (`2b75f3a`) plus
the production fix (`5ad2ce2`), suite 854/0/0/4, `tests/` fully swept and every marker
dispositioned. Two lessons carried forward and worth applying in *any* task here: **verify each
recommendation against the tree before acting** (seven stale ones surfaced this way in one
session), and **a green new test is not a proven test** — flip an assertion and watch it fail. If
TF2 stalls or the owner redirects, the swept suite and the still-open G-1/G-2 are the context to
resume from.
