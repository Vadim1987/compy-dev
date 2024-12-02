--- @param s str
--- @param defs Assignment[]
--- @return table {string[], string[]}
local prep = function(s, defs)
  local orig = (function()
    if type(s) == 'string' then
      return string.lines(s)
    elseif type(s) == 'table' then
      local ret = {}
      for i, v in ipairs(s) do
        ret[i] = v
      end
      return ret
    end
  end)()

  return { orig, defs }
end

local table1 = prep({
  'local t = {',
  ' ty = 3,',
  '}',
  't2 = {',
  ' w1 = 1,',
  ' w2 = 2,',
  '}',
  'a = {',
  ' 1,',
  ' z = 2,',
  ' 3,',
  '}',
}, {
  { name = 't',     line = 1,  type = 'local' },
  { name = 't.ty',  line = 2,  type = 'field' },
  { name = 't2',    line = 4,  type = 'global' },
  { name = 't2.w1', line = 5,  type = 'field' },
  { name = 't2.w2', line = 6,  type = 'field' },
  { name = 'a',     line = 8,  type = 'global' },
  { name = 'a.z',   line = 10, type = 'field' },
})
local table2 = prep({
  'tmp = {}',
  'tmp[1] = 2',
}, {
  { name = 'tmp', line = 1, type = 'global' }
})

local simple = {
  --- sets
  prep({
    'x = 2',
    'y = 3',
    'x = 3',
    'w, ww = 10, 11',
  }, {
    { line = 1, name = 'x',  type = 'global', },
    { line = 2, name = 'y',  type = 'global', },
    { line = 3, name = 'x',  type = 'global', },
    { line = 4, name = 'w',  type = 'global', },
    { line = 4, name = 'ww', type = 'global', },
  }),
  prep({
    'local l = 1',
    'local x, y = 2, 3',
  }, {
    { line = 1, name = 'l', type = 'local', },
    { line = 2, name = 'x', type = 'local', },
    { line = 2, name = 'y', type = 'local', },
  }),
  --- tables
  table1,
  -- table2,
  --- functions
  prep({
    'function drawBackground()',
    'end',
  }, {
    { line = 1, name = 'drawBackground', type = 'function', },
  }),
  prep({
    'function love.draw()',
    '  draw()',
    'end',
  }, {
    { line = 1, name = 'love.draw', type = 'function', },
  }),
  prep({
    'function love.handlers.keypressed()',
    'end',
  }, {
    { line = 1, name = 'love.handlers.keypressed', type = 'function', },
  }),
  prep({
    'local function drawBody()',
    'end',
  }, {
    { name = 'drawBody', line = 1, type = 'function' }
  }),
  --- methods
  prep({
    'function M:draw()',
    'end',
  }, {
    { name = 'M:draw', line = 1, type = 'method' }
  }),
}

local sierpinski = [[function sierpinski(depth)
  lines = { '*' }
  for i = 2, depth + 1 do
    sp = string.rep(' ', 2 ^ (i - 2))
    tmp = {} -- comment
    for idx, line in ipairs(lines) do
      tmp[idx] = sp .. line .. sp
      tmp[idx + #lines] = line .. ' ' .. line
    end
    lines = tmp
  end
  return table.concat(lines, '\n')
end

print(sierpinski(4))]]

local clock = {
  'love.draw = function()',
  '  draw()',
  'end',
  '',
  'function love.update(dt)',
  '  t = t + dt',
  '  s = math.floor(t)',
  '  if s > midnight then s = 0 end',
  'end',
  '',
  'function cycle(c)',
  '  if c > 7 then return 1 end',
  '  return c + 1',
  'end',
  '',
  'love.keyreleased = function (k)',
  '  if k == \'space\' then',
  '    if love.keyboard.isDown("lshift", "rshift") then',
  '      bg_color = cycle(bg_color)',
  '    else',
  '      color = cycle(color)',
  '    end',
  '  end',
  '  if k == \'s\' then',
  '    stop(\'STOP THE CLOCKS!\')',
  '  end',
  'end' }

local meta =
[[
--- @param node token
--- @return table
function M:extract_comments(node)
   local lfi = node.lineinfo.first
   local lla = node.lineinfo.last
   local comments = {}

   --- @param c table
   --- @param pos 'first'|'last'
   local function add_comment(c, pos)
      local idf = c.lineinfo.first.id
      local idl = c.lineinfo.last.id
      local present = self.comment_ids[idf] or self.comment_ids[idl]
      if not present then
         local comment_text    = c[1]
         local len             = string.len(comment_text)
         local n_l             = #(string.lines(comment_text))
         local cfi             = c.lineinfo.first
         local cla             = c.lineinfo.last
         local cfirst          = { l = cfi.line, c = cfi.column }
         local clast           = { l = cla.line, c = cla.column }
         local off             = cla.offset - cfi.offset
         local d               = off - len
         local l_d             = cla.line - cfi.line
         local newline         = (n_l ~= 0 and n_l == l_d)
         local li              = {
            idf = idf,
            idl = idl,
            first = cfirst,
            last = clast,
            text = comment_text,
            multiline = (d > 4),
            position = pos,
            prepend_newline = newline
         }
         self.comment_ids[idf] = true
         self.comment_ids[idl] = true
         table.insert(comments, li)
      end
   end
   if lfi.comments then
      for _, c in ipairs(lfi.comments) do
         add_comment(c, 'first')
      end
   end
   if lla.comments then
      for _, c in ipairs(lla.comments) do
         add_comment(c, 'last')
      end
   end

   return comments
end
]]

local fullclock = [[
--- @diagnostic disable: duplicate-set-field,lowercase-global
width, height = G.getDimensions()
midx = width / 2
midy = height / 2

local m = 60
local h = m * m
midnight = 24 * m * h

local H, M, S, t
function setTime()
  H = os.date("%H")
  M = os.date("%M")
  S = os.date("%S")
  t = S + m * M + h * H
end

setTime()
s = 0

math.randomseed(os.time())
color = math.random(7)
bg_color = math.random(7)
font = G.newFont(72)

local function pad(i)
  return string.format("%02d", i)
end

function getTimestamp()
  local hours_f = pad(math.floor(s / h))
  local minutes_f = pad(math.fmod(math.floor(s / m), m))

  local hours = s >= h and hours_f or '00'
  local minutes = s >= m and minutes_f or '00'
  local seconds = pad(math.floor(math.fmod(s, m)))
  return string.format('%s:%s:%s', hours, minutes, seconds)
end

function love.draw()
  G.setColor(Color[color + Color.bright])
  G.setBackgroundColor(Color[bg_color])
  G.setFont(font)

  local text = getTimestamp()
  local l = string.len(text)
  local off_x = l * font:getWidth(' ')
  local off_y = font:getHeight() / 2
  G.print(text, midx - off_x, midy - off_y, 0, 1, 1)
end

function love.update(dt)
  t = t + dt
  s = math.floor(t)
  if s > midnight then s = 0 end
end

function cycle(c)
  if c > 7 then return 1 end
  return c + 1
end

local function shift()
  return love.keyboard.isDown("lshift", "rshift")
end
local function color_cycle(k)
  if k == "space" then
    if shift() then
      bg_color = cycle(bg_color)
    else
      color = cycle(color)
    end
  end
end
function love.keyreleased(k)
  color_cycle(k)
  if k == "r" and shift() then
    setTime()
  end
  if k == "s" then
    stop("STOP THE CLOCKS!")
  end
end
]]

local full = {
  prep(sierpinski, {
    { line = 1,  name = 'sierpinski', type = 'function', },
    { line = 2,  name = 'lines',      type = 'global', },
    { line = 4,  name = 'sp',         type = 'global', },
    { line = 5,  name = 'tmp',        type = 'global', },
    { line = 10, name = 'lines',      type = 'global', },
  }),
  prep(clock, {
    { line = 1,  name = 'love.draw',        type = 'function', },
    { line = 5,  name = 'love.update',      type = 'function', },
    { line = 6,  name = 't',                type = 'global', },
    { line = 7,  name = 's',                type = 'global', },
    { line = 8,  name = 's',                type = 'global', },
    { line = 11, name = 'cycle',            type = 'function', },
    { line = 16, name = 'love.keyreleased', type = 'function', },
    { line = 19, name = 'bg_color',         type = 'global', },
    { line = 21, name = 'color',            type = 'global', },
  }),
  prep(meta, {
    { line = 3,  name = 'M:extract_comments', type = 'method', },
    { line = 4,  name = 'lfi',                type = 'local', },
    { line = 5,  name = 'lla',                type = 'local', },
    { line = 6,  name = 'comments',           type = 'local', },
    { line = 10, name = 'add_comment',        type = 'function', },
    { line = 11, name = 'idf',                type = 'local', },
    { line = 12, name = 'idl',                type = 'local', },
    { line = 13, name = 'present',            type = 'local', },
    { line = 15, name = 'comment_text',       type = 'local', },
    { line = 16, name = 'len',                type = 'local', },
    { line = 17, name = 'n_l',                type = 'local', },
    { line = 18, name = 'cfi',                type = 'local', },
    { line = 19, name = 'cla',                type = 'local', },
    { line = 20, name = 'cfirst',             type = 'local', },
    { line = 20, name = 'cfirst.l',           type = 'field', },
    { line = 20, name = 'cfirst.c',           type = 'field', },
    { line = 21, name = 'clast',              type = 'local', },
    { line = 21, name = 'clast.l',            type = 'field', },
    { line = 21, name = 'clast.c',            type = 'field', },
    { line = 22, name = 'off',                type = 'local', },
    { line = 23, name = 'd',                  type = 'local', },
    { line = 24, name = 'l_d',                type = 'local', },
    { line = 25, name = 'newline',            type = 'local', },
    { line = 26, name = 'li',                 type = 'local', },
    { line = 27, name = 'li.idf',             type = 'field', },
    { line = 28, name = 'li.idl',             type = 'field', },
    { line = 29, name = 'li.first',           type = 'field', },
    { line = 30, name = 'li.last',            type = 'field', },
    { line = 31, name = 'li.text',            type = 'field', },
    { line = 32, name = 'li.multiline',       type = 'field', },
    { line = 33, name = 'li.position',        type = 'field', },
    { line = 34, name = 'li.prepend_newline', type = 'field', },
  }),
  prep(fullclock, {
    { line = 2,  name = 'width',            type = 'global', },
    { line = 2,  name = 'height',           type = 'global', },
    { line = 3,  name = 'midx',             type = 'global', },
    { line = 4,  name = 'midy',             type = 'global', },
    { line = 6,  name = 'm',                type = 'local', },
    { line = 7,  name = 'h',                type = 'local', },
    { line = 8,  name = 'midnight',         type = 'global', },
    { line = 11, name = 'H',                type = 'local', },
    { line = 11, name = 'M',                type = 'local', },
    { line = 11, name = 'S',                type = 'local', },
    { line = 11, name = 't',                type = 'local', },
    { line = 12, name = 'setTime',          type = 'function', },
    { line = 13, name = 'H',                type = 'global', },
    { line = 14, name = 'M',                type = 'global', },
    { line = 15, name = 'S',                type = 'global', },
    { line = 16, name = 't',                type = 'global', },
    { line = 20, name = 's',                type = 'global', },
    { line = 23, name = 'color',            type = 'global', },
    { line = 24, name = 'bg_color',         type = 'global', },
    { line = 25, name = 'font',             type = 'global', },
    { line = 27, name = 'pad',              type = 'function', },
    { line = 31, name = 'getTimestamp',     type = 'function', },
    { line = 32, name = 'hours_f',          type = 'local', },
    { line = 33, name = 'minutes_f',        type = 'local', },
    { line = 35, name = 'hours',            type = 'local', },
    { line = 36, name = 'minutes',          type = 'local', },
    { line = 37, name = 'seconds',          type = 'local', },
    { line = 41, name = 'love.draw',        type = 'function', },
    { line = 46, name = 'text',             type = 'local', },
    { line = 47, name = 'l',                type = 'local', },
    { line = 48, name = 'off_x',            type = 'local', },
    { line = 49, name = 'off_y',            type = 'local', },
    { line = 53, name = 'love.update',      type = 'function', },
    { line = 54, name = 't',                type = 'global', },
    { line = 55, name = 's',                type = 'global', },
    { line = 56, name = 's',                type = 'global', },
    { line = 59, name = 'cycle',            type = 'function', },
    { line = 64, name = 'shift',            type = 'function', },
    { line = 67, name = 'color_cycle',      type = 'function', },
    { line = 70, name = 'bg_color',         type = 'global', },
    { line = 72, name = 'color',            type = 'global', },
    { line = 76, name = 'love.keyreleased', type = 'function', },
  }),
}

return {
  { 'simple', simple },
  { 'full',   full },
}
