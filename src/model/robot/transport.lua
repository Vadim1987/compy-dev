--- Robot transport: the protocol machine over a line link.
--- Builds the COMMAND id envelope, matches ACK identifiers,
--- retries the identical line on a timeout, associates the
--- bridge to the pair's radio group, and reports outcomes.
--- One command at a time: the link is stop-and-wait.
---
--- The machine touches no environment tables: the consumer
--- wires compy.serial fields to connected(), disconnected()
--- and take(), and hands in the send function. The clock is
--- injected: seconds, monotonic. Identifiers grow across
--- reconnects and are never reused, which is safe under any
--- suppression policy on the robot.

--- @class RobotTransport
RobotTransport = {}
RobotTransport.__index = RobotTransport

--- @param send function send(line) -> ok, err
--- @param clock function seconds
--- @param group integer? radio group, default 0
--- @param retry_s number? retry timeout, default 0.030
--- @param tries integer? attempts, default 8
--- @return RobotTransport
function RobotTransport.new(send, clock, group, retry_s, tries)
  local self = setmetatable({}, RobotTransport)
  self.send = send
  self.clock = clock
  self.group = group or 0
  self.retry_s = retry_s or 0.030
  self.tries_max = tries or 8
  self.mode = 'idle'
  self.next_id = 1
  self.id = nil
  self.line = nil
  self.deadline = 0
  self.tries = 0
  self.done = nil
  self.stale = 0
  self.fault = nil
  return self
end

--- Send the current line and arm the retry clock
function RobotTransport:fire()
  self.send(self.line .. '\r')
  self.tries = self.tries + 1
  self.deadline = self.clock() + self.retry_s
end

--- The link is up; begin the association
function RobotTransport:connected()
  self.mode = 'associating'
  self.line = '!g ' .. self.group
  self.tries = 0
  self:fire()
end

--- The link is gone; the outstanding command fails
function RobotTransport:disconnected()
  local done = self.done
  self.done = nil
  self.mode = 'idle'
  self.line = nil
  if done then
    done(nil, 'disconnected')
  end
end

--- @param payload string
--- @param done function done(ok, err)
--- @return boolean? accepted
--- @return string? err
function RobotTransport:command(payload, done)
  if self.mode ~= 'ready' then
    return nil, self.mode
  end
  local id = self.next_id
  self.next_id = self.next_id + 1
  self.mode = 'sending'
  self.id = tostring(id)
  self.line = 'COMMAND ' .. self.id .. ' ' .. payload
  self.tries = 0
  self.done = done
  self:fire()
  return true
end

--- A line from the link
--- @param l string
function RobotTransport:take(l)
  if self.mode == 'associating' then
    local n = string.match(l, '^!ok group (%d+)$')
    if n and tonumber(n) == self.group then
      self.mode = 'ready'
      self.line = nil
    end
  elseif self.mode == 'sending' then
    local id, bit = string.match(l, '^ACK (%d+) (%d)$')
    if id == self.id then
      local done = self.done
      self.done = nil
      self.mode = 'ready'
      self.line = nil
      if done then
        if bit == '1' then
          done(true)
        else
          done(false, 'refused')
        end
      end
    elseif id then
      self.stale = self.stale + 1
    end
  end
end

--- Retry pump; call every tick after serial update
--- @return string? fault
function RobotTransport:update()
  local fault = self.fault
  self.fault = nil
  if not self.line or self.clock() < self.deadline then
    return fault
  end
  if self.tries < self.tries_max then
    self:fire()
    return fault
  end
  if self.mode == 'sending' then
    local done = self.done
    self.done = nil
    self.mode = 'ready'
    self.line = nil
    if done then
      done(nil, 'timeout')
    end
  elseif self.mode == 'associating' then
    self.mode = 'idle'
    self.line = nil
    fault = 'bridge not answering'
  end
  return fault
end

--- @return string
function RobotTransport:state()
  return self.mode
end
