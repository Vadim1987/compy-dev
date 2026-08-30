# Owner attestation — `oneshot` is a widget property, not a `show`-only key

**2026-08-30, session57, in discussion.** This **overrules `FEAT-01-01`'s Q1**, ruled the same day.
Recorded here because a ruling that lives only in a chat is lost; `FEAT-02` executes it.

## What prompted it

The cold peer review of `FEAT-01` found that a `oneshot` prompt re-opened from inside the submit
chain — `show{force = true, oneshot = true}` from `on_text_entered` or `after_submit` — is closed
immediately, before the user can type into it. The parent documented it and raised the code fix
rather than taking it. The owner's response reopened the design instead of the defect.

## The owner's reasoning

> *The widget is a singleton within a project session and that is justified. Therefore calling
> `show(force, oneshot)` from within a teardown sequence becomes contradictory by definition if it
> alters the flag which is already "deferred" until input close.*

> *`force` means "I know what I am doing" and allows full reconfiguration of the widget at any
> moment, including from its hooks. It also overrides the previous ruling of `oneshot` being a
> show-only key and turns it into a widget property — I'd say rightfully so, because **`oneshot` is
> machinery, and show-specific keys are an exclusion carved out to protect user-owned input. The
> user does not own lifecycle.***

> *Therefore `oneshot` should be a widget property, cleared on consumption. It will make the API
> more predictable, even if it overrules a previous decision.*

**This replaces an analogy with a principle.** Decision 36's edge 1 argued `oneshot` belongs beside
`text`, `cursor` and `force` because it *describes this session*. The category's actual reason is
narrower: `text` and `cursor` are **the user's**, and `force` is in the list because it is
*meaningless* at `configure`, not because it is protected from it. `oneshot` was admitted on a
resemblance to two keys it does not resemble.

## What was ruled

1. **`oneshot` is a widget property.** It leaves `SHOW_ONLY_KEYS` and becomes project-owned:
   settable at `show` **and** `configure`, set-if-given, `false` to unset (Decision 35, statement 3
   — the disarm idiom arrives free).
2. **Disarmed when the widget goes down.** The parent's condition, accepted: *"cleared on
   consumption"* alone leaves the flag alive when a session ends **without** a submit — Escape, then
   a later bare `show()` gets a `oneshot` nobody asked for, which is exactly the stickiness Q1 was
   right to fear. The close calls `hide`, so consumption is subsumed. One rule: **armed by `show` /
   `configure`, disarmed when the widget goes down.**
3. **It becomes a first-class, readable flag** — checkable from project code the way `is_shown()`
   is. A project reasoning about its own teardown path must be able to *ask*.
4. **The edge case is documented, not fixed.** A project calling `show{force}` from a teardown path
   should either **check the flag and disarm it first**, or do the re-show **after** the widget is
   hidden, with its state stashed project-side.

## What was rejected, and why — capture the flag before the hooks

The owner's first candidate: wrap the `after_submit` invocation so the close acts on the flag's
value *before* the hook could change it. **Rejected on evidence, not argument.** The parent had
already run exactly that mutation while checking the new test discriminates:

- follow-up **with** `oneshot` → still closed. The captured value is `true`; the hide fires anyway.
  **Unfixed.**
- follow-up **without** `oneshot` → **now also closed.** Today it survives.

`busted` failed exactly the `a forced follow-up show survives the close` case and nothing else. So
capturing early trades the one case that works for no gain. **Reading the flag after the hooks is
what makes a forced follow-up survivable at all.**

## What is NOT fixed, said plainly

**Adopting this does not fix the peer review's case.** Under the new shape a hook doing
`show{force, oneshot = true}` still re-arms, and the trailing close still fires. Owning the close by
the submit that armed it needs a generation token, and that state was judged not worth it. What
changes is that the behaviour acquires a one-line explanation a reader can hold — *the close reads
the flag at the end of the submit it is running, so re-arming inside that submit arms it for a close
already underway* — and the hook gains the clean escape it currently lacks.

## The live defect this also closes

Raised by the parent and not previously on the record: **today, changing your mind about `oneshot`
mid-session requires `show{force}`, which is a full re-setup that clears the user's draft**
(Decision 35, statement 4; pinned by `force without text clears the content` in
`input_widget_control_spec.lua`). Disarming a `oneshot` therefore costs the user's typing, or an
exact hand re-supply of `text` and `cursor`. That is the strongest single argument for the change
and it is a defect, not a preference.
