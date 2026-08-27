-- Serial terminal: the demonstration project for the
-- compy.serial API. The terminal above prints everything
-- arriving over USB serial; the console below takes a
-- syntactically complete Lua chunk and Enter sends the
-- whole chunk down the line. With the Lua REPL firmware on
-- the micro:bit this is remote execution: write Lua on
-- Compy, it runs on the board.

local serial = compy.serial

serial.onConnect = function(info)
  print('[connected ' .. tostring(info and info.name) .. ']')
end

serial.onDisconnect = function()
  print('[disconnected]')
end

serial.onLine = function(l)
  print(l)
end

if serial.isConnected() then
  print('[device already connected]')
else
  print('[plug the micro:bit in]')
end

local r = user_input()

function love.update()
  if r:is_empty() then
    input_code('lua> ')
  else
    local chunk = r()
    -- the board's REPL runs a line on carriage return, so
    -- a multiline chunk goes out line by line and the REPL
    -- assembles it through its own continuation
    local ok, err = serial.send(chunk:gsub('\n', '\r') .. '\r')
    if not ok then
      print('[send failed: ' .. tostring(err) .. ']')
    end
  end
end
