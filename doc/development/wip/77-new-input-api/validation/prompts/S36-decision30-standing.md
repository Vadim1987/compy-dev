# Commission — does Decision 30 survive its corrected premise? (cold, session36)

**Model:** Sonnet (passed explicitly at spawn). **Mode:** read-only analysis. **Deliverable:**
`doc/development/wip/77-new-input-api/validation/outcomes/S36-decision30-standing.md`.

## The question, exactly

**Decision 30** (`doc/development/decisions/input.md`) dissolved the framework's tracked
held-key set: the combo matcher now asks the keyboard directly, and `compy.input.keys_pressed`
no longer exists. Three steps of work have already executed on that basis (~16 commits).

The owner has raised a challenge to it and it must be answered on evidence:

> One of the decision's premises was **"nothing uses it"**, and that premise was **FALSE** — the
> biggest input-heavy example (`src/examples/keyboard`) read that surface. Moreover, that
> example had **independently developed a model of the same shape** before the framework offered
> one, which the owner reads as *a symptom that such a model was needed*.

**Your question: does the decision survive the corrected premise?** Not "was the reasoning
tidy" — whether the conclusion is right, now that one of its stated grounds is known to be wrong.

## What you must not do

- **Do not trust the author of the work.** The session track, the plan, and the commit messages
  in this range are **the author's claims**. So is the reasoning summarised below. Verify in code
  and in git history.
- **Do not confirm by default.** A cold review that agrees with the author because agreeing is
  easier is worthless. If the decision does not survive, say so plainly and say what it costs.
- Do not change any file except your own report. No commits, no pushes.

## The claims you are testing (each one is the author's; check each)

1. `keys_pressed` **did not exist before this feature** — zero occurrences in `src/` at the PR
   base `3256aac`, entering in `2a156025`. So dissolving it removes the feature's own addition
   rather than pre-existing functionality.
2. The keyboard example's reliance on it was **created by this feature**, in the example repo's
   commit `4814407` (2026-08-03), which migrated the example off its own mirror onto
   `compy.input.keys_pressed`.
3. The example's **own** mirror (`INPUT.held`, first seen in that repo's `79260c5`) existed
   primarily for **repeat detection** — `if INPUT.held[k] then return end` — and that inference
   is what made its Alt-keys scene deaf on the device while working in the IDE.
4. Every **surviving** read in that example is a live *"is this down right now"* question —
   modifier folds for a chord filter, Caps reconciliation, a keycap renderer drawing outside any
   event, and `help.lua`'s `h` — none of which needs event-derived history.
5. The genuine loss is **enumeration** ("which keys are held"), which a device poll cannot
   answer, and which nothing in the platform or examples currently needs.

## What the answer has to weigh

- **The owner's convergence argument on its own terms:** an independent implementation appearing
  in the biggest example is evidence of an unmet need. Your job is to identify **what need**, and
  whether a framework-tracked set exposed to projects is what meets it — as against `isrepeat`
  (edge semantics), `Key` (modifier folding), a device poll (current state), or the held-condition
  abstraction sketched in `doc/development/technical_debt/input.md` ("A chord that gates a state
  while it is held has no vocabulary", and the `compy.input.keys` proposal above it).
- **The reversed argument.** Decision 29 previously held that an event-time question is answered
  from an event-tracked set (the "two clocks" reasoning). Decision 30 reversed it. Is the reversal
  sound, or does event-versus-device skew matter somewhere real — including `src/harmony`, which
  fakes modifiers to the poll and injects events?
- **Staleness.** The withdrawn P9d recorded that a tracked set is never cleared on focus loss.
  Weigh that against whatever the set bought.
- **Cost of reversal**, stated but NOT decisive: reversing now unwinds three executed steps;
  reversing after the PR is worse. Say what it would take; do not let it drive the verdict.

## How to work

- **Write your report to the deliverable path immediately and update it as you go.** A previous
  reviewer lost a full pass to an infrastructure failure with nothing on disk.
- **The `lua-lsp` MCP server is available** (defs / refs / diagnostics over a real AST of
  `/repo`) — use it to resolve symbols and prove callers. It **misses** occurrences routed through
  metatable `__index` on string keys, which the keyboard example uses heavily, so grep is the
  completeness backstop and the two are cross-checked.
- The three example repos under `src/examples/{keyboard,maze,balloons}` are **separate git
  repositories**; their history is invisible from the platform log — `cd` into them to use `git`.
- `busted tests` → expect 942 / 0 / 0 / 10.

## The report must contain

- A **verdict** at the top: does Decision 30 survive its corrected premise — yes / yes-with-
  qualifications / no.
- The **need** the example's independent model was actually reaching for, argued from its code
  and its history, not from the author's summary.
- Any claim above you found **false or overstated**, with the evidence.
- What is genuinely **lost** by the decision, and who would notice.
- What you **could not determine**.
