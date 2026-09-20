---
description: Compy IDE keyboard-input quirks (event order, key-repeat, modifier chords) — how they bite game code, the platform fixes that would remove them, and where the workaround lives
status: active
audience: developer
---
# Compy Input Quirks

The IDE Controller harvests LÖVE events and re-dispatches them to the
running project. That layer changes input behavior from upstream
LÖVE/SDL in ways that quietly break input-sensitive games. This is the
catalogue: what each quirk is, how it bites, and the platform fix that
would let game code stay idiomatic. Until those land, use the
**Text & Key Input** recipe in `dev/docs/compy-lua-game-patterns.md`.

Discovered while fixing `compy-keyboard-alt-input-chord-bug`; confirmed
on-device via logcat (`adb logcat -d | grep KBD`).

## Quirks

### 1. textinput arrives BEFORE keypressed

- The produced glyph (`love.textinput`) reaches game code *before* the
  `love.keypressed` for the same physical key — the reverse of upstream
  LÖVE (keydown, then textinput). On-device every printable press logs
  `TI <glyph>` before `KP <key>` in the same frame.
- **Bites:** the idiomatic "a fresh keypress arms a flag, its textinput
  consumes it" gate cannot work — the glyph arrives before anything arms
  the flag. After any flag-clearing event (a modifier chord, a pause)
  the next press's glyph is silently dropped → "press twice" bugs. They
  are **invisible to synchronous test harnesses** that deliver
  keypressed-then-textinput, so unit tests pass while the device fails.
- **Platform fix:** re-dispatch in canonical order (keypressed →
  textinput → keyreleased), or declare the reversed order a hard
  guarantee and ship a `compy.keyboard` helper. → `compy-ide-event-order`

### 2. key-repeat is on and isrepeat is stripped

- The runtime keeps OS key-repeat enabled and drops the `isrepeat`
  argument before calling `love.keypressed`, so a repeat is
  indistinguishable from a fresh press at the callback. Held printable
  keys also emit repeated `love.textinput`.
- **Bites:** every game must re-derive "is this a repeat?" by manually
  edge-tracking held keys, and must defend against repeated textinput
  (constant feedback, or a held key's glyph bleeding into later state).
  A final key-repeat glyph can also land **just after** the key's
  release, past the held check — so a key must stay "stale" for a frame
  after release, not only while held.
- **Platform fix:** forward `isrepeat` (matches upstream), and/or expose
  a fresh-vs-repeat helper; optionally allow per-project key-repeat.
  → `compy-ide-key-repeat-flag`

### 3. a modifier chord can leak to the judge

- `Alt`+key and `Ctrl`+key fire `keypressed`, and on this IDE a glyph
  `textinput` for the key can ALSO surface — the modifier does **not**
  reliably suppress text the way upstream SDL does. Because `textinput`
  precedes `keypressed`, the held-key filter cannot catch that glyph.
- **Bites:** the chord reaches the scene as a wrong key or a wrong glyph
  and fumbles the live target — pressing any Alt-combination "eats" a
  target. Code that assumes "a chord makes no glyph, so there is nothing
  to clean up" is wrong (confirmed on-device).
- **Recovery:** treat anything with Alt or Ctrl held as a chord and drop
  it in **both** callbacks — skip the keypress and drop the textinput
  glyph; only Shift modifies a real target. See the workaround recipe.
- **Platform fix:** reliably suppress chord text (match upstream) and/or
  expose an `isChord`/`isPrintableKey` helper so games need not guess.

### 4. no project-exit cleanup hook

- A game cannot reliably restore global input state (key-repeat, text
  input, relative mouse) on exit — `love.quit` is owned by the
  Controller and the `Ctrl+Esc` force-exit path runs no game code.
- **Bites:** a game that mutates global input state leaks it into the
  console after force-exit; games must avoid mutating it instead.
- **Platform fix:** a teardown callback honored on every exit path.
  → `compy-keyboard-exit-hook`

## Debugging note

The LÖVE save dir is app-private external storage and is **not**
adb-pullable under this device's scoped storage. `print()` goes to
Android logcat, which **is** readable: `adb logcat -d | grep <TAG>`.
Use it (not the save-dir file) to inspect real on-device event order
and timing. Synthetic `adb input` does not reproduce these timing
quirks — `input keycombination` holds a key without generating
key-repeat textinput, and its event order can differ from the real
keyboard — so confirm with logcat from real typing, not injection.

## Workaround

`dev/docs/compy-lua-game-patterns.md` → **Text & Key Input**. Reference
implementation: `repos/games/keyboard/` (`input.lua`, `alt.lua`).
