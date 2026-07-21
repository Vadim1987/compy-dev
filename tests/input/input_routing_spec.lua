-- routing — split from input_contracts_spec.lua (TF1). Routing invariant
-- (doc/development/decisions/input.md, Decision 1): inter-route dispatch is EXCLUSIVE —
-- each event reaches exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = consumer an event
-- is dispatched to; WIDGET = a route-managed input surface; SINK = last consumer. Tests
-- assert observable outcomes at public seams, never method-name spies. keypressed fires
-- for every physical key, textinput only for character-producing keys
-- (doc/development/internals/user_input.md, "Data flow").
-- Mode x channel routing grid: console, editor, editor search, project run
-- (doc/development/internals/user_input.md, "Dispatch chain").

-- ----------------------------------------------------------------------
-- SUITE-LEVEL REVIEW NOTES (owner's, carried verbatim from the file head
-- of input_contracts_spec.lua when it was split in TF1 — they concern the
-- whole input contract suite, not this file alone; kept here in the first
-- split file so they stay greppable in-tree for the jargon / spec-ref /
-- Phase-C passes):
-- REVIEW/DOC: all comments point to canonical docs, never the
-- feature's ephemeral working tree
-- REVIEW/DOC: referencing items as 'paragraph X' is insufficient and unreadable -- should reference specific named sections so they are discoverable/greppable in their doc
-- REVIEW/DOC: fix spec references EVERYWHERE IN THE FILE (I will wrap them into {badspecref:} wherever I see them
-- REVIEW/DOC: also I will wrap with {jargon:...} the words or phrases which seem invented
-- REVIEW: maybe A/B/C/D buckets can be dissolved today as they are less important today when feature is supposedly implemented. Simply marking tests as 'since 1.0.0...' (or 'changed in 1.0.0...') for new/altered behaviour would be enough.
-- REVIEW: using tags in groups would also be great but I will inject some myself
-- REVIEW: would it be worth splitting the 2K+ LoC into several test suites, for easier inspection?
-- ----------------------------------------------------------------------

local F = require('tests.helpers.input_fixture')

describe('input contracts: routing #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- Bucket A — PRESERVE (stable-now contracts; green now)
  --
  -- Keyboard, text and pointer are EXCLUSIVE on the
  -- active route (doc/development/decisions/input.md, Decision 1 and Decision 2;
  -- doc/development/internals/user_input.md, "Dispatch chain"): the mode-fixed route
  -- receives, the others do not. One subgroup per mode
  -- below, so a missing mode x channel cell is visible on
  -- sight (the routing invariant, doc/development/decisions/input.md
  -- Decision 1, applied per mode x channel). Every
  -- test in this group fires its events through the
  -- installed love.handlers entries — the same dispatch
  -- path a real keystroke takes — via the driver in
  -- tests/helpers/input_session.lua.
  -- ====================================================

  describe('routing: console mode', function()

    
    -- Setup seeds text via the model; the assertion path
    -- (backspace) travels love.handlers -> {jargon:gate} -> console,
    -- so routing itself is what is witnessed (doc/development/decisions/input.md,
    -- Decision 1 and Decision 2; doc/development/internals/user_input.md,
    -- "Dispatch chain").
    it('routes keys to the console', function()
      -- REVIEW/nitpick: we can have function kind of F.console_with('ab') to distinguish between test context setup (tests-specific method, explicitly aliased in fixture) and actions under test (called as in real code)
      F.console:add_text('ab')
      F.session.press('backspace')
      assert.same({ 'a' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    -- (doc/development/decisions/input.md, Decision 1 and Decision 2;
    -- doc/development/internals/user_input.md, "Data flow").
    it('routes text to the console', function()
      F.session.type('Z')
      assert.same({ 'Z' }, F.console:get_text())
      assert.is_true(F.cc.editor.input:is_empty())
    end)

    -- SURFACED GAP (doc/development/internals/user_input.md, "Key
    -- release"): console delivery of a
    -- release has no observable mutation today (a release
    -- carries no text), so only the project route is
    -- directly witnessed. Named here so the cell is
    -- visible, not silent.
    pending('routes the key release to the console')

    -- The production widget disables selection, so an
    -- observable selection on the console route witnesses
    -- active-route pointer delivery. The precondition
    -- assert pins causality: no selection existed before
    -- the pointer events. (doc/development/internals/user_input.md,
    -- "Input widget mouse").
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
    -- (doc/development/decisions/input.md, Decision 1 and Decision 2;
    -- doc/development/internals/user_input.md, "Dispatch chain";
    -- {badspecref: reviews/M4-0-04.md finding 1} — editor
    -- keypressed-EXCLUSIVE had zero regression coverage before this
    -- test was added)
    it('routes keys to the editor', function()
      F.session.type('q')
      F.session.press('backspace')
      assert.is_true(F.cc.editor.input:is_empty())
      assert.is_true(F.console:is_empty())
    end)

    -- (doc/development/decisions/input.md, Decision 1 and Decision 2;
    -- doc/development/internals/user_input.md, "Data flow").
    it('routes text to the editor', function()
      F.session.type('q')
      assert.same({ 'q' }, F.cc.editor.input:get_text())
      assert.is_true(F.console:is_empty())
    end)

    -- keyreleased under editor: the console/editor fork is
    -- CC-internal and out of {badspecref: #77's blast radius}
    -- (doc/development/internals/user_input.md, "Key release" for the
    -- release-channel gap; "Dispatch chain" for the future
    -- console/editor migration note) — foundation for the future
    -- console/editor migration; no suite row is owed under
    -- {badspecref: this feature}.
    -- REVIEW: why not add the test then?

    -- SURFACED GAP (doc/development/internals/user_input.md, "Input widget
    -- mouse"): the production editor
    -- widget disables selection, so pointer delivery to
    -- the editor route has no observable outcome without
    -- extra scaffolding. Named, not silently absent.
    -- REVIEW: why not implement?
    pending('routes the pointer to the editor')
  end)

  -- REVIEW: and why not test it, is it complex? Spec is not called 'feature_77_spec.lua' so not being included in blast radius is a weak excuse for incompleteness (if test could be filled easily)
  -- Search (doc/development/internals/user_input.md, "Search — a third
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
    -- witnessing delivery to the project route.
    -- (doc/development/decisions/input.md, Decision 1 and Decision 2;
    -- doc/development/internals/user_input.md, "Dispatch chain").
    it('routes keys to the project', function()
      local got = { }
      F.running_project('keypressed', function(k)
        got[#got + 1] = k
      end)
      F.session.press('a')
      assert.same({ 'a' }, got)
      assert.is_true(F.console:is_empty())
    end)

    -- (doc/development/decisions/input.md, Decision 1 and Decision 2;
    -- doc/development/internals/user_input.md, "Data flow").
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
    -- active route receives exactly once. (doc/development/internals/user_input.md,
    -- "Key release").
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
    -- went to exactly one route. (doc/development/internals/user_input.md,
    -- "Direct mouse events").
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

    -- SURFACED GAP (doc/development/internals/user_input.md, "Touch"):
    -- touch has no gateway
    -- entry today and both the widget and route touch
    -- handlers are no-ops, so delivery is not black-box
    -- observable. Greens when a touch consumer lands.
    pending('touch reaches the active route')
  end)
end)
