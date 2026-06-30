-- Input contracts — the framework's behavioural input
-- guarantees.
--
-- Authored top-down from the corrected contract record
-- (notes/input-contracts.md); each test cites the section it
-- traces to (§2 / §3.x / §4.x / §5.x) in a comment, never in
-- its description. The suite describes framework BEHAVIOUR —
-- what the M4/M5 routing rewrite must preserve and what it must
-- still implement — so it outlives the mechanism rather than
-- churning with it.
--
-- The one routing invariant (§2): inter-route dispatch is
-- EXCLUSIVE for EVERY event type — keyboard, text, pointer.
-- Each event reaches exactly ONE route, the active one fixed by
-- the exclusive screen mode (console / project-running /
-- editor); never zero, never two. The widget is an operational
-- surface the active route drives, not a router: it never owns
-- an event by merely existing. The only "both" is INTRA-route
-- (a route forwarding an event to a surface it activated AND
-- running its own logic) — the route's private affair,
-- invisible to this contract and never asserted as a second
-- delivery.
--
-- Vocabulary (§2 glossary): ROUTE = the consumer an event is
-- dispatched to (exactly one per event); WIDGET = the
-- route-managed input surface; SINK = a route's last-resort
-- disposition. Tests assert OBSERVABLE OUTCOMES (state/text
-- changed) or receipt at a public seam (a project's own love.*
-- callback) — never an internal method-name spy, never
-- love.state internals as behaviour.
--
-- Buckets (an organising concept, not a file split):
--   A PRESERVE        — stable-now contracts, green now
--   B IMPLEMENT       — forward contracts, carried pending
--   C MECHANISM-GUARD — object-lifecycle/NFR, labelled
--   D CHARACTERIZE    — factual-today, expected to change

local F  = require('tests.helpers.input_fixture')
local TU = require('tests.testutil')
local mock = require('tests.mock')

require('tests.helpers.codesnippets')
require('tests.helpers.editor_session')

-- A standalone editor session for the block-nav row; it drives
-- EditorController directly to exercise editor-internal block
-- navigation, the one row that is editor behaviour rather than
-- framework routing (the routing siblings below go through the
-- gate).
local function make_editor_session()
  local model = EditorModel(F.cfg)
  local ec    = EditorController(model)
  EditorView(F.cfg.view, ec)
  local press = function(k) ec:keypressed(k) end
  local save  = TU.get_save_function({ })
  return EditorSession(ec, press, save, mock)
end

describe('input contracts #input', function()
  before_each(function() F.reset() end)

  -- ====================================================
  -- Bucket A — PRESERVE (stable-now contracts; green now)
  -- ====================================================

  -- Keyboard and text are EXCLUSIVE on the active route
  -- (§3.1-3.3): each event reaches exactly one route — the one
  -- fixed by the screen mode — never two, never dropped. The
  -- sibling rows below prove the SAME rule across the three
  -- real routes; the active route receives AND the others do
  -- not. Provenance: the ratified inter-route-exclusivity
  -- principle (§2) + the tier-1 mandate "only text fields
  -- break; native keyboard handling must keep working," at
  -- route level. (Widget-presence is NOT a routing state here —
  -- that the overlay gate routes by widget today is mechanism
  -- #77 removes, §3.1; it is characterized provisional below,
  -- never preserved.)
  describe('keyboard exclusive to the active route', function()

    it('console mode routes keys to the console', function()
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'a' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    it('editor mode routes keys to the editor', function()
      love.state.app_state = 'editor'
      F.cc.editor:open('t.lua', '', function() return true end)
      F.session.type('q')
      assert.same({ 'q' }, F.cc.editor.input:get_text())
      assert.is_true(F.console:is_empty())
    end)

    it('project run routes keys to the project', function()
      local got = { }
      F.running_project('keypressed', function(k)
        got[#got + 1] = k
      end)
      F.session.press('a')
      assert.same({ 'a' }, got)
      assert.is_true(F.console:is_empty())
    end)

    it('console mode routes text to the console', function()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    it('project run routes text to the project', function()
      local got = { }
      F.running_project('textinput', function(t)
        got[#got + 1] = t
      end)
      F.session.type('Z')
      assert.same({ 'Z' }, got)
      assert.is_true(F.console:is_empty())
    end)

    -- §3.3: a release carries no text mutation, so exclusivity
    -- is observed at the project's own release callback — the
    -- active route receives exactly once. (keyreleased IS
    -- consumed: the held-key tracker removes the key, §4.1.)
    it('the active route receives the key release', function()
      local got = 0
      F.running_project('keyreleased', function()
        got = got + 1
      end)
      F.session.release('a')
      assert.equal(1, got)
    end)
  end)

  -- Held-key set lifecycle (§4.1): a key is added on press and
  -- removed on release BEFORE any dispatch runs, so the set
  -- already reflects the event when a route consumer runs. (The
  -- forward, route-observable form — the set handed to the
  -- route as a read-only proxy — is Bucket B I4 / D-α, not yet
  -- wired.)
  describe('held-key set lifecycle', function()

    it('the pressed key is in the held set', function()
      local seen
      local orig = love.keypressed
      love.keypressed = function(k)
        seen = Controller.keys_pressed['x']
        orig(k)
      end
      F.session.press('x')
      love.keypressed = orig
      assert.is_true(seen)
    end)

    it('the released key is gone before dispatch', function()
      Controller.keys_pressed['x'] = true
      local seen = true
      local orig = love.keyreleased
      love.keyreleased = function(k)
        seen = Controller.keys_pressed['x']
        orig(k)
      end
      F.session.release('x')
      love.keyreleased = orig
      assert.is_nil(seen)
    end)

    it('left/right names stay raw in the held set', function()
      -- Folding to the generic name is combo_string's job
      -- (§4.2), not the held set's; asserted there, not via
      -- delegation here.
      F.session.press('lctrl')
      assert.is_true(Controller.keys_pressed['lctrl'])
      assert.is_nil(Controller.keys_pressed['ctrl'])
    end)
  end)

  -- Global shortcuts are non-consuming (§4.3): a framework
  -- shortcut fires its effect AND the key still reaches its
  -- route. (Carried as-is — open whether this is a mandated
  -- invariant or incidental, §4.3; recorded, not re-litigated.)
  describe('global shortcuts do not consume the key', function()

    it('a shortcut fires but does not consume', function()
      love.state.app_state = 'running'
      local n = 0
      local orig = love.keypressed
      love.keypressed = function(k) n = n + 1; orig(k) end
      mock.keystroke('C-pause', F.session.press, false)
      love.keypressed = orig
      assert.equal('snapshot', love.state.app_state)
      assert.equal(1, n)
    end)

    -- Play mode narrows the active set: restart/profile stay
    -- live, the project-management shortcuts
    -- (quit/stop/quickswitch) do not. Driven on an isolated
    -- play-mode gate (save/restore the shared love.handlers so
    -- the fixture gate is untouched).
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

  -- Pointer is EXCLUSIVE on the active route (§3.5-3.6): a
  -- pointer event reaches the one active route, like every
  -- other event. Any forwarding to a widget is INTRA-route (the
  -- route's concern) and is NOT asserted as a second
  -- inter-route delivery — the earlier "pointer reaches BOTH
  -- route and widget" was today's un-gated mouse path promoted
  -- to invariant, removed by the correction (§3.5). Provenance:
  -- the ratified principle (§2).
  describe('pointer exclusive to the active route', function()

    -- The production singleton disables selection (its pointer
    -- handler is a no-op), so an observable selection on the
    -- console route witnesses active-route delivery.
    it('a pointer reaches the active route', function()
      F.console:set_text({ 'aa', 'bb', 'cc' })
      F.session.mousepressed(10, 540, 1, false, 1)
      F.session.mousereleased(40, 508, 1, false, 1)
      assert.is_true(F.console.model:has_selection())
    end)

    it('project run routes the pointer', function()
      local got = 0
      F.running_project('mousepressed', function()
        got = got + 1
      end)
      F.console:set_text({ 'aa', 'bb', 'cc' })
      F.session.mousepressed(10, 540, 1, false, 1)
      assert.equal(1, got)
      assert.is_false(F.console.model:has_selection())
    end)

    -- SURFACED GAP: touch has no gateway entry today (the
    -- production gate wires keypressed/textinput/keyreleased/
    -- mouse*, not touch), and both the widget and route touch
    -- handlers are no-ops, so touch delivery is not black-box
    -- observable. Greened when a touch consumer lands; reason
    -- recorded so the gap is visible, not silent.
    pending('touch reaches the active route')
  end)

  -- Framework click detection (§4.7): a derived path, separate
  -- from raw pointer delivery. The 0.4s / 2.5px constants are
  -- mechanism — only the outcomes are asserted, against the
  -- project-defined handlers (default no-ops).
  describe('framework click detection', function()

    it('a single click confirms after the window', function()
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

    it('pointer drift suppresses the single click', function()
      local hit = 0
      local bump = function() hit = hit + 1 end
      F.set_compy_handler('singleclick', bump)
      F.session.mousereleased(10, 540, 1, false, 1)
      F.set_mouse_pos(400, 400)
      F.update(0.5)
      assert.equal(0, hit)
    end)

    it('a double click calls the project handler', function()
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

  -- Slot restoration on project stop (§4.4): after stop, no
  -- project handler remains in any slot — the console owns
  -- input again. (The form is renamed to a console-named
  -- restoration at m4, Bucket B I2, §5.2; the end state
  -- asserted here is identical, row stays green.)
  describe('slot restoration on project stop', function()

    it('no project handler remains after stop', function()
      love.keypressed = function() end
      F.cc:stop_project_run()
      assert.equal(
        Controller._defaults.keypressed, love.keypressed)
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'a' }, F.console:get_text())
    end)
  end)

  -- Legacy text solicitation (§4.5): one successful submit both
  -- fills the poll handle and closes the widget; guarded
  -- refusals warn (never silent). The path retires at m8.
  describe('legacy text solicitation #legacy', function()

    it('a submit fills the handle and closes', function()
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

    it('a guarded refusal warns, never silent', function()
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

  -- Widget activation / reset (§4.6): driven through the public
  -- surface (compy.input.show/hide), asserted on the widget's
  -- observable content. The "no cancel chain" facts are
  -- stable-now; they flip at m6, when hide()/cancel fire a
  -- chain.
  describe('widget activation and reset', function()

    it('re-activation without force warns + no-ops', function()
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

    it('re-activation with force reapplies text', function()
      local input = F.compy_input()
      input.show({ text = 'original' })
      input.show({ force = true, text = 'replaced' })
      assert.same({ 'replaced' }, F.singleton:get_text())
    end)

    it('force without text leaves content intact', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.show({ force = true })
      assert.same({ 'keep' }, F.singleton:get_text())
    end)

    it('a fresh activation with no text is empty', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.hide()
      input.show()
      assert.is_true(F.singleton:is_empty())
    end)

    -- After hide the widget is no longer the surface the active
    -- route forwards to, so input reaches the console route.
    it('hide deactivates the widget', function()
      local input = F.compy_input()
      input.show()
      input.hide()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)

    -- A oneshot submit pushes userinput, which deactivates the
    -- widget; subsequent input reaches the console route.
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

  -- Hidden widget does not consume (§2C) [owner-minted: a fresh
  -- owner ruling (prompt12) + common logic — no user intent to
  -- modify an off-screen surface — NOT a reverse-engineered,
  -- code-preserved invariant]. An event arriving while the
  -- widget is hidden does not mutate widget state; it reaches
  -- the active route instead. Intra-route rule; inter-route
  -- dispatch is unchanged.
  describe('a hidden widget does not consume', function()

    it('input while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.session.type('Z')
      assert.same({ 'keep' }, F.singleton:get_text())
      assert.same({ 'Z' }, F.console:get_text())
    end)
  end)

  -- Editor block navigation at the buffer limit (editor-route
  -- behaviour, not framework routing). Exercises block-nav
  -- INDIRECTLY through the at-limit condition: only an up/down
  -- at the vertical limit escalates to block navigation. Guards
  -- the later is_at_limit line-scope rewrite from regressing
  -- whole-input block nav. (editor_session, used unchanged.)
  describe('editor block navigation at the limit #editor',
    function()

      before_each(function()
        love.state.app_state = 'editor'
      end)

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

  -- ====================================================
  -- Bucket D — CHARACTERIZE-PROVISIONAL (factual today)
  -- Current behaviour EXPECTED TO CHANGE, with no stakeholder
  -- mandate — NOT preserve-contracts. Each asserts only
  -- verifiable present behaviour; any "how it should become" is
  -- a comment, so a deliberate change reads as expected.
  -- ====================================================
  describe('provisional — expected to change, no mandate',
    function()

      -- inspect (§3.4, OWNER RULING PENDING): under inspect the
      -- console REPL owns the input surface; a shown project
      -- widget is not honoured; input is not dead. The owner
      -- deliberately kept this assumption — revisit when the
      -- routing model lands.
      it('inspect: the console owns the surface', function()
        F.show_widget()
        F.console:add_text('ab')
        love.state.app_state = 'inspect'
        F.session.type('Z')
        assert.same({ 'abZ' }, F.console:get_text())
        assert.is_true(F.singleton:is_empty())
      end)

      -- wheel (§3.7): the gateway has no wheel entry, so the
      -- framework forwards nothing — only a project's
      -- love.wheelmoved consumes it (no-op default). "Never the
      -- widget" is mechanism-by-omission, not a designed
      -- asymmetry. Intended shape (not asserted): project
      -- pass-through, opt-in consume.
      it('wheel has no framework gateway entry', function()
        assert.is_nil(F.session.handlers.wheelmoved)
      end)

      -- keyreleased under a widget (§3.3 note): today the
      -- overlay gate diverts the release to the widget, so a
      -- project release handler is bypassed. Possibly a defect
      -- to fix, not a contract to keep — expected to change
      -- with the gate removal.
      it('a release under a widget is not routed', function()
        local got = 0
        love.state.app_state = 'running'
        love.keyreleased = function() got = got + 1 end
        F.show_widget()
        F.session.release('a')
        assert.equal(0, got)
      end)
    end)

  -- ====================================================
  -- Bucket C — MECHANISM-GUARD (NFR; not behaviour)
  -- Genuine object-lifecycle guards. Labelled so no reader
  -- mistakes them for behaviour contracts (the behaviour they
  -- once stood in for is covered by the PRESERVE rows, through
  -- the public surface). These intentionally poke the singleton
  -- mechanism (identity / allocation), which is exactly what an
  -- NFR guard is for.
  -- ====================================================
  describe('mechanism / NFR guards — not behaviour', function()

    -- Singleton identity: the same UserInputController instance
    -- backs the widget across show/hide cycles.
    it('the widget keeps identity across cycles', function()
      F.show_widget()
      local first = love.state.user_input.C
      F.singleton:hide()
      F.show_widget()
      assert.equal(first, love.state.user_input.C)
    end)

    -- No reallocation per input session (NFR-1): the backing
    -- model is reused, never rebuilt, across activations.
    it('no widget model is reallocated', function()
      local m1 = F.singleton.model
      F.show_widget()
      F.singleton:hide()
      F.show_widget()
      assert.equal(m1, F.singleton.model)
    end)
  end)

  -- ====================================================
  -- Bucket B — IMPLEMENT (forward contracts; pending → green)
  -- Carried pending with greppable DEFERRED (0.1.0-mN) markers
  -- at the milestone that greens each. Bodies document the
  -- target assertion on the PUBLIC API; none of it exists in
  -- src/ yet.
  -- ====================================================
  describe('forward contracts (pending until implemented)',
    function()

      -- DEFERRED (0.1.0-m4): I1 — the overlay gate is removed,
      -- so project key/text/release reach the project route
      -- even while a widget is up, instead of being dropped by
      -- the gate (§5.1).
      pending('project keys reach the project sink',
        function()
          local got = { }
          F.running_project('keypressed', function(k)
            got[#got + 1] = k
          end)
          F.show_widget()
          F.session.press('a')
          assert.same({ 'a' }, got)
        end)

      -- DEFERRED (0.1.0-m4): I2 — on stop the
      -- keypressed/textinput slots are restored to
      -- ConsoleController as a NAMED target, not as an emergent
      -- property of reinstalling defaults (§5.2). Same end
      -- state the 'slot restoration' PRESERVE row guards.
      pending('stop names the console as restored route',
        function()
          F.cc:stop_project_run()
          assert.equal(F.console, F.cc:active_keyboard_route())
        end)

      -- DEFERRED (0.1.0-m4): I3 — native-handler coexistence
      -- (§5.3, D-9): a project that sets its own native
      -- love.keypressed and no compy.input surface has that
      -- handler driven by the project route while the widget is
      -- hidden, and the text-editing sink while it is shown —
      -- same end state as today, founded on the active route
      -- not widget presence. (Native is legitimate.)
      pending('a native handler coexists with the sink',
        function()
          local native = 0
          F.cc:provision_native(function()
            native = native + 1
          end)
          F.session.press('a')
          assert.equal(1, native)
          F.show_widget()
          F.session.press('a')
          assert.equal(1, native)
        end)

      -- DEFERRED (0.1.0-m4): I4 — the gateway slot widens from
      -- function(k) so isrepeat is no longer dropped (§5.4-m4).
      -- Per D-α the WHOLE keypressed path carries the uniform
      -- (k, keys_pressed, isrepeat) triple — the SINK included,
      -- not only the project callback.
      pending('the keypressed path carries the triple',
        function()
          local seen
          F.show_widget()
          F.singleton.keypressed = function(_, keys, isr)
            seen = { keys, isr }
          end
          F.session.repeat_press('a')
          assert.is_table(seen[1])
          assert.is_true(seen[2])
        end)

      -- DEFERRED (0.1.0-m5a): I5 — compy.input.on_key_pressed
      -- AND on_text_entered are exposed; assigning one replaces
      -- the sink, firing dispatches to the project (default =
      -- the sink) (design §4).
      pending('on_key_pressed and on_text_entered exist',
        function()
          local k_got, t_got
          local input = F.compy_input()
          input.on_key_pressed = function(k) k_got = k end
          input.on_text_entered = function(t) t_got = t end
          F.session.press('a')
          F.session.type('Z')
          assert.equal('a', k_got)
          assert.equal('Z', t_got)
        end)

      -- DEFERRED (0.1.0-m5): I6 — isrepeat is delivered to the
      -- project keyboard callback as the uniform triple
      -- (§5.4-m5). Distinct from I4 (which only stops the
      -- gateway dropping it): here it reaches on_key_pressed —
      -- false on a fresh press, true on a repeat.
      pending('on_key_pressed receives isrepeat',
        function()
          local seen = { }
          F.compy_input().on_key_pressed =
            function(_, _, isr) seen[#seen + 1] = isr end
          F.session.press('a')
          F.session.repeat_press('a')
          assert.same({ false, true }, seen)
        end)

      -- DEFERRED (0.1.0-m5b): I7 — compy.input.handlers[combo]
      -- dispatch on the normalised combo string (§4.2).
      -- Fresh-vs-repeat keying is PROVISIONAL (§6 D-C, owner
      -- not-yet-ruled); existing combos keep their behaviour
      -- unless explicitly altered — repeat semantics are NOT
      -- asserted as settled here.
      pending('combo handlers dispatch on the combo',
        function()
          local fired
          F.compy_input().handlers =
            { ['ctrl+s'] = function() fired = true end }
          mock.keystroke('C-s', F.session.press, false)
          assert.is_true(fired)
        end)
    end)

  -- ====================================================
  -- M6 / M7 forward — structural anchor only. Names the
  -- not-yet-authored forward contracts so they are not
  -- forgotten; deliberately NOT fleshed out (scope fence:
  -- m4/m5). See input-contracts.md §5 scope note.
  -- ====================================================
  describe('later forward contracts — not yet authored',
    function()
      pending(
        'submit/cancel chains, on_limit_reached, ' ..
        'configure/set_text/cursor, force-vs-configure')
    end)
end)
