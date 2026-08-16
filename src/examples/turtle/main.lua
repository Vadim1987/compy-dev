actions = require("action")
require("drawing")

width, height = gfx.getDimensions()
midx = width / 2
midy = height / 2
incr = 10

tx, ty = midx, midy
debug = false

function eval(input)
  local f = actions[input]
  if f then
    f()
  end
end

local font = gfx.newFont(compy.fonts.mono, 32)
local debug_font = gfx.newFont(compy.fonts.serif, 20)

function love.draw()
  gfx.setFont(font)
  drawBackground()
  drawHelp()
  drawTurtle(tx, ty)
  if debug then
    gfx.setFont(debug_font)
    drawDebuginfo()
  end
end

function love.keypressed(key)
  if Key.shift() then
    if key == "r" then
      tx, ty = midx, midy
    end
  end
  if key == "space" then
    debug = not debug
  end
  if key == "pause" then
    pause()
  end
end

-- The `i` that opens the prompt must not also be typed into
-- it (doc/input_api.md, "Opening the input widget from a key"):
-- LÖVE delivers a keypressed and a textinput for one physical
-- key in no guaranteed order. This one-shot eats that echo
-- whichever side of the open it lands on, then unregisters so
-- `i` is ordinary content afterwards.
local function arm_echo_guard()
  compy.input.shortcuts.textinput["i"] = function()
    compy.input.shortcuts.textinput["i"] = nil
    return true
  end
end
arm_echo_guard()

-- One-shot prompt (doc/input_api.md, "Submit lifecycle"): the overlay
-- stays open after submit by default, so a project that wants a
-- prompt-per-command closes it itself. The field comes up empty
-- next time because show() with no `text` clears it — hide()
-- only takes the overlay down — so no separate clear is
-- needed. Closing is also where the echo guard is re-armed: the
-- next open needs a fresh one-shot.
compy.input.callbacks.after_submit = function()
  compy.input.hide()
  arm_echo_guard()
end

-- This project keeps its keyboard on love.keypressed/keyreleased on
-- purpose: the framework captures a project's own love.* handlers and
-- runs them as hooks (doc/input_api.md, "Event hooks and shortcuts"),
-- and turtle is the example that demonstrates that path. Everything
-- here would work the same written as compy.input.hooks.*.
function love.keyreleased(key)
  -- Open only when it is closed, and consume `i` only then: the hook
  -- runs BEFORE the overlay, so without the guard every `i` typed into
  -- the prompt would re-trigger show (which warns and no-ops).
  if key == "i" and not compy.input.is_shown() then
    compy.input.show{
      prompt = "TURTLE",
      on_text_entered = function(lines)
        eval(lines[1])
      end,
    }
    return true
  end

end

function love.update()
  if ty > midy then
    debug_color = Color.red
  end
end
