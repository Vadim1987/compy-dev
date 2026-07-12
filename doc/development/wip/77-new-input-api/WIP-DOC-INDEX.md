# WIP Doc Index — `doc/development/wip/77-new-input-api/`

> **Purpose.** This working directory is slated for **deletion before the PR merges**.
> Before it goes, a reviewer must decide what — if anything — should be carried into the
> permanent docs corpus (`doc/development/{overview,conventions,internals,…}`). This index
> lets that decision be made **without reading all 253 docs**: each canonical doc gets a
> 1–2 line summary + role + apparent status; snapshot/version/process-bulk directories are
> summarized at the directory level with a file count only.
>
> **Roles:** design · spec · ratified-model · stakeholder-input · analysis-note ·
> migration-note · process-artifact[session|prompt|outcome|review|estimate|status].
> **Status** is "apparent" — read from each doc's header/body (`Approved by human? YES/NOT YET`,
> `Gate-N`, `ratified`, `superseded`, `draft`, `historical`). Where a header says NOT YET but
> the body/downstream shows it landed, both are noted.

## Corpus tally

- **253** markdown docs in the original corpus.
  - **115** canonical docs indexed individually below.
  - **21** in version/archive **snapshot** dirs — summarized per-directory, not per-file.
  - **117** in **process-bulk** dirs (implementation & design prompts/outcomes/reviews/sessions)
    — summarized per-directory with milestone families, not per-file.
- **+1** newer markdown artifact (`reviews/synthetic-diff-manifest.md`, created mid-review;
  see §Flags) → 254 md files present at index time.
- **Non-doc files to flag** (see §Flags): `implementation/ses/SWEEP.tgz` (root-owned binary),
  `reviews/synthetic-system-diff.patch` (302 KB), plus docker infra (`compose.yml`, `.env`,
  `Dockerfile`, `mcp.json`) and an empty `implementation/notes/.gitkeep`.

---

## Likely incorporation candidates (reviewer shortlist)

Durable **system knowledge** worth considering for the permanent corpus. Everything not listed
here is, by default, **process ephemera** (SDLC bookkeeping, session logs, superseded drafts)
with no lasting doc value — the reviewer makes the final call.

**Tier 1 — the ratified design of the shipped feature:**
- `design/notes/ratified-model.md` — the one-page **RATIFIED** canonical model (Gate 1, human-approved 2026-07-05); the authority `design.md`/`spec.md` derive from. *Strongest single keep.*
- `design/spec.md` — cross-cutting API contract (chain tiers, `keys_pressed`, widget lifecycle, semantic chains, cursor/text). Gate 2 APPROVED. *The API reference.*
- `design/design.md` — re-derived design (opens with the ratified model verbatim). Gate 2 APPROVED.
- `design/requirements.md` — normalized FR/NFR set (the durable "what & why").
- `design/notes/input.md` — verbatim original stakeholder ticket + owner clarification; canonical ground-truth ask.

**Tier 2 — current-behaviour reference likely destined for `internals/`:**
- `notes/input-contracts.md` — canonical current-behaviour input-routing contract record; the doc itself names `doc/development/internals/` as its promotion target at feature close. Read together with its already-applied `input-contracts-correction.md` + `input-contracts-revalidation.md`.
- `notes/stakeholder-3-input/compy-input-quirks.md` — developer-facing catalogue of Compy input quirks (event order, key-repeat, modifier chords). Reference-grade, audience-facing.
- `notes/stakeholder-3-input/compy-lua-game-patterns.md` — Lua game/example design-pattern guide. Reference-grade.

**Tier 3 — the frozen implementation targets (keep if per-milestone spec history is wanted; else the shipped code + `spec.md` suffice):**
- `design/spec/M5c-dispatch-chain.md`, `design/spec/M7-02-recut.md`, `design/spec/M8-02-recut.md` — the three **Gate-3 CLOSED / frozen** (2026-07-07) implementation specs that superseded the earlier M4–M8 cuts.
- `design/roadmap.md` — milestone roadmap (Gate-3 frozen).

**Tier 4 — cross-cutting method lessons (candidate for a process/retro home, not the input corpus):**
- `notes/retro-contract-provenance.md` — standing "who decided this must hold?" discipline; explicitly self-marked `status: reference`.
- `notes/talk/two-tier-test-strategy.md` — settled test-strategy decision (safety-net vs test-first tiers).

**Note:** `reviews/synthetic-system-diff.patch` + `synthetic-diff-manifest.md` capture the **actual
shipped system change** (baseline→HEAD, wip dir excluded). Not a doc to incorporate, but the most
faithful record of *what the feature actually changed* — useful to the reviewer for cross-check.
The manifest cites a shipped **usage guide** (commit `ced38bd`) that likely supersedes the draft
`notes/talk/api-demo.md`.

---

## Root

- `README.md` — feature overview: the two chained, asymmetric phases (`design/` = managed SDLC lifecycle; `implementation/` = unmanaged black-box execution ledger) and their single handoff. Role: design (index). Status: current.
- `entrypoints.md` — maintained menu of open/closed actionable entrypoints (E-numbers) with status + depends-on. Role: process-artifact[status]. Status: live tracker (large, 68 KB).

---

## `design/` (managed SDLC lifecycle)

### `design/` (top-level)
- `design/README.md` — feature TL;DR + doc-chain map (requirements → context → status → design → spec → roadmap → estimates). Role: design (index). Status: current.
- `design/context.md` — SDLC `context` node: maps each requirement to current architecture (what exists/missing/reusable); no solutions. Role: analysis-note. Status: stable/converged.
- `design/design.md` — re-derived design (E29), ratified model verbatim in §0. Role: design. Status: **Gate 2 APPROVED (2026-07-06)**; supersedes design.versions/version01.
- `design/estimates.md` — derived PERT sizing per milestone (without/with-LLM; ≈77h/≈45h). Role: analysis-note[estimate]. Status: **Gate 3 CLOSED (2026-07-07)**, baseline v04.
- `design/requirements.md` — normalized FR/NFR from the stakeholder ticket. Role: requirements. Status: stable, decisions resolved.
- `design/roadmap.md` — milestone roadmap M1→M8; RE-CUT consolidated M5a/M5b/M6 into M5c. Role: design (roadmap). Status: **Gate 3 CLOSED/frozen (2026-07-07)**.
- `design/spec.md` — re-derived cross-cutting API contract (E29). Role: spec. Status: **Gate 2 APPROVED (2026-07-06)**; supersedes spec.versions/version01; one §5 open item pending owner commit.
- `design/status.md` — rolling chain dashboard + blocking-decisions track; records the M4 architect-pushback crisis and its 3-gate resolution. Role: analysis-note[status]. Status: live — Gate 3 CLOSED 2026-07-07.

### `design/agents/`
- `design/agents/process.md` — defines the design lifecycle's custom SDLC process/flow and its deviations. Role: process-artifact. Status: header NOT YET approved; operative.
- `design/agents/sdlc.md` — mechanical SDLC binding overlay for the `design/` subtree (role→filename map). Role: process-artifact. Status: header NOT YET approved.

### `design/notes/` — analysis/ingest notes feeding the design
- `design/notes/ratified-model.md` — **RATIFIED canonical model** (Gate 1, human-approved 2026-07-05): gateway→active-route→four-tier chain + binding rules + glossary. Role: ratified-model. Status: **RATIFIED** — the authority `design.md`/`spec.md` derive from. **[Tier-1 keep]**
- `design/notes/input.md` — verbatim original stakeholder ticket + owner clarification. Role: stakeholder-input. Status: canonical/immutable, highest authority. **[Tier-1 keep]**
- `design/notes/routing_unification.md` — core structural proposal: remove the overlay gate so the input widget is a universal terminal sink. Role: analysis-note. Status: foundational; superseded-in-detail by the ratified model (origin of ruling 1).
- `design/notes/routing_unification-revalidation.md` — E29 Stage-1 verdict table revalidating every `routing_unification` claim against the platform; "no core claim falsified." Role: analysis-note. Status: header NOT YET; Gate-1 evidentiary artifact.
- `design/notes/solution_sketch.md` — high-level implementation approach (keys_pressed table, singleton controller, three-level dispatch) feeding design.md. Role: analysis-note. Status: processed; largely superseded by ratified model, structurally influential.
- `design/notes/decisions-record.md` — authoritative per-decision rationale D-1…D-10 (Question/Context/Affects/Source/Decision). Role: analysis-note. Status: header NOT YET; body CONVERGED.
- `design/notes/decisions.md` — working analysis of decision suggestions feeding decisions-record. Role: analysis-note. Status: processed/historical.
- `design/notes/deferred-input-ergonomics.md` — one explicitly deferred non-blocking open question (show/configure/set_text split), parked at Gate 3. Role: analysis-note. Status: OPEN, deliberately deferred.
- `design/notes/concerns.md` — untriaged early technical risks (keypressed fully consumed; no mid-session update path). Role: analysis-note. Status: processed/historical.
- `design/notes/context_differences.md` — REPL/editor/project-overlay widget-usage comparison (informs D-2). Role: analysis-note. Status: processed.
- `design/notes/design.md` — ad-hoc early design ideas ("not decisions"), predating canonical design.md. Role: analysis-note. Status: superseded/historical.
- `design/notes/editor_repl_input.md` — current REPL/editor input architecture (supports FR-11/FR-12, D-7). Role: analysis-note. Status: processed.
- `design/notes/enter_escape_routing.md` — how Enter/Escape route through all four contexts today (the `oneshot` flag + its planned removal). Role: analysis-note. Status: processed.
- `design/notes/event_delegation_chain.md` — current keyboard delegation chain across the four mutually-exclusive contexts. Role: analysis-note. Status: processed.
- `design/notes/event_routing.md` — LÖVE keypressed-vs-textinput taxonomy + OS co-occurrence (informs D-3/D-6). Role: analysis-note. Status: processed.
- `design/notes/love2d_handler_layers.md` — LÖVE's two-level handler architecture (`love.handlers.*` vs `love.*`) and Compy's override. Role: analysis-note. Status: processed.
- `design/notes/textinput_routing.md` — the parallel `love.textinput` routing path (Ctrl+Shift filter, unconfigured-singleton guard). Role: analysis-note. Status: processed.
- `design/notes/requirements.md` — working notes clarifying formal requirements (educational-platform framing, GC/allocation principle). Role: analysis-note. Status: processed, feeds requirements.md.
- `design/notes/index.md` — ingest-tier index for `notes/` (raw input + analysis notes, all "Processed? ✓"). Role: process-artifact/analysis-note. Status: header NOT YET; functionally current.
- `design/notes/plan.md` — early sequencing plan for the analysis/design artifact chain (references renamed docs). Role: process-artifact. Status: superseded/historical.

### `design/notes/input/` — round-2 stakeholder-input processing
- `design/notes/input/stakeholder2_notes.md` — raw round-2 (SR2) stakeholder feedback (backward-compat, second-setup-call blocking, naming, keys_pressed indexing). Role: stakeholder-input. Status: raw ground truth, processed.
- `design/notes/input/stakeholder2_structured.md` — SR2 feedback re-ordered with D-number annotations. Role: stakeholder-input. Status: processed.
- `design/notes/input/summary00.md` — plain-language SR2 summary for stakeholder consumption. Role: stakeholder-input. Status: historical, processed.
- `design/notes/input/impact_outline00.md` — scopes what SR2 touches across the chain (CHANGE/CLARIFY/CONFIRM tags). Role: stakeholder-input. Status: historical, superseded by track00.
- `design/notes/input/track00.md` — line-by-line application log of SR2 changes C1–C7. Role: stakeholder-input. Status: historical/complete.
- `design/notes/input/evaluation00.md` — round-2 coherence check across the chain ("Consistent"). Role: stakeholder-input. Status: historical, processed.

### `design/spec/` — per-milestone specs
> **Supersession map:** live implementation targets are `M5c-dispatch-chain.md` (replaces
> M5.md, M5-01-split.md, M6.md), `M7-02-recut.md` (replaces M7.md, folds in M7-01), and
> `M8-02-recut.md` (replaces M8.md, folds in M8-01) — all **Gate-3 CLOSED / frozen 2026-07-07**.
> `M4-0-characterization-net.md` → superseded by `M4-0-01-front-tests.md` → shape folded into
> the still-unblessed `M4-0-03-contract-suite.md`. M1/M2 family appear already-landed.

- `design/spec/M1.md` — `Controller.keys_pressed` (live held-key table) + `combo_string` helper. Role: spec. Status: header NOT YET; later specs treat M1 as landed.
- `design/spec/M2.md` — extract `UserInputController` into a startup singleton (`compy.input.show/hide`). Role: spec. Status: header NOT YET; corrected by M2-01 (design slice stays frozen).
- `design/spec/M2a.md` — M1-review hygiene: drop dead profiler stub, collapse duplicated modifier-fold into `util/key.lua`. Role: spec (cleanup slice). Status: header NOT YET; zero-behaviour-change.
- `design/spec/M2-01-restore-mvc.md` — corrective: restore full `{M,C,V}` overlay handle + empty-on-fresh-prompt (M2 take-1 regressed both). Role: corrective spec. Status: header NOT YET; corrects commit 2245aa5.
- `design/spec/M2-02-submit-path-test.md` — test-only slice exercising the real oneshot submit path (closes C-2 gap). Role: test spec. Status: header NOT YET; forbids touching prod code.
- `design/spec/M4.md` — introduce `ProjectInputController`, remove the `if user_input` overlay gate. Role: spec ("largest integration step"). Status: header NOT YET; reworked test-first (M4-0-01), ultimately absorbed by M5c.
- `design/spec/M4-0-characterization-net.md` — original M4-precondition characterization net + harness ext. Role: precondition/test spec. Status: **SUPERSEDED** by M4-0-01-front-tests (kept as record of rejected approach; harness Part A survives).
- `design/spec/M4-0-01-front-tests.md` — corrective: small routing-level "front-tests" suite. Role: corrective test spec. Status: header NOT YET; supersedes characterization-net; later folded into M4-0-03.
- `design/spec/M4-0-03-contract-suite.md` — restructure the suite top-down from the `notes/input-contracts.md` contract record. Role: test-architecture spec. Status: **blocked draft** — "STOP for owner blessing", NOT YET.
- `design/spec/M5.md` — three-level keypressed dispatch + independent textinput channel + `compy.input.handlers` machinery. Role: spec. Status: header NOT YET; **superseded as impl target** by M5c.
- `design/spec/M5-01-split.md` — resequencing: split M5 into M5a (callbacks) + deferred M5b (`handlers[combo]` sugar). Role: decision spec. Status: **Approved YES (session 23)**; superseded as impl target by M5c.
- `design/spec/M5c-dispatch-chain.md` — **consolidated E29 re-cut**: four-tier dispatch across keypressed/textinput/keyreleased + submit/cancel chains + widget outputs + route restoration. Explicitly supersedes M5.md, M5-01, M6.md. Role: impl spec (largest, 32 KB, most authoritative). Status: **Approved YES — Gate 3 CLOSED, frozen 2026-07-07**. **[Tier-3 keep]**
- `design/spec/M6.md` — named submit/cancel chains, `framework_handlers` return/escape ownership, delete `oneshot`, extend `is_at_limit`. Role: spec. Status: header NOT YET; **superseded as impl target** by M5c.
- `design/spec/M6-01-oneshot-snapshot.md` — remove dead `self.oneshot` snapshot field from `UserInputView`. Role: housekeeping slice. Status: header NOT YET; target moved with M6→M5c.
- `design/spec/M6-02-before-exit.md` — new `compy.before_exit()` lifecycle hook (restore native LÖVE state e.g. key-repeat). Role: spec. Status: **Approved YES (session 23)**; NOT in M5c's supersede list — appears to stand as a separate approved target.
- `design/spec/M7.md` — extended singleton API: `configure()`, `clear()`, 2D cursor accessors, `set_text()`. Role: spec. Status: header NOT YET; **superseded** by M7-02-recut.
- `design/spec/M7-01-retarget.md` — F-5 boundary: can an active session be re-targeted via `configure()`? Default Option B (forbid). Role: decision slice. Status: header NOT YET; **folded into** M7-02-recut.
- `design/spec/M7-02-recut.md` — Gate-3 re-cut of M7 (configure/clear/cursor/set_text), depends on M5c, folds in M7-01. Supersedes M7.md. Role: impl spec. Status: **Approved YES — Gate 3 CLOSED, frozen 2026-07-07**. **[Tier-3 keep]**
- `design/spec/M8.md` — remove five legacy text-input globals + migrate in-repo examples. Role: spec (terminal milestone). Status: header NOT YET; **superseded** by M8-02-recut.
- `design/spec/M8-01-dead-text-input.md` — one-line cleanup: remove dead `compy_namespace.text_input` alias. Role: housekeeping slice. Status: header NOT YET; **folded into** M8-02-recut.
- `design/spec/M8-02-recut.md` — Gate-3 re-cut of M8 (legacy removal/migration), depends on M5c + M7-02, folds in M8-01. Supersedes M8.md. Carries a **"REVALIDATE AT COMMISSIONING"** caution. Role: impl spec. Status: **Approved YES — Gate 3 CLOSED, frozen 2026-07-07**. **[Tier-3 keep]**

### `design/` snapshots & prompts (summarized as directories)
- `design/prompts/` — **process-artifact** dir, **12 files** (`prompt.md`, `prompt3.md`–`prompt13.md`): design-session prompts driving the lifecycle. Not individually indexed.
- `design/design.versions/` — historical snapshots of `design/design.md` — **2 files** (superseded by canonical `design/design.md`).
- `design/estimates.versions/` — historical snapshots of `design/estimates.md` — **4 files** (superseded by `design/estimates.md`).
- `design/spec.versions/` — historical snapshots of `design/spec.md` — **2 files** (superseded by `design/spec.md`).
- `design/status.versions/` — historical snapshots of `design/status.md` — **2 files** (superseded by `design/status.md`).
- `design/status/archive/README.md` — explains the frozen audit-trail dir (`validation/` VR1 FAIL→VR2/VR3 PASS; `reevaluations/` round-1 episode). Role: process-artifact. Status: frozen, "do not edit."
- `design/status/archive/reevaluations/` — round-1 reevaluation snapshots — **4 files** (round1, check1, changes1, outcome1).
- `design/status/archive/validation/` — internal validation-round snapshots — **7 files** (validation_report_1–3, recommendations_1–2, changelog_1–2).

---

## `notes/` (topic-level notes — outside both structured chains)

### `notes/` (top-level)
- `notes/input-contracts.md` — canonical current-behaviour input-routing contract record (outcome-vs-mechanism framing); self-nominated promotion candidate for `internals/`. Role: analysis-note. Status: header NOT YET; current/canonical of its family. **[Tier-2 keep]**
- `notes/input-contracts-inventory.md` — verified factual inventory (P1) of today's keyboard/text/mouse/touch routing, every claim cited file:line. Role: analysis-note. Status: NOT YET; factual basis for the contract record.
- `notes/input-contracts-revalidation.md` — cold independent revalidation (P3): "sound after listed corrections." Role: analysis-note. Status: NOT YET; corrections to land before promotion.
- `notes/input-contracts-correction.md` — provenance correction fixing two mislabeled PRESERVE invariants found by the intent-fidelity audit. Role: analysis-note. Status: "active — STOP for owner blessing".
- `notes/input-routing-model.md` — draft mental-model contrasting widget-centric vs route-centric dispatch. Role: analysis-note/design. Status: explicit DRAFT, "NOT yet a contract".
- `notes/input-suite-validation-map.md` — row-by-row map from the contract record to `input_contracts_spec.lua`. Role: analysis-note. Status: NOT YET.
- `notes/intent-fidelity-audit.md` — cold audit of whether the derived design chain faithfully encodes stakeholder intent vs drifting into mechanism. Role: analysis-note. Status: active; triggered the correction doc.
- `notes/retro-contract-provenance.md` — standing methodology retro ("who decided this must hold?"). Role: analysis-note. Status: explicit `status: reference` — cross-cutting SDLC lesson. **[Tier-4 keep]**
- `notes/late-input-register.md` — traceability index of post-session stakeholder inputs (SR2/SR3) and where absorbed. Role: process-artifact/analysis-note. Status: active.
- `notes/m4-0-04-safety-net-review.md` — review of the M4-0-04 prompt + contract record against session findings; triages inline `-- REVIEW:` comments. Role: analysis-note. Status: NOT YET.
- `notes/plan-reevaluation-against-session-findings.md` — critical re-eval of plan vs session findings ("mostly holds, 4 issues"). Role: analysis-note. Status: NOT YET.
- `notes/plan.md` — feature-level plan for the "safety net" characterization phase (distinct from the milestone roadmap). Role: process-artifact. Status: session-31 snapshot, superseded in-progress by later commits.
- `notes/design-method-process.md` — informal notes mapping old artifacts to a proposed SDLC-shaped redesign. Role: process-artifact. Status: draft/informal, superseded by formal enrollment decisions.
- `notes/future-input-layer-refinements.md` — parked side-note on future input-layer ingest refinements. Role: process-artifact. Status: explicitly "Parked, not for now".

### `notes/assessment/` — cross-component codebase investigations
- `notes/assessment/cursor-and-reset-operations.md` — cursor/reset APIs across console/editor/search/project vs FR-8/FR-9; finds API-surface gaps. Role: analysis-note. Status: NOT YET.
- `notes/assessment/fr2-fr6-fr7-provenance-and-gaps.md` — stakeholder provenance of FR-2/FR-7 + FR-6/FR-7 code gaps. Role: analysis-note. Status: NOT YET.
- `notes/assessment/inspect-mode-current-state.md` — from-scratch read of the `inspect` app-state (two distinct "input widget" concepts). Role: analysis-note. Status: investigative baseline, no marker.
- `notes/assessment/keypressed-vs-textinput.md` — how console/editor keypressed vs textinput divide labor; feeds a correction to `internals/user_input.md`. Role: analysis-note. Status: NOT YET.
- `notes/assessment/keyreleased-isrepeat-events.md` — keyreleased routing + isrepeat + text assembly; finds a real gap (editor/search never receive keyreleased). Role: analysis-note. Status: NOT YET.
- `notes/assessment/shared-input-widget-singleton.md` — whether the four contexts should share one reconfigurable `UserInputController`. Role: analysis-note. Status: NOT YET.

### `notes/migration/`
- `notes/migration/process-evaluation.md` — reconstruction/evaluation of the predecessor ad-hoc process vs canonical SDLC, prep for enrollment. Role: migration-note. Status: intermediate/draft; precursor to `talk/session-decisions.md`.

### `notes/stakeholder-3-input/` — stakeholder-3 (SR3) input
- `notes/stakeholder-3-input/assessment.md` — E20 assessment of whether SR3 pains + maze/keyboard examples alter design direction. Verdict: direction holds. Role: stakeholder-input. Status: active; resolved at E9 (session 20).
- `notes/stakeholder-3-input/compy-input-quirks.md` — catalogue of Compy IDE input quirks (event order, key-repeat, chords, no exit-cleanup) + platform fixes. Role: stakeholder-input. Status: active, developer-facing reference. **[Tier-2 keep]**
- `notes/stakeholder-3-input/compy-lua-game-patterns.md` — Lua design-pattern/recipe guide for Compy games (skeleton, draw decomposition, helper dispatch). Role: stakeholder-input. Status: active. **[Tier-2 keep]**

### `notes/talk/` — materialized chat insights
- `notes/talk/two-tier-test-strategy.md` — human-settled two-tier test strategy (M4-0 safety net vs per-milestone test-first); corrects `m3-revival-tdd-for-m4.md`. Role: ratified-model/process-artifact. Status: "Decisions settled", authoritative. **[Tier-4 keep]**
- `notes/talk/keys-pressed-no-modifier-privilege.md` — standing stance: modifiers are ordinary keys, combo strings are sugar not source-of-truth. Role: ratified-model (design stance). Status: active from outset.
- `notes/talk/ratified-model-remarks-analysis.md` — analysis + proposed resolutions of 11 Gate-1 REVIEW remarks (R1–R11) on the ratified model. Role: analysis-note (central, larger). Status: NOT YET; "rulings pending — model stays unratified until each resolved".
- `notes/talk/api-demo.md` — developer-facing sketches of consuming `compy.input.*` (show/after_submit/before_exit/handlers). Role: analysis-note. Status: "Draft — API surface not yet shipped" (likely superseded by shipped usage guide `ced38bd`).
- `notes/talk/implementation-orchestration-model.md` — two-plane process model: orchestration (brainlab/Opus) vs execution (throwaway agent sessions). Role: process-artifact/ratified-model. Status: decided, in force.
- `notes/talk/build-continuity-vs-product-bc.md` — decision distinguishing withdrawn "shipped product BC" from in-force "build-time continuity". Role: analysis-note (decision). Status: standing rule.
- `notes/talk/safety-net-as-characterization-replan.md` — re-plan reframing the M4 safety net as formal black-box characterization + definition-of-done. Role: analysis-note (decision). Status: supersedes earlier framing; actionable form in `notes/plan.md`.
- `notes/talk/session-decisions.md` — SDLC-enrollment session decisions (topic-as-mount, binding location, assessment→context rename, two chained lifecycles). Role: process-artifact. Status: human-ruled; some items deferred.
- `notes/talk/session23-insights.md` — session-23 architecture insights (overlay test-coverage collapse accepted; maze API→show/after_submit). Role: analysis-note. Status: settled for that session.
- `notes/talk/sdlc-provenance-and-layered-pipelines.md` — attestation that canonical SDLC was generalized from #77's proto-method + layered-pipelines insight. Role: process-artifact. Status: NOT YET; durable record.
- `notes/talk/mvp-assessment-and-editor.md` — session-23 assessment: was design refinement necessary vs MVP overhead? Verdict: unavoidable. Role: analysis-note. Status: verdict, no marker.
- `notes/talk/m4-pushback-rulings-and-provenance.md` — architect's answers to 5 M4-pushback questions + traces "replace-the-sink" to a same-commit contradiction. Role: analysis-note. Status: NOT YET.
- `notes/talk/e31-m5c-suite-sequencing-contradictions.md` — escalation ledger of two M5c/suite contradictions found at cold revalidation (E31). Role: analysis-note. Status: escalated to E32; Gate-3 left open.
- `notes/talk/m5c-suite-reconciliation-open-contradictions.md` — ledger of two unsettled M5c acceptance-criteria contradictions. Role: analysis-note. Status: open, escalated.
- `notes/talk/codeinspect-harness.md` — build justification + resolved architecture for the single-container MCP-LSP harness (supersedes a multi-container blueprint). Role: analysis-note (infra decision). Status: build commissioned, pending smoke-test.
- `notes/talk/mcp-lsp-adherence.md` — why Sonnet skips the MCP-LSP tool (adherence not capability). Role: analysis-note. Status: NOT YET.
- `notes/talk/mcp-lsp-tooling.md` — per-agent-role assessment of MCP-LSP value; recommends adoption (E17). Role: analysis-note. Status: NOT YET; wiring superseded by `codeinspect-harness.md`.
- `notes/talk/m3-revival-tdd-for-m4.md` — proposal to revive M3 as a TDD net before M4. Role: analysis-note. Status: **"Superseded in part (session 12)"** — core claim wrong; kept as originating analysis.

---

## `implementation/` (unmanaged black-box execution ledger)

### `implementation/` (top-level)
- `implementation/README.md` — the black-box model (prompt→agent→outcome→review) + escalation rule + prompt template + M0–M4 milestone index. Role: process-artifact[status]. Status: NOT YET; index table stale past M4.
- `implementation/M5c-chunk-plan.md` — PM plan carving M5c into 5 gated chunks, validated vs frozen M5c spec. Role: process-artifact[status]. Status: chunks landed since writing.
- `implementation/M7-chunk-plan.md` — PM plan carving M7 into 2 chunks (cursor-text, reconfigure-boundary). Role: process-artifact[status]. Status: session-04 plan.
- `implementation/M8-chunk-plan.md` — PM plan carving terminal M8 into 3 chunks + one design ruling (delete undocumented `astv_input` global). Role: process-artifact[status]. Status: session-05 plan; all chunks landed since.
- `implementation/review-prompt.md` — reusable Opus reviewer bootloader (verify spec compliance vs diff, re-run tests, maintain the debt ledger). Role: process-artifact[review] (template). Status: NOT YET; in continuous use.
- `implementation/technical_debt.md` — feature-scoped interim debt ledger (M2→M8-03, many items struck as closed; several open/anticipated). Role: process-artifact[status]. Status: actively maintained; some items still open.

### Process-bulk directories (summarized, not per-file)
- `implementation/prompts/` — **process-artifact[prompt]**, **48 files**: one self-contained task prompt per milestone/chunk handed to black-box agents. Families: M0; M1; M2 (+M2a, M2-01, M2-02); M4-0 sub-suite; M4; M5c sub-suite (M5c-01…05 + reviews); M7 sub-suite; M8 sub-suite (incl. M8-01-resume); input-contracts-01…04; plus two sweep mandates.
- `implementation/outcomes/` — **process-artifact[outcome]**, **24 files**: per-milestone outcome ledgers (commit refs, verification, gaps), mirroring prompts/. Families: M0–M2a, M4-0 sub-suite, M4, M5c-01…05 (incl. 02c-corrective), M7-01/02, M8-01/02/03.
- `implementation/reviews/` — **process-artifact[review]**, **23 files**: independent review verdicts per chunk. Human-in-the-loop reviews (notable): `M2-human-review.md`, `M4-0-human.md`. Families: M1-01, M2 family, M4-0 sub-suite, M5c-01…05 (incl. 02c), M7-01/02, M8-01/02/03.
- `implementation/sessions/` — **process-artifact[session]**, **5 subdirs × 2 files = 10** (session01–05, each `prompt.md` + `track.md`): session-managed work logs. `session05/track.md` is **COMPLETE** — records "★ THE #77 NEW-INPUT-API SWEEP IS COMPLETE ★" (M5c/M7/M8 all landed + reviewer-approved, final suite 808/0/0/4), no session06. Its "what remains for the human" punch list flags non-blocking items (interactive hand-play verification, an unpushed balloons commit, an uncommitted maze patch).

### `implementation/docker/` — containerized black-box agent environment
- `implementation/docker/README.md` — the single `codeinspect` container: 3 interchangeable CLIs (claude/cursor-agent/agy) + stdio Lua LSP bridge + reindex/build notes. Role: process-artifact (infra doc). Status: reference.
- `implementation/docker/src/agent/orientation.md` — seeded agent operating instructions (rule-chain pointers, grep-vs-LSP guidance, `sleep 1` reindex caveat) — mirrors this session's orientation. Role: process-artifact. Status: reference.
- Non-markdown infra (not indexed as docs): `compose.yml` (has uncommitted local diff — pre-existing, not this feature's), `.env`, `src/agent/mcp.json`, `src/agent/Dockerfile`.

### Empty / non-doc
- `implementation/notes/` — empty, `.gitkeep` placeholder only.
- `implementation/ses/` — see §Flags (binary `SWEEP.tgz`).

---

## `entrypoints/` (ratified decision records)
- `entrypoints/E4-restructure.md` — resumable action-chain to restructure `design/` into canonical SDLC shape (consolidate notes, split decisions into status.md, archive round-history, rename assessment→context, slice specs). Role: migration-note. Status: **Approved YES**; all steps done.
- `entrypoints/E9-architect-call.md` — architect-call decision record resolving forward-path questions ahead of M4 (commission M4-0, confirm two-tier test strategy, dispatch semantics, combo-repeat keying, overlay-flag contract A5, project-hook leak A1/P4). Role: ratified-model (decision record feeding later specs). Status: items human-ratified.

---

## `reviews/` (root-level cold review passes)
- `reviews/input-contracts-correction.md` — cold review of the prompt12 correction to `input-contracts.md` + M4-0-03 for provenance honesty. Role: process-artifact[review]. Status: **APPROVE** with 3 minor non-blocking findings.
- `reviews/m4-architect-pushback.md` — large root-cause analysis classifying ~57 architect `REVIEW:` remarks on M4 (no implementor hallucination; divergence = unratified corpus + evolved mental model); proposes 5-step resolution. Role: analysis-note. Status: header NOT YET, but Addendum records all 5 Step-1 questions ruled same session — this is what produced the M5c/M7/M8 re-derivation.
- `reviews/m5c-m8-corpus-validation.md` — cold pre-Gate-3 validation of the re-derived M5c/M7-02/M8-02 corpus vs the ratified model (found convergent; M4 absorbed by M5c), but surfaced ONE stop: `input_contracts_spec.lua` carried a stale invariant contradicting AC-31. Role: analysis-note/review. Status: fix APPLIED same session per Addendum; awaiting M5c re-review, Gate-3 not yet flipped at write time.

---

## Flags for the reviewer (anomalies / non-doc content)

- **`reviews/synthetic-system-diff.patch`** (302 KB) + **`reviews/synthetic-diff-manifest.md`** (10 KB) —
  created **mid-review** (2026-07-12), apparently by a **concurrent sibling task**, not part of the
  original 253-doc corpus. The patch is the shipped system change (baseline `3256aac` → HEAD `ced38bd`,
  wip dir excluded, LLM-header-only files stripped); the manifest is its auditable reproduction record.
  **Most faithful record of what the feature actually changed** — useful for cross-check, but a diff, not a doc to incorporate. The manifest references a shipped **usage guide** commit that likely supersedes `notes/talk/api-demo.md`.
- **`implementation/ses/SWEEP.tgz`** (~29 KB) — **root-owned** binary tar archive (anomalous: all other
  files are `agent`-owned) sitting in a doc tree. Provenance/content unclear from the directory; not extracted.
- **`implementation/docker/compose.yml`** — carries an uncommitted working-tree diff flagged as pre-existing
  / not-this-feature's; worth a glance before deleting the tree.
- Numerous specs/notes carry `Approved by human? NOT YET` in their headers despite downstream evidence of
  landing — treat header-status as advisory, body/Gate markers as authoritative.
