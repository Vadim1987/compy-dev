# Feature #77 — feature-level plan

_LLM(Claude Opus 4.8) + human(Hleb): 2026-07-01 (session 31). **Feature-level** plan (phase
strategy + definition-of-done), not a milestone/implementation plan — those live in
[`../design/roadmap.md`](../design/roadmap.md) and `../implementation/`. Rationale + the
strategic exchange behind this: [`talk/safety-net-as-characterization-replan.md`](talk/safety-net-as-characterization-replan.md)._

## Where we are

Foundation and the characterization net are built; the feature itself has not started, and we
are one bounded step short of starting it.

- **Landed** (behaviour-neutral by design): M1 (`keys_pressed`/`combo_string`), M2 (singleton
  extraction, +M2-01/02), M2a (hygiene).
- **In convergence**: the input-subsystem **characterization** — the current-reality doc
  (`notes/input-contracts.md` + `notes/assessment/*` + `internals/user_input.md`) and the net
  that enforces it (`tests/input/input_contracts_spec.lua`, green: 717/9 pending). Not yet
  *trusted*, i.e. not yet done by the definition below.
- **Not started**: M4 (ProjectInputController + overlay-gate removal — the first behaviour
  change, the widest integration tail) and M5a→M5b→M6→M7→M8, i.e. the whole feature.

## What this phase actually is (and why it grew)

The "safety net" is the **formal characterization of an undocumented black-box input
subsystem** — a precondition for extending it, not test ceremony. It grew through *rewrites*
(instrumental → wrong-architectural-model → intended-shape-but-untrusted) because the target
was being **discovered, not transcribed**. It is legitimate debt-retirement: the subsystem's
own architect was mind-blocked designing #77 against it, which is critical accidental
complexity by definition; and it is the **M4 integration risk firing as forecast** — without a
re-documented system there is no criterion to judge whether integration succeeds or is a
catastrophe. See the talk note for the full argument.

## Definition of done (this phase) — "trust" made operational

The net (doc + suite) is **done** when all four hold — this replaces "I trust it" as the gate:

1. **Complete by construction, visibly** — every mode × channel cell
   (console/editor/search/project × keypressed/textinput/keyreleased/pointer) has a named row
   or an explicit `pending`/gap marker; per-mode `describe` nesting makes holes visible on sight.
2. **Every assertion carries provenance** — a design clause, a stakeholder quote, or an
   explicit *"characterized from current runtime, not yet ratified"* tag. No untagged assertion.
3. **Architect-legible cold** — any block readable with no session memory: what it guarantees, why.
4. **Every surfaced gap logged with a disposition** — fix-now / defer-to-Mx / accept-and-document.

## Scope — whole-subsystem is mapped; the act now is classification

The subsystem is mapped end to end; residual one-more-blind-spot risk is **accepted**. Findings
are classified by #77 blast radius:

- **In radius** — keypressed/textinput/keyreleased routing across the four modes, the overlay
  gate, submit/cancel/limit. Characterize **and** enforce now.
- **Out of radius, kept as foundation for future console/editor adoption of the new API** —
  the four `reset()` implementations, `inspect`-mode input suppression (undocumented today),
  the `search` sub-widget, the `keyreleased` console-only fork, the cursor two-layer split.
  Captured deliberately so the later integration isn't the same debt mess; **not** discarded or
  silently dropped.

## Canonical doc: two parts — current reality vs. designed API

- **(A) Current behaviour** — the black box formally identified; normalized from
  `input-contracts.md` + `assessment/*` + `internals/user_input.md`. The suite validates
  against this. Promotion to `internals/` at feature close (carries R7).
- **(B) Designed API on top** — the design corpus (`design/design.md`/`spec.md` + slices),
  already existing; the *desired* reality.

The suite's excess prose (flagged by the human's `-- REVIEW:` remarks) is **raw material for
(A)**: move "what/why" into prose (A); the suite keeps enforcement + doc-links, not inline
essays.

## The convergence pass (collapse the processual debt)

One convergent pass, ending at the definition of done — then M4 without delay:

1. **Normalize doc (A)** — split current-reality from designed-API; fold in the assessment
   findings and the session-30 gaps (§3.3 keyreleased CC-internal fork; bucket labels).
2. **Validate the suite against (A)** — every assertion maps to an (A) clause or a provenance tag.
3. **Clean the suite to the definition of done** — resolve the ~65 `-- REVIEW:` remarks in one
   pass (a couple pin real misunderstandings; most cosmetic); apply the two Opus findings
   (editor keypressed sibling + retitle; extract `restore_native_slots()` so `F.reset()` ≤ 14
   lines); per-mode `describe` nesting; strip session IDs (`D-α`/`R1`–`R7`/`F-A`–`F-E`) →
   plain rationale + doc-links; one keypressed-vs-textinput explainer near the top; relabel the
   held-key-set block as mechanism; tighten pointer-selection causality; add explicit `pending`
   for the `search` gap.
4. **Classify out-of-radius findings** into (A) as future-integration foundation (above).
5. **Reconcile `implementation/prompts/M4.md`** — stale `input_routing_spec.lua` name +
   Group-1/2 vocabulary → `input_contracts_spec.lua` + Bucket A–D model.

## Forward path (after the gate clears)

Fold two decisions into the M4 prompt as **acceptance lines** rather than floating notes:

- **"No-op when hidden" for the keypressed/textinput path** — becomes a live obligation the
  moment M4 removes the gate (the sink then runs on every keystroke, shown or hidden). Add:
  *a keystroke delivered while the singleton is hidden produces no model mutation, no view
  update, no history/selection/cursor change.*
- **M4↔M5 `keyreleased` tier** — M4's spec cross-references a dispatch tier M5 never specifies.
  One-line decision: explicitly descope (note it) or add the missing M5 tier.

Then: M4 (test-first, greens the pending forwards, removes the gate; 4-mode manual verify) →
M5a → M6/M7 → M8. Each test-first against its frozen spec slice.

Also to park explicitly (not silently): FR-2 resolution stakeholder-reconfirmation (low
urgency; likely resolves *by construction* once "no-op when hidden" is tested).

## The bet, and how we'll know it paid off

Once the net is frozen, M4 lands **test-first in one pass, not four**. Implementation is
expected to be fast because the human decides fast once the coordinate system is mapped
correctly — which is what this phase delivers. If M4 also thrashes, the thesis was wrong.
