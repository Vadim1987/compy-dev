local analyzer = require("model.lang.error")

describe(' #parse_error', function()
  -- it('', function() end)
  it('get_first', function()
    local f = { l = 2, c = 1, msg = 'error 3' }
    local t = {
      { l = 3, c = 10, msg = 'error 1' },
      { l = 2, c = 3,  msg = 'error 2' },
      f,
      { l = 4, c = 8, msg = 'error 4' },
      { l = 6, c = 5, msg = 'error 5' },
    }

    assert.same(Error.get_first(t), f)
  end)
end)
