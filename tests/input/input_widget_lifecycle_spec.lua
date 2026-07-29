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
-- Widget activation/reset via the public compy.input surface and the
-- hidden-widget non-consumption rule (doc/input_api.md, "Activating the
-- widget: `show`"; doc/development/decisions/input.md, Decision 2).

local F  = require('tests.helpers.input_fixture')

describe('input contracts: widget lifecycle #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- Widget activation / reset (doc/input_api.md,
  -- "Activating the widget: `show`"), driven through
  -- the public project surface. F.compy_input() resolves
  -- project_env.compy.input — exactly what a project sees.
  -- show({ text = ... }) seeds the widget's CONTENT (the
  -- editable text) and show({ prompt = ... }) its label — a separate
  -- config key, one row each (same section). The
  -- "no cancel chain" facts are stable-now.
  describe('widget activation and reset', function()

    -- Prompt LABELLING at activation. Re-labelling on an already
    -- active session is the reconfigure concern and is covered there
    -- (input_reconfigure_spec.lua, 'updates the prompt on an active
    -- session'), so this row only pins the show() half.
    it('a fresh activation applies the prompt label', function()
      local input = F.compy_input()
      input.show({ text = 'hi', prompt = 'name?' })
      assert.equal('name?', F.widget.model:get_label())
    end)

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
  -- One row per channel: the pair differs only in which channel the
  -- event arrives on (textinput vs keypressed), so they are named for
  -- that and nothing else.
  describe('a hidden widget does not consume', function()

    it('a typed character while hidden does not mutate it', function()
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
    -- The keypressed sibling of the row above: a key arriving while
    -- the widget is hidden goes to the console and mutates the
    -- console line, {disputable: and the hidden widget's
    -- content, history and cursor stay untouched}.
    it('a pressed key while hidden does not mutate it', function()
      local input = F.compy_input()
      input.show({ text = 'keep' })
      input.hide()
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'keep' }, F.widget:get_text())
      assert.same({ 'a' }, F.console:get_text())
    end)
  end)

  -- Editor block navigation at the buffer limit lives in
  -- tests/editor/editor_spec.lua ("with blocks:" → "navigation at the
  -- block limit"): it is editor-INTERNAL behaviour driven below the
  -- gate, not a routing contract of the kind
  -- doc/development/decisions/input.md, Decision 1, asserts. This suite
  -- asserts only that the keystrokes reach the editor route
  -- (input_routing_spec.lua, "routing: editor mode").
end)
