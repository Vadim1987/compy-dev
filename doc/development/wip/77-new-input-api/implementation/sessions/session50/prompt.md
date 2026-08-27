# session50 — execute `ARC-02`: `show` composes `configure`

Read `agents/sessions.md` and `agents/validation.md` first. Then **`../session49/report.md`** — the
handover. Session49's track is long and you do not need it.

Baseline: **979 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Your task

**Execute `ARC-02`, nine steps, in order.** This is **execution**, not analysis
(`agents/validation.md`, operational modes — watch that boundary, and say so if you cross it).

- **The plan:** [`validation/reviews/ARC-02-configure-boundary-plan.md`](../../../validation/reviews/ARC-02-configure-boundary-plan.md)
- **The steps and their current numbering:** `ROADMAP.md`, the `ARC-02` sprint
- **The cold review of the plan:** [`validation/outcomes/ARC-02-plan-cold-review.md`](../../../validation/outcomes/ARC-02-plan-cold-review.md)
  — *approve with changes*; its four changes are already folded into the roadmap steps

**The design is settled and ratified as Decision 35** (`doc/development/decisions/input.md`,
`ACTIVE`). Both open picks were closed by the owner. **Do not reopen the design.** If execution turns
up something that genuinely contradicts it, stop and bring it to the owner — that is a ruling, not an
implementation detail.

## Read this before opening the plan

**The plan and the cold review use the OLD step numbers.** `BUG-01-10` was folded in as `ARC-02-06`
on 2026-08-27, so the old `-06`/`-07`/`-08` are now `-07`/`-08`/`-09`. The crosswalk is on the
roadmap sprint. Where the plan says "§5.1" or names a step, map it through the roadmap.

## Three traps, already paid for

1. **`clear_input()` is not `set_text('')`.** It also runs `clear_selection()`, sets
   `custom_status = nil`, and calls `history:reset_index()` (`userInputModel.lua:344-351`). "Normalise
   `text` to empty" is a statement of *contract*, not a literal default value. Two of those three
   effects have no test that would notice them going missing.
2. **`ARC-02-02` cannot be its own commit.** Suite-green-at-every-commit means the breaking tests
   land **with** the step that makes them pass. Write them first, *see them fail*, then implement —
   `agents/development.md` — but commit them together.
3. **A green suite is not evidence on the project dispatch path.** `with_canvas_and_errors` xpcalls
   the walk, so a raise there is swallowed and printed. Anything asserting a raise reaches a project
   must observe the error channel (`love.state.suspend_msg`, `app_state`).

## Standing cautions

- **Verify before acting.** Session49 had four of its own claims overturned; the recurring shape was
  **a conclusion drawn from one instance and generalised to its neighbours**. When you check one
  field, one heading, one call site — say so, and do not speak for its siblings.
- **Check the PR base `3256aac`** when provenance matters. It has overturned a verdict repeatedly,
  and nobody else reliably makes that check.
- `| head` on a counting grep lies, and so does a loose one — session49's own ledger cross-check came
  back green because a loose pattern matched the convention being *described* in prose.
- **Commit at the natural seam**, one concern each; a production fix is always its own commit;
  suite green and its count stated in every message. **Never push.**
- **Sub-agents:** always pass `model` explicitly; Fable is retired. The `lua-lsp` MCP is up — use it
  for "who calls this", grep as the completeness backstop.
- The example repos are separate repositories with their own remotes. Commit as the work demands;
  **never push** any of them, or the platform.

## Where the project stands, if you want it before the plan

[`../../../status.md`](../../../status.md) — the bookmark page for the three ledgers and the roadmap.
The ledgers are the position; the roadmap is the plan. `ARC-02` fulfils the debt goal
**`T-CFG-BOUNDARY`**, and closes or dissolves `BUG-01-06` (+ its highlighter-deferral sibling),
`BUG-01-08`, `BUG-01-10`, `FIX-02-21` and `FIX-02-12`.
