local class = require('util.class')

--- @class Cursor
--- @field l number
--- @field c number
Cursor = class.create(function(l, c)
  local ll = l or 1
  local cc = c or 1
  return { l = ll, c = cc }
end)

function Cursor:__tostring()
  return string.format('{l%d, %d}', self.l, self.c)
end

function Cursor.inline(c)
  return Cursor(1, c)
end

--- @param this {c: integer, l: integer}
--- @param that {c: integer, l: integer}
--- @return integer?
function Cursor.ordering(this, that)
  if type(this) == 'table' and this.c and this.l
      and type(that) == 'table' and that.l and that.c then
    if this.l > that.l then
      return -1
    elseif this.l < that.l then
      return 1
    else
      if this.c > that.c then
        return -1
      elseif this.c < that.c then
        return 1
      else
        return 0
      end
    end
  end
end

function Cursor:compare(other)
  return Cursor.ordering(self, other)
end

function Cursor:is_before(other)
  if other and other.l and other.c then
    return 0 < self:compare(other)
  else
    return false
  end
end

function Cursor:is_after(other)
  if other and other.l and other.c then
    return 0 > self:compare(other)
  else
    return false
  end
end
