-- Highlight shape contract.
--
-- The view (userInputView.render_input) reads
-- `highlight.hl` and immediately indexes it
-- (`hl[tlc.l][tlc.c]`). Regression guard for the
-- "attempt to index upvalue hl (a nil value)" crash:
-- UserInputModel:get_highlight(), when it returns a
-- non-nil highlight, must always expose an INDEXABLE
-- `.hl` — never a plain-table field left nil.
--
-- The crash path is the parser-bearing evaluator whose
-- highlighter is absent (or returns nil): highlight()'s
-- parser branch used to store `{ hl = nil, parse_err }`,
-- a plain literal with no auto-vivifying metatable, so
-- `hl[l]` blew up.

require("model.input.userInputModel")
require("model.interpreter.eval.evaluator")
require("util.string.string")

if not orig_print then
  _G.orig_print = function() end
end

describe("highlight shape contract #input", function()
  local w        = 64
  local mockConf = { view = { drawableChars = w, lines = 16, input_max = 14 } }
  mock           = require("tests.mock")
  mock.mock_love({ state = { app_state = 'ready' } })

  -- Emulates the view's exact access on the first visible
  -- char: highlight.hl[line][col]. Must not throw.
  local function view_access_ok(model)
    local h = model:get_input().highlight
    if h == nil then return true end
    -- the view's own access: `hl[tlc.l]` with NO `hl and`
    -- guard (userInputView.lua render_input). Replicate it
    -- unguarded so a nil `.hl` throws exactly as it does live.
    return pcall(function()
      local hl = h.hl
      return hl[1] and hl[1][1]
    end)
  end

  it('parser present, highlighter returns nil -> hl still indexable', function()
    local ev = LuaEval()
    ev.highlighter = function() return nil end -- parser-bearing, no colouring
    local m = UserInputModel(mockConf, ev)
    m:set_text({ 'return 1' })
    assert.is_true(view_access_ok(m))
  end)

  it('standard lua eval -> hl indexable (empty and non-empty)', function()
    local m = UserInputModel(mockConf, InputEvalLua)
    assert.is_true(view_access_ok(m))
    m:set_text({ 'return 1' })
    assert.is_true(view_access_ok(m))
  end)

  it('validated text eval (no parser) -> hl indexable', function()
    local m = UserInputModel(mockConf, ValidatedTextEval({ function() return true end }))
    assert.is_true(view_access_ok(m))
    m:set_text({ '42' })
    assert.is_true(view_access_ok(m))
  end)
end)
