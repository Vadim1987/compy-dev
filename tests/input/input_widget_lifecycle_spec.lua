-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

---> REMARK: prose below seems to be copied from elsewhere without much relevance to test suite content
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

---> REMARK: avoid word 'overlay', better 'project input widget'
---> REMARK: There was another test suite on reconfiguration -- worth merging here and possibly de-duplicating?

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
        assert.is_false(F.is_widget_visible())
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
  -- These ran on the CONSOLE route while it still had a widget
  -- step, and were tagged #disputable because the second half
  -- of each -- the console line receiving what the hidden
  -- widget declined -- rested on a fallback nobody had ruled
  -- on. That fallback is gone: the console route has no widget
  -- step at all now (Decision 1, "widget visibility is never a
  -- routing condition"), which would leave these rows passing
  -- for a reason unrelated to their claim -- a SHOWN widget
  -- would satisfy them there just as well.
  --
  -- Re-sited on the project route, where a hidden widget is a
  -- real decision: the walk skips it and reports not-consumed.
  -- What discriminates hidden from shown is the WIDGET's own
  -- text, and the third row is the control that says so. The
  -- hook assertion is not a discriminator -- hooks run BEFORE
  -- the widget, so it fires either way; it proves the event
  -- reached the chain at all rather than being dropped
  -- upstream, which would make an unchanged widget prove
  -- nothing. The dispute is settled, not pinned, so the tag is
  -- gone.
  describe('a hidden widget is skipped', function()

    it('a typed character while hidden does not mutate it',
      function()
        local input = F.activate_project()
        local seen = 0
        input.hooks.textinput = function() seen = seen + 1 end
        input.show({ text = 'keep' })
        input.hide()
        F.session.type('Z')
        assert.same({ 'keep' }, F.widget:get_text())
        assert.equal(1, seen)
      end)

    -- The keypressed sibling of the row above.
    it('a pressed key while hidden leaves it alone',
      function()
      local input = F.activate_project()
      local seen = 0
      input.hooks.keypressed = function() seen = seen + 1 end
      input.show({ text = 'keep' })
      input.hide()
      F.session.press('backspace')
      assert.same({ 'keep' }, F.widget:get_text())
      assert.equal(1, seen)
    end)

    -- THE CONTROL for both rows above: the identical keystroke,
    -- with the widget shown, DOES edit it. Without this the
    -- two could pass against a widget that never receives
    -- anything under any condition.
    it('shown, the same key edits the widget', function()
      local input = F.activate_project()
      local seen = 0
      input.hooks.keypressed = function() seen = seen + 1 end
      input.show({ text = 'keep' })
      F.session.press('backspace')
      assert.same({ 'kee' }, F.widget:get_text())
      assert.equal(1, seen)
    end)
  end)

  -- doc/input_api.md, "Live changes": the overlay answers whether it
  -- is up. A project cannot read this from love.state — its `love` is
  -- a sandboxed clone, so `love.state.user_input` is always nil inside
  -- a project (project_sandbox_env.md, T1) — which is why the query is
  -- part of the surface rather than an idiom.
  describe('is_shown', function()

    it('reports the overlay state across a show/hide cycle',
      function()
        local input = F.compy_input()
        assert.is_false(input.is_shown())
        input.show({ text = 'x' })
        assert.is_true(input.is_shown())
        input.hide()
        assert.is_false(input.is_shown())
      end)

    -- The guard the ruling asks an example to write: act only when
    -- the overlay is down, and leave the key to it when it is up.
    it('lets a project skip a redundant show', function()
      local shows = 0
      local input = F.activate_project()
      input.hooks.keypressed = function()
        if input.is_shown() then return end
        shows = shows + 1
        input.show({ text = 'from i' })
        return true
      end
      F.session.press('i')
      F.session.press('i')
      assert.equal(1, shows)
      assert.same({ 'from i' }, F.widget:get_text())
    end)
  end)

  -- doc/input_api.md, "Opening the overlay from a key". LÖVE
  -- delivers a keypressed AND a textinput for one physical key
  -- and guarantees nothing about their order, so the trigger's
  -- own echo can land in the field it just opened. The API's
  -- answer is a project idiom, not a mechanism: a one-shot
  -- shortcut on the textinput channel eats the echo and
  -- unregisters itself, re-armed wherever the project closes.
  -- These rows pin the idiom the guide documents. It is only as
  -- good as the seams it rests on: shortcuts run before the
  -- widget on every channel, and a handler may clear its own
  -- slot mid-flight.
  describe('the documented echo guard', function()

    local function arm(input)
      input.shortcuts.textinput['i'] = function()
        input.shortcuts.textinput['i'] = nil
        return true
      end
    end

    -- The guide's shape: open from a key, guard with the pair.
    local function open_on(event)
      local input = F.activate_project()
      input.hooks[event] = function(k)
        if k == 'i' and not input.is_shown() then
          input.show({ prompt = 'cmd' })
          return true
        end
      end
      arm(input)
      return input
    end

    it('the echo does not reach an overlay it opened',
      function()
        open_on('keypressed')
        F.session.press('i')
        F.session.type('i')
        assert.is_true(F.is_widget_visible())
        assert.is_true(F.widget:is_empty())
      end)

    -- The order LÖVE does not promise: the echo arrives BEFORE
    -- the open and is eaten while the overlay is still closed,
    -- which is why the idiom needs no ordering guarantee.
    it('holds when the echo precedes the open', function()
      open_on('keyreleased')
      F.session.type('i')
      F.session.press('i')
      F.session.release('i')
      assert.is_true(F.is_widget_visible())
      assert.is_true(F.widget:is_empty())
    end)

    -- One-shot: spent on the echo, so the trigger character is
    -- ordinary content from then on.
    it('the trigger is typable once the one-shot is spent',
      function()
        open_on('keypressed')
        F.session.press('i')
        F.session.type('i')
        F.session.type('i')
        F.session.type('x')
        assert.same({ 'ix' }, F.widget:get_text())
      end)

    -- The re-arm the guide insists on: without it the second
    -- open takes the echo, which is the whole cost of the idiom.
    it('a re-armed guard protects the next open too', function()
      local input = open_on('keypressed')
      F.session.press('i')
      F.session.type('i')
      input.hide()
      arm(input)
      F.session.press('i')
      F.session.type('i')
      assert.is_true(F.widget:is_empty())
    end)
  end)

  -- A shown overlay must be PAINTED, whatever the project does.
  -- Two draw paths exist and they are not interchangeable: a project
  -- that hooks love.draw is wrapped by set_love_update, which paints
  -- the overlay after the project's own frame; a project that hooks
  -- nothing keeps the console's draw, which is the path these rows
  -- pin. Consuming input the user cannot see is the failure mode
  -- (doc/development/internals/user_input.md, "Widget lifecycle"),
  -- and the overlay's own view is the only surface that shows it —
  -- the console's input line below it belongs to the console.
  -- The view is the fixture's stub, so what is asserted is the
  -- WIRING (the frame reaches the overlay's view), never pixels.
  describe('a shown overlay is painted', function()

    it('the console draw path paints a shown overlay', function()
      local painted = 0
      F.widget.view.draw = function() painted = painted + 1 end
      F.compy_input().show({ text = 'x' })
      love.draw()
      assert.equal(1, painted)
    end)

    it('a hidden overlay is not painted', function()
      local painted = 0
      F.widget.view.draw = function() painted = painted + 1 end
      local input = F.compy_input()
      input.show({ text = 'x' })
      input.hide()
      love.draw()
      assert.equal(0, painted)
    end)

    -- doc/development/decisions/input.md, Decision 12: under inspect
    -- the console owns the surface and the project's widget is
    -- unhonoured — including on screen.
    it('an overlay is not painted under inspect', function()
      local painted = 0
      F.widget.view.draw = function() painted = painted + 1 end
      F.compy_input().show({ text = 'x' })
      love.state.app_state = 'inspect'
      love.draw()
      assert.equal(0, painted)
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
