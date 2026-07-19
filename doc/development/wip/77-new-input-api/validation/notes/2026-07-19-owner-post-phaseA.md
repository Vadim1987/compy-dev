# Owner attestations & plan-direction ruling — post-Phase-A (2026-07-19)

_Recorded by session11 (Opus) from the owner's in-chat ruling after reviewing the Phase A
outcomes (A1 spec-ref sweep `801ad4f`, A2 test-fidelity `912a2cd`). These are the owner's
observations and proposed direction — a **mandate for the successor session to evaluate**,
not phases enacted by session11. "Do not rampage."_

## Attestations (owner's reading of the A1/A2 evidence)

1. **The input-contracts doc ("doc A") should likely be promoted into the persistent corpus —
   but validated first.** A1 found ~55 comment references with no persistent home, dominated
   by `wip/77-new-input-api/notes/input-contracts.md`. Owner's context: that doc was **built up
   as evidence of current *undocumented* behaviour, before implementation started** — it is not
   known whether it was kept in sync with what actually shipped. So promotion is not mechanical:
   the doc must first be **checked for status/fidelity against the delivered code** (does it
   still describe reality?) before it can serve as a citation target.

2. **The small number of test-fidelity fixes is itself a warning sign, not an all-clear.** A2
   found only 1 mechanical fix. Owner reads this as: more smells likely went **unnoticed**, not
   that the suite is clean. Owner intends to **personally re-inspect the test suite** for
   infidelity — but that is impractical until the **large spec is split** into human-reviewable
   pieces, and that split is best done **after doc/comment normalization is finished** (so the
   references being split around are already correct).

## Proposed plan direction (owner — for successor to evaluate & materialize)

The owner proposes the current Phase B ("stage B", convergence check) be **gated behind a new
doc-integrity + test-fidelity sequence**. Candidate extra phases, in order:

1. Check status & fidelity of `input-contracts.md` ("doc A") against the shipped code;
   **consider its promotion to a persistent doc**.
2. **Re-run the comment sweep (A1)** to point the ~55 inventoried refs at the promoted doc
   (only if promotion is ruled in).
3. **Split the big test** (`tests/input/input_contracts_spec.lua`) to prepare it for human
   review.
4. **Owner human-review** of the split suite for more hints of test infidelity.
5. Evaluate the new hints and **re-run the test-fidelity check** over them.
6. **Evaluate & triage any escalations** discovered along the way.
7. **Only once doc-integrity AND test-fidelity are achieved**, proceed to (the current) Phase B.

## Successor commission

The next session **inspects the A1 + A2 outcomes plus this note and makes a judgement** about
refining `validation/plan.md` — expanding/adjusting it with (a suitable form of) the phases
above. Its deliverable is a **possible plan expansion/adjustment**, not execution. Per owner,
that session is **run by Fable** (the expensive wisdom oracle) for judgement efficiency — plan
architecture is exactly the judgement tier, not mechanical work.
