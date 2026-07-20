-- Phase R4 acceptance criteria (validation/reviews/
-- delta-spec-input-api.md §7) as durable, tests-first anchors. This
-- file grows one AC at a time as the redesign lands:
--   U2 (surface reshape): AC8 (hook seeding, one-shot, no
--       resurrection) + AC9 (D7 guard — frozen container, writable
--       leaves).
--   U3 (dispatch + submit/cancel) will add AC1-7 and AC10.
-- Assertions are on observable seams (the surface, the widget's text,
-- project-registered callbacks) — never internal method spies.

local F = require('tests.helpers.input_fixture')

describe('#input #r4 input-API redesign acceptance', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- AC8 (delta-spec §5 / Decision 10 revised): hooks[event] is one
  -- table, seeded ONCE at activation with the project's captured
  -- native love.* handler; thereafter a nil clears it with no
  -- resurrection — the deliberate semantic change from the old
  -- per-event `explicit or native` re-resolution.
  describe('AC8 — hook seeding, one-shot', function()
    it('a captured native fires via the seeded hook', function()
      local seen = 0
      F.activate_project({
        keypressed = function() seen = seen + 1 end,
      })
      F.session.press('x')
      assert.equal(1, seen)
    end)

    it('nil-ing a seeded hook does not resurrect the native',
      function()
        local seen = 0
        local input = F.activate_project({
          keypressed = function() seen = seen + 1 end,
        })
        F.session.press('x')
        assert.equal(1, seen)
        input.hooks.keypressed = nil
        F.session.press('x')
        assert.equal(1, seen)
      end)
  end)

  -- AC9 (delta-spec §1 / Decision 7 revised): the container and the
  -- IDENTITY of its three sub-tables are frozen; every leaf inside is
  -- freely writable.
  describe('AC9 — D7 guard: frozen container, writable leaves',
    function()
      it('replacing a sub-table identity raises', function()
        local input = F.compy_input()
        assert.has_error(function() input.shortcuts = { } end)
        assert.has_error(function() input.hooks = { } end)
        assert.has_error(function() input.callbacks = { } end)
        assert.has_error(
          function() input.shortcuts.keypressed = { } end)
      end)

      it('leaf writes succeed', function()
        local input = F.compy_input()
        assert.has_no.errors(function()
          input.hooks.keypressed = function() end
          input.callbacks.validator = function() return true end
          input.shortcuts.keypressed['ctrl+s'] = function() end
        end)
      end)
    end)
end)
