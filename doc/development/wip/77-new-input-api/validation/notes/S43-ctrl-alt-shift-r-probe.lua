local F = require('tests.helpers.input_fixture')
local mock = require('tests.mock')

describe('probe: ctrl+alt+shift+r', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)

  it('fires restart and reset both', function()
    F.reset()
    local calls = {}
    F.cc.restart = function() calls.restart = true end
    F.cc.reset   = function() calls.reset = true end
    Controller.setup_callback_handlers(F.cc)
    love.state.app_state = 'running'

    mock.hold('lctrl'); mock.hold('lalt'); mock.hold('lshift')
    love.handlers.keypressed('r', '', false)
    mock.release_keys()

    print('restart:', tostring(calls.restart), ' reset:', tostring(calls.reset))
    assert.is_true(calls.restart and calls.reset)
  end)
end)
