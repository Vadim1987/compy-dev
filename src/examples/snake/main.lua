--size for draw
unit = 10
--game area dimensions
cw = 102
ch = 60
love.window.setTitle("snake")

is_compy = true
drawgrid = false
status = "running"

if not is_compy then
  function love.load()
    -- start/restart game
    if G == nil then
      G = love.graphics
      love.window.setMode(1024, 600)
      midx, midy = G.getDimensions()
      is_compy = false
    end
    start()
  end
end

function running()
  love.draw = runningDraw
  -- love.update = runningUpdate
  love.keypressed = runningKeypressed
end

function gameover()
  love.draw = gameoverDraw
  -- love.update = gameoverUpdate
  love.keypressed = gameoverKeypressed
end

direction = {
  up = function()
    snake[1].y = snake[1].y - 1
  end,
  down = function()
    snake[1].y = snake[1].y + 1
  end,
  left = function()
    snake[1].x = snake[1].x - 1
  end,
  right = function()
    snake[1].x = snake[1].x + 1
  end
}

function runningDraw()
  if drawgrid then
    G.setColor(0.2, 0.2, 0.2)
    G.setLineWidth(.1)
    for x = 1, cw * unit, unit do
      G.line(x, 0, x, ch * unit)
    end
    for y = 1, ch * unit, unit do
      G.line(0, y, cw * unit, y)
    end
  end
  -- draw the snake rounded rectangle
  for i, snake_part in ipairs(snake) do
    if i == 1 then
      G.setColor(0, .4, 0, 1)
    else
      G.setColor(0, 0.8, 0)
    end
    G.rectangle("fill",
      snake_part.x * unit, snake_part.y * unit,
      unit, unit,
      5, 5);
  end

  --draw the apple rounded rectangle just like snake
  G.setColor(0.8, 0, 0)
  G.rectangle("fill",
    apple.x * unit,
    apple.y * unit,
    unit, unit, 5, 5)

  if status == "gameover" then
    G.setColor(1, 1, 1)
    G.setNewFont(20)
    gameovertext = "GAME OVER\nPress [SPACE] for a new game\nor\n[ESCAPE] for leave"
    G.printf(gameovertext, midx / 2 - 150, midy / 2, 300, "center")
  end
end

function gameoverDraw()
  runningDraw()
  --draw the game over screen
  -- G.setColor(1, 1, 1)
  --  G.setNewFont(20)
  -- G.printf("GAME OVER\nPress [SPACE] for a new game", 0, width*10/2,height*10/2, "center")
end

-- function runningUpdate(dt)
function love.update(dt)
  if status == "running" then
    --time limit for speed of snake
    timer = timer + dt
    if timer < speed then
      return
    end

    local last_head_position = { x = snake[1].x, y = snake[1].y }
    move()

    --check food
    if snake[1].x == apple.x and snake[1].y == apple.y then
      --add food and increase the snake
      apple = get_free_position()
      table.insert(snake, {})
    end

    --set snake snake parts
    --from snake end to second
    for snake_pos = #snake, 3, -1 do
      snake[snake_pos] = snake[snake_pos - 1]
    end

    if #snake > 1 then
      snake[2] = last_head_position
    end

    --check if game is over
    --because snake's head is out of the screen
    if snake[1].x < 0
        or snake[1].y < 0
        or snake[1].x > cw - 1
        or snake[1].y > ch - 1 then
      --game is over
      gameover()
      status = "gameover"
    end

    --because snake's head is in the snake
    for _, snake_part in pairs(snake) do
      if _ > 1 then
        if snake[1].x == snake_part.x
            and snake[1].y == snake_part.y
        then
          --game is over
          gameover()
          status = "gameover"
        end
      end
    end
    timer = 0
  end
end

-- function gameoverUpdate(dt)
-- end

left = function()
  if direction.right ~= move then
    move = direction.left
  end
end

right = function()
  if direction.left ~= move then
    move = direction.right
  end
end

up = function()
  if direction.down ~= move then
    move = direction.up
  end
end

down = function()
  if direction.up ~= move then
    move = direction.down
  end
end

heading = {
  up = up,
  left = left,
  down = down,
  right = right,
  w = up,
  a = left,
  s = down,
  d = right,

  space = function()
    start()
  end,
  escape = function()
    love.event.quit()
  end
}

function runningKeypressed(key)
  if key == 'g' then
    drawgrid = not drawgrid
  end
  if heading[key] then
    heading[key]()
  end
end

function gameoverKeypressed(key)
  if key == "space" then
    start()
  end
  if key == "escape" then
    love.event.quit()
  end
end

function start()
  math.randomseed(os.time())
  if (G ~= nil) then
    midx, midy = G.getDimensions()
  end
  running()
  status = "running"
  move = direction.right
  -- position for snake's head in center
  local start_x = cw / 2
  local start_y = ch / 2
  -- table for the snake
  snake = {
    {
      x = start_x,
      y = start_y
    },
    {
      x = start_x - 1,
      y = start_y
    },
    {
      x = start_x - 2,
      y = start_y
    },
  }
  --set speed and timer
  speed = 0.25
  timer = 0
  --table for the apple
  apple = get_free_position()
end

function get_free_position()
  --random number total game area minus the snake
  randompos = math.random(cw * ch - (#snake))
  local cnt = 0
  --iterate in game area
  gamearea = {}
  for i = 0, cw - 1 do
    for j = 0, ch - 1 do
      --the snake
      gamearea[j * cw + i] = true
    end
  end
  --when snake set to false
  for _, v in ipairs(snake) do
    gamearea[v.y * cw + v.x] = false
  end
  --iterate again and return
  for i = 0, cw - 1 do
    for j = 0, ch - 1 do
      if gamearea[j * cw + i] then
        cnt = cnt + 1
        if cnt == randompos then
          return { x = i, y = j }
        end
      end
    end
  end
end

if (is_compy) then
  start()
end
