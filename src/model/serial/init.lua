require('model.serial.line_reader')
require('model.serial.dispatcher')

--- Backend contract:
---   backend:start(sink)  sink.attach(info), sink.detach(),
---                        sink.bytes(chunk)
---   backend:send(data) -> true | nil, err
---   backend:stop()

--- @class Serial
--- @field new function
--- @field onConnect function
--- @field onDisconnect function
--- @field onBytes function
--- @field onLine function
--- @field send function
--- @field isConnected function
--- @field programPaused function
--- @field programContinued function
--- @field programEnded function
--- @field update function
--- @field stop function
Serial = {}
Serial.__index = Serial

--- @param backend table
--- @param max_line integer?
--- @return Serial
function Serial.new(backend, max_line)
  local self = setmetatable({}, Serial)
  self.backend = backend
  self.reader = LineReader.new(max_line)
  self.dispatcher = Dispatcher.new()
  self.faults = {}
  self.connected = false
  backend:start(self:sink())
  return self
end

--- @return table
function Serial:sink()
  return {
    attach = function(info)
      self.connected = true
      self.reader:reset()
      self.dispatcher:push('connect', info)
    end,
    detach = function()
      self.connected = false
      self.reader:reset()
      self.dispatcher:push('disconnect')
    end,
    bytes = function(chunk)
      self:receive(chunk)
    end,
  }
end

--- Raw chunk first, then the lines it completed
--- @param chunk string
function Serial:receive(chunk)
  self.dispatcher:push('bytes', chunk)
  local lines, err = self.reader:feed(chunk)
  for _, l in ipairs(lines) do
    self.dispatcher:push('line', l)
  end
  if err then
    self.faults[#self.faults + 1] = { env = 'serial', err = err }
  end
end

--- @param fn function handler(device_info)
--- @param env SerialEnv?
function Serial:onConnect(fn, env)
  self.dispatcher:add('connect', env or 'program', fn)
end

--- @param fn function handler()
--- @param env SerialEnv?
function Serial:onDisconnect(fn, env)
  self.dispatcher:add('disconnect', env or 'program', fn)
end

--- @param fn function handler(chunk)
--- @param env SerialEnv?
function Serial:onBytes(fn, env)
  self.dispatcher:add('bytes', env or 'program', fn)
end

--- @param fn function handler(line), no terminator
--- @param env SerialEnv?
function Serial:onLine(fn, env)
  self.dispatcher:add('line', env or 'program', fn)
end

--- Terminator is appended here
--- @param line string
--- @return boolean? ok
--- @return string? err
function Serial:send(line)
  if not self.connected then
    return nil, 'no device connected'
  end
  return self.backend:send(line .. '\n')
end

--- @return boolean
function Serial:isConnected()
  return self.connected
end

--- Stopped, but continue() may follow
function Serial:programPaused()
  self.dispatcher:suspend_env('program')
end

function Serial:programContinued()
  self.dispatcher:resume_env('program')
end

--- Stopped for good
function Serial:programEnded()
  self.dispatcher:resume_env('program')
  self.dispatcher:clear_env('program')
end

--- Call once per update loop
--- @return table[] errors
function Serial:update()
  local errors = self.dispatcher:pump()
  for _, f in ipairs(self.faults) do
    errors[#errors + 1] = f
  end
  self.faults = {}
  return errors
end

function Serial:stop()
  self.backend:stop()
  self.connected = false
end
