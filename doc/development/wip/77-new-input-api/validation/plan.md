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

> **Revision 2026-07-19 (session12, Fable) — RATIFIED by the owner in-session (2026-07-19),
> with one owner amendment: per-step model recommendations injected (the bracketed
> `[model: …]` tags below).** Model plan in one line: **Fable is required nowhere before the
> Phase D sitting** — DI/TF and B/C are Opus-managed with Sonnet workers; Fable-consult
> triggers are marked inline (DI2, TF3) and stay consult-in-main-session, not spawns.
> Phases DI and TF are inserted between A and B as a gate, per the owner's post-Phase-A
> direction (`notes/2026-07-19-owner-post-phaseA.md`). Reasoning + ratification of record:
> [`reviews/plan-revision-2026-07-19-doc-test-gate.md`](reviews/plan-revision-2026-07-19-doc-test-gate.md).
> Existing phase letters B–G are deliberately untouched (labels are load-bearing across frozen
> prompts/tracks).
>
> **Recommended session layout** (session12, contesting the owner's "each step = one cold
> session" default; owner may adjust at any wrap): session boundaries belong at owner-gates
> and context boundaries, not per step — a ruling and its execution share fresh context, and
> every cold boot re-pays the ritual + evidence re-read. **S13 = DI1** (big evidence job,
> cold session earned); **S14 = DI2 sitting + DI3 execution** (+ TF1 if capacity allows —
> DI3 and TF1 are two serial Sonnet units under one Opus); **S15 = TF1** only if spilled;
> **S16 = TF2 + TF3** (one sitting, per TF3's own text).

## Phases

Ordering is load-bearing: A3 (test fidelity) precedes any ruling that cites green tests
(standing constraint); slice regeneration is always LAST. [PROPOSED 2026-07-19: Phase B is
additionally gated on DI + TF below — doc-integrity and test-fidelity first, and B *consumes*
DI1's verdict table instead of re-deriving it.]

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

### Phase DI — Doc integrity: doc A disposition (PROPOSED 2026-07-19; gate, part 1)

"Doc A" = `wip/77-new-input-api/notes/input-contracts.md` — the pre-implementation contract
record ~30 test/fixture comments still cite (A1 inventory's dominant family), slated for
deletion with `wip/77`. Verified this session: its temporal frame is inverted by the shipped
code (its "forward" §7 largely landed — `ProjectInputController` is real; its "today"
mechanism notes describe the pre-rewrite world, though `get_user_input` survives
reinterpreted as the console route's intra-route forward), and it names its own unmet
promotion preconditions ("human-approved: NOT YET"; m6/m7 outcomes absent from §7).

- **DI1. Doc-A fidelity audit** (Sonnet evidence, orchestrator consolidates; hygiene a/b/c).
  Per-section verdict table: still-true / stale-mechanism / superseded-by-shipped /
  already-covered-in-corpus (cite where) / unique-no-home. **Verify against code (LSP +
  grep), never against the suite** — the suite's own fidelity is Phase TF's question; using
  it as witness is circular. Leverage + refresh `notes/input-suite-validation-map.md` (the
  clause→test bridge; carries one open coverage-gap finding already). Fold in known corpus
  drift: `doc/development/tests.md` suite section says 808 and cites stale pending line
  numbers (real: 815/0/0/4; pendings 118/172/185/246).
  Output: `validation/outcomes/DI1-docA-fidelity.md`.
- **DI2. Owner ruling — promotion form (OWNER-GATED).** Options with DI1 evidence attached:
  (a) promote a re-baselined doc A as a new corpus doc; (b) merge surviving unique content
  into existing corpus homes (`internals/user_input.md`, `decisions/input.md`,
  `technical_debt/input.md`), doc A stays a frozen wip record; (c) no promotion — reword the
  ~30 clause refs to cite behaviour/corpus. Session12 prior (to be tested by DI1): (b).
- **DI3. Execute the ruling** (Sonnet mechanical): content moves/merges; re-run the A1
  retarget over the doc-A family (incl. `input_fixture.lua`'s "doc A" definition and the
  `design.md §4` sibling); refresh `tests.md` facts. The ~25 non-doc-A inventory refs
  (milestone marks, review-doc citations, process artifacts) are **NOT absorbed** — they
  need rulings, not homes: they remain Phase C evidence. Doc A itself stays unedited in
  place regardless of outcome; `design/` stays frozen.

### Phase TF — Test-fidelity deepening, owner-in-the-loop (PROPOSED 2026-07-19; gate, part 2)

Runs after DI (owner's coupling: split only once comments are final; deeper reason: the
owner reviews the suite *against* the validated doc via the refreshed validation map —
DI is what makes TF2 cheap).

- **TF1. Split `tests/input/input_contracts_spec.lua`** (Sonnet mechanical) into
  human-reviewable files along its describe/bucket boundaries (19 inner describes, clean
  thematic seams). **Behaviour-preservation contract: suite count identical 815/0/0/4, same
  tags, same four pendings.** The one real risk: the shared fixture builds at file-require
  time — any cross-describe state coupling riding file-scope ordering must be found and
  surfaced, not papered over. Update `tests.md` (its "comment header, not a file split"
  sentence is superseded by the owner's direction).
- **TF2. Owner human review of the split suite (OWNER-GATED, interactive — never started
  unprompted).** Hints recorded to `validation/notes/`.
- **TF3. Evaluate hints + triage** — hint-scoped fidelity re-check (NOT a re-audit;
  guardrail 1 stands): mechanical fixes land per hint; judgment items are **pooled with
  A2's two standing fixture-architecture questions** (wrap-native helper; play-mode
  fixture) into one triage list, ruled in the same sitting as TF2 where possible.
  Principle-shaped leftovers roll to Phase C/D; nothing dropped.

**Gate:** Phase B starts only when the owner declares DI + TF accepted.

### Phase B — Convergence check (Opus; judgment-lite; NO code edits)

[PROPOSED 2026-07-19 addendum: B consumes DI1's verdict table as its evidence base for the
input-routing domain — it does not re-derive code-vs-contract facts. B keeps its own
altitude: intent-level deviation judgment and scaffolding-suspect hunting.]

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

Output: `validation/reviews/convergence-check.md`.

### Phase C — Reassessment + sitting prep (Opus; Fable consult ONLY if a call is genuinely
hard and being wrong is costly)

Merge Phase A leftovers + Phase B findings + the Pass-2 sheet + `technical_debt` notes
into **two artifacts**, both in `validation/reviews/`:

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
Output: `validation/reviews/final-revalidation.md`.

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
