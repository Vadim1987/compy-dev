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

## Follow-up: should the keyboard example register `shortcuts.textinput['alt+*']`?

Owner question, same session: the reserved chords are registered on `keypressed`
only, so should `textinput` get the same `stop_here` plumbing, to suppress
characters emitted by a chord?

**No — and the reason is that it would not touch the case that motivates it.**
The two candidate characters are different events:

**The chord's own character** (Alt held while it is produced — AltGr layouts do
this; desktop Ctrl and left-Alt generally produce nothing). A
`shortcuts.textinput['alt+*']` registration *would* match this one, because the
class lookup does run on `textinput`: `find_shortcut` tries
`tbl[combo_string(t, keys)]` and then falls back to `tbl[combo_string('*', keys)]`
= `alt+*` while Alt is held. But it is **already suppressed**, by the example's
own hook: `appTextinput` opens with `if INPUT.alt then return end` /
`if INPUT.ctrl then return end` (`input.lua:189-194`). Registering the shortcut
would be a second mechanism for a job already done — the DRY problem, and a
divergence risk the moment one of the two is edited.

> **Correction (owner, 2026-08-08).** An earlier draft of this paragraph said the
> existing guard sits "one tier up" from the proposed shortcut. That is backwards
> and the owner caught it. The walk is **shortcuts → hooks → widget**
> (`projectInputController.lua:133-141`): `appTextinput` is registered as a
> **hook** (`input.lua:104`), so it sits one tier **below** where the proposed
> shortcut would sit. The DRY point stands; the direction was wrong.

**The trailing character** (modifiers already released, key still held — the
residual this whole thread is about). By then **no modifier is held**, so
`combo_string` yields the bare character and the class key is a bare `'*'`.
`alt+*` cannot match it. The proposed registration is a **no-op on the case it
was proposed for**, by construction: a modifier-classed shortcut cannot catch an
event that carries no modifier.

So the concern about chord-emitted characters is genuinely non-existent — but
because the example already filters them at the hook, not because the platform
does. The gateway applies **no** modifier filter to `textinput`
(`controller.lua:899-903`, `handlers.textinput` forwards unconditionally); that
choice belongs to the example.

Worth knowing for the example: because `INPUT.alt` folds `lalt` and `ralt`, that
filter also drops **AltGr**-produced characters. No Alt-keys target needs AltGr —
the target set is ASCII (`ALT_GROUPS`, `SHIFT_MAP`) — so it costs nothing today,
but a layout-aware target set later would collide with it.

## The literal question: does LÖVE fire `textinput('h')` while Ctrl+Alt+H are held?

Asked directly by the owner, and the earlier answer talked around it. **Not
answerable from this repository** — it is SDL/OS behaviour, and the only smoke
evidence anyone has here is Linux under `xvfb`. Stating what is known and where
the boundary of that knowledge is:

- **Linux and macOS:** Ctrl+key and Alt+key generally produce **no** `textinput`.
  SDL generates text from the layout, and those modifiers suppress composition.
- **Windows:** **AltGr is reported as LeftCtrl + RightAlt.** On layouts that use
  AltGr for characters, a Ctrl+Alt chord therefore *can* produce a character.
  This is the case that makes "generally no" not "never".

Consequence for the example: the `INPUT.alt` / `INPUT.ctrl` guard in
`appTextinput` is **load-bearing on Windows AltGr layouts** and inert elsewhere.
It should not be removed as dead code by someone testing only on Linux.

## Follow-up finding: `INPUT` is a façade, but its modifier folding is a duplicate

Owner asked what `INPUT` is, suspecting a private held-key register duplicating
the platform's. Checked (`input.lua:53-61`):

```lua
INPUT = setmetatable({ upRecent = { } }, {
  __index = function(_, k)
    if k == "held"  then return compy.input.keys_pressed end
    if k == "shift" then return modHeld("lshift", "rshift") end
    if k == "ctrl"  then return modHeld("lctrl", "rctrl") end
    if k == "alt"   then return modHeld("lalt", "ralt") end
  end,
})
```

**It is not a duplicate register.** `INPUT.held` *is* `compy.input.keys_pressed`,
and `modHeld` reads that same table. The file's own comment says so — *"Only
`upRecent` is ours"* — and `upRecent` is exactly what the new design deletes,
which would leave `INPUT` a pure read-through façade owning nothing.

**But the folding is a duplicate, and the owner is right about that.** The
platform already has `Key.shift()` / `Key.ctrl()` / `Key.alt()`
(`src/util/key.lua:166-178`), and projects **can** reach them — `paint`,
`tixy` and `sapper` all call them (`paint/main.lua:407`, `tixy/main.lua:197`,
`sapper/main.lua:672,690,697`). So the example hand-rolls a fold the platform
provides.

**And they are not the same question.** `Key.alt()` polls
`love.keyboard.isDown(...)` — the **live device**. `modHeld` reads
`compy.input.keys_pressed` — the framework's **event-tracked** set. They can
disagree: a key released while the window is unfocused never delivers its
`keyreleased`, so the event set stays stale-true while the device poll reports
false. That is the same staleness hazard the example already documents for
`capslock`.

**The platform mixes the two itself.** `combo_string` builds combos from
`keys_pressed` (event-tracked), while `handlers.keypressed` / `handlers.keyreleased`
gate on `Key.ctrl()` / `Key.alt()` / `Key.shift()` (device poll) —
`controller.lua:514, 531, 791, 813, 824`.

**What this adds up to, for the owner to rule on.** The public surface documents
`compy.input.keys_pressed` — raw, unfolded, event-tracked — and every project
that wants "is Shift held" either hand-rolls the l/r fold or reaches for the
undocumented `Key`. Two ways to ask one question, with different failure modes,
one of them not part of the advertised API. The owner's own in-code
`REMARK: WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?` (`input.lua:56`)
is pointing at this.

Not acted on. It is an API-surface question in the feature's own territory, and
the options — document `Key`, expose a folded query on `compy.input`, or rule
that hand-rolling is the intended cost — differ in whether they add a moving
part to an API whose brief was to get simpler. **Owner's call; a candidate for
P10/W9 or for the PR's open questions.**

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
