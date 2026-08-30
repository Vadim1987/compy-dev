-- Serial terminal: the demonstration project for the
-- compy.serial API. The terminal above shows everything
-- arriving over USB serial, partial lines included; the
-- field below takes a syntactically complete Lua chunk and
-- Enter sends the whole chunk down the line. With the Lua
-- REPL firmware on the micro:bit this is remote execution.
--
-- Diagnostic build: every chunk is printed as byte values
-- before it is turned into text, and the chunk handed to
-- send is printed the same way. A byte lost in the input
-- field and a byte lost on the wire look alike as text and
-- differ here: a short tx means the field mangled it, a
-- whole tx with a short rx means the line did.

local serial = compy.serial

--- Byte values, so a damaged chunk stays readable and
--- terminators remain visible
--- @param chunk string
--- @return string
local function hex_of(chunk)
  local out = {}
  for i = 1, #chunk do
    out[i] = string.format('%02X', string.byte(chunk, i))
  end
  return table.concat(out, ' ')
end

-- Everything means everything: bytes are assembled into
-- lines here, and a tail that stays unterminated (the
-- REPL's "> " prompt, partial output) is shown after a
-- short settle instead of waiting for a terminator.
local tail = ''
local settle = 0

serial.onBytes = function(chunk)
  print('rx ' .. #chunk .. ' ' .. hex_of(chunk))
  local text = chunk:gsub('\r\n', '\n'):gsub('\r', '\n')
  tail = tail .. text
  while true do
    local line, rest = tail:match('^([^\n]*)\n(.*)$')
    if not line then break end
    print(line)
    tail = rest
  end
  settle = 0.2
end

function love.update(dt)
  if tail == '' then return end
  settle = settle - dt
  if settle <= 0 then
    print(tail)
    tail = ''
  end
end

serial.onConnect = function(info)
  print('[connected ' .. tostring(info and info.name) .. ']')
end

serial.onDisconnect = function()
  print('[disconnected]')
end

if serial.isConnected() then
  print('[device already connected]')
else
  print('[plug the micro:bit in]')
end

compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  prompt = 'lua> ',
  validator = LuaSyntaxValidator,
  highlighter = LuaHighlighter,
  on_text_entered = function(lines)
    local chunk = table.concat(lines, '\r') .. '\r'
    print('tx ' .. #chunk .. ' ' .. hex_of(chunk))
    local ok, err = serial.send(chunk)
    if not ok then
      print('[send failed: ' .. tostring(err) .. ']')
    end
  end,
}
