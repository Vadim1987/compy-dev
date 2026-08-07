require("view.input.userInputView")
require("controller.editorController")
require("controller.userInputController")
require("controller.projectInputController")


local class = require('util.class')
local LANG = require("util.eval")
local FS = require('util.filesystem')
require("util.key")
require("util.table")
local TerminalTest = require("util.test_terminal")

local messages = {
  file_does_not_exist = function(name)
    local n = name or ''
    return 'cannot open ' .. n .. ': No such file or directory'
  end,
}
--- @class ConsoleController
--- @field time number
--- @field model Model
--- @field main_ctrl table
--- @field main_env LuaEnv
--- @field pre_env LuaEnv
--- @field base_env LuaEnv
--- @field project_env LuaEnv
--- @field loaders function[]
--- @field input UserInputController
--- @field editor EditorController
--- @field view ConsoleView?
--- @field cfg Config
--- methods
--- @field edit function
--- @field finish_edit function
ConsoleController = class.create()

--- @param M Model
function ConsoleController.new(M, main_ctrl)
  local env = getfenv()
  local pre_env = table.clone(env)
  local config = M.cfg
  pre_env.font = config.view.font
  local IC = UserInputController(M.input):always_shown()
  -- Console history navigation: at the vertical boundary the
  -- widget fires on_limit_reached; the console maps up/down to
  -- history back/forward (doc/development/decisions/input.md,
  -- Decision 5), retiring the old keypressed
  -- return-value channel.
  IC.callbacks.on_limit_reached = function(dir)
    if dir == 'up' then IC:history_back() end
    if dir == 'down' then IC:history_fwd() end
  end
  local self = setmetatable({
    time        = 0,
    model       = M,
    main_ctrl   = main_ctrl,
    input       = IC,
    -- console runner env
    main_env    = env,
    -- copy of the application's env before the prep
    pre_env     = pre_env,
    -- the project env where we make the API available
    base_env    = {},
    -- this is the env in which the user project runs
    -- subject to change, for example when switching projects
    project_env = {},

    loaders     = {},

    view        = nil,

    cfg         = config
  }, ConsoleController)
  --- the editor has to know about us
  local EC = EditorController(M.editor, self)
  self.editor = EC
  -- initialize the stub env tables
  ConsoleController.prepare_env(self)
  ConsoleController.prepare_project_env(self)

  return self
end

--- @param V ConsoleView
function ConsoleController:init_view(V)
  self.view = V
  self.input:init_view(V.input)
  self.input:update_view()
end

--- @param name string
--- @param f function
function ConsoleController:cache_loader(name, f)
  self.loaders[name] = f
end

--- @param name string
--- @return function?
function ConsoleController:get_loader(name)
  return self.loaders[name]
end

--- @param f function
--- @param cc ConsoleController
--- @param project_path string?
--- @return boolean success
--- @return string? errmsg
local function run_user_code(f, cc, project_path)
  local output = cc.model.output
  local env = cc:get_base_env()

  local ok, call_err
  cc:use_canvas(function()
    if project_path then
      env = cc:get_project_env()
    end
    ok, call_err = pcall(f)
    if project_path and ok then -- user project exec
      if love.PROFILE then
        love.PROFILE.frame = 0
        love.PROFILE.report = {}
      end
      cc.main_ctrl.set_user_handlers(env['love'], cc)
    end
    output:restore_main()
  end)
  if not ok then
    local msg = LANG.get_call_error(call_err)
    return false, msg
  end
  return true
end

---> REMARK: comment does not match code and is too verbose
-- Project lifecycle callback. It is intentionally separate from
-- compy.input's keyboard/text dispatch surface. Declared up
-- here with hide_overlay because both ends of a run reset it:
-- the stop path, and the failed-run path in run_project.
local function default_before_exit()
  Log.debug('compy.before_exit noop')
end

---> REMARK: word 'overlay' is strongly opposed. if its needed in console context (the only context where its meaningful), let use something like 'input_widget_overlay'
---> REMARK: too verbose comment. just briefly tell in which contexts function is supposed to be invoked instead of reexplaining how it works (prose length is x5 longer than code length!)
--- Take the overlay down THROUGH the widget when a run ends,
--- so its own `shown` flag comes down together with the
--- published handle. Clearing love.state.user_input alone left
--- the widget believing it was still active, and the next
--- project's show() was then refused as a repeat by the
--- already-active guard (doc/development/decisions/input.md,
--- Decision 3) — a stopped project's overlay silently
--- swallowing the next project's.
--- hide() fires no cancel chain (Decision 6), which is what
--- teardown wants: this is not a user-facing dismiss.
--- Declared here rather than beside stop_project_run because
--- the failed-run path in run_project below needs it too.
local function hide_overlay()
  local widget = love.state.user_input_controller
  if widget then return widget:hide() end
  love.state.user_input = nil
end

--- @param cc ConsoleController
local function close_project(cc)
  local ok = cc:close_project()
  if ok then
    print('Project closed')
  else
    Log.err('error in closing')
  end
end

--- @private
--- @param name string
--- @return string?
function ConsoleController:_readfile(name)
  local PS              = self.model.projects
  local p               = PS.current
  local ok, text_or_err = p:readfile(name)
  if ok then
    return text_or_err
  else
    print(text_or_err)
  end
end

--- @private
--- @param name string
--- @return string[]?
function ConsoleController:_readlines(name)
  local s = self:_readfile(name)
  if s then
    return string.lines(s)
  end
end

--- @private
--- @param name string
--- @param content string[]
--- @return boolean success
--- @return string? err
function ConsoleController:_writefile(name, content)
  local P = self.model.projects
  local p = P.current
  local text = string.unlines(content)
  return p:writefile(name, text)
end

function ConsoleController:writefile(name, content)
  local P = self.model.projects
  local p = P.current
  local fpath = p:get_path(name)
  local ex = FS.exists(fpath)
  if ex then
    -- TODO: confirm overwrite
  end
  local ok, err = self:_writefile(name, content)
  if ok then
    print(name .. ' written')
  else
    print(err)
  end
end

_G.o_loadfile = _G.loadfile
--- @param name string
--- @return function?
function ConsoleController:loadfile(name)
  local PS               = self.model.projects
  local p                = PS.current
  local chunk = p:load_file(name)
  return chunk
end

-- (wrap_handler and get_compy_handler removed together: both
-- existed for compy.singleclick / compy.doubleclick, which are
-- now ordinary events reached through the dispatch chain. The
-- one surviving way to run project code — canvas bound, errors
-- routed, return propagated — is `guarded` in controller.lua,
-- applied where a route is entered. wrap_handler differed from
-- it only by discarding the return, which nothing needed.)

--- @param name string?
function ConsoleController:run_project(name)
  if love.state.app_state == 'inspect' or
      love.state.app_state == 'running'
  then
    self.input:set_error(
      { "There's already a project running!" })
    return
  end
  local P   = self.model.projects
  local cur = P.current
  local ok
  if cur and (not name or cur.name == name) then
    ok = true
  else
    ok = self:open_project(name or '', false)
  end

  if ok then
    local runner_env = self:get_project_env()
    local f, load_err, path = P:run(name, runner_env)
    if f then
      local n = name or P.current.name or 'project'
      Log.info('Running \'' .. n .. '\'')
      love.state.app_state = 'running'
      local rok, run_err = run_user_code(f, self, path)
      if not rok then
        -- Top-level code raised, so the route was never
        -- connected. Release, then take down any overlay the
        -- project managed to show first: Decision 11's teardown
        -- invariant says a widget whose owning route is
        -- inactive goes unhonoured, and a shown one is not
        -- (doc/development/decisions/input.md, Decision 11).
        self.main_ctrl.release_keyboard_route(self)
        hide_overlay()
        -- ...and the participants it installed before raising.
        -- Same invariant, same reason: nothing survives the
        -- project that installed it. before_exit is RESET but
        -- not FIRED: the frozen spec scopes the hook to stop
        -- paths and excludes crash, yet a slot left holding the
        -- dead project's function would fire for the next one.
        self.main_ctrl.clear_user_handlers(self)
        self:get_project_env().compy.before_exit =
            default_before_exit
        love.state.app_state = 'project_open'
        print('Error: ', run_err)
      else
        if not self.main_ctrl.user_is_blocking() then
          -- The route is NOT released here. A non-blocking run
          -- reaching 'project_open' keeps every channel until
          -- the project actually stops. That is the pre-feature
          -- lifecycle: at the PR base nothing was released
          -- before suspend or stop, and the keyboard-only
          -- release this feature added was what forced pointer
          -- to be exempted from it. With every channel on one
          -- route there is nothing left to exempt.
          -- (doc/development/decisions/input.md, Decision 11.)
          love.state.app_state = 'project_open'
        end
      end
    else
      --- TODO extract error message here
      print(load_err)
    end
  end
end

local o_require = _G.require
_G.o_require = o_require
--- @param name string
--- @param run 'run'?
local function project_require(name, run)
  if run then
    Log.info('req', name)
  end
  if _G.web and name == 'bit' then
    return o_require('util.luabit')
  else
    return o_require(name)
  end
end

_G.o_dofile = _G.dofile
--- @param cc ConsoleController
--- @param filename string
--- @param env LuaEnv?
local function project_dofile(cc, filename, env)
  local P = cc.model.projects
  local fn = filename
  local open = P.current
  if open then
    local chunk = open:load_file(fn)
    if chunk then
      if env then
        setfenv(chunk, env)
      end
      return true, chunk()
    else
      print(messages.file_does_not_exist(filename))
    end
  end
end


-- Set up audio table
local compy_audio = require("util.audio")
local compy_graphics = {
  shape2d = require("util.graphics.shape2d")
}
-- Builds the `compy.terminal` sub-namespace — the console
-- OUTPUT surface. These wrap the live `terminal` (the
-- REPL/console text grid): position the grid cursor
-- (gotoxy), show/hide it, and clear the screen. This is
-- where a project WRITES to the console; always present
-- while the project runs. Contrast with `compy.input`
-- below, the input solicitation surface.
local get_compy_terminal = function(terminal)
  return {
    --- @param x number
    --- @param y number
    gotoxy = function(x, y)
      return terminal:move_to(x, y)
    end,
    show_cursor = function()
      return terminal:show_cursor()
    end,
    hide_cursor = function()
      return terminal:hide_cursor()
    end,
    clear = function()
      terminal:move_to(1, 1)
      return terminal:clear()
    end
  }
end

-- Builds the `compy.input` sub-namespace — the input
-- solicitation surface, complementary to compy.terminal
-- (above): compy.terminal is the always-present console
-- OUTPUT grid the project writes to; compy.input is the
-- transient input widget the project pops up to ask the
-- user for text and get a value back. The two "cursor"
-- notions differ: terminal.gotoxy moves the console grid
-- cursor, input.get_cursor/set_cursor address the caret
-- WITHIN the input field.
-- By architectural contract these wrappers are the ONLY
-- project-facing surface for the input widget: they wrap
-- UserInputController (love.state.user_input_controller);
-- projects never touch the controller directly. Namespace +
-- lifecycle docs: doc/development/internals/user_input.md.
-- compy.input's write boundary (doc/development/decisions/input.md,
-- Decision 7): the container and the IDENTITY of its
-- three sub-tables (shortcuts / hooks / callbacks) are frozen — a
-- project cannot replace them (compy.input.shortcuts = {} raises).
-- Every LEAF inside is freely writable: shortcuts[event][combo] = fn
-- (through the combo table's own normalising __newindex, Decision 8),
-- hooks[event] = fn, callbacks[name] = fn. One structural rule
-- replaces the old enumerated 11-name allowlist — nothing to keep in
-- sync with the API surface.
---> REMARK: need more explicit name e.g. 'unassignable_error', 
--- @param k any
local function frozen_error(k)
  error("compy.input: '" .. tostring(k)
    .. "' is not assignable", 2)
end

--- shortcuts sub-table: per-event combo tables whose identities are
--- frozen (shortcuts.keypressed = {} raises); leaf combo writes reach
--- the combo table's own normalising __newindex (Decision 8).
--- @param shortcuts table
local function build_shortcuts_surface(shortcuts)
  return setmetatable({ }, {
    ---> REMARK: setting __index is redundant, because its trivial?
    __index = function(_, event) return shortcuts[event] end,
    __newindex = function(_, event)
      frozen_error('shortcuts.' .. tostring(event))
    end,
  })
end

--- hooks / callbacks sub-table: flat leaf writes are allowed (nothing
--- nested to protect); only the sub-table's own identity is frozen, at
--- the compy.input container level above.
--- @param store table
---> REMARK: whole function is redundant because its trivial? (literally setting __index and __newindex to their default behaviour!)
local function build_leaf_surface(store)
  return setmetatable({ }, {
    __index = function(_, k) return store[k] end,
    __newindex = function(_, k, v) store[k] = v end,
  })
end

---> REMARK: fix prose -- not "where the event GOES" but "whether event PROPAGATES by returning hardcoded true/false"
---> REMARK: why not shorter form? e.g. 'fn and fn(...);return false;' ? its one-off, very straight wrappers
---> REMARK: if we drop the 'keys' parameter (therefore unifying shorcuts/hooks signature with love.*), ignore_repeat should be updated
--- The dispatch combinators (doc/development/decisions/input.md,
--- Decisions 22 and 24), reached as compy.input.fn.*. Stateless
--- and orthogonal: `ignore_repeat` decides whether the handler
--- RUNS, `stop_here`/`side_run` decide where the event GOES, and
--- neither knows about the other. Named for their effect on the
--- event, which is what a reader of a registration table needs.
---> REMARK: what you mean by 'reserved binding'? Its maybe 'recommended' or 'often used'?
--- A reserved binding is `stop_here(ignore_repeat(fn))`.
local INPUT_FN = {
  --- Skip the handler on an OS key repeat. Says nothing about
  --- propagation: a fresh press returns what the handler
  --- returned, a skipped repeat returns nothing.
  ignore_repeat = function(fn)
    return function(k, sc, isr)
      if isr then return end
      return fn(k, sc, isr)
    end
  end,
  --- Run `fn` if given, then consume. With no `fn` the binding's
  --- only job is to swallow the event.
  stop_here = function(fn)
    return function(...)
      if fn then fn(...) end
      return true
    end
  end,
  --- Run `fn` if given, and let the event carry on regardless of
  --- what it returned — the binding is a side effect, not a
  --- claim on the key.
  side_run = function(fn)
    return function(...)
      if fn then fn(...) end
      return false
    end
  end,
}

---> REMARK: why set '__index' if its trivial
---> REMARK: we have characteristical 'frozen write' metatable, why not use class instead of repeating same setmetatable three times?
local input_fn_surface = setmetatable({ }, {
  __index = function(_, k) return INPUT_FN[k] end,
  __newindex = function(_, k)
    frozen_error('fn.' .. tostring(k))
  end,
})

--- Assemble the compy.input surface: reads resolve the three frozen
--- sub-tables (shortcuts / hooks / callbacks), the combinator
--- table, the live held-key view, or a callable method; every
--- write to the container itself is refused loudly (Decision 7
--- revised — frozen container, writable leaves).
--- `get_keys` is resolved on every read, never captured: the
--- view is rebuilt when its backing table identity changes
--- (Decision 13), so a reference taken at build time goes stale.
--- @param state table
--- @param methods table
--- @param get_keys fun(): table
--- @return table
local function build_input_surface(state, methods, get_keys)
  local shortcuts = build_shortcuts_surface(state.shortcuts)
  local hooks = build_leaf_surface(state.hooks)
  local callbacks = build_leaf_surface(state.callbacks)
  return setmetatable({ }, {
    __index = function(_, k)
      if k == 'shortcuts' then return shortcuts end
      if k == 'hooks' then return hooks end
      if k == 'callbacks' then return callbacks end
      if k == 'fn' then return input_fn_surface end
      if k == 'keys_pressed' then return get_keys() end
      return methods[k]
    end,
    __newindex = function(_, k) frozen_error(k) end,
  })
end

---> REMARK: lets respect the vocabulary. these things are called *callbacks*.
-- The four widget-output entries (doc/development/decisions/input.md,
-- Decision 5):
-- show()/configure() config key and direct field-write
-- share one underlying `state` entry, sticky across shows
-- until overwritten (doc/input_api.md, "Callback
-- assignments"; the doc/development/internals/user_input.md,
-- "configure(config)" live reconfigure surface below
-- leaves this unchanged).
local OUTPUT_KEYS = {
  'on_text_entered',
  'on_limit_reached',
  'validator',
  'highlighter',
}

---> REMARK: why "pending"? need better name. like 'configure-only'? not sure about 'cursor' -- aren't we using set_cursor/get_cursor? not sure what 'cursor' ever means and how its used -- is it?
-- prompt/text/cursor are per-show fields (never sticky at
-- this layer) — EXCEPT when configure() stashes them while
-- hidden: then they apply once, on the very next show().
local PENDING_KEYS = { 'prompt', 'text', 'cursor' }

---> REMARK: why dupicate key names instead of assembling from two tables above?
-- show() has a deliberately small config table.  Callback
-- lifecycle hooks remain explicit compy.input.callbacks writes.
local SHOW_KEYS = {
  prompt = true,
  text = true,
  cursor = true,
  force = true,
  highlighter = true,
  validator = true,
  on_text_entered = true,
  on_limit_reached = true,
}

---> REMARK: why two distinct tables 'SHOW_KEYS' and 'CONFIGURE_KEYS' if they are identical by shape and content?
-- configure() takes the same table minus force: force answers
-- "replace the text of an ALREADY-active overlay", which is
-- the only state configure() ever runs in.
local CONFIGURE_KEYS = { }
for k in pairs(SHOW_KEYS) do CONFIGURE_KEYS[k] = true end
CONFIGURE_KEYS.force = nil

-- Lifecycle callbacks are compy.input.callbacks assignments,
-- never config-table keys. Naming one here is the likeliest
-- mistake, so it earns a message that says where it belongs.
local LIFECYCLE_KEYS = {
  before_submit = true, after_submit = true,
  before_cancel = true, after_cancel = true,
}

--- @param fname string
--- @param key any
--- @return string
local function bad_key_message(fname, key)
  local name = tostring(key)
  if LIFECYCLE_KEYS[name] then
    return fname .. ": assign '" .. name ..
      "' on compy.input.callbacks, do not pass it here"
  end
  return fname .. ": unknown config key '" .. name .. "'"
end

--- Strict contract enforcement
--- (doc/development/decisions/input.md, Decision 15):
--- the config table is CLOSED, so a key
--- outside it can only be an authoring error — raise, and let
--- the project stop at the typo instead of running on in a
--- shape nobody asked for. Level 3 puts the trace on the
--- project's own show()/configure() line.
--- Runtime STATE no-ops (an active overlay, a hidden widget)
--- are NOT this: they keep warning, per Decision 3.
--- @param cfg table
--- @param fname string
--- @param allowed table
local function check_keys(cfg, fname, allowed)
  for key in pairs(cfg) do
    if not allowed[key] then
      error(bad_key_message(fname, key), 3)
    end
  end
end

--- Merge the sticky output-callback state into a show()/
--- configure() config in place: an explicit value wins and is
--- written back into `state`; an absent one defaults to the
--- last-known value.
--- @param state table
--- @param cfg table
local function merge_output_keys(state, cfg)
  for _, k in ipairs(OUTPUT_KEYS) do
    if cfg[k] ~= nil then state.callbacks[k] = cfg[k] end
    cfg[k] = state.callbacks[k]
  end
end

--- Consume the hidden-configure pending prompt/text/cursor
--- (doc/development/internals/user_input.md, "configure(config)"): spent
--- on this show() regardless of whether it
--- ends up used (an explicit cfg value at this same show() call
--- wins) — a later bare show() must not keep re-injecting a
--- stale draft.
--- @param pending table
--- @param cfg table
local function consume_pending(pending, cfg)
  for _, k in ipairs(PENDING_KEYS) do
    if cfg[k] == nil then cfg[k] = pending[k] end
    pending[k] = nil
  end
end

--- Stash configure()'s provided prompt/text/cursor into the
--- pending store for consumption by the next show()
--- (doc/development/internals/user_input.md, "configure(config)");
--- output-callback fields go through the same sticky `state`
--- fields show() already reads — persisted, never applied
--- live (there is no active session to apply them to).
--- @param state table
--- @param cfg table
local function stash_hidden_configure(state, cfg)
  merge_output_keys(state, cfg)
  for _, k in ipairs(PENDING_KEYS) do
    if cfg[k] ~= nil then state.pending[k] = cfg[k] end
  end
end

---> REMARK: major flaw in recent changes across this file is: a) there's too much boilerplate and copypaste for functions that merely do one simple sing (validation and rejection of config keys in various contexts) b) real load-bearing functions are simply lambdas inside moster block (build_widget_api) -- I'd rather extract show and hide here into first-class functions, and reference them from api dictionary -- its much more readable (also why not define them in separate file at all?)

-- Builds the compy.input surface: the three-consumer dispatch
-- surface (doc/development/decisions/input.md, Decision 2) a
-- project registers against. `shortcuts[event]` are the
-- doc/development/decisions/input.md, Decision 8 per-event combo
-- sub-tables (normalising); `hooks[event]` is the one seeded hook
-- per event (Decision 10). show/hide drive the widget
-- (resolved from love.state, never held by the project).
-- The widget-method surface a project drives (show/hide/
-- configure/set_text/set_cursor/get_cursor/clear), parameterized
-- by instance: any
-- adopter — not only the project overlay — gets the same
-- ergonomics over ITS OWN widget by supplying its own resolvers.
-- `get_widget` resolves the UserInputController; `get_active_flag`
-- reports shown-ness (truthy = shown); `state` is the sticky
-- output/pending store show()/configure() read. The project
-- overlay closes the two resolvers over the love.state globals —
-- behaviour-identical to the pre-factory inline shape.
--- @param get_widget fun(): UserInputController?
--- @param get_active_flag fun(): table?
--- @param state table
--- @return table
local function build_widget_api(get_widget, get_active_flag, state)
  return {
    show = function(cfg)
      local next_cfg = cfg or {}
      check_keys(next_cfg, 'compy.input.show', SHOW_KEYS)
      merge_output_keys(state, next_cfg)
      consume_pending(state.pending, next_cfg)
      local ui = get_widget()
      if ui then ui:show(next_cfg) end
    end,
    hide = function()
      local ui = get_widget()
      if ui then ui:hide() end
    end,
    -- doc/development/decisions/input.md, Decision 18: the one
    -- state question a project may ask the overlay. It cannot
    -- read this itself — a project's `love` is a sandboxed
    -- clone, so `love.state.user_input` is always nil inside a
    -- project (internals/project_sandbox_env.md).
    is_shown = function()
      return get_active_flag() or false
    end,
    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": 1-based (line, col); nil
    -- when hidden — a plain read of "nothing to report", not
    -- a refused mutation, so unlike set_cursor/set_text
    -- below it does not warn (same section).
    get_cursor = function()
      if not get_active_flag() then return nil end
      return get_widget():get_cursor_pos()
    end,
    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": clamped move; no-op +
    -- warn while hidden.
    set_cursor = function(line, col)
      if not get_active_flag() then
        Log.warn('compy.input.set_cursor ignored — hidden')
        return
      end
      get_widget():set_cursor_pos(line, col)
    end,
    -- doc/input_api.md, "Live changes": replace content
    -- (cursor to end, or kept + clamped); no-op + warn
    -- while hidden; view updates via the controller's
    -- set_text (no re-show).
    set_text = function(text, keep_cursor)
      if not get_active_flag() then
        Log.warn('compy.input.set_text ignored — hidden')
        return
      end
      get_widget():set_text(text, keep_cursor)
    end,
    -- doc/development/internals/user_input.md, "configure(config)": live
    -- update on an active session (only
    -- the Contract's live-updatable set — prompt/highlighter/
    -- validator/widget outputs; text/cursor inert there); safe
    -- + un-warned while hidden — provided fields persist (via
    -- state/pending, same fields show() reads) for the very next
    -- show(). Never a partial/silent apply either way.
    configure = function(cfg)
      local next_cfg = cfg or { }
      check_keys(next_cfg, 'compy.input.configure',
        CONFIGURE_KEYS)
      if not get_active_flag() then
        stash_hidden_configure(state, next_cfg)
        return
      end
      merge_output_keys(state, next_cfg)
      get_widget():configure(next_cfg)
    end,
    -- doc/development/internals/user_input.md, "clear()": empty content +
    -- cursor to start, no callback;
    -- no-op + warn while hidden. Refreshes the view directly
    -- (no re-show) — reuses the controller's existing clear()
    -- (content + error state).
    clear = function()
      if not get_active_flag() then
        Log.warn('compy.input.clear ignored — hidden')
        return
      end
      local ui = get_widget()
      ui:clear()
      ui:update_view()
    end,
  }
end

local get_compy_input = function()
  -- callbacks IS the overlay widget's OWN table (owner ruling
  -- 2026-07-20: compy.input.callbacks === the widget's
  -- self.callbacks). The widget is provisioned before the console
  -- (main.lua reorder), so it exists here. NEVER reassign this
  -- table — only mutate it — since the surface holds this exact
  -- reference (teardown re-seeds in place).
  local widget = love.state.user_input_controller
  -- One combo table per channel, from the list the route
  -- dispatches on — not a copy of it, so a channel cannot exist
  -- for dispatch and be missing here.
  local shortcut_tables = { }
  for _, ev in ipairs(ProjectInputController.EVENTS) do
    shortcut_tables[ev] = Key.new_handler_table()
  end
  local state = {
    -- shortcuts: per-event combo tables (Decision 8, normalising).
    -- hooks: one fn per event, seeded once at activation (Decision
    -- 10 revised). callbacks: the widget's own table (Decision 7
    -- revised). shortcuts/hooks start empty (leaves fill on project
    -- write); callbacks carries the widget's stay-open defaults.
    shortcuts = shortcut_tables,
    hooks = { },
    callbacks = widget.callbacks,
    pending = { },
  }
  -- get_active resolves the overlay's OWN shown flag (is_shown),
  -- never love.state directly.
  local function get_active()
    local w = love.state.user_input_controller
    return w and w:is_shown()
  end
  local methods = build_widget_api(
    function() return love.state.user_input_controller end,
    get_active,
    state)
  -- doc/development/decisions/input.md, Decision 20: the
  -- held-key view a project can read OUTSIDE an event. The same
  -- read-only proxy the chain hands participants (Decision 13)
  -- — a project cannot build one, its `love` being a clone.
  local held = Controller.held_keys
  return build_input_surface(state, methods, held)
end

-- Builds the `compy.*` table injected into a project's sandbox env (terminal, audio, graphics,
-- fonts, input); called while preparing the project environment.
local get_compy_namespace = function(terminal)
  require("util.namespace.fonts")
  ---> REMARK: why so special treatment for 'before_exit_slot' if default_before_exit is simply a noop? that's exactly case where simple check of nil-ness followed by execution of non-nil function would be justified than complex meta-table jugglng (feel free to contest)
  local before_exit_slot = default_before_exit
  local ns = {
    terminal = get_compy_terminal(terminal),
    audio = compy_audio,
    graphics = compy_graphics,
    fonts = CompyFonts(),
    input = get_compy_input(),
  }
  return setmetatable(ns, {
    __index = function(t, k)
      if k == 'before_exit' then return before_exit_slot end
      return rawget(t, k)
    end,
    __newindex = function(t, k, v)
      if k == 'before_exit' then
        before_exit_slot = v
      else
        rawset(t, k, v)
      end
    end,
  })
end

function ConsoleController.prepare_env(cc)
  local prepared            = cc.main_env
  prepared.gfx              = love.graphics

  local P                   = cc.model.projects

  prepared.require          = function(name)
    return project_require(name)
  end

  --- @param f function
  local check_open_pr       = function(f, ...)
    if not P.current then
      print(P.messages.no_open_project)
    else
      return f(...)
    end
  end

  prepared.require          = project_require

  prepared.dofile           = function(name)
    return check_open_pr(function()
      return project_dofile(cc, name)
    end)
  end

  prepared.list_projects    = function()
    local ps = P:list()
    if ps:is_empty() then
      -- no projects, display a message about it
      print(P.messages.no_projects)
    else
      -- list projects
      cc.model.output:reset()
      print(P.messages.list_header)
      for _, p in ipairs(ps) do
        print('> ' .. p.name)
      end
    end
  end

  --- @param name string
  local open_project        = function(name)
    return cc:open_project(name)
  end

  prepared.project          = open_project

  prepared.close_project    = function()
    close_project(cc)
  end

  prepared.current_project  = function()
    if P.current and P.current.name then
      print('Currently open project: ' .. P.current.name)
    else
      print(P.messages.no_open_project)
    end
  end

  prepared.example_projects = function()
    local ok, err = P:deploy_examples()
    if not ok then
      print('err: ' .. err)
    end
  end

  prepared.clone            = function(old, new)
    local ok, err = P:clone(old, new)
    if not ok then
      print(err)
    end
  end

  prepared.list_contents    = function()
    return check_open_pr(function()
      local p = P.current
      local items = p:contents()
      print(P.messages.project_header(p.name))
      for _, f in pairs(items) do
        print('• ' .. f.name)
      end
    end)
  end

  --- @param name string
  --- @return string?
  prepared.readfile         = function(name)
    return check_open_pr(cc._readfile, cc, name)
  end

  --- @param name string
  --- @return function? chunk
  prepared.loadfile         = function(name)
    return check_open_pr(cc.loadfile, cc, name)
  end

  --- @param name string
  --- @return string[]?
  prepared.readlines        = function(name)
    return check_open_pr(cc._readlines, cc, name)
  end

  --- @param name string
  --- @param content string[]
  prepared.writefile        = function(name, content)
    return check_open_pr(cc.writefile, cc, name, content)
  end

  --- @param name string
  prepared.edit             = function(name)
    return check_open_pr(cc.edit, cc, name)
  end

  prepared.run_project      = function(name)
    cc:run_project(name)
  end

  local terminal            = cc.model.output.terminal
  local compy_namespace     = get_compy_namespace(terminal)
  prepared.compy            = compy_namespace
  prepared.tty              = compy_namespace.terminal

  prepared.run              = prepared.run_project

  prepared.eval             = LANG.eval
  prepared.print_eval       = LANG.print_eval

  prepared.appver           = function()
    local ver = FS.read('ver.txt', true)
    if ver then print(ver) end
  end

  prepared.quit             = function()
    love.event.quit()
  end
end

--- API functions for the user
--- @param cc ConsoleController
function ConsoleController.prepare_project_env(cc)
  require("controller.userInputController")
  require("model.input.userInputModel")
  require("view.input.userInputView")
  local cfg                   = cc.model.cfg
  ---@type table
  local project_env           = cc:get_pre_env_c()

  project_env.require         = function(name)
    return project_require(name)
  end
  project_env.dofile          = function(name)
    return project_dofile(cc, name, cc:get_project_env())
  end
  -- project_env.require         = function(name)
  --   return project_require(name, 'run')
  -- end

  --- @param name string
  --- @return string?
  project_env.readfile        = function(name)
    --- @diagnostic disable-next-line: invisible
    return cc:_readfile(name)
  end

  --- @param name string
  --- @return string[]?
  project_env.readlines       = function(name)
    --- @diagnostic disable-next-line: invisible
    return cc:_readlines(name)
  end

  --- @param name string
  --- @param content string[]
  project_env.writefile = function(name, content)
    return cc:writefile(name, content)
  end

  --- @param name string
  --- @return function? chunk
  project_env.loadfile         = function(name)
    return cc:loadfile(name)
  end

  --- @param msg string?
  project_env.pause           = function(msg)
    cc:suspend_run(msg)
  end
  project_env.stop            = function()
    cc:stop_project_run()
  end
  project_env.run             = function()
    if love.state.app_state == 'inspect' then
      cc:stop_project_run()
      cc:run_project()
    end
  end
  project_env.run_project     = project_env.run

  project_env.continue        = function()
    if love.state.app_state == 'inspect' then
      -- resume
      love.state.app_state = 'running'
      cc.main_ctrl.restore_user_handlers(cc)
    else
      print('No project halted')
    end
  end

  project_env.close_project   = function()
    close_project(cc)
  end

  --- @param name string
  project_env.edit           = function(name)
    return cc:edit(name)
  end

  project_env.gfx            = love.graphics

  local terminal             = cc.model.output.terminal
  local compy_namespace      = get_compy_namespace(terminal)
  project_env.compy          = compy_namespace

  project_env.LuaHighlighter = LuaHighlighter
  project_env.LuaSyntaxValidator = LuaSyntaxValidator
  project_env.LineValidators = LineValidators
  ---> REMARK: why those four below are nils, and what's the point of exporting them into project_env if they are not real functions?
  project_env.InputEvalText  = nil
  project_env.InputEvalLua   = nil
  project_env.ValidatedTextEval = nil
  project_env.LuaEditorEval  = nil

  project_env.eval           = LANG.eval
  project_env.print_eval     = LANG.print_eval

  local base                 = table.clone(project_env)
  local project              = table.clone(project_env)
  cc:_set_base_env(base)
  cc:_set_project_env(project)
end

---@param dt number
function ConsoleController:pass_time(dt)
  self.time = self.time + dt
  self.model.output.terminal:update(dt)
end

---@return number
function ConsoleController:get_timestamp()
  return self.time
end

function ConsoleController:evaluate_input()
  local inter = self.input

  local text = inter:get_text()
  if text:is_empty() then return end
  local eval = inter:get_eval()

  local eval_ok, res = inter:evaluate()

  if eval_ok and not string.is_non_empty(res) then
    return
  end

  if eval and eval.parser then
    if eval_ok then
      local code = string.unlines(text)
      local run_env = (function()
        if love.state.app_state == 'inspect' then
          return self:get_project_env()
        end
        return self:get_console_env()
      end)()
      local f, load_err = codeload(code, run_env)
      if f then
        local _, err = run_user_code(f, self)
        if err then
          inter:set_error({ err })
        else
          inter:clear()
        end
      else
        Log.error('Load error:', LANG.get_call_error(load_err))
        inter:set_error(load_err)
      end
    else
      local eval_err = res
      if eval_err then
        inter:set_error(eval_err)
      end
    end
  end
end

function ConsoleController:_reset_executor_env()
  self:_set_project_env(table.clone(self.base_env))
end

function ConsoleController:reset()
  self:quit_project()
  self.input:reset(true) -- clear history
end

function ConsoleController:restart()
  self:stop_project_run()
  self:run_project()
end

---@return LuaEnv
function ConsoleController:get_pre_env_c()
  return table.clone(self.pre_env)
end

---@return LuaEnv
function ConsoleController:get_console_env()
  return self.main_env
end

---@return LuaEnv
function ConsoleController:get_project_env()
  return self.project_env
end

---@return LuaEnv
function ConsoleController:get_base_env()
  return self.base_env
end

---@return LuaEnv
function ConsoleController:get_effective_env()
  if
      love.state.app_state == 'running'
      or love.state.app_state == 'inspect'
  then
    return self:get_project_env()
  else
    return self:get_console_env()
  end
end

---@param t LuaEnv
function ConsoleController:_set_project_env(t)
  self.project_env = t
end

---@param t LuaEnv
function ConsoleController:_set_base_env(t)
  self.base_env = t
  table.protect(t)
end

function ConsoleController:suspend()
  if love.state.app_state ~= 'snapshot' then
    return
  end
  local runner_env = self:get_project_env()
  Log.info('Suspending project run')
  love.state.app_state = 'inspect'
  local msg = love.state.suspend_msg
  if msg then
    self.input:set_error({ tostring(msg) })
    love.state.suspend_msg = nil
  end

  self.model.output:invalidate_terminal()

  self.main_ctrl.save_user_handlers(runner_env['love'])
  self.main_ctrl.set_default_handlers(self, self.view)
end

--- @param msg string?
function ConsoleController:suspend_run(msg)
  if love.state.app_state ~= 'running' then
    return
  end
  love.state.app_state = 'snapshot'
  love.state.suspend_msg = msg
end

--- @param name string
--- @param play boolean
--- @return boolean success
function ConsoleController:open_project(name, play)
  local P = self.model.projects
  if not name then
    print('No project name provided!')
    return false
  end
  local cur = P.current
  if cur then
    self:close_project()
  end

  local open, create, err = P:opreate(name, play)
  local ok = open or create
  if ok then
    local project_loader =
        P.current:get_loader(function()
          return self:get_effective_env()
        end)
    self:cache_loader(name, project_loader)

    if not table.is_member(package.loaders, project_loader)
    then
      table.insert(package.loaders, 1, project_loader)
    end
    love.state.app_state = 'project_open'
  end
  if open then
    print('Project ' .. name .. ' opened')
  elseif create then
    print('Project ' .. name .. ' created')
  else
    print(err)
  end
  return ok
end

--- @return boolean success
function ConsoleController:close_project()
  local P = self.model.projects
  local open = P.current
  if open then
    local name = P.current.name
    local ok = P:close()
    local lf = self:get_loader(name)
    if lf then
      table.delete_by_value(package.loaders, lf)
    end
    self:_reset_executor_env()
    self.model.output:clear_canvas()
    View.clear_snapshot()
    love.state.app_state = 'ready'
    return ok
  end
  return true
end

--- @return Project?
function ConsoleController:get_current_project()
  local P = self.model.projects
  return P.current
end

function ConsoleController:evacuate_required()
  local open = self:get_current_project()
  if not open then return end
  local files = open:contents()
  local lua = '.lua$'
  for _, v in ipairs(files) do
    if string.matches(v.name, lua, true) then
      local fn = v.name
      local modname = fn:gsub(lua, '')
      if package.loaded[modname] then
        package.loaded[modname] = nil
      end
    end
  end
end

function ConsoleController:stop_project_run()
  self:evacuate_required()
  local compy = self:get_project_env().compy
  ---> REMARK: that's exactly where we can check hook existance before execution instead of relying on 20 lines of useless boilerplate and metatables
  compy.before_exit()
  self.main_ctrl.set_default_handlers(self, self.view)
  self.main_ctrl.set_love_update(self)
  hide_overlay()
  View.clear_snapshot()
  self.main_ctrl.set_love_draw(self, self.view)
  self.main_ctrl.clear_user_handlers(self)
  compy.before_exit = default_before_exit
  self.main_ctrl.report()
  love.state.app_state = 'project_open'
end

function ConsoleController:quit_project()
  self:stop_project_run()
  self:close_project()
  self.model.output:reset()
  self.input:reset()
end

--- @param name string
--- @param state EditorState
function ConsoleController:edit(name, state)
  if love.state.app_state == 'running' then return end

  local PS = self.model.projects
  local p  = PS.current
  if not p then return end
  local filename
  -- if state and state.buffer then
  --   filename = state.buffer.filename
  -- else
  filename    = name or ProjectService.MAIN
  -- end
  local fpath = p:get_path(filename)
  local ex    = FS.exists(fpath)
  local text
  if ex then
    text = self:_readfile(filename)
  end

  if love.state.app_state ~= 'editor' then
    love.state.prev_state = love.state.app_state
    love.state.app_state = 'editor'
  end
  local save = function(newcontent)
    return self:_writefile(filename, newcontent)
  end

  self.editor:open(filename, text, save)
  self.editor:restore_state(state)
end

--- @return EditorState?
function ConsoleController:close_buffer()
  self.editor:close_buffer()
end

--- @return EditorState?
function ConsoleController:finish_edit()
  self.editor:save_state()
  self.editor:close()
  local ok = true
  local errs = {}
  if ok then
    love.state.app_state = love.state.prev_state
    love.state.prev_state = nil
  else
    print(string.unlines(errs))
  end
  self.buffers = {}
  return self.editor:get_state()
end

--- Handlers ---

--- @param t string
function ConsoleController:textinput(t)
  if love.state.app_state == 'editor' then
    self.editor:textinput(t)
  elseif self.cfg.mode == 'play' then
    --- console is disabled in this mode
  else
    local input = self.input
    if input:has_error() then
      input:clear_error()
    else
      if Key.ctrl() and Key.shift() then
        return
      end
      input:textinput(t)
    end
  end
end

--- @param k string
function ConsoleController:keypressed(k)
  local input = self.input

  local function terminal_test()
    local out = self.model.output
    if love.state.app_state ~= 'ready'
        or love.state.app_state ~= 'project_open'
    then
      return
    end
    if not love.state.testing then
      love.state.testing = 'running'
      input:cancel()
      TerminalTest.test(out.terminal)
    elseif love.state.testing == 'waiting' then
      TerminalTest.reset(out.terminal)
      love.state.testing = false
    end
  end

  if love.state.app_state == 'editor' then
    self.editor:keypressed(k)
  else
    if love.state.testing == 'running' then
      return
    end
    if love.state.testing == 'waiting' then
      terminal_test()
      return
    end

    if input:has_error() then
      if k == 'space' or Key.is_enter(k)
          or k == "up" or k == "down" then
        input:clear_error()
      end
      return
    end

    if k == "pageup" then
      input:history_back()
    end
    if k == "pagedown" then
      input:history_fwd()
    end
    -- History navigation at the vertical boundary is driven by
    -- the widget's on_limit_reached callback (set at construction),
    -- not by keypressed's return value (retired,
    -- doc/development/decisions/input.md, Decision 5).
    -- keypressed still runs for its editing side effects; its
    -- return is unused.
    input:keypressed(k)
    if not Key.shift() and Key.is_enter(k) then
      if not input:has_error() then
        self:evaluate_input()
      end
    end

    -- Ctrl held
    if Key.ctrl() then
      if k == "l" then
        self.model.output:reset()
      end
      if love.DEBUG then
        if Key.alt() and k == 't' then
          terminal_test()
          return
        end
      end
    end
  end
  input:update_view()
end

--- @param k string
function ConsoleController:keyreleased(k)
  self.input:keyreleased(k)
  self.input:update_view()
end

--- @param x integer
--- @param y integer
--- @param btn integer
--- @param touch boolean
--- @param presses number
function ConsoleController:mousepressed(
    x, y, btn, touch, presses)
  if love.DEBUG then
    Log.info(string.format('click! {%d, %d}', x, y))
  end
  if love.state.app_state == 'editor' then
    if self.cfg.editor.mouse_enabled then
      self.editor.input:mousepressed(x, y, btn, touch, presses)
    end
  else
    self.input:mousepressed(x, y, btn, touch, presses)
  end
end

--- @param x integer
--- @param y integer
--- @param btn integer
--- @param touch boolean
--- @param presses number
function ConsoleController:mousereleased(
    x, y, btn, touch, presses)
  if love.state.app_state == 'editor' then
    if self.cfg.editor.mouse_enabled then
      self.editor.input:mousereleased(x, y, btn, touch, presses)
    end
  else
    self.input:mousereleased(x, y, btn, touch, presses)
  end
end

--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param touch boolean
function ConsoleController:mousemoved(x, y, dx, dy, touch)
  if love.state.app_state == 'editor' then
    if self.cfg.editor.mouse_enabled then
      self.editor.input:mousemoved(x, y, dx, dy, touch)
    end
  else
    self.input:mousemoved(x, y, dx, dy, touch)
  end
end

--- @param x number
--- @param y number
function ConsoleController:wheelmoved(x, y)
  if love.state.app_state == 'editor' then
    if self.cfg.editor.mouse_enabled then
      self.editor.input:wheelmoved(x, y)
    end
  else
    self.input:wheelmoved(x, y)
  end
end

--- @param id userdata
--- @param x number
--- @param y number
--- @param dx number?
--- @param dy number?
--- @param pressure number?
function ConsoleController:touchpressed(id, x, y,
                                        dx, dy, pressure)
  if love.state.app_state == 'editor' then
    if self.cfg.editor.touch_enabled then
      self.editor.input:touchpressed(id, x, y, dx, dy, pressure)
    end
  else
    self.input:touchpressed(id, x, y, dx, dy, pressure)
  end
end

--- @param id userdata
--- @param x number
--- @param y number
--- @param dx number?
--- @param dy number?
--- @param pressure number?
function ConsoleController:touchreleased(id, x, y,
                                         dx, dy, pressure)
  if love.state.app_state == 'editor' then
    if self.cfg.editor.touch_enabled then
      self.editor.input:touchreleased(id, x, y,
        dx, dy, pressure)
    end
  else
    self.input:touchreleased(id, x, y, dx, dy, pressure)
  end
end

--- @param id userdata
--- @param x number
--- @param y number
--- @param dx number?
--- @param dy number?
--- @param pressure number?
function ConsoleController:touchmoved(id, x, y,
                                      dx, dy, pressure)
  if love.state.app_state == 'editor' then
    if self.cfg.editor.touch_enabled then
      self.editor.input:touchmoved(id, x, y, dx, dy, pressure)
    end
  else
    self.input:touchmoved(id, x, y, dx, dy, pressure)
  end
end

--- @return Terminal
function ConsoleController:get_terminal()
  return self.model.output.terminal
end

--- @return love.Canvas
function ConsoleController:get_canvas()
  return self.model.output.canvas
end

--- @param f function
function ConsoleController:use_canvas(f)
  local canvas = self.model.output.canvas
  gfx.setCanvas({
    canvas, -- this is actually [1] = canvas
    stencil = true
  })
  local r = f()
  gfx.setCanvas()
  return r
end

--- @return ViewData
function ConsoleController:get_viewdata()
  return {
    w_error = self.input:get_wrapped_error(),
  }
end

function ConsoleController:autotest()
  --- @diagnostic disable-next-line undefined-global
  local autotest = prequire('tests.autotest')
  if autotest then
    autotest(self)
  end
end
