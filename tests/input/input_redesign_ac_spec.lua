-- Availability: feature-new — these are the redesign acceptance
-- criteria: behaviour introduced or altered by this feature
-- (since / changed in 1.0.0-rc20260712).

-- The input-API redesign's acceptance criteria, pinned here as
-- durable, tests-first anchors — these tests ARE the ACs. Rationale
-- for each behaviour lives in doc/development/decisions/input.md;
-- the mechanism is in doc/development/internals/user_input.md.
-- Assertions are on observable seams (the surface, the widget's text,
-- project-registered callbacks) — never internal method spies.

local F = require('tests.helpers.input_fixture')

describe('#input #r4 input-API redesign acceptance', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- AC8 (Decision 10 revised): hooks[event] is one
  -- table, seeded ONCE at activation with the project's captured
  -- love.* handler; thereafter a nil clears it with no
  -- resurrection — the deliberate semantic change from the old
  -- per-event `explicit or handler` re-resolution.
  describe('AC8 — hook seeding, one-shot', function()
    it('a captured handler fires via the seeded hook', function()
      local seen = 0
      F.activate_project({
        keypressed = function() seen = seen + 1 end,
      })
      F.session.press('x')
      assert.equal(1, seen)
    end)

    it('nil-ing a seeded hook does not resurrect the handler',
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

  -- AC9 (Decision 7 revised): the container and the
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

  -- AC1 (Decision 6): Escape clears content; the default
  -- after_cancel is a no-op, so the widget STAYS shown.
  it('AC1 — Escape clears and leaves the widget shown', function()
    local input = F.activate_project()
    input.show({ text = 'abc' })
    assert.is_not_nil(love.state.user_input)
    F.session.press('escape')
    assert.is_true(F.widget:is_empty())
    assert.is_not_nil(love.state.user_input)
  end)

  -- AC2 (Decision 6): a truthy before_cancel VETOES — content
  -- is not cleared, after_cancel does not fire, widget unchanged.
  it('AC2 — before_cancel veto keeps content, skips after_cancel',
    function()
      local input = F.activate_project()
      local after = false
      input.callbacks.before_cancel = function() return true end
      input.callbacks.after_cancel = function() after = true end
      input.show({ text = 'abc' })
      F.session.press('escape')
      assert.is_false(F.widget:is_empty())
      assert.is_not_nil(love.state.user_input)
      assert.is_false(after)
    end)

  -- AC3 (Decision 6): submit fires on_text_entered, stays open,
  -- and does NOT auto-clear content (that is the project's job).
  it('AC3 — submit stays open with no auto-clear', function()
    local input = F.activate_project()
    local got
    input.show({
      text = 'hello',
      on_text_entered = function(t) got = t end,
    })
    F.session.press('return')
    assert.same({ 'hello' }, got)
    assert.is_not_nil(love.state.user_input)
    assert.is_false(F.widget:is_empty())
  end)

  -- AC4 (Decision 6): opt-in auto-close reproduces the old
  -- prompt-once behaviour with one line.
  it('AC4 — after_submit = hide reproduces auto-close', function()
    local input = F.activate_project()
    input.callbacks.after_submit = function() input.hide() end
    input.show({ text = 'hello' })
    F.session.press('return')
    assert.is_nil(love.state.user_input)
  end)

  -- AC5 (Decision 6): Enter is shadowable — a shortcut on
  -- 'return' runs first and consumes, so no submit occurs.
  it('AC5 — a shortcut on return shadows the submit', function()
    local input = F.activate_project()
    local submitted = false
    input.shortcuts.keypressed['return'] = function() return true end
    input.show({
      text = 'hello',
      on_text_entered = function() submitted = true end,
    })
    F.session.press('return')
    assert.is_false(submitted)
    assert.is_not_nil(love.state.user_input)
  end)

  -- AC6 (Decision 2): the widget consumes iff shown — a hidden
  -- widget falls through (not consumed); a shown widget consumes
  -- any key, including ones it does nothing with.
  it('AC6 — consumption derives from shownness', function()
    F.activate_project()
    local pic = Controller.project_input
    assert.is_falsy(pic:keypressed('x'))
    F.show_widget({ text = 'a' })
    assert.is_true(pic:keypressed('x'))
  end)

  -- AC10 (Decision 11): teardown re-seeds DEFAULT_CALLBACKS — a
  -- stopped project's after_cancel does not leak into the next,
  -- which sees the stay-open default (not a nil-call error).
  it('AC10 — teardown re-seeds, no cross-project callback leak',
    function()
      local a = F.activate_project()
      local leaked = false
      a.callbacks.after_cancel = function() leaked = true end
      F.cc:stop_project_run()
      local b = F.activate_project()
      b.show({ text = 'x' })
      F.session.press('escape')
      assert.is_false(leaked)
      assert.is_not_nil(love.state.user_input)
      assert.is_true(F.widget:is_empty())
    end)

  -- AC7 (Decision 5): the console's history navigation is
  -- driven by its widget's on_limit_reached callback (wired at
  -- construction), NOT by keypressed's return value (retired).
  -- Up on the single-line console input hits the vertical limit →
  -- on_limit_reached('up') → history_back recalls the last entry.
  it('AC7 — console Up at the vertical limit navigates history',
    function()
      local console = F.console
      console.model.history:remember({ 'foo' })
      F.session.press('up')
      assert.same({ 'foo' }, console:get_text())
    end)
end)
