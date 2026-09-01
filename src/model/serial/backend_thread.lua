require('love.thread')

--- The Android backend as seen from the frame loop: same
--- contract as any other backend, with the work happening
--- on the thread in model/serial/worker.lua.
---
--- poll() drains what the worker posted since the last
--- frame and hands it to the sink, so delivery order and
--- the dispatcher stay exactly as before.
---
--- send() is the one difference worth knowing: the write
--- happens on the worker, so this returns as soon as the
--- command is queued and a refused write comes back later
--- as a fault instead of a return value. The frame never
--- waits on the cable.
---
--- BLIND-CODED: not yet verified on a device.

--- @class ThreadBackend
--- @field new function
--- @field start function
--- @field poll function
--- @field send function
--- @field stop function
ThreadBackend = {}
ThreadBackend.__index = ThreadBackend

local RX_NAME = 'serial-rx'
local TX_NAME = 'serial-tx'
local WORKER = 'model/serial/worker.lua'
--- Long enough that a request stands nearly always, short
--- enough that a queued send waits no longer than a blink
local READ_MS = 100
local STATS_S = 1

--- @return ThreadBackend
function ThreadBackend.new()
  local self = setmetatable({}, ThreadBackend)
  self.rx = love.thread.getChannel(RX_NAME)
  self.tx = love.thread.getChannel(TX_NAME)
  self.thread = nil
  self.sink = nil
  self.stats = nil
  self.told_crash = false
  return self
end

--- @param sink table
function ThreadBackend:start(sink)
  self.sink = sink
  self.rx:clear()
  self.tx:clear()
  self.thread = love.thread.newThread(WORKER)
  self.thread:start(RX_NAME, TX_NAME, READ_MS, STATS_S)
end

--- Worker events, one handler per kind
local events = {}

events.attach = function(self, e)
  self.sink.attach({ name = e.a })
end

events.detach = function(self)
  self.sink.detach()
end

events.bytes = function(self, e)
  self.sink.bytes(e.a)
end

events.stats = function(self, e)
  self.stats = e.a
end

--- A thread that died takes the port with it, so say so
--- once and stay quiet afterwards
--- @return string? fault
function ThreadBackend:crash()
  if self.told_crash or not self.thread then return end
  local err = self.thread:getError()
  if not err then return end
  self.told_crash = true
  return 'serial thread: ' .. err
end

--- @return string? fault
function ThreadBackend:poll()
  local fault = self:crash()
  while true do
    local e = self.rx:pop()
    if not e then return fault end
    local fn = events[e.kind]
    if fn then fn(self, e) end
    if e.kind == 'fault' then fault = fault or e.a end
  end
end

--- Queued, not written here: see the note at the top
--- @param data string
--- @return boolean ok
function ThreadBackend:send(data)
  self.tx:push({ kind = 'send', a = data })
  return true
end

--- @param k string
--- @param v any
function ThreadBackend:setTune(k, v)
  self.tx:push({ kind = 'tune', a = k, b = v })
end

function ThreadBackend:resetStats()
  self.tx:push({ kind = 'reset' })
  self.stats = nil
end

function ThreadBackend:stop()
  if not self.thread then return end
  self.tx:push({ kind = 'stop' })
  self.thread:wait()
  self.thread = nil
end
