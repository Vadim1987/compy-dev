local G = love.graphics

font = G.newFont()
bg_color = Color.black
debugColor = Color.yellow

function drawBackground(color)
  local c = bg_color
  local not_green = color ~= Color.green
      and color ~= Color.green + Color.bright
  local color_valid = Color.valid(color) and not_green
  if color_valid then
    c = color
  end
  G.setColor(Color[c])
  G.rectangle("fill", 0, 0, width, height)
end

function drawFrontLegs(x_r, y_r, leg_xr, leg_yr)
  G.setColor(Color[Color.green + Color.bright])
  G.push("all")
  G.translate(-x_r, -y_r / 2 - leg_xr)
  G.rotate(-math.pi / 4)
  G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
  G.pop()
  G.push("all")
  G.translate(x_r, -y_r / 2 - leg_xr)
  G.rotate(math.pi / 4)
  G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
  G.pop()
end

function drawHindLegs(x_r, y_r, leg_r, leg_yr)
  G.setColor(Color[Color.green + Color.bright])
  G.push("all")
  G.translate(-x_r, y_r / 2 + leg_r)
  G.rotate(math.pi / 4)
  G.ellipse("fill", 0, 0, leg_r, leg_yr, 100)
  G.pop()
  G.push("all")
  G.translate(x_r, y_r / 2 + leg_r)
  G.rotate(-math.pi / 4)
  G.ellipse("fill", 0, 0, leg_r, leg_yr, 100)
  G.pop()
end

function drawBody(x_r, y_r, head_r)
  --- body
  G.setColor(Color[Color.green])
  G.ellipse("fill", 0, 0, x_r, y_r, 100)
  --- head
  local neck = 5
  G.circle("fill", 0, ((0 - y_r) - head_r) + neck, head_r, 100)
  --- end
end

function drawTurtle(x, y)
  local head_r = 8
  local leg_xr = 5
  local leg_yr = 10
  local x_r = 15
  local y_r = 20
  G.push("all")
  G.translate(x, y)
  drawFrontLegs(x_r, y_r, leg_xr, leg_yr)
  drawHindLegs(x_r, y_r, leg_xr, leg_yr)
  drawBody(x_r, y_r, head_r)
  G.pop()
end

function drawHelp()
  G.setColor(Color[Color.white])
  G.print("Press [I] to open console", 20, 20)
  local help = "Enter 'forward', 'back', 'left', or 'right'" ..
      "to move the turtle!"
  G.print(help, 20, 50)
end

function drawDebuginfo()
  G.setColor(Color[debugColor])
  local dt = string.format("Turtle position: (%d, %d)", tx, ty)
  G.print(dt, width - 200, 20)
end
