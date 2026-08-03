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


-- Two lists, one lifetime. Every channel installs the same way
-- (occupy_keyboard), runs the same chain, and is released at
-- the same moment: the project's stop. The split that existed
-- here (keyboard released at running->project_open, pointer
-- exempted so pen-and-paper projects survived it) came with
-- this feature and is gone: at the PR base nothing was
-- released before suspend or stop.
-- The lists remain because the two groups still differ in what
-- they CARRY, not in how they are routed: keyboard/text events
-- have a combo trigger and therefore a shortcuts tier, pointer
-- events have neither and enter the walk at the hook tier.
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
-- through compy.input.hooks like anything else. They are NOT in
-- _supported because there is no love.<name> for a project to
-- have written, so nothing seeds them from the sandbox table.
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

--- NAMING — settled. `userlove` KEEPS its name (owner ruling,
--- 2026-08-03: "its nice and makes no harm itself"). Read it as
--- "a table indexed by love-event name holding the project's
--- handlers", which is what both callers pass: the sandboxed
--- `love` table from `set_user_handlers`, and the saved
--- `_userhandlers` from `restore_user_handlers`. The second is
--- why the once-proposed `project_love` was dropped: it would
--- have been true at only one of the two.
--- The `*_native` names went with the two wrappers when they
--- merged; `forward_*` left by deletion, its console-route
--- widget gate being gone.

--- Run `fn` the way project code must always be run: drawing
--- routed onto the project's canvas (CC:use_canvas — the
--- offscreen surface project draws land on), errors routed to
--- the project error handler, return value propagated.
---
--- This is THE boundary, and it sits at the point where a route
--- is entered rather than around each participant. The dispatch
--- chain itself carries no error handling
--- (projectInputController.lua), so wrapping participants left
--- two of the three tiers unprotected — a raise in
--- `shortcuts[...]` or in a directly-assigned `hooks[...]`
--- escaped the chain entirely — and made a raise in the third
--- look like a falsey "did not consume", so the walk carried on
--- into the widget. One boundary above the walk covers every
--- tier and aborts it.
--- @param CC ConsoleController
--- @param fn function
--- @return function
local function guarded(CC, fn)
  return function(...)
    local args = { ... }
    return CC:use_canvas(function()
      local ok, res = wrap(fn, CC, unpack(args))
      if ok then return res end
    end)
  end
end

--- The project's own handler for an event, raw; nil when the
--- project did not define one. NOT wrapped — `guarded` above
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
  local orig = Controller._defaults[key]
  local new = userlove[key]
  if not (orig and new and orig ~= new) then return end
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
  for _, k in ipairs(_supported) do
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
local function occupy_keyboard(userlove, CC)
  local pic = Controller.project_input
  local compy = CC:get_project_env().compy
  pic:activate(project_handlers(userlove, CC), compy.input)
  -- `guarded` here, not around each participant: entering the
  -- route IS the boundary, so every tier of the walk runs with
  -- the project canvas bound and one error handler above it.
  -- Wrapped (not assigned) to bind `pic` as method receiver:
  -- `love.keypressed = pic.keypressed` would drop `self`.
  love.keypressed = guarded(CC, function(k, sc, isr)
    return pic:keypressed(k, sc, isr)
  end)
  love.textinput = guarded(CC, function(t)
    return pic:textinput(t)
  end)
  love.keyreleased = guarded(CC, function(k)
    return pic:keyreleased(k)
  end)
  -- Pointer occupies the same way, through the same chain. The
  -- split that kept it out was this feature's invention, not
  -- inherited behaviour: pre-feature every event installed
  -- through one path and none was released before stop.
  for _, k in ipairs(_pointer) do
    love[k] = guarded(CC, function(...)
      return pic[k](pic, ...)
    end)
  end
  for _, k in ipairs(_derived) do
    love[k] = guarded(CC, function(...)
      return pic[k](pic, ...)
    end)
  end
end

--- @param userlove table
--- @param CC ConsoleController
-- Pointer handlers are installed by occupy_keyboard now, along
-- with every other channel; what remains here is the liveness
-- flag. `user_pointer` marks a non-blocking project as still
-- interactive so it keeps the route in 'project_open'
-- (technical_debt/input.md, ruling (a)).
--- @param userlove table
--- @param CC ConsoleController
local function hook_pointer(userlove, CC)
  for _, k in ipairs(_pointer) do
    if project_handler(userlove, k) then
      user_pointer = true
    end
  end
  -- Runs after occupy_keyboard, so the hooks table is already
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
  occupy_keyboard(userlove, CC)
  hook_pointer(userlove, CC)
  hook_update(userlove)
  hook_draw(userlove)
end

-- Every channel that can carry a hook, pointer included: else
-- a stopped project's pointer hook survives teardown and blocks
-- the NEXT project's seeding (seed_hooks fills only a nil
-- slot). Decision 11's teardown invariant covers all of them.
local HOOK_EVENTS = {}
for _, k in ipairs(_supported) do
  table.insert(HOOK_EVENTS, k)
end
for _, k in ipairs(_derived) do
  table.insert(HOOK_EVENTS, k)
end

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
  wipe_table(input.shortcuts.keypressed)
  wipe_table(input.shortcuts.keyreleased)
  wipe_table(input.shortcuts.textinput)
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
  -- Empty: the click stubs that used to sit here were a fossil
  -- of the era when single/doubleclick were love.* events. They
  -- were dead: every _defaults read iterates _supported (plus
  -- 'draw'), which never included them.
  _defaults = { },
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

  --- @private
  --- @param CC ConsoleController
  set_love_keyreleased = function(CC)
    -- Same wrapper shape as keypressed above (terminal love-
    -- boundary, return not propagated). CC is the console — the
    -- named default/restore route (doc/development/decisions/input.md #1); not
    -- "special", just the default occupant. Per-event installer
    -- repetition logged in technical_debt.
    --- @diagnostic disable-next-line: duplicate-set-field
    local function keyreleased(k)
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
    Controller.set_love_keyreleased(CC)
    Controller.set_love_textinput(CC)
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

    local clear_user_input = function()
      love.state.user_input = nil
    end

    --- @diagnostic disable-next-line: undefined-field
    local handlers = love.handlers

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

Controller.project_input = ProjectInputController()
