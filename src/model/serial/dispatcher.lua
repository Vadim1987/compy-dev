--- @alias SerialEnv 'console' | 'program'
--- @alias SerialEvent 'connect' | 'disconnect' | 'bytes' | 'line'

--- @class Dispatcher
--- @field new function
--- @field add function
--- @field suspend_env function
--- @field resume_env function
--- @field clear_env function
--- @field push function
--- @field pump function
Dispatcher = {}
Dispatcher.__index = Dispatcher

local EVENTS = {
  connect = true,
  disconnect = true,
  bytes = true,
  line = true,
}

local ENVS = { console = true, program = true }

--- @return Dispatcher
function Dispatcher.new()
  local self = setmetatable({}, Dispatcher)
  self.handlers = {
    connect = {},
    disconnect = {},
    bytes = {},
    line = {},
  }
  self.queue = {}
  self.suspended = {}
  return self
end

--- @param event SerialEvent
--- @param env SerialEnv
--- @param fn function
function Dispatcher:add(event, env, fn)
  if not EVENTS[event] then
    error('no such event: ' .. tostring(event))
  end
  if not ENVS[env] then
    error('no such environment: ' .. tostring(env))
  end
  if type(fn) ~= 'function' then
    error('handler is not a function')
  end
  local hs = self.handlers[event]
  hs[#hs + 1] = { env = env, fn = fn }
end

--- Keep handlers registered, stop delivering to them
--- @param env SerialEnv
function Dispatcher:suspend_env(env)
  if not ENVS[env] then
    error('no such environment: ' .. tostring(env))
  end
  self.suspended[env] = true
end

--- Deliver again, from now on. No replay of the gap.
--- @param env SerialEnv
function Dispatcher:resume_env(env)
  self.suspended[env] = nil
end

--- @param env SerialEnv
function Dispatcher:clear_env(env)
  for event, hs in pairs(self.handlers) do
    local kept = {}
    for _, h in ipairs(hs) do
      if h.env ~= env then kept[#kept + 1] = h end
    end
    self.handlers[event] = kept
  end
end

--- @param event SerialEvent
--- @param arg any?
function Dispatcher:push(event, arg)
  self.queue[#self.queue + 1] = { event = event, arg = arg }
end

--- Run queued events through their handlers, in order.
--- Anything pushed from a handler waits for the next pump.
--- @return table[] errors
function Dispatcher:pump()
  local batch = self.queue
  self.queue = {}
  local errors = {}
  for _, ev in ipairs(batch) do
    for _, h in ipairs(self.handlers[ev.event]) do
      if not self.suspended[h.env] then
        local ok, e = pcall(h.fn, ev.arg)
        if not ok then
          errors[#errors + 1] = { env = h.env, err = e }
        end
      end
    end
  end
  return errors
end
