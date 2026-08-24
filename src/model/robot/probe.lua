require('model.robot.transport')
require('model.serial.backend_android')

--- Device check for the robot transport. Not part of the
--- API and not meant to survive review: it builds the
--- transport over the serial API, associates, and sends one
--- enveloped command on request.
---
--- robot_probe()              start and associate, group 0
--- robot_probe('M 10 10 500') send that payload once
--- robot_probe(false)         stop and release

--- @param arg string|boolean|nil
function robot_probe(arg)
  if arg == false then
    if RobotPort then RobotPort.serial:stop() end
    RobotPort = nil
    print('robot: stopped')
    return
  end
  if not RobotPort then
    local serial = Serial.new(AndroidBackend.new())
    local t = RobotTransport.new(serial, love.timer.getTime)
    t:start('console')
    serial:onConnect(function()
      print('robot: connected, associating')
    end, 'console')
    serial:onDisconnect(function()
      print('robot: disconnected')
    end, 'console')
    RobotPort = t
    print('robot: started, plug the bridge in')
  end
  if type(arg) == 'string' then
    local t = RobotPort
    local ok, err = t:command(arg, function(done, why)
      print('robot: done ' .. tostring(done) ..
        ' ' .. tostring(why))
    end)
    if not ok then
      print('robot: not sent, ' .. tostring(err))
    end
  else
    print('robot: state ' .. RobotPort:state())
  end
end
