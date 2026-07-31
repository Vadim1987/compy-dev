-- Availability: the History model below predates the Compy
-- input API (introduced in 1.0.0-rc20260712); the
-- console-navigation group at the bottom of this file arrived
-- with it.

--- @diagnostic disable: invisible
require("model.input.history")
local F = require('tests.helpers.input_fixture')

if not orig_print then
  --- @diagnostic disable: duplicate-set-field
  _G.orig_print = function() end
end

describe('history #history', function()
  require("util.debug")

  local history
  local t = {
    { 'close_project()' },
    { 'project("clock")' },
    { 'run("turtle")' },
  }
  local t1 = t[1]
  local ok = false
  local cur = { '' }
  setup(function()
    history = History()
  end)

  it('remembers', function()
    history:remember(t1)
    local h1 = { t1 }
    assert.same(h1, history:_get_entries())
    history:remember(t[2])
    history:remember(t[3])
    assert.same(t, history:_get_entries())
  end)
  it('recalls', function()
    --- go back
    assert.same(t, history:_get_entries())
    assert.same(nil, history.index)
    ok, cur = history:history_back()
    assert.same(3, history.index)
    assert.is_true(ok)
    assert.same(t[3], cur)
    ok, cur = history:history_back()
    assert.same(2, history.index)
    assert.is_true(ok)
    assert.same(t[2], cur)
    ok, cur = history:history_back()
    assert.same(1, history.index)
    assert.is_true(ok)
    assert.same(t[1], cur)
    --- bottoms out
    ok, cur = history:history_back()
    assert.same(1, history.index)
    assert.is_false(ok)

    --- now go fwd
    ok, cur = history:history_fwd()
    assert.same(2, history.index)
    assert.is_true(ok)
    assert.same(t[2], cur)
    ok, cur = history:history_fwd()
    assert.same(3, history.index)
    assert.is_true(ok)
    assert.same(t[3], cur)
    --- no more items
    ok, cur = history:history_fwd()
    assert.same(3, history.index)
    assert.is_false(ok)
    assert.same(nil, cur)
  end)
end)

-- Recall the way a user reaches it, through the real console.
-- The console input is single-line, so Up hits the vertical
-- limit at once and the widget reports that through the
-- on_limit_reached callback wired at construction; the
-- console's handler turns it
-- into history_back (doc/development/decisions/input.md,
-- Decision 5). The retired mechanism -- the console reading
-- keypressed's return value -- is why this is an end-to-end row
-- and not another model one.
describe('console history navigation #input #history',
  function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  it('Up at the vertical limit recalls the last entry',
    function()
    F.console.model.history:remember({ 'foo' })
    F.session.press('up')
    assert.same({ 'foo' }, F.console:get_text())
  end)
end)
