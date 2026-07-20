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
