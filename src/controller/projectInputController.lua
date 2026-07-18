local class = require('util.class')
require("util.key")

--- REVIEW/DOC: can we reconsider 'slots' as a primary term? Could it be 'event slot' or 'event handler slot' or something similar? Ideally I want a concise and unambiguous term. "Slot" is a bit vague as it requires understanding the context
-- The project route: occupant of the keyboard/text slots while
-- a project run owns the screen — a sibling to ConsoleController
-- / EditorController. Inside the route every keyboard/text event
-- runs ONE four-tier chain ({badspecref: spec §2}), the same
-- shape on all three channels:
--
--   1. framework_handlers.<event>[combo]  structural keys
--      ({badspecref: spec §5}:
--       keypressed['return']/['escape'], engaged
--       only while the widget is shown; non-overridable)
--   2. compy.input.handlers.<event>[combo]  project combo
--      handlers ({badspecref: R14} per-event sub-tables;
--      normalising {badspecref: §1})
--   3. per-event generic callback           on_key_pressed /
--      on_text_input / on_key_released — precedence
--      ({badspecref: R7}): an explicit on_* wins over the
--      project's own love.* handler captured at activate(),
--      which wins over noop+log
--   4. sink                                  the singleton
--      widget; terminal, with an INTERNAL hidden-check
--      (userInputController) — no external gating wrapper
--
-- Truthy return at any tier consumes the event (stop, sink
-- included); falsey falls through. Consuming never removes a
-- tier ({badspecref: R13}); the sink's return carries no
-- chain meaning ({badspecref: R12}).
-- Routing contract: doc/development/internals/user_input.md

-- Event type -> its tier-3 generic-callback field on compy.input.
local CHANNELS = {
  keypressed  = 'on_key_pressed',
  keyreleased = 'on_key_released',
  textinput   = 'on_text_input',
}

--- @param branch string
local function log_branch(branch)
  if love.DEBUG then
    Log.debug('project input: ' .. branch)
  end
end

--- REVIEW: why if-dispatching instead of returning noop+log as default index value from hooks table? (do not fix; either rationalize or mark as refactoring opportunity)
--- Run a route-owned before_/after_ hook
--- ({badspecref: spec §5, AC-26}): a
--- project-set function fires; an absent one debug-logs — the
--- same noop+log default shape as tier 3 (log_branch above).
--- Hooks live on compy_input (the route), never on the
--- widget ({badspecref: spec §5 scope note}: "the widget
--- never owns submit").
--- @param ci table  compy_input surface
--- @param name string  hook field name
local function run_hook(ci, name, ...)
  local hook = ci[name]
  if hook then
    hook(...)
    return
  end
  log_branch(name .. ' noop')
end

--- @return UserInputController? ui  the singleton, only while
--- shown ({badspecref: AC-20}: hidden -> no framework entry
--- engages, so the
--- combo falls through to lower tiers like any other key).
local function shown_widget()
  local ui = love.state.user_input_controller
  if ui and ui:is_shown() then return ui end
end

--- Tier-1 submit entry
--- ({badspecref: spec §5, AC-17/20/21}): before_submit
--- always runs; after_submit only on accept (ui:submit()
--- returns the delivered text, nil on reject/empty).
--- @param self ProjectInputController
--- @return fun(k: string, keys_pressed: table)
local function framework_submit(self)
  return function(_, keys_pressed)
    local ui = shown_widget()
    if not ui then return false end
    local ci = self.compy_input
    run_hook(ci, 'before_submit', keys_pressed)
    local text = ui:submit()
    if text ~= nil then run_hook(ci, 'after_submit', text) end
    return true
  end
end

--- Tier-1 cancel entry
--- ({badspecref: spec §5, AC-19/20/21}): before_/
--- after_cancel bracket ui:cancel() unconditionally — cancel
--- always dismisses, unlike submit there is no reject path.
--- @param self ProjectInputController
--- @return fun(k: string, keys_pressed: table)
local function framework_cancel(self)
  return function(_, keys_pressed)
    local ui = shown_widget()
    if not ui then return false end
    local ci = self.compy_input
    run_hook(ci, 'before_cancel', keys_pressed)
    ui:cancel()
    run_hook(ci, 'after_cancel')
    return true
  end
end

-- Tier-1 return/escape ({badspecref: spec §5}): populated
-- once, at
-- construction, not per-activate() — they are structural/
-- non-overridable, not project-installed, so they exist
-- whether or not a project is currently running.
--- @param self ProjectInputController
local function install_tier1(self)
  local kp = self.framework_handlers.keypressed
  kp['return'] = framework_submit(self)
  kp['escape'] = framework_cancel(self)
end

local function new()
  local self = {
    natives = {},
    compy_input = nil,
    framework_handlers = {
      keypressed  = {},
      keyreleased = {},
      textinput   = {},
    },
  }
  install_tier1(self)
  return self
end

--- @class ProjectInputController
--- @field natives table
--- @field compy_input table?
--- @field framework_handlers table
ProjectInputController = class.create(new)

--- Tier 3 — the per-event generic callback, resolved by
--- precedence ({badspecref: spec §8 R7}): an explicit
--- compy.input.on_* wins; else the project's own love.*
--- handler captured at activate; else a noop that only
--- debug-logs and never consumes ({badspecref: AC-10}).
--- A truthy
--- return consumes; falsey falls through to the sink.
--- @param event string
--- @return boolean? consumed
--- TODO(debt): tier-3 precedence is fixed at activate but
--- re-resolved per event; a default noop-that-logs would also
--- drop the `if cb` guard. See technical_debt/input.md
--- "`_generic_callback` re-resolves the callback precedence on every event".
function ProjectInputController:_generic_callback(event, ...)
  local ci = self.compy_input
  local cb = ci[CHANNELS[event]] or self.natives[event]
  if cb then return cb(...) end
  log_branch('generic callback noop: ' .. event)
  return false
end

--- (Not reached when a prior tier consumed: `_dispatch` short-
--- circuits with `return true` at each tier, so `_sink` runs
--- only on full fall-through.)
--- TODO(debt): reaches the widget via the `love.state` global +
--- nil-guards it; inject `self.input` and assert the singleton.
--- See technical_debt/input.md "Widget sink reaches the
--- singleton via `love.state` global".
--- Tier 4 — the terminal widget sink. Always invoked (never
--- gated from outside): the hidden-check is INTERNAL to the
--- sink, which no-ops while the overlay is hidden
--- ({badspecref: AC-11/13}).
--- The sink's return is discarded — it carries no chain
--- meaning ({badspecref: R12}); the chain ends here
--- regardless.
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
--- The staged form (not one `or` chain) guards nil per-tier
--- handlers: `fw`/`ph` come from sparse combo tables and are
--- often nil, so each is `x and x(...)`. A single `or` chain
--- would need every tier guaranteed-callable.
--- REVIEW: it was told multiple times that more tier-agnostic chain is to run 'OR' combination, while nill-able elements are secured by default noop (configured via metaindex on relevant tables). Let it be for now, but mark potential improvement as a tech debt or just `TODO:consider` note.
function ProjectInputController:_dispatch(event, trigger, ...)
  local combo = Controller.combo_string(
    trigger, Controller.keys_pressed)
  local fw = self.framework_handlers[event][combo]
  if fw and fw(...) then return true end
  local ph = self.compy_input.handlers[event][combo]
  if ph and ph(...) then return true end
  if self:_generic_callback(event, ...) then return true end
  return self:_sink(event, ...)
end

--- Take the keyboard route for a project run. `natives` holds
--- the project's own error-wrapped love.* keyboard handlers
--- (from the caller); they seed tier 3 as default participants
--- ({badspecref: R7} pure wrap) — read once here, never
--- re-consulted, and
--- only used when the project sets no on_* (precedence in
--- _generic_callback). No handler is copied onto compy.input.
--- @param natives table?
--- @param compy_input table
--- (Natives are seeded by precedence, never copied onto
--- compy.input — see decisions/input.md #10 "legacy natives
--- pure-wrapped as tier-3".)
function ProjectInputController:activate(natives, compy_input)
  self.natives = natives or {}
  self.compy_input = compy_input
end

--- Forget the project's handlers ({badspecref: AC-27/29}).
--- Nulling compy_input/natives does not itself disconnect
--- anything: the caller (controller.lua
--- release_keyboard_route / set_default_handlers) re-points
--- the love.* callbacks at the console, after which
--- _dispatch is unreachable. Dropping the references here
--- lets the stopped project's handlers be collected and
--- guarantees the next activate() starts from a clean
--- state instead of a stale project's callbacks.
function ProjectInputController:deactivate()
  self.compy_input = nil
  self.natives = {}
end

--- Keypressed ({badspecref: AC-27, ratified-model ruling
--- 3}). The route is connected/disconnected at the
--- 'running' <-> 'project_open' boundary by reinstalling
--- the love.* callbacks (controller.lua), not per-event
--- here — once disconnected, love.keypressed no longer even
--- points at this method, so no state guard is needed.
--- @param k string
--- @param sc string?
--- @param isr boolean?
--- DEFERRED ({badspecref: 0.1.0-m5}): whether the combo
--- tiers (1-2) fire on
--- key-repeat is unruled; isrepeat is threaded to tier 3 only,
--- combos keep current behaviour. Do not design a mechanism.
--- REVIEW: what is 'sc' and why its not used?
--- REVIEW: duplicaion of 'k,k' and 't,t' looks smelly -- why is it needed. in additon, _dispatch grabs keys_pressed itself(should not) and how other arguments are consumed its not very easy to understand.
function ProjectInputController:keypressed(k, sc, isr)
  return self:_dispatch(
    'keypressed', k, k, Controller.held_keys(), isr)
end

--- @param t string
function ProjectInputController:textinput(t)
  return self:_dispatch(
    'textinput', t, t, Controller.held_keys())
end

--- @param k string
--- The released key is already gone from the held set (removed
--- at the gateway before dispatch), so consumers see it absent.
function ProjectInputController:keyreleased(k)
  return self:_dispatch(
    'keyreleased', k, k, Controller.held_keys())
end
