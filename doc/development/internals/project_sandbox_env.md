---
description: How a running project's Lua environment is sandboxed — the deep-cloned env, the shared-leaf-function consequence, and the three tiers of state (managed callbacks, compy.* wrappers, leaky raw love.* globals)
status: active
audience: developer
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
So every *function* on `love` (and `love.mouse`, `love.keyboard`, `love.audio`, …) is the **same C
function** the global `love` holds. The *table* is sandboxed; the *functions and their side effects*
are not.

## Three tiers of project state

| Tier | What | Isolated / restored? |
|---|---|---|
| **T1 — callbacks** | `love.draw`, `love.update`, `love.keypressed`, `love.textinput`, `love.mouse*`… defined by the project | **Yes — framework-managed.** Set on the project's cloned `love`; harvested by `save_user_handlers(runner_env['love'])` (`consoleController.lua:824`) and wired into the real dispatch; reset to defaults on stop (`set_default_handlers` / `restore_user_handlers`, `controller.lua:826`). No leak. |
| **T2 — `compy.*`** | `compy.terminal`, `compy.audio`, `compy.graphics`, `compy.input`… injected into the env (`get_compy_namespace`, `consoleController.lua:360`) | **Yes — framework wrappers.** The project calls a controlled surface; the framework owns the underlying object. No leak. |
| **T3 — raw `love.*` imperative calls** | `love.keyboard.setKeyRepeat`/`setTextInput`, `love.mouse.setRelativeMode`/`setVisible`, raw `love.audio.newSource`/`play`, cursor… called (not defined) by the project | **No.** These invoke the shared C functions → mutate **real global SDL/LÖVE subsystem state**. Nothing snapshots or restores them across run boundaries. **They leak into the IDE/console after the project exits.** |

## Why this matters

- **T1 isolation is what makes the IDE survive a project** — a project that defines `love.draw` doesn't
  permanently hijack the console, because the framework swaps handlers in/out. Any input feature that
  reroutes callbacks (e.g. #77's `ProjectInputController`) lives in this T1 machinery.
- **T3 is the real leak surface.** A project that sets relative-mouse mode, hides the cursor, disables
  key-repeat, or leaves a sound playing leaves that state changed after exit — including after the
  `Ctrl+Esc` force-exit path (`controller.lua:672`, `love.event.quit()`), which today runs no project
  code. Example: `src/examples/keyboard/input.lua` *wants* to disable key-repeat for clean input but
  deliberately doesn't, **because it cannot restore it on exit** — and hand-rolls edge-tracking instead.
- **The robust fix for T3 is framework snapshot/restore across run boundaries** — extend the T1
  save/restore discipline to imperative subsystem state. This is sandbox-safe (doesn't trust the
  project to clean up), survives crash/force-exit, and is strictly better than a project teardown hook.
  A project `before_exit` hook (which *can* be framework-invoked at the quit sites, including
  `Ctrl+Esc`) is then needed only for **project-internal** teardown (save/memoize), not for restoring
  global state.

## Pointers

- Input singleton namespace + lifecycle: [`user_input.md`](user_input.md).
- The analysis that surfaced this model (feature #77, session 18):
  `doc/development/wip/77-new-input-api/notes/stakeholder-3-input/assessment.md` (P4).
