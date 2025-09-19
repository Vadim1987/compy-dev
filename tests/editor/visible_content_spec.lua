require("view.editor.visibleContent")

require("util.string.string")

describe('VisibleContent #wrap', function()
  local turtle_doc = {
    '',
    'Turtle graphics game inspired the LOGO family of languages.',
    '',
  }

  local os_max = 8
  local input_max = 16

  local content1 = VisibleContent(80, {},
    os_max, input_max)
  local content2 = VisibleContent(30, turtle_doc,
    os_max, input_max)
  describe('produces forward mapping', function()
    it('1', function()
      local fwd1 = { { 1 } }
      assert.same(fwd1, content1.wrap_forward)
    end)
    it('2', function()
      local fwd2 = { { 1 }, { 2, 3 }, { 4 }, { 5 } }
      assert.same(fwd2, content2.wrap_forward)
    end)
  end)
  describe('produces reverse mapping', function()
    it('1', function()
      local rev1 = { 0 }
      assert.same(rev1, content1.wrap_reverse)
    end)
    it('2', function()
      local rev2 = { 1, 2, 2, 3, 4 }
      assert.same(rev2, content2.wrap_reverse)
    end)
  end)

  describe('correctly determines visible range', function()
    local w = 5
    local L = 4
    local starter = '123'
    local wrapper = VisibleContent(w, { starter }, 0, L)
    it('1', function()
      assert.same({ starter }, wrapper:get_text())
      assert.same(1, wrapper:get_text_length())
      wrapper:check_range()
      assert.same(Range(1, 1), wrapper:get_range())
    end)
  end)
end)
