-- parser.lua
-- Token parser: shorthand (3E), named sequences, relative dirs.

DIRECTIONS = { N = true, S = true, E = true, W = true }
RELATIVE = { L = true, R = true, F = true, B = true }
DRAW_CMDS = { C = true, G = true }
RESERVED = {
  N=1, S=1, E=1, W=1, L=1, R=1, F=1, B=1, C=1, G=1, Q=1,
}

-- Parse a single token like "N", "3E", "3F", "L"

function parseToken(s)
  local num, ch = s:match("^(%d+)([A-Za-z])$")
  if num and isMovable(ch:upper()) then
    return { dir = ch:upper(), count = tonumber(num) }
  end
  local u = s:upper()
  if #s == 1 and isCommand(u) then
    return { dir = u, count = 1 }
  end
  return nil
end

function isMovable(ch)
  return DIRECTIONS[ch] or ch == "F" or ch == "B"
end

function isCommand(ch)
  return DIRECTIONS[ch] or RELATIVE[ch] or DRAW_CMDS[ch]
end

-- Check if a character is a valid named sequence letter

function isSeqName(ch)
  local u = ch:upper()
  return #u == 1 and u:match("[A-Z]")
    and not RESERVED[u]
end

-- Parse a named sequence definition: "X=EENN"

function parseDefinition(line, defs)
  local name, body = line:match("^(%a)=(.+)$")
  if not name then
    return false
  end
  if not isSeqName(name) then
    return false
  end
  local cmds = tokenizeLine(body, defs)
  if cmds then
    defs[name:upper()] = cmds
  end
  return true
end

-- Tokenize a line into a list of {dir, count} commands

function tokenizeLine(line, defs)
  local cmds = { }
  local pos = 1
  while pos <= #line do
    pos = skipSpaces(line, pos)
    if pos > #line then break end
    local ok, npos = readToken(line, pos, defs, cmds)
    if not ok then return nil, pos end
    pos = npos
  end
  return cmds
end

function skipSpaces(line, pos)
  while pos <= #line and line:sub(pos, pos) == " " do
    pos = pos + 1
  end
  return pos
end

-- Read one token from line at pos, append to cmds

function readToken(line, pos, defs, cmds)
  local chunk = line:sub(pos):match("^%d*%a")
  if not chunk then
    return false, pos
  end
  local tok = parseToken(chunk)
  if tok then
    for i = 1, tok.count do
      table.insert(cmds, { dir = tok.dir, col = pos })
    end
    return true, pos + #chunk
  end
  return tryExpandSeq(chunk, defs, cmds, pos)
end

-- Try expanding a named sequence reference

function tryExpandSeq(chunk, defs, cmds, pos)
  local ch = chunk:sub(1, 1):upper()
  if defs and defs[ch] then
    for _, c in ipairs(defs[ch]) do
      table.insert(cmds, { dir = c.dir, col = pos })
    end
    return true, pos + 1
  end
  return false, pos
end

-- Parse all lines of the editor into commands

function parseProgram(lines)
  local defs = { }
  local all_cmds = { }
  local errors = { }
  for i, line in ipairs(lines) do
    parseProgramLine(line, i, defs, all_cmds, errors)
  end
  return all_cmds, errors, defs
end

function appendCmds(result, idx, cmds)
  for _, c in ipairs(result) do
    table.insert(cmds, {
      dir = c.dir, line = idx, col = c.col,
    })
  end
end

function parseProgramLine(line, idx, defs, cmds, errors)
  if line == "" then return end
  if parseDefinition(line, defs) then return end
  local result, err_pos = tokenizeLine(line, defs)
  if result then
    appendCmds(result, idx, cmds)
  else
    table.insert(errors, { line = idx, col = err_pos })
  end
end
