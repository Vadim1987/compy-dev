require('model.robot.transport')

--- Device check for the robot transport. Not part of the
--- API and not meant to survive review: it wires the
--- transport to the platform port's console table.
---
--- robot_probe()              start and associate, group 0
--- robot_probe('M 10 10 500') send that payload once
--- robot_probe(false)         stop and release the fields

--- @param arg string|boolean|nil
function robot_probe(arg)
  local cs = SerialPort:table_for('console')
  if arg == false then
    cs.onConnect = nil
    cs.onDisconnect = nil
    cs.onLine = nil
    RobotPort = nil
    print('robot: stopped')
    return
  end
  if not RobotPort then
    local t = RobotTransport.new(cs.send, love.timer.getTime)
    cs.onConnect = function()
      print('robot: connected, associating')
      t:connected()
    end
    cs.onDisconnect = function()
      print('robot: disconnected')
      t:disconnected()
    end
    cs.onLine = function(l)
      t:take(l)
    end
    RobotPort = t
    if cs.isConnected() then
      print('robot: bridge already here, associating')
      t:connected()
    else
      print('robot: started, plug the bridge in')
    end
  end
  if type(arg) == 'string' then
    local ok, err = RobotPort:command(arg, function(done, why)
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
