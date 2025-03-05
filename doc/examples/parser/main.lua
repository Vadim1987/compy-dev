--- @diagnostic disable: duplicate-set-field,lowercase-global
local function asd()
  return 1
end

function love.update(dt)
  t = t + dt
  if ty > midy then
    debugColor = Color.red
  end
end
