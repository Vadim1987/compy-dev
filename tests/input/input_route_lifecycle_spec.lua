-- Availability: feature-new — route connect/disconnect, stop
-- teardown and the compy.before_exit hook are introduced by this
-- feature (since 1.0.0-rc20260712).

-- route connection lifecycle — split from input_contracts_spec.lua (TF1).
-- Routing invariant (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route, fixed by
-- the active screen mode. Vocabulary (doc/development/internals/user_input.md, "Dispatch
-- chain"): ROUTE = the controller an event is dispatched to; WIDGET =
-- the route-managed input surface and terminal of the chain. Tests assert
-- observable outcomes at public seams, never method-name spies.
-- keypressed fires for every physical key, textinput only for
-- character-producing keys (doc/development/internals/user_input.md, "Data flow").
-- Connect/disconnect at the 'running' boundary, full teardown at stop,
-- inspect's project-route disconnect, and the compy.before_exit stop hook
-- (doc/development/decisions/input.md, Decision 11 and Decision 12).

local F = require('tests.helpers.input_fixture')

describe('input contracts: route connection lifecycle #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- Route connection lifecycle (doc/development/decisions/input.md,
  -- Decision 11): connect/disconnect at the 'running'
  -- boundary
  -- (same decision), pointer excluded from that
  -- disconnect
  -- (same decision), full teardown at stop (same
  -- decision), inspect
  -- (doc/development/decisions/input.md, Decision 12), and the
  -- compy.before_exit stop hook.
  -- All rows drive the
  -- REAL
  -- production functions (Controller.release_keyboard_
  -- route, ConsoleController:stop_project_run/:suspend),
  -- not a simulation of them.
  -- ====================================================

  describe('route connection lifecycle #m5c', function()

    describe('connection at the running boundary', function()
      -- doc/development/decisions/input.md, Decision 11: the route
      -- owns keyboard/text only while 'running' -- a
      -- non-blocking run's exit restores console text entry.
      it('the console regains text entry when a ' ..
          'non-blocking run exits', function()
        local input = F.activate_project()
        local got = 0
        input.hooks.textinput = function() got = got + 1 end
        Controller.release_keyboard_route(F.cc)
        love.state.app_state = 'project_open'
        F.session.type('a')
        assert.equal(0, got)
        assert.same({ 'a' }, F.console:get_text())
      end)

      -- doc/development/decisions/input.md, Decision 11: pointer is explicitly
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
    end)

    describe('stop teardown', function()
      -- doc/development/decisions/input.md, Decision 11 (teardown
      -- invariant): stop clears every
      -- compy.input participant a project installed --
      -- combo handlers and every project-mutable field.
      it('clears every project-installed handler ' ..
          'and hook', function()
        local input = F.activate_project()
        input.shortcuts.keypressed['a'] = function() end
        input.hooks.keypressed = function() end
        input.callbacks.before_submit = function() end
        input.callbacks.validator = function() return true end
        F.cc:stop_project_run()
        assert.same({ }, input.shortcuts.keypressed)
        assert.is_nil(input.hooks.keypressed)
        assert.is_nil(input.callbacks.before_submit)
        assert.is_nil(input.callbacks.validator)
      end)

      -- doc/development/decisions/input.md, Decision 11: a
      -- widget left shown at
      -- stop is silently hidden -- teardown is not a cancel,
      -- so no cancel chain fires (contrast Decision 6).
      it('silently hides a shown widget without ' ..
          'firing the cancel chain', function()
        local input = F.activate_project()
        local cancelled = 0
        input.callbacks.before_cancel = function()
          cancelled = cancelled + 1
        end
        input.callbacks.after_cancel = function()
          cancelled = cancelled + 1
        end
        F.show_widget({ text = 'x' })
        F.cc:stop_project_run()
        assert.is_nil(love.state.user_input)
        assert.equal(0, cancelled)
      end)

      -- doc/development/decisions/input.md, Decision 11: the widget's OWN
      -- mirrored output fields
      -- (userInputController.apply_config) persist across a
      -- hide/re-show within one run (doc/input_api.md,
      -- "Callback assignments") but must not
      -- leak into the next project.
      it('resets the widget\'s own output fields',
        function()
          F.activate_project()
          F.show_widget({
            validator = function() return true end,
            on_text_entered = function() end,
            highlighter = function() end,
          })
          F.cc:stop_project_run()
          assert.is_nil(F.widget.callbacks.validator)
          assert.is_nil(F.widget.callbacks.on_text_entered)
          assert.equal(noop, F.widget.callbacks.on_limit_reached)
          assert.is_nil(F.widget.model.evaluator.highlighter)
        end)

      -- doc/development/decisions/input.md, Decision 11:
      -- teardown also re-seeds the DEFAULT lifecycle callbacks
      -- on the project-facing surface, not merely nils them.
      -- The next project therefore meets the documented
      -- stay-open default -- neither the previous project's
      -- after_cancel nor a nil-call error.
      it('re-seeds the default callbacks for the next project',
        function()
          local first = F.activate_project()
          local leaked = false
          first.callbacks.after_cancel =
            function() leaked = true end
          F.cc:stop_project_run()

          local second = F.activate_project()
          second.show({ text = 'x' })
          F.session.press('escape')

          assert.is_false(leaked)
          assert.is_not_nil(love.state.user_input)
          assert.is_true(F.widget:is_empty())
        end)
    end)

    describe('inspect', function()
      -- doc/development/decisions/input.md, Decision 12: inspect is the console
      -- bound over the project env -- the project route
      -- disconnects and its widget goes unhonoured.
      it('disconnects the project route and its ' ..
          'widget goes unhonoured', function()
        F.activate_project()
        F.show_widget({ text = 'x' })
        love.state.app_state = 'snapshot'
        F.cc:suspend()
        F.session.type('a')
        assert.same({ 'a' }, F.console:get_text())
        assert.same({ 'x' }, F.widget:get_text())
      end)
    end)

    describe('compy.before_exit', function()
      -- compy.before_exit fires once on
      -- stop, before
      -- the framework's own cleanup runs (love.* calls
      -- inside it are still safe).
      it('fires once on stop before ' ..
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

      -- The hook resets to its noop default on stop
      -- -- same lifecycle as compy.input's before_/after_
      -- hooks (doc/development/decisions/input.md, Decision 11).
      it('resets to noop after stop',
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
  end)
end)
