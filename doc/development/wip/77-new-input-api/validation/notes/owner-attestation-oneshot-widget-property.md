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
2. **It persists until replaced, like every other project-owned key — no clearing rule.** The
   parent proposed *disarmed when the widget goes down*, arguing that a session ending without a
   submit would leave the flag armed for a later bare `show()`. **The owner withdrew it the same
   day:** the flag lives on the widget as `callbacks` do, and the widget lives one **run**
   (Decision 3 as amended by `ARC-01`), so project exit tears it down and no machinery is needed.
   Two further reasons it was wrong, which the parent conceded: clearing at `hide` would be a
   **second reconfiguration policy** where `ARC-01-07` established one — *content resets,
   everything the project sets persists until replaced* — and the argument **proves too much**,
   since `validator` persists across a bare `show()` in exactly the same way and surprises nobody.
   A project wanting a continuous session after a `oneshot` one writes `oneshot = false`.
2a. **The settled reading: `oneshot` configures a *type of behaviour*, not one show/hide cycle**
   (owner, 2026-08-30, closing the clearing question). This is the ground the withdrawal stands on,
   and it is stronger than the lifetime argument that first retired the clearing rule: *"I like the
   concept that `oneshot` configures the **type** of behaviour, not merely one show/hide cycle — it
   avoids introducing a new entity, a 'one-off flag' just for syntactic sugaring."* So the flag is
   an ordinary project-owned setting that happens to govern the lifecycle, and it needs **no
   category of its own**: no clearing rule, no consumption semantics, nothing that behaves unlike
   `validator`. **Persistent until disabled.**

2b. **Because it is persistent, the docs must say so, and the ledger must rule it** (owner). Not a
   remark in passing — see the trap below, which is the parent's addition and the reason the owner's
   condition is not optional.

   **The name says one-off; the semantics say mode.** `oneshot = true` reads to a project author as
   *"this one time"*, and a reader who assumes that will expect the flag to clear itself. It does
   not: every subsequent submit closes the widget until the project disables it. That is a silent
   trap of the same class this feature keeps meeting — right-looking code, wrong behaviour, no
   error.

2c. **Superseded the same day: the flag is RENAMED instead** (owner, overruling their own earlier
   position). *"Use a new name without semantic ambiguity — it does not bear the one-off vibe and
   reads like a mode."* This deletes the warning rather than writing it, and is the better trade.

   **The parent had argued renaming was unavailable, and was wrong twice over.** It claimed
   Decision 36's grounding forfeits, and it claimed the replaced API's behaviour was *"not checkable
   in this repo"* — the owner corrected that, and the check was then run
   ([`oneshot-at-the-pr-base.md`](oneshot-at-the-pr-base.md)). It shows the opposite of what the
   ledger says: at base `3256aac`, `oneshot` was an **internal model constructor argument**
   distinguishing the transient prompt widget from the console's permanent one — suppressing
   history, pushing the `userinput` event for the poll idiom, and switching the view's draw path. **A
   project never wrote it or read it.** So Decision 36's *"a migrating project author meets a
   familiar name"* is false; the **capability** was restored, the name was not. The token is also
   already taken in-tree by the profiler. `FEAT-02-01` amends that ground; `FEAT-02-02` does the
   rename.

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
