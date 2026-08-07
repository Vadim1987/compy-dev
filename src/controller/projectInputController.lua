local class = require('util.class')
require("util.key")

-- The project route: owner of the keyboard/text handlers while
-- a project run owns the screen — a sibling to ConsoleController
-- / EditorController. The route is DUMB: it navigates each
-- keyboard/text event through THREE consumers in order, stopping
-- at the first that returns truthy (doc/development/decisions/input.md,
-- Decision 2), the same shape on all three channels:
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

-- Every channel the chain dispatches on. Keyboard/text carry a
-- combo trigger and a shortcuts tier; pointer channels carry
-- neither and start at the hook tier, so `dispatch` tolerates a
-- missing shortcuts table rather than each channel special-
-- casing itself. Pointer payloads are exactly LÖVE's own
-- arguments; no held-key view is appended, since a project
-- reads that through
-- compy.input.keys_pressed (Decision 20) and appending it would
-- change the signature every existing pointer handler was
-- written against.
---> REMARK: where are singleclick/doubleclick? they should better be supported as any other
local EVENTS = {
  'keypressed', 'keyreleased', 'textinput',
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'touchpressed', 'touchreleased', 'touchmoved',
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

--- Exact combo first, then the modifier class
--- (doc/development/decisions/input.md, Decision 21): 'alt+*' is
--- every Alt chord. The class key needs no parsing — it is the
--- same serialisation with '*' as the trigger. A modifier's own
--- press dispatches e.g. 'alt+lalt' and must not match 'alt+*'.
--- @param tbl table   one channel's combo table
--- @param trigger string
--- @return function?
local function find_shortcut(tbl, trigger)
  -- Pointer channels have no combo table and no trigger; they
  -- enter the walk at the hook tier.
  if not tbl then return end
  local keys = Controller.keys_pressed
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

-- Keyboard/text channels. The payload is LÖVE's own leading
-- arguments; the held-key set is read from
-- compy.input.keys_pressed, never threaded as an argument.
-- These three exist only to name the combo trigger.

--- Keypressed (doc/development/decisions/input.md, Decision 11). The
--- route is connected/disconnected at the
--- 'running' <-> 'project_open' boundary by reinstalling
--- the love.* callbacks (controller.lua), not per-event
--- here — once disconnected, love.keypressed no longer even
--- points at this method, so no state guard is needed.
--- @param k string
--- @param sc string?
--- @param isr boolean?
--- isrepeat reaches every consumer and dispatch does not gate on
--- it (doc/development/decisions/input.md, Decision 22): a held
--- combo fires each frame, and a binding that wants once per
--- physical press wraps itself in
--- compy.input.fn.ignore_repeat.
function ProjectInputController:keypressed(k, sc, isr)
  return self:_dispatch('keypressed', k, k, isr)
end

--- @param t string
function ProjectInputController:textinput(t)
  return self:_dispatch('textinput', t, t)
end

--- @param k string
function ProjectInputController:keyreleased(k)
  return self:_dispatch('keyreleased', k, k)
end


---> REMARK: as discussed, lets *support* combo triggers, fully unifying all dispatching of input events. just that combo triggers for pointer won't have the 'triggering' key they would be modifier-only . btw what about right button? and maybe 'button' for those which support button number. easy change, would unify a lot
-- Pointer channels. Each is the keyboard shape minus the combo
-- trigger: no shortcuts tier (find_shortcut answers nil for a
-- missing table), hooks then the shown widget, first truthy
-- return consuming. The payload is LÖVE's own argument list,
-- unchanged, so a project handler seeded from love.mousepressed
-- and the widget's own method both see what they always saw.
--- @param event string
local function pointer_channel(event)
  ProjectInputController[event] = function(self, ...)
    return self:_dispatch(event, nil, ...)
  end
end

-- The last two are DERIVED: the framework's click timer
-- synthesises them, LÖVE does not deliver them. They dispatch
-- identically all the same, which is the point: a project binds
-- compy.input.hooks.singleclick as it binds any other.
for _, event in ipairs({
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'touchpressed', 'touchreleased', 'touchmoved',
  'singleclick', 'doubleclick',
}) do
  pointer_channel(event)
end
