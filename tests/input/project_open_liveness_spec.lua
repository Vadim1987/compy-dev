-- An input-only / pointer-only
-- project is "live" without hooking love.update/draw.
-- In project_open such a project keeps the project route
-- (so submit works) and Ctrl+Esc returns to the console
-- (not quit the app), while a truly idle console
-- (project_open, nothing interactive) still quits on
-- Ctrl+Esc.
--
-- See doc/development/technical_debt/input.md, the
-- "Input-only / pointer-only projects stay live in
-- `project_open` (RESOLVED, ruling a)" entry.

local F = require('tests.helpers.input_fixture')

describe('project_open liveness #input', function()
  local saved_stop = F.cc.stop_project_run

  local function stub_stop()
    local calls = { n = 0 }
    F.cc.stop_project_run = function() calls.n = calls.n + 1 end
    return calls
  end

  before_each(function()
    love.state.user_input = nil
    love.state.app_state = 'ready'
    Controller.set_love_quit(F.cc)
  end)

  after_each(function()
    F.cc.stop_project_run = saved_stop
  end)

  -- Ctrl+Esc runs love.event.quit -> the love.quit callback;
  -- returning true aborts the OS quit (drop to console), a
  -- falsy return lets the process exit.
  it('Ctrl+Esc stops a live overlay project (project_open) instead of quitting', function()
    local calls = stub_stop()
    love.state.app_state = 'project_open'
    love.state.user_input = {} -- an overlay is up => interactive
    local aborted = love.quit()
    assert.are.equal(1, calls.n)
    assert.is_true(aborted)
  end)

  it('Ctrl+Esc quits the app from an idle console (project_open, nothing interactive)', function()
    local calls = stub_stop()
    love.state.app_state = 'project_open'
    love.state.user_input = nil
    local aborted = love.quit()
    assert.are.equal(0, calls.n)
    assert.is_not_true(aborted)
  end)

  it('user_is_interactive tracks an active overlay', function()
    love.state.user_input = nil
    assert.is_falsy(Controller.user_is_interactive())
    love.state.user_input = {}
    assert.is_truthy(Controller.user_is_interactive())
  end)

  -- Behavioural guard: with the project route retained (what the
  -- run_project fix now does for an interactive non-blocking
  -- project) submit fires in project_open exactly as in running.
  it('an active overlay submits on Enter while in project_open', function()
    local seen
    local input = F.activate_project()
    input.show({
      text = 'x',
      on_text_entered = function(t) seen = t end,
    })
    love.state.app_state = 'project_open' -- route NOT released
    F.session.press('return')
    assert.are.equal('x', seen)
  end)
end)
