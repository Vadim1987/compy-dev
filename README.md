# Pong - Two-player Game

In this example, we explore dual input systems, 
multiplayer gameplay, collision detection, and game 
state management. You will learn how to create a 
competitive game where two players face each other 
in real-time.

```
     |   10 : 8   |
     |            |
 [|] |     []     | [|]
     |            |
```

This program implements a two-player Pong game with:
- Keyboard and mouse control for left player
- Keyboard control for right player
- Real-time collision detection
- Score tracking and game states


## Concepts Covered

- **Dual input systems** - keyboard and mouse together
- **Multiplayer input** - handling two players
- **Game loop** - update and draw callbacks
- **Collision detection** - AABB rectangle overlap
- **State management** - start, play, and game over
- **Delta time** - frame-rate independent movement


## Files

**constants.lua** - configuration values
```lua
PADDLE_WIDTH   = 10
PADDLE_HEIGHT  = 60
PADDLE_SPEED   = 180
BALL_SIZE      = 10
BALL_SPEED_X   = 240
BALL_SPEED_Y   = 120
WIN_SCORE      = 10
MOUSE_SENSITIVITY = 1.0
```

**main.lua** - game logic, rendering, and input


## Program Structure

### State Table

All game state is kept in a single global table `S`:

```lua
S = {
  player = {},   -- left paddle
  opp = {},      -- right paddle
  ball = {},     -- ball
  ps = 0,        -- left player score
  os = 0,        -- right player score
  state = "start"
}
```

This makes inspection and debugging easier. During 
gameplay, you can press BREAK and examine or modify 
any value in the `S` table.


### Coordinate System

Screen coordinates start at the top-left corner:

```
(0,0) ────────────> X (increases right)
  │
  │   [paddle]
  │   at x=30, y=200
  ↓
  Y (increases down)
```

Moving "up" means decreasing Y, moving "down" means 
increasing Y.


## Input Handling

### Left Player - Keyboard

The left player uses Q and A keys:

```lua
function updateLeft(dt)
  local dir = 0
  if love.keyboard.isDown("q") then 
    dir = -1   -- up
  end
  if love.keyboard.isDown("a") then 
    dir = 1    -- down
  end
  movePaddle(S.player, dir, dt)
end
```


### Left Player - Mouse

We enable relative mouse mode for the left player:

```lua
love.mouse.setRelativeMode(true)
mouseEnabled = true
```

This provides cursor-free control:

```lua
function love.mousemoved(x, y, dx, dy, istouch)
  if not mouseEnabled then return end
  if istouch then return end
  if S.state ~= "play" then return end
  
  local p = S.player
  p.y = p.y + dy * MOUSE_SENSITIVITY
  clampPaddle(p)
end
```

The `dy` parameter represents vertical mouse 
displacement. Moving up 5 pixels gives `dy = -5`.


### Right Player - Keyboard

The right player uses arrow keys:

```lua
function updateRight(dt)
  local dir = 0
  if love.keyboard.isDown("up") then 
    dir = -1   -- up
  end
  if love.keyboard.isDown("down") then 
    dir = 1    -- down
  end
  movePaddle(S.opp, dir, dt)
end
```


### Why Dual Input Works

Both keyboard and mouse modify `S.player.y`:

```lua
-- Keyboard in love.update():
if love.keyboard.isDown("q") then
  S.player.y = S.player.y - PADDLE_SPEED * dt
end

-- Mouse in love.mousemoved():
S.player.y = S.player.y + dy * MOUSE_SENSITIVITY
```

Their effects combine naturally. The left player can 
use either or both simultaneously.


## Movement and Physics

### Delta Time

Movement uses `dt` (delta time) for consistency:

```lua
function movePaddle(p, dir, dt)
  if dir ~= 0 then
    p.dy = PADDLE_SPEED * dir
  else
    p.dy = 0
  end
  
  p.y = p.y + p.dy * dt
  clampPaddle(p)
end
```

Without `dt`, movement would depend on frame rate.

Example:
```
PADDLE_SPEED = 180 pixels/second
dt = 0.016 seconds (60 FPS)
Movement = 180 * 0.016 = 2.88 pixels per frame
```


### Boundary Clamping

Paddles must stay on screen:

```lua
function clampPaddle(p)
  if p.y < 0 then 
    p.y = 0
    p.dy = 0
  end
  
  local maxY = H() - p.h
  if p.y > maxY then 
    p.y = maxY
    p.dy = 0
  end
end
```



## Collision Detection

### AABB Collision

Two rectangles overlap if all four edge comparisons 
are true:

```lua
function collide(b, p, offset)
  local hitX = b.x < p.x + p.w
  local hitX2 = b.x + b.s > p.x
  local hitY = b.y < p.y + p.h
  local hitY2 = b.y + b.s > p.y
  
  if hitX and hitX2 and hitY and hitY2 then
    b.x = p.x + offset
    b.dx = -b.dx
  end
end
```

Visualization:
```
Paddle:          Ball:
┌────┐          ┌──┐
│    │          └──┘
│    │  Check: overlap on all axes?
└────┘

All edges overlap → collision
Ball reverses direction
```


### Wall Bouncing

The ball reflects off top and bottom walls:

```lua
function bounceWalls(b)
  if b.y <= 0 then 
    b.y = 0
    b.dy = -b.dy
  end
  
  local maxY = H() - b.s
  if b.y >= maxY then
    b.y = maxY
    b.dy = -b.dy
  end
end
```


## Game Loop

The game runs continuously:

```lua
function love.update(dt)
  if S.state ~= "play" then return end

  updateLeft(dt)    -- left player input
  updateRight(dt)   -- right player input
  updateBall(dt)    -- physics
  
  if checkScore() then return end
  if ballOut() then resetBall() end
end
```

Each frame:
1. Check game state
2. Process both players' input
3. Update ball position and collisions
4. Check for scoring
5. Reset ball if needed


## Code Reuse

Both paddles use identical movement logic:

```lua
function updateLeft(dt)
  local dir = 0
  if love.keyboard.isDown("q") then dir = -1 end
  if love.keyboard.isDown("a") then dir = 1 end
  movePaddle(S.player, dir, dt)  -- shared
end

function updateRight(dt)
  local dir = 0
  if love.keyboard.isDown("up") then dir = -1 end
  if love.keyboard.isDown("down") then dir = 1 end
  movePaddle(S.opp, dir, dt)     -- same function
end
```

This demonstrates DRY (Don't Repeat Yourself). 
Changes to paddle behavior happen in one place.


## Relative Mouse Mode

Normal vs Relative mode comparison:

**Normal mode:**
```
Cursor visible
Mouse at x=100, y=200
Move 5 pixels right
Result: x=105, y=200
```

**Relative mode:**
```
Cursor hidden
Mouse position unknown/irrelevant
Move 5 pixels right
Result: dx=5, dy=0
```

Relative mode advantages:
- No cursor interference
- No screen edge limits
- Precise game control


## Experimentation

The program encourages exploration:

**Adjust game speed:**
```lua
PADDLE_SPEED = 120   -- slower paddles
BALL_SPEED_X = 400   -- faster ball
```

**Change mouse feel:**
```lua
MOUSE_SENSITIVITY = 0.5  -- less sensitive
MOUSE_SENSITIVITY = 2.0  -- more sensitive
```

**Modify appearance:**
```lua
COLOR_BG = {0, 0.1, 0.2}  -- dark blue
COLOR_FG = {0, 1, 0}      -- green
PADDLE_HEIGHT = 80        -- taller paddles
```

Colors use RGB from 0 to 1:
- `{1, 0, 0}` = red
- `{0, 1, 0}` = green
- `{0, 0, 1}` = blue


## User Documentation

This program is a two-player competitive Pong game.

**Controls:**
- Left player: `Q` (up) / `A` (down) or mouse
- Right player: `↑` (up) / `↓` (down)
- `Space` - start or restart game
- `Esc` - quit

**Gameplay:**
First to reach 10 points wins. The ball bounces off 
walls and paddles. When the ball goes past a paddle, 
the other player scores.

The left player can use keyboard, mouse, or both 
simultaneously for maximum control.


