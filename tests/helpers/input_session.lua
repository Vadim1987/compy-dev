-- Keypress-level driver over installed love.handlers.* slots.
-- Built on the keys_pressed_spec raw-handler pattern.
-- NOT an EditorSession generalisation — that helper bypasses
-- the love slots and drives EditorController directly.

require('controller.controller')

-- Install real handlers and return a driver exposing press /
-- release / type / repeat_press over the production slots.
-- Call AFTER mock.mock_love() + view.view stub are set up.
-- @param cfg table?  passed to setup_callback_handlers
local function new(cfg)
  love.handlers = {}
  Controller.setup_callback_handlers(
    cfg or { cfg = { mode = 'dev' } }
  )
  local kp = love.handlers.keypressed
  local kr = love.handlers.keyreleased
  local ti = love.handlers.textinput
  return {
    press        = function(k) kp(k, '', false) end,
    release      = function(k) kr(k)            end,
    type         = function(t) ti(t)            end,
    -- isrepeat=true: currently dropped at controller.lua:554
    -- (function(k) signature); M4 threads it.
    repeat_press = function(k) kp(k, '', true)  end,
  }
end

return { new = new }
