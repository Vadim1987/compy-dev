-- REVIEW/fidelity: any occurence of 'singleton' in any file triggers fidelity check on the appropriate case -- is there alternative 'official' method of configuration/invocation? if access to singleton happens because we need to mock or trigger its internal methods which normally would not be accessible (boundary tests), can we wrap it into clearly test-specific function (i.e. F.mock_widget). 
-- REVIEW/clarity/design/terminology: I suggest following global renaming: 'singleton'->'widget', 'sink' -> 'widget', 'tier-3/tier3' -> '[project] hook[s]', 'framework handlers' -> 'global/framework handlers' (if they capture combo) or 'framework/global] shortcuts' ( if they always address only two specific keys ESC/Enter and are not configurable for generic combos handling ) , 'handlers'->'[project] handler[s]' (those which bind to key combos), '.on_{eventname}' -> 'hooks[eventname]', 'generic callbacks' -> '[project] hook[s]', How to name the 'love' hooks that project installs (legacy) as love.handlers and which are converted to 'hooks' -- its an open question. Maybe literally "project's [sandboxed] love.* hook(s)'? suggestions are welcome. PRINCIPLE: I'd reserve word 'handlers' for combo-bound things, 'callbacks' -- for something that is called by trigger, 'hooks' -- to something that is injected in the middle of event processing and can intercept/modify it. 'routing' may remain 'routing' and rely strictly to selection of dispatcher(controller).

-- dispatch chain: tier mechanics 
-- {historical: split from input_contracts_spec.lua (TF1)}.
--
-- REVIEW/clarity: prose below calls both ROUTE and SINK 'consumers' which may lead to confusion: afaik 'route' is in fact controller, while 'sink' is the name for the last item in the processing chain the route enforces
-- Routing invariant (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route, fixed by
-- the active screen mode. Vocabulary (doc/development/internals/user_input.md, "Dispatch
-- chain"): ROUTE = consumer an event is dispatched to; WIDGET = a
-- route-managed input surface; SINK = last consumer. 
-- 
-- Tests assert
-- observable outcomes at public seams, never method-name spies.
--
-- keypressed fires for every physical key, textinput only for
-- character-producing keys (doc/development/internals/user_input.md, "Data flow").
--
-- REVIEW/clarity: language of the prose below is broken -- it tries to say that this test covers only half of the activities but fails to say so (and its alwo not clear why we have 9 input files not just 2 spolier: because its not 'half-this/half-that' split)
-- Mechanics half of the four-tier dispatch chain (order/consume/
-- fall-through, combo tables, signatures, defaults, tier-3 callbacks and
-- native install, the mutable/immutable boundary) — doc/development/decisions/input.md,
-- Decision 2. The outputs half (widget outputs, submit/cancel) is
-- input_widget_callbacks_spec.lua.

local F = require('tests.helpers.input_fixture')

--- REVIEW/clarity: need to cleanup jargon, also the prose below partialy duplicates opening prose
--- REVIEW/clarity: prose below speaks of callbacks but we have also output callbacks -- maybe we should instead use term 'hooks' to describe what is installed by project into dispatch chain
-- ====================================================
-- The four-tier dispatch chain 
-- (doc/development/decisions/input.md, Decision 2).
-- All rows drive the REAL project route: F.activate_
-- project() installs the ProjectInputController as the
-- {jargon: slot occupant} (app_state='running') via the same
-- Controller.set_user_handlers path {clarity: a run calls}, and
-- returns the project-facing compy.input surface. The
-- observable {jargon: seams} are the widget's text ({jargon: the sink})
-- and
-- the callbacks a project registers — never a spy on an
-- internal method (except the one sink-signature row,
-- which patches the shared singleton and restores it).
-- ====================================================

describe('#input events dispatching', function()


  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)


  -- REVIEW/fidelity: comment overexplains mechanics that helper does not control; first line would be enough
  -- Press a modifier key then a trigger so the held set
  -- (Controller.keys_pressed) carries the modifier and the
  -- combo serialises to 'ctrl+…' (doc/development/decisions/input.md,
  -- Decision 8) — a real chord.
  -- REVIEW/quality: better allow random chords -- (...) and iterating over it? cheap and more flexible
  local function chord(mod, k)
    F.session.press(mod)
    F.session.press(k)
  end

  -- REVIEW/clarity: the prose below is correct but uncomprehensible, looks like noise
  -- ---- order, consume, fall-through
  -- (doc/development/decisions/input.md, Decision 2) --

  describe('order, consume, fall-through', function()
    -- REVIEW/fidelity/consistence: group tests only against specific event type -- keypressed. Should rather be generalized (dynamically constructed) to test against all relevant even types (keyreleased, textinput)?

    -- doc/development/decisions/input.md, Decision 2: a {jargon: tier-1}
    -- framework handler runs first and,
    -- returning truthy, consumes — no lower {jargon: tier} sees
    -- the event.
    -- REVIEW/clarity: internal jargon in it description -- i'd rather "framework hooks intercepts before project handlers, hooks, and widget"
    -- REVIEW/clarity: my suggested alternative vocabulary -- dispatch chain consists of 'handlers'(event-bound x combo-bound) and 'hooks'(event-bound -- act if handlers did not intercept), with framework, project and widget, installing their own hooks, widget hooks always being the last in current architecture
    -- REVIEW/architecture: the very need of framewrk hooks is disputable and should be reviewed after tests stabilization -- maybe they should be demoted to intra-widget logic
    it('a framework handler consumes before lower tiers',
      -- REVIEW/fidelity/clarity: a) 'lower' is confusing, use 'canary' or just 'x' -- set to nil initially, check if it was true or false b) mark framework handler as 'test-specific patching' while `input.on_key_pressed = ` as official way of configuring project hook c) why not test on real-life 'enter' and 'cancel' -- demonstrating they do not reach proect hook IF the whole 'do not reach' decision would be confirmed in architectural review?
      function()
        local lower = false
        local input = F.activate_project()
        Controller.project_input
          .framework_handlers.keypressed['a'] =
            function() return true end
        input.on_key_pressed =
            function() lower = true; return true end
        F.session.press('a')
        assert.is_false(lower)
      end)

    -- doc/development/decisions/input.md, Decision 2: an unconsumed event
    -- descends every
    -- {jargon: tier} IN ORDER and reaches the {jargon: sink} (backspace
    -- edits the
    -- shown widget — the sink's observable trace).
    it('an unconsumed event descends every tier to the sink',
      function()
        local order = { }
        local fw = Controller.project_input.framework_handlers
        local input = F.activate_project()
        fw.keypressed['backspace'] =
            function() order[#order + 1] = 'framework_handler' end
        input.handlers.keypressed['backspace'] =
            function() order[#order + 1] = 'project_handler' end
        input.on_key_pressed =
            function() order[#order + 1] = 'project_hook' end
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'framework_handler', 'project_handler', 'project_hook' }, order)
        assert.same({ 'a' }, F.singleton:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 2: a truthy combo
    -- handler ({jargon: tier 2}) stops the descent —
    -- neither the generic callback nor the sink runs.
    -- REVIEW/clarity: I would use same chain with mnemonic flags as in previous case -- and probably matrix test to show interception on every step, and also that lack of step (no combo defined, no hook defined) does not prevent other parts from working
    -- REVIEW/clarity: I'd double-check the 'it' description -- 'truthy handler' means handler is truthy when its function (not false or nil value). we're speaking about *return value* instead. also 'decent' describes mechanics maybe and instead we should use 'stops processing', or 'prevents reaching hook' (and testboth). 
    -- REVIEW/clarity: do we have the symmetric test 'truthy hook return value prevents reaching widget'? and symmetric tests for '*missing* handler does not prevent reaching hook, missing hook does not prevent reaching widget'?
    it('a truthy combo handler stops the descent', function()
      local reached_cb = false
      local input = F.activate_project()
      input.handlers.keypressed['backspace'] =
          function() return true end
      input.on_key_pressed =
          function() reached_cb = true; return true end
      F.show_widget({ text = 'ab' })
      F.session.press('backspace')
      assert.is_false(reached_cb)
      assert.same({ 'ab' }, F.singleton:get_text())
    end)

    -- doc/development/decisions/input.md, Decision 2: consuming never
    -- removes a {jargon:
    -- tier} — the same callback
    -- fires again on the next event (configuration is permanent).
    -- REVIEW/clarity/sanity:
    it('is a permanent configuration', function()
      local n = 0
      local input = F.activate_project()
      input.on_key_pressed =
          function() n = n + 1; return true end
      F.session.press('a')
      F.session.press('a')
      assert.equal(2, n)
    end)

    -- doc/development/decisions/input.md, Decision 2: assigning a generic
    -- callback replaces
    -- ONLY it; when
    -- it returns falsey the sink still runs for that event.
    -- REVIEW/clarity/consistence: this test is redundant -- the whole need raised from reversing misinterpreted requirements -- test can safely go, it repeats one particular configuration tested above
    it('assigning a callback replaces only it; sink still runs',
      function()
        local input = F.activate_project()
        F.show_widget({ text = 'ab' })
        input.on_key_pressed = function() return false end
        F.session.press('backspace')
        assert.same({ 'a' }, F.singleton:get_text())
      end)
  end)

  -- REVIEW/clarity: cleanup prose below and reformulate 'it' in more human-friendly way
  -- REVIEW/clarity: maybe wrap three cases below into sub-describe
  -- ---- combo tables and normalisation
  -- (doc/development/decisions/input.md, Decision 8) -------
  -- REVIEW/clarity: mention handlers there ('tables and normalization' are characteristics of internals, not observable behaviour)
  describe('combo tables and normalisation', function()
    -- doc/development/decisions/input.md, Decision 8: each channel has its
    -- OWN combo sub-table
    -- and keys normalise on assignment ('Ctrl+S' -> 'ctrl+s').
    it('a keypressed combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.handlers.keypressed['Ctrl+S'] =
            function() fired = true; return true end
        chord('lctrl', 's')
        assert.is_true(fired)
      end)

    it('a textinput combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.handlers.textinput['Ctrl+S'] =
            function() fired = true; return true end
        F.session.press('lctrl')
        F.session.type('s')
        assert.is_true(fired)
      end)

    it('a keyreleased combo fires on the normalised combo',
      function()
        local fired = false
        local input = F.activate_project()
        input.handlers.keyreleased['Ctrl+S'] =
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
        assert.is_table(input.handlers.keypressed)
        assert.is_table(input.handlers.keyreleased)
        assert.is_table(input.handlers.textinput)
        local leaked = false
        input.handlers.keypressed['s'] =
            function() leaked = true; return true end
        F.session.type('s')
        assert.is_false(leaked)
      end)
  end)

  -- REVIEW/clarity: I'd rather wrap in 'describe'
  -- REVIEW/clarity: cleanup prose below and get rid of jargon ('tier-3' is 'project hook' in newly suggested vocabulary)
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
        input.on_key_pressed = function(k, keys, isr)
          seen = { k, keys, isr }; return true
        end
        F.session.repeat_press('a')
        -- REVIEW/fidelity: only type signature is tested but not what is really delivered -- so its not a test of contract, only of its type-compliance
        assert.equal('a', seen[1])
        assert.is_table(seen[2])
        assert.is_true(seen[3])
      end)

    -- REVIEW/clarity: fix jargon ('tier-3' -> 'hook'?)
    -- doc/development/decisions/input.md, Decision 9: isrepeat is false on
    -- a fresh press, true on repeat.
    it('isrepeat threads to the tier-3 callback', function()
      local seen = { }
      local input = F.activate_project()
      input.on_key_pressed = function(_, _, isr)
        seen[#seen + 1] = isr; return true
      end
      F.session.press('a')
      F.session.repeat_press('a')
      assert.same({ false, true }, seen)
    end)

    -- REVIEW/clarity: this test IS testing both reading from proxy (i.e. proxy contents) and prohibited writing. But its not stated in the 'it' (definition focused only on write-prohibition). Also, word 'proxy' is not well-undertandable without details and describes implementation, not behaviour. 
    -- REVIEW/clarity/consistency/fidelity: Should instead be something like "describe('pressed keys table') -> it('contains pressed keys') , it('does not contain released keys'), it('can not be modified from hook or handler'))" and multiply it by evet type?
    -- doc/development/decisions/input.md, Decision 13: the keys_pressed
    -- argument is a
    -- READ-ONLY proxy —
    -- reads pass through, writes raise.
    it('the keys_pressed proxy is read-only', function()
      local proxy
      local input = F.activate_project()
      input.on_key_pressed = function(_, keys)
        proxy = keys; return true
      end
      F.session.press('a')
      assert.is_table(proxy)
      assert.is_true(proxy['a'])
      assert.has_error(function() proxy['x'] = true end)
    end)

    -- REVIEW/clarity: jargon ('sink' -> 'widget hook', 'widget'?)
    -- doc/development/decisions/input.md, Decision 9: the SINK is included
    -- in the uniform
    -- signature — it
    -- receives the same (k, proxy, isrepeat) triple. Patches the
    -- shared singleton method, restored after the assertion.
    it('the sink receives the uniform keypressed triple',
      function()
        local seen
        F.activate_project()
        F.show_widget()
	-- REVIEW/fidelity: are we testing internals there instead of behavior? in this case its justified if we cannot configure widget from the outside but need to ensure it received keypress -- but then maybe explicitly admit that this is test-specific patching. Maybe expose method like F.mock_widget_with(...) so that purpose will be clear, especially given the fact same mechanics is used in few other places. Right now it looks like legit configuration, which it is not (or is it?)
        F.singleton.keypressed = function(_, k, keys, isr)
          seen = { k, keys, isr }
        end
        F.session.repeat_press('a')
	-- REVIEW: why set to nil here?
        F.singleton.keypressed = nil
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
        input.on_key_released = function(k, keys)
          present = keys[k]; return true
        end
        F.session.press('a')
        F.session.release('a')
        assert.is_nil(present)
      end)
  end)

  -- REVIEW/clarity/consistency: 'avoid *sink*, use *text widget* instead'?
  -- REVIEW/cosmetic: extra '---' right below this line and after
  -- ---- defaults + hidden sink (doc/development/decisions/input.md,
  -- Decision 10 and Decision 2) -------

  describe('defaults and the hidden sink', function()
    -- REVIEW/fidelity/consistency: test against all non-defined participants? (both handler and hook -- disabled altogether or one-by-one -- I think already described somewhere above... symmetry feels off there

    -- REVIEW/clarity/terminology: current suggested alternative to 'generic callback' is 'hook'/'project hook'
    -- doc/development/decisions/input.md, Decision 10: the default generic
    -- callback neither
    -- edits nor
    -- consumes — the event falls through to the sink, which
    -- performs the edit.
    -- REVIEW/clarity: 'default callback(hook) does (not) smth' is implementation details, behavioural manifestation is 'when no hook configured...'
    it('the default callback neither edits nor consumes',
      function()
        F.activate_project()
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'a' }, F.singleton:get_text())
      end)

    -- REVIEW/cosmetic: prose below is a bit unnatural (content fine, grammar crippled) 
    -- doc/development/decisions/input.md, Decision 2: an event with no
    -- participant anywhere and a
    -- HIDDEN widget mutates nothing — the sink's internal no-op.
    it('no participant + hidden widget mutates nothing',
      function()
        F.activate_project()
        F.show_widget({ text = 'keep' })
        F.singleton:hide()
        F.session.press('backspace')
        assert.same({ 'keep' }, F.singleton:get_text())
      end)
  end)

  -- ---- {jargon: tier-3}: the on_* generic callback
  -- (doc/development/decisions/input.md, Decision 5 and Decision 10) ---

  -- REVIEW/terminology: now we can simply call it 'hooks' ("describe: hook" -> describe("on_text_input") -> it("fires per character"))
  describe('tier-3: the on_* generic callback', function()

    -- REVIEW/fidelity/consistency: only 'on_text_input' hook is tested, what about 'on_key_pressed'?
    -- doc/development/decisions/input.md, Decision 5: on_text_input is the
    -- PER-CHARACTER
    -- {jargon: tier-3} textinput
    -- callback (distinct from the submit output on_text_entered,
    -- which is the pending row above).
    it('on_text_input fires per character as text arrives',
      function()
        local got = { }
        local input = F.activate_project()
        input.on_text_input = function(t)
          got[#got + 1] = t; return true
        end
        F.session.type('a')
        F.session.type('b')
        assert.same({ 'a', 'b' }, got)
      end)

    -- doc/development/decisions/input.md, Decision 10 (on_* install path):
    -- a truthy callback intercepts
    -- the sink; a present-but-falsey callback falls through.
    it('a truthy on_text_input intercepts; falsey reaches sink',
      function()
        local input = F.activate_project()
        F.show_widget()
	-- REVIEW/clarity/suggestion: what if we redesign API syntax in this part and decide its not 'input.on_*' but input.hooks.{textinput,keypressed,keyreleased,mousewheel} -- with same logic just different configuration syntax/arch
        input.on_text_input = function() return true end
        F.session.type('X')
	-- REVIEW/fidelity: why would we check sigleton internals instead of compy.input. method ? (official behaviour)
        assert.is_true(F.singleton:is_empty())
        input.on_text_input = function() return false end
        F.session.type('Y')
        assert.same({ 'Y' }, F.singleton:get_text())
      end)
  end)

  -- REVIEW/clarity/jargon: rename? (according to new vocabulary the describe below would be something like "hooks: installation via sandboxed love.* handlers/slots" (in this context 'slots' may be tolerable?) suggestions are welcome. Word 'native' is certainly misleading and should be removed from all declarations in the group.
  -- ---- {jargon: tier-3}: the {jargon: native} install path
  -- (doc/development/decisions/input.md, Decision 10) -----

  describe('tier-3: the native install path', function()
    -- doc/development/decisions/input.md, Decision 10: a project
    -- {jargon: native} is a plain {jargon: tier-3}
    -- participant that fires REGARDLESS of widget-shown state
    -- (the reversed suppress-while-shown mutation is gone).
    -- REVIEW/consistency: any hook not only promoted 'native' should fire regardless of widget status (and widget absence can have two forms: never was 'shown', or was 'shown than hidden')
    -- REVIEW/clarity: make it clear that 'native' always behaves like hook -- so the match in behaviour is not occasional. Maybe reuse shared tests suite (if busted supports it)
    it('a native fires whether or not the widget is shown',
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

    -- doc/development/decisions/input.md, Decision 10, {jargon: native}
    -- path: a truthy {jargon: native} intercepts the sink.
    it('a native returning truthy intercepts the sink',
      function()
        F.activate_project({
          keypressed = function() return true end,
        })
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'ab' }, F.singleton:get_text())
      end)

    -- doc/development/decisions/input.md, Decision 10, {jargon: native}
    -- path: a falsey {jargon: native} falls through to
    -- the sink (asserted on the textinput channel too, so all
    -- three channels are covered across the {jargon: native}
    -- rows).
    it('a falsey native textinput falls through to the sink',
      function()
        F.activate_project({
          textinput = function() return false end,
        })
        F.show_widget()
        F.session.type('Z')
        assert.same({ 'Z' }, F.singleton:get_text())
      end)

    -- REVIEW/clarity: unite with the first test in this group, and remove references from 'downstream bucket D' from the prose. We simply test that hook fires whether widget is shown or hidden or never shown. Its a wortful test which would normally belong to both variants (hook installed via input API, and hook installed from legacy sandboxed love.* equivalent). See remark abouve about reusing tests group. Amd once again -- the test itself is worthful, and belongs to dispatching chain. The reason: it checks that downstream dispatching chain members (or just last one -- widget) do not block upstream consumption
    -- doc/development/decisions/input.md, Decision 10, {jargon: native}
    -- path, keyreleased
    -- channel: fires regardless
    -- of widget-shown state (case a) — the downstream half of
    -- the retired Bucket-D (doc/development/tests.md,
    -- "Input Contract Suite (feature #77)") 'release under a
    -- widget' row.
    it('a native keyreleased fires while the widget is shown',
      function()
        local seen = 0
        F.activate_project({
          keyreleased = function() seen = seen + 1 end,
        })
        F.show_widget()
        F.session.release('a')
        assert.equal(1, seen)
      end)

    -- REVIEW/clarity: update prose and declaration and variable names to new vocabulary
    -- doc/development/decisions/input.md, Decision 10 precedence:
    -- an explicit on_* takes
    -- precedence over the captured {jargon: native} — the
    -- {jargon: native} never
    -- seeds the {jargon: slot} when an on_* is set (no
    -- "replace" relation).
    it('an explicit on_* takes precedence over the native',
      function()
        local native_hits, cb_hits = 0, 0
        local function bump() native_hits = native_hits + 1 end
	-- REVIEW/fidelity/consistency: is 'activate_project' installing hooks via legacy path? (as love.*) are other tests (in the beginning of this suite) also testing this path and theerfore NOT testing input.on_ path (explicit hook configuration). What do we do with it?
        local input = F.activate_project({ keypressed = bump })
        input.on_key_pressed =
            function() cb_hits = cb_hits + 1; return true end
        F.session.press('a')
        assert.equal(1, cb_hits)
        assert.equal(0, native_hits)
      end)
  end)

  -- REVIEW/consistency/architecture: if we decide to pivot from .on_{event} to .hooks[event] the whole test should not be needed at all
  -- ---- the mutable/immutable boundary
  -- (doc/development/decisions/input.md, Decision 7)
  -- -------------

  describe('the mutable/immutable boundary', function()
    -- doc/development/decisions/input.md, Decision 7: exactly the
    -- {jargon: tier-3} callback {jargon: slots} are assignable;
    -- anything else raises loudly (never a silent swallow).
    it('assigning an unknown slot raises', function()
      local input = F.compy_input()
      assert.has_error(function() input.nonsense = 1 end)
      assert.has_error(function()
        input.show = function() end
      end)
      assert.has_error(function() input.handlers = { } end)
    end)

    it('assigning an allowed callback slot is accepted',
      function()
        local input = F.compy_input()
        assert.has_no.errors(function()
          input.on_key_pressed  = function() end
          input.on_text_input   = function() end
          input.on_key_released = function() end
        end)
      end)
  end)
end)
