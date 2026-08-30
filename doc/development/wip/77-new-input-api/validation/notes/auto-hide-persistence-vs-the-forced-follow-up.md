# The persistence retires the implicit disarm — and one ruled test with it

**session58, 2026-08-30, during `FEAT-02-03`.** Raised rather than resolved: the roadmap cell and
the session prompt both say `a forced follow-up show survives the close` **must keep passing**, and
on the evidence it cannot, unchanged. The prompt also says *stop* if I find myself making it pass a
different way. I stopped.

**I did not touch the flag's read placement.** `submit_flow` still reads `self.auto_hide` after the
callbacks; the mutation the prompt warns about was not made (and is re-refuted below).

## What happens

`FEAT-02-03` as ruled — `auto_hide` set-if-given in `configure_core`, persistent until replaced —
makes this case fail:

```lua
input.show({ text = 'a', auto_hide = true,
  on_text_entered = function()
    input.show({ prompt = 'again?', force = true })   -- follow-up
  end })
```

The follow-up is now closed by the submit still in progress. **The case passed before because the
seating was unconditional**: `open_widget` did `self.oneshot = cfg.oneshot`, so a bare `show{force}`
wrote `nil` and disarmed the flag as a side effect. Its own comment says so — *"the flag is read
AFTER the callbacks **and the second show cleared it**"*.

**That implicit disarm *is* the show-only semantics `FEAT-02` retires.** A key that a bare call
silently clears is the definition of "spent by its own `show`"; a project-owned key that persists
until replaced cannot also be cleared by a call that never names it — that is Decision 35's
set-if-given rule, and clearing anyway would be the second reconfiguration policy `ARC-02` deleted.
So the test does not merely happen to break. It pins the category, **as well as** the placement.

## Evidence — three runs

| run | suite |
|---|---|
| `-03` implemented, case unchanged | **1022 / 1** — fails at `a forced follow-up show survives the close` |
| same, follow-up passing `auto_hide = false` | **1023 / 0** — fully green |
| same, **plus** the forbidden mutation (capture the flag before the hooks) | **1022 / 1** — fails again, same case |

The third run matters: it re-establishes, under the new shape, what session57 established under the
old one. **Reading the flag after the callbacks is still load-bearing** — capture-before closes even
the follow-up that explicitly disarms, so there is still exactly one placement that lets any
follow-up survive. The rejected fix stays rejected for the same reason, with fresh evidence.

## The behaviour delta, stated plainly

- **Before:** a follow-up `show{force = true}` from inside the submit chain survived; one that passed
  the flag itself did not.
- **After:** a follow-up survives only if it passes **`auto_hide = false`**. Silence is no longer a
  disarm.

This is a **deviation from pre-change functionality**, and it deepens the peer review's case rather
than fixing it — which the sprint already says it does not fix. It is also the same silent-trap
class this feature keeps meeting: right-looking code, wrong behaviour, no error. The project author
who wrote the surviving follow-up under `FEAT-01` gets a widget that vanishes, with nothing raised.

## The options, and why only one is consistent

1. **Accept it; the follow-up disarms explicitly.** `show{force = true, auto_hide = false}` — the
   idiom Decision 35 statement 3 already gives for free, and the exact shape the attestation's
   ruling 4 recommends (*"check the flag and disarm it first"*, now unconditional so no check is
   needed). The test's scenario gains one key; both of the things it pins survive, one of them
   restated. **Recommended.**
2. **Keep `show` seating unconditionally, so a bare forced `show` still disarms.** Rejected: it is a
   second reconfiguration policy — the key would be project-owned at `configure` and show-only at
   `show` — and it contradicts the ruled persistence in the same breath as implementing it.
3. **Clear at `hide`, or on consumption.** Withdrawn by the owner, twice, on 2026-08-30. Not
   reopened here.

## What this costs `FEAT-02-04`

The guide's current advice for the follow-up is *"leave `auto_hide` off"*. Under option 1 that
becomes **"pass `auto_hide = false`"** — off is no longer a state a `show` can express by omission.
`doc/input_api.md`, *"Asking one question"*, has three bullets that say it the old way.

## RULED — option 1, and the framing was corrected (owner, 2026-08-30)

> *"Well, there is no 'working idiom'. We retired `oneshot` in its old shape, then were asked to
> restore the capability as it is convenient to reduce boilerplate in projects which are not
> user-focused. What you see on disk is a result of an attempt to quickly design and implement the
> `oneshot` flag as a disposable variable, disarmed on consumption. Then I overruled myself for the
> sake of a configuration flag which applies across many hide/show cycles until it is reset to
> false. Whatever contradiction you see, it should be eliminated for the win of this latest ruling.
> Effectively your goal is to implement the pivot, changing a precious fragile implementation into a
> more reliable new one, including updates across code, tests, examples and docs."*

**The correction is to the question, not only the answer.** I framed the delta as *a working idiom
stops working*, which grants `FEAT-01`'s shape the standing of installed behaviour. It has none: it
was a quick implementation of a disposable flag, ruled and overruled within the day, and never
released. **There is no migration and no user of the old shape** — the same fact the base check
established for the *name* now applies to the *semantics*. A contradiction with it is not a cost to
be weighed; it is the thing being removed.

So `-03` lands with the follow-up case updated to the disarming idiom, its comment rewritten to pin
the **placement** — the half that survives — and the suite at **1023**. `-04` carries the guide.
Examples were checked and use the flag nowhere (`turtle` closes with its own `after_submit`, which
Decision 36 already records), so nothing there contradicts the pivot.
