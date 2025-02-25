### Sinewave

This project demonstrates the basics of drawing on the screen.
The end result is a display of coordinate system axes and a sine wave.

#### Drawing

First, we establish the screen coordinates. It starts at the top left corner, which is (0, 0), and we can programmatically find out where the other ends are with the `getWidth()` and `getHeight()` functions. Unlike a usual coordinate system would look on paper (and what our end result will use), the y axis is flipped, it's value grows from top to bottom.