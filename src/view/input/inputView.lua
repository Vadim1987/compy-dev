require("view.input.statusline")

local class = require("util.class")
require("util.debug")
require("util.view")


--- @param cfg ViewConfig
--- @param ctrl UserInputController
local function new(cfg, ctrl)
  return {
    cfg = cfg,
    controller = ctrl,
    statusline = Statusline(cfg),
    oneshot = ctrl.model.oneshot,
  }
end

--- @class InputView : ViewBase
--- @field controller UserInputController
--- @field statusline table
--- @field oneshot boolean
InputView = class.create(new)


--- @param input InputDTO
--- @param time number
function InputView:draw(input, time)
  ---@diagnostic disable-next-line: param-type-mismatch
  UserInputView.draw_input(self, input, time)
end
