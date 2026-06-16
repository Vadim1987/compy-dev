# Feature #77 — Process Evaluation (migration to canonical SDLC)

*My (LLM) current evaluation of the process that actually produced this
topic's artifacts, and how it relates to the canonical SDLC method, written
as the intermediate step before we brainstorm the enrollment. Reconstructed
from the artifacts themselves (their prose provenance) — not from a process
spec, because none was written down.*

---

## 1. What the predecessor process actually was

This topic was worked **before** the canonical SDLC method existed, so it ran
its own directed-problem-solving process — clearly SDLC-*shaped*, but with its
own chaining logic. Reconstructed chain (edges are stated in the docs' own
prose, not as formal `Derived from:` lines):

```
input.md            verbatim ticket + stakeholder clarification (+ round-2 feedback appended)
  │  "normalized from input.md"
  ▼
requirements.md     what is asked for (no solutions, no internals)
  │  "maps each requirement to the current architecture"
  ▼
assessment.md       requirement × current code: what exists / missing / reuse
  │  decisions "surfaced during requirements analysis and architecture assessment"
  ▼
decisions.md        blocking decisions D-1..D-10 (approve/veto ledger; D-1 ruled by stakeholders)
  │  "assuming decisions.md → design.md is endorsed"
  ▼
design.md           conceptual solution (from notes/solution_sketch.md + notes)
  │  "design context: design.md"
  ▼
spec.md             API contract for implementors
  │  "matching the section order in notes/solution_sketch.md"
  ▼
roadmap.md          milestones in dependency order + effort estimates (~39–66 h)

derived view:   summaries/*  — stakeholder-altitude condensations, RECALCULATED from each canonical doc
iteration:      reevaluations/ (round1: round→check→changes→outcome)
                input/         (round2: stakeholder2 notes → structured → impact_outline → track → evaluation → summary)
                validation/    (validation_report_1..3 + recommendations_1..2 + changelogs)
process scaffold: prompts/     (prompt.md, prompt3..10 — the session prompts that drove the work)
```

The feature is **pre-build**: the chain stops at an endorsed-pending roadmap;
no code/PR exists yet (the "derived proposal documents, pre-built on the
assumption design is endorsed rather than vetoed" framing in spec.md/roadmap.md).

## 2. Where it matches canonical SDLC

- **Same directional spine**: input → requirements → design → spec → roadmap.
- **"Broken-until-converged" stance** is already native: the proposal docs
  declare themselves pre-built on an unendorsed design — exactly SDLC's "the
  chain stays broken until contradictions resolve."
- **A review/iteration loop exists** (validation/ + reevaluations/) — kin to
  SDLC's review control loop "designed to break often."
- **Stakeholder-altitude condensation exists** (summaries/) — kin to a depth
  `split-down` overview layer.
- **Provenance is already expressed**, just in prose — formalizing it into
  `Derived from:` lines is a non-destructive header addition, not a rewrite.

## 3. Where it diverges (the load-bearing differences)

These are the points where "just coerce to canonical" would *lose* structure,
and where a custom process *on top of* SDLC may be the right call:

1. **`assessment.md` is a first-class stage.** A full requirement×code matrix
   sits between requirements and decisions. Canonical SDLC folds current-state
   into a thin `context` node. *(Decided this session: map → `context`, but it
   is far richer than canonical thin context — it is effectively a
   "current-architecture assessment" node feeding design.)*
2. **`decisions.md` is an upstream pipeline node, not a control-loop output.**
   The predecessor elevates decision-surfacing to a *named stage* (D-1..D-10
   with approve/veto status) that feeds design. Canonical SDLC keeps surfaced
   decisions in `review`'s contradiction list (a control artifact spanning
   edges), **downstream**, not as a pipeline node. This is the single biggest
   topological difference.
3. **Review is round-structured, not edge-structured.** validation/ and
   reevaluations/ are *temporal episodes* (round 1, round 2), each emitting
   report + recommendations + changelog. Canonical `review` is *per-edge
   coherence verdicts generated from the provenance graph* (the edge-coverage
   invariant). The predecessor iterates **by feedback round**; SDLC iterates
   **by edge**. Different control-loop topology — reconciling them is the core
   of the brainstorm.
4. **`summaries/` is a parallel recalculated layer**, not in-place split-down.
   A separate folder regenerated from the canonical docs, rather than per-role
   overview+detail. (Confirmed this session: full docs = canonical; summaries
   = derived view → out-of-chain.)
5. **Missing canonical nodes**: no explicit `objective` (implicit in input.md +
   README TL;DR), no `status` dashboard (implicit in round summaries), no
   `outcome` (feature unbuilt — deferred to a separate discussion).
6. **`constraints` not separated** — folded into requirements §1 and decisions.

## 4. Enrollment options (for the brainstorm)

- **(a) Coerce to canonical.** assessment→context, decisions→review
  contradiction list, validation/reevaluations→review, summaries→split-down.
  Purest invariants, but discards the explicit decision-ledger and the
  round-based history — highest harm.
- **(b) Custom process on top of SDLC (overlay-extended).** The binding overlay
  already supports role→filename overrides and out-of-chain dirs; SDLC is
  "opinion, not operations," configured per-topic. So name the predecessor's
  extra stages as first-class overlay roles (`assessment` as a rich context-tier
  node; `decisions` as a named pipeline node) and define how the **round-based
  review** maps onto / coexists with the **edge-based** review invariants —
  while preserving the canonical guarantees (chain-completeness, edge-coverage,
  input-stability). Lowest harm; the path the human is leaning toward.
- **(c) Hybrid.** Coerce the spine, keep assessment+decisions as named nodes,
  archive the round history out-of-chain, seed fresh canonical review+status
  going forward.

## 5. Open question carried into the brainstorm

The deep one: **is the predecessor's round-based control loop a topic-local
variant, or does it reveal a generalizable enhancement to canonical SDLC?**
(e.g. "assessment as an explicit context-expansion stage" and "decisions as a
pipeline node" may be promotable; round-vs-edge review is the harder question,
since canonical SDLC chose edge-based *deliberately* for completeness.) Whether
we build a topic-local custom overlay or feed changes back into the library is
itself part of what we are deciding.

## 6. `outcome` — explicitly deferred

What constitutes the SDLC `outcome` (world-out deliverable) for a pre-build
feature — the merged code? the PR? a "ready-to-build" gate? — is parked for a
separate discussion at the human's request, after the tacticals settle.
