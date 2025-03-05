r = user_input()

function love.update()
  if r:is_empty() then
    input_text()
  else
    print(r())
  end
end
