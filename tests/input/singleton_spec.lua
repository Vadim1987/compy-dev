require("model.interpreter.eval.evaluator")
require("model.input.userInputModel")
require("controller.userInputController")

TU = require('tests.testutil')

describe('UserInputController singleton #input', function()
  local mock    = require('tests.mock')
  local cfg     = TU.mock_view_cfg()
  -- REVIEW: non-mnemonic name, would prefer full mnemonic + short explicit alias
  local mv      = { render = function() end }

  mock.mock_love({
    state = {
      app_state = 'running',
      user_input = nil,
      user_input_controller = nil,
    },
  })

  -- REVIEW: same as in another test -- worth generalizing? and why not real API/flow?
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
    -- REVIEW: it tests implementation internals, not behavior :( how can we be sure it shows?
    it('show sets user_input', function()
      local c = make_ctrl()
      c:show()
      assert.truthy(love.state.user_input)
    end)

    -- REVIEW: again, implementation internals, not behavior
    it('user_input.C is the controller', function()
      local c = make_ctrl()
      c:show()
      assert.equal(c, love.state.user_input.C)
    end)

    -- REVIEW: same problem -- why not test its really hidden? if love.state.user_input is fundamental contract which alters draw behaviour -- should it be documented and is it sane arch decision first ofall?
    it('hide clears user_input', function()
      local c = make_ctrl()
      c:show()
      c:hide()
      assert.is_nil(love.state.user_input)
    end)

    -- REVIEW: the only test of behaviour... and even then, why not via compy.input API? (real consumers are not supposed to interact with controller directly, or are they?) 
    it('show with text pre-fills content', function()
      local c = make_ctrl()
      c:show({ text = 'hello' })
      assert.same({ 'hello' }, c:get_text())
    end)
  end)

  -- REVIEW: silent discard is a seen, at least log should be demanded and checked
  describe('show while active — no-op', function()
    it('second show leaves text unchanged', function()
      local c = make_ctrl()
      c:show({ text = 'first' })
      c:show({ text = 'second' })
      assert.same({ 'first' }, c:get_text())
    end)

    -- REVIEW: again internals, not behaviour...
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
      -- REVIEW: worth checking also with c:show('another text') -- in same test case just another step+assertion
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

    -- REVIEW: non-realistic scenario, why someone would call with just 'force:true'? Should alter something else, e.g. prompt? or should test different scenarios?
    -- btw, will it be shown in show-hide-show sequence without a force flag?
    it('preserves text when text not in config', function()
      local c = make_ctrl()
      c:show({ text = 'keep' })
      c:show({ force = true })
      assert.same({ 'keep' }, c:get_text())
    end)

    -- REVIEW: internals, not behaviour...
    it('force leaves user_input active', function()
      local c = make_ctrl()
      c:show({ text = 'abc' })
      c:show({ force = true, text = 'new' })
      assert.truthy(love.state.user_input)
    end)
  end)

  -- REVIEW: this is maybe the only internals test worth keeping, as it validates NFR -- no object waste
  -- REVIEW: worth testing against 'force' flag too, as we know that with lack of 'force' everything *might* be simply ignored so the test would be trivial and not test any real mutability paths
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
