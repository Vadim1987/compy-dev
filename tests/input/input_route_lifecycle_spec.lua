-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — route connect/disconnect, stop teardown
-- and the compy.before_exit hook.

-- route connection lifecycle. Routing invariant
-- (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route,
-- fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"):
-- ROUTE = the controller an event is dispatched to; WIDGET =
-- the route-managed input surface and terminal of the chain.
-- Tests assert observable outcomes at public seams, never
-- method-name spies. keypressed fires for every physical key,
-- textinput only for character-producing keys
-- (doc/development/internals/user_input.md, "Data flow").
-- Connect/disconnect at the 'running' boundary, full teardown
-- at stop, inspect's project-route disconnect, and the
-- compy.before_exit stop hook
-- (doc/development/decisions/input.md, Decision 11 and Decision
-- 12).

local F = require('tests.helpers.input_fixture')

describe('input surface: inbound events — route lifetime #input',
  function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ====================================================
  -- Route connection lifecycle
  -- (doc/development/decisions/input.md, Decision 11):
  -- connect/disconnect at the 'running' boundary (same
  -- decision), pointer excluded from that disconnect (same
  -- decision), full teardown at stop (same decision), inspect
  -- (doc/development/decisions/input.md, Decision 12), and the
  -- compy.before_exit stop hook. All cases drive the REAL
  -- production functions (Controller.release_keyboard_ route,
  -- ConsoleController:stop_project_run/:suspend), not a
  -- simulation of them.
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
      -- doc/development/decisions/input.md, Decision 11
      -- (teardown invariant): stop clears every compy.input
      -- participant a project installed -- combo handlers and
      -- every project-mutable field.
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

      -- doc/development/decisions/input.md, Decision 11: the
      -- widget's OWN mirrored output fields
      -- (userInputController.apply_config) persist across a
      -- hide/re-show within one run (doc/input_api.md,
      -- "Callback assignments") but must not leak into the next
      -- project.
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

      -- doc/development/decisions/input.md, Decision 11: the
      -- case above starts its first project WITHOUT an input
      -- widget, so it cannot see whether stop leaves the widget
      -- re- showable. This one does: project one shows, is
      -- stopped, and project two shows again. The widget must
      -- come up with the SECOND project's text — the widget's
      -- shown flag is part of what teardown resets, not merely
      -- the published love.state handle.
      it('a second project gets its input widget after the first ' ..
          'is stopped', function()
        local first = F.activate_project()
        first.show({ text = 'one' })
        F.cc:stop_project_run()

        local second = F.activate_project()
        second.show({ text = 'two' })

        assert.is_true(F.is_widget_visible())
        assert.same({ 'two' }, F.widget:get_text())
      end)

      -- doc/development/decisions/input.md, Decision 11: a
      -- configure() while HIDDEN has no session to apply to, so
      -- it stashes prompt/text/cursor for the next show()
      -- (doc/development/internals/user_input.md,
      -- "configure(config)"). The compy.input closure that held
      -- that store is built ONCE for the application, not per
      -- run, so teardown has to drop it -- otherwise the next
      -- project's bare show() opens on the previous draft.
      it('discards a draft stashed by a hidden configure',
        function()
          local first = F.activate_project()
          first.configure({ text = 'secret', prompt = 'A> ' })
          F.cc:stop_project_run()

          local second = F.activate_project()
          second.show()

          assert.is_true(F.widget:is_empty())
          assert.not_equal('A> ', F.widget.model:get_label())
        end)
    end)

    -- doc/development/decisions/input.md, Decision 11 (the
    -- teardown invariant): a project whose TOP-LEVEL code
    -- raises never reaches the route installer, so run_project
    -- tears the route down instead of connecting it. An
    -- input widget the project already showed is part of that
    -- teardown — the invariant says a widget whose owning
    -- route is inactive goes unhonoured, and a shown one is
    -- not unhonoured.
    describe('teardown after a top-level raise', function()
      -- Drives the REAL ConsoleController:run_project. Only the
      -- loader is stubbed, because a chunk that shows an input
      -- widget and then raises is the one part of this path a
      -- unit test cannot supply from disk. `extra` runs after
      -- the widget is up and before the raise, so a case can
      -- install participants the way a real project's top-level
      -- code would.
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

      -- Both halves, deliberately: clearing the published
      -- handle alone leaves the widget believing it is still
      -- active (consoleController.lua, hide_input_widget).
      it('leaves no input widget behind', function()
        run_raising_project()
        assert.is_false(F.is_widget_visible())
        assert.is_false(F.widget:is_shown())
      end)

      -- The user-visible consequence of the case above, and the
      -- control that proves it is not vacuous: show() is a
      -- no-op over an active widget (Decision 3), so a
      -- surviving widget would silently swallow the next run's.
      it('lets the next run show its own input widget', function()
        run_raising_project()
        local second = F.activate_project()
        second.show({ text = 'two' })
        assert.is_true(F.is_widget_visible())
        assert.same({ 'two' }, F.widget:get_text())
      end)

      -- Same invariant as the stop-teardown case above, on the
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

      -- doc/input_api.md, "Stop hook — `compy.before_exit`":
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
      -- doc/development/decisions/input.md, Decision 12:
      -- inspect is the console bound over the project env --
      -- the project route disconnects and its widget goes
      -- unhonoured.
      it('disconnects the project route and its ' ..
          'widget goes unhonoured', function()
        F.activate_project()
        F.show_widget({ text = 'x' })
        love.state.app_state = 'snapshot'
        F.cc:suspend()
        F.session.type('a')
        assert.same({ 'a' }, F.console:get_text())
        assert.same({ 'x' }, F.widget:get_text())
        -- Unhonoured is not hidden: suspend disconnects the
        -- route, so the widget receives nothing, while its own
        -- shown flag and the widget handle the draw path reads
        -- are both left standing. Asserted because the two are
        -- easy to conflate and only the first is what Decision
        -- 12 promises.
        assert.is_true(F.widget:is_shown())
        assert.is_true(F.is_widget_visible())
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
    -- Each case asserts the handler RAN before it raised, so a
    -- silently-skipped handler cannot pass the case by never
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
      -- as the case that shows the other two are not asserting
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
    -- in. These cases pin all three tiers and the abort.
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
      -- on — so a crashed project's widget edited the very
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

      -- The hook resets to its noop default on stop -- same
      -- lifecycle as compy.input's before_/after_ hooks
      -- (doc/development/decisions/input.md, Decision 11).
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

      -- A project cannot refuse to stop, and cannot break the
      -- stop by failing. The hook is a notification, not a
      -- veto: it runs at the top of teardown, so anything it
      -- does that escapes -- a raise, or a truthy return read
      -- as a veto -- would abandon the rest of the sequence.
      -- That is the whole contract for this hook, and it is
      -- decided rather than deferred (Decision 11).
      it('a raising hook does not block the stop', function()
        F.activate_project()
        F.cc:get_project_env().compy.before_exit = function()
          error('boom')
        end
        assert.has_no.errors(function()
          F.cc:stop_project_run()
        end)
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
      end)

      it('a truthy return does not veto the stop', function()
        F.activate_project()
        F.cc:get_project_env().compy.before_exit =
            function() return true end
        F.cc:stop_project_run()
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
        assert.equal('project_open', love.state.app_state)
      end)

      -- Fires exactly once per stop. The framework owns the
      -- teardown and calls the project's hook from inside it,
      -- so there is one invocation point by construction; this
      -- case is what would notice a second one growing.
      it('fires exactly once per stop', function()
        local n = 0
        F.activate_project()
        F.cc:get_project_env().compy.before_exit =
            function() n = n + 1 end
        F.cc:stop_project_run()
        assert.equal(1, n)
      end)

      -- Nothing a project installed outlives it, including a
      -- slot the hook reassigns on its way out. This is what
      -- fixes the ORDER: uninstalling after the call, never
      -- before, is the only arrangement a parting
      -- reinstallation cannot escape. Mutation-checked:
      -- moving the uninstall above the call fails this case.
      it('a hook reassigned during teardown does not survive',
        function()
          local leaked = false
          F.activate_project()
          local compy = F.cc:get_project_env().compy
          compy.before_exit = function()
            compy.before_exit = function() leaked = true end
          end
          F.cc:stop_project_run()
          F.activate_project()
          F.cc:stop_project_run()
          assert.is_false(leaked)
        end)

      -- A project may nil the hook -- clearing a callback is
      -- how every other slot on this surface is released. Stop
      -- must survive it: the call site is the first statement
      -- of teardown, so a raise there abandons the whole
      -- sequence, leaving handlers wired and the slot stuck
      -- nil, which makes every LATER stop raise too.
      it('stop survives a nil hook', function()
        F.activate_project()
        F.cc:get_project_env().compy.before_exit = nil
        assert.has_no.errors(function()
          F.cc:stop_project_run()
        end)
        -- teardown completed, not merely survived the call
        assert.equal(
          Controller._defaults.keypressed, love.keypressed)
      end)

      -- A second stop still works: the reset line sits after
      -- the call, so a raise would have skipped it.
      it('a nil hook does not block the next stop', function()
        F.activate_project()
        F.cc:get_project_env().compy.before_exit = nil
        F.cc:stop_project_run()
        F.activate_project()
        assert.has_no.errors(function()
          F.cc:stop_project_run()
        end)
      end)
    end)
  end)
end)
