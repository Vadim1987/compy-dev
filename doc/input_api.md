# Compy Input API

<!-- authored By LLM; human-approved NOT YET -->

## Overview

This guide is for people writing compy projects — games and apps that run inside compy — and
covers `compy.input`, the sole project-facing input surface. For how the machinery works under
the hood, see the internals doc linked at the bottom.

**Current version: `1.0.0-rc20260712`.**

The callback API described here is the whole story: the entire `compy.input.*` surface is
**(supported since 1.0.0-rc20260712)**, and the legacy polling globals it replaced
(`user_input()`, `input_text()`, `input_code()`, `validated_input()`, `write_to_input()`) are
**(deprecated, removed in 1.0.0-rc20260712)**. There is no compatibility shim: calling a removed
global is an ordinary nil call. See [Migration from the legacy globals](#migration-from-the-legacy-globals).

`compy.input` is a table on your project's `compy` namespace. It holds **methods** (call them —
assigning over a method name raises loudly) and **callback slots** (assign to them — that is how
you wire the tier-3 callbacks such as `after_submit`). The input widget itself is a single shared
overlay: there is one active input session at a time, and your project drives it through this
table. **There is no per-frame polling** — submitted text is delivered to your callbacks.

## Quick start

The smallest useful program — an echo loop (this is `src/examples/repl`, verbatim):

```lua
compy.input.after_submit = function()
  compy.input.show{}
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
```

Line by line:

- `compy.input.after_submit = function() ... end` — `after_submit` is a **field-write-only**
  callback (see [the callout below](#the-submit-lifecycle)): you assign it directly, you do not
  pass it inside `show{}`. It fires after each submit, once the widget has already hidden — the
  right moment to re-open the widget for the next round.
- `compy.input.show{}` — the bare re-show. Prompt, evaluator, validator and the sticky callbacks
  all persist from the first `show`, so re-arming needs no arguments.
- `compy.input.show{ on_text_entered = ... }` — activates the widget. `on_text_entered` receives
  the submitted text while the widget is still active; here it just prints it.

Run it, type something, press Enter: the line is printed and the widget immediately reopens for
the next line.

## Activating the widget: `show`

```lua
compy.input.show(config)
```

Activates the input overlay. `config` is a table with the following keys (all optional):

| Key | Type | Meaning |
|---|---|---|
| `prompt` | string | Label shown next to the field. |
| `text` | string \| list of line-strings | Initial content. |
| `eval` | evaluator | Runs on submit; drives highlighting/validation. `InputEvalText` (plain text, the default), `InputEvalLua` (Lua syntax highlighting), or `ValidatedTextEval(filters)` (plain text gated by a list of validator functions). Omit for plain text. |
| `validator` | `function(text) -> true \| false, err` | Gates submit (alternative to a `ValidatedTextEval`). Sticky. |
| `highlighter` | function | Colorizes the field. Sticky. |
| `on_text_entered` | `function(text)` | Fires on submit, while the widget is still active. Sticky — also assignable as a field. |
| `on_limit_reached` | callback | Fires when cursor movement hits a boundary. Sticky — also assignable as a field. |
| `force` | boolean | See below. |

If the widget is **already active**, `show` is a no-op **and warns** — unless `config.force = true`,
which replaces only the `text` and ignores every other key. `force` is not how you re-prompt:
normal round-after-round re-prompting is done from `after_submit`
(see [The continuous-session idiom](#the-continuous-session-idiom)).

To deactivate the widget, call `compy.input.hide()`. No cancel callbacks fire.

## The submit lifecycle

When the user presses Enter on an active widget, the steps are, in order:

1. `before_submit(keys_pressed)` fires first (if set) — **before** validation, and it runs even
   on an empty-input Enter. Its argument is the held-key set (`keys_pressed`), **not** the text; a
   return value is reserved for a future veto and is ignored today (blocking bad input is the
   `validator`'s job).
2. The evaluator/validator **gates** the submit. A rejected validation locks the field and shows
   the error; nothing below runs (`after_submit` does not fire).
3. `on_text_entered(text)` fires **while the widget is still active** — this is where you consume
   the submitted text.
4. The widget **hides** (`love.state.user_input` cleared).
5. `after_submit(text)` fires **after** the hide, **only on an accepted submit** — this is where
   you re-prompt for a continuous session.

Cancel (Escape, in the relevant context) fires `before_cancel` / `after_cancel` analogously.

### Two callback families

The callbacks split into two families, and the distinction matters:

- **Sticky / config-mergeable** — pass them in `show{}`/`configure{}` *or* assign them as fields;
  they persist across show/hide until overwritten: `on_text_entered`, `on_limit_reached`,
  `validator`, `highlighter`.
- **Field-write only** — these are **not** merged by `show{}`; you must assign them directly on
  `compy.input`: `before_submit`, `after_submit`, `before_cancel`, `after_cancel`,
  `on_key_pressed`, `on_text_input`, `on_key_released`.

> **Warning — the `after_submit` footgun.** `after_submit` (and the rest of the field-write-only
> family) is **not a `show{}` config key**. Passing it inside `show{...}` is **silently dropped** —
> no error, no warning, your callback just never fires and the widget never reopens. Always assign
> it directly:
>
> ```lua
> -- WRONG: silently ignored
> compy.input.show{ after_submit = function() compy.input.show{} end }
>
> -- RIGHT: field write
> compy.input.after_submit = function() compy.input.show{} end
> ```

## The continuous-session idiom

This is the headline pattern. The widget delivers via callbacks and there is no polling, so to
keep accepting input round after round you activate **once** and re-arm from `after_submit`:

```lua
compy.input.after_submit = function()
  compy.input.show{}          -- bare re-show; callbacks/validator/eval/prompt stay sticky
end

compy.input.show{
  prompt          = "say something:",
  on_text_entered = function(text) print(text) end,
}
```

Because `on_text_entered`, `validator`, `highlighter`, `eval` and the `prompt` all persist across
a bare `show{}`, the re-arm needs no arguments. `after_submit` runs after the widget has hidden
(step 5 of the lifecycle), so the `show{}` inside it is a fresh activation, not a
warned-about double `show`.

To **change** the prompt mid-session, call `compy.input.configure{ prompt = "..." }` — e.g. from
inside `on_text_entered`, or between rounds
(see [Live reconfigure](#live-reconfigure-configure-set_text-clear-cursor)).

## Validation & highlighting

The `eval` config key selects the evaluator that runs on submit and drives highlighting and
validation. Three evaluators are available as globals in the project environment:

- `InputEvalText` — plain text. The default; omit `eval` to get it.
- `InputEvalLua` — Lua, with syntax highlighting in the field.
- `ValidatedTextEval(filters)` — plain text whose `filters` (a list of validator functions) gate
  the submit.

A validator function has the shape `(text) -> true | false, err`. On `false`, the submit is
rejected: the field locks and the error is shown; `on_text_entered` never fires for that attempt.

**Validated input** (from `src/examples/guess` — reject anything that isn't a natural number):

```lua
compy.input.after_submit = function()
  compy.input.show{}
end

compy.input.show{
  prompt          = "Guess a number:",
  eval            = ValidatedTextEval({ is_natural }),   -- is_natural(s) -> true | false, err
  on_text_entered = function(t) check(tonumber(t)) end,
}
```

Filters compose as a list — `src/examples/valid` uses the same shape with multiple filters:

```lua
eval = ValidatedTextEval({ min_length(2), is_lower })
```

A single `validator = function(text) ... end` config key is the lighter-weight alternative when
you don't need the filter-list machinery, and `highlighter = function(...) ... end` lets you
colorize the field yourself. Both are sticky.

**Lua-highlighted code entry with a pre-filled body** (from `src/examples/tixy`):

```lua
local function submit_body(text)
  body = string.unlines(text)   -- text arrives as a list of lines
  setupTixy()
end

compy.input.after_submit = function()
  compy.input.show{ text = string.lines(body) }
end

compy.input.show{
  prompt          = "function tixy(t, i, x, y)",
  text            = string.lines(body),
  eval            = InputEvalLua,       -- Lua syntax highlighting
  on_text_entered = submit_body,
}
```

Here the re-show is *not* bare: it re-injects the just-submitted body so the user keeps editing
in place instead of starting from an empty field.

## Live reconfigure: `configure`, `set_text`, `clear`, cursor

**`compy.input.configure(config)`** live-reconfigures the session:

- While the widget is **active**, it immediately applies `prompt`, `highlighter`, `validator`,
  and the widget-output callbacks (`on_text_entered`, `on_limit_reached`). `text` and `cursor`
  are accepted but have **no effect** while active — use `set_text` / `set_cursor` / `clear` for
  content.
- While the widget is **hidden**, `configure` is always safe (never warns) and stashes `prompt` /
  `text` / `cursor` to apply on the **next** `show()`. The stash is one-shot: a later bare
  `show()` won't re-inject a stale draft.
- It is never a partial apply: each field applies in full or is dropped.

**`compy.input.set_text(text [, keep_cursor])`** replaces the widget content live. `text` is a
string or a list of line-strings. By default the caret moves to the end; pass `keep_cursor = true`
to keep it (clamped to the new content). No-ops **and warns** if the widget is hidden.

**`compy.input.clear()`** empties the active session's content and moves the caret to the start;
no callback fires. No-ops **and warns** if hidden.

**`compy.input.get_cursor()`** returns `line, col`; **`compy.input.set_cursor(line, col)`** moves
the caret. Both act on the active session.

**A continuous session with a changing prompt** (from `src/examples/balloons`):

```lua
-- deliver submitted text to whatever handler the app currently wants
local current_handler = function(_) end
local function deliver(text) current_handler(text) end

compy.input.after_submit = function()
  compy.input.show{}
end
compy.input.show{ on_text_entered = deliver }

-- later, update the visible prompt live (safe whether active or hidden):
compy.input.configure{ prompt = next_hint }
```

And tixy's preset loader live-fills the field while it is active:

```lua
compy.input.set_text(body)
```

## Combo key handlers

Advanced: to grab a specific chord rather than a stream of events, register it in
`compy.input.handlers`:

```lua
compy.input.handlers.keypressed["ctrl+s"] = function() save() end
```

`handlers.keypressed`, `handlers.keyreleased` and `handlers.textinput` each map a canonical combo
string to a handler. Combo strings list modifiers in the fixed order ctrl, alt, shift, gui, then
the key — e.g. `"ctrl+s"`, `"alt+shift+f4"`, `"escape"`. For general per-key handling, the
field-write callbacks (`on_key_pressed`, `on_text_input`, `on_key_released`) are the common path.

## API reference

### Methods (supported since 1.0.0-rc20260712)

Call these; assigning over a method name raises.

| Method | Description |
|---|---|
| `show(config)` | Activate the widget. No-op + warn if already active, unless `config.force = true` (replaces only `text`). |
| `hide()` | Deactivate the widget. No cancel callbacks fire. |
| `configure(config)` | Live-reconfigure: applies `prompt`/`highlighter`/`validator`/output callbacks immediately when active; stashes `prompt`/`text`/`cursor` (one-shot) when hidden. Never warns when hidden. |
| `set_text(text [, keep_cursor])` | Replace content live (string or list of lines). Caret to end unless `keep_cursor`. No-op + warn if hidden. |
| `clear()` | Empty the active content, caret to start, no callback. No-op + warn if hidden. |
| `get_cursor()` | Returns `line, col` of the active session. |
| `set_cursor(line, col)` | Move the caret in the active session. |
| `handlers` | Container for combo key handlers: `handlers.keypressed[combo]`, `handlers.keyreleased[combo]`, `handlers.textinput[combo]`. |

### `show` / `configure` config keys (supported since 1.0.0-rc20260712)

| Key | Description |
|---|---|
| `prompt` | Label shown next to the field. |
| `text` | Initial content: string or list of line-strings. Ignored by `configure` while active. |
| `eval` | Evaluator: `InputEvalText` (default), `InputEvalLua`, or `ValidatedTextEval(filters)`. |
| `validator` | `(text) -> true \| false, err` gating submit. Sticky. |
| `highlighter` | Function colorizing the field. Sticky. |
| `on_text_entered` | Submit consumer (widget still active). Sticky. |
| `on_limit_reached` | Fires when cursor movement hits a boundary. Sticky. |
| `force` | `show` only: replace `text` on an already-active widget instead of warning. |

### Sticky callbacks (supported since 1.0.0-rc20260712)

Config-mergeable *or* field-writable; persist across show/hide until overwritten.

| Callback | Fires |
|---|---|
| `on_text_entered(text)` | On submit, while the widget is still active. |
| `on_limit_reached(...)` | When cursor movement hits a boundary. |
| `validator(text)` | On submit, to gate it. |
| `highlighter(...)` | To colorize the field. |

### Field-write-only callbacks (supported since 1.0.0-rc20260712)

Assign directly (`compy.input.after_submit = fn`); **silently dropped** if passed inside `show{}`.

| Callback | Fires |
|---|---|
| `before_submit(keys_pressed)` | First — before validation, widget still active; runs even on empty Enter. |
| `after_submit(text)` | After the widget hides — the re-prompt hook. |
| `before_cancel(...)` | On cancel, before the widget hides. |
| `after_cancel(...)` | On cancel, after the widget hides. |
| `on_key_pressed(...)` | Key press events. |
| `on_text_input(...)` | Text input events. |
| `on_key_released(...)` | Key release events. |

## Migration from the legacy globals

The legacy polling globals are **(deprecated, removed in 1.0.0-rc20260712)**. There is no shim:
calling one now is an ordinary nil call. The whole poll idiom — grab a handle, check
`is_empty()` every frame, drain it — is gone; the widget now pushes to your callbacks instead.

| Legacy (deprecated, removed in 1.0.0-rc20260712) | Replacement |
|---|---|
| `user_input()` + per-frame `r:is_empty()` / `r()` poll | `on_text_entered` consumes each submit; `after_submit` re-shows for the next round. |
| `input_text(prompt, init)` | `compy.input.show{ prompt = prompt, text = init, on_text_entered = fn }` |
| `input_code(prompt, init)` | `compy.input.show{ prompt = prompt, text = init, eval = InputEvalLua, on_text_entered = fn }` |
| `validated_input(filters, prompt)` | `compy.input.show{ prompt = prompt, eval = ValidatedTextEval(filters), on_text_entered = fn }` |
| `write_to_input(c)` | `compy.input.set_text(c)` |

Before/after, the guessing-game shape:

```lua
-- BEFORE (removed in 1.0.0-rc20260712)
local r = validated_input({ is_natural }, "Guess a number:")
function love.update()
  if not r:is_empty() then check(tonumber(r())) end
end

-- AFTER (supported since 1.0.0-rc20260712)
compy.input.after_submit = function()
  compy.input.show{}
end
compy.input.show{
  prompt          = "Guess a number:",
  eval            = ValidatedTextEval({ is_natural }),
  on_text_entered = function(t) check(tonumber(t)) end,
}
```

## See also

- [User Input — Implementation Overview](development/internals/user_input.md) — the
  how-it-works narrative: widget internals, routing, and mode-specific behavior.
