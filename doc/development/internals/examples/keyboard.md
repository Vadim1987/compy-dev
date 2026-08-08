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

## The paradigm: one channel judges

**`textinput` is the only judge.** Judgement never consults `keypressed`,
`keyreleased`, or the held set. The order the channels arrive in therefore cannot
change a verdict — there is nothing to order. This dissolves the problem above
rather than compensating for it, which is what every previous attempt did.

The other channels keep the jobs that are theirs alone, and none of them is
judgement:

| event | job |
|---|---|
| `keypressed` | filter OS repeats at the source via `isrepeat`; toggle the Caps estimate; **feed** the non-printing targets (`backspace`, `tab`, `return`), which produce no `textinput`; **record** a handled chord's textual part (below); drive the on-screen keyboard |
| `keyreleased` | presentation only — release the key cap. **No judgement state whatsoever** |
| `textinput` | judge |

There is one judging function. What differs between a printable target and a
non-printing one is only **which channel supplies the candidate** — `textinput`
for a character, `keypressed` for a key that produces none. Exactly one of them
feeds at a time, selected by the kind of the current target
(`altIsKeyTarget`).

### What happens before the scene sees a character

Two things in `input.lua`'s shared `appTextinput` run **upstream of every
scene**, not inside this subgame, and they are unchanged since the game's first
version:

- **the chord filter** — `if INPUT.alt then return end` / `if INPUT.ctrl then
  return end`. A character produced with Alt or Ctrl held never reaches any
  scene. Only Shift modifies a target;
- **Caps reconciliation** — `capsReconcile(t, INPUT.shift)` for alphabetic
  characters, before dispatch.

Both read live modifier state, and both are **outside judgement**. This is what
"`textinput` is the only judge" means precisely: the judging function consults
nothing live, while the shared dispatch layer above it applies a filter and
maintains an app-wide estimate. Keeping that distinction is the point — the
original defect was judgement *inferring* a repeat from held state, not a
dispatcher asking whether a modifier is down.

**Caps reconciliation belongs to the shared handler and must stay there.** It
serves every scene that shows the Caps indicator (`press`, `find` via
`findkey.lua`, `intro`), not just this one. Moving it into this subgame's
judging would silently stop Caps re-estimation everywhere else.

## The precondition this rests on: one target, one keystroke

**Every target is a single character or a single non-printing key.** The subgame
never assembles a string. Progression widens the alphabet rather than lengthening
the answer — `ALT_NOTCH` 0 to 4 adds lowercase, then digits, then punctuation,
space and capitals, then the three service keys (`config.lua`, `ALT_GROUPS` /
`ALT_SERVICE`); every entry in every group is one character, and `ALT_SERVICE`'s
three are key names matched through `keypressed`.

This is what makes one remembered character sufficient. **If a later stage ever
asks the player to type a word, this design must be revisited** — `lastText`
would be deduplicating the letters of the answer against each other, and the
block would need to span an entry rather than a keystroke. Stated here because
it is the kind of premise that is invisible until it is violated.

## What the game actually requires

These rules come from the game's own scoring (`gauge.lua`), not from input
theory, and they are what makes the design small:

1. **A repeated wrong character changes nothing.** `gaugeOnWrong` is already
   idempotent per presentation — `if st.fumbled then return end`. Several wrong
   keys read as one miss, by design.
2. **A correct character advances the target immediately.** `gaugeOnCorrect`
   calls `gaugeNext` synchronously, so a repeat of the *winning* character would
   arrive with a **different** target displayed and fumble it.

So of all the repeat cases input plumbing has historically tried to suppress,
exactly one changes an outcome. The input layer owes the game one thing: **the
winning character must not be judged twice.**

## State

One predeclared table, mutated in place — never reassigned:

```lua
ALT_JUDGE = {
  lastText = nil,    -- the character most recently judged
  blocked  = false,  -- judgement and writes suspended across a win
}
```

Predeclared because the per-event path must allocate nothing. A **table** rather
than loose scalars for two reasons: blocking writes to a container is more
reliable than freezing an isolated scalar, and the game's judgement state is a
thing worth modelling explicitly rather than leaving implicit in input plumbing.

`CAPS_STATE` stays separate: it is app-wide, not scene-scoped.

## Rules

On `textinput(text)` reaching this scene — so after the shared chord filter and
Caps reconciliation above — in order:

1. **If blocked, stop.**
2. **If `text == lastText`, stop.**
3. **Judge.** Set `lastText = text`; match → hit, else miss.

Caps is deliberately **not** a rule here. It is reconciled upstream for every
scene, and it must keep running for characters this subgame ignores — repeats
and characters arriving during a celebration are all valid evidence of the lock
state, which is why the shared handler reconciles before it dispatches and
before any suppression.

**On a hit:** block, advance the target, release the block. While blocked,
nothing is judged and `lastText` is not written — so the winning character
survives the transition, and its trailing repeats are stopped by rule 3
afterwards. Blocking the writes rather than clearing the field is what makes
this hold even if a celebration or animation is ever inserted between targets.

Non-printing targets are fed from `keypressed` into the same judging function;
their repeats are already filtered by `isrepeat` at the source. **One exemption
carries over and must not be dropped:** a modifier or `capslock` pressed while a
non-printing target is displayed does **not** count as a wrong answer
(`alt.lua`'s `not isMod(k) and k ~= "capslock"`, and the same idiom in
`findkey.lua` and `hunt.lua`). Holding Shift must never knock a `backspace`
target.

## Consequences, accepted

- **An OS repeat and a deliberate re-press of the same character are not
  distinguished, and need not be.** By the game's own rules the only repeat that
  changes an outcome is a repeat of the winning character, and rule 3 stops that
  one. This is the concession that removes the clock, the grace window and the
  claim table at once.
- **Two identical consecutive targets would have their second suppressed by
  rule 2 — and the game already prevents them.** `gaugeCandidates` collects
  candidates *excluding* `st.cur`, and only falls back to the full list if that
  leaves nothing. So the case survives solely where excluding the current target
  empties the candidate set — a one-token notch. **No game-side change is
  required**; this is a precondition the game already meets, recorded so that a
  later change to candidate selection does not silently break judgement.
- **Judgement adds no modifier guard of its own.** It does not need one: the
  shared handler already drops anything produced with Alt or Ctrl held, and
  Shift must pass, since Shift is how every capital in this game is typed. A
  guard inside judgement would therefore be a second filter with an exemption
  list — the invented special case this design exists to avoid.
- **A character produced after a chord's modifiers are released is an ordinary
  character.** It passes the shared filter, because by then no modifier is held.
  A player who reaches `h` by releasing Alt from `Alt+H` has typed `h`, and that
  is a win (owner ruling, 2026-08-08). The losing half of that — a trailing
  character that is *not* the target — is handled by the chord record below,
  without adding state.
- **A character whose `textinput` arrives after its own `keyreleased` is
  judged.** Nothing couples to `keyreleased`, so a fast tap cannot lose its
  character. Every shipped version of this game to date drops it.
- **No test suite.** The repository has none, so this design is reasoned, not
  proven.

## A handled chord records its character without judging it

`Ctrl+Alt+H` re-arms the hint. If the player lets go of Ctrl and Alt while `H` is
still down, `H`'s repeats produce `h` characters that pass the shared chord
filter — no modifier is held by then — and reach judgement. If `h` is not the
current target that is a **miss**, and it fumbles the presentation the player
just asked for help with: `gaugeOnWrong` decrements that target's `learn[].n`
and the eventual correct answer then scores nothing.

**Resolution (owner, 2026-08-08).** When the scene handles a chord, it writes the
chord's textual part into `lastText` **without judging it**. The trailing
character then meets rule 2 and is ignored. If it never arrives, nothing is owed:
the next judged character overwrites `lastText` anyway. No new state, no timing,
no held read — the field that already exists is told what the player has
effectively produced.

**One invariant this must not break.** In normal play `lastText` can never equal
the live target: it is written only by judging, and after a hit the target
advances away from it (`gaugeCandidates` excludes `st.cur`), while after a miss
the character written is by definition not the target. A chord write is the first
thing that could violate that — hinting while the target *is* `h` would suppress
the player's own correct `h`, and keep suppressing it, since only a judged
character clears the field. **So the record is made only when the chord's textual
part is not the current target.** When it *is* the target, the trailing character
is let through and judged — a win, which is the ruling already given for reaching
`h` by releasing Alt from `Alt+H`.

**Residual, stated not solved.** Chords consumed at the platform's shortcuts tier
(`alt+*`, `alt+p` — `input.lua`, `register_reserved`) never reach the scene, so
the scene cannot record for them, and a character trailing one of those can still
be judged. Narrower than the hint case: those chords carry no game meaning, and
it needs the same held-across-release behaviour to occur at all.

**For the record, what the earlier versions do here** — read from the code, not
from their comments. **A** dropped it, because `inputStale` rejects a character
whose key is held: a side effect of the helper whose main use was the defect, but
it did cover this. **C** claims to cover it (`alt.lua`'s comment names `Alt+H` by
example) and the path does not bear that out — while the modifiers are down the
character never reaches `altTextinput`, so no claim is recorded, and the first
character after the release is unclaimed and would be judged. Whether any
character is produced at all depends on whether the OS emits repeats for a key
held across a modifier release, which needs the device to settle; it decides
whether C has a live defect here or a theoretical one, but not what this design
does.

## Caps Lock

The **key** arrives normally as `keypressed('capslock', …)`. Three things do not:

- **the lock state** — LÖVE 11.5 has no API to query it, so `CAPS_STATE.on` is an
  estimate the example maintains;
- **the state at startup**, and any toggle made while the window was unfocused;
- **`keyreleased('capslock')`, reliably** — which is why `capslock` is exempt
  from the `isrepeat` filter in `keypressed`; a missing release would otherwise
  wedge it in the held set.

Correcting the estimate from `textinput` (rule 1) is the only way to observe a
lock state nobody reported. It must therefore run before any suppression. It
remains presentation: it decorates the keyboard and never decides a target.

## Suggested, not adopted — a hold requirement

Owner suggestion, 2026-08-08, recorded here for the game's owner to rule on. It
is a change to the **game's rules**, not to input judgement, and is deliberately
not part of the design above.

Count a win only for a character sustained for roughly half a second, so that
storming the keyboard with an open palm is not a winning strategy. The concern is
real: today a mash whose *first* hit happens to be the correct key scores
cleanly, because `gaugeOnCorrect` counts while the presentation is not yet
fumbled.

Two ways it could be built, with their costs:

- **Stamp the frame at each `textinput`.** Cheap, and it gives the age of the
  current character directly. But the cadence it measures is the OS key-repeat
  rate — a user setting, and one that can be switched off entirely. The win
  condition would then vary by machine and be unreachable where repeat is
  disabled.
- **Confirm the win from `love.update`.** Start a timer on a candidate hit and
  confirm it if the key is still held. This does read the held set, and that is
  legitimate: the rule's own question is *"is the player still holding the
  key"*, which the held set answers **directly**. That is different in kind from
  asking the held set to *infer* whether a character is a repeat, which is the
  defect this design removes.

The second is the better shape if the rule is wanted.

## Smoke checklist

- a target character is accepted on the first press;
- holding the right key scores one hit and does not bleed a miss onto the next
  target;
- holding a wrong key knocks once, not once per frame;
- `Ctrl+Alt+H`, then typing the hinted letter — the letter registers;
- `Ctrl+Alt+H` **releasing the modifiers while `H` stays down** — no stray `h`
  reaches the target, and the target is not fumbled;
- the same, **while the target is `h`** — the trailing `h` counts as a win rather
  than being swallowed;
- `backspace` / `tab` / `return` targets still match, and **Shift held during a
  `backspace` target does not knock**;
- the Caps decal corrects itself after a Caps toggle the app did not observe —
  check it in `press` or `find` too, not only here, since the estimate is
  shared;
- a very fast tap of the target character registers — the case the shipped code
  drops.

## The shipped code, for contrast

`spendGlyph` (`input.lua`) claims one character per press and releases the claim
on `keyreleased`, with `INPUT.upRecent` + `INPUT_UP_GRACE` covering the tail. It
fixed the original defect — judgement no longer reads the held set — and it is
correct for holds and for either order of `keypressed` and `textinput`.

What it still costs: judgement depends on a release arriving, so a character
delivered after its own `keyreleased` is dropped; non-printing targets are judged
on a second path (`altPlayKey`); and the mechanism is a claim table plus a frame
stamp plus a grace constant, where the game needs one remembered character.

The design above therefore **subtracts**: `spendGlyph`, `GLYPH_CLAIMED`,
`INPUT.upRecent`, `INPUT_UP_GRACE` and `altPlayKey`'s judging path all go.
`altIsKeyTarget` stays — it is what selects the feeding channel.
