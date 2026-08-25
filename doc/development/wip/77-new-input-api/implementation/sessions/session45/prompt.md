# session45 — run P11: inventory the gap first, then compact

Read `agents/sessions.md` and `agents/validation.md` first, then
`../session44/report.md`. Do **not** re-derive session44's work from its track;
the report is the handover.

## Where the sprint is

The operative list is `validation/reviews/S27-triage-and-plan.md`. Its parent
release plan is `validation/plan.md`, which resumes only after the sprint closes
— and the first thing waiting there is **the B→C→D collapse ruling**, an open
gate, not a settled substitution. Do not touch the parent plan.

**P10 is closed** (session44). **P11 is the last block of the sprint** and the
largest. After it: the human smoke pass owed by P9/P17/P18 (not container work),
then slice regeneration and PR assembly, which stay last.

**P11 is not gated on anything.** Two framings that said otherwise were traced
and retired in session44 — see the report. The marker question was ruled in
session36 and the ruling is restated in plan **§17.5**; read that section before
planning anything, it is short and it is the row's real scope.

## Your task

### 0. First, a short revalidation — session44 exercised judgment

Every execution step had the owner in the loop, so do not re-review the code or
the prose. What no one outside session44 has checked is its **two judgment
artifacts**: `validation/reviews/S44-W9a-ledger-prune-verdicts.md` (five
verdicts, executed) and §6 of `S44-decisions-33-34-revalidation.md`. Read them
against `agents/rules/revalidation.md`'s coherence checks — do the tombstones say
what the ledger now says, do Decisions 6/7/15 still carry every claim their
citations rest on, and did the compression drop anything a reader needed?
`grep -rn 'Decision 6\|Decision 7\|Decision 12\|Decision 15\|Decision 16' src/ tests/`
is the instrument. Report; correct what is clearly wrong; raise the rest.

### 1. Then P11, and it starts with an inventory — this is the point

**The row's size is known for markers and unknown for everything else.** The
census in §17.5 (100 markers, measured 2026-08-25) covers only what
`grep -rniE 'INTERIM|REMARK'` finds. Two parts of P11 have **never been
enumerated by anyone**:

- **W10 batch 3 — comment bloat, "~50 remark ids".** That number is a guess
  inherited from the S27 triage and the subset was never listed. It must be
  **re-derived from `../outcomes/S27-remark-inventory.md`** before any editing
  begins.
- **The `maze` + `draw` comment compaction** in the nested repos. `P-17-06`…
  `P-17-14` wrote deliberately full comments under the 2026-08-13 verbosity
  ruling, so there is real volume there and nobody has measured it.

**Deliverable of this step, before you edit a single comment:** one inventory
document under `validation/outcomes/`, listing every site P11 owns, by kind
(factually wrong / editorial / bloat / marker), with the disposition each takes
under §17.5's ruling. Session44's experience is the argument for doing this
first: two of P10's four "remaining" members turned out to be already done or
already ruled, and the only reason that was cheap is that they were checked
before they were worked.

### 2. Then the compaction and the marker clearing

Under `agents/rules/commenting.md` — the authority, and **read it fresh**: the
owner added a section on 2026-08-25 that did not exist when the earlier passes
ran.

**The guardrail the owner named explicitly, and the one to watch hardest:**

> **A reference is not an annotation.** Compaction must not turn comments into an
> index of reference ids. A comment reduced to `-- Decision 21` has been deleted,
> not compacted — it says something governs this code without saying **what**, so
> the reader must leave the file to learn anything. Every citation carries **at
> least a clause of its own**: the claim or constraint that applies *here*, with
> the reference for whoever digs deeper.

Two more that follow from it:

- **Any rationale a compaction removes must already exist in the persistent
  corpus, or land there first** (plan §17.5). That turns a deletion into a doc
  edit, which is the same shape as the standing deviation rule.
- **`keyboard`'s 177 → 101 pass is the model you were given, and it was
  self-assessed.** No cold reader ever checked that no argument was lost. Copy
  its ambition, not its assurance.

The gate is `grep -rniE 'INTERIM|REMARK' src/ tests/` returning nothing — note
the `-i` and the missing colons: two markers once hid from the colon-only form.

## Two things not to be surprised by

- **Phase L will reach back into the ledger.** The parent plan's Phase L
  reverses "tombstone, never renumber" for the release: decisions established
  and then collapsed *within this feature* are **removed** before the PR. Two
  tombstones were created in session44, and **Decision 16 fits that criterion
  exactly**. Do not pre-empt Phase L, and do not treat the tombstones as
  permanent either.
- **The parent plan's status block is stale** (baseline `955/0/0/3`, the sprint
  described as a "P0–P13 table"). The owner was offered a refresh and left it,
  since the collapse ruling rewrites that block anyway. Do not fix it in passing.

## How session44 worked, in case it is useful

The parent did the judgment and the prose, and delegated one mechanical sweep to
Sonnet with a prompt of record on disk. Two rules earned their keep and both
apply directly to P11: **verify the handover's claims before acting on them**
(twice a listed task was already done or already ruled), and **check citations
before cutting, not after** (Decision 16 had none, Decision 12 had seven, and
that asymmetry is invisible until you look). One hygiene fix owed: a sub-agent
ran `git stash`/`pop` in the shared tree with the parent's uncommitted edits
live — **forbid git outright in worker prompts**, not just committing.
