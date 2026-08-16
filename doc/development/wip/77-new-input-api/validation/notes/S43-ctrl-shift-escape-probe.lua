-- Probe: does the platform's release-side Ctrl+Escape gate override a
-- project shortcut registered on 'ctrl+shift+escape' (maze da9d1c2)?
local F = require('tests.helpers.input_fixture')
local mock = require('tests.mock')

describe('probe: maze ctrl+shift+escape vs the platform gate', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)

  it('fires the project shortcut, then the gate stops the project', function()
    F.reset()
    local stops = { n = 0 }
    F.cc.stop_project_run = function() stops.n = stops.n + 1 end
    Controller.set_love_quit(F.cc)

    local input = F.compy_input()
    local fired = 0
    input.shortcuts.keypressed['ctrl+shift+escape'] = function()
      fired = fired + 1
      return true                     -- stop_here: consume it
    end
    F.activate_project({})
    love.state.app_state = 'running'

    -- the real loop: love.event.quit() enqueues a quit, and the loop
    -- calls love.quit() before exiting (truthy return aborts the exit)
    local quit_asked, quit_aborted = 0, nil
    love.event.quit = function()
      quit_asked = quit_asked + 1
      quit_aborted = love.quit()
    end

    -- ctrl+shift held, escape pressed and released while they stay held
    mock.hold('lctrl'); mock.hold('lshift')
    love.handlers.keypressed('escape', '', false)
    love.handlers.keyreleased('escape', '')
    mock.release_keys()

    print('project shortcut fired:', fired)
    print('platform asked to quit:', quit_asked)
    print('quit aborted (to console):', tostring(quit_aborted))
    print('stop_project_run calls :', stops.n)
    assert.are.equal(1, fired)
    assert.are.equal(0, stops.n)   -- expectation IF the gesture were honoured
  end)
end)
