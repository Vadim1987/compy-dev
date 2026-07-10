# session01 — prompt (M4)

_Genesis handover, written by the commissioning brainlab session (session 31, 2026-07-02). There is
no predecessor `report.md`; the carryover below restates what you'd otherwise read there. Workflow:
the mandate `../../prompts/M4-M8-sweep-mandate.md` — read it first if you haven't (the `agents/sweep.md`
boot pointer sends you through it)._

## Carryover

- The M4 guardrail is in place and trusted: the input contract suite
  (`tests/input/input_contracts_spec.lua`) was converged to an explicit definition-of-done
  (provenance on every assertion → "doc A §N" = `notes/input-contracts.md`; per-mode nesting; every
  gap dispositioned) and **verified green: 718 pass / 0 fail / 0 error / 12 pending**
  (`implementation/outcomes/M4-0-05-suite-cleanup-verify.md`, commit `dfd95c7`).
- **Human rulings already made — do not re-ask:** `keyreleased` tier = **descope-with-note**
  (M4.md step 3b's "ruling required at launch" is hereby RESOLVED to its recorded default);
  the suite's kept-OPEN rows (editor block-nav, inspect) stand as-is; `on_text_entered` semantics
  stays parked at its m5a `pending`.
- M4 is the first real behaviour change of feature #77 ("Risk: Highest") — everything landed so far
  (M1/M2/M2a/M4-0) was behaviour-neutral plumbing plus this net.

## Your task

Execute **`implementation/prompts/M4.md`** — it is commissioned, reconciled (2026-07-02), and
self-contained: `ProjectInputController` + overlay-gate removal + `isrepeat` threading, test-first
against the contract suite (four `DEFERRED (0.1.0-m4)` pendings → live green), four-mode manual
verification, outcome ledger `implementation/outcomes/M4.md`.

Per the mandate's milestone loop: delegate mechanical grind to Sonnet subagents, keep judgment
yourself; track as you go; **stop at any genuine judgment call** (M4 is an explicitly flagged
escalation candidate — if it cannot be integrated cleanly, say so and stop rather than forcing it);
then **present the result and hold the gate** — M4 is done only when the human explicitly approves.
Only after approval: commit, wrap (report + `session02/prompt.md` for M5a + repoint
`agents/sweep.md`), and end the session. Note M5a has no implementation prompt yet — authoring it
(from frozen `design/spec/M5.md` + `design/spec/M5-01-split.md`, with its Tier-2 test-first step)
is session02's first move, subject to human approval before execution, per the mandate.
