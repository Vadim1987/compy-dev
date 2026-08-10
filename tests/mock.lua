require('util.dequeue')
require('util.string.string')
require('util.debug')

local held = {
  lctrl = false,
  rctrl = false,
  lshift = false,
  rshift = false,
  lalt = false,
  ralt = false,
  --- aka Super / Win / Cmd
  lgui = false,
  rgui = false,
}

-- Emacs notation for the left-hand modifiers. The right-hand keys
-- have no letter in it, so a test names the key itself: 'rctrl-x'.
local mods = {
  C = 'lctrl',
  S = 'lshift',
  M = 'lalt',
  rctrl  = 'rctrl',
  rshift = 'rshift',
  ralt   = 'ralt',
}

local W = 1024
local H = 600

--- @param t love
local function mock_love(t)
  local love = {
    keyboard = {
      -- Variadic, as LÖVE's is: Key.ctrl() asks
      -- isDown('lctrl', 'rctrl'), so a one-argument mock silently
      -- answers for the left key alone and no test can hold a
      -- right-hand modifier.
      isDown = function(...)
        for _, k in ipairs({ ... }) do
          if held[k] then return true end
        end
        return false
      end
    },
    graphics = {
      mock = true,
      getWidth = function() return W end,
      getHeight = function() return H end,
      getDimensions = function() return W, H end,
      newCanvas = function() end,
      setCanvas = function() end,
      clear = function() end,
    },
  }
  for k, v in pairs(t) do
    love[k] = v
  end
  _G.love = love
  _G.TESTING = Dequeue()
end

local function release_keys()
  for k, _ in pairs(held) do
    held[k] = false
  end
end

--- @param s string
--- @param press function?
--- @param hold boolean?
--- @param opts table?  e.g. {isrepeat=true, scancode='a'}
local function keystroke(s, press, hold, opts)
  local isrepeat = opts and opts.isrepeat or false
  local scancode = opts and opts.scancode or ''
  local keypress = press or love.keypressed
  local ks = string.split(s, '-')
  for _, v in ipairs(ks) do
    local m = mods[v]
    if m then
      held[m] = true
    else
      keypress(v, scancode, isrepeat)
    end
  end
  if not hold then
    release_keys()
  end
end

--- Emit a textinput(t) event through the installed handler.
--- Independently orderable relative to keypressed
--- (doc/development/internals/user_input.md, "Data flow": no ordering
--- guarantee between keypressed and textinput on real
--- devices).
--- @param t string
--- @param press function?  defaults to love.handlers.textinput
local function textinput(t, press)
  local handler = press
  if not handler and love.handlers then
    handler = love.handlers.textinput
  end
  if handler then handler(t) end
end

return {
  mock_love    = mock_love,
  keystroke    = keystroke,
  textinput    = textinput,
  release_keys = release_keys,
}
