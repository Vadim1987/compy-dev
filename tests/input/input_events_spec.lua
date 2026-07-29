-- Availability: feature-new — the dispatch chain, the per-event
-- hooks and the project-handler install path are introduced by this
-- feature (since 1.0.0-rc20260712); none exist in the baseline.

-- REVIEW/fidelity: any occurence of 'singleton' in any file triggers fidelity check on the appropriate case -- is there alternative 'official' method of configuration/invocation? if access to singleton happens because we need to mock or trigger its internal methods which normally would not be accessible (boundary tests), can we wrap it into clearly test-specific function (i.e. F.mock_widget). 

-- dispatch chain: tier mechanics 
-- {historical: split from input_contracts_spec.lua (TF1)}.
--
-- Routing invariant (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route, fixed by
-- the active screen mode. Vocabulary (doc/development/internals/user_input.md, "Dispatch
-- chain"): ROUTE = the controller an event is dispatched to; WIDGET =
-- the route-managed input surface and terminal of the chain. 
-- 
-- Tests assert
-- observable outcomes at public seams, never method-name spies.
--
-- keypressed fires for every physical key, textinput only for
-- character-producing keys (doc/development/internals/user_input.md, "Data flow").
--
-- This file covers the dispatch-chain MECHANICS: order/consume/fall-through,
-- combo tables, signatures, defaults, hook and handler install, the
-- mutable/immutable boundary (doc/development/decisions/input.md, Decision 2).
-- Widget OUTPUTS (submit/cancel) live in input_widget_callbacks_spec.lua. These
-- are two of the suite's nine thematic files (TF1 split by topic — not a
-- two-way mechanics/outputs cut).

local F = require('tests.helpers.input_fixture')

-- All rows drive the REAL project route: F.activate_project() installs the
-- ProjectInputController as the active route (app_state='running') via the
-- production Controller.set_user_handlers path, and returns the project-facing
-- compy.input surface. Assertions read the widget's text and the callbacks a
-- project registers — except the one widget-signature row, which patches the
-- shared widget and restores it.

describe('#input events dispatching', function()


  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)


  -- Press a modifier then a trigger so the combo serialises to 'ctrl+…' — a real chord
  -- (doc/development/decisions/input.md, Decision 8).
  local function chord(mod, k)
    F.session.press(mod)
    F.session.press(k)
  end

  -- doc/development/decisions/input.md, Decision 2.

  describe('order, consume, fall-through', function()
    -- Walked on the keypressed channel only, deliberately. The walk
    -- is ONE channel-agnostic function in production —
    -- `dispatch(shortcuts, hooks, widget, event, trigger, ...)` in
    -- projectInputController.lua indexes `shortcuts[event]` and
    -- `hooks[event]` and is otherwise identical per channel — so
    -- re-running the order/consume rows for keyreleased and textinput
    -- would re-prove the same function three times. That the three
    -- channels each REACH the walk is proven separately, per channel,
    -- in the combo group below.

    -- doc/development/decisions/input.md, Decision 2 revised: the dumb
    -- walk stops at the first consumer. A shortcut returning
    -- truthy consumes — the hook and widget below never run.
    it('a shortcut consumes before the hook and widget',
      function()
        local reached_hook = false
        local input = F.activate_project()
        input.shortcuts.keypressed['a'] =
            function() return true end
        input.hooks.keypressed =
            function() reached_hook = true; return true end
        F.show_widget({ text = 'b' })
        F.session.press('a')
        assert.is_false(reached_hook)
      end)

    -- doc/development/decisions/input.md, Decision 2 revised: an
    -- unconsumed event walks shortcut → hook → widget in order;
    -- falsy consumers fall through, and the shown widget is the
    -- terminal consumer (backspace edits it — the observable trace).
    it('an unconsumed event walks shortcut, hook, then widget',
      function()
        local order = { }
        local input = F.activate_project()
        input.shortcuts.keypressed['backspace'] =
            function() order[#order + 1] = 'shortcut' end
        input.hooks.keypressed =
            function() order[#order + 1] = 'hook' end
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'shortcut', 'hook' }, order)
        assert.same({ 'a' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 2: a truthy combo
    -- handler ({jargon: tier 2}) stops the descent —
    -- neither the hook nor the widget runs.
    it('a shortcut returning truthy stops the chain (hook not reached)', function()
      local reached_cb = false
      local input = F.activate_project()
      input.shortcuts.keypressed['backspace'] =
          function() return true end
      input.hooks.keypressed =
          function() reached_cb = true; return true end
      F.show_widget({ text = 'ab' })
      F.session.press('backspace')
      assert.is_false(reached_cb)
      assert.same({ 'ab' }, F.widget:get_text())
    end)

    -- doc/development/decisions/input.md, Decision 2: consuming never
    -- removes a {jargon:
    -- tier} — the same callback
    -- fires again on the next event (configuration is permanent).
    it('is a permanent configuration', function()
      local n = 0
      local input = F.activate_project()
      input.hooks.keypressed =
          function() n = n + 1; return true end
      F.session.press('a')
      F.session.press('a')
      assert.equal(2, n)
    end)

  end)

  -- doc/development/decisions/input.md, Decision 2: the interception
  -- matrix. Two things at once — each participant intercepts for
  -- itself only (a consumer stops the walk exactly where it sits), and
  -- a MISSING participant is not a barrier: the walk skips it and the
  -- ones below still run. Rows configure (shortcut, hook) as
  -- pass-through or consuming, or leave them undefined; `seen` is the
  -- mnemonic trace and the widget's text is the observable terminal
  -- (backspace edits 'ab' -> 'a' exactly when the widget runs).
  describe('the interception matrix', function()

    local CONSUME, PASS = 'consume', 'pass'

    local rows = {
      { name = 'no participant defined: the widget still runs',
        widget_runs = true, expect = { } },
      { name = 'both pass through: shortcut, hook, then the widget',
        shortcut = PASS, hook = PASS,
        widget_runs = true, expect = { 'shortcut', 'hook' } },
      { name = 'a consuming shortcut stops the walk at itself',
        shortcut = CONSUME, hook = PASS,
        widget_runs = false, expect = { 'shortcut' } },
      { name = 'a consuming hook stops the walk before the widget',
        shortcut = PASS, hook = CONSUME,
        widget_runs = false, expect = { 'shortcut', 'hook' } },
      { name = 'a missing shortcut does not stop a consuming hook',
        hook = CONSUME,
        widget_runs = false, expect = { 'hook' } },
      { name = 'a missing shortcut does not stop the widget',
        hook = PASS,
        widget_runs = true, expect = { 'hook' } },
      { name = 'a missing hook does not stop the widget',
        shortcut = PASS,
        widget_runs = true, expect = { 'shortcut' } },
    }

    -- records itself in `seen`, then consumes iff mode is CONSUME
    local function participant(seen, who, mode)
      return function()
        seen[#seen + 1] = who
        return mode == CONSUME
      end
    end

    local function configure(input, row, seen)
      if row.shortcut then
        input.shortcuts.keypressed['backspace'] =
            participant(seen, 'shortcut', row.shortcut)
      end
      if row.hook then
        input.hooks.keypressed =
            participant(seen, 'hook', row.hook)
      end
    end

    for _, row in ipairs(rows) do
      it(row.name, function()
        local seen = { }
        configure(F.activate_project(), row, seen)
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same(row.expect, seen)
        assert.same({ row.widget_runs and 'a' or 'ab' },
          F.widget:get_text())
      end)
    end
  end)

  -- doc/development/decisions/input.md, Decision 8.
  describe('shortcuts fire on the normalised combo', function()
    -- doc/development/decisions/input.md, Decision 8: each channel has its
    -- OWN combo sub-table
    -- and keys normalise on assignment ('Ctrl+S' -> 'ctrl+s').
    it('a keypressed combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.keypressed['Ctrl+S'] =
            function() fired = true; return true end
        chord('lctrl', 's')
        assert.is_true(fired)
      end)

    it('a textinput combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.textinput['Ctrl+S'] =
            function() fired = true; return true end
        F.session.press('lctrl')
        F.session.type('s')
        assert.is_true(fired)
      end)

    it('a keyreleased combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.shortcuts.keyreleased['Ctrl+S'] =
            function() fired = true; return true end
        chord('lctrl', 's')
        F.session.release('s')
        assert.is_true(fired)
      end)

    -- doc/development/decisions/input.md, Decision 8: the per-event
    -- tables are distinct — asserted by BEHAVIOUR (a registration on
    -- one channel does not fire on another) rather than by reading
    -- the table structure, which was the smell the previous form had.
    it('a keypressed combo does not fire on textinput',
      function()
        local leaked = false
        local input = F.activate_project()
        input.shortcuts.keypressed['s'] =
            function() leaked = true; return true end
        F.session.type('s')
        assert.is_false(leaked)
      end)

    -- The hook half of the same claim: hooks are per-event too, so a
    -- keypressed hook must not see a textinput event.
    it('a keypressed hook does not fire on textinput', function()
      local leaked = false
      local input = F.activate_project()
      input.hooks.keypressed =
          function() leaked = true; return true end
      F.session.type('s')
      assert.is_false(leaked)
    end)
  end)

  -- ---- signatures + read-only proxy
  -- (doc/development/decisions/input.md, Decision 9 and Decision 13) ---

  describe('signatures and the read-only proxy', function()
    -- The table's CONTENTS are asserted in this file's
    -- 'the pressed-keys table' group below (what it holds after a
    -- press, what it no longer holds after a release, and that a
    -- participant cannot write to it); this group covers the
    -- signature the participants are called with.
    -- doc/development/decisions/input.md, Decision 9: keypressed
    -- participants receive (k, proxy, isrepeat). Asserted over the
    -- WHOLE chain, not one participant: every step is configured
    -- pass-through (records its triple, returns false), so the event
    -- walks shortcut -> hook -> widget and each step is checked for
    -- what was actually DELIVERED — the key itself, a proxy that
    -- really reports the held key, and the true isrepeat flag — not
    -- merely for type compliance.
    it('every step of the chain receives the same delivered triple',
      function()
        local seen  = { }
        local input = F.activate_project()
        local step  = function(who)
          return function(k, keys, isr)
            seen[who] = { k, keys['a'], isr }
          end
        end
        input.shortcuts.keypressed['a'] = step('shortcut')
        input.hooks.keypressed         = step('hook')
        F.session.repeat_press('a')
        assert.same({ 'a', true, true }, seen.shortcut)
        assert.same({ 'a', true, true }, seen.hook)
      end)

    -- doc/development/decisions/input.md, Decision 9: isrepeat is false on
    -- a fresh press, true on repeat.
    it('isrepeat threads to the hook', function()
      local seen = { }
      local input = F.activate_project()
      input.hooks.keypressed = function(_, _, isr)
        seen[#seen + 1] = isr; return true
      end
      F.session.press('a')
      F.session.repeat_press('a')
      assert.same({ false, true }, seen)
    end)

    -- The held-key table as a participant sees it: what it contains,
    -- what it no longer contains, and that it cannot be written to
    -- (doc/development/decisions/input.md, Decision 13;
    -- doc/development/internals/user_input.md, "Key release").
    describe('the pressed-keys table', function()

      it('contains the pressed key', function()
        local proxy
        local input = F.activate_project()
        input.hooks.keypressed = function(_, keys)
          proxy = keys; return true
        end
        F.session.press('a')
        assert.is_table(proxy)
        assert.is_true(proxy['a'])
      end)

      -- the key is removed at the gateway BEFORE dispatch, so a
      -- keyreleased participant never sees it still held.
      it('no longer contains a released key', function()
        local present = true
        local input = F.activate_project()
        input.hooks.keyreleased = function(k, keys)
          present = keys[k]; return true
        end
        F.session.press('a')
        F.session.release('a')
        assert.is_nil(present)
      end)

      it('cannot be modified from a hook', function()
        local proxy
        local input = F.activate_project()
        input.hooks.keypressed = function(_, keys)
          proxy = keys; return true
        end
        F.session.press('a')
        assert.has_error(function() proxy['x'] = true end)
      end)
    end)

    -- doc/development/decisions/input.md, Decision 9: the WIDGET is included
    -- in the uniform
    -- signature — it
    -- receives the same (k, proxy, isrepeat) triple. Patches the
    -- shared widget method, restored after the assertion.
    it('the widget receives the uniform keypressed triple',
      function()
        local seen
        F.activate_project()
        F.show_widget()
	-- REVIEW/fidelity: are we testing internals there instead of behavior? in this case its justified if we cannot configure widget from the outside but need to ensure it received keypress -- but then maybe explicitly admit that this is test-specific patching. Maybe expose method like F.mock_widget_with(...) so that purpose will be clear, especially given the fact same mechanics is used in few other places. Right now it looks like legit configuration, which it is not (or is it?)
        F.widget.keypressed = function(_, k, keys, isr)
          seen = { k, keys, isr }
        end
        F.session.repeat_press('a')
	-- REVIEW: why set to nil here?
        F.widget.keypressed = nil
        assert.equal('a', seen[1])
        assert.is_table(seen[2])
        assert.is_true(seen[3])
      end)

  end)

  -- defaults + hidden widget (doc/development/decisions/input.md,
  -- Decision 10 and Decision 2)

  describe('defaults and the hidden widget', function()
    -- The non-defined-participant permutations the symmetry calls
    -- for (none defined, shortcut missing, hook missing) are the
    -- missing-participant rows of the interception matrix above; this
    -- group covers what the DEFAULTS do once the event arrives.

    -- doc/development/decisions/input.md, Decision 10: the default hook neither
    -- edits nor
    -- consumes — the event falls through to the widget, which
    -- performs the edit.
    it('with no project hook set, the event passes through to the widget',
      function()
        F.activate_project()
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'a' }, F.widget:get_text())
      end)

    -- REVIEW/concern: "mutates nothing" may conflict with the
    -- postponed console-hidden-sink decision (collapse-gate ledger
    -- G-1 / D3) — if the console is ruled to listen to all or to
    -- unconsumed events, this expectation changes. Revalidate at G-1.
    -- doc/development/decisions/input.md, Decision 2: an event with no
    -- participant anywhere, and a hidden widget, mutates nothing — a no-op.
    it('no participant + hidden widget mutates nothing',
      function()
        F.activate_project()
        F.show_widget({ text = 'keep' })
        F.widget:hide()
        F.session.press('backspace')
        assert.same({ 'keep' }, F.widget:get_text())
      end)
  end)

  -- ---- the per-event hook
  -- (doc/development/decisions/input.md, Decision 5 and Decision 10) ---

  describe('the per-event hook', function()

    -- The keypressed counterpart is not missing, it is upstream: the
    -- interception matrix and the delivered-triple row both drive
    -- hooks.keypressed. What is specific to textinput, and is why
    -- this row exists, is the PER-CHARACTER cadence.
    -- doc/development/decisions/input.md, Decision 5: the textinput hook
    -- fires PER-CHARACTER (distinct from the submit output on_text_entered,
    -- which is the pending row above).
    it('the textinput hook fires per character as text arrives',
      function()
        local got = { }
        local input = F.activate_project()
        input.hooks.textinput = function(t)
          got[#got + 1] = t; return true
        end
        F.session.type('a')
        F.session.type('b')
        assert.same({ 'a', 'b' }, got)
      end)

    -- doc/development/decisions/input.md, Decision 10 (on_* install path):
    -- a truthy callback intercepts
    -- the widget; a present-but-falsey callback falls through.
    it('a truthy textinput hook intercepts; falsey reaches the widget',
      function()
        local input = F.activate_project()
        F.show_widget()
        input.hooks.textinput = function() return true end
        F.session.type('X')
	-- REVIEW/fidelity: why would we check sigleton internals instead of compy.input. method ? (official behaviour)
        assert.is_true(F.widget:is_empty())
        input.hooks.textinput = function() return false end
        F.session.type('Y')
        assert.same({ 'Y' }, F.widget:get_text())
      end)
  end)

  -- ---- the project-handler install path
  -- (doc/development/decisions/input.md, Decision 10) -----

  describe('the project-handler install path', function()
    -- doc/development/decisions/input.md, Decision 10: a project
    -- handler is a plain hook
    -- participant that fires REGARDLESS of widget-shown state
    -- (the reversed suppress-while-shown mutation is gone).
    -- REVIEW/clarity: make it clear that a project handler always behaves like a hook -- so the match in behaviour is not occasional. Maybe reuse shared tests suite (if busted supports it)
    -- Fires in all THREE widget states — never shown, shown, and
    -- shown-then-hidden (widget absence has two distinct forms) — on
    -- both the keypressed and keyreleased channels: a downstream
    -- chain member never blocks upstream consumption. A handler is
    -- seeded into hooks[event], so this is the hook contract, not a
    -- handler-only one (seed_hooks, projectInputController.lua).
    it('a project handler fires whether or not the widget is shown',
      function()
        local seen = { pressed = 0, released = 0 }
        F.activate_project({
          keypressed  = function()
            seen.pressed = seen.pressed + 1
          end,
          keyreleased = function()
            seen.released = seen.released + 1
          end,
        })
        F.session.press('a')
        F.session.release('a')
        F.show_widget()
        F.session.press('a')
        F.session.release('a')
        F.widget:hide()
        F.session.press('a')
        F.session.release('a')
        assert.same({ pressed = 3, released = 3 }, seen)
      end)

    -- doc/development/decisions/input.md, Decision 10, project-handler
    -- path: a truthy handler intercepts the widget.
    it('a handler returning truthy intercepts the widget',
      function()
        F.activate_project({
          keypressed = function() return true end,
        })
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'ab' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 10, project-handler
    -- path: a falsey handler falls through to
    -- the widget (asserted on the textinput channel too, so all
    -- three channels are covered across the handler
    -- rows).
    it('a falsey handler textinput falls through to the widget',
      function()
        F.activate_project({
          textinput = function() return false end,
        })
        F.show_widget()
        F.session.type('Z')
        assert.same({ 'Z' }, F.widget:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 10 precedence:
    -- an explicit hook takes
    -- precedence over the captured handler — the
    -- handler never
    -- seeds the hook when an explicit hook is set (no
    -- "replace" relation).
    it('an explicit hook takes precedence over the handler',
      function()
        local handler_hits, cb_hits = 0, 0
        local function bump() handler_hits = handler_hits + 1 end
    -- Audited: BOTH paths are exercised in this file, not one.
    -- F.activate_project({ keypressed = f }) is the legacy path — f
    -- is the project's sandboxed love.keypressed, seeded into
    -- hooks[event] once at activation (seed_hooks,
    -- projectInputController.lua) — while every row that assigns
    -- input.hooks.<event> directly (the interception matrix, the
    -- delivered-triple row, the textinput rows) drives the explicit
    -- path. This row is the one that pins how they INTERACT.
        local input = F.activate_project({ keypressed = bump })
        input.hooks.keypressed =
            function() cb_hits = cb_hits + 1; return true end
        F.session.press('a')
        assert.equal(1, cb_hits)
        assert.equal(0, handler_hits)
      end)
  end)

  -- REVIEW/consistency/architecture: after we pivoted to .hooks[event] (from .on_{event}), is this whole test still needed at all? (resolve in D4)
  -- ---- the mutable/immutable boundary
  -- (doc/development/decisions/input.md, Decision 7)
  -- -------------

  describe('the mutable/immutable boundary', function()
    -- doc/development/decisions/input.md, Decision 7: exactly the
    -- the hook fields are assignable;
    -- anything else raises loudly (never a silent swallow).
    it('assigning an unknown key raises', function()
      local input = F.compy_input()
      assert.has_error(function() input.nonsense = 1 end)
      assert.has_error(function()
        input.show = function() end
      end)
      assert.has_error(function() input.shortcuts = { } end)
    end)

    it('assigning an allowed hook is accepted',
      function()
        local input = F.compy_input()
        assert.has_no.errors(function()
          input.hooks.keypressed  = function() end
          input.hooks.textinput   = function() end
          input.hooks.keyreleased = function() end
        end)
      end)
  end)
end)
