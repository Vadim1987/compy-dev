# session44 — finish P10, then P11 cold

Read `agents/sessions.md` and `agents/validation.md` first, then
`../session43/report.md`. Do **not** re-derive session43's work from its track;
the report is the handover and the plan rows carry the detail.

## Where the sprint is

The operative list is `validation/reviews/S27-triage-and-plan.md` — the single
plan of record. Its parent release plan is `validation/plan.md`, which resumes
only after the sprint closes.

Session43 closed **P-13, P-20, P-21, P-22, P-23, P-24 and P9**, and produced
**Decisions 33 and 34** in the persistent ledger. Suite is **968 / 0 / 0 / 10**
— that is the number to confirm at boot, and the ten pending are sanctioned by
owner ruling, not drift.

**What is left in the sprint:**

- **P10 — part done, and it is your first task.** Still owed: the flag-shortcut
  teaching defect, W9(a)'s ledger prune, W9(b)'s two accuracy items, and W10
  batch 4 (vocabulary). Detail on the row.
- **P11 — the largest block, and the owner intends to run it cold with their
  own planning changes.** Do not start it without them. Its size is unknown
  until the §16.2 marker question is ruled.
- **The human smoke pass** owed by P9, P17 and P18 — not container work.
- **Slice regeneration and PR assembly**, which stay last
  (`implementation/pr-assembly-guide.md`).

## Your task

**1. A short revalidation of session43's judgment, before adding to it.** Every
execution step already had its own cold review, so do not re-review the code.
What has *not* been checked by anyone outside the session that wrote them are
**Decisions 33 and 34** themselves — read them against
`agents/rules/revalidation.md`'s coherence checks: do they say what the code
does, do they sit coherently beside Decisions 21, 27, 30 and 31, and does
anything they claim as ratified reasoning actually rest on something the owner
ruled? Report; do not edit the ledger without the owner.

**2. Then P10's remainder.** Suggested order, yours to revise with the owner:

- **The flag-shortcut teaching defect first** — it is the only member that is a
  defect in what the guide *teaches* rather than how it reads. `doc/input_api.md`
  binds bare `'space'` on press and release; press Space, press Ctrl, release
  Space, and the release serialises as `'ctrl+space'`, so the clearing binding
  never fires and the flag stays set. With a modifier in the combo it is
  unfixable by any second binding, because a modifier's own release has no
  expressible combo (Decision 21). The section needs the boundary stated: **a
  combo serves an atomic transition, not a held state.** Reasoning is in
  `technical_debt/input.md`, "A chord that gates a state while it is held".
- **W9(a), the ledger prune** — Decisions 6, 7, 12, 15 and 16 are each
  challenged as not-a-decision, trivial, or superseded, against the owner's
  test: *if the behaviour is what the platform always did, there was no decision
  to record.* **Tombstone, never renumber** (W9's hard constraint). This is
  owner-gated: prepare a one-line verdict per decision and wait.
- **W9(b)** — R134 and R127, each a factual claim to verify in code and correct.
- **W10 batch 4** — vocabulary: "callbacks" not "widget-output entries",
  "test cases" not "rows", "reserved binding".

**3. P11 only when the owner brings their planning changes.**

## How session43 worked, in case it is useful

Sub-agents did the execution and the cold reviews; the parent wrote prompts of
record, evaluated results rather than relaying them, and did the design writing
itself. Two rules earned their keep: **"no existing test may need editing"** as
the proof that a rewrite is representation-only, and **verify a sub-agent's
factual claims before acting** — several were right in substance and wrong in
the instrument they cited. Both are worth reusing.

`validation/notes/S43-pr-lines-owed.md` holds three PR-description paragraphs
this session owes the assembly step; add to it rather than letting the work
land unrecorded.
