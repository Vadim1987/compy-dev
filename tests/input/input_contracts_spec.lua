-- Input contracts — the framework's behavioural input
-- guarantees.
--
-- REVIEW/DOC: no comment should point to wip/77 -- only to canonical docs
-- REVIEW/DOC: referencing items as 'paragraph X' is insufficient and unreadable -- should reference specific named sections so they are discoverable/greppable in their doc
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
-- Vocabulary (doc A §3): ROUTE = the consumer(controller)
-- an event is dispatched to; WIDGET = a route-managed
-- input surface; SINK = the last consumer in the dispatch
-- chain. Tests assert observable outcomes (state or text
-- changed) or receipt at a public seam (a project's own
-- love.* callback). A project's love.* callback is the one
-- it set in its sandboxed project-env `love` table; the
-- framework wraps it and installs the wrapper — it is
-- never the raw top-level LÖVE callback.
-- Never a method-name spy, never love.state internals as
-- behaviour.
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
--
-- REVIEW: maybe A/B/C/D buckets can be dissolved today as they are less important today when feature is supposedly implemented. Simply marking tests as 'since 1.0.0...' (or 'changed in 1.0.0...') for new/altered behaviour would be enough. 
-- REVIEW: using tags in groups would also be great but I will inject some myself
-- REVIEW: would it be worth splitting the 2K+ LoC into several test suites, for easier inspection?

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
-- REVIEW: this helper serves one case which must be displaced
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

  -- REVIEW/DOC: fix spec references EVERYWHERE IN THE FILE (I will wrap them into {badspecref:} wherever I see them
  -- REVIEW/DOC: also I will wrap with {jargon:...} the words or phrases which seem invented
  -- ====================================================
  -- Bucket A — PRESERVE (stable-now contracts; green now)
  --
  -- Keyboard, text and pointer are EXCLUSIVE on the
  -- active route ({badspecref:doc A §5.1-5.5}): the mode-fixed route
  -- receives, the others do not. One subgroup per mode
  -- below, so a missing mode x channel cell is visible on
  -- sight ({badspecref: doc A §4} completeness table). Every
  -- test in this group fires its events through the
  -- installed love.handlers entries — the same dispatch
  -- path a real keystroke takes — via the driver in
  -- tests/helpers/input_session.lua.
  -- ====================================================

  describe('routing: console mode', function()

    
    -- Setup seeds text via the model; the assertion path
    -- (backspace) travels love.handlers -> {jargon:gate} -> console,
    -- so routing itself is what is witnessed. ({badspecref: doc A §5.1}) 
    it('routes keys to the console', function()
      -- REVIEW/nitpick: we can have function kind of F.console_with('ab') to distinguish between test context setup (tests-specific method, explicitly aliased in fixture) and actions under test (called as in real code)
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'a' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    -- ({badspecref:doc A §5.2}) 
    it('routes text to the console', function()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    -- SURFACED GAP ({badspecref: doc A §5.3}): console delivery of a
    -- release has no observable mutation today (a release
    -- carries no text), so only the project route is
    -- directly witnessed. Named here so the cell is
    -- visible, not silent.
    pending('routes the key release to the console')

    -- The production singleton disables selection, so an
    -- observable selection on the console route witnesses
    -- active-route pointer delivery. The precondition
    -- assert pins causality: no selection existed before
    -- the pointer events. ({badspecref: doc A §5.5})
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
    -- ({badspecref: doc A §5.1; reviews/M4-0-04.md finding 1})
    it('routes keys to the editor', function()
      F.session.type('q')
      F.session.press('backspace')
      assert.is_true(F.cc.editor.input:is_empty())
      assert.is_true(F.console:is_empty())
    end)

    -- ({badspecref:doc A §5.2})
    it('routes text to the editor', function()
      F.session.type('q')
      assert.same({ 'q' }, F.cc.editor.input:get_text())
      assert.is_true(F.console:is_empty())
    end)

    -- keyreleased under editor: the console/editor fork is
    -- CC-internal and out of {badspecref: #77's blast radius} ({badspecref:doc A
    -- §5.3, §8}) — foundation for the future console/editor
    -- migration; no suite row is owed under {badspecref: this feature}.
    -- REVIEW: why not add the test then?

    -- SURFACED GAP ({badspecref: doc A §5.5}): the production editor
    -- widget disables selection, so pointer delivery to
    -- the editor route has no observable outcome without
    -- extra scaffolding. Named, not silently absent.
    -- REVIEW: why not implement?
    pending('routes the pointer to the editor')
  end)

  -- REVIEW: and why not test it, is it complex? Spec is not called 'feature_77_spec.lua' so not being included in blast radius is a weak excuse for incompleteness (if test could be filled easily)
  -- Search (internals/user_input.md, "Search — a third
  -- widget instance, live only in editor/search mode"): a
  -- {jargon: third full MVC input triad
  -- under the editor}, absent from the design corpus —
  -- see same section ("None of the design documents for
  -- feature #77 mention this surface") — but part of the
  -- {jargon: mode
  -- x channel grid}, so the gap is named, not silent.
  describe('routing: editor search', function()
    pending('routes keys and text to the search widget')
  end)

  describe('routing: project run', function()

    -- The project's {jargon: own love.* callback}{better: 'own (sandboxed) love.* callback' or simply "project's callback"?} is the {jargon: public seam}
    -- witnessing delivery to the project route. ({badspecref: doc A
    -- §5.1})
    it('routes keys to the project', function()
      local got = { }
      F.running_project('keypressed', function(k)
        got[#got + 1] = k
      end)
      F.session.press('a')
      assert.same({ 'a' }, got)
      assert.is_true(F.console:is_empty())
    end)

    -- ({badspecref: doc A §5.2})
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
    -- active route receives exactly once. ({badspecref: doc A §5.3})
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
    -- in the console-mode test above; with the project
    -- route active no selection may appear — the pointer
    -- went to exactly one route. ({badspecref: doc A §5.5})
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

    -- SURFACED GAP ({badspecref: doc A §5.6}): touch has no gateway
    -- entry today and both the widget and route touch
    -- handlers are no-ops, so delivery is not black-box
    -- observable. Greens when a touch consumer lands.
    pending('touch reaches the active route')
  end)

  -- Global shortcuts are non-consuming
  -- (internals/user_input.md, "Dispatch chain": "None of
  -- these consume the key: it still reaches the active
  -- route afterward"): a
  -- framework shortcut fires its effect AND the key still
  -- reaches its route. Carried as-is; whether this is a
  -- mandated invariant or incidental is recorded as open
  -- there, not re-litigated here.
  -- REVIEW: both cases need reconsideration/refinement later, they look plausible in spirit but they do not demonstrate which exact production scenario is tested, and mastering framework state via low-level configuration flags is suspicious (if we mock the real production path like project run, it should be explicit, not imitated)
  describe('global shortcuts do not consume the key (#disputable))',
    function()

      it('a shortcut fires but does not consume', function()
        love.state.app_state = 'running'
        local n = 0
        local orig = love.keypressed
	-- REVIEW: is it how in real scenarios handlers are altered? 
        love.keypressed = function(k) n = n + 1; orig(k) end
        mock.keystroke('C-pause', F.session.press, false)
        love.keypressed = orig
        assert.equal('snapshot', love.state.app_state)
        assert.equal(1, n)
      end)

      -- cfg.mode is a global framework state: 'play' means
      -- the framework runs on an end device for a player,
      -- 'dev' that a developer runs it to work on it.
      -- 'play' narrows the shortcut set so a player cannot
      -- manage projects: restart/profile stay live,
      -- quit/stop/quickswitch do not ({badspecref: doc A
      -- §6.3)}. The shared fixture is built in dev mode, so
      -- this test wires a private play-mode stub controller
      -- and saves/restores the shared love.handlers around
      -- it.
      it('#play mode narrows the active shortcut set',
      	-- REVIEW: suspiciously big amount of lower-level 'magic' manipulations -- should not test execute a few real framework methods instead and check their results?
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

  -- Framework click detection (internals/user_input.md,
  -- "Framework-level click handling"): a derived
  -- path over raw pointer delivery, asserted on outcomes
  -- against the project-defined handlers (default no-ops).
  -- The 0.4s / 2.5px constants are mechanism. In scope
  -- because {badspecref: M4} {jargon: rewires the handler slots} this path hangs
  -- off — it is a regression surface, not a routing rule.
  describe('framework click detection', function()

    it('a single click confirms after the window',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
	-- REVIEW: why not setup via 'running_project'? unification is good. or it does not work with mouse events?
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

  -- Project stop returns input to the console
  -- (decisions/input.md, Decision 11): a project's
  -- {jargon: native handler} {jargon: is installed} while
  -- it runs; after stop it receives nothing and typing
  -- lands in the console again. Asserted end-to-end on
  -- behaviour — who receives — not on slot identity.
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

  -- Legacy text solicitation (doc/input_api.md, "Migration
  -- from the legacy globals"): the five poll-idiom globals +
  -- the debug-only
  -- astv_input (a sixth global on the same machinery) are
  -- gone from the project environment — an ordinary nil
  -- field, no shim, no deprecation path (same section).
  describe('legacy text solicitation #legacy', function()

    it('the legacy globals are gone — ordinary nil calls',
      function()
        F.activate_project()
        local env = F.cc:get_project_env()
        assert.is_nil(env.user_input)
        assert.is_nil(env.input_code)
        assert.is_nil(env.input_text)
        assert.is_nil(env.write_to_input)
        assert.is_nil(env.validated_input)
        assert.is_nil(env.astv_input)
      end)
  end)

  -- Widget activation / reset (doc/input_api.md,
  -- "Activating the widget: `show`"), driven through
  -- the public project surface. F.compy_input() resolves
  -- project_env.compy.input — exactly what a project sees.
  -- show({ text = ... }) seeds the widget's CONTENT (the
  -- editable text); the prompt label is a separate,
  -- untested-here concern (same section). The
  -- "no cancel chain" facts are stable-now.
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
    -- today only the text subset takes effect
    -- (doc/input_api.md, "Activating the widget: `show`").
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
    -- reset; doc/input_api.md, "Activating the widget:
    -- `show`").
    it('force without text leaves content intact',
      function()
        local input = F.compy_input()
        input.show({ text = 'keep' })
        input.show({ force = true })
        assert.same({ 'keep' }, F.singleton:get_text())
      end)

    -- REVIEW/DOC: I believe that design rule is that after hide widget stops consuming whatever comes to it -- concern-under-test is valid, prose description is misorienting. MAYBE (check towards design) deactivated widget simply means if events fall through they are ignored. I am not sure that console consuming typed characters while not being shown is the valid or desired scenario!
    -- After hide the widget stops being the surface the
    -- route forwards to: typed text lands in the console,
    -- not the widget (whose non-mutation is asserted in
    -- the hidden-widget row below).
    it('hide deactivates the widget', function()
      local input = F.compy_input()
      input.show()
      input.hide()
      assert.is_false(F.singleton:is_shown())
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)

  end)

  -- Hidden widget does not consume (decisions/input.md,
  -- Decision 2: "its hidden-check is internal"),
  -- {jargon: owner-minted PRESERVE}): an event arriving while the
  -- widget is hidden never mutates widget state — it
  -- {jargon: reaches the active route instead. Intra-route rule;
  -- inter-route dispatch unchanged}.
  -- REVIEW: whenever we migrate console to new API, we may stop silent consuming of input (to be confirmed yet) -- therefore assertions checking the console as hidden sink will break and will have to be updated (see also one of previous remarks not so far before)
  -- REVIEW: this test case is literally a sibling of previous one, the only difference is that two modes are preserved ('keep' vs no-keep). So the two should be better named/grouped. Not sure if we can just test the widget state (e.g. typing+enter do *not* delivering on_text_entered while widget is hidden; and the re-delegation to console is a separate *disputable* concern that should be asserted separately (if not discarded)
  describe('a hidden widget does not consume', function()

    it('input while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.session.type('Z')
      assert.same({ 'keep' }, F.singleton:get_text())
      assert.same({ 'Z' }, F.console:get_text())
    end)


    -- REVIEW: remark below is historical (from previous passes, it addresses same problem as substantial remarks on two previous cases)
    -- REVIEW: now I am concerned about the very concept. Was it in place before? (that console absorbs any interaction when project is active but widget is hidden) How it correlates with common logic? Will it mean somewhere in the console random keystrokes are accumulating? What for? User even does not see the console if project is running -- will it see a garbage on 'inspect'? what is user occasionally types some destructive or ambiguous command while project is running -- will console evaluate/execute it? if so, its dangerous and strange; if not, there's no point in routing input to console. MY UNDERSTANDING IS: if "project/editor" is active -- its an active route -- events travel down through it. Whether they end up in user_widget (shown) or in noop (if widget is hidden), or intercepted by project combos/handlers and interpreted other way -- is totally the responsibility of the route (e.g. project input controller or editor controlle or console controller). Is this logic reasonable?
    -- REVIEW: once again -- the very concept of console secretly and meaningfully processing user input while not being on the screen looks weird to me.
    -- The keypressed sibling: a key arriving while the
    -- widget is hidden goes to the console and mutates the
    -- console line, {disputable: and the hidden widget's
    -- content, history and cursor stay untouched}.
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

  -- REVIEW: this test in this form should be relocated under tests/editor. Input contract should test delivery *and only if editor really relies on it* (situation where editor *may* not rely on it: just counting keystrokes itself and translating them into files' coordinates with every move -- therefore block-nav is triggered not by event emitted by input widget, but by the mere fact that internal navigation map says the cursor in 'project space' is no more inside current selection lines)
  -- OPEN (owner call, carried from the review passes):
  -- this row tests editor-INTERNAL block navigation at
  -- the buffer limit, not a doc A routing contract. It
  -- drives EditorController directly (editor_session),
  -- below the gate. Kept because it guards the later
  -- is_at_limit line-scope rewrite from regressing
  -- whole-input block nav; disposition (relocate to
  -- tests/editor/, or recut as a boundary-signal
  -- contract) is the human's call — see the punch list.
  -- REVIEW/RESPONSE: (check preceding REVIEW/OPEN lines) editor behaviour test clearly does not belong here. here we should just check that the relevant behavior is triggered by native keys events (and for key-level tests we have separate editor helper -- half of editor suite uses it and we should too. Here we can just reference new test disposition in the COMMENT. Or test at boundary (keystroke/invokation)
  describe('#editor block navigation at the limit',
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
  -- Bucket D — CHARACTERIZE-PROVISIONAL (factual today;
  -- doc/development/tests.md, "Input Contract Suite
  -- (feature #77)")
  -- Current behaviour {oudated: EXPECTED TO CHANGE}, {jargon: no stakeholder
  -- mandate — NOT preserve-contracts}. Each asserts only
  -- verifiable present behaviour, so a deliberate change
  -- reads as expected while an accidental one still
  -- fails the build.
  -- ====================================================
  describe('provisional — expected to change, no mandate',
    function()

      -- inspect (decisions/input.md, Decision 12), OWNER
      -- RULING PENDING (see internals/user_input.md,
      -- "Dispatch chain"): under
      -- inspect the console REPL owns the input surface; a
      -- shown project widget is not honoured; input is not
      -- dead. Asserted live (not pending) so an ACCIDENTAL
      -- change still fails; revisit when the m4 routing
      -- model lands.
      -- REVIEW/DOC: its no more 'expected to change', going to be correct invariant/contract? maybe moved out of 'provisional'?
      it('inspect: the console owns the surface', function()
        F.show_widget()
        F.console:add_text('ab')
        love.state.app_state = 'inspect'
        F.session.type('Z')
        assert.same({ 'abZ' }, F.console:get_text())
        assert.is_true(F.singleton:is_empty())
      end)

      -- wheel ({badspecref: doc A §5.7}): {jargon: the gateway has no wheel
      -- entry, so the framework forwards nothing; only a
      -- project's own love.wheelmoved consumes it}. No
      -- example project consumes it today. Mechanism-by-
      -- omission, not a designed asymmetry; intended
      -- forward shape (not asserted): project
      -- pass-through, opt-in consume.
      it('wheel has no framework gateway entry', function()
        assert.is_nil(F.session.handlers.wheelmoved)
      end)

    end)

  -- ====================================================
  -- Bucket C — MECHANISM-GUARD (NFR; not
  -- behaviour; doc/development/tests.md, "Input Contract
  -- Suite (feature #77)")
  -- Genuine mechanism guards, labelled so no reader
  -- mistakes them for behaviour contracts. These
  -- intentionally poke internals (identity, allocation,
  -- the held-key table), which is exactly what an NFR
  -- guard is for.
  -- ====================================================
  describe('mechanism / NFR guards — not behaviour',
    function()

      -- Held-key set lifecycle (internals/user_input.md,
      -- "Key state: `Controller.keys_pressed` and
      -- `combo_string`", mechanism):
      -- a key is added on press and removed on release
      -- BEFORE dispatch, so the set already reflects the
      -- event when a consumer runs. The route-observable
      -- form — the set handed along as a read-only proxy
      -- in the keypressed triple — is the Bucket B
      -- (doc/development/tests.md, "Input Contract Suite
      -- (feature #77)")
      -- forward; until it lands, the
      -- guard
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
      -- job (decisions/input.md, Decision 8, covered in
      -- keys_pressed_spec),
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
      -- consideration ({badspecref: doc A §8}), not asserted
      -- here.
      -- REVIEW: do we have pending tests outlined for future consideration?
      it('the widget keeps identity across cycles',
        function()
          F.show_widget()
          local first = love.state.user_input.C
          F.singleton:hide()
          F.show_widget()
          assert.equal(first, love.state.user_input.C)
        end)

      -- No reallocation per input session
      -- (decisions/input.md, Decision 3): the
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
  -- Bucket B — IMPLEMENT (forward contracts;
  -- doc/development/tests.md, "Input Contract Suite
  -- (feature #77)"; pending →
  -- green at the named milestone). Greppable DEFERRED
  -- ({badspecref: 0.1.0-mN}) markers; bodies document the
  -- target
  -- assertion on the PUBLIC API — none of it exists in
  -- src/ yet, and the implementer adapts a body to the
  -- landed API shape when greening it.
  -- ====================================================
  describe('forward contracts (pending until implemented)',
    function()

      -- Retargeted ({badspecref: E30} {badspecref:
      -- Scope-10(a)}): stop's DISTINCTIVE
      -- contract is the full teardown, not "keyboard route
      -- == console" -- that end state is shared by
      -- project-exit and inspect too, so it does not by
      -- itself distinguish stop (see {badspecref:
      -- M5c-dispatch-chain.md}
      -- {badspecref: Scope item 10(a)}). The
      -- Controller.active_keyboard_
      -- route() accessor this row used is dropped ({badspecref:
      -- C23}: no
      -- unconsumed public surface -- its only production-
      -- code reader was this row; controller.lua:998-999).
      -- Retargeted to decisions/input.md, Decision 11's
      -- literal claim
      -- instead:
      -- after stop no project handler remains wired in ANY
      -- {jargon: slot}. The wider Decision 11 teardown
      -- (compy.input
      -- handlers/hooks, widget silent-hide) is covered by
      -- the 'route connection lifecycle' block below.
      it('stop leaves no project handler wired in any ' ..
          'slot', function()
        F.activate_project()
        assert.is_not.equal(
          Controller._defaults.keypressed, love.keypressed)
        F.cc:stop_project_run()
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
      end)

      -- on_text_entered is the SUBMIT output (widget
      -- vocabulary, decisions/input.md, Decision 5): fired
      -- once at Enter with the
      -- assembled text — NOT
      -- the per-character chain callback (that is on_text_input,
      -- covered live in the dispatch-chain block below,
      -- same decision).
      -- Landed live in the 'submit and cancel chain' block
      -- below ('Enter runs the full submit call-order chain'
      -- etc.) — not here, since exercising it needs the real
      -- project route (F.activate_project), not this bucket's
      -- fixtures.
    end)

  -- ====================================================
  -- The {jargon: four-tier dispatch chain} ({badspecref:
  -- 0.1.0-m5c}, decisions/input.md, Decision 2).
  -- All rows drive the REAL project route: F.activate_
  -- project() installs the ProjectInputController as the
  -- {jargon: slot occupant} (app_state='running') via the same
  -- Controller.set_user_handlers path a run calls, and
  -- returns the project-facing compy.input surface. The
  -- observable {jargon: seams} are the widget's text (the sink)
  -- and
  -- the callbacks a project registers — never a spy on an
  -- internal method (except the one sink-signature row,
  -- which patches the shared singleton and restores it).
  -- ====================================================
  describe('the four-tier dispatch chain #m5c', function()

    -- Press a modifier key then a trigger so the held set
    -- (Controller.keys_pressed) carries the modifier and the
    -- combo serialises to 'ctrl+…' (decisions/input.md,
    -- Decision 8) — a real chord.
    local function chord(mod, k)
      F.session.press(mod)
      F.session.press(k)
    end

    -- ---- order, consume, fall-through
    -- (decisions/input.md, Decision 2) --

    -- decisions/input.md, Decision 2: a {jargon: tier-1}
    -- framework handler runs first and,
    -- returning truthy, consumes — no lower {jargon: tier} sees
    -- the event.
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

    -- decisions/input.md, Decision 2: an unconsumed event
    -- descends every
    -- {jargon: tier} IN ORDER and reaches the sink (backspace
    -- edits the
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

    -- decisions/input.md, Decision 2: a truthy combo
    -- handler ({jargon: tier 2}) stops the descent —
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

    -- decisions/input.md, Decision 2: consuming never
    -- removes a {jargon:
    -- tier} — the same callback
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

    -- decisions/input.md, Decision 2: assigning a generic
    -- callback replaces
    -- ONLY it; when
    -- it returns falsey the sink still runs for that event.
    it('assigning a callback replaces only it; sink still runs',
      function()
        local input = F.activate_project()
        F.show_widget({ text = 'ab' })
        input.on_key_pressed = function() return false end
        F.session.press('backspace')
        assert.same({ 'a' }, F.singleton:get_text())
      end)

    -- ---- combo tables and normalisation
    -- (decisions/input.md, Decision 8) -------

    -- decisions/input.md, Decision 8: each channel has its
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

    -- decisions/input.md, Decision 8: the three tables
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

    -- ---- signatures + read-only proxy
    -- (decisions/input.md, Decision 9 and Decision 13) ---

    -- decisions/input.md, Decision 9: keypressed
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
        assert.equal('a', seen[1])
        assert.is_table(seen[2])
        assert.is_true(seen[3])
      end)

    -- decisions/input.md, Decision 9: isrepeat is false on
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

    -- decisions/input.md, Decision 13: the keys_pressed
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

    -- decisions/input.md, Decision 9: the SINK is included
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

    -- internals/user_input.md, "Key release": a keyreleased
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

    -- ---- defaults + hidden sink (decisions/input.md,
    -- Decision 10 and Decision 2) -------

    -- decisions/input.md, Decision 10: the default generic
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

    -- decisions/input.md, Decision 2: an event with no
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
    -- (decisions/input.md, Decision 5 and Decision 10) ---

    -- decisions/input.md, Decision 5: on_text_input is the
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

    -- decisions/input.md, Decision 10 (on_* install path):
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
    -- (decisions/input.md, Decision 10) -----

    -- decisions/input.md, Decision 10: a project
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

    -- decisions/input.md, Decision 10, {jargon: native}
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

    -- decisions/input.md, Decision 10, {jargon: native}
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

    -- decisions/input.md, Decision 10, {jargon: native}
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

    -- decisions/input.md, Decision 10 precedence
    -- ({badspecref: E30}): an explicit on_* takes
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
    -- (decisions/input.md, Decision 7)
    -- -------------

    -- decisions/input.md, Decision 7: exactly the
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

    -- ---- widget outputs (decisions/input.md, Decision 5)
    -- ----------

    -- decisions/input.md, Decision 5: the four widget
    -- outputs are project-assignable
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

    -- decisions/input.md, Decision 5: show(config) keys and
    -- field assignment hit
    -- the same underlying {jargon: slots}.
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

    -- decisions/input.md, Decision 5 cont.: on_text_entered
    -- and validator also
    -- reach the same {jargon: slot} via config key and via
    -- field write
    -- (settable-only here; firing/gating is decisions/
    -- input.md, Decision 6).
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

    -- decisions/input.md, Decision 5: a custom highlighter
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
        local got = F.singleton.model:get_highlight()
        assert.equal(marker, got.hl)
      end)

    -- decisions/input.md, Decision 5, boundary half:
    -- crossing attempts fire
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

    -- decisions/input.md, Decision 5: line-scope boundary
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

    -- ---- submit and cancel (decisions/input.md,
    -- Decision 6) -------

    -- decisions/input.md, Decision 6: the full submit
    -- call-order chain on a real Enter
    -- keypress. on_text_entered receives the FULL ASSEMBLED
    -- text (Decision 5) — not a per-character capture
    -- (same decision's trap).
    it('Enter runs the full submit call-order chain',
      function()
        local order = { }
        local input = F.activate_project()
        input.before_submit = function()
          order[#order + 1] = 'before'
        end
        input.after_submit = function(t)
          order[#order + 1] = 'after:' .. t
        end
        input.show({
          text = { 'a', 'b' },
          on_text_entered = function(t)
            order[#order + 1] = 'entered:' .. t
          end,
        })
        F.session.press('return')
        assert.same(
          { 'before', 'entered:a\nb', 'after:a\nb' }, order)
      end)

    -- internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains": on_text_entered sees the
    -- session still active;
    -- after_submit sees it deactivated (the observable order
    -- the mechanism note fixes once push('userinput') is gone).
    it('on_text_entered sees the session active; ' ..
      'after_submit sees it deactivated', function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = 'x',
        on_text_entered = function()
          seen.entered = love.state.user_input ~= nil
        end,
      })
      input.after_submit = function()
        seen.after = love.state.user_input ~= nil
      end
      F.session.press('return')
      assert.is_true(seen.entered)
      assert.is_false(seen.after)
    end)

    -- internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains": a custom validator is invoked
    -- with the live
    -- assembled text (not stale/empty data).
    it('a custom validator is invoked with the assembled text',
      function()
        local seen
        local input = F.activate_project()
        input.show({
          text = 'ab',
          validator = function(t) seen = t; return true end,
        })
        F.session.press('return')
        assert.equal('ab', seen)
      end)

    -- internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains": a rejecting validator locks
    -- the
    -- session — no delivery, no deactivation, no
    -- after_submit.
    it('a rejecting validator locks input without delivering',
      function()
        local entered, after = false, false
        local input = F.activate_project()
        input.after_submit = function() after = true end
        input.show({
          text = 'bad',
          validator = function() return false, 'nope' end,
          on_text_entered = function() entered = true end,
        })
        F.session.press('return')
        assert.is_false(entered)
        assert.is_false(after)
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.singleton:has_error())
      end)

    -- decisions/input.md, Decision 6: the full cancel
    -- call-order chain;
    -- Escape genuinely
    -- dismisses (content cleared AND the widget hidden).
    it('Escape runs the full cancel call-order chain',
      function()
        local order = { }
        local input = F.activate_project()
        input.before_cancel = function()
          order[#order + 1] = 'before'
        end
        input.after_cancel = function()
          order[#order + 1] = 'after'
        end
        input.show({ text = 'x' })
        F.session.press('escape')
        assert.same({ 'before', 'after' }, order)
        assert.is_nil(love.state.user_input)
        assert.is_true(F.singleton:is_empty())
      end)

    -- internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains": Enter/Escape are ordinary
    -- keys while
    -- hidden — no
    -- framework entry engages, so lower {jargon: tiers} get a
    -- chance.
    it('Enter and Escape are ordinary keys while hidden',
      function()
        local seen = { }
        local input = F.activate_project()
        input.handlers.keypressed['return'] = function()
          seen[#seen + 1] = 'return'; return true
        end
        input.handlers.keypressed['escape'] = function()
          seen[#seen + 1] = 'escape'; return true
        end
        F.session.press('return')
        F.session.press('escape')
        assert.same({ 'return', 'escape' }, seen)
      end)

    -- internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains": while shown, the framework
    -- entries run first,
    -- unconditionally — a project combo handler cannot shadow
    -- them (the submit still ran: the widget deactivated).
    it('framework Enter cannot be shadowed while shown',
      function()
        local shadowed = false
        local input = F.activate_project()
        input.handlers.keypressed['return'] = function()
          shadowed = true; return true
        end
        input.show({ text = 'x' })
        F.session.press('return')
        assert.is_false(shadowed)
        assert.is_nil(love.state.user_input)
      end)

    -- internals/user_input.md, "Multiline input": Shift+Return
    -- is NOT a framework
    -- combo — it falls
    -- to the sink, which still inserts a newline (unchanged
    -- sink behaviour); the widget stays open (not submitted).
    -- Drives BOTH modifier tracks the production code reads:
    -- F.session.press keeps Controller.keys_pressed (combo_
    -- string) correct, mock.keystroke's 'S' token flips the
    -- separate love.keyboard.isDown mock the sink's own
    -- Key.shift() reads (tests/mock.lua — two distinct
    -- tables).
    it('Shift+Return is not intercepted; the sink edits',
      function()
        F.activate_project()
        F.show_widget({ text = 'a' })
        F.session.press('lshift')
        mock.keystroke('S-return', F.session.press, false)
        assert.same({ 'a', '' }, F.singleton:get_text())
        assert.is_not_nil(love.state.user_input)
      end)

    -- decisions/input.md, Decision 6 ("hide() ... fires no
    -- cancel chain"): hide() and a force=true reconfigure
    -- fire no
    -- cancel chain (the user-facing dismiss is Escape only).
    it('hide() fires no cancel chain', function()
      local fired = false
      local input = F.activate_project()
      input.before_cancel = function() fired = true end
      input.show({ text = 'x' })
      input.hide()
      assert.is_false(fired)
    end)

    it('a force=true reconfigure fires no cancel chain',
      function()
        local fired = false
        local input = F.activate_project()
        input.before_cancel = function() fired = true end
        input.show({ text = 'first' })
        input.show({ force = true, text = 'second' })
        assert.is_false(fired)
      end)

    -- doc/input_api.md, "The continuous-session idiom":
    -- re-activates within
    -- the same submit sequence, before the frame draws.
    it('after_submit can re-activate the widget mid-sequence',
      function()
        local input = F.activate_project()
        input.after_submit = function()
          input.show({ prompt = 'next' })
        end
        input.show({ text = 'first' })
        F.session.press('return')
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.singleton:is_empty())
      end)

    -- doc/input_api.md, "Sticky callbacks": widget outputs
    -- persist across a deactivation —
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

    -- decisions/input.md, Decision 6: absent hooks default
    -- to noop —
    -- submit and cancel
    -- both complete without error when no hook is configured
    -- (the green replacement for the
    -- retired 'a oneshot
    -- submit deactivates the widget' row — internals/
    -- user_input.md, "Submit and cancel — the framework
    -- tier-1 chains": this proves
    -- deactivation without any of the deleted oneshot/push
    -- machinery).
    it('submit and cancel complete with no hooks set',
      function()
        F.activate_project()
        F.show_widget({ text = 'x' })
        assert.has_no.errors(function()
          F.session.press('return')
        end)
        assert.is_nil(love.state.user_input)
        F.show_widget({ text = 'y' })
        assert.has_no.errors(function()
          F.session.press('escape')
        end)
        assert.is_nil(love.state.user_input)
      end)
  end)

  -- ====================================================
  -- Route connection lifecycle ({badspecref: 0.1.0-m5c}
  -- {badspecref: chunk 4}, decisions/input.md,
  -- Decision 11): connect/disconnect at the 'running'
  -- boundary
  -- (same decision), pointer excluded from that
  -- disconnect
  -- (same decision), full teardown at stop (same
  -- decision), inspect
  -- (decisions/input.md, Decision 12), and the
  -- compy.before_exit stop hook
  -- ({badspecref: M6-02-before-exit.md}). All rows drive the
  -- REAL
  -- production functions (Controller.release_keyboard_
  -- route, ConsoleController:stop_project_run/:suspend),
  -- not a simulation of them.
  -- ====================================================
  describe('route connection lifecycle #m5c', function()

    -- decisions/input.md, Decision 11 ({badspecref:
    -- ratified-model ruling 3}): the route
    -- owns keyboard/text only while 'running' -- a
    -- non-blocking run's exit restores console text entry.
    it('the console regains text entry when a ' ..
        'non-blocking run exits', function()
      local input = F.activate_project()
      local got = 0
      input.on_text_input = function() got = got + 1 end
      Controller.release_keyboard_route(F.cc)
      love.state.app_state = 'project_open'
      F.session.type('a')
      assert.equal(0, got)
      assert.same({ 'a' }, F.console:get_text())
    end)

    -- decisions/input.md, Decision 11
    -- ({badspecref: design.md §4}): pointer is explicitly
    -- NOT part of that disconnect -- a pen-and-paper
    -- project (sapper-like) stays clickable in
    -- 'project_open'.
    it('pointer stays hooked when a non-blocking run ' ..
        'ends', function()
      local got = 0
      F.activate_project({
        mousepressed = function() got = got + 1 end,
      })
      Controller.release_keyboard_route(F.cc)
      love.state.app_state = 'project_open'
      F.session.mousepressed(10, 10, 1, false, 1)
      assert.equal(1, got)
    end)

    -- decisions/input.md, Decision 11 (teardown
    -- invariant): stop clears every
    -- compy.input participant a project installed --
    -- combo handlers and every project-mutable field.
    it('stop clears every project-installed handler ' ..
        'and hook', function()
      local input = F.activate_project()
      input.handlers.keypressed['a'] = function() end
      input.on_key_pressed = function() end
      input.before_submit = function() end
      input.validator = function() return true end
      F.cc:stop_project_run()
      assert.same({ }, input.handlers.keypressed)
      assert.is_nil(input.on_key_pressed)
      assert.is_nil(input.before_submit)
      assert.is_nil(input.validator)
    end)

    -- decisions/input.md, Decision 11 + {badspecref: spec
    -- §10} edge case: a
    -- widget left shown at
    -- stop is silently hidden -- teardown is not a cancel,
    -- so no cancel chain fires (contrast Decision 6).
    it('stop silently hides a shown widget without ' ..
        'firing the cancel chain', function()
      local input = F.activate_project()
      local cancelled = 0
      input.before_cancel = function()
        cancelled = cancelled + 1
      end
      input.after_cancel = function()
        cancelled = cancelled + 1
      end
      F.show_widget({ text = 'x' })
      F.cc:stop_project_run()
      assert.is_nil(love.state.user_input)
      assert.equal(0, cancelled)
    end)

    -- decisions/input.md, Decision 11: the widget's OWN
    -- mirrored output fields
    -- (userInputController.apply_config) persist across a
    -- hide/re-show within one run (doc/input_api.md,
    -- "Sticky callbacks") but must not
    -- leak into the next project.
    it('stop resets the widget\'s own output fields',
      function()
        F.activate_project()
        F.show_widget({
          validator = function() return true end,
          on_text_entered = function() end,
          highlighter = function() end,
        })
        F.cc:stop_project_run()
        assert.is_nil(F.singleton.validator)
        assert.is_nil(F.singleton.on_text_entered)
        assert.equal(noop, F.singleton.on_limit_reached)
        assert.is_nil(F.singleton.model.evaluator.highlighter)
      end)

    -- decisions/input.md, Decision 12 ({badspecref:
    -- ratified-model R11}): inspect is the console
    -- bound over the project env -- the project route
    -- disconnects and its widget goes unhonoured.
    it('inspect disconnects the project route and its ' ..
        'widget goes unhonoured', function()
      F.activate_project()
      F.show_widget({ text = 'x' })
      love.state.app_state = 'snapshot'
      F.cc:suspend()
      F.session.type('a')
      assert.same({ 'a' }, F.console:get_text())
      assert.same({ 'x' }, F.singleton:get_text())
    end)

    -- {badspecref: M6-02}: compy.before_exit fires once on
    -- stop, before
    -- the framework's own cleanup runs (love.* calls
    -- inside it are still safe).
    it('compy.before_exit fires once on stop before ' ..
        'cleanup', function()
      local calls = 0
      local state_at_fire
      F.activate_project()
      F.cc:get_project_env().compy.before_exit = function()
        calls = calls + 1
        state_at_fire = love.state.app_state
      end
      F.cc:stop_project_run()
      assert.equal(1, calls)
      assert.equal('running', state_at_fire)
    end)

    -- {badspecref: M6-02}: the hook resets to its noop default
    -- on stop
    -- -- same lifecycle as compy.input's before_/after_
    -- hooks (decisions/input.md, Decision 11).
    it('compy.before_exit resets to noop after stop',
      function()
        local calls = 0
        F.activate_project()
        F.cc:get_project_env().compy.before_exit =
            function() calls = calls + 1 end
        F.cc:stop_project_run()
        F.cc:get_project_env().compy.before_exit()
        assert.equal(1, calls)
      end)
  end)

  -- The cursor + text surface (doc/input_api.md, "Live
  -- reconfigure: `configure`, `set_text`, `clear`, cursor",
  -- and "API reference"). Driven through the public
  -- project
  -- surface F.compy_input() — exactly what a project sees.
  -- get_cursor/set_cursor/set_text are non-assignable
  -- methods (NOT in INPUT_CALLBACKS), so decisions/input.md,
  -- Decision 7 rides the
  -- same __newindex boundary as show/hide.
  describe('cursor and text surface #m7', function()

    -- internals/user_input.md, "Cursor manipulation and
    -- 'reset'": active → 1-based (line, col); hidden
    -- → nil.
    it('get_cursor reports 1-based line, col when active',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(6, c)
      end)

    it('get_cursor returns nil when hidden', function()
      local input = F.compy_input()
      assert.is_nil(input.get_cursor())
    end)

    -- internals/user_input.md, "Cursor manipulation and
    -- 'reset'": move; out-of-range clamps to the
    -- valid range.
    it('set_cursor moves the cursor', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(1, 3)
      local l, c = input.get_cursor()
      assert.same(1, l)
      assert.same(3, c)
    end)

    -- Discriminating: seat the cursor at col 2 first, so a
    -- clamp-to-line-end (col 6) is distinguishable from
    -- move_cursor's fallback-to-previous (would stay col 2).
    -- Proves set_cursor_pos clamps rather than no-ops.
    it('set_cursor clamps an over-range column', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(1, 2)
      input.set_cursor(1, 999)
      local _, c = input.get_cursor()
      assert.same(6, c) -- 'hello' end (len 5 + 1)
    end)

    it('set_cursor clamps an over-range line', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(999, 2)
      local l = input.get_cursor()
      assert.same(1, l) -- single line: clamps to 1
    end)

    -- doc/input_api.md, "API reference": hidden set_cursor
    -- no-ops and warns.
    it('set_cursor while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_cursor(1, 2)
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_nil(input.get_cursor())
    end)

    -- doc/input_api.md, "Live reconfigure": replace
    -- content, cursor to end.
    it('set_text replaces content and jumps to the end',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_text('worldly')
        assert.same({ 'worldly' }, F.singleton:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(8, c) -- 'worldly' end (len 7 + 1)
      end)

    -- doc/input_api.md, "Live reconfigure": keep_cursor
    -- preserves position (clamped).
    it('set_text with keep_cursor preserves the cursor',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_cursor(1, 3)
        input.set_text('world', true)
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(3, c)
      end)

    it('set_text keep_cursor clamps when text shrinks',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_cursor(1, 5)
        input.set_text('xy', true)
        local _, c = input.get_cursor()
        assert.same(3, c) -- 'xy' end (len 2 + 1)
      end)

    -- internals/user_input.md, "Cursor manipulation and
    -- 'reset'": the view reflects the change WITHOUT
    -- a re-show
    -- (the overlay handle is not re-published; the widget's
    -- own view render fires via the controller's update_view).
    it('set_text updates the view without a re-show',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local handle = love.state.user_input
        local renders = 0
        local orig = F.singleton.view.render
        F.singleton.view.render =
            function(...) renders = renders + 1 end
        input.set_text('again')
        F.singleton.view.render = orig
        assert.equal(handle, love.state.user_input)
        assert.is_true(renders > 0)
      end)

    -- doc/input_api.md, "API reference": hidden set_text
    -- no-ops and warns.
    it('set_text while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_text('nope')
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_true(F.singleton:is_empty())
    end)

    -- decisions/input.md, Decision 7: the three callables are
    -- non-assignable — the
    -- mutable boundary raises loudly (never a silent swallow).
    it('assigning the cursor/text callables raises',
      function()
        local input = F.compy_input()
        assert.has_error(function()
          input.get_cursor = function() end
        end)
        assert.has_error(function()
          input.set_cursor = function() end
        end)
        assert.has_error(function()
          input.set_text = function() end
        end)
      end)
  end)

  -- ====================================================
  -- Live reconfigure + clear (configure/clear, closing
  -- the {badspecref: M7-01} re-target boundary — the
  -- {badspecref: M7-02-recut} spec's
  -- Contract). The former 'later forward contracts' anchor
  -- ('configure/set_text/cursor, force-vs-configure') is
  -- now fully authored: set_text/cursor above, configure/
  -- clear here; force-vs-configure is documented in
  -- doc/development/internals/user_input.md.
  -- ====================================================
  describe('live reconfigure and clear #m7', function()

    -- internals/user_input.md, "configure(config)": prompt
    -- updates live on an active session;
    -- content/cursor/callbacks stay untouched.
    it('configure updates the prompt on an active session',
      function()
        local input = F.compy_input()
        local cb = function() end
        input.show({ text = 'hi', on_text_entered = cb })
        input.configure({ prompt = 'new' })
        assert.equal('new', F.singleton.model:get_label())
        assert.same({ 'hi' }, F.singleton:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(3, c)
        assert.equal(cb, input.on_text_entered)
      end)

    -- internals/user_input.md, "configure(config)":
    -- validator — the NEXT submit uses the new fn,
    -- not the one set at show() (exercised, not just read).
    it('configure swaps the live validator', function()
      local input = F.activate_project()
      input.show({
        text      = 'ab',
        validator = function() return false, 'old' end,
      })
      local seen
      input.configure({
        validator = function(t)
          seen = t
          return true
        end,
      })
      F.session.press('return')
      assert.equal('ab', seen)
      assert.is_nil(love.state.user_input)
    end)

    -- internals/user_input.md, "configure(config)":
    -- highlighter — the NEXT keystroke's highlight
    -- uses the new fn.
    it('configure swaps the live highlighter', function()
      local input = F.activate_project()
      local marker = { { 'x' } }
      input.show({
        highlighter = function() return { { 'old' } } end,
      })
      input.configure({
        highlighter = function() return marker end,
      })
      F.session.type('a')
      local got = F.singleton.model:get_highlight()
      assert.equal(marker, got.hl)
    end)

    -- internals/user_input.md, "configure(config)":
    -- on_text_entered — the swapped fn fires on the
    -- next submit; the old one set at show() does not.
    it('configure swaps the live on_text_entered', function()
      local old_called, new_text = false, nil
      local input = F.activate_project()
      input.show({
        text            = 'ab',
        on_text_entered = function() old_called = true end,
      })
      input.configure({
        on_text_entered = function(t) new_text = t end,
      })
      F.session.press('return')
      assert.is_false(old_called)
      assert.equal('ab', new_text)
    end)

    -- internals/user_input.md, "configure(config)":
    -- on_limit_reached — the swapped fn fires on the
    -- next boundary; the old one set at show() does not.
    it('configure swaps the live on_limit_reached', function()
      local old_called, new_dir = false, nil
      local input = F.activate_project()
      input.show({
        text             = 'ab',
        on_limit_reached = function() old_called = true end,
      })
      input.configure({
        on_limit_reached = function(dir) new_dir = dir end,
      })
      F.singleton:jump_home()
      F.session.press('left')
      assert.is_false(old_called)
      assert.equal('left', new_dir)
    end)

    -- internals/user_input.md, "configure(config)":
    -- text/cursor are inert on an active session
    -- — even mixed with a live field, the live one applies
    -- and the inert ones are untouched (no partial/silent
    -- application: each field's own rule holds exactly).
    it('configure leaves text/cursor untouched on an ' ..
      'active session, even mixed with a live field',
      function()
        local input = F.compy_input()
        input.show({ text = 'hi' })
        input.set_cursor(1, 2)
        input.configure({
          prompt = 'live',
          text   = 'ignored',
          cursor = { 1, 99 },
        })
        assert.same({ 'hi' }, F.singleton:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(2, c)
        assert.equal('live', F.singleton.model:get_label())
      end)

    -- internals/user_input.md, "configure(config)":
    -- configure while hidden is safe
    -- (no warn —
    -- it is not a refusal) and text/cursor apply on the
    -- very next show().
    it('hidden configure applies text and cursor on the ' ..
      'next show', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.configure({ text = 'draft', cursor = { 1, 2 } })
      Log.warn = ow
      assert.equal(0, warned)
      input.show({})
      assert.same({ 'draft' }, F.singleton:get_text())
      local l, c = input.get_cursor()
      assert.same(1, l)
      assert.same(2, c)
    end)

    -- internals/user_input.md, "configure(config)": a
    -- hidden configure of a live field
    -- (prompt,
    -- validator) applies cleanly on the next show() too.
    it('hidden configure applies prompt and validator on ' ..
      'the next show', function()
      local input = F.compy_input()
      input.configure({
        prompt    = 'draft-label',
        validator = function() return true end,
      })
      input.show({})
      assert.equal(
        'draft-label', F.singleton.model:get_label())
      assert.is_function(input.validator)
    end)

    -- Pending fields are one-shot: a LATER bare show() must
    -- not keep re-injecting a stale hidden-configured draft
    -- (distinguishes this from the output-callback {jargon:
    -- slots},
    -- which stay sticky forever by design).
    it('hidden-configured text does not leak into a later ' ..
      'show', function()
      local input = F.compy_input()
      input.configure({ text = 'draft' })
      input.show({})
      input.hide()
      input.show({})
      assert.is_true(F.singleton:is_empty())
    end)

    -- internals/user_input.md, "clear()": on an active
    -- session empties content,
    -- cursor to start, no callback fires.
    it('clear empties an active session with no callback',
      function()
        local input = F.compy_input()
        local called = false
        input.show({
          text            = 'hi',
          on_text_entered = function() called = true end,
        })
        input.clear()
        assert.is_true(F.singleton:is_empty())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(1, c)
        assert.is_false(called)
      end)

    -- internals/user_input.md, "clear()": while hidden is
    -- a no-op + warn —
    -- unlike configure(), this call IS refused.
    it('clear while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.clear()
      Log.warn = ow
      assert.equal(1, warned)
    end)

    -- decisions/input.md, Decision 7: the mutable boundary
    -- is unchanged for the two
    -- new callables.
    it('assigning configure/clear raises', function()
      local input = F.compy_input()
      assert.has_error(function()
        input.configure = function() end
      end)
      assert.has_error(function()
        input.clear = function() end
      end)
    end)
  end)

  -- ====================================================
  -- doc/input_api.md, "The continuous-session idiom"
  -- (migration recipe):
  -- on_text_entered consumes; after_submit re-shows.
  -- Pins the pattern every example
  -- migration relies
  -- on, before any example is touched.
  --
  -- SURFACED ({jargon: surprise-first}, see {badspecref: M8-01}
  -- ledger):
  -- before_submit/after_submit/before_cancel/after_cancel
  -- are NOT among show()'s merged cfg keys (only
  -- on_text_entered/on_limit_reached/validator/highlighter
  -- are, per OUTPUT_KEYS in consoleController.lua) — passing
  -- after_submit inside show{...} is silently dropped (no
  -- error, no warn). The wired path is a direct field
  -- write (`input.after_submit = fn`), exactly the pattern
  -- the existing decisions/input.md, Decision 6
  -- submit-chain test above
  -- already
  -- uses. The commission's illustrative show{after_submit=…}
  -- sugar does not literally work; this test uses the
  -- field-write form that does.
  -- ====================================================
  describe('continuous-session idiom #m8', function()

    -- The recipe: consume in on_text_entered, re-show
    -- (bare, no config) in after_submit. Asserts (a) the
    -- assembled text reaches on_text_entered and (b) the
    -- widget is active again once after_submit returns.
    it('re-shows from after_submit with the same callbacks',
      function()
        local input = F.activate_project()
        local seen = { }
        input.after_submit = function() input.show({}) end
        input.show({
          prompt = 'first',
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        assert.same({ 'a' }, seen)
        assert.is_not_nil(love.state.user_input)
        assert.is_true(F.singleton:is_shown())
      end)

    -- The re-show re-arms with the STICKY callback — a
    -- second submit is observed without re-passing
    -- on_text_entered, proving the loop can repeat (the
    -- shape every migrated example's re-prompt depends on).
    it('the re-armed session observes a second submit',
      function()
        local input = F.activate_project()
        local seen = { }
        input.after_submit = function() input.show({}) end
        input.show({
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        F.session.type('b')
        F.session.press('return')
        assert.same({ 'a', 'b' }, seen)
      end)

    -- Balloons shape (doc/input_api.md, "Live reconfigure",
    -- "A continuous session with a changing prompt"): a
    -- hint set via configure()
    -- INSIDE on_text_entered (session still active,
    -- internals/user_input.md, "Submit and cancel — the
    -- framework tier-1 chains")
    -- must survive the after_submit bare re-show, not the
    -- show()-time prompt. Model-sticky per {badspecref: M8-01}
    -- surprise #2
    -- + doc/input_api.md, "The continuous-session idiom"'s
    -- apply_config: custom_label is
    -- only overwritten
    -- when cfg.prompt is given, so a bare show({}) never
    -- resets what configure() just set.
    it('a prompt configured inside on_text_entered ' ..
      'survives the after_submit re-show', function()
      local input = F.activate_project()
      input.after_submit = function() input.show({}) end
      input.show({
        prompt = 'first',
        on_text_entered = function()
          input.configure({ prompt = 'live' })
        end,
      })
      F.session.type('a')
      F.session.press('return')
      assert.equal('live', F.singleton.model:get_label())
      assert.is_not_nil(love.state.user_input)
    end)
  end)
end)
