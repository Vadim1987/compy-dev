local class = require('util.class')
require("util.key")
require("util.view")
require("util.string.string")
require("util.lua")

-- Stay-open defaults for the submit/cancel lifecycle
-- after_submit/after_cancel default to
-- no-ops, so a widget stays open unless a callback hides it. on_limit_
-- reached defaults to a no-op so the navigation-boundary emit is an
-- unconditional call. Re-seeded (not wiped) on teardown (AC10).
local function default_callbacks()
  return {
    on_limit_reached = noop,
    after_submit = noop,
    after_cancel = noop,
  }
end

--- @param model UserInputModel
--- @param disable_selection boolean?
--- @param allow_modify boolean?  enable the Ctrl+D duplicate-line
--- combo (editor-only today). Known at construction; the overlay
--- and console never opt in.
local new = function(model, disable_selection, allow_modify)
  return {
    model = model,
    disable_selection = disable_selection,
    -- Ctrl+D duplicate-line gate (editor-only today; a future
    -- combo-table would supersede this per-action flag).
    allow_modify = allow_modify,
    -- Strictly internal shown/hidden flag (owner ruling
    -- 2026-07-20): is_shown() reads this, never love.state. The
    -- overlay starts hidden and is toggled by show()/hide();
    -- always-active widgets (console/editor) set it true at
    -- construction.
    shown = false,
    -- The widget-invoked callbacks (outputs + submit/cancel
    -- lifecycle). For the project overlay this table IS
    -- compy.input.callbacks (same table, owner ruling 2026-07-20);
    -- console/editor set their own directly.
    callbacks = default_callbacks(),
  }
end

--- @class UserInputController
--- @field model UserInputModel
--- @field view UserInputView?
--- @field disable_selection boolean
UserInputController = class.create(new)

--- @param v UserInputView
function UserInputController:init_view(v)
  self.view = v
end

function UserInputController:update_view()
  local input = self.model:get_input()
  local status = self:get_status()
  self.view:render(input, status)
end

---------------
--  entered  --
---------------

--- @param t str
function UserInputController:add_text(t)
  self.model:add_text(string.unlines(t))
end

--- @return InputText
function UserInputController:get_text()
  return self.model:get_text()
end

--- @param t str
--- @param keep_cursor boolean?
function UserInputController:set_text(t, keep_cursor)
  self.model:set_text(t, keep_cursor)
  self:update_view()
end

--- @return boolean
function UserInputController:is_empty()
  local ent = self:get_text()
  local is_empty = not string.is_non_empty_string_array(ent)
  return is_empty
end

--- @param dir VerticalDir?
--- @param scope 'input'|'line'?
--- @return boolean
function UserInputController:is_at_limit(dir, scope)
  return self.model:is_at_limit(dir, scope)
end

----------------
-- evaluation --
----------------

--- @param eval Evaluator
function UserInputController:set_eval(eval)
  self.model:set_eval(eval)
end

--- @return Evaluator
function UserInputController:get_eval()
  return self.model.evaluator
end

function UserInputController:clear()
  self.model:clear_input()
  self:clear_error()
end

--- @param cs CustomStatus
function UserInputController:set_custom_status(cs)
  self.model:set_custom_status(cs)
end

--- @return InputDTO
function UserInputController:get_input()
  return self.model:get_input()
end

--- @return Status
function UserInputController:get_status()
  return self.model:get_status()
end

--- @return CursorInfo
function UserInputController:get_cursor_info()
  return self.model:get_cursor_info()
end

--- @return integer l
--- @return integer c
function UserInputController:get_cursor_pos()
  return self.model:get_cursor_pos()
end

--- @param cursor Cursor
function UserInputController:set_cursor(cursor)
  return self.model:set_cursor(cursor)
end

--- Clamped 2D move (compy.input.set_cursor;
--- doc/development/internals/user_input.md, "Cursor manipulation and
--- 'reset'"). Named
--- apart from set_cursor(Cursor) above — that simple function
--- already has a different signature/caller (editorController
--- load_selection); this computes a valid landing itself
--- (byte length, matching move_cursor's own bound) rather
--- than relying on move_cursor's fallback-to-previous, which
--- does not clamp an out-of-range value to the line/text end.
--- @param line integer
--- @param col integer
function UserInputController:set_cursor_pos(line, col)
  local n = self.model:get_n_text_lines()
  local l = math.max(1, math.min(line, n))
  local llen = #(self.model:get_text_line(l))
  local c = math.max(1, math.min(col, llen + 1))
  self.model:move_cursor(l, c)
end

-----------
-- error --
-----------
--- @return boolean
function UserInputController:has_error()
  return self.model:has_error()
end

function UserInputController:clear_error()
  self.model:clear_error()
end

--- @param error string[]|Error[]?
function UserInputController:set_error(error)
  self.model:set_error(error)
end

--- @return string[]?
function UserInputController:get_wrapped_error()
  return self.model:get_wrapped_error()
end

--- @return boolean
--- @return Error[]
function UserInputController:evaluate()
  local ok, res = self.model:handle(true)
  self:update_view()
  return ok, res
end

--- Unconditional clear + hide. NOT the project widget's Escape path
--- any more (that is `cancel_flow`, below, callback-driven and
--- stay-open by default) — this method survives only as
--- console's own debug/test-mode cancel
--- (`consoleController.lua`'s `terminal_test`).
function UserInputController:cancel()
  self.model:cancel()
  self:hide()
end

function UserInputController:jump_home()
  self.model:jump_home()
end

----------------------
---     history    ---
----------------------
--- @param history boolean?
function UserInputController:reset(history)
  self.model:reset(history)
end

function UserInputController:history_back()
  self.model:history_back()
end

function UserInputController:history_fwd()
  self.model:history_fwd()
end

----------------------
---   widget API    ---
----------------------

-- Internal widget API. Not called by projects directly — only via the compy.input.*
-- wrappers (consoleController). Free functions rather than class methods because they are
-- private helpers to show()/hide() below.

--- @param self UserInputController
--- @param cfg table
local apply_config = function(self, cfg)
  if cfg.prompt ~= nil then
    self.model.custom_label = cfg.prompt
  end
  if cfg.text ~= nil then
    self.model:set_text(cfg.text)
  end
  local ev = self.model.evaluator
  if cfg.highlighter ~= nil and ev then
    ev.highlighter = cfg.highlighter
  end
  if cfg.validator ~= nil then
    self.callbacks.validator = cfg.validator
  end
  if cfg.on_text_entered ~= nil then
    self.callbacks.on_text_entered = cfg.on_text_entered
  end
  if cfg.on_limit_reached ~= nil then
    self.callbacks.on_limit_reached = cfg.on_limit_reached
  end
end


--- Fresh activation of the overlay widget: clear content when no text is given, apply
--- config, publish the overlay handle, render once. Called only by show() on the
--- inactive->active transition (show() guards against re-entry while active). The
--- clear-on-no-text lives here, not in apply_config, because it is activation policy
--- (a re-show with no text starts empty) rather than per-field config.
--- `cursor` (a `{line, col}` pair) lands here too, applied
--- after text (doc/development/internals/user_input.md, "Cursor
--- manipulation and 'reset'") — kept out of apply_config so
--- the live-reconfigure path (configure() below) can never
--- reach it.
--- @param self UserInputController
--- @param cfg table
local open_fresh = function(self, cfg)
  if cfg.text == nil then
    self.model:clear_input()
  end
  apply_config(self, cfg)
  if cfg.cursor ~= nil then
    self:set_cursor_pos(cfg.cursor[1], cfg.cursor[2])
  end
  -- love.state.user_input is the overlay CONTRACT: its
  -- presence is the flag the draw loop (controller.lua)
  -- checks to paint V:draw() each frame, and it carries the
  -- { M, C, V } handle the legacy poll idiom reads. Drivers
  -- change but the flag persists (doc/development/internals/user_input.md,
  -- "Widget lifecycle").
  love.state.user_input = {
    M = self.model,
    C = self,
    V = self.view,
  }
  self.shown = true
  self:update_view()
end

--- Activate the widget.
--- No-op if already active, unless force=true.
--- @param config table?
function UserInputController:show(config)
  local cfg = config or {}
  if self.shown then
    -- doc/development/decisions/input.md, Decision 3 (warn-don't-swallow):
    -- a plain show() over an active overlay is suppressed;
    -- say so.
    if not cfg.force then
      Log.warn('UserInputController:show ignored — overlay already active (pass force=true to override)')
      return
    end
    -- force=true intentionally applies only the text subset
    -- of cfg on an active overlay; a full live reconfigure
    -- is the compy.input API's configure() (internals/
    -- user_input.md, "configure(config)"). Other fields
    -- are ignored here by design.
    if cfg.text ~= nil then
      self.model:set_text(cfg.text)
      self:update_view()
    end
    return
  end
  open_fresh(self, cfg)
end

--- Deactivate without firing the cancel chain. Clearing
--- love.state.user_input is what "hides" the overlay: the
--- draw loop (controller.lua) paints V:draw() only while
--- the flag is set, so nil-ing it stops the paint on the
--- next frame.
function UserInputController:hide()
  self.shown = false
  love.state.user_input = nil
end

--- Live-reconfigure an active session (compy.input.
--- configure; doc/development/internals/user_input.md, "configure(config)"
--- — the boundary decision closed here): only
--- the Contract's live-updatable set reaches apply_config —
--- prompt/highlighter/validator/widget-output callbacks. text/
--- cursor never reaches it from here — accepted but
--- inert on an active session (use set_text/set_cursor, or
--- clear()+show()); no partial/silent path exists because this
--- filtered table is the only thing configure() ever applies.
--- @param cfg table
function UserInputController:configure(cfg)
  apply_config(self, {
    prompt           = cfg.prompt,
    highlighter      = cfg.highlighter,
    validator        = cfg.validator,
    on_text_entered  = cfg.on_text_entered,
    on_limit_reached = cfg.on_limit_reached,
  })
  self:update_view()
end

----------------------
--- submit / cancel ---
----------------------

-- Submit/cancel are the widget's OWN default behaviour
-- (doc/development/decisions/input.md, Decision 6 revised; validation/
-- reviews/delta-spec-input-api.md §3): the widget runs them on
-- Enter/Escape as an ordinary consumer (never a routing concern)
-- and signals out through its callbacks. before_/after_submit and
-- before_/after_cancel are read off self.callbacks — the same
-- table a project populates via compy.input.callbacks.

--- Validator gate (doc/development/internals/user_input.md, "Submit and
--- cancel — widget-owned callback sequences").
--- No custom validator
--- accepts unconditionally; a set validator's ok/err_msg
--- verdict decides, locking the session on reject via the
--- existing has_error()/clear_error() gate in keypressed().
--- @param model UserInputModel
--- @param validator function?
--- @param lines string[]
--- @return boolean ok
local function gate(model, validator, lines)
  if not validator then return true end
  local ok, errors = validator(lines)
  if not ok then model:set_error(errors) end
  return ok
end

--- @param label string
--- REVIEW/nitpick: noop_debug would be better semantically (primary action first, side-effect second). Also using it as factory would be even more elegant (therefore 'noop_debug()' would produce earmarked 'noop' that could be invoked transparently)
local function debug_noop(label)
  if love.DEBUG then
    Log.debug('input: ' .. label .. ' noop')
  end
end

--- Invoke a widget callback by name (self.callbacks[name]);
--- absent → no-op + debug-log. The return value is honoured by
--- the caller only where noted (before_cancel veto).
--- @param self UserInputController
--- @param name string
--- @return any
local function run_callback(self, name, ...)
  local cb = self.callbacks[name]
  if cb then return cb(...) end
  debug_noop(name)
end

--- Submit flow (doc/development/decisions/input.md, Decision 6
--- revised; validation/reviews/delta-spec-input-api.md §3): the
--- widget's own Enter behaviour. before_submit (veto reserved,
--- unbuilt) → empty guard → validate → deliver (fires
--- on_text_entered) → after_submit. after_submit defaults to a
--- no-op, so the widget stays open unless a callback hides it.
--- @param keys_pressed table?
function UserInputController:submit_flow(keys_pressed)
  run_callback(self, 'before_submit', keys_pressed)
  if self.model:get_text():is_empty() then return end
  local lines = self.model:get_text()
  if not gate(self.model, self.callbacks.validator, lines) then
    return
  end
  run_callback(self, 'on_text_entered', lines)
  run_callback(self, 'after_submit', lines)
end

--- Cancel flow (Decision 6 revised; delta-spec §3): the
--- widget's own Escape behaviour. A truthy before_cancel VETOES
--- (skips the clear); otherwise clear (hardwired) → after_cancel.
--- after_cancel defaults to a no-op — Escape clears but the widget
--- stays open unless a callback hides it.
--- @param keys_pressed table?
function UserInputController:cancel_flow(keys_pressed)
  if run_callback(self, 'before_cancel', keys_pressed) then
    return
  end
  self.model:cancel()
  run_callback(self, 'after_cancel')
end

----------------------
--- event handlers ---
----------------------

--- Whether this widget is currently shown — a strictly INTERNAL
--- flag (owner ruling 2026-07-20; no love.state reach). Toggled
--- by show()/hide(); always-active widgets (console/editor) set
--- it true at construction. The project route consumes an event
--- at the widget only while shown; the view skips its per-frame
--- redraw only while shown.
--- @return boolean
function UserInputController:is_shown()
  return self.shown
end

--- Mark this widget as an always-active surface (console/editor
--- input, never toggled like the transient overlay) and return
--- self, for inline construction. The overlay leaves shown=false
--- and toggles it via show()/hide().
--- @return UserInputController self
function UserInputController:always_shown()
  self.shown = true
  return self
end

--- Re-seed the callbacks to the stay-open DEFAULT_CALLBACKS, IN
--- PLACE — never reassign the table, the compy.input surface
--- holds this exact reference. Teardown between project runs
--- (doc/development/decisions/input.md, Decision 11; delta-spec §3
--- "re-seed, don't wipe" / AC10): clears a stopped project's
--- callbacks and restores defaults, so a nil'd after_cancel never
--- silently means "stays open forever" for the next project.
function UserInputController:reset_callbacks()
  local c = self.callbacks
  for k in pairs(c) do c[k] = nil end
  for k, v in pairs(default_callbacks()) do c[k] = v end
end

----------------
--  keyboard  --
----------------

--- @param k string
--- @param keys_pressed table?  read-only pressed-keys view
--- (doc/development/decisions/input.md, Decision 13)
--- @param isr boolean?
-- No return value: the old limit-flag return channel is retired
-- (Decision 5 revised) — on_limit_reached is the sole notification
-- path now (see "emit_limit" below).
-- This handler now receives the uniform
-- (k, keys_pressed, isr) triple (doc/development/decisions/input.md,
-- Decision 9).
-- Its own editing logic still reads modifiers via Key.*
-- (love.keyboard) — widening that to the keys_pressed
-- read-only view is not required here, but recommended in
-- the future.
function UserInputController:keypressed(k, keys_pressed, isr)
  if not self.shown then
    if love.DEBUG then Log.debug('input: hidden no-op') end
    return
  end
  -- Defensive render-on-entry: guarantees the view catches up to the model even if a prior
  -- branch returned without re-rendering. Mutating branches below re-render at their end,
  -- so this is belt-and-suspenders, not the primary update.
  self:update_view()
  -- _G.web: web/love.js build flag. On web, space may not emit
  -- textinput, so synthesise it here.
  if _G.web and k == 'space' then
    self:textinput(' ')
  end
  local input = self.model

  -- Navigation-boundary output (doc/development/decisions/input.md,
  -- Decision 5 revised): the widget signals a hit limit ONLY
  -- through on_limit_reached — the keypressed return value no
  -- longer carries a limit flag (retired; console reads history
  -- via its own on_limit_reached callback, delta-spec §6).
  local function emit_limit(dir, scope)
    local cb = self.callbacks.on_limit_reached
    if cb then cb(dir, scope) end
  end

  local function horizontal_limit_scope(dir)
    if input:get_n_text_lines() == 1 then return 'input' end
    if input:is_at_limit(dir, 'input') then return 'input' end
    return 'line'
  end

  -- (combo serialisation lives in controller.lua; this
  -- handler only sees the raw key.)
  -- doc/development/internals/user_input.md, "Error state": locked-on-reject
  -- unlocks on Enter/Space/arrows.
  if input:has_error() then
    if Key.is_enter(k)
        or k == "up" or k == "down"
        or k == "left" or k == "right"
        or k == "space"
    then
      input:clear_error()
    end
    return
  end

  -- utility functions
  local function paste()
    input:paste(love.system.getClipboardText())
    input:clear_selection()
  end
  local function copy()
    local t = string.unlines(input:get_selected_text())
    if string.is_non_empty_string(t) then
      love.system.setClipboardText(t)
    end
  end
  local function cut()
    local t = string.unlines(
      input:pop_selected_text() or { '' }
    )
    if string.is_non_empty_string(t) then
      love.system.setClipboardText(t)
    end
  end
  --- @param dir VerticalDir
  local function swap_line(dir)
    local cl = input:get_cursor_y()
    --- this looks reversed because the cursor is already moved
    --- by the time we are here, so we are swapping the previous
    --- line with the current, not the current with the next
    local pl = (function()
      if dir == 'up' then return cl + 1 end
      if dir == 'down' then return cl - 1 end
    end)()
    if pl then input:swap_lines(cl, pl) end
  end

  -- action categories
  local function removers()
    if k == "backspace" then
      input:backspace()
    end
    if k == "delete" then
      input:delete()
    end
    if Key.ctrl() then
      if k == "y" then
        input:delete_line()
      end
    end
  end
  local function vertical()
    if k == "up" then
      if input:cursor_vertical_move('up') then
        emit_limit('up', 'input')
      end
    end
    if k == "down" then
      if input:cursor_vertical_move('down') then
        emit_limit('down', 'input')
      end
    end
    if Key.alt() then
      if k == "up" then
        swap_line('up')
      end
      if k == "down" then
        swap_line('down')
      end
    end
  end
  local function horizontal()
    if k == "left" and input:is_at_limit('left', 'line') then
      emit_limit('left', horizontal_limit_scope('left'))
    end
    if k == "right" and input:is_at_limit('right', 'line') then
      emit_limit('right', horizontal_limit_scope('right'))
    end
    if k == "left" then
      input:cursor_left()
    end
    if k == "right" then
      input:cursor_right()
    end

    if not Key.alt()
        and k == "home" then
      input:jump_home()
    end
    if not Key.alt()
        and k == "end" then
      input:jump_end()
    end
    if Key.alt()
        and k == "home" then
      input:jump_line_start()
    end
    if Key.alt()
        and k == "end" then
      input:jump_line_end()
    end
  end
  local function newline()
    if Key.shift() then
      if Key.is_enter(k) then
        input:line_feed()
      end
    end
  end
  local function modify()
    if Key.ctrl() then
      if k == 'd' then
        local line = input:get_current_line()
        input:insert_text_line(line)
      end
    end
  end
  local function copypaste()
    if Key.ctrl() then
      if k == "v" then
        paste()
      end
      if k == "c" or k == "insert" then
        copy()
      end
      if k == "x" then
        cut()
      end
    end
    if Key.shift() then
      if k == "insert" then
        paste()
      end
      if k == "delete" then
        cut()
      end
    end
  end
  local function selection()
    local en = not self.disable_selection
    if en and Key.shift() then
      input:hold_selection(false)
    end
    if not Key.shift() then
      input:release_selection()
    end
  end

  removers()
  vertical()
  horizontal()
  newline()
  if self.allow_modify then modify() end
  copypaste()
  selection()

  -- The widget's own submit/cancel flow (Decision 6 revised): plain Enter
  -- submits, plain Escape cancels — ordinary widget behaviour, out through
  -- callbacks. Shift+Enter is a newline (newline() above); Ctrl+Escape is not a
  -- cancel. Editor/console callers that must not run these consume the key
  -- upstream (editor) or set no callbacks (console no-op).
  if Key.is_enter(k) and not Key.shift() then
    self:submit_flow(keys_pressed)
  elseif k == 'escape' and not Key.ctrl() then
    self:cancel_flow(keys_pressed)
  end

  self:update_view()
end

--- @param t string
--- @param keys_pressed table?  read-only pressed-keys view
--- (doc/development/decisions/input.md, Decision 13)
-- Uniform textinput signature
-- (doc/development/decisions/input.md, Decision 9). Visibility is
-- decided by the internal hidden-check (shown -> edit; hidden ->
-- no-op). A shown widget always edits its live model state.
function UserInputController:textinput(t, keys_pressed)
  if not self.shown then
    if love.DEBUG then Log.debug('input: hidden no-op') end
    return
  end
  self:update_view()
  if self.model:has_error() then
    return
  end
  self.model:add_text(t)
  self:update_view()
end

--- @param k string
--- @param keys_pressed table?  read-only pressed-keys view
--- (doc/development/decisions/input.md, Decision 13)
function UserInputController:keyreleased(k, keys_pressed)
  if not self.shown then
    if love.DEBUG then Log.debug('input: hidden no-op') end
    return
  end
  local input = self.model
  self:update_view()

  if input:has_error() then
    if k == 'space' then
      input:clear_error()
    end
    return
  end

  local function selection()
    if Key.is_shift(k) then
      input:release_selection()
    end
  end

  selection()
  self:update_view()
end

---------------
--   mouse   --
---------------

--- @private
--- @param x integer
--- @param y integer
--- @return integer c
--- @return integer l
function UserInputController:_translate_to_input_grid(x, y)
  local cfg = self.model.cfg
  local h = cfg.view.h
  local fh = cfg.view.fh
  local fw = cfg.view.fw
  local line = math.floor((h - y) / fh)
  local a, b = math.modf((x / fw))
  local char = a + 1
  if b > .5 then char = char + 1 end
  return char, line
end

--- @private
--- @param x integer
--- @param y integer
--- @param btn integer
--- @param handler function
function UserInputController:_handle_mouse(x, y, btn, handler)
  if self.disable_selection then return end
  if btn == 1 then
    local im = self.model
    local n_lines = im:get_wrapped_text():get_content_length()
    local c, l = self:_translate_to_input_grid(x, y)
    if l < n_lines then
      handler(n_lines - l, c)
    end
  end
end

--- @param x integer
--- @param y integer
--- @param btn integer
--- @param touch boolean
--- @param presses number
function UserInputController:mousepressed(
    x, y, btn, touch, presses)
  if self.disable_selection then return end
  local im = self.model
  self:_handle_mouse(x, y, btn, function(l, c)
    im:mouse_click(l, c)
  end)
end

--- @param x integer
--- @param y integer
--- @param btn integer
--- @param touch boolean
--- @param presses number
function UserInputController:mousereleased(
    x, y, btn, touch, presses)
  if self.disable_selection then return end
  local im = self.model
  self:_handle_mouse(x, y, btn, function(l, c)
    im:mouse_release(l, c)
  end)
  im:release_selection()
end

--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param touch boolean
function UserInputController:mousemoved(x, y, dx, dy, touch)
  if self.disable_selection then return end
  local im = self.model
  self:_handle_mouse(x, y, 1, function(l, c)
    im:mouse_drag(l, c)
  end)
end

--- @param x integer
--- @param y integer
function UserInputController:wheelmoved(x, y)
  --- TODO
end

--- @param id userdata
--- @param x number
--- @param y number
--- @param dx number?
--- @param dy number?
--- @param pressure number?
function UserInputController:touchpressed(id, x, y,
                                          dx, dy, pressure)
  --- TODO
end

--- @param id userdata
--- @param x number
--- @param y number
--- @param dx number?
--- @param dy number?
--- @param pressure number?
function UserInputController:touchreleased(id, x, y,
                                           dx, dy, pressure)
  --- TODO
end

--- @param id userdata
--- @param x number
--- @param y number
--- @param dx number?
--- @param dy number?
--- @param pressure number?
function UserInputController:touchmoved(id, x, y,
                                        dx, dy, pressure)
  --- TODO
end
