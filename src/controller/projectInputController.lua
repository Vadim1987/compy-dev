local class = require('util.class')
require("util.key")

-- The project route: owner of the input handlers while a project
-- run owns the screen — a sibling to ConsoleController /
-- EditorController. The route is DUMB: it navigates every event,
-- keyboard and pointer alike, through THREE consumers in order,
-- stopping at the first that returns truthy
-- (doc/development/decisions/input.md, Decision 2):
--
--   1. compy.input.shortcuts[event][combo]  project shortcut
--      combos (doc/development/decisions/input.md, Decision 8:
--      per-event sub-tables, normalising)
--   2. compy.input.hooks[event]             one hook per event
--      (doc/development/decisions/input.md, Decision 10): the
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
-- value (doc/development/decisions/input.md, Decision 5).
-- Routing contract: doc/development/internals/user_input.md

-- Every channel the chain dispatches on, in ONE list. The derived
-- clicks belong in it: where an event comes from (LÖVE, or the
-- framework's click timer) is not how a project binds it, and the
-- seeder has to see the same channels the dispatcher installs.
local EVENTS = {
  'keypressed', 'keyreleased', 'textinput',
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'touchpressed', 'touchreleased', 'touchmoved',
  'singleclick', 'doubleclick',
}

-- The channels that NAME a trigger in their combos. Everything
-- else builds its combo from held modifiers alone.
local KEYBOARD = {
  keypressed = true, keyreleased = true, textinput = true,
}

--- Seed the project's hooks table (doc/development/decisions/input.md,
--- Decision 10): each event with no explicit project hook gets
--- the project's own love.* handler, once, at activation. After this
--- the hooks table is the single source of truth — a nil'd hook clears,
--- with no resurrection.
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

-- Published: the console provisions one shortcut table per
-- channel and teardown wipes them, so both need the list this
-- file dispatches on rather than a copy of it.
ProjectInputController.EVENTS = EVENTS

--- Exact combo first, then the modifier class
--- (doc/development/decisions/input.md, Decision 21): 'alt+*' is
--- every Alt chord. The class key needs no parsing — it is the
--- same serialisation with '*' as the trigger. A modifier's own
--- press dispatches e.g. 'alt+lalt' and must not match 'alt+*'.
---
--- A pointer event names no trigger, so the class key is all it
--- can have: 'ctrl+*' is a ctrl-click. With no modifier held
--- there is nothing to name and the event belongs to the hook —
--- which is also why the held-modifier test comes first, so an
--- unmodified mousemoved never allocates a combo string.
--- @param tbl table   one channel's combo table
--- @param trigger string?
--- @return function?
local function find_shortcut(tbl, trigger)
  if not tbl then return end
  local keys = Controller.keys_pressed
  if not trigger then
    if not Controller.any_mod(keys) then return end
    return tbl[Controller.combo_string('*', keys)]
  end
  local sc = tbl[Controller.combo_string(trigger, keys)]
  if sc or Key.is_mod(trigger) then return sc end
  return tbl[Controller.combo_string('*', keys)]
end

--- The three-consumer walk: shortcuts[event][combo] →
--- hooks[event] → widget, stopping at the first that consumes.
--- A shortcut or hook consumes by returning truthy; the widget
--- consumes whenever it is shown (its own internal flag), and is
--- skipped when hidden — so the walk reports consumed iff a
--- consumer fired or the widget was shown. A free function over
--- plain tables + a widget reference, so any adopter (not only
--- the project overlay) can reuse it over its own instance.
--- The nil guards are deliberate (Decision 23): whether a hook
--- is set is information a project reads, so an unset one stays
--- nil rather than defaulting to a callable noop. Nothing is
--- logged when an event is consumed by nobody either — that
--- would be a line per ordinary keystroke at this tier.
--- @param shortcuts table   per-event combo tables
--- @param hooks table       per-event hook fns
--- @param widget table      responds to widget[event](...) + is_shown()
--- @param event string
--- @param trigger string
--- @return boolean consumed
local function dispatch(shortcuts, hooks, widget, event, trigger, ...)
  local sc = find_shortcut(shortcuts[event], trigger)
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
--- doc/development/decisions/input.md, Decision 10) — only where
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

-- One installer for every channel. The keyboard/text channels
-- name their first argument as the combo trigger; the rest name
-- none and enter the walk at the modifier-class lookup. Nothing
-- else differed between them once the held-key view stopped
-- being threaded through the payload.
--- @param event string
local function channel(event)
  local names_trigger = KEYBOARD[event]
  ProjectInputController[event] = function(self, ...)
    local trigger = names_trigger and ... or nil
    return self:_dispatch(event, trigger, ...)
  end
end

for _, event in ipairs(EVENTS) do channel(event) end
