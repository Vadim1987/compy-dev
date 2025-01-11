
function move_forward(d)
  ty = ty - (d or incr)
end
function move_back(d)
  ty = ty + (d or incr)
end
function move_left(d)
  tx = tx - (d or (2 * incr))
end
function move_right(d)
  tx = tx + (d or (2 * incr))
end

function pause()
  pause("user pause")
end

actions = {
  forward = move_forward,
  fd = move_forward,
  back = move_back,
  b = move_back,
  left = move_left,
  l = move_left,
  right = move_right,
  r = move_right,
  pause = pause
}
