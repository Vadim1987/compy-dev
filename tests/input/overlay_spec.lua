require("model.interpreter.eval.evaluator")
require("model.input.userInputModel")
require("controller.userInputController")

TU = require('tests.testutil')

describe('UserInputController overlay #input', function()
  local mock = require('tests.mock')
  local cfg  = TU.mock_view_cfg()
  -- view with both render (update_view) and draw (overlay)
  local mv = {
    render = function() end,
    draw   = function() end,
  }

  mock.mock_love({
    state = {
      app_state = 'running',
      user_input = nil,
      user_input_controller = nil,
    },
  })

  local make_ctrl = function()
    local m = UserInputModel(cfg, InputEvalText, true)
    local c = UserInputController(m, nil, true)
    c:init_view(mv)
    return c
  end

  before_each(function()
    love.state.user_input = nil
  end)

  describe('overlay shape', function()
    it('user_input.V is drawable after show', function()
      local c = make_ctrl()
      c:show()
      local ui = love.state.user_input
      assert.truthy(ui.V)
      ui.V:draw()
    end)
  end)

  describe('empty on reprompt', function()
    it('fresh show with no text opens empty', function()
      local c = make_ctrl()
      c:show({ text = 'hello' })
      c:hide()
      c:show()
      assert.truthy(c:is_empty())
    end)
  end)
end)
