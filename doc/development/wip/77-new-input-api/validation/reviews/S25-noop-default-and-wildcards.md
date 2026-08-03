---
description: Two owner proposals re-raised — a noop default on the hooks/shortcuts tables (which the frozen design already ratified, and the implementation dropped) and wildcard combo classes like ctrl+alt+*
status: active
audience: developer
authored: llm
reviewed: none
---

# S25 · the noop default, and wildcard combos

Owner, 2026-08-03: *"many, many times during our architectural sessions I told
that I'd prefer hooks and shortcuts tables to have `__index` set to noop
function … i was ignored all the time"*, and *"why not simply allow combo
definitions like `ctrl-alt-*` in configuration?"*

Nothing implemented here. Both are rulings to make.

## 1 · The noop default — the record backs the owner, and this is drift

Not a preference that lost an argument. It is in the **frozen** design.

`design/design.md:39`, the ratified chain, tier 3:

```
   3. per-event generic callback   on_key_pressed | on_text_input | on_key_released
                                     — DEFAULT: noop (+debug log)
```

And `design/notes/decisions.md`, twice over — `:297` has the *table* itself
answering with a default (*"by default table returns noop"*), and `:793`
states the intent as a cross-cutting rule:

> **Default noop + debug log.** D-3 and D-4 both propose this as the default
> for overloadable callbacks. Worth adopting as the standard for all
> project-facing callbacks: **silent failure is replaced by a visible hint in
> debug mode.**

**What shipped instead.** `projectInputController.lua`:

```lua
local sc = shortcuts[event][combo]
if sc and sc(...) then return true end
local hk = hooks[event]
if hk and hk(...) then return true end
```

Nil guards, and **no log anywhere in the file** — verified, `Log` is not even
required there.

So the drift is not stylistic. Behaviourally a nil guard and a noop that
returns nil are the same thing, and that is presumably why it passed review.
But the design's stated *purpose* for the default was the debug log, and you
cannot log from a `nil`. The tier that was supposed to say "nothing handled
this" says nothing at all, in debug mode included. That is the part that was
lost, and it is a ratified acceptance criterion, not a taste.

### What implementing it actually costs

- **`seed_hooks` reads nil as meaning "unset"** (`projectInputController.lua:44`,
  `if hooks[event] == nil then hooks[event] = handlers[event] end`). With a
  noop-returning `__index` no hook is ever nil, so seeding would silently stop
  happening — Decision 10's whole capture path. It needs `rawget`.
- **Decision 10's "a nil'd hook clears, with no resurrection"** stays true as
  *semantics*, but every internal read that asks "is this set?" moves to
  `rawget`. There are few, and they are findable.
- **The project-facing read changes.** `compy.input.hooks.textinput` would
  return a function a project never installed. "Did I set this?" stops being
  answerable from the surface. This is the one real design cost, and it argues
  for putting the default in the **dispatch view** rather than in the stored
  table — the leaf surface keeps answering nil to projects, dispatch resolves
  through a defaulting read.

### RULED 2026-08-03 — explicit branches, not a defaulting `__index`

> *"wiring noop into index masks the real behaviour and disables full class of
> decisions based on whether hook was set or not … just adding three `else`
> branches inside dispatch function (keeping its nil checks in place) would be
> more transparent."*

Accepted, and the reason given is stronger than either argument I had made:
**a hook's nil-ness is information**, and code that installs or removes a
handler conditionally on what another part already installed needs it. A
defaulting `__index` does not merely hide the check, it deletes an
introspection capability. It also disposes of the `seed_hooks` problem below —
nothing changes there if `nil` keeps meaning unset.

Shape: keep `if sc and sc(...)`, add the unhandled branch beside it.

**One thing to settle before implementing: where the log goes, or it is a
flood.** A "no shortcut for this combo" line fires on *every* keystroke that
is not a bound combo — i.e. on ordinary typing, 60/s under `love.DEBUG`. That
is not the "visible hint" the design asked for. Two observations:

- `design.md:39` puts the default at **tier 3** (the per-event generic
  callback, today `hooks[event]`), not at the combo tier. Logging only there is
  closer to what was ratified.
- The genuinely useful signal is *the walk fell through entirely* — nothing
  consumed the event and no widget was shown. That is one log per truly
  dropped event, and it is the case a project author is actually debugging.

Recommendation: log once, where `dispatch` returns false, naming event and
combo; optionally a second line at the hook tier. Not three logs.

Also a size constraint worth knowing: `dispatch`'s body is 11 lines against
the 14-line limit, so three full `if/elseif` branches (+6) do not fit and
would force a split. One `if not sc then …` line per tier fits.

### Recommendation — CORRECTED 2026-08-03 (superseded by the ruling above)

The recommendation below was *"put the default in the dispatch view, keep the
project-facing tables answering nil"*. Both halves were wrong, and the owner's
question is what exposed them.

**There is no dispatch view to put it in.** `occupy_keyboard` passes
`compy.input` itself to `pic:activate`, and `_dispatch` reads
`self.compy_input.shortcuts` / `.hooks` — dispatch goes through the **same
proxies the project uses**. Creating a separate view is not a scoping
detail, it is new machinery.

**And "did I set this?" is already unanswerable.** `seed_hooks` writes the
project's captured `love.*` handlers into the hooks table (Decision 10), so a
project that defined `love.keypressed` finds `compy.input.hooks.keypressed`
non-nil having never assigned it. The property I said a noop default would
destroy is already gone.

So the honest recommendation is the plain one the owner asked for
originally: **put the noop on the store's `__index`**, where both dispatch and
the project get a callable. Consistency is a feature — a project chaining to
an unset hook stops being a crash for the same reason dispatch stops needing a
guard.

**The one real cost, and it is not `rawget`.** `seed_hooks` tests
`hooks[event] == nil` to decide whether to seed (`projectInputController.lua:44`).
With a defaulting store, nothing is ever nil, and seeding silently stops —
Decision 10's whole capture path. `rawget` does **not** rescue it either:
`seed_hooks` receives the *leaf proxy*, which is an empty table over the store,
so `rawget(proxy, k)` is always nil. Seeding needs an explicit "is this set"
query on the surface, or seeding has to move to where the store is in scope.
That is the piece to design, and it is the only one.

## 2 · Wildcard combo classes (`ctrl+alt+*`)

This is a good idea and cheaper than the debt entry I wrote implied. Note the
separator is `+`, not `-`.

**It needs no new normalisation.** `normalize_combo` splits on `+`, lowercases,
folds l/r, orders modifiers by precedence and puts the trigger last. `*` is
simply a non-modifier token, so `'Ctrl+Alt+*'` normalises to `'ctrl+alt+*'`
with the existing code, unchanged.

**It needs no new payload.** A handler already receives `(k, keys, isr)` and
`k` *is* the actual trigger, so a wildcard handler can tell which key matched
without anything being added.

**Precedence is one extra lookup, only on a miss.** Exact first, then the
class key — `mods .. '+*'`. Nothing changes on the hit path.

**It is better than the hand-rolled version it replaces**, which is the
strongest evidence for it. keyboard's `appChord` needs an explicit
`if INPUT.ctrl then return false end`, because "Alt-class" must exclude
Ctrl+Alt+H. With combo classes that exclusion is free: `ctrl+alt+h` produces a
different modifier set and simply does not match `alt+*`. The whole of
`appChord` becomes two declarative entries:

```lua
sc['alt+*'] = suppress_repeat(function() end)   -- swallow the class
sc['alt+p'] = suppress_repeat(pauseToggle)      -- exact wins
```

### The two corners it owes an answer to

- **A modifier's own press.** Holding Alt and pressing nothing else dispatches
  the combo `alt+lalt` — `combo_string` prepends the held modifier to a
  trigger that *is* that modifier key (measured). `alt+*` must not match it,
  or every Alt press fires the class handler. Rule: `*` does not match when
  the trigger is itself a modifier.
- **A bare `*`.** "Any key, no modifiers" is what a hook is for. Either reject
  it at registration or document it as a hook; do not let two mechanisms mean
  the same thing.

### Recommendation

Take it. It is the elegant answer to the class problem, it reuses the
normaliser untouched, and it deletes hand-rolled modifier tests from projects
rather than adding a concept. Ruling needed on the two corners above; both are
one-liners once decided.

## How the class check should actually be implemented

The earlier claim that the two proposals "compose through `__index`" was
sloppy. They are different kinds of thing and belong in different places.

**The class lookup is an explicit two-step read in `dispatch`, not `__index`:**

```lua
local sc = shortcuts[event][combo]
if sc == nil and not Key.is_mod(trigger) then
  sc = shortcuts[event][Controller.combo_string('*', keys)]
end
```

The class key needs no parsing — `combo_string('*', keys_pressed)` builds it
directly from the same held set the exact combo came from. Measured: with
Ctrl and Alt held it returns `ctrl+alt+*`.

Why explicit rather than `__index`:

- **`__index` would lie to readers.** A project inspecting
  `compy.input.shortcuts.keypressed['alt+q']` would get the class handler back
  for a combo it never registered. The table should stay a plain map of what
  was registered.
- **Precedence and the modifier-trigger exclusion are policy**, and policy in
  a data structure's metamethod is invisible at the point it matters. In
  `dispatch` it is two greppable lines next to the walk they belong to.
- The noop default is genuinely a *default*, so `__index` is right for it.
  Different concern, different mechanism.

## The grammar question — what was actually ratified

The owner (2026-08-03): *"'A combo is modifiers plus exactly one trigger' —
it never was my definition. i only ratified writing modifiers in the beginning
of serialized string for predictable and readable ordering."*

**They are right, and the frozen design says so.** `design.md:348`, the
salvage register:

> **Combo format**: modifier-first fixed precedence (ctrl, alt, shift, gui),
> l/r folded, `+`-joined; registration normalised on assignment;
> **matcher = marked extension seam**.

What is ratified is the *serialisation*: ordering, folding, joining,
normalise-on-assign. The **matcher is explicitly an extension seam** — the
design anticipated it being extended. "Exactly one trigger" is nowhere in it;
it is an implementation consequence of `combo_string` prepending only the four
modifier classes.

Two things follow. Combo classes (`ctrl+alt+*`) land *inside* the seam the
design marked, rather than against the grain of it. And the single-trigger
narrowing is a decision to defend on its merits, not an inherited constraint:

### Why the narrowing is nonetheless worth keeping

Not tradition — the exact-lookup matcher depends on it.

Dispatch serialises the actual key state into one string and does one `O(1)`
lookup. That is sound for modifiers because a combo names **every** modifier
that matters: `ctrl+s` deliberately does *not* fire while Alt is also held.
Extend the same rule to ordinary keys and every binding becomes conditional on
nothing else being held — hold `a` for movement, press `space`, and the
`space` binding silently stops firing because the combo is now `a+space`. That
is a severe foot-gun, and it is the real reason non-modifiers stay out.

The alternative — "a combo fires when the keys it names are held, other held
keys ignored" — cannot be a serialise-and-look-up matcher at all. It is a
subset test against every registered binding, i.e. `O(bindings)` per event or
a new index. That is a different mechanism, which is precisely why the design
called the matcher a seam.

There is also an asymmetry that does not go away: modifiers are few, named,
and held deliberately before the trigger. For two letters, `a+b` and `b+a`
look symmetric and are not — the trigger is whichever arrived last. And
multi-key chords are unreliable on hardware with limited n-key rollover,
which matters for this device.

**So:** keep the narrowing, but record it as a *decision with reasons* rather
than an accident, and stop describing it as if the design imposed it. If
multi-key chords are ever wanted, the honest route is the matcher seam and a
subset test — not a wider serialisation.

## `a+b+*` today: it does not mean what it looks like, and fails silently

A combo is **modifiers plus exactly one trigger**. `combo_string` prepends only
the four modifier classes; a held non-modifier key never enters the string.
Measured with `a` and `b` both held and `b` pressed: the combo is
`ctrl+alt+b`, with no trace of `a`.

So `a+b+*` is not expressible, and neither is `a+b` — multi-key chords are
outside the grammar entirely, wildcard or not. A project wanting "a and b held
together" reads `compy.input.keys_pressed` (Decision 20), which is what it is
for.

**And today that failure is silent, which is a defect in its own right.**
`normalize_combo` takes the *last* non-modifier token as the trigger and drops
the rest. Measured:

| written | stored as |
|---|---|
| `a+b+*` | `*` |
| `ctrl+a+b` | `ctrl+b` |
| `ctrl+alt+*` | `ctrl+alt+*` |

So `a+b+*` registers a bare-`*` handler — the widest possible binding, from a
string the author meant as the narrowest. `ctrl+a+b` silently becomes
`ctrl+b`. This is independent of wildcards and should be fixed regardless:
**raise at registration on a combo carrying more than one non-modifier
token**, the same way `show`/`configure` raise on an unrecognised key
(Decision 15). It also disposes of the bare-`*` question — if `*` is the only
non-modifier token allowed alongside modifiers, `a+b+*` raises rather than
needing a rule.
