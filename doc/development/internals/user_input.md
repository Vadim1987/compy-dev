# User Input — Implementation Overview

<!-- authored By LLM; human-approved NOT YET -->

Input handling in Compy has two mostly independent layers: **text/keyboard input** (the input widget shared across console, editor, and project overlays) and **mouse/pointer input** (handled partly by the framework, partly delegated to projects). This doc covers both, with mode-specific notes where the behavior differs.

Companion doc — the routing **contracts** (what must hold across the feature #77 rewrite, with provenance and stability tags): [`wip/77-new-input-api/notes/input-contracts.md`](../wip/77-new-input-api/notes/input-contracts.md). This doc stays the descriptive "how it works today" narrative; the contracts doc is where OUTCOME-vs-MECHANISM and blast-radius classification live.

---

## Text Input Widget

`UserInputModel` / `UserInputController` / `UserInputView` form a shared widget reused in three contexts: the console REPL, the editor input strip, and project-created overlays. The widget is always the same code; what differs is the evaluator attached to it and which controller handles the result.

### Data flow

```
LÖVE2D textinput event
  → love.handlers.textinput
    → ConsoleController:textinput (dispatches by app_state)
      → editor mode: EditorController:textinput
      → console/overlay mode: UserInputController:textinput
        → UserInputModel:add_text
          → updates InputText (cursor-aware string)
            → view re-renders
```
> NOTE: this doc does not show handling events via project -- neither via new Controller nor via old 'overlay'. it *mentions* overlay but does not show how UserInputController:textinput is triggered
> Also, do we have (or will we implement) a mechanism that will hook project code to e.g. 'textinput' (not just draining it down into UserInputController, which I assume is default/last-resort if no custom handling of textinput is defined by project)?

Text characters arrive via `love.textinput` (OS-processed, handles IME and layout, fires only for character-producing keys). Raw key events arrive via `love.keypressed` — but `keypressed` is **not** restricted to non-character keys: LÖVE2D fires it for every physical key, textual or not. Pressing `q` fires both `keypressed('q')` and `textinput('q')`.

The "keypressed = control channel, textinput = character channel" split used throughout this doc is therefore **compy's own convention, not a LÖVE2D guarantee**. Nowhere does compy's `keypressed` code filter out or ignore textual keycodes — it simply never gives `k` a match that means "insert this character" (see `UserInputController:keypressed` below: every branch checks `k` against a fixed set of named control keys, or a modifier + letter combo used as a *shortcut*, e.g. Ctrl+C). A bare `keypressed('q')` with no modifier held matches nothing and falls through untouched. All literal character insertion (`UserInputModel:add_text`) is reachable only from `textinput` handlers, plus two `keypressed`-triggered paths that move **existing** text (not the pressed key) into the model — clipboard paste (Ctrl+V) and `load_selection` (Escape, editor mode, loads buffer text into the input).
> Side-question (resolved): does KP fire for character keys too? **Yes**, confirmed — this was previously flagged as "evidence, unconfirmed"; it's now established as LÖVE2D's actual behavior, not app-level filtering.
> Side-question (still open): does LÖVE2D guarantee the *order* textinput/keypressed arrive in for the same physical key? Not verified — treat as unconfirmed.
> Side-question (resolved): what about 'isrepeat' modifier? Where its defined, where its suppressed
> and why? **Stripped at the very first hop, before any mode fork exists to make a choice about it.**
> `love.handlers.keypressed = function(k)` (`controller.lua:554`) — a single-parameter override of
> LÖVE's own dispatch slot — is the outermost interception point; LÖVE calls it with
> `(key, scancode, isrepeat)`, but the override's signature only names `k`, so `scancode`/`isrepeat`
> are silently discarded before `ConsoleController`, `EditorController`, `SearchController`, or the
> project singleton ever see the event. None of them "choose" to ignore repeats — they never get the
> chance. There is no code anywhere in `src/` today that reads `isrepeat` or `scancode` (confirmed:
> zero matches). Threading it back through is planned infrastructure (`design/design.md` §3,
> `keys_pressed`/combo work, 0.1.0-m4/m5) — see
> [`notes/keyreleased-isrepeat-events.md`](../../wip/77-new-input-api/notes/keyreleased-isrepeat-events.md).

### Multiline input

The input is not single-line. `Shift+Enter` inserts a newline (`line_feed()`). The cursor model tracks both line and column. Lines are stored as a `Dequeue<string>` in `InputText`. The view wraps long lines at `drawableChars` width (same wrap machinery as the editor's `VisibleContent`).

> What assembles multiline input together, providing special handling of Shift+Enter? Love2d? Custom
> code in UserInputController? **Resolved:** custom code. `UserInputController:keypressed`'s
> `newline()` local (`userInputController.lua:387-393`) calls `input:line_feed()` when Shift+Enter is
> detected — LÖVE has no multiline-text concept; it only delivers discrete `textinput`/`keypressed`
> events, one character or one key at a time. There is also no separate "keystroke assembly" buffer:
> `textinput` mutates the model's persistent text immediately and continuously (character-by-character,
> live), and Enter (a `keypressed`, not a `textinput`) is a purely discrete control signal handled
> separately — it reads whatever the *current* buffer state is (`get_text()`) at the moment it fires
> and runs the evaluator against that. Nothing replays or buffers a keystroke history to reconstruct
> the submitted text; the live model state *is* the submitted text. True uniformly for console,
> editor, and the project overlay (all three read `get_text()` at submit time); search has no
> evaluator/submit concept at all — its Enter jumps to the currently-selected result, not the typed
> query.

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

### Cursor manipulation and "reset" — three API layers, and a real FR-1 gap

Cursor access exists at three layers that don't line up. **Model** (`UserInputModel`) has the full
primitive surface (`cursor_left/right`, `move_cursor`, `jump_home/end`, `jump_line_start/end`,
`get/set_cursor_pos`, `set_cursor(c)`) — used internally by the model's own `keypressed` handling in
response to arrow/Home/End. **Controller** (`UserInputController`) exposes a narrower passthrough:
`get_cursor_info`/`get_cursor_pos`/`set_cursor`/`jump_home` only. **`compy` (project-facing)**
exposes none of it yet — `get_compy_input()` (`consoleController.lua:347-358`) is `show`/`hide` only.

There are exactly **two** current call sites that manipulate the cursor programmatically (i.e., not
as a direct response to an arrow/Home/End keypress) in the entire codebase, both in
`editorController.lua`, both live: `load_selection` (`:590-604`, reads/restores the cursor via the
**controller** API to preserve the caret across an insert) and `reject_oversized` (`:628-633`,
called from two live submit paths, jumps the cursor to a rejected block's start via
**`input.model:move_cursor` directly, bypassing the controller**). Console and search never touch
it programmatically; the project overlay has no way to yet. `UserInputModel:set_cursor(c)` is a
raw, **unvalidated** assignment (`self.cursor = c`) — safe today only because every caller already
supplies a pre-validated `Cursor`; a future `compy.input.set_cursor(line, col)` would be the first
caller ever handed an arbitrary project-supplied pair, with no existing bounds-check precedent to
build on.

**FR-1's "initial cursor position" is not implemented.** `UserInputModel.new(cfg, eval, oneshot,
custom_label)` (`userInputModel.lua:47-66`) hardcodes `cursor = Cursor()` — always `(1, 1)` — with
no cursor constructor parameter; `UserInputController:show(cfg)`'s `force` path also only patches
`cfg.text`, never a cursor. Confirmed gap, not a stub to extend. Full trace, plus the four
inconsistent "reset the prompt" implementations (console/editor/search/project each do it
differently — Ctrl+L vs. Escape vs. Ctrl+W vs. Ctrl+Q vs. nothing at all for the project overlay):
[`notes/cursor-and-reset-operations.md`](../../wip/77-new-input-api/notes/cursor-and-reset-operations.md).

---

## Keyboard Handling

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
      └─ project run: ProjectInputController:keypressed
           → widget shown: the text-editing sink
               (UserInputController, uniform triple)
           → widget hidden: the project's own native
               love.keypressed, if it defined one (via the
               auto-provisioned lifecycle-split wrapper)
           → neither: no-op (a hidden widget consumes
               nothing; no other consumer exists)
```

Global shortcuts in `love.handlers.keypressed` (controller.lua:520+) are intercepted before anything reaches the controller: Ctrl+Pause suspends, Ctrl+Q quits project, Ctrl+S stops run or closes buffer, Ctrl+Shift+R resets application, Ctrl+Alt+R restarts project, Ctrl+Esc exits app.

> our plan includes firing "before_quit", "before_suspend" on the project? 

As of 0.1.0-m4 the gateway (`love.handlers.*`) no longer routes on widget presence — the overlay gate is removed. The slot occupant (the active route's controller) always receives the event and forwards to the overlay widget itself when one is shown: the console-route default handlers forward when `love.state.user_input` is set (except under `inspect`), and `ProjectInputController` delegates to the same widget as its text-editing sink. The widget is never a routing destination of the gateway and never a slot occupant. On project stop the console is the *named* restore target — `Controller.active_keyboard_route()` reports the occupant (the ConsoleController by default, the project route during a run).

While a project run occupies the slots but the state has left `'running'` (a non-blocking project that returned: `app_state == 'project_open'`), `ProjectInputController` forwards events to the console default handlers — non-running states route to the console (the REPL stays live after a script finishes).

> what defined the overlay controller before we introduced the singleton change? Was every projet defining their own controller and view, or they simply read the r() for text input values, with everything else being totally obscure for them? Was the recreation of M,V,C triade (before change) just a brute-force way of resetting the state, not leaving anything behind?

**`inspect` mode overrides all of the above.** While `app_state == 'inspect'` (a paused/broken-into project), the console REPL owns every input channel and a project-set overlay is not honoured, regardless of the routing described above — see [`input-contracts.md`](../wip/77-new-input-api/notes/input-contracts.md) §5.4 for the full current-behaviour trace (mechanism, provenance, and why it's carried provisional rather than fixed).

### Key state: `Controller.keys_pressed` and `combo_string`

`Controller.keys_pressed` is a `{keyname → true}` table maintained on
the global `Controller`. It is updated at the very top of
`love.handlers.keypressed` (add) and `love.handlers.keyreleased`
(remove), before any downstream handler runs. Key names are LÖVE2D
canonical (`"lctrl"`, `"rshift"`, `"return"`, etc.); left/right
variants are stored without folding — `lctrl` and `rctrl` are two
separate entries, not merged into `ctrl`.

> Let's mark "introduced in version..." like Love2D does. Can also include "planned for version" instead of milestone references

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

These two surfaces will be consumed by the `ProjectInputController`
dispatch table (`compy.input.handlers[combo]`), planned for 0.1.0-m5.
Since 0.1.0-m4 the gateway no longer drops `isrepeat`/`scancode` at
the slot signature, and the whole keypressed path hands the widget
sink the uniform `(k, keys_pressed, isrepeat)` triple — the sink is
included by design (one signature across the path; see
`input-contracts.md` §9). The sink's own implementation still binds
only `k`; it starts consuming the extra arguments when its dispatch
milestone (0.1.0-m5) lands.

### Console-specific keys

- **PageUp/PageDown**: history back/forward
- **Up/Down at input boundary**: also triggers history navigation (handled as a "limit reached" return from `UserInputController:keypressed`)
- **Enter** (no shift): submit → `evaluate_input()`
- **Ctrl+L**: clear terminal output
- **Shift+Enter**: insert newline in input (multiline expression)

> In this context what is 'console-specific'? Specific for console mode? If so, are they interpreted at console controller (where they would belong) or in generic controller (which would therefore be assuming duties of specific mode and which would be wrong?)? 

**The "limit reached" signal (FR-7) already propagates through most of the stack — traced
precisely.** `cursor_vertical_move` returns `true` at a boundary; `UserInputController:keypressed`
threads it out as its own return value (`return ret`, `userInputController.lua:481-482`) from
*both* branches of its internal `app_state` fork, so it's available everywhere. Console captures it
(`consoleController.lua:1058`, `local limit = input:keypressed(k)`) and uses it for history nav.
Editor discards it (`editorController.lua:803-805`, a bare `input:keypressed(k)` call, no `local`)
— but doesn't need it, since it independently computes boundary state via
`inputView:is_at_limit(...)` instead (a separate mechanism, at the view layer). The project overlay
dispatch (`controller.lua`'s `handlers.keypressed`) also calls it bare and has no `on_limit_reached`
callback to hand it to yet — this is the one point where the signal is genuinely lost, not
recomputed elsewhere. Full trace:
[`notes/fr2-fr6-fr7-provenance-and-gaps.md`](../../wip/77-new-input-api/notes/fr2-fr6-fr7-provenance-and-gaps.md).

**FR-6 (project notification of key events): the keyboard exclusion is resolved as of 0.1.0-m4.**
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

> Techically, how its different? Which hooks are redefined? **Partially resolved:** the outer
> difference is the ConsoleController/EditorController fork already covered above (console handles
> escape/history/Ctrl+L itself; editor delegates to `EditorController:keypressed`'s own
> `edit`/`reorder`/`search` mode dispatch instead). But there's a **second, inner** fork worth
> knowing about: the *shared* `UserInputController:keypressed` is not fully context-blind either —
> its own body branches on `love.state.app_state == 'editor'` (`userInputController.lua:456-479`) to
> decide whether to call its own `cancel()` local at all (Escape → `model:cancel()`, content reset).
> That inner branch is **why** editor's Escape→`load_selection()` (which just populated the input)
> isn't immediately wiped by the shared sink's own Escape-cancels-content behavior on the same
> keypress — the sink skips `cancel()` entirely when `app_state == 'editor'`. So "which hooks are
> redefined" isn't just outer-controller dispatch; the shared sink also self-selects behavior by
> mode for at least this one case. Full trace:
> [`notes/cursor-and-reset-operations.md`](../../wip/77-new-input-api/notes/cursor-and-reset-operations.md) §5.

### UserInputController keypressed (shared)

`UserInputController:keypressed` handles the low-level input operations regardless of context: removers (backspace, delete, Ctrl+Y delete line), vertical cursor movement, horizontal movement (Left/Right, Home/End, Alt+Home/End for line vs field boundaries), Shift+Enter newline, Ctrl+D duplicate line, copy/cut/paste (Ctrl+C/X/V and Shift+Insert/Delete), selection management. It never inserts literal characters — see "Text Input Widget" above for why `keypressed` and `textinput` divide the work this way.

> what 'regardless of context' means there? Projects can or cannot redefine their own hooks?

The `oneshot` flag on `UserInputModel` (set for project overlays) enables a submit path inside `UserInputController:keypressed` — on Enter, the evaluator runs and the result is sent to the callback. Console submission is handled separately in `ConsoleController:keypressed`, not here.

> what exactly 'oneshot' is? I do not get it. Is it auto-triggering of text evaluator when Enter is
> keypressed? Is it reasonable way of handling event? Is there better way, are we planning for it?
> **Resolved:** yes, exactly that — `oneshot=true` is what makes the *generic*
> `UserInputController:keypressed`'s own `submit()` local (`userInputController.lua:438-454`) run the
> evaluator on Enter, instead of leaving submission to the owning controller. It is a per-`UserInputModel`
> constructor flag (`UserInputModel(cfg, evaluator, oneshot, label)`), **`true` only for the one project
> singleton** built in `main.lua:363`; console (`consoleModel.lua:15`), the editor's main input
> (`editorModel.lua:14`), and search (`searchModel.lua:31`) all construct with `oneshot` false/omitted.
> That is why console and editor each have their **own** separate Enter-handling
> (`ConsoleController:evaluate_input`, `EditorController:_handle_submit`) instead of relying on this
> generic path — this shared sink's built-in auto-submit exists *specifically* for the project overlay,
> which has no owning mode-controller of its own to do it. Whether there's a "better way" — not
> addressed by #77 as scoped; `oneshot` is slated for deletion only once console/editor migrate
> (`design/design.md` §3, "`UserInputController` singleton"). Full trace, including the
> `love.event.push('userinput')` side effect this flag also gates:
> [`notes/keyreleased-isrepeat-events.md`](../../wip/77-new-input-api/notes/keyreleased-isrepeat-events.md).

### Key release

`keypressed`/`textinput` get careful three-way routing (console / editor / project); **`keyreleased`
gets route-level delegation but no editor fork.** Since 0.1.0-m4, `handlers.keyreleased` dispatches
to the slot occupant like the other channels: during a project run `ProjectInputController:keyreleased`
delegates to the shown widget, else to the project's native `love.keyreleased` (sink delegation only —
no release dispatch tier exists; that scope is descoped, see the 0.1.0-m4 outcome ledger). On the
console route the default handler forwards to a shown widget, else falls to `CC:keyreleased`
= `ConsoleController:keyreleased` (`consoleController.lua:1090-1093`), which **unconditionally** calls
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
routing discipline. See
[`notes/keyreleased-isrepeat-events.md`](../../wip/77-new-input-api/notes/keyreleased-isrepeat-events.md)
for the full trace.

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

### Singleton lifecycle (since 0.1.0-m2)
> Milestone identifiers are meaningless in persistent documentation. Let's stick to semantic versioning and speak about current version -- maybe with prefixes like x.y-m2...

`UserInputController` is a singleton created once in `love.load()`
(in `src/main.lua`) and stored in `love.state.user_input_controller`.
The same model, controller, and view are reused across every overlay
session; per-session allocation is eliminated.

Activation: `compy.input.show(config)` (or the legacy wrapper
`input_code()`/`input_text()`) calls `UserInputController:show(config)`,
which sets `love.state.user_input = { M = model, C = singleton, V = view }`
and runs a view update. Deactivation: `UserInputController:hide()` (or
`hide()` on the `compy.input` table) sets `love.state.user_input = nil`.

`show()` on an already-active singleton is a no-op unless
`{ force = true }` is passed. With `force`, the text is replaced if
a `text` field is in the config; otherwise the existing text is
preserved. No cancel chain fires in either case.

> Functional adjustment: let's warn if 'show' without force is suppressed? (rationale: no silent action)

### Dispatch while active

While `love.state.user_input` is set:

- **Text input** (`love.handlers.textinput`): goes to `user_input.C:textinput(t)` instead of the main controller
- **Key input** (`love.handlers.keypressed`): goes to `user_input.C:keypressed(k)`
- **The overlay view** is drawn via `user_input.V:draw()` inside the
  framework's `love.update` wrapping of the project draw function
  (`controller.lua`, `set_love_update`)

> we're going to disable the path "instead of main controller", aren't we? Worth mentioning

The project polls `r:is_empty()` in `love.update`. When the user presses Enter, the evaluator runs, and if it passes, the result is stored in the `reftable` ref. On the next `update()`, `r:is_empty()` returns false, `r()` returns the value and resets to empty.

> the project can poll r:is_empty() from wherever? love.update is just typical place to do that? 
> worth mentioning we're going to deprecate this way of polling? (do we?)
> I am sure that overlay view is not always redrawn -- it was a problem in balloons on the game end? or it was a different problem (model not updated, therefore view reflecting old model)?

### The `'userinput'` LÖVE event — how the overlay auto-hides after submit

This is the only "event" (in the pub/sub sense) fired from inside any input consumer today, and it
exists solely for this singleton — console, editor, and search never fire or observe it.

`UserInputModel:handle(eval)` (`userInputModel.lua:803-821`), reached from both `evaluate()` and
`cancel()`, does `if self.oneshot then love.event.push('userinput') end` after a **successful**
evaluate. `love.event.push` queues a custom LÖVE event rather than acting immediately, so the
current frame's `love.update()` still sees `r:is_empty() == false` (the project can still read
`r()`) before anything is torn down. On the *next* tick, LÖVE dispatches the queued event to
`love.handlers.userinput` (`controller.lua:737-742`), whose entire body is: if the overlay is still
active, `clear_user_input()` (`love.state.user_input = nil` — the same effect as calling `hide()`).
That one-tick delay is *why* the auto-hide is a queued event and not a direct call in `handle()`.

Because `self.oneshot` is `true` only for the project singleton (`main.lua:363`; console/editor/search
all construct with it false, see the `oneshot` note above), this whole mechanism is invisible outside
the project-overlay path — console and editor submissions never push or dispatch `'userinput'`, and
have no equivalent auto-hide (they aren't hidden/shown lifecycle objects in the first place). There is
no other generic event/callback bus in the current input code — `compy.input.on_key_pressed`,
`on_text_entered`, `handlers[combo]`, `before/after_submit`, `before/after_cancel`, `on_limit_reached`
(§ design surfaces below) do not exist in `src/` yet (confirmed: zero matches repo-wide) — they are
M4–M6 design vocabulary, not current implementation.

### `compy.input` namespace

`compy.input` is a table created once at namespace setup (inside
`get_compy_namespace()` in `consoleController.lua`). It exposes:
- `compy.input.show(config)` — activates the singleton
- `compy.input.hide()` — deactivates without firing cancel chain

(Planned for 0.1.0-m7: `configure`, `clear`, `get_cursor`,
`set_cursor`, `set_text`. The `compy.input` namespace itself is new
in 0.1.0-m2.)

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
| `src/controller/controller.lua` | Global key dispatch, click detection, user handler management |
| `src/controller/consoleController.lua` | Top-level key/text dispatch, overlay creation API |

> key files are good, but its not clear what uses them
