-- Throwaway probe: model the REAL harmony loop, where love.event.push
-- only enqueues and the handlers run on a later frame (main_loop polls
-- before love.update, which is where the scenario coroutine advances).
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
  local queue = { }
  -- real LÖVE semantics: push enqueues, nothing runs yet
  love.event.push = function(name, key)
    queue[#queue + 1] = { event_name(name), key }
  end
  local pump = function()
    local q = queue
    queue = { }
    for _, e in ipairs(q) do
      love.handlers[e[1]](e[2])
    end
  end
  stub_view()
  require('util.key')
  require('controller.controller')
  local harmony = require('harmony.init')
  harmony(true)
  harmony.load()
  return harmony, pump
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

describe('harmony under the real push/pump split', function()
  it('delivers Ctrl+T as a bare t — the modifier is already released', function()
    local harmony, pump = setup_harmony()
    local calls = gateway()

    harmony.utils.love_key('C-t')   -- scenario step, inside love.update
    pump()                          -- next frame's poll loop

    print('ctrl at pump time:', tostring((Key.ctrl())))
    print('quickswitch fired:', tostring(calls.edit or false))
    assert.same({ }, calls)
  end)
end)
