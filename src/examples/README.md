
# Pong - Single Player Game

In this example, we explore keyboard and mouse input, 
simple AI behavior, collision detection, and game state 
management. You will learn how to create a game where 
you compete against a computer opponent.

```
     |   10 : 8   |
     |            |
 [|] |     []     |  |
     |            | [|]
```

This program implements a single-player Pong game with:
- Keyboard and mouse control for the player
- AI opponent that follows the ball
- Real-time collision detection
- Score tracking and game states


## Concepts Covered

- **Input handling** - keyboard and relative mouse mode
- **Simple AI** - opponent tracks ball position
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
AI_DEADZONE    = 10
```

**main.lua** - game logic, AI, rendering, and input


## Program Structure

### State Table

All game state is kept in a single global table `S`:

```lua
S = {
  player = {},   -- your paddle (left)
  opp = {},      -- AI paddle (right)
  ball = {},     -- ball
  ps = 0,        -- player score
  os = 0,        -- opponent score
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


## Player Input

### Keyboard Control

The game checks keyboard state each frame:

```lua
function updatePlayer(dt)
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

The `dir` variable represents direction:
- `-1` = upward (decrease Y)
- `0` = stationary
- `1` = downward (increase Y)


### Mouse Control - Relative Mode

We enable relative mouse mode to track movement 
without cursor constraints:

```lua
love.mouse.setRelativeMode(true)
mouseEnabled = true
```

This changes how mouse data is reported. Instead of 
absolute coordinates, we receive displacement values:

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

The `dx` and `dy` parameters represent pixels moved 
since the last callback. Moving the mouse up 5 pixels 
gives `dy = -5`.

Relative mode advantages:
- Cursor is hidden during gameplay
- No screen edge limitations
- More precise control


### Dual Input

Both keyboard and mouse control the player paddle 
simultaneously. They both modify `S.player.y`, so 
their effects combine naturally.


## AI Opponent

### Simple Tracking AI

The opponent paddle follows the ball's Y position:

```lua
function updateOpp(dt)
  local c = S.opp.y + S.opp.h / 2
  local by = S.ball.y + S.ball.size / 2
  local diff = by - c
  
  if math.abs(diff) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = diff > 0 and 1 or -1
    movePaddle(S.opp, dir, dt)
  end
end
```

How it works:
1. Calculate paddle center (`c`)
2. Calculate ball center (`by`)
3. Find the difference (`diff`)
4. If difference is small (within deadzone), stop
5. Otherwise, move toward the ball

The deadzone prevents jitter. Without it, the paddle 
would constantly oscillate around the ball position.


### AI Deadzone

```lua
AI_DEADZONE = 10
```

This creates a "comfort zone" around the ball. If the 
paddle center is within 10 pixels of the ball center, 
the AI stops moving.

Visualization:
```
Ball center: y = 300

Deadzone: 290 to 310
  ┌─────────┐
  │         │
  │    ●    │  ← AI stops here
  │         │
  └─────────┘

Outside deadzone: AI moves toward ball
```

Adjusting this value changes AI behavior:
- Smaller (5) = more precise, but jittery
- Larger (20) = smoother, but less accurate


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

Without `dt`, movement speed would depend on frame 
rate. A computer running at 30 FPS would see the 
paddle move half as fast as one at 60 FPS.

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

When a paddle hits the edge, we stop its velocity 
to prevent visual jitter.


## Collision Detection

### AABB Collision

We use Axis-Aligned Bounding Box collision. Two 
rectangles overlap if all four edge comparisons 
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
│    │  Check: do they overlap?
└────┘

If all edges overlap → collision
Ball direction reverses
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

Reversing `dy` changes vertical direction while 
maintaining speed.


## Game Loop

The game runs in a continuous loop:

```lua
function love.update(dt)
  if S.state ~= "play" then return end

  updatePlayer(dt)  -- player input
  updateOpp(dt)     -- Computer behavior
  updateBall(dt)    -- physics
  
  if checkScore() then return end
  if ballOut() then resetBall() end
end
```

Each frame:
1. Check game state
2. Process player input
3. Update AI opponent
4. Update ball position and collisions
5. Check for scoring
6. Reset ball if out of bounds


## Code Reuse

Notice how both paddles use the same movement function:

```lua
function updatePlayer(dt)
  local dir = 0
  if love.keyboard.isDown("q") then dir = -1 end
  if love.keyboard.isDown("a") then dir = 1 end
  movePaddle(S.player, dir, dt)  -- shared
end

function updateOpp(dt)
  -- AI calculates direction
  local dir = diff > 0 and 1 or -1
  movePaddle(S.opp, dir, dt)     -- same function
end
```

This demonstrates the DRY principle (Don't Repeat 
Yourself). Changes to paddle movement only need to 
be made once.


## Experimentation

The program is designed for interactive exploration.

**Adjust difficulty:**
```lua
AI_DEADZONE = 5    -- harder (Computer more precise)
AI_DEADZONE = 20   -- easier (Computer less precise)
PADDLE_SPEED = 120 -- slower paddles
```

**Change ball speed:**
```lua
BALL_SPEED_X = 400  -- faster horizontal
BALL_SPEED_Y = 200  -- faster vertical
```

**Modify mouse sensitivity:**
```lua
MOUSE_SENSITIVITY = 0.5  -- less sensitive
MOUSE_SENSITIVITY = 2.0  -- more sensitive
```

**Change colors:**
```lua
COLOR_BG = {0, 0.1, 0.2}  -- dark blue
COLOR_FG = {0, 1, 0}      -- green
```

Colors use RGB values from 0 to 1.


**Controls:**
- Player: `Q` (up) / `A` (down) or mouse
- `Space` - start or restart game
- `Esc` - quit

**Gameplay:**
First to reach 10 points wins. The ball bounces off 
walls and paddles. If the ball goes past your paddle, 
the opponent scores.

The computer opponent tracks the ball automatically 
and will try to intercept it.




