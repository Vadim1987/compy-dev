-- editor.lua
-- Minimal single-line editor matching Compy's built-in style.
-- Does NOT use input_text(), so love.keypressed fires normally.

ED = {
  text = "",
  cursor = 0,
  prompt = "estimate>",
  on_submit = nil,
  on_escape = nil,
}

-- Font and layout (matching Compy's built-in editor)
-- Use the font Compy already set as default.

ED_FONT = nil
ED_FH = 0
ED_FW = 0

function edInitFont()
  if ED_FONT then return end
  ED_FONT = gfx.getFont()
  ED_FH = ED_FONT:getHeight()
  ED_FW = ED_FONT:getWidth("W")
end

-- Colors matching Compy's user input colors

ED_COL = {
  bg = Color[Color.white],
  fg = Color[Color.black + Color.bright],
  cursor = Color[Color.white + Color.bright],
  status_bg = Color[Color.blue],
  status_fg = Color[Color.white],
}

-- Text manipulation

function edInsert(ch)
  local before = ED.text:sub(1, ED.cursor)
  local after = ED.text:sub(ED.cursor + 1)
  ED.text = before .. ch .. after
  ED.cursor = ED.cursor + #ch
end

function edBackspace()
  if ED.cursor == 0 then return end
  local before = ED.text:sub(1, ED.cursor - 1)
  local after = ED.text:sub(ED.cursor + 1)
  ED.text = before .. after
  ED.cursor = ED.cursor - 1
end

function edClear()
  ED.text = ""
  ED.cursor = 0
end

-- Cursor movement

function edLeft()
  if ED.cursor > 0 then
    ED.cursor = ED.cursor - 1
  end
end

function edRight()
  if ED.cursor < #ED.text then
    ED.cursor = ED.cursor + 1
  end
end

-- Set editor text (e.g., to restore previous input)

function edSetText(text)
  ED.text = text or ""
  ED.cursor = #ED.text
end

-- Key dispatch table

ED_KEYS = {
  backspace = edBackspace,
  left = edLeft,
  right = edRight,
  home = function() ED.cursor = 0 end,
  ["end"] = function() ED.cursor = #ED.text end,
  ["return"] = function()
    if ED.on_submit then ED.on_submit(ED.text) end
  end,
  escape = function()
    if ED.on_escape then ED.on_escape() end
  end,
}

function edKeypressed(k)
  local action = ED_KEYS[k]
  if action then action() end
end

-- Handle text input (printable characters)

function love.textinput(t)
  edInsert(t)
end

-- Draw the statusline (prompt bar)

function drawStatusline()
  local w = gfx.getWidth()
  local h = gfx.getHeight()
  local y = h - 2 * ED_FH
  gfx.setColor(ED_COL.status_bg)
  gfx.rectangle("fill", 0, y, w, ED_FH)
  gfx.setFont(ED_FONT)
  gfx.setColor(ED_COL.status_fg)
  gfx.print(ED.prompt, 0, y)
end

-- Draw the text input area

function drawEditorText()
  local w = gfx.getWidth()
  local h = gfx.getHeight()
  local y = h - ED_FH
  gfx.setColor(ED_COL.bg)
  gfx.rectangle("fill", 0, y, w, ED_FH)
  gfx.setFont(ED_FONT)
  gfx.setColor(ED_COL.fg)
  gfx.print(ED.text, 0, y)
  drawEditorCursor(y)
end

-- Draw the cursor

function drawEditorCursor(y)
  local x = ED.cursor * ED_FW - ED_FW / 2
  gfx.setColor(ED_COL.cursor)
  gfx.print("|", x, y)
end

-- Draw the complete editor

function drawEditor()
  edInitFont()
  drawStatusline()
  drawEditorText()
end
