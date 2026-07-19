# User Input — Implementation Overview

<!-- authored By LLM; human-approved NOT YET -->

Input handling in Compy has two mostly independent layers: **text/keyboard input** (the input widget shared across console, editor, and project overlays) and **mouse/pointer input** (handled partly by the framework, partly delegated to projects). This doc covers both, with mode-specific notes where the behavior differs.

For the project-facing usage guide (examples, the `show()` config table, the submit lifecycle from a project author's point of view), see [Compy Input API](../../input_api.md). This doc is the "how it works under the hood" narrative — routing, the dispatch chain, and the mechanism behind each guarantee.

---

## Text Input Widget

`UserInputModel` / `UserInputController` / `UserInputView` form a shared widget reused in three contexts: the console REPL, the editor input strip, and project-created overlays. The widget is always the same code; what differs is the evaluator attached to it and which controller handles the result.

### Data flow

```
LÖVE2D textinput event
  → love.handlers.textinput (gateway)
    → console/editor route (default slot handler):
        ConsoleController:textinput (dispatches by app_state)
          → editor mode: EditorController:textinput
          → console/overlay mode: UserInputController:textinput
            → UserInputModel:add_text
              → updates InputText (cursor-aware string)
                → view re-renders
    → project route (while a project is 'running'):
        ProjectInputController:textinput
          → the four-tier chain ("Keyboard Handling" below);
            the terminal tier is the same
            UserInputController:textinput/add_text path
```

A project hooks `textinput` either via `compy.input.handlers.textinput[combo]` /
`compy.input.on_text_input` (tiers 2-3 of the chain) or by defining its own
`love.textinput`, which auto-provisions as the tier-3 default when no `on_text_input`
is set (see "Keyboard Handling" below) — draining down into the widget sink is what
happens only when nothing upstream consumes the event.

Text characters arrive via `love.textinput` (OS-processed, handles IME and layout, fires only for character-producing keys). Raw key events arrive via `love.keypressed` — but `keypressed` is **not** restricted to non-character keys: LÖVE2D fires it for every physical key, textual or not. Pressing `q` fires both `keypressed('q')` and `textinput('q')`. (LÖVE2D does not guarantee the relative *order* the two arrive in for the same physical key.)

The "keypressed = control channel, textinput = character channel" split used throughout this doc is therefore **compy's own convention, not a LÖVE2D guarantee**. Nowhere does compy's `keypressed` code filter out or ignore textual keycodes — it simply never gives `k` a match that means "insert this character" (see `UserInputController:keypressed` below: every branch checks `k` against a fixed set of named control keys, or a modifier + letter combo used as a *shortcut*, e.g. Ctrl+C). A bare `keypressed('q')` with no modifier held matches nothing and falls through untouched. All literal character insertion (`UserInputModel:add_text`) is reachable only from `textinput` handlers, plus two `keypressed`-triggered paths that move **existing** text (not the pressed key) into the model — clipboard paste (Ctrl+V) and `load_selection` (Escape, editor mode, loads buffer text into the input).

`isrepeat` is threaded through the gateway and the project route, but not uniformly all the way to every consumer. LÖVE calls `love.handlers.keypressed` with `(key, scancode, isrepeat)`; the gateway (`controller.lua:797`) keeps all three and calls `love.keypressed(k, sc, isr)` unconditionally (`controller.lua:899-900`). From there:
- while a project runs, the project route's `love.keypressed` is `ProjectInputController:keypressed(k, sc, isr)` (`controller.lua:199-201`), which threads `isr` through all four dispatch tiers, sink included (`projectInputController.lua:219-222`) — both `compy.input.on_key_pressed` and the sink receive the uniform `(k, keys_pressed, isrepeat)` triple;
- in console/editor mode the slot function keeps `isr` only to forward it to a shown widget (`forward_keypressed`, `controller.lua:36-41`, called from the console-route default keypressed at `controller.lua:398-436`) — a widget being edited sees repeats; but the fallback call `CC:keypressed(k)` (and, from there, `EditorController:keypressed(k)`) drops it, so console/editor's own mode dispatch never sees `isrepeat`.
Combo-tier dispatch (tiers 1-2 of the project chain) does not gate on `isrepeat` either — see "Key state" below.

### Multiline input

The input is not single-line. `Shift+Enter` inserts a newline (`line_feed()`). The cursor model tracks both line and column. Lines are stored as a `Dequeue<string>` in `InputText`. The view wraps long lines at `drawableChars` width (same wrap machinery as the editor's `VisibleContent`).

LÖVE has no multiline-text concept of its own; it only delivers discrete `textinput`/`keypressed` events, one character or one key at a time. Assembly is entirely compy's own: `UserInputController:keypressed`'s `newline()` local (`userInputController.lua:568-574`) calls `input:line_feed()` whenever Shift+Enter is detected — **unconditionally**; there is no `multiline` config flag gating it (a `show{multiline=...}` key was proposed but never implemented — `userInputModel.lua:499` still carries a `-- TODO multiline`). There is also no separate "keystroke assembly" buffer: `textinput` mutates the model's persistent text immediately and continuously, and Enter (a `keypressed`, not a `textinput`) is a purely discrete control signal that reads whatever the *current* buffer state is (`get_text()`) at the moment it fires. Nothing replays or buffers a keystroke history to reconstruct the submitted text; the live model state *is* the submitted text. True uniformly for console, editor, and the project overlay (all three read `get_text()` at submit time); search has no evaluator/submit concept at all — its Enter jumps to the currently-selected result, not the typed query.

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
- **Project overlays**: `InputEvalText` (plain), `InputEvalLua` (Lua syntax), or a `ValidatedTextEval` with custom validators
- **Search**: `nil` evaluator (search input is free text, no validation)

Validators run on every character (via `validation_hl` for real-time highlighting) and again on submit. A validator returns `true` or `false, Error(msg, column)`. The column is used to highlight the specific offending character.

### Cursor manipulation and "reset" — three API layers, now all connected

Cursor access exists at three layers. **Model** (`UserInputModel`) has the full primitive surface
(`cursor_left/right`, `move_cursor`, `jump_home/end`, `jump_line_start/end`, `get/set_cursor_pos`,
`set_cursor(c)`) — used internally by the model's own `keypressed` handling in response to
arrow/Home/End. **Controller** (`UserInputController`) exposes a narrower passthrough plus a
clamped 2D mover: `get_cursor_info`/`get_cursor_pos`/`set_cursor(Cursor)`/`jump_home`/
`set_cursor_pos(line, col)` — the last one (`userInputController.lua:124-139`) computes its own
clamp against line/text length rather than relying on `move_cursor`'s fallback-to-previous-position
behaviour. **`compy` (project-facing)** now has its own surface on the singleton overlay:
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

The project route runs a per-event chain, tier by tier, each tier
consuming only if it returns truthy — combo handler → project
generic callback → widget-if-shown — with no `if`-governed
native/widget split at the dispatch site and the hidden-check
moved *inside* the sink itself.

### Dispatch chain

```
love.handlers.keypressed (k, scancode, isrepeat)
  → held-key bookkeeping + global shortcuts — controller.lua
    → love.keypressed — the slot occupant (the active route)
      ├─ console/editor (the default slot handler):
      │    → overlay widget shown (except inspect):
      │        UserInputController:keypressed
      │          (k, keys_pressed, isrepeat)
      │    → else ConsoleController:keypressed
      │        → if editor state: EditorController:keypressed
      │        → else: console key handling
      │          → history navigation (PageUp/Down)
      │          → UserInputController:keypressed
      │          → Enter → ConsoleController:evaluate_input
      └─ project run: ProjectInputController — ONE four-tier
           chain, same shape on keypressed/keyreleased/textinput:
           1. framework_handlers.<event>[combo]  (structural
                keys; return/escape land in a later slice)
           2. compy.input.handlers.<event>[combo]  (project
                combo handlers; per-event tables, normalising)
           3. per-event generic callback  (on_key_pressed /
                on_text_input / on_key_released) — precedence:
                explicit on_* > project native captured at
                activate > noop+log
           4. the sink (UserInputController) — terminal; edits
                when shown, INTERNAL no-op when hidden
         Truthy at any tier consumes (stop, sink included);
         falsey falls through. Consuming never removes a tier.
```

`app_state == 'starting'` is never observed by any input path: `main.lua`'s `love.load()` sets it, then flips it to `'ready'` a few lines later — both synchronously, before LÖVE's event pump runs, so no `love.handlers.*` entry point can ever see the `'starting'` value.

Global shortcuts intercepted in `love.handlers.keypressed` (`controller.lua:797+`) before anything reaches the active route's controller: Ctrl+Pause suspends, Ctrl+Q quits project, Ctrl+S stops run or closes buffer, Ctrl+Shift+R resets application, Ctrl+Alt+R restarts project, Ctrl+T quick-switches between run and edit. Ctrl+Esc (quit) is the one exception living on the release side — `love.handlers.keyreleased` (`controller.lua:910-920`), not keypressed. None of these consume the key: it still reaches the active route afterward (§6.3 non-consuming shortcuts).

The gateway (`love.handlers.*`) no longer routes on widget presence — the overlay gate is removed. The slot occupant (the active route's controller) always receives the event. The project route runs the four-tier chain above: a project native auto-provisions as the tier-3 default participant (seen even while the widget is shown, only when the project set no `on_*` — explicit `on_*` takes precedence), and the widget sink is the terminal tier with its hidden-check now *internal* (it no-ops on the published singleton while `love.state.user_input` is nil, so a hidden widget mutates nothing without any external gate). The console-route default handlers still forward to the widget when `love.state.user_input` is set (except under `inspect`). The widget is never a routing destination of the gateway and never a slot occupant. `Controller._keyboard_route` records which controller currently occupies the slot (the `ConsoleController` by default, the `ProjectInputController` during a run) — bookkeeping with no reader beyond its own two assignment sites (`controller.lua:209`, `:434`) today.

**On the `'running'` → `'project_open'` boundary, the project route is disconnected only when the project has no interaction surface left — an interactive non-blocking project keeps it.** A non-blocking project that returns (no `update`/`draw` hooked) drops `app_state` to `'project_open'`; `ConsoleController:run_project` then checks `Controller.user_is_interactive()` (`controller.lua:1112-1113`: `love.state.user_input ~= nil or user_pointer`, the latter set in `hook_pointer` when the project installs any pointer/click handler and reset in `set_default_handlers`). Only when that predicate is false does `run_project` call `Controller.release_keyboard_route(CC)` (`controller.lua:730-735`, `consoleController.lua:266-267`), which calls `Controller.project_input:deactivate()` and **reinstalls the console's own `love.keypressed`/`keyreleased`/`textinput`** — the same slot-reassignment `set_default_handlers` does on project stop, just scoped to the keyboard/text slots (pointer slots stay hooked either way, so pen-and-paper projects remain clickable while `'project_open'`). A project with an active input overlay or a hooked pointer handler instead keeps the project route live: `ProjectInputController` stays the keyboard/text occupant, so the overlay's submit/cancel keep working and `love.quit` (`controller.lua:752-754`) treats `'project_open'` + `user_is_interactive()` the same as `'running'`, stopping to console on Ctrl+Esc rather than letting the app quit. `ProjectInputController` itself has no per-event "am I still running?" forward any more — its own `:keypressed` doc comment (`projectInputController.lua:205-213`) is explicit that this older guard is gone precisely *because* the slots are only ever restored when the route is actually released, so there is nothing left to guard against.

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

Both surfaces are consumed by `ProjectInputController:_dispatch`
(`projectInputController.lua:170-179`), which serialises every
project-route keyboard/text event with `Controller.combo_string`
and looks the result up first against `framework_handlers.<event>`
(tier 1), then `compy.input.handlers.<event>` (tier 2). Downstream
consumers (tiers 2-4, project code included) never see the raw
`Controller.keys_pressed` table directly — they receive a read-only
proxy (`Controller.held_keys()`, `controller.lua:345-367`):
reads pass through to the live set, writes raise. On the shipping
LuaJIT/Lua 5.1 runtime `pairs()` ignores a table's `__pairs`
metamethod, so `pairs(proxy)` silently yields nothing — the proxy
is index-only in practice (`proxy['lctrl']` works, iterating over
it does not); `__pairs` is kept for a future 5.2+ host. There is
no project-facing way to *poll* held keys outside a callback
either — `compy`'s namespace (`get_compy_namespace`,
`consoleController.lua:549-558`) has no `keys_pressed` field; the
proxy only ever arrives as a callback argument.

The whole keypressed path hands the widget sink the uniform
`(k, keys_pressed, isrepeat)` triple — the sink is included by
design (one signature across the path) — but only on the project
route; see "Data flow" above for exactly where `isrepeat` does and
does not reach. Combo dispatch itself does not gate on `isrepeat`:
tiers 1-2 fire on **every** repeat, not just fresh presses — an
in-code `DEFERRED` marker above `ProjectInputController:keypressed`
(`projectInputController.lua:216-218`) records this as an unruled,
provisional leaning (fresh-only at tiers 1-2 was considered, never
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

**The "limit reached" boundary signal has two independent paths today, and the project-facing one
is now a widget output, not a lost return value.** `cursor_vertical_move`/`is_at_limit` return
`true` at a boundary; `UserInputController:keypressed` threads that out as its own return value
(`return ret`, `userInputController.lua:656`) from both branches of its internal `app_state` fork.
Console captures it (`consoleController.lua:1171`, `local limit = input:keypressed(k)`) and uses it
for history nav — this return-value path is **console-only** plumbing, unrelated to the project
surface. Editor discards it (`editorController.lua:803-804`, a bare `input:keypressed(k)` call, no
`local`) — it doesn't need it, since it independently computes boundary state via
`inputView:is_at_limit(...)` at the view layer. For the **project widget**, the same boundary check
additionally calls `self.on_limit_reached(dir, scope)` directly from inside the sink itself
(`emit_limit`, `userInputController.lua:448-449`, called from both `vertical()` and `horizontal()`)
— this is the `compy.input.on_limit_reached(direction, scope)` widget output a project sets via
`show()`/`configure()` or a direct field assignment; it fires regardless of what the chain's return
value does, because widget outputs are explicitly **not** chain-return-value plumbing (the sink is
terminal; nothing above it inspects its return for this purpose). The return-value route and the
`on_limit_reached` route are two separate, independent notification paths that happen to share one
boundary check.

**FR-6 (project notification of key events): the keyboard exclusion is resolved as of 1.0.0-rc20260712.**
Historically, while `love.state.user_input` was set, `controller.lua`'s
`handlers.keypressed`/`handlers.textinput` called *only* the overlay — the project's own
`love.keypressed`/`love.textinput` were not called at all (binary, not partial). With the gate
removed, project key/text events always reach the project route (`ProjectInputController`); which
surface consumes them (the overlay sink while shown, the project's native handler while hidden) is
the route's internal delegation, no longer a gateway drop. Mouse never had this problem:
`handlers.mousepressed`/`mousereleased` call the overlay conditionally but call the project's own
handler **unconditionally**, regardless of overlay state. This is why touch/mouse needed no
separate #77 scope item: only keyboard was ever exclusively gated.

### Editor-specific keys

See `editor.md` for full detail. Key differences from console mode:
- No history navigation (PageUp/Down scroll the buffer instead)
- Up/Down at input boundary moves buffer selection, not history
- Escape loads selected block text into input
- Ctrl+M / Ctrl+F switch modes

The difference is two forks, not one. The **outer** fork is the ConsoleController/EditorController
split already covered above (console handles escape/history/Ctrl+L itself; editor delegates to
`EditorController:keypressed`'s own `edit`/`reorder`/`search` mode dispatch instead). There is also
a **second, inner** fork worth knowing about: the *shared* `UserInputController:keypressed` is not
fully context-blind either — its own body branches on `love.state.app_state == 'editor'`
(`userInputController.lua:633-653`) to decide whether to call its own `cancel()` local at all
(Escape → `model:cancel()`, content reset — only reachable in the non-editor branch, and, for the
project widget, only when the project route's own tier-1 escape entry hasn't already intercepted
the key first, see "UserInputController keypressed" below). That inner branch is **why** editor's
Escape→`load_selection()` (which just populated the input) isn't immediately wiped by the shared
sink's own Escape-cancels-content behavior on the same keypress — the sink skips `cancel()` entirely
when `app_state == 'editor'`. So "which hooks are redefined" isn't just outer-controller dispatch;
the shared sink also self-selects behavior by mode for at least this one case.

### UserInputController keypressed (shared)

`UserInputController:keypressed` handles the low-level input operations that apply regardless of which route is driving it (console, editor, or the project widget): removers (backspace, delete, Ctrl+Y delete line), vertical cursor movement, horizontal movement (Left/Right, Home/End, Alt+Home/End for line vs field boundaries), Shift+Enter newline (unconditional — see "Multiline input" above), Ctrl+D duplicate line, copy/cut/paste (Ctrl+C/X/V and Shift+Insert/Delete), selection management. It never inserts literal characters — see "Text Input Widget" above for why `keypressed` and `textinput` divide the work this way.

There is no `oneshot` flag any more, and no submit path inside this method at all — `UserInputModel.new(cfg, eval, custom_label)` (`userInputModel.lua:45`) takes no such parameter. For the **project widget**, Enter and Escape are intercepted at the project route's tier 1 (`framework_handlers.keypressed['return']`/`['escape']`, installed once at construction in `projectInputController.lua:105-109`) *before* this sink ever sees them: `framework_submit`/`framework_cancel` (`projectInputController.lua:71-98`) call `UserInputController:submit()`/`:cancel()` directly and, whenever a widget is shown, always consume — so this sink's own `cancel()` local (Escape → `model:cancel()`, `userInputController.lua:621-625`) is unreachable for the project widget; it only fires for **console/editor's own routes**, which have no tier-1 layer of their own. Console's own Enter handling stays in `ConsoleController:evaluate_input`; the editor's is `EditorController:_handle_submit` — both unrelated to this shared sink, unchanged from before.

### Key release

On the **project route** keyreleased runs the same unified chain as keypressed/textinput
(combos → generic callback → widget-if-shown, DOM-style truthy-stops-propagation) — see the
dispatch-chain diagram above. The rest of this section concerns the **console route**, which this
pass deliberately did not touch (its legacy fork stays until the console/editor migration).

`keypressed`/`textinput` get careful three-way routing (console / editor / project); **`keyreleased`
gets route-level delegation but no editor fork.** Since 1.0.0-rc20260712, `ProjectInputController:keyreleased`
runs the same four-tier chain as the other channels (combo → `on_key_released` → sink), the released
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
routing is untouched by feature #77).

### Search — a third widget instance, live only in editor/search mode

`EditorController.search` (`editorController.lua:14-17`) wraps its own `SearchController`/`Search`
model pair around its own `UserInputController` instance — a **third** consumer of the shared input
widget primitive, alongside console's own and the editor's main input. It is live only while
`app_state == 'editor'` and `EditorController.mode == 'search'` (entered via Ctrl+F, see
"Editor-specific keys" above). `keypressed` forwards through `EditorController:_search_mode_keys`
(`:485-503`) to `SearchController:keypressed`; `textinput` forwards through `EditorController:textinput`
(`:287-302`) when in search mode. There is no evaluator (search input is free text with no
validation) and Enter jumps to the currently-selected result rather than submitting the typed
query. `SearchController` defines no `:keyreleased` method at all — combined with the missing
editor fork above, search's `UserInputController` instance never receives a release under any
circumstance. `SearchController:clear()` (`searchController.lua:44-47`) reaches past its own
controller straight into `self.model.input:clear_input()`, skipping `clear_error()` — currently
harmless (search has no evaluator, so no error can ever be set) but a layering inconsistency against
every other reset path described above. None of the design documents for feature #77 mention this
surface — it is real, live code with no corresponding entry in the design corpus, carried here as
the first record of it in the permanent doc corpus.

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

### Singleton lifecycle (introduced in an earlier build)

`UserInputController` is a singleton created once in `love.load()`
(in `src/main.lua`) and stored in `love.state.user_input_controller`.
The same model, controller, and view are reused across every overlay
session; per-session allocation is eliminated.

Activation: `compy.input.show(config)` calls
`UserInputController:show(config)`, which sets
`love.state.user_input = { M = model, C = singleton, V = view }`
and runs a view update. Deactivation: `UserInputController:hide()` (or
`hide()` on the `compy.input` table) sets `love.state.user_input = nil`.
`compy.input.*` is the sole project-facing input surface
**(supported since 1.0.0-rc20260712)**; the five legacy globals
(`user_input`, `input_text`, `input_code`, `validated_input`,
`write_to_input`) and the debug-only `astv_input` are
**(deprecated, removed in 1.0.0-rc20260712)** — gone from the
project environment, an ordinary `nil` field, no shim.

`show()` on an already-active singleton is a no-op unless
`{ force = true }` is passed — and the suppression **warns**
(`Log.warn('UserInputController:show ignored — overlay already
active...')`, `userInputController.lua:282`), matching the
framework's warn-don't-swallow convention. With `force`, the text
is replaced if a `text` field is in the config; otherwise the
existing text is preserved. No cancel chain fires in either case.

### Dispatch while active

While a project runs, `compy.input.show(config)`/etc. drive the *same* singleton and the *same*
routing already described under "Keyboard Handling" above — there is no separate "instead of the
main controller" special case any more. In short: the gateway always calls the active route's
slot occupant; the console/editor route's default handler additionally forwards to the widget
(`forward_keypressed`/`forward_textinput`/`forward_keyreleased`) whenever `love.state.user_input`
is set (except under `inspect`); the project route always reaches the widget as its chain's
terminal tier. The overlay view is drawn via `user_input.V:draw()` inside the framework's
`love.update` wrapping of the project draw function (`controller.lua`, `set_love_update`,
`:589-668`).

There is no per-frame polling. When the user presses Enter, submit runs synchronously within that
one keypress — see "Submit and cancel chains" below for the exact order.

### Submit and cancel — the framework tier-1 chains

Enter/Escape on the project widget are framework-level, non-overridable tier-1 participants
(`framework_handlers.keypressed['return']`/`['escape']`, installed once at construction —
`projectInputController.lua:105-109`), engaged only while the widget is shown (`shown_widget()`,
`:61-64`) — hidden, the combo falls through to lower tiers like any other key.

**Submit** (`framework_submit`, `projectInputController.lua:71-81`):

```
before_submit(keys_pressed)
→ UserInputController:submit() (userInputController.lua:380-389):
    validator(text) rejects → error display, input locked until
      acknowledged (Enter/Space/arrows clear it); nothing below fires
    accepts → deliver(text): fills the legacy poll reftable (if a
      project still uses one) and calls on_text_entered(text) while
      the session is still active → hide() (love.state.user_input = nil)
→ after_submit(text) — fires only once ui:submit() returned
    non-nil, i.e. after the widget has already hidden
```

This is what "auto-close on submit" means today: a successful submit synchronously validates,
delivers, and hides within the one Enter keypress — no queued event, no next-tick delay, no
`oneshot` flag gating any of it (the `oneshot`/`love.event.push('userinput')` mechanism this
replaced is gone entirely — see "UserInputController keypressed" above). `before_submit`/
`after_submit` are read directly off the `compy.input` surface by `projectInputController.lua`'s
`run_hook` helper (`:41-56`, `run_hook`/`log_branch`): an unset hook silently debug-logs and the
framework step it brackets still runs regardless; there is no way to veto the framework step from
a hook today — `before_submit`'s return value is ignored (a reserved future extension).

**Cancel** (`framework_cancel`, `projectInputController.lua:88-98`) has no reject path — Escape
always dismisses:

```
before_cancel(keys_pressed)
→ UserInputController:cancel() (userInputController.lua:176-179):
    model:cancel() (content cleared) → hide()
→ after_cancel()
```

`compy.input.hide()` (the programmatic path) fires **no** cancel chain — cancel is the user-facing
Escape path only.

One vestige of the old mechanism remains in the gateway: `love.handlers.userinput`
(`controller.lua:976-981`) still exists and would null `love.state.user_input` if a queued
`'userinput'` LÖVE event ever arrived, but nothing in `src/` pushes that event any more — the old
`oneshot`-gated `love.event.push('userinput')` was removed along with `oneshot` itself. This handler
is unreachable today, not a live part of submit/cancel.

This whole `before_*`/`after_*` + widget-output surface (`on_text_entered`, `on_limit_reached`,
`on_key_pressed`, `on_text_input`, `on_key_released`, `handlers.*`) is now live in `src/` — see
"Keyboard Handling" above for the four-tier dispatch chain these callbacks hang off of.

### `compy.input` namespace

For a project-author usage guide with examples, see
[Compy Input API](../../input_api.md).

`compy.input` is a table created once at namespace setup (`get_compy_input()`,
`consoleController.lua:462-541`, wrapped into the project's `compy` table by
`get_compy_namespace()`, `:549-558`). It exposes:
- `compy.input.show(config)` — activates the singleton
- `compy.input.hide()` — deactivates without firing cancel chain
- `compy.input.get_cursor()` / `set_cursor(line, col)` /
  `set_text(text [, keep_cursor])` — the cursor/text surface; see
  "Cursor manipulation" above for the layering this sits on.
- `compy.input.configure(config)` — live-reconfigures an active
  session; `compy.input.clear()` — resets an active session's
  content.
- `compy.input.handlers.keypressed/keyreleased/textinput` (tier 2)
  and `on_key_pressed`/`on_text_input`/`on_key_released` (tier 3),
  plus `before_submit`/`after_submit`/`before_cancel`/`after_cancel`
  — the dispatch-chain and submit/cancel surfaces described above.

Everything on `compy.input` other than the `handlers` container and
the widget-output/tier-3/submit-cancel callback fields is callable
API: assigning to any of the names above raises loudly rather than
silently replacing the function (`build_input_surface`,
`consoleController.lua:382-397`).

There is no project-facing `is_active()`/`is_shown()` predicate: an
internal `UserInputController:is_shown()` exists
(`userInputController.lua:415-417`) but is not exposed on this
surface — a project that needs to know whether the widget is
currently up reads `love.state.user_input` directly (as
`examples/maze/main.lua` does, with its own per-tick re-arm poll)
rather than calling a `compy.input` method.

#### `show(config)` — activate

All fields are optional and, except where noted, match the
project-facing guide's table (`doc/input_api.md`): `prompt`, `text`,
`cursor` (`{line, col}`, applied after `text` — see "Cursor
manipulation" above), `validator`, `highlighter`, `on_text_entered`,
`on_limit_reached`, `force`. `apply_config`
(`userInputController.lua:211-239`) additionally accepts two keys
outside that table: `eval` (installs an `Evaluator` object directly —
the mechanism `doc/input_api.md`'s own `eval` config key documents
for project authors) and `result` (a legacy reftable the submit path
still fills for the old poll idiom). Neither is a config key in the
frozen feature #77 design spec, whose table lists only `validator`/
`highlighter` — an unrecorded but real and working surface.
`apply_config` reads only its known keys with no `else`/warn branch,
so a config key it doesn't recognise (a typo, or a field-write-only
name like `after_submit` passed inside `show{}` instead of assigned
directly) is **silently dropped** — no error, no log. This is an
inconsistency, not a blanket policy: `set_cursor`/`set_text`, by
contrast, **do** warn when called while hidden
(`consoleController.lua:495`, `:505`).

#### `configure(config)` — the live-reconfigure surface

On an active session, `configure` takes the same config keys as
`show()` and applies only the ones given, immediately: `prompt`,
`highlighter`, `validator`, and the widget-output callbacks
(`on_text_entered`, `on_limit_reached`) take effect from the very
next prompt render / keystroke / submit onward. `text` and `cursor`
are accepted but have **no effect** on an active session —
`configure` never mutates content or the caret; use
`set_text`/`set_cursor` for that, or `clear()` followed by a fresh
`show()`. There is no partial application: each field either
applies in full or is dropped in full, per the rule above — never a
half-applied config.

While hidden, `configure` is always safe and never warns (it is not
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
| `src/controller/controller.lua` | Gateway (`love.handlers.*`), global shortcuts, `keys_pressed`/`combo_string`/held-key proxy, route slot management |
| `src/controller/projectInputController.lua` | The project route: the four-tier dispatch chain, tier-1 submit/cancel |
| `src/controller/consoleController.lua` | Console/editor route dispatch, `compy` namespace + `compy.input` surface construction |

`controller.lua` is consumed from `main.lua` (constructs the singleton, wires
`set_default_handlers`) and `consoleController.lua` (calls into it on every mode
transition — run, stop, suspend, inspect). `projectInputController.lua` is used
only by `controller.lua` (the single `Controller.project_input` instance) and is
never referenced by console/editor code directly. `userInputController.lua`
instances are constructed by `main.lua` (the project singleton),
`editorController.lua` (its own main input and its `search` sub-widget), and
implicitly by console (`consoleModel`/`consoleController`) — see "Search" above
for the third, less obvious instance.
