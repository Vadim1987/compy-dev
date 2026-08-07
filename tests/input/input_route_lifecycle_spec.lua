-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — route connect/disconnect, stop teardown
-- and the compy.before_exit hook.

-- route connection lifecycle.
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

  describe('route connection lifecycle', function()

    describe('connection at the running boundary', function()
      -- The route is held by an OPEN project, not only by a
      -- running one: a non-blocking run reaching 'project_open'
      -- keeps every channel until the project actually stops.
      -- That is the pre-feature lifecycle — at the PR base
      -- nothing was released before suspend or stop. It is what
      -- lets one release path serve every channel. Ctrl+Esc
      -- is the documented way back to the console.
      it('keyboard stays on the route in project_open',
        function()
          local input = F.activate_project()
          local got = 0
          input.hooks.textinput = function() got = got + 1 end
          love.state.app_state = 'project_open'
          F.session.type('a')
          assert.equal(1, got)
          assert.same({ '' }, F.console:get_text())
        end)

      -- The pen-and-paper case (sapper-like): clickable while
      -- otherwise idle. It used to need an explicit exemption
      -- from a keyboard-only release; with one lifetime for all
      -- channels there is nothing to exempt.
      it('pointer stays on the route in project_open',
        function()
          local got = 0
          F.activate_project({
            mousepressed = function() got = got + 1 end,
          })
          love.state.app_state = 'project_open'
          F.session.mousepressed(10, 10, 1, false, 1)
          assert.equal(1, got)
        end)

      -- Stop is still the boundary that hands everything back.
      it('stop returns both channels to the console',
        function()
          local input = F.activate_project()
          local keys, clicks = 0, 0
          input.hooks.textinput = function() keys = keys + 1 end
          input.hooks.mousepressed =
              function() clicks = clicks + 1 end
          F.cc:stop_project_run()
          F.session.type('a')
          F.session.mousepressed(10, 10, 1, false, 1)
          assert.equal(0, keys)
          assert.equal(0, clicks)
          assert.same({ 'a' }, F.console:get_text())
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
        assert.is_false(F.is_widget_visible())
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
          assert.is_true(F.is_widget_visible())
          assert.is_true(F.widget:is_empty())
        end)

      -- doc/development/decisions/input.md, Decision 11: the row
      -- above starts its first project WITHOUT an overlay, so it
      -- cannot see whether stop leaves the widget re-showable. This
      -- one does: project one shows, is stopped, and project two
      -- shows again. The overlay must come up with the SECOND
      -- project's text — the widget's own shown flag is part of what
      -- teardown resets, not merely the published love.state handle.
      it('a second project gets its overlay after the first ' ..
          'is stopped', function()
        local first = F.activate_project()
        first.show({ text = 'one' })
        F.cc:stop_project_run()

        local second = F.activate_project()
        second.show({ text = 'two' })

        assert.is_true(F.is_widget_visible())
        assert.same({ 'two' }, F.widget:get_text())
      end)
    end)

    -- doc/development/decisions/input.md, Decision 11 (the
    -- teardown invariant): a project whose TOP-LEVEL code
    -- raises never reaches the route installer, so run_project
    -- tears the route down instead of connecting it. An
    -- overlay the project already showed is part of that
    -- teardown — the invariant says a widget whose owning
    -- route is inactive goes unhonoured, and a shown one is
    -- not unhonoured.
    describe('teardown after a top-level raise', function()
      -- Drives the REAL ConsoleController:run_project. Only the
      -- loader is stubbed, because a chunk that shows an
      -- overlay and then raises is the one part of this path a
      -- unit test cannot supply from disk.
      -- `extra` runs after the overlay is up and before the
      -- raise, so a row can install participants the way a real
      -- project's top-level code would.
      local function run_raising_project(extra)
        local P = F.cc.model.projects
        local prev_current, prev_run = P.current, P.run
        P.current = { name = 'boom' }
        P.run = function()
          return function()
            local input = F.cc:get_project_env().compy.input
            input.show({ text = 'x' })
            if extra then extra(input) end
            error('kaboom')
          end, nil, '/tmp/boom'
        end
        F.cc:run_project('boom')
        P.current, P.run = prev_current, prev_run
      end

      -- Both halves, deliberately: hide_overlay exists because
      -- clearing the published handle alone left the widget
      -- believing it was still active
      -- (consoleController.lua hide_overlay).
      it('leaves no overlay behind', function()
        run_raising_project()
        assert.is_false(F.is_widget_visible())
        assert.is_false(F.widget:is_shown())
      end)

      -- The user-visible consequence of the row above, and the
      -- control that proves it is not vacuous: show() is a
      -- no-op over an active overlay (Decision 3), so a
      -- surviving widget would silently swallow the next run's.
      it('lets the next run show its own overlay', function()
        run_raising_project()
        local second = F.activate_project()
        second.show({ text = 'two' })
        assert.is_true(F.is_widget_visible())
        assert.same({ 'two' }, F.widget:get_text())
      end)

      -- Same invariant as the stop-teardown row above, on the
      -- other end of a run: top-level code that raises has
      -- usually installed participants first, and Decision 11
      -- lets none of them outlive the project that installed
      -- them. Nothing to inspect on this path either: a
      -- top-level raise is caught by run_user_code's bare
      -- pcall, so it never reaches suspend_run and never
      -- enters 'inspect'.
      it('clears every project-installed handler and hook',
        function()
          local captured
          run_raising_project(function(input)
            input.shortcuts.keypressed['a'] = function() end
            input.hooks.keypressed = function() end
            input.callbacks.before_submit = function() end
            input.callbacks.validator = function() return
              true
            end
            captured = input
          end)
          assert.same({ }, captured.shortcuts.keypressed)
          assert.is_nil(captured.hooks.keypressed)
          assert.is_nil(captured.callbacks.before_submit)
          assert.is_nil(captured.callbacks.validator)
        end)

      -- doc/input_api.md, "Stop hook — compy.before_exit":
      -- the hook fires on stop paths and a raise is not one,
      -- and it is reset by whichever path ended the run so one
      -- project's hook never fires for the next. Two claims,
      -- so two checkpoints: after the raise (it did not fire)
      -- and after a LATER run's stop, which is the control —
      -- were the slot still holding the dead project's fn, a
      -- real stop would certainly fire it.
      it('neither fires nor survives a top-level raise',
        function()
          local fired = 0
          run_raising_project(function()
            F.cc:get_project_env().compy.before_exit =
                function() fired = fired + 1 end
          end)
          assert.equal(0, fired)
          F.activate_project()
          F.cc:stop_project_run()
          assert.equal(0, fired)
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
        ---> REMARK: worth also checking that widget is not shown after suspend?
        assert.same({ 'a' }, F.console:get_text())
        assert.same({ 'x' }, F.widget:get_text())
      end)
    end)

    -- A raise inside a project's own handler must reach
    -- user_error_handler and suspend the run
    -- (doc/development/technical_debt/input.md, "A raise from
    -- project top-level and from a handler surface
    -- differently" describes this as the handler-side
    -- behaviour). suspend_run moves 'running' to 'snapshot';
    -- the screenshot callback that completes the move to
    -- 'inspect' needs a real graphics context, so 'snapshot'
    -- is the observable this far.
    -- Each row asserts the handler RAN before it raised, so a
    -- silently-skipped handler cannot pass the row by never
    -- reaching its error.
    describe('a raise in a project handler suspends', function()
      it('from a pointer handler', function()
        local ran = 0
        F.activate_project({
          mousepressed = function()
            ran = ran + 1
            error('boom')
          end,
        })
        F.session.mousepressed(10, 10, 1, false, 1)
        assert.equal(1, ran)
        assert.equal('snapshot', love.state.app_state)
      end)

      it('from the project update handler', function()
        local ran = 0
        F.activate_project({
          update = function()
            ran = ran + 1
            error('boom')
          end,
        })
        F.love_update(0.1)
        assert.equal(1, ran)
        assert.equal('snapshot', love.state.app_state)
      end)

      -- The control: this channel already worked, because the
      -- keyboard chain's wrapper binds CC in a closure. Kept
      -- as the row that shows the other two are not asserting
      -- something impossible.
      it('from a keyboard hook', function()
        local ran = 0
        F.activate_project({
          keypressed = function()
            ran = ran + 1
            error('boom')
          end,
        })
        F.session.press('a')
        assert.equal(1, ran)
        assert.equal('snapshot', love.state.app_state)
      end)
    end)

    -- The chain itself has no error boundary — dispatch
    -- (projectInputController.lua) has no pcall/xpcall. The
    -- boundary belongs where the chain is INVOKED, on the
    -- controller side, so that it covers every tier rather than
    -- whichever participants happened to be wrapped on the way
    -- in. These rows pin all three tiers and the abort.
    describe('the chain is error-bounded at entry', function()
      it('a raising shortcut does not escape the chain',
        function()
          local input = F.activate_project()
          input.shortcuts.keypressed['a'] =
              function() error('boom') end
          assert.has_no.errors(function()
            F.session.press('a')
          end)
          assert.equal('snapshot', love.state.app_state)
        end)

      -- The documented API surface: a hook the project assigns
      -- itself, rather than one seeded from its love.* handler.
      it('a raising direct hook does not escape the chain',
        function()
          local input = F.activate_project()
          input.hooks.keypressed = function() error('boom') end
          assert.has_no.errors(function()
            F.session.press('a')
          end)
          assert.equal('snapshot', love.state.app_state)
        end)

      -- A raise aborts the WALK. Previously the wrapper caught
      -- per-participant, answered falsey, and the walk carried
      -- on — so a crashed project's overlay edited the very
      -- event that crashed it.
      it('a raise stops the walk before the widget',
        function()
          local input = F.activate_project()
          input.hooks.textinput = function() error('boom') end
          input.show({ text = '' })
          F.session.type('z')
          assert.same({ '' }, F.widget:get_text())
          assert.equal('snapshot', love.state.app_state)
        end)
    end)

    ---> REMARK: test that neither raising from before_exit, nor attempt to return true do not block the exit (inability to disable exit from before_exit is dictated by common logic so it becomes final form of the contract for this specific hook)
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
