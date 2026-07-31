-- Availability: the highlighter predates the Compy input API
-- (introduced in 1.0.0-rc20260712); this guards a render crash
-- fixed there.

-- Regression guard: highlight `.hl` must stay indexable.
--
-- The invariant: UserInputModel:get_highlight(), whenever it returns a
-- highlight at all, exposes an INDEXABLE `.hl` — never a plain-table
-- field left nil. Consumers index it straight away (the view reads
-- `highlight.hl` then `hl[l][c]`), and the original
-- "attempt to index upvalue hl (a nil value)" crash was exactly that
-- field arriving nil.
--
-- `highlight()` has TWO branches and each had to be taught the
-- invariant separately — the parser branch (`{ hl = hl or {}, … }`)
-- and the parser-less one (`{ hl = ev.highlighter(text) or {} }`). The
-- rows below are the resulting matrix: [lua parser || plain text] x
-- [highlighter returning nil || highlighter absent], plus the
-- empty/non-empty text split on the standard lua evaluator.

require("model.input.userInputModel")
require("model.interpreter.eval.evaluator")
require("util.string.string")

if not orig_print then
  _G.orig_print = function() end
end

describe("highlight nil-index regression #input", function()
  local w        = 64
  local mockConf = { view = { drawableChars = w, lines = 16, input_max = 14 } }
  mock           = require("tests.mock")
  mock.mock_love({ state = { app_state = 'ready' } })

  -- The contract guarded here is the MODEL's: whenever
  -- get_highlight() returns a highlight at all, its `.hl` must
  -- be indexable.  Asserted on the model directly, not through
  -- a replica of the view's access. The view carries its own
  -- `if hl and hl[tlc.l]` guard since the same fix that made
  -- `.hl` indexable (src/view/input/userInputView.lua), so a
  -- view-shaped replica would assert a symptom the live view no
  -- longer shows — while the model contract, which every other
  -- consumer of `.hl` depends on, is the thing that actually
  -- has to hold. Nothing is swallowed by pcall either: a nil
  -- `.hl` fails the assertion outright instead of collapsing
  -- into a boolean.
  local function assert_indexable_hl(model)
    local h = model:get_input().highlight
    assert.is_not_nil(h)
    assert.is_table(h.hl, '.hl is a table, never nil')
    assert.has_no.errors(function() return h.hl[1] and h.hl[1][1] end)
  end

  -- One row per highlighter condition that decides whether `.hl` is a
  -- crash-prone plain literal or indexable:
  --   1. Lua parser present, highlighter returns nil — the original
  --      regression path. Uses the LuaEval() FACTORY (a fresh
  --      instance) so it can override .highlighter to nil without
  --      mutating the shared InputEvalLua singleton.
  --   2. Standard Lua eval (InputEvalLua singleton, real
  --      highlighter) — normal colouring, one row for empty text and
  --      one for non-empty.
  --   3. Text eval (no parser), highlighter returns nil — the same
  --      hole on the other branch, and the one a project actually
  --      reaches through show({ highlighter = … }).
  --   4. Text eval, no highlighter at all — the validation-highlight
  --      path, a different production scenario (text, not Lua).
  it('lua eval, highlighter returns nil -> hl still indexable',
    function()
      local ev = LuaEval()
      ev.highlighter = function() return nil end -- parser, no colouring
      local m = UserInputModel(mockConf, ev)
      m:set_text({ 'return 1' })
      assert_indexable_hl(m)
    end)

  -- "empty" and "non-empty" are the model's TEXT, split into their own
  -- rows so each states which one it covers: a freshly built model
  -- holds no text, and the highlight is memoised on first query.
  it('lua eval, empty text -> hl indexable', function()
    assert_indexable_hl(UserInputModel(mockConf, InputEvalLua))
  end)

  it('lua eval, non-empty text -> hl indexable', function()
    local m = UserInputModel(mockConf, InputEvalLua)
    m:set_text({ 'return 1' })
    assert_indexable_hl(m)
  end)

  -- The non-parser branch's own nil-highlighter cell — the missing
  -- square of [lua || text] x [highlighter absent || returning nil].
  -- Reachable from the public API: the project widget is built on a
  -- parser-less evaluator (`UserInputModel(baseconf, InputEvalText)`,
  -- src/main.lua) and `show({ highlighter = f })` assigns f straight
  -- onto that evaluator (src/controller/userInputController.lua), so a
  -- highlighter returning nil for some input — e.g. one that returns
  -- nothing for empty text — lands here. A fresh ValidatedTextEval
  -- stands in for it so the shared InputEvalText singleton is not
  -- mutated.
  it('text eval, highlighter returns nil -> hl still indexable',
    function()
      local ev = ValidatedTextEval({ function() return true end })
      ev.highlighter = function() return nil end
      local m = UserInputModel(mockConf, ev)
      m:set_text({ '42' })
      assert_indexable_hl(m)
    end)

  it('text eval, no highlighter -> hl indexable', function()
    local m = UserInputModel(mockConf,
      ValidatedTextEval({ function() return true end }))
    assert_indexable_hl(m)
    m:set_text({ '42' })
    assert_indexable_hl(m)
  end)
end)
