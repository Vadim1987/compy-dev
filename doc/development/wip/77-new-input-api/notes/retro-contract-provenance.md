---
description: Methodology retro for #77 — why the contract record drifted into encoding
  implementation mechanism, and the one cheap discipline that prevents it. Cross-cutting
  SDLC lesson, not an input-feature fact.
status: reference
audience: design / method
---
# Retro — provenance and altitude in a preservation contract

A standing lesson extracted at the close of session 27, after the intent-fidelity audit
(`intent-fidelity-audit.md`) localized the #77 drift. Recorded here because it is a
**process** lesson that outlives this feature, not a fact about the input API.

## What happened, in one mechanism

The feature dropped backward-compatibility. **Backward-compat had been a blanket
preservation contract with a built-in owner** — everyone agreed "keep it all," so "what
must not break?" needed no per-behaviour judgment. Dropping it silently transferred that
judgment onto the contract derivation. The derivation answered with the only data
available — **current behaviour** — and current behaviour carries no provenance for
*must-keep*. So the contract record encoded *how the system behaves* precisely because
*how it behaves* was the only answer on hand once no one owned *what must survive*.

The symptom showed up three times, same disease each time (see
`input-routing-model.md`): keyboard routing keyed on widget presence; the `keyreleased`
drop; pointer routing as inter-route BOTH. Each was today's implementation mistaken for
the invariant — the exact thing #77 exists to cure, leaked one level up into the
contract meant to govern the cure.

## Two altitudes were conflated

A behaviour can be described at three altitudes: (i) implementation detail, (ii)
behavioural mechanism ("widget up → widget consumes"), (iii) design intent / principle
("the active route owns input; the widget is operational"). Deriving the safety net
"one level up" from examples correctly dodged altitude (i) — but landed at (ii). The
discriminator **invariant-vs-accident is only decidable at (iii)**: a behaviour stated
at the mechanism altitude can still be an accident; only the *why* tells you which. The
net encoded *how* when the thing that distinguishes a contract from a coincidence lives
in the design-decision record, not the test spec.

## The one cheap discipline (the actual lesson)

Not "do heavy SDLC for tests too" — that would be the wrong takeaway. The
non-skippable thing was never a revalidation *chain*; it was a **single column**:

> Every PRESERVE claim must answer **"who decided this must hold?"** — a tier-1/2
> mandate, or an explicitly ratified design principle. A claim that can answer neither
> is **CHARACTERIZE-PROVISIONAL**, never PRESERVE.

Empty cells in that column *are* the drift, and they surface at near-zero cost. The
provenance gate is a **two-way valve** and must stay one: "no provenance" has two valid
outcomes — find the owner, **or** tag provisional. The failure mode of the cure is
manufacturing a mandate for every unowned behaviour — the mirror of the original
disease.

## The drift was productive (reframe the "waste")

The implementation-shaped tests were not wasted effort; they were the **probe** that
found the architecture had never recorded its *why*. You cannot formalize intent you
don't know is missing. The real output of that exercise was not the tests — it was the
discovery of the empty provenance cells, i.e. the architectural core now being
formalized. Nothing here was avoidable: starting from the full remedy (cold audit +
provenance gate) would have been over-theorizing; the probe is what justified it.

## Carry-forward

- The provenance column is now enforced in the contract correction (`prompt12.md`) and
  its review (`prompt13.md`). Keep it on any future preservation contract, in any
  feature.
- When backward-compat is dropped, the preservation question's owner is the
  **architect**, via **preserve-by-default** (everything not authorized-to-change keeps
  working) — *not* a stakeholder enumeration. Calibrate the reverse-engineered
  characterization against documented change-intents, and state kept behaviours at
  intent altitude. See "Was the layering worth it?" below.

---

## Was the layering worth it? (added s27 close, after architect contest)

The sharper question: did the layered analysis (design → contract net → tests)
over-invest, vs. a leaner "acceptance tests only" or "implement with some testing"?

**Preserve-by-default, not stakeholder-enumeration.** An earlier draft of this note said
"ask the owner which surfaces must survive." That is a junior move — most existing
scenarios are unformalized, partially formalized, or only manually retested when not
forgotten; you cannot ask for an enumeration that does not exist. The correct rule is the
architect's: **everything not explicitly authorized to be altered must keep working**, and
deciding what "everything" and "must keep working" mean is the architect's call, obtained
by reverse-engineering the platform (cheap, and an asset regardless). So the operative
provenance question **inverts**: not "who decided this must be kept?" but **"where is the
authorization to *change* this?"** — absent one, it is preserved.

**The missing step was calibration, not the net.** The reverse-engineered characterization
was correct; it simply was not subtracted against the **already-documented change-intents**
(the design decisions). A behaviour authorized to change (e.g. the keyboard overlay gate M4
deletes) got frozen as `preserve`. One calibration pass — characterized behaviour ×
change-intent — would have saved the weird-specs iteration. That pass is the cheap,
non-skippable step; the contract-record ceremony itself was risk-proportionate (below), it
was just run uncalibrated. *[Corrected — see "Architect's attestation" below: the
calibration was not missing; it was deliberately gated on the materialized outcome (the
test suite), not the prose. The one iteration was the chosen price of a more reliable
gate, not an omission.]*

**Preserve-by-default still over-freezes accidents — so altitude is the second filter.**
Calibration alone is insufficient: not everything currently-working is a *requirement*;
some is accident. `pointer-BOTH` is the proof — no change-intent named pointer routing (the
gate being removed was keyboard-only), so calibration would have *kept* it, yet it should
change. What exposes it is stating the kept behaviour at **intent altitude** ("the active
mode owns input exclusively"), where the accident is visibly not a requirement; at mechanism
altitude ("the mouse path reaches both") it is invisible. A preservation net needs **both**
filters: (1) subtract documented change-intents, and (2) state each kept behaviour at
intent/surface altitude, never mechanism.

## When is heavy upfront testing worth it? (the TDD question)

"Implement these specs with some testing" produces worthless tests — they assert that the
code does what the code does (mock-lambda callability), because their source of truth *is
the implementation*. Manual testing leaves no tangible artifact and does not scale. Neither
is the answer. The criterion for how much net to build:

> Net value scales with **blast radius × opacity** — how many existing surfaces depend on
> what you are changing, times how poorly their guarantees are documented/tested.

A low-blast-radius, transparent leaf feature: test it by hand and forget it; a formal net
is overkill. A change that **alters a load-bearing architectural column across multiple
levels** whose existing guarantees are **neither well-documented nor well-tested**: both
factors maxed → heavy upfront testing is *matched to the risk*, not overcommitment. It looks
waterfall but is not: waterfall front-loads *everything* regardless of risk; this front-loads
*only the load-bearing, opaque part* and stays iterative (shoot-and-correct) elsewhere. That
is risk-proportionate front-loading.

**The one principle under all of it.** Design ceremony, the contract net, the provenance
gate, rejecting "some testing" — one rule: **a test or contract is worth its weight only if
its source of truth is independent of the implementation it guards.** Trivial LLM tests fail
it (source = the code); mechanism tests fail it (source = current internals); acceptance
tests and calibrated invariants pass it (source = the spec / the authorized-change delta).
That independence is what costs effort — and what you are buying.

## Architect's attestation and correction (s27 close)

The architect contests the "missing calibration" reading, and the evidence is on disk:
the disputed suite carries **tens of inline REVIEW remarks** ("why is it this way?"). That
*is* the calibration — the outcome stress-tested against the intent the architect held —
and it is exactly what surfaced the drift. So calibration was **not** missing; it was a
**deliberate choice of gate**:

> Treat the contract prose as an **intermediate**, not a review target. Good prose can
> encode a bad spec and bad prose a good one, so reviewing the prose for fidelity gives
> false confidence. Gate instead on the **materialized outcome** (the executable tests),
> which is concrete and interrogable against intent.

This is the same distrust-of-prose-as-contract the whole feature exists to address, applied
reflexively to one's own process. It is sound. Corrections to this note's earlier framing:

- **The calibration *content* stands** (subtract authorized changes; state at intent
  altitude) — but the point is its **placement**: on the outcome, not the prose.
- **The "extra weird-specs iteration" was not waste** — it was the *designed cost* of a
  high-reliability gate. Prose-review would have been cheaper but lower-reliability, and it
  **does not replace** the outcome review, so skipping it was rational, not negligent.
- **Choose the review gate by reliability, not earliness.** For load-bearing work the
  reliable gate is the materialized artifact; accept one materialization cycle as its price.
- **One nuance retained:** the contract prose is also the *persistent regeneration source*,
  not only a throwaway intermediate — so once the outcome review has told you what is wrong,
  the source earns a fidelity pass (this is precisely the prompt12 correction).
  Outcome-review finds the drift → fix the persistent source → regenerate. That sequence is
  optimal, and it is the one that was followed.

Net: the process caught the drift by the right mechanism at the right gate. The standing
lesson is **gate-by-reliability**, not "calibrate earlier."
