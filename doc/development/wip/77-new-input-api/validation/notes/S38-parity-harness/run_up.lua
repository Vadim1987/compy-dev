HARNESS_DIR = HARNESS_DIR or "./"
dofile(HARNESS_DIR .. "common.lua")

-- upstream input.lua verbatim (git show 025e858:input.lua)
dofile(HARNESS_DIR .. "up_input.lua")

goBack = function() note("goBack") end
notchAdjust = function(d) note("notchAdjust " .. d) end

-- upstream alt.lua handled Ctrl+Alt+H inside its own keypressed.
local base_scene_kp = SCENES.alt.keypressed
SCENES.alt.keypressed = function(k)
  if k == "h" and INPUT.ctrl and INPUT.alt then
    note("onHint")
    return
  end
  base_scene_kp(k)
end

for _, set in ipairs(MODSETS) do
  for _, trig in ipairs(TRIGGERS) do
    local dup = false
    for _, m in ipairs(set) do if m == trig then dup = true end end
    if not dup then
      inputInit()
      HELD = {}
      LOG = {}
      for _, m in ipairs(set) do
        HELD[m] = true
        appKeypressed(m)
      end
      LOG = {}
      HELD[trig] = true
      appKeypressed(trig)
      print(modname(set) .. " | " .. trig .. " => "
        .. (#LOG == 0 and "-" or table.concat(LOG, " ; ")))
    end
  end
end
