-- micro:bit tools. Load them into the console with
-- require("tools"); every function below becomes a command.
--
-- The board is a micro:bit with the Lua REPL firmware, on
-- USB. Everything it prints arrives through compy.serial,
-- and everything sent to it leaves the same way. The REPL is
-- a terminal: it ends its lines with CR, and it echoes every
-- character it receives.

local serial = compy.serial
local input = compy.input

local LEAVE_KEY = "shift+escape"
-- A highlighter is a plain function with no name of its own,
-- so the prompt looks the name up here; an unknown one is
-- "input". Until the input API names them itself.
local HIGHLIGHTER_NAMES = { [LuaHighlighter] = "Lua" }
local UNNAMED_PROMPT = "input"
local EXEC_PREFIX = "assert(loadstring [[\r"
local EXEC_SUFFIX = "]])()\r"
local EXEC_MARKER = "]])()"

-- echo --------------------------------------------------------

local echoing = false

-- The board ends lines with CR; the terminal wants LF
-- @param chunk string
-- @return string
local function asLines(chunk)
  local lf = chunk:gsub("\r\n", "\n"):gsub("\r", "\n")
  return lf
end

-- io.write, not print: a chunk is a piece of a line, and
-- print would end it
-- @param chunk string
local function printFromBoard(chunk)
  io.write(asLines(chunk))
end

-- Show everything the board sends. On by default once the
-- tools are loaded; echo(false) stops it, echo() resumes.
-- @param on boolean?
function echo(on)
  echoing = on ~= false
  serial.onBytes = echoing and printFromBoard or nil
end

-- terminal ----------------------------------------------------

-- What was typed, the way the REPL reads it: CR ends a line
-- @param text string
local function sendLine(text)
  local cr = text:gsub("\n", "\r")
  assert(serial.send(cr .. "\r"))
end

-- @return boolean consumed
local function leaveTerminal()
  input.hide()
  return true
end

-- A serial terminal: typed lines go to the board, its
-- answers show above through echo. Shift+Escape leaves it.
-- Lua highlighting unless another highlighter is given.
-- @param highlighter function?
function terminal(highlighter)
  local coloring = highlighter or LuaHighlighter
  local name = HIGHLIGHTER_NAMES[coloring] or UNNAMED_PROMPT
  input.shortcuts.keypressed[LEAVE_KEY] = leaveTerminal
  input.callbacks.after_submit = input.clear
  input.show{
    prompt = name .. "> ",
    highlighter = coloring,
    validator = false,
    on_text_entered = sendLine,
  }
end

-- send, exec --------------------------------------------------

-- A project file, ready for the REPL: CR line endings and
-- a CR at the end, so the last line is entered too
-- @param filename string
-- @return string
local function fileForBoard(filename)
  local text = assert(readfile(filename), "no " .. filename)
  local cr = text:gsub("\r\n", "\n"):gsub("\n", "\r")
  if cr:sub(-1) ~= "\r" then cr = cr .. "\r" end
  return cr
end

-- Send a project file to the board, line by line, as if
-- typed
-- @param filename string
function send(filename)
  assert(serial.send(fileForBoard(filename)))
end

-- Stay silent until the board has echoed the marker, then
-- print what followed and restore echo as it was
-- @param marker string
-- @return function
local function silentUntil(marker)
  local heard = ""
  return function(chunk)
    heard = heard .. chunk
    local _, at = heard:find(marker, 1, true)
    if not at then return end
    echo(echoing)
    if echoing then printFromBoard(heard:sub(at + 1)) end
  end
end

-- Run a project file on the board as one chunk, wrapped in
-- assert(loadstring [[ ... ]])(). The board echoes every byte
-- it receives; that echo is held back while the file is in
-- flight, the program's own output comes through.
-- @param filename string
function exec(filename)
  local body = fileForBoard(filename)
  local code = EXEC_PREFIX .. body .. EXEC_SUFFIX
  serial.onBytes = silentUntil(EXEC_MARKER)
  assert(serial.send(code))
end

-- help --------------------------------------------------------

function help()
  print("micro:bit tools")
  print("  help()                    this list")
  print("  echo(on)                  board output in the")
  print("                            console; echo(false)")
  print("                            stops it, echo() resumes")
  print("  terminal(highlighter)     type to the board;")
  print("                            Shift+Escape leaves")
  print("  send(filename)            file to the board,")
  print("                            as typed")
  print("  exec(filename)            file to the board,")
  print("                            run as one chunk")
end

echo()
help()
