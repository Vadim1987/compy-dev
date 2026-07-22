-- REVIEW/clarity: remove historical reference to once-monolithic spec.
--
-- NFR guards and forward contracts — split from input_contracts_spec.lua
-- (TF1). Routing invariant (doc/development/decisions/input.md, Decision 1): inter-route
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

-- REVIEW/recheck: the "named milestone" ref is fragile — milestones
-- are ephemeral and won't survive release; reword to not depend on it.
-- This file's assertions are deliberately non-final: provisional facts
-- about today's implementation (expected to change), guards on mechanism
-- and NFRs rather than behaviour, and forward contracts pending the named
-- milestone (doc/development/tests.md, "Input Contract Suite (this feature)").

local F = require('tests.helpers.input_fixture')

-- REVIEW/clarity: 'forward' means what? lots of prose in this group are outdated (including REVIEW remarks)
-- REVIEW/consistence: group 'expected to change' actually describes *behaviour* that precedes the tests (so is taken as de-facto standard to keep -- probably could be referenced from decision docs), and should be renamed accordingly
describe('input contracts: NFR and forward #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

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

      -- inspect (doc/development/decisions/input.md, Decision 12), OWNER
      -- RULING PENDING (see doc/development/internals/user_input.md,
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
        assert.is_true(F.widget:is_empty())
      end)

      -- wheel (doc/development/internals/user_input.md, "Direct mouse
      -- events"): {jargon: the gateway has no wheel
      -- entry, so the framework forwards nothing; only a
      -- project's own love.wheelmoved consumes it}. No
      -- example project consumes it today. Mechanism-by-
      -- omission, not a designed asymmetry; intended
      -- forward shape (not asserted): project
      -- pass-through, opt-in consume.
      -- REVIEW/fidelity: why check session.handlers? any other space?
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

      -- Held-key set lifecycle (doc/development/internals/user_input.md,
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
      -- job (doc/development/decisions/input.md, Decision 8, covered in
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
      -- only the overlay widget is wired; wiring the
      -- console/editor/search widgets to it is a future
      -- consideration, out of #77 blast radius (see
      -- doc/development/internals/user_input.md: "Key release", "Dispatch
      -- chain", "Search — a third widget instance, live only
      -- in editor/search mode", "Cursor manipulation and
      -- 'reset'" for the related surfaces), not asserted
      -- here.
      -- REVIEW: do we have pending tests outlined for future consideration?
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
      -- Scope-10(a)} — cold session, route-restoration =
      -- active route/mode, not handler restore; design/spec/
      -- M5c-dispatch-chain.md "Resolved (E30..."): stop's
      -- DISTINCTIVE
      -- contract is the full teardown, not "keyboard route
      -- == console" -- that end state is shared by
      -- project-exit and inspect too, so it does not by
      -- itself distinguish stop (see {badspecref:
      -- M5c-dispatch-chain.md}
      -- {badspecref: Scope item 10(a)} — same doc, same
      -- "Resolved (E30..." section). The
      -- Controller.active_keyboard_
      -- route() accessor this row used is dropped ({badspecref:
      -- C23} — QUALITY item, reviews/
      -- m4-architect-pushback.md: no
      -- unconsumed public surface -- its only production-
      -- code reader was this row; controller.lua:998-999).
      -- Retargeted to doc/development/decisions/input.md, Decision 11's
      -- literal claim
      -- instead:
      -- after stop no project handler remains wired in ANY
      -- love.* callback. The wider Decision 11 teardown
      -- (compy.input
      -- handlers/hooks, widget silent-hide) is covered by
      -- the 'route connection lifecycle' block below.
      it('stop leaves no project handler wired in any ' ..
          'love.* callback', function()
        F.activate_project()
        assert.is_not.equal(
          Controller._defaults.keypressed, love.keypressed)
        F.cc:stop_project_run()
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
      end)

      -- on_text_entered is the SUBMIT output (widget
      -- vocabulary, doc/development/decisions/input.md, Decision 5): fired
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
end)
