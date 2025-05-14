local G = love.graphics
math.randomseed(os.time())
cw, ch = G.getDimensions()
midx = cw / 2

require('bit')
require('math')
require('examples')

size = 28
spacing = 3
offset = size + 4

local colors = {
  bg   = Color[Color.black],
  pos  = Color[Color.white],
  neg  = Color[Color.red],
  text = Color[Color.white]
}

body = 'return -i / (count * count)'
legend = ''
count = 16
ex_idx = 1
ex_idx = 14

function load_example(ex)
  body   = ex.code
  legend = ex.legend
end

function advance()
  local e = examples[ex_idx]
  load_example(e)
  if ex_idx < #examples then ex_idx = ex_idx + 1 end
end

function pick_random(t)
  if type(t) == "table" then
    local n = #t
    local r = math.random(n)
    return t[r], r
  end
end

function randomize()
  local e, i = pick_random(examples)
  load_example(e)
  ex_idx = i
end

function b2n(b)
  if b then return 1 else return 0 end
end

function n2b(n)
  if n ~= 0 then return true else return false end
end

local time = 0
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
  G.setColor(colors.text)
  local sof = (size / 2) + offset
  G.printf(legend, midx + sof, sof, midx - sof)
end

r = user_input()

function love.update(dt)
  time = time + dt
  if r:is_empty() then
    input_code('function tixy(t, i, x, y)', string.lines(body))
  else
    local ret = r()
    body = string.unlines(ret)
    legend = ''
  end
end

function love.mousepressed(_, _, button)
  if button == 1 then
    advance()
  end
  if button == 2 then
    randomize()
  end
end

advance()
