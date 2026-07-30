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
  if love.keyboard.isDown("lshift", "rshift") then
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

function love.keyreleased(key)
  if key == "i" then
    compy.input.show{
      prompt = "TURTLE",
      on_text_entered = function(lines)
        eval(lines[1])
      end,
    }
  end

  if love.keyboard.isDown("lctrl", "rctrl") then
    if key == "escape" then
      love.event.quit()
    end
  end
end

function love.update()
  if ty > midy then
    debug_color = Color.red
  end
end
