# S27 sub-agent prompt of record — cold review of the plan's quality

**Model:** Fable (wisdom oracle). **Spawned:** 2026-08-07, session27.
**Nature:** judgment. Read-only. Cold by design — you are being asked precisely
because you did not participate in producing the plan.

---

You are working in the LÖVE2D project **compy**, repo root `/repo` (your cwd).
**Read-only**: do not edit source, tests or docs; do not commit; do not push.
Your only write is one markdown file, named at the end.

## The situation, stated plainly

A feature called the "new input API" (issue #77) has been implemented over
roughly 27 working sessions and is now being prepared for a pull request. The
code landed long ago; what remains is stress-testing it against intent and
common sense.

The project owner reviewed the entire branch and left **187 inline remarks** in
the code, tests and documentation. Those were extracted verbatim, then triaged
into workstreams with an execution plan. **You are reviewing the plan, not the
remarks.**

The owner's own framing, given in session:

> generally architecture is converged, but some final architectural tweaks are
> still required (mainly: full unification of pointer/keyboard/singleclick
> routing, unification of signature). They do not break architecture
> fundamentally but still slightly change the shape of the final solution.

And the strategic frame that governs the whole phase:

> Stakeholders asked for a **simpler and more robust input API**. The PR must be
> reviewable from `doc/input_api.md` + the PR description **alone**, and must
> not carry moving parts or vocabulary beyond that ask without justification.
> Ratified-but-unexamined design is not exempt. When in doubt the question is
> never "is it approved?" but **"does it make the system more predictable, or
> merely more elaborate?"**

## Read

1. `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`
   — the plan under review.
2. `doc/development/wip/77-new-input-api/implementation/sessions/session26/report.md`
   — what the previous session did and what it learned. Short. Read it: its
   "non-obvious points" section describes failure modes this project has
   actually suffered, and the plan should not be walking back into them.
3. `doc/input_api.md` — the project-facing surface the PR is judged by.
4. Whatever code you need. The plan's central proposals live in
   `src/controller/projectInputController.lua`, `src/controller/controller.lua`,
   `src/controller/userInputController.lua`, `src/controller/consoleController.lua`.

The remark inventory
(`validation/outcomes/S27-remark-inventory.md`) is available if you want to
check what the owner actually said about something — it is large; use it as a
reference, not a read-through.

## The questions I want answered

**1. Is the plan's central bet right?** The plan treats four things as one
architectural movement — dropping `keys_pressed` from hook signatures (so they
equal LÖVE's), adding a modifier-only shortcut tier for pointer events, making
`singleclick`/`doubleclick` first-class members of one event list, and
collapsing the per-event dispatch methods into one loop. Is that genuinely one
change, or is the plan bundling things that should be judged separately? Does
it make the system **more predictable, or merely more elaborate**?

**2. Is anything here scope creep dressed as convergence?** The PR must not
carry moving parts beyond "a simpler and more robust input API". Some of these
187 remarks are the owner thinking out loud, and an owner remark is not
automatically a mandate. Which accepted items would you cut, and which declined
items (§3 of the plan) would you reinstate?

**3. The breaking change.** Dropping the `keys_pressed` argument changes every
hook signature in the tree, including three nested example repositories with
their own remotes (`src/examples/{balloons,maze,keyboard}`) that ship their own
PRs alongside this one. Nothing has been released, so there are no external
consumers. Is the plan's handling of this proportionate — is gating it behind
one owner ruling (phase P1) enough, and is the migration surface correctly
identified?

**4. Ordering.** The plan works code → tests → docs → comments, deliberately
inverting the *commit* order (docs → tests → code). It defers all comment work
to the very end on the grounds that comments written before the code settles
get written twice. Is that right? Is there a phase whose dependencies are
actually wrong, or an item that will be silently invalidated by a later phase?

**5. R080 — the one I am least sure of.** The plan **declines** it. The remark
asks whether the input widget deserves to be a special third tier of the
dispatch chain (it consumes whenever it is shown, rather than by returning a
value like the other two tiers), or whether that specialness is a leftover of a
design that a previous session found to be hallucinated and removed. The plan
argues the widget is a stateful sink with no return value to give, so making it
return a boolean would add a value whose only source is `is_shown()`. **Read
the dispatch function and decide for yourself.** If the plan is wrong here, say
so — it is exactly the kind of ratified-but-unexamined structure the strategic
frame says to challenge.

**6. What is missing?** Not "what else could be done" — what does the plan need
in order to be *safe*, that it does not have.

## How to answer

- **Verify factual claims in code before relying on them.** You have been wrong
  about facts in this project before, and so has everyone else here; the
  defence that keeps working is reading the source. `git show 3256aac:<path>`
  shows a file as it was *before* this feature, and has twice overturned a
  conclusion that "the system has always done X".
- **The `lua-lsp` MCP server is available** — defs / refs / hover / diagnostics
  over a real AST of the `/repo` workspace. Use `references` for impact
  questions ("what breaks if this signature changes") rather than reasoning
  about it. Grep as the completeness backstop; Lua is dynamic and LSP refs can
  be incomplete.
- **Give recommendations, not a survey.** Where you disagree, say what to do
  instead. Where you are uncertain, say how uncertain and what would settle it.
- Rank what you find: what must change before implementation starts, what
  should change, what is taste.

## Deliverable

Write **`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S27-plan-review.md`** —
your answers to the six questions, with a ranked list of required changes at
the top and your evidence cited as `file:line`.
