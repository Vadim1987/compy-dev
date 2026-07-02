-- Input contracts — the framework's behavioural input
-- guarantees.
--
-- Doc A (the contract record this suite enforces):
--   doc/development/wip/77-new-input-api/notes/
--   input-contracts.md
-- Cited below as "doc A §N". Every test traces to a doc A
-- clause; the citation lives in a comment, never in the
-- test description.
--
-- The one routing invariant (doc A §5.9): inter-route
-- dispatch is EXCLUSIVE for every event type. Each event
-- reaches exactly ONE route — the one fixed by the active
-- screen mode — never zero, never two. Intra-route
-- forwarding (a route driving a surface it activated) is
-- the route's private affair and is never asserted as a
-- second delivery.
--
-- Vocabulary (doc A §3): ROUTE = the consumer an event is
-- dispatched to; WIDGET = a route-managed input surface,
-- never a slot occupant; SINK = a route's last-resort
-- disposition. Tests assert observable outcomes (state or
-- text changed) or receipt at a public seam (a project's
-- own love.* callback) — never a method-name spy, never
-- love.state internals as behaviour.
--
-- Key events vs text events (doc A §2): LÖVE fires
-- keypressed for EVERY physical key and textinput only for
-- OS-processed character-producing keys — pressing 'q'
-- fires both. The "keypressed = control, textinput =
-- characters" split is compy's own convention, not a LÖVE
-- guarantee; the suite exercises both channels separately
-- for that reason.
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

-- A standalone editor session, used ONLY by the block-nav
-- row at the bottom (an editor-internal behaviour, not a
-- routing contract — see the OPEN marker there). It drives
-- EditorController directly, below the love.handlers gate,
-- which is why no routing row may use it.
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
  --
  -- Keyboard, text and pointer are EXCLUSIVE on the
  -- active route (doc A §5.1-5.5): the mode-fixed route
  -- receives, the others do not. One subgroup per mode
  -- below, so a missing mode x channel cell is visible on
  -- sight (doc A §4 completeness table). All rows drive
  -- the REAL love.handlers gate (tests/helpers/
  -- input_session.lua).
  -- ====================================================

  describe('routing: console mode', function()

    -- Setup seeds text via the model; the assertion path
    -- (backspace) travels love.handlers -> gate -> console,
    -- so routing itself is what is witnessed. (doc A §5.1)
    it('routes keys to the console', function()
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'a' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    -- (doc A §5.2)
    it('routes text to the console', function()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    -- SURFACED GAP (doc A §5.3): console delivery of a
    -- release has no observable mutation today (a release
    -- carries no text), so only the project route is
    -- directly witnessed. Named here so the cell is
    -- visible, not silent.
    pending('routes the key release to the console')

    -- The production singleton disables selection, so an
    -- observable selection on the console route witnesses
    -- active-route pointer delivery. The precondition
    -- assert pins causality: no selection existed before
    -- the pointer events. (doc A §5.5)
    it('routes the pointer to the console', function()
      F.console:set_text({ 'aa', 'bb', 'cc' })
      assert.is_false(F.console.model:has_selection())
      F.session.mousepressed(10, 540, 1, false, 1)
      F.session.mousereleased(40, 508, 1, false, 1)
      assert.is_true(F.console.model:has_selection())
    end)
  end)

  describe('routing: editor mode', function()

    before_each(function()
      love.state.app_state = 'editor'
      F.cc.editor:open('t.lua', '', function()
        return true
      end)
    end)

    -- The key channel witnessed on its own: text arrives
    -- via textinput, then a KEY event (backspace) mutates
    -- the editor buffer — travelling the same gate.
    -- (doc A §5.1; reviews/M4-0-04.md finding 1)
    it('routes keys to the editor', function()
      F.session.type('q')
      F.session.press('backspace')
      assert.is_true(F.cc.editor.input:is_empty())
      assert.is_true(F.console:is_empty())
    end)

    -- (doc A §5.2)
    it('routes text to the editor', function()
      F.session.type('q')
      assert.same({ 'q' }, F.cc.editor.input:get_text())
      assert.is_true(F.console:is_empty())
    end)

    -- keyreleased under editor: the console/editor fork is
    -- CC-internal and out of #77's blast radius (doc A
    -- §5.3, §8) — foundation for the future console/editor
    -- migration; no suite row is owed under this feature.

    -- SURFACED GAP (doc A §5.5): the production editor
    -- widget disables selection, so pointer delivery to
    -- the editor route has no observable outcome without
    -- extra scaffolding. Named, not silently absent.
    pending('routes the pointer to the editor')
  end)

  -- Search (doc A §5.8): a third full MVC input triad
  -- under the editor, absent from the design corpus; out
  -- of #77's blast radius (doc A §8) but part of the mode
  -- x channel grid, so the gap is named, not silent.
  describe('routing: editor search', function()
    pending('routes keys and text to the search widget')
  end)

  describe('routing: project run', function()

    -- The project's own love.* callback is the public seam
    -- witnessing delivery to the project route. (doc A
    -- §5.1)
    it('routes keys to the project', function()
      local got = { }
      F.running_project('keypressed', function(k)
        got[#got + 1] = k
      end)
      F.session.press('a')
      assert.same({ 'a' }, got)
      assert.is_true(F.console:is_empty())
    end)

    -- (doc A §5.2)
    it('routes text to the project', function()
      local got = { }
      F.running_project('textinput', function(t)
        got[#got + 1] = t
      end)
      F.session.type('Z')
      assert.same({ 'Z' }, got)
      assert.is_true(F.console:is_empty())
    end)

    -- A release carries no text mutation, so exclusivity
    -- is observed at the project's release callback: the
    -- active route receives exactly once. (doc A §5.3)
    it('routes the key release to the project', function()
      local got = 0
      F.running_project('keyreleased', function()
        got = got + 1
      end)
      F.session.release('a')
      assert.equal(1, got)
    end)

    -- Negative control: the console is seeded with the
    -- SAME text and coordinates that produce a selection
    -- in the console-mode row above; with the project
    -- route active no selection may appear — the pointer
    -- went to exactly one route. (doc A §5.5)
    it('routes the pointer to the project', function()
      local got = 0
      F.running_project('mousepressed', function()
        got = got + 1
      end)
      F.console:set_text({ 'aa', 'bb', 'cc' })
      F.session.mousepressed(10, 540, 1, false, 1)
      assert.equal(1, got)
      assert.is_false(F.console.model:has_selection())
    end)

    -- SURFACED GAP (doc A §5.6): touch has no gateway
    -- entry today and both the widget and route touch
    -- handlers are no-ops, so delivery is not black-box
    -- observable. Greens when a touch consumer lands.
    pending('touch reaches the active route')
  end)

  -- Global shortcuts are non-consuming (doc A §6.3): a
  -- framework shortcut fires its effect AND the key still
  -- reaches its route. Carried as-is; whether this is a
  -- mandated invariant or incidental is recorded as open
  -- in doc A §6.3, not re-litigated here.
  describe('global shortcuts do not consume the key',
    function()

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

      -- Play mode = the end-user runtime (cfg.mode =
      -- 'play', vs 'dev'); it narrows the shortcut set so
      -- a player cannot manage projects: restart/profile
      -- stay live, quit/stop/quickswitch do not (doc A
      -- §6.3). Driven on an isolated play-mode gate: the
      -- shared fixture gate is built in dev mode, so a
      -- private stub controller is wired and the shared
      -- love.handlers saved/restored around it.
      it('play mode narrows the active shortcut set',
        function()
          local calls = { }
          local stub = {
            cfg = { mode = 'play' },
            restart = function() calls.restart = true end,
            quit_project = function() calls.quit = true end,
            stop_project_run = function() end,
            keypressed = function() end,
          }
          local saved    = love.handlers
          local saved_kp = love.keypressed
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

  -- Framework click detection (doc A §6.7): a derived
  -- path over raw pointer delivery, asserted on outcomes
  -- against the project-defined handlers (default no-ops).
  -- The 0.4s / 2.5px constants are mechanism. In scope
  -- because M4 rewires the handler slots this path hangs
  -- off — it is a regression surface, not a routing rule.
  describe('framework click detection', function()

    it('a single click confirms after the window',
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

    it('pointer drift suppresses the single click',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
        F.set_compy_handler('singleclick', bump)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.set_mouse_pos(400, 400)
        F.update(0.5)
        assert.equal(0, hit)
      end)

    it('a double click calls the project handler',
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

  -- Project stop returns input to the console (doc A
  -- §6.4): a project's native handler is installed while
  -- it runs; after stop it receives nothing and typing
  -- lands in the console again. Asserted end-to-end on
  -- behaviour — who receives — not on slot identity. (The
  -- m4 form names the console as the restored target,
  -- Bucket B below; the end state guarded here is
  -- identical, this row stays green.)
  describe('project stop returns input to the console',
    function()

      it('the console receives after stop', function()
        local got = 0
        F.running_project('keypressed', function()
          got = got + 1
        end)
        F.cc:stop_project_run()
        F.console:add_text('ab')
        F.session.press('backspace')
        assert.equal(0, got)
        assert.same({ 'a' }, F.console:get_text())
      end)
    end)

  -- Legacy text solicitation (doc A §6.5). "Legacy" is
  -- the WIRING (env.user_input()/input_text(), the poll
  -- handle), which retires at 0.1.0-m8; the behaviour it
  -- exercises — oneshot submit fills and closes — persists
  -- into the new API (0.1.0-m6 chains). Guarded refusals
  -- warn, never silently drop (the C2 warn-don't-swallow
  -- convention) — that is current, tested behaviour, not
  -- a forward promise.
  describe('legacy text solicitation #legacy', function()

    -- Fully event-driven: the text arrives through the
    -- real gate (the shown widget is the soliciting
    -- surface), the submit is a real return keypress.
    it('a submit fills the handle and closes', function()
      local env = F.cc:get_project_env()
      local ref = env.user_input()
      env.input_text('prompt?')
      local closed = false
      love.event.push = function(ev)
        if ev == 'userinput' then closed = true end
      end
      F.session.type('4')
      F.session.type('2')
      F.session.press('return')
      assert.equal('42', ref())
      assert.is_true(closed)
    end)

    it('a refused solicitation warns, never silently',
      function()
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

  -- Widget activation / reset (doc A §6.6), driven through
  -- the public project surface. F.compy_input() resolves
  -- project_env.compy.input — exactly what a project sees.
  -- show({ text = ... }) seeds the widget's CONTENT (the
  -- editable text); the prompt label is a separate,
  -- untested-here concern (doc A §6.6). The "no cancel
  -- chain" facts are stable-now; they flip at 0.1.0-m6.
  describe('widget activation and reset', function()

    it('a fresh activation with no text is empty',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.hide()
        input.show()
        assert.is_true(F.singleton:is_empty())
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
        assert.same({ 'first' }, F.singleton:get_text())
      end)

    -- force = live reconfiguration of an ACTIVE widget;
    -- today only the text subset takes effect (doc A
    -- §6.6 reset semantics; scope widens at 0.1.0-m7).
    it('re-activation with force reapplies text',
      function()
        local input = F.compy_input()
        input.show({ text = 'original' })
        input.show({ force = true, text = 'replaced' })
        assert.same({ 'replaced' },
          F.singleton:get_text())
      end)

    -- force with NO text: a reconfiguration that changes
    -- nothing — content survives (it is not a hidden
    -- reset; doc A §6.6).
    it('force without text leaves content intact',
      function()
        local input = F.compy_input()
        input.show({ text = 'keep' })
        input.show({ force = true })
        assert.same({ 'keep' }, F.singleton:get_text())
      end)

    -- After hide the widget stops being the surface the
    -- route forwards to: typed text lands in the console,
    -- not the widget (whose non-mutation is asserted in
    -- the hidden-widget row below).
    it('hide deactivates the widget', function()
      local input = F.compy_input()
      input.show()
      input.hide()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)

    -- Oneshot submit is exercised through the legacy
    -- wiring because that is the only solicitation
    -- surface that exists today; the deactivation
    -- behaviour itself carries into the m6 chains.
    it('a oneshot submit deactivates the widget',
      function()
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

  -- Hidden widget does not consume (doc A §3(C),
  -- owner-minted PRESERVE): an event arriving while the
  -- widget is hidden never mutates widget state — it
  -- reaches the active route instead. Intra-route rule;
  -- inter-route dispatch unchanged.
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

  -- OPEN (owner call, carried from the review passes):
  -- this row tests editor-INTERNAL block navigation at
  -- the buffer limit, not a doc A routing contract. It
  -- drives EditorController directly (editor_session),
  -- below the gate. Kept because it guards the later
  -- is_at_limit line-scope rewrite from regressing
  -- whole-input block nav; disposition (relocate to
  -- tests/editor/, or recut as a boundary-signal
  -- contract) is the human's call — see the punch list.
  -- REVIEW: this test in thsi form should be relocated under tests/editor. Input contract should test delivery *and only if editor really relies on it* (situation where editor *may* not rely on it: just counting keystrokes itself and translating them into files' coordinates with every move -- therefore block-nav is triggered not by event emitted by input widget, but by the mere fact that internal navigation map says the cursor in 'project space' is no more inside current selection lines)
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
  -- Current behaviour EXPECTED TO CHANGE, no stakeholder
  -- mandate — NOT preserve-contracts. Each asserts only
  -- verifiable present behaviour, so a deliberate change
  -- reads as expected while an accidental one still
  -- fails the build.
  -- ====================================================
  describe('provisional — expected to change, no mandate',
    function()

      -- inspect (doc A §5.4, OWNER RULING PENDING): under
      -- inspect the console REPL owns the input surface; a
      -- shown project widget is not honoured; input is not
      -- dead. Asserted live (not pending) so an ACCIDENTAL
      -- change still fails; revisit when the m4 routing
      -- model lands.
      it('inspect: the console owns the surface', function()
        F.show_widget()
        F.console:add_text('ab')
        love.state.app_state = 'inspect'
        F.session.type('Z')
        assert.same({ 'abZ' }, F.console:get_text())
        assert.is_true(F.singleton:is_empty())
      end)

      -- wheel (doc A §5.7): the gateway has no wheel
      -- entry, so the framework forwards nothing; only a
      -- project's own love.wheelmoved consumes it. No
      -- example project consumes it today. Mechanism-by-
      -- omission, not a designed asymmetry; intended
      -- forward shape (not asserted): project
      -- pass-through, opt-in consume.
      it('wheel has no framework gateway entry', function()
        assert.is_nil(F.session.handlers.wheelmoved)
      end)

      -- keyreleased under a widget (doc A §5.3 note,
      -- provenance: assessment/keyreleased-isrepeat-
      -- events.md): today the overlay gate diverts the
      -- release to the widget, bypassing a project release
      -- handler. Possibly a defect, not a contract —
      -- expected to change with the gate removal.
      it('a release under a widget is not routed',
        function()
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
  -- Genuine mechanism guards, labelled so no reader
  -- mistakes them for behaviour contracts. These
  -- intentionally poke internals (identity, allocation,
  -- the held-key table), which is exactly what an NFR
  -- guard is for.
  -- ====================================================
  describe('mechanism / NFR guards — not behaviour',
    function()

      -- Held-key set lifecycle (doc A §6.1, mechanism):
      -- a key is added on press and removed on release
      -- BEFORE dispatch, so the set already reflects the
      -- event when a consumer runs. The route-observable
      -- form — the set handed along as a read-only proxy
      -- in the keypressed triple — is the Bucket B
      -- forward (doc A §7.4); until it lands, the guard
      -- necessarily reads Controller.keys_pressed.
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

      it('the released key is gone before dispatch',
        function()
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

      -- Folding lctrl/rctrl to 'ctrl' is combo_string's
      -- job (doc A §6.2, covered in keys_pressed_spec),
      -- not the held set's.
      it('left/right names stay raw in the held set',
        function()
          F.session.press('lctrl')
          assert.is_true(Controller.keys_pressed['lctrl'])
          assert.is_nil(Controller.keys_pressed['ctrl'])
        end)

      -- Singleton identity across show/hide (NFR): today
      -- only the overlay singleton is wired; wiring the
      -- console/editor/search widgets to it is a future
      -- consideration (doc A §8), not asserted here.
      it('the widget keeps identity across cycles',
        function()
          F.show_widget()
          local first = love.state.user_input.C
          F.singleton:hide()
          F.show_widget()
          assert.equal(first, love.state.user_input.C)
        end)

      -- No reallocation per input session (NFR-1): the
      -- backing model is reused across activations.
      it('no widget model is reallocated', function()
        local m1 = F.singleton.model
        F.show_widget()
        F.singleton:hide()
        F.show_widget()
        assert.equal(m1, F.singleton.model)
      end)
    end)

  -- ====================================================
  -- Bucket B — IMPLEMENT (forward contracts; pending →
  -- green at the named milestone). Greppable DEFERRED
  -- (0.1.0-mN) markers; bodies document the target
  -- assertion on the PUBLIC API — none of it exists in
  -- src/ yet, and the implementer adapts a body to the
  -- landed API shape when greening it.
  -- ====================================================
  describe('forward contracts (pending until implemented)',
    function()

      -- DEFERRED (0.1.0-m4): the overlay gate is removed;
      -- project keys reach the project's controller even
      -- while a widget is up, instead of being dropped.
      -- The controller then dispatches internally: combo
      -- handlers, the project's own love.keypressed, the
      -- userinput singleton as sink (doc A §7.1).
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

      -- DEFERRED (0.1.0-m4): on stop the keyboard/text
      -- slots are restored to the console as a NAMED
      -- target, not as an emergent effect of reinstalling
      -- defaults (doc A §7.2). The behavioural end state
      -- is already guarded green by the PRESERVE row
      -- ("project stop returns input to the console");
      -- this pending guards only the named-target API
      -- shape m4 introduces — assert on whatever public
      -- accessor m4 lands.
      pending('stop names the console as restored route',
        function()
          F.cc:stop_project_run()
          assert.equal(F.console,
            F.cc:active_keyboard_route())
        end)

      -- REVIEW: what else could bring up the widget if project does not? A bit strange test. Testing just default keys delivery would be fine. Also I think our design assumes keys are anyway delivered into project input controller -- whether they reach text sink (if its installed) is determined on what projects' keypressed and combo handlers return -- we discussed convention of returning truthy/falsey value to enable/disable propagation
      -- DEFERRED (0.1.0-m4): native-handler coexistence
      -- (doc A §7.3, design D-9). Plainly: a project that
      -- installs its own love.keypressed (and never opens
      -- a compy.input surface) keeps receiving keys while
      -- no widget is shown; while a widget IS shown, keys
      -- go to the text-editing sink instead — same end
      -- state as today, but founded on the active route,
      -- not on widget presence. provision_native is a
      -- placeholder for the m4 auto-provision wrapper.
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

      -- DEFERRED (0.1.0-m4): today the gateway slot is
      -- function(k) — isrepeat is dropped at the door. m4
      -- widens the slot so every keypressed consumer,
      -- the sink included, receives the uniform
      -- (k, keys_pressed, isrepeat) triple (doc A §7.4;
      -- §9 resolves that the sink is included).
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

      -- DEFERRED (0.1.0-m5a): compy.input.on_key_pressed
      -- and on_text_entered are exposed; assigning one
      -- replaces the sink for that channel (design.md §4).
      -- OPEN (design question, surfaced in review): does
      -- on_text_entered fire per textinput character (as
      -- drafted here) or once per submitted block on
      -- return? Settle at m5a commissioning; the body
      -- follows the ruling.
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

      -- DEFERRED (0.1.0-m5): isrepeat reaches
      -- on_key_pressed via the same uniform triple —
      -- false on a fresh press, true on a repeat.
      -- Distinct from the m4 row (which only stops the
      -- gateway dropping it); asserted together with the
      -- keys_pressed slot of the triple.
      pending('on_key_pressed receives isrepeat',
        function()
          local seen = { }
          F.compy_input().on_key_pressed =
            function(_, _, isr) seen[#seen + 1] = isr end
          F.session.press('a')
          F.session.repeat_press('a')
          assert.same({ false, true }, seen)
        end)

      -- DEFERRED (0.1.0-m5b): compy.input.handlers[combo]
      -- dispatches on the normalised combo string (doc A
      -- §6.2). Two provisionals ride this row, neither
      -- asserted as settled: fresh-vs-repeat keying (doc
      -- A §9, owner not-yet-ruled; existing combos keep
      -- their behaviour unless explicitly altered) and
      -- HOW the engine collects combo definitions from a
      -- project (undefined until m5b commissioning).
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
  -- 0.1.0-m6 / m7 forward — structural anchor only.
  -- Names the not-yet-authored forward contracts so they
  -- are not forgotten; deliberately NOT fleshed out
  -- (scope fence: m4/m5 — doc A §7 scope note).
  -- ====================================================
  describe('later forward contracts — not yet authored',
    function()
      pending(
        'submit/cancel chains, on_limit_reached, ' ..
        'configure/set_text/cursor, force-vs-configure')
    end)
end)
