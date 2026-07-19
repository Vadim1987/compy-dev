-- dispatch chain: widget outputs and submit/cancel — split from
-- input_contracts_spec.lua (TF1). Routing invariant (doc/development/decisions/input.md,
-- Decision 1): inter-route dispatch is EXCLUSIVE — each event reaches
-- exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = consumer an event
-- is dispatched to; WIDGET = a route-managed input surface; SINK = last
-- consumer. Tests assert observable outcomes at public seams, never
-- method-name spies. keypressed fires for every physical key, textinput
-- only for character-producing keys (doc/development/internals/user_input.md, "Data
-- flow").
-- Outputs half of the four-tier dispatch chain (Decision 5's four widget
-- output fields, the highlighter/on_limit_reached boundary, and the full
-- submit/cancel call-order chains of Decision 6). The mechanics half
-- (order/consume/fall-through, combo tables, signatures) is
-- input_dispatch_chain_spec.lua.

local F    = require('tests.helpers.input_fixture')
local mock = require('tests.mock')

-- ====================================================
-- The {jargon: four-tier dispatch chain} ({badspecref:
-- 0.1.0-m5c}, doc/development/decisions/input.md, Decision 2).
-- All rows drive the REAL project route: F.activate_
-- project() installs the ProjectInputController as the
-- {jargon: slot occupant} (app_state='running') via the same
-- Controller.set_user_handlers path a run calls, and
-- returns the project-facing compy.input surface. The
-- observable {jargon: seams} are the widget's text (the sink)
-- and
-- the callbacks a project registers — never a spy on an
-- internal method (except the one sink-signature row,
-- which patches the shared singleton and restores it).
-- ====================================================

describe('dispatch chain: widget outputs and submit/cancel #m5c #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- ---- widget outputs (doc/development/decisions/input.md, Decision 5)
  -- ----------

  -- doc/development/decisions/input.md, Decision 5: the four widget
  -- outputs are project-assignable
  -- fields on compy.input (same boundary, widened allowlist).
  it('the four widget output fields are assignable',
    function()
      local input = F.compy_input()
      assert.has_no.errors(function()
        input.on_text_entered  = function() end
        input.on_limit_reached = function() end
        input.validator        = function() end
        input.highlighter      = function() end
      end)
    end)

  -- doc/development/decisions/input.md, Decision 5: show(config) keys and
  -- field assignment hit
  -- the same underlying {jargon: slots}.
  it('show(config) and fields share one output slot',
    function()
      local input = F.compy_input()
      local cb = function() end
      input.show({ on_limit_reached = cb })
      assert.equal(cb, input.on_limit_reached)
      local hl = function() return { { } } end
      input.highlighter = hl
      input.show()
      assert.equal(hl, input.highlighter)
    end)

  -- doc/development/decisions/input.md, Decision 5 cont.: on_text_entered
  -- and validator also
  -- reach the same {jargon: slot} via config key and via
  -- field write
  -- (settable-only here; firing/gating is decisions/
  -- input.md, Decision 6).
  it('show(config) shares on_text_entered slot',
    function()
      local input = F.compy_input()
      local cb = function() end
      input.show({ on_text_entered = cb })
      assert.equal(cb, input.on_text_entered)
    end)

  it('field write shares on_text_entered slot',
    function()
      local input = F.compy_input()
      local cb = function() end
      input.on_text_entered = cb
      input.show()
      assert.equal(cb, input.on_text_entered)
    end)

  it('show(config) shares validator slot',
    function()
      local input = F.compy_input()
      local vfn = function() return true end
      input.show({ validator = vfn })
      assert.equal(vfn, input.validator)
    end)

  it('field write shares validator slot',
    function()
      local input = F.compy_input()
      local vfn = function() return true end
      input.validator = vfn
      input.show()
      assert.equal(vfn, input.validator)
    end)

  -- doc/development/decisions/input.md, Decision 5: a custom highlighter
  -- transforms live text and
  -- the queried highlight reflects that transformed output.
  it('a custom highlighter transforms queried highlight',
    function()
      local input = F.activate_project()
      local marker = { { 'x' } }
      input.show({
        highlighter = function()
          return marker
        end,
      })
      F.session.type('a')
      local got = F.singleton.model:get_highlight()
      assert.equal(marker, got.hl)
    end)

  -- doc/development/decisions/input.md, Decision 5, boundary half:
  -- crossing attempts fire
  -- on_limit_reached(direction, scope) and its return value
  -- is ignored (observational only; sink still runs).
  it('up boundary fires direction up with input scope',
    function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.singleton:set_cursor(Cursor(1, 2))
      F.session.press('up')
      assert.same({ { 'up', 'input' } }, seen)
    end)

  it('down boundary fires direction down with input scope',
    function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = { 'ab', 'cd' },
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
        end,
      })
      F.singleton:set_cursor(Cursor(2, 2))
      F.session.press('down')
      assert.same({ { 'down', 'input' } }, seen)
    end)

  it('left boundary fires output; return is ignored',
    function()
      local seen = { }
      local input = F.activate_project()
      input.show({
        text = 'ab',
        on_limit_reached = function(dir, scope)
          seen[#seen + 1] = { dir, scope }
          return true
        end,
      })
      F.singleton:jump_home()
      F.session.press('left')
      assert.same({ { 'left', 'input' } }, seen)
    end)

  -- doc/development/decisions/input.md, Decision 5: line-scope boundary
  -- in multiline text.
  it('left line boundary fires scope line', function()
    local seen = { }
    local input = F.activate_project()
    input.show({
      text = { 'ab', 'cd' },
      on_limit_reached = function(dir, scope)
        seen[#seen + 1] = { dir, scope }
      end,
    })
    F.singleton:set_cursor(Cursor(2, 1))
    F.session.press('left')
    assert.same({ { 'left', 'line' } }, seen)
  end)

  it('right line boundary fires scope line', function()
    local seen = { }
    local input = F.activate_project()
    input.show({
      text = { 'ab', 'cd' },
      on_limit_reached = function(dir, scope)
        seen[#seen + 1] = { dir, scope }
      end,
    })
    F.singleton:set_cursor(Cursor(1, 3))
    F.session.press('right')
    assert.same({ { 'right', 'line' } }, seen)
  end)

  -- Edge case: first-line left is a horizontal key that
  -- maps to whole-input limit scope.
  it('left at first-line start has input scope', function()
    local seen = { }
    local input = F.activate_project()
    input.show({
      text = { 'ab', 'cd' },
      on_limit_reached = function(dir, scope)
        seen[#seen + 1] = { dir, scope }
      end,
    })
    F.singleton:set_cursor(Cursor(1, 1))
    F.session.press('left')
    assert.same({ { 'left', 'input' } }, seen)
  end)

  -- Edge case: last-line right is a horizontal key that
  -- maps to whole-input limit scope.
  it('right at last-line end reports input scope', function()
    local seen = { }
    local input = F.activate_project()
    input.show({
      text = { 'ab', 'cd' },
      on_limit_reached = function(dir, scope)
        seen[#seen + 1] = { dir, scope }
      end,
    })
    F.singleton:set_cursor(Cursor(2, 3))
    F.session.press('right')
    assert.same({ { 'right', 'input' } }, seen)
  end)

  -- ---- submit and cancel (doc/development/decisions/input.md,
  -- Decision 6) -------

  -- doc/development/decisions/input.md, Decision 6: the full submit
  -- call-order chain on a real Enter
  -- keypress. on_text_entered receives the FULL ASSEMBLED
  -- text (Decision 5) — not a per-character capture
  -- (same decision's trap).
  it('Enter runs the full submit call-order chain',
    function()
      local order = { }
      local input = F.activate_project()
      input.before_submit = function()
        order[#order + 1] = 'before'
      end
      input.after_submit = function(t)
        order[#order + 1] = 'after:' .. t
      end
      input.show({
        text = { 'a', 'b' },
        on_text_entered = function(t)
          order[#order + 1] = 'entered:' .. t
        end,
      })
      F.session.press('return')
      assert.same(
        { 'before', 'entered:a\nb', 'after:a\nb' }, order)
    end)

  -- doc/development/internals/user_input.md, "Submit and cancel — the
  -- framework tier-1 chains": on_text_entered sees the
  -- session still active;
  -- after_submit sees it deactivated (the observable order
  -- the mechanism note fixes once push('userinput') is gone).
  it('on_text_entered sees the session active; ' ..
    'after_submit sees it deactivated', function()
    local seen = { }
    local input = F.activate_project()
    input.show({
      text = 'x',
      on_text_entered = function()
        seen.entered = love.state.user_input ~= nil
      end,
    })
    input.after_submit = function()
      seen.after = love.state.user_input ~= nil
    end
    F.session.press('return')
    assert.is_true(seen.entered)
    assert.is_false(seen.after)
  end)

  -- doc/development/internals/user_input.md, "Submit and cancel — the
  -- framework tier-1 chains": a custom validator is invoked
  -- with the live
  -- assembled text (not stale/empty data).
  it('a custom validator is invoked with the assembled text',
    function()
      local seen
      local input = F.activate_project()
      input.show({
        text = 'ab',
        validator = function(t) seen = t; return true end,
      })
      F.session.press('return')
      assert.equal('ab', seen)
    end)

  -- doc/development/internals/user_input.md, "Submit and cancel — the
  -- framework tier-1 chains": a rejecting validator locks
  -- the
  -- session — no delivery, no deactivation, no
  -- after_submit.
  it('a rejecting validator locks input without delivering',
    function()
      local entered, after = false, false
      local input = F.activate_project()
      input.after_submit = function() after = true end
      input.show({
        text = 'bad',
        validator = function() return false, 'nope' end,
        on_text_entered = function() entered = true end,
      })
      F.session.press('return')
      assert.is_false(entered)
      assert.is_false(after)
      assert.is_not_nil(love.state.user_input)
      assert.is_true(F.singleton:has_error())
    end)

  -- doc/development/decisions/input.md, Decision 6: the full cancel
  -- call-order chain;
  -- Escape genuinely
  -- dismisses (content cleared AND the widget hidden).
  it('Escape runs the full cancel call-order chain',
    function()
      local order = { }
      local input = F.activate_project()
      input.before_cancel = function()
        order[#order + 1] = 'before'
      end
      input.after_cancel = function()
        order[#order + 1] = 'after'
      end
      input.show({ text = 'x' })
      F.session.press('escape')
      assert.same({ 'before', 'after' }, order)
      assert.is_nil(love.state.user_input)
      assert.is_true(F.singleton:is_empty())
    end)

  -- doc/development/internals/user_input.md, "Submit and cancel — the
  -- framework tier-1 chains": Enter/Escape are ordinary
  -- keys while
  -- hidden — no
  -- framework entry engages, so lower {jargon: tiers} get a
  -- chance.
  it('Enter and Escape are ordinary keys while hidden',
    function()
      local seen = { }
      local input = F.activate_project()
      input.handlers.keypressed['return'] = function()
        seen[#seen + 1] = 'return'; return true
      end
      input.handlers.keypressed['escape'] = function()
        seen[#seen + 1] = 'escape'; return true
      end
      F.session.press('return')
      F.session.press('escape')
      assert.same({ 'return', 'escape' }, seen)
    end)

  -- doc/development/internals/user_input.md, "Submit and cancel — the
  -- framework tier-1 chains": while shown, the framework
  -- entries run first,
  -- unconditionally — a project combo handler cannot shadow
  -- them (the submit still ran: the widget deactivated).
  it('framework Enter cannot be shadowed while shown',
    function()
      local shadowed = false
      local input = F.activate_project()
      input.handlers.keypressed['return'] = function()
        shadowed = true; return true
      end
      input.show({ text = 'x' })
      F.session.press('return')
      assert.is_false(shadowed)
      assert.is_nil(love.state.user_input)
    end)

  -- doc/development/internals/user_input.md, "Multiline input": Shift+Return
  -- is NOT a framework
  -- combo — it falls
  -- to the sink, which still inserts a newline (unchanged
  -- sink behaviour); the widget stays open (not submitted).
  -- Drives BOTH modifier tracks the production code reads:
  -- F.session.press keeps Controller.keys_pressed (combo_
  -- string) correct, mock.keystroke's 'S' token flips the
  -- separate love.keyboard.isDown mock the sink's own
  -- Key.shift() reads (tests/mock.lua — two distinct
  -- tables).
  it('Shift+Return is not intercepted; the sink edits',
    function()
      F.activate_project()
      F.show_widget({ text = 'a' })
      F.session.press('lshift')
      mock.keystroke('S-return', F.session.press, false)
      assert.same({ 'a', '' }, F.singleton:get_text())
      assert.is_not_nil(love.state.user_input)
    end)

  -- doc/development/decisions/input.md, Decision 6 ("hide() ... fires no
  -- cancel chain"): hide() and a force=true reconfigure
  -- fire no
  -- cancel chain (the user-facing dismiss is Escape only).
  it('hide() fires no cancel chain', function()
    local fired = false
    local input = F.activate_project()
    input.before_cancel = function() fired = true end
    input.show({ text = 'x' })
    input.hide()
    assert.is_false(fired)
  end)

  it('a force=true reconfigure fires no cancel chain',
    function()
      local fired = false
      local input = F.activate_project()
      input.before_cancel = function() fired = true end
      input.show({ text = 'first' })
      input.show({ force = true, text = 'second' })
      assert.is_false(fired)
    end)

  -- doc/input_api.md, "The continuous-session idiom":
  -- re-activates within
  -- the same submit sequence, before the frame draws.
  it('after_submit can re-activate the widget mid-sequence',
    function()
      local input = F.activate_project()
      input.after_submit = function()
        input.show({ prompt = 'next' })
      end
      input.show({ text = 'first' })
      F.session.press('return')
      assert.is_not_nil(love.state.user_input)
      assert.is_true(F.singleton:is_empty())
    end)

  -- doc/input_api.md, "Sticky callbacks": widget outputs
  -- persist across a deactivation —
  -- only project stop resets them (a later chunk), not
  -- submit.
  it('on_text_entered persists across a hide/re-show cycle',
    function()
      local hits = 0
      local input = F.activate_project()
      input.show({
        text = 'a',
        on_text_entered = function() hits = hits + 1 end,
      })
      F.session.press('return')
      input.show({ text = 'b' })
      F.session.press('return')
      assert.equal(2, hits)
    end)

  -- doc/development/decisions/input.md, Decision 6: absent hooks default
  -- to noop —
  -- submit and cancel
  -- both complete without error when no hook is configured
  -- (the green replacement for the
  -- retired 'a oneshot
  -- submit deactivates the widget' row — internals/
  -- user_input.md, "Submit and cancel — the framework
  -- tier-1 chains": this proves
  -- deactivation without any of the deleted oneshot/push
  -- machinery).
  it('submit and cancel complete with no hooks set',
    function()
      F.activate_project()
      F.show_widget({ text = 'x' })
      assert.has_no.errors(function()
        F.session.press('return')
      end)
      assert.is_nil(love.state.user_input)
      F.show_widget({ text = 'y' })
      assert.has_no.errors(function()
        F.session.press('escape')
      end)
      assert.is_nil(love.state.user_input)
    end)
end)
