-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

-- widget lifecycle. Routing
-- invariant (doc/development/decisions/input.md, Decision 1): inter-route dispatch is
-- EXCLUSIVE — each event reaches exactly ONE route, fixed by the active
-- screen mode. Vocabulary (doc/development/internals/user_input.md, "Dispatch chain"):
-- ROUTE = the controller an event is dispatched to; WIDGET = the
-- route-managed input surface and terminal of the chain. Tests assert
-- observable outcomes
-- at public seams, never method-name spies. keypressed fires for every
-- physical key, textinput only for character-producing keys
-- (doc/development/internals/user_input.md, "Data flow").
-- Widget activation/reset via the public compy.input surface and the
-- hidden-widget non-consumption rule (doc/input_api.md,
-- "`show(config)`"; doc/development/decisions/input.md,
-- Decision 2).

local F  = require('tests.helpers.input_fixture')

describe('input contracts: widget lifecycle #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- Widget activation / reset (doc/input_api.md,
  -- "`show(config)`"), driven through
  -- the public project surface. F.compy_input() resolves
  -- project_env.compy.input — exactly what a project sees.
  -- show({ text = ... }) seeds the widget's CONTENT (the
  -- editable text) and show({ prompt = ... }) its label — a separate
  -- config key, one row each (same section). The
  -- "no cancel chain" facts are stable-now.
  describe('widget activation and reset', function()

    -- Prompt LABELLING at activation. Re-labelling on an already
    -- active session is the reconfigure concern and is covered there
    -- (input_reconfigure_spec.lua, 'updates the prompt on an active
    -- session'), so this row only pins the show() half.
    it('a fresh activation applies the prompt label', function()
      local input = F.compy_input()
      input.show({ text = 'hi', prompt = 'name?' })
      assert.equal('name?', F.widget.model:get_label())
    end)

    it('a fresh activation with no text is empty',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.hide()
        input.show()
        assert.is_true(F.widget:is_empty())
      end)
    
    it('a fresh activation with text sets text',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        assert.same({ 'hello' }, F.widget:get_text())
      end)

    it('re-activation without force warns + no-ops',
      function()
        local input = F.compy_input()
        input.show({ text = 'first' })
        local warned = 0
        local ow = Log.warn
        Log.warn = function() warned = warned + 1 end
        input.show({ text = 'second' })
        Log.warn = ow
        assert.equal(1, warned)
        assert.same({ 'first' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 15:
    -- show()/configure() take a closed config table, so an
    -- unrecognised key can only be an authoring mistake. It
    -- raises rather than warning — the project stops at the
    -- typo instead of running on in a shape nobody asked for.
    it('show raises on a key outside its config table',
      function()
        local input = F.compy_input()
        assert.has_error(function()
          input.show({ text = 'ok', eval = InputEvalLua })
        end)
        assert.is_nil(love.state.user_input)
      end)

    it('the raise names the offending key',
      function()
        local input = F.compy_input()
        local _, err = pcall(function()
          input.show({ result = { } })
        end)
        assert.matches('result', err)
      end)

    -- The likeliest mistake is a lifecycle callback in the
    -- table instead of on compy.input.callbacks, so it earns
    -- a message that says where the assignment belongs.
    it('a lifecycle callback in the table names callbacks',
      function()
        local input = F.compy_input()
        local _, err = pcall(function()
          input.show({ after_submit = function() end })
        end)
        assert.matches('after_submit', err)
        assert.matches('callbacks', err)
      end)

    it('configure raises on an unknown key too',
      function()
        local input = F.compy_input()
        input.show({ text = 'ok' })
        assert.has_error(function()
          input.configure({ eval = InputEvalLua })
        end)
      end)

    -- force is a show()-only key; configure() has no inactive
    -- overlay to force, so passing it is the same mistake.
    it('configure raises on force',
      function()
        local input = F.compy_input()
        input.show({ text = 'ok' })
        assert.has_error(function()
          input.configure({ force = true })
        end)
      end)

    -- Guard against strictness creeping past its remit: a
    -- runtime STATE that makes a call a no-op is not an
    -- authoring error, and must keep warning rather than raise.
    it('a state-condition no-op warns and does not raise',
      function()
        local input = F.compy_input()
        local ow = Log.warn
        Log.warn = function() end
        local ok = pcall(function()
          input.show({ text = 'first' })
          input.show({ text = 'second' })
          input.hide()
          input.clear()
        end)
        Log.warn = ow
        assert.is_true(ok)
      end)

    -- force = live reconfiguration of an ACTIVE widget;
    -- today only the text subset takes effect
    -- (doc/input_api.md, "`show(config)`").
    it('re-activation with force reapplies text',
      function()
        local input = F.compy_input()
        input.show({ text = 'original' })
        input.show({ force = true, text = 'replaced' })
        assert.same({ 'replaced' },
          F.widget:get_text())
      end)

    -- force with NO text: a reconfiguration that changes
    -- nothing — content survives (it is not a hidden
    -- reset; doc/input_api.md, "`show(config)`").
    it('force without text leaves content intact',
      function()
        local input = F.compy_input()
        input.show({ text = 'keep' })
        input.show({ force = true })
        assert.same({ 'keep' }, F.widget:get_text())
      end)

    -- After hide the widget stops being the surface the
    -- route forwards to: typed text lands in the console,
    -- not the widget (whose non-mutation is asserted in
    -- the hidden-widget row below). That the CONSOLE is
    -- where it lands is the disputed half — see the group
    -- below for where that is recorded.
    it('hide deactivates the widget', function()
      local input = F.compy_input()
      input.show()
      input.hide()
      assert.is_false(F.widget:is_shown())
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)

  end)

  -- Hidden widget does not consume (doc/development/decisions/input.md,
  -- Decision 2: "its hidden-check is internal"): an event arriving while the
  -- widget is hidden never mutates widget state — it
  -- reaches the active route instead. Inter-route dispatch is unchanged.
  -- One row per channel: the pair differs only in which channel the
  -- event arrives on (textinput vs keypressed), so they are named for
  -- that and nothing else.
  --
  -- #disputable — the first assertion of each row (the widget keeps
  -- its content) is settled contract; the second (the CONSOLE LINE
  -- receives what the hidden widget declined) is the console route's
  -- own fallback, and whether it should exist at all was one of this
  -- feature's live arguments. It is ruled for the project route and
  -- unruled here: doc/development/technical_debt/input.md, "On the
  -- console route, a hidden widget's input falls to the console line".
  -- These rows pin today's behaviour so a change to it is deliberate;
  -- they do not endorse it.
  describe('a hidden widget does not consume #disputable', function()

    it('a typed character while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.session.type('Z')
      assert.same({ 'keep' }, F.widget:get_text())
      assert.same({ 'Z' }, F.console:get_text())
    end)

    -- The keypressed sibling of the row above: a key arriving while
    -- the widget is hidden goes to the console and mutates the
    -- console line while the hidden widget remains unchanged.
    it('a pressed key while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'keep' }, F.widget:get_text())
      assert.same({ 'a' }, F.console:get_text())
    end)
  end)

  -- Editor block navigation at the buffer limit lives in
  -- tests/editor/editor_spec.lua ("with blocks:" → "navigation at the
  -- block limit"): it is editor-INTERNAL behaviour driven below the
  -- gate, not a routing contract of the kind
  -- doc/development/decisions/input.md, Decision 1, asserts. This suite
  -- asserts only that the keystrokes reach the editor route
  -- (input_routing_spec.lua, "routing: editor mode").
end)
