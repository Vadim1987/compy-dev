-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

-- live reconfigure and the continuous-session idiom.
-- Routing invariant (doc/development/decisions/input.md,
-- Decision 1): inter-route dispatch is EXCLUSIVE — each event reaches
-- exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = the controller
-- an event is dispatched to; WIDGET = the route-managed input surface
-- and terminal of the chain. Tests assert observable outcomes at public
-- seams, never
-- method-name spies. keypressed fires for every physical key, textinput
-- only for character-producing keys (doc/development/internals/user_input.md, "Data
-- flow").
-- configure()/clear() live-reconfigure semantics, and the
-- continuous session the overlay's stay-shown default enables
-- (doc/development/internals/user_input.md, "configure(config)",
-- "clear()"; doc/input_api.md, "Submit lifecycle").

local F = require('tests.helpers.input_fixture')

describe('input contracts: live reconfigure #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- Live reconfigure + clear. Configure changes live
  -- callback fields; clear resets an active session as
  -- documented in doc/development/internals/user_input.md.
  -- ====================================================

  describe('live reconfigure and clear', function()

    describe('configure on an active session', function()
      -- doc/development/internals/user_input.md, "configure(config)": prompt
      -- updates live on an active session;
      -- content/cursor/callbacks stay untouched.
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

      -- doc/development/internals/user_input.md, "configure(config)":
      -- validator — the NEXT submit uses the new fn,
      -- not the one set at show() (exercised, not just read).
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

      -- doc/development/internals/user_input.md, "configure(config)":
      -- highlighter — the NEXT keystroke's highlight
      -- uses the new fn.
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

      -- doc/development/internals/user_input.md, "configure(config)":
      -- on_text_entered — the swapped fn fires on the
      -- next submit; the old one set at show() does not.
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

      -- doc/development/internals/user_input.md, "configure(config)":
      -- on_limit_reached — the swapped fn fires on the
      -- next boundary; the old one set at show() does not.
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

      -- doc/development/internals/user_input.md, "configure(config)":
      -- text/cursor are inert on an active session
      -- — even mixed with a live field, the live one applies
      -- and the inert ones are untouched (no partial/silent
      -- application: each field's own rule holds exactly).
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

    describe('hidden configure', function()
      -- doc/development/internals/user_input.md, "configure(config)":
      -- configure while hidden is safe
      -- (no warn —
      -- it is not a refusal) and text/cursor apply on the
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

      -- doc/development/internals/user_input.md, "configure(config)": a
      -- hidden configure of a live field
      -- (prompt,
      -- validator) applies cleanly on the next show() too.
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

    describe('clear', function()
      -- doc/development/internals/user_input.md, "clear()": on an active
      -- session empties content,
      -- cursor to start, no callback fires.
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

      -- doc/development/internals/user_input.md, "clear()": while hidden is
      -- a no-op + warn —
      -- unlike configure(), this call IS refused.
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

    describe('immutability', function()
      -- doc/development/decisions/input.md, Decision 7: the mutable boundary
      -- is unchanged for the two
      -- new callables.
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
  end)

  -- ====================================================
  -- doc/input_api.md, "Submit lifecycle": the overlay stays
  -- shown after a submit, so a continuous session needs no
  -- re-show — on_text_entered consumes and after_submit
  -- clears. A bare re-show from after_submit stays legal and
  -- is pinned here too, because the sticky-callback re-arm it
  -- relies on is contract.
  --
  -- Lifecycle callbacks are direct fields, not show() options.
  -- The project assigns after_submit before starting this loop.
  -- ====================================================

  describe('continuous-session idiom', function()

    ---> REMARK: did not we swap default widget behaviour to always show, and recommended to make closing explicit from 'after_submit'? Then this test actually tests nothing and needs to be replaced with closure-on-submit
    -- One shape: consume in on_text_entered, re-show
    -- (bare, no config) in after_submit. Asserts (a) the
    -- assembled text reaches on_text_entered and (b) the
    -- widget is active again once after_submit returns.
    it('re-shows from after_submit with the same callbacks',
      function()
        local input = F.activate_project()
        local seen = { }
        input.callbacks.after_submit = function() input.show({}) end
        input.show({
          prompt = 'first',
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        assert.same({ { 'a' } }, seen)
        assert.is_true(F.is_widget_visible())
        assert.is_true(F.widget:is_shown())
      end)

    -- The re-show re-arms with the STICKY callback — a
    -- second submit is observed without re-passing
    -- on_text_entered, proving the loop can repeat (the
    -- shape every migrated example's re-prompt depends on).
    it('the re-armed session observes a second submit',
      function()
        local input = F.activate_project()
        local seen = { }
        -- The idiom (Decision 6): the widget stays open;
        -- the project clears between prompts from after_submit.
        input.callbacks.after_submit = function() input.clear() end
        input.show({
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        F.session.type('b')
        F.session.press('return')
        assert.same({ { 'a' }, { 'b' } }, seen)
      end)

    -- Balloons shape (doc/input_api.md, "Live changes",
    -- "A continuous session with a changing prompt"): a
    -- hint set via configure()
    -- INSIDE on_text_entered (session still active,
    -- doc/development/internals/user_input.md, "Submit
    -- and cancel — widget-owned callback sequences")
    -- must survive the after_submit bare re-show, not the
    -- show()-time prompt: apply_config's custom_label is
    -- only overwritten
    -- when cfg.prompt is given, so a bare show({}) never
    -- resets what configure() just set.
    it('a prompt configured inside on_text_entered ' ..
      'survives the after_submit re-show', function()
      local input = F.activate_project()
      input.callbacks.after_submit = function() input.show({}) end
      input.show({
        prompt = 'first',
        on_text_entered = function()
          input.configure({ prompt = 'live' })
        end,
      })
      F.session.type('a')
      F.session.press('return')
      assert.equal('live', F.widget.model:get_label())
      assert.is_true(F.is_widget_visible())
    end)
  end)
end)
