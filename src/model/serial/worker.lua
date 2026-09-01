--- The Android USB backend, running on a thread of its own.
---
--- Why: a read issued from the frame loop is cancelled a
--- few milliseconds later and reissued on the next frame,
--- so for most of every frame no request is outstanding and
--- the tail of a reply waits on the device until the next
--- write pushes it out. Here the read blocks, comes back
--- the moment bytes arrive, and is reissued at once, so a
--- request stands almost always — the way a desktop CDC
--- driver reads the same board.
---
--- JNIEnv is thread-local and the port caches it, so the
--- port is opened here and never crosses back. What crosses
--- are two channels of plain tables: events out, commands
--- in. Nothing else is shared.
---
--- BLIND-CODED: not yet verified on a device.

require('love.timer')
require('love.thread')
require('util.jni')
require('model.serial.backend_android')

local rx_name, tx_name, read_ms, stats_s = ...

local rx = love.thread.getChannel(rx_name)
local tx = love.thread.getChannel(tx_name)

--- Idle spin guard: with no device open, poll returns at
--- once, and nothing should burn a core for that
local IDLE_S = 0.05

--- @param kind string
--- @param a any
local function post(kind, a)
  rx:push({ kind = kind, a = a })
end

--- Backend events, on their way to the main thread. Only
--- the device name crosses, not the JNI handle behind it.
local sink = {
  attach = function(info)
    post('attach', info and info.name)
  end,
  detach = function()
    post('detach')
  end,
  bytes = function(chunk)
    post('bytes', chunk)
  end,
}

local backend = AndroidBackend.new()
backend:setTune('read_ms', read_ms)
backend:start(sink)

local running = true

--- Commands from the main thread, one handler per kind
local commands = {}

commands.send = function(cmd)
  local ok, err = backend:send(cmd.a)
  if not ok then post('fault', err) end
end

commands.tune = function(cmd)
  backend:setTune(cmd.a, cmd.b)
end

commands.reset = function()
  backend:resetStats()
end

commands.stop = function()
  running = false
end

local function take_commands()
  while true do
    local cmd = tx:pop()
    if not cmd then return end
    local fn = commands[cmd.kind]
    if fn then fn(cmd) end
  end
end

--- Counters cross on a timer, so serial_stats has
--- something recent to print without asking
local due = 0
local function report()
  local t = love.timer.getTime()
  if t < due then return end
  due = t + stats_s
  post('stats', backend.stats)
end

while running do
  take_commands()
  local fault = backend:poll()
  if fault then post('fault', fault) end
  report()
  if backend.state ~= 'open' then
    love.timer.sleep(IDLE_S)
  end
end

backend:stop()
post('closed')
