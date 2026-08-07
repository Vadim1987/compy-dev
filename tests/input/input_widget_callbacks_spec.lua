-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — the widget output fields are new with
-- it, and it is what set today's submit/cancel defaults.

---> REMARK: remove copypasted irrelevant prose below
-- dispatch chain: widget outputs and submit/cancel.
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
-- Outputs half of the dispatch chain (Decision 5's four widget
-- output fields, the highlighter/on_limit_reached boundary, and the full
-- submit/cancel call-order chains of Decision 6). The mechanics half
-- (order/consume/fall-through, combo tables, signatures) is
-- input_events_spec.lua.

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')
local TU   = require('tests.testutil')

---> REMARK: artifact prose from elsewhere? distill to only relevant
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

describe('input surface: widget callbacks #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  describe('the callback fields', function()
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

  describe('navigation boundaries', function()
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
    -- A truthy before_submit VETOES the submit, the mirror of
    -- before_cancel below: nothing downstream runs and the text
    -- stays in the field, so a project can refuse a submission it
    -- is not ready for without having to undo one.
    it('a truthy before_submit vetoes the whole submit',
      function()
        local input = F.activate_project()
        local reached = { }
        input.callbacks.before_submit = function() return true end
        input.callbacks.validator = function()
          reached[#reached + 1] = 'validator'; return true
        end
        input.callbacks.after_submit = function()
          reached[#reached + 1] = 'after'
        end
        input.show({
          text = 'abc',
          on_text_entered = function()
            reached[#reached + 1] = 'entered'
          end,
        })
        F.session.press('return')
        assert.same({ }, reached)
        assert.same({ 'abc' }, F.widget:get_text())
      end)

    -- The control for the row above: a FALSEY before_submit must
    -- not veto anything. Without it, a submit broken outright
    -- would satisfy the veto assertion just as well.
    it('a falsey before_submit lets the submit through',
      function()
        local input = F.activate_project()
        local entered
        input.callbacks.before_submit = function() return nil end
        input.show({
          text = 'abc',
          on_text_entered = function(t) entered = t end,
        })
        F.session.press('return')
        assert.same({ 'abc' }, entered)
      end)

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

    -- Decision 6: submit does not auto-close. The
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
          seen.entered = F.is_widget_visible()
        end,
      })
      input.callbacks.after_submit = function()
        seen.after = F.is_widget_visible()
      end
      F.session.press('return')
      assert.is_true(seen.entered)
      assert.is_true(seen.after)
    end)

    -- The validator is a step OF the submit chain, which is why it
    -- is documented with it (doc/development/internals/user_input.md,
    -- "Submit and cancel — widget-owned callback sequences") — the
    -- section reference is not a mismatch. What this row pins is not
    -- the chain order (the first row of this group does that) but the
    -- argument: a custom validator receives the widget's live line
    -- array, not joined or stale text.
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
        assert.is_true(F.is_widget_visible())
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
        assert.is_true(F.is_widget_visible())
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
    -- Decision 6: Escape runs the
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
        assert.is_true(F.is_widget_visible())
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
        assert.is_true(F.is_widget_visible())
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

    -- Decision 6: Enter/Escape are
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
        assert.is_true(F.is_widget_visible())
      end)

    -- doc/development/internals/user_input.md, "Multiline input":
    -- what the WIDGET does with Shift+Return once the event reaches
    -- it — insert a newline unconditionally, do not submit, stay
    -- open. "Unconditionally" is the widget's own internal claim (no
    -- state of its own suppresses the newline); it says nothing about
    -- whether the event can be claimed before it arrives. It can, and
    -- the row below pins that.
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
        assert.is_true(F.is_widget_visible())
      end)

    -- The interceptability half of the row above. Shift+Return
    -- reaches the widget only because nothing upstream claimed it:
    -- it is an ordinary combo, so a project shortcut on
    -- 'shift+return' consumes it like any other key and no newline
    -- is inserted (doc/development/decisions/input.md, Decision 2 —
    -- the route holds no unshadowable keys; the gateway power keys
    -- are the only ones a project cannot reach).
    it('a shortcut on shift+return intercepts the newline',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.keypressed['shift+return'] = function()
          fired = true; return true
        end
        F.show_widget({ text = 'a' })
        F.session.press('lshift')
        mock.keystroke('S-return', F.session.press, false)
        assert.is_true(fired)
        assert.same({ 'a' }, F.widget:get_text())
      end)
  end)

  describe('hide() and force fire no cancel', function()
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

  describe('the continuous session', function()
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

    -- Decision 6: absent callbacks
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
        assert.is_true(F.is_widget_visible())
        assert.is_false(F.widget:is_empty())
        assert.has_no.errors(function()
          F.session.press('escape')
        end)
        assert.is_true(F.is_widget_visible())
        assert.is_true(F.widget:is_empty())
      end)

    -- Submit leaves the widget open, so closing is the
    -- project's to do and after_submit is where it does it.
    -- Asserted in that direction on purpose: the row that
    -- asserted the OPPOSITE — re-show from after_submit, then
    -- check the widget is shown — could not fail, because a
    -- submit no longer hides and the assertion held whether or
    -- not the callback ran at all. Proven by mutation: deleting
    -- the callback assignment left the whole file green.
    it('after_submit is what closes the widget', function()
      local input = F.activate_project()
      local seen = { }
      input.callbacks.after_submit = function() input.hide() end
      input.show({
        prompt = 'first',
        on_text_entered = function(t) seen[#seen + 1] = t end,
      })
      F.session.type('a')
      F.session.press('return')
      assert.same({ { 'a' } }, seen)
      assert.is_false(F.widget:is_shown())
      assert.is_false(F.is_widget_visible())
    end)

    -- The control the pair needs: WITHOUT a closing callback
    -- the widget stays up. Together the two rows pin the
    -- default and the override; either alone pins neither.
    it('and without it the widget stays open', function()
      local input = F.activate_project()
      input.show({ prompt = 'first' })
      F.session.type('a')
      F.session.press('return')
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
        assert.is_true(F.is_widget_visible())
        assert.is_true(F.widget:is_empty())
        F.session.type('b')
        F.session.press('return')
        assert.is_true(F.is_widget_visible())
        assert.is_true(F.widget:is_empty())
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

  ---> REMARK: dry up the prose and consider making test cases more readable and self-evident
  ---> REMARK: I'd avoid word 'overlay' fully -- can be 'project input widget'
  -- Enter and Escape mean the same thing in every input surface.
  -- A single lifecycle — `submit_flow` / `cancel_flow` in
  -- UserInputController — serves the console line, the editor's
  -- input and the project overlay alike; no widget instance reads
  -- the global screen mode to decide what a key does. Where a
  -- surface needs different behaviour it says so locally: the
  -- editor consumes Enter/Escape upstream before the widget sees
  -- them, and Ctrl+D line-duplication is a per-instance
  -- `allow_duplicate_line` flag set at construction.
  --
  -- This file is the guard against that uniformity being quietly
  -- re-conditioned on global state. Each group drives one surface
  -- through the same two keys and states what it must produce;
  -- the ones that look repetitive ARE the claim — same keys, same
  -- lifecycle, three surfaces.
  --
  -- Rationale: doc/development/decisions/input.md, Decision 6.
  -- Mechanism: doc/development/internals/user_input.md.
  --
  -- Assertions are on observable seams (widget text, fired
  -- callbacks), plus two narrow method patches where the seam IS
  -- the call itself (the console's evaluate_input call count, and
  -- model:cancel not running under the editor's Escape) — the
  -- same technique input_events_spec.lua uses for its one
  -- widget-signature row.
  describe('the same lifecycle on every route #lifecycle', function()
    -- A standalone widget, NOT the persistent/overlay — direct
    -- construction, like user_input_view_spec.lua.
    local function bare_uic()
      local m = UserInputModel(F.cfg, InputEvalText)
      local c = UserInputController(m, true)
      c:init_view({
        render = function() end,
        draw   = function() end,
      })
      return c
    end

    -- keypressed-only driver: mock.keystroke calls
    -- press(k, scancode, isrepeat); controllers here only
    -- care about k.
    local function driver(ctrl)
      return function(k) ctrl:keypressed(k) end
    end

    -- Open a plaintext doc in the REAL wired editor (F.editor),
    -- mirroring ConsoleController:edit's own app_state flip.
    local function open_doc(lines)
      love.state.app_state = 'editor'
      local save = TU.get_save_function(lines)
      F.editor:open('doc.txt', lines, save)
      return F.editor
    end

    -- ---- 1. the lifecycle ignores the screen mode ----------

    describe('a widget does not read the screen mode',
      function()
      -- The clearest statement of the rule: a plain widget,
      -- owned by nobody, behaves identically no matter what
      -- love.state.app_state happens to say. Screen mode picks
      -- which ROUTE receives an event; it never changes what
      -- the widget does with one.
      it('plain Enter submits, plain Escape cancels', function()
        local c = bare_uic()
        love.state.app_state = 'editor'
        local submitted = 0
        c:show({
          text = 'hello',
          on_text_entered = function() submitted = submitted + 1 end,
        })

        mock.keystroke('return', driver(c))
        assert.equal(1, submitted)

        mock.keystroke('escape', driver(c))
        assert.is_true(c:is_empty())
      end)
    end)

    -- ---- 2. the editor's own meaning for Escape ------------

    -- In the editor, Escape means "load the selected line into
    -- the input for editing" — the opposite of the widget's
    -- clear-the-draft cancel. The editor therefore consumes the
    -- key upstream (EditorController:_normal_mode_keys) and the
    -- widget's cancel_flow never runs; the spy on model.cancel
    -- is how that absence is observed.
    describe('editor Escape loads instead of cancelling',
      function()
      it('loads the selection and does not clear it', function()
        local doc = { 'first line', 'second line', '' }
        local ed  = open_doc(doc)
        local model = ed.input.model
        local canceled = false
        local orig_cancel = model.cancel
        model.cancel = function(...)
          canceled = true
          return orig_cancel(...)
        end

        mock.keystroke('up', driver(ed))
        mock.keystroke('escape', driver(ed))

        assert.same({ 'second line' }, ed.input:get_text():items())
        assert.is_false(canceled)
        model.cancel = orig_cancel
      end)
    end)

    -- ---- 3. the editor's own meaning for Enter -------------

    -- Same shape as Escape above: Enter (plain or with Ctrl)
    -- applies the edit to the buffer, and the editor consumes
    -- it, so the submission is delivered once — to the editor —
    -- and never a second time through the widget's
    -- on_text_entered.
    describe('editor Enter submits to the editor alone',
      function()
        it('plain Enter applies the edit, no on_text_entered',
          function()
            local doc = { '', 'body', '' }
            local ed  = open_doc(doc)
            local fired = false
            ed.input.callbacks.on_text_entered =
              function() fired = true end

            mock.keystroke('up', driver(ed))
            ed.input:add_text('replaced')
            mock.keystroke('return', driver(ed))

            assert.is_false(fired)
            assert.is_true(ed.input:is_empty())
          end)

        it('Ctrl+Enter applies the edit, no on_text_entered',
          function()
            local doc = { '', 'body', '' }
            local ed  = open_doc(doc)
            local fired = false
            ed.input.callbacks.on_text_entered =
              function() fired = true end

            ed.input:add_text('inserted')
            mock.keystroke('C-return', driver(ed))

            assert.is_false(fired)
          end)
      end)

    -- ---- 4. an Enter variant the editor does not claim -----

    -- Alt+Enter is not one of the editor's submit variants, so
    -- the editor lets it through and the widget's ordinary
    -- submit runs. Nothing happens, and nothing is supposed to:
    -- the editor assigns no on_text_entered or after_submit, so
    -- a submit with no callbacks delivers to nobody and leaves
    -- the loaded text alone — the same harmless no-op the
    -- console relies on. The row exists so an unclaimed variant
    -- can never grow into a real, unintended editor submit.
    describe('editor Alt+Enter, an unclaimed variant',
      function()
      it('submits to nobody and leaves the text alone',
        function()
          local doc = { 'first line', 'second line', '' }
          local ed  = open_doc(doc)
          mock.keystroke('up', driver(ed))
          mock.keystroke('escape', driver(ed))   -- load selection

          mock.keystroke('M-return', driver(ed))

          assert.same({ 'second line' },
            ed.input:get_text():items())
        end)
    end)

    -- ---- 5. Shift+Enter is a newline everywhere ------------

    -- Shift+Enter is carved out of submit in every surface: it
    -- inserts a line-feed and never submits, including inside
    -- the editor's input, where the surrounding Enter variants
    -- are claimed by the editor.
    describe('editor Shift+Enter on non-empty input', function()
      it('inserts a line-feed instead of submitting', function()
        local doc = { '', 'body', '' }
        local ed  = open_doc(doc)

        ed.input:add_text('abc')
        mock.keystroke('S-return', driver(ed))

        assert.same({ 'abc', '' }, ed.input:get_text():items())
      end)
    end)

    -- ---- 6. the same two keys in the other two surfaces ----

    -- The uniformity claim in its plainest form: after the
    -- editor rows above, the console and the project overlay
    -- are driven through the same Enter and Escape. Their
    -- subject-matter contracts (the full submit call-order
    -- chain, the cancel chain, validators) belong to this file's
    -- 'submit' and 'cancel — the Escape chain' groups; what is
    -- asserted here is only that each surface runs the one
    -- lifecycle at all.
    describe('console: the same Enter and Escape', function()
      it('Enter evaluates the line exactly once, text intact',
        function()
          local calls, seen = 0, nil
          local orig = F.cc.evaluate_input
          F.cc.evaluate_input = function(self, ...)
            calls = calls + 1
            seen = self.input:get_text():items()
            return orig(self, ...)
          end

          F.console:add_text('1')
          mock.keystroke('return', F.session.press)

          assert.equal(1, calls)
          assert.same({ '1' }, seen)
          F.cc.evaluate_input = orig
        end)

      it('Escape clears the console line', function()
        F.console:add_text('abc')
        mock.keystroke('escape', F.session.press)
        assert.is_true(F.console:is_empty())
      end)
    end)

    describe('project overlay: the same Enter and Escape',
      function()
      it('Enter submits, Escape cancels', function()
        local input = F.activate_project()
        local got
        input.show({
          text = 'hi',
          on_text_entered = function(t) got = t end,
        })
        F.session.press('return')
        assert.same({ 'hi' }, got)

        input.show({ text = 'bye', force = true })
        F.session.press('escape')
        assert.is_true(F.widget:is_empty())
      end)
    end)

    -- ---- 7. `modify` per-instance flag ---------------------

    -- Line-duplication is the one behaviour that genuinely
    -- differs between surfaces, and it is carried by a
    -- constructor flag on the instance that wants it —
    -- `allow_duplicate_line`, alongside `disable_selection` — not by
    -- the screen mode. Each case still sets app_state, to the
    -- value the real caller would have, precisely to show the
    -- flag and not the mode is what decides
    -- (doc/development/decisions/input.md, Decision 6).
    describe('the modify flag alone gates Ctrl+D', function()
      it('with the flag: Ctrl+D duplicates the line', function()
        local c = bare_uic()
        c.allow_duplicate_line = true
        love.state.app_state = 'editor'
        c:show({ text = 'abc' })

        mock.keystroke('C-d', driver(c))

        assert.same({ 'abc', 'abc' }, c:get_text():items())
      end)

      it('without it: Ctrl+D does nothing', function()
        local c = bare_uic()
        c.allow_duplicate_line = false
        love.state.app_state = 'ready'
        c:show({ text = 'abc' })

        mock.keystroke('C-d', driver(c))

        assert.same({ 'abc' }, c:get_text():items())
      end)
    end)

    -- ---- 8. how wide "Enter" is -----------------------------

    -- Submit triggers on any Enter that is not Shift+Enter, so
    -- Ctrl+Enter and Alt+Enter submit as well; only the newline
    -- is carved out (doc/development/decisions/input.md,
    -- Decision 6 and Decision 14; mechanism in
    -- doc/development/internals/user_input.md). It is
    -- longstanding behaviour the input API kept, pinned here so
    -- the breadth is not narrowed to bare Enter by accident —
    -- narrowing it is a deliberate spec change, not a tidy-up.
    describe('every non-Shift Enter submits', function()
        it('overlay: Ctrl+Enter submits', function()
          local input = F.activate_project()
          local got
          input.show({
            text = 'hi',
            on_text_entered = function(t) got = t end,
          })
          mock.keystroke('C-return', F.session.press)
          assert.same({ 'hi' }, got)
        end)

        it('overlay: Alt+Enter submits', function()
          local input = F.activate_project()
          local got
          input.show({
            text = 'hi',
            on_text_entered = function(t) got = t end,
          })
          mock.keystroke('M-return', F.session.press)
          assert.same({ 'hi' }, got)
        end)

        it('console: Ctrl+Enter evaluates', function()
          local calls = 0
          local orig = F.cc.evaluate_input
          F.cc.evaluate_input = function(self, ...)
            calls = calls + 1
            return orig(self, ...)
          end

          F.console:add_text('x')
          mock.keystroke('C-return', F.session.press)

          assert.equal(1, calls)
          F.cc.evaluate_input = orig
        end)
      end)
  end)
end)
