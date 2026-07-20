# Compy Input API

<!-- authored By LLM; human-approved NOT YET -->

## Overview

This guide is for people writing compy projects — games and apps that run inside compy — and
covers `compy.input`, the sole project-facing input surface. For how the machinery works under
the hood, see the internals doc linked at the bottom.

**Current version: `1.0.0-rc20260712`, input-API redesign (Phase R4).**

The callback API described here is the whole story: the entire `compy.input.*` surface is
**(supported since 1.0.0-rc20260712)**, and the legacy polling globals it replaced
(`user_input()`, `input_text()`, `input_code()`, `validated_input()`, `write_to_input()`) are
**(deprecated, removed in 1.0.0-rc20260712)**. There is no compatibility shim: calling a removed
global is an ordinary nil call. See [Migration from the legacy globals](#migration-from-the-legacy-globals).

`compy.input` is a table on your project's `compy` namespace, holding three writable sub-tables —
`shortcuts`, `hooks`, `callbacks` — plus **methods** (call them; assigning over a method name
raises loudly). The container itself, and the identity of each of the three sub-tables, is
frozen: a project cannot do `compy.input.shortcuts = {}` or `compy.input.callbacks = {}`. Every
**leaf** inside those sub-tables is freely writable — that's how you wire a callback such as
`after_submit`: `compy.input.callbacks.after_submit = fn`. The input widget itself is a single
shared overlay: there is one active input session at a time, and your project drives it through
this table. **There is no per-frame polling** — submitted text is delivered to your callbacks.
**The widget stays open by default** — nothing auto-closes it any more; see
[The submit lifecycle](#the-submit-lifecycle) below.

## Quick start

The smallest useful program — an echo loop (this is `src/examples/repl`, verbatim):

```lua
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
```

Line by line:

- `compy.input.callbacks.after_submit = function() ... end` — `after_submit` is a **field-write-only**
  callback (see [the callout below](#the-submit-lifecycle)): you assign it directly on `callbacks`,
  you do not pass it inside `show{}`. It fires after each successful submit, **while the widget is
  still shown** (the widget no longer auto-closes on submit) — the right moment to clear the field
  for the next round.
- `compy.input.clear()` — empties the content and puts the cursor back at the start; the widget
  itself never needs to be re-shown, because it never hid.
- `compy.input.show{ on_text_entered = ... }` — activates the widget. `on_text_entered` receives
  the submitted text while the widget is still active; here it just prints it.

Run it, type something, press Enter: the line is printed and the field is immediately cleared for
the next line — the widget was never hidden.

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
| `on_text_entered` | `function(text)` | Fires on submit, while the widget is still active. Sticky — also assignable as a `callbacks` field. |
| `on_limit_reached` | callback | Fires when cursor movement hits a boundary. Sticky — also assignable as a `callbacks` field. |
| `force` | boolean | See below. |

If the widget is **already active**, `show` is a no-op **and warns** — unless `config.force = true`,
which replaces only the `text` and ignores every other key. `force` is not how you re-prompt:
because the widget stays open by default, there is usually nothing to re-show at all — see
[The continuous-session idiom](#the-continuous-session-idiom).

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
4. `after_submit(text)` fires — **the widget is still shown at this point.** `after_submit`
   DEFAULTS to a no-op, so **a plain Enter no longer closes the widget.** If you want the
   pre-redesign "prompt once, then close" behaviour, opt in explicitly:
   `compy.input.callbacks.after_submit = function() compy.input.hide() end`.

Cancel (Escape, in the relevant context) is similar but with one asymmetry: `before_cancel`'s
return value **is honoured** — a truthy return **vetoes** the clear step entirely (content
untouched, `after_cancel` does not fire). Otherwise: content clears (hardwired) → `after_cancel`
fires, and — same flipped default as submit — `after_cancel` DEFAULTS to a no-op, so **Escape
clears the field but does not close the widget** either, unless your own `after_cancel` calls
`compy.input.hide()`.

**Enter and Escape are shadowable.** Both are now ordinary keys the widget handles itself, not a
non-overridable framework layer — a project shortcut registered on `'return'` or `'escape'`
(`compy.input.shortcuts.keypressed['return'] = fn`) wins over the widget's default submit/cancel,
same as any other combo. This is a deliberate, named withdrawal of the old
"nothing can stop Enter/Escape while the widget is shown" guarantee — it was never a stakeholder
requirement, and the gateway's power keys (Ctrl+Q, Ctrl+Break, etc.) remain the real, unshadowable
escape hatch regardless of what a project registers here.

### Two callback families

The callbacks split into two families, and the distinction matters. **All of them live in
`compy.input.callbacks`** (a plain leaf-write table — literally the widget's own internal callback
table, so there is nothing to synchronise):

- **Sticky / config-mergeable** — pass them in `show{}`/`configure{}` *or* assign them as
  `callbacks` fields; they persist across show/hide until overwritten: `on_text_entered`,
  `on_limit_reached`, `validator`, `highlighter`.
- **Field-write only** — these are **not** merged by `show{}`; you must assign them directly on
  `compy.input.callbacks`: `before_submit`, `after_submit`, `before_cancel`, `after_cancel`.

> **Warning — the `after_submit` footgun.** `after_submit` (and the rest of the field-write-only
> family) is **not a `show{}` config key**. Passing it inside `show{...}` is **silently dropped** —
> no error, no warning, your callback just never fires. Always assign it directly:
>
> ```lua
> -- WRONG: silently ignored
> compy.input.show{ after_submit = function() compy.input.clear() end }
>
> -- RIGHT: field write, on callbacks
> compy.input.callbacks.after_submit = function() compy.input.clear() end
> ```

## The continuous-session idiom

This is the headline pattern. The widget delivers via callbacks, there is no polling, and — since
the redesign — **the widget stays open by default**, so keeping a session going round after round
usually needs nothing more than clearing the field after each submit:

```lua
compy.input.callbacks.after_submit = function()
  compy.input.clear()          -- fresh empty field; the widget was never hidden
end

compy.input.show{
  prompt          = "say something:",
  on_text_entered = function(text) print(text) end,
}
```

Because the widget never closes, `after_submit` only has to reset the *content* — there is no
re-`show()` involved at all (a `show()` call over an already-active widget is a suppressed,
warned-about no-op). This replaces the old "prompt-once, re-show from `after_submit`" idiom, which
this redesign retires: under the old auto-close default, `after_submit` had to re-open the widget;
under the new stays-open default, a bare re-show is both unnecessary and actively suppressed.

Three shapes cover most cases:

- **Fresh empty field per submit** (the pattern above) — `after_submit = function()
  compy.input.clear() end`.
- **Re-show only to change the prompt** — don't re-show at all; call
  `compy.input.configure{ prompt = "..." }` live, from `on_text_entered` or `after_submit`.
- **Re-show was purely to "stay open"** — remove the callback entirely; staying open is now the
  default.

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
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  prompt          = "Guess a number:",
  eval            = ValidatedTextEval({ is_natural }),   -- is_natural(s) -> true | false, err
  on_text_entered = function(t) check(tonumber(t)) end,
}
```

`guess`'s cancel path needs no callback at all: Escape's own default (clear + stay open) already
re-arms the prompt for the next guess, with nothing left for `after_cancel` to do.

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

-- No after_submit needed: the widget stays open with the just-submitted
-- body already in the field — nothing to re-inject.
compy.input.callbacks.after_cancel = function()
  -- Cancel's own default DOES clear the field (hardwired), so restore
  -- the last-good body live rather than leaving the strip empty.
  compy.input.set_text(string.lines(body))
end

compy.input.show{
  prompt          = "function tixy(t, i, x, y)",
  text            = string.lines(body),
  eval            = InputEvalLua,       -- Lua syntax highlighting
  on_text_entered = submit_body,
}
```

Here submit and cancel diverge: submit leaves the field untouched (so editing continues in
place for free), while cancel's hardwired clear needs an explicit `after_cancel` to restore the
body — otherwise Escape would leave the code strip empty, defeating the point of the demo.

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

**A continuous session with a changing prompt** (the shape `src/examples/balloons`' own
`terminal_init` illustrates the intent of — note `src/examples/balloons` is untracked,
sanctioned scratch and has **not** been migrated onto this redesign's API, so its actual code
still uses the retired auto-close idiom; the snippet below is the *migrated* shape, not a verbatim
quote):

```lua
-- deliver submitted text to whatever handler the app currently wants
local current_handler = function(_) end
local function deliver(text) current_handler(text) end

compy.input.callbacks.after_submit = function()
  compy.input.clear()
end
compy.input.show{ on_text_entered = deliver }

-- later, update the visible prompt live (safe whether active or hidden):
compy.input.configure{ prompt = next_hint }
```

And tixy's preset loader live-fills the field while it is active:

```lua
compy.input.set_text(body)
```

## Combo shortcuts

Advanced: to grab a specific chord rather than a stream of events, register it in
`compy.input.shortcuts`:

```lua
compy.input.shortcuts.keypressed["ctrl+s"] = function() save() end
```

`shortcuts.keypressed`, `shortcuts.keyreleased` and `shortcuts.textinput` each map a canonical combo
string to a function. Combo strings list modifiers in the fixed order ctrl, alt, shift, gui, then
the key — e.g. `"ctrl+s"`, `"alt+shift+f4"`, `"escape"`. A shortcut registered here always wins
over the widget's own default behaviour for that combo — including `'return'`/`'escape'`, see
[The submit lifecycle](#the-submit-lifecycle) above. For a per-event fallback that isn't
combo-specific, register a single function in `compy.input.hooks` (below).

## The `hooks` table

`compy.input.hooks.keypressed` / `hooks.keyreleased` / `hooks.textinput` are each a single
function slot per event — the fallback consumer that runs after `shortcuts` and before the widget.
At project activation, any event for which you have not already set an explicit hook is seeded
once with your project's own captured `love.keypressed`/`love.textinput`/`love.keyreleased`
function (if you defined one) — so defining a plain `love.keypressed` in your project "just works"
without touching `compy.input` at all. Once seeded, `hooks[event]` is the single source of truth:
setting it to `nil` clears it for good — there is no fallback resurrection of your original
`love.*` function.

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

### Sub-tables (supported since 1.0.0-rc20260712)

The container and each sub-table's identity are frozen; every leaf inside is a plain writable
assignment.

| Sub-table | Description |
|---|---|
| `shortcuts` | Combo shortcuts: `shortcuts.keypressed[combo]`, `shortcuts.keyreleased[combo]`, `shortcuts.textinput[combo]`. Always win over the widget's own default behaviour, Enter/Escape included. |
| `hooks` | One fallback function per event: `hooks.keypressed`, `hooks.keyreleased`, `hooks.textinput`. Seeded once from your project's own `love.*` functions at activation; a `nil` write clears for good. |
| `callbacks` | The widget's own invoked-callback table — see below. |

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

### Sticky `callbacks` (supported since 1.0.0-rc20260712)

Config-mergeable *or* field-writable on `compy.input.callbacks`; persist across show/hide until
overwritten.

| Callback | Fires |
|---|---|
| `on_text_entered(text)` | On submit, while the widget is still active. |
| `on_limit_reached(...)` | When cursor movement hits a boundary. |
| `validator(text)` | On submit, to gate it. |
| `highlighter(...)` | To colorize the field. |

### Field-write-only `callbacks` (supported since 1.0.0-rc20260712)

Assign directly (`compy.input.callbacks.after_submit = fn`); **silently dropped** if passed inside
`show{}`.

| Callback | Fires |
|---|---|
| `before_submit(keys_pressed)` | First — before validation, widget still active; runs even on empty Enter. Return value reserved for a future veto (ignored today). |
| `after_submit(text)` | After a successful submit — **widget still shown** (no auto-close). |
| `before_cancel(keys_pressed)` | Before the clear step; a **truthy return vetoes** the clear (and `after_cancel` does not fire). |
| `after_cancel()` | After a non-vetoed cancel's clear — **widget still shown** (no auto-close). |

## Migration from the legacy globals

The legacy polling globals are **(deprecated, removed in 1.0.0-rc20260712)**. There is no shim:
calling one now is an ordinary nil call. The whole poll idiom — grab a handle, check
`is_empty()` every frame, drain it — is gone; the widget now pushes to your callbacks instead.

| Legacy (deprecated, removed in 1.0.0-rc20260712) | Replacement |
|---|---|
| `user_input()` + per-frame `r:is_empty()` / `r()` poll | `on_text_entered` consumes each submit; the widget stays open for the next round by default. |
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
compy.input.callbacks.after_submit = function()
  compy.input.clear()
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
