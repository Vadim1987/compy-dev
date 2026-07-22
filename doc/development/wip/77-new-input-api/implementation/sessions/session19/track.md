# session19 — track

## Boot (2026-07-21)
- Read validation.md flow + agents/sessions.md. Boot ritual done.
- HEAD `7a2cd8d` (session18 wrap). Tree: untracked scratch only (sanctioned anomalies per
  validation.md §Hard guardrails); no staged/modified tracked files.
- Re-entrance guardrail: session19/ has only prompt.md → **fresh start**. Track opened here.
- Baseline suite: **841 / 0 / 0 / 4** — matches prompt. 4 pendings intentional.
- Predecessor session18: Phase R CLOSED + owner-accepted (`affc932`), R3 fold-in done,
  post-R reconciliation discharged. Read report.md.
- Carryovers noted: (1) LSP was unreliable all S18 — grep is ground-truth backstop until
  re-verified; (2) post-R replan carryover FIRED+retired, do not copy forward.

## Task this session
Phase TF2 — owner's human review of the split input suite (interactive, OWNER-GATED, never
start unprompted). Record every owner hint to validation/notes/. No fixing mid-review (TF3
triages). Then TF3, then owner-confirmed collapsed B→C→D.

## TF2 kickoff (2026-07-21)
- Owner workflow: reviews the split specs **out-of-band, injecting inline `-- REVIEW:` notes**;
  pings me with codebase/purpose questions + concerns to discuss. My job: answer against the
  validated persistent docs, record each hint to validation/notes/, NO mid-review fixes (TF3).
- **Not a cold start:** split files already carry owner inline `-- REVIEW:` notes from the
  session15 pre-R TF2 pass (commit `34cf318`). Phase R reshaped some files since, so some notes
  may be stale/addressed — TF3 triage sorts that.
- **Scope ruling (owner): ALL 12 files** = 9 TF1-split (input_events, input_widgets_callbacks,
  input_reconfigure, input_nfr_forward, input_routing, input_route_lifecycle,
  input_widget_lifecycle, input_cursor_text, input_shortcuts_click) + project_open_liveness
  (fixture precursor) + input_lifecycle_unfork + input_redesign_ac (R-era). Shared fixture:
  tests/input/input_fixture.lua.
- Delivered the file list (table w/ purpose+LoC). Owner now reviewing out-of-band.

## REVIEW-marker inventory directive (owner, 2026-07-21)
Owner redirect BEFORE fresh TF2 read: too many old REVIEW markers (owner counted ~106) to
re-evaluate cold. Directive:
1. Build **persistent (until PR) committed inventory** of REVIEW markers across tests/+doc/+src/;
   periodically updated.
2. Then sweep genuinely-dissolvable ones, presented in **batches ≤10** carved on file/logical
   boundaries, owner-gated per batch.
3. Update inventory after each sweep.
4. Then triage remaining ones in batches.
- Rationale: mechanical validation/cleanup = LLM sweet spot w/ stop-at-human-gate; the ≤10-batch
  interactive mode may become the standard shape for other triages too.
- **This IS TF3-shaped work pulled forward + merged with TF2** (plan allows "ruled in same sitting").

### Scope finding (evidence-backed)
- Genuine actionable universe = **56 `-- REVIEW:` inline comments in OUR .lua: 34 tests/ + 22 src/**.
- doc/ has 205 REVIEW: hits but ~all are PROSE CITATIONS in narrative/frozen/pr-slice records
  (wip/77 = 202, dies at PR); persistent corpus has 0 genuine markers (technical_debt/input.md's 3
  are prose about markers). src/ FIXME all vendored metalua (not ours).
- Decision: inventory the 56. **Owner confirmed 2026-07-21: EXCLUDE wip/ entirely** (citation
  noise / historical trail). So scope = tests/ + src/ own-code markers only.
- History check: NO resolution-prune pass ever ran; markers carried verbatim thru TF1 split
  (net-0 move), only 1 incidental drop in R4 f1050d8. All still on owner disposition.

### COUNT CORRECTION (owner pushback, 2026-07-21) — CRITICAL
My `grep "REVIEW:"` (colon-only) UNDERCOUNTED badly (56). Owner's markers use a TAXONOMY:
`REVIEW:`, `REVIEW/clarity:`, `/fidelity:`, `/DOC:`, `/cosmetic:`, `/nitpick:`, `/consistency:`,
`/terminology:`, `/RESPONSE:`, `/OPEN`, compounds `/clarity/consistence:` etc.
- **True detector = `REVIEW[:/]`. True universe = 138 (114 tests + 24 src).**
- Owner's own `grep -rni review` gave 83 src/123 tests but that's case-insensitive w/ false
  positives (preview, review-doc citations, example-game prose "review level"). Real = 138.
- 2 uppercase-REVIEW non-markers excluded: routing_spec:13 (header), input_fixture:128 (removed-note).
- Kind-suffix captured as bucketing signal (cosmetic/nitpick/clarity lean dissolve; fidelity/DOC/
  consistency/architecture lean triage).
- Lesson: verify marker pattern against owner's actual taxonomy before scoping. Owner was right to
  be suspicious of the small counter.

### Delegation
Inventory build → Sonnet worker (mechanical, explicit model). Prompt: validation/prompts/
S19-review-marker-inventory-worker.md (updated w/ corrected pattern+counts+Kind field).
Output: validation/notes/review-marker-inventory.md. Worker relaunched-in-place via SendMessage
with corrected scope (was mid-run on wrong 56-pattern).

### Inventory built + Batch 1 done (2026-07-21)
- Inventory committed `b9c2bfb` (138 markers, 6 DISSOLVE?/132 TRIAGE, RVW-001..138, Kind, per-file).
  Worker matched 114+24 exactly; verified RVW-045/127/121 against code myself. 2 multi-line markers.
- **Batch 1** (tests/ dissolvables) committed `fb9e67b`, suite 841/0/0/4:
  - RVW-045 removed (empty body); RVW-064 removed remark + extra ----/------- banner dashes
    (owner: strip decoration, keep label+ref; leaves banner lighter than siblings — owner-directed);
  - RVW-010 replaced by ref to consoleController.lua#run_user_code (owner corrected file: it's
    consoleController not controller; run_user_code:108 calls set_user_handlers — the real path).
    Owner rule: reference by FUNCTION NAME not line (drift). Verified target exists.
- **tests/ DISSOLVE? bucket now EXHAUSTED** (3 done). Remaining 3 dissolvables (RVW-121/123/127)
  are src/ = PARKED.
- Next: TRIAGE phase over 111 remaining tests/ markers in ≤10 batches. NB cross-cutting theme
  clusters exist (vocabulary/terminology rename RVW-033 etc.; console-hidden-sink security Q;
  .on_*→.hooks[] API-syntax Q) — should be ruled as themes, not purely per-marker.

### Triage carve (owner: theme-first; delegate walkthrough to Sonnet, 2026-07-21)
Owner wants: Opus CARVES (judgment) + attaches recommendations; Sonnet runs the walkthrough as
secretary (cites annotations, applies rulings) to save Opus tokens. Owner: "carve, then decide
[runner mode]." Runner-mode Q deferred until carve seen.
- **Carve committed `ae7e04e`**: validation/reviews/S19-tests-triage-plan.md. 111 open tests/
  markers → 4 GOVERNING decisions (rule first, collapse ~35):
  - D1 vocab (master RVW-033) — split D1a test-prose rename (safe now) / D1b production-symbol
    rename (defer, tie to src sweep + D2).
  - D2 .on_*→.hooks API-shape (master RVW-071) — rec DEFER as design-question (out of scope).
  - D3 console-hidden-sink SAFETY (master RVW-111) — rec DECIDE doc-first; I pre-research
    decisions/internals; highest-value, do NOT delegate the ruling. May surface a real design gap.
  - D4 testing-philosophy real-code-vs-mocks (fixture+mock_widget+shortcuts cluster) — pools with
    A2's 2 standing fixture-arch Qs (wrap-native helper; play-mode fixture). Rule principle once.
  - Mop-up themed ≤10 batches: B-E prose REWORD, B-F structural, B-COV coverage, B-I doc-hygiene.
  - PARKED (owner-owned in-progress): RVW-092/093/095 (badspecref/jargon/tags sweeps).
- Disposition vocab defined in plan (DROP/REWORD/RENAME/RESTRUCT/RELOC/COV/PROMOTE/DEFER/DECIDE/PARK).

### D1/D2 RULED + IMPLEMENTED (owner, 2026-07-21)
Owner posed a principle question spanning D1+D2: "we already ratified+implemented the API
shape / vocab unification — so why do these markers still stand?" Ground-truth check
(src + tests + decisions/input.md) answered per-term:
- **Substance already shipped:** `input.hooks[event]` / `shortcuts` / `widget` are ratified in
  `decisions/input.md`, implemented in `src/` (no `input.on_*` surface; no `sink`/`tier-3` in
  production), and driven by the specs. So NOT hyp-1 (unimplemented) and NOT hyp-3 (fake tests).
- **What lagged = janitorial:** stale REVIEW markers never wiped (hyp-5) + stale describe/it prose
  (hyp-4) + one test-local symbol `F.singleton` never renamed (hyp-2). `.callbacks.on_*` is a
  different layer (widget trigger-callbacks) already matching the ratified principle.
- Owner ruling: **ratify D1/D2 now, implement immediately; D3/D4/smaller clusters later** (D4 needs
  its own methodical pass — `native` vocab). Clearance = immediate.
- **Pass A** `46595d2`: mechanical `F.singleton→F.widget` symbol rename (78 lines/10 files, Sonnet).
- **Pass B** `e698309`: vocab prose reword (`sink`→widget, `tier-3`/`generic callback`→hook), rewrote
  shared ROUTE/WIDGET/SINK def block, unwrapped `{jargon:}` pointers whose content is now resolved
  (owner clarified: those tags are sweep-support, remove when wrapped content resolved), dropped 12
  D1/D2 markers (RVW-033/028/034/037/052/056/059/063/066/069/071/081), updated inventory+plan.
- **RVW-073/077/079 DEFERRED→D4**: carve filed them D1/D2 but they're `native`/on_*-install
  entangled; native-install-path describe group left untouched. Suite 841/0/0/4 throughout.
- tests/ open markers now ~99 (was 114; −3 Batch 1, −12 D1/D2).

### D5/D6 opened — native + slot vocabulary (owner, 2026-07-21)
- **Baseline test settled it:** `git grep native/slot updev -- src` = **0** (native hits = vendored
  `nativefs` only). Both are feature-invented, self-ratified interim terms — NOT public contracts
  (public surface = `compy.input.hooks[event]`; `native` leaked only into private ids + comments;
  `slot` into comments + one private local). Owner's suspicion confirmed against baseline.
- **D5 RULED: `native`→`handler` (variant B).** Prose "the project's own love.* handler";
  ids `project_natives`→`project_handlers`, `*_native`→`*_handler`, `natives` param→`handlers`;
  keep `userlove`. ~74 lines (src ~21 / tests ~37 / docs ~16). Re-homes RVW-073/077 from D4→D5.
- **D6 RULED: dissolve `slot`** — it's overloaded (occupancy→`route`; assignable→`hook`/callback
  field). ~57 lines (src 10 / tests 28 / docs 19). Resolves src marker projectInputController:4.
- **REORDER (owner): run D5,D6 SOON, before D4,D3** — noise reduction for remaining review.
  Full rulings + census + per-file counts in reviews/S19-tests-triage-plan.md §D5/§D6.
- **Both touch src + ratified docs + tests together** (not tests-only) — sweep all three per cluster.
- **LSP re-verified:** OK for definition/diagnostics/local-fn refs; **BROKEN on cross-file method
  refs** (missed `pic:activate`). Grep = completeness authority; not a staleness/restart issue.

### D5 IMPLEMENTED — native→handler (owner option B, 2026-07-21)
- **Scope carve (owner FLAG-1 = option B):** the wrapper family `wrapped_native`/`chain_native`/
  `keyboard_native` + defining comment (`controller.lua:146-199`) is entangled with a design smell
  (duplicated guard; `keyboard_native` misnamed — nothing keyboard-specific; guard is load-bearing,
  NOT skippable → skipping seeds an always-erroring hook). **Carved OUT of D5** to a
  behaviour-preserving refactor filed in `technical_debt/input.md` §"Project-handler wrapping".
- **D5 applied (suite 841/0/0/4 throughout):** src `natives`→`handlers` (`seed_hooks`/`activate`
  params + `project_natives`→`project_handlers` + `@return`), ratified-doc prose (variant B: "the
  project's own love.* handler"; `pure-native`→`handler-only`), tests (native→handler; folded in the
  residual sink→widget + tier-3/on_*→hook that D1/D2 left in the deferred `native install path`
  group). LSP diagnostics clean on both src files.
- **Markers:** RVW-073/077 RESOLVED+removed; RVW-074/075 dejargoned + survive→D4; RVW-076/078/079
  survive→D4 (079 prose actualized). Inventory + triage-plan §D5 updated.
- **FLAG rulings:** FLAG-4 `restore_native_slots` → D6 (framework-defaults + occupancy sense, not
  project-handler); FLAG-5 `widget_lifecycle:171` kept (hardware-key sense); FLAG-2 non-issue
  (ragged-right list, no re-pad). Completeness grep: every remaining `native` is an intentional keep
  (carved family / vendored nativefs / D6-bound occupancy / surviving markers / FLAG-5).
- **Next: D6 (dissolve slot)**, then D4,D3. `restore_native_slots` + fixture:151 "Native slots" join D6.

### Sweep order (owner, 2026-07-21)
- Inventory = all 138 (tests+src) — kept, gives owner generic codebase-state read.
- **SWEEP tests/ first** (114 markers), several batches expected (input_events_spec=48 &
  input_fixture=16 each need multiple). src/ (24) inventoried but PARKED.
- **src/ sweep = deferred expansion**, owner CONFIRMS after tests/ swept (same-shape efficiency +
  pre-inspection codebase knowledge). Do not start src/ sweep unprompted.

### D6 IMPLEMENTED — dissolve `slot` (owner, 2026-07-21)
- **`dbeb491`**: `slot` dissolved contextually — occupancy sense → route vocab, assignable sense →
  hook/callback field. Ratified the hook/callback/handler taxonomy across src + docs + tests.
  Resolves src marker projectInputController:4. Suite 841/0/0/4.
- **`95e775f`**: new `internals/event_dispatch_layers.md` documenting the `love.handlers.*` (master
  dispatch table, shortcut logic) vs `love.<event>` (individual callbacks) two-layer split — the home
  for the D4 item-3 naming-collision (`setup_callback_handlers` vs `set_default_handlers`).
- **Governing tier now fully ruled+applied** (D1/D2/D5/D6). Only D3/D4 remain, both relocated (below).

## CONTEXT COMPACTED (2026-07-21→22) — big-plan reconcile
- Owner asked to reconcile (not review) validation/plan.md's four big phases [A/R, B, C, D] against
  current position. **Verdict: we are at the *beginning of TF2*.** R CLOSED+accepted (`affc932`); the
  S19 marker triage is an **improvised pre-TF2 noise-cleanup sub-step** the owner commissioned at TF2's
  opening to cut review noise — NOT standalone. Owner: "what we do *is* real work, in a different mode."
- **Owner mental model:** [A/R gate]=A+DI+TF+R (integrity+redesign), B=convergence, C=principle sheet,
  D=owner sitting. Collapse hypothesis: B/C/D collapse into one sitting IF the whole gate-ledger rules
  out with low residual risk — **gated on TF2/TF3**.

### D3 + D4 disposed (owner rulings, 2026-07-21) — `591b941`
- **D3 (console-hidden-sink safety) → RELOCATED to a new collapse-gate ledger**
  (`validation/notes/collapsed-gate-ledger.md`, row **G-1**, category (b), OPEN). It's a runtime
  design-safety ambiguity, not marker vocab — ruled in the collapsed sitting, NOT the marker lane.
  Markers RVW-107..112 stay in-tree pointing there.
- **D4 (testing-philosophy) → DEFERRED as a unit into TF2/TF3** — it IS the Test-Fidelity
  investigation; ruling it in the marker lane would rule it twice. The 3 fidelity items (fixture:150/
  :227 →TF2; naming-collision item 3) ride along. **Naming-collision left in-tree for the owner's own
  eyes during TF2 manual recheck** (owner: "not heavy") — explicitly NOT promoted to the ledger.
- Owner chose **Variant 1**: keep grinding mop-up batches; resort to manual check when they feel like it.

### B-E DONE — prose/clarity (owner-gated, one batch at a time)
- **E1 `c141d2b`** (7 markers) + **`b3bd3f9`** (RVW-023 evaluator-variant explanation): split-file
  header prose cleanup; renamed highlight_shape_spec → highlight_regression_spec. RVW-020/023 KEPT for
  TF2 eyeball.
- **E2 `aba6dad`** (8 markers): events + nfr it-desc/prose. RVW-075 KEPT for TF2. Two forward-flags
  planted: `REVIEW/concern` on "mutates nothing" ↔ ledger G-1 revalidation touchpoint; `REVIEW/recheck`
  on the fragile milestone ref. B-E fully processed (15 resolved, 3 kept for TF2).

### B-I/1 DONE — fixture doc-hygiene — `8bc066f`
- 6 markers: RVW-001/011 RESOLVED-moot (target prose already removed by D5's rewrite — verified gone);
  RVW-002 reworded (explain set_love_update / click-timer); RVW-005 `F.update`→`F.love_update` (def +
  4 call sites); RVW-004 dropped (speculative refactor, overlaps D4).
- **RVW-003 ESCALATED → collapse-gate ledger G-2** (category (b), OPEN). It exposed a real public-API
  coherence gap: **mouse** handlers are bare callbacks on `compy.<event>` (`compy.singleclick`, pulled
  via `get_compy_handler`, controller.lua:262/659/671); **keyboard/text** handlers are hooks under
  `compy.input.hooks[event]` seeded from `love.<event>` (seed_hooks, projectInputController.lua:42/108).
  Same act, two shapes — user confusion. Unifying seam (owner): make `compy.{single,double}click` a hook
  source too; caveat: mouse-side API unexamined in #77. In-tree echo: shortcuts_click:96 (RVW-101).
  Rename deferred until the gate rules the API shape. **G-2 = second category-(b) find from the sweep**
  (after G-1) — mild signal the collapsed sitting has real content.

### D1 leftover recorded (so it isn't lost)
- `input_routing_spec.lua:4-5` still carries the old `ROUTE=consumer … SINK=last consumer` block D1
  Pass B was meant to rewrite (RVW-034 overload); nfr_forward got it, routing was missed. **Folded into
  the B-I/2 batch note** in the triage plan (B-I/2 already edits that header via RVW-090/091/094).

## WRAP (2026-07-22)
- Owner directed a session wrap (session length), NOT task-complete: TF2 proper + remaining mop-up
  (B-I/2, B-F, B-COV) still pending. Successor = **continuation**, resume at B-I/2.
- My first wrap attempt (`086a66d`) mislabeled a lone triage-plan commit as "the wrap" — owner
  corrected: track not updated, no report, no successor prompt. This is the real wrap ritual.


