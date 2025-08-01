--- original from https://github.com/Aethelios/Conway-s-Game-of-Life-in-Lua-and-Love2D

local cell_size = 10
local screen_w, screen_h = G.getDimensions()
local grid_w = screen_w / cell_size
local grid_h = screen_h / cell_size
local grid = {}

g_dir = nil
mouse_held = false
hold_time = 0
local speed = 10
local time = 0
local tick = function()
  if time > (1 / speed) then
    time = 0
    return true
  end
end

local function initializeGrid()
  for x = 1, grid_w do
    grid[x] = {}
    for y = 1, grid_h do
      -- Initialize with some random live cells
      grid[x][y] = math.random() > 0.7 and 1 or 0
    end
  end
end

local function init()
  time = 0
  initializeGrid()
end

local function countAliveNeighbors(x, y)
  local count = 0
  for dx = -1, 1 do
    for dy = -1, 1 do
      if dx ~= 0 or dy ~= 0 then
        local nx, ny = x + dx, y + dy
        if nx >= 1
            and nx <= grid_w
            and ny >= 1
            and ny <= grid_h
        then
          local row = grid[nx] or {}
          count = count + (row[ny] or 0)
        end
      end
    end
  end
  return count
end

local function updateGrid()
  local newGrid = {}
  for x = 1, grid_w do
    newGrid[x] = {}
    for y = 1, grid_h do
      local aliveNeighbors = countAliveNeighbors(x, y)
      if grid[x][y] == 1
      then
        newGrid[x][y] = (aliveNeighbors == 2
          or aliveNeighbors == 3) and 1 or 0
      else
        newGrid[x][y] = (aliveNeighbors == 3) and 1 or 0
      end
    end
  end
  grid = newGrid
end

function changeSpeed(d)
  if not d then return end
  if d > 0 and speed >= 100 then
    return
  end
  if d < 0 and speed < 1 then
    return
  end
  speed = speed + d
end

function love.update(dt)
  time = time + dt
  if love.mouse.isDown(1) then
    hold_time = hold_time + dt
  end
  if tick() then
    updateGrid()
  end
end

function love.keypressed(k)
  if k == 'r' then
    init()
  end
  if k == '-' then
    changeSpeed(-1)
  end
  if k == '+' or k == '=' then
    changeSpeed(1)
  end
end

function love.mousemoved(_, _, _, dy)
  if love.mouse.isDown(1) then
    if dy < 0 then
      g_dir = 1
    elseif dy > 0 then
      g_dir = -1
    end
  end
end

function love.mousepressed(_, _, button)
  if button == 1 then
    mouse_held = true
  end
end

function love.mousereleased(_, _, button)
  if button == 1 then
    mouse_held = false
    if hold_time > 1 then
      init()
    elseif g_dir then
      changeSpeed(g_dir)
    end
    hold_time = 0
  end
end

function drawHelp()
  G.setColor(1, 1, 1, .5)
  local margin = 5
  local bottom = screen_h - margin
  local right_edge = screen_w - margin
  local h = font:getHeight()
  local reset_msg = "Reset: [r] key or long press"
  local speed_msg = "Set speed: [+]/[-] key or drag up/down"
  G.print(reset_msg, margin, bottom - h - h)
  G.print(speed_msg, margin, bottom - h)
  local speed_label = "Speed: " .. speed
  local label_w = font:getWidth(speed_label)
  G.print(speed_label, right_edge - label_w, bottom - h)
end

function love.draw()
  for x = 1, grid_w do
    for y = 1, grid_h do
      if grid[x][y] == 1 then
        G.setColor(.9, .9, .9)
        G.rectangle('fill',
          (x - 1) * cell_size,
          (y - 1) * cell_size,
          cell_size, cell_size)
        G.setColor(.3, .3, .3)

        G.rectangle('line',
          (x - 1) * cell_size,
          (y - 1) * cell_size,
          cell_size, cell_size)
      end
    end
  end

  drawHelp()
end

G.setFont(font)
initializeGrid()
