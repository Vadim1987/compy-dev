# Commission — oracle review of the input-usage principles (Fable, session36)

**Model:** Fable (passed explicitly). **Mode:** judgement, read-only. **Deliverable:**
`doc/development/wip/77-new-input-api/validation/reviews/S36-fable-principles-review.md`.

You are being asked for judgement, not verification — that is why this costs what it costs. Be
willing to say the proposal is wrong, or right for the wrong reason, or right but not now.

## What you are reviewing

`doc/development/wip/77-new-input-api/validation/reviews/S36-input-usage-principles.md` — five
principles for **how projects should use** the input API, plus one proposed new primitive. §1 is
the owner's, §2 is the assistant's assessment and contests, §3 is the knock-on. Read it whole.

If ratified, §1 goes into the persistent corpus (`doc/input_api.md`, and whatever is
decision-shaped into `doc/development/decisions/input.md`), and the plan is replanned around it —
**including possibly reverting landed work and discarding steps**. So this is not a style review.

## The frame it must be judged against (owner's, not negotiable by you)

Stakeholders asked for a **simpler and more robust input API**. The PR must be reviewable from
`doc/input_api.md` + the PR description **alone**, and must not carry moving parts or vocabulary
beyond that ask without a one-line justification. The standing test is never *"is it approved?"*
but *"does it make the system more predictable, or merely more elaborate?"*

## The questions, in priority order

1. **Do the five principles hold together, and are they true?** Especially P1's notion of
   "stateless transition" and P2's claim that interdependent shortcuts are an architectural smell
   rather than a bug to be fixed case by case. Is there a case the principles get wrong — a
   legitimate use of a mirrored pair, or of a shortcut for continuous state?
2. **Is P5.1 (`Key.pressed('ctrl','!shift','h')`) justified in THIS release?** It is new API
   surface in a feature mandated to simplify. The owner's justification is boilerplate removal,
   fewer moving parts, and low cost. The assistant's §2.3 argues it dissolves a live problem
   (sapper) with no behaviour change at all. Weigh both against the frame. **"Right idea, wrong
   release" is an available verdict** — and so is "the principles are worth more than the
   primitive; ship the prose, defer the code".
3. **Is the exclusivity question (§2.2 C2) answered correctly?** The shortcut vocabulary makes
   `'shift+*'` mean *shift and no other modifier*. Should the query default to permissive with `*`
   for exclusivity, or exclusive by default, or something else? This is the one open design point.
4. **What is missing?** Name what the principles fail to cover that a project author will hit.
5. **Does anything here contradict what is already ratified?** Decisions 8, 21, 26, 30 and 31 are
   the live ones (`doc/development/decisions/input.md`). Contradiction is a finding, not a
   footnote — but note that superseding a decision *deliberately* is legitimate if it is stated.

## Rules of engagement

- **Verify factual claims in code before relying on them** — yours, the owner's, and especially
  the assistant's. The tree is the authority. `src/util/key.lua` (the `Key` module),
  `src/controller/projectInputController.lua` (`find_shortcut`, the chain),
  `src/controller/controller.lua` (`combo_string`, click synthesis, the gateway's reserved
  combos), `doc/input_api.md` (the project-facing guide).
- **The `lua-lsp` MCP server is available** (defs / refs / diagnostics over a real AST). It misses
  occurrences routed through metatable `__index` on string keys; grep is the completeness backstop.
- `src/examples/{keyboard,maze,balloons}` are **separate git repositories** nested in the tree.
- **Write your report to the deliverable path early and update it as you go** — a previous
  reviewer lost a full pass to an infrastructure failure with nothing on disk.
- Read-only: change no file but your own report, make no commit, never push.

## Evidence you should know exists, and may challenge

- Three defects found **before** the principles were written, each an instance of P2: the `alt+h`
  overlay pair (a modifier's own release has no expressible combo, so the closing binding cannot
  be written); the guide's own flag-shortcut example (bare `'space'` on both channels, missed when
  an unrelated modifier is held at release); and sapper's derived-click echo.
- `love.keyboard.isDown` **raises** on an unknown key constant (checked in the engine), which is
  the basis of the assistant's argument that variadic tokens fail loudly where a proxy table would
  fail silently.
- Two adjacent proposals already in the persistent register (`doc/development/technical_debt/
  input.md`): a held-state surface whose implementation can be swapped behind it, and
  `compy.states` — arbitrary conditions polled with on/off callbacks at their transitions. Judge
  whether P5.1 makes either redundant, or vice versa.

## The report must contain

- A **verdict** on the principles (ratify / ratify-with-changes / do not ratify) and a **separate
  verdict** on P5.1 in this release.
- Your answer to the exclusivity question, argued.
- Anything the assistant got wrong, named.
- What you could not determine.
