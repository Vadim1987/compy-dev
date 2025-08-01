local goose = { 0.303, 0.431, 0.431 }
local width, height = G.getDimensions()
--- color palette
local block_w = width / 10
local block_h = block_w / 2
local pal_h = 2 * block_h
local pal_w = 8 * block_w
local sel_w = 2 * block_w
--- tool
local margin = block_h / 10
local m_2 = margin * 2
local m_4 = margin * 4
local box_w = 1.5 * block_w
local box_h = height - pal_h
local marg_l = box_w - m_2
local tool_h = box_h / 2
local mid_t = box_w / 2
local n_t = 2
local icon_h = (tool_h - m_4) / n_t
local icon_w = (box_w - m_4 - m_4) / 1 -- one col for now
local icon_d = math.min(icon_w, icon_h)

-- line weight
local weight_h = box_h / 2
local wb_y = box_h - weight_h
local weights = { 1, 2, 4, 5, 6, 9, 11, 13 }
--- canvas
local can_w = width - box_w
local can_h = height - pal_h
local canvas = G.newCanvas(can_w, can_h)

local color = 0    -- black
local bg_color = 0 -- black
local weight = 3
local tool = 1     -- brush

function inCanvasRange(x, y)
  if y <= height - pal_h then
    if x >= box_w then
      return true
    end
  end
  return false
end

function inPaletteRange(x, y)
  if y >= height - pal_h then
    if x >= width - pal_w
        and x <= width
    then
      return true
    end
  end
  return false
end

function inToolRange(x, y)
  if x <= box_w then
    if y <= tool_h
    then
      return true
    end
  end
  return false
end

function inWeightRange(x, y)
  if x <= box_w then
    if y <= height - pal_h
        and y >= wb_y
    then
      return true
    end
  end
  return false
end

function drawBackground()
  G.setColor(Color[Color.black])
  G.rectangle("fill", 0, 0, width, height)
end

function drawColorPalette()
  local y = height - block_h

  G.setColor(Color[bg_color])
  G.rectangle("fill", 0, y - block_h, block_w * 2, block_h * 2)
  G.setColor(Color[Color.white])
  G.rectangle("line", 0, y - block_h, sel_w, pal_h)
  G.rectangle("line", sel_w, y - block_h, width, pal_h)
  -- display selection
  G.setColor(Color[color])
  G.rectangle("fill", block_w / 2, y - (block_h / 2),
    block_w, block_h)
  -- outline
  local line_color = Color.white + Color.bright
  if color == line_color then
    line_color = Color.black
  end
  G.setColor(Color[line_color])
  G.rectangle("line", block_w / 2, y - (block_h / 2),
    block_w, block_h)

  -- available colors
  for c = 0, 7 do
    local x = block_w * (c + 2)
    G.setColor(Color[c])
    G.rectangle("fill", x, y, width, block_h)
    G.setColor(Color[c + 8])
    G.rectangle("fill", x, y - block_h, width, block_h)
    G.setColor(Color[Color.white])
    G.rectangle("line", x, y, width, block_h)
    G.rectangle("line", x, y - block_h, width, block_h)
  end
end

function drawBrush(cx, cy)
  G.push()
  G.translate(cx, cy)
  local s = icon_d / 100 * .8
  G.scale(s, s)
  G.rotate(math.pi / 4) -- 45 degree rotation

  -- Draw the brush handle (wooden brown color)
  G.setColor(0.6, 0.4, 0.2)
  G.rectangle("fill", -8, -80, 16, 60)

  -- Handle highlight
  G.setColor(0.8, 0.6, 0.4)
  G.rectangle("fill", -6, -75, 3, 50)

  -- Metal ferrule
  G.setColor(0.7, 0.7, 0.8)
  G.rectangle("fill", -10, -25, 20, 12)

  -- Ferrule shine
  G.setColor(0.9, 0.9, 1.0)
  G.rectangle("fill", -8, -24, 3, 10)

  -- Bristles with smooth flame-shaped tip
  G.setColor(0.2, 0.2, 0.2)
  G.rectangle("fill", -12, -13, 24, 25)

  -- Create flame tip using bezier curve
  local curve = love.math.newBezierCurve(
    -12, 12, -- Start left
    -15, 20, -- Control point 1 (outward curve)
    -5, 30,  -- Control point 2 (inward curve)
    0, 35,   -- Tip point
    5, 30,   -- Control point 3 (inward curve)
    15, 20,  -- Control point 4 (outward curve)
    12, 12   -- End right
  )

  local points = curve:render()
  G.polygon("fill", points)

  G.pop()
end

function drawEraser(cx, cy)
  G.push()
  G.translate(cx, cy)
  local s = icon_d / 100
  G.scale(s, s)
  G.rotate(math.pi / 4) -- 45 degree rotation

  -- Main eraser body (light blue)
  G.setColor(Color[Color.white])
  G.rectangle("fill", -12, -40, 24, 60)

  -- Blue stripes running lengthwise (darker blue)
  G.setColor(Color[Color.blue])
  G.rectangle("fill", -12, -40, 6, 60)
  G.rectangle("fill", 6, -40, 6, 60)

  -- Worn eraser tip (slightly darker)
  G.setColor(Color[Color.white + Color.bright])
  G.rectangle("fill", -12, 15, 24, 8)

  -- Eraser crumbs
  G.setColor(Color[Color.white])
  G.circle("fill", 18, 25, 2)
  G.circle("fill", 22, 30, 1.5)
  G.circle("fill", 15, 32, 1)

  G.pop()
end

local tools = {
  drawBrush,
  drawEraser,
}
function drawTools()
  local tb = icon_d --(tool_h - m_4) / n_t
  local tb_half = tb / 2
  for i = 1, n_t do
    local x = mid_t - tb_half
    local y = (i - 1) * (m_2 + tb)
    if i == tool then
      G.setColor(Color[Color.black])
    else
      G.setColor(Color[Color.white + Color.bright])
    end
    G.rectangle("fill", x, y + m_2, tb, tb)

    G.setColor(Color[Color.black])
    G.rectangle("line", x, y + m_2, tb, tb)

    local draw = tools[i]
    draw(mid_t - m_2, y + tb_half + m_4)
  end
end

function drawWeightSelector()
  G.rectangle("line", 0, box_h - weight_h, box_w, weight_h)
  local h = (weight_h - (2 * margin)) / 8
  local w = marg_l
  for i = 0, 7 do
    local y = wb_y + margin + (i * h)
    local lw = i + 1
    local mid = y + (h / 2)
    G.setColor(Color[Color.white + Color.bright])
    G.rectangle("fill", margin, y, w, h)
    if lw == weight then
      -- G.setColor(Color[Color.white])
      -- G.rectangle("fill", margin, y, w, h)
      G.setColor(goose)
      local rx1 = 3 * margin
      local rx2 = 5 * margin
      local ry1 = mid - margin
      local ry2 = ry1 + m_2
      -- G.rectangle("fill", 3 * margin, y + margin, m_2, m_2)
      -- G.polygon("fill", rx1, ry1, rx1, ry2, rx2, ry2, rx2, ry1)
      local x1 = 5 * margin
      local x2 = 7 * margin
      local y1 = mid - m_2
      local y2 = mid + m_2
      G.polygon("fill",
        -- body
        rx2, ry1,
        rx1, ry1,
        rx1, ry2,
        rx2, ry2,
        -- head
        x1, y2,
        x2, mid,
        x1, y1
      )
      G.setColor(Color[Color.black])
      G.setLineWidth(2)
      G.polygon("line",
        -- body
        rx2, ry1,
        rx1, ry1,
        rx1, ry2,
        rx2, ry2,
        -- head
        x1, y2,
        x2, mid,
        x1, y1
      )
      G.setLineWidth(1)
    else
    end
    G.setColor(Color[Color.black])
    local aw = weights[lw]
    G.rectangle("fill", box_w / 3, mid - (aw / 2),
      box_w / 2, aw)
  end
end

function drawToolbox()
  --- outline
  G.setColor(Color[Color.white])
  G.rectangle("fill", 0, 0, box_w, height - pal_h)
  G.setColor(Color[Color.white + Color.bright])
  G.rectangle("line", 0, 0, box_w, box_h)
  drawTools()
  drawWeightSelector()
end

function getWeight()
  local aw
  if tool == 1 then
    aw = weights[weight]
  elseif tool == 2 then
    aw = weights[weight] * 1.5
  end
  return aw
end

function drawTarget()
  local x, y = love.mouse.getPosition()
  if inCanvasRange(x, y) then
    local aw = getWeight()
    G.setColor(Color[Color.white])
    G.circle("line", x, y, aw)
  end
end

function love.draw()
  drawBackground()
  drawToolbox()
  drawColorPalette()
  G.draw(canvas, box_w)
  drawTarget()
end

function setColor(x, y, btn)
  local row = (function()
    if (height - y) > block_h then return 1 end
    return 0
  end)()
  local col = math.modf((x - sel_w) / block_w)
  color = col + (8 * row)
end

function selectTool(_, y)
  local h = icon_d + m_4
  local sel = math.modf(y / h) + 1
  if sel <= n_t then
    tool = sel
  end
end

function setLineWeight(y)
  local h = weight_h / 8
  local lw = math.modf((y - wb_y) / h) + 1
  if lw > 0 and lw <= 8 then
    weight = lw
  end
end

function useCanvas(x, y, btn)
  canvas:renderTo(function()
    local aw = getWeight()
    if tool == 1 then
      G.setColor(Color[color])
    elseif tool == 2 then
      G.setColor(Color[bg_color])
    end
    G.circle("fill", x - box_w, y, aw)
  end)
end

function point(x, y)
    set_color(x, y)
  if inPaletteRange(x, y) then
  end
  if inCanvasRange(x, y) then
    useCanvas(x, y, btn)
  end
  if inToolRange(x, y) then
    selectTool(x, y)
  end
  if inWeightRange(x, y) then
    setLineWeight(y)
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then
    point(x, y)
  end
  if button == 2 then
  end
end

function love.mousemoved(x, y, dx, dy)
  if inCanvasRange(x, y)
  then
    for btn = 1, 2 do
      if
          love.mouse.isDown(btn)
      then
        useCanvas(x, y, btn)
      end
    end
  end
end

function love.touchpressed(_, x, y)
  point(x, y)
end

function love.touchmoved(_, x, y)
  use_canvas(x, y)
end

colorkeys = {
  ['1'] = 0,
  ['2'] = 1,
  ['3'] = 2,
  ['4'] = 3,
  ['5'] = 4,
  ['6'] = 5,
  ['7'] = 6,
  ['8'] = 7,
}
function love.keypressed(k)
  if k == 'tab' then
    if tool >= n_t then
      tool = 1
    else
      tool = tool + 1
    end
  end
  if k == '[' then
    if weight > 1 then
      weight = weight - 1
    end
  end
  if k == ']' then
    if weight < #weights then
      weight = weight + 1
    end
  end
  local c = colorkeys[k]
  if c then
    if Key.shift() then
      c = c + 8
    end
    color = c
  end
end
