# repl

<!-- authored By LLM; human-approved NOT YET -->

**Minimal input loop.** Accepts a line from the user and **prints it straight back** to the terminal.

Despite the name, it does **not** evaluate what you type: `on_text_entered` receives the submitted
line strings and passes them to `print`, and the overlay widget is provisioned with the plain-text
evaluator (`InputEvalText`, `main.lua:370`), which has no parser and executes nothing. Type `x = 2 + 3`
and you get the characters `x = 2 + 3` back, not a binding. Making it a real read-**eval**-print loop
is an open question for the examples, not a documentation gap.

For the full project-author usage guide, see [Compy Input API](../../../input_api.md).

> REMARK: why two different paths if both actions can be called in a single 'on_text_entered'? if we want to show the different ways, we may explain its for demo purposes (actually on_text_entered and after_submit are obviously duplicates which may be a small architectural smell; consider removing 'after_submit' from callbacks? or allow installing all callbacks via show? or even avoiding setting callbacks via show and only use callbacks table?). ON THE OTHER HAND (and its good argument to keep both, same pardigm in `valid`) -- one callback could be used for mechanical widget cleanup, another one to meaningfullly process the input. Developer is not obliged to use both -- but in some circumstances it may be convenient to be able to do so

## Code

```lua
-- Continuous-session idiom (doc/input_api.md, "Submit
-- lifecycle"): consume the line in on_text_entered;
-- the widget stays open by default now, so after_submit just clears
-- the field for the next line instead of re-showing.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  on_text_entered = function(lines) print(string.unlines(lines)) end,
}
```

## Purpose

The smallest possible demonstration of the `compy.input.show`/`after_submit` continuous-session idiom **(supported since 1.0.0-rc20260712)**. No game logic, no drawing, no state, no evaluation. Useful as a reference skeleton for any project that needs live text input.

## Notes

> REMARK: its literally called *with* config in the example above -- and config installs callback, which raises a question of API shape (why not have separate callbacks interface as the only way to set callbacks)

`compy.input.show{}` is called with no config — no prompt, no initial text. The overlay appears with an empty input field. `on_text_entered` receives submitted line strings while the session is active; `after_submit` is a direct callback assignment that clears the next draft.

The old `user_input()`/`input_text()` poll-a-reftable pattern (`r = user_input()`, `r:is_empty()`, `r()` each `love.update()` tick) is **(deprecated, removed in 1.0.0-rc20260712)**.

## Files

`src/examples/repl/main.lua`
