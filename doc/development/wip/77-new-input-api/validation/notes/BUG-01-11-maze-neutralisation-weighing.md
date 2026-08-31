---
description: BUG-01-11 / T-MAZE-NEUTRALIZE — the pros-and-contras the row opens with, and the evidence that collapses it
status: active
audience: developer
authored: llm
reviewed: none
---

# `BUG-01-11` — the weighing

**Session60, 2026-08-31.** The row opens *by weighing rather than by fixing* (owner, 2026-08-30),
and `wontfix` is a legitimate outcome. This is that weighing. It ends somewhere the framing did
not anticipate: **the row's premise is factually wrong**, so the choice it set up does not arise.

## What the row says

> `draw_main.lua` and `maze_main.lua` neutralise two hook sites by clearing a flag, not by the
> widget guard — they set `ctrl_pressed = nil` where `core_editor.lua` uses a pre-existing
> `is_shown` guard. The cold review could not trace every path, so this is unverified, not
> known-broken.

Two claims: (a) `ctrl_pressed = nil` is being used *as* a neutralisation idiom, in place of the
guard; (b) `core_editor.lua` shows the house alternative by using `is_shown`.

## What the code says

**`ctrl_pressed` is maze's control-mode slot, not an input guard.** `controls.lua` defines the
modes and each one assigns the slot: `keys()` sets `ctrl_pressed = handle_key`, `plan()` sets
`plan_key` and a matching `ctrl_update`. The file's own header says so — *"Control mode
initializers. Each sets two optional callbacks."* Clearing the slot means **no control mode is
active**, which is a statement about the game, not about the widget.

**The two disputed sites are mode exits, and both hide the widget in the same breath.**
`maze_main.lua`'s `to_menu()` and `draw_main.lua`'s `toDrawMenu()` set `GS.mode`/`GS.screen`, drop
`ctrl_update` and `ctrl_pressed`, and call `compy.input.hide()`. Each carries a comment saying why
the widget must go — quoting maze's own comment, whose "field" is the game's word, not ours:
*"nothing else can close one, so a field left open here would sit over the menu for the rest of
the session, taking a share of every key the menu is trying to read."* That is a
teardown of gameplay state, not a substitute for a guard.

**`core_editor.lua` uses the same idiom, so claim (b) inverts the contrast.** `arm_editor` —
`core_editor.lua:147` — is itself `ctrl_pressed = nil`, followed by `ctrl_update = rearm_input` and
`set_prompt(text)`. The row reads `core_editor.lua` as the file doing it the other way; it does it
the same way.

**And its `is_shown` is not a double-handling guard.** `core_editor.lua:68` is inside
`set_prompt`, branching *show vs configure*: if the widget is already up, reconfigure it and set
the text; otherwise open it. It answers "is there a widget to reconfigure?", not "should I ignore
this key?". The `turtle` guard the row has in mind is a different shape — a whole-handler early return
at the top of `love.keypressed`.

## Is double-handling actually prevented?

Yes, and the path is traceable end to end — which is what the cold review could not do:

1. Both games register `compy.input.hooks.keypressed`, deliberately (`maze_main.lua:233`,
   `draw_main.lua:376`; the comment explains a hook is used *because* combos are registered on the
   same channel and are offered the press first).
2. A hook is tier 2 and the widget is tier 3, so while the widget is shown **the hook still
   fires** — the framework does not silence it; that is the documented walk (`doc/input_api.md`,
   *"How events reach your project"*).
3. `maze_main.lua`'s hook returns early on `escape`, then routes to `menu_key` or `game_key`.
4. `game_key` looks up `SYSTEM_KEYS[k]` — nil for any ordinary key; the table's only member is
   `menu`, and it is never keyed by a key name — and otherwise calls `ctrl_pressed`.
5. While the editor widget is shown, `arm_editor` has set `ctrl_pressed = nil`. So the hook runs,
   finds nothing to call, and the keystroke reaches the widget alone.

No double-handling, on either game, by construction rather than by luck.

## The weighing, for the record

**For fixing it** — maze is a reference implementation, and a superseded pattern there teaches the
next reader wrongly.

**Against** — maze is a separate repo whose working code must not be overfixed to match a house
idiom, when the approach is legitimate and contradicts no convention.

**Neither argument applies**, because there is no superseded pattern here to teach anyone. The
`turtle` guard and maze's mode slot solve different problems: `turtle` has a live handler that
must stand down while the widget is shown, and maze has no live handler to stand down — its mode
slot is already empty whenever the widget is up, for its own reasons. Replacing the slot-clearing
with an `is_shown` guard would add a second, redundant mechanism to code that already reaches the
right outcome, and would make the two games *less* readable, not more.

## Recommendation, and the ruling

**Recommended `wontfix`, and correct the row's premise** — the second half matters more than the
first. The entry as written tells a future reader that maze uses the wrong idiom, and that is the
part that would mislead.

**RULED `wontfix` (owner, 2026-08-31)**, with a sharper reading than the one above. The pattern is
not merely harmless, it is **the shape the guide advises**: read the hardware early and turn the
result into a deterministic variable the rest of the logic runs on — `doc/input_api.md`, *"Perform
hardware polling before complex processing"*. What is left to say against it is that the variable
is named after the keyboard where its role is mode selection; `special_mode` would say it. That is
semantics and taste, in another repo's working code, and is **not** being fixed.

## A note on this document's own vocabulary

Its first draft said "while a field is open" five times. **"Field" is not our word** — the term is
**widget**, and the four-names row (`FIX-02-09`) exists to remove exactly this. It was corrected
here, and the observation that the phrase is still being *minted in conversation*, long after the
sweep was scoped, is recorded on that row.

## Found while reading, not fixed

`SYSTEM_KEYS` (both games) is looked up by key name — `SYSTEM_KEYS[k]` — but only ever populated
by member name (`SYSTEM_KEYS.menu`, bound to `love.mousepressed`). The lookup can therefore never
hit. It is harmless, pre-dates this feature, is unrelated to the input API, and is maze's own.
Reported, not fixed (`agents/development.md`).
