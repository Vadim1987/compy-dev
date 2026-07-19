# Plan-revision proposal — doc-integrity + test-fidelity gate before Phase B

_Session12 (Fable, 2026-07-19), per `implementation/sessions/session12/prompt.md` and the owner's
post-Phase-A note (`validation/notes/2026-07-19-owner-post-phaseA.md`). **Status: PROPOSED — owner
ratification pending.** The concrete phase text is amended into `validation/plan.md` (marked
PROPOSED there); this document records the judgment behind it._

## Verdict in one paragraph

The owner's proposed gate is right in substance and right in order; it is not over-elaborate —
every step maps to an evidenced integrity hole, not a hypothetical. But its seven steps are two
phases wearing seven hats: a **doc-integrity phase** (validate doc A → owner rules on promotion
form → execute + re-sweep refs) and a **test-fidelity phase** (split spec → owner review →
evaluate hints + triage). Step 7 is the gate itself, not work. I propose exactly that
consolidation, plus four additions the owner's list implies but doesn't state: a circularity
guard (validate doc A against **code**, never against the suite whose fidelity is still in
question), a behaviour-preservation contract for the split (identical 815/0/0/4, the one real
technical risk), an explicit disposition for the ~25 non-doc-A inventory refs (they stay Phase C
— the gate must not silently absorb only the doc A family), and consumption wiring so Phase B
gets thinner instead of re-deriving what the doc-A audit will already have proven.

## Facts verified in code/tree this session (not taken from any report)

- **Doc A's temporal frame is inverted by the shipped code.** Doc A §5.1/§7 describe the overlay
  gate as "today" and `ProjectInputController` as "forward". Shipped `controller.lua` has
  `Controller.project_input = ProjectInputController()` (line 1192) — the forward world landed —
  while `get_user_input` **survives** (lines 21–24), reinterpreted as the console route's
  intra-route widget forward (comment at lines 30–37). So doc A is neither current nor cleanly
  obsolete: outcome-level contracts likely hold, mechanism notes and stability tags are stale in
  both directions. Validation is genuinely non-trivial; promotion-as-is would import a stale doc.
- **Doc A names its own unmet promotion preconditions.** Header: "human-approved: NOT YET";
  §7 scope note: m6/m7 outcomes "are **not** enumerated here; they are to be added before this
  note is promoted to `internals/`."
- **Corpus drift beyond doc A exists.** `doc/development/tests.md` ("Input Contract Suite"
  section) states "808 successes … confirmed by a live run" and cites pending rows at lines
  101/153/161/222; the live suite is **815**/0/0/4 with pendings at 118/172/185/246 (same four
  rows by content — pure line/count drift).
- **The suite-review suspicion is already evidenced.** `notes/input-suite-validation-map.md`
  (the doc-A-clause → suite-row bridge, itself "human-approved: NOT YET") records an open
  finding: the "editor mode routes keys to the editor" test drives `textinput`, not
  `keypressed` — a coverage gap masked by a mis-titled test, precisely the infidelity genre A2's
  single mechanical fix hints at.
- The big spec is 2269 lines, one outer + 19 inner `describe` blocks with clean thematic
  boundaries (routing / shortcuts / click / lifecycle / `#m5c` dispatch + route lifecycle /
  `#m7` cursor + reconfigure / `#m8` idiom) — a natural split skeleton exists.

## The proposed shape (two phases, one gate)

Inserted between Phase A and Phase B as **Phase DI (doc integrity)** and **Phase TF
(test-fidelity deepening)** — deliberately *not* re-lettering B–G: those labels are load-bearing
across frozen prompts, tracks, and `agents/validation.md` ("do not start Phase B/D"); re-lettering
would scramble standing references for zero gain.

- **DI1 — doc-A fidelity audit** (Sonnet evidence, orchestrator consolidates verdicts).
  Per-section verdict table: still-true / stale-mechanism / superseded-by-shipped /
  already-covered-in-corpus (cite where) / unique-no-home. Claims verified against **code**
  (LSP + grep), never against the suite — the suite's own fidelity is what Phase TF audits;
  using it as the doc's witness would be circular. Leverage + refresh the validation map as the
  bridge artifact. Fold in the small `tests.md` drift found this session.
- **DI2 — owner ruling on promotion form** (gated). Three options, evidence-attached:
  (a) promote a **re-baselined** doc A (temporal frame flipped to shipped reality, m6/m7
  covered) as a new corpus doc; (b) **merge** the surviving unique content into the existing
  corpus homes (`internals/user_input.md`, `decisions/input.md`, `technical_debt/input.md`) and
  leave doc A a frozen wip record; (c) no promotion — reword the ~30 clause refs to cite
  behaviour/corpus sections. My prior, to be tested by DI1 evidence: **(b)** — much of doc A is
  already superseded by the corpus that was written after it, and the strategic frame argues
  against a sixth overlapping doc; note (c) partially collapses into (b), since A1 already
  reworded every ref that *had* an independent corpus home — the ~30 leftovers are precisely
  the clauses with no persistent mirror, so "reword" mostly means "write the missing content
  somewhere" anyway.
- **DI3 — execute the ruling** (Sonnet mechanical): content moves/merges; re-run the A1
  retarget over the doc-A family (~30 refs incl. `input_fixture.lua`'s "doc A" definition and
  the `design.md §4` sibling); refresh `tests.md` facts. The ~25 non-doc-A inventory refs
  (milestone marks, `M2-human-review` questions, process artifacts) are **not** absorbed — they
  need rulings, not homes, and stay Phase C evidence as already planned.
- **TF1 — split the spec** (Sonnet mechanical, only after DI3 — owner's own coupling: the
  comments being carried into new files must already be final). Split along describe/bucket
  boundaries into human-reviewable files. **Behaviour-preservation contract:** suite count
  identical 815/0/0/4, same tags, same four pendings; the one real risk is the shared fixture's
  require-time build — any cross-describe state coupling that today rides file-scope ordering
  must be found (not papered over) before the split lands. `tests.md`'s "a comment header, not
  a file split" sentence is superseded by the owner's own direction.
- **TF2 — owner human review of the split suite** (gated, interactive; never started
  unprompted). Hints recorded to `validation/notes/`.
- **TF3 — evaluate hints + triage** (hint-scoped, not a re-audit — guardrail 1 stands):
  mechanical fixes land per hint; judgment items are **pooled with A2's two standing
  fixture-architecture questions** (wrap-native helper; play-mode fixture) into one triage list,
  ruled while the owner is already at the table from TF2 — one sitting, consistent rulings,
  instead of re-raising the same fixture questions cold in Phase D. Anything principle-shaped
  rolls to Phase C/D as before; nothing is dropped.
- **The gate:** Phase B starts only when the owner declares DI + TF accepted.

## Ordering — why the owner's couplings hold (and the deeper reason)

Promotion before re-sweep: refs need a target — trivially right. Split after comment
normalization: the owner's stated reason (refs already correct when split) — right. The
load-bearing reason the *whole* DI-before-TF order is correct, worth stating because it's what
makes the gate coherent rather than two unrelated chores: **a human review of tests for
infidelity needs a trustworthy statement of what the tests are supposed to assert.** Today that
statement is doc A — stale and unvalidated. Validate the doc first and the owner reviews the
suite *against* it (via the refreshed validation map); review the suite first and every
suspicion has to be re-derived from code by hand. DI is what makes TF2 cheap.

## Overlap with Phase B (the prompt's direct question)

Partial and real. Phase B's "satisfied/deviated" buckets and DI1's verdict table are the same
verification work for the input-routing domain: checking shipped behaviour against the recorded
contract. Resolution: **B consumes DI1's verdict table** as its evidence base for that domain
and keeps only its own altitude — intent-level deviation judgment (incl. the three known
shipped-API deviations, already recorded at the foot of `decisions/input.md`), and
scaffolding-suspect hunting. B gets thinner, not duplicated. This is amended into B's phase text
as part of the proposal.

## The "more predictable vs more elaborate" test, applied to the gate itself

Each step traces to an evidenced hole: DI to ~30 test-comment citations of a doc slated for
deletion with `wip/77` (a real reviewability hole against the strategic frame) plus the
verified staleness above; TF to a demonstrated infidelity pattern (A2's title/body mismatch,
the validation map's masked coverage gap). What keeps it from elaboration: DI audits **the
doc's claims**, not the feature (no re-sweep); TF3 is hint-scoped; the split is
behaviour-frozen; the ~25 residue refs and all jargon rulings stay where the ratified plan
already puts them (C and D). Nothing in the gate invents a new artifact genre — it reuses A1's
sweep method, A2's audit method, and the existing validation map.

## Owner decision points (in order of appearance)

1. **Ratify this revision** (or amend — the phase text in `plan.md` is the proposal).
2. **DI2** — promotion form: (a) re-baselined promotion / (b) merge into corpus / (c) reword
   refs only.
3. **TF2** — the sitting itself (owner schedules; never auto-started).
4. **TF3** — fixture-architecture + hint triage rulings (pooled with the A2 pair).
5. Standing, unchanged: Phase D sitting; jargon cluster; `wip/77` deletion.

## Risks / cautions carried into the phase text

- Split: fixture require-time state coupling (above) — the split worker must prove independence
  per new file, not assume it.
- DI scope creep: the audit answers "does this doc describe shipped reality", never "is the
  feature correct" (guardrail 1).
- Doc A stays **unedited in place** regardless of DI2's outcome (it is a wip historical record;
  re-baselined content lands in the corpus copy). `design/` remains frozen.
