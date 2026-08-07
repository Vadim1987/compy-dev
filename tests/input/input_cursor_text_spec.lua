--> REMARK: what if we organize tests by three groups named explicitly: a) interception of inbound key/mouse events b) management of input widget c) reacting to input widget events (limits, submission, cancellation) -- but we'll need good names for describe, aligned with documentation

-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

-- Cursor and text surface: get_cursor / set_cursor / set_text,
-- driven through F.compy_input() — exactly what a project sees
-- (doc/input_api.md, "Live changes";
-- doc/development/internals/user_input.md, "Cursor
-- manipulation and \"reset\""). Implementation:
-- model/input/userInputModel.lua, controller/userInputController.lua.

local F = require('tests.helpers.input_fixture')

describe('input surface: widget control — cursor and text #input',
  function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)


  -- These three are non-assignable methods (NOT in
  -- INPUT_CALLBACKS), so they ride the same frozen-surface
  -- boundary as show/hide — doc/development/decisions/input.md,
  -- Decision 7 (what a project may assign).


  describe("get_cursor", function()
    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": active → 1-based
    -- (line, col); hidden → nil.
    it('reports 1-based (line, col) when active',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        assert.same({ 1, 6 }, { input.get_cursor() })
      end)

    -- The pair above proves the report is 1-based ONCE. This row
    -- proves it keeps TRACKING: the reported position follows real
    -- edits (a typed character, a deletion) rather than being a
    -- constant that happens to match the opening state.
    -- activate_project, not compy_input alone: this row TYPES,
    -- so it needs the route a real project's overlay is fed
    -- through. Reading the surface needs no route; delivery
    -- does.
    it('keeps reporting the cursor as the text is edited',
      function()
        local input = F.activate_project()
        input.show({ text = 'hi' })
        assert.same({ 1, 3 }, { input.get_cursor() })
        F.session.type('!')
        assert.same({ 1, 4 }, { input.get_cursor() })
        F.session.press('backspace')
        assert.same({ 1, 3 }, { input.get_cursor() })
      end)

    -- Multiline: the LINE half of the pair has to move too, or a
    -- single-line-only report would pass every row above.
    it('reports the line on multiline text', function()
      local input = F.compy_input()
      input.show({ text = { 'ab', 'cd' } })
      assert.same({ 2, 3 }, { input.get_cursor() })
    end)

    -- Shown-with-text first, THEN hidden: without that setup a nil
    -- return would be indistinguishable from "the widget was empty
    -- and never active", which is not the claim being made.
    it('returns nil when hidden', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      assert.is_not_nil(input.get_cursor())
      input.hide()
      assert.is_nil(input.get_cursor())
    end)
 end)

 describe("set_cursor", function()

    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": move; out-of-range
    -- clamps to the valid range.
    
    -- activate_project: the row types to prove the caret is
    -- seated, so it needs the project route to deliver.
    it('moves the cursor', function()
      local input = F.activate_project()
      input.show({ text = 'lemon' })
      input.set_cursor(1, 3)
      assert.same({ 1, 3 }, { input.get_cursor() })
      -- The caret is really seated, not merely reported back:
      -- typing lands at the caret. `col` counts positions
      -- BETWEEN characters (1 .. #line + 1), so col 3 is
      -- between 'e' and 'm' (doc/input_api.md, "Live changes").
      F.session.type('X')
      assert.same({ 'leXmon' }, F.widget:get_text())
    end)

    -- Discriminating: seat the cursor at col 2 first, so a
    -- clamp-to-line-end (col 6) is distinguishable from
    -- move_cursor's fallback-to-previous (would stay col 2).
    -- Proves set_cursor_pos clamps rather than no-ops.
    it('clamps an over-range column', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(1, 2)
      input.set_cursor(1, 999)
      local _, c = input.get_cursor()
      assert.same(6, c) -- 'hello' end (len 5 + 1)
    end)

    it('clamps an over-range line', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(999, 2)
      local l = input.get_cursor()
      assert.same(1, l) -- single line: clamps to 1
    end)

    -- doc/input_api.md, "Live changes": hidden set_cursor
    -- no-ops and warns.
    it('while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_cursor(1, 2)
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_nil(input.get_cursor())
    end)
 end)

 describe("set_text", function()
    -- doc/input_api.md, "Live changes": replace
    -- content, cursor to end.
    it('replaces content and jumps to the end',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_text('worldly')
        assert.same({ 'worldly' }, F.widget:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(8, c) -- 'worldly' end (len 7 + 1)
      end)

    describe("with keep_cursor", function()
    -- doc/input_api.md, "Live changes": keep_cursor
    -- preserves position (clamped).
      -- activate_project: types across the text swap, so the
      -- project route has to be up to deliver it.
      it('preserves the cursor',
        function()
          local input = F.activate_project()
          input.show({ text = 'hello' })
          input.set_cursor(1, 3)
          input.set_text('world', true)
          local l, c = input.get_cursor()
          assert.same(1, l)
          assert.same(3, c)
          -- Seated for real, across the text swap: typing lands
          -- at the caret, which sits between 'o' and 'r'
          -- (caret positions, doc/input_api.md, "Live changes").
          F.session.type('X')
          assert.same({ 'woXrld' }, F.widget:get_text())
        end)

      it('clamps when text shrinks',
        function()
          local input = F.compy_input()
          input.show({ text = 'hello' })
          input.set_cursor(1, 5)
          input.set_text('xy', true)
          local _, c = input.get_cursor()
          assert.same(3, c) -- 'xy' end (len 2 + 1)
      end)
    end) 

    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": the view reflects the
    -- change WITHOUT a re-show
    -- (the overlay handle is not re-published; the widget's
    -- own view render fires via the controller's update_view).
    it('updates the view without a re-show',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local handle = love.state.user_input
        local renders = 0
        local orig = F.widget.view.render
        F.widget.view.render =
            function(...) renders = renders + 1 end
        input.set_text('again')
        F.widget.view.render = orig
        assert.equal(handle, love.state.user_input)
        assert.is_true(renders > 0)
      end)

    -- doc/input_api.md, "Live changes": hidden set_text
    -- no-ops and warns.
    it('while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_text('nope')
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_true(F.widget:is_empty())
    end)
  end)

    -- doc/development/decisions/input.md, Decision 7 (what a
    -- project may assign): the three callables are not among
    -- them, so the frozen surface raises loudly rather than
    -- swallowing the write.
    it('assigning the cursor/text callables raises',
      function()
        local input = F.compy_input()
        assert.has_error(function()
          input.get_cursor = function() end
        end)
        assert.has_error(function()
          input.set_cursor = function() end
        end)
        assert.has_error(function()
          input.set_text = function() end
        end)
      end)
end)
