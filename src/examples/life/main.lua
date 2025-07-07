--- original from https://github.com/Aethelios/Conway-s-Game-of-Life-in-Lua-and-Love2D

local cellSize = 10
local screenWidth, screenHeight = G.getDimensions()
local gridWidth = screenWidth / cellSize
local gridHeight = screenHeight / cellSize
local grid = {}

local speed = 10
local time = 0
local tick = function(dt)
  time = time + dt
  if time > (1 / speed) then
    time = 0
    return true
  end
end

local function initializeGrid()
  for x = 1, gridWidth do
    grid[x] = {}
    for y = 1, gridHeight do
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
            and nx <= gridWidth
            and ny >= 1
            and ny <= gridHeight
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
  for x = 1, gridWidth do
    newGrid[x] = {}
    for y = 1, gridHeight do
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

function love.update(dt)
  if tick(dt) then
    updateGrid()
  end
end

function love.keypressed(k)
  if k == 'r' then
    init()
  end
  if k == '-' then
    if speed > 1 then
      speed = speed - 1
    end
  end
  if k == '+' or k == '=' then
    if speed < 100 then
      speed = speed + 1
    end
  end
end

function love.draw()
  for x = 1, gridWidth do
    for y = 1, gridHeight do
      if grid[x][y] == 1 then
        G.setColor(.9, .9, .9)
        G.rectangle('fill',
          (x - 1) * cellSize,
          (y - 1) * cellSize,
          cellSize, cellSize)
        G.setColor(.3, .3, .3)

        G.rectangle('line',
          (x - 1) * cellSize,
          (y - 1) * cellSize,
          cellSize, cellSize)
      end
    end
  end

  G.setColor(1, 1, 1, .5)
  G.print("Press 'r' to reset, +/- to adjust speed",
    10, screenHeight - 30)
  local speedLabel = "Speed: " .. speed
  G.print(speedLabel, screenWidth - font:getWidth(speedLabel),
    screenHeight - 30)
end

G.setFont(font)
initializeGrid()
