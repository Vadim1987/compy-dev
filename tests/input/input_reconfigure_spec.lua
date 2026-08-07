-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

-- live reconfigure and the continuous-session idiom.
-- Routing invariant (doc/development/decisions/input.md,
-- Decision 1): inter-route dispatch is EXCLUSIVE — each event reaches
-- exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = the
-- controller an event is dispatched to; WIDGET = the route-managed input
-- surface and terminal of the chain. Tests assert observable outcomes at
-- public seams, never
-- method-name spies. keypressed fires for every physical key, textinput
-- only for character-producing keys (doc/development/internals/user_input.md, "Data
-- flow").
-- configure()/clear() live-reconfigure semantics, and the
-- continuous session the overlay's stay-shown default enables
-- (doc/development/internals/user_input.md, "configure(config)",
-- "clear()"; doc/input_api.md, "Submit lifecycle").

local F = require('tests.helpers.input_fixture')

describe('input contracts: live reconfigure #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- doc/input_api.md, "Submit lifecycle": the overlay stays
  -- shown after a submit, so a continuous session needs no
  -- re-show — on_text_entered consumes and after_submit
  -- clears. A bare re-show from after_submit stays legal and
  -- is pinned here too, because the sticky-callback re-arm it
  -- relies on is contract.
  --
  -- Lifecycle callbacks are direct fields, not show() options.
  -- The project assigns after_submit before starting this loop.
  -- ====================================================

  describe('continuous-session idiom', function()

    -- Submit leaves the widget open, so closing is the
    -- project's to do and after_submit is where it does it.
    -- Asserted in that direction on purpose: the row that
    -- asserted the OPPOSITE — re-show from after_submit, then
    -- check the widget is shown — could not fail, because a
    -- submit no longer hides and the assertion held whether or
    -- not the callback ran at all. Proven by mutation: deleting
    -- the callback assignment left the whole file green.
    it('after_submit is what closes the widget', function()
      local input = F.activate_project()
      local seen = { }
      input.callbacks.after_submit = function() input.hide() end
      input.show({
        prompt = 'first',
        on_text_entered = function(t) seen[#seen + 1] = t end,
      })
      F.session.type('a')
      F.session.press('return')
      assert.same({ { 'a' } }, seen)
      assert.is_false(F.widget:is_shown())
    end)

    -- The control the pair needs: WITHOUT a closing callback
    -- the widget stays up. Together the two rows pin the
    -- default and the override; either alone pins neither.
    it('and without it the widget stays open', function()
      local input = F.activate_project()
      input.show({ prompt = 'first' })
      F.session.type('a')
      F.session.press('return')
      assert.is_true(F.widget:is_shown())
    end)

    -- The re-show re-arms with the STICKY callback — a
    -- second submit is observed without re-passing
    -- on_text_entered, proving the loop can repeat (the
    -- shape every migrated example's re-prompt depends on).
    it('the re-armed session observes a second submit',
      function()
        local input = F.activate_project()
        local seen = { }
        -- The idiom (Decision 6): the widget stays open;
        -- the project clears between prompts from after_submit.
        input.callbacks.after_submit = function() input.clear() end
        input.show({
          on_text_entered = function(t)
            seen[#seen + 1] = t
          end,
        })
        F.session.type('a')
        F.session.press('return')
        F.session.type('b')
        F.session.press('return')
        assert.same({ { 'a' }, { 'b' } }, seen)
      end)

    -- Balloons shape (doc/input_api.md, "Live changes",
    -- "A continuous session with a changing prompt"): a
    -- hint set via configure()
    -- INSIDE on_text_entered (session still active,
    -- doc/development/internals/user_input.md, "Submit
    -- and cancel — widget-owned callback sequences")
    -- must survive the after_submit bare re-show, not the
    -- show()-time prompt: apply_config's custom_label is
    -- only overwritten
    -- when cfg.prompt is given, so a bare show({}) never
    -- resets what configure() just set.
    it('a prompt configured inside on_text_entered ' ..
      'survives the after_submit re-show', function()
      local input = F.activate_project()
      input.callbacks.after_submit = function() input.show({}) end
      input.show({
        prompt = 'first',
        on_text_entered = function()
          input.configure({ prompt = 'live' })
        end,
      })
      F.session.type('a')
      F.session.press('return')
      assert.equal('live', F.widget.model:get_label())
      assert.is_true(F.is_widget_visible())
    end)
  end)
end)
