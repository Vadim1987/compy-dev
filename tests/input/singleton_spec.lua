require("model.interpreter.eval.evaluator")
require("model.input.userInputModel")
require("controller.userInputController")

TU = require('tests.testutil')

describe('UserInputController singleton #input', function()
  local mock    = require('tests.mock')
  local cfg     = TU.mock_view_cfg()
  local mv      = { render = function() end }

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

  describe('show / hide', function()
    it('show sets user_input', function()
      local c = make_ctrl()
      c:show()
      assert.truthy(love.state.user_input)
    end)

    it('user_input.C is the controller', function()
      local c = make_ctrl()
      c:show()
      assert.equal(c, love.state.user_input.C)
    end)

    it('hide clears user_input', function()
      local c = make_ctrl()
      c:show()
      c:hide()
      assert.is_nil(love.state.user_input)
    end)

    it('show with text pre-fills content', function()
      local c = make_ctrl()
      c:show({ text = 'hello' })
      assert.same({ 'hello' }, c:get_text())
    end)
  end)

  describe('show while active — no-op', function()
    it('second show leaves text unchanged', function()
      local c = make_ctrl()
      c:show({ text = 'first' })
      c:show({ text = 'second' })
      assert.same({ 'first' }, c:get_text())
    end)

    it('second show leaves user_input unchanged', function()
      local c = make_ctrl()
      c:show()
      local before = love.state.user_input
      c:show()
      assert.equal(before, love.state.user_input)
    end)

    it('no-op does not reset content', function()
      local c = make_ctrl()
      c:show({ text = 'abc' })
      c:show()
      assert.same({ 'abc' }, c:get_text())
    end)
  end)

  describe('show { force = true }', function()
    it('replaces text when text provided', function()
      local c = make_ctrl()
      c:show({ text = 'original' })
      c:show({ force = true, text = 'replaced' })
      assert.same({ 'replaced' }, c:get_text())
    end)

    it('preserves text when text not in config', function()
      local c = make_ctrl()
      c:show({ text = 'keep' })
      c:show({ force = true })
      assert.same({ 'keep' }, c:get_text())
    end)

    it('force leaves user_input active', function()
      local c = make_ctrl()
      c:show({ text = 'abc' })
      c:show({ force = true, text = 'new' })
      assert.truthy(love.state.user_input)
    end)
  end)

  describe('singleton identity', function()
    it('same instance across show/hide cycles', function()
      local c = make_ctrl()
      c:show()
      local ref1 = love.state.user_input.C
      c:hide()
      c:show()
      local ref2 = love.state.user_input.C
      assert.equal(ref1, ref2)
    end)
  end)
end)
