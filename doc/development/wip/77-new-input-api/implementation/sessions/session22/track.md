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
