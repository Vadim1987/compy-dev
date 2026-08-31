# Session 62 — environment-lifecycle code map

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

Mechanical, read-only evidence gathering. No design proposals, no
judgments. Every claim below is either a direct code citation
(`file:line`) or an empirically observed result from a throwaway
`busted` probe run against the real `ConsoleController` (never
committed, never touched `src/` — see "Method" below).

## Method

Static reading of the five files named in the prompt, cross-checked
with `grep` and the `lua-lsp` MCP server (`references` on
`close_project`, `stop_project_run`, `_reset_executor_env` — all three
came back with exactly the call sites `grep` had already found inside
`src/`; the only extra hit was a pre-existing instrumentation probe at
`doc/development/wip/77-new-input-api/validation/notes/ARC-01-01-probes/harmony-sapper-lifetime.lua`,
which monkey-patches the same three methods for logging and is not
part of the production call graph).

Several claims below turn on **runtime metatable/`pairs` behaviour**
that cannot be settled by reading alone, so they were checked by
running small standalone `busted` specs against the real
`ConsoleController` (via the existing `tests/helpers/input_fixture.lua`
fixture). Those spec files were written to
`tests/helpers/zz_scratch_probe_spec.lua`, run, and then **deleted**
immediately after — nothing was committed and no file under `tests/`
or `src/` was left modified. Reported interpreter: **LuaJIT 2.1**
(`/usr/bin/luajit`, invoked by the container's `busted`), not PUC Lua.
Per project memory, the owner's own machine runs PUC Lua 5.1 — the
`pairs`/`next`-ignore-metatables and `__metatable`-string semantics
relied on below are identical in both (`__pairs` does not exist in
either), but this was not verified on PUC Lua directly, only on
LuaJIT.

---

## 1. The environments

Four environment tables exist, plus one field that is easy to mistake
for a fifth ("runner env") but is not one.

| Name | Built where | Cloned from | (Re)built when | Is it `_G`? |
|---|---|---|---|---|
| `main_env` | `consoleController.lua:40` (`local env = getfenv()`), stored at `:60` | nothing — it *is* the caller's env | Never rebuilt; mutated in place forever by `prepare_env` (`:970-1107`) | **Yes.** Empirically confirmed: `F.cc.main_env == _G` is `true`. `ConsoleController.new` is called once, from `main.lua:373`, and nothing in this codebase `setfenv`s the console's own chunks, so `getfenv()` there returns the real global table. |
| `pre_env` | `consoleController.lua:41` (`table.clone(env)`) | `main_env`, but the clone happens **before** `prepare_env` mutates `main_env` (`ConsoleController.new` calls `table.clone` at line 41, then `prepare_env` at line 79) | Once, at construction | No — separate table, deep-cloned |
| `base_env` | `consoleController.lua:1217` (`table.clone(project_env)`, the local variable built in `prepare_project_env`), stored via `_set_base_env` at `:1219`/`:1329-1332` | the local `project_env` variable inside `prepare_project_env` (`:1117-1218`), which itself starts from `cc:get_pre_env_c()` = `table.clone(self.pre_env)` (`:1292-1294`) | **Once**, at `ConsoleController.new` time (`prepare_project_env` is called only from the constructor, line 80) — **not** "at project-open time" | No |
| `project_env` (initial) | `consoleController.lua:1218` (`table.clone(project_env-local)`), stored via `_set_project_env` at `:1220`/`:1324-1326` | the **same** `project_env`-local as `base_env` — `base_env` and `project_env` are **siblings**, not parent/child, at construction time | Once at construction, then **replaced wholesale** by `_reset_executor_env` (`:1277-1279`, `table.clone(self.base_env)`) — called only from `close_project` (`:1428`) | No |
| "runner env" | n/a | n/a | n/a | **Does not exist as a separate table.** `run_user_code`'s local `env` (`:111,116`) and `ConsoleController:run_project`'s local `runner_env` (`:320`) are both just local aliases for `get_base_env()`/`get_project_env()` — see Q4. |

Because `main_env` **is** `_G`, every assignment in `prepare_env`
(`prepared.dofile = ...` at `:991`, `prepared.require = ...` at
`:989`, `prepared.run = ...` at `:1094`, `prepared.quit = ...` at
`:1104`, etc.) is a mutation of the **real global table**, not a
separate sandbox. `_G.o_dofile = _G.dofile` (`:390`) and
`_G.o_loadfile = _G.loadfile` (`:283`) are saved specifically because
the very next statements overwrite the real globals of the same name
(for `dofile`; `loadfile` is not reassigned globally, only
`main_env.loadfile`/`project_env.loadfile` fields are set, at `:1064`
and `:1151`, which for `main_env` is the same thing since
`main_env == _G`).

### Which table a REPL line compiles into, per app state

`ConsoleController:evaluate_input` (`:1234-1275`) picks the env with
its own inline check, **independent of** `get_effective_env()`
(`:1311-1321`, used elsewhere — see the discrepancy noted at the end
of this section):

```
run_env = (app_state == 'inspect') and get_project_env() or get_console_env()
```
(`:1250-1255`)

| App state | REPL compiles into | Why |
|---|---|---|
| `ready` | `main_env` (`get_console_env()`, `:1297-1299`) | not `'inspect'`, falls to console env |
| `project_open` | `main_env` | same — `evaluate_input`'s check is `== 'inspect'` only, `project_open` is not special-cased |
| `running` | `main_env` (**if reached at all**) | Same fallback; but `ConsoleController:keypressed` is not normally invoked here — the project route owns `love.keypressed` while `running` (Decision 11, `controller.lua:211-241` `occupy_input`), so in practice the console's REPL is unreachable during `running` |
| `inspect` | `project_env` (`get_project_env()`, `:1302-1304`) | explicit branch |
| `editor` | **REPL not entered.** `ConsoleController:keypressed` (`:1559-1629`) checks `app_state == 'editor'` first (`:1577`) and dispatches to `self.editor:keypressed(k)` instead of ever calling `evaluate_input`. `editorController.lua` was out of scope for this pass, so what env (if any) the editor itself compiles saved buffers into is **not established here**. |

**Discrepancy worth flagging (fact, not a judgment):** three different
functions pick "the current env" by three different rules:
- `evaluate_input`'s inline lambda (`:1250-1255`): `'inspect'` only.
- `get_effective_env()` (`:1311-1321`): `'running'` **or** `'inspect'`.
- `run_user_code` (`:109-133`): ignores `app_state` entirely, branches
  on whether a `project_path` argument was passed.
- `Project:get_loader`'s closure (`consoleController.lua:1380-1382`,
  `project.lua:118-134`, used for every project `require`) uses
  `get_effective_env()`, so it resolves `'running'` and `'inspect'`
  identically, while a REPL line typed during a (hypothetically
  reachable) `'running' `state would not.

---

## 2. `table.clone` semantics (`src/util/table.lua:48-65`)

**Deep, recursive, reference-cycle-safe, metatable-preserving, and
non-tables (including functions and userdata) pass through by
reference.** One paragraph, cited: `table.clone(obj, seen, omit)`
returns `obj` unchanged when `type(obj) ~= 'table'` (`:50`) — this is
the load-bearing line: functions and userdata are never copied, only
tables are. For a table it walks `pairs(obj)` (`:58`) recursively
cloning both keys and values, consults a `seen` map keyed by object
identity to short-circuit cycles (`:51,55,57`), optionally omits
named top-level keys via `omit` (`:59-60`, only at the top level —
recursion doesn't propagate `omit`), and finishes with
`setmetatable(res, getmetatable(obj))` (`:64`), so a cloned table
carries the **same metatable object** as its source (not a copy of
it) — this is what makes `base_env.compy` and `project_env.compy`
share one metatable (and hence one `before_exit` closure slot and one
`compy.input` surface object) even though they are separate table
objects — see Q7.

**Interaction with `table.protect` (empirically significant — see
Q1/Q5/Q8).** `table.protect(t)` (`table.lua:72-99`) does not mutate
`t`; it builds a **new** proxy table with `__index`/`__newindex`
(and a defended `__metatable = 'no-no'`) and returns `proxy, orig`. If
that return value is discarded (as it is at the one call site,
`consoleController.lua:1331-1332`), the original table is completely
unaffected — `pairs`/`next`/writes on it behave exactly as if
`table.protect` had never been called, because Lua's `pairs`/`next`
do not consult `__index`/`__newindex` at all (in either PUC 5.1 or
LuaJIT), and only a table that metatable actually protects would show
different behavior.

---

## 3. `dofile` from the console — every entry point

| Entry point | Where | `env` argument | `setfenv`'d into | Globals visible at REPL afterward | What's restored |
|---|---|---|---|---|---|
| `dofile(name)` typed at console REPL | `prepared.dofile`, `consoleController.lua:991-995`, delegates to `project_dofile(cc, name)` — **no 3rd arg** | `project_dofile`'s `env` param is `nil` | **Not `setfenv`'d at all** — `project_dofile` (`:394-409`) only calls `setfenv(chunk, env)` if `env` is truthy (`:401-403`); the chunk keeps whatever `loadstring`'s implicit default env is, which is the calling thread's global env, i.e. real `_G` | Since `main_env == _G`, effectively visible in `main_env` too, but incidentally (no explicit wiring makes this true) | n/a — nothing was swapped |
| `dofile(name)` called from **project code** | `project_env.dofile`, `:1122-1124` | `cc:get_project_env()`, resolved **dynamically at call time** (not the env captured when `prepare_project_env` ran) | `project_env` (whatever it currently is) | Yes — assigned globals land in `project_env`, visible to later project code and to the REPL while `inspect` | n/a |
| `require(name)` (console or project) | `prepared.require`/`project_env.require`, both `project_require` (`:379-388`) | n/a — delegates to the real `o_require` (`:375-376`, saved before override) | Not here — see next row | — | — |
| `package.loaders` project entry | `Project:get_loader` (`project.lua:118-134`), registered in `open_project` (`consoleController.lua:1379-1388`) prepended with `table.insert(package.loaders, 1, project_loader)` | `get_env()` closure = `function() return self:get_effective_env() end` (`:1380-1382`), evaluated **fresh on every module load** | `setfenv(f, get_env())` (`project.lua:127`) → whichever of `main_env`/`project_env` `get_effective_env()` currently names (`'running'`/`'inspect'` → project_env, else console env) | Yes, into whichever env was chosen | Loader stored in `self.loaders[name]` (`:1383`), removed from `package.loaders` on `close_project` (`:1424-1427`) |
| `codeload`/direct `setfenv` in `Project:run` | `project.lua:373-394`, `codeload(code, env, ProjectService.MAIN)` | `runner_env` = caller-supplied (`consoleController.lua:320-321`, always `get_project_env()`) | `setfenv` happens **inside `codeload`** (`util/lua.lua:17-28`, line 26, only if `env` truthy) | Yes, into `project_env` | — |

No `codeload`/`run_user_code`/`require` path was found that installs
into a table other than `main_env`/`base_env`/`project_env` — the
enumeration in Q1 is exhaustive for these five files.

---

## 4. `run()` / `run("name")` — the full call path

Two different symbols share the name `run`, resolving to different
behavior depending which env the REPL/project is compiling into
(see Q1's table):

- **`main_env.run`** = `main_env.run_project` (`:1094`, aliasing
  `prepared.run_project` at `:1085-1087`) → `ConsoleController:run_project(name)`
  (`:302-373`).
- **`project_env.run`** (`:1162-1168`) means something else entirely:
  only acts if `app_state == 'inspect'`, and then calls
  `cc:stop_project_run()` then `cc:run_project()` with **no name**
  (restart of the currently-open project, not "run a named project").

Full path for `run_project(name)`:

1. `ConsoleController:run_project` (`:302-373`) — refuses if already
   `'inspect'`/`'running'` (`:303-309`); opens the project via
   `self:open_project` if not already current (`:316`).
2. `runner_env = self:get_project_env()` (`:320`) — this is the
   "runner env" the prompt asks about: **it is `project_env` itself**,
   just accessed through a local alias; nothing new is built here.
3. `P:run(name, runner_env)` (`project.lua:373-394`) reads
   `main.lua` off disk/VFS and calls
   `codeload(code, env, ProjectService.MAIN)`.
4. `codeload` (`util/lua.lua:17-28`) does
   `loadstring(code, '@main.lua')` then `setfenv(f, env)` — the chunk
   is now bound to `project_env`.
5. `love.state.app_state = 'running'` (`:325`), `build_input_widget`
   (`:332`, builds a **new** `UserInputController` per run — see Q6).
6. `run_user_code(f, self, path)` (`:109-133`, called at `:333`) —
   since `project_path` (`path`) is truthy, `env = cc:get_project_env()`
   (`:116`, re-fetched, same table as step 2 unless something reset it
   between steps 2 and 6, which nothing does), `pcall(f)` runs the
   chunk, and on success
   `cc.main_ctrl.set_user_handlers(env['love'], cc)` (`:124`) harvests
   callbacks — see Q6.

**What can reach a fresh run from before it, empirically and
statically confirmed:**
- **Leftover globals in `project_env`**: yes, if the project was not
  *closed* since the last run — `project_env` is the **same table
  object** across repeated `run_project`/`stop_project_run` cycles
  (only `close_project` → `_reset_executor_env` replaces it). Verified
  by probe: a chunk doing `score = 99` leaves `project_env.score == 99`
  visible after `stop_project_run`, and still visible after a second
  `run_project` on the same env, until an actual `close_project`
  resets it (see Q5/Q7).
- **`package.loaded`**: `evacuate_required` (`:1443-1457`, called from
  `stop_project_run` at `:1460`) clears entries only for `.lua` files
  in the project's **top-level directory listing**
  (`open:contents()` → `FS.dir` → `filesystem.lua:86-98`'s
  `getDirectoryItemsInfo`, which calls
  `love.filesystem.getDirectoryItems(path)` **non-recursively**,
  `filesystem.lua:88`). A module `require`d from a **subdirectory**
  (`require('sub.helpers')`) is never named by this loop and its
  `package.loaded` entry survives indefinitely across runs and even
  across `close_project`.
- **Custom loader / `package.loaders`**: removed on `close_project`
  only (`:1424-1427`), **not** on `stop_project_run` — so a stopped
  (but not closed) project's loader is still installed and a bare
  `require('x')` from the console (state `project_open`) would still
  resolve through it if `get_effective_env()` names the console env
  (it does, for `project_open`).
- **`compy` namespace / `love` table**: see Q7.

---

## 5. Stop / quit / close / restart / reset / crash — what happens

| Action | env tables | `package.loaded` | interaction callbacks | other |
|---|---|---|---|---|
| **`stop_project_run()`** (`:1459-1474`) | `project_env` **untouched** — same table, same accumulated globals | `evacuate_required()` (top-level `.lua` only, see Q4) | `set_default_handlers` (`:1463`, `controller.lua:742-787`) restores console's own `love.update`/`draw`/`keypressed`/etc; `clear_user_handlers` (`:1471`, `controller.lua:1074-1084`) wipes `Controller._userhandlers` and the project's `compy.input.shortcuts`/`hooks` (`reset_compy_input`, `controller.lua:319-330`) | `framework_before_exit(compy)` (`:1462`) fires the project's `compy.before_exit` **once**, then resets the slot to `default_before_exit` (`consoleController.lua:172`); widget destroyed (`destroy_input_widget`, `:1468`); `app_state → 'project_open'` (`:1473`) |
| **`suspend_run(msg)`** (`:1354-1360`) | untouched | untouched | **not yet** — only requests a snapshot; `app_state → 'snapshot'` | actual handler save happens one tick later in `suspend()` |
| **`suspend()`** (`:1334-1351`, called from the `love.update` snapshot branch, `controller.lua:593-599`) | untouched | untouched | `save_user_handlers(runner_env['love'])` (`:1349`, `controller.lua:1050-1066`) copies the project's still-installed handlers into `Controller._userhandlers` (**not** cleared — unlike `stop_project_run`); then `set_default_handlers` (`:1350`) installs console defaults | `app_state → 'inspect'` (`:1340`) |
| **`continue()`** (`project_env.continue`, `:1170-1178`) | untouched | untouched | `restore_user_handlers(cc)` → `set_handlers(Controller._userhandlers, CC)` (`controller.lua:1069-1071`) re-**occupies** the project route with the saved handlers | only reachable from `'inspect'`; `app_state → 'running'` (`:1173`) |
| **`close_project()`** (`:1417-1435`) | `_reset_executor_env()` (`:1428`) → `project_env := table.clone(self.base_env)`, a **fresh, working clone** (verified empirically — API functions like `.run` are present post-reset) | **not touched here** — only `stop_project_run`'s `evacuate_required` clears `package.loaded`; a `close_project` reached **without** a prior `stop_project_run` leaves cached project modules in `package.loaded` | Only the **widget** is torn down (`destroy_input_widget`, `:1418`) — no handler save/restore/clear at all | `P:close()` (`project.lua:312-315`, sets `P.current = nil`); project's custom loader removed from `package.loaders` (`:1424-1427`); `app_state → 'ready'` (`:1431`). **Confirmed by the code's own comment (`:1401-1416`) and matched empirically: `close_project` bypasses the rest of the exit path** — it does not call `stop_project_run`, so if it's reached while a project is still `running`/`inspect` (e.g. via the bare `close_project()` exposed directly in `project_env`, `:1180-1182`, with **no `app_state` guard**), `compy.before_exit` never fires and handlers are never released through the normal channel. |
| **`quit_project()`** (`:1476-1481`) | `stop_project_run()` then `close_project()` — so this path **does** get both the handler teardown/hook-fire **and** the env reset | both `evacuate_required` (via stop) and the loader removal (via close) run | full teardown (stop's handler clear + close's widget destroy) | `self.model.output:reset()`, `self.input:reset()` (`:1479-1480`) |
| **`restart()`** (`:1286-1289`) | `stop_project_run()` + `run_project()` — **does not go through `close_project`**, so `project_env` is **not** reset; a restarted project resumes with the previous run's leftover globals still present (only `package.loaded`'s top-level entries were evicted, so `require`s re-execute, but plain global assignments persist) | evicted (top-level only, via stop) | torn down then re-harvested on the new run | `app_state`: `running`→(stop)→`project_open`→(run)→`running` |
| **`_reset_executor_env()`** (`:1277-1279`) | `project_env := table.clone(base_env)` | not touched | not touched | called only from `close_project` |
| **`_set_base_env(t)`** (`:1329-1332`) | `self.base_env = t; table.protect(t)` — **the `table.protect` return value is discarded**, so `base_env` is **not actually write-protected** at runtime (see Q2/Q8) | n/a | n/a | called once, from `prepare_project_env` (`:1219`) |
| **`evacuate_required()`** (`:1443-1457`) | n/a | clears `package.loaded[modname]` for every top-level `.lua` file in the **currently open** project | n/a | no-op if no project is open (`:1445`) |

**Crash path (top-level project code raises).** `run_project`
(`:333-353`) checks `rok` from `run_user_code`; on failure it does
**not** call `stop_project_run` — it directly calls
`self.main_ctrl.release_keyboard_route(self)` (`:341`,
`controller.lua:725-738`), `destroy_input_widget()` (`:342`),
`self.main_ctrl.clear_user_handlers(self)` (`:349`), and manually
resets `compy.before_exit` **without firing it**
(`:350-351`, `self:get_project_env().compy.before_exit = default_before_exit`
— comment at `:344-348` states this is deliberate: "before_exit is
uninstalled but NOT fired"). `app_state → 'project_open'` (`:352`).
So the crash path reaches: widget teardown, route release, handler
clear — but **not** `evacuate_required` (`package.loaded` keeps the
crashed project's top-level modules cached) and **not**
`framework_before_exit`'s actual invocation of the project's hook
(only the slot reset runs).

A **non-top-level** raise (inside a `love.update`/`love.draw`
callback, once the run is connected) is caught by `wrap`/`xpcall`
(`controller.lua:138-146`) via `user_error_handler` (`:102-109`),
which calls `CC:suspend_run(user_msg)` — i.e. this crash path is
routed through the **normal suspend→inspect** machinery, not through
`run_project`'s failed-run branch. `project_env` and `package.loaded`
are untouched by this route until the user explicitly stops/closes.

---

## 6. The interaction callbacks specifically

- **Harvest**: `project_handler(userlove, key)` (`controller.lua:188-192`)
  reads `userlove[key]` off the project's **own sandboxed `love`
  table** (`env['love']`, i.e. `project_env.love` — a deep clone, see
  Q7), filtering out anything still equal to the framework's own
  default (`Controller._defaults[key]`). `project_handlers` (`:202-208`)
  does this for every channel in `_bindable` (`:92-98`, keyboard +
  pointer + derived clicks). `hook_update`/`hook_draw`
  (`:266-287`) separately harvest `userlove.update`/`userlove.draw`.
- **Called from**: `set_handlers` (`:293-298`, exported as
  `Controller.set_user_handlers`, `:1036`), invoked once per run at
  `consoleController.lua:124` (`cc.main_ctrl.set_user_handlers(env['love'], cc)`,
  inside `run_user_code`, only after the top-level chunk returns
  successfully).
- **Stored**: keyboard/text handlers become the live `love.keypressed`
  etc. via `occupy_input` (`:228-242`, installs
  `love[k] = with_canvas_and_errors(CC, ...)` wrappers around
  `Controller.project_input`, an instance of `ProjectInputController`);
  `love.update`'s user half is stored as
  `Controller._userhandlers.update` (`:270`); `love.draw`'s user half
  is installed directly as the new `love.draw` (`:280-285`), wrapped to
  also call `View.drawFPS()`.
- **Re-installed** on resume: `restore_user_handlers(CC)`
  (`controller.lua:1069-1071`) calls `set_handlers(Controller._userhandlers, CC)`
  again — i.e. it re-runs the **same harvest/occupy logic** over the
  table `save_user_handlers` populated (`:1050-1066`), invoked from
  `project_env.continue` (`consoleController.lua:1174`).
- **Reset to the console's own**: `set_default_handlers(CC, CV)`
  (`controller.lua:742-787`) — deactivates `Controller.project_input`
  (`:750`), reinstalls `love.keypressed`/console channels
  (`:753-756`), resets the `user_update`/`user_draw`/`user_pointer`
  flags to `false` (`:777-780`), and reinstalls console
  `love.update`/`love.draw`/`love.quit` (`:778,784,786`). Called from
  `suspend()` (`:1350`) and `stop_project_run()` (`:1463`), and once at
  boot from `main.lua:377`.
- **`clear_user_handlers(CC)`** (`controller.lua:1074-1084`) is a
  separate, narrower reset: it empties `Controller._userhandlers`
  (the *saved copy*, not the live installation) and wipes the
  project's `compy.input.shortcuts`/`hooks` via `reset_compy_input`
  (`:319-330`) — called from the crash path (`:349`) and from
  `stop_project_run` (`:1471`).

---

## 7. What survives a run today

Verified by direct reading plus the empirical probes described under
"Method".

| Thing | Survives a `stop_project_run`? | Survives a `close_project`/`quit_project`? | Evidence |
|---|---|---|---|
| Plain globals the project assigned (e.g. `score = 99`) | **Yes** — `project_env` is not touched by stop | **No** — `_reset_executor_env` replaces `project_env` wholesale | Probe: `score` field present after `stop_project_run`, `nil` in the new `project_env` after a real `close_project` (with `P.current` genuinely open at close time) |
| Modules `require`d from the project's **top-level** directory | Cleared from `package.loaded` by `evacuate_required` | Cleared (same mechanism, if `stop_project_run` ran first) | `consoleController.lua:1443-1457`, `filesystem.lua:86-98` |
| Modules `require`d from a **subdirectory** | **Not cleared** — `evacuate_required`'s directory listing is non-recursive | **Not cleared**, ever, by any code path in these five files | `filesystem.lua:88` (`LFS.getDirectoryItems`, no recursion) |
| `compy.before_exit` hook | Explicitly reset to `default_before_exit` **after firing** (`consoleController.lua:172`) | **Only if `stop_project_run` actually ran** — a `close_project` that bypasses it (see Q5) does not touch the slot, and the slot is a **closure upvalue shared by every env clone with the same metatable** (verified: setting it via `project_env.compy.before_exit = fn` makes `base_env.compy.before_exit == fn` **and** it is still `fn` on the fresh `project_env` produced by `_reset_executor_env`, because `table.clone` reuses the source's metatable object, `util/table.lua:64`) | `consoleController.lua:928-968` (`get_compy_namespace`'s `before_exit_slot` upvalue), comment at `:934-939` names this as unsettled tech debt |
| `compy.input` (shortcuts/hooks/callbacks surface) | Its **shortcuts/hooks tables are wiped in place** by `reset_compy_input` (`controller.lua:319-330`), called from `clear_user_handlers` — but the **surface object itself is the same table** across the whole app lifetime (built once per `get_compy_namespace` call, shared by `base_env`/`project_env` via the shared metatable, confirmed empirically: `base_env.compy.input == project_env.compy.input`) | Same object persists; only its `shortcuts`/`hooks` contents are cleared when `clear_user_handlers` actually runs | `consoleController.lua:885-923`, `controller.lua:311-330` |
| Project's `love` subsystem state (cursor, key-repeat, relative mouse, actual audio) | **Yes, and permanently** — this is documented as T3 in `project_sandbox_env.md` and independently confirmed here: `project_env.love` (and `base_env.love`) is a **one-time deep clone of the real `love` table taken once at `ConsoleController.new`** (never rebuilt per run — same table survives every run, stop, and reset, since it lives inside `base_env`/`project_env`'s ancestry which only get re-cloned from each other, never re-sourced from the live `love`). Its **leaf functions are the same C functions** as the real `love` (functions aren't cloned, `table.lua:50`), so calls a project makes through its own `love.keyboard.setKeyRepeat()` etc. mutate the **real, shared** LÖVE/SDL subsystem state, and nothing in these five files snapshots or restores it | Same — no code path here touches this | `consoleController.lua:40-41` (the one-time clone), empirically: `project_env.love ~= love` (different table) but `project_env.love.state.app_state == 'ready'` forever (frozen at the value it had when `ConsoleController.new` ran, long before any project existed) |
| `project_env` itself as an object identity | **Same table** across runs until closed | **Different table** after close (fresh clone from `base_env`) | Probe: `project_env == same table object as before stop?` → `true`; after a real close, a brand-new table with `.run` etc. present |
| `package.loaders` project entry | **Stays installed** (only removed on close) | Removed | `consoleController.lua:1424-1427` |

---

## 8. Contradicts the docs

- **`console.md:44`**: *"`base_env` — a frozen snapshot of
  `project_env` at project-open time. Protected with `table.protect()`
  (writes are blocked)."* — **Two disagreements.** (a) It is built at
  `ConsoleController.new` (construction) time, not "project-open
  time" — `open_project` (`:1365-1399`) never calls
  `_set_base_env`/`prepare_project_env`. (b) It is **not actually
  protected** — `_set_base_env` (`:1329-1332`) calls
  `table.protect(t)` but discards the returned proxy, so `self.base_env`
  is the plain, mutable original table. Verified empirically: writing
  directly and iterating `pairs(base_env)` over the real fixture's
  `base_env` returns all 134 keys with no interception, and
  `getmetatable(base_env)` is `nil` (a genuinely protected proxy would
  show `0` keys via `pairs` and a `'no-no'` string from
  `getmetatable`, per `table.lua:96`).
- **`console.md:46`**: *"`project_env` — ... Started as a clone of
  `base_env`."* — True **after** the first `_reset_executor_env`, but
  the **initial** `project_env` (built at construction, before any
  reset) is a **sibling** clone of the same intermediate local table
  `base_env` was cloned from (`:1217-1218`), not a clone of
  `base_env` itself. Confirmed empirically:
  `base_env.compy == project_env.compy` is `false` at construction.
- **`console.md`** line-number citations throughout ("`prepare_env`
  and `prepare_project_env` (consoleController.lua:341 and 482)",
  "`open_project(name)` (consoleController.lua:782)",
  "`run_project(name)`: (line 230)", "`evacuate_required()` (line
  844)") are **all stale** against the current file — the real lines
  today are `970`/`1111`, `1365`, `302`, and `1443` respectively. This
  matches the prompt's warning that citations here have drifted; not
  re-verified exhaustively beyond these examples.
- **`console.md:91`**: *"`stop_project_run()`: ... The project's global
  state persists in `project_env` (can be inspected at the REPL)."* —
  **Matches code and the empirical probe** (`score` survived a stop).
- **`project_sandbox_env.md:73-79`**, on `compy.before_exit`: *"The
  slot is then reset to the default in the same function, so the next
  project starts clean and cannot inherit the previous one's
  teardown."* This is true for the **normal stop path**
  (`stop_project_run` → `framework_before_exit`), but the doc does not
  mention (and its own cross-reference to
  `technical_debt/input.md`'s crash-path note only covers the raise
  case) that the **same gap exists for `close_project`**, which is
  reachable directly from project code (`project_env.close_project`,
  `:1180-1182`, no `app_state` guard) and bypasses
  `stop_project_run`/`framework_before_exit` entirely (confirmed by
  the code's own comment at `:1401-1416` and empirically — see Q5).
  A project could set `compy.before_exit` and then call the exposed
  `close_project()` itself, in which case the hook slot is left
  exactly as-is (not fired, not reset) and — because the slot is a
  shared closure upvalue (Q7) — the **next** project run, whose
  `project_env` was freshly reset by `_reset_executor_env`, would
  still see the previous project's `before_exit` function.
- **`project_sandbox_env.md:19-20`** cites `get_pre_env_c` →
  `prepare_project_env`, `:514–520`, and `project_dofile` doing
  `setfenv(chunk, env)` at `:297` — current lines are `1292-1294` and
  `402` respectively; another drifted-citation instance, noted per the
  prompt's expectation rather than exhaustively chased further.
- **`project_sandbox_env.md`'s three-tier table (T1/T2/T3) itself
  checks out against code** for T1 (harvested/restored via
  `save_user_handlers`/`restore_user_handlers`/`set_default_handlers`,
  Q6) and T3 (the shared-`love`-leaf-functions mechanism, Q7);
  nothing found here contradicts those two rows.

---

## Uncertain / could not determine

- **Editor state's own code-execution env.** The prompt lists `editor`
  among the states whose REPL-compile-target was asked about, but
  `evaluate_input`/`codeload` are never reached in that state (input
  is diverted to `self.editor:keypressed`, `consoleController.lua:1577-1578`).
  What environment (if any) `editorController.lua`'s own save/execute
  path uses was **not investigated** — that file was outside the five
  named in the prompt.
- **PUC Lua vs LuaJIT parity for the metatable/`pairs` findings.** All
  dynamic probes ran on the container's LuaJIT 2.1. The semantics
  relied on (`pairs`/`next` ignoring metamethods, `__metatable`
  shadowing `getmetatable`) are standard Lua 5.1 semantics present in
  both interpreters, but this was not independently confirmed on PUC
  Lua, which per project memory is what the owner actually runs.
- **Whether `open_project`'s unconditional `close_project()` call
  (`:1373`) can ever fire while `app_state == 'running'`.** Reasoned
  from Decision 11 (console loses keyboard ownership during `running`,
  so the REPL command that reaches `open_project` shouldn't be
  reachable then) but not exercised by a probe; stated as inference,
  not verified fact.
- **Whether any code path outside these five files (e.g. Ctrl+T
  quickswitch into the editor, `controller.lua:801-816`
  `reserved_quickswitch`) reaches `close_project` or
  `_reset_executor_env` through a route not covered above.** Grep and
  LSP `references` for `close_project`/`stop_project_run`/
  `_reset_executor_env` found no additional call sites in `src/`
  beyond the ones cited, but `reserved_quickswitch` calls
  `CC:stop_project_run()` directly (not `close_project`), so it's
  already covered by the Q5 table; flagged here only for completeness
  since quickswitch itself wasn't traced end-to-end into
  `editorController.lua`.
- **Exact recursive-vs-flat semantics of `FS.dir`/`love.filesystem.getDirectoryItems`
  for a project laid out with nested directories was inferred from the
  LÖVE API name and the single-level loop in `filesystem.lua:86-98`,
  not from an on-disk test with actual subdirectories** (the scratch
  probes used flat, single-file test projects).
