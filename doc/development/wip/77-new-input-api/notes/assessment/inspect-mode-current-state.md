# `inspect` mode — current implementation and recoverable intent

Scope note: this is a from-scratch read of `src/` (facts) plus non-#77 docs
(`doc/development/internals/console.md`, `doc/development/docs.md`,
`doc/mermaid/fsm.md`) and git history (intent). Everything under
`doc/development/wip/77-new-input-api/` was deliberately **not** consulted —
this is meant to be an independent baseline, not a restatement of the current
sprint's framing.

## What `inspect` is

`love.state.app_state == 'inspect'` is one of eight `AppState` values
(`src/types.lua:121-129`). It is the state the app is in while a running
project is **paused/broken into**, console-REPL-over-frozen-project-state
(`doc/development/internals/console.md:19`). Reachable transitions
(`doc/mermaid/fsm.md`, `fsm_f.md`):

```
running --pause()--> snapshot --(next tick, auto)--> inspect
inspect --continue()--> running
inspect --edit()--> editor
editor  --finish_edit()--> inspect   (only if project was running before edit)
```

`snapshot` is a one-frame transition: `love.update` (`controller.lua:427-433`)
sees `app_state == 'snapshot'`, grabs a screenshot into `View.snapshot`, then
calls `ConsoleController:suspend()`, which is what actually flips the state to
`'inspect'` (`consoleController.lua:809-826`). The screenshot is drawn as a
frozen background behind the console UI while inspecting.

Entry points that reach `pause()`/`suspend_run()`: Ctrl+Pause
(`controller.lua:581-583`, `messages.user_break = "BREAK into program"`), and
an uncaught runtime error in the project's own handlers
(`user_error_handler` → `CC:suspend_run(exec_error_msg)`,
`controller.lua:45-51`). So `inspect` is a **debugger-break** concept, not
just a manual pause: both an explicit key chord and an unhandled exception
land here.

## Two separate "input widgets" — don't conflate them

The codebase has two distinct input-widget concepts that both matter to this
question, and they are affected differently by `inspect`:

1. **The console's own input line** (`ConsoleController.input`, a
   `UserInputController` instance created in `ConsoleController.new`,
   `consoleController.lua:44,49`). This is the always-present REPL prompt at
   the bottom of the console UI. It is drawn unconditionally by
   `ConsoleView:draw` → `drawConsole()` → `self.input:draw()`
   (`consoleView.lua:48-57`), in every non-`editor` state, `inspect` included.
2. **The project input overlay singleton**
   (`love.state.user_input_controller`, provisioned once in `main.lua`;
   activated per-request via `compy.input.show()` /
   legacy `input_text()`/`input_code()`/`user_input()`,
   `consoleController.lua:347-358, 601-634`). Its *active* handle is published
   as `love.state.user_input = { M, C, V }` (`userInputController.lua:211-228`)
   and cleared to `nil` on hide (`userInputController.lua:257-259`). This is
   what `doc/development/internals/console.md` calls "The `user_input`
   Overlay" (§105-124).

**`inspect` suppresses #2, not #1.** The console's own input line stays live
and becomes *the* input surface during inspect (see below); the project
overlay is force-disabled regardless of whether one happens to be open.

## The suppression mechanism (facts)

`controller.lua:19-22`:
```lua
local get_user_input = function()
  if love.state.app_state == 'inspect' then return end
  return love.state.user_input
end
```
This is not "the overlay happens to not be open during inspect" — it is an
unconditional override. Even if `love.state.user_input` is non-nil (a project
overlay was mid-session when the break happened), `get_user_input()` reports
"nothing" while inspecting. Two consequences follow from every call site of
`get_user_input()`:

- **Draw**: `love.draw` (`controller.lua:403-413`) does
  `local ui = get_user_input(); if ui then ui.V:draw() end` — the overlay's
  view is skipped while inspecting, i.e. it is *hidden*, not merely
  input-deaf.
- **Input routing**: every `love.handlers.*` entry point
  (`keypressed`/`textinput`/`keyreleased`/`mousepressed`/…,
  `controller.lua:554-785`) does `local user_input = get_user_input(); if
  user_input then <route to overlay.C> else <fall through to love.keypressed
  etc.> end`. During inspect this always takes the fallback branch.

The fallback branch (`love.keypressed`, `love.textinput`, …) is, during
inspect, the **console's own default handler**
(`Controller.set_love_keypressed/_textinput/_keyreleased`,
`controller.lua:187-238`, each of which does `CC:keypressed(k)` /
`CC:textinput(t)` against `self.input`, i.e. widget #1) — not the project's.
That is arranged by `ConsoleController:suspend()`
(`consoleController.lua:809-826`):

```lua
function ConsoleController:suspend()
  ...
  love.state.app_state = 'inspect'
  ...
  self.main_ctrl.save_user_handlers(runner_env['love'])   -- stash project's love.* callbacks
  self.main_ctrl.set_default_handlers(self, self.view)    -- reinstall console defaults
end
```
`save_user_handlers` (`controller.lua:806-823`) diffs the project's
`love.keypressed`/`draw`/`update`/etc. against the framework defaults and
squirrels away anything that differs into `Controller._userhandlers`.
`set_default_handlers` then overwrites `love.keypressed`/`love.textinput`/
`love.draw`/`love.update`/`love.quit` back to the console's own functions.
`continue()` (`project_env.continue`, `consoleController.lua:573-581`) does
the mirror image: flips state back to `running` and calls
`restore_user_handlers`, which re-installs the stashed project callbacks via
`set_handlers` (`controller.lua:73-107`, wrapped in `xpcall`/error-handler
via `CC:wrap_handler`).

Net effect: **while inspecting, the project's own `love.keypressed` /
`love.textinput` / `love.draw` / `love.update` are not called at all** — they
are literally swapped out of the `love.*` global slots, not merely
short-circuited by a state check. The project is frozen in every sense: no
callbacks fire, no frame advances its own draw (the screenshot substitutes
for it), and any input overlay it had open is invisible and deaf.

## Console does treat itself as "providing its own input" during inspect

Several other call sites confirm the console explicitly treats `inspect`
as "console REPL takes over, using the paused project's environment":

- `ConsoleController:get_effective_env()` (`consoleController.lua:786-796`)
  returns `project_env` for both `running` and `inspect` (console env
  otherwise) — code the user types resolves symbols against the *project's*
  globals while inspecting.
- `ConsoleController:evaluate_input()` (`consoleController.lua:709-739`)
  picks `run_env` the same way inline: project env if `inspect`, console env
  otherwise. So Enter-in-the-REPL during inspect compiles and runs the typed
  chunk with the project's `fenv` — the console becomes a live debugger
  console into the paused project's globals, matching
  `doc/development/internals/console.md:65`, `"the REPL runs code in
  project_env, allowing the user to inspect and mutate the paused project's
  state."`
- `project_env.run`/`project_env.continue`
  (`consoleController.lua:565-581`) are only meaningful (no-ops otherwise)
  when `app_state == 'inspect'` — `run()` stops-and-restarts the project,
  `continue()` resumes it. These are functions injected into the project env
  itself, callable from the REPL while paused.
- `run_project()` (`consoleController.lua:230-237`) explicitly refuses to
  start a second run while `inspect` (or `running`): `"There's already a
  project running!"` — `inspect` is treated as "still running, just paused,"
  not as a separate idle state.
- Global quickswitch/editor-toggle (Ctrl+T, `controller.lua:557-577`) and
  `f9`-style editor toggle both accept `inspect` alongside `running`/
  `project_open` as valid source states — reachable from the debugger break,
  consistent with the `inspect --edit()--> editor` / `editor
  --finish_edit()--> inspect` transitions in the fsm diagrams.

## Visual signaling

`inspect` gets its own color theme, distinct from `running` and plain
console/`ready`, in both the input line and the statusline:
- `UserInputView`'s `get_colors()` (`userInputView.lua:32-40`): `inspect` →
  `cf_colors.input.inspect`, `running` → `cf_colors.input.user`, else
  `cf_colors.input.console`.
- `Statusline:draw` (`statusline.lua:14-25`): same three-way (plus `editor`)
  branch for `cf.colors.statusline.*`.
- `conf/colors.lua` declares `inspect` as a first-class member of both
  `InputColors` (`:24`) and the `InputTheme` alias (`:6`), alongside
  `console`/`user`/`editor`.

So the REPL prompt visibly changes color to flag "you are inspecting a
paused project," reinforcing that it is the same physical widget just
re-themed, not a separate one.

## Recovered original intent (git archaeology)

The feature was introduced incrementally, and the intent is legible mostly
from commit titles/diffs (no PR descriptions or design docs from that era
were found):

- **`0831fcf` "feat: introduce stop() and continue()"** (2024-01-23) is the
  first commit to create `'inspect'` as a state at all. It adds a
  `suspend_run()` local that flips `app_state` to `'inspect'` on `Ctrl+Pause`
  and a `continue()` that flips it back to `'running'`. The diff includes a
  literal `-- reset handlers and suspend` TODO comment marking work not yet
  done at that point (handler save/restore came later). This frames `inspect`
  from its very first commit as a **debugger breakpoint**: "stop the running
  project where it is, let me poke at it from the REPL, then resume it,"
  modeled directly on `stop()`/`continue()` debugger vocabulary.
- **`dc940b0` / `0e1bce3` "fix: disable user input in inspect mode"**
  (2025-01-13, appears twice — the repo carries two overlapping commit
  lineages, likely a rebase/mirror artifact) is the commit that added the
  `get_user_input()` override quoted above. It is a one-line diff with no
  body beyond the title; the title itself is the clearest available
  statement of intent: input (meaning the project-overlay widget, per the
  code it touches) must not remain reachable once the project is paused —
  filed and phrased as a **bug fix**, not a feature, i.e. the pre-existing
  behavior (overlay still live/drawn during inspect) was judged wrong once
  someone tried it. No linked issue/PR text was recoverable to say *why* it
  was judged wrong, but the placement (right after a run of input-model
  fixes: paste-overwrite, wrap-width, wrapped-text cleanup) suggests it
  surfaced during general input-widget hardening rather than a
  design-first decision.
- **`500251c` "feat(project): allow editor toggle from inspector"**
  (2024-11-19) extends the Ctrl+T/`f9` editor-quickswitch condition from
  `running` to also include `inspect`. Confirms the intent that `inspect` is
  meant to interoperate with the editor workflow the same way `running`
  does — you should be able to jump from "paused, inspecting" straight into
  editing the source, not just from "actively running."

No comments in the current source at the exact suppression site
(`controller.lua:19-22`) explain *why*; the only rationale on record is the
commit title. Everything else about "why the console must own input while
inspecting" is inferable only from the surrounding architecture (single
active `love.*` handler set, project handlers physically swapped out during
suspend) rather than from any comment or doc prose.

## A gap worth flagging

`doc/development/internals/console.md:116` describes overlay dispatch as
"if set, key events go to the overlay controller, not the main console
input" — true in general, but it does not mention the `inspect`-specific
override that forces this check to fail regardless of the overlay's actual
active/inactive state. `doc/development/internals/user_input.md` (the other
current non-#77 doc touching this widget) does not mention `app_state ==
'inspect'` anywhere at all. So the forced-suppression behavior, while very
much present and deliberate in the code (and traceable to an explicit "fix"
commit), is not currently documented in either of the two docs that would be
the natural place for it.
