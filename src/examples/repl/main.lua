r = user_input()

function love.update()
  if r:is_empty() then
    input_text()
  else
    local input = r()
    print(input)
  end
end
