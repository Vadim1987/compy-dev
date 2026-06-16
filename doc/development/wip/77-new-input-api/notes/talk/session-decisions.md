# Talk note — SDLC-enrollment session decisions

*Materialized per `agents/materialization_rule.md`: durable record of the
valuable rulings/insights from the enrollment-discussion chat (not the
intermittent back-and-forth). Telegraphic on purpose.*

---

## Decisions reached (human-ruled unless noted)

- **Topic is a mount (R14).** `topics/git/` is the external project repo; the
  topic is the artifact path `doc/development/wip/77-new-input-api/` inside it.
  Engine-runtime config must not leak into that repo.
- **Sessions structure created** at `sessions/git/doc/development/wip/77-new-input-api/`
  (brainlab-side, out of the project repo). Only that — no session prompt seeded
  yet (first task still being scoped).
- **Binding location → in-repo** at `topics/<topic>/agents/sdlc.md`.
  Rationale (LLM recommendation, human-accepted): an out-of-repo binding would
  defeat presence-based method detection (`starting-chat.md` §2 / `methods.md`
  §6), forcing a per-boot mount-check + dual-location lookup on *every* future
  chat — the recurring inference cost the human wanted to avoid. In-repo "just
  works" with zero library change and is explicitly R14-blessed (the binding is
  the one engine file allowed inside an artifact-only repo; reads like
  ARCHITECTURE.md). *Not yet written — pending enrollment go-ahead.*
- **`assessment.md` → `context`** (world-in). Closest canonical fit, though
  richer than canonical thin context (see migration/process-evaluation.md §3.1).
- **Least-harm principle: "declare, don't move."** Reclassify existing artifacts
  via the overlay name-map + `Derived from:` header lines + out-of-chain dir
  declarations — leave files in place. Only forced new structure: requirements
  (+constraints) `.versions/` baseline (genesis-skip = no diff burden),
  placeholders for missing mandatory nodes (`objective`, `status`), first
  `revalidate`.
- **`summaries/` = out-of-chain derived view** (recalculated from canonical
  docs); full docs are canonical.
- **`outcome` semantics deferred** to a separate discussion after tacticals.

## Pivot

- Human reframed the review-mapping question: the predecessor process was **not
  exactly SDLC** (it predates the canonical method); consider building a
  **custom process on top of SDLC** rather than coercing. Next step is a
  brainstorm; this note + `migration/process-evaluation.md` are its inputs.

## Architecture decision — two chained lifecycles (human-proposed)

The predecessor process is **iterative conceptual design with repetitive
stakeholder feedback** — surfacing gaps, recording resolutions, checking
consistency downstream to roadmap+estimates. **The roadmap+estimates ARE its
de-facto output.** So split the topic into two chained lifecycles instead of
one strained chain:

- **`design/`** — the design lifecycle (the predecessor process), moved wholesale
  under a `design/` subdir with all its artifacts; kept as its own process (with
  better rules authored from brainlab primitives). Its `outcome` = the converged
  roadmap/spec.
- **implementation** — current topic seeded **fresh with canonical SDLC**, taking
  its inputs/requirements **from design's outcome**. Possibly one SDLC instance
  **per milestone** (each milestone a subdir, activated when it starts).
- **topic-root doc** explains how the two relate.

Why it resolves the tensions: round-based review and decisions-as-pipeline-node
are *correct* for a design lifecycle; canonical edge-based review is for
implementation. The deferred `outcome` question answers itself —
**design.outcome = roadmap = impl.input** (the chain edge between the two).

Priority constraint: **start implementation ASAP once design+roadmap converge.**
=> Formalizing the design *method* must not gate seeding the impl SDLC.

## Restructure executed (this session)

Refinements the human locked in, then green-lit the restructure:

- **Topic-level `notes/`** holds generic/meta/process notes (this `talk/`,
  `migration/`, future remarks) — **not** part of any structured chain. The 14
  design-analysis notes moved to `design/notes/` (they are design inputs).
- **Implementation = agile sprints**, not a single `impl/`: `sprint01`,
  `sprint02`, … each **its own SDLC instance**, correlated to a milestone in
  `design/roadmap.md`. **Sprints added only as they activate** (no pre-sharding).
- **A sprint's outcome = the list of commits in this git repo** — the actual
  implementation, world-out by reference. (This is the concrete answer to the
  earlier-deferred `outcome` question, for the implementation side.)
- **Move done via `git mv`** (history + relative cross-links preserved): the whole
  design bundle now lives under `design/`; topic-root README rewritten as the
  design→sprints relationship doc; old topic README preserved as `design/README.md`.

Not done yet (intentionally): no `sprintNN/` seeded (none activated — design
decisions D-2…D-10 still open); the design lifecycle's own formal rules ("(a)"
track) left for later, must not gate the first sprint.

## Conventions adopted this session

- **Topic-root `entrypoints.md`** — a maintained list of actionable open
  entrypoints; on boot, the next session offers them as a selectable menu
  (recommended-next first). Referenced from the top of `README.md`. Keep current.
- **Honesty correction:** "design not converged" is the docs' *self-report*, not a
  verified conclusion (and possibly stale vs the round-2 + validation work).
  Verifying it = entrypoint **E1 (revalidate the design)**, the agreed next step.

## Standing rule activated this session

- `materialization_rule.md` added to the project's `agents/`: valuable chat
  insights/attestations → saved as notes under `./notes/talk/` by default.
