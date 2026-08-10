---
description: Project-author guide to compy.input — the overlay, its config table, the submit lifecycle, hooks and shortcuts
status: active
audience: project author
authored: llm
reviewed: none
---

# Compy Input API

> REMARK: rewrite intro completely, be dev-friendly. Vague statements do not help. Just tell its an API for configuring and interacting with text solicitation subsystem, and for reacting to user input events (all of them). Tell that even when widget is not shown or used, still it can be used to manage hotkeys, combos etc.

This guide is for projects running inside Compy. `compy.input` is the
project-facing input surface: it opens one shared text overlay and delivers
submissions through callbacks. There is no polling API or compatibility shim.

> REMARK: would it help readability if we conceptually split API into three surfaces (and say so): a) dispatching/intercepting inbound events via shortcuts and hooks b) altering the soliciting widget state (hide/show/cursor/reconfigure) c) handling events generated inside widget via callbacks (submit, cancel, limit...)

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

1. `before_submit()`, if assigned. A truthy return vetoes the
   submit: steps 2-4 do not run and the text stays in the field.
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

Escape first runs `before_cancel()`. A truthy return vetoes the
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

> REMARK: why developer would even think of reading love.state?

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
way. A shortcut runs before the input widget and can consume the event.

**Every shortcut, hook and callback receives exactly the arguments LÖVE
delivers for that event** — `keypressed(key, scancode, isrepeat)`,
`mousepressed(x, y, button, istouch, presses)`, and so on. A handler you
already wrote as `love.keypressed` works unchanged when it becomes a hook,
because it is the same signature. Held modifiers are not among the arguments:
ask the keyboard for them with `love.keyboard.isDown`, which works inside a
handler and outside one alike — see "Held keys" below.

A combo is its modifiers plus **one** trigger — `'ctrl+alt+s'`. The modifiers
are optional: `'s'` is a valid combo and binds a bare unmodified S, the same
way `'mouse2'` binds an unmodified right-click. Modifiers come first in a fixed
order (ctrl, alt, shift, gui), left and right fold together, and the whole
string is normalised when you assign it, so `'Ctrl+Alt+S'` and `'ctrl+alt+s'`
are the same binding. A combo naming two triggers or none raises.

The trigger may be `*`, which binds the whole modifier class: `'alt+*'` is
every Alt chord, and the handler receives the actual key as its first
argument. An exact binding wins — with both `'alt+*'` and `'alt+p'`
registered, Alt+P runs the exact one. A class is its modifier set exactly, so
`'alt+*'` does not catch Ctrl+Alt+H, and it never fires for the modifier's own
press.

A bare `'*'` raises: a class needs modifiers to be a class *of*. For every key
on a channel, use a hook — that is what hooks are.

```lua
compy.input.shortcuts.keypressed['alt+*'] = function() return true end
compy.input.shortcuts.keypressed['alt+p'] = function()
  pause()
  return true
end
```

A held key repeats, and shortcuts and hooks see every repeat. Three
combinators under `compy.input.fn` let a registration say what should happen,
so the handler does not have to:

| wrapper | effect |
|---|---|
| `fn.ignore_repeat(f)` | skip `f` on a repeat; says nothing about propagation |
| `fn.stop_here([f])` | run `f` if given, then consume — the event stops here |
| `fn.side_run([f])` | run `f` if given, and let the event carry on |

They are orthogonal — one about whether your function *runs*, two about where
the event *goes* — and they compose:

```lua
local fn = compy.input.fn
-- a reserved key: acts once per press, nothing below sees it
sc['ctrl+alt+up'] = fn.stop_here(fn.ignore_repeat(function() notch(1) end))
-- swallow a whole class, with nothing to run
sc['alt+*'] = fn.stop_here()
-- a side effect: acts once, and the key still reaches the overlay
sc['backspace'] = fn.side_run(fn.ignore_repeat(note_deleting))
```

`stop_here` and `side_run` both take the function optionally, and `side_run`
lets the event through even when the wrapped function returns truthy — the
declaration at the registration site outranks the handler, which is the point
of declaring it there.

Without them you would end handlers with `return true`, which makes a function
that merely toggles a pause know what happens after it returns, and carry that
knowledge wherever it is reused.

> REMARK: retire word 'overlay' -- "stop reaching the input widget too" is a proper formula 

All three wrap a hook the same way, but think before you do: a whole-channel
hook wrapped in `stop_here(ignore_repeat(...))` swallows every repeat on that
channel, so held backspace and held arrows stop repeating in the overlay too.

Combos of ordinary keys — "A and B held together" — are deliberately not
expressible. Every binding would otherwise become conditional on nothing else
being held, so holding a movement key would silently break unrelated
shortcuts. Anything beyond exact-or-class matching belongs in a hook, which
sees every event on its channel; "Shortcuts that set a flag" below is the shape
to reach for when the two have to work together.

`compy.input.hooks.keypressed`, `.keyreleased`, and `.textinput` are one
fallback function per event. At activation, an existing project `love.*`
handler seeds the matching hook when no explicit hook was supplied.

## Pointer and click hooks

Pointer events run the same chain as keyboard ones, so they are hooks like
any other: `hooks.mousepressed`, `.mousereleased`, `.mousemoved`,
`.wheelmoved`, `.touchpressed`, `.touchreleased`, `.touchmoved`. Each
receives exactly the arguments LÖVE delivers, and each is seeded at
activation from your `love.*` handler of the same name, so an existing
`function love.mousepressed(x, y, btn)` keeps working untouched.

Two more are **derived**: the framework watches the raw presses and decides
whether they amount to one click or two, then delivers the verdict as an
ordinary event.

```lua
compy.input.hooks.singleclick = function(x, y) place(x, y) end
compy.input.hooks.doubleclick = function(x, y) remove(x, y) end
```

A single click is only confirmed after the double-click window has passed,
so it arrives slightly late — that wait is what makes the two
distinguishable. Moving the pointer between the presses invalidates both.

Being ordinary chain participants, pointer hooks **consume on a truthy
return** like keyboard ones: return truthy and a shown overlay does not see
the event. Return nothing and it carries on to the overlay, which is what
you want while an overlay is up for its own reasons.

Pointer events take shortcuts too, and the vocabulary is the same one: the
button is the trigger, written `mouse1` (left), `mouse2` (right), `mouse3`
(middle).

```lua
compy.input.shortcuts.mousepressed['mouse2'] = function(x, y)
  open_context_menu(x, y)
  return true
end
compy.input.shortcuts.mousepressed['ctrl+mouse1'] = function(x, y)
  add_to_selection(x, y)
  return true
end
```

`mousepressed` and `mousereleased` name a button. The channels that have no
discrete trigger — `mousemoved`, `wheelmoved`, the touch events, and the
derived clicks — take modifier classes only, so `shortcuts.mousemoved['ctrl+*']`
is a ctrl-drag and an unmodified move goes straight to the hook.

> REMARK: not 'overlay', but 'input widget'
> REMARK: frame this whole paragraph as example of solving non-conventional challenge (preventing modifier-based hotkey from echoing into the input widget), not say "if you open with 'i'" as if it was some common or recommended convention

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

> REMARK: term 're-arm' is invented -- if you use it, make sure its explained or defined in the same doc, upfront.

Re-arm wherever you close the overlay: one that is closed without re-arming
takes the echo on its next open. Only your own `hide()` calls need this —
Escape *clears* the field without closing, so the spent one-shot is still
correct.

Use a **bare** key as the trigger. A modified combo cannot be guarded this
way: the two channels do not share a combo string for it — `shift+i` on
`keypressed` against `shift+I` on `textinput` — and the upper-case form
cannot be registered.

## Held keys

> PENDING: this section documents the device read as the only held-key answer,
> while `compy.input.keys_pressed` still exists in the tree. The platform step
> that removes the field removes this marker.

**Reach for a combo first.** To react to a *modified event* — a click with Ctrl,
`Shift+Enter`, `alt+p` — register a shortcut and let the framework match it:
`shortcuts.keypressed['ctrl+s']`. That says it once, as data, in a vocabulary
that is already folded and already the same on every channel. Asking about
modifiers imperatively inside a handler turns into a cascade repeated at every
call site.

For what a combo cannot express, **ask the keyboard**. `love.keyboard.isDown`
takes any number of key names and answers about the device as it is right now:

```lua
function love.draw()
  draw_keycaps(love.keyboard.isDown('lshift', 'rshift'))
end
```

Key names are LÖVE's own, so left and right modifiers are two separate keys —
name both when either will do. (Combo strings *are* folded:
`shortcuts.keypressed['shift+a']` matches either shift.)

The call works anywhere: in a handler, and in `love.draw`, which is the point —
a project that *draws* held state has no event argument to consult. Handlers
need nothing added to their arguments for it, and get nothing added: every
shortcut, hook and widget call receives LÖVE's own argument list.

## Shortcuts that set a flag

Some logic does not fit inside one shortcut function — it needs to know a key is
held *while something else happens*, or it spans several events on different
channels. Growing the shortcut is the wrong move: it ends up asking the keyboard
the same question at every call site, which is the cascade shortcuts exist to
replace.

Let a tiny shortcut record the fact instead, and let the hook read it. The
shortcut sets a flag and **does not consume** its event, so everything
downstream still sees the key; the real logic then branches on your project's
own state rather than on the hardware:

```lua
local fn = compy.input.fn
local drawing = false

compy.input.shortcuts.keypressed['space'] = fn.side_run(function()
  drawing = true
end)
compy.input.shortcuts.keyreleased['space'] = fn.side_run(function()
  drawing = false
end)

compy.input.hooks.mousemoved = function(x, y)
  if drawing then paint(x, y) end
end
```

The binding stays declarative and listable, the hook stays a plain function of
state you own, and nothing in between has to ask which keys are down.

## Callback assignments

`compy.input.callbacks` is writable. These entries may also be supplied in
`show` or `configure` and persist until replaced: `on_text_entered`,
`on_limit_reached`, `validator`, and `highlighter`.

The lifecycle entries are direct assignments only: `before_submit`,
`after_submit`, `before_cancel`, and `after_cancel`.

## Stop hook — `compy.before_exit`

A settable slot on `compy` itself, not on `compy.input`: it is a
project-*run* lifecycle hook, not an input-channel callback. It exists so a
project can put back global device state it changed imperatively — the
sandbox clones the `love` table but shares the underlying C functions, so
calls like `love.keyboard.setKeyRepeat(false)` change real state that
outlives the run.

```lua
love.keyboard.setKeyRepeat(false)

compy.before_exit = function()
  love.keyboard.setKeyRepeat(true)
end
```

> REMARK: it should be able to suprress/defer the stop?  or if its not allowed purposefully -- that it should not be announced as 'deferred' functionality in other part of documentation

- **Signature:** no arguments — the project knows its own state.
- **Return value:** ignored. It cannot suppress or defer the stop.
- **Timing:** runs *before* the framework's own teardown, so `love.*` calls
  inside it are still safe.
- **Fires on:** every framework-invoked stop of a running project —
  `Ctrl+Esc`, quitting the project, switching away to the editor, and app
  shutdown in play mode.
- **Does NOT fire when the project's own code raises.** A raise in top-level
  code ends the run without a stop, and a raise inside a handler suspends it
  instead; neither is a stop path. Do not rely on this hook to undo something
  a crash could leave behind — see
  [technical debt](development/technical_debt/input.md), "A project that
  raises leaves global device state dirty".
- **Reset:** back to the default no-op once the run ends, by whichever path
  it ended — so one project's hook never fires for the next one. Like every
  other project participant, it does not survive the run that installed it.
- **Default:** a no-op that logs in debug mode.

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
| `function compy.singleclick(x, y)` | `compy.input.hooks.singleclick = function(x, y) ... end` |
| `function compy.doubleclick(x, y)` | `compy.input.hooks.doubleclick = function(x, y) ... end` |
| `eval = InputEvalLua` | `highlighter = LuaHighlighter, validator = LuaSyntaxValidator` |
| `eval = ValidatedTextEval(filters)` | `validator = LineValidators(filters)` |
| `result = ...` | Consume `lines` in `on_text_entered`; no result object exists. |

The old evaluator globals (`InputEvalText`, `InputEvalLua`,
`ValidatedTextEval`, and `LuaEditorEval`) are not project API. Do not place
them in `show` or `configure` tables.

## See also

- [User Input — Implementation Overview](development/internals/user_input.md)
