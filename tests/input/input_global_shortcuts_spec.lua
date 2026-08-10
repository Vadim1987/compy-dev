-- Global (platform) shortcuts: controller.lua's
-- setup_callback_handlers installs these ahead of route
-- dispatch, over love.handlers.keypressed/keyreleased
-- (doc/development/internals/user_input.md, "Dispatch chain").
-- That section also states they do not consume the key —
-- characterized in tests/input/input_shortcuts_click_spec.lua,
-- which this file does not repeat.
--
-- This file's own claim: a project cannot suppress one of these
-- by registering the same combo on its own
-- compy.input.shortcuts.keypressed table. The platform effect
-- fires regardless — a property of the gateway running before
-- any route is reached, not of any one binding.
--
-- Each reserved combo's OWN effect (not the suppression claim)
-- is left as a named pending gap below — see
-- doc/development/tests.md, "Input Contract Suite" for the
-- pending-row convention this suite already follows.

local F = require('tests.helpers.input_fixture')

describe('input surface: inbound events — global platform'
  .. ' shortcuts #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  describe('a project cannot suppress a platform combo',
    function()

      -- Route-preserving: suspend only flips app_state, so the
      -- project route is still installed afterward — BOTH the
      -- platform effect and the project's own binding run for
      -- the same event.
      it('ctrl+pause suspends despite a project claiming it',
        function()
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+pause'] = function()
            project_ran = true
            return true
          end
          love.state.app_state = 'running'
          F.session.press('lctrl')
          F.session.press('pause')
          assert.equal('snapshot', love.state.app_state)
          assert.is_true(project_ran)
        end)

      -- Route-destroying: quit tears the project route down
      -- (stop_project_run reinstalls the console's handlers)
      -- BEFORE the gateway forwards the event, so the project's
      -- own binding never runs. That is the route disappearing,
      -- not the platform suppressing it — the project could
      -- not have blocked the quit either way.
      it('ctrl+q quits despite a project claiming it',
        function()
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+q'] = function()
            project_ran = true
            return true
          end
          F.session.press('lctrl')
          F.session.press('q')
          assert.equal('project_open', love.state.app_state)
          assert.is_false(project_ran)
        end)
    end)

  -- Reserved combos, own effect not yet asserted here (named
  -- gaps, not failures — doc/development/tests.md, "Input
  -- Contract Suite"). ctrl+pause and ctrl+q are omitted: their
  -- own effect is already asserted live above (this file), and
  -- ctrl+pause's also in input_shortcuts_click_spec.lua — so
  -- listing them again as gaps would misstate coverage.
  describe('reserved combos, own effect not yet asserted',
    function()

      pending('ctrl+alt+r restarts the current project')
      pending('ctrl+t quickswitches run <-> editor')
      pending('ctrl+alt+p / ctrl+alt+shift+p start/stop the'
        .. ' oneshot profiler (love.PROFILE gated)')
      -- Disagreement with the enumeration read off the source
      -- by the parent session: the code has no modifier gate on
      -- f10 at all (controller.lua, the profile() local) — it
      -- cycles on bare f10 regardless of any modifier held, not
      -- only "with no modifier".
      pending('f10 cycles the FPS-corner overlay'
        .. ' (love.PROFILE gated)')
      pending('ctrl+s stops a run, or saves/closes an editor'
        .. ' buffer, depending on app_state')
      pending('ctrl+shift+r resets: quits and wipes console'
        .. ' history')
      pending('ctrl+escape (release) asks love to quit')
    end)
end)
