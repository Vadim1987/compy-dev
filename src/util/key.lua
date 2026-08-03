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

--- Split a combo string into a generic-modifier set, the trigger
--- token, and how many triggers were seen. Tokens fold l/r to
--- generic names; anything that is not a modifier is a trigger.
--- The count is what lets registration refuse a combo naming two
--- of them — dispatch itself only ever splits its own output.
--- @param combo string
--- @return table mods
--- @return string? trigger
--- @return integer triggers
local function split_combo(combo)
  local mods, trigger, n = { }, nil, 0
  for tok in combo:lower():gmatch('[^+]+') do
    local g = fold_mod[tok] or tok
    if mod_rank[g] then
      mods[g] = true
    else
      trigger, n = g, n + 1
    end
  end
  return mods, trigger, n
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

--- A combo names modifiers plus exactly ONE trigger
--- (doc/development/decisions/input.md, Decision 21). Refused at
--- registration rather than silently canonicalised, because the
--- canonical form used to keep the LAST trigger and drop the
--- rest: 'ctrl+a+b' became 'ctrl+b', and 'a+b+*' became a bare
--- '*' — the widest binding there is, from a string written to
--- mean the narrowest.
---
--- A bare '*' is refused for a different reason: it satisfies
--- the one-trigger rule but is the class of "no modifiers
--- held", i.e. every unmodified key. That is what hooks[event]
--- already is, by a spelling that reads like a narrow binding.
--- @param combo string
local function check_combo(combo)
  local mods, trigger, n = split_combo(combo)
  if n == 1 then
    if trigger ~= '*' or next(mods) then return end
    error("bad combo '*': a class needs modifiers to be a"
      .. ' class of (e.g. alt+*); for every key, use'
      .. ' compy.input.hooks', 4)
  end
  local why = (n == 0) and 'names no trigger'
      or 'names more than one trigger'
  error("bad combo '" .. tostring(combo) .. "': " .. why
    .. ' (modifiers plus one trigger, e.g. ctrl+alt+s'
    .. ' or ctrl+alt+*)', 4)
end

--- A project handlers sub-table (doc/development/decisions/input.md,
--- Decision 8): assigned combo keys normalise on
--- registration, so handlers.keypressed['Ctrl+S'] is
--- stored (and dispatch-matched) as 'ctrl+s'.
--- The matcher uses exact canonical lookup (O(1)), plus one
--- class lookup on a miss (Decision 21).
--- @return table
local function new_handler_table()
  return setmetatable({ }, {
    __newindex = function(t, k, v)
      check_combo(k)
      rawset(t, normalize_combo(k), v)
    end,
  })
end

--- @param k string
--- @return boolean
local function is_enter(k)
  return k == "return" or k == 'kpenter'
end

--- Whether a key name is any modifier, l/r alike. A combo class
--- (Decision 21) must not match its own modifier: holding Alt
--- alone dispatches 'alt+lalt', the modifier prepended to itself
--- as the trigger, which 'alt+*' would otherwise catch.
--- @param k string
--- @return boolean
local function is_mod(k)
  return fold_mod[k] ~= nil
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
  is_mod      = is_mod,
  shift       = shift,
  is_shift    = is_shift,
  ctrl        = ctrl,
  is_ctrl     = is_ctrl,
  alt         = alt,
  is_alt      = is_alt,
}
