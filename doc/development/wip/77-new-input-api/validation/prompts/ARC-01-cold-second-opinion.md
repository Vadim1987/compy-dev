# ARC-01 — cold second-opinion commission (session47, 2026-08-26)

**Model:** Fable, by the charter's own test — this reinterprets a ratified decision and being wrong
is expensive (a structural refactor at the pre-PR gate). **Deliverable:**
`validation/outcomes/ARC-01-cold-second-opinion.md`. Prompt of record per sub-agent hygiene (c);
handed to the agent verbatim below.

---

You are giving an independent architectural second opinion on a proposed refactor in a LÖVE2D/Lua
codebase at `/repo`. **A proposal, not a plan you are helping execute.** Your job is to say whether
it is sound, and to make the strongest possible case *against* it before you agree with it.

## Hard boundary

**Do not read anything under `doc/development/wip/77-new-input-api/`.** That tree holds the
proposing session's own reasoning, and reading it would give you the conclusion instead of the
evidence. Everything else in `/repo` is fair game and you are expected to read the code:
`src/controller/consoleController.lua`, `src/controller/controller.lua`,
`src/controller/userInputController.lua`, `src/controller/projectInputController.lua`,
`src/main.lua`, `tests/`, `doc/development/decisions/input.md`,
`doc/development/internals/user_input.md`, `doc/input_api.md`.

## Tooling

- **`lua-lsp` MCP is DOWN.** Use `grep`/`rg` and read the files. Where you would ask an LSP "who
  calls this", grep all of `src/` and `tests/` and read each hit — Lua is dynamically typed, so a
  name match is a hint, not a fact.
- Suite: `busted tests` from `/repo`, no display needed. Currently `970 / 0 / 0 / 10`. The 10
  pending are a deliberate owner ruling, not a finding.
- **Never pipe a counting grep to `| head`** — it has silently undercounted twice in this project.

## The situation

`compy.input` is the API a sandboxed user project uses for input. Behind it sits a private `state`
table built by a closure that runs **once per application**. Two defects were fixed today, both the
same shape — a store on an application-lifetime object holding something a *project* put there,
surviving that project's stop and reaching the next one:

- commit `bd2a5d49` — a hidden-`configure` stash (`pending`) survived project stop;
- commit `8a9022ec` — the prompt label (`model.custom_label`) survived project stop.

Both fixes are **hand-maintained wipes** at teardown (`reset_widget_outputs` in
`src/controller/controller.lua`). A third store was missed for months because that wipe list is
maintained by hand and nothing forces it to stay in step with `apply_config`, the function that
writes the fields.

## The proposal

Give the **project's input widget a per-project-run lifetime** — construct it when a project starts,
destroy it when the project stops — instead of constructing it once at application load. The
teardown wipe machinery then deletes: nothing needs clearing because the object holding it is gone.

The argument that it does not violate the ratified decision: **Decision 3**
(`doc/development/decisions/input.md`) forbids allocating a fresh object graph **per input session**
— its stated reason is repeated prompting on a memory-constrained device. A *project run* is a much
coarser boundary than an *input session*. So the claim is that the NFR was applied one boundary
wider than it states, and per-run construction honours it rather than withdrawing it. Read Decision 3
yourself and judge whether that reading is honest or convenient.

## What you are asked to judge

1. **Is the reading of Decision 3 sound**, or is it motivated reasoning that will look like a
   loophole to a stakeholder? This is the crux — say so plainly either way.
2. **Is per-run construction actually simpler**, or does it move complexity somewhere less visible?
   Consider what has to happen when `love.state.user_input_controller` is nil between runs, and
   whether every consumer handles that. Enumerate the consumers yourself.
3. **The one coupling the proposal identifies:** `get_compy_input()` in `consoleController.lua`
   captures the widget's `callbacks` and `pending` tables **by reference**, so a replaced widget
   would leave the API surface pointing at a dead object. The proposal is to resolve them
   dynamically instead. Is that sound, and what does it cost? Note there is a standing owner ruling
   that `compy.input.callbacks` **is** the widget's own table (identity, not a copy) — assess
   whether dynamic resolution can preserve what that ruling was protecting.
4. **Which seam** — construct at project *open* or at project *run*? They differ; say which and why.
5. **What breaks that the proposal has not mentioned?** This is the highest-value part of your
   review. Look especially at: the input *view* and how it is bound; anything that caches the widget
   or its sub-objects across a run boundary; the editor and console widgets (are they affected at
   all?); and the test fixture in `tests/helpers/input_fixture.lua`.
6. **Sizing.** The proposal claims production is ~5 files and net *deletion*, with the real churn in
   ~101 test touchpoints concentrated at one fixture seam. Check that. If it is wrong, say by how
   much.

## Context that constrains the answer

- This is a **pre-PR validation phase**. The code landed long ago; what remains is stress-testing it
  before it ships. The feature's mandate from stakeholders was *a simpler and more robust input
  API*, and it must not carry moving parts beyond that ask.
- The repo is **86+ commits behind upstream** and an upstream reconciliation is still pending, so a
  structural change now has merge cost.
- The alternative on the table is smaller: keep the singleton, and add a single `reset_config`
  function symmetric to `apply_config` so the wipe list has exactly one home instead of being
  scattered. **Compare the two honestly** — including the possibility that the smaller one is
  sufficient and the refactor is not worth it now.

## Deliverable

Write to `/repo/doc/development/wip/77-new-input-api/validation/outcomes/ARC-01-cold-second-opinion.md`
(writing there is fine — the ban is on *reading* that tree).

- **Verdict** — `sound, proceed` / `sound, but not now` / `unsound` — one sentence.
- **The strongest case against**, stated first and in good faith, before any agreement.
- **Answers to the six questions**, each with the file:line evidence that settles it.
- **What the proposal missed**, if anything.
- **Sizing check** — agree / disagree with numbers.
- **What you could not verify** and why.

Do not commit to git. Do not modify any file except your deliverable. Being right matters more than
being agreeable: if you think this should not happen, the useful thing is to say so now.
