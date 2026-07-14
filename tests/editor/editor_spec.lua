--- @diagnostic disable: invisible
require("model.editor.editorModel")
require("controller.editorController")
require("view.editor.editorView")
require("view.editor.visibleContent")

local mock, TU

describe('Editor #editor', function()
  setup(function()
    mock = require("tests.mock")
    TU = require('tests.testutil')

    local love = {
      state = {
        --- @type AppState
        app_state = 'ready',
      },
    }
    mock.mock_love(love)
  end)

  local trtl =
  'Turtle graphics game inspired the LOGO family of languages.'

  local turtle_doc = {
    '',
    trtl,
    '',
  }

  --- @param cfg Config
  --- @return EditorController
  --- @return function press
  --- @return EditorView view
  local function wire(cfg)
    local model = EditorModel(cfg)
    local controller = EditorController(model)
    -- this hooks itself back into the controller
    EditorView(cfg.view, controller)
    local function press(...)
      controller:keypressed(...)
    end

    return controller, press, controller.view
  end

  local print_result = "print(sierpinski(4))"
  local sierpinski = {
    "function sierpinski(depth)",
    "  lines = { '*' }",
    "  for e = 2, depth + 1 do",
    "    sp, tmp = string.rep(' ', 2 ^ (e - 2))",
    "    tmp = {}",
    "    for idx, line in ipairs(lines) do",
    "      tmp[idx] = sp .. line .. sp",
    "      tmp[idx + #lines] = line .. ' ' .. line",
    "    end",
    "    lines = tmp",
    "  end",
    [[  return table.concat(lines, '\n')]],
    "end",
    "",
    print_result,
  }

  describe('opens', function()
    it('no wrap needed', function()
      local w = 80
      local controller = wire(TU.mock_view_cfg(w))

      local save = TU.get_save_function(turtle_doc)
      controller:open('turtle', turtle_doc, save)

      local buffer = controller:get_active_buffer()
      local bc = buffer:get_content()

      assert.same(turtle_doc, bc)
      assert.same(#turtle_doc, buffer:get_content_length())

      local sel = buffer:get_selection()
      local sel_t = buffer:get_selected_text()
      --- files open at the first line
      assert.same(1, sel)
      assert.same(turtle_doc[1], sel_t)
    end)
  end)

  describe('plaintext works', function()
    describe('with wrap', function()
      local w = 16
      love.state.app_state = 'editor'

      local controller, press = wire(TU.mock_view_cfg(w))

      local save = TU.get_save_function(turtle_doc)

      controller:open('turtle', turtle_doc, save)

      local buffer = controller:get_active_buffer()
      local start_sel = #turtle_doc

      it('opens', function()
        local bc = buffer:get_content()

        assert.same(turtle_doc, bc)
        assert.same(#turtle_doc, buffer:get_content_length())

        local sel = buffer:get_selection()
        local sel_t = buffer:get_selected_text()
        --- files open at the first line
        assert.same(1, sel)
        assert.same(turtle_doc[1], sel_t)
      end)

      it('interacts', function()
        --- files open at the top; walk to the end first,
        --- as these interactions historically assume it
        for _ = 1, start_sel - 1 do
          mock.keystroke('down', press)
        end
        --- select middle line
        mock.keystroke('up', press)
        assert.same(start_sel - 1, buffer:get_selection())
        assert.same(turtle_doc[2], buffer:get_selected_text())
        --- load it
        local input = function()
          return controller.input:get_text():items()
        end
        mock.keystroke('return', press)
        assert.same({ turtle_doc[2] }, input())
        --- arrows stay in the input while editing
        mock.keystroke('end', press)
        mock.keystroke('down', press)
        assert.same(start_sel - 1, buffer:get_selection())
        --- drop the edit, walk to the trailing empty
        mock.keystroke('S-escape', press)
        assert.same({ '' }, input())
        mock.keystroke('down', press)
        assert.same(start_sel, buffer:get_selection())
        --- compose text (inserted before the empty)
        controller:textinput('-')
        controller:textinput('-')
        controller:textinput(' ')
        controller:textinput('t')
        controller:textinput('e')
        controller:textinput('s')
        controller:textinput('t')
        assert.same({ '-- test' }, input())
        --- replace line with input content
        mock.keystroke('return', press)
        local new = {
          '',
          trtl,
          '-- test',
          ''
        }
        assert.same(new, buffer:get_text_content())
        --- input clears
        assert.same({ '' }, input())
        --- highlight moves down
        assert.same(start_sel + 1, buffer:get_selection())

        mock.keystroke('up', press)
        assert.same(start_sel, buffer:get_selection())
        --- compose over it, then discard and reopen
        controller:textinput('i')
        controller:textinput('n')
        controller:textinput('s')
        controller:textinput('e')
        controller:textinput('r')
        controller:textinput('t')
        assert.same({ 'insert' }, input())
        mock.keystroke('S-escape', press)
        mock.keystroke('return', press)
        assert.same({ '-- test' }, input())
      end)
    end)


    describe('with scroll', function()
      local l = 6

      local controller, _, view = wire(TU.mock_view_cfg(80, l))
      local model = controller.model

      local save = TU.get_save_function(sierpinski)
      --- use it as plaintext for this test
      controller:open('sierpinski.txt', sierpinski, save)
      local buf = controller:get_active_buffer()
      local bv = view:open(buf)

      local visible = bv.content
      local scroll = bv.SCROLL_BY

      --- files open at the top now; these specs assume
      --- the historical EOF position, so walk down first
      for _ = 1, #sierpinski do
        controller:keypressed('down')
      end

      local off = #sierpinski - l + 1
      bv:scroll_to(off)
      local start_range = Range(off + 1, #sierpinski + 1)

      local function peek(dir)
        mock.keystroke('C-M-' .. dir, function(kk)
          controller:keypressed(kk)
        end)
      end
      it('loads', function()
        --- selection is at EOF, view at the historical offset
        assert.same(#sierpinski + 1, buf:get_selection())
        assert.same(off, bv:get_offset())
        assert.same(start_range, visible.range)
      end)
      it('follows the active line', function()
        --- walk the line up out of the viewport
        for _ = 1, l + 2 do
          buf:move_line('up')
        end
        local al = buf:get_active_line()
        assert.is_true(al < visible.range.start)
        bv:follow_line()
        assert.is_true(visible.range:inc(al))
        --- and back down below it
        for _ = 1, l + 4 do
          buf:move_line('down')
        end
        bv:follow_line()
        assert.is_true(
          visible.range:inc(buf:get_active_line()))
        --- restore the historical position for the
        --- describes that follow
        buf:move_selection('down', nil, true)
        bv:scroll_to(off)
      end)
      local base = Range(1, l)
      it('scrolls up', function()
        peek('pageup')
        assert.same(start_range:translate(-scroll), visible.range)
        peek('pageup')
        assert.same(start_range:translate(-scroll * 2), visible.range)
        peek('pageup')
        assert.same(start_range:translate(-scroll * 3), visible.range)
        peek('pageup')
      end)
      it('tops out', function()
        assert.same(base, visible.range)
      end)
      it('scrolls down', function()
        peek('pagedown')
        assert.same(base:translate(scroll), visible.range)
        peek('pagedown')
        assert.same(base:translate(scroll * 2), visible.range)
        peek('pagedown')
        assert.same(base:translate(scroll * 3), visible.range)
        peek('pagedown')
        assert.same(base:translate(scroll * 4), visible.range)
        peek('pagedown')
      end)
      it('bottoms out', function()
        local limit = #sierpinski + visible.overscroll
        -- assert.same(Range(limit - l + 2, limit), visible.range)
      end)
    end)

    describe('with scroll and wrap', function()
      local l = 6

      local controller, _, view = wire(TU.mock_view_cfg(27, l))

      local save = TU.get_save_function(sierpinski)
      controller:open('sierpinski.txt', sierpinski, save)

      local function press(...)
        controller:keypressed(...)
      end

      local buffer = controller:get_active_buffer()
      --- @type BufferView
      local bv = view:open(buffer)
      -- bv:open(buffer)

      local visible = bv.content
      local scroll = bv.SCROLL_BY

      --- files open at the top now; these specs assume
      --- the historical EOF position, so walk down first
      for _ = 1, #sierpinski do
        press('down')
      end

      local clen = visible:get_content_length()
      local off = clen - l
      bv:scroll_to(off)
      local start_range = Range(off + 1, clen)
      it('loads', function()
        --- selection is at EOF, view at the historical offset
        assert.same(#sierpinski + 1, buffer:get_selection())
        assert.same(off, bv:get_offset())
        assert.same(start_range, visible.range)
      end)
      local base = Range(1, l)
      describe('scrolls', function()
        it('scrolls up', function()
          mock.keystroke('C-M-pageup', press)
          assert.same(start_range:translate(-scroll), visible.range)
          mock.keystroke('C-M-pageup', press)
          assert.same(start_range:translate(-scroll * 2), visible.range)
          mock.keystroke('C-M-pageup', press)
          assert.same(start_range:translate(-scroll * 3), visible.range)
          mock.keystroke('C-M-pageup', press)
          assert.same(start_range:translate(-scroll * 4), visible.range)
        end)
        it('tops out', function()
          mock.keystroke('C-M-pageup', press)
          assert.same(base, visible.range)
        end)
        it('scrolls down', function()
          mock.keystroke('C-M-pagedown', press)
          assert.same(base:translate(scroll), visible.range)
          mock.keystroke('C-M-pagedown', press)
          assert.same(base:translate(scroll * 2), visible.range)
          mock.keystroke('C-M-pagedown', press)
          assert.same(base:translate(scroll * 3), visible.range)
          mock.keystroke('C-M-pagedown', press)
          assert.same(base:translate(scroll * 4), visible.range)
          mock.keystroke('C-M-pagedown', press)
          assert.same(base:translate(scroll * 5), visible.range)
        end)
        it('bottoms out', function()
          mock.keystroke('C-M-pagedown', press)
          mock.keystroke('C-M-pagedown', press)
          mock.keystroke('C-M-pagedown', press)
          local limit = clen + visible.overscroll
          assert.same(Range(limit - l + 1, limit), visible.range)
        end)

        describe('moving the selection affects scrolling', function()
          --- the walk left the selection at EOF
          assert.same(#sierpinski + 1, buffer:get_selection())

          local function line_visible()
            local al = buffer:get_active_line()
            local wl = visible.wrap_forward[al]
            if not wl then return false end
            for _, v in ipairs(wl) do
              if visible.range:inc(v) then return true end
            end
            return false
          end

          it('from below', function()
            --- scroll away, then a line move pulls it back
            mock.keystroke('C-M-pageup', press)
            mock.keystroke('up', press)
            assert.same(#sierpinski, buffer:get_selection())
            assert.is_true(line_visible())
          end)
          it('to above', function()
            --- walk a screenful up; the line stays in view
            for _ = 1, l do
              mock.keystroke('up', press)
              assert.is_true(line_visible())
            end
          end)
          it('tops out', function()
            for _ = 1, clen do
              mock.keystroke('up', press)
            end
            assert.same(1, buffer:get_selection())
            assert.same(1, buffer:get_active_line())
            assert.same(1, visible.range.start)
          end)
          it('from above', function()
            --- scroll away downwards, a line move follows
            mock.keystroke('C-M-pagedown', press)
            mock.keystroke('C-M-pagedown', press)
            mock.keystroke('down', press)
            assert.same(2, buffer:get_selection())
            assert.is_true(line_visible())
          end)
          it('to below', function()
            for _ = 1, l do
              mock.keystroke('down', press)
              assert.is_true(line_visible())
            end
          end)
          it('bottoms out', function()
            for _ = 1, clen do
              mock.keystroke('down', press)
            end
            --- capped at the phantom line past the end
            local cap = buffer:get_selection()
            mock.keystroke('down', press)
            assert.same(cap, buffer:get_selection())
          end)
        end)
      end)

      describe('peek and page moves', function()
        it('peek scrolls, the selection stays', function()
          mock.keystroke('C-end', press)
          local sel = buffer:get_selection()
          local r0 = visible.range.start
          mock.keystroke('C-M-pageup', press)
          assert.same(sel, buffer:get_selection())
          assert.is_true(visible.range.start < r0)
          mock.keystroke('C-M-up', press)
          assert.same(sel, buffer:get_selection())
        end)
        it('typing after a peek returns the view', function()
          controller:textinput('x')
          local al = buffer:get_active_line()
          local wl = visible.wrap_forward[al]
          local seen = false
          for _, v in ipairs(wl) do
            if visible.range:inc(v) then seen = true end
          end
          assert.is_true(seen)
          mock.keystroke('S-escape', press)
        end)
        it('a held chord glyph is dropped', function()
          mock.keystroke('C-M-down', press, true)
          controller:textinput('q')
          assert.same({ '' }, controller.input:get_text())
          mock.release_keys()
        end)
        it('bare pages move the active line', function()
          mock.keystroke('C-home', press)
          assert.same(1, buffer:get_active_line())
          mock.keystroke('pagedown', press)
          assert.same(1 + l, buffer:get_active_line())
          assert.is_true(bv:is_selection_visible())
          mock.keystroke('pageup', press)
          assert.same(1, buffer:get_active_line())
          --- restore the state the describes below assume
          mock.keystroke('C-end', press)
          mock.keystroke('down', press)
        end)
      end)

      describe('jumps', function()
        local sel = table.clone(buffer:get_selection())
        it('to top', function()
          mock.keystroke('C-pageup', press)
          --- scrolls to top
          assert.same(base, visible.range)
          --- and selection is unaffected
          assert.same(sel, buffer:get_selection())
        end)
        it('to bottom', function()
          -- mock.keystroke('C-pagedown', press)
          --- scrolls to bottom
          --- TODO
          -- assert.same(start_range, visible.range)
          --- and selection is unaffected
          assert.same(sel, buffer:get_selection())
        end)
      end)
      describe('warps selection', function()
        mock.keystroke('up', press)
        local sel = table.clone(buffer:get_selection())
        it('to bottom', function()
          mock.keystroke('C-end', press)
          --- warps to bottom, selection in view
          assert.same(#sierpinski + 1, buffer:get_selection())
          assert.is_true(bv:is_selection_visible())
          -- assert.is_not.same(sel, buffer:get_selection())
        end)
        it('to top', function()
          mock.keystroke('C-home', press)
          --- warps to top
          assert.same(base, visible.range)
          assert.is_not.same(sel, buffer:get_selection())
        end)
      end)
      describe('input', function()
        local inter = controller.input
        it('loads', function()
          local selected = buffer:get_selected_text()
          mock.keystroke('return', press)
          assert.same(inter:get_text(), { selected })
        end)
        it("doesn't clear on move", function()
          --- ctrl-moving the selection keeps the input
          local loaded = inter:get_text()
          mock.keystroke('C-up', press)
          assert.same(loaded, inter:get_text())
        end)
        it('discards', function()
          --- Shift+Esc drops the edit and returns to nav
          mock.keystroke('S-escape', press)
          assert.same({ '' }, inter:get_text())
        end)
      end)
    end)
  end)
  --- end plaintext

  describe('structured (lua) works', function()
    it('moves the block with Alt+arrows', function()
      local controller, press = wire(TU.mock_view_cfg())
      local save, savefile = TU.get_save_function(sierpinski)
      controller:open('sierpinski.lua', sierpinski, save)
      local buffer = controller:get_active_buffer()
      local first = buffer:get_selected_text()

      mock.keystroke('M-down', press)
      --- the block moved down, selection follows it
      assert.same(2, buffer:get_selection())
      assert.same(first, buffer:get_selected_text())
      --- and the swap is written through
      assert.same('', string.lines(savefile())[1])

      mock.keystroke('M-up', press)
      assert.same(1, buffer:get_selection())
      assert.same(first, buffer:get_selected_text())
      --- capped at the edge
      mock.keystroke('M-up', press)
      assert.same(1, buffer:get_selection())
    end)

    it('changing single line', function()
      local controller, press = wire(TU.mock_view_cfg())
      local save, savefile = TU.get_save_function(sierpinski)

      controller:open('sierpinski.lua', sierpinski, save)

      local input = controller.input
      local buffer = controller:get_active_buffer()
      local cont = buffer:get_content()


      assert.same('lua', buffer.content_type)
      assert.same('block', cont:type())
      assert.same(4, buffer:get_content_length())
      local modified = table.clone(sierpinski)
      local new_print = 'print(sierpinski(3))'
      mock.keystroke('C-down', press)
      mock.keystroke('C-down', press)
      assert.same(3, buffer:get_selection())
      assert.same({ print_result }, buffer:get_selected_text())
      mock.keystroke('return', press)
      input:clear()
      input:add_text(new_print)
      mock.keystroke('return', press)
      assert.same(4, buffer:get_selection())
      local after = savefile()
      modified[#modified] = new_print
      modified[#modified + 1] = ''
      assert.same(string.unlines(modified), after)
    end)

    describe('with blocks:', function()
      require("tests.helpers.codesnippets")
      require("tests.helpers.editor_session")
      local src = snippets_to_code
      local fmt = string.format

      local controller, press, save, savefile, session

      before_each(function()
        controller, press = wire(TU.mock_view_cfg())
        save, savefile = TU.get_save_function({})
        session = EditorSession(controller, press, save, mock)
      end)

      describe("replacement with", function()
        it('single normal block', function()
          local f_orig = mock_func_snippet("orig")
          local f_modified = mock_func_snippet("modified")
          local f_untouched = mock_func_snippet("untouched")

          local src_orig = src(f_orig, '', f_untouched)
          local src_exp = src(f_modified, '', f_untouched, '')

          local input, buffer = session:open(src_orig, 3)
          session:select_and_open_block(1, f_orig)
          session:submit(f_modified)

          assert.is_true(input:is_empty(), "input cleared")
          assert.same(2, buffer.selection, "selection moved")
          assert.same({}, buffer:get_selected_text(),
                      "next (empty) block is selected")

          session:select_block(1)
          assert.same(string.lines(f_modified),
                      buffer:get_selected_text(),
                      "selection replaced with modified block")
          assert.same(string.lines(src_exp),
                      buffer:get_text_content(),
                      "buffer contains expected altered content")
          assert.same(src_exp, savefile(),
                      "saved content has altered block")
        end)

        it('multiple normal blocks', function()
          local f_orig = mock_func_snippet("orig")
          local f1 = mock_func_snippet("f1")
          local f2 = mock_func_snippet("f2")
          local new_code = src(f1, f2)

          local input, buffer = session:open(f_orig, 1)
          session:select_and_open_block(1, f_orig)
          session:submit(new_code)

          assert.is_true(input:is_empty(), "input cleared")
          assert.same(4, buffer.selection, "selection moved")
          assert.same({}, buffer:get_selected_text(),
                      "next (empty) block is selected")

          session:select_block(1)
          assert.same( string.lines(f1),
                       buffer:get_selected_text(),
                       "first block injected first")
          session:select_block(2)
          assert.same({}, buffer:get_selected_text(),
                      "empty line injected after first")
          session:select_block(3)
          assert.same( string.lines(f2),
                       buffer:get_selected_text(),
                       "second block injected second")
          assert.same(src(f1,'',f2,''), savefile(),
                      "old block replaced in saved content")

        end)

        it('oversized block is rejected', function()
          local f_simple = mock_func_snippet("simple")
          local f_oversized = mock_func_snippet("oversized",17)
          local input, buffer = session:open(f_simple, 1)
          session:select_and_open_block(1, f_simple)
          session:submit(f_oversized)

          assert.same(1, buffer.selection, "selection not moved")
          assert.same(string.lines(f_simple),
                      buffer:get_selected_text(),
                      "selection content not changed")
          assert.same(string.lines(f_oversized),
                      input:get_text(),
                      "input content stays altered")
          assert.same(f_simple,
                      savefile(),
                      "saved content not changed")
          session:assert_cursor_at(session:input_line_of(f_oversized))
        end)

        it("normal block rewrites oversized", function()
          local f_simple = mock_func_snippet("simple")
          local f_oversized = mock_func_snippet("oversized",17)

          local input, buffer = session:open(f_oversized, 1)
          session:select_and_open_block(1, f_oversized)
          session:submit(f_simple)

          assert.same(2, buffer.selection, "selection moved")
          assert.is_true(input:is_empty(), "input cleared")
          session:select_block(1)
          assert.same(string.lines(f_simple),
                      buffer:get_selected_text(),
                      "previous block content replaced")
          assert.same(f_simple..'\n', savefile(),
                      "updated content is saved")
        end)

        it("refactored blocks with oversized tail rejected", function()
          local f_simple = mock_func_snippet("simple")
          local f_over_orig = mock_func_snippet("oversized",20)
          local f_over_new = mock_func_snippet("oversized2",17)
          local code_refactored = src(f_simple, f_over_new)

          local input, buffer = session:open(f_over_orig, 1)
          session:select_and_open_block(1, f_over_orig)
          session:submit(code_refactored)

          assert.same(1, buffer.selection,
                       "selection not moved")
          assert.same( string.lines(f_over_orig),
                       buffer:get_selected_text(),
                       "selection text stays untouched" )
          assert.same( string.lines(code_refactored),
                       input:get_text(),
                       "input keeps full submission")
          assert.same(f_over_orig,
                      savefile(),
                      "saved content not changed")
          session:assert_cursor_at(session:input_line_of(f_over_new))
        end)

        -- see issue #114
        it ("extra emptyline+comment before single LOC", function()
          local emptyline = ''
          local comment = '-- comment'
          local single_loc = 'print("original line of code")'


          local orig = src(single_loc, emptyline)
          local edited = src(emptyline, comment, single_loc)

          local input, buffer = session:open(orig)
          session:select_and_open_block(1, single_loc)

          session:submit( edited )

          local expected  = src(emptyline,
                                comment,
                                emptyline,
                                single_loc,
                                emptyline)

          assert.same( expected, savefile() )
        end)

        it ("extra emptyline+comment before block", function()
          local emptyline = ''
          local comment = '-- comment'
          local block = mock_func_snippet("orig_block")


          local orig = src(block, emptyline)
          local edited = src(emptyline, comment, block)

          local input, buffer = session:open(orig)
          session:select_and_open_block(1, single_loc)

          session:submit( edited )

          local expected  = src(emptyline,
                                comment,
                                emptyline,
                                block,
                                emptyline)

          assert.same( expected, savefile() )
        end)

        it ("extra emptyline before comment", function()
          local emptyline = ''
          local comment = '-- comment'

          local orig = src(comment)
          local edited = src(emptyline, comment)

          local input, buffer = session:open(orig)
          session:select_and_open_block(1, comment)

          session:submit( edited )
          assert.same( edited.."\n", savefile() )
        end)

      end)

      describe("insertion of", function()
        setup(function()
          some_func = mock_func_snippet('some')
          other_func = mock_func_snippet('other')
          base_blocks = {
            some_func,
            '',
            '--some comment',
            '',
            other_func,
            ''
          }
          existing_src = src(unpack(base_blocks))
          n_blocks = #base_blocks
          input = nil
          buffer = nil
        end)

        before_each(function()
          input, buffer = session:open(existing_src, n_blocks)
          --- files open at the top; these insert at the end
          session:select_block(n_blocks)
        end)

        it("single normal block", function()
          local new_func = mock_func_snippet("new_func")
          session:submit(new_func, true)

          assert.is_true(input:is_empty(), "input cleared")
          assert.same(n_blocks+1, buffer:get_content_length(),
                      "buffer size increased by 1 block")
          assert.same(n_blocks+1, buffer.selection,
                      "selection moved down by 1")

          session:select_block(n_blocks)
          assert.same( string.lines(new_func),
                       buffer:get_selected_text(),
                       "content added as new block")
          assert.same( existing_src..new_func..'\n',
                       savefile(),
                       "saved file contains updates")
        end)

        it("multiple normal blocks", function()
          local f1 = mock_func_snippet("f1")
          local f2 = mock_func_snippet("f2")
          local new_code = src(f1, f2)
          session:submit(new_code, true)

          assert.is_true(input:is_empty(), "input cleared")
          assert.same(n_blocks+3, buffer:get_content_length(),
                      "buffer size increased by 3 blocks")
          assert.same(n_blocks+3, buffer.selection,
                      "selection moved down by 3")
          assert.same( {},
                       buffer:get_selected_text(),
                       "trailing empty line is selected")

          session:select_block(n_blocks)
          assert.same( string.lines(f1),
                       buffer:get_selected_text(),
                       "first block injected first")
          session:select_block(n_blocks+1)
          assert.same({}, buffer:get_selected_text(),
                      "empty line injected after first")
          session:select_block(n_blocks+2)
          assert.same( string.lines(f2),
                       buffer:get_selected_text(),
                       "second block injected second")
          assert.same( src(existing_src..f1,'',f2,''),
                       savefile(),
                       "saved file contains updates")
        end)

        it('single oversized block is rejected', function()
          local f_oversized = mock_func_snippet("oversized",20)
          session:submit(f_oversized, true)

          assert.is_false(input:is_empty(), "input not cleared")
          assert.same( string.lines(f_oversized),
                       input:get_text(),
                       "text remains in the input")
          assert.same(n_blocks, buffer.selection,
                       "selection not moved")
          assert.same(n_blocks, buffer:get_content_length(),
                       "buffer length not changed")
          assert.same( existing_src,
                       savefile(),
                       "saved file unchanged")
          session:assert_cursor_at(session:input_line_of(f_oversized))
        end)

        it("normal+oversized mix rejected", function()
          local f_normal = mock_func_snippet("normal")
          local f1 = mock_func_snippet("f1")
          local f2 = mock_func_snippet("f2")
          local f_oversized = mock_func_snippet("oversized",20)

          local good = { f_normal, f1, f2 }
          local bad =  { f_oversized }
          local mix = table.flatten({good, bad})
          local mixed_content = src(unpack(mix))

          local old_sel = buffer.selection
          local old_len = buffer:get_content_length()
          local old_selected_block = buffer:get_selected_text()

          session:submit(mixed_content, true)

          assert.same(old_len, buffer:get_content_length(),
                      "buffer length unchanged")
          assert.same(old_sel, buffer.selection,
                      "selection not moved")
          assert.same(old_selected_block,
                      buffer:get_selected_text(),
                      "original block unchanged")
          assert.same(string.lines(mixed_content),
                      input:get_text(),
                      "input keeps full submission")
          assert.same(existing_src,
                      savefile(),
                      "saved file unchanged")
          session:assert_cursor_at(session:input_line_of(f_oversized))
        end)
      end)

    end)

  end)
end)
