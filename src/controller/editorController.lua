require("model.interpreter.eval.evaluator")
require("controller.userInputController")
require("controller.searchController")
require("view.input.customStatus")

local class = require('util.class')

--- @param M EditorModel
local function new(M)
  return {
    input = UserInputController(M.input, nil, false),
    model = M,
    search = SearchController(
      M.search,
      UserInputController(M.search.input, nil, false)
    ),
    view = nil,
    mode = 'edit',
  }
end

--- @alias EditorMode
--- | 'edit' --- default
--- | 'reorder'
--- | 'search'

--- @class EditorController
--- @field model EditorModel
--- @field input UserInputController
--- @field search SearchController
--- @field view EditorView?
--- @field state EditorState?
--- @field mode EditorMode
---
--- @field open function
--- @field get_state function
--- @field set_state function
--- @field save_state function
--- @field restore_state function
--- @field get_clipboard function
--- @field set_clipboard function
--- @field set_mode function
--- @field get_mode function
--- @field close function
--- @field get_active_buffer function
--- @field get_input function
--- @field update_status function
--- @field textinput function
--- @field keypressed function
EditorController = class.create(new)


--- @param name string
--- @param content string[]?
--- @param save function
function EditorController:open(name, content, save)
  local w = self.model.cfg.view.drawableChars
  local is_lua = string.match(name, '.lua$')
  local ch, hl, pp
  if is_lua then
    self.input:set_eval(LuaEditorEval)
    local luaEval = LuaEval()
    local parser = luaEval.parser
    if not parser then return end
    hl = parser.highlighter
    --- @param t string[]
    --- @param single boolean
    ch = function(t, single)
      return parser.chunker(t, w, single)
    end
    pp = function(t)
      return parser.pprint(t, w)
    end
  else
    self.input:set_eval(TextEval)
  end

  local b = BufferModel(name, content, save, ch, hl, pp)
  self.model.buffer = b
  self.view.buffer:open(b)
  self:update_status()
  self:set_state()
end

--- @param m EditorMode
--- @return boolean
local function is_normal(m)
  return m == 'edit'
end

--- @param mode EditorMode
function EditorController:set_mode(mode)
  local set_reorg = function()
    self:save_state()
  end
  local init_search = function()
    self:save_state()
    local buf = self:get_active_buffer()
    local ds = buf.semantic.definitions
    self.search:load(ds)
  end

  local current = self.mode
  Log.info('-- ' .. string.upper(mode) .. ' --')
  if is_normal(current) then
    if mode == 'reorder' then
      set_reorg()
    end
    if mode == 'search' then
      init_search()
    end
    self.mode = mode
  else
    --- currently in a special mode, only return is allowed
    if is_normal(mode) then
      self.mode = mode
    end
  end
  self:update_status()
end

--- @return EditorMode
function EditorController:get_mode()
  return self.mode
end

--- @param clipboard string
function EditorController:set_clipboard(clipboard)
  self.state.clipboard = clipboard
end

--- @return string
function EditorController:get_clipboard()
  return self.state.clipboard
end

--- @param clipboard string?
function EditorController:set_state(clipboard)
  local buf_view_state = self.view.buffer:get_state()
  local buf = self:get_active_buffer()
  if self.state then
    self.state.buffer = buf_view_state
    self.state.moved = buf:get_selection()
    if clipboard then self:set_clipboard(clipboard) end
  else
    self.state = {
      buffer = buf_view_state,
      clipboard = clipboard,
      moved = buf:get_selection()
    }
  end
end

--- @return EditorState
function EditorController:get_state()
  return self.state
end

function EditorController:save_state()
  self:set_state(love.system.getClipboardText())
end

--- @param state EditorState?
function EditorController:restore_state(state)
  if state then
    local buf = self:get_active_buffer()
    local sel = state.buffer.selection
    local off = state.buffer.offset
    buf:set_selection(sel)
    self.view.buffer:scroll_to(off)
    local clip = state.clipboard
    if string.is_non_empty_string(clip) then
      love.system.setClipboardText(clip or '')
    end
  end
end

--- @return string name
--- @return Dequeue content
function EditorController:close()
  local buf = self:get_active_buffer()
  self.input:clear()
  local content = buf:get_text_content()
  return buf.name, content
end

--- @return BufferModel
function EditorController:get_active_buffer()
  return self.model.buffer
end

--- @private
--- @param sel integer
--- @return CustomStatus
function EditorController:_generate_status(sel)
  --- @type BufferModel
  local buffer = self:get_active_buffer()
  local len = buffer:get_content_length() + 1
  local bufview = self.view.buffer
  local more = bufview.content:get_more()
  local cs
  local m = self.mode
  if bufview.content_type == 'plain' then
    cs = CustomStatus(bufview.content_type, len, more, sel, m)
  end
  if bufview.content_type == 'lua' then
    local range = bufview.content:get_block_app_pos(sel)
    cs = CustomStatus(
      bufview.content_type, len, more, sel, m, range)
  end

  return cs
end

function EditorController:update_status()
  local sel = self:get_active_buffer():get_selection()
  local cs = self:_generate_status(sel)
  self.input:set_custom_status(cs)
end

--- @param t string
function EditorController:textinput(t)
  if self.mode == 'edit' then
    local input = self.model.input
    if input:has_error() then
      input:clear_error()
    else
      if Key.ctrl() and Key.shift() then
        return
      end
      self.input:textinput(t)
    end
  elseif self.mode == 'search' then
    self.search:textinput(t)
  end
end

--- @return InputDTO
function EditorController:get_input()
  return self.input:get_input()
end

--- @param buf BufferModel
function EditorController:save(buf)
  local ok, err = buf:save()
  if not ok then Log.error("can't save: ", err) end
end

---------------------------
---  keyboard handlers  ---
---------------------------

--- @private
--- @param go fun(nt: string[]|Block[])
function EditorController:_handle_submit(go)
  local inter = self.input
  local raw = inter:get_text()

  local buf = self:get_active_buffer()
  local ct = buf.content_type
  if ct == 'lua' then
    if not string.is_non_empty_string_array(raw) then
      local sel = buf:get_selection()
      local block = buf:get_content():get(sel)
      if not block then return end
      local ln = block.pos.start
      if ln then go({ Empty(ln) }) end
    else
      local pretty = buf.printer(raw)
      if pretty then
        inter:set_text(pretty)
      else
        --- fallback to original in case of unparse-able input
        pretty = raw
      end
      local ok, res = inter:evaluate()
      local _, chunks = buf.chunker(pretty, true)
      if ok then
        go(chunks)
      else
        local eval_err = res
        if eval_err then
          inter:set_error(eval_err)
        end
      end
    end
  else
    go(raw)
  end
end

--- @private
--- @param dir VerticalDir
--- @param by integer?
--- @param warp boolean?
--- @param moved integer?
function EditorController:_move_sel(dir, by, warp, moved)
  local buf = self:get_active_buffer()
  if self.input:has_error() then return end

  --- @type boolean
  local mv = (function()
    if moved then return true end
    return false
  end)()
  local m = buf:move_selection(dir, by, warp, mv)
  if m then
    if mv then self.view:refresh(moved) end
    self.view.buffer:follow_selection()
    self:update_status()
  end
end

--- @private
--- @param dir VerticalDir
--- @param warp boolean?
--- @param by integer?
function EditorController:_scroll(dir, warp, by)
  self.view.buffer:scroll(dir, by, warp)
  self:update_status()
end

--- @private
--- @param save boolean
function EditorController:_reorg(save)
  local moved = self.state.moved
  if not moved then return end

  local buf = self:get_active_buffer()
  if save then
    local target = buf:get_selection()
    buf:move(moved, target)
    buf:rechunk()
    self:save(buf)
  else
    buf:set_selection(moved)
    self:restore_state(self:get_state())
  end
  self.view:refresh()

  self:set_mode('edit')
end

--- @private
--- @param k string
function EditorController:_reorg_mode_keys(k)
  if k == 'escape' then
    self:_reorg(false)
  end
  if Key.is_enter(k) then
    self:_reorg(true)
  end

  local function navigate()
    -- move selection
    if k == "up" then
      self:_move_sel('up', nil, nil, self.state.moved)
    end
    if k == "down" then
      self:_move_sel('down', nil, nil, self.state.moved)
    end
    if k == "home" then
      self:_move_sel('up', nil, true, self.state.moved)
    end
    if k == "end" then
      self:_move_sel('down', nil, true, self.state.moved)
    end
    -- scroll
    if Key.shift()
        and k == "pageup" then
      self:_scroll('up', false, 1)
    end
    if Key.shift()
        and k == "pagedown" then
      self:_scroll('down', false, 1)
    end
  end

  navigate()
end

function EditorController:_search_mode_keys(k)
  if k == 'escape' then
    self:set_mode('edit')
    return
  end

  local jump = self.search:keypressed(k)
  if jump then
    self.view.buffer:scroll_to_line(jump - 1)
    self:set_mode('edit')
  end
end

--- @private
--- @param k string
function EditorController:_normal_mode_keys(k)
  local input          = self.input
  local is_empty       = input:is_empty()
  local at_limit_start = input:is_at_limit('up')
  local at_limit_end   = input:is_at_limit('down')
  local passthrough    = true
  local block_input    = function() passthrough = false end
  --- @type BufferModel
  local buf            = self:get_active_buffer()

  local function newline()
    if not Key.ctrl() and Key.shift() and Key.is_enter(k) then
      buf:insert_newline()
      self.view:refresh()
      block_input()
    end
  end

  local function delete_block()
    buf:delete_selected_text()
    self:save(buf)
    self.view:refresh()
  end

  local function paste()
    local t = love.system.getClipboardText()
    input:add_text(t)
  end
  local function copy()
    local t = string.unlines(buf:get_selected_text())
    love.system.setClipboardText(t)
    self:set_clipboard(t)
    block_input()
  end
  local function cut()
    copy()
    delete_block()
  end

  local function copycut()
    if Key.ctrl() then
      if k == "c" or k == "insert" then
        copy()
        block_input()
      end
      if k == "x" then
        cut()
        block_input()
      end
    end
    if Key.shift() then
      if k == "delete" then
        cut()
        block_input()
      end
    end
  end
  local function paste_k()
    if (Key.ctrl() and k == "v")
        or (Key.shift() and k == "insert")
    then
      paste()
      block_input()
    end
  end

  if is_empty then
    newline()
    copycut()
  end

  paste_k()

  --- @param add boolean?
  local function load_selection(add)
    local t = buf:get_selected_text()
    if string.is_non_empty(t) then
      buf:set_loaded()
    else
      buf:clear_loaded()
    end
    if add then
      local c = input:get_cursor_info().cursor
      input:add_text(t)
      input:set_cursor(c)
    else
      input:set_text(t)
      input:jump_home()
    end
  end


  --- handlers
  local function submit()
    if not Key.ctrl() and not Key.shift() and Key.is_enter(k) then
      local bufv = self.view.buffer
      local function go(newtext)
        if bufv:is_selection_visible() then
          if buf:loaded_is_sel(true) then
            local _, n = buf:replace_selected_text(newtext)
            buf:clear_loaded()
            self:save(buf)
            input:clear()
            self.view:refresh()
            self:_move_sel('down', n)
            load_selection()
            self:update_status()
          else
            buf:select_loaded()
            bufv:follow_selection()
          end
        else
          bufv:follow_selection()
        end
      end

      self:_handle_submit(go)
    end
  end
  local function load()
    if not Key.ctrl() and
        not Key.shift()
        and k == "escape" then
      load_selection()
    end
    if not Key.ctrl() and
        Key.shift() and
        k == "escape" then
      load_selection(true)
    end
  end
  local function delete()
    if Key.ctrl() then
      if k == "delete"
          or (k == "y" and is_empty) then
        delete_block()
        block_input()
      end
    end
  end
  local function navigate()
    -- move selection
    if Key.ctrl() then
      if k == "up" then
        self:_move_sel('up')
        block_input()
      end
      if k == "down" then
        self:_move_sel('down')
        block_input()
      end
      if k == "home" then
        self:_move_sel('up', nil, true)
      end
      if k == "end" then
        self:_move_sel('down', nil, true)
      end
    else
      if k == "up" and at_limit_start then
        self:_move_sel('up')
        block_input()
      end
      if k == "down" and at_limit_end then
        self:_move_sel('down')
        block_input()
      end
    end

    -- scroll
    if not Key.shift()
        and k == "pageup" then
      self:_scroll('up', Key.ctrl())
    end
    if not Key.shift()
        and k == "pagedown" then
      self:_scroll('down', Key.ctrl())
    end
    if Key.shift()
        and k == "pageup" then
      self:_scroll('up', false, 1)
    end
    if Key.shift()
        and k == "pagedown" then
      self:_scroll('down', false, 1)
    end
  end
  local function clear()
    if Key.ctrl() and k == "w" then
      buf:clear_loaded()
      input:clear()
    end
  end

  submit()
  load()
  delete()
  navigate()
  clear()

  if passthrough then
    input:keypressed(k)
  end
end

--- @param k string
function EditorController:keypressed(k)
  local mode = self.mode

  if Key.ctrl() then
    if k == "m" then
      self:set_mode('reorder')
    end
    if k == "f" then
      self:set_mode('search')
    end
  end

  if mode == 'reorder' then
    self:_reorg_mode_keys(k)
  elseif mode == 'search' then
    self:_search_mode_keys(k)
  else
    self:_normal_mode_keys(k)
  end

  if love.debug then
    local buf = self:get_active_buffer()
    local bufview = self.view.buffer
    if k == 'f5' then
      if Key.ctrl() then buf:rechunk() end
      bufview:refresh()
    end
  end
end
