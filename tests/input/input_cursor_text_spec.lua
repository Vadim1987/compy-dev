-- cursor and text surface — {temporal/REVIEW: split from input_contracts_spec.lua (TF1)}.
-- REVIEW/clarity: why the prose below describes event dispatching if the suite references active API? (getting,setting text/cursor?)
-- Routing invariant (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route, fixed by
-- the active screen mode. Vocabulary (doc/development/internals/user_input.md, 
--- REVIEW/clarity: route(controller) and sink(chain element in the controller) are both called 'consumer' below
-- "Dispatch
-- chain"): ROUTE = consumer an event is dispatched to; WIDGET = a
-- route-managed input surface; SINK = last consumer. Tests assert
-- observable outcomes at public seams, never method-name spies.
-- keypressed fires for every physical key, textinput only for
-- character-producing keys (doc/development/internals/user_input.md, "Data flow").
--- REVIEW/clarity: phrase below has no verb so reads awkwardly ('"x on y (...)" -- does or means what?')
-- get_cursor/set_cursor/set_text on the public project surface
-- (doc/input_api.md, "API reference"; doc/development/internals/user_input.md, "Cursor
-- manipulation and 'reset'").

local F = require('tests.helpers.input_fixture')

describe('input API: cursor and text surface', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)


  -- The cursor + text surface (doc/input_api.md, "Live
  -- reconfigure: `configure`, `set_text`, `clear`, cursor",
  -- and "API reference"). Driven through the public
  -- project
  -- surface F.compy_input() — exactly what a project sees.
  -- get_cursor/set_cursor/set_text are non-assignable
  -- methods (NOT in INPUT_CALLBACKS), so doc/development/decisions/input.md,
  -- Decision 7 rides the
  -- same __newindex boundary as show/hide.


  describe("get_cursor", function()
    -- doc/development/internals/user_input.md, "Cursor manipulation and
    -- 'reset'": active → 1-based (line, col); hidden
    -- → nil.
    it('reports 1-based (line, col) when active',
      function()
	--- REVIEW/fidelity: only one case is checked -- 'when active' proven, but whether this line/col really always match cursor? not clear (otoh we're against testing all corner cases). Maybe its not worth separate case -- but running few modifications and rechecking assertions would be practical?
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(6, c)
      end)

    it('returns nil when hidden', function()
      --- REVIEW/fidelity: no explicit 'hide()', no text filled -- nil could be returned just by default because input is *empty* not because its hidden
      local input = F.compy_input()
      assert.is_nil(input.get_cursor())
    end)
 end)

 describe("set_cursor", function()

    -- doc/development/internals/user_input.md, "Cursor manipulation and
    -- 'reset'": move; out-of-range clamps to the
    -- valid range.
    
    it('moves the cursor', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(1, 3)
      local l, c = input.get_cursor()
      assert.same(1, l)
      assert.same(3, c)
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

    -- doc/input_api.md, "API reference": hidden set_cursor
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
    -- doc/input_api.md, "Live reconfigure": replace
    -- content, cursor to end.
    it('replaces content and jumps to the end',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_text('worldly')
        assert.same({ 'worldly' }, F.singleton:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(8, c) -- 'worldly' end (len 7 + 1)
      end)

    describe("with keep_cursor", function()
    -- doc/input_api.md, "Live reconfigure": keep_cursor
    -- preserves position (clamped).
      it('preserves the cursor',
        function()
          local input = F.compy_input()
          input.show({ text = 'hello' })
          input.set_cursor(1, 3)
          input.set_text('world', true)
          local l, c = input.get_cursor()
          assert.same(1, l)
          assert.same(3, c)
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

    -- doc/development/internals/user_input.md, "Cursor manipulation and
    -- 'reset'": the view reflects the change WITHOUT
    -- a re-show
    -- (the overlay handle is not re-published; the widget's
    -- own view render fires via the controller's update_view).
    it('updates the view without a re-show',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local handle = love.state.user_input
        local renders = 0
        local orig = F.singleton.view.render
        F.singleton.view.render =
            function(...) renders = renders + 1 end
        input.set_text('again')
        F.singleton.view.render = orig
        assert.equal(handle, love.state.user_input)
        assert.is_true(renders > 0)
      end)

    -- doc/input_api.md, "API reference": hidden set_text
    -- no-ops and warns.
    it('while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_text('nope')
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_true(F.singleton:is_empty())
    end)
  end)

    -- doc/development/decisions/input.md, Decision 7: the three callables are
    -- non-assignable — the
    -- mutable boundary raises loudly (never a silent swallow).
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
