--- @diagnostic disable: duplicate-set-field,lowercase-global
cw, ch = love.graphics.getDimensions()

require('math')

size = 28
spacing = 3
offset = size + 4

local colors = {
  bg = Color[Color.black],
  pos = Color[Color.white],
  neg = Color[Color.red],
}

count = 16
local time = 0
body = "return (x - y) - math.sin(t)"
callback = function(t, i, x, y)
  local code = [[
    local count = ...
    return function(t, i, x, y)
    ]] .. body ..
      ' end'
  local f    = loadstring(code)
  if f then
    setfenv(f, _G)
    local val = assert(f)(count)(t, i, x, y)

    return val
  end
end

function drawOutput()
  local index = 0
  local ts = time

  for y = 0, count - 1 do
    for x = 0, count - 1 do
      local value =
          tonumber(callback(ts, index, x, y) or .1) or -.1
      local color = colors.pos
      local radius = (value * size) / 2
      if radius < 0 then
        radius = -radius
        color = colors.neg
      end

      if radius > size / 2 then
        radius = size / 2
      end

      G.setColor(color)
      G.circle("fill",
        x * (size + spacing) + offset,
        y * (size + spacing) + offset,
        radius
      )
      index = index + 1
    end
  end
end

function love.draw()
  --- background
  G.setColor(colors.bg)
  G.rectangle("fill", 0, 0, cw, ch)

  drawOutput()
end

r = user_input()

function love.update(dt)
  time = time + dt
  if r:is_empty() then
    input_code('function tixy(t, i, x, y)')
  else
    local ret = r()
    body = string.unlines(ret)
  end
end
