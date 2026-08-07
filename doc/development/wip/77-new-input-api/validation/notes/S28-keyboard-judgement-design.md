# S28 — keyboard Alt-keys: judgement decoupled from delivery order

**Status: agreed design, not yet implemented.** Owner design + rulings,
2026-08-07. Scheduled as **P9b** in the running plan
(`../reviews/S27-triage-and-plan.md` §4).

Background: SM5 and its interim fix are in `S28-smoke-findings.md`; why this is
not the turtle echo guard is in `S28-owner-concerns.md`.

## The resolution

The interim fix (`3a9d48c`, nested keyboard repo) is correct and stays in place
until this lands. It replaced *"is the producing key held"* — which answers
which build you are on, not whether a glyph is a repeat — with a claim per
press. That works, but it still leans on an input event: the claim is released
by `keyreleased`, so a lost release leaves a key's glyphs dropped.

The owner's design goes further and removes the lean entirely. **Judgement reads
one channel.** `textinput` decides hits and misses; `keypressed` and the held set
drive the on-screen keyboard and nothing else. Delivery order stops being
handled and starts being irrelevant.

Acceptance is re-opened by a **game** event — a new task being displayed — not by
a device event. Game state governing game rules is the invariant worth having:
device delivery cannot wedge it.

## The state

**A predeclared table, mutated in place; never reassigned** (owner, 2026-08-07):

```lua
-- Judgement state for the Alt-keys scene. Predeclared once and
-- written field-by-field: closing acceptance is one flag on a
-- table that already exists, not a scalar frozen somewhere else.
ALT_JUDGE = {
  lastGlyph = nil,    -- the glyph most recently judged
  accepting = false,  -- are writes open? closed from a hit until the next task
}
```

Two reasons the owner gave, both worth keeping in the code:

- **Blocking writes to a table is more reliable than freezing an isolated
  scalar** — one place says whether judgement is open, and it is the same place
  that holds what was last judged.
- **It models the game's internal state explicitly**, rather than leaving that
  state implicit in the input plumbing, which is where it lives today.

Predeclared, so the per-event path allocates nothing — the same argument that
ruled out a journal: a growing list judged only by its last entry is machinery
outgrowing its rule, and it churns the GC on a device that cannot afford it.

**Caps stays where it is.** `CAPS_STATE = { on = false }` is app-wide, not
scene-scoped, and already follows exactly this pattern — a predeclared table
holding one scalar. Folding it into `ALT_JUDGE` would put two different
lifetimes in one table.

## The rules

Judging, on a `textinput` glyph reaching the scene:

1. `if not ALT_JUDGE.accepting then return end` — between a hit and the next
   task, nothing is judged.
2. `if ch == ALT_JUDGE.lastGlyph then return end` — the same glyph again is an
   OS repeat.
3. record `ALT_JUDGE.lastGlyph = ch`, then judge: match → `altHit()`, otherwise
   `altWrong()`.
4. on a hit: `accepting = false`, `lastGlyph = nil`.
5. when the gauge displays the next target (`gauge.lua`, where `st.cur` is set
   and `st.fumbled` cleared): `accepting = true`.

**Non-printing targets are injected, not judged separately.** Backspace, Tab and
Enter produce no glyph, so `appKeypressed` writes the key name into the same
path — one judging function, one state. Repeats there are already filtered by
the real `isrepeat` flag `appKeypressed` receives, so the injection needs no
filter of its own. This retires the second judging path (`altPlayKey`), which is
the part of today's code that makes "which channel decides?" ambiguous.

## Consequences, accepted

**Rule 2 is a dedupe, not repeat detection.** It cannot distinguish an OS repeat
from a deliberate re-press of the same key. That costs nothing here — a wrong key
already knocks once per target (`gauge.lua`, `st.fumbled`), and a correct one
closes acceptance — but it must be written down, because the next reader will
spot the gap and be tempted to reach back across the channels to close it. That
reach is the bug this design exists to remove.

**Caps reconciliation must read the RAW glyph stream.** Effective Caps Lock has
no API in LÖVE 11.5 and is re-derived from every alphabetic `textinput` as
`isUpper(letter) XOR shift_held` (`indicators.lua`). It therefore has to run
*before* rules 1 and 2 — a held key's repeats and glyphs typed during a
celebration still correct the estimate. Concretely: `capsReconcile` stays in
`appTextinput`, and the dedupe lives in the scene's judging function, not at the
input hook.

**The post-keyup grace stays.** `INPUT.upRecent` + `INPUT_UP_GRACE` guard a
different leak: a glyph that arrives after its own key is already up. The OS
emits repeat glyphs while a key is held, and the last one can land after the
keyup has been processed — which matters because the keyup is exactly what
re-opens the key for judging. `appKeyreleased` stamps the release frame
(`DBG_FRAME`, the game's own counter from `main.lua`), and for one frame after
it, glyphs for that key are discarded. Orthogonal to delivery order and cheap.

**A chord's trailing glyph needs one more line — record what the modifier guard
discards.** `appTextinput` drops glyphs while Alt or Ctrl is held (a chord glyph
is never a target), *before* judging sees them. So if the child holds Ctrl+Alt+H,
releases the modifiers and **keeps holding `h`**, the next repeat glyph arrives
unmodified, with nothing recorded about it and its key not released — past rule 2
(the last judged glyph is a different character) and past the grace. It would be
judged as a fresh wrong key.

The interim `spendGlyph` fix has this hole; the pre-SM5 held-set check covered it
by accident, because a held key was always stale. **The design closes it without
reaching back across the channels: write `lastGlyph` even when the modifier guard
discards the glyph.** It *was* seen, so recording it makes the trailing repeats
dedupe away by rule 2. One assignment, no new state, no cross-channel inference —
and it is the reason judgement state must be reachable from `appTextinput`, not
private to the scene's judging function.

## What this removes

`GLYPH_CLAIMED`, `spendGlyph`, and the `INPUT.held` read in the judging path all
go: the interim fix's machinery is superseded, not extended. `altPlayKey`'s
separate judging path folds into the injection. The net change should **subtract**
code, and if it does not, the design has been misread.

## Files

- `src/examples/keyboard/input.lua` — drop `spendGlyph`/`GLYPH_CLAIMED`; keep
  `INPUT.upRecent` and the grace; `appKeypressed` injects the non-printing
  targets; `capsReconcile` stays where it is.
- `src/examples/keyboard/alt.lua` — `ALT_JUDGE`, the five rules, one judging
  function.
- `src/examples/keyboard/gauge.lua` — re-open acceptance where the next target
  is displayed.

**No platform change, and no platform helper.** One example's need is not an API
(`agents/rules.md`, "No invented special cases").

## Verification

The keyboard repo has **no test suite**, so this is reasoned, not proven — same
standing as the interim fix. It wants a smoke pass on the device: a target letter
accepted on first press; a held right key not bleeding a miss onto the next
target; a held wrong key knocking once; Backspace/Tab/Enter targets still
matching; the Caps decal still correcting itself after an unobserved Caps toggle.
