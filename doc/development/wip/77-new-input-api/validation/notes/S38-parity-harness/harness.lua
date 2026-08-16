-- Read-only instrument: drives the REAL platform dispatch chain
-- (projectInputController + util/key) over the REAL game input.lua.
package.path = '/repo/src/?.lua;' .. package.path

----------------------------------------------------------------
-- love stub: only what is touched; isDown mimics measured LOVE
----------------------------------------------------------------
local RAISES = {}
for c in ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('.') do RAISES[c] = true end
RAISES['~'] = true; RAISES['{'] = true; RAISES['}'] = true
RAISES['|'] = true; RAISES[' '] = true

HELD = {}
local ISDOWN_CALLS = 0
love = {
  keyboard = {
    setTextInput = function() end,
    isDown = function(...)
      ISDOWN_CALLS = ISDOWN_CALLS + 1
      local n = select('#', ...)
      local any = false
      for i = 1, n do
        local k = select(i, ...)
        if RAISES[k] then error('Invalid key constant: ' .. k) end
        if HELD[k] then any = true end
      end
      return any
    end,
  },
  mouse = { getRelativeMode = function() return false end,
            setRelativeMode = function() end },
  state = {},
}

----------------------------------------------------------------
-- platform: real Key + real dispatch; Controller.* copied verbatim
-- from src/controller/controller.lua:380-424
----------------------------------------------------------------
require('util.table')
require('util.color')
require('util.key')
require('controller.projectInputController')

local COMBO_MODS = Key.mod_triples
local MOD_HELD = { ctrl = Key.ctrl, alt = Key.alt, shift = Key.shift }
Controller = {
  combo_string = function(k)
    local parts = {}
    for _, m in ipairs(COMBO_MODS) do
      if MOD_HELD[m[3]]() then parts[#parts + 1] = m[3] end
    end
    parts[#parts + 1] = k
    return table.concat(parts, '+')
  end,
  any_mod = function()
    for _, m in ipairs(COMBO_MODS) do
      if MOD_HELD[m[3]]() then return true end
    end
    return false
  end,
}

-- INPUT_FN copied verbatim from consoleController.lua:483-508
local INPUT_FN = {
  ignore_repeat = function(fn)
    return function(k, sc, isr)
      if isr then return end
      return fn(k, sc, isr)
    end
  end,
  stop_here = function(fn)
    return function(...)
      if fn then fn(...) end
      return true
    end
  end,
  side_run = function(fn)
    return function(...)
      if fn then fn(...) end
      return false
    end
  end,
}

local shortcuts = {
  keypressed = Key.new_handler_table(),
  keyreleased = Key.new_handler_table(),
  textinput = Key.new_handler_table(),
}
local hooks = {}
compy = { input = { fn = INPUT_FN, shortcuts = shortcuts, hooks = hooks } }

local PIC = ProjectInputController()
PIC.compy_input = { shortcuts = shortcuts, hooks = hooks }

----------------------------------------------------------------
-- game stubs + the real game files
----------------------------------------------------------------
EVENTS = {}
local function log(s) EVENTS[#EVENTS + 1] = s end

PAUSED = false
ACTIVE = 'alt'
function helpOverlayShown()
  return love.keyboard.isDown('h') and Key.alt() and not Key.ctrl()
end
function capsToggle() log('capsToggle') end
function dbgLog() end
function pauseToggle() PAUSED = not PAUSED; log('pauseToggle -> ' .. tostring(PAUSED)) end
function isGameScene() return true end
function gotoScene(n) log('gotoScene ' .. n) end

SCENES = {
  alt = {
    keypressed = function(k) log('scene.keypressed ' .. k) end,
    keyreleased = function(k) log('scene.keyreleased ' .. k) end,
    -- exactly alt.lua/words.lua's first line
    textinput = function(t)
      if spendGlyph(glyphBaseKey(t)) then
        log('dropped "' .. t .. '" (claim)')
        return
      end
      log('SCENE ACCEPTS "' .. t .. '"')
    end,
    onNotch = function(d) log('onNotch ' .. d) end,
    onHint = function() log('onHint') end,
  },
}

dofile('/repo/src/examples/keyboard/config.lua')
dofile('/repo/src/examples/keyboard/indicators.lua')
dofile('/repo/src/examples/keyboard/input.lua')
inputInit()

----------------------------------------------------------------
-- driver
----------------------------------------------------------------
local down = {}
local function press(k, ch)
  local isr = down[k] == true
  down[k] = true; HELD[k] = true
  PIC:keypressed(k, k, isr)
  if ch then PIC:textinput(ch) end
end
local function textfirst(k, ch)
  local isr = down[k] == true
  PIC:textinput(ch)
  down[k] = true; HELD[k] = true
  PIC:keypressed(k, k, isr)
end
local function release(k)
  down[k] = nil; HELD[k] = nil
  PIC:keyreleased(k, k)
end
local function frame() inputTick() end

local function case(name, body)
  EVENTS = {}
  HELD = {}; down = {}
  GLYPH_CLAIMED = {}
  PAUSED = false
  local ok, err = pcall(body)
  if not ok then EVENTS[#EVENTS + 1] = 'RAISED: ' .. tostring(err) end
  print('--- ' .. name)
  for _, e in ipairs(EVENTS) do print('    ' .. e) end
end

-- 1. plain typing, keypress-first order
case('T1 plain "a" keypress-first, then hold 3 frames, release', function()
  press('a', 'a'); frame()
  PIC:textinput('a'); frame()   -- OS repeat glyph
  PIC:textinput('a'); frame()
  release('a'); frame()
  press('a', 'a')
end)

-- 2. plain typing, textinput-first order
case('T2 plain "a" textinput-first', function()
  textfirst('a', 'a'); frame()
  PIC:textinput('a'); frame()
end)

-- 3. doubled letter
case('T3 doubled letter l,l (press/release/press)', function()
  press('l', 'l'); release('l'); frame()
  press('l', 'l'); frame()
end)

-- 4. fast tap: press+text+release all in one frame
case('T4 fast tap (press, text, release in one batch)', function()
  local isr = false
  HELD['a'] = true
  PIC:keypressed('a', 'a', isr)
  PIC:textinput('a')
  HELD['a'] = nil
  PIC:keyreleased('a', 'a')
  frame()
end)

-- 5. shifted symbol in Words (~)
case('T5 shift+` producing "~"', function()
  press('lshift'); press('`', '~'); frame()
  PIC:textinput('~'); frame()
end)

-- 6. Ctrl+Alt+H then release modifiers, H keeps repeating
case('T6 ctrl+alt+h, release ctrl+alt, h repeats', function()
  press('lctrl'); press('lalt'); press('h')
  frame()
  release('lctrl'); release('lalt')
  PIC:keypressed('h', 'h', true); PIC:textinput('h')
  frame()
  PIC:keypressed('h', 'h', true); PIC:textinput('h')
  frame()
end)

-- 7. Alt+H help overlay, release Alt first
case('T7 alt+h overlay, release alt first', function()
  press('lalt'); press('h')
  frame()
  release('lalt')
  PIC:keypressed('h', 'h', true); PIC:textinput('h')
  frame()
end)

-- 8. reserved chords
case('T8 shift+escape / alt+shift+escape', function()
  press('lshift'); press('escape'); release('escape'); release('lshift'); frame()
  press('lalt'); press('lshift'); press('escape'); frame()
end)

case('T9 ctrl+alt+up held (repeat)', function()
  press('lctrl'); press('lalt'); press('up')
  PIC:keypressed('up', 'up', true)
  PIC:keypressed('up', 'up', true)
  frame()
end)

case('T10 alt+p', function()
  press('lalt'); press('p'); PIC:keypressed('p', 'p', true); frame()
end)

case('T11 alt+SHIFT+p  (upstream toggled pause)', function()
  press('lalt'); press('lshift'); press('p'); frame()
end)

case('T12 bare alt press', function()
  press('lalt'); frame()
end)

case('T13 bare shift press', function()
  press('lshift'); frame()
end)

case('T14 ctrl+alt+h while PAUSED', function()
  PAUSED = true
  press('lctrl'); press('lalt'); press('h'); frame()
end)

case('T15 alt+shift+letter (was a wrong-key knock before 42d1a8b)', function()
  press('lalt'); press('lshift'); press('q', 'Q'); frame()
end)

case('T16 capslock repeat', function()
  press('capslock'); PIC:keypressed('capslock', 'capslock', true); frame()
end)

case('T17 re-press faster than one frame (no inputTick between)', function()
  press('a', 'a')
  release('a')
  press('a', 'a')
  frame()
end)

case('T18 unpollable glyph (accented char, no SHIFT_MAP entry)', function()
  RAISES['\195\169'] = true
  PIC:textinput('\195\169')
  PIC:textinput('\195\169')
  frame()
end)

case('T19 held wrong key, keypress-first: does the scene see repeats?', function()
  press('z', 'z'); frame()
  PIC:keypressed('z', 'z', true); PIC:textinput('z'); frame()
end)

print('isDown calls total: ' .. ISDOWN_CALLS)

----------------------------------------------------------------
-- menu -> judging-scene entry, keypress-first order
-- (upstream's INPUT.held suppressed the digit's glyph here)
----------------------------------------------------------------
SCENES.menu = {
  keypressed = function(k)
    local n = tonumber(k)
    if n then log('menu: gotoScene words'); ACTIVE = 'words' end
  end,
}
SCENES.words = {
  textinput = function(t)
    if spendGlyph(glyphBaseKey(t)) then
      log('words: dropped "' .. t .. '"'); return
    end
    log('words: JUDGED "' .. t .. '"  -> wrong char, KNOCK + word marked unclean')
  end,
}

case('T20 press "5" in the menu (keypress-first order)', function()
  ACTIVE = 'menu'
  press('5', '5')
  frame()
end)

case('T21 press "5" in the menu (textinput-first order)', function()
  ACTIVE = 'menu'
  textfirst('5', '5')
  frame()
end)
