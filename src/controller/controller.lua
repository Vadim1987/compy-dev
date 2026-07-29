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


--- REVIEW: why separate function for every forwarder, not generic one, with event name as payload?
--- REVIEW: why explicit work with ui.c instead of something like get_user_input().handle(event_name,k,held_keys,is_r) ?
--- REVIEW: why returning strict 'true' instead of returning whatever handler returns?
--- Intra-route forward: the console route hands the event
--- to the widget it activated (nil under 'inspect' — the
--- console owns that surface itself). The widget receives the
--- uniform per-channel signature with the read-only
--- pressed-keys view (doc/development/decisions/input.md, Decision 9 and
--- Decision 13). Returns whether the
--- widget was the surface (true = forwarded), so the caller
--- falls back to the console line only when no widget is up.
--- @param k string
--- @param isr boolean?
--- @return boolean forwarded
local function forward_keypressed(k, isr)
  local ui = get_user_input()
  if not ui then return false end
  ui.C:keypressed(k, Controller.held_keys(), isr)
  return true
end

--- @param t string
--- @return boolean forwarded
local function forward_textinput(t)
  local ui = get_user_input()
  if not ui then return false end
  ui.C:textinput(t, Controller.held_keys())
  return true
end

--- @param k string
--- @return boolean forwarded
local function forward_keyreleased(k)
  local ui = get_user_input()
  if not ui then return false end
  ui.C:keyreleased(k, Controller.held_keys())
  return true
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


-- keyboard/text and pointer are split: different install
-- paths AND lifecycles. Keyboard/text events run the
-- three-consumer chain (shortcuts -> hooks -> widget) and
-- return to the console at running->project_open; pointer
-- handlers are error-wrapped
-- straight into love.* and stay hooked until the project
-- stops. The widget-lockout problem only ever existed on
-- keyboard/text; pointer was deliberately left as-is. See
-- doc/development/decisions/input.md #11 "route connects only while running"
-- (which forbids unifying the two lifecycles). Pointer
-- delivery itself: see the debt note referenced at
-- handlers.mousepressed below.
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

local _supported = {}
for _, k in ipairs(_keyboard) do
  table.insert(_supported, k)
end
for _, k in ipairs(_pointer) do
  table.insert(_supported, k)
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
local function wrap(f, CC, ...)
  if _G.web then
    local ok, r = pcall(f, ...)
    if not ok then
      user_error_handler(CC, r)
    end
    return r
  else
    return xpcall(f, user_error_handler, ...)
  end
end

--- REVIEW: `key` is ambiguous -- use 'handlername' or whatever semantically meaningful?
--- The project's own handler for an event, error-wrapped;
--- nil when the project did not define one. "Native" here
--- and below = a handler the project installed in its own
--- sandboxed love table (passed in as `userlove`). The wrap
--- routes errors to the project error handler; the return
--- value is discarded, which suits fire-and-forget pointer
--- handlers — chain_native below is the variant for chain
--- participants, which must keep the return.
--- @param userlove table
--- @param CC ConsoleController
--- @param key string
--- @return function? wrapped
local function wrapped_native(userlove, CC, key)
  local orig = Controller._defaults[key]
  local new = userlove[key]
  if orig and new and orig ~= new then
    return CC:wrap_handler(new, wrap)
  end
end

--- Wrap a project keyboard handler for the dispatch chain:
--- run it with project error handling, drawing routed onto
--- the project's canvas (CC:use_canvas — the offscreen
--- surface project draws land on), AND propagate its return
--- value — the chain's truthy=consume contract depends on it
--- (doc/development/decisions/input.md, Decision 2: return-propagation).
--- A raised error routes to user_error_handler and the call
--- reports non-consuming (nil).
--- @param CC ConsoleController
--- @param fn function
--- @return function
local function chain_native(CC, fn)
  return function(...)
    local args = { ... }
    return CC:use_canvas(function()
      local ok, res = xpcall(fn, function(m)
        user_error_handler(CC, m)
      end, unpack(args))
      if ok then return res end
    end)
  end
end

--- @param userlove table
--- @param CC ConsoleController
--- @param key string
--- @return function?
local function keyboard_native(userlove, CC, key)
  local orig = Controller._defaults[key]
  local new = userlove[key]
  if orig and new and orig ~= new then
    return chain_native(CC, new)
  end
end

--- The project's own keyboard/text handlers, error-wrapped for
--- seeding as hooks[event] (doc/development/decisions/input.md,
--- Decision 10 revised: pure wrap) — return values
--- preserved so a seeded hook can consume like any participant.
--- @param userlove table
--- @param CC ConsoleController
--- @return table handlers
local function project_handlers(userlove, CC)
  return {
    keypressed =
        keyboard_native(userlove, CC, 'keypressed'),
    textinput =
        keyboard_native(userlove, CC, 'textinput'),
    keyreleased =
        keyboard_native(userlove, CC, 'keyreleased'),
  }
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
-- hidden console. (`userlove`/`forward_*` renames: technical_debt.)
local function occupy_keyboard(userlove, CC)
  local pic = Controller.project_input
  local compy = CC:get_project_env().compy
  pic:activate(project_handlers(userlove, CC), compy.input)
  -- wrapped (not assigned) to bind `pic` as method receiver:
  -- `love.keypressed = pic.keypressed` would drop `self`.
  love.keypressed = function(k, sc, isr)
    return pic:keypressed(k, sc, isr)
  end
  love.textinput = function(t)
    return pic:textinput(t)
  end
  love.keyreleased = function(k)
    return pic:keyreleased(k)
  end
end

--- @param userlove table
--- @param CC ConsoleController
local function hook_pointer(userlove, CC)
  for _, k in ipairs(_pointer) do
    local w = wrapped_native(userlove, CC, k)
    if w then
      --- @type function
      love[k] = w
      user_pointer = true
    end
  end
  if CC:get_compy_handler('singleclick')
      or CC:get_compy_handler('doubleclick') then
    user_pointer = true
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
  occupy_keyboard(userlove, CC)
  hook_pointer(userlove, CC)
  hook_update(userlove)
  hook_draw(userlove)
end

local HOOK_EVENTS = { 'keypressed', 'keyreleased', 'textinput' }

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
--- (Decision 7 revised).
--- @param CC ConsoleController
local function reset_compy_input(CC)
  local input = CC:get_project_env().compy.input
  wipe_table(input.shortcuts.keypressed)
  wipe_table(input.shortcuts.keyreleased)
  wipe_table(input.shortcuts.textinput)
  for _, ev in ipairs(HOOK_EVENTS) do input.hooks[ev] = nil end
end

--- Teardown of the widget's own output/callback state on project
--- stop (Decision 11): re-seed the callbacks to their stay-open
--- defaults (AC10 — not a wipe-to-nil), and clear the legacy poll
--- reftable and the evaluator's highlighter.
local function reset_widget_outputs()
  local ui = love.state.user_input_controller
  if not ui then return end
  ui:reset_callbacks()
  ui.result = nil
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


--- REVIEW: from engineering perspective it would be more interesting to unwrap 'serialized' combo definitions (defined by project) into a chain of functions built-in-place, that would be applied to every keypress. building functions once per project load -- looks clear than building tables on every keypress (NOT TO IMPLEMENT NOW: put into tech debt ledger as suggestion)
--- Serialise a key event into a canonical combo string ("ctrl+s", "alt+shift+f4").
--- Held modifiers are prepended in COMBO_MODS precedence, l/r folded to generic names.
--- NOTE: the per-keypress table allocation here, and
--- whether dispatch should match on keys_pressed directly
--- instead of serialising, is an open design question
--- (doc/development/technical_debt/input.md, "Combo-string dispatch
--- allocates a table per call").
--- @param k string            triggering key (raw LÖVE name)
--- @param keys_pressed table  { keyname -> true } live held-key set
--- @return string             canonical combo string
local function combo_string(k, keys_pressed)
  local parts = { }
  for _, m in ipairs(COMBO_MODS) do
    if keys_pressed[m[1]] or keys_pressed[m[2]] then
      parts[#parts + 1] = m[3]
    end
  end
  parts[#parts + 1] = k
  return table.concat(parts, '+')
end

-- Memoised read-only view over Controller.keys_pressed handed to
-- every chain consumer (doc/development/decisions/input.md, Decision 13):
-- reads pass through to the
-- live held set; assignment raises. Rebuilt only when the backing
-- identity changes (tests swap the table wholesale), so dispatch
-- allocates nothing per event. NOTE: under LuaJIT/Lua 5.1 `pairs`
-- ignores __pairs, so iterating this view yields nothing on this
-- platform; the load-bearing contract (read-through + write-raise)
-- holds, and __pairs is kept for 5.2+ hosts.
local held_backing, held_proxy
local function held_keys()
  local backing = Controller.keys_pressed
  if held_backing ~= backing then
    held_backing = backing
    held_proxy = setmetatable({ }, {
      __index = backing,
      __newindex = function()
        error('keys_pressed is read-only', 2)
      end,
      __pairs = function() return pairs(backing) end,
    })
  end
  return held_proxy
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
Controller = {
  --- @private
  _defaults = {
    singleclick = function() end,
    doubleclick = function() end,
  },
  --- @private
  _userhandlers = {},

  keys_pressed = { },
  combo_string = combo_string,
  held_keys = held_keys,

  ----------------
  --  keyboard  --
  ----------------
  --- @private
  --- @param CC ConsoleController
  set_love_keypressed = function(CC)
    local function keypressed(k, _, isr)
      --- REVIEW: consider alternative combo-table mechanism
      --- (table on initialization used to build a chain of
      --- checkers)
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
      -- `forward_keypressed` routes to the active keyboard route
      -- (e.g. the editor fork) and returns whether it consumed;
      -- on consume we stop. Two-statement (not `or`-chained) form
      -- is deliberate: this is the terminal love-boundary, so the
      -- return is not propagated (LÖVE ignores handler returns).
      -- `forward_*` rename tracked in doc/development/technical_debt/input.md.
      if forward_keypressed(k, isr) then return end
      CC:keypressed(k)
    end
    Controller._defaults.keypressed = keypressed
    love.keypressed = keypressed
  end,

  --- @private
  --- @param CC ConsoleController
  set_love_keyreleased = function(CC)
    -- Same wrapper shape as keypressed above (terminal love-
    -- boundary, return not propagated). CC is the console — the
    -- named default/restore route (doc/development/decisions/input.md #1); not
    -- "special", just the default occupant. Per-event installer
    -- repetition + `forward_*` naming logged in technical_debt.
    --- @diagnostic disable-next-line: duplicate-set-field
    local function keyreleased(k)
      if forward_keyreleased(k) then return end
      CC:keyreleased(k)
    end
    Controller._defaults.keyreleased = keyreleased
    love.keyreleased = keyreleased
  end,

  --- @private
  --- @param CC ConsoleController
  set_love_textinput = function(CC)
    -- Same wrapper shape (see keypressed/keyreleased above);
    -- naming + table-driven install logged in technical_debt.
    local function textinput(t)
      if forward_textinput(t) then return end
      CC:textinput(t)
    end
    Controller._defaults.textinput = textinput
    love.textinput = textinput
  end,

  -------------
  --  mouse  --
  -------------
  --- @private
  --- @param CC ConsoleController
  set_love_mousepressed = function(CC)
    --- @param x number
    --- @param y number
    --- @param button number
    --- @param touch boolean
    --- @param presses number
    local function mousepressed(x, y, button, touch, presses)
      if love.DEBUG then
        Log.info(string.format('click! {%d, %d}', x, y))
      end
      CC:mousepressed(x, y, button, touch, presses)
    end

    Controller._defaults.mousepressed = mousepressed
    love.mousepressed = mousepressed
  end,

  --- @private
  --- @param CC ConsoleController
  set_love_mousereleased = function(CC)
    --- @param x number
    --- @param y number
    --- @param button number
    --- @param touch boolean
    --- @param presses number
    local function mousereleased(x, y, button, touch, presses)
      CC:mousereleased(x, y, button, touch, presses)
    end

    Controller._defaults.mousereleased = mousereleased
    love.mousereleased = mousereleased
  end,

  --- @private
  --- @param CC ConsoleController
  set_love_mousemoved = function(CC)
    --- @param x number
    --- @param y number
    --- @param dx number
    --- @param dy number
    --- @param touch boolean
    local function mousemoved(x, y, dx, dy, touch)
      CC:mousemoved(x, y, dx, dy, touch)
    end

    Controller._defaults.mousemoved = mousemoved
    love.mousemoved = mousemoved
  end,

  --- @private
  --- @param CC ConsoleController
  set_love_wheelmoved = function(CC)
    --- @param x number
    --- @param y number
    local function wheelmoved(x, y)
      CC:wheelmoved(x, y)
    end

    Controller._defaults.wheelmoved = wheelmoved
    love.wheelmoved = wheelmoved
  end,

  -------------
  --  touch  --
  -------------
  --- @private
  --- @param CC ConsoleController
  set_love_touchpressed = function(CC)
    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    local function touchpressed(id, x, y, dx, dy, pressure)
      CC:touchpressed(id, x, y, dx, dy, pressure)
    end

    Controller._defaults.touchpressed = touchpressed
    love.touchpressed = touchpressed
  end,
  --- @private
  --- @param CC ConsoleController
  set_love_touchreleased = function(CC)
    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    local function touchreleased(id, x, y, dx, dy, pressure)
      CC:touchreleased(id, x, y, dx, dy, pressure)
    end

    Controller._defaults.touchreleased = touchreleased
    love.touchreleased = touchreleased
  end,
  --- @private
  --- @param CC ConsoleController
  set_love_touchmoved = function(CC)
    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    local function touchmoved(id, x, y, dx, dy, pressure)
      CC:touchmoved(id, x, y, dx, dy, pressure)
    end

    Controller._defaults.touchmoved = touchmoved
    love.touchmoved = touchmoved
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
        if click_count == 1 then
          -- single click confirmed after delay
          local handler = CC:get_compy_handler('singleclick')
          if handler then
            local h = CC:wrap_handler(handler, wrap)
            local x, y = love.mouse.getPosition()
            local cur = { x = x, y = y }
            if no_drift(click_pos, cur) then
              h(x, y)
            end
          end
        elseif click_count >= 2 then
          -- double click detected
          local dbl_handler =
              CC:get_compy_handler('doubleclick')
          if dbl_handler then
            local h = CC:wrap_handler(dbl_handler, wrap)
            local x, y = love.mouse.getPosition()
            local cur = { x = x, y = y }
            if no_drift(click_pos, cur) then
              h(x, y)
            end
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
    local function draw()
      View.draw(CC, CV)
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
    Controller.set_love_keyreleased(CC)
    Controller.set_love_textinput(CC)
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

    -- TODO(debt): these ten near-identical set_love_* installers
    -- could be driven from a { event -> installer } table. See
    -- doc/development/technical_debt/input.md "Per-event set_love_* installers".
    Controller.set_love_keypressed(CC)
    Controller.set_love_keyreleased(CC)
    Controller.set_love_textinput(CC)
    -- SKIPPED textedited - IME support, TODO?

    Controller.set_love_mousemoved(CC)
    Controller.set_love_mousepressed(CC)
    Controller.set_love_mousereleased(CC)
    Controller.set_love_wheelmoved(CC)

    Controller.set_love_touchpressed(CC)
    Controller.set_love_touchreleased(CC)
    Controller.set_love_touchmoved(CC)

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
    Controller.set_love_draw(CC, CV)
    Controller._defaults.draw = View.main_draw
    Controller.set_love_quit(CC)
  end,

  --- @param CC ConsoleController
  setup_callback_handlers = function(CC)
    local cfg = CC.cfg
    local playback = cfg.mode == 'play'

    local clear_user_input = function()
      love.state.user_input = nil
    end

    --- @diagnostic disable-next-line: undefined-field
    local handlers = love.handlers

    -- REVIEW: what is 'sc' ? meaningless name
    handlers.keypressed = function(k, sc, isr)
      Controller.keys_pressed[k] = true
      --- Power shortcuts
      local function quickswitch()
        if Key.ctrl() and not Key.alt() and k == 't' then
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
        if Key.ctrl() then
          if k == "pause" then
            CC:suspend_run(messages.user_break)
          end
          if k == "q" then
            CC:quit_project()
          end
          if k == "s" then
            if love.state.app_state == 'running' then
              CC:stop_project_run()
            elseif love.state.app_state == 'editor' then
              if Key.shift() then
                CC:finish_edit()
              else
                CC:close_buffer()
              end
            end
          end
          if Key.shift() then
            --- Ensure the user can get back to the console
            if k == "r" then
              CC:reset()
            end
          end
        end
      end
      local function restart()
        if Key.ctrl() and Key.alt() and k == "r" then
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
        if k == "f10" then
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

    handlers.keyreleased = function(k)
      Controller.keys_pressed[k] = nil
      if Key.ctrl() then
        if k == "escape" then
          love.event.quit()
        end
      end
      if love.keyreleased then
        return love.keyreleased(k)
      end
    end

    --- @param x integer
    --- @param y integer
    --- @param btn integer
    --- @param touch boolean
    --- @param presses number
    -- Pointer has NO three-consumer chain: this is an
    -- unstructured broadcast. The widget gets the event
    -- whenever present (no bounds/consume check, return
    -- ignored), then the project's own handler gets it
    -- unconditionally. `user_input` is touched directly
    -- because the widget needs pointer events (click-to-
    -- cursor / drag-select) and no chain carries them.
    -- Pointer never had the widget-lockout problem, so its
    -- delivery stays pre-existing behaviour, deliberately
    -- out of scope. A mirrored consume-chain for pointer is
    -- an OPEN owner ruling — see doc/development/technical_debt/input.md
    -- "Pointer delivery is an unstructured broadcast".
    handlers.mousepressed = function(x, y, btn, touch, presses)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousepressed(x, y, btn, touch, presses)
      else
      end
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
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousereleased(x, y, btn, touch, presses)
      else
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
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousemoved(x, y, dx, dy, touch)
      else
      end
      if love.mousemoved then
        return love.mousemoved(x, y, dx, dy, touch)
      end
    end

    handlers.userinput = function()
      local user_input = get_user_input()
      if user_input then
        clear_user_input()
      end
    end

    --- @param id userdata
    --- @param x number
    --- @param y number
    --- @param dx number?
    --- @param dy number?
    --- @param pressure number?
    handlers.touchpressed = function(id, x, y, dx, dy, pressure)
      local user_input = get_user_input()
      if user_input then
        user_input.C:touchpressed(id, x, y, dx, dy, pressure)
      else
      end
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
      local user_input = get_user_input()
      if user_input then
        user_input.C:touchreleased(id, x, y, dx, dy, pressure)
      else
      end
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
      local user_input = get_user_input()
      if user_input then
        user_input.C:touchmoved(id, x, y, dx, dy, pressure)
      else
      end
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

Controller.project_input = ProjectInputController()
