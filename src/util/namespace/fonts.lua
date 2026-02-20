local class = require('util.class')
local fonts = require("util.fonts")

---@alias FontEnum
---| 'mono'
---| 'retro'
---| 'serif'
---| 'sans'

--- @class CompyFonts
--- @field list function

CompyFonts = class.create(function()
  --- only cloning references, so it's cheap, but ensures that
  --- the user can't wreck it permanently
  local ret = table.clone(fonts.user)
  return ret
end)
