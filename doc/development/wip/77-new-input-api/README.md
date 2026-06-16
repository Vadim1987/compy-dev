# Feature #77 — New Input API

> **Next actions:** see [`entrypoints.md`](entrypoints.md) — the maintained list
> of open entrypoints to pick from.

This topic runs in **two chained phases**, each managed as its own lifecycle.
The boundary between them is a single handoff: **design produces the roadmap +
spec; implementation consumes them.**

```
design/  ──(outcome: roadmap + spec)──▶  sprint01/ sprint02/ …  ──▶  commits in this repo
```

## `design/` — the design lifecycle

Iterative **conceptual design with repetitive stakeholder feedback**: surface
gaps, record resolutions (the `decisions.md` ledger), and check consistency
downstream to the roadmap + estimates. Its **outcome is the converged roadmap +
spec** — a plan, not yet code. This phase is essentially complete; what remains
open is the approve/veto on `design/decisions.md` (D-2…D-10).

Start at **[`design/README.md`](design/README.md)** (the feature at stakeholder
altitude; read `design/summaries/` first).

## `sprintNN/` — the implementation sprints (agile)

Implementation is delivered as **sprints**, each correlated to a milestone in
[`design/roadmap.md`](design/roadmap.md). Rules:

- **Each sprint is its own SDLC instance** — `notes → requirements → design →
  spec → roadmap → outcome`, with the canonical edge-based `review` + `status`
  control loop.
- A sprint's **inputs/requirements derive from the design outcome** (the
  roadmap milestone it implements + `design/spec.md`).
- A sprint's **outcome is the list of commits in this repository** — the actual
  implementation (world-out, by reference).
- **Sprints are added only when they activate.** No `sprintNN/` exists until its
  milestone is picked up; we don't pre-shard the whole roadmap into chains.

## `notes/` — generic topic notes

Process/meta notes about the topic as a whole (migration evaluation, session
decisions, future remarks) — **not** part of either structured chain. See
[`agents/materialization_rule.md`](../../../../agents/materialization_rule.md):
valuable chat insights are materialized here under `notes/talk/`.

## Why two lifecycles

A single SDLC chain strained because design and implementation have different
control loops: design iterates by **stakeholder-feedback round** (and legitimately
treats decision-surfacing as a pipeline node), while implementation iterates by
**edge-coherence** against a frozen spec. Splitting them lets each use the loop
that fits, and makes the `design.outcome → sprint.requirements` edge the explicit,
single point of contact.
