---
description: How a running project's Lua environment is sandboxed — the deep-cloned env, the shared-leaf-function consequence, and the three tiers of state
status: active
audience: developer
authored: llm
reviewed: none
---

# Project sandbox environment

A project does **not** run in the raw global environment. The console controller builds a per-project
env and `setfenv`'s the project's chunks into it. Understanding *what is and isn't isolated* by that env
is load-bearing for any feature touching project lifecycle, global state, or teardown.

## How the env is built

- `ConsoleController.new` captures the file env: `local env = getfenv()` (`consoleController.lua:40`),
  and clones it: `pre_env = table.clone(env)` (`:41`).
- The project env descends from that clone (`get_pre_env_c` → `prepare_project_env`, `:514–520`); the
  project's files are loaded via `project_dofile` which does `setfenv(chunk, env)` (`:297`).
- `table.clone` (`util/table.lua:48`) is **recursive** (deep) and copies metatables, with a `seen` set
  for cycles.

**The crucial consequence.** A deep clone gives the env a `love` table with a **fresh identity**, but
its **leaf values are shared by reference** — `table.clone` returns non-tables as-is (`table.lua:50`).
So every *engine function* the clone starts with — `love.graphics.print`, `love.mouse.setVisible`,
`love.keyboard.setKeyRepeat`, `love.audio.play`, … — is the **same C function** the global `love`
holds. The *table* is sandboxed; the *functions and their side effects* are not.

This is about the functions a project **calls**, not the callbacks it **defines**. Those are the
opposite case: when a project assigns `love.draw`, `love.keypressed`, `love.textinput` and friends, it
writes into its own cloned `love`, and the framework harvests them from there
(`save_user_handlers(runner_env['love'])`, `consoleController.lua:824`) rather than letting them reach
the real global — see T1 below, and `event_dispatch_layers.md` for where a harvested callback is
re-installed. Input callbacks in particular are re-installed as *hooks* on the project route, never as
global LÖVE handlers ([`user_input.md`](user_input.md), "Dispatch chain"). Nothing in this section
weakens that: a captured callback is safe precisely *because* it never touches the shared leaf, and
a shared leaf is dangerous precisely *because* nothing captures a call to it.

## Three tiers of project state

**Leak** here means one thing: state a project changed that is **still changed after the project
stops**, so the console — or the next project — inherits it. A tier "does not leak" when the framework
either keeps the state inside the project's own env or restores it at stop; it "leaks" when the state
lives in a global subsystem nobody snapshots.

| Tier | What | Isolated / restored? |
|---|---|---|
| **T1 — callbacks** | `love.draw`, `love.update`, `love.keypressed`, `love.textinput`, `love.mouse*`… defined by the project | **Yes — framework-managed.** Set on the project's cloned `love`; harvested by `save_user_handlers(runner_env['love'])` (`consoleController.lua:824`) and wired into the real dispatch; reset to defaults on stop (`set_default_handlers` / `restore_user_handlers`, `controller.lua:826`). No leak. |
| **T2 — `compy.*`** | `compy.terminal`, `compy.audio`, `compy.graphics`, `compy.input` **(supported since 1.0.0-rc20260712)**… injected into the env (`get_compy_namespace`, `consoleController.lua:360`) | **Yes — framework wrappers.** The project calls a controlled surface; the framework owns the underlying object. No leak. |
| **T3 — raw `love.*` imperative calls** | `love.keyboard.setKeyRepeat`/`setTextInput`, `love.mouse.setRelativeMode`/`setVisible`, raw `love.audio.newSource`/`play`, cursor… called (not defined) by the project | **No.** These invoke the shared C functions → mutate **real global SDL/LÖVE subsystem state**. Nothing snapshots or restores them across run boundaries. **They leak into the IDE/console after the project exits.** |

## Why this matters

- **T1 isolation is what makes the IDE survive a project** — a project that defines `love.draw` doesn't
  permanently hijack the console, because the framework swaps handlers in/out. Any input feature that
  reroutes callbacks (e.g. the `ProjectInputController` added in 1.0.0-rc20260712) lives in this T1
  machinery.
- **T3 is the real leak surface.** A project that sets relative-mouse mode, hides the cursor, disables
  key-repeat, or leaves a sound playing leaves that state changed after exit.
  Example: `src/examples/keyboard/input.lua` *wants* to disable key-repeat for clean input but
  deliberately doesn't, **because it cannot restore it on exit** — and hand-rolls edge-tracking instead.
- **The robust fix for T3 is framework snapshot/restore across run boundaries** — extend the T1
  save/restore discipline to imperative subsystem state. This is sandbox-safe (doesn't trust the
  project to clean up), survives a crash, and is strictly better than relying on a project teardown
  hook — which is why `compy.before_exit` (below) is scoped to project-internal teardown and not
  offered as the answer to T3.

### `compy.before_exit` — the project teardown hook

> REMARK: Update 'exists, not a proposal' with concrete avaiability reference -- "since version..."
> REMARK: during session 24 we discussed a conceptual problem that before_exit() cannot guarantee a teardown if project raises before being ablt to clean up. the prose below should be updated to refkect this concern and also reference the appropriate decisions and tech debt record (which in turn could reference back here) -- and the 'proposed robust fix' in the previous paragraph is precisely a counter-measure for this failure mode -- indentified, registered, not implemented (contrary to 'before_exit' hook)

It exists and is wired; it is **not** a proposal. `compy.before_exit` is a slot on the injected
`compy` namespace, defaulting to a no-op (`consoleController.lua:697`), assignable by the project
through the namespace metatable (`:715–721`) — assign a function to it and the framework calls it
**once, first thing, when the project stops** (`ConsoleController:stop_project_run`, `:1193`), before
any handler teardown. The slot is then reset to the default (`:1200`), so the next project starts
clean and cannot inherit the previous one's teardown.

Every stop path that runs a project reaches `stop_project_run`, so the hook fires on all of them:
`Ctrl+Q` and `Ctrl+S` (`controller.lua:899`, `:903`), `Ctrl+T` into the editor (`:877`), and the
`Ctrl+Esc` / `love.quit` path (`controller.lua:751–779`, which stops the project instead of quitting
whenever one is running or the console is still interactive). The only exit that runs no project code
is quitting with **no** project running, where there is nothing to tear down.

What it is for: **project-internal** teardown — save a score, flush a memo, stop a timer. It is not a
restore mechanism for T3 global state, which the project cannot restore reliably in any case
(a crash never reaches the hook). Covered by `tests/input/input_route_lifecycle_spec.lua`
("`compy.before_exit`").

> REMARK: make pointer annotations more useful for reader, and also check their completeness/consistency and whther they are actual
## Pointers

- Input singleton namespace + lifecycle: [`user_input.md`](user_input.md).
- Project-author input usage guide: [`../../input_api.md`](../../input_api.md).
- The stop sequence `before_exit` opens: [`../decisions/input.md`](../decisions/input.md),
  Decision 11 (the route connects only while the project is actively running).
