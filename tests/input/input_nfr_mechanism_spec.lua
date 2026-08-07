
-- Availability: predates the Compy input API (introduced in
-- 1.0.0-rc20260712).

-- NFR and mechanism guards. Routing invariant
-- (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route, fixed by
-- the active screen mode. 
--
--
-- Vocabulary (doc/development/internals/user_input.md, "Dispatch
-- chain"): ROUTE = the controller an event is dispatched to; WIDGET =
-- the route-managed input surface and terminal of the chain. Tests assert
-- observable outcomes at public seams, never method-name spies.
-- keypressed fires for every physical key, textinput only for
-- character-producing keys (doc/development/internals/user_input.md, "Data flow").

-- Guards on MECHANISM, not on behaviour: object identity,
-- allocation, and the held-key table's own shape. Nothing here
-- is a project-facing contract — those live in the other
-- input_*_spec.lua files, and a row that turns out to be one
-- belongs there instead.
--
-- The file has been narrowed twice on that test. A wheel row
-- went to input_events_spec.lua when it became one case of
-- "every channel reaches the route"; a characterisation row
-- went entirely, having stopped discriminating.

local F = require('tests.helpers.input_fixture')

describe('input contracts: NFR and mechanism guards #input',
  function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- Characterized behaviour (no stakeholder mandate). De-facto
  -- behaviour that predates the Compy input API,
  -- reverse-engineered and canonicalized here. Each row asserts
  -- only what is verifiably true today, so a deliberate change
  -- reads as expected while an accidental one still fails the
  -- build. (doc/development/tests.md, "Input Contract Suite")
  -- ====================================================
  -- ====================================================
  -- Mechanism / NFR guards — not behaviour contracts.
  -- Labelled so no reader mistakes them for behaviour contracts. These
  -- intentionally poke internals (identity, allocation, the held-key
  -- table), which is exactly what an NFR guard is for.
  -- (doc/development/tests.md, "Input Contract Suite")
  -- ====================================================
  describe('mechanism / NFR guards — not behaviour',
    function()

      -- Held-key set lifecycle (doc/development/internals/user_input.md,
      -- "Key state: `Controller.keys_pressed` and
      -- `combo_string`", mechanism):
      -- a key is added on press and removed on release
      -- BEFORE dispatch, so the set already reflects the
      -- event when a consumer runs. The route-observable form is the
      -- read-only view delivered in the keypressed triple; delivery and
      -- contents are covered in input_events_spec. These direct checks
      -- remain mechanism/NFR guards because they protect the live backing
      -- set and avoid an allocation on each dispatch, not a project
      -- identity contract.
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

      it('reuses the held-key view for one backing table', function()
        local first = Controller.held_keys()
        assert.equal(first, Controller.held_keys())
      end)

      -- Folding lctrl/rctrl to 'ctrl' is combo_string's
      -- job (doc/development/decisions/input.md, Decision 8, covered in
      -- keys_pressed_spec),
      -- not the held set's.
      -- Both sides pressed, so the claim rests on what the set
      -- CONTAINS (two raw names) and not only on what it lacks: a
      -- bare absence of 'ctrl' would also hold if the set were
      -- simply empty.
      it('left/right names stay raw in the held set',
        function()
          F.session.press('lctrl')
          F.session.press('rctrl')
          assert.is_true(Controller.keys_pressed['lctrl'])
          assert.is_true(Controller.keys_pressed['rctrl'])
          assert.is_nil(Controller.keys_pressed['ctrl'])
        end)

      -- Singleton identity across show/hide (NFR): today
      -- only the overlay widget is wired; wiring the
      -- console/editor/search widgets to it is a future
      -- consideration, deliberately out of scope (see
      -- doc/development/internals/user_input.md: "Key
      -- release", "Dispatch chain", "Search — a third
      -- widget instance, live only in editor/search mode",
      -- "Cursor manipulation and \"reset\"" for the related
      -- surfaces), not asserted here.
      it('the widget keeps identity across cycles',
        function()
          F.show_widget()
          local first = love.state.user_input.C
          F.widget:hide()
          F.show_widget()
          assert.equal(first, love.state.user_input.C)
        end)

      -- No reallocation per input session
      -- (doc/development/decisions/input.md, Decision 3): the
      -- backing model is reused across activations.
      it('no widget model is reallocated', function()
        local m1 = F.widget.model
        F.show_widget()
        F.widget:hide()
        F.show_widget()
        assert.equal(m1, F.widget.model)
      end)
    end)

  -- ====================================================
  -- Teardown, seen from the LÖVE side. The project-facing half
  -- of Decision 11 is input_route_lifecycle_spec.lua; this row
  -- watches the same stop from below, where the wiring actually
  -- lives. ====================================================
  describe('teardown leaves the love.* wiring at defaults',
    function()

      -- Decision 11 requires full teardown: after stop no
      -- project handler remains wired in any love.* callback.
      it('stop leaves no project handler wired in any ' ..
          'love.* callback', function()
        F.activate_project()
        assert.is_not.equal(
          Controller._defaults.keypressed, love.keypressed)
        F.cc:stop_project_run()
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
      end)

    end)
end)
