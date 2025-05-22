local home = os.getenv("HOME")
package.path = package.path .. ";" ..
    home .. "/.luarocks/share/lua/5.1/?.lua;" ..
    home .. "/.luarocks/share/lua/5.1/?/init.lua" .. ";" ..
    "./src/?.lua"
package.cpath = package.cpath .. ";" ..
    home .. "/.luarocks/lib/lua/5.1/?.so"

local parser = require("model.lang.lua.parser")()
local FS = require("util.filesystem")

local files = {}
local write = false

for _, a in ipairs(arg) do
  if a == '--write'
      or a == '-w'
  then
    write = true
  elseif a:match("%.lua$")
  then
    table.insert(files, a)
  end
end

if #files == 0 then
  print('Usage: ')
  print('util/compyfmt [] <file1> <file2> ... <fileN> [-w]')
  print('      -w, --write')
  print('            Overwrite files with the formatted content')
  print('            If not specified, it will be dumped to stdout instead')
  os.exit(3)
end

local function debug(...)
  io.stderr:write(..., "\n")
end

local function do_code(ast, seen_comments)
  local w = 64
  local code, comments = parser.ast_to_src(ast, seen_comments, w)
  local seen = seen_comments or {}
  for k, v in pairs(comments) do
    --- if a table was passed in, this modifies it
    seen[k] = v
  end
  return code, seen_comments
end

for _, f in ipairs(files) do
  local result = {}
  local rok, cont = FS.read(f)
  if rok then
    local ok, r = parser.parse(cont or '')
    if ok then
      local has_lines = false
      local seen_comments = {}
      for _i, v in ipairs(r) do
        local li = v.lineinfo
        local lfl = li.first.line
        local lffl = li.first.facing.line
        local d = lfl - (lffl + 1)
        for _ = 1, d do
          --- insert extra lines
          table.insert(result, '')
        end

        has_lines = true
        local ct, _ = do_code(v, seen_comments)
        for _, cl in ipairs(string.lines(ct) or {}) do
          table.insert(result, cl)
        end
      end
      --- corner case, e.g comments only
      --- it is valid code, but gets parsed a bit differently
      if not has_lines then
        result = string.lines(do_code(r)) or {}
      end
      --- remove trailing newline
      -- if result[#result] == '' then
      --   table.remove(result)
      -- end

      if write then
        local bak = f .. '.bak'
        FS.cp(f, bak)
        FS.write(f, string.unlines(result))
        FS.unlink(bak)
      else
        print('==> ' .. f .. ' <==')
        print(string.unlines(result))
      end
    end
  end
end
