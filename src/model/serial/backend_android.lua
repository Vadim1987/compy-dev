--- USB CDC-ACM over the Android USB host API, through the
--- LuaJIT FFI the platform already uses.
---
--- Not ported yet. The sequence to bring over from the robot
--- prototype, where it runs on the device:
---   match VID 0x0D28, requestPermission if needed,
---   openDevice, claim control and data interfaces,
---   SET_LINE_CODING (may fail here, not fatal),
---   bulk read per tick into sink.bytes,
---   one close path releasing both interfaces.
--- First device wins; a second one is reported and ignored;
--- rescan on detach of the active one.

--- @class AndroidBackend
--- @field new function
--- @field start function
--- @field send function
--- @field stop function
AndroidBackend = {}
AndroidBackend.__index = AndroidBackend

local MICROBIT_VID = 0x0D28
local NOT_PORTED = 'android backend not ported yet'

--- @return AndroidBackend
function AndroidBackend.new()
  return setmetatable({ vid = MICROBIT_VID }, AndroidBackend)
end

function AndroidBackend:start()
  error(NOT_PORTED)
end

function AndroidBackend:send()
  return nil, NOT_PORTED
end

function AndroidBackend:stop()
end
