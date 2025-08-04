function moveForward(d)
  ty = ty - (d or incr)
end

function moveBack(d)
  ty = ty + (d or incr)
end

function moveLeft(d)
  tx = tx - (d or (2 * incr))
end

function moveRight(d)
  tx = tx + (d or (2 * incr))
end

function pause(msg)
  pause(msg or "user paused the game")
end

actions = {
  forward = moveForward,
  fd = moveForward,
  back = moveBack,
  b = moveBack,
  left = moveLeft,
  l = moveLeft,
  right = moveRight,
  r = moveRight,
  pause = pause
}
