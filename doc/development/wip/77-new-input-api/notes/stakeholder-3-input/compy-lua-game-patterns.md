---
description: Lua design patterns for small Compy games and examples
status: active
audience: developer
---
# Compy Lua Game Patterns

## Scope

- Use these patterns for Compy games, IDE examples, and game templates.
- For Compy IDE platform code, use `dev/docs/compy-ide-design-patterns.md`.
- Shared Lua 5.1 runtime facts live in `dev/docs/compy-lua-runtime.md`.

## Canonical Skeleton

```lua
gfx = love.graphics

WIDTH = gfx.getWidth()
HEIGHT = gfx.getHeight()
PLAYER = { x = WIDTH / 2, y = HEIGHT / 2 }

function love.update(dt)
  updatePlayer(dt)
end

function love.draw()
  drawPlayer()
end
```

## Draw Decomposition

```lua
function love.draw()
  drawBackground()
  drawPlayer()
  drawStatus()
end
```

- Keep `love.draw` as a short table of contents.
- Put repeated shape math in named helpers.

## Helper Dispatch

```lua
ACTIONS = {
  left = moveLeft,
  right = moveRight,
}

function love.keypressed(key)
  local action = ACTIONS[key]
  if action then
    action()
  end
end
```

## State

- Use individual globals for tiny examples.
- Use one global table for non-trivial game state.
- Keep all file-level variables global, including aliases and constants.
- Do not use module-scope `local` (except in performance-critical or
  generated code).

## Input

```lua
function love.keypressed(key)
  if key == "space" then
    RUNNING = not RUNNING
  end
end
```

- Use key callbacks for discrete actions.
- Use `love.keyboard.isDown` for continuous movement.

## Mouse Pointer (Relative Mode)

A mouse pushed to the top or bottom screen edge reveals the Android
status and navigation bars — disruptive on the child-facing device.
Every mouse-driven program suppresses this by taking the system pointer
out of play: run in relative mode, track the pointer yourself, and draw
your own cursor.

```lua
EDGE_PAD = 1          -- keep the pointer one pixel off the edges
POINTER_SPEED = 2.5   -- raw deltas carry no OS acceleration

love.mouse.setRelativeMode(true)
mx = WIDTH / 2
my = HEIGHT / 2

function clampAxis(v, dim)
  return math.max(EDGE_PAD, math.min(dim - EDGE_PAD - 1, v))
end

function love.mousemoved(_, _, dx, dy)
  mx = clampAxis(mx + dx * POINTER_SPEED, WIDTH)
  my = clampAxis(my + dy * POINTER_SPEED, HEIGHT)
end
```

- Relative mode hides the system cursor and delivers raw `dx, dy`
  deltas instead of absolute coordinates, so no OS pointer ever reaches
  the physical edge and the reveal gesture never fires. This is the
  load-bearing part.
- Hiding an absolute cursor (`love.mouse.setVisible(false)` without
  relative mode) does **not** work: the OS pointer still travels to the
  edge, just invisibly.
- Track your own pointer in `mx, my` and clamp it one pixel inside the
  screen — edge contact was measured to pop the bars.
- Raw deltas have no OS acceleration; scale them (`POINTER_SPEED`) for a
  usable feel.
- Draw your own cursor in `love.draw`; the system one is gone.
- Restore on every exit path, including `Shift+Esc` and `Ctrl+Esc`:
  `love.mouse.setRelativeMode(false)` (and `setVisible(true)` if you hid
  it), so the console gets its cursor back.
- Reference implementations: `repos/games/paint/`, `repos/games/pong3d/`,
  `repos/games/mouse/`.

## Text & Key Input

The IDE re-dispatches events, so input does NOT behave like upstream
LÖVE: `textinput` arrives BEFORE the matching `keypressed`, key-repeat
is on with `isrepeat` stripped, a held key repeats `textinput`, and
modifier chords emit no `textinput`. The usual "a keypress arms a flag,
its textinput consumes it" gate therefore drops presses — notably the
first press after a chord or pause — and a held key bleeds its repeats
into later state. Judge directly and edge-track held keys instead.

```lua
-- Edge-track held keys: a key already down is a repeat
-- (isrepeat is stripped); the source of truth for fresh/repeat.
INPUT = { held = { } }

-- capslock is exempt: its release may not arrive, wedging
-- the held set. Modifier chords (Alt/Ctrl+key) make no glyph;
-- consume them here. Judge non-printing keys here too.
function love.keypressed(k)
  if INPUT.held[k] and k ~= "capslock" then return end
  INPUT.held[k] = true
  if appChord(k) then return end    -- Alt/Ctrl chord
  judgeKey(k)                       -- backspace/tab/enter
end

function love.keyreleased(k)
  INPUT.held[k] = nil
end

-- textinput precedes its keypress and repeats while a key is
-- held. On a FRESH press its key is not yet held; on a REPEAT
-- it is -- so drop a glyph whose key is still held.
function love.textinput(t)
  if INPUT.held[glyphKey(t)] then return end
  judgeGlyph(t)                     -- produced glyph
end

-- A glyph -> the physical key that makes it. SHIFT_BASE
-- is the reverse of your shift map (e.g. ["!"] = "1").
function glyphKey(t)
  if t == " " then return "space" end
  if SHIFT_BASE[t] then return SHIFT_BASE[t] end
  if t:lower() ~= t then return t:lower() end
  return t
end
```

- The load-bearing part: judge `textinput` **directly**. Never gate it
  on a flag set in `keypressed` — the glyph arrives first, so the flag
  is always empty and the press is dropped.
- Edge-track held keys in `keypressed`; a key already in `held` is a
  repeat. Exempt `capslock` — its release may not arrive and would wedge
  the set.
- Drop a `textinput` whose key is still `held` — this filters key-repeat
  glyphs at the source: it stops a held wrong key knocking every frame
  and a held right key bleeding a miss onto the next target.
- Split judging by key vs glyph: non-printing keys (Backspace, Tab,
  Enter, arrows) in `keypressed`; produced glyphs (letters, digits,
  symbols, space) in `textinput`. A printable key fires both — judge it
  once, in `textinput`.
- Modifier chords (`Alt`/`Ctrl`+key) emit no `textinput`; consume them
  in `keypressed`. There is no trailing glyph to clean up.
- Because the glyph is seen while the *old* state is still current,
  guard the glyph judge on your state (target / phase / done) so a wrong
  key's glyph is dropped before a later keypress moves state under it —
  no separate "skip the next textinput" flag needed.
- Drop input while paused or modal in both callbacks.
- Why, and the platform fixes that would retire this recipe:
  `dev/docs/compy-input-quirks.md`.
- Reference implementation: `repos/games/keyboard/` — `input.lua` (the
  dispatcher) and `alt.lua` (`altTextinput` / `altPlayKey` judging).

## Frame-Independent Motion

```lua
function updateBall(dt)
  BALL.x = BALL.x + BALL.dx * dt
  BALL.y = BALL.y + BALL.dy * dt
end
```

## Color Palette

```lua
gfx.setBackgroundColor(Color[0])
gfx.setColor(Color[2 + Color.bright])
```

- Prefer palette colors over raw RGB values.
- Use brightness as state feedback.

## Anti-Patterns

- No metatables.
- No coroutines.
- No nested functions.
- No `love.load`.
- No raw RGB values in published examples.
- No module-scope `local` for file-level variables.
- No single-quoted string literals.
- No compound conditions directly in `if` or `while`.
