require("view.titleView")
require("view.editor.editorView")
require("view.canvas.canvasView")
require("view.input.interpreterView")

local class = require("util.class")
require("util.color")
require("util.view")
require("util.debug")

local G = love.graphics

--- @param cfg Config
--- @param ctrl ConsoleController
local function new(cfg, ctrl)
  return {
    title = TitleView,
    canvas = CanvasView(cfg),
    interpreter = InterpreterView(cfg.view, ctrl.interpreter),
    editor = EditorView(cfg.view, ctrl.editor),
    controller = ctrl,
    cfg = cfg,
    drawable_height = ViewUtils.get_drawable_height(cfg.view),
  }
end

--- @class ConsoleView
--- @field title table
--- @field canvas CanvasView
--- @field interpreter InterpreterView
--- @field editor EditorView
--- @field controller ConsoleController
--- @field cfg Config
--- @field drawable_height number
ConsoleView = class.create(new)

--- @param terminal table
--- @param canvas love.Canvas
--- @param input InputDTO
--- @param snapshot love.Image?
function ConsoleView:draw(terminal, canvas, input, snapshot)
  if love.DEBUG then
    self:draw_placeholder()
  end

  local function drawConsole()
    local tc = self.controller.model.output.term_canvas
    self.canvas:draw(
      terminal, canvas, tc,
      self.drawable_height, snapshot)

    if ViewUtils.conditional_draw('show_input') then
      local time = self.controller:get_timestamp()
      self.interpreter:draw(input, time)
    end
  end

  local function drawEditor()
    self.editor:draw()
  end

  if love.state.app_state == 'editor' then
    drawEditor()
  else
    drawConsole()
  end
end

function ConsoleView:draw_placeholder()
  local band = self.cfg.view.fh
  local w    = self.cfg.view.w
  local h    = self.cfg.view.h
  G.push('all')
  G.setColor(Color[Color.yellow])
  for o = -h, w, 2 * band do
    G.polygon("fill"
    , o + 0, h
    , o + h, 0
    , o + h + band, 0
    , o + band, h
    )
  end
  G.pop()
end
