-- Shared fixture for the input contract suite. Builds the
-- real love.handlers wiring over a real ConsoleController,
-- the singleton input widget (mirroring main.lua), the
-- click/update path and a keypress-level driver — so a
-- contract test reads as a one-line statement (see
-- tests/helpers/input_session). All MVC/gfx/font
-- boilerplate the suite needs lives here; consumed, never
-- copied.

-- view.view stub: the real module calls gfx.newFont at load and
-- needs a graphics context absent here. Set BEFORE any view
-- require below.
package.preload['view.view'] = function()
  View = {
    prev_draw      = nil,
    main_draw      = nil,
    snapshot       = nil,
    clear_snapshot = function() end,
    draw           = function() end,
    drawFPS        = function() end,
  }
end

local mock = require('tests.mock')
local TU   = require('tests.testutil')

-- Mouse position the click path samples; tests drive it through
-- set_mouse_pos to make drift detection observable.
local mx, my = 0, 0

local function mock_runtime()
  mock.mock_love({
    state = {
      app_state             = 'ready',
      user_input            = nil,
      user_input_controller = nil,
      editor                = nil,
    },
    DEBUG   = false,
    PROFILE = false,
    event   = { quit = function() end, push = function() end },
    audio   = {
      newSource = function() return { } end,
      stop      = function() end,
      play      = function() end,
    },
    mouse      = { getPosition = function() return mx, my end },
    paths      = { project_path = '/tmp' },
    filesystem = { getInfo = function() end },
  })
end

local canvas_stub = setmetatable({ }, {
  __index = function() return function() end end,
})

-- Enrich the graphics mock enough to build the terminal/canvas
-- the console model allocates — no real display is opened.
local function enrich_gfx()
  local gfx = love.graphics
  gfx.newCanvas = function() return canvas_stub end
  gfx.getCanvas = function() return nil end
  gfx.setCanvas = function() end
  gfx.setFont   = function() end
  gfx.setColor  = function() end
  gfx.clear     = function() end
  gfx.push      = function() end
  gfx.pop       = function() end
end

-- A monospace font is a leaf dependency of the terminal; stub the
-- metrics it queries at construction.
local font_stub = setmetatable({
  getHeight     = function() return 32 end,
  getWidth      = function() return 16 end,
  setFallbacks  = function() end,
  setLineHeight = function() end,
}, { __index = function() return function() end end })

local function build_cfg()
  require('util.color')
  local cfg = TU.mock_view_cfg()
  cfg.view.font   = font_stub
  cfg.view.colors = require('conf.colors')
  cfg.view.w      = 1024
  cfg.view.h      = 600
  cfg.view.fw     = 16
  cfg.view.lh     = 1
  cfg.mode        = 'dev'
  return cfg
end

local function require_modules()
  require('model.consoleModel')
  require('model.input.userInputModel')
  require('model.interpreter.eval.evaluator')
  require('controller.consoleController')
  require('view.consoleView')
  require('controller.userInputController')
  require('controller.controller')
end

-- The Console MVC the way main.lua wires it; ConsoleView's
-- constructor calls CC:init_view(self) internally.
local function build_console(cfg)
  local CM = ConsoleModel(cfg)
  local CC = ConsoleController(CM, Controller)
  ConsoleView(cfg, CC)
  return CC
end

-- The persistent singleton widget (main.lua: one instance,
-- published to love.state.user_input_controller; the compy.input
-- wrappers resolve it from there).
local function build_singleton(cfg)
  local m = UserInputModel(cfg, InputEvalText)
  local c = UserInputController(m, nil, true)
  c:init_view({ render = function() end, draw = function() end })
  love.state.user_input_controller = c
  return c
end

-- The world below is built from each spec file's busted `setup()`
-- (via F.setup), NOT at module-load time. NOTE: busted 2 already
-- insulates _G and package.loaded per spec file (envmode='insulate'),
-- so this is not guarding a live cross-file collision — it makes the
-- fixture explicit and every (split) spec file runnable standalone.
-- The line-123 REVIEW that used to sit here ("is it safe to call these
-- at load time?") is resolved by exactly this move. F.reset (below)
-- still runs per-test; setup/teardown bracket the whole file.
local cfg, CC, singleton, session

-- F for Fixture. Fields (F.cc/console/editor/singleton/session/cfg) are
-- nil until F.setup runs; reading them at describe-body scope is a bug.
local F = {}

function F.setup()
  if CC then return end -- already built for this spec file
  mock_runtime()
  enrich_gfx()
  cfg = build_cfg()
  require_modules()

  -- Provision the singleton widget BEFORE the console (mirrors
  -- main.lua's reorder): ConsoleController construction builds
  -- the project env's compy.input, which binds to the widget's
  -- own callbacks table — so the widget must exist first.
  singleton = build_singleton(cfg)
  CC = build_console(cfg)
  --- REVIEW/DOC: 'slots', 'gate last-resort route' sound exotic and cannot be understood without context -- dependence on 'when no widget is up' looks like abstraction leak; if its just the way framework sets the controllers when launched -- tell exactly that
  -- Native slots: the gate's last-resort route when no widget
  -- is up, and the route half of pointer delivery
  -- (doc/development/internals/user_input.md, "Direct mouse events").
  Controller.set_love_keypressed(CC)
  Controller.set_love_keyreleased(CC)
  Controller.set_love_textinput(CC)
  Controller.set_love_mousepressed(CC)
  Controller.set_love_mousereleased(CC)
  Controller.set_love_update(CC)
  -- REVIEW/DOC: explain what the line before does and why its needed
  session = require('tests.helpers.input_session').new(CC)

  F.cc        = CC
  F.console   = CC.input
  F.editor    = CC.editor
  F.singleton = singleton
  F.session   = session
  F.cfg       = cfg
end

-- Symmetric partner to F.setup, deliberately shallow: require-cached
-- class globals cannot be un-required, and busted 2's per-file
-- insulation reverts _G/package.loaded anyway — so we only undo the
-- fixture's own semantic state and the two globals mock_love writes.
function F.teardown()
  if Controller and Controller.project_input then
    Controller.project_input:deactivate()
  end
  _G.love, _G.TESTING = nil, nil
  cfg, CC, singleton, session = nil, nil, nil, nil
  F.cc, F.console, F.editor   = nil, nil, nil
  F.singleton, F.session, F.cfg = nil, nil, nil
end

-- The project-facing public surface (compy.input.show/hide); it
-- resolves the singleton exactly as a project does.
function F.compy_input()
  return CC:get_project_env().compy.input
end

-- REVIEW/DOC: we have 'native' handlers, and we have 'compy' handlers, and then we have compy input handlers... there could be a confusion. Can we find a better name explaining this setter unambiguously? Maybe "project_set_compy"? (it will also exactly match what it does.  
-- REVIEW: maybe we should instead use common method 'project_compy_namespace' (which encapsulates CC:get_project_env().compy), and let calling code work from there? (explicirly setting and getting .input, or other attributes)
-- Register a project click handler
-- (compy.singleclick/doubleclick), the target the framework
-- click path invokes (doc/development/internals/user_input.md,
-- "Framework-level click handling").
function F.set_compy_handler(name, fn)
  CC:get_project_env().compy[name] = fn
end

function F.set_mouse_pos(x, y)
  mx, my = x, y
end

-- REVIEW: is it used? Maybe name it 'love_update' for better grepability and transparency?
function F.update(dt)
  love.update(dt)
end

-- Activate the singleton widget 
-- REVIEW: why not via compy.input.show ? 
function F.show_widget(opts)
  singleton:show(opts)
  return singleton
end

-- REVIEW: is it adequate mocking? When project sets up 'love' its actually sets up project_env.love -- sandboxed table what is passed as 'userlove' in a container. Here' instead it sets up direct love callback?
-- Simulate a running project whose callback for `name` is
-- fn: set app_state = 'running' and assign fn directly to
-- the top-level love[name] the dispatcher invokes.
function F.running_project(name, fn)
  love.state.app_state = 'running'
  love[name] = fn
end

--- REVIEW/DOC: 'slot' and 'tier-3' language should rather not be there. instead I'd pferer to see specific pointer to the code/function which is mocked (and why is it mocked, not called?) 
--- REVIEW: I am not sure the level of mocking is correct there. I would rather expect setting 'natives' as project environment (like userlove) and calling the normal framework operation that runs project
--- The "REAL activation path" is consoleController.lua `run_user_code`,
--- the real project-run entry that calls Controller.set_user_handlers.
--- REVIEW/DOC: 'M4 ruling-1' is emphemeral dev-time reference, and I suspect the whole comment may reflect outdated logic/architecture
-- Take the project route through the REAL activation path
-- (Controller.set_user_handlers, what a project run calls): the
-- ProjectInputController becomes the slot occupant and captures
-- the project's `natives` (its love.* handlers) as tier-3 seeds.
-- app_state = 'running' so the four-tier chain (not the M4
-- ruling-1 forward) dispatches. Returns the project-facing
-- compy.input surface. Unlike running_project (which
-- assigns love[name] directly), this goes through the
-- production Controller.set_user_handlers call.
function F.activate_project(natives)
  love.state.app_state = 'running'
  Controller.set_user_handlers(natives or { }, CC)
  return F.compy_input()
end

--- REVIEW: why this low-level machinery and not a call of some existing function? the intent is plausible, the implementation is suspicious
-- A selection-enabled widget seeded with multi-line text, so a
-- pointer event lands an OBSERVABLE selection (the production
-- singleton disables selection, making pointer delivery a no-op —
-- doc/development/internals/user_input.md, "Input widget mouse"). Witnesses
-- pointer delivery to the widget half.
function F.show_selectable_widget(lines)
  local m = UserInputModel(cfg, InputEvalText)
  local w = UserInputController(m, nil, false)
  w:init_view({ render = function() end, draw = function() end })
  w.model:set_text(lines or { 'aa', 'bb', 'cc' })
  love.state.user_input = { M = m, C = w, V = w.view }
  return w
end

--- REVIEW: do not we have framework/consolecontroller method for that? Why not call it? Otherwise its not clear which part of the real lifecycle we're mimicking there (if any)
--- REVIEW: in general, I'd prefer helper/fixture functions to call real framework's code with some test-specific parameters/configuration -- not implement its own 'provision/deprovision' algorithms which will inevitably deviate from what real framework is doing
-- Restore the love.* callbacks a test replaced via
-- running_project, so the next test starts on the
-- framework defaults.
local function restore_native_slots()
  love.keypressed    = Controller._defaults.keypressed
  love.textinput     = Controller._defaults.textinput
  love.keyreleased   = Controller._defaults.keyreleased
  love.mousepressed  = Controller._defaults.mousepressed
  love.mousereleased = Controller._defaults.mousereleased
end

-- Empty a table in place, except any key in `keep`
-- (entries the framework itself installs, never
-- project/test-installed). Assigning nil mid-traversal
-- is fine.
local function wipe(t, keep)
  for k in pairs(t) do
    if not (keep and keep[k]) then rawset(t, k, nil) end
  end
end

--- REVIEW: is not there a framework/controller method doing this? why replicate instead of calling it?
-- Drop every project-route participant the chain rows
-- install, so each test starts from framework defaults:
-- deactivate the route and clear the project-installed
-- shortcut/combo tables and hooks. The widget's callbacks are
-- re-seeded separately (F.reset -> singleton:reset_callbacks),
-- since compy.input.callbacks IS the widget's own table.
local function reset_chain()
  Controller.project_input:deactivate()
  local input = CC:get_project_env().compy.input
  wipe(input.shortcuts.keypressed)
  wipe(input.shortcuts.keyreleased)
  wipe(input.shortcuts.textinput)
  for _, ev in ipairs({ 'keypressed', 'keyreleased', 'textinput' }) do
    input.hooks[ev] = nil
  end
end

-- Clean slate between tests: no held keys, no widget, console mode,
-- empty console line, drained click state, cleared click handlers.
-- REVIEW: good intent but why not framework method? I am sure it has methods for exiting the project and doing big cleanup
function F.reset()
  Controller.keys_pressed       = { }
  love.state.user_input         = nil
  love.state.app_state          = 'ready'
  love.state.editor             = nil
  -- Otherwise leaks into the next test's suspend(): a
  -- stale message from an earlier suspend_run() would set
  -- an unrelated console error (discovered via the route-
  -- lifecycle inspect row, m5c chunk 4).
  love.state.suspend_msg        = nil
  restore_native_slots()
  reset_chain()
  local compy                   = CC:get_project_env().compy
  compy.singleclick             = nil
  compy.doubleclick             = nil
  love.update(1.0)
  CC.input:clear()
  CC.editor.input:clear()
  singleton:clear()
  singleton.shown = false
  -- The widget's OWN callbacks table (which IS compy.input.
  -- callbacks): re-seed the stay-open defaults between tests, the
  -- same reset production teardown runs (reset_widget_outputs).
  -- A value set by one test would otherwise leak into the next.
  singleton:reset_callbacks()
  singleton.result = nil
end

return F
