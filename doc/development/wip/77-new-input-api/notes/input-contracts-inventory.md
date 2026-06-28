# Input Routing — Verified Factual Inventory

<!-- authored by LLM (Opus 4.8); human-approved: NOT YET -->
<!-- P1 of 2: facts only. Contracts are the next task. -->

Scope: how keyboard / text / mouse / touch input is routed
and consumed in the current implementation. Every claim
carries a `file:line` citation. Paths are repo-root relative.

Method: read the four target files exhaustively; cross-checked
read/write sites of `love.state.user_input{,_controller}` and
every `love.<event>` slot via grep over `src/` (LSP available
but field accesses on `love.state` are dynamic; grep was the
reliable backstop and is exhaustive here). UNCERTAIN items are
marked inline. Verified against code, not docs.

Two-name convention used below:
- **gateway** = `love.handlers.<event>` (permanent dispatch).
- **slot / base sink** = `love.<event>` (swappable handler the
  gateway forwards to when no overlay is active).

---

## 1. The gateway

The gateway is the set of `love.handlers.<event>` functions
installed by `Controller.setup_callback_handlers`
(`controller.lua:543`). In stock LÖVE, `love.run` pulls events
and calls `love.handlers[name]`; Compy overrides those entries
so every OS event funnels through one Compy-owned function,
which then decides overlay-vs-slot.

Install site & timing:
- Called exactly once in boot, from `main.lua:373`
  (`ctrl.setup_callback_handlers(CC)`), immediately before
  `set_default_handlers` at `main.lua:374`.
- The handlers table is frozen after install:
  `table.protect(love.handlers)` (`controller.lua:797`).
- No other site reassigns `love.handlers.*`. The only other
  reader is the Harmony test loop, which *invokes*
  `love.handlers[n](...)` for synthetic events
  (`harmony/init.lua:67`) — an alternate feeder, not a second
  installer.

Lifetime: **permanent**. Installed once, never reinstalled,
never torn down. What changes at runtime is the *slot*
(`love.<event>`) each gateway entry forwards to, not the
gateway entry itself.

Events the gateway defines (`controller.lua`):
`keypressed` (554), `textinput` (660), `keyreleased` (669),
`mousepressed` (689), `mousereleased` (705), `mousemoved`
(726), `userinput` (737), `touchpressed` (750),
`touchreleased` (767), `touchmoved` (784).

**`wheelmoved` is NOT in the gateway.** There is no
`handlers.wheelmoved`. Wheel events therefore use LÖVE's
default `love.handlers.wheelmoved`, which calls the
`love.wheelmoved` *slot* directly, bypassing the overlay
entirely. See §4 and §11. (The slot itself IS installed —
`set_love_wheelmoved`, `controller.lua:296`.)

---

## 2. `app_state` enumeration

`love.state.app_state` is a free-form string field on
`love.state` (typed `LoveState`). Distinct values found
(verified by grepping every `app_state =` / `== '...'` in
`src/`):

- **`starting`** — set in the initial `love.state` literal
  (`main.lua:286`). The pre-init instant.
- **`ready`** — console idle, no project open. Set at end of
  `love.load` (`main.lua:319`) and on `close_project`
  (`consoleController.lua:890`).
- **`project_open`** — a project is open but not running.
  Set after a run finishes non-blocking
  (`consoleController.lua:256`, `:260`), on `open_project`
  success (`:864`), and on `stop_project_run` (`:927`).
- **`running`** — project run is live and (possibly) owns
  slots. Set at the top of `run_project`
  (`consoleController.lua:253`) and on `continue` from inspect
  (`:576`).
- **`snapshot`** — transient one-frame state used to grab a
  screenshot before suspending. Set by `suspend_run`
  (`consoleController.lua:833`); consumed in the update loop
  (`controller.lua:427`) which captures the screen then calls
  `CC:suspend()`.
- **`inspect`** — project run halted/paused, REPL usable
  against the project env. Set by `suspend`
  (`consoleController.lua:815`).
- **`editor`** — code editor open. Set by `edit`
  (`consoleController.lua:960`); the prior state is stashed in
  `love.state.prev_state` and restored by `finish_edit`
  (`:982`).
- **`shutdown`** — app is quitting. Set in `exit`
  (`main.lua:36`) and in `love.quit` for play mode
  (`controller.lua:484`).

NOTE: `cfg.mode == 'play'` (`main.lua`, playback build) is a
**separate** axis from `app_state`, not a value of it. It
gates the console off and changes shortcut handling (§7).

UNCERTAIN: whether `starting` is ever observed by an input
path — by the time any event arrives, `app_state` is already
`ready` or later. Listed for completeness.

---

## 3. Slot ownership (the base sink)

### Default ownership

In every non-running state the slots are owned by the
framework defaults, all routed to the single
`ConsoleController` (CC). `set_default_handlers`
(`controller.lua:503`) installs them via the `set_love_*`
setters:
- keyboard: `keypressed`/`keyreleased`/`textinput`
  (`controller.lua:504-506`) → `CC:keypressed/...`.
- mouse: `mousemoved`/`mousepressed`/`mousereleased`/
  `wheelmoved` (`:509-512`).
- touch: `touchpressed`/`touchreleased`/`touchmoved`
  (`:514-516`).
- `update` (`:535`), `draw` (`:537`), `quit` (`:539`).

Each setter both assigns the live slot (`love.<event> = fn`)
and records the same fn in `Controller._defaults[event]`
(e.g. `controller.lua:215-216` for keypressed). So
`_defaults` is the framework's canonical slot table, captured
at install time.

CC then re-dispatches by `app_state`: in `editor` it forwards
to `self.editor` (`consoleController.lua:995`, `:1033`,
`:1102`...); otherwise to `self.input` (the console
`UserInputController`). So the *default* per-event owner is
CC, which sub-routes editor-vs-console internally.

### How a running project overrides slots

On project start, `run_user_code` calls
`cc.main_ctrl.set_user_handlers(env['love'], cc)`
(`consoleController.lua:115`) = `set_handlers`
(`controller.lua:73`, aliased at `:800`). For each event in
`_supported` (`controller.lua:28-41`:
keypressed, keyreleased, textinput, mousemoved, mousepressed,
mousereleased, wheelmoved, touchmoved, touchpressed,
touchreleased) it runs `hook_if_differs` (`:75`):
- reads `orig = _defaults[key]`, `new = userlove[key]`;
- only if **both exist and differ**, sets
  `love[key] = CC:wrap_handler(new, wrap)`
  (`controller.lua:78-81`).

So a project overrides only the events it actually defined;
others keep the default slot. `wrap_handler`
(`consoleController.lua:202`) wraps in `use_canvas` + the
`wrap`/`xpcall` error handler (`controller.lua:59`).

`update` and `draw` are special-cased (NOT in `_supported`):
- custom `update` → stored in `_userhandlers.update`,
  `user_update=true` (`controller.lua:89-93`).
- custom `draw` → `love.draw` replaced by
  `udr(); View.drawFPS()` (`:96-106`), `user_draw=true`.

### Restore on stop — exactly how & when

`stop_project_run` (`consoleController.lua:918`) restores
wholesale, not per-key:
1. `evacuate_required()` unloads project modules (`:919`).
2. `set_default_handlers(self, view)` (`:920`) — reinstalls
   ALL default slots over whatever the project set.
3. `set_love_update` (`:921`), then `user_input = nil`
   (`:922`), `View.clear_snapshot()` (`:923`),
   `set_love_draw` (`:924`).
4. `clear_user_handlers()` (`:925`) resets
   `_userhandlers = {}` and clears the snapshot
   (`controller.lua:830`).
5. `app_state = 'project_open'` (`:927`).

So restoration = unconditional re-install of defaults; the
project's slot fns are simply overwritten, not reverted
individually.

### Suspend / inspect / continue path

- `suspend` (`consoleController.lua:809`, fired from the
  `snapshot` update branch) calls
  `save_user_handlers(env['love'])` then
  `set_default_handlers` (`:824-825`). `save_user_handlers`
  (`controller.lua:807`) saves each `_supported` event that
  differs from default into `_userhandlers`, plus `draw`
  (`:818-822`). NOTE: `update` is NOT saved here — it already
  lives in `_userhandlers.update` from the run.
- `continue` (`consoleController.lua:573`, only from
  `inspect`) sets `app_state='running'` and
  `restore_user_handlers` → `set_handlers(_userhandlers, cc)`
  (`controller.lua:826-828`), re-hooking the saved project
  slots.

### Roles, summarised

- `_defaults` (`controller.lua:172`) — canonical framework
  slot table; the baseline `hook_if_differs`/`save_if_differs`
  compare against.
- `_supported` (`controller.lua:28`) — the event list the
  hook/save sweeps iterate; defines which events are
  project-overridable as slots. `update`/`draw` are handled
  outside it.

---

## 4. Per-event routing

For each event, the question is: gateway → overlay sink, base
slot, or both; EXCLUSIVE vs BOTH; order; guards. "overlay" =
`get_user_input()` non-nil. The overlay gate is
`get_user_input()` (`controller.lua:19`): returns
`love.state.user_input`, **but returns nil when
`app_state == 'inspect'`** (`controller.lua:20`) even if the
overlay is set — an inspect-time suppression (see §11).

### keypressed (`controller.lua:554`)

Order within the gateway:
1. `keys_pressed[k] = true` (`:555`) — always, first.
2. Global shortcuts run (§7), gated by play-vs-normal
   (`:635-650`). **Non-consuming.**
3. `user_input = get_user_input()` (`:652`):
   - if set → `user_input.C:keypressed(k)` (`:654`)
     — EXCLUSIVE (base slot not called).
   - else → `return love.keypressed(k)` (`:656`)
     — base slot.
So keyboard delivery is **EXCLUSIVE** (overlay OR slot).
isrepeat is dropped at the signature (§8).

### textinput (`controller.lua:660`)

Overlay set → `user_input.C:textinput(t)` (`:663`); else
`love.textinput(t)` (`:665`). **EXCLUSIVE.**

### keyreleased (`controller.lua:669`)

1. `keys_pressed[k] = nil` (`:670`) — always, first.
2. Guard: `Key.ctrl()` + `k=='escape'` →
   `love.event.quit()` (`:671-674`). Non-consuming.
3. Overlay set → `C:keyreleased(k)` (`:678`); else
   `love.keyreleased(k)` (`:680`). **EXCLUSIVE.**

### mousepressed (`controller.lua:689`)

1. Overlay set → `C:mousepressed(...)` (`:692`).
   (empty `else` branch, `:693`.)
2. Unconditionally after: `if love.mousepressed then
   return love.mousepressed(...)` (`:695-697`).
**BOTH** — overlay AND base slot, overlay first. No
EXCLUSIVE gate. No state guard (the inspect guard still
applies via `get_user_input`, suppressing only the overlay
half).

### mousereleased (`controller.lua:705`)

1. If `btn == 1`: `click_count++`, `click_timer =
   click_delay`, `click_pos = {x,y}` (`:706-710`) — framework
   click detection, always.
2. Overlay set → `C:mousereleased(...)` (`:713`).
3. Unconditionally: `love.mousereleased(...)` (`:716`).
**BOTH**, overlay first, then slot. Click confirmation is
resolved later in update (§10).

### mousemoved (`controller.lua:726`)

Overlay set → `C:mousemoved(...)` (`:729`); then
unconditionally `love.mousemoved(...)` (`:732`). **BOTH.**

### wheelmoved

No gateway entry (§1). LÖVE's default
`love.handlers.wheelmoved` calls the `love.wheelmoved` slot
directly. The slot default routes to `CC:wheelmoved`
(`controller.lua:299`), which forwards to editor input
(if `cfg.editor.mouse_enabled`) or `self.input:wheelmoved`
(a TODO no-op, `userInputController.lua:604`). **Slot only —
overlay NEVER sees wheel events.** EXCLUSIVE-to-slot by
omission. A running project that sets `love.wheelmoved` takes
the slot via `hook_if_differs` (wheelmoved IS in `_supported`).

### touchpressed / touchreleased / touchmoved
(`controller.lua:750` / `:767` / `:784`)

Each: overlay set → `C:touch*(...)`; then unconditionally
`love.touch*(...)`. **BOTH**, overlay first. The overlay's
touch handlers are all `--- TODO` no-ops
(`userInputController.lua:614`, `:625`, `:636`).

### Editor sub-routing (when `app_state == 'editor'`)

The base slot owner CC re-routes to `self.editor` for
keypressed/textinput (`consoleController.lua:995`, `:1033`)
and to `self.editor.input` for mouse/touch — but only when
`cfg.editor.mouse_enabled` / `touch_enabled`
(`:1102-1204`), both **false** by default
(`main.lua:333-335`). So in editor mode mouse/touch are
effectively disabled by default.

---

## 5. `user_input` read/write sites

### `love.state.user_input` (the `{ M, C, V }` overlay handle)

WRITES (set):
- `open_fresh` → `{ M=model, C=self, V=view }`
  (`userInputController.lua:222`) — the activation write.

WRITES (clear to nil):
- `UserInputController:hide` (`userInputController.lua:258`).
- gateway `clear_user_input` local, called from
  `handlers.userinput` (`controller.lua:548`, invoked `:740`).
- `set_love_quit` play-mode quit (`controller.lua:485`).
- `stop_project_run` (`consoleController.lua:922`).

READS:
- `get_user_input` (`controller.lua:21`) — the gateway gate,
  read on every routed event (§4) and in the draw loop
  (`:409`).
- `show` re-entry guard (`userInputController.lua:235`).
- legacy `input()` already-active guard
  (`consoleController.lua:603`).
- `write_to_input` reads `.C` (`consoleController.lua:653`).

### `love.state.user_input_controller` (the singleton)

WRITE: assigned once at boot
(`main.lua:371`, `= ui_c`). Never reassigned.

READS:
- `compy.input.show` / `.hide`
  (`consoleController.lua:350`, `:354`).
- legacy `input()` wrapper (`consoleController.lua:608`).

### `get_user_input` / `clear_user_input` / `handlers.userinput`

- `get_user_input` (`controller.lua:19`): inspect-guarded
  read of `user_input` (§4).
- `clear_user_input` (`controller.lua:547`): sets
  `user_input = nil`.
- `handlers.userinput` (`controller.lua:737`): if overlay
  set, calls `clear_user_input` — i.e. a pushed `'userinput'`
  event deactivates the overlay. Emitted by the model on a
  successful oneshot submit (`userInputModel.lua:819`, or the
  Harmony-routed variant `:815`). This is the auto-close on
  submit.

---

## 6. Overlay (widget) lifecycle

`show(config)` (`userInputController.lua:233`):
- `cfg = config or {}`.
- If `love.state.user_input` already set (active):
  - no `force` → `Log.warn(... already active ...)` and
    return (`:236-239`). Warn-on-suppression IS present.
  - `force=true` → applies ONLY the `text` subset: if
    `cfg.text ~= nil`, `set_text` + `update_view`; other
    fields ignored by design (`:241-248`). No cancel chain.
- Else (inactive) → `open_fresh(self, cfg)` (`:250`).

`open_fresh` (`userInputController.lua:211`):
- if `cfg.text == nil` → `model:clear_input()` (activation
  policy: re-show with no text starts empty).
- `apply_config` (`:215`): sets `eval` if given, `custom_label
  = prompt` if non-nil, `set_text` if `text` non-nil,
  `self.result = cfg.result` if non-nil (`:187-202`).
- writes `love.state.user_input = { M, C, V }` (`:222`).
- `update_view()` once (`:227`).

`hide()` (`userInputController.lua:257`): sets
`love.state.user_input = nil`. No cancel chain fires.

`{ M, C, V }` shape: `M = self.model`, `C = self` (the
singleton controller), `V = self.view` (`:222-226`). The
draw loop reads `ui.V:draw()` (`controller.lua:411`); legacy
poll reads `.C`/`.M`.

`force` semantics: text-only live update on an active overlay;
full reconfigure deferred to compy.input API
(comment `:241-243`). Already-active no-op without `force` =
warn + return.

---

## 7. Global shortcuts (top of keypressed)

All live inside `handlers.keypressed` (`controller.lua:554`),
AFTER `keys_pressed[k]=true` and BEFORE the
`get_user_input()` dispatch. **None consume the event** — the
key still flows on to overlay or slot at `:652-657`. They run
conditionally on `playback` (`cfg.mode=='play'`):

Normal mode (`controller.lua:643-650`):
- `restart()` — Ctrl+Alt+R → `CC:restart()` (`:606-610`).
- `quickswitch()` — Ctrl+t (no alt): toggles between
  run/inspect/project_open and the editor; in editor (normal
  mode) finishes edit and runs (`:556-578`).
- `profile()` — Ctrl+Alt+P (+Shift to stop) and F10 cycles
  FPS counter position (`:611-633`), gated on `love.PROFILE`.
- `project_state_change()` (`:579-605`), all under
  `Key.ctrl()`:
  - Ctrl+pause → `suspend_run(user_break)`.
  - Ctrl+q → `quit_project()`.
  - Ctrl+s → if running `stop_project_run`; if editor,
    Shift→`finish_edit` else `close_buffer`.
  - Ctrl+Shift+r → `reset()`.

Play mode (`controller.lua:635-642`): only `restart()` and
`profile()` run; plus if `app_state=='shutdown'`,
`love.event.quit()`. `quickswitch`/`project_state_change`
are skipped.

Also note a release-side global: in `handlers.keyreleased`,
Ctrl+escape → `love.event.quit()` (`controller.lua:671-674`),
likewise non-consuming.

DEBUG-only shortcuts live in the *default slot* keypressed
(`set_love_keypressed`, `controller.lua:187-214`), not the
gateway: Ctrl+Shift+1/2/3/5 toggle debug views, Ctrl+Alt+d
dumps terminal debug — guarded by `love.DEBUG`. These reach
CC only when no overlay intercepts (EXCLUSIVE keyboard path).

---

## 8. `keys_pressed`, `combo_string`, `isrepeat`

`Controller.keys_pressed` (`controller.lua:179`): a
`{ keyname -> true }` table on the global `Controller`.
- add at the very top of `handlers.keypressed`
  (`:555`), before shortcuts/dispatch.
- remove at the very top of `handlers.keyreleased`
  (`:670`).
- Stored with raw LÖVE names; l/r NOT folded (`lctrl` and
  `rctrl` are distinct entries).

`combo_string(k, keys_pressed)` (`controller.lua:148`):
serialises to a canonical combo string. Iterates
`COMBO_MODS = Key.mod_triples` (`controller.lua:138`,
`key.lua:16`) in precedence order ctrl, alt, shift, gui;
for each, if either l/r variant is held, appends the generic
name; then appends `k`; `table.concat(parts, '+')`. So
`lctrl` held + `s` → `"ctrl+s"`; nothing held → just `k`.
Exposed as `Controller.combo_string` (`:180`).

UNCERTAIN/notable: `combo_string` is defined and exported but
has **no caller in `src/` yet** (grep finds only the
definition/export). It is staged for the planned
ProjectInputController dispatch, not wired into the current
sink. `keys_pressed` itself is maintained but also not read
by any current sink.

`isrepeat`: **structurally dropped at the gateway
signature.** `handlers.keypressed = function(k)`
(`controller.lua:554`) binds only `k`; LÖVE supplies
`(key, scancode, isrepeat)` but the extra args are never
captured. The default slot `keypressed(k)`
(`controller.lua:188`) and `CC:keypressed(k)` are likewise
single-arg. So `isrepeat` never reaches any handler; it is
"suppressed" simply by not being in the parameter list, at
`controller.lua:554` (gateway) and `:188` (slot). This
answers the open doc question in §11.

---

## 9. Legacy solicitation path

The legacy text-solicitation API is built in
`prepare_project_env` (`consoleController.lua:514`):

- `user_input()` (`:631`): calls `create_input_handle()`
  which does `input_ref = table.new_reftable()` (`:592-593`)
  and returns it. The reftable is a `__call` table: `r()`
  pops `self.value` (and clears it), `r(v)` stores;
  `r:is_empty()` is `value == nil` (`util/table.lua:3-28`).
- `input(eval, prompt, init)` (`:601`): the shared entry.
  Guards, each warning-not-silent (rule C2):
  - if `love.state.user_input` set → `Log.warn('input()
    ignored — an input overlay is already active')`, return
    (`:603-605`).
  - if no `user_input_controller` → warn + return
    (`:608-611`).
  - if no `input_ref` → `Log.warn('... call user_input()
    first')`, return (`:613-615`).
  - else `uic:show({ eval, prompt, text=init,
    result=input_ref })` (`:619`) and returns `input_ref`
    (`:628`).
- `input_code(prompt, init)` → `input(InputEvalLua, ...)`
  (`:638`).
- `input_text(prompt, init)` → `input(InputEvalText, ...)`
  (`:643`).
- `validated_input(filters, prompt)` →
  `input(ValidatedTextEval(filters), prompt)` (`:667`).
- `astv_input()` → `input(LuaEditorEval)`, only if
  `love.debug` (`:671-675`).
- `write_to_input(content)` (`:650`): reads
  `love.state.user_input`; if absent `Log.warn('write_to_input
  ignored — no active input overlay')` and return; else
  `overlay.C:set_text(content)`.

Polling: the project calls `r:is_empty()` / `r()` (typically
in its `love.update`). The submit path writes the result into
the reftable: in `UserInputController:keypressed` →
`submit()`, on a oneshot Enter, `input:evaluate()` succeeds
and `res(t)` stores the unlined text into the reftable
(`userInputController.lua:438-453`). Separately the model
pushes the `'userinput'` event (`userInputModel.lua:819`)
which clears the overlay (§5). So one successful submit both
fills the reftable and closes the overlay.

Removal/migration markers: comments tag `input_code` /
`input_text` / `user_input` for removal in 0.1.0-m8 and
`write_to_input` replacement by `compy.input.set_text` in
m7/m8 (`consoleController.lua:594-600`, `:647-649`).

---

## 10. Mouse / click specifics

Single/double-click detection is framework-level, split
across the gateway and the update loop:
- Module-level state: `click_delay = 0.4`,
  `drift_tolerance = 2.5`, `click_count`, `click_timer`,
  `click_pos` (`controller.lua:109-115`).
- `handlers.mousereleased` (`:705`): on `btn==1`, increments
  `click_count`, resets `click_timer = 0.4`, records
  `click_pos = {x,y}` (`:706-710`).
- Update loop (`set_love_update`, `controller.lua:364`):
  decrements `click_timer` by dt (`:369-371`); when it
  reaches ≤0 (`:372`):
  - `click_count == 1` → resolve `compy.singleclick` via
    `CC:get_compy_handler('singleclick')` (`:375`).
  - `click_count >= 2` → `compy.doubleclick` (`:386-388`).
  - both wrapped (`CC:wrap_handler(handler, wrap)`) and
    invoked with current mouse pos only if `no_drift(click_pos,
    cur)` (`:380-394`).
  - then `click_count = 0` (`:397`).
- `no_drift` (`controller.lua:120`): true only if both |dx|
  and |dy| between press-pos and current pos are
  `< drift_tolerance` (2.5px). Drift beyond tolerance
  suppresses the click.
- `get_compy_handler` (`consoleController.lua:216`) looks up
  `env['compy'][name]` in the *project* env — so
  `compy.singleclick` / `compy.doubleclick` are
  project-defined Compy abstractions, not LÖVE events.
  Defaults are no-ops in `_defaults`
  (`controller.lua:173-174`).

Consequence: there is no instant single-click — a single
click is confirmed only after the 0.4s window expires with no
second release.

Overlay-AND-project double delivery: confirmed at the gateway
for mouse (`mousepressed` `:695`, `mousereleased` `:716`,
`mousemoved` `:732`) and touch (`:756`, `:773`, `:790`) —
the overlay sink AND the base slot both receive the raw
event (§4, BOTH). The `singleclick`/`doubleclick` resolution
above is a *third*, derived delivery driven from update, not
the raw slot.

---

## 11. Doc-vs-code discrepancies

Against `doc/development/internals/user_input.md` (and the
sibling docs), which the prompt flags as a lead, not truth:

1. **wheelmoved is not gatewayed.** The doc ("Direct mouse
   events") lists `love.wheelmoved` among events "forwarded
   directly to project handlers" and implies the
   overlay-AND-user pattern applies. In code there is no
   `handlers.wheelmoved`; wheel reaches only the slot, never
   the overlay (§1, §4). The slot path is real; the
   overlay-also claim is wrong for wheel.

2. **inspect-time overlay suppression is undocumented.**
   `get_user_input` returns nil when `app_state == 'inspect'`
   (`controller.lua:20`), so during inspect the overlay is
   bypassed and events flow to the base slot even if
   `user_input` is set. The doc's "if `user_input` is set,
   events go to the overlay" omits this guard.

3. **`isrepeat` — the doc's open question is answerable.**
   The doc asks "where is isrepeat suppressed and why". Answer
   (§8): it is dropped at the gateway/slot signatures
   (`controller.lua:554`, `:188`), which bind only `k`. Not a
   deliberate filter — a narrow parameter list.

4. **keyboard/text delivery is EXCLUSIVE, mouse/touch is
   BOTH.** The doc describes the overlay as taking over key
   input ("bypassing the main input") but for mouse says the
   framework "calls the user handler AND the overlay". Both
   halves are individually correct, but the doc does not state
   the contrast as a single rule: keyboard/text = EXCLUSIVE
   (overlay XOR slot, `:654/:656`, `:663/:665`); mouse/touch
   = BOTH (overlay then slot unconditionally). Worth making
   explicit for the contract task.

5. **Line-number drift.** The doc cites "global shortcuts
   (controller.lua:520+)" and "click handling
   (controller.lua:662+)". Actual: shortcuts begin at the
   `handlers.keypressed` body ~`:556`; click increment is at
   `:706`; click resolution in update at `:372`. Minor drift,
   code wins.

6. **`combo_string` / `keys_pressed` are staged, not wired.**
   The doc presents them as the surface "consumed by the
   ProjectInputController dispatch" (future) — accurate as
   intent, but worth recording as a present-state fact: today
   they have no consumer in `src/` (§8). `keys_pressed` is
   maintained; `combo_string` is exported but uncalled.

7. **Singleton lifecycle — doc is correct, milestone labels
   noted as the author's own gripe.** `user_input_controller`
   is created once (`main.lua:371`) and never reassigned;
   `show`/`hide` toggle `user_input`. The doc's content
   matches code; its inline `>` notes (milestone naming,
   warn-on-suppress) are largely now addressed — e.g.
   warn-on-suppress IS implemented
   (`userInputController.lua:238`), contrary to the doc's
   open suggestion.

8. **Editor mouse/touch default-off not in the input doc.**
   Editor-state mouse/touch reach `editor.input` only when
   `cfg.editor.mouse_enabled`/`touch_enabled`, both false by
   default (`main.lua:333-335`). The doc mentions editor
   `disable_selection` but not the controller-level gate.

No discrepancies found in: the `{ M, C, V }` shape, the
`force` text-only semantics, the reftable poll mechanism, the
0.4s/2.5px click constants — all match code.

---

## Coverage / status

- Sections 1–11: all filled, verified against code.
- Discrepancy count (§11): **8** (1 substantive code-vs-doc
  error re: wheelmoved; the rest omissions, drift, or
  now-resolved open notes).
- UNCERTAIN items: (a) whether `app_state=='starting'` is ever
  seen by an input path (§2); (b) confirming `combo_string`
  has zero current callers — based on exhaustive grep of
  `src/`, treated as a strong negative but flagged (§8).
- Read-only: no files under `src/` or `tests/` changed; the
  frozen `design/` dir untouched. This inventory is the only
  file created.
