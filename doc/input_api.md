# Compy Input API

This guide is for projects running inside Compy. `compy.input` is the
project-facing input surface: it opens one shared text overlay and delivers
submissions through callbacks. There is no polling API or compatibility shim.

## Quick start

```lua
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  prompt = "say something:",
  on_text_entered = function(lines)
    print(string.unlines(lines))
  end,
}
```

The overlay stays open after a successful submit. `after_submit` clears the
next draft; it is assigned on `callbacks`, not passed to `show`.

## `show(config)`

`compy.input.show(config)` activates the overlay. All keys are optional.

| Key | Meaning |
|---|---|
| `prompt` | Label shown next to the field. |
| `text` | Initial content: a string or list of line strings. |
| `cursor` | Initial `{line, col}` after `text` is applied. |
| `highlighter` | `function(lines) -> coloring`; changes display only. |
| `validator` | `function(lines) -> true` or `false, Error[]`; gates submit. |
| `on_text_entered` | `function(lines)` called after successful validation. |
| `on_limit_reached` | Called when cursor movement reaches a boundary. |
| `force` | `show` only: while active, replace `text` instead of warning. |

`show` on an active overlay warns and does nothing unless `force = true`.

A key outside this table **raises**. The config table is closed, so an
unrecognised key can only be a mistake, and a mistake you can see beats one
that leaves the overlay quietly not doing what you asked. This includes
lifecycle callbacks such as `after_submit`: assign those to
`compy.input.callbacks` instead.

```lua
-- Wrong: raises, naming the key and where it belongs.
compy.input.show{ after_submit = function() end }

-- Right: a direct callback assignment.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end
```

## Submit lifecycle

Enter submits; Shift+Enter inserts a newline. On a non-empty submission the
order is:

1. `before_submit(keys_pressed)`, if assigned.
2. `validator(lines)`, if assigned.
3. `on_text_entered(lines)`, if assigned.
4. `after_submit(lines)`, if assigned.

`lines` is always a list of line strings. A rejecting validator returns
`false, errors`, where `errors` is a list of positioned `Error` values; the
overlay displays the error and steps 3–4 do not run. A highlighter has no
submit or validation authority: it only controls how the current text looks.

The overlay remains shown by default. To close it after a submit, make that
choice explicit:

```lua
compy.input.callbacks.after_submit = function()
  compy.input.hide()
end
```

Escape first runs `before_cancel(keys_pressed)`. A truthy return vetoes the
cancel. Otherwise it clears the field and calls `after_cancel()`; it also
stays shown unless that callback hides it.

## Validation and highlighting

Projects can use the supplied helpers or provide functions with the same
shapes. The helpers are globals in the project environment:

| Helper | Use |
|---|---|
| `LuaHighlighter(lines)` | Lua syntax coloring for the overlay. |
| `LuaSyntaxValidator(lines)` | Accepts valid Lua or returns positioned parse errors. |
| `LineValidators(filters)` | Adapts one filter or a list of line filters into a validator. |

A line filter receives one string and returns `true`, or `false, error`.
`LineValidators` applies every filter to every submitted line and turns
rejections into positioned `Error` values.

```lua
local natural = function(line)
  if line:match("^%d+$") then return true end
  return false, Error("Expected a natural number", 1)
end

compy.input.show{
  prompt = "Guess a number:",
  validator = LineValidators(natural),
  on_text_entered = function(lines)
    check(tonumber(lines[1]))
  end,
}
```

For code entry, choose the display and submit policies independently:

```lua
compy.input.show{
  prompt = "Lua:",
  text = string.lines(body),
  highlighter = LuaHighlighter,
  validator = LuaSyntaxValidator,
  on_text_entered = function(lines)
    body = string.unlines(lines)
  end,
}
```

## Live changes

`compy.input.configure(config)` updates an active overlay. It accepts the
same documented configuration keys except `force`, and raises on anything
else by the same rule as `show`; active `text` and `cursor`
are not changed by `configure`, so use `set_text`, `set_cursor`, or `clear`.
When hidden, `configure` retains `prompt`, `text`, and `cursor` for one later
`show`.

`compy.input.set_text(text [, keep_cursor])` replaces content. `clear()`
empties it. `get_cursor()` returns `line, col`; `set_cursor(line, col)` moves
it. Mutating calls warn and do nothing while the overlay is hidden.

## Event hooks and shortcuts

`compy.input.shortcuts.keypressed[combo]` registers a combo-specific
function. `shortcuts.keyreleased` and `shortcuts.textinput` work the same
way. A shortcut runs before the overlay and can consume the event.

`compy.input.hooks.keypressed`, `.keyreleased`, and `.textinput` are one
fallback function per event. At activation, an existing project `love.*`
handler seeds the matching hook when no explicit hook was supplied.

## Callback assignments

`compy.input.callbacks` is writable. These entries may also be supplied in
`show` or `configure` and persist until replaced: `on_text_entered`,
`on_limit_reached`, `validator`, and `highlighter`.

The lifecycle entries are direct assignments only: `before_submit`,
`after_submit`, `before_cancel`, and `after_cancel`.

## Migration

The retired polling globals have no replacement compatibility layer. Move
their work into a callback:

| Old shape | Replacement |
|---|---|
| `user_input()` plus a per-frame poll | `on_text_entered = function(lines) ... end` |
| `input_text(prompt, text)` | `show{ prompt = prompt, text = text, on_text_entered = fn }` |
| `input_code(prompt, text)` | `show{ prompt = prompt, text = text, highlighter = LuaHighlighter, validator = LuaSyntaxValidator, on_text_entered = fn }` |
| `validated_input(filters, prompt)` | `show{ prompt = prompt, validator = LineValidators(filters), on_text_entered = fn }` |
| `write_to_input(text)` | `compy.input.set_text(text)` |
| `eval = InputEvalLua` | `highlighter = LuaHighlighter, validator = LuaSyntaxValidator` |
| `eval = ValidatedTextEval(filters)` | `validator = LineValidators(filters)` |
| `result = ...` | Consume `lines` in `on_text_entered`; no result object exists. |

The old evaluator globals (`InputEvalText`, `InputEvalLua`,
`ValidatedTextEval`, and `LuaEditorEval`) are not project API. Do not place
them in `show` or `configure` tables.

## See also

- [User Input — Implementation Overview](development/internals/user_input.md)
