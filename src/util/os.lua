require("util.string")

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
    --- sadly, this doesn't capture the return code,
    --- so it doesn't mean that it was a success
    return true, result
  end
  return false
end

--- @param cmd string
--- @return boolean success
--- @return string? result
local function runcmd_with_exit(cmd)
  if not test_popen() then return false end
  if get_name() ~= 'Linux' then
    return false, 'OS not supported'
  end
  local handle = io.popen(cmd .. ' 2>&1; echo $?')
  if handle then
    local result = handle:read("*a")
    handle:close()
    local _, _, exit_code = result:find("(%d+)%s*$")
    result = result:sub(1,
      result:find("(%d+)%s*$") - 1):gsub("%s+$", ""
    )
    exit_code = tonumber(exit_code)
    if exit_code ~= 0 then
      return false, result
    end
    return true, result
  end
  return false
end

--- @param templ string?
--- @return boolean success
--- @return string? result
local function mktempdir(templ)
  if get_name() == 'Linux' then
    local cmd = 'mktemp -d'
    local tmpdir = '/tmp'
    if string.is_non_empty_string(templ) then
      cmd = string.format('%s -p %s %s', cmd, tmpdir, templ)
    end
    return runcmd_with_exit(cmd)
  end
  return false, 'OS not supported'
end

return {
  name = get_name(),
  runcmd = runcmd,
  mktempdir = mktempdir,
}
