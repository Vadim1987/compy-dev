local class = require('util.class')
require("util.key")
require("util.view")
require("util.string.string")
require("util.lua")

-- Stay-open defaults for the submit/cancel lifecycle
-- after_submit/after_cancel default to no-ops, so a widget
-- stays open unless a callback hides it. on_limit_ reached
-- defaults to a no-op so the navigation-boundary emit is an
-- unconditional call. Re-seeded (not wiped) on teardown (AC10).
-- before_submit/before_cancel are deliberately absent: their
-- return is READ as a veto, and an unset one must be
-- distinguishable from one that declines to veto
-- (doc/development/decisions/input.md, Decision 23).
-- run_callback already answers nil for an absent name, which is
-- no veto.
local function default_callbacks()
  return {
    on_limit_reached = noop,
    after_submit = noop,
    after_cancel = noop,
  }
end

--- @param model UserInputModel
--- @param disable_selection boolean?
--- @param allow_duplicate_line boolean?  editor-only today
local new = function(model, disable_selection,
                     allow_duplicate_line)
  return {
    model = model,
    disable_selection = disable_selection,
    allow_duplicate_line = allow_duplicate_line,
    -- is_shown() reads this, never love.state (owner ruling
    -- 2026-07-20).
    shown = false,
    -- For the project widget, compy.input.callbacks RESOLVES to
    -- this table for as long as this widget is the current one
    -- (owner ruling 2026-07-20, re-made 2026-08-27); console
    -- and editor set their own directly.
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

--- Give the highlighter ONE home: this widget's `callbacks`
--- slot, which is also what compy.input.callbacks resolves to.
--- The evaluator stops holding a copy and RESOLVES the slot
--- instead, so a direct `compy.input.callbacks.highlighter`
--- assignment and a show()/configure() key are the same write
--- by construction — rather than by a copy step every writing
--- path has to remember, which is the step that was missed
--- (doc/development/technical_debt/input.md,
--- "T-HL-TWO-HOMES").
---
--- Resolution, not a forwarding function, because the model
--- branches on the TRUTH of `ev.highlighter`: with no
--- highlighter set it must stay nil so the validation-colouring
--- fallback still runs (userInputModel.lua, `highlight`).
---
--- Call it only on a widget whose evaluator is its OWN. The
--- console's and editor's evaluators are shared and carry a
--- LANGUAGE highlighter of their own, which is not a project
--- callback and must not be resolved away.
function UserInputController:bind_highlighter()
  local ev = self.model.evaluator
  if not ev then return end
  local base = getmetatable(ev)
  local callbacks = self.callbacks
  setmetatable(ev, {
    __index = function(_, k)
      if k == 'highlighter' then
        return callbacks.highlighter
      end
      return base[k]
    end,
  })
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
--- doc/development/internals/user_input.md, "Cursor
--- manipulation and \"reset\""). Named apart from
--- set_cursor(Cursor) above — that simple function
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

--- Throw away the current draft, firing nothing. Deliberately
--- NOT `cancel_flow` (below): that is a project's Escape and
--- runs `before_cancel`/`after_cancel`, which a console debug
--- path must not trigger on a project's behalf. Its only
--- caller is `consoleController.lua`'s `terminal_test`.
function UserInputController:discard_draft()
  self.model:cancel()
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

-- Internal widget API, reached only through the compy.input.*
-- wrappers (consoleController). Free functions, not methods:
-- they are private helpers to show()/hide() below.

-- The callbacks a config table may carry. The lifecycle ones
-- (before_/after_submit, before_/after_cancel) are deliberately
-- absent: they are set through compy.input.callbacks, never
-- through show() or configure().
local CONFIG_CALLBACKS = {
  'validator', 'on_text_entered', 'on_limit_reached',
  'highlighter',
}

--- Everything the PROJECT owns: set-if-given, left alone when
--- absent, and identical in both entry points — which is what
--- stops show() and configure() drifting apart
--- (doc/development/decisions/input.md, Decision 35).
--- The user's content is deliberately not here; see
--- reset_content.
--- @param self UserInputController
--- @param cfg table
local configure_core = function(self, cfg)
  if cfg.prompt ~= nil then
    self.model.custom_label = cfg.prompt
  end
  for _, name in ipairs(CONFIG_CALLBACKS) do
    if cfg[name] ~= nil then
      self.callbacks[name] = cfg[name]
    end
  end
end

--- The content baseline, which only ACTIVATION sets: text given
--- is the content, text absent is an empty field (Decision 35,
--- statement 1). "Absent means empty" is the contract, not a
--- default value passed through: clear_input() also drops the
--- selection, the custom status and the history index, none of
--- which set_text('') would do.
--- @param self UserInputController
--- @param cfg table
local reset_content = function(self, cfg)
  if cfg.text == nil then
    self.model:clear_input()
  else
    self.model:set_text(cfg.text)
  end
end

--- The activation path: content baseline, then the
--- project-owned fields, then the cursor, then publish the
--- handle and render once. `text` and `cursor` are here and not
--- in configure_core because they are the USER's — activation
--- is the only call that may seat them
--- (doc/development/decisions/input.md, Decision 35).
--- See doc/development/internals/user_input.md,
--- "Cursor manipulation and reset".
--- @param self UserInputController
--- @param cfg table
local open_widget = function(self, cfg)
  reset_content(self, cfg)
  configure_core(self, cfg)
  if cfg.cursor ~= nil then
    self:set_cursor_pos(cfg.cursor[1], cfg.cursor[2])
  end
  -- Seated unconditionally, unlike the project-owned fields
  -- above: auto_hide describes THIS session, so a later bare
  -- show() must clear it rather than inherit it
  -- (doc/development/decisions/input.md, Decision 36).
  self.auto_hide = cfg.auto_hide
  -- love.state.user_input is the widget CONTRACT: its presence
  -- is the flag the draw loop (controller.lua) checks to paint
  -- V:draw() each frame, and it carries the { M, C, V } handle
  -- the legacy poll idiom reads. Drivers change but the flag
  -- persists (doc/development/internals/user_input.md, "Widget
  -- lifecycle").
  love.state.user_input = {
    M = self.model,
    C = self,
    V = self.view,
  }
  self.shown = true
  self:update_view()
end

--- Activate the widget. Over a widget that is already up this
--- is refused unless force=true, and a forced show is the SAME
--- path a first one takes — a full re-setup, not a narrower
--- second policy (doc/development/decisions/input.md,
--- Decision 35, statement 4).
--- @param config table?
function UserInputController:show(config)
  local cfg = config or {}
  -- doc/development/decisions/input.md, Decision 3
  -- (warn-don't-swallow): a plain show() over an active widget
  -- is suppressed; say so.
  if self.shown and not cfg.force then
    Log.warn('UserInputController:show ignored — widget already'
      .. ' active (pass force=true to override)')
    return
  end
  open_widget(self, cfg)
end

--- Deactivate without firing the cancel chain. Clearing
--- love.state.user_input is what "hides" the widget: the draw
--- loop (controller.lua) paints V:draw() only while the flag is
--- set, so nil-ing it stops the paint on the next frame.
--- A permanent surface (always_shown) declines.
function UserInputController:hide()
  if self.always then return end
  self.shown = false
  love.state.user_input = nil
end

--- Live-reconfigure an active session (compy.input.configure;
--- doc/development/internals/user_input.md,
--- "configure(config)"). It runs configure_core and nothing
--- else, so the project-owned fields are applied by the same
--- code show() uses. No filter table stands in front of it:
--- configure_core cannot see the user's content, which is the
--- boundary itself rather than something this call enforces
--- (doc/development/decisions/input.md, Decision 35).
--- @param cfg table
function UserInputController:configure(cfg)
  configure_core(self, cfg)
  self:update_view()
end

----------------------
--- submit / cancel ---
----------------------

-- Submit/cancel are the widget's OWN default behaviour
-- (doc/development/decisions/input.md, Decision 6): the widget
-- runs them on Enter/Escape as an ordinary consumer (never a
-- routing concern) and signals out through its callbacks.
-- before_/after_submit and before_/after_cancel are read off
-- self.callbacks — the same table a project populates via
-- compy.input.callbacks.

--- Run the project's validator, if it set one, and record its
--- errors on the model — which is what locks the session until
--- keypressed()'s has_error()/clear_error() releases it. No
--- validator accepts unconditionally.
--- @param model UserInputModel
--- @param validator function?
--- @param lines string[]
--- @return boolean accepted
local function validate(model, validator, lines)
  if not validator then return true end
  local ok, errors = validator(lines)
  if not ok then model:set_error(errors) end
  return ok
end

--- @param label string
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

--- Submit flow (doc/development/decisions/input.md, Decision
--- 6): the widget's own Enter behaviour. A truthy before_submit
--- VETOES; otherwise empty guard → validate → deliver (fires
--- on_text_entered) → after_submit. after_submit defaults to a
--- no-op, so the widget stays open unless a callback hides it.
---
--- The two deliveries differ by PAYLOAD, which is what tells
--- the callbacks apart (Decision 37): the concatenated text to
--- on_text_entered, whose name promises text, and the line
--- list to after_submit. The validator keeps the lines — it
--- runs per line, and LineValidators reports which one failed.
---
--- An auto_hide session hides LAST, so the project's own
--- after_submit still runs against a live widget (Decision 36).
--- The close sits here and nowhere else, which is what makes
--- every early return above suppress it without a rule of its
--- own — and why a callback that RAISES leaves the widget
--- standing: the raise unwinds to the route boundary
--- (controller.lua, with_canvas_and_errors) past this line,
--- exactly as it unwinds past a hand-written after_submit that
--- hides. That edge is ruled, not incidental (Decision 36).
function UserInputController:submit_flow()
  if run_callback(self, 'before_submit') then return end
  if self.model:get_text():is_empty() then return end
  local lines = self.model:get_text()
  local validator = self.callbacks.validator
  if not validate(self.model, validator, lines) then
    return
  end
  run_callback(self, 'on_text_entered', string.unlines(lines))
  run_callback(self, 'after_submit', lines)
  -- Read AFTER the callbacks, not captured before them: a
  -- callback that opens a follow-up prompt with
  -- show{force = true} re-seats this flag, and clearing it is
  -- how that prompt survives the close belonging to the submit
  -- still in progress. A follow-up that passes auto_hide ITSELF
  -- does not survive — documented at doc/input_api.md,
  -- "Asking one question".
  if self.auto_hide then self:hide() end
end

--- Cancel flow (Decision 6): the widget's own Escape behaviour.
--- A truthy before_cancel VETOES (skips the clear); otherwise
--- clear (hardwired) → after_cancel. after_cancel defaults to a
--- no-op — Escape clears but the widget stays open unless a
--- callback hides it.
function UserInputController:cancel_flow()
  if run_callback(self, 'before_cancel') then
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

--- Mark this widget as its host's permanent input surface —
--- the console line, the editor's input and search strips —
--- and return self, for inline construction. A project's widget
--- leaves shown=false and toggles it with show()/hide().
---
--- The name is enforced, not aspirational: hide() refuses on
--- such a widget. Shownness became a flag with this API
--- (pre-feature there was none: a widget was live iff
--- love.state.user_input was set), and a flag anything may
--- clear is a convention, not the guarantee the name claims.
--- @return UserInputController self
function UserInputController:always_shown()
  self.shown = true
  self.always = true
  return self
end

----------------
--  keyboard  --
----------------

--- LÖVE's own argument list, like every other consumer on the
--- chain (doc/development/decisions/input.md, Decision 26). The
--- tail is unread here and named anyway: this widget is where a
--- repeat-aware edit would land, and the position has to be the
--- right one when it does.
--- @param k string
--- @param sc string?    scancode
--- @param isr boolean?  key repeat
-- No return value: the old limit-flag return channel is retired
-- (Decision 5) — on_limit_reached is the sole notification
-- path now (see "emit_limit" below).
-- Its editing logic reads modifiers via Key.* (love.keyboard).
function UserInputController:keypressed(k, sc, isr)
  if not self.shown then
    if love.DEBUG then Log.debug('input: hidden no-op') end
    return
  end
  -- Defensive render-on-entry: guarantees the view catches up
  -- to the model even if a prior branch returned without
  -- re-rendering. Mutating branches below re-render at their
  -- end, so this is belt-and-suspenders, not the primary
  -- update.
  self:update_view()
  -- _G.web: web/love.js build flag. On web, space may not emit
  -- textinput, so synthesise it here.
  if _G.web and k == 'space' then
    self:textinput(' ')
  end
  local input = self.model

  -- Navigation-boundary output
  -- (doc/development/decisions/input.md, Decision 5): the
  -- widget signals a hit limit ONLY through on_limit_reached —
  -- the keypressed return value no longer carries a limit flag
  -- (retired; console reads history via its own
  -- on_limit_reached callback).
  local function emit_limit(dir, scope)
    local cb = self.callbacks.on_limit_reached
    if cb then cb(dir, scope) end
  end

  local function horizontal_limit_scope(dir)
    if input:get_n_text_lines() == 1 then return 'input' end
    if input:is_at_limit(dir, 'input') then return 'input' end
    return 'line'
  end

  -- (combo serialisation lives in controller.lua; this handler
  -- only sees the raw key.)
  -- doc/development/internals/user_input.md, "Error state":
  -- locked-on-reject unlocks on Enter/Space/arrows.
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
  if self.allow_duplicate_line then modify() end
  copypaste()
  selection()

  -- The widget's own submit/cancel flow (Decision 6): plain
  -- Enter submits, plain Escape cancels — ordinary widget
  -- behaviour, out through callbacks. Shift+Enter is a newline
  -- (newline() above); Ctrl+Escape is not a cancel.
  -- Editor/console callers that must not run these consume the
  -- key upstream (editor) or set no callbacks (console no-op).
  if Key.is_enter(k) and not Key.shift() then
    self:submit_flow()
  elseif k == 'escape' and not Key.ctrl() then
    self:cancel_flow()
  end

  self:update_view()
end

--- @param t string
-- Visibility is decided by the internal hidden-check (shown ->
-- edit; hidden -> no-op). A shown widget always edits its live
-- model state.
function UserInputController:textinput(t)
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
--- @param sc string?    scancode; LÖVE's second argument,
---                    unread
function UserInputController:keyreleased(k, sc)
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

-- The derived clicks are the framework's synthesis, for
-- projects to bind; text editing has no use for them. Present
-- because the chain calls every channel on its terminal tier.
function UserInputController:singleclick()
end

function UserInputController:doubleclick()
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
