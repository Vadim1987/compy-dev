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
--- @field get_first function

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

--- @param errors Error[]
--- @return Error?
function Error.get_first(errors)
  if type(errors) == "table" then
    local function get_ln(err)
      if type(err) == "table" then
        return err.l
      end
    end
    local function same_ln(err, ln)
      if type(err) == "table" then
        return err.l == ln
      end
    end
    local function get_c(err)
      if type(err) == "table" then
        return err.c
      end
    end
    local earliest_line = table.min_by(errors, get_ln)
    if earliest_line and earliest_line.l then
      local line_first = table.filter_array(errors, function(t)
        return same_ln(t, earliest_line.l)
      end)
      if #line_first > 0 then
        return table.min_by(line_first, get_c)
      end
    end
  end
end
