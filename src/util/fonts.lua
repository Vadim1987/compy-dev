require("util.table")

local font_dir = "assets/fonts/"

local default = font_dir .. "ubuntu_mono_bold_nerd.ttf"
local nerdfont = font_dir .. "SFMonoNerdFontMono-Regular.otf"
local cjkfont = font_dir .. "SarasaGothicJ-Bold.ttf"
local userfonts = {
  mono = default,
  retro = font_dir .. "PressStart2P-Regular.ttf",
  sans = font_dir .. "FreeSansBold.ttf",
  serif = font_dir .. "FreeSerifBold.ttf",
}

local fonts = {
  main = default,
  icon = nerdfont,
  cjk = cjkfont,
  user = userfonts,

  default_size = 32.4,
  label_size = 12,
}

return table.clone(fonts)
