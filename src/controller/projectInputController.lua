local class = require('util.class')

-- The project route: occupant of the keyboard/text slots
-- while a project run owns the screen — a sibling to
-- ConsoleController/EditorController. Sink delegation only:
-- the singleton text-editing widget is the route's default
-- disposition when shown; hidden, it consumes nothing.
-- Dispatch tiers (combos, project callbacks) come later.
-- Routing contract: doc/development/internals/user_input.md

local function new()
  return {
    natives = {},
    compy_input = nil,
    provisioned = nil,
  }
end

--- @class ProjectInputController
--- @field natives table
--- @field compy_input table?
--- @field provisioned function?
ProjectInputController = class.create(new)

--- @param branch string
local function log_branch(branch)
  if love.DEBUG then
    Log.debug('project input: ' .. branch)
  end
end


--- REVIEW: I refuse to even consider 'sink' as a first-class architectural concept. It was just an internal term to determine default/final/last-resort receiver of the event, *whatever it will be* (yet it *happpens* to be UserInputController in current design). 'sink' is not something that special or important to participate in routing decisions and names of functions!
--- The route's default disposition: the text-editing sink
--- when the singleton is shown; a keystroke arriving while
--- it is hidden mutates nothing.
--- @param k string
--- @param keys table
--- @param isr boolean?
local function sink_keypressed(k, keys, isr)
  local ui = love.state.user_input
  -- REVIEW: why not just call compy.input.* method and let it decide whether it consumed event or not? what's the point of talking with UI controller directly? (tangling/depending on its implementation)
  if ui then
    -- the sink binds only k until its dispatch milestone
    --- @diagnostic disable-next-line: redundant-parameter
    return ui.C:keypressed(k, keys, isr)
  -- REVIEW: silent swallow on 'else', no warning, nothing...
  end
end

-- REVIEW: as said many times, logic seems inverted to me. there should be no if-governed 'native-split', just a unified chain of processing, one of the consumers (last) being user input, which noops if its hidden
--- Lifecycle-split wrapper (native coexistence): singleton
--- shown -> the text-editing sink; hidden -> the project's
--- own native handler. The trailing scancode keeps the
--- native on the LÖVE (k, scancode, isrepeat) signature.
--- @param native function
--- @return function
local function native_split(native)
  return function(k, keys, isr, sc)
    local ui = love.state.user_input
    if ui then
      log_branch('sink')
      --- @diagnostic disable-next-line: redundant-parameter
      return ui.C:keypressed(k, keys, isr)
    end
    log_branch('native keypressed')
    return native(k, sc, isr)
  end
end

-- REVIEW: what calls 'activate'? Why we support 'legacy' if no backwards-compatibility is required?
--- Take the keyboard route for a project run. `natives`
--- holds the project's own love.* keyboard handlers
--- (error-wrapped by the caller). A project with a native
--- keypressed and no compy input callback set is legacy:
--- its handler is auto-provisioned as
--- `compy_input.on_key_pressed` via the lifecycle split.
--- @param natives table?
--- @param compy_input table?
function ProjectInputController:activate(natives, compy_input)
  self.natives = natives or {}
  self.compy_input = compy_input
  local native = self.natives.keypressed
  if compy_input
      and native
      and not compy_input.on_key_pressed
  then
    self.provisioned = native_split(native)
    compy_input.on_key_pressed = self.provisioned
  end
end

-- REVIEW: what calls deactivate? why? why cannot upper-level *controller* detach routing without doing anything special inside routed ProjectInputController ?
--- Release the route on project stop; the auto-provisioned
--- callback goes with the rest of the project state.
function ProjectInputController:deactivate()
  local ci = self.compy_input
  if ci and ci.on_key_pressed == self.provisioned then
    ci.on_key_pressed = nil
  end
  self.provisioned = nil
  self.natives = {}
  self.compy_input = nil
end

--- Occupancy is the route's for the whole run lifecycle,
--- but consumption follows the routing model: outside
--- 'running' (e.g. after a non-blocking run returned) the
--- console route consumes, so events forward to the
--- default slot handlers.
--- @param k string
--- @param sc string?
--- @param isr boolean?
function ProjectInputController:keypressed(k, sc, isr)
  -- REVIEW: whether app is running is not a concern of THIS controller -- upper-level controller should change routing, therefore condition checked would never fire
  if love.state.app_state ~= 'running' then
    --- @diagnostic disable-next-line: redundant-parameter
    return Controller._defaults.keypressed(k, sc, isr)
  end
  -- REVIEW: where is the handling of project-installed keypressed hook? let alone stub for handlers before it? all connected via truthy/falthy return value?
  -- REVIEW: why all the code below and not just compy.input.on_key_pressed ? (which *should* be noop if not installed) how sink_keypressed is different? it routes same stuff to the same consumer, just via legacy interface -- I see no use of it at all.
  local ci = self.compy_input
  local cb = ci and ci.on_key_pressed
  if cb then
    return cb(k, Controller.keys_pressed, isr, sc)
  end
  return sink_keypressed(k, Controller.keys_pressed, isr)
end

--- @param t string
-- REVIEW: same problem as described -- does not match design of unified routing (combos -> projecthandler -> compy.input )
function ProjectInputController:textinput(t)
  if love.state.app_state ~= 'running' then
    return Controller._defaults.textinput(t)
  end
  local ui = love.state.user_input
  if ui then
    return ui.C:textinput(t)
  end
  local native = self.natives.textinput
  if native then
    log_branch('native textinput')
    return native(t)
  end
end

-- REVIEW: why not unified routing for all types of events? could be one function with signal name as parameter
--- Sink delegation only — no release dispatch tier exists;
--- the native delegation mirrors keypressed.
--- @param k string
function ProjectInputController:keyreleased(k)
  if love.state.app_state ~= 'running' then
    return Controller._defaults.keyreleased(k)
  end
  local ui = love.state.user_input
  if ui then
    return ui.C:keyreleased(k)
  end
  local native = self.natives.keyreleased
  if native then
    return native(k)
  end
end
