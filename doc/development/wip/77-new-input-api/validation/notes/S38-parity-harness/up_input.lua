-- Input lifecycle and event model.
--
-- The IDE keeps key-repeat enabled and strips the isrepeat flag
-- before calling the game, so repeats are filtered here by
-- edge tracking: a key already in INPUT.held is a repeat and is
-- ignored completely. The game does NOT disable global
-- key-repeat (the runner exposes no project-exit cleanup hook
-- to restore it on Ctrl+Esc force-exit; see Beads
-- compy-keyboard-exit-hook). Text input is enabled to match
-- the IDE default (restoring it on exit is a no-op).
--
-- Ordering: the IDE delivers textinput BEFORE the matching
-- keypress (the reverse of desktop LOVE). So a "fresh keypress
-- arms a gate, its textinput consumes it" scheme cannot work --
-- the glyph arrives before anything arms it, and after a chord
-- (which clears such a gate) the next target is dropped. So
-- textinput is judged directly, with no gate. An Alt+key chord
-- is swallowed in appChord (the keypress) AND its glyph dropped
-- in appTextinput (a chord glyph CAN surface and is never a
-- target), so a chord cannot fumble a target. A held key emits
-- textinput; since textinput precedes the fresh keypress, the
-- producing key is in INPUT.held when a repeat arrives, so the
-- scene drops it. The release boundary still leaks, though: a
-- final key-repeat glyph can arrive just after its keyup, so a
-- key is "stale" for a frame after release (INPUT.upRecent);
-- inputStale() drops input for a held OR just-released key.
--
-- Held modifier edges are the source of truth for
-- modifier-dependent acceptance and for Caps reconciliation.

INPUT = {
  held = { }, upRecent = { },
  shift = false, ctrl = false, alt = false
}

-- A key stays "stale" this many frames after its release, to
-- swallow a final key-repeat glyph arriving just after keyup.
INPUT_UP_GRACE = 1

function inputInit()
  love.keyboard.setTextInput(true)
  INPUT.held = { }
  INPUT.upRecent = { }
  INPUT.shift = false
  INPUT.ctrl = false
  INPUT.alt = false
end

function modHeld(a, b)
  if INPUT.held[a] or INPUT.held[b] then
    return true
  end
  return false
end

function isMod(k)
  return k == "lshift" or k == "rshift"
    or k == "lctrl" or k == "rctrl"
    or k == "lalt" or k == "ralt"
end

function inputUpdateMods()
  INPUT.shift = modHeld("lshift", "rshift")
  INPUT.ctrl = modHeld("lctrl", "rctrl")
  INPUT.alt = modHeld("lalt", "ralt")
end

function goBack()
  if isGameScene(ACTIVE) then
    gotoScene("menu")
  end
end

function notchAdjust(delta)
  local s = SCENES[ACTIVE]
  if s and s.onNotch then s.onNotch(delta) end
end

-- Reserved chords are handled before scene input, keyed on the
-- non-modifier key so a held Shift during a letter falls
-- through to the scene.
function reservedChord(k)
  if k == "escape" and INPUT.shift and not INPUT.ctrl then
    goBack()
    return true
  end
  if INPUT.ctrl and INPUT.alt and k == "up" then
    notchAdjust(1)
    return true
  end
  if INPUT.ctrl and INPUT.alt and k == "down" then
    notchAdjust(-1)
    return true
  end
  return false
end

-- Alt+key (without Ctrl) is a chord, never a typed target, so
-- swallow it here. Alt+P toggles the modal pause on a timed
-- scene (a no-op elsewhere); Alt+H peeks help (via helpHeld).
-- Ctrl+Alt+H stays unconsumed, for the scene's hint re-arm.
function appChord(k)
  if INPUT.ctrl then return false end
  if not INPUT.alt then return false end
  if k == "p" then pauseToggle() end
  return true
end

-- A key is "stale" (a repeat, not a fresh press) while held
-- or for INPUT_UP_GRACE frames after its release -- the latter
-- catches a final key-repeat glyph delivered just after keyup.
function inputStale(k)
  if INPUT.held[k] then return true end
  local up = INPUT.upRecent[k]
  if not up then return false end
  return DBG_FRAME - up <= INPUT_UP_GRACE
end

-- capslock is exempt from the stale filter (its release may not
-- arrive, wedging the set and freezing Caps). Scene input is
-- also dropped while the help overlay is up (the game is frozen
-- behind it).
function appKeypressed(k)
  if inputStale(k) and k ~= "capslock" then return end
  dbgLog("KP " .. k)
  INPUT.held[k] = true
  inputUpdateMods()
  if reservedChord(k) then return end
  if appChord(k) then return end
  if k == "capslock" then capsToggle() end
  if PAUSED then return end
  if helpOverlayShown() then return end
  local s = SCENES[ACTIVE]
  if s and s.keypressed then s.keypressed(k) end
end

function appKeyreleased(k)
  dbgLog("KR " .. k)
  INPUT.held[k] = nil
  INPUT.upRecent[k] = DBG_FRAME
  inputUpdateMods()
  local s = SCENES[ACTIVE]
  if s and s.keyreleased then s.keyreleased(k) end
end

-- textinput is judged by the scene (the per-glyph stale filter
-- lives there); dropped here while paused or behind help. A
-- glyph made with Alt or Ctrl held is a chord, never a target
-- (only Shift modifies a target), so drop it too.
function appTextinput(t)
  if PAUSED then return end
  if INPUT.alt then return end
  if INPUT.ctrl then return end
  if helpOverlayShown() then return end
  dbgLog("TI " .. t .. " sh=" .. tostring(INPUT.shift))
  if isAlphaChar(t) then
    capsReconcile(t, INPUT.shift)
  end
  local s = SCENES[ACTIVE]
  if s and s.textinput then s.textinput(t) end
end
