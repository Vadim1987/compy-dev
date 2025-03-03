require("util.string")
require("util.key")
local LANG = require("util.eval")

local key_break_msg = "BREAK into program"

local get_user_input = function()
  if love.state.app_state == 'inspect' then return end
  return love.state.user_input
end
--- @type boolean
local user_update
--- @type boolean
local user_draw

local _supported = {
  'keypressed',
  'keyreleased',
  'textinput',

  'mousemoved',
  'mousepressed',
  'mousereleased',
}

local _C

--- @param msg string
local function user_error_handler(msg)
  local err = LANG.get_call_error(msg) or ''
  local user_msg = 'Execution error at ' .. err
  _C:suspend_run(user_msg)
  print(user_msg)
end

--- @param f function
--- @param ...   any
--- @return boolean success
--- @return any result
--- @return any ...
local function wrap(f, ...)
  if _G.web then
    -- local ok, r = pcall(f, ...)
    -- if not ok then
    --   user_error_handler(r)
    -- end
    -- return r
    -- return xpcall(f, user_error_handler, ...)
    --- TODO no error handling, sorry, it leads to a stack overflow
    --- in love.wasm
    return f(...)
  else
    return xpcall(f, user_error_handler, ...)
  end
end

--- @param f function
--- @return function
local function error_wrapper(f)
  return function(...)
    return wrap(f, ...)
  end
end

--- @param userlove table
local set_handlers = function(userlove)
  --- @param key string
  local function hook_if_differs(key)
    local orig = Controller._defaults[key]
    local new = userlove[key]
    if orig and new and orig ~= new then
      --- @type function
      love[key] = error_wrapper(new)
    end
  end

  -- input hooks
  for _, k in ipairs(_supported) do
    hook_if_differs(k)
  end
  -- update - special handling, inner updates
  local up = userlove.update
  if up and up ~= Controller._defaults.update then
    user_update = true
    Controller._userhandlers.update = up
  end

  -- drawing - separate table
  local draw = userlove.draw
  if draw and draw ~= View.main_draw then
    love.draw = draw
    user_draw = true
  end
end

--- @class Handlers
--- @field update function?
--- @field draw function?
--- @field keypressed function?
--- @field keyreleased function?
--- @field textinput function?
--- @field mousemoved function?
--- @field mousepressed function?
--- @field mousereleased function?

--- @class Controller
--- @field _defaults Handlers
--- @field _userhandler Handlers
--- public interface
--- @field set_love_draw function
--- @field setup_callback_handlers function
--- @field set_default_handlers function
--- @field save_user_handlers function
--- @field clear_user_handlers function
--- @field restore_user_handlers function
--- @field has_user_update function
Controller = {
  _defaults = {},
  _userhandlers = {},

  ----------------
  --  keyboard  --
  ----------------

  --- @param C ConsoleController
  set_love_keypressed = function(C)
    local function keypressed(k)
      if Key.ctrl() and Key.shift() then
        if love.DEBUG then
          if k == "1" then
            table.toggle(love.debug, 'show_terminal')
          end
          if k == "2" then
            table.toggle(love.debug, 'show_snapshot')
          end
          if k == "3" then
            table.toggle(love.debug, 'show_canvas')
          end
          if k == "5" then
            table.toggle(love.debug, 'show_input')
          end
        end
      end
      if Key.ctrl() and Key.alt() then
        if love.DEBUG then
          if k == "d" then
            Log.debug(Debug.termdebug(C.model.output.terminal))
          end
        end
      end
      C:keypressed(k)
    end
    Controller._defaults.keypressed = keypressed
    love.keypressed = keypressed
  end,
  --- @param C ConsoleController
  set_love_keyreleased = function(C)
    --- @diagnostic disable-next-line: duplicate-set-field
    local function keyreleased(k)
      C:keyreleased(k)
    end
    Controller._defaults.keyreleased = keyreleased
    love.keyreleased = keyreleased
  end,
  --- @param C ConsoleController
  set_love_textinput = function(C)
    local function textinput(t)
      C:textinput(t)
    end
    Controller._defaults.textinput = textinput
    love.textinput = textinput
  end,

  -------------
  --  mouse  --
  -------------

  --- @param C ConsoleController
  set_love_mousepressed = function(C)
    local function mousepressed(x, y, button)
      if love.DEBUG then
        Log.info(string.format('click! {%d, %d}', x, y))
      end
      C:mousepressed(x, y, button)
    end

    Controller._defaults.mousepressed = mousepressed
    love.mousepressed = mousepressed
  end,
  --- @param C ConsoleController
  set_love_mousereleased = function(C)
    local function mousereleased(x, y, button)
      C:mousereleased(x, y, button)
    end

    Controller._defaults.mousereleased = mousereleased
    love.mousereleased = mousereleased
  end,
  --- @param C ConsoleController
  set_love_mousemoved = function(C)
    local function mousemoved(x, y, dx, dy)
      C:mousemoved(x, y, dx, dy)
    end

    Controller._defaults.mousemoved = mousemoved
    love.mousemoved = mousemoved
  end,

  --------------
  --  update  --
  --------------

  --- @param C ConsoleController
  set_love_update = function(C)
    local function update(dt)
      local ddr = View.prev_draw
      local ldr = love.draw
      local ui = get_user_input()
      if ldr ~= ddr or ui then
        local function draw()
          if ldr then
            wrap(ldr)
          end
          local user_input = get_user_input()
          if user_input then
            user_input.V:draw(user_input.C:get_input())
          end
        end
        View.prev_draw = draw
        love.draw = draw
      end
      C:pass_time(dt)

      local uup = Controller._userhandlers.update
      if user_update and uup
      then
        wrap(uup, dt)
      end
      Controller.snapshot()
    end

    if not Controller._defaults.update then
      Controller._defaults.update = update
    end
    love.update = update
  end,

  ---------------
  --    draw   --
  ---------------
  --- @param C ConsoleController
  --- @param CV ConsoleView
  set_love_draw = function(C, CV)
    local function draw()
      View.draw(C, CV)
    end
    love.draw = draw

    View.prev_draw = love.draw
    View.main_draw = love.draw
  end,

  snapshot = function()
    if user_draw then
      View.snap_canvas()
    end
  end,

  ----------------
  ---  public  ---
  ----------------
  --- @param C ConsoleController
  init = function(C)
    _C = C
  end,
  --- @param C ConsoleController
  --- @param CV ConsoleView
  set_default_handlers = function(C, CV)
    Controller.set_love_keypressed(C)
    Controller.set_love_keyreleased(C)
    Controller.set_love_textinput(C)
    -- SKIPPED textedited - IME support, TODO?

    Controller.set_love_mousemoved(C)
    Controller.set_love_mousepressed(C)
    Controller.set_love_mousereleased(C)
    -- SKIPPED wheelmoved - TODO

    -- SKIPPED touchpressed  - target device doesn't support touch
    -- SKIPPED touchreleased - target device doesn't support touch
    -- SKIPPED touchmoved    - target device doesn't support touch

    -- SKIPPED joystick and gamepad support

    -- SKIPPED focus       - intented to run as kiosk app
    -- SKIPPED mousefocus  - intented to run as kiosk app
    -- SKIPPED visible     - intented to run as kiosk app

    -- SKIPPED quit        - intented to run as kiosk app - TODO
    -- SKIPPED threaderror - no threading support

    -- SKIPPED resize           - intented to run as kiosk app
    -- SKIPPED filedropped      - intented to run as kiosk app
    -- SKIPPED directorydropped - intented to run as kiosk app
    -- SKIPPED lowmemory
    -- SKIPPED displayrotated   - target device has laptop form factor

    user_update = false
    Controller.set_love_update(C)
    user_draw = false
    Controller.set_love_draw(C, CV)
    Controller._defaults.draw = View.main_draw
  end,

  --- @param C ConsoleController
  setup_callback_handlers = function(C)
    local clear_user_input = function()
      love.state.user_input = nil
    end

    --- @diagnostic disable-next-line: undefined-field
    local handlers = love.handlers

    handlers.keypressed = function(k)
      if Key.ctrl() then
        if k == "pause" then
          C:suspend_run(key_break_msg)
        end
        if Key.shift() then
          -- Ensure the user can get back to the console
          if k == "q" then
            C:quit_project()
          end
          if k == "s" then
            if love.state.app_state == 'running' then
              C:stop_project_run()
            elseif love.state.app_state == 'editor' then
              C:finish_edit()
            end
          end
          if k == "r" then
            C:reset()
          end
        end
      end
      if k == 'f8' then
        if love.state.app_state == 'running'
            or love.state.app_state == 'inspect'
            or love.state.app_state == 'project_open'
        then
          C:stop_project_run()
          local st = love.state.editor
          if st then
            C:edit(st.buffer.filename, st)
          else
            C:edit()
          end
        elseif love.state.app_state == 'editor' then
          if C.editor:is_normal_mode() then
            local ed_state = C:finish_edit()
            love.state.editor = ed_state
            C:run_project()
          end
        end
      end

      local user_input = get_user_input()
      if user_input then
        user_input.C:keypressed(k)
      else
        if love.keypressed then return love.keypressed(k) end
      end
    end

    handlers.textinput = function(t)
      local user_input = get_user_input()
      if user_input then
        user_input.C:textinput(t)
      else
        if love.textinput then return love.textinput(t) end
      end
    end

    handlers.keyreleased = function(k)
      if Key.ctrl() then
        if k == "escape" then
          love.event.quit()
        end
      end
      local user_input = get_user_input()
      if user_input then
        user_input.C:keyreleased(k)
      else
        if love.keyreleased then return love.keyreleased(k) end
      end
    end

    handlers.mousepressed = function(x, y, btn)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousepressed(x, y, btn)
      else
        if love.mousepressed then return love.mousepressed(x, y, btn) end
      end
    end

    handlers.mousereleased = function(x, y, btn)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousereleased(x, y, btn)
      else
        if love.mousereleased then return love.mousereleased(x, y, btn) end
      end
    end

    handlers.mousemoved = function(x, y, dx, dy)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousemoved(x, y, dx, dy)
      else
        if love.mousemoved then return love.mousemoved(x, y, dx, dy) end
      end
    end

    handlers.userinput = function()
      local user_input = get_user_input()
      if user_input then
        clear_user_input()
      end
    end

    --- @diagnostic disable-next-line: undefined-field
    table.protect(love.handlers)
  end,

  set_user_handlers = set_handlers,

  has_user_update = function()
    return user_update
  end,

  --- @param userlove table
  save_user_handlers = function(userlove)
    --- @param key string
    local function save_if_differs(key)
      local orig = Controller._defaults[key]
      local new = userlove[key]
      if orig and new and orig ~= new then
        Controller._userhandlers[key] = new
      end
    end

    -- input hooks
    for _, a in pairs(_supported) do
      save_if_differs(a)
    end
    save_if_differs('draw')
  end,

  restore_user_handlers = function()
    set_handlers(Controller._userhandlers)
  end,

  clear_user_handlers = function()
    Controller._userhandlers = {}
    View.clear_snapshot()
  end,
}
