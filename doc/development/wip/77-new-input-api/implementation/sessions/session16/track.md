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
