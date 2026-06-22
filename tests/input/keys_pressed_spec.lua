-- REVIEW: is this boilerplate loaded anywhere else? if so, why would not we reuse it? if not, why we need it here?

-- REVIEW: which interface is mimiced/mocked? reference neeeded
-- REVIEW/remark: gfx is normally a shortcut for love.graphics (or compy.graphics)
-- view.view calls gfx.newFont() at top level; needs gfx ctx
package.preload['view.view'] = function()
  View = {
    prev_draw = nil,
    main_draw = nil,
    snapshot = nil,
    clear_snapshot = function() end,
    draw = function() end,
    drawFPS = function() end,
  }
end

-- REVIEW: same question about boilerplate: used elsewhere? needed here? why?
-- REVIEW: comment mentions keyboard, but I do not see keyboard mocked 
-- handlers access love.state/keyboard/DEBUG/event at runtime
local mock = require('tests.mock')
mock.mock_love({
  state = {
    app_state = 'ready',
    user_input = nil,
    editor = nil,
  },
  DEBUG = false,
  PROFILE = false,
  -- REVIEW: we do not test quit here, just ensure the process does not crash?
  event = { quit = function() end },
})

-- REVIEW: what is setup_callback_handlers and how its related to our task? why not wire it into mock.mock_love above?
-- mock_love omits handlers; needed by setup_callback_handlers
love.handlers = { }

require('controller.controller')


-- REVIEW: is it reproducing some real workflow?
-- wires keypressed/keyreleased closures into love.handlers
Controller.setup_callback_handlers({
  cfg = { mode = 'dev' },
})

-- REVIEW: do we have a problem with test isolation here? does it need more fundamental resolution? do other tests perform the same setup?
-- save refs: other test files replace _G.love during collection
local kp_handler = love.handlers.keypressed
local kr_handler = love.handlers.keyreleased

describe('keys_pressed table #input', function()
  before_each(function()
    Controller.keys_pressed = { }
  end)

  it('adds key on keypressed', function()
    kp_handler('s')
    assert.truthy(Controller.keys_pressed['s'])
  end)

  -- REVIEW: why not test as a single flow? kp_handler / assert pressed / kp_released / assert not pressed
  -- REVIEW: I understand the idea of testing once concern per test. but one concern is not one assertion. also we test the *feature* not *implementation*? and feature is both key_pressed/key_released, they are not parts used independently 
  it('removes key on keyreleased', function()
    Controller.keys_pressed['s'] = true
    kr_handler('s')
    assert.is_nil(Controller.keys_pressed['s'])
  end)

  -- REVIEW: this is good but is worth assertion that no more keys are returning truthy if they are not pressed
  it('tracks multiple held keys', function()
    kp_handler('lctrl')
    kp_handler('s')
    assert.truthy(Controller.keys_pressed['lctrl'])
    assert.truthy(Controller.keys_pressed['s'])
  end)

  -- REVIEW: and where the fold happens? should not the last assertion be actually truthy, because either lctrl and rctrl semantically means ctrl is pressed? (there's no separate 'ctrl' key which is neither left not right -- so this scenario assumes the last assertion is always falsey and never changes, therefore makes no sense?
  it('does not fold lr variants in table', function()
    kp_handler('lctrl')
    kp_handler('rctrl')
    assert.truthy(Controller.keys_pressed['lctrl'])
    assert.truthy(Controller.keys_pressed['rctrl'])
    assert.is_nil(Controller.keys_pressed['ctrl'])
  end)
end)


-- REVIEW: as said during documentation review I think we should deserialize combo strings on hooks setup (into constructed-in-place hook dispatcher function)
-- REVIEW: I know the idea above may contradict no-if-arrows-rule but I wonder whether we can find better resolution because current implemetation means creating empty table on each keypressed just for serialization
describe('combo_string #input', function()
  local cs = Controller.combo_string

  it('bare key escape', function()
    assert.equal('escape', cs('escape', { }))
  end)

  it('bare key s', function()
    assert.equal('s', cs('s', { }))
  end)

  it('ctrl+s from lctrl held', function()
    local held = { lctrl = true }
    assert.equal('ctrl+s', cs('s', held))
  end)

  it('ctrl+s from rctrl held', function()
    local held = { rctrl = true }
    assert.equal('ctrl+s', cs('s', held))
  end)

  it('alt+shift+f4 ordering', function()
    local held = { lalt = true, lshift = true }
    assert.equal('alt+shift+f4', cs('f4', held))
  end)

  it('ctrl before alt precedence', function()
    local held = { lalt = true, lctrl = true }
    assert.equal('ctrl+alt+s', cs('s', held))
  end)

  it('all modifiers: ctrl alt shift gui', function()
    local held = {
      lgui = true, lshift = true,
      lalt = true, lctrl = true,
    }
    local expected = 'ctrl+alt+shift+gui+s'
    assert.equal(expected, cs('s', held))
  end)
end)
