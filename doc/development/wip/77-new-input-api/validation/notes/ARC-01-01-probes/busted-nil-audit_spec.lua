-- ARC-01-01 PROBE — NOT A KEEPER. Temporary instrument for the
-- nil audit: with love.state.user_input_controller nil, does
-- each dynamic consumer survive? Delete after recording.

local F = require('tests.helpers.input_fixture')

describe('ARC-01-01 nil audit #probe', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  local function nil_widget()
    love.state.user_input_controller = nil
  end

  it('C1 hide_input_widget via stop_project_run', function()
    F.activate_project()
    nil_widget()
    F.cc:stop_project_run()
    assert.is_nil(love.state.user_input)
  end)

  it('C1b hide_input_widget with a shown widget handle', function()
    F.activate_project()
    F.show_widget({ text = 'x' })
    nil_widget()
    F.cc:stop_project_run()
    assert.is_nil(love.state.user_input)
  end)

  it('C2 reset_widget_outputs via clear_user_handlers', function()
    F.activate_project()
    nil_widget()
    Controller.clear_user_handlers(F.cc)
    assert.is_true(true)
  end)

  -- The dispatch path runs inside with_canvas_and_errors, which
  -- xpcalls the walk and routes a raise to suspend_run. A raise
  -- there does NOT fail a test, so "no crash" proves nothing:
  -- the observable is the error channel.
  it('C3 dispatch: keypress with no widget', function()
    local seen = {}
    local p = F.tracer(seen)
    local input = F.activate_project()
    input.hooks.keypressed = p('hook')
    nil_widget()
    F.session.press('a')
    F.session.type('a')
    F.session.release('a')
    assert.same({ 'hook' }, seen)
    assert.is_nil(love.state.suspend_msg)
    assert.equal('running', love.state.app_state)
  end)

  it('C3b dispatch: pointer with no widget', function()
    F.activate_project()
    nil_widget()
    F.session.mousepressed(10, 10, 1)
    F.session.mousereleased(10, 10, 1)
    F.session.mousemoved(12, 12, 2, 2)
    F.session.wheelmoved(0, 1)
    F.session.touchpressed(1, 10, 10, 0, 0, 1)
    assert.is_nil(love.state.suspend_msg)
    assert.equal('running', love.state.app_state)
  end)

  it('C4 surface: show/hide with no widget', function()
    local input = F.activate_project()
    nil_widget()
    input.show({ text = 'hi', prompt = 'p?' })
    input.hide()
    assert.is_false(input.is_shown())
  end)

  it('C4b surface: readers/mutators with no widget', function()
    local input = F.activate_project()
    nil_widget()
    assert.is_nil(input.get_cursor())
    input.set_cursor(1, 1)
    input.set_text('nope')
    input.clear()
    assert.is_false(input.is_shown())
  end)

  it('C4c surface: configure with no widget', function()
    local input = F.activate_project()
    nil_widget()
    input.configure({ prompt = 'q?', text = 't' })
    assert.is_true(true)
  end)

  it('C4d surface: configure while SHOWN, then widget vanishes',
    function()
      local input = F.activate_project()
      input.show({ text = 'hi' })
      nil_widget()
      input.configure({ prompt = 'q?' })
      assert.is_true(true)
    end)

  it('C5 quit_project with no widget', function()
    F.activate_project()
    nil_widget()
    F.cc:quit_project()
    assert.is_true(true)
  end)

  -- ARC-01-02's ordering claim, made concrete: the compy.input
  -- closure indexes the widget at BUILD time, so a console
  -- built with no widget present raises.
  it('C7 get_compy_input captures the widget by reference',
    function()
      nil_widget()
      local CM = ConsoleModel(F.cfg)
      assert.has_error(function()
        ConsoleController(CM, Controller)
      end)
    end)

  it('C6 restart with no widget', function()
    F.activate_project()
    nil_widget()
    F.cc:restart()
    assert.is_true(true)
  end)
end)
