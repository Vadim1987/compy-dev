---> REMARK: what remained here is very unlikely collection, I'd dissolve it across other files. E.g. held_keys is literally a part of documented contract now -- worth its own test suite. "wheel" test should be universalized across all supported event types, and live somewhere around dispatching, as literally a list of supported event types and cyle over it testing that every event is reaching, The *only* NFR I could think of is the usage of widget singleton across project invocations (therefore avoiding GC abuse) -- but its no here (if it was moved elsewhere, that's fine) . If we move these two said tests as said, there's a chance file could be dissolved

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

-- Two kinds of row live here, and neither is a project-facing
-- behaviour contract: de-facto behaviour characterized as it
-- stands, and guards on mechanism (identity, allocation, the
-- held-key table) rather than on behaviour. Project contracts
-- live in the other input_*_spec.lua files.

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
  describe('current behaviour — characterized, no mandate',
    function()

      -- (An 'inspect: the console owns the surface' row lived
      -- here and was removed 2026-08-03: it had stopped
      -- discriminating. It set app_state = 'inspect' over a
      -- shown widget and asserted the console got the text —
      -- but once the console route lost its widget step
      -- entirely (Decision 1), the console gets the text with
      -- or without the inspect line. Deleting that line left
      -- the row green, which is the definition of noise.
      -- Decision 12 is still covered, by a row that does
      -- discriminate: input_route_lifecycle_spec.lua,
      -- 'inspect' — it activates the PROJECT route first, so
      -- without the suspend() the widget would receive the
      -- keystroke.)

    end)

  -- Wheel used to be the one pointer channel compy declared no
  -- gateway entry for. It still worked in production, by
  -- accident rather than design: setup_callback_handlers writes
  -- INTO love.handlers rather than replacing it, so LÖVE's own
  -- stock wheelmoved entry survived and called love.wheelmoved.
  -- The fixture builds a fresh love.handlers, so the absence
  -- was visible here and nowhere else: a row characterising
  -- the fixture, not the product. compy now declares the entry
  -- itself (owner ruling, 2026-08-03), which is also what makes
  -- the gateway self-contained rather than dependent on the
  -- stock table surviving our mutation.
  describe('wheel reaches the route like any pointer event',
    function()

      it('a project hook receives it', function()
        local input = F.activate_project()
        local got
        input.hooks.wheelmoved =
            function(x, y) got = { x, y } end
        F.session.wheelmoved(0, 1)
        assert.same({ 0, 1 }, got)
      end)

      -- The control: with no project route the emit is a no-op
      -- rather than an error, the same as the derived clicks.
      it('is silently dropped with no project route', function()
        assert.has_no.errors(function()
          F.session.wheelmoved(0, 1)
        end)
      end)
    end)

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
