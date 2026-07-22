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
  -- REVIEW/quality: better allow random chords -- (...) and iterating over it? cheap and more flexible
  local function chord(mod, k)
    F.session.press(mod)
    F.session.press(k)
  end

  -- doc/development/decisions/input.md, Decision 2.

  describe('order, consume, fall-through', function()
    -- REVIEW/fidelity/consistence: group tests only against specific event type -- keypressed. Should rather be generalized (dynamically constructed) to test against all relevant even types (keyreleased, textinput)?

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
    -- REVIEW/clarity: I would use same chain with mnemonic flags as in previous case -- and probably matrix test to show interception on every step, and also that lack of step (no combo defined, no hook defined) does not prevent other parts from working
    -- REVIEW/clarity: do we have the symmetric test 'truthy hook return value prevents reaching widget'? and symmetric tests for '*missing* handler does not prevent reaching hook, missing hook does not prevent reaching widget'?
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

    -- doc/development/decisions/input.md, Decision 2: assigning a generic
    -- callback replaces
    -- ONLY it; when
    -- it returns falsey the widget still runs for that event.
    -- REVIEW/clarity/consistence: this test is redundant -- the whole need raised from reversing misinterpreted requirements -- test can safely go, it repeats one particular configuration tested above
    it('assigning a callback replaces only it; widget still runs',
      function()
        local input = F.activate_project()
        F.show_widget({ text = 'ab' })
        input.hooks.keypressed = function() return false end
        F.session.press('backspace')
        assert.same({ 'a' }, F.widget:get_text())
      end)
  end)

  -- REVIEW/clarity: maybe wrap three cases below into sub-describe
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

    -- REVIEW/fidelity: we'd rather should test that setting combo on one event does not alter propagation of other events, and same with hooks. on the other hand, this test does smoke-check in most economic way. but still testing internals is smelly!
    -- doc/development/decisions/input.md, Decision 8: the three tables
    -- are distinct; a keypressed
    -- combo does not leak into the textinput channel.
    it('the combo tables are per-event, not one flat table',
      function()
        local input = F.activate_project()
        assert.is_table(input.shortcuts.keypressed)
        assert.is_table(input.shortcuts.keyreleased)
        assert.is_table(input.shortcuts.textinput)
        local leaked = false
        input.shortcuts.keypressed['s'] =
            function() leaked = true; return true end
        F.session.type('s')
        assert.is_false(leaked)
      end)
  end)

  -- REVIEW/clarity: I'd rather wrap in 'describe'
  -- ---- signatures + read-only proxy
  -- (doc/development/decisions/input.md, Decision 9 and Decision 13) ---

  describe('signatures and the read-only proxy', function()
    -- REVIEW/fidelity: no test in the group checks the contents of keypressed table (if its checked in another suit, maybe replace this comment with reference)
    -- REVIEW: why not test whole chain instead? configure all parts to be passthrough/nonconsuming (registering args and returning false), than check that every step registered the triade? 
    -- doc/development/decisions/input.md, Decision 9: keypressed
    -- participants receive
    -- (k, proxy,
    -- isrepeat); isrepeat threads through to {jargon: tier 3}.
    it('keypressed carries (k, keys_pressed, isrepeat)',
      function()
        local seen
        local input = F.activate_project()
        input.hooks.keypressed = function(k, keys, isr)
          seen = { k, keys, isr }; return true
        end
        F.session.repeat_press('a')
        -- REVIEW/fidelity: only type signature is tested but not what is really delivered -- so its not a test of contract, only of its type-compliance
        assert.equal('a', seen[1])
        assert.is_table(seen[2])
        assert.is_true(seen[3])
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

    -- REVIEW/clarity/consistency/fidelity: Should instead be something like "describe('pressed keys table') -> it('contains pressed keys') , it('does not contain released keys'), it('can not be modified from hook or handler'))" and multiply it by evet type?
    -- doc/development/decisions/input.md, Decision 13: the keys_pressed
    -- argument is read-only — reads pass through, writes raise.
    it('keys_pressed can be read but not modified', function()
      local proxy
      local input = F.activate_project()
      input.hooks.keypressed = function(_, keys)
        proxy = keys; return true
      end
      F.session.press('a')
      assert.is_table(proxy)
      assert.is_true(proxy['a'])
      assert.has_error(function() proxy['x'] = true end)
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

    -- REVIEW/consistency: this test checks the delivery of keys_pressed table -- should not it live alongside the test which checks the contents of passed table (symmetry: key present on keypressed (and tetnput ?), released on keyreleased)
    -- doc/development/internals/user_input.md, "Key release": a keyreleased
    -- participant sees the
    -- key ALREADY gone
    -- from the held set (removed at the {jargon: gateway}
    -- before dispatch).
    it('a keyreleased participant sees the key already gone',
      function()
        local present = true
        local input = F.activate_project()
        input.hooks.keyreleased = function(k, keys)
          present = keys[k]; return true
        end
        F.session.press('a')
        F.session.release('a')
        assert.is_nil(present)
      end)
  end)

  -- defaults + hidden widget (doc/development/decisions/input.md,
  -- Decision 10 and Decision 2)

  describe('defaults and the hidden widget', function()
    -- REVIEW/fidelity/consistency: test against all non-defined participants? (both handler and hook -- disabled altogether or one-by-one -- I think already described somewhere above... symmetry feels off there

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

    -- REVIEW/fidelity/consistency: only 'on_text_input' hook is tested, what about 'on_key_pressed'?
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
    -- REVIEW/consistency: any hook not only a promoted project handler should fire regardless of widget status (and widget absence can have two forms: never was 'shown', or was 'shown than hidden')
    -- REVIEW/clarity: make it clear that a project handler always behaves like a hook -- so the match in behaviour is not occasional. Maybe reuse shared tests suite (if busted supports it)
    it('a project handler fires whether or not the widget is shown',
      function()
        local seen = 0
        F.activate_project({
          keypressed = function() seen = seen + 1 end,
        })
        F.session.press('a')
        F.show_widget()
        F.session.press('a')
        assert.equal(2, seen)
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

    -- REVIEW/clarity: unite with the first test in this group, and remove references from 'downstream bucket D' from the prose. We simply test that hook fires whether widget is shown or hidden or never shown. Its a wortful test which would normally belong to both variants (hook installed via input API, and hook installed from legacy sandboxed love.* equivalent). See remark abouve about reusing tests group. Amd once again -- the test itself is worthful, and belongs to dispatching chain. The reason: it checks that downstream dispatching chain members (or just last one -- widget) do not block upstream consumption
    -- doc/development/decisions/input.md, Decision 10, project-handler
    -- path, keyreleased
    -- channel: fires regardless
    -- of widget-shown state (case a) — the downstream half of
    -- the retired Bucket-D (doc/development/tests.md,
    -- "Input Contract Suite (feature #77)") 'release under a
    -- widget' row.
    it('a handler keyreleased fires while the widget is shown',
      function()
        local seen = 0
        F.activate_project({
          keyreleased = function() seen = seen + 1 end,
        })
        F.show_widget()
        F.session.release('a')
        assert.equal(1, seen)
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
	-- REVIEW/fidelity/consistency: is 'activate_project' installing hooks via legacy path? (as love.*) are other tests (in the beginning of this suite) also testing this path and theerfore NOT testing input.on_ path (explicit hook configuration). What do we do with it?
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
