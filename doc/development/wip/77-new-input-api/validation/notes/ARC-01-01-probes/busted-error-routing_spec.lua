local F = require('tests.helpers.input_fixture')

describe('ARC-01-01 error routing probe #probe', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  it('raise in a hook while running is reported', function()
    local input = F.activate_project()
    input.hooks.keypressed = function() error('boom') end
    F.session.press('a')
    assert.is_not_nil(love.state.suspend_msg)
  end)

  it('raise in a hook at project_open is swallowed', function()
    local input = F.activate_project()
    input.hooks.keypressed = function() error('boom') end
    love.state.app_state = 'project_open'
    F.session.press('a')
    assert.is_nil(love.state.suspend_msg)
    assert.equal('project_open', love.state.app_state)
  end)
end)
