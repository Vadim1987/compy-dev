-- main.lua - Player paddle (Q/A + Mouse)

require "constants"

-- Canvas helpers
function W() 
  return love.graphics.getWidth() 
end

function H() 
  return love.graphics.getHeight() 
end

function cx(s) 
  return W()/2 - s/2 
end

function cy(s) 
  return H()/2 - s/2 
end

-- Mouse state
mouseEnabled = false
mouseSensitivity = 1.0

-- Global state
S = {
  player = {
    x=PADDLE_OFFSET_X, 
    y=0, 
    w=PADDLE_WIDTH,
    h=PADDLE_HEIGHT, 
    dy=0
  },
  opp = {
    x=0, 
    y=0, 
    w=PADDLE_WIDTH, 
    h=PADDLE_HEIGHT, 
    dy=0
  },
  ball = {
    x=0, 
    y=0, 
    dx=BALL_SPEED_X, 
    dy=BALL_SPEED_Y,
    size=BALL_SIZE
  },
  playerScore = 0, 
  oppScore = 0, 
  state = "start"
}

-- Center paddles and ball
function layout()
  S.player.y = cy(PADDLE_HEIGHT)
  S.opp.x = W() - PADDLE_OFFSET_X - PADDLE_WIDTH
  S.opp.y = cy(PADDLE_HEIGHT)
  S.ball.x = cx(BALL_SIZE)
  S.ball.y = cy(BALL_SIZE)
end
layout()

-- Enable mouse control
love.mouse.setRelativeMode(true)
mouseEnabled = true

-- Clamp paddle position
function clamp_paddle(p)
  if p.y < 0 then 
    p.y = 0 
  end
  local maxY = H() - p.h
  if p.y > maxY then 
    p.y = maxY 
  end
end

-- Move paddle (direction: -1 up, 1 down)
function move_paddle(p, dir, dt)
  p.dy = PADDLE_SPEED * dir
  p.y = p.y + p.dy * dt
  clamp_paddle(p)
end

-- Mouse control for player
function love.mousemoved(x, y, dx, dy, istouch)
  if not mouseEnabled then return end
  if istouch then return end
  if S.state ~= "play" then return end
  
  local p = S.player
  p.y = p.y + dy * mouseSensitivity
  clamp_paddle(p)
end

-- Move ball
function move_ball(b, dt)
  b.x = b.x + b.dx * dt
  b.y = b.y + b.dy * dt
end

-- Bounce off walls
function bounce(b)
  if b.y <= 0 then 
    b.y = 0
    b.dy = -b.dy
  end
  local maxY = H() - b.size
  if b.y >= maxY then
    b.y = maxY
    b.dy = -b.dy 
  end
end

-- Calculate paddle hit offset
function hit_offset(b, p)
  local pc = p.y + p.h / 2
  local bc = b.y + b.size / 2
  local o = (bc - pc) / (p.h / 2)
  return o
end

-- Paddle collision
function collide(b, p, off)
  local hitX = b.x < p.x + p.w 
  local hitX2 = b.x + b.size > p.x
  local hitY = b.y < p.y + p.h
  local hitY2 = b.y + b.size > p.y
  
  if hitX and hitX2 and hitY and hitY2 then
    b.x = p.x + off
    b.dx = -b.dx
    local o = hit_offset(b, p)
    local adjust = o * (BALL_SPEED_Y * 0.75)
    b.dy = b.dy + adjust
  end
end

-- Update ball physics
function update_ball(dt)
  local b = S.ball
  move_ball(b, dt)
  bounce(b)
  collide(b, S.player, S.player.w)
  collide(b, S.opp, -b.size)
end

-- Check win condition
function check_win()
  local pWin = S.playerScore >= WIN_SCORE
  local oWin = S.oppScore >= WIN_SCORE
  return pWin or oWin
end

-- Handle scoring
function scored(s)
  if s == "opp" then 
    S.oppScore = S.oppScore + 1
  else 
    S.playerScore = S.playerScore + 1 
  end
  
  if check_win() then
    S.state = "gameover"
    return true 
  end
  return false
end

-- Check out-of-bounds
function check_score()
  local b = S.ball
  if b.x < 0 then 
    return scored("opp") 
  end
  if b.x + b.size > W() then 
    return scored("plr") 
  end
  return false
end

-- Reset ball position
function reset_ball()
  local b = S.ball
  b.x = cx(BALL_SIZE)
  b.y = cy(BALL_SIZE)
  
  local s = S.playerScore + S.oppScore
  local dir = (s % 2 == 0) and 1 or -1
  b.dx = dir * BALL_SPEED_X
  
  local yMod = (s % 3 - 1) * BALL_SPEED_Y
  b.dy = yMod * 0.3
end

-- Update player paddle
function update_player(dt)
  local dir = 0
  if love.keyboard.isDown("q") then 
    dir = -1 
  end
  if love.keyboard.isDown("a") then 
    dir = 1 
  end
  move_paddle(S.player, dir, dt)
end

-- Update opponent AI (no flicker)
function update_opp(dt)
  local c = S.opp.y + S.opp.h / 2
  local by = S.ball.y + S.ball.size / 2
  local diff = by - c
  
  if math.abs(diff) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = diff > 0 and 1 or -1
    move_paddle(S.opp, dir, dt)
  end
end

-- Check if ball out
function ball_out()
  local b = S.ball
  local outLeft = b.x < 0
  local outRight = b.x + b.size > W()
  return outLeft or outRight
end

-- Main update loop
function love.update(dt)
  if S.state ~= "play" then return end

  update_player(dt)
  update_opp(dt)
  update_ball(dt)
  
  if check_score() then return end
  if ball_out() then reset_ball() end
end

-- Draw background
function draw_bg()
  love.graphics.clear(COLOR_BG)
  love.graphics.setColor(COLOR_FG)
end

-- Draw paddle (integer pixels)
function draw_paddle(p)
  local x = math.floor(p.x + 0.5)
  local y = math.floor(p.y + 0.5)
  love.graphics.rectangle("fill", x, y, p.w, p.h)
end

-- Draw ball
function draw_ball(b)
  local x = math.floor(b.x + 0.5)
  local y = math.floor(b.y + 0.5)
  love.graphics.rectangle(
    "fill", x, y, b.size, b.size
  )
end

-- Draw scores
function draw_scores()
  local leftX = W()/2 - 60
  local rightX = W()/2 + 40
  love.graphics.print(
    S.playerScore, leftX, SCORE_OFFSET_Y
  )
  love.graphics.print(
    S.oppScore, rightX, SCORE_OFFSET_Y
  )
end

-- Draw center line
function draw_center()
  love.graphics.setColor(COLOR_FG)
  local x = math.floor(W()/2 - 2 + 0.5)
  local step = BALL_SIZE * 2
  local y = 0
  while y < H() do
    love.graphics.rectangle(
      "fill", x, y, 4, BALL_SIZE
    )
    y = y + step
  end
end

-- Draw text helper
function draw_text(t)
  love.graphics.printf(
    t, 0, H()/2 - 16, W(), "center"
  )
end

-- Draw start message
function draw_start()
  draw_text("Press Space to Start")
end

-- Draw game over
function draw_gameover()
  draw_text("Game Over - Space to Restart")
end

-- Main draw loop
function love.draw()
  draw_bg()
  draw_center()
  draw_paddle(S.player)
  draw_paddle(S.opp)
  draw_ball(S.ball)
  draw_scores()
  
  if S.state == "start" then draw_start() end
  if S.state == "gameover" then draw_gameover() end
end

-- Handle start state
function handle_start()
  S.state = "play"
  reset_ball()
end

-- Handle game over state
function handle_gameover()
  S.playerScore = 0
  S.oppScore = 0
  layout()
  S.state = "start"
end

-- Keyboard input
function love.keypressed(k)
  if k == "space" then
    if S.state == "start" then 
      handle_start()
    elseif S.state == "gameover" then 
      handle_gameover()
    end
  elseif k == "escape" then 
    love.event.quit() 
  end
end

-- Window resize
function love.resize() 
  layout() 
end