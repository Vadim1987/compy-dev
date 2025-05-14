examples = {
  {
    code = "return math.random() < 0.1",
    legend = "for every dot return 0 or 1 \nto change the visibility"
  },
  {
    code = "return math.random()",
    legend = "use a float between 0 and 1 \nto define the size"
  },
  {
    code = "return math.sin(t)",
    legend = "parameter `t` is \nthe time in seconds"
  },
  {
    code = "return i / 256",
    legend = "param `i` is the index \nof the dot (0..255)"
  },
  { -- 5
    code = "return x / 16",
    legend = "`x` is the column index\n from 0 to 15"
  },
  {
    code = "return y / 16",
    legend = "`y` is the row\n also from 0 to 15"
  },
  {
    code = "return y - 7.5",
    legend = "positive numbers are white,\nnegatives are red"
  },
  {
    code = "return y - t",
    legend = "use the time\nto animate values"
  },
  {
    code = "return y - 4 * t",
    legend = "multiply the time\nto change the speed"
  },
  { -- 10
    code = "return ({1, 0, -1})[i % 3 + 1]",
    legend = "create patterns using \ndifferent color"
  },
  {
    code = "return sin(t - sqrt((x - 7.5)^2 + (y-6)^2) )",
    legend = "skip `math.` to use methods \nand props like `sin` or `pi`"
  },
  {
    -- code = "return math.sin(y/8 + t)",
    code = "return sin(y/8 + t)",
    legend = "more examples ..."
  },
  {

    code = "return y - x",
    legend = "simple triangle"
  },
  {
    code = "return b2n( (y > x) and (14 - x < y) )",
    legend = "quarter triangle"
  },
  {
    code = "return i % 4 - y % 4",
    legend = "pattern"
  },
  {
    code = "return b2n(n2b(math.fmod(x, 4)) and n2b(math.fmod(y, 4)))",
    legend = "grid"
  },
  {
    code = "return b2n( x>3 and y>3 and x<12 and y<12 )",
    legend = "square"
  },
  {
    code = "return -1 * b2n( x>t and y>t and x<15-t and y<15-t )",
    legend = "animated square"
  },
  {
    code = "return (y-6) * (x-6)",
    legend = "mondrian squares"
  },
  {
    code = "return floor(y - 4 * t) * floor(x - 2 - t)",
    legend = "moving cross"
  },
  {
    code = "return bit.band(4 * t, i, x, y)",
    legend = "sierpinski"
  },
  {
    code = "return y == 8 and bit.band(t * 10, bit.lshift(1, x)) or 0",
    legend = "binary clock"
  },
  {
    code = "return random() * 2 - 1",
    legend = "random noise"
  },
  {
    code = "return sin(i ^ 2)",
    legend = "static smooth noise"
  },
  {
    code = "return cos(t + i + x * y)",
    legend = "animated smooth noise"
  },
  {
    code = "return sin(x/2) - sin(x-t) - y+6",
    legend = "waves"
  },
  {
    code = "return (x-8) * (y-8) - sin(t) * 64",
    legend = "bloop bloop bloop"
  },
  {
    code = "return -.4 / (hypot(x - t%10, y - t%8) - t%2 * 9)",
    legend = "fireworks"
  },
  {
    -- code = "return sin(t - sqrt(x*x+y*y))",
    code = "return sin(t - hypot(x, y))",
    legend = "ripples"
  },
  { -- [5463,2194,2386][y+t*9&7]&1<<x-1"
    code = 'return bit.band(' ..
        ' ({5463,2194,2386})[ bit.band(y+t*9, 7) ] or 0, ' ..
        'bit.lshift(1, x - 1) )',
    legend = "scrolling TIXY"
  },


}
