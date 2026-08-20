require('model.serial.init')
require('model.serial.backend_android')

--- Device check for the serial API. Not part of the API and
--- not meant to survive review: it opens a port, prints what
--- the callbacks report, and sends one line once connected.
---
--- serial_probe()            start, print events, send PING
--- serial_probe('print(1)')  same, but send that line
--- serial_probe(false)       stop and release

--- Byte values, so an unprintable reply is still readable
--- @param chunk string
--- @return string
local function hex_of(chunk)
  local out = {}
  for i = 1, #chunk do
    out[i] = string.format('%02X', string.byte(chunk, i))
  end
  return table.concat(out, ' ')
end

--- @param arg string|boolean|nil
function serial_probe(arg)
  if arg == false then
    if SerialPort then SerialPort:stop() end
    SerialPort = nil
    print('probe: stopped')
    return
  end
  if SerialPort then
    print('probe: already running, stop it with false')
    return
  end
  local line = type(arg) == 'string' and arg or 'PING'
  SerialPort = Serial.new(AndroidBackend.new())
  SerialPort:onConnect(function(info)
    print('probe: connected ' .. tostring(info and info.name))
    if info and info.acm then
      print('probe: acm refused, ' .. info.acm)
    end
    local ok, err = SerialPort:send(line .. '\r')
    print('probe: sent ' .. line .. ' -> ' ..
      tostring(ok) .. ' ' .. tostring(err))
  end, 'console')
  SerialPort:onDisconnect(function()
    print('probe: disconnected')
  end, 'console')
  SerialPort:onLine(function(l)
    print('probe: line [' .. l .. ']')
  end, 'console')
  SerialPort:onBytes(function(chunk)
    print('probe: bytes ' .. #chunk .. ' ' .. hex_of(chunk))
  end, 'console')
  print('probe: started, plug the micro:bit in')
end
