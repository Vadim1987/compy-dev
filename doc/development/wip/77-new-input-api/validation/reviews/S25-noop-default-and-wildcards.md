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

### Recommendation

Implement it, scoped as: **dispatch always calls; the default is a noop that
logs under `love.DEBUG`; the project-facing tables keep answering `nil`.**
That satisfies the ratified AC (the visible hint exists), removes the guards
from the walk, and does not make "unset" unanswerable to a project.

It is a small change to one function plus a `rawget` in `seed_hooks`. The
value is not the saved `and` — it is the log the design asked for and the
tree does not have.

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

## How these two interact

If both land, the combo table's `__index` does one job with two steps: try the
class key, then fall back to the logging noop. They compose rather than
compete — the wildcard *is* an `__index` behaviour, which is the mechanism the
owner asked for in the first place.
