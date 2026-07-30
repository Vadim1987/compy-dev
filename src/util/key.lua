require("util.table")

local unpack  = unpack or table.unpack

local shift_k = { "lshift", "rshift" }
local ctrl_k  = { "lctrl", "rctrl" }
local alt_k   = { "lalt", "ralt" }
-- gui = super/cmd/win. Kept in the modifier set for parity with ctrl/alt/shift so
-- combo_string can serialise gui-combos; no shortcut registers one yet.
local gui_k   = { "lgui", "rgui" }

-- Single source of truth for left/right modifier folding. Each row is
-- { left-key, right-key, generic-name }; combo_string folds e.g. lctrl|rctrl -> "ctrl"
-- (precedence order: ctrl, alt, shift, gui). This is the single
-- source shared by combo registration and dispatch.
local mod_triples = {
  { ctrl_k[1],  ctrl_k[2],  "ctrl" },
  { alt_k[1],   alt_k[2],   "alt" },
  { shift_k[1], shift_k[2], "shift" },
  { gui_k[1],   gui_k[2],   "gui" },
}

-- Generic modifier names in combo-string precedence order
-- (doc/development/decisions/input.md, Decision 8: ctrl < alt < shift <
-- gui), and the l/r fold that maps held key-names onto
-- them ('lctrl' -> 'ctrl').
local mod_rank = {
  ctrl = 1, alt = 2, shift = 3, gui = 4,
}
local mod_order = { 'ctrl', 'alt', 'shift', 'gui' }
local fold_mod = { }
for _, row in ipairs(mod_triples) do
  fold_mod[row[1]] = row[3]
  fold_mod[row[2]] = row[3]
end

--- Split a combo string into a generic-modifier set and the
--- trigger token. Tokens fold l/r to generic names; anything
--- that is not a modifier is the trigger (last one wins).
--- @param combo string
--- @return table mods
--- @return string? trigger
local function split_combo(combo)
  local mods, trigger = { }, nil
  for tok in combo:lower():gmatch('[^+]+') do
    local g = fold_mod[tok] or tok
    if mod_rank[g] then mods[g] = true else trigger = g end
  end
  return mods, trigger
end

--- Canonicalise a combo string (doc/development/decisions/input.md,
--- Decision 8): lower-cased, l/r folded, modifiers in
--- fixed precedence, trigger last, '+'-joined. 'Ctrl+S' ->
--- 'ctrl+s'; bare 'S' -> 's'. Matches what combo_string()
--- (controller.lua) emits at dispatch.
--- @param combo string
--- @return string
local function normalize_combo(combo)
  local mods, trigger = split_combo(combo)
  local parts = { }
  for _, name in ipairs(mod_order) do
    if mods[name] then parts[#parts + 1] = name end
  end
  if trigger then parts[#parts + 1] = trigger end
  return table.concat(parts, '+')
end

--- A project handlers sub-table (doc/development/decisions/input.md,
--- Decision 8): assigned combo keys normalise on
--- registration, so handlers.keypressed['Ctrl+S'] is
--- stored (and dispatch-matched) as 'ctrl+s'.
--- The matcher uses exact canonical lookup (O(1)).
--- @return table
local function new_handler_table()
  return setmetatable({ }, {
    __newindex = function(t, k, v)
      rawset(t, normalize_combo(k), v)
    end,
  })
end

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
  normalize_combo = normalize_combo,
  new_handler_table = new_handler_table,
  is_enter    = is_enter,
  shift       = shift,
  is_shift    = is_shift,
  ctrl        = ctrl,
  is_ctrl     = is_ctrl,
  alt         = alt,
  is_alt      = is_alt,
}
