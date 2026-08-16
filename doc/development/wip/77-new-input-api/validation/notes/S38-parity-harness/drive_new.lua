-- Boot the new input.lua on the REAL platform dispatcher.
-- Returns a `press(key, isrepeat)` driver.
dofile(HARNESS_DIR .. "common.lua")

require("util.class")
require("util.key")

-- combo_string / any_mod: copied verbatim from src/controller/controller.lua
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
require("controller.projectInputController")

-- fn combinators: copied verbatim from src/controller/consoleController.lua
INPUT_FN = {
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

compy = { input = { hooks = {}, fn = INPUT_FN, shortcuts = {} } }

dofile("/repo/src/examples/keyboard/input.lua")
goBack = function() note("goBack") end
notchAdjust = function(d) note("notchAdjust " .. d) end

PIC = ProjectInputController()

function reboot()
  compy.input.shortcuts = {}
  for _, e in ipairs(ProjectInputController.EVENTS) do
    compy.input.shortcuts[e] = Key.new_handler_table()
  end
  compy.input.hooks = {}
  inputInit()
  PIC:activate({}, compy.input)
end
