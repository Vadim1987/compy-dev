-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

-- Widget lifecycle: activation and reset through the public
-- compy.input surface, and the rule that a hidden widget
-- consumes nothing (doc/input_api.md, "`show(config)`";
-- doc/development/decisions/input.md, Decision 2).

local F  = require('tests.helpers.input_fixture')

describe('input surface: widget control #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- Widget activation / reset (doc/input_api.md,
  -- "`show(config)`"), driven through the public project
  -- surface. F.compy_input() resolves project_env.compy.input —
  -- exactly what a project sees. show({ text = ... }) seeds the
  -- widget's CONTENT (the editable text) and show({ prompt =
  -- ... }) its label — a separate config key, one case each
  -- (same section). The "no cancel chain" facts are stable-now.
  describe('show(): activation and reset', function()

    -- Prompt LABELLING at activation. Re-labelling on an
    -- already active session is the reconfigure concern and is
    -- covered in this file's 'configure(): the live session'
    -- group ('updates the prompt on an active session'), so
    -- this case only pins the show() half.
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
    -- widget to force, so passing it is the same mistake.
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
    -- the hidden-widget case below). That the CONSOLE is
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

  -- ====================================================
  -- Live reconfigure + clear. Configure changes live
  -- callback fields; clear resets an active session as
  -- documented in doc/development/internals/user_input.md.
  -- ====================================================

  describe('configure(): the live session', function()
    -- doc/development/internals/user_input.md,
    -- "configure(config)": prompt updates live on an active
    -- session; content/cursor/callbacks stay untouched.
    it('updates the prompt on an active session',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ text = 'hi', on_text_entered = cb })
        input.configure({ prompt = 'new' })
        assert.equal('new', F.widget.model:get_label())
        assert.same({ 'hi' }, F.widget:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(3, c)
        assert.equal(cb, input.callbacks.on_text_entered)
      end)

    -- doc/development/internals/user_input.md,
    -- "configure(config)": validator — the NEXT submit uses the
    -- new fn, not the one set at show() (exercised, not just
    -- read).
    it('swaps the live validator', function()
      local input = F.activate_project()
      input.show({
        text      = 'ab',
        validator = function() return false, 'old' end,
      })
      local seen
      input.configure({
        validator = function(t)
          seen = t
          return true
        end,
      })
      F.session.press('return')
      assert.same({ 'ab' }, seen)
      assert.is_true(F.is_widget_visible())
    end)

    -- doc/development/internals/user_input.md,
    -- "configure(config)": highlighter — the NEXT keystroke's
    -- highlight uses the new fn.
    it('swaps the live highlighter', function()
      local input = F.activate_project()
      local marker = { { 'x' } }
      input.show({
        highlighter = function() return { { 'old' } } end,
      })
      input.configure({
        highlighter = function() return marker end,
      })
      F.session.type('a')
      local got = F.widget.model:get_highlight()
      assert.equal(marker, got.hl)
    end)

    -- doc/development/internals/user_input.md,
    -- "configure(config)": on_text_entered — the swapped fn
    -- fires on the next submit; the old one set at show() does
    -- not.
    it('swaps the live on_text_entered', function()
      local old_called, new_text = false, nil
      local input = F.activate_project()
      input.show({
        text            = 'ab',
        on_text_entered = function() old_called = true end,
      })
      input.configure({
        on_text_entered = function(t) new_text = t end,
      })
      F.session.press('return')
      assert.is_false(old_called)
      assert.same({ 'ab' }, new_text)
    end)

    -- doc/development/internals/user_input.md,
    -- "configure(config)": on_limit_reached — the swapped fn
    -- fires on the next boundary; the old one does not.
    it('swaps the live on_limit_reached', function()
      local old_called, new_dir = false, nil
      local input = F.activate_project()
      input.show({
        text             = 'ab',
        on_limit_reached = function() old_called = true end,
      })
      input.configure({
        on_limit_reached = function(dir) new_dir = dir end,
      })
      F.widget:jump_home()
      F.session.press('left')
      assert.is_false(old_called)
      assert.equal('left', new_dir)
    end)

    -- doc/development/internals/user_input.md,
    -- "configure(config)": text/cursor are inert on an active
    -- session — even mixed with a live field, the live one
    -- applies and the inert ones are untouched (no
    -- partial/silent application: each field's own rule holds
    -- exactly).
    it('leaves text/cursor untouched on an ' ..
      'active session, even mixed with a live field',
      function()
        local input = F.compy_input()
        input.show({ text = 'hi' })
        input.set_cursor(1, 2)
        input.configure({
          prompt = 'live',
          text   = 'ignored',
          cursor = { 1, 99 },
        })
        assert.same({ 'hi' }, F.widget:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(2, c)
        assert.equal('live', F.widget.model:get_label())
      end)
  end)

  describe('configure(): while hidden', function()
    -- doc/development/internals/user_input.md,
    -- "configure(config)": configure while hidden is safe (no
    -- warn — it is not a refusal) and text/cursor apply on the
    -- very next show().
    it('applies text and cursor on the ' ..
      'next show', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.configure({ text = 'draft', cursor = { 1, 2 } })
      Log.warn = ow
      assert.equal(0, warned)
      input.show({})
      assert.same({ 'draft' }, F.widget:get_text())
      local l, c = input.get_cursor()
      assert.same(1, l)
      assert.same(2, c)
    end)

    -- doc/development/internals/user_input.md,
    -- "configure(config)": a hidden configure of a live field
    -- (prompt, validator) applies cleanly on the next show()
    -- too.
    it('applies prompt and validator on ' ..
      'the next show', function()
      local input = F.compy_input()
      input.configure({
        prompt    = 'draft-label',
        validator = function() return true end,
      })
      input.show({})
      assert.equal(
        'draft-label', F.widget.model:get_label())
      assert.is_function(input.callbacks.validator)
    end)

    -- Pending fields are one-shot: a LATER bare show() must
    -- not keep re-injecting a stale hidden-configured draft
    -- (distinguishes this from the output-callback
    -- fields,
    -- which stay sticky forever by design).
    it('hidden-configured text does not leak into a later ' ..
      'show', function()
      local input = F.compy_input()
      input.configure({ text = 'draft' })
      input.show({})
      input.hide()
      input.show({})
      assert.is_true(F.widget:is_empty())
    end)
  end)

  describe('clear()', function()
    -- doc/development/internals/user_input.md, "clear()": on an
    -- active session empties content, cursor to start, no
    -- callback fires.
    it('empties an active session with no callback',
      function()
        local input = F.compy_input()
        local called = false
        input.show({
          text            = 'hi',
          on_text_entered = function() called = true end,
        })
        input.clear()
        assert.is_true(F.widget:is_empty())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(1, c)
        assert.is_false(called)
      end)

    -- doc/development/internals/user_input.md, "clear()": while
    -- hidden is a no-op + warn — unlike configure(), this call
    -- IS refused.
    it('while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.clear()
      Log.warn = ow
      assert.equal(1, warned)
    end)
  end)

  describe('the mutable boundary', function()
    -- doc/development/decisions/input.md, Decision 7: the
    -- mutable boundary is unchanged for the two new callables.
    it('assigning configure/clear raises', function()
      local input = F.compy_input()
      assert.has_error(function()
        input.configure = function() end
      end)
      assert.has_error(function()
        input.clear = function() end
      end)
    end)
  end)

  -- Hidden widget does not consume
  -- (doc/development/decisions/input.md, Decision 2: "its
  -- hidden-check is internal"): an event arriving while the
  -- widget is hidden never mutates widget state — it reaches
  -- the active route instead. Inter-route dispatch is
  -- unchanged. One case per channel: the pair differs only in
  -- which channel the event arrives on (textinput vs
  -- keypressed), so they are named for that and nothing else.
  --
  -- These ran on the CONSOLE route while it still had a widget
  -- step, and were tagged #disputable because the second half
  -- of each -- the console line receiving what the hidden
  -- widget declined -- rested on a fallback nobody had ruled
  -- on. That fallback is gone: the console route has no widget
  -- step at all now (Decision 1, "widget visibility is never a
  -- routing condition"), which would leave these cases passing
  -- for a reason unrelated to their claim -- a SHOWN widget
  -- would satisfy them there just as well.
  --
  -- Re-sited on the project route, where a hidden widget is a
  -- real decision: the walk skips it and reports not-consumed.
  -- What discriminates hidden from shown is the WIDGET's own
  -- text, and the third case is the control that says so. The
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

    -- The keypressed sibling of the case above.
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

    -- THE CONTROL for both cases above: the identical
    -- keystroke, with the widget shown, DOES edit it. Without
    -- this the two could pass against a widget that never
    -- receives anything under any condition.
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

  -- doc/input_api.md, "Live changes": the widget answers
  -- whether it is up. A project cannot read this from
  -- love.state — its `love` is a sandboxed clone, so
  -- `love.state.user_input` is always nil inside a project
  -- (project_sandbox_env.md, T1) — which is why the query is
  -- part of the surface rather than an idiom.
  describe('is_shown()', function()

    it('reports the widget state across a show/hide cycle',
      function()
        local input = F.compy_input()
        assert.is_false(input.is_shown())
        input.show({ text = 'x' })
        assert.is_true(input.is_shown())
        input.hide()
        assert.is_false(input.is_shown())
      end)

    -- The guard the ruling asks an example to write: act only
    -- when the widget is down, and leave the key to it when it
    -- is up.
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

    -- always_shown() is a construction-time property of the
    -- console and editor surfaces: they are host chrome, not a
    -- transient prompt, and no path should take them down.
    -- Enforcing it is what makes the name true: the flag was a
    -- convention any hide() call would have silently broken.
    it('an always-shown widget refuses to hide', function()
      local m = UserInputModel(F.cfg, InputEvalText)
      local w = UserInputController(m, true):always_shown()
      assert.is_true(w:is_shown())
      w:hide()
      assert.is_true(w:is_shown())
    end)

    -- The control: an ordinary widget hides normally, so the
    -- case above pins the always_shown property and not a
    -- hide() that stopped working.
    it('an ordinary widget still hides', function()
      local m = UserInputModel(F.cfg, InputEvalText)
      local w = UserInputController(m, true)
      w.shown = true
      w:hide()
      assert.is_false(w:is_shown())
    end)
  end)

  -- doc/input_api.md, "Opening the input widget from a key".
  -- LÖVE delivers a keypressed AND a textinput for one physical
  -- key and guarantees nothing about their order, so the
  -- trigger's own echo can land in the field it just opened.
  -- The API's answer is a project idiom, not a mechanism: a
  -- one-shot shortcut on the textinput channel eats the echo
  -- and unregisters itself, re-armed wherever the project
  -- closes. These cases pin the idiom the guide documents. It
  -- is only as good as the seams it rests on: shortcuts run
  -- before the widget on every channel, and a handler may clear
  -- its own slot mid-flight.
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

    it('the echo does not reach an input widget it opened',
      function()
        open_on('keypressed')
        F.session.press('i')
        F.session.type('i')
        assert.is_true(F.is_widget_visible())
        assert.is_true(F.widget:is_empty())
      end)

    -- The order LÖVE does not promise: the echo arrives BEFORE
    -- the open and is eaten while the widget is still closed,
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
    -- open takes the echo, which is the whole cost of the
    -- idiom.
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

  -- A shown widget must be PAINTED, whatever the project does.
  -- Two draw paths exist and they are not interchangeable: a
  -- project that hooks love.draw is wrapped by set_love_update,
  -- which paints the widget after the project's own frame; a
  -- project that hooks nothing keeps the console's draw, which
  -- is the path these cases pin. Consuming input the user
  -- cannot see is the failure mode
  -- (doc/development/internals/user_input.md, "Widget
  -- lifecycle"), and the widget's own view is the only surface
  -- that shows it — the console's input line below it belongs
  -- to the console. The view is the fixture's stub, so what is
  -- asserted is the WIRING (the frame reaches the widget's
  -- view), never pixels.
  describe('a shown widget is painted', function()

    it('the console draw path paints a shown widget', function()
      local painted = 0
      F.widget.view.draw = function() painted = painted + 1 end
      F.compy_input().show({ text = 'x' })
      love.draw()
      assert.equal(1, painted)
    end)

    it('a hidden widget is not painted', function()
      local painted = 0
      F.widget.view.draw = function() painted = painted + 1 end
      local input = F.compy_input()
      input.show({ text = 'x' })
      input.hide()
      love.draw()
      assert.equal(0, painted)
    end)

    -- doc/development/decisions/input.md, Decision 12: under
    -- inspect the console owns the surface and the project's
    -- widget is unhonoured — including on screen.
    it('a widget is not painted under inspect', function()
      local painted = 0
      F.widget.view.draw = function() painted = painted + 1 end
      F.compy_input().show({ text = 'x' })
      love.state.app_state = 'inspect'
      love.draw()
      assert.equal(0, painted)
    end)
  end)

  -- Editor block navigation at the buffer limit lives in
  -- tests/editor/editor_spec.lua ("with blocks:" → "navigation
  -- at the block limit"): it is editor-INTERNAL behaviour
  -- driven below the gate, not a routing contract of the kind
  -- doc/development/decisions/input.md, Decision 1, asserts.
  -- This suite asserts only that the keystrokes reach the
  -- editor route (input_routing_spec.lua, "routing: editor
  -- mode").
end)
