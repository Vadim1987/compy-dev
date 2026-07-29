-- Availability: feature-new — covers the compy.input surface
-- introduced by this feature (since 1.0.0-rc20260712).

-- widget lifecycle — split from input_contracts_spec.lua (TF1). Routing
-- invariant (doc/development/decisions/input.md, Decision 1): inter-route dispatch is
-- EXCLUSIVE — each event reaches exactly ONE route, fixed by the active
-- screen mode. Vocabulary (doc/development/internals/user_input.md, "Dispatch chain"):
-- ROUTE = the controller an event is dispatched to; WIDGET = the
-- route-managed input surface and terminal of the chain. Tests assert
-- observable outcomes
-- at public seams, never method-name spies. keypressed fires for every
-- physical key, textinput only for character-producing keys
-- (doc/development/internals/user_input.md, "Data flow").
-- Widget activation/reset via the public compy.input surface, the
-- hidden-widget non-consumption rule, and editor-internal block
-- navigation at the buffer limit (doc/input_api.md, "Activating the
-- widget: `show`"; doc/development/decisions/input.md, Decision 2).

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

describe('input contracts: widget lifecycle #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

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
        assert.is_true(F.widget:is_empty())
      end)
    
    it('a fresh activation with text sets text',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        assert.same({ 'hello' }, F.widget:get_text())
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
        assert.same({ 'first' }, F.widget:get_text())
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
          F.widget:get_text())
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
        assert.same({ 'keep' }, F.widget:get_text())
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
      assert.is_false(F.widget:is_shown())
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
    end)

  end)

  -- Hidden widget does not consume (doc/development/decisions/input.md,
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
      assert.same({ 'keep' }, F.widget:get_text())
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
      assert.same({ 'keep' }, F.widget:get_text())
      assert.same({ 'a' }, F.console:get_text())
    end)
  end)

  -- REVIEW: this test in this form should be relocated under tests/editor. Input contract should test delivery *and only if editor really relies on it* (situation where editor *may* not rely on it: just counting keystrokes itself and translating them into files' coordinates with every move -- therefore block-nav is triggered not by event emitted by input widget, but by the mere fact that internal navigation map says the cursor in 'project space' is no more inside current selection lines)
  -- OPEN (owner call, carried from the review passes):
  -- this row tests editor-INTERNAL block navigation at
  -- the buffer limit, not a routing contract of the kind
  -- doc/development/decisions/input.md, Decision 1, asserts. It
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
end)
