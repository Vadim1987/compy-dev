# What the console environment actually does — four questions, answered from code

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

**Session:** 62 · **Date:** 2026-08-31 · Asked by the owner while shaping the environment-lifecycle
ticket ([`owner-inquiry-console-env-lifecycle.md`](owner-inquiry-console-env-lifecycle.md);
analysis in [`../reviews/env-lifecycle-inquiry-assessment.md`](../reviews/env-lifecycle-inquiry-assessment.md)).

Every answer below is read from code and cited. "Base" means the PR base `3256aac`, checked with
`git show`. Nothing here was executed on a device; two items are marked as reasoned-not-run.

---

## 1. Is `compy.*` reachable from the console — before and after the feature?

**Yes, both.** The console environment **is** `_G` (`consoleController.lua:40,60`), and
`prepare_env` puts the namespace on it directly.

| | base `3256aac` | today |
|---|---|---|
| `compy` on the console env | **yes** — `prepared.compy` (`:462`) | **yes** — `prepared.compy` (`:1091`) |
| `tty` alias | `prepared.tty` (`:463`) | `prepared.tty` (`:1092`) |
| members | `terminal`, `audio`, `graphics`, `fonts` — plain table (`:331-339`) | same four as fields, plus `input` and `before_exit` resolved through a metatable (`:942-967`) |
| separate instance from the project's? | **yes** — `get_compy_namespace` called at `:461` (console) and `:627` (project) | **yes** — called at `:1090` (console) and `:1192` (project) |

**The two-instance shape is pre-existing, not this feature's** — recorded because provenance is kept
apart in the PR description, and because finding **C3** in the assessment is about this shape.

What actually works when typed at the console today: `compy.terminal` / `tty`, `compy.audio`,
`compy.graphics`, `compy.fonts` — all real. What does not:

- **`compy.input`** exists but is inert twice over — its methods resolve
  `love.state.user_input_controller`, which is nil outside a run, and its `shortcuts`/`hooks` tables
  are never dispatched on, because `occupy_input` activates the route on
  `CC:get_project_env().compy.input` (`controller.lua:229-231`), a different object.
- **`compy.before_exit`** assigns the **console** namespace's closure slot; the framework fires the
  **project** env's namespace (`stop_project_run` → `self:get_project_env().compy`,
  `consoleController.lua:1461-1462`). A console-side assignment is never called.

*(At base, the divergence ran the other way too: the project namespace was mutated with an extra
member the console's never had — `compy_namespace.text_input = input_text`, base `:628`.)*

## 2. What happens if you type `love.draw = function() return end` at the console?

The console env is `_G`, so this writes the **real** `love.draw`.

1. On the next frame, `set_love_update`'s update notices `love.draw ~= View.prev_draw` and
   **re-wraps it**: your function is called inside `gfx.push('all')` + `wrap(…)` (error-wrapped), and
   the input widget, if any, is painted after it (`controller.lua:566-582`).
2. **The console stops being painted** — an empty draw means a blank screen.
3. **The keyboard is untouched.** You can still type blind and still evaluate.
4. **Nothing restores it.** `set_love_draw` runs at boot and from `set_default_handlers`, i.e. on
   project teardown (`consoleController.lua:1470`).
5. `user_draw` and `app_state` are **not** updated — those are set by the harvest
   (`set_user_handlers`), which only runs for project code (`run_user_code`, `:118-124`). So the
   framework still believes nothing is running while your function owns the screen.

**Recovery:** `Ctrl+Shift+R` (`reserved_reset` → `CC:reset()` → `quit_project` → `stop_project_run`
→ `set_default_handlers`), or run-and-stop a project. `Ctrl+T` also works **if a project is open**.

## 3. Same for `love.keypressed` and the other input events?

Worse, because the console's own handler *is* the thing in that slot.

- Layer 1 forwards unconditionally after its framework concerns:
  `if love.keypressed then return love.keypressed(k, sc, isr) end` (`controller.lua:909-911`), and
  the console installed itself there via `set_love_keypressed` (`:523-524`).
- Assigning it at the console **replaces the console's handler: you can no longer type.**
- Unlike `draw`, there is **no re-wrap detection** for keypressed — your function is called raw: no
  error wrapper, no canvas binding.
- `textinput`, `keyreleased`, `mousepressed/moved/released`, `wheelmoved`, `touch*` have the same
  shape (`:914-925` and the pointer handlers) — the raw handler forwards to whoever occupies
  the slot.
- **What still works:** the `RESERVED` combos, which run *before* the forward (`:871-889`) —
  `ctrl+t`, `ctrl+q`, `ctrl+s`, `ctrl+shift+r`, `ctrl+alt+r`, `ctrl+alt+p`, `ctrl+alt+shift+p`,
  `f10`, and `ctrl+escape` on release.
- **Only `Ctrl+Shift+R` is a universal way back:** `reserved_quickswitch` acts only from
  `running`/`inspect`/`project_open`, and `reserved_stop_run` only from `running`.

**Reasoned, not run:** `reset()` → `quit_project()` → `stop_project_run()` carries no state guard
and sets `app_state = 'project_open'` (`:1473`); if no project was open, `close_project` returns
early without setting it back to `'ready'` (`:1417-1435`). Recovery from `ready` may therefore leave
the state machine claiming `project_open` with no project. Worth a probe before it is relied on.

### 3b. The severity gradient, and the one state where it inverts

Every slot is one assignment away from being taken, with **no guard anywhere** — the console
environment is `_G` at base too (`3256aac`, `:40-41,51,53`), so this is pre-existing, not the
feature's. What differs is what you lose:

| typed at the console | effect | can you still type? |
|---|---|---|
| `love.draw = f` | screen belongs to `f`; console no longer painted | **yes** — blind, but it works |
| `love.keypressed = f` | console's own handler replaced | **no** — true lock-out |
| `love.textinput = f` | character entry dies; keys still reach the console | partly — editing keys yes, letters no |
| `love.update = f` | kills the framework's per-frame work: draw re-wrap, click timer, snapshot/suspend, harmony | yes (events pump via `love.handlers`, independent of `love.update`) |
| `love.mousepressed` / `wheelmoved` / `touch*` | pointer channel taken | yes |

`RESERVED` runs before every forward (`controller.lua:871-889`), so the recovery keys survive all of
these. **Ctrl+Shift+R is the only universal one** (Ctrl+T needs a project open, Ctrl+S needs
`running`, Ctrl+Esc quits).

**In `inspect` the same line does something else entirely.** The REPL compiles into `project_env`
there (`consoleController.lua:1250-1256`), so `love.draw = f` writes `project_env.love.draw` — the
boot-time **clone**, which nothing reads. It appears to do nothing… and then **comes alive at the
next run of that project**, because `set_handlers(userlove, CC)` installs from that very table
(`controller.lua:293-298`, via `hook_draw`). Same keystrokes, three outcomes depending on state:
takes effect now, does nothing, or fires later. *(The dormant-then-live path is read from code, not
run.)*

## 4. Does opening a project (without running it) change either answer?

**No** — not for questions 2 and 3.

- The REPL compiles into the **project** env only in `inspect`; in `ready`, `project_open`,
  `running` and `editor` it compiles into the console env (`:1250-1256`). So `love.draw = …` still
  writes the real `love` with a project merely open.
- Note the asymmetry: `get_effective_env()` — used by the project's `package.loader` — switches on
  `running` **or** `inspect` (`:1312-1320`), a *different* rule from `evaluate_input`'s. Two
  functions, two answers to "which environment is current".

What opening a project *does* change: `dofile`/`readfile`/`edit` stop refusing (`check_open_pr`,
`:981-995`), the project's `package.loader` is installed, `project_env` is reset (opening closes any
current project first, `:1421-1423`), and **`Ctrl+T` becomes a recovery path**, since quickswitch
acts from `project_open`.

`compy` reachability does not change at all — the console's namespace is built once, at boot.

## 5. Is `dofile` executable only when a project is open?

**Yes — doubly gated, and identical at base** (so pre-existing, not this feature's).

1. `prepared.dofile` wraps the call in `check_open_pr`, which prints *"no open project"* and returns
   nil when `P.current` is nil (`:991-995`; base `:362-366`, identical).
2. `project_dofile` gates again on `P.current` (`:394-398`) and loads through `open:load_file(fn)` —
   the **open project's** mount, so the filename resolves inside that project. An arbitrary path is
   not reachable.

Three consequences for the ticket:

- **It does not obstruct the "run an example by `dofile`" reading**: open the example project, then
  `dofile('main.lua')`. This also answers the assessment's Q9 from intent — `dofile` is
  project-scoped **by design**, and the ticket should affirm that or state the widening.
- **An ungated raw `dofile` already sits on the console env, unused.** `_G.o_dofile = _G.dofile`
  (`:390`; base `:285`) stashes the original on the global table, so `o_dofile('/any/path.lua')` is
  reachable from the REPL, unrestricted, reading real disk in `_G`. Its sibling `o_require` has real
  consumers (`bufferModel.lua:180`, `harmony/init.lua:1`, `util/lua.lua:1`, `util/debug.lua:441`);
  **`o_dofile` has no reader anywhere in `src/`**. Undocumented capability, probably dead code —
  name it or remove it.
- **The return shape is not Lua's.** `project_dofile` returns `true, chunk()` (`:404`), so
  `local x = dofile('f.lua')` is `true`, not the file's value — and `nil` when no project is open.
  Standard `dofile` returns the chunk's returns. Under R1's *"as if typed at the console"* this is a
  small but real deviation to fix or ratify.

## 6. Is `dofile` advertised anywhere? (the search for intended usage)

**No user-facing documentation exists, before or after the feature.**

- **At the PR base `3256aac`**, `dofile` appears in exactly **two** tracked files: the
  implementation (`consoleController.lua`) and one aside in `doc/development/internals/console.md`
  about `project_env` accumulating `require`/`dofile` results. Root `README.md`: nothing.
- **Today**, the same two plus `internals/project_sandbox_env.md` — also internals, and its `:297`
  citation has drifted (the `setfenv` is at `:402`).
- No mention in any user-facing guide, and none in `doc/input_api.md`.

**One statement of intent exists, and it is the load-declarations reading.**
`src/examples/balloons/docs/requirements.md:4`, in the project owner's voice (Russian; the file is
**untracked** in the balloons repo, so it carries no git provenance):

> *"The point of `graphics.lua` is that it can be run as `dofile("graphics.lua")` — but since it
> contains only declarations, it executes quickly and without particular consequences, other than
> assigning values to a bunch of symbols."*

**De-facto usage agrees.** `src/examples/keyboard/main.lua:53-62` calls the *project-side* `dofile`
ten times — `config.lua`, `pastel.lua`, `locale.lua`, `layout.lua`, … — as an include mechanism for
declaration files. (`maze/spec/*` also uses `dofile`, but that is real Lua `dofile` under `busted`,
outside the app.)

**So the intended scenario, on the only evidence there is: `dofile` includes a file of declarations
into the current environment.** Not "run a program". Two independent sources, both predating this
discussion, both matching reading **D**.

Two consequences for the ticket: R1 is not a new feature request but a request that undocumented
behaviour match its only recorded intent, plus a callback rule for the case where the file is *not*
pure declarations (`main.lua`); and the ticket inherits a **documentation obligation** — `dofile` is
a user-facing console verb with zero user-facing documentation.

---

## Why these answers matter to the ticket

They are the concrete form of *"unintuitive … not even properly specified"*:

- A single line typed at the console can take the screen (Q2) or the keyboard (Q3) with no state
  change, no warning, and no automatic way back — and the recovery key is undocumented.
- Two of the namespace's members (`input`, `before_exit`) are present at the console and silently
  do nothing, because the console's namespace instance is not the one the framework reads.
- "Which environment is current" already has two different implementations that disagree.

R1's *"restore the interaction callbacks so that the console works"* is exactly the rule that would
make Q2 and Q3 safe — which is the strongest argument in the inquiry's favour, and it is an argument
from behaviour rather than from taste.
