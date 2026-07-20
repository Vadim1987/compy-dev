# session16 — track

## Boot (2026-07-20)
- HEAD `25b0475` (session15 wrap). Tree: guardrail-3 anomalies only (+ owner's
  `.input_nfr_forward_spec.lua.swp`, compose.yml diff — untouched).
- Baseline suite confirmed: **815 / 0 / 0 / 4** (`busted tests`).
- Re-entrance: fresh start (only prompt.md in session16/). Track opened now.
- Task per prompt.md: **Fable-led preliminary analysis + plan review** —
  pressure-test the redesign proposal (D6 layering seam, D10 precedence,
  loosened-D7 boundary, vocabulary consistency), then plan-revision for
  TF2-finish + redesign phasing.
- **Process note (owner, in-session):** Fable runs THIS session directly
  (main seat), not summoned as a subagent — owner wants iterative
  discussion over the topic and outcomes. "Commission Fable" step 2
  becomes in-session analysis; still materialized on disk per hygiene (c).
- Read: validation.md, sessions.md, s16 prompt, s15 report+track, plan.md,
  redesign proposal + evaluation, decisions/input.md (13 decisions).

## Pressure-test executed (in-session Fable) — 3 new code facts
- Grounding reads: projectInputController.lua (full), userInputController.lua
  (full), consoleController.lua:320-610 (compy.input surface + D7 metatable),
  controller.lua:200-320 (route wiring) + :860-990 (gateway pre-tap).
- **F1 (D6 seam):** two cancels coexist — UIC:cancel() (clear+hide, tier-1's
  callee) vs sink escape branch input:cancel() (model-only, clear-no-hide =
  the original bug's shape, alive at userInputController.lua:678-682). Widget
  default MUST be the UIC methods, never the sink editing branch. Console
  submit is route-owned too (consoleController.lua:1218) → middle step stays
  per-adopter config.
- **F2 (propagation):** NO parent dispatch exists; love.keypressed IS the
  route; global exit = gateway PRE-tap (controller.lua:874-984), runs BEFORE
  route, unshadowable. Proposal's "bubbles to parent" holds only under the
  modest reading (= existing D1/D11 routing); strong reading (per-event
  bubble) = new machinery + safety regression risk. Adopt modest, state it.
- **F3 (consumption signal):** UIC:keypressed return already means
  limit-flag (consumed at consoleController.lua:1209, editorController:493);
  cannot overload as "consumed". Rule: consumption = shownness decided at
  the dispatch step; widget return stays chain-meaningless (D5 stays true).
- F4 dropped no-shadow guarantee = named owner ruling; F5 D10 seed semantics
  must be chosen (lean: seed-by-copy at activation); F6 D7 loosening only
  works BECAUSE of restructure; callbacks table missing on_limit_reached/
  validator/highlighter → admit, define callback = "widget-invoked";
  F7 "widget" overloaded (console REPL UIC instance), hook→callback rename
  must be complete-or-nothing.
- Materialized: prompts/S16-fable-redesign-pressure-test.md (commission of
  record, notes in-session-Fable deviation), outcomes/S16-fable-redesign-
  pressure-test.md (verdict, F1-F7 + 5 delta-spec obligations + 4 test
  anchors), reviews/S16-plan-revision-post-redesign.md (DRAFT: TF2 unchanged
  + {redesign} tags, TF3 + absorbed-by-redesign bucket, redesign in-scope
  pre-PR via existing phases B/C/D/E with E-r1..r4 units).
- Verdict headline: SOUND, do pre-PR, under F2 modest reading + 5 obligations.
- Awaiting owner iteration (gate open; 4 pending rulings listed in the
  plan-revision draft).

## Iteration 1 (owner ⇄ Fable)
- Owner engages on F1/F2/F3 directly, with concrete counter-shapes —
  materialized as "Iteration 1" section appended to the outcomes file.
- **F2 confirmed:** tier-1 verified Enter/Esc-only (install_tier1) →
  invented solely for in-route Enter/Esc; remove code+tests; callbacks =
  direct exposure of widget's table with pre-populated defaults. Caveats
  accepted: teardown must RE-SEED defaults (reset_compy_input wipes today);
  "5 callbacks" leaves on_limit_reached/validator/highlighter membership
  open (F6); F4 ruling widens (overriding after_* = owning lifecycle).
- **F1 verified in devupstream:** pre-feature UIC:cancel = model-only
  (clear, no hide) — clear-only IS the old canon and the old bug; +hide is
  #77's addition. Owner sequence (before_cancel → clear → after_cancel
  w/ dismiss default) matches my read; correction: default after_cancel =
  hide only, NOT UIC:cancel() (double model:cancel otherwise).
- **F3: my blast-radius claim CORRECTED** — editorController:493 is
  SearchController (own jump contract), NOT a UIC consumer. Only live
  consumer = console history nav (:1209). Owner's redefinition (return =
  consumed universally; limit via on_limit_reached) SUPERSEDES my F3(a) —
  and is D5-purifying (limit result stops leaking via return). Dual
  channel verified redundant (vertical() sets flag AND fires emit_limit).
  Console tweak: instance on_limit_reached filtered to vertical dirs.
  Rule to pin: shown → consumed for EVERY key.
- Behavioral note (owner): thinks in default-value terms — guarantees
  become overridable defaults, uniformly; prefers deletion over parallel
  channels; asks for cross-surface impact before accepting.

## Iteration 2 (owner clarifying Q&A, 1.a-6.b) — all verified in code/design docs
- 1.a/1.b: gateway pre-tap confirmed pre-feature too (devupstream controller.lua
  ~528-622, same shape); today controller.lua:862/874.
- 2.a: before_cancel veto approved, mirrors already-reserved before_submit veto.
- 2.b: owner proposes flipping shared auto-close default OFF (stay open unless
  after_* explicitly hides) — verified as restoring pre-feature `oneshot` flag
  (devupstream userInputModel.lua), deleted outright by #77. Zero cost to
  console (never calls UIC:submit/cancel). Folded into obligation 2.
- 3.a: confirmed single-function console patch (consoleController.lua:1209).
- 4.a: verified NOT stakeholder-mandated — requirements.md:201-205 leaves
  cancel/dismiss notification explicitly unresolved by stakeholders;
  non-overridable shape was a design-team fix for the oneshot two-role problem
  (notes/enter_escape_routing.md:10-58), not external ask.
- 6.a/6.b: confirmed via full obligation-by-obligation pass — only obligation 3
  touches console/editor code; Decision-1 deferral undisturbed.
- **NEW finding (owner's migratability question):** roadmap.md:330 promised a
  SHARED dispatch() reusable by console/editor "later" — shipped `_dispatch` is
  actually a PIC method reading self.compy_input/self.natives, NOT reusable;
  promise is aspirational today. Redesign is a chance to deliver it for real:
  obligation 6 added — extract dispatch(handlers,hooks,widget,event,...) as a
  plain-table function, compy.input's guard becomes a thin wrapper over it.
  Zero cost now, folds into E-r1/E-r2.
- Materialized: outcomes file "Iteration 2" section; plan-revision doc's owner-
  rulings section now ALL CHECKED with final 6-obligation wording (supersedes
  original 5-item F-summary).
- **Owner ruling: ALL FOUR plan-revision gates now closed** — TF2/TF3 accepted,
  redesign pre-PR confirmed, 6 obligations accepted as delta-spec skeleton,
  E-r1..E-r4 ordering accepted. S16's core mandate (pressure-test + plan review)
  is substantively complete; remaining open thread is drafting the actual
  delta-spec document (next concrete step) then resuming TF2.

## Iteration 3 (owner clarifying question on obligation 6) — gap found + closed
- Owner asks: does "thin wrapper over shared dispatch" mean console/editor lose
  compy.input, get similarly-shaped access differently, or (risk to flag) ONLY
  dispatch becomes reusable while show/hide/configure/cursor/eval stay
  project-only? Verified: obligation 6 AS WRITTEN was the narrow/risk case —
  only dispatch was covered.
- Verified: compy is project-sandbox-scoped only (get_compy_namespace called
  solely at project-env-prep sites, consoleController.lua:732/834);
  console/editor already bypass compy entirely, hold direct UIC refs, call
  class methods directly (set_eval/clear/set_custom_status/etc) — capability
  was never gated by compy, only guarded FOR untrusted project code.
  get_compy_input's methods table (show/hide/get_cursor/set_cursor/set_text/
  configure/clear) hardwired to ONE global love.state.user_input_controller
  (main.lua:381) — confirmed exactly 4 UIC instances total (project overlay
  [published], editor input, editor search, console REPL), only project one
  reachable through that table.
- **Corroboration found:** main.lua:360 owner's OWN standing REVIEW note asks
  nearly the identical question ("why not rewire Console/Editor to use the
  same singleton?"). Resolved it: can't share ONE instance — console REPL
  state must persist independently through inspect mode (console route over
  paused project env, D12); one shared instance would clobber console's
  buffer. Multiple instances required; only the WRAPPER SHAPE should be
  shared, not the instance.
- Obligation 6 split: 6a = dispatch (as before), 6b (NEW) = parameterize
  get_compy_input's methods table into build_widget_api(widget) instead of
  reading the global. Both mechanical/zero-cost/zero-behavior-change, fold
  into E-r1/E-r2, no new phase.
- Materialized: outcomes file "Iteration 3" section; plan-revision doc
  obligation 6 rewritten as 6a/6b split.

## Deliverables round (owner request: delta-design, delta-spec, plan correction)
- Owner asks for 3 things + 2 meta-questions: (1) delta-design doc (decision-
  level, mirrors decisions/input.md voice), (2) delta-spec doc (mechanism-
  level, signatures/tables/acceptance criteria), (3) correct validation/
  plan.md — insert an iteration/execution phase before current Phase B (owner's
  framing: ran an informal "Phase B" in their head during TF2, found gaps,
  worked them out with me, now wants formal re-entry). Meta: (a) finish TF2/
  TF3 as-is, or redirect to an Opus markup sweep instead? (b) should this
  planning conversation happen in a cold session instead?
- Verified before answering: Phase A (A1/A2) + DI (DI1/DI2/DI3) both already
  COMPLETE (outcome files exist); TF1 done, TF2 mid-flight, TF3/B/C/D/E/F/G
  not started. 33 REVIEW: remarks counted in src/controller/*.lua alone.
- My answers: (meta-b) stay in this session — shared context, same open gate,
  sessions.md favors it. (meta-a) split the jobs — TF2 is owner JUDGMENT
  (test-quality smells, coverage gaps), not renaming; an Opus/Sonnet sweep is
  good for the MECHANICAL question (impact inventory of REVIEW remarks +
  rename targets) but shouldn't replace TF2. Recommend: run redesign
  EXECUTION first (new Phase R), THEN resume TF2 over the settled suite once
  (not twice), THEN TF3 with a near-empty absorbed-by-redesign bucket.
  (plan structure) insert Phase R between TF and B (same insertion pattern as
  DI/TF's own 2026-07-19 precedent) rather than deferring into generic B/C/D —
  reasoning: what happened in S16 already WAS a rigorously-ruled Phase-D-style
  sitting on one cluster, more thorough than a typical Phase-D row; deferring
  it would dilute rather than protect against smuggling.
- Delivered: reviews/delta-design-input-api.md (D2/D6/D7/D10 revised, D5
  touched, vocabulary table, "what stays the same" checklist, implementation-
  note appendix for 6a/6b, withdrawn-guarantee stakeholder-origin note).
  reviews/delta-spec-input-api.md (compy.input table shapes, dispatch()
  pseudocode, submit/cancel sequence w/ veto+default-flip, widget-api factory,
  hooks seeding algorithm, console patch, 10 tests-first acceptance criteria).
  Both marked PROPOSED pending R3 confirm-gate (substance already ratified
  in-session across iterations 1-3; this catches chat-to-prose wording slips).
- plan.md corrected: appended 2026-07-20 revision blockquote (PROPOSED,
  superseding the "S16=TF2+TF3" 07-19 layout note in place, not rewritten);
  new "### Phase R — Redesign" section inserted between TF and B (R1/R2 done,
  R3 confirm-gate, R4 execution w/ 8 sub-steps starting with the REVIEW-remarks
  Sonnet reconnaissance sweep, R5 = obligation 6a/6b extraction); Phase B's
  gate line amended to require R; TF2/TF3 bullets amended in place noting the
  reorder + shrunk absorbed-by-redesign bucket.
- Suite reconfirmed 815/0/0/4 (docs-only turn).
- Awaiting: owner sign-off on delta-design/delta-spec content + the plan.md
  Phase-R insertion (R3 gate). Once confirmed: kick off R4 execution
  (Sonnet REVIEW-remarks sweep first, per model economy — explicit model tag).
