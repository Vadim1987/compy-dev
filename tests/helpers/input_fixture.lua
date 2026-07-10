-- Full input standup for the contract suite. Stands up the REAL
-- love.handlers gate over a REAL ConsoleController, the singleton
-- input widget (mirroring main.lua), the click/update path and a
-- keypress-level driver — so a contract test reads as a one-line
-- statement (see tests/helpers/input_session). The ~175 ln of
-- MVC/gfx/font boilerplate that used to sit inline in
-- input_contracts_spec lives here; consumed, never copied.
-- "doc A" = the contract record:
-- doc/development/wip/77-new-input-api/notes/input-contracts.md

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

mock_runtime()
enrich_gfx()
local cfg = build_cfg()
require_modules()

local CC = build_console(cfg)
-- Native slots: the gate's last-resort route when no widget is up,
-- and the route half of pointer delivery (doc A §5.5).
Controller.set_love_keypressed(CC)
Controller.set_love_keyreleased(CC)
Controller.set_love_textinput(CC)
Controller.set_love_mousepressed(CC)
Controller.set_love_mousereleased(CC)
Controller.set_love_update(CC)
local singleton = build_singleton(cfg)
local session   = require('tests.helpers.input_session').new(CC)

local F = {
  cc        = CC,
  console   = CC.input,
  editor    = CC.editor,
  singleton = singleton,
  session   = session,
  cfg       = cfg,
}

-- The project-facing public surface (compy.input.show/hide); it
-- resolves the singleton from love.state, exactly as a project does.
function F.compy_input()
  return CC:get_project_env().compy.input
end

-- Register a project click handler (compy.singleclick/doubleclick),
-- the target the framework click path invokes (doc A §6.7).
function F.set_compy_handler(name, fn)
  CC:get_project_env().compy[name] = fn
end

function F.set_mouse_pos(x, y)
  mx, my = x, y
end

function F.update(dt)
  love.update(dt)
end

-- Activate the singleton widget (publishes love.state.user_input).
function F.show_widget(opts)
  singleton:show(opts)
  return singleton
end

-- Stand a running project on screen whose native LÖVE callback
-- is fn. With no widget up the gateway routes the event to
-- love[name], so the project's own callback is the public seam
-- witnessing delivery to the project route (doc A §5.1-5.3).
function F.running_project(name, fn)
  love.state.app_state = 'running'
  love[name] = fn
end

-- Take the project route through the REAL activation path
-- (Controller.set_user_handlers, what a project run calls): the
-- ProjectInputController becomes the slot occupant and captures
-- the project's `natives` (its love.* handlers) as tier-3 seeds.
-- app_state = 'running' so the four-tier chain (not the M4
-- ruling-1 forward) dispatches. Returns the project-facing
-- compy.input surface. This is the seam the dispatch-chain rows
-- drive, in contrast with running_project's raw-slot shortcut.
function F.activate_project(natives)
  love.state.app_state = 'running'
  Controller.set_user_handlers(natives or { }, CC)
  return F.compy_input()
end

-- A selection-enabled widget seeded with multi-line text, so a
-- pointer event lands an OBSERVABLE selection (the production
-- singleton disables selection, making pointer delivery a no-op —
-- doc A §5.5). Witnesses pointer delivery to the widget half.
function F.show_selectable_widget(lines)
  local m = UserInputModel(cfg, InputEvalText)
  local w = UserInputController(m, nil, false)
  w:init_view({ render = function() end, draw = function() end })
  w.model:set_text(lines or { 'aa', 'bb', 'cc' })
  love.state.user_input = { M = m, C = w, V = w.view }
  return w
end

-- Undo any project-native slot a test installed via
-- running_project, so the next test starts on the framework
-- route.
local function restore_native_slots()
  love.keypressed    = Controller._defaults.keypressed
  love.textinput     = Controller._defaults.textinput
  love.keyreleased   = Controller._defaults.keyreleased
  love.mousepressed  = Controller._defaults.mousepressed
  love.mousereleased = Controller._defaults.mousereleased
end

-- Empty a table in place (used to clear the normalising
-- handler sub-tables between tests; assigning nil is fine
-- mid-traversal), except any key in `keep` (the framework's
-- OWN structural entries, never project/test-installed —
-- spec §5 AC-17/19).
local function wipe(t, keep)
  for k in pairs(t) do
    if not (keep and keep[k]) then rawset(t, k, nil) end
  end
end

-- Drop every project-route participant the chain rows
-- install, so each test starts from framework defaults (the
-- M5c teardown invariant, exercised at fixture scope):
-- deactivate the route, clear the project-installed
-- framework/combo tables and generic callbacks/hooks. Tier-1
-- return/escape (installed once, at ProjectInputController
-- construction, not per-test) survive the keypressed wipe —
-- they are structural, not a test artifact.
local function reset_chain()
  Controller.project_input:deactivate()
  local fw = Controller.project_input.framework_handlers
  wipe(fw.keypressed, { ['return'] = true, escape = true })
  wipe(fw.keyreleased); wipe(fw.textinput)
  local input = CC:get_project_env().compy.input
  wipe(input.handlers.keypressed)
  wipe(input.handlers.keyreleased)
  wipe(input.handlers.textinput)
  input.on_key_pressed  = nil
  input.on_text_input   = nil
  input.on_key_released = nil
  input.on_text_entered = nil
  input.on_limit_reached = nil
  input.validator = nil
  input.highlighter = nil
  input.before_submit = nil
  input.after_submit = nil
  input.before_cancel = nil
  input.after_cancel = nil
end

-- Clean slate between tests: no held keys, no widget, console mode,
-- empty console line, drained click state, cleared click handlers.
function F.reset()
  Controller.keys_pressed       = { }
  love.state.user_input         = nil
  love.state.app_state          = 'ready'
  love.state.editor             = nil
  restore_native_slots()
  reset_chain()
  local compy                   = CC:get_project_env().compy
  compy.singleclick             = nil
  compy.doubleclick             = nil
  love.update(1.0)
  CC.input:clear()
  CC.editor.input:clear()
  singleton:clear()
  -- The widget's OWN output/hook fields (apply_config only
  -- overwrites when a show() config key is given, so a value
  -- set by one test would otherwise survive into the next —
  -- production behaviour, AC-24, but wrong at fixture scope).
  singleton.validator = nil
  singleton.on_text_entered = nil
  singleton.on_limit_reached = noop
  singleton.result = nil
end

return F
