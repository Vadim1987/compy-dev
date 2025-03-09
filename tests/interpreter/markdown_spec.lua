local term = require("util.termcolor")
local mark = require("model.lang.md.parser")
require("util.debug")
require("util.tree")

local inputs = require("tests.interpreter.markdown_inputs")

local highlighter_debug = os.getenv("HL_DEBUG")

describe('Markdown parser #markdown', function()
  describe('highlights #markdown', function()
    for i, input in ipairs(inputs) do
      local tag = 'input #' .. i
      it(tag, function()
        -- term.print_c(4, tag)
        print(term.reset)
        local hl = mark.highlighter(input)
        -- Log.debug(Debug.terse_t(hl, nil, nil, true))
        if highlighter_debug then
          for l, line in ipairs(string.lines(input)) do
            local rowc = hl[l] or {}
            for j = 1, #line do
              local c = mark.colorize(rowc[j]) or 0
              term.print_c(c, string.usub(line, j, j), true)
              -- io.write((c or '') .. string.sub(line, j, j))
            end
            print()
          end
          print(term.reset)
        end
      end)
    end
  end)
end)
