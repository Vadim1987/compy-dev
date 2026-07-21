# Owner attestation (2026-07-20, session18) — the real smell is context-dependent behaviour, not the state read

Sharpens `../reviews/R4-open-issue-uic-mode-leak.md`. Verbatim owner framing on boot of the
open-issue analysis:

> My bigger concern about the abstraction leak is that **referencing state is a symptom** — the
> real smell is the **context-dependent behaviour difference inside UIC**. Which may prevent
> unification of input management **conceptually**, and may be an early signal of future problems
> with future adoption of the new input API inside the editor. Which, if it happens, would violate
> one of the requirements for the current feature — **editor migration is *not* demanded, but the
> API *should make it possible***. That's why I am concerned — I do not want to close R being
> afraid it would smuggle rubber-stamped tech debt into the future.

## Why this raises the bar for the analysis
- The fix is **not** merely "stop reading `love.state`." Swapping the global read for an injected
  flag/config (option B) removes the *symptom* but may leave the *behaviour fork* — UIC doing
  different things depending on who runs it — intact. If that fork is the thing that blocks a
  future editor migration onto the new API, B is lipstick.
- The acceptance test for any option is therefore not "is the leak gone?" but: **does UIC end up
  with one uniform input-management concept, such that the editor could later adopt the new API
  without UIC needing to know it's the editor?** An option that keeps a hidden mode-fork inside
  UIC fails that test even if it reads no globals.
- Requirement anchor to re-verify against the frozen design/spec: *editor migration not demanded,
  but must be **made possible** by the API.* Confirm this is an actual stated requirement (design/
  or stakeholder intent), not paraphrase, during revalidation.
- Consequence for R's close: R must not close if the disposition merely rubber-stamps the fork as
  tech debt. Closing is legitimate only if either (i) the fork is removed/relocated so UIC is
  concept-uniform, or (ii) we can show with evidence the fork does **not** obstruct future editor
  adoption and is honestly recorded as bounded, owner-ruled debt — not smuggled.
