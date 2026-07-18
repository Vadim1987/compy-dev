# Validation-phase plan — feat #77 pre-PR (actionable)

_Produced session10 (Fable, 2026-07-18) from the owner's raw notes (`plan_notes.txt`,
same directory) plus in-session owner amendments. This is the **mandate** for session11
onward, designed to be **managed by Opus**. Session mechanics (boot ritual, track
discipline, wrap rule, guardrails, sub-agent hygiene a/b/c, model economy) are governed
by `agents/validation.md` and are NOT restated here — read that first._

## Why this plan exists (problem statement, owner's)

Naive review passes mixed concern-altitudes, burned tokens on in-place fixing, and
revealed a repeatable failure mode: suboptimal decisions smuggled in and rubber-stamped
at design/spec time, then canonicalized. The previous corrective plan (the Pass-2 sheet)
asked for ~30 individual rulings — too cognitive-heavy, and bulk approval is exactly how
smuggling happened. This plan moves judgment to a **small number of principle-level
rulings** that dissolve most row-level concerns, with mechanical work delegated down.

## Owner decisions already made (do not re-ask)

1. **Jargon rulings are POSTPONED** until after the convergence check (Phase B) — they
   may depend on its findings. Do **not** implement the terminology-intro-at-top-of-file
   stopgap beforehand; jargon is decided once, at the Phase D sitting, then executed once.
2. **Design is retrospectively challengeable.** The `design/` freeze was an
   *implementation-time* restriction. Now that the solution has physical shape,
   scaffolding-era design decisions may be **proposed** for replacement/straightening
   where that improves clarity/stability and avoids future tech debt. Each such proposal
   is an **owner-gated ruling** (Phase D). `design/` files themselves stay unedited —
   they are history/source-of-intent, and `wip/77` is ephemeral anyway.
3. **The Pass-2 sheet** (`implementation/reviews/pass2-consolidated-ruling-sheet.md`)
   is **consumed as evidence, not walked row-by-row**: every row must be dispositioned
   via the Phase C table, none silently dropped. Verified concrete findings (e.g. R2/R4/R5
   shipped-API deviations) must survive the abstraction.
4. **Commits**: the owner has explicitly granted all sessions authority to commit
   locally at their own discretion (2026-07-18 grant, recorded at the bottom of
   `agents/validation.md`). Unit-sized, noted in track. Never push.

## Phases

Ordering is load-bearing: A3 (test fidelity) precedes any ruling that cites green tests
(standing constraint); slice regeneration is always LAST.

### Phase A — Mechanical integrity (Sonnet workers, Opus orchestrates; no owner gate)

- **A1. Spec-reference sweep.** Comments in code and tests must reference the
  **persistent docs corpus** (list in `agents/validation.md`, "PERSISTENT DOCS CORPUS")
  with named sections — not `wip/` drafts, milestone marks, or `badrefspec`-flagged
  targets. Fix mechanically where the persistent target exists; **inventory** every
  reference with no persistent home (these become Phase C evidence, not ad-hoc fixes).
  Output: edits + report `implementation/sessions/sessionNN/spec-ref-sweep.md`.
- **A2. Test-fidelity audit + fixes (the S7 precondition).** Find tests that
  step-by-step reimplement framework behaviour instead of calling the real methods, or
  otherwise don't test what their descriptions claim. Fix the mechanical cases; **list**
  the judgment-required cases for Phase C. Suite must end green; any count change from
  815/0/0/4 is explained in the report, not waved through.
  Output: edits + report `implementation/sessions/sessionNN/test-fidelity.md`.
- Sub-agent hygiene rules (a) LSP told, (b) delegate down, (c) prompts+results on disk —
  per `agents/validation.md`, every spawn.

### Phase B — Convergence check (Opus; judgment-lite; NO code edits)

Check the delivered solution (code + persistent docs) against `design/` and original
stakeholder intent ("simpler and more robust input API"; PR reviewable from
`doc/input_api.md` + PR description alone). This is a **delta check, not a re-sweep**
(guardrail 1) — output is one short report, three buckets:

- **satisfied** — intent met, nothing to do;
- **deviated** — solution differs from design/intent (include the shipped-API deviations
  already verified: `eval`/`result` keys, `multiline` promised-not-shipped, silent
  config-key drop — confirm still current, don't re-derive);
- **scaffolding-suspect** — design decisions that served construction but now reduce
  clarity/stability, candidates for retrospective straightening (owner decision 2 above).

Output: `implementation/reviews/convergence-check.md`.

### Phase C — Reassessment + sitting prep (Opus; Fable consult ONLY if a call is genuinely
hard and being wrong is costly)

Merge Phase A leftovers + Phase B findings + the Pass-2 sheet + `technical_debt` notes
into **two artifacts**, both in `implementation/reviews/`:

- **C1. Principle sheet** (`principle-sheet.md`): the *small* set of high-level questions
  for the owner — expected ≲8. Known members: jargon policy (the postponed S2 cluster:
  `overlay`, `callback slots`, tier-N prose); invented-concept threshold ("more
  predictable vs more elaborate"); design-tweak proposals (scaffolding-suspects from B);
  API-deviation policy (fix vs document-and-justify); doc-of-record boundaries. Each
  question: plain language, the real tradeoff, a recommendation-as-proposal.
- **C2. Disposition table** (`disposition-table.md`): **every** Pass-2 row + every new
  finding → which principle resolves it → proposed concrete action (or "needs individual
  ruling" — keep these rare). This table is what prevents the abstraction from becoming
  a new smuggling channel: the owner skims mappings instead of re-litigating rows.

### Phase D — Owner ruling sitting (interactive; owner + session model)

The anti-rubber-stamp contract, unchanged from session10's mandate in *method*, applied
at principle altitude: **one principle at a time** — plain statement, evidence on probe,
recommendation as proposal with the invented-concept check asked aloud, STOP, discuss,
owner may amend, **record immediately on disk** in the principle sheet before moving on.
Then the owner reviews the disposition table for mis-mappings; corrections recorded the
same way. Jargon and design-tweak rulings land here. Batch approval is prohibited.

### Phase E — Execution (Sonnet mechanical under Opus; judgment escalates)

Execute the dispositioned actions in this order: ruling-driven code/test changes →
simplifications → `internals/user_input.md` rewrite (the A-doc: stakeholders are pointed
at it from the PR) → remaining doc incorporation → ledger sweeps. Unit-sized work, each
unit in track; suite green after every unit.

### Phase F — Final revalidation (Opus; one page)

Delta check of the post-execution tree against stakeholder intent AND the
meta-requirements (clarity, stability, robustness, minimalism). Anything failed →
back to Phase D as a named question, not silently patched.
Output: `implementation/reviews/final-revalidation.md`.

### Phase G — PR assembly (per `implementation/pr-assembly-guide.md`)

Slice regeneration **LAST**, after the tree settles. PR description structure: intent →
design → ratified deviations → justification table (generated from the principle sheet +
disposition table — this is where every surviving "keep + justify" gets its one line) →
open questions. Reviewability gate: a stakeholder with only `doc/input_api.md` + the PR
description must be able to review it. `wip/77` deletion: owner-gated, after PR is up.

## Standing constraints (inherited, listed for the orchestrator's convenience)

- Suite baseline **815/0/0/4**; the only unprompted re-check. No sweep re-runs.
- Anomalies to leave alone: `agents/validation.md` guardrail 3 list.
- Verify factual claims (any oracle's, any sheet cell's) in code before acting: LSP for
  symbols, grep as completeness backstop; two verdicts were overturned this way already.
- Historical session prompts/docs are frozen records — fix references only in *living*
  documents (this plan, `agents/validation.md`, persistent corpus).
