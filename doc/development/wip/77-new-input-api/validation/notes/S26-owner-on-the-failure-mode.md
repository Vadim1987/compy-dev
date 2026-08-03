# S26 — the owner on how a hallucinated design got ratified

**Recorded 2026-08-03**, at the owner's request, while the pointer
unification was landing. Their words, verbatim, then what the record
corroborates.

---

## The attestation

> the complexity we eliminate now is the biggest one which prevented release
> from happening. it surfaced here and there, I was squeezing it out of various
> system corners until it stayed isolated in 6 methods with weird names which
> all served weird purpose — support alternative self-inflicted
> event-dispatching mechanism nobody asked for.
>
> its the second time when I capture biggest misunderstanding that smuggled
> into specs and became self-authorized load-bearing requiement. How it
> happened? I think LLM assistant told me "currently, system does this and
> that" — describing the *defective part of the design* while I was thinking
> "currently" relates to existing behaviour. So I occasionally ratified design
> hallucination and we spent lots of time building workarounds around it.
>
> It does not change nothing in current plan — just explains the failure mode
> which happened for a second time (first one was when architecture assistant
> hallucinated idea of "four-tier" handling, with tier before shortcuts being
> responsible for events interception and special modes of widget state
> manipulation, all hallucinated)

---

## What the record corroborates

**The four-tier episode is in the history under that name.** Two commits
carry it in their subject: `17f6f7e8` "test(input): red rows for the four-tier
dispatch chain (M5c chunk 1)" and `56c4284f` "feat(input): the four-tier
project-route dispatch chain (M5c chunk 1)". Its removal is recorded in
`decisions/input.md`, Decision 2, "No framework tier":

> There was once a fourth, leading component — `framework handlers` —
> non-overridable and not exposed to project code, that claimed Enter/Escape
> unconditionally while the widget was shown. It is deleted outright, code and
> tests: it existed solely to give Enter/Escape special handling inside the
> route…

**The second episode is the one session26 unwound**, and the same
`56c4284f` is its origin commit. The claim that the keyboard/pointer split was
inherited platform behaviour is written into Decision 11 as "**Why.** This is
the established platform behaviour, adopted as a design constraint because no
product ruling motivated changing it." Checked against the PR base `3256aac`:
`set_default_handlers` is called from exactly two sites — `suspend()` and
`stop_project_run()` — and `running→project_open` releases nothing. Both
channels stayed installed until suspend or stop. There was no asymmetry to
inherit. `release_keyboard_route` arrived with `386cfe1d`, keyboard-only, and
pointer then had to be exempted from a release that had not existed.

**The "six methods with weird names" are countable.** Removed or collapsed
across session26: `forward_keypressed` / `forward_textinput` /
`forward_keyreleased` (the console-route widget gate Decision 1 says is gone),
`wrapped_native` / `keyboard_native` / `chain_native` (two wrappers and an
inner builder, split by a return-policy constraint that was never real), plus
`get_compy_handler` and the dead `_defaults` click stubs. What each existed to
serve was a second dispatch arrangement running beside the one the feature
designed.

## The failure mode, stated for reuse

An assistant writes "currently the system does X". The owner reads *currently*
as **observed existing behaviour** and ratifies on that basis. The assistant
meant *currently* as **the state of the design under discussion** — including
parts it had just invented. The word carries no marker for which, and a
ratified line then becomes load-bearing: later work treats it as a constraint
to be worked around rather than a claim to be checked.

Both episodes share the shape: an invented mechanism acquires authority by
being described as pre-existing, and the cost is paid later in workarounds
built to preserve it.

**The cheap defence, and it worked twice this session:** when a document
asserts that behaviour is pre-existing, check it against the PR base before
building on it. `git show 3256aac:<file>` settled both the pointer-lifecycle
claim and the `wrap` arity question in minutes, and overturned a ratified
rationale in the first case. A claim about the past is verifiable; treat
"this is how it has always worked" as a hypothesis with a known test.

Related: `S26-pointer-unification-plan.md` (the plan this note accompanies),
`S26-event-chain.md` (the traced chain).
