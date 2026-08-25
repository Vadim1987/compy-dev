---
description: Project-author guide to compy.input — the input widget, its config table, the submit lifecycle, hooks and shortcuts
status: active
audience: project author
authored: llm
reviewed: none
---

# Compy Input API

> REMARK: rewrite intro completely, be dev-friendly. Vague statements do not help. Just tell its an API for configuring and interacting with text solicitation subsystem, and for reacting to user input events (all of them). Tell that even when widget is not shown or used, still it can be used to manage hotkeys, combos etc.

This guide is for projects running inside Compy. `compy.input` is the
project-facing input surface: it opens one shared text input widget and delivers
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

The input widget stays open after a successful submit. `after_submit` clears the
next draft; it is assigned on `callbacks`, not passed to `show`.

## `show(config)`

`compy.input.show(config)` activates the input widget. All keys are optional.

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

`show` on an active input widget warns and does nothing unless `force = true`.

A key outside this table **raises**. The config table is closed, so an
unrecognised key can only be a mistake, and a mistake you can see beats one
that leaves the input widget quietly not doing what you asked. This includes
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
input widget displays the error and steps 3–4 do not run. A highlighter has no
submit or validation authority: it only controls how the current text looks.

The input widget remains shown by default. To close it after a submit, make that
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
| `LuaHighlighter(lines)` | Lua syntax coloring for the input widget. |
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

`compy.input.configure(config)` updates an active input widget. It accepts the
same documented configuration keys except `force`, and raises on anything
else by the same rule as `show`; active `text` and `cursor`
are not changed by `configure`, so use `set_text`, `set_cursor`, or `clear`.
When hidden, `configure` retains `prompt`, `text`, and `cursor` for one later
`show`.

`compy.input.is_shown()` tells you whether the input widget is up. Use it when a
project must not act twice — opening the prompt from a key that is also
typed *into* the prompt, for example:

```lua
compy.input.hooks.keyreleased = function(key)
  if key == 'i' and not compy.input.is_shown() then
    compy.input.show{ prompt = 'command' }
    return true -- consumed; while it is open, 'i' is the widget's
  end
end
```

That guard stops *later* presses of `i` from re-opening the prompt. It does
not stop the `i` that opened it from being typed into it — see "Opening the
input widget from a key" below.

`compy.input.set_text(text [, keep_cursor])` replaces content. `clear()`
empties it. `get_cursor()` returns `line, col`; `set_cursor(line, col)` moves
it. Mutating calls warn and do nothing while the input widget is hidden.

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
ask `Key` for them — `Key.shift()` for a modifier, `Key.any_pressed(k)` for
any other key — which works inside a handler and outside one alike; see
"Held keys" below.

A combo is its modifiers plus **one** trigger — `'ctrl+alt+s'`. The modifiers
are optional: `'s'` is a valid combo and binds a bare unmodified S, the same
way `'mouse2'` binds an unmodified right-click. Modifiers come first in a fixed
order (ctrl, alt, shift — there are three, and Super/Cmd is not one of
them), left and right fold together, and the whole
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
-- a side effect: acts once, and the key still reaches the widget
sc['backspace'] = fn.side_run(fn.ignore_repeat(note_deleting))
```

`stop_here` and `side_run` both take the function optionally, and `side_run`
lets the event through even when the wrapped function returns truthy — the
declaration at the registration site outranks the handler, which is the point
of declaring it there.

Without them you would end handlers with `return true`, which makes a function
that merely toggles a pause know what happens after it returns, and carry that
knowledge wherever it is reused.

All three wrap a hook the same way, but think before you do: a whole-channel
hook wrapped in `stop_here(ignore_repeat(...))` swallows every repeat on that
channel, so held backspace and held arrows stop repeating in the input widget too.

Combos of ordinary keys — "A and B held together" — are deliberately not
expressible. Every binding would otherwise become conditional on nothing else
being held, so holding a movement key would silently break unrelated
shortcuts. Anything beyond exact-or-class matching belongs in a hook, which
sees every event on its channel; "Choosing the mechanism" below covers what to
do when a binding and a held key have to work together.

`compy.input.hooks.keypressed`, `.keyreleased`, and `.textinput` are one
fallback function per event. At activation, an existing project `love.*`
handler seeds the matching hook when no explicit hook was supplied.

## Combos the framework keeps

A few combinations belong to the platform. They are answered before your
project's route exists, so **a project cannot take one by naming it** — but the
platform does not swallow the key either: **your binding still runs**, and the
platform's action happens as well.

That combination is worth reading twice, because it is the opposite of how your
own shortcuts behave. Yours consume by returning truthy. A reserved combo never
consumes; it acts *and* passes the key on.

The practical consequence is only visible for the ones that end a run: your
handler runs, and then the project is stopped anyway. Nothing suppressed you —
the route you were bound to was taken down underneath you.

**A reservation is its modifier set exactly.** It does not extend to chords it
does not name, so `ctrl+shift+escape` is yours to bind even though `ctrl+escape`
is not, and `ctrl+shift+t` is yours even though `ctrl+t` is not. Adding a
modifier to a reserved combo is a reliable way to get a nearby chord for
yourself.

| Combo | What the platform does | When |
|---|---|---|
| `ctrl+escape` (on **release**) | stops the run; quits when there is nothing to go back to | always |
| `ctrl+alt+r` | restarts the project | always |
| `ctrl+t` | switches between running and the editor | development only |
| `ctrl+s` | stops a running project | development only |
| `ctrl+q` | quits the project | development only |
| `ctrl+pause` | suspends the run | development only |
| `ctrl+shift+r` | resets: quits and wipes the console | development only |
| `ctrl+alt+p` / `ctrl+alt+shift+p` | starts / stops the profiler | profiling builds |
| `f10` | cycles the FPS overlay corner | profiling builds |

"Development only" means the combo is inert in a packaged build, where the
console it returns you to is not there to return to. Note `f10` is the one
reservation with no modifier at all: bare F10 is the platform's in a profiling
build, and F10 with any modifier is yours.

It is also the only F-key worth binding at all. On the current hardware the
function row is the keyboard's Fn layer — Insert is Fn+F12, Scroll Lock is
Fn+F10, mute and the media keys are Fn+F5 through Fn+F8 — so **F1 to F9 never
reach your project**; the firmware answers them. F10 does arrive, which is why
the platform could take it; F11 and F12 are untested. Bind help, pause and debug
gestures to letter chords instead: an example that wants a held help overlay
uses Alt+H (`doc/development/keyboard.md` is the per-key availability table).

Ctrl+S and Ctrl+Shift+S also do something in the **editor** — close the buffer
and finish the edit — but that is the editor's own handling, not a reservation:
it applies when you are editing, not while your project runs.

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
return** like keyboard ones: return truthy and a shown input widget does not see
the event. Return nothing and it carries on to the input widget, which is what
you want while an input widget is up for its own reasons.

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

## Worked example: a plain key that opens the input widget

Not a recommended shape — a **worked example of an awkward case**, and of how
the pieces above combine to solve one. Most projects open the widget from a
modified combo, where nothing below arises.

Bind a bare character key to open a prompt and the prompt comes up with that
character already in the field. LÖVE delivers a `keypressed` **and** a
`textinput` for one physical key and does not promise their order, so the
trigger's own echo arrives on the other channel, either side of the open. The
`is_shown()` guard does not help: it is about the *next* press, not this one.

Guard the trigger with a one-shot shortcut on the `textinput` channel.
Shortcuts run before the input widget, so it swallows the echo whichever side of
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

**Re-arming** is registering that one-shot again, and it is needed wherever you
close the input widget: one closed without a fresh guard takes the echo on its
next open. Only your own `hide()` calls need this —
Escape *clears* the field without closing, so the spent one-shot is still
correct.

Use a **bare** key as the trigger. A modified combo cannot be guarded this
way: the two channels do not share a combo string for it — `shift+i` on
`keypressed` against `shift+I` on `textinput` — and the upper-case form
cannot be registered.

## Held keys

There are three ways to find out that a key is held, and they are **not
equal alternatives** — the further down this list you go, the more likely it
is that the logic wanted to be a binding and became a hardware question
instead.

**1. Register a combo — the mechanism, and the first thing to reach for.** To
react to a *modified event* — a click with Ctrl, `Shift+Enter`, `alt+p` —
register a shortcut and let the framework match it:
`shortcuts.keypressed['ctrl+s']`. That says it once, as data, in a vocabulary
that is already folded and already the same on every channel. Asking about
modifiers imperatively inside a handler turns into a cascade repeated at every
call site. When a binding and a held key have to work together, see "Choosing
the mechanism" below.

**2. Ask `Key` — allowed, and worth a second look.** `Key` is available to
every project, like `compy`. `Key.shift()`, `Key.ctrl()` and `Key.alt()`
answer whether that modifier is held right now, either side:

```lua
function love.draw()
  draw_keycaps(Key.shift())
end
```

Each folds its own left/right pair, so you never name `lshift` and `rshift`
yourself — the same folding a combo string does. Nothing is wrong with these
calls, but a project that reaches for them repeatedly is usually describing a
binding it has not written yet; that is the cascade combos exist to replace.

**3. Ask `Key.any_pressed` — for a key that is not a modifier.** It takes any
number of key names and answers about the device as it is right now, for
**any** key:

```lua
function love.draw()
  draw_keycap('space', Key.any_pressed('space'))
end
```

This is the rung to use when the folded accessors have no answer — an
ordinary key, which is what drawing a keyboard and lighting its pressed caps
needs. Names are LÖVE's own, so left and right modifiers are two separate
keys here and you name both when either will do — `Key.any_pressed('lshift',
'rshift')` is what `Key.shift()` already says. **Several names mean *any* of
them**, exactly like the device call it wraps. Prefer the folded accessors
whenever the question is about a modifier, and reach here when it is not.

`love.keyboard.isDown` still works and is what this calls; using `Key` for
both kinds of question just keeps one surface in your code instead of two
spellings of the same question in one expression.

Every rung works anywhere: in a handler, and in `love.draw`, which is the
point — a project that *draws* held state has no event argument to consult.
Handlers need nothing added to their arguments for it, and get nothing added:
every shortcut, hook and widget call receives LÖVE's own argument list.

## Choosing the mechanism: transitions, state, and what not to build

The API offers three ways to reach input, and they answer different questions.
Choosing by question rather than by taste is what keeps a project predictable.

**A shortcut is for a one-off transition of your own state** — start the game,
end it, switch mode, open the prompt. It is an *independent* change that stands
on its own once made. Its purpose is decomposition: one binding per thing,
listable as data, instead of one hook demultiplexing a dozen combos by hand.

**Polling is for continuous state** — is the paddle key down, is Ctrl held
while this drag happens, which caps to light while drawing. Ask `Key` at the
moment you need the answer. This is not a lesser rung: the device is
self-correcting, and asking it costs nothing but the call.

**Do not use a pair of shortcuts to hold a state.** Setting a flag on
`keypressed` and clearing it on `keyreleased` for the same combo looks tidy and
is not reliable, because the closing event is not guaranteed to arrive in the
shape the opening one expects:

```lua
-- DON'T: the flag can outlive the key.
compy.input.shortcuts.keypressed['alt+h']  = fn.side_run(function() peek = true end)
compy.input.shortcuts.keyreleased['alt+h'] = fn.side_run(function() peek = false end)
```

Release Alt before `H` and the second event serialises as plain `'h'`, so the
clearing binding never runs and `peek` stays true. Hold an unrelated modifier
while releasing and a bare `'space'` binding misses the same way. Lose the
window to a notification and no release arrives at all. **A modifier's own
release cannot even be bound**, so for some chords the closing half is not
writable.

Ask instead, at the moment the answer matters:

```lua
-- DO: a question with no state to go stale.
local function peeking()
  return Key.any_pressed('h') and Key.alt() and not Key.ctrl()
end

compy.input.hooks.mousemoved = function(x, y)
  if Key.shift() then paint(x, y) end
end
```

Reacting on `keyreleased` is still a fine *choice* — it is a natural fit for
"act once when the key comes up", and it sidesteps key repeat without any
filtering. What it must not be is the closing half of a mirrored pair. (For
"act once on press", `fn.ignore_repeat` does the same job on the press
channel.)

**Do not rebuild "what is held" from the event stream.** Keeping your own table
of keys currently down — or a boolean mirroring one key — is virtual state with
no path back to the truth: a release lost to focus change or a hiccup leaves it
lying, and nothing corrects it afterwards. If your project has a reason to do
it anyway, make that an explicit decision taken in awareness of the drift, not
a default. The framework does not maintain such a table, and deliberately so.

**Lift the hardware to the top.** When logic gets complex, read the keyboard
early — at the top of the handler or `update` — into names that mean something
in your game, then let the rest of the logic run on those:

```lua
local fast   = Key.shift()          -- one place asks the hardware
local precise = Key.ctrl()

move(fast, precise)                  -- everything below is deterministic
```

It keeps the non-deterministic part visible in one place instead of scattered
through code that is otherwise a pure function of your own state.

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
