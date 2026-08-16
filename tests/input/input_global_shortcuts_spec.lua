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

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')

-- restart/reset reach real project execution (run_project) or
-- console history teardown -- machinery this file's fixture
-- does not stand up. A minimal stub records which of the two
-- the raw gate invoked, isolating the modifier-exactness
-- question from project loading (doc/development/decisions/
-- input.md, Decision 17's named-seam exception; same technique
-- as input_shortcuts_click_spec.lua's play-mode row).
-- @param combo string  mock.keystroke syntax, e.g. 'C-M-r'
-- @return table  {restart = true?, reset = true?}
local function drive_stub(combo)
  local calls = { }
  local stub  = {
    cfg     = { mode = 'dev' },
    restart = function() calls.restart = true end,
    reset   = function() calls.reset = true end,
  }
  local saved    = table.clone(love.handlers)
  local saved_kp = love.keypressed
  love.keypressed = function() end
  Controller.setup_callback_handlers(stub)
  mock.keystroke(combo, love.handlers.keypressed, false)
  for k, v in pairs(saved) do love.handlers[k] = v end
  love.keypressed = saved_kp
  return calls
end

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

  -- A reservation matches its modifier set exactly
  -- (doc/development/decisions/input.md, Decision 33): the
  -- named modifiers held, and no other. Each pair below proves
  -- the boundary, not the reserved combo's own effect (that
  -- stays a named pending gap, per P15).
  describe('a reservation matches its modifier set exactly',
    function()

      it('ctrl+escape (release) still asks love to quit',
        function()
          local quits = 0
          local orig  = love.event.quit
          love.event.quit = function() quits = quits + 1 end
          F.session.press('lctrl')
          F.session.release('escape')
          love.event.quit = orig
          assert.equal(1, quits)
        end)

      it('ctrl+shift+escape no longer quits; the project'
        .. ' binding runs instead', function()
          local quits, project_ran = 0, false
          local orig = love.event.quit
          love.event.quit = function() quits = quits + 1 end
          local input = F.activate_project()
          input.shortcuts.keyreleased['ctrl+shift+escape'] =
              function() project_ran = true; return true end
          F.session.press('lctrl')
          F.session.press('lshift')
          F.session.release('escape')
          love.event.quit = orig
          assert.equal(0, quits)
          assert.is_true(project_ran)
        end)

      it('ctrl+t still quickswitches while running', function()
        F.activate_project()
        love.state.app_state = 'running'
        F.session.press('lctrl')
        F.session.press('t')
        assert.are_not.equal('running', love.state.app_state)
      end)

      it('ctrl+shift+t no longer quickswitches; the project'
        .. ' binding runs instead', function()
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+shift+t'] =
              function() project_ran = true; return true end
          love.state.app_state = 'running'
          F.session.press('lctrl')
          F.session.press('lshift')
          F.session.press('t')
          assert.equal('running', love.state.app_state)
          assert.is_true(project_ran)
        end)

      it('ctrl+alt+pause no longer suspends; the project'
        .. ' binding runs instead', function()
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+alt+pause'] =
              function() project_ran = true; return true end
          love.state.app_state = 'running'
          F.session.press('lctrl')
          F.session.press('lalt')
          F.session.press('pause')
          assert.equal('running', love.state.app_state)
          assert.is_true(project_ran)
        end)

      it('ctrl+shift+q no longer quits; the project'
        .. ' binding runs instead', function()
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+shift+q'] =
              function() project_ran = true; return true end
          F.session.press('lctrl')
          F.session.press('lshift')
          F.session.press('q')
          assert.equal('running', love.state.app_state)
          assert.is_true(project_ran)
        end)

      -- Shift stays meaningful in the editor branch (finish
      -- edit vs close buffer); exactness excludes Alt only.
      -- Exercised through the simpler running-state branch,
      -- which shares the same outer condition.
      it('ctrl+s still stops a running project', function()
        F.activate_project()
        love.state.app_state = 'running'
        F.session.press('lctrl')
        F.session.press('s')
        assert.equal('project_open', love.state.app_state)
      end)

      it('ctrl+alt+s no longer stops the run; the project'
        .. ' binding runs instead', function()
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+alt+s'] =
              function() project_ran = true; return true end
          love.state.app_state = 'running'
          F.session.press('lctrl')
          F.session.press('lalt')
          F.session.press('s')
          assert.equal('running', love.state.app_state)
          assert.is_true(project_ran)
        end)

      -- Shift stays meaningful in the editor branch: ctrl+s
      -- closes the buffer, ctrl+shift+s finishes the edit
      -- instead (S43-P-21-05 finding S2). Exactness excludes
      -- Alt only, so a stray `not Key.shift()` here would be
      -- wrong. CC's own methods are stubbed so the branch
      -- taken is observable without EditorController's real
      -- save/close machinery — same avoidance the
      -- running-state pair above already takes.
      it('ctrl+shift+s finishes the edit in the editor'
        .. ' branch', function()
          local called
          love.state.app_state = 'editor'
          F.cc.editor:open('t.lua', '', function()
            return true
          end)
          local orig = F.cc.finish_edit
          F.cc.finish_edit = function() called = true end
          F.session.press('lctrl')
          F.session.press('lshift')
          F.session.press('s')
          F.cc.finish_edit = orig
          assert.is_true(called)
        end)

      it('ctrl+s closes the buffer in the editor branch',
        function()
          local called
          love.state.app_state = 'editor'
          F.cc.editor:open('t.lua', '', function()
            return true
          end)
          local orig = F.cc.close_buffer
          F.cc.close_buffer = function() called = true end
          F.session.press('lctrl')
          F.session.press('s')
          F.cc.close_buffer = orig
          assert.is_true(called)
        end)

      -- love.PROFILE is restored to false BEFORE asserting: the
      -- module-load-time guard in controller.profiler.lua
      -- captures love.PROFILE once, so leaving it truthy past a
      -- failed assertion here breaks Controller.report() in
      -- every later test's F.reset().
      it('f10 still cycles the FPS overlay unmodified',
        function()
          love.PROFILE = { fpsc = 'off' }
          F.session.press('f10')
          local fpsc = love.PROFILE.fpsc
          love.PROFILE = false
          assert.equal('T_L_B', fpsc)
        end)

      it('ctrl+f10 no longer cycles; the project binding'
        .. ' runs instead', function()
          love.PROFILE = { fpsc = 'off' }
          local project_ran = false
          local input = F.activate_project()
          input.shortcuts.keypressed['ctrl+f10'] =
              function() project_ran = true; return true end
          F.session.press('lctrl')
          F.session.press('f10')
          local fpsc = love.PROFILE.fpsc
          love.PROFILE = false
          assert.equal('off', fpsc)
          assert.is_true(project_ran)
        end)

      it('ctrl+alt+r still restarts', function()
        local calls = drive_stub('C-M-r')
        assert.is_true(calls.restart)
      end)

      it('ctrl+alt+shift+r no longer restarts', function()
        local calls = drive_stub('C-M-S-r')
        assert.is_nil(calls.restart)
      end)

      it('ctrl+shift+r still resets', function()
        local calls = drive_stub('C-S-r')
        assert.is_true(calls.reset)
      end)

      it('ctrl+alt+shift+r no longer resets', function()
        local calls = drive_stub('C-M-S-r')
        assert.is_nil(calls.reset)
      end)

      -- The defect this closes (blast-radius review, rows 5/6):
      -- pre-fix, ctrl+alt+shift+r satisfied both the tolerant
      -- reset gate (ctrl+shift) and the tolerant restart gate
      -- (ctrl+alt), so ONE event ran BOTH. Exactness makes the
      -- two gates mutually exclusive by construction.
      it('ctrl+alt+shift+r fires neither restart nor reset',
        function()
          local calls = drive_stub('C-M-S-r')
          assert.is_nil(calls.restart)
          assert.is_nil(calls.reset)
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
