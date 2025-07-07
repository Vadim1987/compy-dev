require('util.lua')
local init = require('init')

local start = init.argparse()

if start.mode == 'harmony' then
  require("harmony.init")(true)
end

--- @diagnostic disable-next-line: duplicate-set-field
function love.conf(t)
  t.identity = 'compy'
  t.window.title = 'Compy'
  t.window.resizable = false
  local hidpi = os.getenv("HIDPI")
  if os.getenv("DEBUG") then
    love.DEBUG = true
  end
  if os.getenv("TRACE") then
    love.TRACE = true
  end

  --- disable unused modules to shorten startup
  t.modules.joystick = false
  t.modules.physics = false

  local width = 1024
  local height = 600
  if hidpi == 'true' or hidpi == 'TRUE' then
    t.window.width = width * 2
    t.window.height = height * 2
    love.hiDPI = true
  else
    t.window.width = width
    t.window.height = height
  end
  love.fixHeight = t.window.height
  love.fixWidth = t.window.width
  love.test_grid_x = 4
  love.test_grid_y = 4

  -- Android: use SD card for storage
  t.externalstorage = true

  local hostconf = prequire('host')
  if hostconf then
    hostconf.conf_love(t)
  end
  love.start = start
end
