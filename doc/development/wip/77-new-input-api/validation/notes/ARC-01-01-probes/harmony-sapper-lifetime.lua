-- ARC-01-01 PROBE — NOT A KEEPER. Temporary scenario: does a
-- pen-and-paper project (sapper) pass through run_project and
-- stay live in 'project_open', and is stop_project_run the only
-- place a per-run widget would be destroyed? Delete after use.

local h = love.harmony.utils or error()

local function log(tag)
  print(string.format(
    'ARC01| %-22s state=%-13s widget=%s handle=%s',
    tag, tostring(love.state.app_state),
    tostring(love.state.user_input_controller),
    tostring(love.state.user_input)))
end

local function patch()
  local run = ConsoleController.run_project
  ConsoleController.run_project = function(self, name)
    log('>> run_project ' .. tostring(name))
    local r = run(self, name)
    log('<< run_project')
    return r
  end
  local stop = ConsoleController.stop_project_run
  ConsoleController.stop_project_run = function(self)
    log('>> stop_project_run')
    local r = stop(self)
    log('<< stop_project_run')
    return r
  end
  local close = ConsoleController.close_project
  ConsoleController.close_project = function(self, ...)
    log('>> close_project')
    return close(self, ...)
  end
end

-- The derived single/double-click channel re-samples
-- love.mouse.getPosition() when the window closes and discards
-- the click if it drifted from the press. Harmony's synthetic
-- events carry coordinates the real pointer does not have, so
-- the pointer has to follow them or every derived click is
-- dropped as drift (controller.lua, no_drift).
local px, py = 0, 0
love.mouse.getPosition = function() return px, py end

local function click(x, y)
  px, py = x, y
  h.love_event('mousepressed', x, y, 1)
  h.love_event('mousereleased', x, y, 1)
end

local function arc01probe()
  scenario('sapper_lifetime', function(wait)
    patch()
    wait(.3)
    log('boot')
    h.love_text('run("sapper")')
    wait(.3)
    h.love_key('return')
    wait(1.5)
    log('settled after run')
    h.screenshot('01-settled')
    -- Live in project_open? A double click unlocks a cell.
    click(300, 300)
    wait(.15)
    click(300, 300)
    wait(.8)
    log('after doubleclick')
    h.screenshot('02-after-doubleclick')
    -- And a second one somewhere else, to see the board move.
    click(400, 300)
    wait(.15)
    click(400, 300)
    wait(.8)
    log('after 2nd doubleclick')
    h.screenshot('03-after-2nd-doubleclick')
    -- Now really stop it.
    h.love_key('C-S-q')
    wait(1.0)
    log('after C-S-q')
    h.screenshot('04-after-quit')
    wait(.3)
    hm_done()
  end)
end

arc01probe()
