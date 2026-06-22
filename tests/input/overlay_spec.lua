require("model.interpreter.eval.evaluator")
require("model.input.userInputModel")
require("controller.userInputController")

TU = require('tests.testutil')

describe('UserInputController overlay #input', function()
  local mock = require('tests.mock')
  local cfg  = TU.mock_view_cfg()
  -- A mock view with both render (used by update_view) and draw (used by the overlay).
  local mock_view = {
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

  -- Build a ready-to-use controller with model + mock view wired, the way main.lua wires the real
  -- singleton at startup. Each test gets its own instance.
  local make_ctrl = function()
    local m = UserInputModel(cfg, InputEvalText, true)
    local c = UserInputController(m, nil, true)
    c:init_view(mock_view)
    return c
  end

  -- Precondition reset: each test starts with the overlay inactive. Done directly (not via hide())
  -- because it runs before any controller instance exists.
  -- (Coverage of the legacy "submission destroys user input" scenarios is an open A8 item — the
  -- C2T-1 test below covers the reprompt-empty case; see M2-human-review.md.)
  before_each(function()
    love.state.user_input = nil
  end)

  describe('overlay shape', function()
    -- The framework draw loop (controller.lua) calls V:draw() each frame while the overlay flag is
    -- set; this test just asserts the published handle is drawable (A5 contract).
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

      local userinput_emitted = false
      -- override only push (love.event may be unset under mock_love, so ensure the table first)
      love.event = love.event or {}
      love.event.push = function(ev)
        if ev == 'userinput' then
          userinput_emitted = true
        end
      end

      local ok, result = c.model:handle(true)
      assert.truthy(ok)
      assert.truthy(userinput_emitted)

      c:hide()
      c:show()
      assert.truthy(c:is_empty())
      assert.is_not.equal('REMEMBER_ME', c:get_text():render())
    end)
  end)
end)
