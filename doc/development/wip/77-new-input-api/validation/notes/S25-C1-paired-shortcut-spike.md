---
description: Spike — the owner's paired keypressed/textinput shortcut idiom for the C1 race, run against the real dispatch chain; works for bare triggers, blocked for modified ones by a pre-existing combo-case defect
status: active
audience: developer
authored: llm
reviewed: none
---

# S25 · spike — the paired-shortcut idiom for the C1 race

Owner's proposal (2026-08-03), paraphrased: instead of a framework
mechanism, register **two** shortcuts under the same combo — the
`keypressed` one opens the overlay, the `textinput` one swallows the echo
and **unregisters itself**; whatever closes the overlay re-arms it. Order
between the two events stops mattering, because whichever arrives first is
handled by its own channel.

Not landed anywhere. This note is evidence for the ruling.

## Verdict

**It works, and it needs no framework change** — proven against the real
dispatch chain, in both delivery orders. Two limits, one of them a
pre-existing defect elsewhere in the surface:

1. **Re-arming has no single home.** Escape *clears but does not hide*
   (Decision 6 continuity), and there is no `after_hide`/`on_close`
   callback — only `before/after_submit` and `before/after_cancel`. A
   project that hides from its own code must re-arm at that site. Every
   close path added later is a place the idiom silently rots.
2. **Only bare triggers share a combo key.** With a modifier held the two
   channels look up *different* strings, and the `textinput` one is
   **unreachable** — see the measurement below.

## Why the dispatch chain permits it

`src/controller/projectInputController.lua:71-83` — the walk is
`shortcuts[event][combo]` → `hooks[event]` → widget, stopping at the first
truthy. Three facts follow, all load-bearing for the idiom:

- shortcuts are consulted **before the widget on every channel**, including
  `textinput`, so the echo can be intercepted before the field sees it;
- the lookup is a direct index, not a `pairs` walk, so a handler may delete
  its own entry while running;
- leaf writes are permitted — the sub-table *identities* are frozen
  (`consoleController.lua:376-380`), the combo slots are not.

## The spike

Run against `tests.helpers.input_fixture`; **6 successes / 0 failures**,
including the deliberate negative row.

```lua
local function arm(input, combo)
  input.shortcuts.textinput[combo] = function()
    input.shortcuts.textinput[combo] = nil
    return true
  end
end

local function install(combo)
  local input = F.activate_project()
  input.shortcuts.keypressed[combo] = function()
    if not input.is_shown() then
      input.show({ prompt = 'cmd' })
    end
    return true
  end
  arm(input, combo)
  return input
end
```

| Row | Sequence | Result |
|---|---|---|
| order A | `press('i')` → `type('i')` | shown, field **empty** |
| order B | `type('i')` → `press('i')` | shown, field **empty** |
| trigger char is typable | open, then `type('i')`, `type('i')`, `type('x')` | `'ix'` — the one-shot is spent, later `i`s are content |
| **negative:** no re-arm | open, echo eaten, `hide()`, open again | field `'i'` — **the race is back** |
| re-arm at the close site | same, with `arm()` after `hide()` | field **empty** |
| re-arm via `after_cancel` | `after_cancel = hide + arm` | field **empty** on the second open |

Order B is the interesting one: the `textinput` arrives while the overlay is
still *closed*, the one-shot eats it and disarms, and the `keypressed` then
opens a clean field. Nothing depends on which event LÖVE delivers first —
which is exactly what the batch seal was built to achieve, achieved without
it.

Also worth noting: the `keypressed` shortcut stays registered and consuming
while the overlay is up, and that is harmless — the widget takes its content
from `textinput`, so consuming the trigger's *keypress* costs nothing.

## The modified-trigger limit — measured, not reasoned

Registration normalises, dispatch does not. `Key.new_handler_table`'s
`__newindex` (`src/util/key.lua:74-80`) stores every combo through
`normalize_combo`, which **lower-cases** (`:lower()` in `split_combo`,
`:44`). `Controller.combo_string` (`controller.lua:390-399`) prepends held
modifiers to the raw trigger and lower-cases nothing — and on the `textinput`
channel the trigger is the literal character.

Probed directly:

```
DISPATCH LOOKS UP:      shift+I , i
REGISTRATION STORED AS: shift+i
```

So `shortcuts.textinput['shift+I']` — the slot the idiom needs for a
`shift+i` trigger — **cannot be written**: it normalises to `shift+i`, which
dispatch never asks for. Bare lowercase triggers (`i`, and hence
`examples/turtle`'s actual case) are unaffected; anything shifted, and
anything an IME produces, is out of reach.

This is the debt ledger's *"`combo_string` does not normalise the case of a
textinput token"*, whose revisit condition is *"if a real textinput-combo
consumer appears"*. This proposal is that consumer, so the condition has
fired — noted in the entry.

## What it changes about the option set

The idiom is a much better **(d)** than the "clear the field on the next
`update`" shape recorded earlier: no flicker, no field mutation, no guessing.
It is recorded as **(d′)** in
[`../reviews/S25-C1-event-batch-seal.md`](../reviews/S25-C1-event-batch-seal.md).

It also improves the *framework* option. If the framework armed the one-shot
itself when `show()` is called from inside a keyboard event, projects would
write nothing — and a framework-armed one-shot can be a **wildcard** (swallow
the next `textinput`, whatever it is), which sidesteps the combo-case defect
entirely and is strictly narrower than the reverted batch seal. That is
option (a′), and the owner's idea is what makes it implementable in the
existing shortcuts vocabulary rather than as new widget state.
