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
  event = { quit = function() end },
})
-- mock_love omits handlers; needed by setup_callback_handlers
love.handlers = { }

require('controller.controller')

-- wires keypressed/keyreleased closures into love.handlers
Controller.setup_callback_handlers({
  cfg = { mode = 'dev' },
})

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

  it('removes key on keyreleased', function()
    Controller.keys_pressed['s'] = true
    kr_handler('s')
    assert.is_nil(Controller.keys_pressed['s'])
  end)

  it('tracks multiple held keys', function()
    kp_handler('lctrl')
    kp_handler('s')
    assert.truthy(Controller.keys_pressed['lctrl'])
    assert.truthy(Controller.keys_pressed['s'])
  end)

  it('does not fold lr variants in table', function()
    kp_handler('lctrl')
    kp_handler('rctrl')
    assert.truthy(Controller.keys_pressed['lctrl'])
    assert.truthy(Controller.keys_pressed['rctrl'])
    assert.is_nil(Controller.keys_pressed['ctrl'])
  end)
end)

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
