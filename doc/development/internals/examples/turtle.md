# turtle

<!-- authored By LLM; human-approved NOT YET -->

**Turtle graphics interpreter** driven by typed commands and keyboard input.

## Architecture

Multi-file: `main.lua` (main loop, input wiring), `action.lua` (command table), `drawing.lua` (rendering: background, turtle icon, trail, debug overlay).

Overrides `love.draw`, `love.update`, `love.keypressed`, `love.keyreleased`.

## Input pattern

Dual input: typed commands via `compy.input.*` **(supported since 1.0.0-rc20260712)**, and direct keyboard actions. Unlike the other examples, turtle does **not** use the continuous-session `after_submit` idiom — there is no overlay shown at load; `i` opens it on demand, one shot at a time:

```lua
function love.keyreleased(key)
  if key == "i" then
    compy.input.show{
      prompt = "TURTLE",
      on_text_entered = function(lines)
        eval(lines[1])
      end,
    }
  end

  if love.keyboard.isDown("lctrl", "rctrl") then
    if key == "escape" then
      love.event.quit()
    end
  end
end
```

`eval(input)` looks up `actions[input]` and calls the function if found. Actions are defined in `action.lua` as a table mapping strings to closures. Typed input is thus a command dispatcher; the submit callback passes it the first submitted line.

`love.keyreleased`: the `i` key opens the input overlay with a fresh `compy.input.show{}` call each time (there is no `after_submit` re-arm, so the overlay does not automatically reopen after a submit — pressing `i` again is required). `shift+r` resets turtle position.

See [Compy Input API](../../../input_api.md) for the general usage pattern. The old `r = user_input()` / `input_text(...)` polling API is **(deprecated, removed in 1.0.0-rc20260712)**.

## Drawing

`drawing.lua` contains `drawBackground()` (clears to dark), `drawTurtle(tx, ty)` (draws a triangle pointing in the turtle's current direction), `drawHelp()`, and `drawDebuginfo()`. The turtle trail is drawn to the virtual canvas via `gfx.*` calls in the action functions — so trails persist across frames without a redraw loop.

## Points of attention

- Each press of `i` calls `compy.input.show{}` fresh — there is no `after_submit` re-arm, so the overlay does not reappear automatically after a command is submitted; the player must press `i` again for the next typed command.
- `debug_color` is set in `love.update` based on turtle position — this modifies a global used by `drawDebuginfo`. The debug overlay is toggled by `space`.

## Files

`src/examples/turtle/` — main.lua, action.lua, drawing.lua
