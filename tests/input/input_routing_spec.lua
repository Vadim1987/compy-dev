-- Input routing through the installed love.handlers.* gate.
--
-- WHAT THIS TESTS: the path a keystroke takes from LOVE to the
-- controller that consumes it. main.lua installs the gate via
-- Controller.setup_callback_handlers, which wraps love.handlers
-- keypressed/textinput/keyreleased. Every key/char event enters
-- there, and the gate alone decides who consumes it.
--
-- THREE SINKS, picked by app_state (and overlay presence). Each
-- has its OWN model -- the three modes do not share one:
--   * REPL console -- app_state 'ready'. Sink is CC.input, a
--     UserInputController; CC.input.model is its UserInputModel
--     (the line being typed at the console prompt).
--   * editor -- app_state 'editor'. ConsoleController delegates
--     to CC.editor, an EditorController it builds and owns from
--     construction (not on mode switch); it has its own model.
--   * input overlay -- the singleton modal dialog (e.g. project
--     prompts). When shown it publishes itself to
--     love.state.user_input; the gate then routes to it,
--     overriding the console/editor sink. Its own model again.
--
-- EVENT VOCABULARY: 'textinput' is LOVE's character-typed event
-- (one per printable char, e.g. 'Z') -- NOT a key like Enter,
-- which arrives as 'keypressed'('return'). The driver below
-- (session.type / session.press) and mock.textinput just fire
-- these real events through the gate.
--
-- Each test drives a real production slot and asserts the REAL
-- consumer received it -- never a hand-rolled lambda. The tests
-- are agnostic to the gate's internals, so the regression group
-- holds before and after the overlay-gate rewrite.

-- Stub view.view before any require loads the real module:
-- view.lua calls gfx.newFont at load and needs a graphics
-- context absent here.
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

local mock = require('tests.mock')
local TU   = require('tests.testutil')

-- Mock the runtime a real ConsoleController touches at build
-- time and on the input path (audio, project paths, events).
mock.mock_love({
  state = {
    app_state = 'ready',
    user_input = nil,
    editor = nil,
  },
  DEBUG   = false,
  PROFILE = false,
  event   = { quit = function() end, push = function() end },
  audio   = {
    newSource = function() return { } end,
    stop      = function() end,
    play      = function() end,
  },
  paths      = { project_path = '/tmp' },
  filesystem = { getInfo = function() end },
})

-- Enrich the graphics mock enough to build the terminal/canvas
-- the console model allocates -- no real display is opened.
local canvas_stub = setmetatable({ }, {
  __index = function() return function() end end,
})
local gfx = love.graphics
gfx.newCanvas = function() return canvas_stub end
gfx.getCanvas = function() return nil end
gfx.setCanvas = function() end
gfx.setFont   = function() end
gfx.setColor  = function() end
gfx.clear     = function() end
gfx.push      = function() end
gfx.pop       = function() end

-- A monospace font is a leaf dependency of the terminal; stub
-- the metrics it queries at construction.
local font_stub = setmetatable({
  getHeight     = function() return 32 end,
  getWidth      = function() return 16 end,
  setFallbacks  = function() end,
  setLineHeight = function() end,
}, { __index = function() return function() end end })

require('util.color')
local colors = require('conf.colors')

local cfg = TU.mock_view_cfg()
cfg.view.font   = font_stub
cfg.view.colors = colors
cfg.view.w      = 1024
cfg.view.h      = 600
cfg.view.fw     = 16
cfg.view.lh     = 1
cfg.mode        = 'dev'

require('model.consoleModel')
require('model.input.userInputModel')
require('model.interpreter.eval.evaluator')
require('controller.consoleController')
require('view.consoleView')
require('controller.userInputController')
require('controller.controller')
local input_session = require('tests.helpers.input_session')

-- Wire the Console MVC the way main.lua does, then install the
-- input slots and the gate. The gate (input_session) falls back
-- to the love.keypressed/textinput slots when no overlay is
-- active, so the real ConsoleController is the sink reached.
local CM = ConsoleModel(cfg)
local CC = ConsoleController(CM, Controller)
ConsoleView(cfg, CC)
Controller.set_love_keypressed(CC)
Controller.set_love_keyreleased(CC)
Controller.set_love_textinput(CC)
-- The driver: input_session installs the gate and exposes it as
-- session.press(key) (keypressed), session.type(char)
-- (textinput) and session.repeat_press(key). Every call goes
-- through the real love.handlers.* path, never straight to a
-- controller.
local session = input_session.new(CC)

-- Build the input overlay singleton the way main.lua does at
-- startup: its own model + controller, then :show() publishes
-- it to love.state.user_input. Once published the gate routes
-- to it and overrides the console/editor sink -- this is the
-- "a modal dialog is open" condition the overlay tests need.
local overlay_view = {
  render = function() end,
  draw   = function() end,
}
local function show_input_overlay(result_ref)
  local m = UserInputModel(cfg, InputEvalText, true)
  local c = UserInputController(m, result_ref, true)
  c:init_view(overlay_view)
  c:show()
  return c
end

-- EditorSession (unchanged) for the at-limit block-nav row; it
-- drives EditorController directly, not through the love slots.
require('tests.helpers.codesnippets')
require('tests.helpers.editor_session')

local function make_editor_session()
  local model = EditorModel(cfg)
  local ec    = EditorController(model)
  EditorView(cfg.view, ec)
  local press = function(k) ec:keypressed(k) end
  local save  = TU.get_save_function({ })
  return EditorSession(ec, press, save, mock)
end

-- Spy that records receipt at a REAL consumer's method boundary
-- (obj[name]) and auto-restores after each test. Record-only:
-- swallows the call, so it proves the gate delivered to this
-- exact instance without depending on downstream view/buffer
-- state. Returns the list of received args to assert on.
local cleanup = { }
local function record_calls(obj, name)
  local calls = { }
  local orig  = obj[name]
  obj[name] = function(_, a) calls[#calls + 1] = a end
  cleanup[#cleanup + 1] = function() obj[name] = orig end
  return calls
end

describe('input routing #input', function()

  after_each(function()
    for _, restore in ipairs(cleanup) do restore() end
    cleanup = { }
  end)

  before_each(function()
    -- Reset to a clean REPL: no held keys, no overlay shown,
    -- console mode, and an empty console input line.
    Controller.keys_pressed = { }
    love.state.user_input   = nil
    love.state.app_state    = 'ready'
    CC.input.model:clear_input()
  end)

  -- ── must-not-degrade (regression smoke) ──
  -- Green now and after the gate rewrite. Driven through the
  -- gate; each asserts a real controller received.
  describe('must-not-degrade', function()

    it('console text reaches the console input', function()
      -- app_state 'ready' = REPL mode (set in before_each).
      -- mock.textinput fires LOVE's character-typed event 'Z'
      -- (the tests/mock.lua emitter, through the gate) -- this
      -- is a typed letter, not Enter. Assert the REPL console
      -- input (CC.input, a UserInputController) captured it.
      mock.textinput('Z')
      assert.same({ 'Z' }, CC.input:get_text())
    end)

    it('console keypress reaches the console', function()
      local calls = record_calls(CC, 'keypressed')
      session.press('left')
      assert.same({ 'left' }, calls)
    end)

    it('editor text reaches the editor', function()
      love.state.app_state = 'editor'
      local calls = record_calls(CC.editor, 'textinput')
      session.type('q')
      assert.same({ 'q' }, calls)
    end)

    it('editor keypress reaches the editor', function()
      love.state.app_state = 'editor'
      local calls = record_calls(CC.editor, 'keypressed')
      session.press('left')
      assert.same({ 'left' }, calls)
    end)

    it('active overlay receives input', function()
      local c = show_input_overlay()
      local calls = record_calls(c, 'keypressed')
      session.press('a')
      assert.same({ 'a' }, calls)
    end)

    -- Routing exclusivity: an active overlay must not also fire
    -- the native slot (no double-delivery).
    it('active overlay does not also fire native', function()
      show_input_overlay()
      local native = 0
      local slot = love.keypressed
      love.keypressed = function(...)
        native = native + 1
        return slot(...)
      end
      cleanup[#cleanup + 1] =
        function() love.keypressed = slot end
      session.press('a')
      assert.equal(0, native)
    end)

    -- textinput EXCLUSIVE (§3.2): overlay active → overlay
    -- receives it; with no overlay → base sink (already above).
    it('active overlay receives textinput', function()
      local c = show_input_overlay()
      local calls = record_calls(c, 'textinput')
      session.type('Z')
      assert.same({ 'Z' }, calls)
    end)

    it('active overlay blocks native textinput', function()
      show_input_overlay()
      local native = 0
      local slot = love.textinput
      love.textinput = function(...)
        native = native + 1
        return slot(...)
      end
      cleanup[#cleanup + 1] =
        function() love.textinput = slot end
      session.type('Z')
      assert.equal(0, native)
    end)

    -- keyreleased EXCLUSIVE (§3.3): base sink (no overlay),
    -- overlay-only when active, never both.
    it('console keyreleased reaches the console', function()
      local calls = record_calls(CC, 'keyreleased')
      session.release('a')
      assert.same({ 'a' }, calls)
    end)

    it('active overlay receives keyreleased', function()
      local c = show_input_overlay()
      local calls = record_calls(c, 'keyreleased')
      session.release('a')
      assert.same({ 'a' }, calls)
    end)

    it('active overlay blocks native keyreleased', function()
      show_input_overlay()
      local native = 0
      local slot = love.keyreleased
      love.keyreleased = function(...)
        native = native + 1
        return slot(...)
      end
      cleanup[#cleanup + 1] =
        function() love.keyreleased = slot end
      session.release('a')
      assert.equal(0, native)
    end)

    -- mousepressed BOTH (§3.5): overlay active → widget AND
    -- base sink each receive (order incidental, R3).
    it('mousepressed reaches widget and base sink', function()
      local c = show_input_overlay()
      local wgt = record_calls(c, 'mousepressed')
      local base = 0
      love.mousepressed =
        function() base = base + 1 end
      cleanup[#cleanup + 1] =
        function() love.mousepressed = nil end
      session.mousepressed(100, 200, 1, false, 1)
      assert.equal(1, #wgt)
      assert.equal(1, base)
    end)
  end)

  -- inspect ownership — provisional characterization only.
  -- A deliberate inspect routing change must not red this suite.
  describe('inspect ownership', function()
    -- Current behaviour (§3.4): under app_state='inspect',
    -- get_user_input() returns nil (controller.lua:20), so a
    -- shown widget is not offered keyboard/text; the
    -- console/REPL receives via love.keypressed/textinput.
    --
    -- PROVISIONAL (contract §3.4): kept for now, expected to
    -- change under routing unification; characterize, do not
    -- regression-guard. Revisit when the routing model lands.
    pending('inspect: console owns input — provisional')
  end)

  -- ── editor block-nav at buffer limit #editor ──
  -- Exercises block navigation INDIRECTLY through the at-limit
  -- condition: only an up/down press while the cursor sits at
  -- the input's vertical limit escalates to block-nav. Guards
  -- that the later line-scope rewrite of is_at_limit cannot
  -- regress whole-input block nav. Drives EditorController.
  describe('editor block-nav at-limit #editor', function()

    before_each(function()
      love.state.app_state = 'editor'
    end)

    it('up at top limit navigates blocks', function()
      local es  = make_editor_session()
      local f1  = mock_func_snippet("one")
      local f2  = mock_func_snippet("two")
      local src = (snippets_to_code(f1, '', f2))
      es:open(src, 3)
      local buf = es.controller:get_active_buffer()
      es:select_and_open_block(3)
      -- line 1, not at down-limit: cursor moves, block stays
      es.mock.keystroke('down', es.press)
      assert.equal(3, buf.selection)
      -- line 2, not at up-limit: cursor moves, block stays
      es.mock.keystroke('up', es.press)
      assert.equal(3, buf.selection)
      -- line 1 (top limit): escalates to block navigation
      es.mock.keystroke('up', es.press)
      assert.is_true(buf.selection < 3)
    end)
  end)

  -- ── to-be-implemented by the gate rewrite ──
  -- Carried pending so the suite stays green and the pre-commit
  -- hook passes; the gate rewrite converts each to a live it().
  describe('to-be-implemented', function()

    -- DEFERRED (0.1.0-m4): gate-removal payoff. With a project
    -- running and the singleton active, project key events must
    -- reach ProjectInputController. Today the `if user_input`
    -- gate silently drops them.
    pending('project key events reach the project sink')

    -- DEFERRED (0.1.0-m4): slot ownership/restoration. The
    -- ProjectInputController owns the keypressed/text slots
    -- while a project runs; on stop the slot is restored
    -- to the ConsoleController.
    pending('project stop restores the console slot')

    -- DEFERRED (0.1.0-m4): native coexistence. A legacy project
    -- (native love.keypressed, no compy.* surfaces) gets a
    -- lifecycle-split wrapper: native handler fires while
    -- the singleton is hidden; the sink receives while visible.
    pending('legacy native handler coexists with the sink')

    -- DEFERRED (0.1.0-m4): isrepeat threading. isrepeat reaches
    -- the keypressed path once the harvest wrapper threads it
    -- (today the function(k) signature drops it).
    pending('isrepeat reaches the keypressed path')
  end)
end)
