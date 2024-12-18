r = user_input()

function min_length(n)
  return function(s)
    if n < string.len(s) then
      return true
    end
    return false, "too short!"
  end
end

function max_length(n)
  return function(s)
    if string.len(s) < n then
      return true
    end
    return false, "too long!"
  end
end

function is_upper(s)
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
  return false, "should be all uppercase"
end

function is_number(s)
  local n = tonumber(s)
  if n then
    return true
  end
  return false, "NaN"
end

function is_natural(s)
  local is_num, err = is_number(s)
  if not is_num then
    return false, err
  end
  local n = tonumber(s)
  if n < 0 then
    return false, "It's negative!"
  end
end

function love.update()
  if not r:is_empty() then
    validated_input({
      min_length(2),
      is_natural
    })
  else
    print(r())
  end
end
