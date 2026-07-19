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

describe('#input events dispatch chain', function()
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

  -- REVIEW/clarity: cleanup prose below and reformulate 'it' in more human-friendly way
  -- REVIEW/clarity: maybe wrap three cases below into sub-describe
  -- ---- combo tables and normalisation
  -- (doc/development/decisions/input.md, Decision 8) -------

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

  -- REVIEW/fidelity: we'd rather should test that setting combo on one event does not alter propagation of other events, and same with hooks. on the other hand, this test does smoke-check in most economic way
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

  -- REVIEW/clarity: I'd rather wrap in 'describe'
  -- REVIEW/clarity: cleanup prose below and get rid of jargon ('tier-3' is 'project hook' in newly suggested vocabulary)
  -- ---- signatures + read-only proxy
  -- (doc/development/decisions/input.md, Decision 9 and Decision 13) ---

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
      F.singleton.keypressed = function(_, k, keys, isr)
        seen = { k, keys, isr }
      end
      F.session.repeat_press('a')
      F.singleton.keypressed = nil
      assert.equal('a', seen[1])
      assert.is_table(seen[2])
      assert.is_true(seen[3])
    end)

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

  -- ---- defaults + hidden sink (doc/development/decisions/input.md,
  -- Decision 10 and Decision 2) -------

  -- doc/development/decisions/input.md, Decision 10: the default generic
  -- callback neither
  -- edits nor
  -- consumes — the event falls through to the sink, which
  -- performs the edit.
  it('the default callback neither edits nor consumes',
    function()
      F.activate_project()
      F.show_widget({ text = 'ab' })
      F.session.press('backspace')
      assert.same({ 'a' }, F.singleton:get_text())
    end)

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

  -- ---- {jargon: tier-3}: the on_* generic callback
  -- (doc/development/decisions/input.md, Decision 5 and Decision 10) ---

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
      input.on_text_input = function() return true end
      F.session.type('X')
      assert.is_true(F.singleton:is_empty())
      input.on_text_input = function() return false end
      F.session.type('Y')
      assert.same({ 'Y' }, F.singleton:get_text())
    end)

  -- ---- {jargon: tier-3}: the {jargon: native} install path
  -- (doc/development/decisions/input.md, Decision 10) -----

  -- doc/development/decisions/input.md, Decision 10: a project
  -- {jargon: native} is a plain {jargon: tier-3}
  -- participant that fires REGARDLESS of widget-shown state
  -- (the reversed suppress-while-shown mutation is gone).
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

  -- doc/development/decisions/input.md, Decision 10 precedence
  -- ({badspecref: E30} — cold session resolving
  -- assign-replaces-capture to precedence-not-replace):
  -- an explicit on_* takes
  -- precedence over the captured {jargon: native} — the
  -- {jargon: native} never
  -- seeds the {jargon: slot} when an on_* is set (no
  -- "replace" relation).
  it('an explicit on_* takes precedence over the native',
    function()
      local native_hits, cb_hits = 0, 0
      local function bump() native_hits = native_hits + 1 end
      local input = F.activate_project({ keypressed = bump })
      input.on_key_pressed =
          function() cb_hits = cb_hits + 1; return true end
      F.session.press('a')
      assert.equal(1, cb_hits)
      assert.equal(0, native_hits)
    end)

  -- ---- the mutable/immutable boundary
  -- (doc/development/decisions/input.md, Decision 7)
  -- -------------

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
