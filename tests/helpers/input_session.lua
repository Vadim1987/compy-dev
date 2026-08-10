---> REMARK: simplify comment, do not tell what it is noe
-- Keypress-level driver over the installed love.handlers.* gate.
-- Every emitter fires a REAL event through the production
-- gateway (love.handlers.*), never straight to a controller, so a
-- test exercises the same path a keystroke takes from LÖVE.
-- NOT an EditorSession generalisation (that helper bypasses the
-- love handlers and drives EditorController directly).

require('controller.controller')

---> REMARK: simplify comment. just tell it exposes API to invoke 'love' events via handlers. (providing a controllable imitation of love2d events emitting, which in production would be done in response to actions over physical hardware)
-- Expose one emitter per gateway entry. `handlers` is the live
-- love.handlers table, so combo drivers (tests.mock.keystroke)
-- can hold modifiers and call .keypressed directly.
local function emitters()
  local h = love.handlers
  return {
    press         = function(k) h.keypressed(k, '', false) end,
    repeat_press  = function(k) h.keypressed(k, '', true) end,
    release       = function(k) h.keyreleased(k, '') end,
    type          = function(t) h.textinput(t) end,
    mousepressed  = function(...) h.mousepressed(...) end,
    mousereleased = function(...) h.mousereleased(...) end,
    mousemoved    = function(...) h.mousemoved(...) end,
    wheelmoved    = function(...) h.wheelmoved(...) end,
    touchpressed  = function(...) h.touchpressed(...) end,
    handlers      = h,
  }
end

---> REMARK: simplify comment. just tell it invokes production function connectinng controller to love2d
-- Install the real gate into a fresh love.handlers and return the
-- emitters. Call AFTER mock.mock_love() + the view.view stub are
-- set up. @param CC ConsoleController  (read for cfg + shortcuts)
local function new(CC)
  love.handlers = { }
  -- Installs the production gateway (controller.lua
  -- setup_callback_handlers, the love.run wiring main.lua
  -- performs) onto a fresh love.handlers. The `or` default lets
  -- a bare driver stand up without a ConsoleController.
  Controller.setup_callback_handlers(
    CC or { cfg = { mode = 'dev' } }
  )
  return emitters()
end

return { new = new }
