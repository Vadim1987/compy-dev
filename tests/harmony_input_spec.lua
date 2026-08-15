local mock = require('tests.mock')

local function event_name(name)
  return string.sub(name, string.len('sazed_') + 1)
end

local function stub_view()
  package.loaded['view.view'] = nil
  package.preload['view.view'] = function()
    View = {
      clear_snapshot = function() end,
      draw = function() end,
      drawFPS = function() end,
    }
  end
end

local function setup_harmony()
  package.loaded['harmony.init'] = nil
  _G.Harmony = nil
  mock.mock_love({
    event = { },
    handlers = { },
    state = { app_state = 'running' },
    window = {
      getTitle = function() return 'test' end,
      setTitle = function() end,
    },
  })
  local events = { }
  love.event.push = function(name, key)
    events[#events + 1] = event_name(name) .. ':' .. key
    love.handlers[event_name(name)](key)
  end
  stub_view()
  require('util.key')
  require('controller.controller')
  local harmony = require('harmony.init')
  harmony(true)
  harmony.load()
  return harmony, events
end

local function gateway()
  local calls = { }
  local cc = {
    cfg = { mode = 'dev' },
    edit = function() calls.edit = true end,
    stop_project_run = function() calls.stop = true end,
  }
  Controller.setup_callback_handlers(cc)
  return calls
end

describe('harmony input', function()
  it('drives Ctrl+T through the device-read matcher', function()
    local harmony, events = setup_harmony()
    local calls = gateway()

    harmony.utils.love_key('C-t')

    assert.same({ edit = true, stop = true }, calls)
    assert.same({
      'keypressed:lctrl',
      'keypressed:t',
      'keyreleased:t',
      'keyreleased:lctrl',
    }, events)
    local ctrl = Key.ctrl()
    assert.is_falsy(ctrl)
  end)
end)

