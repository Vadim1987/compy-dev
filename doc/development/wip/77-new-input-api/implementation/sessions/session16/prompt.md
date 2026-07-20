# session16 — prompt

Read and strictly respect `agents/sessions.md`.
You're working inside `agents/validation.md` flow.
Read `../../../validation/plan.md`.

Your predecessor (session15) completed **TF1** (+ a readability sub-describe amendment),
started **TF2** (owner human review — in progress), and — as a **side-product** — captured an
owner-sketched **input-API redesign**. Read `../session15/report.md`.

## Process pivot (owner directive, 2026-07-20)
This session is **NOT** the default post-TF1 revalidation task. TF2 is mid-flight and must
still be finished **against the current implementation**; but the *plan after TF2* may change
because the review surfaced a coherent redesign idea. So S16 is a **preliminary analysis +
plan review, led by Fable**.

## Your task
1. **Read the redesign artifacts** (both under `validation/notes/`):
   `input-api-redesign-proposal.md` (the 3-component chain + widget-callbacks + vocabulary +
   decision-by-decision keep/supersede map) and `input-api-redesign-evaluation.md` (the
   orchestrator assessment + the 7 resurfacing tensions + risk/watch-items). Ground yourself in
   `../../../decisions/input.md` (the 13 ratified decisions) and the live chain in
   `src/controller/projectInputController.lua` — verify claims in code, don't take the notes on
   faith (charter rule).
2. **Commission Fable** to pressure-test the proposal — chiefly the **Decision-6 layering seam**
   (is "widget owns Enter/Esc" safe *only* if the controller, not the model, owns
   detect+propagate while the parent context owns lifecycle?), the D10 hook-unification
   precedence, the loosened-D7 guard boundary, and whether the vocabulary is internally
   consistent and complete. Materialize the Fable prompt + verdict on disk (hygiene c:
   `validation/prompts/`, `validation/outcomes/`).
3. **Review the plan**: propose how TF2 finishes against the current impl, and how (or whether)
   the redesign becomes a bounded, tests-first Phase-B/refinement step vs a fast-follow. Output a
   short plan-revision under `validation/reviews/`. This is judgment, not code — no edits to
   `src/` or the frozen `design/`.

Gate discipline: iterate with the owner until explicitly approved; do not wrap early. Delegate
mechanical/wisdom work down (Sonnet / Fable), always passing the model explicitly.
