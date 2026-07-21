local class = require('util.class')
require("util.key")

--- REVIEW/DOC: can we reconsider 'slots' as a primary term? Could it be 'event slot' or 'event handler slot' or something similar? Ideally I want a concise and unambiguous term. "Slot" is a bit vague as it requires understanding the context
-- The project route: occupant of the keyboard/text slots while
-- a project run owns the screen — a sibling to ConsoleController
-- / EditorController. The route is DUMB: it navigates each
-- keyboard/text event through THREE consumers in order, stopping
-- at the first that returns truthy (doc/development/decisions/input.md,
-- Decision 2 revised), the same shape on all three channels:
--
--   1. compy.input.shortcuts[event][combo]  project shortcut
--      combos (doc/development/decisions/input.md, Decision 8:
--      per-event sub-tables, normalising)
--   2. compy.input.hooks[event]             one hook per event
--      (doc/development/decisions/input.md, Decision 10 revised): the
--      single source of truth, seeded once at activate() with the
--      project's captured love.* handler where unset; a nil clears
--      with no resurrection
--   3. the widget                           terminal; consumes
--      whenever it is shown (its own internal flag), skipped when
--      hidden. Enter/Escape/submit/cancel are the WIDGET's own
--      business (userInputController), signalled via callbacks —
--      never a routing concern.
--
-- Truthy at a consumer stops the walk; falsey falls through. The
-- widget's participation derives from its shownness, not a return
-- value (doc/development/decisions/input.md, Decision 5 revised).
-- Routing contract: doc/development/internals/user_input.md

-- The three uniform event channels the chain dispatches on.
local EVENTS = { 'keypressed', 'keyreleased', 'textinput' }

--- Seed the project's hooks table (doc/development/decisions/input.md,
--- Decision 10 revised): each event with no explicit project hook gets
--- the project's own love.* handler, once, at activation. After this
--- the hooks table is the single source of truth — a nil'd hook clears,
--- with no resurrection (validation/reviews/delta-spec-input-api.md §5).
--- Runs after the project's top-level code, so an explicit hooks[event]
--- set there is already present and correctly preserved.
--- @param hooks table  compy_input.hooks
--- @param handlers table  { event -> fn? }
local function seed_hooks(hooks, handlers)
  for _, event in ipairs(EVENTS) do
    if hooks[event] == nil then
      hooks[event] = handlers[event]
    end
  end
end

local function new()
  return { compy_input = nil }
end

--- @class ProjectInputController
--- @field compy_input table?
ProjectInputController = class.create(new)

--- The dumb three-consumer walk (obligation 6a; validation/
--- reviews/delta-spec-input-api.md §2): shortcuts[event][combo] →
--- hooks[event] → widget, stopping at the first that consumes.
--- A shortcut or hook consumes by returning truthy; the widget
--- consumes whenever it is shown (its own internal flag), and is
--- skipped when hidden — so the walk reports consumed iff a
--- consumer fired or the widget was shown. A free function over
--- plain tables + a widget reference, so any adopter (not only
--- the project overlay) can reuse it over its own instance.
--- @param shortcuts table   per-event combo tables
--- @param hooks table       per-event hook fns
--- @param widget table      responds to widget[event](...) + is_shown()
--- @param event string
--- @param trigger string
--- @return boolean consumed
local function dispatch(shortcuts, hooks, widget, event, trigger, ...)
  local combo = Controller.combo_string(
    trigger, Controller.keys_pressed)
  local sc = shortcuts[event][combo]
  if sc and sc(...) then return true end
  local hk = hooks[event]
  if hk and hk(...) then return true end
  if widget and widget:is_shown() then
    widget[event](widget, ...)
    return true
  end
  return false
end

--- Run the chain for one event. `trigger` is the combo token
--- (the key, or the text); the varargs are the channel payload.
--- @param event string
--- @param trigger string
--- @return boolean consumed
function ProjectInputController:_dispatch(event, trigger, ...)
  return dispatch(
    self.compy_input.shortcuts, self.compy_input.hooks,
    love.state.user_input_controller, event, trigger, ...)
end

--- Take the keyboard route for a project run. `handlers` holds the
--- project's own error-wrapped love.* keyboard handlers (from the
--- caller); they seed the hooks table once here (seed_hooks;
--- doc/development/decisions/input.md, Decision 10 revised) — only where
--- the project set no explicit hook. After seeding, hooks is read
--- directly on each event; there is no separate handlers store.
--- @param handlers table?
--- @param compy_input table
function ProjectInputController:activate(handlers, compy_input)
  self.compy_input = compy_input
  seed_hooks(compy_input.hooks, handlers or {})
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
--- DEFERRED (doc/development/technical_debt/input.md, "Shortcuts
--- key-repeat semantics are shipped unsettled"): whether
--- shortcuts fire on
--- key-repeat is unruled; isrepeat is threaded to hooks only,
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
