local home = os.getenv("HOME")
package.path = package.path .. ";" ..
    home .. "/.luarocks/share/lua/5.1/?.lua;" ..
    home .. "/.luarocks/share/lua/5.1/?/init.lua"
package.cpath = package.cpath .. ";" ..
    home .. "/.luarocks/lib/lua/5.1/?.so"

local lfs = require("lfs")

local utils_dir = "src/util"
local dependency_graph = {}
local short = {
  utf8 = 'u8',
  utf = 'u',
  string = 's',
  class = 'c',
  color = 'co',
}
local omit = {
  -- wrapped by 'utf'
  ['utf8']                  = true,
  ['lua-utf8']              = true,
  -- wrapped by 'filesystem'
  ['lfs']                   = true,
  ['lib.nativefs.nativefs'] = true,
  ['bit']                   = true,
  -- plumbing
  ['class']                 = true,
  -- lib
  ['test_terminal']         = true,
}

local function get_lua_files(dir)
  local files = {}
  for file in lfs.dir(dir) do
    if file ~= "." and file ~= ".." then
      local fullpath = dir .. "/" .. file
      local attr = lfs.attributes(fullpath)
      if attr.mode == "directory" then
        for _, f in ipairs(get_lua_files(fullpath)) do
          table.insert(files, f)
        end
      elseif file:match("%.lua$") then
        table.insert(files, fullpath)
      end
    end
  end
  return files
end

local function extract_requires(filepath)
  local requires = {}
  for line in io.lines(filepath) do
    -- Match require "foo.bar" or require('foo.bar')
    local req = line:match("require%s*[%(%[%{]?%s*['\"]([%w_%.%-/]+)['\"]")
    if req then
      table.insert(requires, req)
    end
  end
  return requires
end

for _, file in ipairs(get_lua_files(utils_dir)) do
  dependency_graph[file] = extract_requires(file)
end

local function debug(...)
  io.stderr:write(..., "\n")
end

local heading = [[flowchart BT
  u(((utf8)))
  co(((color)))
  s(string)
]]

local main = function()
  local shorten = function(name)
    local sn = short[name]
    local label = sn and sn or name
    local shortened = sn and true or false
    return label, shortened
  end
  local prio = heading
  local text = ''

  for file, deps in pairs(dependency_graph) do
    local fn = file
        :gsub(utils_dir .. '/', '')
        :gsub('.lua$', '')
    for _, dep in ipairs(deps) do
      local d = dep:gsub('util.', '')
      if not omit[fn] and not omit[d] then
        local sn = shorten(d)
        local f, pr = shorten(fn)
        if pr then
          prio = prio .. '  ' .. f .. " --> " .. sn .. '\n'
        else
          text = text .. '  ' .. f .. " --> " .. sn .. '\n'
        end
      end
    end
  end
  print(prio .. text)
end

main()
