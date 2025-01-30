local class = require('util.class')

--- Input evaluation error class holding an error message and
--- optionally the location of the error in the input.

--- @class Error
--- @field msg string
--- @field c number?
--- @field l number
---
--- @field wrap fun(e: string|{msg: string}): Error?
--- @field __tostring function

--- @param msg string
--- @param c number?
--- @param l number?
local newe = function(msg, c, l)
  return { msg = msg, c = c or 1, l = l or 1 }
end

--- @type Error
Error = class.create(newe)

--- @param e string|{msg: string}
--- @return Error
function Error.wrap(e)
  if type(e) == "string" then
    return Error(e)
  end
  if type(e) == "table" and type(e.msg) == "string" then
    return e
  end
  return Error(tostring(e))
end

--- @return string
function Error:__tostring()
  local li = ''
  if self.l then
    li = li .. 'L' .. self.l .. ':'
    if self.c then
      li = li .. self.c .. ':'
    end
  end
  return li .. self.msg
end
