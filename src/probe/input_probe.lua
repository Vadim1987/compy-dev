-- Input clock probe — DIAGNOSTIC, TEMPORARY. Delete when the
-- polling-vs-tracking question is ruled on.
--
-- Measures the two things that question turns on and that no
-- amount of reading the tree can answer:
--
--   1. how often two key events are dispatched in one frame
--      (LÖVE pumps the whole OS batch, then dispatches it one
--      event at a time, so a device poll taken during event 1
--      of N already reports the state after event N);
--   2. how often the device poll and the event-tracked set
--      disagree at the moment an event is dispatched — i.e.
--      how often a polling consumer would have decided
--      differently from an event-tracked one.
--
-- (2) is the measurement that matters: it is the mechanism
-- behind "weird reaction to keyboard sometimes", and its rate
-- is what decides whether the 70 device-poll call sites are a
-- real defect or a theoretical one.
--
-- USAGE, from the app's own console (no source edit needed):
--     require('probe.input_probe').install()
--   type normally for a while — the editor is the best place,
--   and fast chords (ctrl+s, shift+arrows) are the interesting
--   input — then:
--     probe_report()
--
-- Findings print as they happen, capped so a bad case cannot
-- flood the terminal; counting continues after the cap.

local MAX_PRINT = 40

local S = {
  frames = 0,
  events = 0,
  printed = 0,
  multi = 0,
  batch_max = 0,
  self_skew = 0,
  mod_skew = 0,
}

local batch = 0
local our_update

local function note(msg)
  S.printed = S.printed + 1
  if S.printed <= MAX_PRINT then
    print('[probe] ' .. msg)
  end
end

-- Called at the top of love.update, which LÖVE runs only after
-- the whole polled batch has been dispatched — so this is the
-- frame boundary, and `batch` is that frame's key-event count.
local function frame_end()
  S.frames = S.frames + 1
  if batch > S.batch_max then S.batch_max = batch end
  if batch > 1 then S.multi = S.multi + 1 end
  batch = 0
end

-- love.update is reassigned when routes change, so the wrapper
-- is re-applied whenever the identity underneath it moves.
local function ensure_update()
  local up = love.update
  if up == our_update or not up then return end
  our_update = function(dt)
    frame_end()
    return up(dt)
  end
  love.update = our_update
end

--- Did the device and the event-tracked set disagree about any
--- modifier, as of this event?
--- @return string? name  folded modifier name, if they disagree
--- @return boolean? tracked
--- @return boolean? polled
local function mod_skew()
  local keys = Controller.keys_pressed
  for _, m in ipairs(Key.mod_triples) do
    local held = keys[m[1]] or keys[m[2]]
    local tracked = held and true or false
    local polled = love.keyboard.isDown(m[1], m[2])
    if tracked ~= polled then
      return m[3], tracked, polled
    end
  end
end

local function check_mods()
  local name, tracked, polled = mod_skew()
  if not name then return end
  S.mod_skew = S.mod_skew + 1
  note('modifier ' .. name
    .. ': tracked=' .. tostring(tracked)
    .. ' polled=' .. tostring(polled))
end

-- A key reported up while its own press is being dispatched
-- means press and release shared one pump batch: the fast-tap
-- case, and proof the poll answers on the later clock.
local function check_self(k)
  if love.keyboard.isDown(k) then return end
  S.self_skew = S.self_skew + 1
  note('self ' .. k .. ': already up at its own press')
end

local function on_press(k)
  batch = batch + 1
  S.events = S.events + 1
  check_self(k)
  check_mods()
end

local function on_release()
  batch = batch + 1
  S.events = S.events + 1
  check_mods()
end

-- The original runs first on purpose: the gateway updates
-- Controller.keys_pressed at the top of its own handler, so
-- measuring afterwards compares the two sources as every
-- downstream consumer saw them for this event.
local function wrap(name, measure)
  local orig = love.handlers[name]
  if not orig then return end
  love.handlers[name] = function(...)
    ensure_update()
    local r = orig(...)
    measure(...)
    return r
  end
end

local function report()
  print('[probe] frames=' .. S.frames
    .. ' key events=' .. S.events)
  print('[probe] frames with >1 key event=' .. S.multi
    .. ' max in one frame=' .. S.batch_max)
  print('[probe] self-skew=' .. S.self_skew
    .. ' modifier-skew=' .. S.mod_skew)
end

local installed = false

local function install()
  if installed then
    print('[probe] already installed')
    return
  end
  installed = true
  wrap('keypressed', on_press)
  wrap('keyreleased', on_release)
  ensure_update()
  _G.probe_report = report
  print('[probe] installed — call probe_report() for totals')
end

return {
  install = install,
  report = report,
  stats = S,
}
