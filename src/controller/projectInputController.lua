local class = require('util.class')
require("util.key")

--- REVIEW/DOC: can we reconsider 'slots' as a primary term? Could it be 'event slot' or 'event handler slot' or something similar? Ideally I want a concise and unambiguous term. "Slot" is a bit vague as it requires understanding the context
-- The project route: occupant of the keyboard/text slots while
-- a project run owns the screen — a sibling to ConsoleController
-- / EditorController. Inside the route every keyboard/text event
-- runs ONE four-tier chain (doc/development/decisions/input.md, Decision 2),
-- the same shape on all three channels:
--
--   1. framework_handlers.<event>[combo]  structural keys
--      (doc/development/decisions/input.md, Decision 6:
--       keypressed['return']/['escape'], engaged
--       only while the widget is shown; non-overridable)
--   2. compy.input.shortcuts.<event>[combo]  project shortcut
--      combos (doc/development/decisions/input.md, Decision 8:
--      per-event sub-tables, normalising)
--   3. compy.input.hooks[event]              one hook per event
--      (doc/development/decisions/input.md, Decision 10 revised): the
--      single source of truth, seeded once at activate() with the
--      project's captured love.* handler where unset; a nil clears
--      with no resurrection
--   4. sink                                  the singleton
--      widget; terminal, with an INTERNAL hidden-check
--      (userInputController) — no external gating wrapper
--
-- Truthy return at any tier consumes the event (stop, sink
-- included); falsey falls through. Consuming never removes a
-- tier (doc/development/decisions/input.md, Decision 2); the sink's return
-- carries no chain meaning (doc/development/decisions/input.md, Decision 5).
-- Routing contract: doc/development/internals/user_input.md

-- The three uniform event channels the chain dispatches on.
local EVENTS = { 'keypressed', 'keyreleased', 'textinput' }

--- Seed the project's hooks table (doc/development/decisions/input.md,
--- Decision 10 revised): each event with no explicit project hook gets
--- its captured native love.* handler, once, at activation. After this
--- the hooks table is the single source of truth — a nil'd hook clears,
--- with no resurrection (validation/reviews/delta-spec-input-api.md §5).
--- Runs after the project's top-level code, so an explicit hooks[event]
--- set there is already present and correctly preserved.
--- @param hooks table  compy_input.hooks
--- @param natives table  { event -> fn? }
local function seed_hooks(hooks, natives)
  for _, event in ipairs(EVENTS) do
    if hooks[event] == nil then
      hooks[event] = natives[event]
    end
  end
end

--- @param branch string
local function log_branch(branch)
  if love.DEBUG then
    Log.debug('project input: ' .. branch)
  end
end

--- REVIEW: why if-dispatching instead of returning noop+log as default index value from hooks table? (do not fix; either rationalize or mark as refactoring opportunity)
--- Run a route-owned before_/after_ hook
--- (doc/development/decisions/input.md, Decision 6): a
--- project-set function fires; an absent one debug-logs — the
--- same noop+log default shape as tier 3 (log_branch above).
--- Hooks live on compy_input (the route), never on the
--- widget (doc/development/decisions/input.md, Decision 6: "the widget
--- never owns submit").
--- @param ci table  compy_input surface
--- @param name string  callback field name (callbacks.<name>)
local function run_hook(ci, name, ...)
  local hook = ci.callbacks[name]
  if hook then
    hook(...)
    return
  end
  log_branch(name .. ' noop')
end

--- @return UserInputController? ui  the singleton, only while
--- shown (doc/development/internals/user_input.md, "Submit and cancel —
--- the framework tier-1 chains": hidden -> no framework
--- entry engages, so the combo falls through to lower
--- tiers like any other key).
local function shown_widget()
  local ui = love.state.user_input_controller
  if ui and ui:is_shown() then return ui end
end

--- Tier-1 submit entry (doc/development/internals/user_input.md, "Submit
--- and cancel — the framework tier-1 chains"): before_submit
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

--- Tier-1 cancel entry (doc/development/internals/user_input.md, "Submit
--- and cancel — the framework tier-1 chains"): before_/
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

-- Tier-1 return/escape (doc/development/internals/user_input.md, "Submit
-- and cancel — the framework tier-1 chains"): populated
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
--- @field compy_input table?
--- @field framework_handlers table
ProjectInputController = class.create(new)

--- The hook tier (doc/development/decisions/input.md, Decision 10
--- revised): one fn per event on compy.input.hooks, the single source
--- of truth. Seeded once at activation with the project's captured
--- native love.* handler (seed_hooks); thereafter a nil clears with no
--- resurrection. A truthy return consumes; absent or falsey falls
--- through to the widget.
--- @param event string
--- @return boolean? consumed
function ProjectInputController:_generic_callback(event, ...)
  local cb = self.compy_input.hooks[event]
  if cb then return cb(...) end
  log_branch('hook noop: ' .. event)
  return false
end

--- (Not reached when a prior tier consumed: `_dispatch` short-
--- circuits with `return true` at each tier, so `_sink` runs
--- only on full fall-through.)
--- TODO(debt): reaches the widget via the `love.state` global +
--- nil-guards it; inject `self.input` and assert the singleton.
--- See doc/development/technical_debt/input.md "Widget sink reaches the
--- singleton via `love.state` global".
--- Tier 4 — the terminal widget sink. Always invoked (never
--- gated from outside): the hidden-check is INTERNAL to the
--- sink, which no-ops while the overlay is hidden
--- (doc/development/decisions/input.md, Decision 2).
--- The sink's return is discarded — it carries no chain
--- meaning (doc/development/decisions/input.md, Decision 5); the chain
--- ends here regardless.
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
  local ph = self.compy_input.shortcuts[event][combo]
  if ph and ph(...) then return true end
  if self:_generic_callback(event, ...) then return true end
  return self:_sink(event, ...)
end

--- Take the keyboard route for a project run. `natives` holds the
--- project's own error-wrapped love.* keyboard handlers (from the
--- caller); they seed the hooks table once here (seed_hooks;
--- doc/development/decisions/input.md, Decision 10 revised) — only where
--- the project set no explicit hook. After seeding, hooks is read
--- directly on each event; there is no separate natives store.
--- @param natives table?
--- @param compy_input table
function ProjectInputController:activate(natives, compy_input)
  self.compy_input = compy_input
  seed_hooks(compy_input.hooks, natives or {})
end

--- Forget the project's handlers (doc/development/decisions/input.md,
--- Decision 11).
--- Nulling compy_input does not itself disconnect anything: the
--- caller (controller.lua release_keyboard_route /
--- set_default_handlers) re-points the love.* callbacks at the
--- console, after which _dispatch is unreachable. Dropping the
--- reference here lets the stopped project's handlers be collected
--- and guarantees the next activate() starts from a clean state
--- instead of a stale project's callbacks.
function ProjectInputController:deactivate()
  self.compy_input = nil
end

--- Keypressed (doc/development/decisions/input.md, Decision 11). The
--- route is connected/disconnected at the
--- 'running' <-> 'project_open' boundary by reinstalling
--- the love.* callbacks (controller.lua), not per-event
--- here — once disconnected, love.keypressed no longer even
--- points at this method, so no state guard is needed.
--- @param k string
--- @param sc string?
--- @param isr boolean?
--- DEFERRED (doc/development/technical_debt/input.md, "Combo-tier
--- key-repeat semantics are shipped unsettled"): whether
--- the combo tiers (1-2) fire on
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
