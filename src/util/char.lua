----------------------------
--- validation utilities ---
----------------------------

--- 'c' is assumed to be a single character/grapheme, these
--- functions won't be checking for it.

local is_alpha = function(c)
  return string.match(c, "%a") ~= nil
end
local is_alnum = function(c)
  return string.match(c, "%w") ~= nil
end
local is_upper = function(c)
  return string.match(c, "%u") ~= nil
end
local is_lower = function(c)
  return string.match(c, "%l") ~= nil
end
local is_digit = function(c)
  return string.match(c, "%d") ~= nil
end
local is_space = function(c)
  return string.match(c, "%s") ~= nil
end
local is_punct = function(c)
  return string.match(c, "%p") ~= nil
end
local is_ascii = function(c)
  local byte = string.byte(c, 1)
  return byte < 128
end

return {
  is_alpha = is_alpha,
  is_alnum = is_alnum,
  is_lower = is_lower,
  is_upper = is_upper,
  is_digit = is_digit,
  is_space = is_space,
  is_punct = is_punct,
  is_ascii = is_ascii,
}
