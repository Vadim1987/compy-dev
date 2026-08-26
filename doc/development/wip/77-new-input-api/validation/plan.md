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
> **S16 = TF2 + TF3** (one sitting, per TF3's own text). — **Superseded by the 2026-07-20
> revision below**; S16 instead ran a Fable-led redesign pressure-test that grew into a full
> ruling and became **Phase R**, inserted ahead of TF2's completion.
>
> **Revision 2026-07-20 (session16, Fable) — PROPOSED, pending owner confirmation of the
> writeup (substance already ruled on in-session across three iterations).** TF2's human
> review of the split suite surfaced the same tensions repeatedly; the owner sketched a
> reshaping, Fable pressure-tested it against code (verified against `devupstream` pre-feature
> history too), and eight obligations were ratified through iterative Q&A — see
> [`reviews/delta-design-input-api.md`](reviews/delta-design-input-api.md) +
> [`reviews/delta-spec-input-api.md`](reviews/delta-spec-input-api.md) (the ratified content)
> and [`../outcomes/S16-fable-redesign-pressure-test.md`](../outcomes/S16-fable-redesign-pressure-test.md)
> (the reasoning trail, all code-verified). Rather than defer this into the generic Phase
> B → C → D pipeline (which would dilute a cluster already ruled with more rigor than a
> typical Phase-D row gets), it becomes its own inserted phase — **Phase R**, between TF and
> B — executed now, ahead of TF2's remaining files, because the reshape changes the very test
> files TF2 hasn't reviewed yet (tier-1 tests deleted, hooks/callbacks tests added); reviewing
> them before the reshape risks reviewing code about to change shape underneath the reviewer.
> **Revised session layout: S16 continues into Phase R execution** (R1/R2 docs done this
> session; R3 confirm-gate; R4 tests-first execution, Sonnet workers per model economy,
> starting with a Sonnet sweep of the 33 in-tree `REVIEW:` remarks in `src/controller/*.lua`
> — tag each resolved-by-redesign vs. still-open — as reconnaissance before R4 touches code).
> **TF2 resumes after R4**, over the settled post-redesign suite (reviewed once, not twice);
> **TF3** follows with a much smaller absorbed-by-redesign bucket, since most of what would
> have landed there is executed rather than parked. Phase B's gate condition (below) gains R.

> **STATUS BLOCK — added 2026-08-09 (session32), owner-ruled.** This plan had not been
> written to since **session22** (`583fdcd8`, 2026-07-29) while ten sessions of work ran
> against it, so a cold reader was being told the work sits at "TF2 pending". It does not.
> Where the work actually is:
>
> - **A, DI, TF1 — done. R — CLOSED and accepted** (session18, see the note under Phase R).
> - **TF2 — RAN** (session24 take-01 triage; the owner's smoke test, session26). Its output
>   was **187 remarks**, not the near-empty bucket TF3 was predicted to hold.
> - **That output became a spinoff sprint** —
>   [`reviews/S27-triage-and-plan.md`](reviews/S27-triage-and-plan.md), the P0–P13 execution
>   table, live since session27 and **still the operative plan at a lower altitude**. It is
>   the honest descendant of TF2 (owner, 2026-08-09).
> - **We are therefore still clearing TF2** — TF2 *with* its spinoff findings. TF2 is not
>   done, and the phases after it have not started.
> - **The B→C→D collapse remains an OPEN, GATED DECISION** — it has *not* happened.
>   [`notes/post-R-replan-hypothesis.md`](notes/post-R-replan-hypothesis.md) proposed it and
>   [`reviews/S18-post-R-replan-reconciliation.md`](reviews/S18-post-R-replan-reconciliation.md)
>   gated it on TF2/TF3. When TF2 closes we come back to that gate, and the likely finding
>   is that B, C and D are **already satisfied by the code/architecture cleanup the spinoff
>   performed** — in which case **points of THIS plan collapse.** That is a ruling to be
>   made at the gate, not a fact established by the spinoff's existence. The absence of
>   `convergence-check.md` / `principle-sheet.md` / `disposition-table.md` is a **pending
>   question**, not a settled substitution.
> - **The two plans are LINKED, not merged (owner ruling, 2026-08-09).** They sit at
>   different altitudes. Clear the spinoff, close TF2, **rule on the collapse**, then
>   **F → U → G**. Do not fold the P-table into this document.
> - **Baseline is now 955/0/0/3**, not the 854/0/0/4 recorded below.

> **STATUS BLOCK II — added 2026-08-26 (session46), owner-ruled. Supersedes the bullets above
> wherever they disagree; the 2026-08-09 block is kept unedited as the record of where the work
> stood then.**
>
> - **The spinoff sprint is CLOSED, and TF2 closes with it.** All 187 remarks are discharged;
>   P11 shut the marker gate in session45; P25 and P26 opened and are both empty. The ⛔ block at
>   the head of [`reviews/S27-triage-and-plan.md`](reviews/S27-triage-and-plan.md) is the close,
>   and that document is now terminal — no new rows, no reopening.
> - **So "we are still clearing TF2" above is no longer true.** What remained was **acceptance**,
>   not triage: the human smoke pass and the owner's readability review of the PR candidate. Both
>   gate PRs, which is this plan's altitude, so §0's promotion rule sent them up.
> - **They are now Phase ACC**, inserted below and running **first**. Findings from it open a
>   **new focused sprint**, never a reopened TF2.
> - **Step ids were deliberately NOT renamed.** 2,563 P-id citations across 221 files, 786 of
>   them in frozen session dirs; a crosswalk in the sprint's close covers a reader who lands on
>   one. The reasoning is recorded there.
> - **Agreed ordering (owner, 2026-08-26):** **ACC → recon → U → L → G**, with the **B→C→D
>   collapse ruling as step zero of G** — ruled where the evidence is complete and where its
>   output, the justification table, is needed anyway. Phase F's place in that line is open.
> - **Upstream divergence is now measured** — 86 commits behind the edge, 22 behind aldum
>   upstream, one shared merge-base at 2026-06-05. The 86 is a **floor**: it is what a 23-day-old
>   local view can see, and the reported edge-side editor overhaul is not in it. See
>   [`../TAGS.md`](../TAGS.md) and
>   [`notes/S46-repo-head-inventory.md`](notes/S46-repo-head-inventory.md).
> - **Baseline is 968/0/0/10**, not the 955/0/0/3 recorded above.

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
  unprompted).** Hints recorded to `validation/notes/`. **Reordered 2026-07-20:** resumes
  *after* Phase R executes (see revision note above) — the reshape changes the files TF2
  hasn't reviewed yet; reviewing before Phase R risks reviewing soon-to-be-renamed code twice.
  **Added 2026-07-29 (C1, owner-ratified):** before opening TF2, run a documentation
  authority/provenance sweep once the pre-TF2 ruling ledger and its executions are settled.
  A cold Terra pass inventories the persistent #77 docs against the working rulings,
  classifying each decision as stakeholder-approved, owner-ratified in validation,
  implementation-derived, or unresolved. The owning session then makes the persistent
  docs stand alone: concise status/provenance where useful, no required `wip/` history,
  and no unresolved statement presented as settled. Record the sweep under
  `validation/`; it is a PR-candidate shaping gate, not a second feature review. Only
  then regenerate the navigation batch and begin TF2, so the owner reviews the docs
  surface that will actually ship.
  **[RAN — session24 take-01 triage; owner smoke test session26. SPUN OFF — 2026-08-09,
  session32.]** TF2's human review produced **187 remarks**, far past the bucket TF3
  anticipated. They were triaged into a **spinoff sprint** with its own execution table
  (P0–P13): [`reviews/S27-triage-and-plan.md`](reviews/S27-triage-and-plan.md). That
  sprint absorbs TF3 and **is still open — so TF2 is still open with it.** The two plans
  are **linked, never merged** (owner ruling, 2026-08-09); the spinoff names this document
  as its parent in its own §0. **On closing TF2, return to the gated B→C→D collapse
  decision** (post-R hypothesis, gated by `S18-post-R-replan-reconciliation.md`): the
  spinoff's code/architecture cleanup may already have satisfied B, C and D, in which case
  **those phases of this plan collapse**. That is the ruling the gate exists for — it is
  not pre-empted by the spinoff having happened.
- **TF3. Evaluate hints + triage** — hint-scoped fidelity re-check (NOT a re-audit;
  guardrail 1 stands): mechanical fixes land per hint; judgment items are **pooled with
  A2's two standing fixture-architecture questions** (wrap-native helper; play-mode
  fixture) into one triage list, ruled in the same sitting as TF2 where possible.
  Principle-shaped leftovers roll to Phase C/D; nothing dropped. Post-2026-07-20: the
  absorbed-by-redesign bucket (S16 plan-revision) shrinks to near-empty since Phase R
  executes ahead of TF2/TF3 rather than merely parking hints against it.

**Gate:** Phase B starts only when the owner declares DI + TF + **R** (below) accepted.

### Phase R — Redesign (PROPOSED 2026-07-20; gate, part 3, inserted between TF and B)

A scoped, tests-first execution of the input-API reshape that emerged from TF2's human
review (S15 side-product, S16 pressure-test + ratification). Unlike Phase A/DI/TF's
mechanical-then-owner-gated shape, this phase's *ruling* already happened (S16, in-session,
code-verified, iterated three times) — R is about writing it down precisely and executing it,
not re-litigating it. Ordering rationale: executing before TF2 finishes means the owner
reviews the suite's final shape once; executing after would mean reviewing soon-to-be-renamed
code twice.

- **R1/R2. Delta-design + delta-spec** (Fable; DONE session16): `reviews/
  delta-design-input-api.md` (decision-level, mirrors `decisions/input.md`'s voice — what
  changes and why) and `reviews/delta-spec-input-api.md` (mechanism-level — table shapes,
  signatures, call order, ten tests-first acceptance criteria).
- **R3. Confirm-gate (owner, lightweight).** Not a fresh Phase-D-style sitting — the
  substance is already ratified; this checks the written spec matches what was actually
  agreed, since prose can reveal ambiguities free-form chat didn't. Record the confirmation
  (or corrections) directly in the delta-design/spec docs' status line.
- **R4. Execution (Sonnet under Fable/Opus; tests-first, unit-sized, suite green after
  every unit).** Recommended order (matches the delta-spec's obligations):
  1. **REVIEW-remarks reconnaissance** (Sonnet, LSP+grep-backstopped per standing hygiene):
     inventory every `REVIEW:`/`REVIEW/` remark in `src/` (33+ counted in `src/controller/`
     alone), tag resolved-by-redesign / still-open / out-of-scope against the delta-design's
     obligations. Feeds both R4's own execution (resolved ones get removed as their code
     changes) and Phase C's disposition table (still-open ones carry forward).
  2. Tier-1 removal + gateway-pretap-unaffected proof (delta-spec §2; AC 5, 6, 9 middle).
  3. Submit/cancel default-flip + veto (delta-spec §3; AC 1-4).
  4. `hooks[event]` unification + seeding (delta-spec §5; AC 8).
  5. `callbacks` membership + D7 guard simplification (delta-spec §1; AC 9, 10) — guard
     change LAST, after the leaves it protects already exist.
  6. Console patch (delta-spec §6; AC 7) — the only console-facing change, confirmed scoped
     to one function.
  7. Vocabulary/rename sweep (delta-design's table) — LSP `rename_symbol` + grep backstop,
     complete or not at all (a half-migrated "hook" is worse than either endpoint).
  8. `internals/user_input.md` + `doc/input_api.md` + `technical_debt/input.md` updated to
     match (this partially pre-empts Phase E's later doc-rewrite step for the input domain
     specifically — noted so Phase E doesn't redo it).
- **R5. Obligation 6a/6b (dispatch + widget-method-surface extraction)** — mechanical,
  zero project-facing behaviour change; can ride inside R4's units 2-3 or land as a
  dedicated Sonnet unit; either way, suite-green-per-unit discipline applies.

**Gate:** R is accepted when suite is green, all ten delta-spec acceptance criteria pass as
tests, the rename sweep is verified complete (LSP references return zero hits on retired
terms), and the REVIEW-remarks inventory has no un-dispositioned "resolved" items left in
code. Then TF2 resumes.

> **[ACCEPTED 2026-07-21, owner — session18]** Phase R is **CLOSED and accepted** (commit
> `affc932`, suite 841/0/0/4). The one held-open architectural issue (input widget reading
> `love.state.app_state`) was resolved via **option E** (editor consumes Enter/Escape upstream;
> `allow_modify` constructor flag; uniform `keypressed`), and the ratified redesign was folded into
> `decisions/input.md` (R3). Gate met by **grep** (the `LSP references return zero hits` criterion
> could not be taken literally — `lua-lsp` returned phantom refs all session; grep is the ground-truth
> backstop and is clean). The post-R replan hypothesis was reconciled
> (`reviews/S18-post-R-replan-reconciliation.md`): it survives *amended*; its B/C/D-collapse is gated
> on TF2/TF3. **Owner ruling: run TF2 next as planned** (DI + TF + R must all be owner-accepted before
> Phase B — TF still pending).

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

### Phase ACC — Acceptance (INSERTED 2026-08-26, session46, by owner ruling; runs FIRST)

**The spinoff sprint is closed and this is where its last two items landed.** TF2 closed with it
(`reviews/S27-triage-and-plan.md`, the ⛔ block at its head). Neither item was ever remark-shaped:
both gate PRs, which is release altitude, and §0's promotion rule sends release-shaped work up.

Named `ACC` rather than given a sequence letter for the reason Phase U was named `U`: **B–G are
load-bearing across frozen prompts and tracks.** DI, TF, R, U and L carry names for the same
reason.

**Two items, and they are the whole phase:**

1. **The human smoke pass.** Checklists in `doc/development/smoke_checklists.md`. Order by
   upstream sensitivity — **`balloons` first**, being 5 ahead / 0 behind `origin/main`, the only
   repo with no divergence to reconcile and therefore the one result recon cannot invalidate.
   Then `keyboard` and `maze`, then any platform-side rows an edge-side editor overhaul could
   disturb. `balloons` and `sapper` still **owe a list**; the document's header says so.
   **`maze` runs against `newinput-edge`** — `da9d1c2`, the maze half of the `Shift+Esc` fix
   rows B8–B10 exercise, is on that branch only.
2. **The owner's readability review of the PR candidate**, taken **as slices**, for the
   separation of review surface. The assembly guide is re-runnable and git-only, so an
   intermediate cut costs machine time, not owner time; only the **final** cut must stay last.

**Why ACC runs before U, not after (owner, 2026-08-26).** A smoke pass on the pre-merge tree is
not merely reassurance — it is the **control** for the post-merge one. Merging an advanced
upstream, including a reported edge-side editor overhaul, into a branch whose behaviour no human
has verified leaves every later device failure with two candidate causes and no way to separate
them. Re-running a pass costs bounded owner time; bisecting a confounded failure does not.

**Recon does not subsume the pass.** They are orthogonal: recon measures upstream movement, the
pass tests device behaviour no suite can reach. Recon can make the pass premature, never
unnecessary.

**Exit, and what a failure does.** ACC exits when every owed checklist has been run by a human
and the owner has read the slices. **A finding does not reopen TF2** — it opens a **new focused
sprint** against that defect, with its own id space. Tag the states a clean pass ran against
(`TAGS.md`, round 2), so "green" names a commit rather than a moment.

**Phase F's placement relative to ACC is open** — the owner did not rule on it, and the B→C→D
collapse may absorb F. Left for the gate rather than settled here.

### Phase U — Upstream reconciliation and downstream compatibility (INSERTED 2026-08-09,
session32, by owner ruling; sits between F and G)

**Promoted here from the spinoff sprint, where it was P12** (`reviews/S27-triage-and-plan.md`
§8). It was always the wrong altitude for a remark-triage table: it is not a remark, it is a
release precondition. Named `U` rather than a new letter in sequence because **B–G labels are
load-bearing across frozen prompts and tracks** — the same reason DI, TF and R carry names.

Reconcile this branch against the advanced upstreams — the platform repo (and possibly an
advanced fork of it) **and** each of the three nested example repos (`balloons`, `maze`,
`keyboard`, each with its own remote and its own PR) — then land the coordinated set of PRs.

- **It blocks the real PR** and needs its own plan; the spinoff's §8 holds the analysis and
  is not superseded by this promotion, only re-parented.
- Not attempted before the snapshots are stable: re-planning against a moving upstream while
  the design is still settling means doing it twice.
- **Dispositioned — P13 does NOT follow P12 here (owner ruling, 2026-08-09, `d348b505`).**
  This bullet asked the question while it was open; the session32 replan answered it.
  **P13 is REDUCED TO REVALIDATION and stays in the spinoff**: Decision 30 makes the matcher
  read the device — which is exactly what harmony's `patch_isDown` replaces — so harmony can
  now drive the combo mechanism it previously could not, and P13's build premise largely
  dissolves. What remains is to confirm a real combo end-to-end under the device-read matcher
  and retire the manual `release_keys()` discipline if it does. See
  `reviews/S27-triage-and-plan.md` §11.3. **[Recorded S33.]**

### Phase U ordering — the example half comes FIRST (owner intent, 2026-08-11)

The owner intends to **pull the current upstream versions of the two detached example repos**
(`keyboard`, `maze`) and reconcile them. That half of Phase U now **precedes** the sprint's
deepfix steps for those repos (`S27-triage-and-plan.md` P17, P18), rather than following them.

**Why the order matters more than the labelling.** A deepfix planned against a stale base is
planned twice — the argument that has already ordered this feature's work three times — and it is
sharpest here: upstream may have moved in `examples/keyboard/input.lua`, the file the `textinput`
heal rewrites and the file the reconciliation just edited. Meeting that divergence as a merge,
before designing, is cheap; meeting it after designing is a redesign.

**[S36] Mechanic, owner 2026-08-11: pull each upstream into its OWN branch.** Do not merge
upstream into the working branch as the first move. Fetch it to a separate branch per repo so the
reconciler can **switch between them, compare, and rule each merge deliberately** — which is the
difference between reconciliation as an inspectable operation and reconciliation as a conflict
storm resolved under pressure. It also leaves the pre-merge state reachable for the whole
exercise, which matters most in `examples/keyboard`, where our own edits and the heal both land in
the file most likely to have moved upstream.

The platform half of Phase U (upstream reconciliation of the framework repo itself) is untouched
by this and keeps its original placement.

**[S37] `keyboard` is DONE, 2026-08-11; `maze` is still owed.** The owner ruled the merge to
session37 with the shape kept deliberate: **a true merge, ancestry preserved**, because upstream is
expected to move again and every later re-merge is cheap only while `dsent/dev` stays an ancestor.
(The eventual delivery is separate and unaffected: the owner prepares a diff against upstream and
opens a fresh branch off it carrying a commit or two — so ancestry here serves re-merging, not the
PR's shape.)

- **Merge `17289e9`**, upstream snapshot on its own branch `upstream-dsent-dev-20260811`, pre-merge
  state `05cedec`, correction `ca6d5df`. Nothing pushed. 36 commits, 24 files, +5227/−804.
- **The stale-base argument was vindicated, though not where it was aimed.** Upstream never touched
  `input.lua`; it moved in `alt.lua`, `keyboard_view.lua` and `main.lua`, and it added five games.
  The merge was textually clean **and semantically broken**: the new `words.lua` judges typing
  through `textinput` guarded by `inputStale`, the held-key filter this branch deleted, so the
  game raised on the first glyph typed and no hunk touched both files. Had P18 been designed
  first, that would have arrived after the design.
- **The reading of upstream's input model, done before the merge** at the owner's instruction:
  `reviews/S37-keyboard-upstream-input-assessment.md`. Its consequences for the deepfix are bound
  into `reviews/S27-triage-and-plan.md` §15.4.
- **A local-branch trap, recorded so the maze pull does not repeat it:** the branch named
  `dsent/dev` in the keyboard repo is **not** a tracking mirror of upstream — it carries the first
  eight of this feature's own migration commits. The upstream snapshot was taken from
  `origin/dsent/dev` directly. Check what a local branch actually holds before treating its name
  as its content.
- **`maze` needs the same two steps** — the input reading first, then the merge — before P17.

### Phase L — Ledger compaction (INSERTED 2026-08-11, owner) — runs before release, after the tree settles

**The rule this reverses.** The sprint has run under *"tombstone decisions, never renumber"*
(`reviews/S27-triage-and-plan.md`, the W9 hard constraint). The owner reverses the first half for
the release: **decisions that were established and then collapsed within this feature are removed
before the PR**, rather than shipped as tombstones. The second half stands until the owner
discloses their final renumbering algorithm — **do not renumber in this phase**.

**Why.** A stakeholder reading the ledger currently meets five decisions about a surface that
never ships: 13, 20 and 29 established the tracked held-key set, 30 and 31 withdrew it. That reads
as churn, and the strategic frame asks the PR to carry nothing beyond the ask without a
justification. The reasoning is not lost — it is in git, and in the register where it is load
bearing.

**Scope, verified 2026-08-11 rather than assumed.**

- **The three collapsed decisions are cited nowhere in code.** `grep` over `src/` and `tests/`
  finds citations of Decisions 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 14, 15, 18, 21, 23, 26, 30 and 31
  — **not** 13, 20 or 29. Removing them breaks no comment.
- **Six references need repair**, all in prose: five inside `decisions/input.md` itself (including
  Decision 30's own "supersedes" line and two passages in Decisions 26 and 29's neighbourhood),
  and one in `technical_debt/input.md` naming Decision 20's read-only view.
- **Renumbering is what would be dangerous, not removal.** There are ~150 citations by number in
  code; leaving gaps at 13/20/29 costs nothing, while shifting numbers would invalidate all of
  them at once.

**On the owner's question — does this confuse an LLM assistant?** Mildly, and manageably. The risk
is not the gaps: it is that historical commit messages and any surviving external notes cite
numbers that no longer resolve, and an assistant meeting *"Decision 20"* will find nothing and may
invent a reading. **Mitigation: do the excision in ONE commit whose message names each removed
decision and its subject**, so `git log -S 'Decision 20'` answers the question in one step. That is
cheaper than a tombstone and does not put dead text in front of stakeholders.

**[S36] Three items, not one — settled 2026-08-11.**

1. **Excise the collapsed decisions** — 13, 20, 29 established the tracked held-key set and 30/31
   withdrew it. Cited nowhere in code (verified).
2. **Remove Decision 11's withdrawn-rationale audit trail.** A doc marker asks for it, and it was
   held back only because that trail *was* the file's own tombstone precedent. With tombstone
   discipline reversed for the release, the tension dissolves and it goes with the rest.
3. **Demote Decision 12 (`inspect` is a mode-to-route line).** Under the owner's boundary
   (`../../../conventions/docs.md`, *"de-facto behaviour has a boundary"*) it is **not a
   decision**: the `app_state == 'inspect'` routing exists **unchanged at the PR base**
   (`controller.lua:20` there, `:22` now), so the entry canonicalises behaviour that predates the
   feature. Its content belongs in an internals guide if it is not already there; the ledger entry
   goes. **Checked, not assumed** — and the same check cleared Decisions 6, 7 and 15, which are
   choices this feature made: base carried `oneshot` auto-close on submit (removed by 6), and
   `compy.input` does not exist at base at all, so 7 and 15 are about surface the feature invented.

**Gate.** After excision: every `Decision N` citation in `src/`, `tests/` and `doc/` (outside
`wip/`) resolves to a heading that exists. That check is mechanical and should be run, not assumed.

### Phase G — PR assembly (per `implementation/pr-assembly-guide.md`)

Slice regeneration **LAST**, after the tree settles. PR description structure: intent →
design → ratified deviations → justification table (generated from the principle sheet +
disposition table — this is where every surviving "keep + justify" gets its one line) →
open questions. Reviewability gate: a stakeholder with only `doc/input_api.md` + the PR
description must be able to review it. `wip/77` deletion: owner-gated, after PR is up.

**[S37] The human smoke pass has a written checklist, and it is the gate for the detached
repos' own PRs** (§16.3: *"their only gate is a human smoke pass"*). It is
**`doc/development/smoke_checklists.md`** — persistent, so it outlives `wip/77`, with one
list per example, each case naming what to press and what to expect.
Whoever changes an example's input mechanism updates its list in the same commit.

**[S39] The scope, measured rather than assumed (2026-08-13), because "the examples" is
vaguer than it sounds.** This feature changed code in **twelve** examples: nine tracked
(`clock`, `guess`, `paint`, `pong`, `repl`, `sapper`, `tixy`, `turtle`, `valid` —
`git diff 3256aac..HEAD -- src/examples/`) and three detached (`keyboard`, `maze` which
now also emits `draw`, and `balloons`). `life` was not touched.

**Every one of them is smoked before the PRs land. What differs is the gate, not the
requirement:**

- **The three detached repos each open their own PR whose ONLY gate is that pass**, so each
  needs a written list. **Written: `keyboard` (2026-08-12), `maze`+`draw` (2026-08-13).
  OWED: `balloons`.**
- **The nine tracked examples ride the platform PR** and are smoked as part of its review
  pass. A written list is owed only where the input *mechanism* changed materially rather
  than a call being renamed — **`sapper` is the clear case** (P19 owns it, and it carries a
  live defect older than this feature), and `turtle` is the other candidate, being the only
  tracked example that registers a shortcut.
- **Nothing in this work has been run in a game scene by anyone**, at any commit, in any
  example: no container in this project can inject a keystroke. So this pass is not a
  formality on top of testing — for input behaviour it **is** the testing.

## Standing constraints (inherited, listed for the orchestrator's convenience)

- Suite baseline **955/0/0/3** as of session29 (815 when this plan was written, 841 after
  Phase R, 854 at session21, 904 after session25, 923 after session26, 953 after session27);
  the only unprompted re-check. No sweep re-runs. The live number is the one in the
  current `sessionNN/prompt.md`.
- Anomalies to leave alone: `agents/validation.md` guardrail 3 list.
- Verify factual claims (any oracle's, any sheet cell's) in code before acting: LSP for
  symbols, grep as completeness backstop; two verdicts were overturned this way already.
- Historical session prompts/docs are frozen records — fix references only in *living*
  documents (this plan, `agents/validation.md`, persistent corpus).
