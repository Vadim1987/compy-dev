local G = love.graphics

local x0 = 0
local xe = G.getWidth()
local y0 = 0
local ye = G.getHeight()

local xh = xe / 2
local yh = ye / 2

G.setColor(1, 1, 1, 0.5)
G.setLineWidth(1)
G.line(xh, y0, xh, ye)
G.line(x0, yh, xe, yh)

G.setColor(1, 0, 0)
G.setPointSize(2)

local amp = 100
local times = 2
local points = { }

for x = 0, xe do
  local v = 2 * math.pi * (x - xh) / xe
  local y = yh - math.sin(v * times) * amp
  table.insert(points, x)
  table.insert(points, y)
end

G.points(points)
