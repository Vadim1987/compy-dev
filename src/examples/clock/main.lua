local G = love.graphics

width, height = G.getDimensions()
midx = width / 2
midy = height / 2

local M = 60
local H = M * M
local D = 24 * M * H

local h, m, s, t, ts
function setTime()
  local time = os.date("*t")
  h = time.hour
  m = time.min
  s = time.sec
  t = s + M * m + H * h
end

setTime()
ts = 0

math.randomseed(os.time())
color = math.random(7)
bg_color = math.random(7)
font = G.newFont(72)

local function pad(i)
  return string.format("%02d", i)
end

function getTimestamp()
  local hours_f = pad(math.floor(ts / H))
  local minutes_f = pad(math.fmod(math.floor(ts / M), M))
  local hours = H <= ts and hours_f or "00"
  local minutes = M <= ts and minutes_f or "00"
  local seconds = pad(math.floor(math.fmod(ts, M)))
  return string.format("%s:%s:%s", hours, minutes, seconds)
end

function love.draw()
  G.setColor(Color[color + Color.bright])
  G.setBackgroundColor(Color[bg_color])
  G.setFont(font)
  local text = getTimestamp()
  local off_x = font:getWidth(text) / 2
  local off_y = font:getHeight() / 2
  G.print(text, midx - off_x, midy - off_y)
end

function love.update(dt)
  t = t + dt
  ts = math.floor(t)
  if D < ts then
    ts = 0
  end
end

function cycle(c)
  if 7 < c then
    return 1
  end
  return c + 1
end

local function shift()
  return love.keyboard.isDown("lshift", "rshift")
end
local function color_cycle(k)
  if k == "space" then
    if shift() then
      bg_color = cycle(bg_color)
    else
      color = cycle(color)
    end
  end
end
function love.keyreleased(k)
  color_cycle(k)
  if k == "r" and shift() then
    setTime()
  end
  if k == "p" then
    pause("STOP THE CLOCKS!")
  end
end
