local redirect_to = require("model.io.redirect")
require("model.consoleModel")
require("controller.controller")
require("controller.consoleController")
require("view.view")
require("view.consoleView")
require("harmony.controller")

local colors = require("conf.colors")
local hostconf = prequire('host')

require("util.key")
require("util.debug")
OS = require("util.os")
local FS = require("util.filesystem")

require("lib/error_explorer")

G = love.graphics

local messages = {
  dataloss_warning =
  'DEMO: Project data is not guaranteed to persist!',
  play_no_project =
  'Specifying a project is required for playback!',
  invalid_project =
  'Not a valid project',
  no_tmpdir =
  'Unable to create tmpdir',
}

local exit = function(err)
  print(err)
  love.event.quit()
end

--- CLI arguments
--- @param args table
--- @return Start
local argparse = function(args)
  if args[1] then
    local m = args[1]
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
      local a2 = args[2]
      if not string.is_non_empty_string(a2) then
        exit(messages.play_no_project)
      end
      return { mode = 'play', path = a2 }
    end
  end
  return { mode = 'ide' }
end

--- Display
--- @param flags Testflags
--- @return ViewConfig
local config_view = function(flags)
  local tf = flags or {}
  local font_size = 32.4

  local font_dir = "assets/fonts/"
  local font_main = G.newFont(
    font_dir .. "ubuntu_mono_bold_nerd.ttf", font_size)
  local font_icon = G.newFont(
    font_dir .. "SFMonoNerdFontMono-Regular.otf", font_size)
  local lh = tf.size and 1 or 1.0468
  font_main:setLineHeight(lh)
  local fh = font_main:getHeight()
  -- we use a monospace font, so the width should be the same for any input
  local fw = font_main:getWidth('█') -- 16x32

  -- this should lead to 16 lines visible by default on the
  -- console and the editor
  local lines = 16
  local input_max = 14

  local font_labels = G.newFont(
    font_dir .. "PressStart2P-Regular.ttf", 12)

  local w = G.getWidth()
  local h = love.fixHeight
  local eh = h - 2 * fh
  local debugheight = math.floor(eh / (love.test_grid_y * fh))
  local debugwidth = math.floor(love.fixWidth / love.test_grid_x) / fw
  local drawableWidth = w
  if tf.size then
    drawableWidth = debugwidth * fw
  end
  -- drawtest hack
  if drawableWidth < love.fixWidth / 3 then
    drawableWidth = drawableWidth * 2
  end

  local drawableChars = math.floor(drawableWidth / fw)
  if love.DEBUG then drawableChars = drawableChars - 3 end

  return {
    font = font_main,
    iconfont = font_icon,
    fh = fh,
    fw = fw,
    lh = lh,
    lines = lines,
    input_max = input_max,
    show_append_hl = false,
    show_debug_timer = false,

    labelfont = font_labels,
    lfh = font_labels:getHeight(),
    lfw = font_labels:getWidth('█'),

    w = w,
    h = h,
    colors = colors,

    debugheight = debugheight,
    debugwidth = debugwidth,
    drawableWidth = drawableWidth,
    drawableChars = drawableChars,

    drawtest = tf.draw,
    sizedebug = tf.size,
  }
end

--- Find removable and user-writable storage
--- Assumptions are made, which might be specific to the target
--- platform/device
--- @return boolean success
--- @return string? path
local android_storage_find = function()
  local OS = require("util.os")
  -- Yes, I know. We are working with the limitations of Android here.
  local quadhex = string.times('[0-9A-F]', 4)
  local uuid_regex = quadhex .. '-' .. quadhex
  local regex = '/dev/fuse /storage/' .. uuid_regex
  local grep = string.format("grep /proc/mounts -e '%s'", regex)
  local _, result = OS.runcmd(grep)
  local lines = string.lines(result or '')
  if not string.is_non_empty_string_array(lines) then
    return false
  end
  local tok = string.split(lines[1], ' ')
  if string.is_non_empty_string_array(tok) then
    return true, tok[2]
  end
  return false
end

--- @return PathInfo
--- @return boolean
local setup_storage = function()
  local id = love.filesystem.getIdentity()
  local harmony = love.harmony
  local storage_path = ''
  local has_removable = false

  if harmony then
    id = id .. '-harmony'
    local ok, dir = OS.mktempdir(id .. '-XXXXXXX')
    if ok then
      local d = dir or ''
      harmony.tmpdir = d
      storage_path = d
    else
      exit(messages.no_tmpdir)
    end
  else
    if OS.name == 'Android' then
      local ok, sd_path = android_storage_find()
      if not ok then
        print('WARN: SD card not found')
        has_removable = false
        sd_path = '/storage/emulated/0'
      end
      has_removable = true
      storage_path = string.format("%s/Documents/%s", sd_path, id)
      print('INFO: Project path: ' .. storage_path)
    elseif OS.name == 'Web' then
      _G.web = true
      storage_path = ''
    else
      -- TODO: linux assumed, check other platforms, especially love.js
      local home = os.getenv('HOME')
      if home and string.is_non_empty_string(home) then
        storage_path = string.format("%s/Documents/%s", home, id)
      else
        storage_path = love.filesystem.getSaveDirectory()
      end
    end
  end

  local project_path = FS.join_path(storage_path, 'projects')
  local paths = {
    storage_path = storage_path,
    project_path = project_path,
  }
  for _, d in pairs(paths) do
    local ok, err = FS.mkdir(d)
    if not ok then Log(err) end
  end
  --- this is virtual, we don't want to actually create it
  paths.play_path = '/play'
  return paths, has_removable
end

--- @param path string
--- @param paths PathInfo
local load_project = function(path, paths)
  local is_zip = string.matches_r(path, '.compy$')
  local s_path = paths.storage_path
  local p_path = paths.project_path
  local m_path = paths.play_path

  local full_path = path

  if is_zip then
    local ex = FS.exists(path) or
        FS.exists(FS.join_path(s_path, path))
    if not ex then
      exit(ProjectService.messages.file_does_not_exist(path))
    end
  else
    local ex = false
    if FS.exists(path, 'directory') then
      ex = true
    elseif FS.exists(FS.join_path(s_path, path)) then
      ex = true
      full_path = FS.join_path(s_path, path)
    elseif FS.exists(FS.join_path(p_path, path)) then
      ex = true
      full_path = FS.join_path(p_path, path)
    end
    if not ex then
      exit(ProjectService.messages.pr_does_not_exist(path))
    end
  end

  local mok = FS.mount(full_path, m_path)
  if mok then
    local valid = ProjectService.is_project(m_path)
    if not valid then
      exit(messages.invalid_project)
    end
  else
    exit(FS.messages.unreadable(path))
  end
end

--- @param args table
--- @diagnostic disable-next-line: duplicate-set-field
function love.load(args)
  local startup = argparse(args)
  local mode = startup.mode
  local harmony = mode == 'harmony'
  if harmony then
    love.harmony = {}
  end
  local autotest =
      mode == 'test' and startup.testflags.auto or false
  local playback = mode == 'play'

  local viewconf = config_view(startup.testflags)
  --- Android specific settings
  love.keyboard.setTextInput(true)
  love.keyboard.setKeyRepeat(true)
  if OS.name == 'Android' then
    love.window.setMode(
      viewconf.w,
      viewconf.h,
      {
        fullscreen = true,
        fullscreentype = "exclusive",
      })
  end

  local paths, has_removable = setup_storage()
  love.paths = paths
  if playback then
    --- it is not gonna be empty in this mode, but the
    --- typesystem is unable to express that...
    load_project(startup.path or '', paths)
  end

  --- @type LoveState
  love.state = {
    testing = false,
    has_removable = has_removable,
    user_input = nil,
    app_state = 'ready'
  }
  if love.DEBUG then
    love.debug = {
      show_snapshot = true,
      show_terminal = true,
      show_canvas = true,
      show_input = true,
      once = 0
    }
  end

  local editorconf = {
    --- TODO
    mouse_enabled = false,
  }

  --- @class Config
  local baseconf = {
    view = viewconf,
    editor = editorconf,
    autotest = autotest,
    mode = mode,
  }

  if hostconf then
    hostconf.conf_app(viewconf)
  end

  local ctrl = harmony and HarmonyController or Controller
  --- MVC wiring
  local CM = ConsoleModel(baseconf)
  redirect_to(CM)
  local CC = ConsoleController(CM, ctrl)
  local CV = ConsoleView(baseconf, CC)
  CC:set_view(CV)

  ctrl.init(CC)
  ctrl.setup_callback_handlers(CC)
  ctrl.set_default_handlers(CC, CV)

  if playback then
    local ok, err = CC:open_project('play', true)
    if not ok then
      exit(err)
    end
    CC:run_project()
  else
    if _G.web then
      print(messages.dataloss_warning)
      CM.projects:deploy_examples()
    end

    --- run autotest on startup if invoked
    if autotest then CC:autotest() end
    if harmony then
      CM.projects:deploy_examples()
    end
  end
end
