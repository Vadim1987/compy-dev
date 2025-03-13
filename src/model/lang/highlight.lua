local class = require('util.class')

--- @class SyntaxColoring: Color[][]
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
