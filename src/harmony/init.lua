local require = _G.o_require or _G.require
FS = require("util.filesystem")

require("util.debug")

local Timer = require("lib.hump.timer")
local timer = Timer.new()
local frame_time = 0.001

--- @class Harmony
--- @field run function
--- @field timer hump.Timer
--- @field lock boolean
--- @field pre string
--- @field unpre function
--- @field utils HarmonyUtils

local instance
local lock
local debug_print = function(...)
  -- Log.debug(...)
end

Harmony = {
  --- @private
  pre = '',
  unpre = function(s)
    if not s then return end
    return string.sub(s, string.len(Harmony.pre) + 1)
  end,
}
Harmony.__index = Harmony

local function new(_lock)
  local inject = function()
    local function harmonius_run()
      if love.load then
        ---@diagnostic disable-next-line: undefined-field, redundant-parameter
        love.load(love.arg.parseGameArguments(arg), arg)
      end

      if love.timer then love.timer.step() end

      local dt = 0

      local main_loop = function()
        if love.event then
          love.event.pump()
          for name, a, b, c, d, e, f in love.event.poll() do
            if name == 'die' then
              -- debug_print('die')
              -- die = true
              return a or 0
            end
            local sazed_says =
                string.starts_with(name, Harmony.pre)
            if sazed_says then
              local n = Harmony.unpre(name)
              if n == "quit" then
                if not love.quit or not love.quit() then
                  -- break
                  return a or 0
                end
              end
              ---@diagnostic disable-next-line: undefined-field
              love.handlers[n](a, b, c, d, e, f)
            else
              if
                  name == "quit"
                  or name == "keypressed" and a == 'escape'
              then
                if not love.quit or not love.quit() then
                  return a or 0
                end
              end
            end
          end
        end

        if love.timer then dt = love.timer.step() end

        if love.update then love.update(dt) end

        if love.graphics and love.graphics.isActive() then
          local G = love.graphics
          G.origin()
          G.clear(
            G.getBackgroundColor()
          )

          if love.draw then love.draw() end

          love.graphics.present()
        end

        if love.timer then love.timer.sleep(frame_time) end
      end

      return main_loop
    end

    --- override mainloop
    love.run = harmonius_run
  end

  lock = _lock
  if lock then
    Harmony.pre = 'sazed_'
  end
  --- @private
  Harmony.timer = timer
  Harmony.timer_update = function(dt)
    timer:update(dt)
  end

  love.harmony = Harmony
  inject()
end

setmetatable(Harmony, {
  __call = function(_cls, ...)
    if not instance then
      instance = new(...)
    end
    return instance
  end,
})

local messages = {
  not_loaded = function(reason)
    local msg = 'Harmony.load() was not called'
    if reason then
      return msg .. 'needed for: ' .. reason
    end
    return msg
  end
}

local load_guard = function(reason)
  if not Harmony.loaded then
    error(messages.not_loaded(reason))
  end
end

--- Utility functions that depend on love being loaded already

local function utils()
  if not love.harmony then return end
  if love.harmony.utils then return end

  G = love.graphics

  --- @param name love.Event
  local love_event = function(name, ...)
    local n = Harmony.pre .. name
    love.event.push(n, ...)
  end

  local mods = {
    C     = 'lctrl',
    Ctrl  = 'lctrl',
    S     = 'lshift',
    Shift = 'lshift',
    M     = 'lalt',
    Meta  = 'lalt',
    Alt   = 'lalt',
    A     = 'lalt',
    Super = 'lgui',
    Hyper = 'lgui',
    H     = 'lgui',
  }
  local held = {
    lctrl  = false,
    rctrl  = false,
    lshift = false,
    rshift = false,
    lalt   = false,
    ralt   = false,
    --- aka Super / Hyper / Win / Cmd
    lgui   = false,
    rgui   = false,
  }


  --- @param tag string
  local take_screenshot = function(tag)
    local fn = tag .. '.png'
    local dir = Harmony.tmpdir or '/tmp'
    --- @param img_data love.ImageData
    G.captureScreenshot(function(img_data)
      if img_data then
        local from = FS.join_path(
          love.filesystem.getSaveDirectory(), fn
        )
        local to = FS.join_path(dir, fn)
        img_data:encode('png', fn)
        local ok, err = FS.mv(from, to)
        if not ok then
          print(err)
        end
      end
    end)
  end

  local release_keys = function()
    for k, v in pairs(held) do
      if v then
        held[k] = false
      end
    end
  end

  --- @class HarmonyUtils
  --- @field patch_isDown function
  --- @field love_event function
  --- @field love_key function
  --- @field love_text function
  --- @field screenshot function
  --- @field release_keys function
  return {
    patch_isDown = function()
      local down = love.keyboard.isDown
      local isDown = function(...)
        local keys = { ... }
        for _, key in ipairs(keys) do
          if held[key] then return true end
        end
        if not lock then
          return down(...)
        end
      end
      love.keyboard.isDown = isDown
    end,

    love_event = love_event,
    love_text = function(t)
      timer:script(function(wait)
        love_event('textinput', t)
        wait(frame_time * 5)
      end)
    end,
    love_key = function(keys)
      local key = keys
      if string.matches(keys, '-') then
        local ks = string.split(keys, '-')
        debug_print()
        for _, v in ipairs(ks) do
          local m = mods[v]
          if m then
            debug_print(m .. ' held')
            held[m] = true
          else
            love_event('keypressed', v)
            debug_print('\tkey ' .. v)
            love_event('keyreleased', v)
            -- release_keys()
          end
        end
      else
        love_event('keypressed', key)
        debug_print('key ' .. key)
        love_event('keyreleased', key)
      end
    end,

    release_keys = release_keys,

    screenshot = function(tag)
      timer:script(function(wait)
        wait(frame_time)
        take_screenshot(tag)
      end)
    end,
  }
end

local function runner()
  if not love.harmony then return end
  if love.harmony.runner then return end


  local context = ''
  local scenarios = {}
  ---@diagnostic disable-next-line: unused-function
  function scenario(tag, f)
    local id = context .. '.' .. tag
    scenarios[id] = f
  end

  return {
    load_scenarios = function()
      local ls = FS.dir("src/harmony/scenarios")
      --- TODO multiscenario
      for _, d in ipairs(ls) do
        if d.type == 'file' then
          local module_name = string.sub(d.name, 1, -5)
          context = module_name
          require("harmony.scenarios." .. module_name)
        end
      end
    end,

    run_scenarios = function()
      local i = 1
      timer:script(function(wait)
        for tag, sc in pairs(scenarios) do
          --- TODO multiscenario
          if i < 2 then
            debug_print('---- ' .. tag .. ' ----')
            sc(wait)
            i = i + 1
          end
        end
      end)
    end,

  }
end

function Harmony.load()
  Harmony.loaded = true
  require('util.debug')

  Harmony.utils = utils()
  Harmony.utils.patch_isDown()

  Harmony.runner = runner()
end

function Harmony.screenshot(tag)
  load_guard('filesystem')
  return Harmony.utils.screenshot(tag)
end

function Harmony.run()
  timer:after(.1, function()
    Harmony.runner.load_scenarios()
    Harmony.runner.run_scenarios()
  end)
end

return Harmony
