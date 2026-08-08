# S29 — does the shortcuts design rest on the premise we just called unreliable?

Owner question, 2026-08-08, raised while resolving the keyboard example's chord
case: this session has repeatedly said that reading held-key state at `textinput`
time is unreliable, because LÖVE guarantees no order between `keypressed` and
`textinput`. **The shortcuts tier reads `keys_pressed` to build the combo it
matches on — including on the `textinput` channel.** Does the whole design rest
on the same faulty premise?

The owner's own acceptance bar, stated with the question: shortcuts working
almost always, with a small acknowledged miss fraction, is tolerable; shortcuts
that never fire because the design is wrong is not.

**Answer: the design holds, and no miss fraction needs acknowledging.** The two
cases are different in kind, and the difference is visible in the code.

## What the combo is actually built from

`Controller.combo_string(k, keys_pressed)` (`controller.lua:395`):

```lua
for _, m in ipairs(COMBO_MODS) do
  if keys_pressed[m[1]] or keys_pressed[m[2]] then
    parts[#parts + 1] = m[3]
  end
end
parts[#parts + 1] = k
```

It consults `keys_pressed` for **modifiers only** — the l/r pairs in
`COMBO_MODS`. The trigger `k` is not looked up in the held set at all: it arrives
from the event's own payload, via `TRIGGER[event]`
(`projectInputController.lua:48`), and for `textinput` that is
`function(t) return t end` — the character itself.

## Why that is stable, where the original defect was not

The ambiguity LÖVE leaves open is between a character and **its own** key events.
Nothing constrains whether `textinput('a')` arrives before or after
`keypressed('a')`.

A modifier is a **different key**, pressed before the character and released
after it, on human timescales — tens of milliseconds at least, usually far more.
Its presence in `keys_pressed` does not change across the window in which the
character's own events might be reordered. So "is Ctrl down" has a stable answer
at `textinput` time; "has this character's own key been pressed yet" does not.

The keyboard example's original defect read `INPUT.held[k]` where `k` was **the
producing key of the character being judged** — exactly the key whose ordering is
ambiguous. That is why it failed categorically on desktop rather than
occasionally: on desktop the answer is *always* the wrong one.

This is the same distinction already recorded in
`doc/development/internals/examples/keyboard.md`: asking the held set whether a
modifier is down is a **direct** question; asking it to **infer** whether a
character is a repeat is not.

## Edges checked, none of them a reliability problem

- **`keypressed` channel.** `handlers.keypressed` sets `keys_pressed[k] = true`
  *before* dispatch, so the trigger is in the set when the combo is built — but
  since `combo_string` reads only modifiers, that is inert. Where the trigger
  *is* a modifier, `find_shortcut` stops the class fallback explicitly
  (`if sc or Key.is_mod(trigger) then return sc end`).
- **`keyreleased` channel.** `handlers.keyreleased` clears `keys_pressed[k]`
  before dispatch, so a release combo carries the remaining modifiers and not the
  released key. Consistent with the above.
- **Releasing a modifier in the same instant as the character.** Possible in
  principle for Shift, and it would build `a` where `shift+a` was expected. But
  for `textinput` the shift is already baked into the character (`A`), so the
  natural registration is the character itself; this is an API-shape question
  about whether `shift+a` is even meaningful on the text channel, not a
  reliability one.
- **Ctrl/Alt combos on `textinput`.** Desktop generally produces no character
  under Ctrl or left-Alt, so those combos are largely unreachable on that channel
  regardless. Again a reachability question, not a correctness one.

## Disposition

No change proposed. Recorded because the question is a good one, will be asked
again, and the answer is not obvious from reading either file alone —
`combo_string`'s modifier-only reach is the load-bearing detail and it is one
line deep in `controller.lua`.

**P10 candidate:** a sentence of this belongs in
`doc/development/internals/user_input.md`, "Data flow", next to the
no-ordering-guarantee statement — a reader who has just been told the channels
are unordered will reasonably wonder how combos can be trusted. Held for P10
rather than written now, per the code-then-docs ordering.
