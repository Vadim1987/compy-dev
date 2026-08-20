require('model.serial.init')
require('model.serial.backend_android')

--- Device check for the serial API. Not part of the API and
--- not meant to survive review: it opens a port, prints what
--- the four callbacks report, and sends PING once connected.
---
--- serial_probe()      start, print events, send PING
--- serial_probe('M 40 40 500')  same, then drive the robot
--- serial_probe(false) stop and release

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
    local ok, err = SerialPort:send(line)
    print('probe: sent ' .. line .. ' -> ' ..
      tostring(ok) .. ' ' .. tostring(err))
  end, 'console')
  SerialPort:onDisconnect(function()
    print('probe: disconnected')
  end, 'console')
  SerialPort:onLine(function(l)
    print('probe: line [' .. l .. ']')
  end, 'console')
  print('probe: started, plug the micro:bit in')
end
