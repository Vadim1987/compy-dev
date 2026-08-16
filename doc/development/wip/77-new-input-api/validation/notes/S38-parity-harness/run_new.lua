HARNESS_DIR = HARNESS_DIR or "./"
dofile(HARNESS_DIR .. "drive_new.lua")

for _, set in ipairs(MODSETS) do
  for _, trig in ipairs(TRIGGERS) do
    local dup = false
    for _, m in ipairs(set) do if m == trig then dup = true end end
    if not dup then
      reboot()
      HELD = {}
      LOG = {}
      for _, m in ipairs(set) do
        HELD[m] = true
        PIC:keypressed(m, m, false)
      end
      LOG = {}
      HELD[trig] = true
      PIC:keypressed(trig, trig, false)
      print(modname(set) .. " | " .. trig .. " => "
        .. (#LOG == 0 and "-" or table.concat(LOG, " ; ")))
    end
  end
end
