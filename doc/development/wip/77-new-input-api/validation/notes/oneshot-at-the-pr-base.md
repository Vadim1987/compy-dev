# What `oneshot` actually was before this feature — a base check that should have run first

**Session57 addendum, 2026-08-30.** Run because the owner corrected a claim I had put into the
ledger: *"whether the replaced API's `oneshot` self-cleared is not checkable in this repo."* **It is
checkable, and I should have checked.** The base is `3256aac`, it is in this repo's history, and
`agents/validation.md` carries "check the PR base first" as a standing lesson from two verdicts
already overturned that way in this phase. I asserted an unknown instead of running one command.

The owner said there was no need to check, since the rename moots the behaviour question. The check
was run anyway because the *claim* was wrong and had to be corrected — and it turned up something
that bears on Decision 36's stated grounds rather than on the behaviour.

## What the base had

`oneshot` is a **constructor argument on the model** — `UserInputModel.new(cfg, eval, oneshot,
custom_label)` (`3256aac:src/model/input/userInputModel.lua:47`) — with four effects, none of which
is "close after submit":

| effect | site |
|---|---|
| suppresses history: `keep_history()` is `not self.oneshot` | `userInputModel.lua:410-412` |
| on a successful submit, pushes the `userinput` love event — the handshake the retired **poll idiom** waited on | `userInputModel.lua:812` |
| changes the **view's draw path**: `if not self.controller:is_oneshot() then update_view()` | `userInputView.lua:289` |
| gates the submit branch itself: `if not Key.shift() and Key.is_enter(k) and input.oneshot` | `userInputController.lua:346` |

`is_oneshot()` existed (`userInputController.lua:25`) — but as a **view helper**, not a project
surface.

**So `oneshot` at the base meant "this is the transient prompt widget, not the console's permanent
one".** It was a *widget kind*. The closing that a project observed did not come from the flag at
all: the widget was constructed per activation inside the `input()` closure and `love.state.user_input`
was set to nil on the way out — which is what `ARC-01`'s own base check already recorded.

## What this corrects, and it is a ledger-level correction

**Decision 36's first ground does not hold as written.** It says:

> *"`oneshot` **preceded this feature**: the API being replaced had it, so this is a restoration, not
> an invention, and **a migrating project author meets a familiar name** instead of a pattern they
> must reconstruct."*

The token preceded the feature. **The project-facing key did not.** A project at base wrote
`input_text(prompt, text)`, `input_code(...)`, `validated_input(...)` or `r = user_input()`; it never
wrote `oneshot`, never read `is_oneshot`, and had no way to reach either — they are internal to the
model, the view and the framework's own wrappers. **There is no migrating author to whom the name is
familiar.** What is genuinely restored is the *capability* — a prompt that goes away by itself — and
that restoration argument stands untouched. The *name* has no claim on the reader's memory.

**Decision 36's second ground is unaffected.** The `serial` API's author asked for the flag; that is
an owner attestation about a surface outside this repo and nothing here touches it. It does carry a
small cost into any rename: they asked for it under a name they will not find.

**And the token is not free in-tree.** `oneshot` is live in this repo for the **profiler** —
`Prof.start_oneshot`, `love.PROFILE.oneshot`, and a reserved combo whose pending test names it
(`ctrl+alt+p ... the oneshot profiler`). One word, two unrelated meanings, in a feature that already
carries `FIX-02-08` and `FIX-02-09` for exactly that class of drift.

## Consequence

**The main objection to renaming is gone.** I had argued renaming forfeits Decision 36's grounding;
on the evidence it forfeits a familiarity that was never there, keeps the restoration argument
whole, and frees a token the profiler already owns. `FEAT-02-01` therefore amends **two** things in
Decision 36 — the show-only edge, and this ground.
