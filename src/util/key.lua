require("util.table")

local unpack  = unpack or table.unpack

local shift_k = { "lshift", "rshift" }
local ctrl_k  = { "lctrl", "rctrl" }
local alt_k   = { "lalt", "ralt" }
-- gui = super/cmd/win. Kept in the modifier set for parity with ctrl/alt/shift so
-- combo_string can serialise gui-combos; no framework handler registers one yet.
local gui_k   = { "lgui", "rgui" }

-- Single source of truth for left/right modifier folding. Each row is
-- { left-key, right-key, generic-name }; combo_string folds e.g. lctrl|rctrl -> "ctrl"
-- (precedence order: ctrl, alt, shift, gui). Centralised here in 0.1.0-m2a — it was
-- previously a duplicate COMBO_MODS literal in controller.lua.
local mod_triples = {
  { ctrl_k[1],  ctrl_k[2],  "ctrl" },
  { alt_k[1],   alt_k[2],   "alt" },
  { shift_k[1], shift_k[2], "shift" },
  { gui_k[1],   gui_k[2],   "gui" },
}

--- @param k string
--- @return boolean
local function is_enter(k)
  return k == "return" or k == 'kpenter'
end

--- @return boolean
local function is_shift(k)
  return table.is_member(shift_k, k)
end
--- @return boolean
local function shift()
  ---@diagnostic disable-next-line: param-type-mismatch
  return love.keyboard.isDown(unpack(shift_k))
end

--- @return boolean
local function is_ctrl(k)
  return table.is_member(ctrl_k, k)
end
--- @return boolean
local function ctrl()
  ---@diagnostic disable-next-line: param-type-mismatch
  return love.keyboard.isDown(unpack(ctrl_k))
end

--- @return boolean
local function is_alt(k)
  return table.is_member(alt_k, k)
end
--- @return boolean
local function alt()
  ---@diagnostic disable-next-line: param-type-mismatch
  return love.keyboard.isDown(unpack(alt_k))
end

Key = {
  mod_triples = mod_triples,
  is_enter    = is_enter,
  shift       = shift,
  is_shift    = is_shift,
  ctrl        = ctrl,
  is_ctrl     = is_ctrl,
  alt         = alt,
  is_alt      = is_alt,
}
