# repl

<!-- authored By LLM; human-approved NOT YET -->

**Minimal REPL.** Accepts text input from the user and echoes it to the terminal.

For the full project-author usage guide, see [Compy Input API](../../../input_api.md).

## Code

```lua
-- Continuous-session idiom (M8-01): consume the line in
-- on_text_entered, then clear the next draft from after_submit.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  on_text_entered = function(lines) print(string.unlines(lines)) end,
}
```

## Purpose

The smallest possible demonstration of the `compy.input.show`/`after_submit` continuous-session idiom **(supported since 1.0.0-rc20260712)**. No game logic, no drawing, no state. Useful as a reference skeleton for any project that needs live text input.

## Notes

`compy.input.show{}` is called with no config — no prompt, no initial text. The overlay appears with an empty input field. `on_text_entered` receives submitted line strings while the session is active; `after_submit` is a direct callback assignment that clears the next draft.

The old `user_input()`/`input_text()` poll-a-reftable pattern (`r = user_input()`, `r:is_empty()`, `r()` each `love.update()` tick) is **(deprecated, removed in 1.0.0-rc20260712)**.

## Files

`src/examples/repl/main.lua`
