local class = require('util.class')
require("util.key")

-- The project route: occupant of the keyboard/text slots while
-- a project run owns the screen — a sibling to ConsoleController
-- / EditorController. Inside the route every keyboard/text event
-- runs ONE four-tier chain (spec §2), the same shape on all
-- three channels:
--
--   1. framework_handlers.<event>[combo]  structural keys
--      (return/escape land here in a later chunk; the slot
--       exists now and is non-overridable)
--   2. compy.input.handlers.<event>[combo]  project combo
--      handlers (R14 per-event sub-tables; normalising §1)
--   3. per-event generic callback           on_key_pressed /
--      on_text_input / on_key_released — precedence (R7):
--      explicit on_* > native captured at activate > noop+log
--   4. sink                                  the singleton
--      widget; terminal, with an INTERNAL hidden-check
--      (userInputController) — no external gating wrapper
--
-- Truthy return at any tier consumes the event (stop, sink
-- included); falsey falls through. Consuming never removes a
-- tier (R13); the sink's return carries no chain meaning (R12).
-- Routing contract: doc/development/internals/user_input.md

-- Event type -> its tier-3 generic-callback field on compy.input.
local CHANNELS = {
  keypressed  = 'on_key_pressed',
  keyreleased = 'on_key_released',
  textinput   = 'on_text_input',
}

local function new()
  return {
    natives = {},
    compy_input = nil,
    framework_handlers = {
      keypressed  = {},
      keyreleased = {},
      textinput   = {},
    },
  }
end

--- @class ProjectInputController
--- @field natives table
--- @field compy_input table?
--- @field framework_handlers table
ProjectInputController = class.create(new)

--- @param branch string
local function log_branch(branch)
  if love.DEBUG then
    Log.debug('project input: ' .. branch)
  end
end

--- Tier 3 — the per-event generic callback, resolved by
--- precedence (spec §8 R7): an explicit compy.input.on_* wins;
--- else the project's native captured at activate; else a noop
--- that only debug-logs and never consumes (AC-10). A truthy
--- return consumes; falsey falls through to the sink.
--- @param event string
--- @return boolean? consumed
--- REVIEW: its better to install natives as callback once on load than to check every time
function ProjectInputController:_tier3(event, ...)
  local ci = self.compy_input
  local cb = ci[CHANNELS[event]] or self.natives[event]
  -- REVIEW: defaulting cb to noop-with-log and calling unconditionally would be nicer
  if cb then return cb(...) end
  log_branch('generic callback noop: ' .. event)
  return false
end

--- REVIEW: actually should not be invoked if consumed earlier
--- REVIEW: should not user_input_controller be set as instance property (self.input) on creation? code would be cleaner then
--- REVIEW: 'if-then' is not recommended (codestyle), UIC (ideally self.input) should be always present (singleton convention) -- can pcall or just raise if unexpected happens...
--- Tier 4 — the terminal widget sink. Always invoked (never
--- gated from outside): the hidden-check is INTERNAL to the
--- sink, which no-ops while the overlay is hidden (AC-11/13).
--- The sink's return is discarded — it carries no chain
--- meaning (R12); the chain ends here regardless.
--- @param event string
function ProjectInputController:_sink(event, ...)
  local ui = love.state.user_input_controller
  if ui then ui[event](ui, ...) end
end

--- Run the four-tier chain for one event. `trigger` is the
--- combo token (the key, or the text); the varargs are the
--- channel payload handed to every participant. Returns truthy
--- once a tier consumes; otherwise the event reaches the sink.
--- @param event string
--- @param trigger string
--- @return boolean? consumed
--- REVIEW: stylistically should be rather `return (fw(..) or ph(..) or tier3(..) or sink(..))` with all component being noop when read 
function ProjectInputController:_dispatch(event, trigger, ...)
  local combo = Controller.combo_string(
    trigger, Controller.keys_pressed)
  local fw = self.framework_handlers[event][combo]
  if fw and fw(...) then return true end
  local ph = self.compy_input.handlers[event][combo]
  if ph and ph(...) then return true end
  if self:_tier3(event, ...) then return true end
  return self:_sink(event, ...)
end

--- Take the keyboard route for a project run. `natives` holds
--- the project's own error-wrapped love.* keyboard handlers
--- (from the caller); they seed tier 3 as default participants
--- (R7 pure wrap) — read once here, never re-consulted, and
--- only used when the project sets no on_* (precedence in
--- _tier3). No handler is copied onto compy.input.
--- @param natives table?
--- @param compy_input table
--- REVIEW: that's the proper moment to wrap natives and install as callbacks if natives are present and callbacks are not
function ProjectInputController:activate(natives, compy_input)
  self.natives = natives or {}
  self.compy_input = compy_input
end

--- Release the route. Route-lifecycle teardown of the project's
--- handlers/callbacks is owned elsewhere (a later chunk); this
--- only drops the route's references.
function ProjectInputController:deactivate()
  self.compy_input = nil
  self.natives = {}
end

--- Occupancy is the route's for the whole run, but consumption
--- follows the routing model: outside 'running' (e.g. after a
--- non-blocking run returned) the console route consumes, so
--- events forward to the default slot handlers (M4 ruling 1).
--- @param k string
--- @param sc string?
--- @param isr boolean?
--- DEFERRED (0.1.0-m5): whether the combo tiers (1-2) fire on
--- key-repeat is unruled; isrepeat is threaded to tier 3 only,
--- combos keep current behaviour. Do not design a mechanism.
--- REVIEW: what is _defaults and why the check is needed? Is not the whole route disconnected at framework level when app is not running?
--- TODO: refactor this part, simple aliasing/wrapping should be enough, _defaults should either be not used or handled ONCE inside _dispatch
function ProjectInputController:keypressed(k, sc, isr)
  if love.state.app_state ~= 'running' then
    return Controller._defaults.keypressed(k, sc, isr)
  end
  return self:_dispatch(
    'keypressed', k, k, Controller.held_keys(), isr)
end

--- @param t string
function ProjectInputController:textinput(t)
  if love.state.app_state ~= 'running' then
    return Controller._defaults.textinput(t)
  end
  return self:_dispatch(
    'textinput', t, t, Controller.held_keys())
end

--- @param k string
--- The released key is already gone from the held set (removed
--- at the gateway before dispatch), so consumers see it absent.
function ProjectInputController:keyreleased(k)
  if love.state.app_state ~= 'running' then
    return Controller._defaults.keyreleased(k)
  end
  return self:_dispatch(
    'keyreleased', k, k, Controller.held_keys())
end
