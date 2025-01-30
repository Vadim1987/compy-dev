require("util.color")
local class = require('util.class')
local c = require("conf.colors").input
local colors = c.syntax_i

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
      --- default value is an empty array
      table[key] = {}
      return table[key]
    end
  })
end

local tokenHL = {
  --- @return integer?
  colorize = function(t)
    local type = types[t]
    if type then
      return colors[t]
    end
  end,
}

return tokenHL
