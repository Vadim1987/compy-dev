Prof = require("controller.profiler")
require("view.view")
require("controller.projectInputController")

require("util.string.string")
require("util.key")
require("util.lua")
local LANG = require("util.eval")

local messages = {
  user_break = "BREAK into program",
  exit_anykey = "Press any key to exit.",
  exec_error = function(err)
    Log.error((debug.traceback(
      "Error: " .. tostring(err), 1):gsub("\n[^\n]+$", "")
    ))
    return 'Execution error at ' .. err
  end
}

local get_user_input = function()
  if love.state.app_state == 'inspect' then return end
  return love.state.user_input
end


--- @type boolean
local user_update
--- @type boolean
local user_draw
--- @type boolean
-- set when a project installs any pointer/click handler.
-- Together with a shown input widget it marks a non-blocking
-- project (one that overrides no update/draw, e.g. a
-- pen-and-paper game) as still "live"
-- (doc/development/technical_debt/input.md, "Input-only / pointer-only
-- projects stay live in `project_open` (RESOLVED, ruling
-- a)"): keep the project route, Ctrl+Esc -> console.
local user_pointer

-- One lifetime, several names for subsets of it. Every channel
-- installs the same way, runs the same chain, and is released at
-- the same moment: the project's stop. The split that existed
-- here (keyboard released at running->project_open, pointer
-- exempted so pen-and-paper projects survived it) came with
-- this feature and is gone: at the PR base nothing was
-- released before suspend or stop.
-- The subsets below name what a group CARRIES, never how it is
-- routed: keyboard/text events have a combo trigger and
-- therefore a shortcuts tier.
local _keyboard = {
  'keypressed',
  'keyreleased',
  'textinput',
}

local _pointer = {
  'mousemoved',
  'mousepressed',
  'mousereleased',
  'wheelmoved',

  'touchmoved',
  'touchpressed',
  'touchreleased',
}

-- Derived events: not LÖVE's. The click timer in
-- set_love_update synthesises them from raw presses. They
-- travel gateway and route like native ones, so a project reads
-- through compy.input.hooks like anything else. They stay a
-- named subset only because the timer needs to know which
-- events it synthesises — never to decide how one is bound.
local _derived = {
  'singleclick',
  'doubleclick',
}

local _supported = {}
for _, k in ipairs(_keyboard) do
  table.insert(_supported, k)
end
for _, k in ipairs(_pointer) do
  table.insert(_supported, k)
end

-- Every channel a project can bind, native and derived. One
-- list, because seeding, teardown and dispatch have to agree
-- about what a channel is, and three hand-kept subsets did not:
-- a project writing love.singleclick got nothing, while the
-- same project writing love.mousepressed got a seeded hook.
local _bindable = {}
for _, k in ipairs(_supported) do
  table.insert(_bindable, k)
end
for _, k in ipairs(_derived) do
  table.insert(_bindable, k)
end

--- @param CC ConsoleController
--- @param msg string
local function user_error_handler(CC, msg)
  Log.debug('user error: ' .. msg)
  local err = LANG.get_call_error(msg) or ''
  local user_msg = messages.exec_error(err)
  CC:suspend_run(user_msg)
  print(user_msg)
end

--- @param f function
--- @param CC ConsoleController
--- @param ...   any
--- @return boolean success
--- @return any result
--- @return any ...
-- The message handler MUST be a closure binding CC: xpcall
-- calls it with exactly one argument (the error), so passing
-- user_error_handler directly bound CC to the error string,
-- left msg nil, and raised inside the handler — where xpcall
-- swallowed it, so a project raise vanished with no error
-- window at all (doc/development/technical_debt/input.md,
-- "`wrap`'s error handler is called with the wrong arity").
local function wrap(f, CC, ...)
  local function on_error(msg)
    user_error_handler(CC, msg)
  end
  if _G.web then
    -- DO NOT collapse this branch into the xpcall below. It is
    -- not a stylistic duplicate: `xpcall(f, h, ...)` passing
    -- arguments to `f` is a LuaJIT/5.2 extension, and PUC Lua
    -- 5.1 — what the Web build runs — takes exactly two
    -- arguments and drops the rest, so every handler would be
    -- called with nil for all of its parameters. pcall passes
    -- them on both runtimes. `_G.web` is set from
    -- OS.get_name() == 'Web' (main.lua).
    local ok, r = pcall(f, ...)
    if not ok then
      on_error(r)
    end
    -- `ok, r`, not bare `r`: this branch used to answer with a
    -- lone value while the other answered xpcall's tuple, and
    -- every caller discarded the result so nothing caught it.
    -- What the branches now share is the FIRST TWO values,
    -- which is all any caller reads (project_handler takes
    -- `ok, res`, dropping `res` when `ok` is false). The tails
    -- differ and deliberately are not reconciled: xpcall
    -- forwards every return of `f` where pcall is captured to
    -- one here, and on failure xpcall yields `false, nil`
    -- against this branch's `false, <error>`.
    return ok, r
  else
    return xpcall(f, on_error, ...)
  end
end

--- Run `fn` the way project code must always be run: drawing
--- routed onto the project's canvas, errors routed to the
--- project error handler, return value propagated.
---
--- Applied where a route is ENTERED, not around each chain
--- participant: the walk carries no error handling of its own,
--- so wrapping participants left a raise in `shortcuts[...]`
--- or a directly-assigned `hooks[...]` escaping the chain, and
--- made a raise in the widget look like "did not consume", so
--- the walk carried on past it.
--- @param CC ConsoleController
--- @param fn function
--- @return function
local function with_canvas_and_errors(CC, fn)
  return function(...)
    local args = { ... }
    return CC:use_canvas(function()
      local ok, res = wrap(fn, CC, unpack(args))
      if ok then return res end
    end)
  end
end

--- The project's own handler for an event, raw; nil when the
--- project did not define one. NOT wrapped — the boundary
--- covers it once the route is entered, which is what makes a
--- seeded handler an ordinary chain participant rather than a
--- specially-protected one (doc/development/decisions/input.md,
--- Decision 10).
---
--- The guard is load-bearing, not ceremony: without it a
--- project that never overrode an event seeds `hooks[event]`
--- with the framework's own default, which would then run as
--- if it were the project's.
---
--- Early return rather than an `if` around the body: an `if`
--- would nest what follows a level deeper.
--- @param userlove table
--- @param key string
--- @return function? handler
local function project_handler(userlove, key)
  local new = userlove[key]
  if not new or new == Controller._defaults[key] then return end
  return new
end

--- The project's own keyboard/text handlers, for seeding as
--- hooks[event] (doc/development/decisions/input.md,
--- Decision 10) — raw, so a seeded hook is an ordinary chain
--- participant: it consumes on truthy and falls through on
--- falsey exactly like one the project assigned itself.
--- @param userlove table
--- @param CC ConsoleController
--- @return table handlers
local function project_handlers(userlove, CC)
  local out = {}
  for _, k in ipairs(_bindable) do
    out[k] = project_handler(userlove, k)
  end
  return out
end


--- The project route occupies the keyboard/text handlers for
--- the run; the project's own handlers ride along for
--- delegation (never route owners themselves).
--- @param userlove table
--- @param CC ConsoleController
-- `userlove`: the project's sandboxed `love` table. `occupy`:
-- take over the keyboard/text handlers for the project route's
-- run (doc/development/decisions/input.md Decision 11 uses
-- this verb). Giving the project route
-- its own connect path — not a generic route swap — is
-- deliberate: the three routes are not yet fully symmetric
-- (the editor is still reached via the console fork), so PIC
-- is wired explicitly here. See doc/development/decisions/input.md #1
-- "route-centric routing" + #11 "route connects only while
-- running". It installs even with no project handlers: an
-- unhandled event must stop in the project route, never reach the
-- hidden console. (`userlove` rename: technical_debt.)
local function occupy_input(userlove, CC)
  local pic = Controller.project_input
  local compy = CC:get_project_env().compy
  pic:activate(project_handlers(userlove, CC), compy.input)
  -- with_canvas_and_errors here, not around each participant:
  -- route IS the boundary, so every tier of the walk runs with
  -- the project canvas bound and one error handler above it.
  -- Wrapped (not assigned) to bind `pic` as method receiver:
  -- `love.keypressed = pic.keypressed` would drop `self`.
  for _, k in ipairs(_bindable) do
    love[k] = with_canvas_and_errors(CC, function(...)
      return pic[k](pic, ...)
    end)
  end
end

--- `user_pointer` marks a non-blocking project as still
--- interactive, so it keeps the route in 'project_open'
--- (doc/development/technical_debt/input.md, ruling (a)). Set
--- from the project's own pointer handlers and its click hooks.
--- @param userlove table
--- @param CC ConsoleController
local function mark_pointer_liveness(userlove, CC)
  for _, k in ipairs(_pointer) do
    if project_handler(userlove, k) then
      user_pointer = true
    end
  end
  -- Runs after occupy_input, so the hooks table is already
  -- seeded, so a click hook the project set in top-level code
  -- is visible here.
  local hooks = CC:get_project_env().compy.input.hooks
  for _, k in ipairs(_derived) do
    if hooks[k] then user_pointer = true end
  end
end

--- @param userlove table
local function hook_update(userlove)
  local up = userlove.update
  if up and up ~= Controller._defaults.update then
    user_update = true
    Controller._userhandlers.update = up
  end
end

--- @param userlove table
local function hook_draw(userlove)
  local udr = userlove.draw
  local mdr = View.main_draw
  if udr and udr ~= mdr then
    --- @diagnostic disable-next-line: duplicate-set-field
    local ndr = function()
      udr()
      View.drawFPS()
    end
    love.draw = ndr
    user_draw = true
  end
end

-- `userlove` = the project's sandboxed `love` table 
-- (also used in occupy_* and hook_* above); 
--- @param userlove table
--- @param CC ConsoleController
local set_handlers = function(userlove, CC)
  occupy_input(userlove, CC)
  mark_pointer_liveness(userlove, CC)
  hook_update(userlove)
  hook_draw(userlove)
end

-- Teardown clears every bindable channel: else a stopped
-- project's pointer hook survives and blocks the NEXT project's
-- seeding (seed_hooks fills only a nil slot). Decision 11's
-- teardown invariant covers all of them.
local HOOK_EVENTS = _bindable

--- @param t table
local function wipe_table(t)
  for k in pairs(t) do rawset(t, k, nil) end
end

--- Teardown of the project's compy.input registrations
--- (doc/development/decisions/input.md, Decision 11): clears the
--- project's shortcuts and hooks. The callbacks table lives on the
--- widget and is re-seeded by reset_widget_outputs (below), so it
--- is not touched here. Reaches through the frozen container's
--- sub-tables — the container itself refuses direct writes
--- (Decision 7).
--- @param CC ConsoleController
local function reset_compy_input(CC)
  local input = CC:get_project_env().compy.input
  -- Driven by the channel lists, not by iterating the surface:
  -- `shortcuts` and `hooks` are metatable proxies over private
  -- state, so `pairs` on them yields nothing. Every channel that
  -- can hold something is named in a list, and the list is what
  -- teardown walks.
  for _, ev in ipairs(_bindable) do
    wipe_table(input.shortcuts[ev])
  end
  for _, ev in ipairs(HOOK_EVENTS) do input.hooks[ev] = nil end
end

--- Teardown of the widget's own output/callback state on project
--- stop (Decision 11): re-seed the callbacks to their stay-open
--- defaults (AC10 — not a wipe-to-nil) and clear the evaluator's
--- highlighter.
local function reset_widget_outputs()
  local ui = love.state.user_input_controller
  if not ui then return end
  ui:reset_callbacks()
  if ui.model and ui.model.evaluator then
    ui.model.evaluator.highlighter = nil
  end
end

local click_delay = 0.4
local drift_tolerance = 2.5

local click_count = 0
local click_timer = 0
--- @type Point?
local click_pos = nil

--- @param prev Point?
--- @param cur Point?
--- @return boolean
local function no_drift(prev, cur)
  if prev and cur
  then
    local px, py = prev.x, prev.y
    local cx, cy = cur.x, cur.y
    if px and cx and math.abs(px - cx) < drift_tolerance
    then
      if py and cy and math.abs(py - cy) < drift_tolerance
      then
        return true
      end
    end
  end
  return false
end

-- Shared l/r modifier-fold table (see util/key.lua mod_triples): rows of
-- { left-key, right-key, generic-name } in precedence order.
local COMBO_MODS = Key.mod_triples


-- The device question behind each modifier row. Key exports one
-- helper per generic name and each folds its own l/r pair, so a
-- row is answered by one call rather than two lookups.
local MOD_HELD = {
  ctrl  = Key.ctrl,
  alt   = Key.alt,
  shift = Key.shift,
}

-- A reservation matches its modifier set exactly: the named
-- modifiers held, and no other (doc/development/decisions/
-- input.md, Decision 33).
-- `not not` normalises: `Key`'s own `@return boolean` is not
-- enforced for every isDown patcher (technical_debt/input.md,
-- "A modifier accessor answers truthy/falsy, not a boolean").
local function only_mods(ctrl, alt, shift)
  return (not not Key.ctrl()) == ctrl
      and (not not Key.alt()) == alt
      and (not not Key.shift()) == shift
end

--- Serialise a key event into a canonical combo string ("ctrl+s", "alt+shift+f4").
--- Held modifiers are prepended in COMBO_MODS precedence, l/r folded to generic names,
--- and come from the keyboard itself (doc/development/decisions/input.md, Decision 30).
--- NOTE: the per-keypress table allocation here is an open design
--- question (doc/development/technical_debt/input.md, "Combo-string dispatch
--- allocates a table per call").
--- @param k string            triggering key (raw LÖVE name)
--- @return string             canonical combo string
local function combo_string(k)
  local parts = { }
  for _, m in ipairs(COMBO_MODS) do
    if MOD_HELD[m[3]]() then
      parts[#parts + 1] = m[3]
    end
  end
  parts[#parts + 1] = k
  return table.concat(parts, '+')
end

--- Is any modifier held? The cheap pre-check the triggerless
--- (pointer) shortcut lookup runs before building a combo
--- string, so an unmodified motion event allocates nothing.
--- @return boolean
local function any_mod()
  for _, m in ipairs(COMBO_MODS) do
    if MOD_HELD[m[3]]() then
      return true
    end
  end
  return false
end

--- @class Controller
--- @field _defaults Handlers
--- @field _userhandler Handlers
--- public interface
--- @field set_love_draw function
--- @field setup_callback_handlers function
--- @field set_default_handlers function
--- @field save_user_handlers function
--- @field clear_user_handlers function
--- @field restore_user_handlers function
--- @field user_is_blocking function
-- Every console channel except keypressed forwards its
-- arguments to the console controller and does nothing else.
-- Nine copies of the same three lines were nine chances for
-- one to drift, and
-- their per-event @param blocks documented LÖVE's signatures
-- rather than anything this code decides.
--- @param event string
--- @return function
local function console_channel(event)
  return function(CC)
    local function handler(...)
      return CC[event](CC, ...)
    end
    Controller._defaults[event] = handler
    love[event] = handler
  end
end

-- The derived clicks get no console installer: the console does
-- not use them, so releasing them means emptying the slot.
-- The keyboard channels the console installs generically:
-- keypressed is excluded, it has debug hotkeys of its own.
local _keyboard_rest = { 'keyreleased', 'textinput' }

local _console_channels = { }
for _, k in ipairs(_keyboard_rest) do
  table.insert(_console_channels, k)
end
for _, k in ipairs(_pointer) do
  table.insert(_console_channels, k)
end

Controller = {
  --- @private
  -- Console defaults, per channel. The derived clicks have none:
  -- nothing occupies them outside a project run, so anything a
  -- project's sandboxed love table holds there is the project's
  -- own and seeds a hook (project_handler).
  _defaults = { },
  --- @private
  _userhandlers = {},

  combo_string = combo_string,
  any_mod = any_mod,

  ----------------
  --  keyboard  --
  ----------------
  --- @private
  --- @param CC ConsoleController
  set_love_keypressed = function(CC)
    local function keypressed(k, _, isr)
      -- TODO(debt): these debug-hotkey if-blocks predate combos;
      -- migrate onto the combo-table mechanism
      -- (doc/development/decisions/input.md, Decision 8). See
      -- doc/development/technical_debt/input.md "Console debug hotkeys are ad-hoc".
      if Key.ctrl() and Key.shift() then
        if love.DEBUG then
          if k == "1" then
            table.toggle(love.debug, 'show_terminal')
            table.toggle(love.debug, 'show_buffer')
          end
          if k == "2" then
            table.toggle(love.debug, 'show_snapshot')
          end
          if k == "3" then
            table.toggle(love.debug, 'show_canvas')
          end
          if k == "5" then
            table.toggle(love.debug, 'show_input')
          end
        end
      end
      if Key.ctrl() and Key.alt() then
        if love.DEBUG then
          if k == "d" then
            Log.debug(Debug.termdebug(CC.model.output.terminal))
          end
        end
      end
      ---> comment describing what code does NOT do is absolutely of no use; delete if it has no positive info
      -- Straight to the console, with no widget test in front of
      -- it: widget visibility is state on the widget, never a
      -- routing condition (doc/development/decisions/input.md,
      -- Decision 1). A project overlay is reached inside the
      -- PROJECT route's chain, and the console never holds the
      -- slot while one is up.
      CC:keypressed(k)
    end
    Controller._defaults.keypressed = keypressed
    love.keypressed = keypressed
  end,

  --------------
  --  update  --
  --------------
  --- @private
  --- @param CC ConsoleController
  set_love_update = function(CC)
    local function update(dt)
      if love.PROFILE then
        Prof.update()
      end
      if click_timer > 0 then
        click_timer = click_timer - dt
      end
      if click_timer <= 0 then
        -- Synthesis only: decide WHICH derived event the raw
        -- presses amount to, then emit it through the gateway
        -- like any native one. Who receives it, whether it is
        -- error-wrapped and whether anyone consumes it are the
        -- route's business, not this timer's.
        local derived
        if click_count == 1 then
          derived = 'singleclick'
        elseif click_count >= 2 then
          derived = 'doubleclick'
        end
        -- Drift discards the click outright rather than
        -- degrading it to presses: moving between the two
        -- invalidates both (doc/input_api.md, "Pointer and
        -- click hooks"). A project that wants the raw
        -- presses binds mousereleased, which is untouched.
        if derived then
          local x, y = love.mouse.getPosition()
          if no_drift(click_pos, { x = x, y = y }) then
            love.handlers[derived](x, y)
          end
        end
        click_count = 0
      end

      local ddr = View.prev_draw
      local ldr = love.draw
      if ldr ~= ddr then
        local draw = function()
          if ldr then
            gfx.push('all')
            wrap(ldr, CC)
            gfx.pop()
          end
          local ui = get_user_input()
          if ui then
            ui.V:draw()
          end
        end

        View.prev_draw = draw
        love.draw = draw
      end
      CC:pass_time(dt)

      local uup = Controller._userhandlers.update
      if user_update and uup
      then
        CC:use_canvas(function()
          wrap(uup, CC, dt)
        end)
      end
      if love.state.app_state == 'snapshot' then
        gfx.captureScreenshot(function(img)
          local snap = gfx.newImage(img)
          View.snapshot = snap
          CC:suspend()
        end)
      end

      if love.harmony then
        love.harmony.timer_update(dt)
      end
    end

    if not Controller._defaults.update then
      Controller._defaults.update = update
    end
    love.update = update
  end,

  ---------------
  --    draw   --
  ---------------
  --- @private
  --- @param CC ConsoleController
  --- @param CV ConsoleView
  set_love_draw = function(CC, CV)
    -- The overlay is painted on top of the console frame, mirroring
    -- what set_love_update's wrapper does on top of a PROJECT frame.
    -- Both paths are needed: the wrapper installs only when a project
    -- replaces love.draw, so a project that hooks no draw at all (an
    -- input-only one — technical_debt/input.md, ruling (a)) would
    -- otherwise show a widget that takes keystrokes and paints
    -- nothing. get_user_input() carries the inspect gate, so the
    -- suspended project's widget stays unhonoured (Decision 12).
    local function draw()
      View.draw(CC, CV)
      local ui = get_user_input()
      if ui then ui.V:draw() end
      View.drawFPS()
    end
    love.draw = draw

    View.prev_draw = love.draw
    View.main_draw = love.draw
    View.end_draw = function()
      local w, h = gfx.getDimensions()
      gfx.setColor(Color[Color.white])
      gfx.setFont(CC.cfg.view.font)
      gfx.clear()
      gfx.printf(messages.exit_anykey, 0, h / 3, w, "center")
    end
  end,


  --- Quit
  --- @private
  --- @param CC ConsoleController
  set_love_quit = function(CC)
    local cfg = CC.cfg

    local function quit()
      if love.state.app_state == 'shutdown' then
        return false
      end

      if cfg.mode == 'play' then
        CC:quit_project()
        love.state.app_state = 'shutdown'
        love.state.user_input = nil

        love.draw = View.end_draw
        return true
      end
      -- A running project stops to the console. So does the
      -- corner case: a paper-and-pen style project that is
      -- still interactive (input widget shown or pointer
      -- handlers installed — doc/development/technical_debt/input.md,
      -- "Input-only / pointer-only projects stay live in
      -- `project_open` (RESOLVED, ruling a)"). An idle
      -- console in project_open falls through: the app quits.
      if love.state.app_state == 'running'
          or (love.state.app_state == 'project_open'
              and Controller.user_is_interactive()) then
        CC:stop_project_run()
        return true
      end
    end
    love.quit = quit
  end,

  ----------------
  ---  public  ---
  ----------------
  --- Hand keyboard/text back to the console at the moment a
  --- project's code finishes running but the project stays
  --- open (the 'running' -> 'project_open' state change —
  --- doc/development/decisions/input.md, Decision 11). Pointer handlers
  --- stay hooked until the project stops (same decision).
  --- @param CC ConsoleController
  release_keyboard_route = function(CC)
    Controller.project_input:deactivate()
    Controller.set_love_keypressed(CC)
    for _, k in ipairs(_keyboard_rest) do
      Controller['set_love_' .. k](CC)
    end
    -- The derived click slots have no console occupant to
    -- restore, the console not using them, so releasing means
    -- emptying them. Left set they would keep pointing at a
    -- deactivated route.
    for _, k in ipairs(_derived) do
      love[k] = nil
    end
  end,

  --- @param CC ConsoleController
  --- @param CV ConsoleView
  set_default_handlers = function(CC, CV)
    -- When the project route lets go of the keyboard/text
    -- callbacks they always return to the console: it is the
    -- default/restore route (doc/development/decisions/input.md #1), so the
    -- release must precede reinstalling the console below.
    -- The only console/PIC tie is this restore ordering +
    -- inspect suppression (doc/development/decisions/input.md #11/#12) — not
    -- a special-case beyond that.
    Controller.project_input:deactivate()

    -- SKIPPED textedited - IME support, TODO?
    Controller.set_love_keypressed(CC)
    for _, k in ipairs(_console_channels) do
      Controller['set_love_' .. k](CC)
    end

    --- SKIPPED joystick and gamepad support

    --- intented to run as kiosk app
    --- SKIPPED focus
    --- SKIPPED mousefocus
    --- SKIPPED visible
    --- SKIPPED resize
    --- SKIPPED filedropped
    --- SKIPPED directorydropped

    --- target device has laptop form factor, hence disabled
    --- SKIPPED displayrotated

    --- SKIPPED threaderror
    --- SKIPPED lowmemory

    -- reset the user-handler presence flags, then (re)install
    -- the console's update/draw/quit as the love defaults.
    user_update = false
    Controller.set_love_update(CC)
    user_draw = false
    user_pointer = false
    for _, k in ipairs(_derived) do
      love[k] = nil
    end
    Controller.set_love_draw(CC, CV)
    Controller._defaults.draw = View.main_draw
    Controller.set_love_quit(CC)
  end,

  --- @param CC ConsoleController
  setup_callback_handlers = function(CC)
    local cfg = CC.cfg
    local playback = cfg.mode == 'play'

    --- @diagnostic disable-next-line: undefined-field
    local handlers = love.handlers

    handlers.keypressed = function(k, sc, isr)
      --- Power shortcuts
      local function quickswitch()
        if only_mods(true, false, false) and k == 't' then
          if love.state.app_state == 'running'
              or love.state.app_state == 'inspect'
              or love.state.app_state == 'project_open'
          then
            CC:stop_project_run()
            local st = love.state.editor
            if st then
              CC:edit(st.buffer.filename, st)
            else
              CC:edit()
            end
          elseif love.state.app_state == 'editor' then
            if CC.editor:is_normal_mode() then
              local ed_state = CC:finish_edit()
              love.state.editor = ed_state
              CC:run_project()
            end
          end
        end
      end
      local function project_state_change()
        if only_mods(true, false, false) then
          if k == "pause" then
            CC:suspend_run(messages.user_break)
          end
          if k == "q" then
            CC:quit_project()
          end
        end
        if only_mods(true, false, false) and k == "s" then
          if love.state.app_state == 'running' then
            CC:stop_project_run()
          end
        end
        if only_mods(true, false, true) then
          --- Ensure the user can get back to the console
          if k == "r" then
            CC:reset()
          end
        end
      end
      local function restart()
        if only_mods(true, true, false) and k == "r" then
          CC:restart()
        end
      end
      local function profile()
        if Key.ctrl() and Key.alt() and k == "p" then
          if Key.shift() then
            Prof.stop_profiler()
          else
            -- Prof.start_profiler()
            Prof.start_oneshot()
          end
        end
        if k == "f10" and only_mods(false, false, false) then
          if love.PROFILE.fpsc == 'off' then
            love.PROFILE.fpsc = 'T_L_B'
          elseif love.PROFILE.fpsc == 'T_L_B' then
            love.PROFILE.fpsc = 'T_R_B'
          elseif love.PROFILE.fpsc == 'T_R_B' then
            love.PROFILE.fpsc = 'T_L'
          elseif love.PROFILE.fpsc == 'T_L' then
            love.PROFILE.fpsc = 'T_R'
          elseif love.PROFILE.fpsc == 'T_R' then
            love.PROFILE.fpsc = 'off'
          end
        end
      end

      if playback then
        if love.state.app_state == 'shutdown' then
          love.event.quit()
        end
        restart()
        if love.PROFILE then
          profile()
        end
      else
        restart()
        quickswitch()
        if love.PROFILE then
          profile()
        end
        project_state_change()
      end

      -- This is `love.handlers.keypressed`, the raw
      -- event-pump entry; `love.keypressed` below holds the
      -- active route's handler (console via
      -- set_love_keypressed, project via occupy_keyboard).
      -- Forwarding = invoke whichever route is installed.
      -- Widgets are reached inside the route, never gated
      -- here. (Mirrors stock LÖVE's love.handlers[name] ->
      -- love[name].) See doc/development/decisions/input.md #1
      -- "route-centric routing" + #11.
      if love.keypressed then
        return love.keypressed(k, sc, isr)
      end
    end

    handlers.textinput = function(t)
      if love.textinput then
        return love.textinput(t)
      end
    end

    handlers.keyreleased = function(k, sc)
      if only_mods(true, false, false) and k == "escape" then
        love.event.quit()
      end
      if love.keyreleased then
        return love.keyreleased(k, sc)
      end
    end

    --- @param x integer
    --- @param y integer
    --- @param btn integer
    --- @param touch boolean
    --- @param presses number
    -- The gateway entry: hand the event to whoever occupies
    -- the slot. Under a project run that is the project
    -- route's chain; otherwise the console's own handler.
    handlers.mousepressed = function(x, y, btn, touch, presses)
      if love.mousepressed then
        return love.mousepressed(x, y, btn, touch, presses)
      end
    end

    --- @param x integer
    --- @param y integer
    --- @param btn integer
    --- @param touch boolean
    --- @param presses number
    handlers.mousereleased = function(x, y, btn, touch, presses)
      if btn == 1 then
        click_count = click_count + 1
        click_timer = click_delay
        click_pos = { x = x, y = y }
      end
      if love.mousereleased then
        return love.mousereleased(x, y, btn, touch, presses)
      end
    end

    --- @param x number
    --- @param y number
    --- @param dx number
    --- @param dy number
    --- @param touch boolean
    handlers.mousemoved = function(x, y, dx, dy, touch)
      if love.mousemoved then
        return love.mousemoved(x, y, dx, dy, touch)
      end
    end

    -- Wheel had no entry of compy's own until 2026-08-03. It
    -- still reached a project, but by accident: this function
    -- writes INTO love.handlers rather than replacing it, so
    -- LÖVE's stock wheelmoved survived and called
    -- love.wheelmoved. Declaring it makes the gateway
    -- self-contained instead of depending on that, and puts
    -- wheel on the same footing as every other pointer channel.
    --- @param x number
    --- @param y number
    handlers.wheelmoved = function(x, y)
      if love.wheelmoved then
        return love.wheelmoved(x, y)
      end
    end

    -- Derived click events, synthesised by the click timer in
    -- set_love_update. Same shape as every native entry above:
    -- hand it to whatever occupies the slot, and skip when
    -- nothing does. The console and editor do not use them, so
    -- on those routes the slot is simply empty.
    for _, name in ipairs(_derived) do
      handlers[name] = function(x, y)
        if love[name] then return love[name](x, y) end
      end
    end

    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    handlers.touchpressed = function(id, x, y, dx, dy, pressure)
      if love.touchpressed then
        return love.touchpressed(id, x, y, dx, dy, pressure)
      end
    end

    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    handlers.touchreleased = function(id, x, y, dx, dy, pressure)
      if love.touchreleased then
        return love.touchreleased(id, x, y, dx, dy, pressure)
      end
    end

    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    handlers.touchmoved = function(id, x, y, dx, dy, pressure)
      if love.touchmoved then
        return love.touchmoved(id, x, y, dx, dy, pressure)
      end
    end


    --- @diagnostic disable-next-line: undefined-field
    table.protect(love.handlers)
  end,

  set_user_handlers = set_handlers,

  user_is_blocking = function()
    return (user_update or user_draw)
  end,

  --- A non-blocking project is still "live" while it
  --- has an active input overlay or a pointer/click handler — it
  --- keeps the project route and Ctrl+Esc returns to the console.
  user_is_interactive = function()
    return (love.state.user_input ~= nil) or user_pointer
  end,

  --- @param userlove table
  save_user_handlers = function(userlove)
    --- @param key string
    local function save_if_differs(key)
      local orig = Controller._defaults[key]
      local new = userlove[key]
      if orig and new and orig ~= new then
        Controller._userhandlers[key] = new
      end
    end

    -- input hooks
    for _, a in pairs(_supported) do
      save_if_differs(a)
    end

    save_if_differs('draw')
  end,

  --- @param CC ConsoleController
  restore_user_handlers = function(CC)
    set_handlers(Controller._userhandlers, CC)
  end,

  --- @param CC ConsoleController?
  clear_user_handlers = function(CC)
    Controller._userhandlers = {}
    View.clear_snapshot()
    if not CC then return end
    reset_compy_input(CC)
    reset_widget_outputs()
  end,

  oneshot = function()
    if not love.PROFILE then return end
    Prof.start_oneshot()
  end,

  report = function()
    if not love.PROFILE then return end
    local report = Prof.report()
    if report then
      Log.debug(report)
    end
  end,
}

for _, k in ipairs(_console_channels) do
  Controller['set_love_' .. k] = console_channel(k)
end

Controller.project_input = ProjectInputController()
