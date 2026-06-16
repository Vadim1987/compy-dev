# Feature #77 — New Input API

**TL;DR:** a callback-based input API for projects, replacing the polling
functions (`input_text`, `input_code`, `validated_input`, `user_input`). It
turned out to touch keyboard routing across the whole app, not just the REPL —
so it got a proper upfront analysis instead of a dive-in. **Complex, but
solvable**, and pre-planned so building can start on a green light. Per
stakeholder feedback (round 1), the legacy text-input functions are **removed**
— no backward compatibility; the examples that used them migrate to the new
API, others can be excluded from the release. The break is bounded to text
input: native keyboard handling is unchanged, and old releases remain
available.

## Start here

Each chain doc now **opens with its own stakeholder-altitude `## Summary`** (reverse-pyramid)
— read the summaries top-to-bottom for the whole feature in ~30 min, then dive into any
doc's detail as needed. Convergence + the decision calls live in **[`status.md`](status.md)**.

| # | Doc (read its `## Summary` first) | What it answers |
|---|---|---|
| 1 | [`requirements.md`](requirements.md) | What was asked for |
| 2 | [`context.md`](context.md) | What the code does today (the `context` node — the architecture assessment) |
| 3 | [`status.md`](status.md) ⭐ | Chain convergence + the blocking-decision calls & resolutions |
| 4 | [`design.md`](design.md) | How it works |
| 5 | [`spec.md`](spec.md) + [`spec/`](spec/) | The API contract (cross-cutting + per-milestone slices) |
| 6 | [`roadmap.md`](roadmap.md) | Build plan + effort (~39–66 h) |

## If you want to dig

- **`notes/`** — the ingest tier: your ticket (`notes/input.md`), stakeholder feedback
  (`notes/input/`), the deep decision rationale (`notes/decisions.md`), and codebase
  analysis. See [`notes/index.md`](notes/index.md).
- **`status/archive/`** — the round-based review history (`validation/`, `reevaluations/`).
- **`agents/`** — how this lifecycle works ([`agents/process.md`](agents/process.md)) and the
  SDLC binding ([`agents/sdlc.md`](agents/sdlc.md)).
