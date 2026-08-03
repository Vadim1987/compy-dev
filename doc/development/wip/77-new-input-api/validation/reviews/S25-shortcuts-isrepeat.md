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

## RULED (owner, 2026-08-03): option C, the decorator

> *"i like the decorator option. lets implement and document and test this
> decorator. not using it blindly on hooks should be decision of developer."*

Option A is **dropped**, and the owner's objection is the reason it should be.
Two things about it were wrong in the recommendation below:

1. **Irrecoverable suppression is not a bounded cost.** The framework cannot
   know which bindings are commands and which are hold-to-act, so filtering
   repeats at the tier takes a capability away with no way back — the owner's
   *"suppress some behaviours without a way to recover them"*.
2. **A dispatch rule fixes only half the cases.** It would cover commands
   bound as shortcuts and do nothing for commands bound in
   `hooks.keypressed`, which is equally idiomatic. A decorator composes across
   all three tiers; a rule on one tier cannot. This also dissolves the
   tier-semantics argument the recommendation leaned on: "shortcuts are
   commands" is an opinion the framework would impose, and it would still
   leave the hand-written check in the hook path.

For the record, one thing in the owner's framing needs correcting, because it
describes a *third* variant rather than A: A consumed the repeat without
invoking the handler, so nothing fell through to the hook or the widget. The
variant where the shortcut tier is **skipped** for repeats is the broken one —
a held combo's repeats would reach a shown widget, and a project would have to
install a hook re-implementing combo matching to swallow specific combos while
letting held-arrow navigation past. Strictly worse than the line it removes.

### Disclosure: the frozen design leaned the other way, and I missed it

Found after the ruling, while checking an unrelated question
(2026-08-03). `design.md:367`, salvage register:

> **Combo-tier repeat semantics**: provisional leaning (**fresh-only at combo
> tiers**; `on_key_pressed` sees repeats) — **not ruled**; owner constraint:
> existing combos keep current behaviour unless explicitly altered; settle
> near implementation (doc A §9).

So option A was not an invention of this session — it is the design's own
provisional leaning, and the tier split I argued for is the one recorded
there. Three things about that:

1. It is **explicitly "not ruled"**, and parked to "settle near
   implementation". This is that moment, so ruling it now is exactly on
   process, not against it.
2. The ruling for the decorator therefore does not overturn a ratified item.
   It settles an open one, the other way from a leaning.
3. The owner's two objections stand regardless of the leaning: the framework
   cannot distinguish a command binding from a hold-to-act one, and a
   tier rule leaves the same hand-written check in `hooks.keypressed`. A
   leaning is not an argument.

The constraint attached to it — *existing combos keep current behaviour unless
explicitly altered* — is satisfied either way: the decorator is opt-in and
changes nothing that is already registered.

Flagged because a reviewer reading `design.md` will find the leaning, and the
PR should not look as though it was unaware of it. If the owner wants to
reconsider A in light of it, nothing here is built yet.

### Implementation plan — deferred, not started

- **`compy.input.suppress_repeat(fn)`** — decorator. Returns a handler that,
  given the standard `(k, keys, isr)` payload, calls `fn` on a fresh press and
  **consumes either way**. Stateless.
- The consume-on-repeat half is the load-bearing part, not the flag test: a
  repeat that is not consumed falls to the widget, which is exactly the
  failure the skipped-tier variant produces.
- **Tests:** fresh press invokes and consumes; repeat consumes without
  invoking; the wrapped handler still receives the payload; it works when
  installed as a hook as well as a shortcut.
- **Guide:** a section under "Event hooks and shortcuts" — the idiom, and the
  note that wrapping a *whole-channel* hook swallows every repeat including
  ones the widget wants (held backspace, held arrows). Per the ruling, that
  stays the developer's call, stated as a caveat and not a prohibition.
- **Decision 21** in the ledger; the debt entry *"Shortcuts key-repeat
  semantics are shipped unsettled"* closes as deliberate: shortcuts see every
  repeat, `suppress_repeat` is the sanctioned once-per-press idiom.
- **keyboard** drops its private `chord` for the public decorator.
- Dispatch is **unchanged** — Decision 2's dumb walk intact, three tiers
  uniform, nothing suppressed that cannot be recovered.

## Recommendation (superseded by the ruling above)

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

---

## Naming pass, and a measurement that changes the set (2026-08-03)

The owner pushed back on the local aliases `once`/`claim` — `once` is
compellingly wrong (it invites a reader to expect debounce-by-timer
semantics), `claim` is vague — and sketched
`always_true(ignore_repeat(fn))` as the shape.

Probing that sketch produced a result worth the whole exercise.

### The three shapes are not the three I described

| written | fresh press | repeat |
|---|---|---|
| `bypass_repeat(fn)` | `fn` runs; **its return decides** | skipped, event continues |
| `suppress_repeat(fn)` | `fn` runs; **its return decides** | skipped, **consumed** |
| `always_true(bypass_repeat(fn))` | `fn` runs; **consumed** | skipped, **consumed** |

Measured, not reasoned: with a non-consuming handler,
`always_true(bypass_repeat(f))` produced `ran` and nothing else, while
`suppress_repeat(f)` produced `ran, fell through` — the fresh press reached
the hook underneath.

**Row 2 is incoherent.** A binding using it lets the *first* press fall
through to the widget and then eats every repeat: press 1 behaves differently
from presses 2+. Nobody wants that, and it is what `suppress_repeat` offers
today. Rows 1 and 3 are the coherent pair, and both are uniform in propagation.

Note also that row 3 is exactly what `suppress_repeat` did **before** the fix
two commits ago — the version that forced `true`. The bug was not that it
consumed; it was that consuming was welded to repeat-filtering with no way to
separate them.

### Proposal: two combinators, not three

- **`ignore_repeat(fn)`** — skip the handler on a repeat, and say nothing
  about propagation. Renamed from `bypass_repeat`, and for a reason rather
  than taste: "bypass" is a claim about where the *event* goes, which is no
  longer this wrapper's business. "Ignore" describes what the handler does,
  which is all it does.
- **`always_true([fn])`** — unchanged. Propagation, declared at the
  registration site.
- **Drop `suppress_repeat`.** The two coherent behaviours are
  `ignore_repeat(fn)` and `always_true(ignore_repeat(fn))`; the incoherent
  middle one stops being offered. Anyone who genuinely wants it writes four
  lines, and should have to think while doing so.

Two orthogonal combinators — one about invocation, one about propagation —
compose into every shape that makes sense, and neither name has to be
memorised.

### On aliases

Recommend none. `always_true(ignore_repeat(goBack))` is 55 characters at the
call site: it fits, and it reads in the order it happens. A local
`once`/`claim`/`stop_here` layer reintroduces exactly the indirection that
made `reserved()` worth deleting — and `stop_here` would be a third synonym
for a `true` return, after `always_true` and the glossary's own *consume*.

`consuming(fn)` would sit closest to the ratified vocabulary (Decision 2:
"truthy return = consumed"). `always_true` is kept because it says plainly
what the function does at a call site where the reader may not have the
glossary in mind — but if the glossary word is preferred, that is the one
rename worth making, and it is cheap now.
