# keyboard — input judgement (Alt-keys subgame)

<!-- authored By LLM; human-approved NOT YET -->

**Scope:** how the keyboard example decides that a typed character matched its
target. The example's other subsystems (scenes, gauge, layout, sound) are not
covered here. `src/examples/keyboard` is a separate repository.

**Status: recommended design, not the shipped code.** The shipped code carries an
interim fix and is described at the end.

## The problem

For one physical key LÖVE delivers `keypressed(key, scancode, isrepeat)` and, if
the key produces a character, `textinput(text)` — with **no guaranteed order
between the two channels** (`../user_input.md`, "Data flow"). Desktop LÖVE sends
`keypressed` first; the web build sends `textinput` first.

Anything that reads held-key state at `textinput` time therefore answers *which
build is running*, not *what the player did*. That is a defect the example has
already shipped once: judging dropped every character whose key was held, and
since desktop delivers `keypressed` first, a key is always held when its own
`textinput` arrives — so no target was ever accepted.

`textinput` also carries no repeat flag of its own, so an OS key-repeat and a
deliberate press look identical on that channel.

## Channel ownership

| event | job |
|---|---|
| `keypressed` | drop OS repeats via `isrepeat`; toggle the Caps estimate; **inject** the non-printing targets (`backspace`, `tab`, `return`), which produce no `textinput` |
| `keyreleased` | clear `seenText` when the released key produced it; stamp the frame |
| `textinput` | the **only** judge of printable targets |

Held-key state and `keypressed` also drive the on-screen keyboard rendering.
That is presentation, and it is the only thing they drive besides the above.

## State

One predeclared table, mutated in place — never reassigned:

```lua
ALT_JUDGE = {
  seenText   = nil,    -- text of the most recent textinput, judged or not
  judgedText = nil,    -- text most recently judged
  releasedAt = nil,    -- frame at which seenText's key was released
  accepting  = false,  -- closed from a hit until the next target is displayed
}
```

Predeclared because the per-event path must allocate nothing. A table rather
than loose scalars because closing judgement is then one field on a structure
that already exists, and because the game's judgement state is a thing worth
modelling explicitly rather than leaving implicit in input plumbing.

`CAPS_STATE` stays separate: it is app-wide, not scene-scoped.

## Rules

On `textinput(text)`, in order:

1. **Reconcile Caps first, unconditionally.** For alphabetic `text`,
   `CAPS_STATE.on = isUpper(text) ~= shiftHeld`. Before every suppression below,
   because the estimate needs all available evidence — repeats and characters
   arriving during a celebration are all valid evidence of the lock state.
2. **Modifier guard.** If Alt or Ctrl is held, set `seenText = text` and stop. A
   chord's character is never a target; recording it is what suppresses the rest
   of the chord's repeats.
3. **Hold suppression.** If `text == seenText`, stop. The producing key has not
   been released since it was last seen, so this is the same physical hold. No
   timing involved: a key held for ten seconds stays suppressed for ten seconds,
   at any repeat rate.
4. **Tail window.** If `text == seenText`'s value at release and
   `frame - releasedAt <= TEXT_TAIL_FRAMES`, stop.
5. **Acceptance gate.** If `not accepting`, stop.
6. **Judge.** If `text == judgedText`, stop. Otherwise set `seenText` and
   `judgedText` to `text` and judge it: match → hit, else miss.

On a hit: `accepting = false`. When the next target is displayed (`gauge.lua`,
where the current target is set): `judgedText = nil`, `accepting = true`.

Non-printing targets are injected from `keypressed` into the same judging
function, so there is one judging path rather than two. Their repeats are
already filtered by `isrepeat`.

## Why rule 4 needs a clock

Rules 3 and 6 are state, and state alone would be preferable. It is not
sufficient. Because the channels have no order, a `textinput` can arrive **after
its own `keyreleased`**, and at that moment two cases are indistinguishable by
state: a repeat tail from the hold that just ended (drop it), and the press's own
character delivered late (judge it). Only elapsed time separates them.

So `TEXT_TAIL_FRAMES` is **not** a repeat filter — it is a bound on how far the
two channels may drift apart. A few frames; 5 at 60 fps is a starting value. Hold
suppression stays state-based, so the constant covers one narrow case instead of
underwriting the whole rule.

## Caps Lock

The **key** arrives normally as `keypressed('capslock', …)`. Three things do not:

- **the lock state** — LÖVE 11.5 has no API to query it, so `CAPS_STATE.on` is an
  estimate the example maintains;
- **the state at startup**, and any toggle made while the window was unfocused;
- **`keyreleased('capslock')`, reliably** — which is why `capslock` is exempt
  from the `isrepeat` filter in `keypressed`; a missing release would otherwise
  wedge it in the held set.

Correcting the estimate from `textinput` (rule 1) is the only way to observe a
lock state nobody reported. It must therefore run before any suppression.

## Concerns, accepted

- **Rule 6 is a dedupe, not repeat detection.** It cannot distinguish an OS
  repeat from a deliberate re-press of the same character against the same
  target. Harmless here — a wrong key knocks once per target (`gauge.lua`,
  `fumbled`) and a correct one closes acceptance. Recorded because the gap
  invites a "fix" that reaches back across the channels, which is the defect
  this design exists to prevent.
- **`altBaseKey(text)` is the example's own inference.** LÖVE does not link a
  `textinput` to the key that produced it. Rules 3 and 4 need that link and get
  it from `ALT_BASE` (the reverse of `SHIFT_MAP`) plus lowercasing. It is an
  approximation, and it is named here so later prose refers to
  `altBaseKey(text)` rather than to "the key behind the character".
- **The modifier guard reads live held state.** Rule 2 asks whether Alt or Ctrl
  is held *now*. If a chord's modifiers are released before its character
  arrives, the guard does not fire and that character is judged. Later repeats
  are still suppressed by rule 3, so only the first can slip. This is the same
  family as the original defect and is the one live-state read left in the path.
- **No test suite.** The repository has none, so this design is reasoned, not
  proven.

## Smoke checklist

- a target character is accepted on the first press;
- holding the right key scores one hit and does not bleed a miss onto the next
  target;
- holding a wrong key knocks once, not once per frame;
- `Ctrl+Alt+H`, then typing the hinted letter — the letter registers;
- `backspace` / `tab` / `return` targets still match;
- the Caps decal corrects itself after a Caps toggle the app did not observe.

## The shipped code, for contrast

`spendGlyph` (`input.lua`) claims one character per press and releases the claim
on `keyreleased`, with `INPUT.upRecent` + `INPUT_UP_GRACE` covering the tail. It
fixes the original defect and is correct for holds, but judgement still depends
on a release arriving, non-printing targets are judged on a second path
(`altPlayKey`), and a chord whose modifiers are released while its base key is
still held can slip one character through. The design above supersedes it and
should **subtract** code.
