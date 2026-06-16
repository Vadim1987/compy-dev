# Feature #77 — New Input API

> **Next actions:** see [`entrypoints.md`](entrypoints.md) — the maintained list
> of open entrypoints to pick from.

This topic runs in **two chained phases**. They are **not symmetric**: `design/`
is a managed lifecycle (a canonical SDLC instance); implementation is deliberately
**unmanaged** — a black-box execution step recorded in a thin ledger. The boundary
between them is a single handoff: **design produces the roadmap + spec;
implementation consumes a spec slice and reports its commits.**

```
design/  ──(outcome: roadmap + per-milestone specs)──▶  implementation/  ──▶  commits in this repo
   (managed SDLC lifecycle)                              (black-box exec + outcome ledger)
```

## `design/` — the design lifecycle

Iterative **conceptual design with repetitive stakeholder feedback**: surface
gaps, record resolutions, and check consistency downstream to the roadmap +
estimates. Its **outcome is the converged roadmap + per-milestone specs** — a
plan, not yet code. This phase is **converged** (E1) and now formally enrolled as
a **canonical SDLC instance** (binding: [`design/agents/sdlc.md`](design/agents/sdlc.md);
process: [`design/agents/process.md`](design/agents/process.md)). Chain convergence
and the blocking-decision track live in [`design/status.md`](design/status.md).

Start at **[`design/README.md`](design/README.md)** (the feature at stakeholder
altitude; each chain doc now opens with its own summary).

## `implementation/` — the execution ledger (deliberately unmanaged)

Once the design is converged and frozen, implementing a milestone is **mechanical
work against a fixed spec** — the cognition was already spent in `design/`. So
implementation is **not** run as a per-sprint SDLC instance (that would be
degenerate ceremony: requirements/design/spec nodes that just point back to
`design/`). Instead:

- **The implementation agent is a black box.** It receives **one self-contained
  prompt** — which spec slice to implement, and where to record the result — does
  the job, and stops. No session management, no progressive prompting, no SDLC
  chain on the implementation side.
- **Inputs are a single milestone spec slice** ([`design/spec/`](design/spec/)
  `MN.md`) + the cross-cutting contract [`design/spec.md`](design/spec.md) for
  context.
- **Outputs are recorded in this directory** — one ledger file per milestone
  ([`implementation/outcomes/MN.md`](implementation/outcomes/)): the commits (by
  reference — world-out), the verification record, and any gaps the spec didn't
  anticipate.
- **The prompts live here too** ([`implementation/prompts/MN.md`](implementation/prompts/))
  — drafted/reviewed under session management, then handed to the black box.
- **Per-milestone, added only when activated.** No `implementation/` entry exists
  until its milestone is picked up; we don't pre-shard the roadmap.
- **Commits belong to the human** (`agents/git.md`): the agent stages; the human
  commits; the ledger carries the resulting commit refs.

**Escalation.** If a milestone turns out to be **cognition-heavy or
human-driven** (design churn, judgment calls — e.g. the integration-heavy M4 gate
removal or M6 boundary model), it is promoted to its **own subtopic** with full
SDLC + session management. The black-box ledger is the default; the managed
lifecycle is the exception, spun up on demand.

> **Verification caveat.** This workspace cannot run lua/LÖVE/busted
> (`agents/bash.md`). The black box can **write** tests but not **execute** them —
> so every outcome ledger states the test command and marks execution as pending
> human/CI; "tests pass" is never claimed on faith.

## `notes/` — generic topic notes

Process/meta notes about the topic as a whole (migration evaluation, session
decisions, future remarks) — **not** part of either structured chain. See
[`agents/materialization_rule.md`](../../../../agents/materialization_rule.md):
valuable chat insights are materialized here under `notes/talk/`.

## Why this split (and why implementation is unmanaged)

A single SDLC chain strained because design and implementation have different
control loops: design iterates by **stakeholder-feedback round** (and legitimately
treats decision-surfacing as a pipeline node), while implementation, once the spec
is frozen, is **mechanical execution** — not an iterative loop at all. Forcing
implementation into its own SDLC instance produced ceremony with no payload (chain
nodes that only re-point at `design/`).

So the asymmetry is intentional: keep the **managed lifecycle on the side where
judgment lives** (`design/`), and treat the other side as a **black-box execution
step** with a thin outcome ledger. This keeps the `design.outcome → implementation`
edge the explicit, single point of contact, reserves the expensive paradigms (SDLC
+ session management) for cognition-heavy work, and keeps them off the mechanical
path. When a milestone *does* carry real judgment, it earns a managed subtopic
(see **Escalation** above).
