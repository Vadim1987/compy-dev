-- shortcuts and click detection — split from input_contracts_spec.lua
-- (TF1). Routing invariant (doc/development/decisions/input.md, Decision 1): inter-route
-- dispatch is EXCLUSIVE — each event reaches exactly ONE route, fixed by
-- the active screen mode. Vocabulary (doc/development/internals/user_input.md, "Dispatch
-- chain"): ROUTE = consumer an event is dispatched to; WIDGET = a
-- route-managed input surface; SINK = last consumer. Tests assert
-- observable outcomes at public seams, never method-name spies.
-- keypressed fires for every physical key, textinput only for
-- character-producing keys (doc/development/internals/user_input.md, "Data flow").
-- Non-consuming global shortcuts, framework click detection, project-stop
-- console handback, and the legacy poll-idiom removal
-- (doc/development/internals/user_input.md, "Dispatch chain"; doc/input_api.md,
-- "Migration from the legacy globals").

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')

describe('input contracts: shortcuts and click #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- Global shortcuts are non-consuming
  -- (doc/development/internals/user_input.md, "Dispatch chain": "None of
  -- these consume the key: it still reaches the active
  -- route afterward"): a
  -- framework shortcut fires its effect AND the key still
  -- reaches its route. Carried as-is; whether this is a
  -- mandated invariant or incidental is recorded as open
  -- there, not re-litigated here.
  -- REVIEW: both cases need reconsideration/refinement later, they look plausible in spirit but they do not demonstrate which exact production scenario is tested, and mastering framework state via low-level configuration flags is suspicious (if we mock the real production path like project run, it should be explicit, not imitated)
  describe('global shortcuts do not consume the key (#disputable))',
    function()

      it('a shortcut fires but does not consume', function()
        love.state.app_state = 'running'
        local n = 0
        local orig = love.keypressed
	-- REVIEW: is it how in real scenarios handlers are altered? 
        love.keypressed = function(k) n = n + 1; orig(k) end
        mock.keystroke('C-pause', F.session.press, false)
        love.keypressed = orig
        assert.equal('snapshot', love.state.app_state)
        assert.equal(1, n)
      end)

      -- cfg.mode is a global framework state: 'play' means
      -- the framework runs on an end device for a player,
      -- 'dev' that a developer runs it to work on it.
      -- 'play' narrows the shortcut set so a player cannot
      -- manage projects: restart/profile stay live,
      -- quit/stop/quickswitch do not (doc/development/decisions/input.md,
      -- Decision 1; doc/development/internals/user_input.md, "Dispatch
      -- chain"). The shared fixture is built in dev mode, so
      -- this test wires a private play-mode stub controller
      -- and saves/restores the shared love.handlers around
      -- it.
      it('#play mode narrows the active shortcut set',
      	-- REVIEW: suspiciously big amount of lower-level 'magic' manipulations -- should not test execute a few real framework methods instead and check their results?
        function()
          local calls = { }
          local stub = {
            cfg = { mode = 'play' },
            restart = function() calls.restart = true end,
            quit_project = function() calls.quit = true end,
            stop_project_run = function() end,
            keypressed = function() end,
          }
          local saved    = love.handlers
          local saved_kp = love.keypressed
          love.keypressed = function() end
          love.state.app_state = 'running'
          Controller.setup_callback_handlers(stub)
          local kp = love.handlers.keypressed
          mock.keystroke('C-M-r', kp, false)
          mock.keystroke('C-q', kp, false)
          love.handlers, love.keypressed = saved, saved_kp
          assert.is_true(calls.restart)
          assert.is_nil(calls.quit)
        end)
    end)

  -- Framework click detection (doc/development/internals/user_input.md,
  -- "Framework-level click handling"): a derived
  -- path over raw pointer delivery, asserted on outcomes
  -- against the project-defined handlers (default no-ops).
  -- The 0.4s / 2.5px constants are mechanism. In scope
  -- because {badspecref: M4} {jargon: rewires the handler slots} this path hangs
  -- off — it is a regression surface, not a routing rule.
  describe('framework click detection', function()

    it('a single click confirms after the window',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
	-- REVIEW: why not setup via 'running_project'? unification is good. or it does not work with mouse events?
        F.set_compy_handler('singleclick', bump)
        F.set_mouse_pos(10, 540)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.update(0.1)
        assert.equal(0, hit)
        F.update(0.5)
        assert.equal(1, hit)
      end)

    it('pointer drift suppresses the single click',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
        F.set_compy_handler('singleclick', bump)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.set_mouse_pos(400, 400)
        F.update(0.5)
        assert.equal(0, hit)
      end)

    it('a double click calls the project handler',
      function()
        local hit = 0
        local bump = function() hit = hit + 1 end
        F.set_compy_handler('doubleclick', bump)
        F.set_mouse_pos(10, 540)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.session.mousereleased(10, 540, 1, false, 1)
        F.update(0.5)
        assert.equal(1, hit)
      end)
  end)

  -- Project stop returns input to the console
  -- (doc/development/decisions/input.md, Decision 11): a project's
  -- the project handler is installed while
  -- it runs; after stop it receives nothing and typing
  -- lands in the console again. Asserted end-to-end on
  -- behaviour — who receives — not on slot identity.
  describe('project stop returns input to the console',
    function()

      it('the console receives after stop', function()
        local got = 0
        F.running_project('keypressed', function()
          got = got + 1
        end)
        F.cc:stop_project_run()
        F.console:add_text('ab')
        F.session.press('backspace')
        assert.equal(0, got)
        assert.same({ 'a' }, F.console:get_text())
      end)
    end)

  -- Legacy text solicitation (doc/input_api.md, "Migration
  -- from the legacy globals"): the five poll-idiom globals +
  -- the debug-only
  -- astv_input (a sixth global on the same machinery) are
  -- gone from the project environment — an ordinary nil
  -- field, no shim, no deprecation path (same section).
  describe('legacy text solicitation #legacy', function()

    it('the legacy globals are gone — ordinary nil calls',
      function()
        F.activate_project()
        local env = F.cc:get_project_env()
        assert.is_nil(env.user_input)
        assert.is_nil(env.input_code)
        assert.is_nil(env.input_text)
        assert.is_nil(env.write_to_input)
        assert.is_nil(env.validated_input)
        assert.is_nil(env.astv_input)
      end)
  end)
end)
