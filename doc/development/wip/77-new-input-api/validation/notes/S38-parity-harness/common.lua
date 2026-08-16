-- Shared stubs + stimulus enumeration for the gesture-parity harness.
package.path = "/repo/src/?.lua;" .. package.path

HELD = {}
LOG = {}
function note(s) LOG[#LOG + 1] = s end

VALID = {}
for i = 32, 126 do
  local c = string.char(i)
  if not (c:match("%u") or c == " " or c == "{" or c == "|"
      or c == "}" or c == "~") then
    VALID[c] = true
  end
end
for _, n in ipairs({ "space", "escape", "up", "down", "capslock",
  "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "return",
  "tab", "backspace", "kpenter" }) do
  VALID[n] = true
end

love = {
  keyboard = {
    setTextInput = function() end,
    isDown = function(...)
      for i = 1, select('#', ...) do
        local k = select(i, ...)
        if not VALID[k] then
          error("Invalid key constant: " .. tostring(k))
        end
        if HELD[k] then return true end
      end
      return false
    end,
  },
  state = { user_input_controller = nil },
}

SHIFT_MAP = {
  ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$", ["5"] = "%",
  ["6"] = "^", ["7"] = "&", ["8"] = "*", ["9"] = "(", ["0"] = ")",
  ["`"] = "~", ["-"] = "_", ["="] = "+", ["["] = "{", ["]"] = "}",
  ["\\"] = "|", [";"] = ":", ["'"] = "\"", [","] = "<", ["."] = ">",
  ["/"] = "?",
}
function isAlphaChar(t) return t:match("^%a$") ~= nil end
function isUpperChar(t) return t == t:upper() and t ~= t:lower() end

DBG_FRAME = 0
PAUSED = false
ACTIVE = "alt"
CAPS_STATE = { on = false }
function dbgLog() end
function capsToggle() note("capsToggle") end
function capsReconcile(l, s) note("capsReconcile " .. l .. " " .. tostring(s)) end
function pauseToggle() note("pauseToggle") end
function isGameScene() return true end
function gotoScene() end
function helpOverlayShown() return false end
function altHintReenable() note("hintReenable") end

SCENES = { alt = {
  keypressed = function(k) note("scene.keypressed " .. k) end,
  textinput = function(t) note("scene.textinput " .. t) end,
  keyreleased = function(k) note("scene.keyreleased " .. k) end,
  onNotch = function(d) note("onNotch " .. d) end,
  onHint = function() note("onHint") end,
} }

-- Stimulus space: every modifier subset x a representative trigger set.
MODSETS = {
  {}, { "lctrl" }, { "lalt" }, { "lshift" },
  { "lctrl", "lalt" }, { "lctrl", "lshift" }, { "lalt", "lshift" },
  { "lctrl", "lalt", "lshift" },
}
TRIGGERS = {
  "escape", "up", "down", "p", "h", "a", "1", "capslock",
  "lshift", "lctrl", "lalt", "space", "return", "tab", "/",
}

function modname(set)
  if #set == 0 then return "(none)" end
  return table.concat(set, "+")
end
