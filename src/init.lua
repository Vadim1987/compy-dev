--- CLI arguments
--- 1 <game>
--- 2 [<mode>]
--- 3 [options]
--- -2 love
--- -1 embedded boot.lua
--- @return Start
local argparse = function()
  local args = _G.arg

  local m = args[2]
  if m then
    if m == 'harmony' then
      return { mode = 'harmony' }
    elseif m == 'test' then
      local autotest = false
      local drawtest = false
      local sizedebug = false
      for _, a in ipairs(args) do
        if a == '--auto' then autotest = true end
        if a == '--size' then sizedebug = true end
        if a == '--draw' then
          drawtest = true
          sizedebug = true
        end
        if a == '--all' then
          drawtest = true
          sizedebug = true
          autotest = true
        end
      end
      return {
        mode = 'test',
        testflags = {
          auto = autotest,
          draw = drawtest,
          size = sizedebug
        }
      }
    elseif m == 'play' then
      local path = args[3]
      return { mode = 'play', path = path }
    end
  end
  return { mode = 'ide' }
end

return {
  argparse = argparse,
}
