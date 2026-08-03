---
description: Project-author guide to compy.input — the overlay, its config table, the submit lifecycle, hooks and shortcuts
status: active
audience: project author
authored: llm
reviewed: none
---

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

`compy.input.is_shown()` tells you whether the overlay is up. Use it when a
project must not act twice — opening the prompt from a key that is also
typed *into* the prompt, for example:

```lua
compy.input.hooks.keyreleased = function(key)
  if key == 'i' and not compy.input.is_shown() then
    compy.input.show{ prompt = 'command' }
    return true -- consumed; while it is open, 'i' belongs to the overlay
  end
end
```

Do not read `love.state` for this: a project runs in a sandboxed copy of
`love`, so that field is always `nil` from inside a project.

That guard stops *later* presses of `i` from re-opening the prompt. It does
not stop the `i` that opened it from being typed into it — see "Opening the
overlay from a key" below.

`compy.input.set_text(text [, keep_cursor])` replaces content. `clear()`
empties it. `get_cursor()` returns `line, col`; `set_cursor(line, col)` moves
it. Mutating calls warn and do nothing while the overlay is hidden.

`col` is a **caret position between characters**, not a character index: it
ranges over `1 .. #line + 1`, where `1` is before the first character and
`#line + 1` is at the end of the line. So on `"lemon"`, `set_cursor(1, 3)`
puts the caret between `e` and `m` — typing inserts there (`"leXmon"`) and
Backspace deletes the character before it (`"lmon"`). Out-of-range values
clamp to that range rather than failing.

## Event hooks and shortcuts

`compy.input.shortcuts.keypressed[combo]` registers a combo-specific
function. `shortcuts.keyreleased` and `shortcuts.textinput` work the same
way. A shortcut runs before the overlay and can consume the event.

A combo is its modifiers plus **one** trigger — `'ctrl+alt+s'`. Modifiers come
first in a fixed order (ctrl, alt, shift, gui), left and right fold together,
and the whole string is normalised when you assign it, so `'Ctrl+Alt+S'` and
`'ctrl+alt+s'` are the same binding. A combo naming two triggers or none
raises.

The trigger may be `*`, which binds the whole modifier class: `'alt+*'` is
every Alt chord, and the handler receives the actual key as its first
argument. An exact binding wins — with both `'alt+*'` and `'alt+p'`
registered, Alt+P runs the exact one. A class is its modifier set exactly, so
`'alt+*'` does not catch Ctrl+Alt+H, and it never fires for the modifier's own
press.

```lua
compy.input.shortcuts.keypressed['alt+*'] = function() return true end
compy.input.shortcuts.keypressed['alt+p'] = function()
  pause()
  return true
end
```

Combos of ordinary keys — "A and B held together" — are deliberately not
expressible. Every binding would otherwise become conditional on nothing else
being held, so holding a movement key would silently break unrelated
shortcuts. For that, and for anything else beyond exact-or-class matching, use
a hook: it receives the held-key table as its second argument on all three
channels, and `compy.input.keys_pressed` is readable anywhere.

`compy.input.hooks.keypressed`, `.keyreleased`, and `.textinput` are one
fallback function per event. At activation, an existing project `love.*`
handler seeds the matching hook when no explicit hook was supplied.

## Opening the overlay from a key

LÖVE delivers a `keypressed` **and** a `textinput` for one physical key, and
does not promise their order. So a prompt opened from `i` can come up with an
`i` already in the field — the trigger's own echo, arriving on the other
channel either side of the open. The `is_shown()` guard does not help: it is
about the *next* press, not this one.

Guard the trigger with a one-shot shortcut on the `textinput` channel.
Shortcuts run before the overlay, so it swallows the echo whichever side of
the open it lands on, and it unregisters itself so the character is typable
as content afterwards:

```lua
local function arm_echo_guard()
  compy.input.shortcuts.textinput['i'] = function()
    compy.input.shortcuts.textinput['i'] = nil
    return true -- the echo is consumed, not typed
  end
end
arm_echo_guard()

compy.input.callbacks.after_submit = function()
  compy.input.hide()
  arm_echo_guard() -- the next open needs a fresh one-shot
end
```

Re-arm wherever you close the overlay: one that is closed without re-arming
takes the echo on its next open. Only your own `hide()` calls need this —
Escape *clears* the field without closing, so the spent one-shot is still
correct.

Use a **bare** key as the trigger. A modified combo cannot be guarded this
way: the two channels do not share a combo string for it — `shift+i` on
`keypressed` against `shift+I` on `textinput` — and the upper-case form
cannot be registered.

## Held keys

`compy.input.keys_pressed` is a read-only table of the keys held right now,
keyed by LÖVE key name: `compy.input.keys_pressed['lshift']` is `true` while
either shift is down and `nil` otherwise. Reading it is allowed anywhere,
including from `love.draw` — which is the point, since a project that *draws*
held state has no event argument to consult.

```lua
function love.draw()
  local shifted = compy.input.keys_pressed['lshift']
      or compy.input.keys_pressed['rshift']
  draw_keycaps(shifted)
end
```

Writing to it raises: the project observes the held set, it does not own it.
The same table arrives as the second argument of every shortcut, hook and
widget call, so a handler can use either.

Left and right modifiers are **not** folded here — this is the raw held set,
so test `lshift` and `rshift` separately. (Combo strings *are* folded:
`shortcuts.keypressed['shift+a']` matches either.) Iterating the table yields
nothing on the shipping runtime; index it by name.

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
