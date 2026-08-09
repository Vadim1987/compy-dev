# S31 — owner attestation: how we got here, and the meta-question

**Recorded 2026-08-09, session31, at the owner's explicit instruction.** This is
the owner's own account of the thread that led from smoketest regressions to the
current design agenda. It is an attestation of **intent and history**, not an
assistant reconstruction — where it conflicts with an assistant-written summary,
this document wins on intent.

## Amendment to the sub-agent charter

> "cold check through a Sonnet" — **could be also an Opus if judgement-heavy.**

So the model tier is chosen by the *nature of the check*, not by a blanket rule:
Sonnet stays the default for mechanical/scoped work, Opus is permitted for cold
checks that carry judgement, Fable stays the expensive oracle. The standing
requirement to **pass the model explicitly** is unchanged.

## How the thread started, in the owner's words

1. The owner was **moving through smoketest regressions, fixing them.** The intent
   was: land the fixes, then do prose cleanup, then plan for rebasing/merging with
   upstreams that have moved forward.
2. The proposed fix for `keyboard`/`textinput` in the keyboard example's "alt"
   subgame **looked too tactical and fragile**. The owner asked whether the example
   could be rewritten to **judge on the `textinput` sequence only**, thus
   *dissolving* the ordering problem rather than patching it.
   - 2.1 The model **hallucinated**: it wrote the owner's intent down incorrectly,
     started dragging them into a design built on **self-inflicted constraints**,
     and **presented newly-created plumbing as pre-existing**.
   - 2.2 The next session cleared the hallucinated design document, and confirmed
     several strategic points:
     - **a)** The `keyboard` minigames **share an input-management structure**, so
       fixes delivered there must be coherent across them. The owner's intent:
       **rewire `keyboard` and `maze` onto the new input API**, thereby eliminating
       in-project mechanisms that now duplicate platform ones — but do it
       **accurately, respectfully, and without regressions**. **Caveat flagged by
       the owner: `keyboard` apparently relies on draw-time polling for
       visualization, and session29 likely overlooked it.**
     - **b)** The **harmony** subsystem was discovered — non-production (dev-env
       rather than shipped) — **whose existence the whole design of this feature
       did not take into account**.
     - **c)** A **theoretical incompatibility** between `Key.*` polling (the only
       mechanism for combos/chords before the feature) and event-driven tracking
       (which the owner introduced as a tool for centralising and unifying
       modifier/chord logic) — or at least a **limited** compatibility, because the
       two live in slightly different timelines.

## The open questions, as the owner frames them

- Is the **"polling problem"** real?
- **How severe** is it?
- **How should it be mitigated?**
- **Which rules** should we recommend regarding **mixing** both approaches?
- **Which boundaries** should we put between them?

## The meta-question (the actual ask of session31)

> How deep should I inspect these? Can I draw an **operational boundary** for
> myself that would allow shipping the new input architecture **now** —
> deliberately postponing rebuilding editor/console on it — and address the
> console/editor rebuild as well as the "polling problem" **later, in separate
> PRs**, **but without a risk of redoing the current work**?

The risk the boundary must exclude, in the owner's words: **shipping a new input
API which won't be further supportable, or not enrollable into
editor/console/harmony, due to some unforeseen fundamental limitations, would be a
big mistake.**

So the test for any deferral is **not** "is it safe to ship?" but "**does shipping
this now commit us to anything we would have to undo later?**"

---

## Addendum (2026-08-09) — the motivating platform bug, in the owner's words

Recorded at the owner's instruction, mid-session, as the evidence census returned.

> Prior to the feature, a user input widget activated by a project acted as a
> **modal** control, without runtime controls or callbacks. Once activated, it was
> only possible to **poll** the input text; **keyboard events were fully consumed
> by it**, thus **preventing any modifier combos from reaching the project**; and
> there were **limited abilities to destroy/recreate it reliably** (the primary
> mechanism was self-closing on one-shot input).
>
> The new system solves this problem, both by **changing the event propagation
> schema** and by **providing more controls/callbacks on input solicitation**.
> **So it is a win for the platform.** But whether the result is **adoptable** and
> **appropriate** is the open question.
>
> Maybe an appropriate move now would be to **reduce feature scope**, not fix all
> obstacles blocking release. On the blockers side: **only one keyboard subgame
> was not working** — supposedly due to relying on `keypressed`/`textinput`
> order. The remaining blockers were **readability of changes** and the **need to
> catch up with advancing upstreams**.

**Corroborated in the corpus, not merely accepted:**
`doc/development/decisions/input.md:73` describes exactly this — *"a shown widget
swallowed the project's key events wholesale"* — and **Decision 1** (route-centric,
not widget-centric routing) is stated there as **"the single structural change the
subsystem exists for"** (`:95`). The owner's account and the ratified record agree.

**Consequence for the session31 census.** The two "regressions" found in `turtle`
and `maze` are **not accidental breakage**. They are the direct, intended effect
of the single structural change: both examples were written **against the modal
bug**, relying on the widget swallowing their keys. The `is_shown()` guard is the
project's new responsibility under the fixed contract, not a platform patch.
This inverts how they should be reported and how they should be counted.
