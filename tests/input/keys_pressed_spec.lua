-- Stub view.view before anything requires it: the real module (src/view/view.lua) calls
-- gfx.newFont() at load time (gfx = love.graphics), which needs a graphics context absent in
-- tests. This minimal stub mirrors the fields the controller path touches.
-- (Dedup of this stub across the input specs is an open
-- {badspecref: A8} test-infra item (M2 agenda A8, "test
-- the contract": behaviour vs. internals) — see
-- {badspecref: M2-human-review.md} (implementation/
-- reviews/M2-human-review.md).)
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

-- The controller handlers read love.state / DEBUG / event at runtime; mock just those.
-- (love.keyboard is not mocked and the suite passes, so this path doesn't poll it.)
local mock = require('tests.mock')
mock.mock_love({
  state = {
    app_state = 'ready',
    user_input = nil,
    editor = nil,
  },
  DEBUG = false,
  PROFILE = false,
  -- quit is a no-op: we assert the handlers don't crash, not quit behaviour.
  event = { quit = function() end },
})

-- mock_love omits love.handlers; setup_callback_handlers installs the real keypressed/
-- keyreleased closures into it, so the table must exist first.
love.handlers = { }

require('controller.controller')

-- Reproduce the app's real startup wiring: setup_callback_handlers is the production path that
-- registers the input handlers (not a test shortcut).
Controller.setup_callback_handlers({
  cfg = { mode = 'dev' },
})

-- Save handler refs now: other spec files replace _G.love during collection, which would
-- otherwise clobber these. (Shared cross-spec love
-- mutation is an open {badspecref: A8} isolation item —
-- M2 agenda A8, test-the-contract theme.)
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

  -- {badspecref: A8} (test the contract): single
  -- press->release flow + behaviour-vs-internals
  -- restructure is deferred to the
  -- {badspecref: 0.1.0-m4} test-strategy pass — see
  -- {badspecref: M2-human-review.md} (implementation/
  -- reviews/M2-human-review.md, agenda item A8).
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
    -- unpressed keys stay falsey
    assert.is_nil(Controller.keys_pressed['rctrl'])
    assert.is_nil(Controller.keys_pressed['a'])
  end)

  -- The table keeps RAW l/r names distinct; folding to a generic "ctrl" happens only in
  -- combo_string, never in keys_pressed itself. (Replaces the old is_nil('ctrl') assertion,
  -- which was a tautology: nothing ever writes a folded 'ctrl' key to the table.)
  it('keeps lr variants distinct; fold is combo_string\'s job', function()
    kp_handler('lctrl')
    kp_handler('rctrl')
    assert.truthy(Controller.keys_pressed['lctrl'])
    assert.truthy(Controller.keys_pressed['rctrl'])
    -- positive proof the fold lives in combo_string, not the table:
    assert.equal('ctrl+x', Controller.combo_string('x', Controller.keys_pressed))
  end)
end)


-- (serialize-vs-match): proposal to
-- replace per-keypress combo_string serialisation with
-- registration-time dispatcher closures — same open item
-- as doc/development/technical_debt/input.md, "Combo-string dispatch
-- allocates a table per call".
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
