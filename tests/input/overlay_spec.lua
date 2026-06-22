require("model.interpreter.eval.evaluator")
require("model.input.userInputModel")
require("controller.userInputController")

TU = require('tests.testutil')

describe('UserInputController overlay #input', function()
  local mock = require('tests.mock')
  local cfg  = TU.mock_view_cfg()
  -- REVIEW: I only understood that 'mv' means mock_view on maybe third re-read of the code. can we consider using semantically meaningful names, and aliasing them explicitly only if justified?
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

  -- REVIEW: absolutely not obvious what this function is for, why its needed, how it helps the test
  local make_ctrl = function()
    local m = UserInputModel(cfg, InputEvalText, true)
    local c = UserInputController(m, nil, true)
    c:init_view(mv)
    return c
  end

  -- REVIEW: no code is supposed to call love.state.user_input=nil directly? if so, what we are testing here? why not call explicitly the api function which nullifies it?
  -- REVIEW, unrelated: previous implementation destroyed user input on text submission (in some scenarios), do we test them? 
  before_each(function()
    love.state.user_input = nil
  end)

  describe('overlay shape', function()
    -- REVIEW: which code is supossed to call V.draw()? is not it a controllers duty to draw?
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

    it('real submit reprompt opens empty (C2T-1)', function()
      local c = make_ctrl()
      c:show()
      c:set_text('REMEMBER_ME')

      local push_called = false
      -- REVIEW: why redefine love.event table instead of just an element in it?
      love.event = {
        push = function(ev)
          if ev == 'userinput' then
            push_called = true
          end
        end
      }

      local ok, result = c.model:handle(true)
      assert.truthy(ok)
      -- REVIEW: poor flag name, I'd prefer it to be something like userinput_emitted -- explaining the purpose of the test not the mechanics of the mock
      assert.truthy(push_called)

      c:hide()
      c:show()
      assert.truthy(c:is_empty())
      assert.is_not.equal('REMEMBER_ME', c:get_text():render())
    end)
  end)
end)
