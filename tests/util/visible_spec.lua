require("view.editor.visibleContent")
require("model.input.cursor")
require("util.string.string")
require("util.debug")

local md_ex = [[### Input validation

As an extension to the user input functionality, `validated_input()` allows arbitrary user-specified filters.
A "filter" is a function, which takes a string as input and returns a boolean value of whether it is valid and an optional `Error`.
The `Error` is structure which contains the error message (`msg`), and the location the error comes from, with line and character fields (`l` and `c`).

#### Helper functions

* `string.ulen(s)` - as opposed to the builtin `len()`, this works for unicode strings
* `string.usub(s, from, to)` - unicode substrings
* `Char.is_alpha(c)` - is `c` a letter
* `Char.is_alnum(c)` - is `c` a letter or a number (alphanumeric)
]]
local text = string.lines(md_ex)
local w = 64

describe('VisibleContent #visible', function()
  local visible = VisibleContent(w, text, 1, 8)

  -- Log.debug(Debug.terse_ast(visible, true, 'lua'))
  it('translates', function()
    --- scroll to the top
    visible:move_range(- #text)
    local cur11 = Cursor()
    local cur33 = Cursor(3, 3)
    local cur3w = Cursor(3, w)
    local cur3wp1 = Cursor(3, w + 1)
    local cur44 = Cursor(4, 4)
    assert.same(cur11, visible:translate_to_wrapped(cur11))
    assert.same(cur33, visible:translate_to_wrapped(cur33))
    assert.same(cur3w, visible:translate_to_wrapped(cur3w))
    assert.same(Cursor(4, 1), visible:translate_to_wrapped(cur3wp1))

    assert.same(cur33, visible:translate_from_visible(cur33))
    local cur3_67 = Cursor(3, 3 + w)
    local exp3_67 = Cursor(4, 3)
    assert.same(exp3_67, visible:translate_to_wrapped(cur3_67))

    --- scroll to bottom
    visible:to_end()
    -- #01: ''
    -- #02: '* `string.ulen(s)` - as opposed to the builtin `len()`, this wor'
    -- #03: 'ks for unicode strings'
    -- #04: '* `string.usub(s, from, to)` - unicode substrings'
    -- #05: '* `Char.is_alpha(c)` - is `c` a letter'
    -- #06: '* `Char.is_alnum(c)` - is `c` a letter or a number (alphanumeric'
    -- #07: ')'
    -- #08: ''
    assert.same(Cursor(9, 3 + w),
      visible:translate_from_visible(cur33))
    assert.same(Cursor(10, 4),
      visible:translate_from_visible(cur44))
    assert.is_nil(visible:translate_from_visible(Cursor(5, 40)))
    local cur71 = Cursor(7, 1)
    assert.same(Cursor(12, 65),
      visible:translate_from_visible(cur71))
  end)
end)
