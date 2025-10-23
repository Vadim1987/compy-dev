-- main.lua - Two-player Pong 

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

-- Global state
S = {
  player = {}, 
  opp = {}, 
  ball = {},
  ps = 0, 
  os = 0, 
  state = "start"
}

-- Create player paddle (left side)
function initPlayer()
  return {
    x = PADDLE_OFFSET_X,
    y = cy(PADDLE_HEIGHT),
    w = PADDLE_WIDTH,
    h = PADDLE_HEIGHT,
    dy = 0
  }
end

-- Create opponent paddle (right side)
function initOpponent()
  local wx = W() - PADDLE_OFFSET_X - PADDLE_WIDTH
  return {
    x = wx,
    y = cy(PADDLE_HEIGHT),
    w = PADDLE_WIDTH,
    h = PADDLE_HEIGHT,
    dy = 0
  }
end

-- Create ball at screen center
function initBall()
  return {
    x = cx(BALL_SIZE),
    y = cy(BALL_SIZE),
    dx = BALL_SPEED_X,
    dy = BALL_SPEED_Y,
    s = BALL_SIZE
  }
end

-- Layout: build all objects
function layout()
  S.player = initPlayer()
  S.opp    = initOpponent()
  S.ball   = initBall()
end

layout()

-- Enable mouse control
love.mouse.setRelativeMode(true)
mouseEnabled = true

-- Clamp paddle to screen
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

-- Mouse control for left player
function love.mousemoved(x, y, dx, dy, istouch)
  if not mouseEnabled then return end
  if istouch then return end
  if S.state ~= "play" then return end
  
  local p = S.player
  p.y = p.y + dy * MOUSE_SENSITIVITY
  clampPaddle(p)
end

-- Move paddle smoothly
function movePaddle(p, dir, dt)
  if dir ~= 0 then
    p.dy = PADDLE_SPEED * dir
  else
    p.dy = 0
  end
  
  p.y = p.y + p.dy * dt
  clampPaddle(p)
end

-- Ball movement
function moveBall(b, dt)
  b.x = b.x + b.dx * dt
  b.y = b.y + b.dy * dt
end

-- Ball bounces off walls
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

-- Paddle collision
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

-- Update ball physics
function updateBall(dt)
  local b = S.ball
  moveBall(b, dt)
  bounceWalls(b)
  collide(b, S.player, S.player.w)
  collide(b, S.opp, -b.s)
end

-- Check win condition
function checkWin()
  local pWin = S.ps >= WIN_SCORE
  local oWin = S.os >= WIN_SCORE
  return pWin or oWin
end

-- Handle scoring
function scored(side)
  if side == "opp" then 
    S.os = S.os + 1 
  else 
    S.ps = S.ps + 1 
  end
  
  if checkWin() then
    S.state = "gameover"
    return true
  end
  return false
end

-- Check out-of-bounds
function checkScore()
  local b = S.ball
  if b.x < 0 then 
    return scored("opp") 
  end
  if b.x + b.s > W() then 
    return scored("plr") 
  end
  return false
end

-- Reset ball position
function resetBall()
  local b = S.ball
  b.x = cx(BALL_SIZE)
  b.y = cy(BALL_SIZE)
  
  local s = S.ps + S.os
  local dir = (s % 2 == 0) and 1 or -1
  b.dx = dir * BALL_SPEED_X
  
  local yMod = (s % 3 - 1) * BALL_SPEED_Y
  b.dy = yMod * 0.3
end

-- Update left paddle
function updateLeft(dt)
  local dir = 0
  if love.keyboard.isDown("q") then 
    dir = -1 
  end
  if love.keyboard.isDown("a") then 
    dir = 1 
  end
  movePaddle(S.player, dir, dt)
end

-- Update right paddle
function updateRight(dt)
  local dir = 0
  if love.keyboard.isDown("up") then 
    dir = -1 
  end
  if love.keyboard.isDown("down") then 
    dir = 1 
  end
  movePaddle(S.opp, dir, dt)
end

-- Check if ball is out
function ballOut()
  local b = S.ball
  local outL = b.x < 0
  local outR = b.x + b.s > W()
  return outL or outR
end

-- Main update loop
function love.update(dt)
  if S.state ~= "play" then return end

  updateLeft(dt)
  updateRight(dt)
  updateBall(dt)
  
  if checkScore() then return end
  if ballOut() then resetBall() end
end

-- Draw paddle
function drawPaddle(p)
  love.graphics.rectangle(
    "fill", p.x, p.y, p.w, p.h
  )
end

-- Draw ball
function drawBall(b)
  love.graphics.rectangle(
    "fill", b.x, b.y, b.s, b.s
  )
end

-- Draw scores
function drawScores()
  local leftX = W()/2 - 60
  local rightX = W()/2 + 40
  love.graphics.print(S.ps, leftX, SCORE_OFFSET_Y)
  love.graphics.print(S.os, rightX, SCORE_OFFSET_Y)
end

-- Draw center line
function drawCenter()
  love.graphics.setColor(COLOR_FG)
  local x = W()/2 - 2
  local step = BALL_SIZE * 2
  local y = 0
  while y < H() do
    love.graphics.rectangle(
      "fill", x, y, 4, BALL_SIZE
    )
    y = y + step
  end
end

-- Draw start text
function drawStartText()
  local msg = "Press Space to Start"
  local cy = H()/2 - 16
  love.graphics.printf(msg, 0, cy, W(), "center")
end

-- Draw controls help
function drawControls()
  love.graphics.setColor(0.6, 0.6, 0.6)
  local line1 = "Left: Q/A/Mouse | Right: Arrows"
  local line2 = "Space: Start | Esc: Quit"
  love.graphics.print(line1, 20, H() - 40)
  love.graphics.print(line2, 20, H() - 20)
  love.graphics.setColor(COLOR_FG)
end

-- Draw game over
function drawGameOver()
  local msg = "Game Over - Space to Restart"
  local cy = H()/2 - 16
  love.graphics.printf(msg, 0, cy, W(), "center")
end

-- Draw state messages
function drawMessages()
  if S.state == "start" then 
    drawStartText() 
  end
  if S.state == "gameover" then 
    drawGameOver() 
  end
end

-- Main draw loop
function love.draw()
  love.graphics.clear(COLOR_BG)
  love.graphics.setColor(COLOR_FG)
  
  drawCenter()
  drawPaddle(S.player)
  drawPaddle(S.opp)
  drawBall(S.ball)
  drawScores()
  drawControls()
  drawMessages()
end

-- Handle start state
function handleStart()
  S.state = "play"
  resetBall()
end

-- Handle game over state
function handleGameOver()
  S.ps = 0
  S.os = 0
  layout()
  S.state = "start"
end

-- Keyboard input
function love.keypressed(k)
  if k == "space" then
    if S.state == "start" then
      handleStart()
    elseif S.state == "gameover" then
      handleGameOver()
    end
  elseif k == "escape" then
    love.event.quit()
  end
end

-- Recenter on canvas resize
function love.resize() 
  layout() 
end