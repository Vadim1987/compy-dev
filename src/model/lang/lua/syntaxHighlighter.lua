require("util.color")
local class = require('util.class')
local colors = require("conf.lua")

local types = {
  kw_multi   = true, -- 'Keyword'
  kw_single  = true, -- 'Keyword'
  number     = true, -- 'Number'
  string     = true, -- 'String'
  comment    = true,
  identifier = true, -- 'Id'
}

-- @alias SyntaxColoring LexType[][]
--- @class SyntaxColoring
SyntaxColoring = class.create()
SyntaxColoring.new = function()
  return setmetatable({}, {
    __index = function(table, key)
      if not key then return end
      --- default value is an empty array
      table[key] = {}
      return table[key]
    end
  })
end

local tokenHL = {
  --- @param t string tag
  --- @return integer?
  colorize = function(t)
    local type = types[t]
    if type then
      return colors[t]
    end
  end,
}

return tokenHL
