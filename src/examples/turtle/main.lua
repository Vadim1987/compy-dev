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

-- Hooks run above the widget on purpose (doc/input_api.md,
-- "Why the widget sits at tier 3"), so a project that must not
-- act on keys being typed into the prompt says so itself. The
-- guard is blanket, so `pause` goes quiet with `space` and
-- `shift+r`: the framework reserves `ctrl+pause` for the same
-- suspend, and a reservation no guard can reach.
function love.keypressed(key)
  if compy.input.is_shown() then return end
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
-- it (doc/input_api.md, "Worked example: the trigger key
-- echoes into the widget it opened"):
-- LÖVE delivers a keypressed and a textinput for one physical
-- key in no guaranteed order. This one-time guard eats that
-- echo whichever side of the open it lands on, then unregisters
-- so `i` is ordinary content afterwards.
local function arm_echo_guard()
  compy.input.shortcuts.textinput["i"] = function()
    compy.input.shortcuts.textinput["i"] = nil
    return true
  end
end
arm_echo_guard()

-- A prompt per command: the widget stays open after submit by
-- default, so this project asks for the other behaviour with
-- `auto_hide` on the show below (doc/input_api.md, "Asking one
-- question"). It is a mode rather than a one-off — every submit
-- closes the widget until something passes `auto_hide = false`,
-- which is exactly what turtle wants and why it is set once at
-- the show instead of re-armed here. The field comes up empty
-- next time because show() with no `text` clears it, so no
-- separate clear is needed either.
--
-- What is left for after_submit is the echo guard, which runs
-- before the close: the next open needs a fresh one.
compy.input.callbacks.after_submit = arm_echo_guard

-- This project keeps its keyboard on love.keypressed/keyreleased on
-- purpose: the framework captures a project's own love.* handlers and
-- runs them as hooks (doc/input_api.md, "Event hooks and shortcuts"),
-- and turtle is the example that demonstrates that path. Everything
-- here would work the same written as compy.input.hooks.*.
function love.keyreleased(key)
  -- Open only when it is closed, and consume `i` only then: the hook
  -- runs BEFORE the widget, so without the guard every `i` typed into
  -- the prompt would re-trigger show (which warns and no-ops).
  if key == "i" and not compy.input.is_shown() then
    compy.input.show{
      prompt = "TURTLE",
      auto_hide = true,
      on_text_entered = function(text)
        eval(text)
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
