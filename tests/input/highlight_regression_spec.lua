-- Availability: pre-baseline machinery — the highlighter predates
-- this feature; this guards a render crash fixed in it (changed in
-- 1.0.0-rc20260712).

-- Regression guard: highlight `.hl` must stay indexable.
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

--- REVIEW/coherence: does it interfere with other tests?
if not orig_print then
  _G.orig_print = function() end
end

describe("highlight nil-index regression #input", function()
  local w        = 64
  local mockConf = { view = { drawableChars = w, lines = 16, input_max = 14 } }
  mock           = require("tests.mock")
  mock.mock_love({ state = { app_state = 'ready' } })

  -- Emulates the view's exact access on the first visible
  -- char: highlight.hl[line][col]. Must not throw.
  -- REVIEW/clarity: function name does not communicate the purpose of check unambiguously
  local function view_access_ok(model)
    local h = model:get_input().highlight
    --- REVIEW/fidelity: does this guard betray the purpose of test?
    if h == nil then return true end
    -- the view's own access: `hl[tlc.l]` with NO `hl and`
    -- guard (userInputView.lua render_input). Replicate it
    -- unguarded so a nil `.hl` throws exactly as it does live.
    -- REVIEW/fidelity: why check test symptom instead of bug path? (i.e. calling the function which internally could've blow up?)
    return pcall(function()
      local hl = h.hl
      return hl[1] and hl[1][1]
    end)
  end

  -- REVIEW/clarity: what's the difference between three modes not explained? (especially not clear how LuaEval() is different from InputEvalLua. Maybe wrap them into aliases semantically meaningful in test context? (e.g. `ev = evaluator_without_highlighter()`, `input_with_lua_evaluator', 'input_with_text_evaluator'). Or even table (ev = evaluators['text_no_hl']; m=evaluators['lua_normal']; m=evaluators['lua_with_dummy_hl'])
  -- Three cases, one per highlighter condition that decides
  -- whether `.hl` is a crash-prone plain literal or indexable:
  --   1. Lua parser present, highlighter returns nil — the exact
  --      regression path. Uses the LuaEval() FACTORY (a fresh
  --      instance) so it can override .highlighter to nil without
  --      mutating the shared InputEvalLua singleton.
  --   2. Standard Lua eval (InputEvalLua singleton, real
  --      highlighter) — normal colouring, empty + non-empty text.
  --   3. Validated text eval — no parser, takes the non-parser
  --      branch; a different production scenario (text, not Lua).
  it('parser present, highlighter returns nil -> hl still indexable', function()
    --- REVIEW/clarity/fidelity:  how LuaEval() with nil-returning highlighter is different from case#2 and case#3? it seems to be a mix of both, but not sure which production scenarios are mapped. And maybe there shold be 4 cases? ( [lua || text] x [ missing hl || returning empty ])
    local ev = LuaEval()
    ev.highlighter = function() return nil end -- parser-bearing, no colouring
    local m = UserInputModel(mockConf, ev)
    m:set_text({ 'return 1' })
    assert.is_true(view_access_ok(m))
  end)

  -- REVIEW/fidelity: claims 'empty and non-empty' but its not clear what both mean and how *both* are tested
  it('standard lua eval -> hl indexable (empty and non-empty)', function()
    local m = UserInputModel(mockConf, InputEvalLua)
    assert.is_true(view_access_ok(m))
    m:set_text({ 'return 1' })
    assert.is_true(view_access_ok(m))
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
      assert.is_true(view_access_ok(m))
    end)

  it('validated text eval (no parser) -> hl indexable', function()
    local m = UserInputModel(mockConf, ValidatedTextEval({ function() return true end }))
    assert.is_true(view_access_ok(m))
    m:set_text({ '42' })
    assert.is_true(view_access_ok(m))
  end)
end)
