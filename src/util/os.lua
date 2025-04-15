--- @return string? osname
local function get_name()
  if type(love) == "table" and
      type(love.system) == "table" then
    return love.system.getOS()
  elseif jit then
    return jit.os
  end
end

--- @return boolean success
local function test_popen()
  local ok = pcall(io.popen, 'echo')
  return ok
end

--- @param cmd string
--- @return boolean success
--- @return string? result
local function runcmd(cmd)
  if not test_popen() then return false end
  local handle = io.popen(cmd)
  if handle then
    local result = handle:read("*a")
    handle:close()
    return true, result
  end
  return false
end

return {
  name = get_name(),
  runcmd = runcmd,
}
