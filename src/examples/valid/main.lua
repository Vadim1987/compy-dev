r = user_input()

min_length = function(n)
  return function(s)
    if string.len(s) > n then
      return true
    end
    return false, 'too short!'
  end
end

max_length = function(n)
  return function(s)
    if string.len(s) < n then
      return true
    end
    return false, 'too long!'
  end
end

is_upper = function(s)
  local ret = true
  for i = 1, string.ulen(s) do
    local v = string.char_at(s, i)
    if v ~= string.upper(v) then
      ret = false
    end
  end
  if ret then
    return true
  end
  return false, 'should be all uppercase'
end

is_number = function(s)
  local n = tonumber(s)
  if n then return true end
  return false, 'NaN'
end

function love.update()
  if r:is_empty() then
    validated_input(
      { min_length(2), is_number },
      'Enter a number greater than 100:')
  else
    local input = r()
    print(input)
  end
end
