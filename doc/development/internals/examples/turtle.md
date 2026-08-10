# turtle

<!-- authored By LLM; human-approved NOT YET -->

**Turtle graphics interpreter** driven by typed commands and keyboard input.

## Architecture

Multi-file: `main.lua` (main loop, input wiring), `action.lua` (command table), `drawing.lua` (rendering: background, turtle icon, trail, debug overlay).

Overrides `love.draw`, `love.update`, `love.keypressed`, `love.keyreleased`.

## Input pattern

Dual input: typed commands via `compy.input.*` **(supported since 1.0.0-rc20260712)**, and direct keyboard actions. Turtle is the **one-shot** shape rather than the continuous session the other examples use: nothing is shown at load, `i` opens the prompt, and `after_submit` closes it again — so each command gets a fresh, empty field.

> REMARK: remove 'owner ruling' provisional reference, just say its done on purpsoe

Turtle also keeps its keyboard on `love.keypressed`/`love.keyreleased` **on purpose** (owner ruling, 2026-07-31). The framework captures a project's own `love.*` keyboard functions and runs them as hooks, and this is the example that demonstrates that path — everything below would behave identically written as `compy.input.hooks.keyreleased` or, for `i` and `ctrl+escape`, as `compy.input.shortcuts.keyreleased` combos. Keeping one example on the captured path is what makes the path visible at all.

```lua
compy.input.callbacks.after_submit = function()
  compy.input.hide()
end

function love.keyreleased(key)
  -- Open only when it is closed, and consume `i` only then: the hook
  -- runs BEFORE the overlay, so without the guard every `i` typed into
  -- the prompt would re-trigger show (which warns and no-ops).
  if key == "i" and not compy.input.is_shown() then
    compy.input.show{
      prompt = "TURTLE",
      on_text_entered = function(lines)
        eval(lines[1])
      end,
    }
    return true
  end

  if Key.ctrl() then
    if key == "escape" then
      love.event.quit()
    end
  end
end
```

`eval(input)` looks up `actions[input]` and calls the function if found. Actions are defined in `action.lua` as a table mapping strings to closures. Typed input is thus a command dispatcher; the submit callback passes it the first submitted line.

"Re-arm" was the pre-feature vocabulary: because submit used to close the overlay, a project that wanted another line had to re-open it. That is reversed now — the overlay stays open after submit (Decision 6), so a *one-shot* prompt is the shape that needs the extra line, and turtle's `after_submit` is it. And yes: the missing close is exactly why typed commands used to pile up in the field (report A2, "input is not cleared after Enter") — a one-shot prompt that never closed kept the previous command.

`love.keyreleased`: `i` opens the prompt when it is not already open, and consumes the key only in that case; while the prompt is up, `i` belongs to it. It also quits on `ctrl+escape`, asking `Key` for the modifier. `shift+r`, which resets the turtle position, is on `love.keypressed` and asks `Key` the same way.

That guard is about *later* `i`s. The **opening** `i` is a separate problem: LÖVE delivers a `keypressed` and a `textinput` for it in no guaranteed order, so the trigger's own echo can land in the field it just opened. `arm_echo_guard` handles it — a one-shot `compy.input.shortcuts.textinput["i"]` that consumes the echo and unregisters itself, re-armed by `after_submit` alongside the `hide()` ([Compy Input API](../../../input_api.md), "Opening the overlay from a key"). Two guards, one line apart, for two different problems.

See [Compy Input API](../../../input_api.md) for the general usage pattern. The old `r = user_input()` / `input_text(...)` polling API is **(deprecated, removed in 1.0.0-rc20260712)**.

## Drawing

`drawing.lua` contains `drawBackground()` (clears to dark), `drawTurtle(tx, ty)` (draws a triangle pointing in the turtle's current direction), `drawHelp()`, and `drawDebuginfo()`. The turtle trail is drawn to the virtual canvas via `gfx.*` calls in the action functions — so trails persist across frames without a redraw loop.

## Points of attention

- Each command is one prompt: `i` opens it, submit closes it (`after_submit` → `hide` → re-arm), and the player presses `i` again for the next command. The guard on `compy.input.is_shown()` is what keeps the `i` inside a typed word from re-triggering `show`; the one-shot textinput shortcut is what keeps the opening `i` out of the field. Closing without the re-arm would let the next open take the echo.
- `debug_color` is set in `love.update` based on turtle position — this modifies a global used by `drawDebuginfo`. The debug overlay is toggled by `space`.

## Files

`src/examples/turtle/` — main.lua, action.lua, drawing.lua
