-- Availability: predates the Compy input API (introduced in
-- 1.0.0-rc20260712).

require("model.interpreter.eval.evaluator")

describe('Input Evaluator #input', function()
  local eval = TextEval

  it('returns', function()
    local input = { 'asd' }
    local ok, ret = eval:apply(input)

    assert.truthy(ok)
    assert.same(input, ret)
  end)
  it('returns multiline', function()
    local input = { 'asd', 'qwer' }

    local ok, ret = eval:apply(input)
    assert.truthy(ok)
    assert.same(input, ret)
  end)

  it('returns multiline with empties', function()
    local input = { '', 'asd', 'qwer' }

    local ok, ret = eval:apply(input)
    assert.truthy(ok)
    assert.same(input, ret)
  end)
end)
