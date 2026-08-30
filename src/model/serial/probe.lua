--- Device check for the serial API. Not part of the API and
--- not meant to survive review: it prints what arrives on
--- the platform port and sends one line once connected.
---
--- serial_probe()            print events, send PING
--- serial_probe('print(1)')  same, but send that line
--- serial_probe(false)       stop printing, release fields
--- serial_stats()            read-path counters and knobs
--- serial_stats(true)        the same, then zero counters
--- serial_tune{read_ms=50}   change knobs on the live port

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

--- @param t number?
--- @return string
local function ago(t)
  if not t then return 'never' end
  return string.format('%.1fs ago', love.timer.getTime() - t)
end

--- What the platform port's read path did so far, and how
--- it is set. Backends without counters say so.
--- @param reset boolean?
function serial_stats(reset)
  local b = SerialPort.backend
  if not b.stats then
    print('stats: none on this backend')
    return
  end
  local s, t = b.stats, b.tune
  print(string.format(
    'stats: polls %d reads %d got %d empty %d neg %d bytes %d',
    s.polls, s.reads, s.got, s.empty, s.neg, s.bytes))
  print('stats: sends ' .. s.sends .. ', last byte ' ..
    ago(s.last_got_at) .. ', last send ' .. ago(s.last_send_at))
  print(string.format(
    'tune: read_ms %d read_size %d gap_s %.3f drain %s',
    t.read_ms, t.read_size, t.gap_s, tostring(t.drain)))
  if reset then
    b:resetStats()
    print('stats: zeroed')
  end
end

--- Change read-path knobs on the live port, e.g.
--- serial_tune{read_ms = 50, gap_s = 0.05, drain = true}.
--- An unknown key is an error, so a typo cannot pass quietly.
--- @param t table
function serial_tune(t)
  local b = SerialPort.backend
  if not b.tune then
    print('tune: none on this backend')
    return
  end
  for k, v in pairs(t or {}) do
    if b.tune[k] == nil then
      error('tune: no such knob ' .. tostring(k))
    end
    b.tune[k] = v
  end
  serial_stats()
end
