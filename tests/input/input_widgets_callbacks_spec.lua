-- Availability: feature-new — the widget output fields are
-- introduced by this feature, and the submit/cancel defaults were
-- altered by it (since / changed in 1.0.0-rc20260712).

-- dispatch chain: widget outputs and submit/cancel — split from
-- input_contracts_spec.lua (TF1). Routing invariant (doc/development/decisions/input.md,
-- Decision 1): inter-route dispatch is EXCLUSIVE — each event reaches
-- exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = the controller
-- an event is dispatched to; WIDGET = the route-managed input surface
-- and terminal of the chain. Tests assert observable outcomes at public
-- seams, never
-- method-name spies. keypressed fires for every physical key, textinput
-- only for character-producing keys (doc/development/internals/user_input.md, "Data
-- flow").
-- Outputs half of the dispatch chain (Decision 5's four widget
-- output fields, the highlighter/on_limit_reached boundary, and the full
-- submit/cancel call-order chains of Decision 6). The mechanics half
-- (order/consume/fall-through, combo tables, signatures) is
-- input_dispatch_chain_spec.lua.

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')

-- ====================================================
-- The dispatch chain (doc/development/decisions/input.md, Decision 2).
-- All rows drive the REAL project route: F.activate_
-- project() installs the ProjectInputController as the
-- the active route (app_state='running') via the same
-- Controller.set_user_handlers path a run calls, and
-- returns the project-facing compy.input surface. The
-- observable results are the widget's text
-- and
-- the callbacks a project registers — never a spy on an
-- internal method (except the one widget-signature row,
-- which patches the shared widget and restores it).
-- ====================================================

describe('dispatch chain: widget outputs and submit/cancel #m5c #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ---- widget outputs (doc/development/decisions/input.md, Decision 5)
  -- ----------

  describe('output fields and sharing', function()
    -- doc/development/decisions/input.md, Decision 5: the four widget
    -- outputs are project-assignable
    -- fields on compy.input (same boundary, widened allowlist).
    it('the four widget output fields are assignable',
      function()
        local input = F.compy_input()
        assert.has_no.errors(function()
          input.callbacks.on_text_entered  = function() end
          input.callbacks.on_limit_reached = function() end
          input.callbacks.validator        = function() end
          input.callbacks.highlighter      = function() end
        end)
      end)

    -- doc/development/decisions/input.md, Decision 5: show(config) keys and
    -- field assignment hit
    -- the same underlying callbacks.
    it('show(config) and fields share one output field',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ on_limit_reached = cb })
        assert.equal(cb, input.callbacks.on_limit_reached)
        local hl = function() return { { } } end
        input.callbacks.highlighter = hl
        input.show()
        assert.equal(hl, input.callbacks.highlighter)
      end)

    -- doc/development/decisions/input.md, Decision 5 cont.: on_text_entered
    -- and validator also
    -- reach the same callback via config key and via
    -- field write
    -- (settable-only here; firing/gating is decisions/
    -- input.md, Decision 6).
    it('show(config) shares on_text_entered callback',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ on_text_entered = cb })
        assert.equal(cb, input.callbacks.on_text_entered)
      end)

    it('field write shares on_text_entered callback',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.callbacks.on_text_entered = cb
        input.show()
        assert.equal(cb, input.callbacks.on_text_entered)
      end)

    it('show(config) shares validator callback',
      function()
        local input = F.compy_input()
        local vfn = function() return true end
        input.show({ validator = vfn })
        assert.equal(vfn, input.callbacks.validator)
      end)

    it('field write shares validator callback',
      function()
        local input = F.compy_input()
        local vfn = function() return true end
        input.callbacks.validator = vfn
        input.show()
        assert.equal(vfn, input.callbacks.validator)
      end)
  end)

  describe('highlighter', function()
    -- doc/development/decisions/input.md, Decision 5: a custom highlighter
    -- transforms live text and
    -- the queried highlight reflects that transformed output.
    it('a custom highlighter transforms queried highlight',
      function()
        local input = F.activate_project()
        local marker = { { 'x' } }
        input.show({
          highlighter = function()
            return marker
          end,
        })
        F.session.type('a')
        local got = F.widget.model:get_highlight()
        assert.equal(marker, got.hl)
      end)

    it('LuaHighlighter colors Lua overlay text', function()
      local input = F.activate_project()
      input.show({ highlighter = LuaHighlighter })
      F.session.type('return 1')
      local hl = F.widget.model:get_highlight().hl
      assert.is_true(type(hl) == 'table')
    end)
  end)

  describe('navigation boundary outputs', function()
    -- doc/development/decisions/input.md, Decision 5, boundary half:
    -- crossing attempts fire
    -- on_limit_reached(direction, scope) and its return value
    -- is ignored (observational only; widget still runs).
    it('up boundary fires direction up with input scope',
      function()
        local seen = { }
        local input = F.activate_project()
        input.show({
          text = { 'ab', 'cd' },
          on_limit_reached = function(dir, scope)
            seen[#seen + 1] = { dir, scope }
          end,
        })
        F.widget:set_cursor(Cursor(1, 2))
        F.session.press('up')
        assert.same({ { 'up', 'input' } }, seen)
      end)

    it('down boundary fires direction down with input scope',
      function()
        local seen = { }
        local input = F.activate_project()
        input.show({
          text = { 'ab', 'cd' },
          on_limit_reached = function(dir, scope)
            seen[#seen + 1] = { dir, scope }
          end,
        })
        F.widget:set_cursor(Cursor(2, 2))
        F.session.press('down')
        assert.same({ { 'down', 'input' } }, seen)
      end)

    it('left boundary fires output; return is ignored',
      function()
        local seen = { }
        local input = F.activate_project()
        input.show({
          text = 'ab',
          on_limit_reached = function(dir, scope)
            seen[#seen + 1] = { dir, scope }
            return true
          end,
        })
        F.widget:jump_home()
        F.session.press('left')
        assert.same({ { 'left', 'input' } }, seen)
      end)

    -- doc/development/decisions/input.md, Decision 5: line-scope boundary
    -- in multiline text.
    it('left line boundary fires scope line', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.widget:set_cursor(Cursor(2, 1))
      F.session.press('left')
      assert.same({ { 'left', 'line' } }, seen)
    end)

    it('right line boundary fires scope line', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.widget:set_cursor(Cursor(1, 3))
      F.session.press('right')
      assert.same({ { 'right', 'line' } }, seen)
    end)

    -- Edge case: first-line left is a horizontal key that
    -- maps to whole-input limit scope.
    it('left at first-line start has input scope', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.widget:set_cursor(Cursor(1, 1))
      F.session.press('left')
      assert.same({ { 'left', 'input' } }, seen)
    end)

    -- Edge case: last-line right is a horizontal key that
    -- maps to whole-input limit scope.
    it('right at last-line end reports input scope', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.widget:set_cursor(Cursor(2, 3))
      F.session.press('right')
      assert.same({ { 'right', 'input' } }, seen)
    end)
  end)

  -- ---- submit and cancel (doc/development/decisions/input.md,
  -- Decision 6) -------

  describe('submit', function()
    -- doc/development/decisions/input.md, Decision 6: the full submit
    -- call-order chain on a real Enter keypress. Every project
    -- callback receives the widget's native line array.
    it('Enter runs the full submit call-order chain',
      function()
        local order = { }
        local input = F.activate_project()
        input.callbacks.before_submit = function()
          order[#order + 1] = 'before'
        end
        input.callbacks.validator = function(t)
          order[#order + 1] = { 'validator', t }
          return true
        end
        input.callbacks.after_submit = function(t)
          order[#order + 1] = { 'after', t }
        end
        input.show({
          text = { 'a', 'b' },
          on_text_entered = function(t)
            order[#order + 1] = { 'entered', t }
          end,
        })
        F.session.press('return')
        assert.same(
          {
            'before',
            { 'validator', { 'a', 'b' } },
            { 'entered', { 'a', 'b' } },
            { 'after', { 'a', 'b' } },
          }, order)
      end)

    -- Decision 6 revised: submit no longer auto-closes. The
    -- default after_submit is a no-op, so BOTH on_text_entered and
    -- after_submit see the session still active — the widget stays
    -- open unless a callback hides it (AC3).
    it('on_text_entered and after_submit both see the ' ..
      'session still active (stays open)', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = 'x',
        on_text_entered = function()
          seen.entered = love.state.user_input ~= nil
        end,
      })
      input.callbacks.after_submit = function()
        seen.after = love.state.user_input ~= nil
      end
      F.session.press('return')
      assert.is_true(seen.entered)
      assert.is_true(seen.after)
    end)

    -- doc/development/internals/user_input.md, "Submit and
    -- cancel — widget-owned callback sequences": a custom
    -- validator receives the live line array (not joined or
    -- stale text).
    it('a custom validator receives the live lines',
      function()
        local seen
        local input = F.activate_project()
        input.show({
          text = 'ab',
          validator = function(t) seen = t; return true end,
        })
        F.session.press('return')
        assert.same({ 'ab' }, seen)
      end)

    -- doc/development/internals/user_input.md, "Submit and
    -- cancel — widget-owned callback sequences": a
    -- rejecting validator locks the
    -- session — no delivery, no deactivation, no
    -- after_submit.
      it('a rejecting validator locks input without delivering',
      function()
        local entered, after = false, false
        local input = F.activate_project()
        input.callbacks.after_submit = function() after = true end
        input.show({
          text = 'bad',
          validator = function() return false, { Error('nope') } end,
          on_text_entered = function() entered = true end,
        })
        F.session.press('return')
        assert.is_false(entered)
        assert.is_false(after)
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.widget:has_error())
      end)

      it('LineValidators rejects one invalid line', function()
        local entered = false
        local input = F.activate_project()
        input.show({
          text = { 'ok', 'bad' },
          validator = LineValidators(function(line)
            return line ~= 'bad', 'not allowed'
          end),
          on_text_entered = function() entered = true end,
        })
        F.session.press('return')
        assert.is_false(entered)
        assert.is_true(F.widget:has_error())
        assert.is_not_nil(love.state.user_input)
      end)

      it('LuaSyntaxValidator rejects invalid Lua', function()
        local entered = false
        local input = F.activate_project()
        input.show({
          text = 'return (',
          validator = LuaSyntaxValidator,
          on_text_entered = function() entered = true end,
        })
        F.session.press('return')
        assert.is_false(entered)
        assert.is_true(F.widget:has_error())
      end)

      it('LuaSyntaxValidator accepts Lua lines unchanged', function()
        local seen
        local input = F.activate_project()
        input.show({
          text = { 'local x = 1', 'return x' },
          validator = LuaSyntaxValidator,
          on_text_entered = function(lines) seen = lines end,
        })
        F.session.press('return')
        assert.same({ 'local x = 1', 'return x' }, seen)
      end)
  end)

  describe('cancel — the Escape chain', function()
    -- Decision 6 revised (AC1): Escape runs the
    -- cancel call-order chain (before_cancel → clear → after_cancel)
    -- and CLEARS content, but the default after_cancel is a no-op —
    -- the widget stays shown unless a callback hides it.
    it('Escape runs the cancel chain, clears, and stays shown',
      function()
        local order = { }
        local input = F.activate_project()
        input.callbacks.before_cancel = function()
          order[#order + 1] = 'before'
        end
        input.callbacks.after_cancel = function()
          order[#order + 1] = 'after'
        end
        input.show({ text = 'x' })
        F.session.press('escape')
        assert.same({ 'before', 'after' }, order)
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.widget:is_empty())
      end)

    -- doc/input_api.md, "Submit lifecycle": a truthy
    -- before_cancel VETOES the cancel outright -- the draft
    -- survives and after_cancel never runs. This is how a
    -- project guards unsaved content against a stray Escape.
    it('a truthy before_cancel vetoes the whole cancel',
      function()
        local input = F.activate_project()
        local after = false
        input.callbacks.before_cancel =
          function() return true end
        input.callbacks.after_cancel =
          function() after = true end
        input.show({ text = 'abc' })
        F.session.press('escape')
        assert.is_false(F.widget:is_empty())
        assert.is_not_nil(love.state.user_input)
        assert.is_false(after)
      end)
  end)

  describe('Enter and Escape as ordinary keys', function()
    -- doc/development/internals/user_input.md, "Submit and
    -- cancel — widget-owned callback sequences":
    -- Enter/Escape are ordinary keys while
    -- hidden — no
    -- widget submit/cancel handling engages, so project
    -- handlers can run.
    it('Enter and Escape are ordinary keys while hidden',
      function()
        local seen = { }
        local input = F.activate_project()
        input.shortcuts.keypressed['return'] = function()
          seen[#seen + 1] = 'return'; return true
        end
        input.shortcuts.keypressed['escape'] = function()
          seen[#seen + 1] = 'escape'; return true
        end
        F.session.press('return')
        F.session.press('escape')
        assert.same({ 'return', 'escape' }, seen)
      end)

    -- Decision 6 revised (AC5): Enter/Escape are
    -- ordinary chain participants — a project shortcut on 'return'
    -- runs first and consumes, so the widget's submit never fires
    -- (the withdrawn non-overridable guarantee; the gateway power
    -- keys remain the unshadowable safety net, not this).
    it('a shortcut on return shadows the widget submit',
      function()
        local shadowed = false
        local submitted = false
        local input = F.activate_project()
        input.shortcuts.keypressed['return'] = function()
          shadowed = true; return true
        end
        input.show({
          text = 'x',
          on_text_entered = function() submitted = true end,
        })
        F.session.press('return')
        assert.is_true(shadowed)
        assert.is_false(submitted)
        assert.is_not_nil(love.state.user_input)
      end)

    -- doc/development/internals/user_input.md, "Multiline input": Shift+Return
    -- is never intercepted by the route and unconditionally inserts a newline.
    -- The widget stays open; it does not submit.
    -- Drives BOTH modifier tracks the production code reads:
    -- F.session.press keeps Controller.keys_pressed (combo_
    -- string) correct, mock.keystroke's 'S' token flips the
    -- separate love.keyboard.isDown mock the widget's own
    -- Key.shift() reads (tests/mock.lua — two distinct
    -- tables).
    it('Shift+Return unconditionally adds a line without submitting',
      function()
        F.activate_project()
        F.show_widget({ text = 'a' })
        F.session.press('lshift')
        mock.keystroke('S-return', F.session.press, false)
        assert.same({ 'a', '' }, F.widget:get_text())
        assert.is_not_nil(love.state.user_input)
      end)
  end)

  describe('suppressed cancel', function()
    -- doc/development/decisions/input.md, Decision 6 ("hide() ... fires no
    -- cancel chain"): hide() and a force=true reconfigure
    -- fire no
    -- cancel chain (the user-facing dismiss is Escape only).
    it('hide() fires no cancel chain', function()
      local fired = false
      local input = F.activate_project()
      input.callbacks.before_cancel = function() fired = true end
      input.show({ text = 'x' })
      input.hide()
      assert.is_false(fired)
    end)

    it('a force=true reconfigure fires no cancel chain',
      function()
        local fired = false
        local input = F.activate_project()
        input.callbacks.before_cancel = function() fired = true end
        input.show({ text = 'first' })
        input.show({ force = true, text = 'second' })
        assert.is_false(fired)
      end)
  end)

  describe('continuity across submit', function()
    -- Decision 6 revised (AC3): the widget stays
    -- open after submit by default. A project wanting
    -- clear-and-continue does so from its own after_submit
    -- (continuity is now the default, not a re-activation trick).
    it('stays open after submit; a project clears in after_submit',
      function()
        local input = F.activate_project()
        input.callbacks.after_submit = function()
          input.clear()
        end
        input.show({ text = 'first' })
        F.session.press('return')
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.widget:is_empty())
      end)

    -- doc/input_api.md, "Submit lifecycle": closing after a
    -- submit is still available -- it is now one explicit line
    -- rather than the framework's unasked-for default. This
    -- reproduces the pre-feature prompt-once behaviour.
    it('after_submit may hide, reproducing prompt-once',
      function()
        local input = F.activate_project()
        input.callbacks.after_submit =
          function() input.hide() end
        input.show({ text = 'hello' })
        F.session.press('return')
        assert.is_nil(love.state.user_input)
      end)

    -- doc/input_api.md, "Callback assignments": widget
    -- outputs persist across a deactivation —
    -- only project stop resets them (a later chunk), not
    -- submit.
    it('on_text_entered persists across a hide/re-show cycle',
      function()
        local hits = 0
        local input = F.activate_project()
        input.show({
          text = 'a',
          on_text_entered = function() hits = hits + 1 end,
        })
        F.session.press('return')
        input.show({ text = 'b' })
        F.session.press('return')
        assert.equal(2, hits)
      end)

    -- Decision 6 revised (AC1,3): absent callbacks
    -- default to no-ops — submit and cancel both complete without
    -- error and the widget STAYS OPEN. Submit preserves content
    -- (no auto-clear); cancel clears it.
    it('submit and cancel complete with no callbacks set ' ..
      '(stays open)', function()
        F.activate_project()
        F.show_widget({ text = 'x' })
        assert.has_no.errors(function()
          F.session.press('return')
        end)
        assert.is_not_nil(love.state.user_input)
        assert.is_false(F.widget:is_empty())
        assert.has_no.errors(function()
          F.session.press('escape')
        end)
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.widget:is_empty())
      end)
  end)
end)
