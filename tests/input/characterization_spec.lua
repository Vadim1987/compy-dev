-- Feature-global characterization safety net (Tier 1, M4-0).
-- Pins observable input behaviour before M4 rewrites the path.
-- All assertions go through the production-slot driver or the
-- real compy.input surface — no implementation internals.

-- Stub view.view before any require loads the real module
-- (view.lua calls gfx.newFont at load; needs graphics context).
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

require('model.input.userInputModel')
require('model.interpreter.eval.evaluator')
require('controller.userInputController')
require('model.editor.editorModel')
require('controller.editorController')
require('view.editor.editorView')

local mock = require('tests.mock')
local TU   = require('tests.testutil')

mock.mock_love({
  state = {
    app_state = 'running',
    user_input = nil,
    editor = nil,
  },
  DEBUG   = false,
  PROFILE = false,
  event   = { quit = function() end, push = function() end },
})

love.handlers = {}
require('controller.controller')
Controller.setup_callback_handlers({ cfg = { mode = 'dev' } })

-- Capture production-slot handler refs (same as keys_pressed_spec).
local kp = love.handlers.keypressed
local kr = love.handlers.keyreleased
local ti = love.handlers.textinput

-- Production-slot driver.
local session = {
  press        = function(k) kp(k, '', false) end,
  release      = function(k) kr(k)            end,
  type         = function(t) ti(t)            end,
  repeat_press = function(k) kp(k, '', true)  end,
}

local cfg      = TU.mock_view_cfg()
local mock_view = { render = function() end, draw = function() end }

-- Build a oneshot UserInputController overlay and publish it.
local function make_overlay(eval, result_ref)
  local m = UserInputModel(cfg, eval or InputEvalText, true)
  local c = UserInputController(m, result_ref)
  c:init_view(mock_view)
  love.state.user_input = { M = m, C = c, V = mock_view }
  return c
end

-- EditorSession helpers for is_at_limit block-nav tests.
require('tests.helpers.codesnippets')
require('tests.helpers.editor_session')

local function make_editor_session()
  local ec_cfg = TU.mock_view_cfg()
  local model  = EditorModel(ec_cfg)
  local ec     = EditorController(model)
  EditorView(ec_cfg.view, ec)
  local press  = function(k) ec:keypressed(k) end
  local save   = TU.get_save_function({})
  return EditorSession(ec, press, save, mock)
end

-- ── Characterization tests ──────────────────────────────────

describe('characterization net #input', function()

  before_each(function()
    Controller.keys_pressed   = {}
    love.state.user_input     = nil
    love.state.app_state      = 'running'
    love.keypressed           = nil
    love.keyreleased          = nil
    love.textinput            = nil
  end)

  -- ── D-9: native coexistence (pong-like) ────────────────────
  describe('D-9 native coexistence', function()
    it('keypressed routes to love.keypressed', function()
      local got = {}
      love.keypressed = function(k) got[#got+1] = k end
      session.press('space')
      assert.same({ 'space' }, got)
    end)

    it('textinput routes to love.textinput', function()
      local got = {}
      love.textinput = function(t) got[#got+1] = t end
      session.type('a')
      assert.same({ 'a' }, got)
    end)

    it('keyreleased routes to love.keyreleased', function()
      local got = {}
      love.keyreleased = function(k) got[#got+1] = k end
      session.release('x')
      assert.same({ 'x' }, got)
    end)
  end)

  -- ── tixy input_code ─────────────────────────────────────────
  -- tixy uses user_input() + input_code(); both drive through the
  -- overlay path. Characterizes the text-eval submit flow.
  -- P1: textinput and keypressed are injected independently here;
  -- ordering is intentional and does not encode SDL delivery order.
  describe('tixy input_code: overlay text submit', function()
    it('typed text + return populates reftable', function()
      local r = table.new_reftable()
      make_overlay(InputEvalText, r)
      session.type('1')
      session.type('+')
      session.type('1')
      session.press('return')
      assert.is_false(r:is_empty())
      assert.equal('1+1', r())
    end)
  end)

  -- ── balloons input_text ──────────────────────────────────────
  describe('balloons input_text: text-eval overlay', function()
    it('typed text + return populates reftable', function()
      local r = table.new_reftable()
      make_overlay(InputEvalText, r)
      session.type('s')
      session.type('t')
      session.type('a')
      session.type('r')
      session.type('t')
      session.press('return')
      assert.equal('start', r())
    end)
  end)

  -- ── turtle input_text + Esc dismiss ─────────────────────────
  describe('turtle input_text + Esc', function()
    it('escape clears entered text (cancel)', function()
      local r = table.new_reftable()
      local c = make_overlay(InputEvalText, r)
      session.type('U')
      session.type('P')
      assert.is_false(c:is_empty())
      session.press('escape')
      assert.is_true(c:is_empty())
    end)

    it('escape does not populate the reftable', function()
      local r = table.new_reftable()
      make_overlay(InputEvalText, r)
      session.type('a')
      session.press('escape')
      assert.is_true(r:is_empty())
    end)
  end)

  -- ── editor REPL submit (running mode) ───────────────────────
  describe('editor REPL submit', function()
    it('typed text + return submits to reftable', function()
      local r = table.new_reftable()
      make_overlay(InputEvalText, r)
      session.type('f')
      session.type('o')
      session.type('o')
      session.press('return')
      assert.equal('foo', r())
    end)
  end)

  -- ── keyboard example: once-per-press debounce ───────────────
  -- The keyboard example maintains INPUT.held to filter repeats
  -- because controller.lua:554 drops isrepeat (function(k)).
  -- Pins the edge-tracking pattern (P2 surface for M4-M7).
  describe('keyboard once-per-press debounce', function()
    local hit_count, held_keys

    before_each(function()
      hit_count = 0
      held_keys = {}
      love.state.user_input = nil
      love.keypressed = function(k)
        if held_keys[k] then return end
        held_keys[k] = true
        hit_count = hit_count + 1
      end
      love.keyreleased = function(k)
        held_keys[k] = nil
      end
    end)

    it('first press fires', function()
      session.press('a')
      assert.equal(1, hit_count)
    end)

    it('second press without release is dropped', function()
      session.press('a')
      session.press('a')
      assert.equal(1, hit_count)
    end)

    it('repeat_press is also dropped (key still held)', function()
      session.press('a')
      session.repeat_press('a')
      assert.equal(1, hit_count)
    end)

    it('release + repress fires again', function()
      session.press('a')
      session.release('a')
      session.press('a')
      assert.equal(2, hit_count)
    end)
  end)

  -- ── maze legacy idiom ────────────────────────────────────────
  describe('maze legacy idiom', function()
    it('is_empty true before typing, false after', function()
      local r = table.new_reftable()
      local c = make_overlay(InputEvalText, r)
      assert.is_true(c:is_empty())
      session.type('F')
      assert.is_false(c:is_empty())
    end)

    it('native keypressed reached when no overlay', function()
      local got = {}
      love.keypressed = function(k) got[#got+1] = k end
      love.state.user_input = nil
      session.press('up')
      session.press('right')
      assert.same({ 'up', 'right' }, got)
    end)

    it('Shift+Enter inserts newline (multiline input)', function()
      local r = table.new_reftable()
      make_overlay(InputEvalText, r)
      session.type('F')
      mock.keystroke('S-return', function(k)
        kp(k, '', false)
      end)
      session.type('B')
      session.press('return')
      assert.truthy(r():find('\n'))
    end)
  end)

  -- ── editor is_at_limit vertical block-nav ───────────────────
  -- Uses EditorSession (unchanged) — drives EditorController
  -- directly, not through love.handlers. Pins vertical whole-input
  -- is_at_limit so M6's line-scope rewrite can't regress block-nav.
  describe('editor is_at_limit vertical block-nav #editor', function()

    before_each(function()
      love.state.app_state = 'editor'
    end)

    it('up at top limit navigates block; up below stays in input',
      function()
        local es  = make_editor_session()
        local f1  = mock_func_snippet("one")
        local f2  = mock_func_snippet("two")
        local src = (snippets_to_code(f1, '', f2))
        es:open(src, 3)
        local buf = es.controller:get_active_buffer()
        -- Open block 3 (f2, 3 lines) → cursor at home (line 1)
        es:select_and_open_block(3)
        -- press down: at line 1, not at down-limit → cursor moves
        es.mock.keystroke('down', es.press)
        assert.equal(3, buf.selection)
        -- press up: at line 2, not at up-limit → cursor moves
        es.mock.keystroke('up', es.press)
        assert.equal(3, buf.selection)
        -- press up: at line 1 (top limit) → block navigation
        es.mock.keystroke('up', es.press)
        assert.is_true(buf.selection < 3)
    end)
  end)

  -- ── B-3: forward assertion — isrepeat threading (pending) ───
  -- DEFERRED (0.1.0-m4): isrepeat threading — M4 threads isrepeat
  -- at controller.lua:554; convert this pending → live assertion then.
  pending(
    'isrepeat reaches keypressed path (M4 threads it)',
    function()
      -- After M4: handlers.keypressed = function(k, sc, isrepeat)
      -- and isrepeat is forwarded through the overlay path.
      -- The assertions below document the target behaviour.
      local received = nil
      local r = table.new_reftable()
      local c = make_overlay(InputEvalText, r)
      local orig_kp = c.keypressed
      -- TODO (M4): intercept and assert isrepeat arrives here.
      -- session.repeat_press('a')
      -- assert.is_true(received_isrepeat)
    end
  )

end)
