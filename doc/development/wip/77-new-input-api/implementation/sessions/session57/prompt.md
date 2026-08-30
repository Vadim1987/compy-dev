# session57 — `FEAT-01`: the two surface changes

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session56/report.md`](../session56/report.md).

Baseline: **1011 / 0 / 0 / 10**.

## Carryover

Session56 revalidated the `BUG-01-03` turtle fix (approve with comments, both dispositioned) and
filed the owner's three hand-written debt entries into the plan and the ledgers. `OP-01` ran and is
**complete**: it produced **Decision 36** (`oneshot`) and **Decision 37** (the submit callbacks are
told apart by their payload), retired `T-NAMESPACE-CLONE` against a new practice in
`conventions/architecture_principles.md`, and re-derived the debt entries from the decisions.
`FEAT-01` is what implements those two decisions, and it **leads the remaining sequence**.

**You are deliberately cold.** Session56 wrote the decisions you are about to implement, and the
owner chose a fresh session over its warm context precisely so that the ledger is tested as a
specification rather than trusted as a memory. Two consequences: **the decisions and the debt
entries are your source, not the session56 track**, and if they turn out to be insufficient to
implement from, *that is a finding worth reporting*, not a gap to paper over with guesswork.

## Your task — `FEAT-01`, in the roadmap's order

`ROADMAP.md` holds the seven rows and their notes; read them there. In outline:

1. **`FEAT-01-01` — the `oneshot` design ruling. OWNER-GATED, and it is the first thing you do.**
   Decision 36 carries a *recommendation* on each edge (show-only key · submit only, not cancel ·
   composes with a project's `after_submit` rather than refusing it · closes even if a callback
   raised) with the reasoning for each. **None is ratified.** Put them to the owner as a ruling
   sheet — evidence, then the question — and wait. Do not implement ahead of the ruling.
2. **`FEAT-01-02`** — implement `oneshot`. Breaking test first (`agents/development.md`).
3. **`FEAT-01-03`** — the payload split, **ruled together with `FIX-02-01`, never separately**.
4. **`FEAT-01-04`** — implement it; feed `CHG-01`.
5. **`FEAT-01-05` / `-06`** — document the flag, and document how to choose between the two
   callbacks. The owner's wording for `-06` is on the row and should survive into the guide:
   *either or both may be used; the recommendation is `on_text_entered` for text-centric work and
   `after_submit` for generic machinery; **not enforced**.*
6. **`FEAT-01-07`** — *consider* rewiring the examples that join the lines themselves, **only where
   it makes the example clearer**. `wontfix` per example is a legitimate outcome, and two of the
   seven live in separate repos.

### Open with a scoped revalidation — not the full checklist

`agents/rules/revalidation.md` applies (session56 was cognitive-heavy), but a **cold review of that
session's work already ran** — `validation/outcomes/session56-input-work-cold-review.md`, verdict
*sound with corrections*, two factual errors found and fixed. Do not repeat it. What it did **not**
cover, because it audited fidelity to the owner's input rather than fitness for implementation:

- **Are Decisions 36 and 37 executable from the ledger alone?** You are the test. Where you have to
  guess, say so.
- **The corrections landed after that review.** Check the corrected text hangs together — especially
  Decision 37's consequence paragraph, which was rewritten.

Report both before starting `-01`, then proceed.

## Facts worth having up front (all verified in code, 2026-08-30 — re-verify before relying on them)

- The submit chain is `before_submit` (truthy vetoes) → empty guard → validate → `on_text_entered` →
  `after_submit`, both callbacks passed the **same** `lines` today
  (`src/controller/userInputController.lua`). Cancel **clears and does not hide**.
- **`after_submit(lines)` is already the documented and actual behaviour**, so Decision 37 moves
  only `on_text_entered`'s payload.
- **Every in-tree consumer simplifies under the split and none pays.** `maze`'s `submit_program`,
  `tixy`'s `submit_body`, `balloons`'s `deliver` and `repl` all call `string.unlines` on the payload
  as their first statement; `turtle`, `valid` and `guess` take `lines[1]`.
- **Only `turtle` closes the widget on submit**, and it keeps its `after_submit` regardless to
  re-arm an echo guard. Do not read that as evidence against `oneshot` — Decision 36 explains why
  the census measures the wrong thing.
- **A downstream consumer stands on this branch**: platform work on the `serial` API took the
  post-merge snapshot as its foundation. The payload split is therefore a breaking change with a
  real consumer, and `CHG-01`'s migration note has an audience.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push**.
- A behaviour change is **never** documented in the commit message alone — it lands in a document,
  or in a code comment where no document fits.
- Say **widget**, not "field" or "overlay" — `FIX-02-09` exists because that drifted, and session56
  had to sweep its own coinage back out.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.
