function min_length(n)
  return function(s)
    local l = string.ulen(s)
    if n < l then
      return true
    end
    return false, Error("too short!", l)
  end
end

function max_length(n)
  return function(s)
    if string.len(s) <= n then
      return true
    end
    return false, Error("too long!", n + 1)
  end
end

function is_upper(s)
  local ret = true
  local l = string.ulen(s)
  local err_c
  local i = 1
  while ret and i <= l do
    local v = string.usub(s, i, i)
    if v ~= string.upper(v) then
      ret = false
      err_c = i
    end
    i = i + 1
  end

  if ret then
    return true
  end
  return false, Error("should be all uppercase", err_c)
end

function is_lower(s)
  local ok, err_c = string.forall(s, Char.is_lower)
  if ok then
    return true
  end
  return false, Error("should be lowercase", err_c)
end

function is_number(s)
  local sign = string.usub(s, 1, 1)
  local offset = 0
  if sign == '-' then
    offset = 1
  end
  local digits = string.usub(s, 1 + offset)
  local ok, err_c = string.forall(digits, Char.is_digit)
  if ok then
    return true
  end
  return false, Error("NaN", err_c + offset)
end

function is_natural(s)
  local is_num, err = is_number(s)
  if not is_num then
    return false, err
  end
  local n = tonumber(s)
  if n < 0 then
    return false, Error("It's negative!", 1)
  end
end

-- Continuous-session idiom ({badspecref: M8-01} —
-- implementation/outcomes/M8-01.md, example migrations):
-- consume the line in
-- on_text_entered, re-show (bare) from after_submit. eval
-- reuses the legacy validated_input->ValidatedTextEval path
-- (least new logic).
compy.input.after_submit = function()
  compy.input.show{}
end

compy.input.show{
  eval = ValidatedTextEval({
    min_length(2),
    is_lower
  }),
  on_text_entered = function(t) print(t) end,
}
