# guess

<!-- authored By LLM; human-approved NOT YET -->

> REMARK: can we avoid using ambiguous word 'overlay' which is just a synonym for project's input widget? unifying terminology would be less confusing to reader

**Number guessing game** with per-character input validation.

## Architecture

Single-file. No `love.update`/`love.draw` override — output goes to the terminal via `print()`; input is driven entirely by the `compy.input.*` callback API **(supported since 1.0.0-rc20260712)**.

## Input pattern

```lua
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

init()

compy.input.show{
  prompt = "Guess a number:",
  validator = LineValidators({ is_natural }),
  on_text_entered = function(lines) check(tonumber(lines[1])) end,
}
```

This is the continuous-session idiom (see [Compy Input API](../../../input_api.md)): `compy.input.show{}` activates the overlay once; `on_text_entered` receives submitted line strings while the session is active; `after_submit` clears the next draft. `LineValidators({ is_natural })` adapts the existing line rule to the overlay validator.

The old `r = user_input()` / `validated_input(...)` polling pattern is **(deprecated, removed in 1.0.0-rc20260712)**.

## Validator

`is_natural` validates that the input is a string of digit characters using `string.forall(digits, Char.is_digit)`. Returns an `Error` object with a column position on failure — the framework uses this to highlight the offending character in the input widget.


## Files

`src/examples/guess/main.lua`
