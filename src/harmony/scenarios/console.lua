local h = love.harmony.utils or error()

local function console()
  scenario('1', function(wait)
    wait(.1)
    h.love_text('print("1")')
    wait(.1)
    h.love_key('return')
    wait(.1)

    hm_done()
  end)

  scenario('2', function(wait)
    wait(.1)
    h.love_text('print("2")')
    wait(.1)
    h.love_key('return')
    wait(.1)

    hm_done()
  end)
end

console()
