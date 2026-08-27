--- Device check for the serial API. Not part of the API and
--- not meant to survive review: it prints what arrives on
--- the platform port and sends one line once connected.
---
--- serial_probe()            print events, send PING
--- serial_probe('print(1)')  same, but send that line
--- serial_probe(false)       stop printing, release fields

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
  local cs = SerialPort:table_for('console')
  if arg == false then
    cs.onConnect = nil
    cs.onDisconnect = nil
    cs.onLine = nil
    cs.onBytes = nil
    print('probe: stopped')
    return
  end
  local line = type(arg) == 'string' and arg or 'PING'
  local hello = function(info)
    print('probe: connected ' ..
      tostring(info and info.name or 'already'))
    if info and info.acm then
      print('probe: acm refused, ' .. info.acm)
    end
    local ok, err = cs.send(line .. '\r')
    print('probe: sent ' .. line .. ' -> ' ..
      tostring(ok) .. ' ' .. tostring(err))
  end
  cs.onConnect = hello
  cs.onDisconnect = function()
    print('probe: disconnected')
  end
  cs.onLine = function(l)
    print('probe: line [' .. l .. ']')
  end
  cs.onBytes = function(chunk)
    print('probe: bytes ' .. #chunk .. ' ' .. hex_of(chunk))
  end
  if cs.isConnected() then
    hello()
  else
    print('probe: started, plug the micro:bit in')
  end
end
