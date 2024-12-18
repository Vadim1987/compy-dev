math.randomseed(os.time())
r = user_input()
N = 100
-- number_to_guess
ntg = 0

function init()
  print("Welcome to the guessing game!")
  ntg = math.random(N)
end

function is_natural(s)
  local n = tonumber(s)
  if not n then
    return false, "NaN"
  end
  if n <= 0 then
    return false, "Not a positive number!"
  end
  if math.floor(n) ~= n then
    return false, "Not an integer!"
  end
  return true
end

function check(n)
  if not n then
    return
  end
  if ntg < n then
    print("The number is lower")
  elseif n < ntg then
    print("The number is higher")
  else
    print("Correct!")
    print("\n\n")
    init()
  end
end

function love.update()
  if r:is_empty() then
    validated_input({ is_natural }, "Guess a number:")
  else
    local n = tonumber(r())
    check(n)
  end
end

init()
