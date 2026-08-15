local mock = require('tests.mock')

local function event_name(name)
  return string.sub(name, string.len('sazed_') + 1)
end

local function setup_harmony()
  package.loaded['harmony.init'] = nil
  _G.Harmony = nil
  mock.mock_love({
    event = { },
    handlers = { },
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
  require('util.key')
  local harmony = require('harmony.init')
  harmony(true)
  harmony.load()
  return harmony, events
end

describe('harmony input', function()
  it('drives Ctrl+T through the device-read matcher', function()
    local harmony, events = setup_harmony()
    local toggled = false
    love.handlers.keypressed = function(key)
      toggled = key == 't' and Key.ctrl()
    end
    love.handlers.keyreleased = function() end

    harmony.utils.love_key('C-t')

    assert.is_true(toggled)
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

