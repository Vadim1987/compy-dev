require("util.color")
require("model.lang.highlight")
local colors = require("conf.lua")

local types = {
  kw_multi   = true, -- 'Keyword'
  kw_single  = true, -- 'Keyword'
  number     = true, -- 'Number'
  string     = true, -- 'String'
  comment    = true,
  identifier = true, -- 'Id'
}


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
