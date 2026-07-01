# The "safety net" is black-box characterization — strategic re-plan

_LLM(Claude Opus 4.8) + human(Hleb): 2026-07-01 (session 31). Strategic checkpoint on
the #77 "safety-net" phase — why it grew, whether it's justified, and how it converges.
Supersedes the "consolidate four review passes into a punch list" framing of
`session31/prompt.md` with a broader phase re-plan. Actionable form:
[`../plan.md`](../plan.md)._

## The reframe: not a test suite, a formal identification of a black box

What has been called the M4 "safety net" (`tests/input/input_contracts_spec.lua` +
`notes/input-contracts.md`) is not test ceremony. It is the **formal characterization of an
undocumented, organically-grown input subsystem** into something an architect can read,
trust, and reason over. That activity is a *precondition* for extending the subsystem, not a
detour around delivery.

**It was rewrites, not review passes.** The suite went through instrumental → built against a
*wrong architectural model* → the intended contract shape but not yet trusted. Each rewrite
converged toward a target that was **being discovered, not transcribed** — which is why "four
passes" reads as thrash only if you assume a stable target existed to begin with. It didn't.

## Why this is legitimate, not a rabbit hole

- **The architecture's own author was mind-blocked designing #77 against it.** When a system
  exceeds the mental model of the one person who should hold it, its accidental complexity has
  crossed into *critical* technical debt. Characterization retires exactly the debt that was
  blocking the design.
- **The exercise generates real knowledge, not noise.** The 2026-07-01 assessment
  (`notes/assessment/`) — done *because* the human was reviewing the net and asking "does this
  describe desired reality or a guess?" — surfaced genuine latent facts: the `keyreleased`
  routing fork, `inspect`-mode input suppression documented nowhere, four incompatible
  `reset()` implementations, `search` invisible to the entire design corpus. None imagined.
- **This is the M4 *integration* risk firing, as forecast.** Estimation named M4 the widest
  tail precisely for integration. The heavy net + system re-documentation *is* that risk
  materializing: without a re-documented system there was **no criterion to judge integration
  success vs. catastrophe**. So the phase is the anticipated risk surfacing on schedule, not
  scope drift.

**The acid test (falsifiable).** Once the net is frozen, M4 lands test-first against it in
*one* pass, not four. If M4 also thrashes, the thesis was wrong and we say so. The strategic
questions raised this session aren't defensive posture — they're the acknowledgement that
should happen anyway to confirm we're in legitimate unplanned research, not a rabbit hole.

## "Trust" made operational — the definition of done

The recurring blocker was that "I trust it" has no stopping condition, so any rewrite passes
it by feel. Replace the feeling with a checklist. The net (doc + suite) is **done** when all
four hold:

1. **Complete by construction, visibly** — every mode × channel cell
   (console/editor/search/project × keypressed/textinput/keyreleased/pointer) has a named row
   or an explicit `pending`/gap marker. No silent absence. (Per-mode `describe` nesting is what
   makes a hole visible on sight — that is *why* it is first-order, not cosmetic.)
2. **Every assertion carries provenance** — traces to a design clause, a stakeholder quote, or
   an explicit tag *"characterized from current runtime, not yet ratified as desired."* An
   untagged assertion is where a hallucination hides; "no untagged assertion" *is* the
   anti-hallucination guarantee.
3. **Architect-legible cold** — the architect can read any block with no session memory and
   state what it guarantees and why.
4. **Every surfaced gap logged with a disposition** — fix-now / defer-to-Mx / accept-and-document.
   Nothing floating.

## Scope decision — whole-subsystem is already mapped; the act now is classification

The subsystem is already described/mapped end to end. The residual risk of one more blind
spot is **explicitly accepted**. The remaining work is not more discovery but **classifying
findings by #77's blast radius**:

- **In blast radius** (routing of keypressed/textinput/keyreleased across the four modes, the
  overlay gate, submit/cancel/limit) → characterize *and* enforce now; this is what the net
  guards.
- **Out of blast radius** (four `reset()` implementations, `inspect`-mode suppression, `search`
  sub-widget, the `keyreleased` console-only fork, cursor two-layer split) → **mark as
  foundation for the stated future work: adopting the new input API into console/editor.** They
  are captured now, deliberately, so that later integration isn't a re-run of the same
  tech-debt mess. Not discarded, not silently dropped — logged as future-integration
  groundwork.

## Two-part canonical doc — current reality vs. designed API

The canonical input doc should carry two clearly separated parts (possibly two files):

- **(A) How the system works today** — the current-reality characterization (the black box
  formally identified). Normalized from `notes/input-contracts.md` + `notes/assessment/*` +
  `internals/user_input.md`. This is the doc the test suite validates against.
- **(B) The input API designed on top of it** — the design corpus (`design/design.md`,
  `design/spec.md` + slices). Already exists; this side is the *desired* reality.

The **excess prose** the human's `-- REVIEW:` remarks flag in the suite is not just noise to
delete — it is **raw material for normalizing doc (A)**. Move the "what/why" into prose doc
(A); keep the suite as *enforcement derived from* (A), carrying rationale by doc-link, not
inline essays. Splitting these two loads is what shrinks the "trust" problem: prose can say
"why," an assertion can only say "this equals that."

## The bet, and the expected payoff

Collapse the current **processual debt** in one convergent pass:

1. Re-normalize/update the canonical current-behaviour doc (A), splitting current-reality from
   designed-API.
2. Validate the existing suite against (A).
3. Clean up the suite to the definition of done — the human's read is that the ~65 `-- REVIEW:`
   remarks pin only a couple of real misunderstandings; most are cosmetic and eliminable in a
   single pass.
4. Classify out-of-blast-radius findings as future-integration foundation.

That convergence *is* the definition-of-done being satisfied. Then M4–M8 proceed **without
delay** — expected to be fast, because the human is fast at decisions **once the coordinate
system is mapped correctly**, which is exactly what this phase delivers.
