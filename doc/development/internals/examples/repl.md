# repl

<!-- authored By LLM; human-approved NOT YET -->

**Minimal REPL.** Accepts text input from the user and echoes it to the terminal.

For the full project-author usage guide, see [Compy Input API](../../../input_api.md).

## Code

```lua
-- Continuous-session idiom (M8-01): consume the line in
-- on_text_entered, re-show (bare) from after_submit.
compy.input.after_submit = function()
  compy.input.show{}
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
```

## Purpose

The smallest possible demonstration of the `compy.input.show`/`after_submit` continuous-session idiom **(supported since 1.0.0-rc20260712)**. No game logic, no drawing, no state. Useful as a reference skeleton for any project that needs live text input.

## Notes

`compy.input.show{}` is called with no config — no prompt, no initial text. The overlay appears with an empty input field. `on_text_entered` fires with the submitted text while the session is still active; `after_submit` is a **field-write** (not a `show{}` key) that fires after the widget deactivates, and re-arms the overlay for the next line by calling `compy.input.show{}` again.

The old `user_input()`/`input_text()` poll-a-reftable pattern (`r = user_input()`, `r:is_empty()`, `r()` each `love.update()` tick) is **(deprecated, removed in 1.0.0-rc20260712)**.

## Files

`src/examples/repl/main.lua`
