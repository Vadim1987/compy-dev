---
description: The two-layer love.handlers.* vs love.<event> wiring, and what becomes of a project-defined love.*
status: active
audience: developer
authored: llm
reviewed: none
---

# Event Dispatch Layers — `love.handlers.*` vs `love.<event>`

Compy mirrors stock LÖVE's own two-layer event dispatch, and the mirroring is deliberate, not
incidental. Stock LÖVE's `love.run` pumps OS events into a dispatch table `love.handlers[name]`;
the default entry LÖVE itself installs there simply forwards to the user-facing callback
`love[name]` (`love.handlers.keypressed` calls `love.keypressed`). Compy reproduces that same
split on purpose — see the comment at `src/controller/controller.lua:974-982`.

This doc exists because the two layers are easy to conflate from the code alone — both are
LÖVE's own "handlers", one the pump table and one its per-event occupant, and `controller.lua`
uses the word for both within a few hundred lines. Read this before trying to reverse-engineer
the wiring cold. For the *why* of the routing this wiring carries (route-centric dispatch, the
default/restore route, etc.), see [`../decisions/input.md`](../decisions/input.md), in particular
its ["Vocabulary — hook, callback, handler"](../decisions/input.md#vocabulary--hook-callback-handler)
section; this doc's closing section covers what becomes of a project's own `love.*`.

---

## Layer 1 — `love.handlers.*`, the raw event-pump table

Installed once by `Controller.setup_callback_handlers(CC)` (`src/controller/controller.lua:864`).
The function body grabs the table LÖVE itself exposes — `local handlers = love.handlers`
(`controller.lua:873`) — and assigns each event onto it, e.g.
`handlers.keypressed = function(k, sc, isr) ... end` (`controller.lua:876`).

Each raw handler does exactly two jobs, in order:

1. **Route-independent framework concerns** that must run no matter which route is currently
   active: the global power hotkeys — Ctrl+T quickswitch (`controller.lua:879-900`), Ctrl+Alt+R
   restart (`:928-932`), Ctrl+Alt+P / F10 profiler toggle (`:933-955`), Ctrl+Esc quit (on the
   *release* side, `handlers.keyreleased`, `:997-998`) — plus `Controller.keys_pressed`
   bookkeeping (`:877`, and the mirrored removal in `handlers.keyreleased` at `:995`).
2. **Forward to the active route.** Once the framework-level concerns have run, the raw handler
   defers unconditionally to whatever route currently owns the corresponding `love.<event>`:
   `if love.keypressed then return love.keypressed(k, sc, isr) end` (`controller.lua:983-985`).

`setup_callback_handlers` is called **exactly once, at boot** (`src/main.lua:389`) and never
re-invoked or swapped afterward — the fixed, permanent event pump for the process's lifetime.
Tests reproduce this startup wiring directly: `tests/input/keys_pressed_spec.lua` and
`tests/helpers/input_session.lua`.

---

## Layer 2 — `love.<event>`, the active route's handler

This is the layer that actually changes as the app moves between console, editor, and a running
project. Each `Controller.set_love_<event>(CC[, CV])` installer assigns the corresponding
`love.<event>` directly — e.g. `Controller.set_love_keypressed(CC)` (`controller.lua:448`) ends
with `love.keypressed = keypressed` (`controller.lua:491`), where the local `keypressed` closure
is the console/editor route's default handler for that event.

`Controller.set_default_handlers(CC, CV)` (`controller.lua:809`) is the bulk operation that makes
the console the owner of every `love.<event>` at once — "restore to the default route," in the
vocabulary of [`../decisions/input.md`](../decisions/input.md), Decision 1. It does three things,
in order:

1. Calls `Controller.project_input:deactivate()` (`controller.lua:817`) — drops the project route
   first, so the reinstall below is never racing an already-live project occupant.
2. Calls the ten per-event `set_love_*` installers (`controller.lua:822-834`) — keypressed,
   keyreleased, textinput, mousemoved, mousepressed, mousereleased, wheelmoved, touchpressed,
   touchreleased, touchmoved — each one repointing its `love.<event>` at the console.
3. Resets the user-handler presence flags (`user_update`/`user_draw`/`user_pointer = false`,
   `controller.lua:854`, `:856-857`) and installs the console's own `update`/`draw`/`quit`
   (`:855`, `:858-860`), recording the console's own handlers into `Controller._defaults`
   (`:859`, and per-installer at e.g. `:490`).

`set_default_handlers` is called at boot right after Layer 1 is installed —
`src/main.lua:389-390`, `setup_callback_handlers` then `set_default_handlers` back to back — and
again on every project teardown: `src/controller/consoleController.lua:1033` and the
`stop_project_run` call at `:1130`.

During a project **run**, the project route takes `love.keypressed` (and the other event handlers)
away from the console instead, via `occupy_keyboard` (`controller.lua:234-297`).
`set_default_handlers` is what takes it back on stop — it is the console's own restore operation,
not a general-purpose "reset everything" call. The `controller.lua:974-982` comment states this
explicitly at the Layer-1 forwarding site: *"`love.keypressed` below holds the active route's
handler — console via `set_love_keypressed`, project via `occupy_keyboard`."*

---

## The difference in one line

`setup_callback_handlers` builds the **fixed pump** — Layer 1, `love.handlers.*` — which always
runs the global shortcuts first, then forwards; it is set once at boot and never swapped again.
`set_default_handlers` (re)installs **Layer 2**, `love.<event>` — the layer routes actually swap
between console, editor, and a running project — and its specific job each time it runs is "reset
every `love.<event>` back to the console." These are not two ways of doing the same thing: one is
permanent plumbing, the other is a route-switch operation invoked repeatedly over the app's
lifetime.

---
## What becomes of a project-defined `love.*`

`setup_callback_handlers`'s "callback" / "handlers" wording is **LÖVE's own**: the function
literally sets up `love.handlers`, which is what LÖVE calls that table. There is no second,
Compy-specific sense of *handler* to collide with it — the input API's vocabulary
([`../decisions/input.md`](../decisions/input.md#vocabulary--hook-callback-handler)) names two
> REMARK/nitpick -- project vocabulary introduces *three* terms (also a 'shortcut') -- maybe its worth mentioning here too
*other* things, **hook** and **callback**, and leaves "handler" to LÖVE.

What does need saying is what happens to a project's own `love.*` functions, because a project
author writing them believes they are installing handlers:

> REMARK: this needs actualization, because the routing was recently unified and there's no more artificial divergence between keyboard/pointer?
- **keyboard and text** (`keypressed`, `keyreleased`, `textinput`) — captured from the project's
  sandboxed `love` table and **seeded as `compy.input.hooks[event]`** (Decision 10), once, at
  activation. They run in hook position inside the route's walk, with hook semantics: a truthy
  return consumes. They are never installed as `love.<event>`; the route owns that. Writing
  `compy.input.hooks.textinput = f` directly is the same thing said plainly, and is the
  encouraged form.
- **pointer** (`mousepressed`, `mousemoved`, …) — installed as the **actual** `love.<event>`
  handlers (`hook_pointer`), error-wrapped, return value discarded. Here "handler" keeps its
  literal meaning and nothing is demoted.

So the two channels answer the question differently, and that asymmetry is carried in
[`../technical_debt/input.md`](../technical_debt/input.md) ("Pointer delivery is an unstructured
broadcast, not a chain"; Standing: "Future input unification") rather than resolved here.
