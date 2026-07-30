# session24 — wait for the human (TF2 feedback expected)

Read and strictly respect `agents/sessions.md` and `agents/validation.md`. Boot
normally: read this prompt, the complete `../session23/report.md`, the session23
commissioning prompt and track, then create `session24/track.md`. Do not edit
any historical session artifact.

## Where things stand

Session23 revalidated the pre-TF2 gates, found the reference layer around the
persistent contract corpus unreconciled, and — with the owner's acceptance —
executed every correction plus one new in-flight ruling (`show`/`configure`
raise on an unrecognised key). Suite **867 / 0 / 0 / 3**. The navigation slices
are regenerated, 89/89 complete and disjoint, and all eight now apply cleanly
against `BASE` — which the previous batch did not. Details, caveats, and the
disclosed process error: `../session23/report.md`.

The tree is ready for **TF2**. The owner opens it from
`implementation/pr-slices/`; you do not.

## Your task

**Wait for the human.** This prompt specifies no work of your own.

The live expectation is **inbound TF2 review feedback**. When it arrives:

1. Record it in `track.md` as received — verbatim where it is a ruling.
2. Triage each item against the standing ledgers before acting: the decisions
   corpus (`doc/development/decisions/input.md`), the debt ledger
   (`doc/development/technical_debt/input.md`), and `validation/plan.md`'s
   remaining phases (TF3 → the owner's DI+TF+R acceptance gate → B/C/D → E → F
   final revalidation → G PR assembly, which regenerates the slices for real).
   Say which bucket each item lands in — and say so **before** changing files.
3. Act only on the human's instruction. Do not pre-empt TF2's findings, do not
   start the next phase, and do not open a fix sweep off your own reading of
   the feedback.

If the human arrives with something else entirely, ask for instructions and act
on those instead.

## Carryover

- Decision 15 revised is **in-flight**, not settled — it is a live candidate for
  TF2 comment. Its scope line is deliberate: contract violations raise, runtime
  states still warn, both pinned by tests.
- The current slice batch is a **review aid**. Final Phase-G assembly regenerates
  it from `pr-assembly-guide.md` §1 after all later work settles.
- Owner scratch in the working tree is untracked and out of scope. Stage
  explicit paths, never a directory, in this tree.
