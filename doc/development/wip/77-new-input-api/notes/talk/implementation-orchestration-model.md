# Process model — orchestration vs. execution (two planes)

_Materialised from a chat decision (2026-06-17). Owner: Hleb Rubanau. Refines the black-box model in
[`../../implementation/README.md`](../../implementation/README.md)._

The #77 implementation runs on **two separate planes**, deliberately kept apart:

## 1. Orchestration plane — brainlab-managed sessions (this framework)

A session under brainlab management **supervises and orchestrates** the implement/review cycles. It
does **not** itself write feature code. Its work is:

- **Commission** implementation prompts (`implementation/prompts/*.md`) for the execution plane.
- **Author and adjust specs** — corrective takes and adjacent closure specs
  (`design/spec/MN-NN-<why>.md`), never editing the frozen design-time `MN.md`.
- **Ingest** the execution plane's outputs (outcome ledgers + review docs), then **decide**: approve,
  commission a corrective take, adjust specs, dispatch surfaced debt, or escalate a milestone to a
  managed subtopic.
- **Maintain** the orchestration artifacts: `entrypoints.md`, the feature interim-debt ledger
  (`implementation/technical_debt.md`), the index in `implementation/README.md`.

LLM here: **Claude (Opus) under brainlab session management.**

## 2. Execution plane — lightweight agent sessions, OUTSIDE brainlab

Run **directly by the human** in throwaway, **tiny-context** agent sessions. Each carries only:

- the project rules — [`/agents/rules.md`](../../../../../agents/rules.md) +
  [`/agents/development.md`](../../../../../agents/development.md), and
- **one** task, of one of two kinds:

| Task | Input | LLM |
|---|---|---|
| **Implement** the commissioned prompt | `implementation/prompts/MN….md` | **Sonnet** |
| **Review** the implementation | the reported outcome ledger (`implementation/outcomes/MN….md`) + the diff | **Opus** |

These sessions have **no brainlab context** — no workflow, no session OS, no topic tree. The prompt
is self-sufficient by construction (that is why the black-box prompts restate nothing but point at
`/agents/*` and the spec slice).

## The cycle

```
[orchestration: brainlab/Opus]  commission prompt + spec
        │
        ▼
[execution: Sonnet, outside]    implement → commit locally → fill outcome ledger
        │
        ▼
[execution: Opus, outside]      review against outcome+diff → write review doc
        │
        ▼
[orchestration: brainlab/Opus]  ingest outcome+review → approve | commission corrective take
                                | adjust specs | dispatch debt | escalate
```

## Why two planes

- **Cheap, focused execution.** Implement/review need only the rules + one task; loading the whole
  brainlab OS would be waste. Tiny context keeps them fast and reproducible.
- **Judgment stays in one place.** All cross-cutting decisions (what to commission, how to dispatch
  debt, when to escalate) live in the orchestration plane, with the full topic context.
- **Reviewer ≠ implementer, and stronger.** Implement = Sonnet, review = Opus — the review is an
  independent, higher-capability check, not the author grading itself.

## Supersedes

`implementation/README.md` previously said *"outcome review happens back here, under session
management."* Corrected: the **review artifact** is produced in an external Opus session; the brainlab
session does the **orchestration/decision** on the outcome+review, not the review itself.
