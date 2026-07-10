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
  -- REVIEW: both cases need reconsideration/refinement later, they look plausible in spirit but they do not demonstrate which exact production scenario is tested, and mastering framework state via low-level configuration flags is suspicious (if we mock the real production path like project run, it should be explicit, not imitated)
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
    -- DEPRECATED (E32/session39, AC-39): exercises the
    -- oneshot/push('userinput') machinery AC-25 deletes at
    -- m5c. Lifecycle: red on AC-25 delete → pending() →
    -- delete once the submit→on_text_entered→deactivate
    -- behaviour is green through the new chain. busted has
    -- no xfail; pending() is the skipped state.
    it('a submit fills the handle and closes #deprecated', function()
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
  -- REVIEW: TODO: need to test prompt-labelling and relabelling
  describe('widget activation and reset', function()

    it('a fresh activation with no text is empty',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.hide()
        input.show()
        assert.is_true(F.singleton:is_empty())
      end)
    
    it('a fresh activation with text sets text',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        assert.same({ 'hello' }, F.singleton:get_text())
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
    -- DEPRECATED (E32/session39, AC-39): calls
    -- F.session.handlers.userinput() directly (nil after
    -- AC-25 ⇒ error). Same lifecycle as the submit row:
    -- red → pending() → delete when the new chain's
    -- deactivate step is green.
    it('a oneshot submit deactivates the widget #deprecated',
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
  -- REVIEW: whenever we migrate console to new API, we may stop silent consuming of input (to be confirmed yet) -- therefore assertions checking the console as hidden sink will break and will have to be updated
  describe('a hidden widget does not consume', function()

    it('input while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.session.type('Z')
      assert.same({ 'keep' }, F.singleton:get_text())
      assert.same({ 'Z' }, F.console:get_text())
    end)


    -- REVIEW: now I am concerned about the very concept. Was it in place before? (that console absorbs any interaction when project is active but widget is hidden) How it correlates with common logic? Will it mean somewhere in the console random keystrokes are accumulating? What for? User even does not see the console if project is running -- will it see a garbage on 'inspect'? what is user occasionally types some destructive or ambiguous command while project is running -- will console evaluate/execute it? if so, its dangerous and strange; if not, there's no point in routing input to console. MY UNDERSTANDING IS: if "project/editor" is active -- its an active route -- events travel down through it. Whether they end up in user_widget (shown) or in noop (if widget is hidden), or intercepted by project combos/handlers and interpreted other way -- is totally the responsibility of the route (e.g. project input controller or editor controlle or console controller). Is this logic reasonable?
    -- REVIEW: admitting change is nice, but it will read weirdly half a year later -- nobody will know what 'the overlay gate gone' even means...
    -- REVIEW: once again -- the very concept of console secretly and meaningfully processing user input while not being on the screen looks weird to me.
    -- The keypressed sibling: with the overlay gate gone
    -- the key channel also travels the route while the
    -- widget is hidden — the key mutates the active
    -- route's model (console), and the hidden widget's
    -- content, history and cursor stay untouched.
    it('a key while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'keep' }, F.singleton:get_text())
      assert.same({ 'a' }, F.console:get_text())
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
  -- REVIEW: this test in this form should be relocated under tests/editor. Input contract should test delivery *and only if editor really relies on it* (situation where editor *may* not rely on it: just counting keystrokes itself and translating them into files' coordinates with every move -- therefore block-nav is triggered not by event emitted by input widget, but by the mere fact that internal navigation map says the cursor in 'project space' is no more inside current selection lines)
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
      -- REVIEW: its no more 'expected to change', going to be correct invariant/contract?
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

      -- keyreleased under a widget: the raw-slot form of this
      -- Bucket-D row (the release reaches the occupant even with
      -- a widget up) is now covered end-to-end through the real
      -- chain by the AC-36 keyreleased rows (a native release
      -- participant fires regardless of widget-shown state and,
      -- on a falsey return, propagates downstream to the sink
      -- without swallowing — exactly the L588 REVIEW's "correct
      -- test"). Deleted per Scope-10(c) now that those rows are
      -- green; see the four-tier dispatch chain block below.
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
      -- REVIEW: when we come to testing *propagation* of keypressed into consumers, we will need to ensure its the same table -- OR replace this implementation test with end-to-end test ensuring that what was pressed (all keys held) is what is received at consumer
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
      -- REVIEW: why not set 'ctrl' as pressed too? Much cheaper, no?
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
      -- REVIEW: do we have pending tests outlined for future consideration?
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

      -- On stop the keyboard route is the console again. The
      -- behavioural end state is guarded green by the PRESERVE
      -- row ("project stop returns input to the console"); this
      -- row keeps the test-scoped Controller.active_keyboard_
      -- route() accessor honest (C23: no unconsumed PUBLIC
      -- surface, but the manual-verification driver reads it).
      -- The full AC-29 teardown retarget (participants unwired,
      -- widget silently hidden as stop's DISTINCTIVE contract)
      -- rides the route-connection-lifecycle chunk, not this
      -- one; see M5c Scope 10(a) + notes/talk/
      -- m5c-suite-reconciliation-open-contradictions.md.
      -- REVIEW: should be removed after recheck -- an artifact of deviated development
      it('stop names the console as restored route',
        function()
          F.cc:stop_project_run()
          assert.equal(F.cc,
            Controller.active_keyboard_route())
        end)

      -- on_text_entered is the SUBMIT output (widget vocabulary,
      -- R1): fired once at Enter with the assembled text — NOT
      -- the per-character chain callback (that is on_text_input,
      -- covered live in the dispatch-chain block below, AC-40).
      -- The submit output + its before_/after_ chain are the
      -- submit/cancel chunk (spec §5), so this half stays
      -- pending here; greening it now would re-encode the R1
      -- per-char-vs-block trap (AC-40).
      pending('on_text_entered delivers the submitted text')
    end)

  -- ====================================================
  -- The four-tier dispatch chain (0.1.0-m5c, spec §2).
  -- All rows drive the REAL project route: F.activate_
  -- project() installs the ProjectInputController as the
  -- slot occupant (app_state='running') via the same
  -- Controller.set_user_handlers path a run calls, and
  -- returns the project-facing compy.input surface. The
  -- observable seams are the widget's text (the sink) and
  -- the callbacks a project registers — never a spy on an
  -- internal method (except the one sink-signature row,
  -- which patches the shared singleton and restores it).
  -- ====================================================
  describe('the four-tier dispatch chain #m5c', function()

    -- Press a modifier key then a trigger so the held set
    -- (Controller.keys_pressed) carries the modifier and the
    -- combo serialises to 'ctrl+…' (spec §1) — a real chord.
    local function chord(mod, k)
      F.session.press(mod)
      F.session.press(k)
    end

    -- ---- order, consume, fall-through (AC-1..AC-5, AC-38) --

    -- AC-1/AC-38: a tier-1 framework handler runs first and,
    -- returning truthy, consumes — no lower tier sees the event.
    it('a framework handler consumes before lower tiers',
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

    -- AC-1/AC-2/AC-3/AC-38: an unconsumed event descends every
    -- tier IN ORDER and reaches the sink (backspace edits the
    -- shown widget — the sink's observable trace).
    it('an unconsumed event descends every tier to the sink',
      function()
        local order = { }
        local fw = Controller.project_input.framework_handlers
        local input = F.activate_project()
        fw.keypressed['backspace'] =
            function() order[#order + 1] = 'fw' end
        input.handlers.keypressed['backspace'] =
            function() order[#order + 1] = 'combo' end
        input.on_key_pressed =
            function() order[#order + 1] = 'cb' end
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'fw', 'combo', 'cb' }, order)
        assert.same({ 'a' }, F.singleton:get_text())
      end)

    -- AC-2: a truthy combo handler (tier 2) stops the descent —
    -- neither the generic callback nor the sink runs.
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

    -- AC-4: consuming never removes a tier — the same callback
    -- fires again on the next event (configuration is permanent).
    it('consuming never removes a tier (R13)', function()
      local n = 0
      local input = F.activate_project()
      input.on_key_pressed =
          function() n = n + 1; return true end
      F.session.press('a')
      F.session.press('a')
      assert.equal(2, n)
    end)

    -- AC-5: assigning a generic callback replaces ONLY it; when
    -- it returns falsey the sink still runs for that event.
    it('assigning a callback replaces only it; sink still runs',
      function()
        local input = F.activate_project()
        F.show_widget({ text = 'ab' })
        input.on_key_pressed = function() return false end
        F.session.press('backspace')
        assert.same({ 'a' }, F.singleton:get_text())
      end)

    -- ---- combo tables: R14, normalisation (AC-6/7/41) -------

    -- AC-6/AC-7/AC-41: each channel has its OWN combo sub-table
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

    -- AC-6 (R14): the three tables are distinct; a keypressed
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

    -- ---- signatures + read-only proxy (AC-8, AC-9, AC-38) ---

    -- AC-8/AC-38: keypressed participants receive (k, proxy,
    -- isrepeat); isrepeat threads through to tier 3.
    it('keypressed carries (k, keys_pressed, isrepeat)',
      function()
        local seen
        local input = F.activate_project()
        input.on_key_pressed = function(k, keys, isr)
          seen = { k, keys, isr }; return true
        end
        F.session.repeat_press('a')
        assert.equal('a', seen[1])
        assert.is_table(seen[2])
        assert.is_true(seen[3])
      end)

    -- AC-38: isrepeat is false on a fresh press, true on repeat.
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

    -- AC-8: the keys_pressed argument is a READ-ONLY proxy —
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

    -- AC-8: the SINK is included in the uniform signature — it
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

    -- AC-9: a keyreleased participant sees the key ALREADY gone
    -- from the held set (removed at the gateway before dispatch).
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

    -- ---- defaults + hidden sink (AC-10, AC-11, AC-13) -------

    -- AC-10: the default generic callback neither edits nor
    -- consumes — the event falls through to the sink, which
    -- performs the edit.
    it('the default callback neither edits nor consumes',
      function()
        F.activate_project()
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'a' }, F.singleton:get_text())
      end)

    -- AC-11/AC-13: an event with no participant anywhere and a
    -- HIDDEN widget mutates nothing — the sink's internal no-op.
    it('no participant + hidden widget mutates nothing',
      function()
        F.activate_project()
        F.show_widget({ text = 'keep' })
        F.singleton:hide()
        F.session.press('backspace')
        assert.same({ 'keep' }, F.singleton:get_text())
      end)

    -- ---- tier-3: the on_* generic callback (AC-40, AC-36) ---

    -- AC-40: on_text_input is the PER-CHARACTER tier-3 textinput
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

    -- AC-36 (on_* install path): a truthy callback intercepts
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

    -- ---- tier-3: the native install path (AC-31, AC-36) -----

    -- AC-31/AC-36(a): a project native is a plain tier-3
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

    -- AC-36(b) native path: a truthy native intercepts the sink.
    it('a native returning truthy intercepts the sink',
      function()
        F.activate_project({
          keypressed = function() return true end,
        })
        F.show_widget({ text = 'ab' })
        F.session.press('backspace')
        assert.same({ 'ab' }, F.singleton:get_text())
      end)

    -- AC-36(c) native path: a falsey native falls through to
    -- the sink (asserted on the textinput channel too, so all
    -- three channels are covered across the native rows).
    it('a falsey native textinput falls through to the sink',
      function()
        F.activate_project({
          textinput = function() return false end,
        })
        F.show_widget()
        F.session.type('Z')
        assert.same({ 'Z' }, F.singleton:get_text())
      end)

    -- AC-36 native path, keyreleased channel: fires regardless
    -- of widget-shown state (case a) — the downstream half of
    -- the retired Bucket-D 'release under a widget' row.
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

    -- AC-31/AC-36 precedence (E30): an explicit on_* takes
    -- precedence over the captured native — the native never
    -- seeds the slot when an on_* is set (no "replace" relation).
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

    -- ---- the mutable/immutable boundary (AC-33) -------------

    -- AC-33: exactly the tier-3 callback slots are assignable;
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

    -- ---- widget outputs (AC-14/15/16/42a, chunk-2) ----------

    -- AC-16: the four widget outputs are project-assignable
    -- fields on compy.input (same boundary, widened allowlist).
    it('the four widget output fields are assignable',
      function()
        local input = F.compy_input()
        assert.has_no.errors(function()
          input.on_text_entered  = function() end
          input.on_limit_reached = function() end
          input.validator        = function() end
          input.highlighter      = function() end
        end)
      end)

    -- AC-16 (D-b): show(config) keys and field assignment hit
    -- the same underlying slots.
    it('show(config) and fields share one output slot',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ on_limit_reached = cb })
        assert.equal(cb, input.on_limit_reached)
        local hl = function() return { { } } end
        input.highlighter = hl
        input.show()
        assert.equal(hl, input.highlighter)
      end)

    -- AC-16 (D-b) cont.: on_text_entered and validator also
    -- reach the same slot via config key and via field write
    -- (settable-only here; firing/gating is chunk 3).
    it('show(config) shares on_text_entered slot',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ on_text_entered = cb })
        assert.equal(cb, input.on_text_entered)
      end)

    it('field write shares on_text_entered slot',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.on_text_entered = cb
        input.show()
        assert.equal(cb, input.on_text_entered)
      end)

    it('show(config) shares validator slot',
      function()
        local input = F.compy_input()
        local vfn = function() return true end
        input.show({ validator = vfn })
        assert.equal(vfn, input.validator)
      end)

    it('field write shares validator slot',
      function()
        local input = F.compy_input()
        local vfn = function() return true end
        input.validator = vfn
        input.show()
        assert.equal(vfn, input.validator)
      end)

    -- AC-42(a): a custom highlighter transforms live text and
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
        local got = F.singleton.model:get_highlight()
        assert.equal(marker, got.hl)
      end)

    -- AC-15 + AC-14 boundary half: crossing attempts fire
    -- on_limit_reached(direction, scope) and its return value
    -- is ignored (observational only; sink still runs).
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
        F.singleton:set_cursor(Cursor(1, 2))
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
        F.singleton:set_cursor(Cursor(2, 2))
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
        F.singleton:jump_home()
        F.session.press('left')
        assert.same({ { 'left', 'input' } }, seen)
      end)

    -- AC-15: line-scope boundary in multiline text.
    it('left line boundary fires scope line', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.singleton:set_cursor(Cursor(2, 1))
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
      F.singleton:set_cursor(Cursor(1, 3))
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
      F.singleton:set_cursor(Cursor(1, 1))
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
      F.singleton:set_cursor(Cursor(2, 3))
      F.session.press('right')
      assert.same({ { 'right', 'input' } }, seen)
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
