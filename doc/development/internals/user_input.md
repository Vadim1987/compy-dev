---
description: How text/keyboard and pointer input actually work — routing, the dispatch chain, and the mechanism behind each guarantee
status: active
audience: developer
authored: llm
reviewed: none
---

# User Input — Implementation Overview

Input handling in Compy has two mostly independent layers: **text/keyboard input** (the input widget shared across console, editor, and project overlays) and **mouse/pointer input** (handled partly by the framework, partly delegated to projects). This doc covers both, with mode-specific notes where the behavior differs.

For the project-facing usage guide (examples, the `show()` config table, the submit lifecycle from a project author's point of view), see [Compy Input API](../../input_api.md). This doc is the "how it works under the hood" narrative — routing, the dispatch chain, and the mechanism behind each guarantee. For the two-layer `love.handlers.*` vs `love.<event>` wiring underneath the gateway (§"Dispatch chain" below), see [Event Dispatch Layers](event_dispatch_layers.md).

---

## Text Input Widget

`UserInputModel` / `UserInputController` / `UserInputView` form a shared widget reused in three contexts: the console REPL, the editor input strip, and project-created overlays. The widget is always the same code; what differs is the host evaluator and the controller handling the submission.

### Data flow

```
LÖVE2D textinput event
  → love.handlers.textinput (gateway)
    → console/editor route (default handler):
        ConsoleController:textinput (dispatches by app_state)
          → editor mode: EditorController:textinput
          → console/overlay mode: UserInputController:textinput
            → UserInputModel:add_text
              → updates InputText (cursor-aware string)
                → view re-renders
    → project route (while a project is 'running'):
        ProjectInputController:textinput
          → the three-consumer walk ("Keyboard Handling" below);
            the terminal consumer is the same
            UserInputController:textinput/add_text path
```

A project hooks `textinput` either via `compy.input.shortcuts.textinput[combo]` /
`compy.input.hooks.textinput` (the shortcuts/hooks consumers of the chain) or by
defining its own `love.textinput`, which auto-provisions as the seeded hook when
no explicit `hooks.textinput` is set (see "Keyboard Handling" below) — reaching
the widget is what happens only when nothing upstream consumes the event.

Text characters arrive via `love.textinput` (OS-processed, handles IME and layout, fires only for character-producing keys). Raw key events arrive via `love.keypressed` — but `keypressed` is **not** restricted to non-character keys: LÖVE2D fires it for every physical key, textual or not. Pressing `q` fires both `keypressed('q')` and `textinput('q')`. (LÖVE2D does not guarantee the relative *order* the two arrive in for the same physical key.)

The "keypressed = control channel, textinput = character channel" split used throughout this doc is therefore **compy's own convention, not a LÖVE2D guarantee**. Nowhere does compy's `keypressed` code filter out or ignore textual keycodes — it simply never gives `k` a match that means "insert this character" (see `UserInputController:keypressed` below: every branch checks `k` against a fixed set of named control keys, or a modifier + letter combo used as a *shortcut*, e.g. Ctrl+C). A bare `keypressed('q')` with no modifier held matches nothing and falls through untouched. All literal character insertion (`UserInputModel:add_text`) is reachable only from `textinput` handlers, plus two `keypressed`-triggered paths that move **existing** text (not the pressed key) into the model — clipboard paste (Ctrl+V) and `load_selection` (Escape, editor mode, loads buffer text into the input).

`isrepeat` is threaded through the gateway and the project route, but not uniformly all the way to every consumer. LÖVE calls `love.handlers.keypressed` with `(key, scancode, isrepeat)`; the gateway (`controller.lua:797`) keeps all three and calls `love.keypressed(k, sc, isr)` unconditionally (`controller.lua:899-900`). From there:
- while a project runs, the project route's `love.keypressed` is `ProjectInputController:keypressed(k, sc, isr)` (`controller.lua:141-144`), which threads `isr` through the dispatch walk, widget included (`projectInputController.lua:74-86`) — both `compy.input.hooks.keypressed` and the widget receive the uniform `(k, keys_pressed, isrepeat)` triple;
- in console/editor mode the route's default handler accepts `isr` and drops it: the only call it makes is `CC:keypressed(k)` (and, from there, `EditorController:keypressed(k)`), so console/editor's own mode dispatch never sees `isrepeat`. The console route has no widget step to thread it to — see "Keyboard Handling".
Shortcuts dispatch (the `compy.input.shortcuts` combo tables) does not gate on `isrepeat` either — see "Key state" below.

### Multiline input

The input is not single-line. `Shift+Enter` inserts a newline (`line_feed()`). The cursor model tracks both line and column. Lines are stored as a `Dequeue<string>` in `InputText`. The view wraps long lines at `drawableChars` width (same wrap machinery as the editor's `VisibleContent`).

LÖVE has no multiline-text concept of its own; it only delivers discrete `textinput`/`keypressed` events, one character or one key at a time. Assembly is entirely compy's own: `UserInputController:keypressed`'s `newline()` local (`userInputController.lua:568-574`) calls `input:line_feed()` whenever Shift+Enter is detected — **unconditionally**. There is also no separate "keystroke assembly" buffer: `textinput` mutates the model's persistent text immediately and continuously, and Enter (a `keypressed`, not a `textinput`) is a purely discrete control signal that reads whatever the *current* buffer state is (`get_text()`) at the moment it fires. Nothing replays or buffers a keystroke history to reconstruct the submitted text; the live model state *is* the submitted text. True uniformly for console, editor, and the project overlay (all three read `get_text()` at submit time); search has no evaluator/submit concept at all — its Enter jumps to the currently-selected result, not the typed query.

The input view height is `input_max = 14` lines. This is a display limit only — the model can hold more lines, and scrolling within the input works normally. In the editor context this becomes relevant when loading a monster block: the editor's buffer viewport is `LINES = 16`, a **separate** limit from `input_max`, so a block can exceed the 14-line input strip — all content stays in the model, but only 14 lines are visible at once. **Open:** `input_max` (14) and `LINES` (16) currently differ, and whether 14 or 16 is the correct monster-block threshold is **not yet settled** — reconciling them is a pending review item (see `editor.md` — *`input_max` vs `LINES`* and *Monster Blocks*).

### Selection

Text selection works across lines. `Shift+arrow` extends selection; releasing shift releases it. `UserInputController.disable_selection` (set to `true` in editor mode's input instance) suppresses selection — the editor uses its own block-level selection model, not character-level selection in the input.

Mouse click on the input widget (translated from screen coordinates to input grid via `_translate_to_input_grid`) sets the cursor position. Drag extends selection. The coordinate translation is bottom-relative: line 0 is the bottom line of the input, which is non-obvious.

### Error state

When an error is set on the model (`set_error()`), the input is visually locked: text input and most keys are ignored until the error is cleared. Cleared by: Enter, space, or arrow keys. This is used for parse errors, runtime errors, and validation failures.

### Evaluator and validation

Each `UserInputModel` has an `Evaluator` that runs on submit:
- **Console**: `LuaEval` — metalua parse, validates Lua syntax before accepting the submit
- **Editor input (Lua file)**: `LuaEditorEval` — same as LuaEval but adds 64-char line length validator
- **Project overlays**: the internal plain evaluator plus project callbacks for
  validation and display. Projects cannot install evaluator objects.
- **Search**: `nil` evaluator (search input is free text, no validation)

Host evaluators can validate during editing. The project overlay's public
validator runs at submit and receives `string[]`; it returns `true` or
`false, Error[]`. `LuaHighlighter`, `LuaSyntaxValidator`, and
`LineValidators` are the only evaluator-derived helpers exported to a project.

### Cursor manipulation and "reset" — three API layers, now all connected

Cursor access exists at three layers. **Model** (`UserInputModel`) has the full primitive surface
(`cursor_left/right`, `move_cursor`, `jump_home/end`, `jump_line_start/end`, `get/set_cursor_pos`,
`set_cursor(c)`) — used internally by the model's own `keypressed` handling in response to
arrow/Home/End. **Controller** (`UserInputController`) exposes a narrower passthrough plus a
clamped 2D mover: `get_cursor_info`/`get_cursor_pos`/`set_cursor(Cursor)`/`jump_home`/
`set_cursor_pos(line, col)` — the last one (`userInputController.lua:124-139`) computes its own
clamp against line/text length rather than relying on `move_cursor`'s fallback-to-previous-position
behaviour. **`compy` (project-facing)** now has its own surface on the overlay widget:
`compy.input.get_cursor()` / `set_cursor(line, col)` / `set_text(text[, keep_cursor])`
(`consoleController.lua:487-510`) — `get_cursor` returns `nil` while hidden (a plain "nothing to
report" read, not a refusal); `set_cursor`/`set_text` no-op **and warn** while hidden.

There are three call sites that manipulate the cursor programmatically (i.e., not as a direct
response to an arrow/Home/End keypress): two in `editorController.lua` — `load_selection`
(`:590-604`, reads/restores the cursor via the **controller** API to preserve the caret across an
insert) and `reject_oversized` (`:628-633`, called from two live submit paths, jumps the cursor to
a rejected block's start via **`input.model:move_cursor` directly, bypassing the controller**) —
plus the project-facing `compy.input.set_cursor`/`set_text` above. Console and search never touch
it programmatically. `UserInputModel:set_cursor(c)` is a raw, **unvalidated** assignment
(`self.cursor = c`) — safe because every caller supplies a pre-validated `Cursor`; the project path
instead routes through `UserInputController:set_cursor_pos`, which clamps rather than trusting the
raw model setter with an arbitrary project-supplied pair.

**FR-1's "initial cursor position" is implemented at the controller layer, not the model's.**
`UserInputModel.new(cfg, eval, custom_label)` (`userInputModel.lua:45-63`) still hardcodes
`cursor = Cursor()` — always `(1, 1)`, no cursor constructor parameter — but a fresh `show()`
activation (`open_fresh`, `userInputController.lua:252-272`) applies a `cfg.cursor = {line, col}`
via `set_cursor_pos` immediately after construction, after `text` is applied. `show(cfg)`'s `force`
path over an **already-active** session still only patches the `text` subset and ignores `cursor` —
repositioning an active session's cursor is `compy.input.set_cursor`'s job, not `force`'s.

"Reset the prompt" is four bespoke, mutually inconsistent mechanisms, not one shared primitive:
console's own Ctrl+L (terminal-only) vs. Escape (content-reset, history preserved) vs. Ctrl+Q
(content, history preserved) vs. Ctrl+Shift+R (content + history wiped); editor's own Ctrl+W
(content-only, with Escape repurposed for `load_selection` instead of a reset); search's own
`clear()`, which reaches past its own controller straight into `self.model.input:clear_input()`,
skipping `clear_error()` (currently harmless — search has no evaluator, so no error can ever be
set); and the project overlay, which has no "reset the session" surface of its own — only
`compy.input.clear()`, which empties content and cursor but isn't a full reset. Carried as-is; not
touched by this pass.

---

## Keyboard Handling

The project route runs a per-event chain, a dumb three-consumer walk,
each consumer tried only if the previous one returns falsey —
`shortcuts[event][combo]` → `hooks[event]` → the widget — stopping at
the first that consumes. There is no framework tier any more: the old
non-overridable Enter/Escape special-case is gone (see "Submit and
cancel" below); the widget's own participation is decided by its
*shownness*, not a return value, with the hidden-check *internal* to
the widget itself.

### Dispatch chain

```
love.handlers.keypressed (k, scancode, isrepeat)
  → held-key bookkeeping + global shortcuts — controller.lua
    → love.keypressed — the active route
      ├─ console/editor (the default handler):
      │    → overlay widget shown (except inspect):
      │        UserInputController:keypressed
      │          (k, keys_pressed, isrepeat)
      │    → else ConsoleController:keypressed
      │        → if editor state: EditorController:keypressed
      │        → else: console key handling
      │          → history navigation (PageUp/Down)
      │          → UserInputController:keypressed
      │          → Enter → ConsoleController:evaluate_input
      └─ project run: ProjectInputController — the free function
           `dispatch(shortcuts, hooks, widget, event, trigger, ...)`
           (projectInputController.lua), same shape on
           keypressed/keyreleased/textinput:
           1. compy.input.shortcuts[event][combo]  (project
                shortcuts; per-event tables, normalising —
                Decision 8)
           2. compy.input.hooks[event]  (one hook per event,
                seeded once at activation with the project's
                captured love.* handler where unset — no
                per-event precedence re-resolution — Decision 10
                revised)
           3. the widget (UserInputController) — terminal;
                consumes whenever it is shown (its own internal
                `self.shown` flag via `is_shown()`), skipped
                (and reports not-consumed) when hidden
         Truthy at shortcuts/hooks, or shown at the widget,
         consumes (stop); falsey/hidden falls through.
```

`app_state == 'starting'` is never observed by any input path: `main.lua`'s `love.load()` sets it, then flips it to `'ready'` a few lines later — both synchronously, before LÖVE's event pump runs, so no `love.handlers.*` entry point can ever see the `'starting'` value.

Global shortcuts intercepted in `love.handlers.keypressed` (`controller.lua:797+`) before anything reaches the active route's controller: Ctrl+Pause suspends, Ctrl+Q quits project, Ctrl+S stops run or closes buffer, Ctrl+Shift+R resets application, Ctrl+Alt+R restarts project, Ctrl+T quick-switches between run and edit. Ctrl+Esc (quit) is the one exception living on the release side — `love.handlers.keyreleased` (`controller.lua:910-920`), not keypressed. None of these consume the key: it still reaches the active route afterward (§6.3 non-consuming shortcuts).

The gateway (`love.handlers.*`) no longer routes on widget presence — the overlay gate is removed. The active route's controller always receives the event. The project route runs the three-consumer walk above: the project's captured `love.*` handler auto-provisions as the seeded hook (once, at activation — seen even while the widget is shown, only when the project set no explicit `hooks[event]`; an explicit hook always wins), and the widget is the terminal consumer with its hidden-check *internal* (`is_shown()` reads a strictly-internal `self.shown` flag; the widget no-ops while hidden, so a hidden widget mutates nothing without any external gate). The console-route default handlers still forward to the widget when `love.state.user_input` is set (except under `inspect`). The widget is never a routing destination of the gateway and never the active route. `Controller._keyboard_route` records which controller is the active route (the `ConsoleController` by default, the `ProjectInputController` during a run) — bookkeeping with no reader beyond its own two assignment sites (`controller.lua:209`, `:434`) today.

**On the `'running'` → `'project_open'` boundary, the project route is disconnected only when the project has no interaction surface left — an interactive non-blocking project keeps it.** A non-blocking project that returns (no `update`/`draw` hooked) drops `app_state` to `'project_open'`; `ConsoleController:run_project` then checks `Controller.user_is_interactive()` (`controller.lua:1112-1113`: `love.state.user_input ~= nil or user_pointer`, the latter set in `hook_pointer` when the project installs any pointer/click handler and reset in `set_default_handlers`). Only when that predicate is false does `run_project` call `Controller.release_keyboard_route(CC)` (`controller.lua:730-735`, `consoleController.lua:266-267`), which calls `Controller.project_input:deactivate()` and **reinstalls the console's own `love.keypressed`/`keyreleased`/`textinput`** — the same handler-reassignment `set_default_handlers` does on project stop, just scoped to the keyboard/text handlers (pointer handlers stay hooked either way, so pen-and-paper projects remain clickable while `'project_open'`). A project with an active input overlay or a hooked pointer handler instead keeps the project route live: `ProjectInputController` stays the keyboard/text occupant, so the overlay's submit/cancel keep working and `love.quit` (`controller.lua:752-754`) treats `'project_open'` + `user_is_interactive()` the same as `'running'`, stopping to console on Ctrl+Esc rather than letting the app quit. `ProjectInputController` itself has no per-event "am I still running?" forward any more — its own `:keypressed` doc comment (`projectInputController.lua:205-213`) is explicit that this older guard is gone precisely *because* the handlers are only ever restored when the route is actually released, so there is nothing left to guard against.

**`inspect` mode overrides all of the above.** While `app_state == 'inspect'` (a paused/broken-into project), the console REPL owns every input channel and a project-set overlay is not honoured, regardless of the routing described above. The mechanism: `get_user_input()` (`controller.lua:21-24`) unconditionally returns `nil` while `app_state == 'inspect'`, so every `forward_*` call in this section reports "no widget" and every `love.handlers.*` entry point falls back to the console's own default handler — because `ConsoleController:suspend()` (`consoleController.lua:919-936`) physically swaps `love.keypressed`/`textinput`/`draw`/`update` back to the console's own functions via `set_default_handlers`, not merely short-circuiting them. The console additionally runs the *paused project's own* environment while inspecting: `get_effective_env()`/`evaluate_input()` select `project_env` (not the console env) when `app_state == 'inspect'`, so REPL input mutates the paused project's globals — a live debugger console, not a separate idle console. This behaviour is carried as characterized status quo, not a ratified contract — its shape under a future console/editor migration is an open call for the owner, not settled here.

### Key state: `Controller.keys_pressed` and `combo_string`

`Controller.keys_pressed` is a `{keyname → true}` table maintained on
the global `Controller`. It is updated at the very top of
`love.handlers.keypressed` (add) and `love.handlers.keyreleased`
(remove), before any downstream handler runs. Key names are LÖVE2D
canonical (`"lctrl"`, `"rshift"`, `"return"`, etc.); left/right
variants are stored without folding — `lctrl` and `rctrl` are two
separate entries, not merged into `ctrl`.

`Controller.combo_string(k, keys_pressed)` serialises a key event
into a canonical combo string. It prepends any held modifiers in
fixed precedence order — `ctrl`, `alt`, `shift`, `gui` — then
appends the triggering key. Left/right variants are folded to the
generic name at this point (`lctrl`/`rctrl` → `ctrl`, etc.). A key
with no held modifiers serialises to just the key name.

```lua
-- lctrl held, s triggers     → "ctrl+s"
-- lalt + lshift held, f4     → "alt+shift+f4"
-- escape with nothing held   → "escape"
```

Both surfaces are consumed by the free-function `dispatch`
(`projectInputController.lua:74-86`, called from
`ProjectInputController:_dispatch`), which serialises every
project-route keyboard/text event with `Controller.combo_string`
and looks the result up first against `compy.input.shortcuts.<event>`,
then `compy.input.hooks[event]`. Downstream consumers (shortcuts,
hooks, and the widget, project code included) never see the raw
`Controller.keys_pressed` table directly — they receive a read-only
pressed-keys view (`Controller.held_keys()`, `controller.lua:345-367`):
reads pass through to the live set, writes raise. On the shipping
LuaJIT/Lua 5.1 runtime `pairs()` ignores a table's `__pairs`
metamethod, so iterating this view silently yields nothing — it
is index-only in practice (`view['lctrl']` works, iterating over
it does not); `__pairs` is kept for a future 5.2+ host. The same
view is also readable outside a callback, as
`compy.input.keys_pressed` (`../decisions/input.md`, Decision 20):
`build_input_surface` resolves it through the surface's `__index`
on every access, so it tracks a backing-table swap instead of
capturing a proxy at namespace-build time. A project that renders
held state — `examples/keyboard` draws shifted key labels — has no
callback argument in `love.draw`, which is what the second access
path is for.

The whole keypressed path hands the widget the uniform
`(k, keys_pressed, isrepeat)` triple — the widget is included by
design (one signature across the path) — but only on the project
route; see "Data flow" above for exactly where `isrepeat` does and
does not reach. Shortcuts dispatch itself does not gate on `isrepeat`:
shortcuts fire on **every** repeat, not just fresh presses — an
in-code `DEFERRED` marker above `ProjectInputController:keypressed`
(`projectInputController.lua:134-138`) records this as an unruled,
provisional leaning (fresh-only for shortcuts was considered, never
adopted) rather than a settled design.

### Console-specific keys

- **PageUp/PageDown**: history back/forward
- **Up/Down at input boundary**: also triggers history navigation (handled as a "limit reached" return from `UserInputController:keypressed`)
- **Enter** (no shift): submit → `evaluate_input()`
- **Ctrl+L**: clear terminal output
- **Shift+Enter**: insert newline in input (multiline expression)

These are interpreted by `ConsoleController` itself (console-mode-specific dispatch), not the
generic controller — see the dispatch chain above: the console/editor route forks in
`ConsoleController:keypressed` before any of this runs.

**The "limit reached" boundary signal used to travel two independent paths; the return-value one is
retired (Decision 5).** `cursor_vertical_move`/`is_at_limit` return `true` at a boundary, but
`UserInputController:keypressed` no longer threads that out as its own return value at all — the
method returns nothing now. The sole notification path, for every consumer, is the widget output:
the same boundary check calls `self.callbacks.on_limit_reached(dir, scope)` directly from inside the
widget itself (`emit_limit`, `userInputController.lua:554-557`, called from both `vertical()` and
`horizontal()`) — this is the `compy.input.callbacks.on_limit_reached(direction, scope)` widget
output a project sets via `show()`/`configure()` or a direct field assignment (a leaf-write on
`callbacks`, same as console/editor's own instances). **Console's history navigation** now goes
through this same callback: `ConsoleController.new` wires `console_widget.callbacks.on_limit_reached`
directly on its own `UserInputController` instance (`consoleController.lua:49-52`) to call
`history_back()`/`history_fwd()`, replacing the old `local limit = input:keypressed(k)` return-value
capture (`ConsoleController:keypressed` now calls `input:keypressed(k)` purely for its editing side
effects, return value unused — Decision 5). Editor never needed the signal at all, since it
independently computes boundary state via `inputView:is_at_limit(...)` at the view layer.

**FR-6 (project notification of key events): the keyboard exclusion is resolved as of 1.0.0-rc20260712.**
Historically, while `love.state.user_input` was set, `controller.lua`'s
`handlers.keypressed`/`handlers.textinput` called *only* the overlay — the project's own
`love.keypressed`/`love.textinput` were not called at all (binary, not partial). With the gate
removed, project key/text events always reach the project route (`ProjectInputController`); which
surface consumes them (the overlay widget while shown, the project's handler — seeded as a
hook — while hidden) is the route's internal delegation, no longer a gateway drop. Mouse never had this problem:
`handlers.mousepressed`/`mousereleased` call the overlay conditionally but call the project's own
handler **unconditionally**, regardless of overlay state. This is why touch/mouse needed no
separate scope item: only keyboard was ever exclusively gated.

### Editor-specific keys

See `editor.md` for full detail. Key differences from console mode:
- No history navigation (PageUp/Down scroll the buffer instead)
- Up/Down at input boundary moves buffer selection, not history
- Escape loads selected block text into input
- Ctrl+M / Ctrl+F switch modes

The difference is now **one** fork, not two. The **outer** fork is the ConsoleController/
EditorController split already covered above (console handles escape/history/Ctrl+L itself; editor
delegates to `EditorController:keypressed`'s own `edit`/`reorder`/`search` mode dispatch instead).

There used to be a **second, inner** fork: the shared `UserInputController:keypressed` branched on
`love.state.app_state == 'editor'` to decide whether to run its own Enter/Escape submit/cancel at
all. That fork was **removed** (2026-07-21) — a reusable input widget reaching up into global
app-mode to change its own behaviour was an abstraction leak (the widget could not be reasoned about,
or migrated, without knowing it was "the editor"). It is gone; `UserInputController:keypressed` now
runs **one uniform path** for every instance (see the shared-keypressed section below).

The editor's Escape→`load_selection()` (which just repopulated the input) is no longer protected by
a mode-gate inside the widget. Instead the editor **consumes Enter/Escape upstream**: each handled
branch of `EditorController:_normal_mode_keys`' `submit()` (plain Enter, Ctrl+Enter) and `load()`
(plain/Shift Escape) now calls `block_input()`, so `passthrough` is false and the shared widget never
receives that key — its uniform `submit_flow`/`cancel_flow` simply never runs for the keys the editor
owns. The one Enter variant the editor does *not* handle (Alt+Enter) does fall through to the widget's
`submit_flow`, harmlessly: the editor's own input instance sets no submit callbacks, so it is a no-op
(the same no-op console relies on). Search and reorg modes never reach `UserInputController:keypressed`
at all (see "Search" below and reorg's own `_reorg_mode_keys`), so they need no blocking.

Console's own always-shown instance is not blocked and does run the uniform `submit_flow`/`cancel_flow`
on its own Enter/Escape — harmlessly, since console sets no `before_submit`/`after_submit`/
`before_cancel`/`after_cancel` callbacks, so they are no-ops alongside console's own `evaluate_input`/
history handling. The project overlay runs the flows for real (that IS its submit/cancel). So the
per-context behaviour that the old `app_state` fork encoded is now expressed honestly: the editor
consumes upstream, console/overlay set (or don't set) callbacks — no instance interrogates global state.

### UserInputController keypressed (shared)

`UserInputController:keypressed` handles the low-level input operations that apply regardless of which route is driving it (console, editor, or the project widget): removers (backspace, delete, Ctrl+Y delete line), vertical cursor movement, horizontal movement (Left/Right, Home/End, Alt+Home/End for line vs field boundaries), Shift+Enter newline (unconditional — see "Multiline input" above), Ctrl+D duplicate line, copy/cut/paste (Ctrl+C/X/V and Shift+Insert/Delete), selection management. It never inserts literal characters — see "Text Input Widget" above for why `keypressed` and `textinput` divide the work this way.

The body is a **single uniform sequence** (no `love.state.app_state` branch since 2026-07-21):
`removers → vertical → horizontal → newline → (modify if enabled) → copypaste → selection`, then
the lifecycle keys. **`modify` (Ctrl+D duplicate-line) is gated on a per-instance `allow_modify`
flag**, a constructor parameter (`UserInputController(model, disable_selection, allow_modify)`),
set only by the editor's main input; console and the overlay leave it off. This is the honest
replacement for the old "editor branch runs `modify`" gate — a widget capability the owner enables at
construction, like `disable_selection`, not something the widget reads from global mode. (A future
combo-table owned by the widget would supersede the one-off flag — see `technical_debt/input.md`.)

There is no `oneshot` flag any more, and no separate framework-owned submit path — there is no
framework tier at all (Decision 2). Enter and Escape are ordinary keys handled at the end of
this same shared method, **uniformly for every instance**: `Key.is_enter(k) and not Key.shift()`
calls `self:submit_flow(keys_pressed)`; `k == 'escape' and not Key.ctrl()` calls
`self:cancel_flow(keys_pressed)` — see "Submit and cancel" below. **The guard is "Enter without
Shift", not "bare Enter": Ctrl+Enter and Alt+Enter submit too** (only Shift+Enter is carved out, as
the newline); likewise Escape-without-Ctrl cancels. This is a de-facto contract (Decision 14,
guard shape `return and not shift_held`), pinned by `tests/input/input_lifecycle_uniform_spec.lua`.
The widget's own
Enter/Escape handling IS the submit/cancel mechanism; there is no route-level interception above it.
Contexts that must NOT run the flows arrange it themselves: the editor consumes the key upstream
(`block_input()` in its own `submit()`/`load()`); console sets no callbacks so its run is a no-op and
its real work is `ConsoleController:evaluate_input` afterward; the editor's real submit is
`EditorController:_handle_submit`. No instance branches on global state to decide.

### Key release

On the **project route** keyreleased runs the same unified walk as keypressed/textinput
(shortcuts → hooks → widget-if-shown, DOM-style truthy-stops-propagation) — see the
dispatch-chain diagram above. The rest of this section concerns the **console route**, which this
pass deliberately did not touch (its legacy fork stays until the console/editor migration).

`keypressed`/`textinput` get careful three-way routing (console / editor / project); **`keyreleased`
gets route-level delegation but no editor fork.** Since 1.0.0-rc20260712, `ProjectInputController:keyreleased`
runs the same three-consumer walk as the other channels (shortcuts → `hooks.keyreleased` → widget), the released
key already absent from the held set. On the
console route the default handler forwards to a shown widget, else falls to `CC:keyreleased`
= `ConsoleController:keyreleased` (`consoleController.lua:1203-1206`), which **unconditionally** calls
`self.input:keyreleased(k)` — console's own instance — with **no `app_state == 'editor'` fork**.
`EditorController` and `SearchController` do not define a `:keyreleased` method at all. Net effect:
editor's and search's own `UserInputController` instances never receive `keyreleased`, under any
circumstance, even while their mode is the one actually on screen.

`UserInputController:keyreleased` only does two things: release character-selection on Shift-release,
and clear an error on Space-release. Checked whether the gap is currently observable: it isn't, but
only incidentally — editor's and search's own instances have `disable_selection = true` (so the
selection-release job is moot for them), and their error state is also clearable via **any**
`textinput` character (`editorController.lua:291-292`, unconditional clear-on-error, same as console),
which covers Space too, since Space is itself a text-producing key. So the missing fork happens to be
inert today, not silently broken — but it is still a real asymmetry against the otherwise-careful
routing discipline. Carried as-is; out of this pass's scope (console/editor's own `keyreleased`
routing is untouched by the input API).

### Search — a third widget instance, live only in editor/search mode

`EditorController.search` (`editorController.lua:14-17`) wraps its own `SearchController`/`Search`
model pair around its own `UserInputController` instance — a **third** consumer of the shared input
widget primitive, alongside console's own and the editor's main input. It is live only while
`app_state == 'editor'` and `EditorController.mode == 'search'` (entered via Ctrl+F, see
"Editor-specific keys" above). `keypressed` forwards through `EditorController:_search_mode_keys`
(`:485-503`) to `SearchController:keypressed`; `textinput` forwards through `EditorController:textinput`
(`:287-302`) when in search mode. **`SearchController:keypressed` fully owns its key handling and
never delegates to its wrapped `UserInputController:keypressed`** — it drives navigate/removers/Enter
itself and only ever calls its instance's `textinput`/`update_view`, never its `keypressed`. So the
search widget's instance never runs the shared submit/cancel flow at all, and needed no change when
the `app_state` fork was removed. There is no evaluator (search input is free text with no
validation) and **Enter returns the currently-selected result** (a jump target `{block, line}`) up to
`_search_mode_keys` rather than submitting the typed query — the same "keypress return value carries a
domain result" shape the shared widget's own limit-flag return was retired for (Decision 5);
left in place here because `SearchController` is a different class, out of the input API's scope
(`technical_debt/input.md`). `SearchController` defines no `:keyreleased` method at all — combined with the missing
editor fork above, search's `UserInputController` instance never receives a release under any
circumstance. `SearchController:clear()` (`searchController.lua:44-47`) reaches past its own
controller straight into `self.model.input:clear_input()`, skipping `clear_error()` — currently
harmless (search has no evaluator, so no error can ever be set) but a layering inconsistency against
every other reset path described above. None of the input API's design documents mention this
surface — it is real, live code with no corresponding entry in the design corpus, carried here as
the first record of it in the permanent doc corpus.

### Future editor migration path (analysis, not scheduled)

The input API makes a later editor migration possible; it does not migrate the editor. The reusable
seam is the three-consumer dispatch shape — shortcuts, hook, widget — over plain tables and a widget
instance. It must not be mistaken for an instruction to share the project widget: console, editor,
and Search keep independent text, cursor, history, and view state.

A future migration should proceed by mode, preserving the controller that owns each mode's meaning:

1. Keep normal editor commands upstream. Enter/Escape and Ctrl+D already demonstrate this split:
   the editor consumes its own commands, while ordinary editing can reach its widget. Introduce an
   editor-local adapter to the shared dispatch shape only after naming the editor's shortcut and hook
   tables; do not expose the project `compy.input` table to editor internals.
2. Keep Search's controller-owned policy explicit. Its arrows, removers, Enter-to-jump, and Escape
   are search operations, not widget submit/cancel. A migration may use its widget for text editing,
   but must preserve that priority and the selected-definition jump. `tests/editor/editor_spec.lua`
   characterizes Ctrl+F, typing, Enter, and Escape through real editor entry points for this reason.
3. Keep reorder as an editor-owned, widget-free mode until it has an actual text-input requirement.
   It is not a missing widget route.
4. Do not add editor/Search `keyreleased` forwarding merely for symmetry. It is inert today; first
   identify a release-time consumer and specify its mode semantics.

This is implementation-derived migration guidance, not a new project-facing input API or a scheduled
refactor. Any migration must retain the editor-level characterization tests and add tests for each
newly adopted mode before replacing its current handler.

---

## Mouse Input

### Framework-level click handling

The framework implements single/double click detection in `love.handlers.mousereleased` (controller.lua:662+). On each mouse release:
1. `click_count` is incremented, `click_timer` is set to 0.4s
2. On the next `love.update()`, if `click_timer` has expired:
   - `click_count == 1`: single click confirmed — calls `compy.singleclick(x, y)` if defined
   - `click_count >= 2`: double click — calls `compy.doubleclick(x, y)` if defined
3. A drift tolerance of 2.5px is applied: if the mouse moved more than that between press and release, the click is suppressed

`compy.singleclick` and `compy.doubleclick` are looked up in `env['compy']` — the project's `compy` table. They are not LÖVE2D events; they are Compy-specific abstractions. Projects define them as `function compy.singleclick(x, y) ... end`.

The 0.4s delay means single clicks are always confirmed after a short wait — there is no "instant single click" path. This is a deliberate tradeoff for double-click detection consistency.

### Direct mouse events

`love.mousepressed`, `love.mousereleased`, `love.mousemoved`, `love.wheelmoved` are also forwarded directly to project-defined handlers via the standard LÖVE2D mechanism (projects set `love.mousepressed = function(...) end`). These go through `wrap_handler` (error catching + canvas routing) if set by the project.

The framework's own `mousepressed`/`mousereleased` handlers (in `love.handlers`) call the user handler AND the overlay controller if present — both get the event.

### Input widget mouse

`UserInputController` handles mouse events on the input widget:
- `mousepressed`: translates screen (x, y) → input grid (col, line) via `_translate_to_input_grid`. Grid is bottom-relative (y increases upward in input space). Calls `im:mouse_click(l, c)` to set cursor.
- `mousemoved`: if left button held, calls `im:mouse_drag(l, c)` to extend selection.
- `mousereleased`: calls `im:mouse_release(l, c)` then releases selection.

Mouse events on the input widget are only processed when `disable_selection` is false. In editor mode, the input widget's controller has `disable_selection = true` — mouse interaction with the input strip is suppressed, and the editor uses keyboard-only navigation.

### Touch

Touch handlers (`touchpressed`, `touchreleased`, `touchmoved`) are stubbed with `-- TODO` in `UserInputController`. The framework's `love.handlers` forwards touch events to project handlers if defined.

---

## The `user_input` Overlay — Input Perspective

### Widget lifecycle (introduced in an earlier build)

`UserInputController` for the project overlay is a single instance created once in `love.load()`
(in `src/main.lua`) and stored in `love.state.user_input_controller`.
The same model, controller, and view are reused across every overlay
session; per-session allocation is eliminated.

Activation: `compy.input.show(config)` calls
`UserInputController:show(config)`, which sets
`love.state.user_input = { M = model, C = widget, V = view }`
and runs a view update. Deactivation: `UserInputController:hide()` (or
`hide()` on the `compy.input` table) sets `love.state.user_input = nil`.
`compy.input.*` is the sole project-facing input surface
**(supported since 1.0.0-rc20260712)**; the five legacy globals
(`user_input`, `input_text`, `input_code`, `validated_input`,
`write_to_input`) and the debug-only `astv_input` are
**(deprecated, removed in 1.0.0-rc20260712)** — gone from the
project environment, an ordinary `nil` field, no shim.

`show()` on an already-active widget is a no-op unless
`{ force = true }` is passed — and the suppression **warns**
(`Log.warn('UserInputController:show ignored — overlay already
active...')`, `userInputController.lua:319-320`), matching the
framework's warn-don't-swallow convention. With `force`, the text
is replaced if a `text` field is in the config; otherwise the
existing text is preserved. No cancel sequence fires in either case.

### Dispatch while active

While a project runs, `compy.input.show(config)`/etc. drive the *same* widget instance and the
*same* routing already described under "Keyboard Handling" above — there is no separate "instead
of the main controller" special case any more. In short: the gateway always calls the active
route's occupant; the console/editor route's default handler goes straight to its own surface
(the console line, or the editor fork) with no widget test in front of it — widget visibility is
state on the widget, never a routing condition (`../decisions/input.md`, Decision 1); the project
route always reaches the widget as its walk's terminal consumer. The overlay view is drawn via `user_input.V:draw()` inside
the framework's `love.update` wrapping of the project draw function (`controller.lua`,
`set_love_update`).

There is no per-frame polling. When the user presses Enter, submit runs synchronously within that
one keypress — see "Submit and cancel" below for the exact order.

### Submit and cancel — widget-owned callback sequences

Enter and Escape are **ordinary keys handled by the widget itself** (Decision 6) — there is
no framework tier any more, and no non-overridable interception above the widget: a project
shortcut registered on `'return'`/`'escape'` (`compy.input.shortcuts.keypressed['return']`, etc.)
wins over the widget's default, same as any other combo (**withdrawn guarantee**, deliberate — see
Decision 6's "Withdrawn guarantee" note in `decisions/input.md`; the gateway's unconditional power keys, Ctrl+Q etc.,
remain the real, permanent escape hatch, unaffected by any shortcut). Only once no shortcut/hook
consumes the key does the widget's own `UserInputController:keypressed` reach its lifecycle guard
(`Key.is_enter(k) and not Key.shift()` → submit; `k == 'escape' and not Key.ctrl()` → cancel — so
Ctrl+Enter and Alt+Enter submit too, only Shift+Enter is the newline), and only while the widget is
shown — hidden, the widget is skipped entirely by the dispatch walk.

**Submit** (`UserInputController:submit_flow`):

```
run_callback(self, 'before_submit', keys_pressed)   -- veto reserved, unbuilt (R9)
if self.model:get_text():is_empty() then return end
local lines = self.model:get_text()
if not gate(self.model, self.callbacks.validator, lines) then return end
run_callback(self, 'on_text_entered', lines)
run_callback(self, 'after_submit', lines)            -- DEFAULT: no-op — widget stays open
```

`on_text_entered` fires **while the widget is still active** — there is no implicit hide any more.
`after_submit` DEFAULTS to a no-op, so **a successful submit no longer auto-closes the widget** —
this is the flipped default (Decision 6): the widget stays open unless a project's own
`after_submit` calls `compy.input.hide()`. `before_submit`'s return value is reserved for a future
veto and is ignored today (R9, unbuilt); rejecting bad input is the `validator`'s job.

**Cancel** (`UserInputController:cancel_flow`):

```
if run_callback(self, 'before_cancel', keys_pressed) then return end  -- truthy = veto, skip clear
self.model:cancel()                                   -- clear, hardwired
run_callback(self, 'after_cancel')                     -- DEFAULT: no-op — widget stays open
```

Unlike submit, `before_cancel`'s return value **is honoured**: a truthy return vetoes the clear
step entirely (content and widget state untouched, `after_cancel` does not fire) — the one
asymmetry between the two default sequences. `after_cancel` DEFAULTS to a no-op, so Escape clears
the field but the widget stays open, same flipped default as submit.

`run_callback(self, name, ...)` (`userInputController.lua:438-442`) looks up `self.callbacks[name]`;
absent → no-op + debug-log. `self.callbacks` is the widget's own table, seeded at construction with
`DEFAULT_CALLBACKS` (`after_submit`/`after_cancel`/`on_limit_reached` = stay-open no-ops) and
re-seeded — never wiped to `nil` — on project teardown (Decision 11; a nil'd `after_cancel` must
not silently mean "stays open forever" for the next project). For the **project overlay**,
`compy.input.callbacks` **is this exact same table** (owner ruling 2026-07-20; captured once in
`get_compy_input`, `consoleController.lua:601-635`) — a project's `compy.input.callbacks.after_submit
= fn` write lands directly on `self.callbacks.after_submit`, no copy, no bridging. Console/editor set
their own instance's `self.callbacks.X` directly (they are trusted host code, not routed through
`compy.input` at all — see `consoleController.lua:49-52` for console's own `on_limit_reached` wiring).

A project wanting the pre-redesign "prompt once, then close" behaviour opts in with one line:
`compy.input.callbacks.after_submit = function() compy.input.hide() end` (and the `after_cancel`
equivalent for Escape).

`compy.input.hide()` (the programmatic path) fires **no** cancel sequence — cancel is the
user-facing Escape path only.

One vestige of the old mechanism remains in the gateway: `love.handlers.userinput`
(`controller.lua`) still exists and would null `love.state.user_input` if a queued
`'userinput'` LÖVE event ever arrived, but nothing in `src/` pushes that event any more — the old
`oneshot`-gated `love.event.push('userinput')` was removed along with `oneshot` itself. This handler
is unreachable today, not a live part of submit/cancel. (`doc/development/technical_debt/input.md`
tracks it as dead code.)

This whole `before_*`/`after_*` + widget-output surface (`on_text_entered`, `on_limit_reached`,
`validator`, `highlighter`) — collectively `self.callbacks`/`compy.input.callbacks` — is now live in
`src/` — see "Keyboard Handling" above for the three-consumer dispatch walk these hang off of.

### `compy.input` namespace

For a project-author usage guide with examples, see
[Compy Input API](../../input_api.md).

`compy.input` is a table created once per project environment (`get_compy_input()`,
`consoleController.lua:601-635`, wrapped into the project's `compy` table by
`get_compy_namespace()`). Its container and the identity of its three sub-tables
(`shortcuts`/`hooks`/`callbacks`) are frozen — Decision 7, see the
"compy.input's write boundary" comment in `consoleController.lua` — but every leaf inside them is
freely writable. It exposes:
- `compy.input.show(config)` — activates the widget
- `compy.input.hide()` — deactivates without firing the cancel sequence
- `compy.input.is_shown()` — whether the overlay is up (Decision 18); the one
  state query, and the only way a project can learn this — its own
  `love.state.user_input` is a sandbox clone and never set
  (`project_sandbox_env.md`)
- `compy.input.get_cursor()` / `set_cursor(line, col)` /
  `set_text(text [, keep_cursor])` — the cursor/text surface; see
  "Cursor manipulation" above for the layering this sits on.
- `compy.input.configure(config)` — live-reconfigures an active
  session; `compy.input.clear()` — resets an active session's
  content.
- `compy.input.shortcuts.keypressed/keyreleased/textinput[combo]` — the per-event combo tables
  (Decision 8), and `compy.input.hooks.keypressed/keyreleased/textinput` — the one seeded hook per
  event (Decision 10).
- `compy.input.callbacks.{on_text_entered, on_limit_reached, validator, highlighter, before_submit,
  after_submit, before_cancel, after_cancel}` — the widget's own `self.callbacks` table (same
  object, not a copy — see "Submit and cancel" above); every member is a plain leaf-write, uniform
  with `shortcuts`/`hooks`.

Everything on `compy.input` other than the `shortcuts`/`hooks`/`callbacks` sub-table identities is
callable API: assigning to any of the method names raises loudly rather than silently replacing the
function (`build_input_surface`, `consoleController.lua:425-438`); assigning to
`compy.input.shortcuts`/`hooks`/`callbacks` themselves (replacing the sub-table) also raises —
only their leaves are writable.

`compy.input.is_shown()` is the one state predicate on this surface (Decision 18). It returns the
widget's own internal `self.shown` flag (`UserInputController:is_shown()`), so a project's answer
cannot drift from the one the dispatch walk reads.

Reading `love.state.user_input` from inside a project instead does **not** work, and never did: a
project's `love` is a sandboxed deep clone (`project_sandbox_env.md`), so the framework writes the
real global while the project sees its own copy, which stays `nil` forever. An untracked scratch
project guards a per-tick re-arm with exactly that read; the guard has never fired, which is why
that project re-issues `show()` on every tick. That dead guard is the concrete reason the
predicate was added.

#### `show(config)` — activate

All fields are optional and match the project-facing guide's table:
`prompt`, `text`, `cursor` (`{line, col}`, applied after `text`),
`validator`, `highlighter`, `on_text_entered`, `on_limit_reached`, and
`force`. The project wrapper checks this table before it reaches
`apply_config`: an unrecognised key **raises** at the project's call line
(`decisions/input.md`, Decision 15), rather than being dropped. This
includes lifecycle names such as `after_submit`, which are direct
`compy.input.callbacks` assignments rather than `show` keys, and which raise
with a message naming `callbacks`. The wrapper does not expose the host
evaluator or legacy result paths.

#### `configure(config)` — the live-reconfigure surface

On an active session, `configure` takes the same config keys as
`show()` — minus `force`, which raises here — and applies only the
ones given, immediately: `prompt`,
`highlighter`, `validator`, and the widget-output callbacks
(`on_text_entered`, `on_limit_reached`) take effect from the very
next prompt render / keystroke / submit onward. `text` and `cursor`
are accepted but have **no effect** on an active session —
`configure` never mutates content or the caret; use
`set_text`/`set_cursor` for that, or `clear()` followed by a fresh
`show()`. There is no partial application: each field either
applies in full or is dropped in full, per the rule above — never a
half-applied config.

While hidden, `configure` still validates its keys, but is otherwise
always safe and never warns (it is not
a refusal): every provided field — including `prompt`, `text`, and
`cursor` — is retained and applied on the very next `show()`. That
application is one-shot: a *later* bare `show()` (no config) does
not keep re-injecting a stale hidden-configured draft. The
widget-output callbacks are the one exception — like a value passed
directly to `show()`, they stay sticky across every future
show/hide cycle until overwritten, matching `show()`'s own existing
config persistence.

`force` (a `show(config)` flag, not part of `configure`) is a
narrower, older mechanism: re-invoking `show` with
`{force = true}` over an active session replaces only the `text`
subset in place and ignores every other field. `configure` is the
documented, general live-reconfigure path; `force` remains solely
for the content-replacement case it already covered.

#### `clear()`

Empties the active session's content and puts the cursor back at
the start; no widget-output callback fires. While hidden it is a
no-op and logs a warning — unlike `configure`, this call *is* a
refusal (there is no active session to clear).

---

## Key Files

| File | Role |
|---|---|
| `src/controller/userInputController.lua` | Keyboard, mouse, and text event handling for the input widget |
| `src/model/input/userInputModel.lua` | Input state: text, cursor, selection, history, error, evaluator |
| `src/model/input/inputText.lua` | Multiline string with cursor-aware insert/delete |
| `src/model/input/cursor.lua` | Cursor position model |
| `src/model/input/selection.lua` | Selection range model |
| `src/model/input/history.lua` | Command history (console) |
| `src/view/input/userInputView.lua` | Renders the input strip and status line |
| `src/controller/controller.lua` | Gateway (`love.handlers.*`), global shortcuts, `keys_pressed`/`combo_string`/pressed-keys view, route management |
| `src/controller/projectInputController.lua` | The project route: the three-consumer dispatch walk (`shortcuts` → `hooks` → widget), hook seeding |
| `src/controller/consoleController.lua` | Console/editor route dispatch, `compy` namespace + `compy.input` surface construction |

`controller.lua` is consumed from `main.lua` (constructs the widget instance, wires
`set_default_handlers`) and `consoleController.lua` (calls into it on every mode
transition — run, stop, suspend, inspect). `projectInputController.lua` is used
only by `controller.lua` (the single `Controller.project_input` instance) and is
never referenced by console/editor code directly. `userInputController.lua`
instances are constructed by `main.lua` (the project overlay's widget),
`editorController.lua` (its own main input and its `search` sub-widget), and
implicitly by console (`consoleModel`/`consoleController`) — see "Search" above
for the third, less obvious instance.
