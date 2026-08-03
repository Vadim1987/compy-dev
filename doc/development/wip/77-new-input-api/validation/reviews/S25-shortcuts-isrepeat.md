---
description: The isrepeat caveat in shortcut dispatch — what it is, what keyboard had to write, and the three ways out weighed against each other; ruling pending
status: active
audience: developer
authored: llm
reviewed: none
---

# S25 · shortcuts and `isrepeat`

Raised by the owner (2026-08-03) on reading keyboard's migration: *"manual
check of isrepeat flag in every shortcut handler is a serious code smell that
points to suboptimal API design."* Nothing is implemented here. The ruling is
the owner's.

## What the caveat is

The OS repeats a held key. LÖVE reports that as `isrepeat` on `keypressed`,
and the API threads it all the way down: `occupy_keyboard` installs
`pic:keypressed(k, sc, isr)`, and `ProjectInputController:keypressed`
dispatches `('keypressed', k, k, held_keys(), isr)` — so it reaches shortcuts,
hooks and the widget alike, as argument three.

Dispatch itself does **not** gate on it. A shortcut bound to `ctrl+alt+up`
fires on the first press and on every repeat after it, ~30 times a second
while held. That was shipped as an open question, not a decision
(`technical_debt/input.md`, *"Shortcuts key-repeat semantics are shipped
unsettled"*).

Only `keypressed` is affected: LÖVE does not repeat releases, and `textinput`
carries no such flag (`ProjectInputController:keyreleased` passes no `isr`).

## What keyboard had to write

Its reserved chords are commands — `shift+escape` goes back, `ctrl+alt+up`
adjusts the notch. Held, they would ramp. But they must *keep consuming* on
repeat, or the repeats fall past the shortcut into the hook and the scene
sees a phantom keystroke. Two requirements, not one:

```lua
local function chord(fn)
  return function(_, _, isr)
    if not isr then fn() end
    return true          -- consumed either way
  end
end
```

Worth being precise about the smell's size: that is **one decorator applied
three times**, not a check copy-pasted into every handler. But every project
binding a command to a combo will write it, and none of them should have to.

## Current resolution: none — documented, not decided

The platform is unchanged. keyboard carries the decorator, the debt entry now
records it as the open decision's first real consumer, and the entry's revisit
condition ("when shortcuts dispatch gets its next real consumer") has fired.
That is the honest status.

## Option A — a matching shortcut consumes a repeat without being invoked

Dispatch checks `shortcuts[event][combo]`; if it matches and `isr` is true, it
returns consumed **without calling the handler**. Exactly what `chord` does,
moved into the framework.

**For.**

- A *shortcut* is a command binding. Nobody wants Ctrl+S to save thirty times
  a second, and no consumer in the tree wants repeat-firing shortcuts — the
  count is 0 for, 1 against (keyboard), across four example projects.
- **It gives the tier a reason to exist.** Today `shortcuts` and `hooks`
  differ only in their lookup key: one is combo-addressed, the other
  event-addressed, and their semantics are identical. Making shortcuts
  once-per-press makes the split mean something — *shortcuts are cooked
  commands, hooks are the raw channel* — which is a teachable rule and
  directly answers the "suboptimal design" charge.
- **The capability it removes now has a better replacement.** Held-key
  behaviour driven by OS key-repeat was always poor: a ~500 ms initial delay
  and a user-configurable rate are wrong for movement or acceleration. The
  right shape is polling `compy.input.keys_pressed` in `update` — which
  Decision 20 has just made possible. A week ago this argument was weaker.

**Against.**

- **It is silent.** A handler that wanted repeats simply never fires, and
  nothing says why. That cuts against Decision 3's warn-don't-swallow
  instinct, and we cannot warn: it would fire every frame.
- **It puts policy in a walk Decision 2 calls dumb.** Mitigated but not
  erased by the fact that the walk is already tier-differentiated — the widget
  consumes by shownness, not by return value.
- It is a semantic change to a ratified surface, made at PR time.

**Blast radius:** one test row —
`input_events_spec.lua`, *"every step of the chain receives the same delivered
triple"*, which drives `repeat_press` through a shortcut and asserts the
shortcut saw `isr = true`. It would become an assertion that the shortcut is
*not* invoked while the hook and widget still are. No example changes except
keyboard, which deletes `chord`.

## Option B — split the shortcut table by the flag

Two tables, or a nested `[true]`/`[false]`.

**Against, and this is the weakest of the three.**

- A boolean as a table key (`shortcuts.keypressed[false][combo]`) is opaque at
  the call site. Named tables read better but add a third channel name that is
  **not a LÖVE event**, breaking the one-to-one mapping the guide sells —
  `shortcuts.<event>` currently means exactly `love.<event>`.
- A binding that wants both press *and* repeat has to register twice, or the
  framework has to OR the two tables, which is a third rule.
- It doubles the registration surface to express one boolean, and the boolean
  is one nobody has yet asked to say `true` to.

DevX-wise it trades one line inside a handler for a decision at every
registration site. That is worse, not better.

## Option C — ship the decorator

`compy.input.once(fn)` in the API, wrapping exactly what keyboard wrote. No
dispatch change, no semantic ruling, opt-in, composes.

**For:** lowest risk, PR-safe, and it makes the pattern discoverable instead of
folklore. **Against:** it names the smell rather than removing it — every
consumer still has to know the flag exists and decide.

## Recommendation

**Option A**, with the guide stating the rule as *shortcuts fire once per
physical press; hooks see every event, repeats included; hold-to-repeat
behaviour is `keys_pressed` polled in `update`.* The two objections are real
but bounded, and the tier-semantics argument is the one that answers the
owner's actual point: the smell exists because `shortcuts` currently has no
meaning of its own.

If a semantic ruling at PR time is unwelcome, **Option C** is the safe
fallback and does not foreclose A later — `once()` becomes redundant, not
wrong. **Option B** should be dropped either way.

Whichever is ruled, the debt entry closes and the guide gains a sentence: today
a reader has no way to know shortcuts fire on repeat at all.
