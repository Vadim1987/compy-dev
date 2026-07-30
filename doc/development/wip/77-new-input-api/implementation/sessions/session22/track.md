# session22 — track

## 2026-07-29 — boot

- Booted per `agents/validation.md` and `agents/sessions.md`.
  Re-entrance guardrail: no prior `track.md` or `report.md` in
  `session22/` — fresh start; this entry opens the track.
- HEAD `fcaf61b` (`docs(session21): wrap — mop-up CLOSED`);
  working tree has the sanctioned Dockerfile edit and sanctioned
  untracked scratch only. No changes made by this session yet.
- Suite: `busted tests` → **854 / 0 / 0 / 4**, matching the
  session22 prompt. The four intentional pendings remain in
  `tests/input/input_routing_spec.lua`.
- Read: `agents/validation.md`, `agents/sessions.md`,
  `session22/prompt.md`, `session21/prompt.md`, `session21/track.md`,
  and `session21/report.md`.
- Current task: assemble the owner-facing Part-1 back-filter before
  TF2. It must distinguish decisions that would force re-reading the
  same review files if deferred from decisions safe to leave for the
  later collapsed sitting; then wait for owner rulings.

## 2026-07-29 — revised pre-TF2 disposition pass

- Owner rejected the narrow reread-only back-filter. The operative
  criterion is whether a later ruling reshapes the PR candidate. Every
  known item must be executed, retained with an explanation, or
  explicitly excluded before TF2.
- Sol consultation: `validation/outcomes/S22-sol-pre-TF2-ruling-order.md`.
  First batch opened with 0 of 12 items dispositioned.

## 2026-07-29 — G-1 ruled and execution started

- Owner ruled G-1 a resolved #77 fix, not a contested inspect redesign:
  `updev` let unhandled running-project keyboard/text fall into the
  hidden console; #77's unconditional project route replaces it with a
  no-op. Inspect is the retained pre-feature debugger route.
- Required disclosure: Decision 11, code rationale, regression test,
  ledger closure, and initial `CHANGELOG.md` entry. Suite + commit
  pending.

## 2026-07-29 — G-1 complete

- Applied and committed `93330dc` (`fix(input): close hidden-console
  fallback`). The test now proves both the hidden widget and console
  line remain unchanged; a temporary inverted assertion failed exactly
  there before restoration.
- `busted tests`: 854 / 0 / 0 / 4. G-1 is **1 of 12** visible
  pre-TF2 items dispositioned. Next batch remains C1, R4, RVW-100.

## 2026-07-29 — C1 ruled; documentation gate scheduled

- Owner ruled that the persistent documentation corpus is the authoritative
  #77 contract now and after release; `wip/77` remains detailed, non-shipping
  working evidence. New rulings need a concise canonical form as they are
  made, while the working record preserves rationale and reversals.
- A retrospective authority/provenance sweep is now an explicit pre-TF2 gate:
  after all pre-TF2 items are ruled and executed, a cold Terra inventories
  persistent claims against the working record; the owning session integrates
  concise status/provenance into persistent docs and verifies they stand alone.
  Navigation-batch generation and the owner's TF2 begin only afterward.
- C1 is **2 of 12** visible pre-TF2 items dispositioned. Its planned sweep is
  an execution gate, not a remaining authority question.

## 2026-07-29 — R4 source trace

- Verified `multiline` against the verbatim round-two stakeholder record,
  frozen design history, and `updev`; durable evidence:
  `validation/notes/S22-R4-multiline-source-trace.md`.
- Stakeholders requested editor-like multiline *boundary* semantics, not a
  `show{multiline}` switch, default-false policy, or Shift+Enter gating.
  The switch is a design-spec promise over pre-existing unconditional
  Shift+Enter newlines. No R4 ruling yet; awaiting the owner's choice.

## 2026-07-29 — R4 ruled and execution started

- Owner ruled the public `multiline` switch an unauthorised design-detail
  extrapolation: do not implement or plan it. The established contract is
  unconditional Shift+Enter newline insertion; remove the stale promise,
  debt entry, and code marker while retaining direct regression coverage.

## 2026-07-29 — R4 complete

- Removed the stale flag promise from persistent decisions/internals,
  removed its technical-debt row and the no-longer-meaningful model TODO,
  and clarified the direct project-widget regression narrative. Existing
  editor coverage independently pins the same behaviour.
- Persistent-reference sweep found no remaining unimplemented-flag/TODO
  wording. `busted tests` → **854 / 0 / 0 / 4**. R4 is **3 of 12** visible
  pre-TF2 items dispositioned; next is RVW-100 (Search routing scope).

## 2026-07-29 — RVW-100 topology correction and reframing

- There is no third editor-local `UserInputController`: the four live
  instances are project overlay, console REPL, editor main input, and
  editor Search. The remembered menu-like path is editor `reorder` mode;
  it owns keys directly and never calls `UserInputController:keypressed`.
- Search is nonetheless a distinct migration concern: it owns keys through
  `SearchController:keypressed` (navigation/removers and Enter → jump
  target) and delegates only text insertion to its wrapped widget. Search
  and reorder are intentionally outside the R-phase un-fork.
- Owner is considering a real-keystroke characterization test as the
  #77 migration-readiness evidence, rather than treating Search as a new
  project-facing API contract. Proposed future work: a separate analytical
  migration-path document, not speculative code comments; no ruling or
  execution yet.

## 2026-07-30 — RVW-100 characterization executed

- Owner approved a real-entry characterization test and a brief persistent
  migration analysis before PR. `editor_spec` now drives Ctrl+F, typed text,
  Enter jump, and Escape through `EditorController`'s real key/text entry
  points; its only fixture addition is the clipboard boundary required by
  Ctrl+F's existing state snapshot.
- The obsolete input-routing pending is removed and coverage docs/marker
  inventory now classify Search as editor-owned preserved behaviour, not a
  project-facing #77 contract. Full-suite verification and commit pending;
  migration analysis remains the next serial unit.

## 2026-07-30 — editor migration analysis complete

- Added a brief persistent, explicitly non-scheduled migration path in
  `internals/user_input.md`: preserve separate instances, move by editor
  mode, preserve Search's controller-owned policy and reorder's widget-free
  policy, and do not add release routing absent a consumer.
- RVW-100 is **4 of 12** visible pre-TF2 items dispositioned: its
  real-entry characterization protects future rewiring, while the analysis
  makes #77's migration-readiness boundary reviewable without a speculative
  editor rewrite.

## 2026-07-30 — R2 split by owner discussion; API-model finding

- Owner ruled the legacy result reftable route for retirement. The verbatim
  stakeholder record requires no backward compatibility and explicitly
  prefers migrated examples over retained legacy input APIs.
- R2 is not one decision: result is retirement work, while eval needs a
  separate public-contract ruling. The original ticket explicitly asks for
  configurable highlighter and verifier, but does not prescribe a generic
  evaluator config object.
- Code inspection found a material contract mismatch: project-overlay submit
  calls only the simple validator(text) gate, not the configured evaluator
  apply method. Thus ValidatedTextEval is not currently a reliable overlay
  submit gate despite the public guide claiming it is. Do not execute the
  result deletion until the owner rules the intended minimal evaluator /
  highlighter / validator model and its submit order.

## 2026-07-30 — R2 correction chunk planned; execution deferred

- Owner ratified the minimal project-overlay direction: no result or eval
  config keys; optional highlighter and validator functions; one line-array
  representation; validator, on_text_entered, after_submit submit order.
- The S22-R2 input-contract plan under validation notes records scope,
  exclusions,
  test-first execution order, migration/doc/release-note work, and the one
  remaining implementation-time owner choice: public names for Lua helpers
  and the existing-line-validator adapter.
- R2 is **5 of 12** dispositioned at the design level. It is a deferred
  implementation correction, to execute after the owner finishes the
  remaining triage so TF2 sees its final shape once.

## 2026-07-30 — R5 ruled; warning correction queued

- Owner ruled that an unknown show configuration key warns and is ignored.
  Rationale: immediate, actionable feedback for a typo or misplaced callback
  is an obvious user-experience benefit over a silent no-op.
- Canonical Decision 15 records the in-flight ruling. The S22-R5 unknown-show
  keys plan records its later test-first execution: unknown key and misplaced
  field-write callback warnings, config-key enumeration, public-doc update,
  debt cleanup, and full-suite verification.
- R5 is **6 of 12** visible pre-TF2 items dispositioned. Its implementation
  is intentionally deferred with the R2 correction chunk until triage ends.

## 2026-07-30 — G2 boundary reopened for Sol architecture judgment

- Owner accepts concise singleclick/doubleclick aliases as useful installation
  paths, but challenged a premature assumption that derived clicks belong in
  the keyboard/text dispatch mechanism unchanged.
- The live question is the smallest safe future-facing boundary: alias-seeded
  hooks with pointer-local delayed delivery, a narrow derived-click dispatcher,
  or full pointer participation in shortcuts/hooks/widget dispatch. Raw pointer,
  drag, selection, touch, M1/M2, modifier, and timing behaviour must not be
  changed for cosmetic symmetry.
- Sol consultation prompt is materialized under validation/prompts; outcome is
  required under validation/outcomes before an owner resolution. G2 remains
  in progress, so the count stays **6 of 12**.

## 2026-07-30 — G2 resolved: retain asymmetry, defer unification

- Sol confirmed that full dispatch would be false symmetry: derived clicks
  have none of shortcut precedence, widget fallback, or consume semantics, and
  raw pointer broadcast must preserve M2, modifiers, drag, selection, touch,
  timing, and lifecycle behaviour.
- Owner rejected even alias-seeded click hooks because a shared registration
  table would falsely imply common dispatch mechanisms. No G2 code, test,
  fixture, example, or public API change is queued for #77.
- Decision 16 retains the pre-feature split; the future-input-unification debt
  entry records the only trigger for reconsideration: concrete demand plus a
  feasible pointer design. G2 is **7 of 12** dispositioned.

## 2026-07-30 — D4 ruled: behavioural evidence by default

- Owner ruled that #77 tests principally prove observable behaviour through
  real project/framework entry points and public surfaces. Test coverage is
  proportionate, not exhaustive; rare internal edges do not earn tests merely
  by being reachable.
- Direct seams, mocks, and interception remain exceptional mechanism guards:
  allowed only when the real route cannot practically isolate the mechanism,
  and each must say why it is not a public contract test.
- Canonical Decision 17 and the S22 D4 behavioural-test plan record the
  bounded execution: review concrete fixture setup/reset and activation cases,
  replace only unjustified simulations, and do not launch a general rewrite.
  D4 is **8 of 12** dispositioned.

## 2026-07-30 — RVW-023 resolved: retain the explanatory matrix

- Owner accepted the existing explanation of the Lua and text highlighter
  regression matrix. The LuaEval factory is needed only for a fresh mutable
  nil-highlighter case; InputEvalLua remains the normal shared evaluator.
- Do not add aliases or a table merely to shorten this small test. Remove its
  stale review marker in the later cleanup pass; no behavioural change or
  dedicated test work is required. RVW-023 is **9 of 12** dispositioned.

## 2026-07-30 — RVW-020, J1, and RVW-087 closed

- Owner ratified the already-landed assert_indexable_hl helper name (RVW-020).
  J1 needs no further terminology ruling: execute the established plain-
  vocabulary and persistent-reference cleanup criterion.
- Owner ruled that held-key-view identity is not public API. The cached view
  is retained solely as a garbage-collection NFR; its planned mechanism test
  protects no per-event allocation without exposing identity to projects.
- The S22 RVW-087 NFR plan and Decision 13 allocation note record this work.
  All **12 of 12** visible pre-TF2 items are now dispositioned. Remaining work
  is the queued execution, authority sweep, navigation regeneration, and TF2.
