require("model.interpreter.eval.evaluator")
require("model.input.userInputModel")
require("controller.userInputController")

TU = require('tests.testutil')

describe('UserInputController singleton #input', function()
  local mock    = require('tests.mock')
  local cfg     = TU.mock_view_cfg()
  local mock_view = { render = function() end }

  mock.mock_love({
    state = {
      app_state = 'running',
      user_input = nil,
      user_input_controller = nil,
    },
  })

  -- Per-test controller with model + mock view wired (mirrors main.lua startup wiring).
  -- (Generalising this helper across specs, and exercising via the compy.input API instead of the
  -- controller directly, are open A8 items — see M2-human-review.md.)
  local make_ctrl = function()
    local m = UserInputModel(cfg, InputEvalText, true)
    local c = UserInputController(m, nil, true)
    c:init_view(mock_view)
    return c
  end

  before_each(function()
    love.state.user_input = nil
  end)

  -- NOTE: these assert the singleton's love.state.user_input contract (internals). Behaviour-level
  -- coverage via the compy.input API / real flows is the A8 / M4-0 characterization-net work — see
  -- M2-human-review.md. Whether the flag-driven draw contract should be refactored is A5.
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
    -- warn-don't-swallow contract (C2): a suppressed show must not be silent.
    it('warns once when a non-force show is suppressed', function()
      local c = make_ctrl()
      c:show({ text = 'first' })
      local warned = 0
      local orig_warn = Log.warn
      Log.warn = function() warned = warned + 1 end
      c:show({ text = 'second' })
      Log.warn = orig_warn
      assert.equal(1, warned)
    end)

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

    -- warn-don't-swallow boundary (C2): force is the sanctioned override, so it must NOT warn.
    it('does not warn when force=true overrides', function()
      local c = make_ctrl()
      c:show({ text = 'abc' })
      local warned = 0
      local orig_warn = Log.warn
      Log.warn = function() warned = warned + 1 end
      c:show({ force = true, text = 'new' })
      Log.warn = orig_warn
      assert.equal(0, warned)
    end)

    -- force without text must preserve existing content (the text subset is the only field
    -- force re-applies on an active overlay). Broader force scenarios (e.g. live prompt change)
    -- belong to the compy.input.configure API in 0.1.0-m7.
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

  -- Validates the M2 NFR directly: the controller is reused, never reallocated across show/hide
  -- cycles (no object waste — the whole point of the singleton extraction).
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
