-- REVIEW: why input_routing_spec not e.g. input_contracts_spec? 

-- Input routing — the framework's behavioural contracts.
--
-- Authored top-down from the contract record
-- (doc/development/wip/77-new-input-api/notes/input-contracts.md);
-- each test cites the section it traces to (§3.x / §4.x / §5.x).
-- The suite describes framework BEHAVIOUR — what must be preserved
-- and what is still to be implemented — so it outlives the M4/M5
-- routing rewrite rather than churning with the mechanism.
--
-- Vocabulary (§2 glossary): ROUTE = the consumer an event is
-- dispatched to (exactly one per keyboard/text event); WIDGET =
-- the route-managed input surface; SINK = a route's last-resort
-- disposition. Tests assert OBSERVABLE OUTCOMES (state/text
-- changed) or receipt at a public seam — never a method-name spy,
-- never love.state internals as behaviour.
--
-- Buckets (organising concept, not a file split):
--   A PRESERVE              — stable-now contracts, green now
--   B IMPLEMENT             — forward contracts, carried pending
--   C MECHANISM-GUARD       — object-lifecycle/NFR, labelled
--   D CHARACTERIZE          — factual-today, expected to change
-- The whole standup lives in tests/helpers/input_fixture; a test
-- stands up the real gate + a route in one line through it.

local F  = require('tests.helpers.input_fixture')
local TU = require('tests.testutil')
local mock = require('tests.mock')

require('tests.helpers.codesnippets')
require('tests.helpers.editor_session')


-- REVIEW: why would we use editor_session here, and especially drive 'press' via its own :keypressed ?
-- A standalone editor session for the block-nav row (drives
-- EditorController directly, not through the love slots).
local function make_editor_session()
  local model = EditorModel(F.cfg)
  local ec    = EditorController(model)
  EditorView(F.cfg.view, ec)
  local press = function(k) ec:keypressed(k) end
  local save  = TU.get_save_function({ })
  return EditorSession(ec, press, save, mock)
end

describe('input routing #input', function()
  before_each(function() F.reset() end)

  -- ======================================================
  -- Bucket A — PRESERVE (stable-now contracts; green now)
  -- ======================================================

  -- keypressed / textinput / keyreleased are EXCLUSIVE: the event
  -- reaches exactly one route — never two, never dropped (§3.1–3.3,
  -- F-A). "exactly one" is phrased as one-and-only-one receipt, not
  -- as "the project was dropped".
  -- REVIEW: mentioning paragraphs in 'describe' is redundant and too bureacratic -- mention in comment is enough
  describe('keyboard routing is EXCLUSIVE (§3.1-3.3)', function()

    -- REVIEW: what is P1? why widget up/down is going to be route-defining? does not our design presume that route defines whether event reaches widget? yes, right now while overlay gate is true and no ProjectInputController is provisioned yet -- the widget determines routing -- but in this form its TRANSITIONAL behaviour, not PRESERVABLE. Invariant PRESERVABLE behaviour is that event reaches *some* consumer

    -- P1 keypressed
    it('a keypress reaches the route when no widget is up',
      function()
        F.console:add_text('ab')
        F.session.press('backspace')
        assert.same({ 'a' }, F.console:get_text())
      end)

    -- REVIEW: 'widget up' is just legacy and cripple way to define 'project route', its never expected to stay thsi way
    -- REVIEW: also, which scenario exactly is tested? what makes widget 'show up'? shoud not console use the same singleton? I do not understtand the setup described here
    it('a keypress reaches only the widget when one is up',
      function()
        F.console:add_text('ab')
        F.show_widget({ text = 'xy' })
        F.session.press('backspace')
        assert.same({ 'x' }, F.singleton:get_text())
        assert.same({ 'ab' }, F.console:get_text())
      end)

    -- REVIEW: what is P2? plus same concerns about widget role
    -- P2 textinput
    it('a character reaches the route when no widget is up',
      function()
        F.session.type('Z')
        assert.same({ 'Z' }, F.console:get_text())
      end)

    -- REVIEW: this is good test. I would like to see sibling tests for: "console mode", "project mode (widget up)". Also, what happened with other more exotic modes (e.g. inspect)
    it('a character reaches the editor route while editing',
      function()
        love.state.app_state = 'editor'
        F.cc.editor:open('t.lua', '', function() return true end)
        F.session.type('q')
        assert.same({ 'q' }, F.cc.editor.input:get_text())
      end)

    -- REVIEW: as said, wrong abstraction level. "widget up" is not supposed to be a a routing state -- right now its just crippled way to set up 'project routing', is not it?
    it('a character reaches only the widget when one is up',
      function()
        F.show_widget()
        F.session.type('Z')
        assert.same({ 'Z' }, F.singleton:get_text())
        assert.same({ '' }, F.console:get_text())
      end)


    -- REVIEW: it does not look like anything I imagine about contracts --  either I do not understand the contracts, or spec is misinterpreted

    -- P3 keyreleased — release carries no text mutation, so
    -- exclusivity is observed at the route's public framework slot
    -- (love.keyreleased): it receives when no widget is up, and is
    -- bypassed when the widget owns the event.
    it('a key release reaches the route when no widget is up',
      function()
        local n = 0
        local orig = love.keyreleased
        love.keyreleased = function(k) n = n + 1; orig(k) end
        F.session.release('a')
        love.keyreleased = orig
        assert.equal(1, n)
      end)

    -- REVIEW: it sounds exactly like a bug which we are going to combat, does not it?
    it('a key release does not reach the route under a widget',
      function()
        F.show_widget()
        local n = 0
        local orig = love.keyreleased
        love.keyreleased = function(k) n = n + 1; orig(k) end
        F.session.release('a')
        love.keyreleased = orig
        assert.equal(0, n)
      end)
  end)

  -- REVIEW: paragraph in describe is redunadnt, mentioning in comment is fine
  -- REVIEW: is any consumer actually consuming keyreleased now? maybe we should not route it, or route without processing?
  -- REVIEW: held-key-set is generally good because we want to maintain a global registry of keys. However its observable behaviour would be keys table passed to route consumer (not implemented yet but planned)
  -- P6 held-key set lifecycle (§4.1): a key is added on press and
  -- removed on release BEFORE any dispatch, so the set already
  -- reflects the event when a route consumer runs.
  describe('held-key set lifecycle (§4.1)', function()

    it('the pressed key is in the held set while the route runs',
      function()
        local seen
        local orig = love.keypressed
        love.keypressed = function(k)
          -- REVIEW: what is this semicolon syntax? why not return? I understand the logic and its correct, but it *reads* confusing
          seen = Controller.keys_pressed['x']; orig(k)
        end
        F.session.press('x')
        love.keypressed = orig
        assert.is_true(seen)
      end)

    -- REVIEW: ok, it *may* stay, but its smelly (checking implementation not impact)
    it('the released key is gone before the route runs',
      function()
        Controller.keys_pressed['x'] = true
        local seen = true
        local orig = love.keyreleased
        love.keyreleased = function(k)
          seen = Controller.keys_pressed['x']; orig(k)
        end
        F.session.release('x')
        love.keyreleased = orig
        assert.is_nil(seen)
      end)

    -- REVIEW: ok, but still mentioning delegation elsewhere is fragile (can reference supposed delegation in comment but not in assertion statement)
    it('left/right names stay raw; folding is combo_string\'s job',
      function()
        F.session.press('lctrl')
        assert.is_true(Controller.keys_pressed['lctrl'])
        assert.is_nil(Controller.keys_pressed['ctrl'])
      end)
  end)

  -- REVIEW: have no idea what is P7, and moreover -- is there a design decision which may be reconsidered? I.e. framework may decide on case-by-case basis which combos propagate and which do not
  -- P7 global shortcuts are non-consuming (§4.3): a framework
  -- shortcut fires its effect AND the key still reaches its route.
  describe('global shortcuts are non-consuming (§4.3)', function()

    it('a shortcut fires its effect and the key still routes',
      function()
        love.state.app_state = 'running'
        local n = 0
        local orig = love.keypressed
        love.keypressed = function(k) n = n + 1; orig(k) end
        mock.keystroke('C-pause', F.session.press, false)
        love.keypressed = orig
        assert.equal('snapshot', love.state.app_state)
        assert.equal(1, n)
      end)

    -- REVIEW: where this contract comes from? is it incidental or desired behaviour?
    -- Play mode narrows the active set: restart/profile stay live,
    -- the project-management shortcuts (quit/stop/quickswitch) do
    -- not. Driven on an isolated play-mode gate (save/restore the
    -- shared love.handlers so the fixture gate is untouched).
    it('play mode narrows the active shortcut set', function()
      local calls = { }
      local stub = {
        cfg = { mode = 'play' },
        restart = function() calls.restart = true end,
        quit_project = function() calls.quit = true end,
        stop_project_run = function() end,
        keypressed = function() end,
      }
      local saved, saved_kp = love.handlers, love.keypressed
      love.keypressed = function() end
      love.state.app_state = 'running'
      Controller.setup_callback_handlers(stub)
      local kp = love.handlers.keypressed
      mock.keystroke('C-M-r', kp, false)
      mock.keystroke('C-q', kp, false)
      love.handlers, love.keypressed = saved, saved_kp
      assert.is_true(calls.restart)
      assert.is_nil(calls.quit)
    end)
  end)


  -- REVIEW: I strill struggle to see how 'active widget' became an entity that defines routing. Also what is the use of pointer events inside text widget? is it doing some kind of selection?

  -- Pointer delivery is BOTH (§3.5): an active widget does not deny
  -- the route — both receive it (order not asserted, R3); with no
  -- widget the route receives alone. Guards M4 gate-removal from
  -- silently killing pointer delivery to the widget half.
  describe('pointer delivery is BOTH (§3.5-3.6)', function()

    -- P4 mouse. A press+release lands an observable selection on a
    -- selection-enabled widget and on the console route (the
    -- production singleton disables selection — making its pointer
    -- handler a no-op, §3.6 — so a selectable widget instance is
    -- used to witness delivery).
    it('a pointer reaches the route when no widget is up',
      function()
        F.console:set_text({ 'aa', 'bb', 'cc' })
        F.session.mousepressed(10, 540, 1, false, 1)
        F.session.mousereleased(40, 508, 1, false, 1)
        assert.is_true(F.console.model:has_selection())
      end)

    it('a pointer reaches the widget and the route both',
      function()
        local w = F.show_selectable_widget()
        F.console:set_text({ 'aa', 'bb', 'cc' })
        F.session.mousepressed(10, 540, 1, false, 1)
        F.session.mousereleased(40, 508, 1, false, 1)
        assert.is_true(w.model:has_selection())
        assert.is_true(F.console.model:has_selection())
      end)

    -- P5 touch BOTH (§3.6). SURFACED GAP: the widget AND the route
    -- touch handlers are both no-ops today (TODO stubs), so touch
    -- delivery produces no observable outcome anywhere, and a
    -- delivery probe would be the method-name spy Bucket A forbids.
    -- The delivery contract is therefore not black-box expressible
    -- on the current surface — greened when a touch consumer lands.
    --- REVIEW: why its here, where the contract comes from? and what is P5? (someone reading the test would have to dig docs to understand it?)
    pending('a touch reaches the widget and the route both')
  end)

  -- P11 framework click detection (§4.7): a derived path, separate
  -- from raw pointer delivery. Constants (0.4s / 2.5px) are
  -- mechanism — only the outcomes are asserted, against the
  -- project-defined handlers (default no-ops).
  describe('framework click detection (§4.7)', function()

    it('a single click confirms only after the debounce window',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
        F.set_compy_handler('singleclick', bump)
        F.set_mouse_pos(10, 540)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.update(0.1)
        assert.equal(0, hit)
        F.update(0.5)
        assert.equal(1, hit)
      end)

    it('a drifting pointer suppresses the single click',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
        F.set_compy_handler('singleclick', bump)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.set_mouse_pos(400, 400)
        F.update(0.5)
        assert.equal(0, hit)
      end)

    it('a double click calls the project double-click handler',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
        F.set_compy_handler('doubleclick', bump)
        F.set_mouse_pos(10, 540)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.update(0.5)
        assert.equal(1, hit)
      end)
  end)

  -- P8 slot restoration on project stop (§4.4): after stop, no
  -- project handler remains in any slot — the console owns input
  -- again. (Form renamed to a console-named restoration at m4 / I2,
  -- §5.2; the end state asserted here is identical, row stays green.)
  describe('slot restoration on project stop (§4.4)', function()

    it('no project handler remains; the console owns input',
      function()
        -- REVIEW: in reality, love.keypressed set from within project does not alter native love.keypressed -- there's some chemistry mapping project handlers to real love handlers -- we do not seem to test this path here
        love.keypressed = function() end
        F.cc:stop_project_run()
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
        F.console:add_text('ab')
        F.session.press('backspace')
        assert.same({ 'a' }, F.console:get_text())
      end)
  end)

  -- REVIEW: P9 references which doc? should not test be tagged as #legacy? paragraphs in statement are bureacratic
  -- P9 legacy text solicitation (§4.5): one successful submit both
  -- fills the poll handle and closes the widget; guarded refusals
  -- warn (never silent, C2). The whole path retires at m8.
  describe('legacy text solicitation (§4.5)', function()

    it('one successful submit fills the handle and closes',
      -- REVIEW: why its not a part of input_session? such as 'legacy input_text')
      function()
        local env = F.cc:get_project_env()
        local ref = env.user_input()
        env.input_text('prompt?')
        local closed = false
        love.event.push = function(ev)
          if ev == 'userinput' then closed = true end
        end
        F.singleton:set_text('42')
        F.session.press('return')
        assert.equal('42', ref())
        assert.is_true(closed)
      end)

    -- REVIEW: is not this test red yet? or warning logic already implemented?
    it('a guarded refusal warns, never silently drops', function()
      love.state.user_input = { }
      local env = F.cc:get_project_env()
      env.user_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      env.input_text('p')
      Log.warn = ow
      assert.equal(1, warned)
    end)
  end)

  -- P10 widget activation / reset (§4.6): driven through the
  -- public surface (compy.input.show/hide), asserted on the widget's
  -- observable content. The "no cancel chain" facts are stable-now;
  -- they flip at m6 (F-D), at which point hide()/cancel fire a chain.
  describe('widget activation and reset (§4.6)', function()

    it('re-activation without force warns and is a no-op',
      function()
        local input = F.compy_input()
        input.show({ text = 'first' })
        local warned = 0
        local ow = Log.warn
        Log.warn = function() warned = warned + 1 end
        input.show({ text = 'second' })
        Log.warn = ow
        assert.equal(1, warned)
        assert.same({ 'first' }, F.singleton:get_text())
      end)

    it('re-activation with force reapplies the text subset',
      function()
        local input = F.compy_input()
        input.show({ text = 'original' })
        input.show({ force = true, text = 'replaced' })
        assert.same({ 'replaced' }, F.singleton:get_text())
      end)

    it('force without text leaves the content intact', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      -- REVIEW: why not input.hide() between two .show() ?
      input.show({ force = true })
      assert.same({ 'keep' }, F.singleton:get_text())
    end)

    it('a fresh activation with no text starts empty', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.hide()
      input.show()
      assert.is_true(F.singleton:is_empty())
    end)

    -- REVIEW: so how is it 'deactivated' if it still grabs the characters typed?
    it('hide deactivates the widget', function()
      local input = F.compy_input()
      input.show()
      input.hide()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)

    -- REVIEW: a series of cryptic manipulations, what is real behaviour tested?
    it('a oneshot submit deactivates the widget', function()
      local env = F.cc:get_project_env()
      env.user_input()
      env.input_text('p')
      F.singleton:set_text('v')
      F.singleton.model:handle(true)
      F.session.handlers.userinput()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)
  end)

  -- REVIEW: if editor simply tracks arrows-navigation and detects limit itself, we should only ensure it receives arrows movement
  -- REVIEW: if editor relies on special condition delivered (i.e. input widget emitting hit) -- we should test it instead
  -- REVIEW: testing editor's own logic and behaviour seemed good approach intuitively but in fact mixes concerns -- we are not testing editor's own logic here, only integration with user input widget (if editor uses it at all!)
  -- REVIEW: if editor even does not use input widget, the contract is that editor simply receives all the events it relies onto (i.e. if editor subscribes to love. events -- it should continue receiving them in editor mode) -- and we can mock the editor with testing code at the boundary, if we only track event/callback delivery. Almost certainly  we should not use EditorSession mocks -- they are for testing editor internals logic. We should test that user actions are transmitted through framework correctly (i.e. test exactly the flow that leads to the event which editor session mocks)
  -- Editor block navigation at the buffer limit (§3, editor route).
  -- Exercises block-nav INDIRECTLY through the at-limit condition:
  -- only an up/down at the vertical limit escalates to block-nav.
  -- Guards the later is_at_limit line-scope rewrite from regressing
  -- whole-input block nav. (editor_session, used unchanged.)
  describe('editor block-nav at buffer limit #editor', function()

    before_each(function() love.state.app_state = 'editor' end)

    it('up at the top limit navigates blocks', function()
      local es  = make_editor_session()
      local f1  = mock_func_snippet("one")
      local f2  = mock_func_snippet("two")
      local src = (snippets_to_code(f1, '', f2))
      es:open(src, 3)
      local buf = es.controller:get_active_buffer()
      es:select_and_open_block(3)
      es.mock.keystroke('down', es.press)
      assert.equal(3, buf.selection)
      es.mock.keystroke('up', es.press)
      assert.equal(3, buf.selection)
      es.mock.keystroke('up', es.press)
      assert.is_true(buf.selection < 3)
    end)
  end)

  -- ======================================================
  -- Bucket D — CHARACTERIZE-PROVISIONAL (factual today)
  -- These describe CURRENT behaviour that is EXPECTED TO CHANGE;
  -- they are not preserve-contracts. Each asserts only verifiable
  -- present behaviour — any "how it should become" is a comment,
  -- so a deliberate M4 change reads as expected, not regression.
  -- ======================================================
  describe('provisional — expected to change, no mandate',
    function()

      -- CP1 inspect (§3.4, R2). Under inspect the console REPL owns
      -- the input surface; a shown project widget is not honoured;
      -- input is not dead. ASSUMPTION (not asserted): routing
      -- unification may legitimately revise inspect ownership.
      it('inspect: the console owns input; the widget is bypassed',
        function()
          F.show_widget()
          -- REVIEW: what exactly is 'add_text'? Is it love2d-level behaviour, or console internal's operation? if latter, it does not belong to current tests
          F.console:add_text('ab')
          love.state.app_state = 'inspect'
          F.session.type('Z')
          assert.same({ 'abZ' }, F.console:get_text())
          assert.is_true(F.singleton:is_empty())
        end)

      -- CP2 wheel (§3.7, R1). Wheel reaches the route, never the
      -- widget: there is no wheel entry in the gate, so the widget
      -- is bypassed by omission; the route slot exists and is a
      -- no-op unless the project sets love.wheelmoved. ASSUMPTION
      -- (not asserted): intended shape is project pass-through with
      -- project-opt-in consume.
      -- REVIEW: route-not-widget is a bad abstraction for any event dispatching logic , or I am misunderstanding something
      it('wheel reaches the route, never the widget', function()
        assert.is_nil(F.session.handlers.wheelmoved)
        assert.is_function(love.wheelmoved)
      end)
    end)

  -- ======================================================
  -- Bucket C — MECHANISM-GUARD (NFR; not behaviour contracts)
  -- Genuine object-lifecycle guards. Labelled so no reader mistakes
  -- them for behaviour contracts (the behaviour they once stood in
  -- for is covered by the P-rows above, through the public surface).
  -- ======================================================
  describe('mechanism / NFR guards — not behaviour', function()

    -- REVIEW: testing show/hide/show but what about switching modes (e.g. launching and stopping project?)

    -- MG1 singleton identity: the same UserInputController instance
    -- backs the widget across show/hide cycles.
    it('the widget controller keeps identity across cycles',
      function()
        F.show_widget()
        local first = love.state.user_input.C
        F.singleton:hide()
        F.show_widget()
        assert.equal(first, love.state.user_input.C)
      end)

    -- MG2 no reallocation per input session (NFR-1): the backing
    -- model is reused, never rebuilt, across activations.
    it('no widget model is reallocated per session', function()
      local m1 = F.singleton.model
      F.show_widget()
      F.singleton:hide()
      F.show_widget()
      assert.equal(m1, F.singleton.model)
    end)
  end)

  -- ======================================================
  -- Bucket B — IMPLEMENT (forward contracts; pending → green)
  -- Carried pending with greppable DEFERRED (0.1.0-mN) markers at
  -- the milestone that greens them. Bodies document the target
  -- assertion on the PUBLIC API; none of it is implemented in src/.
  -- ======================================================
  describe('forward contracts (pending until implemented)',
    function()

      -- DEFERRED (0.1.0-m4): I1 — project key/text/release reach a
      -- first-class ProjectInputController while a widget is up;
      -- they are no longer dropped by the overlay gate (§5.1).
      pending('project key/text reach the project sink',
        function()
          F.show_widget()
          local got = { }
          -- REVIEW: what is 'on_event'? Should not there be specific callbacks?
          ProjectInputController.on_event =
            function(k) got[#got + 1] = k end
          F.session.press('a')
          assert.same({ 'a' }, got)
        end)

      -- DEFERRED (0.1.0-m4): I2 — slot restoration named to the
      -- console (vs today's wholesale default reinstall, §5.2). Same
      -- end state P8 already guards; this pins the named target.
      pending('project stop restores the slot to the console',
        function()
          F.cc:stop_project_run()
          -- REVIEW: active_keyboard_route ? what is it?
          assert.equal(F.console, F.cc:active_keyboard_route())
        end)

      -- DEFERRED (0.1.0-m4): I3 — D-9 native coexistence (§5.3): a
      -- legacy project (native love.keypressed, no compy surfaces)
      -- gets a lifecycle-split wrapper — native fires while the
      -- widget is hidden, the sink receives while it is shown.
      -- REVIEW: behaviour described above, where it comes from, which requirement???? why widget shown/hidden should be able to change controller routing? (maybe I forgot something?)
      -- REVIEW: what 'legacy native handler' even is? ProjectController can legitimately set its own "love" callbacks, its not legacy. Its just that when they are *not* set, default callback could be propagating to active widget (assuming its configured to trigger required callbacks instead)
      pending('legacy native handler coexists with the sink',
        function()
          local native = 0
          F.cc:provision_legacy(function() native = native + 1 end)
          F.session.press('a')
          assert.equal(1, native)
          F.show_widget()
          F.session.press('a')
          assert.equal(1, native)
        end)

      -- DEFERRED (0.1.0-m4): I4 — isrepeat is no longer dropped at
      -- the gateway; the function(k) slot at controller.lua:554
      -- widens so it reaches the keypressed path (§5.4-m4). Per D-α
      -- the whole path carries (k, keys_pressed, isrepeat) — the
      -- SINK included, not only the callback.
      -- REVIEW: ok, that is good. What about keys pressed being passed too?
      pending('isrepeat is no longer dropped at the gateway',
        function()
          local seen
          F.show_widget()
          F.singleton.keypressed =
            function(_, _, _, isrepeat) seen = isrepeat end
          F.session.repeat_press('a')
          assert.is_true(seen)
        end)

      -- DEFERRED (0.1.0-m5a): I5 — on_key_pressed / on_text_entered
      -- exposed on compy.input; firing them dispatches to the
      -- project, default = the sink (§5, design §4).
      -- REVIEW: somehow it only tests 'on_key_pressed' while promising to test both
      pending('on_key_pressed / on_text_entered are exposed',
        function()
          local got
          F.compy_input().on_key_pressed = function(k) got = k end
          F.session.press('a')
          assert.equal('a', got)
        end)

      -- DEFERRED (0.1.0-m5): I6 — isrepeat delivered to the project
      -- keyboard callback as the uniform triple (§5.4-m5).
      -- REVIEW: how its different from the case described two sections above ("isrepeat is no longer...")?
      -- REVIEW: I'd rather ensure its *not* delivered when no repeat is happening
      pending('isrepeat is delivered to on_key_pressed',
        function()
          local seen
          F.compy_input().on_key_pressed =
            function(_, _, isrepeat) seen = isrepeat end
          F.session.repeat_press('a')
          assert.is_true(seen)
        end)

      -- DEFERRED (0.1.0-m5b): I7 — handlers[combo] dispatch with
      -- normalisation and fresh-only keying (§4.2/§5). I8 combo
      -- serialisation (§4.2) is the optional pure-function format,
      -- already covered green in keys_pressed_spec; it becomes
      -- load-bearing only when this dispatch consumer lands.
      -- REVIEW: ok, this is good one -- except we postponed combo handlers until the very last milestone
      pending('combo handlers dispatch on the normalised key',
        function()
          local fired
          F.compy_input().handlers =
            { ['ctrl+s'] = function() fired = true end }
          mock.keystroke('C-s', F.session.press, false)
          assert.is_true(fired)
        end)
    end)

  -- ======================================================
  -- M6 / M7 forward — structural anchor only (s27 D-δ)
  -- Names the not-yet-authored forward contracts so they are not
  -- forgotten; deliberately NOT fleshed out (scope fence: m4/m5).
  -- See input-contracts.md §5 scope note (R7).
  -- ======================================================a
  -- REVIEW: I hope its tracked as technical debt?
  describe('later forward contracts — not yet authored', function()
    pending(
      'submit/cancel chains, on_limit_reached, ' ..
      'configure/set_text/cursor, force-vs-configure')
  end)
end)
