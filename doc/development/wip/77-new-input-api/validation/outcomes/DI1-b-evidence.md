# DI1-b — evidence dossier: doc A §6–§9 fidelity + corpus-home audit

Worker: Sonnet evidence tier. Scope: `doc/development/wip/77-new-input-api/notes/input-contracts.md`
§6–§9 only (lines 525–859). Verified against `src/**` (grep + `mcp__lua-lsp__references` +
full-file reads) — never against `tests/**`, per the circularity guard. Corpus-home checks against
`doc/input_api.md`, `doc/development/internals/user_input.md`, `doc/development/decisions/input.md`,
`doc/development/technical_debt/input.md`, `doc/development/tests.md`.

Read `validation/outcomes/DI1-a-evidence.md` first; reusing its anchor facts (`get_user_input`
survives as CC's intra-route forward; `ProjectInputController` occupies the keyboard/text slots via
`occupy_keyboard`) without recontesting them.

`mcp__lua-lsp__references` was loaded and used for the two claims the prompt specifically flagged
(§6.1/§6.2 "zero `src/` consumers") — see those rows for the query results (noisy output: many hits
land in a `.patch` file under `implementation/pr-slices/` and in stale `*.tmp.494.*` indexer
artifacts that don't exist on disk; both are non-live-code noise, filtered out below).

---

## 6. Cross-cutting contracts

### 6.1 — Held-key set lifecycle [mechanism-guard]

**Claim(s):** `Controller.keys_pressed` is added-on-press/removed-on-release, always, before any
shortcut/sink dispatch; raw LÖVE names, left/right unfolded. **"Zero current `src/` consumers
outside itself"** — `Key.ctrl/shift/alt()` bypass it via `love.keyboard.isDown()`; it is inert,
staged ahead of the planned combo dispatch (§7.4), "not yet-consumed internal state."

**Code check:**
- Bookkeeping confirmed exactly as described: `Controller.keys_pressed[k] = true` is the literal
  first statement of `handlers.keypressed` (`controller.lua:874`), before `quickswitch`/
  `project_state_change`/`restart`/`profile`/the trailing `love.keypressed(...)` call; `= nil` is
  the first statement of `handlers.keyreleased` (`controller.lua:993`), before the Ctrl+Escape
  quit check. Raw (unfolded) names: the table is keyed directly on `k`, the raw LÖVE name.
- **The "zero consumers" claim is now FALSE — this is the central §6.1 finding.**
  `mcp__lua-lsp__references` on `held_keys` (the read-only proxy factory over
  `Controller.keys_pressed`) returns real call sites beyond bookkeeping: `controller.lua:44`
  (`forward_keypressed`), `:53` (`forward_textinput`), `:62` (`forward_keyreleased`) — CC's own
  intra-route forward to its widget — **and** `projectInputController.lua:259,265,273`
  (`ProjectInputController:keypressed/textinput/keyreleased`, each calling
  `self:_dispatch(event, k_or_t, k_or_t, Controller.held_keys(), isr?)`). The proxy value is then
  threaded through `_dispatch`'s varargs to **all four tiers** — `framework_submit`/
  `framework_cancel` (`projectInputController.lua:83,101`, `function(_, keys_pressed) ...
  run_hook(ci, 'before_submit'/'before_cancel', keys_pressed)`) genuinely consume it (passed to a
  project-settable hook), and it reaches the sink (`UserInputController:keypressed/textinput/
  keyreleased`) as the `keys_pressed` parameter — though inside the widget body itself the
  parameter is accepted but never referenced (grepped the full body of all three methods,
  `userInputController.lua:472-886`: `keys_pressed` appears only in signatures/doc-comments, never
  in a live expression — the widget's own editing logic still reads modifiers via `Key.*`, exactly
  as the widget's own doc-comment at `:466-469` says). So: real consumers exist (PIC's tier-1
  hooks), but the *widget* itself is still a non-consumer as doc-A implies for `Key.*`.
- The persistent corpus has already independently confirmed this: `internals/user_input.md`, "Key
  state" section (line ~200): *"Both surfaces are consumed by `ProjectInputController:_dispatch`
  ... Downstream consumers ... receive a read-only proxy (`Controller.held_keys()`) ..."* — this
  directly contradicts doc-A's "zero consumers," using the exact same code.

**Axis 1 (fidelity):** **superseded-by-shipped.** The bookkeeping mechanism (add-on-press/
remove-on-release, unfolded names) is still-true. But the "zero `src/` consumers outside itself /
inert infrastructure staged ahead of §7.4" framing is no longer accurate: §7.4's dispatch has
landed and *is* a real, live consumer of `held_keys()` (not merely staged). Reading this as the
expected temporal inversion (like §5.1/§5.2 in DI1-a): the "todo, no consumer yet" note anticipated
exactly the dispatch wiring that has since shipped.

**Axis 2 (corpus home):** already-covered, and the corpus is *more current* than doc-A here.
`internals/user_input.md` "Key state: `Controller.keys_pressed` and `combo_string`" states the
current (post-consumer) reality directly, including the `_dispatch` consumer and the
`held_keys()`/proxy mechanics (`__pairs` LuaJIT caveat included). `technical_debt/input.md`
"`keys_pressed` can go stale on focus loss" and "Held-key proxy iteration is index-only" cover two
adjacent debt angles.

**Notes for consolidation:** this is the single highest-value correction in this dossier — doc-A's
own "zero consumers, do not treat as preserve-forever" framing, if promoted as-is, would actively
mislead a reader about current reality. The corpus doc already has it right; doc-A should not be
merged for this content, only (if anything) superseded by pointing at the corpus section.

---

### 6.2 — Combo serialisation [stable-now]

**Claim(s):** `Controller.combo_string(k, keys_pressed)` serialises to a canonical string
(ctrl/alt/shift/gui precedence, folded l/r, bare key if no modifiers) — the serialisation *format*
is durable. **"Today this function and `keys_pressed` have no in-`src/` consumer ... staged for the
planned dispatch, §7."**

**Code check:** Serialisation logic confirmed unchanged (`controller.lua:381-389`,
`COMBO_MODS = Key.mod_triples`). The "no consumer" half is **false for the same reason as §6.1**:
`mcp__lua-lsp__references` on `combo_string` shows the real consumer at
`projectInputController.lua:199-200` inside `_dispatch`:
```lua
function ProjectInputController:_dispatch(event, trigger, ...)
  local combo = Controller.combo_string(trigger, Controller.keys_pressed)
  local fw = self.framework_handlers[event][combo]
  if fw and fw(...) then return true end
  local ph = self.compy_input.handlers[event][combo]
  if ph and ph(...) then return true end
  ...
```
This is the load-bearing tier-1/tier-2 combo lookup for every project keyboard/text event — not
staged infrastructure, the actual routing mechanism.

**Axis 1 (fidelity):** **superseded-by-shipped.** Same inversion as §6.1: the "staged for §7"
framing has landed; `combo_string` is now the core of PIC's dispatch, called on every keypressed/
textinput/keyreleased event while a project runs.

**Axis 2 (corpus home):** already-covered, more current than doc-A. `internals/user_input.md` "Key
state" section states this directly ("Both surfaces are consumed by
`ProjectInputController:_dispatch`"); `decisions/input.md` Decision 8 (per-event combo sub-tables)
provides the decision-level framing. `technical_debt/input.md` "Combo-string dispatch allocates a
table per call" and "`combo_string` does not normalise the case of a textinput token" cover
adjacent, still-open debt on this same mechanism.

**Notes for consolidation:** pair with §6.1 — both rows are the same underlying correction
(doc-A's "inert, no consumer" framing for the `keys_pressed`/`combo_string` pair is stale; the
corpus already documents the shipped consumer relationship correctly).

---

### 6.3 — Global shortcuts are non-consuming [stable-now]

**Claim(s):** Framework shortcuts (Ctrl+Pause, Ctrl+Q, Ctrl+S, Ctrl+Shift+R, Ctrl+Alt+R, Ctrl+T,
profile keys, Ctrl+Escape-on-release) fire but never consume — the key still reaches its sink.
Play mode narrows the active set to restart/profile.

**Code check:** `handlers.keypressed` (`controller.lua:872-984`): `quickswitch`/
`project_state_change`/`restart`/`profile` are all local functions invoked unconditionally
(non-playback branch, `:955-963`) or narrowed (playback branch, `:951-954`: only `restart()` +
`profile()`), and **none** of their bodies ever returns or otherwise short-circuits — the function
always falls through to `if love.keypressed then return love.keypressed(k, sc, isr) end`
(`:982-984`). `handlers.keyreleased` (`:991-1000`) similarly always calls `love.keyreleased(k)`
after the Ctrl+Escape check. Play-mode narrowing confirmed exactly: `local playback = cfg.mode ==
'play'` (`:863`), `if playback then ... restart(); profile() else ... restart(); quickswitch();
profile(); project_state_change() end` (`:951-963`).

**Axis 1 (fidelity):** still-true, both the non-consuming guarantee and the play-mode narrowing —
unchanged by #77 (this layer sits above the route/slot rewrite entirely).

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Console-specific keys" /
"Dispatch chain" region documents the shortcut layer; `decisions/input.md` Decision 1's framing
("Widgets are reached inside the route, never gated here... Mirrors stock LÖVE's
`love.handlers[name] -> love[name]`") matches the code comment at `controller.lua:975-981`
near-verbatim.

**Notes for consolidation:** none; clean match.

---

### 6.4 — Slot restoration on project stop [stable-now]

**Claim(s):** On stop, every slot is restored to the framework default wholesale (not per-key);
after stop no project handler remains wired anywhere. "Current realization: `set_default_handlers`
reinstalls defaults... the forward, sink-named form is §7.2."

**Code check:** `set_default_handlers` (`controller.lua:807-859`) confirmed wholesale: deactivates
PIC, then reinstalls all ten `set_love_*` slots (`keypressed`/`keyreleased`/`textinput`/
`mousemoved`/`mousepressed`/`mousereleased`/`wheelmoved`/`touchpressed`/`touchreleased`/
`touchmoved`) plus `update`/`draw`/`quit`, unconditionally — no per-key/per-slot logic, matching
"wholesale, not per-key." Separately, `release_keyboard_route` (`controller.lua:798-803`) is a
**narrower**, keyboard/text-only restoration used at the `'running'→'project_open'` boundary
(`consoleController.lua:256,270`): `Controller.project_input:deactivate(); set_love_keypressed(CC);
set_love_keyreleased(CC); set_love_textinput(CC)` — this is the "named to `ConsoleController`"
form doc-A's §7.2 anticipates, and it now coexists with (not replaces) the wholesale
`set_default_handlers` used on full stop-to-console-owned-states.

**Axis 1 (fidelity):** still-true for the described "today" mechanism (`set_default_handlers` is
exactly as characterized); the "forward, sink-named form is §7.2" pointer is itself now accurate
in a stronger sense than doc-A frames it — see §7.2 below, that named form has **landed** as a
second, real code path, not merely a future one.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Dispatch chain" section and
`decisions/input.md` Decision 11 ("route connects only while running").

**Notes for consolidation:** worth flagging to the orchestrator that there are now **two** distinct
restoration mechanisms (wholesale `set_default_handlers` vs. narrow `release_keyboard_route`) where
doc-A's §6.4/§7.2 pairing implies a single "today" vs. single "forward" — the shipped reality has
both, used at different transition edges.

---

### 6.5 — Legacy solicitation path [stable-now]

**Claim(s):** `user_input()`/`input()`/`input_code()`/`input_text()`/`validated_input()`/
`astv_input()`, polled via `r:is_empty()`/`r()`, guarantee: one submit both fills the reftable and
closes the widget; warn-on-suppression, never silent. "This whole path is marked for removal at
_0.1.0-m8_; until then its guarantees above hold."

**Code check:** **The legacy path is entirely gone from `src/**` today.** Grepped
`src/controller/*.lua` and `src/model/**` for definitions of `user_input`, `input`, `input_code`,
`input_text`, `validated_input`, `astv_input`, `write_to_input` as global/env functions — zero
hits; only `love.state.user_input` (the singleton *flag*, unrelated name collision) and a
`types.lua` type annotation remain. `git log` confirms the removal commit:
`b4d96eca987a150f91526902be1d71fa911e9dc0` — *"refactor(input)!: remove legacy text-input globals +
poll machinery (M8-03)"*: *"Deletes the five legacy project-env globals
(user_input/input_code/input_text/write_to_input/validated_input), the debug-only sixth global
astv_input ... the input()/input_ref/create_input_handle poll-a-reftable plumbing behind them...
all consumers were already migrated onto compy.input.* ... BREAKING CHANGE: the five legacy globals
+ astv_input are gone from the project environment; calling any of them is now an ordinary nil
call, no shim, no deprecation path."* Git log shows this as the **terminal chunk of the #77 sweep**
(`f2470f9 docs(input): land M8-03 review — APPROVE — #77 new-input-API sweep COMPLETE`). Confirmed
on the tracked/shipped side: `src/examples/tixy/main.lua` (tracked, migrated per the M8-01 commit)
now calls `compy.input.set_text`/`compy.input.show{...}`/`after_submit`/`after_cancel` exclusively
— zero legacy-global calls. (Aside, not part of the fidelity finding: the working tree also has
**untracked** `src/vadexamples/**` — `git status` shows `?? src/vadexamples/` — containing
pre-migration copies that still call `user_input()`/`r:is_empty()`; these are stale scratch, not
part of the shipped/tracked codebase, and are themselves already flagged in
`technical_debt/input.md`, "Untracked scratch examples call removed input globals.")

**Axis 1 (fidelity):** **superseded-by-shipped**, decisively. Doc-A's own framing ("until then its
guarantees hold... marked for removal at 0.1.0-m8") already anticipated exactly this outcome; "then"
has now arrived — there is no path left whose guarantees to hold. Reading doc-A's §6.5 today
describes a removed subsystem, in present tense, as if live.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` and `internals/console.md` were
explicitly re-synced by the M8-03 commit itself ("Syncs internals/user_input.md and
internals/console.md to document compy.input.* as the sole project-facing input surface");
`technical_debt/input.md` "Controller-side dead `result`/reftable delivery path" and "Untracked
scratch examples call removed input globals" capture the residue. `doc/input_api.md` "Migration
from the legacy globals" is the direct replacement content.

**Notes for consolidation:** the strongest single "delete, don't promote" candidate in this
dossier — the content is not just already-covered, it's actively describing removed code; keeping
it around risks a reader treating a dead API's "guarantees" as live.

---

### 6.6 — Widget activation / reset guarantees [stable-now, with forward sub-notes]

**Claim(s) (bulleted, restating §3):** already-active w/o `force` → warn+no-op;
already-active w/ `force` → today only `text` subset; fresh activation w/ no text → empty; `hide()`
deactivates without a cancel chain; auto-close on submit "today via a pushed `userinput` event."
Plus two inline forward-tagged notes: **(a)** "[superseded FORWARD/0.1.0-m6] ... from 0.1.0-m6
`hide()` and cancel paths *do* fire a cancel chain"; **(b)** "[stable-now = the flag-gate; reconfig
scope FORWARD] ... 0.1.0-m7 `configure()`... whether `force` itself widens, or `configure()` owns
reconfigure." Plus the "four incompatible `reset()`/cancel implementations, and a two-layer cursor
split — out of #77 blast radius" paragraph.

**Code check:**
- First three bullets: confirmed unchanged, identical to DI1-a's §3 finding (`show`/`open_fresh`,
  `userInputController.lua:288-310`).
- **`hide()` still does not fire a cancel chain** (`userInputController.lua:319-320`: bare
  `love.state.user_input = nil`) — this specific bullet is still-true, unchanged.
- **But a real cancel chain now exists, reached a different way**: `UserInputController:cancel()`
  (`:179-181`) = `self.model:cancel(); self:hide()`, and PIC's tier-1 `framework_cancel`
  (`projectInputController.lua:99-107`) brackets it: `run_hook(ci, 'before_cancel', keys_pressed);
  ui:cancel(); run_hook(ci, 'after_cancel')`. So forward-note (a)'s 0.1.0-m6 "named submit/cancel
  chains" **have landed** — as `cancel()` (a distinct method from `hide()`), not as a change to
  `hide()` itself. Doc-A's inline forward-note is accurate in substance but is about to describe the
  present, not a future milestone.
- **Auto-close-on-submit mechanism is stale**: `submit()` (`userInputController.lua:409-416`) calls
  `deliver(self, text)` then `self:hide()` directly — a synchronous call, not an event push. The
  code's own comment confirms the change: *"fills the legacy poll reftable — the push('userinput')
  producer is gone, the synchronous fill survives"* (`:381-383`). `handlers.userinput`
  (`controller.lua:1069-1074`) still exists but nothing calls `love.event.push('userinput')`
  anywhere in `src/**` (grepped) — it is unreachable dead code, already flagged in
  `technical_debt/input.md` ("`love.handlers.userinput` is dead code").
- Forward-note (b) (0.1.0-m7 `configure()`): landed — `consoleController.lua` "build_input_surface"
  region exposes `compy.input.configure`, `get_cursor`/`set_cursor`/`set_text` on the project
  surface (`:520-545`); `UserInputController:configure` exists (grepped, real method). The
  text-only-on-`force` gate itself is unchanged (`show`'s `force` branch still only patches
  `cfg.text`, `:298-307`) — `configure()` is confirmed the answer to doc-A's own "open design read":
  `configure()` owns reconfigure, `force` did not widen.
- **Four-incompatible-`reset()` + cursor-split paragraph**: `internals/user_input.md`, "Cursor
  manipulation and 'reset' — three API layers, now all connected" (lines 77-119) states the
  *identical* structural finding almost verbatim — same four reset mechanisms (Console Ctrl+L/
  Escape/Ctrl+Q/Ctrl+Shift+R; Editor Ctrl+W + repurposed Escape; Search's `clear()` bypassing its
  own controller; Project has none) — and explicitly says *"Carried as-is; not touched by this
  pass"*, i.e. this specific sub-claim is **still current, deliberately unresolved**. However the
  **cursor-layer** description has partially moved: doc-A says "`compy`: nothing yet" for the
  project-facing cursor layer; the corpus doc (and code, `consoleController.lua:520-545`) show
  `compy.input.get_cursor()`/`set_cursor(line, col)` now exist (0.1.0-m7 landed) — so "compy:
  nothing yet" is **stale**, while "Controller: narrower passthrough missing `jump_end`/
  `cursor_left`/`right`/`move_cursor`" is confirmed **still accurate**
  (`UserInputController` exposes `get_cursor_info`/`get_cursor_pos`/`set_cursor`/`jump_home`/
  `set_cursor_pos` only — grepped, no `jump_end`/`cursor_left`/`cursor_right`/`move_cursor` methods
  on the controller). `UserInputModel:set_cursor(c)` confirmed still a raw, unvalidated assignment
  (`userInputModel.lua:508-510`: `self.cursor = c`, no validation).

**Axis 1 (fidelity):** **split.** First three bullets + the reset-implementations paragraph:
still-true. "`hide()` no cancel chain": still-true (narrowly, as stated). "Auto-close via pushed
`userinput` event": **stale-mechanism** (now a direct synchronous `hide()` call). Forward-note (a)
(m6 cancel chains): **superseded-by-shipped** (landed, via `cancel()`, not `hide()`). Forward-note
(b) (m7 `configure()`/cursor scope question): **superseded-by-shipped**, and doc-A's own open
question is now answered by the code (`configure()` owns reconfigure). Cursor-split paragraph:
**partially superseded** — the "compy: nothing yet" clause is stale (compy cursor surface now
exists); Model/Controller-layer description is unchanged/still-true.

**Axis 2 (corpus home):** already-covered, but note the *actual* home for the cursor/reset material
is `internals/user_input.md` "Cursor manipulation and 'reset'" — **not**
`technical_debt/input.md` as the task brief's own hint suggested (see Uncertainties). The forward
notes' m6/m7 landings are covered by `internals/user_input.md` "Submit and cancel — the framework
tier-1 chains" and "`configure(config)` — the live-reconfigure surface" respectively;
`decisions/input.md` Decision 6 (named submit/cancel) and the `input_api.md` "Live reconfigure"
section.

**Notes for consolidation:** the "pushed `userinput` event" mechanism note is a clean small
stale-mechanism correction (outcome unchanged, implementation detail wrong) — cheap to flag even if
the section isn't promoted. The cursor-split paragraph is the *one* place in §6–§9 where the task
brief's technical_debt/input.md prediction doesn't quite land — flagging explicitly below.

---

### 6.7 — Framework click detection [stable-now]

**Claim(s):** Single click confirmed only after a 0.4s window; suppressed if drift > 2.5px;
confirmation invokes project-defined `compy.singleclick`/`doubleclick` (not a LÖVE event) — a third
path distinct from raw widget/sink delivery (§5.5).

**Code check:** `click_delay = 0.4`, `drift_tolerance = 2.5` (`controller.lua:338-339`); click-count/
timer state machine at `:1039-1041` (increment on release) and `:651-679` (per-`update()` tick:
`click_timer` counts down, on expiry dispatches to `CC:get_compy_handler('singleclick')`/
`('doubleclick')`, `no_drift` check gates the call). Exactly as described, including the "confirmed
only after the window, no instant single click" framing.

**Axis 1 (fidelity):** still-true — unrelated to the #77 routing rewrite (framework-level pointer
feature, orthogonal to keyboard/text slot ownership).

**Axis 2 (corpus home):** already-covered, closely (near-identical prose). `internals/user_input.md`
"Mouse Input" § "Framework-level click handling" states the same mechanism with the same
constants and the same "no instant single click" framing.

**Notes for consolidation:** none; clean match.

---

## 7. Forward contracts — all four rows re-verified as landed

### 7.1 — Project key/text reach a project sink [forward / 0.1.0-m4]

**Claim:** A first-class `ProjectInputController` receives keypressed/textinput/keyreleased for a
running project and occupies those slots; the rewrite removes the overlay gate.

**Code check:** `occupy_keyboard` (`controller.lua:233-248`) installs
`love.keypressed/textinput/keyreleased` as closures over `pic` (`Controller.project_input`), called
from `set_handlers` (`:295-300`) at project-run start; no `get_user_input()`/widget-presence check
anywhere in the installation or in `ProjectInputController:keypressed/textinput/keyreleased`
(`projectInputController.lua:257-274`), each of which runs the full `_dispatch` four-tier chain
regardless of widget state. Matches DI1-a's anchor fact exactly.

**Axis 1 (fidelity):** superseded-by-shipped — landed exactly as specified.

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 1/2; `internals/
user_input.md` "Dispatch chain."

---

### 7.2 — Slot restoration named to the console [forward / 0.1.0-m4]

**Claim:** On stop, keypressed/textinput slots are restored to `ConsoleController` as a **named**
contract, vs. today's wholesale default reinstall.

**Code check:** `release_keyboard_route` (`controller.lua:798-803`) is exactly this named form:
`Controller.project_input:deactivate(); Controller.set_love_keypressed(CC);
Controller.set_love_keyreleased(CC); Controller.set_love_textinput(CC)` — keyboard/text-only,
explicit `CC` receiver, called at the `'running'→'project_open'` transition
(`consoleController.lua:256,270`). This coexists with the wholesale `set_default_handlers` (see
§6.4) used at fuller stop transitions — both are real, live code paths today.

**Axis 1 (fidelity):** superseded-by-shipped — the named form has landed as a genuine second
restoration path, not merely replacing the wholesale one.

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 11 ("route connects only
while running"); `internals/user_input.md` "Dispatch chain."

---

### 7.3 — Native-handler coexistence [forward / 0.1.0-m4]

**Claim:** A project's own `love.keypressed`/`textinput` remains legitimate; when the project sets
no `compy.input` handler, the default propagates to the active route's sink; PIC auto-provisions so
soliciting forwards intra-route to the widget and non-soliciting reaches the native handler.

**Code check:** `project_natives` (`controller.lua:207-216`) wraps the project's own
`love.keypressed`/`textinput`/`keyreleased` (via `keyboard_native`, error-wrapped, only if the
project actually set one different from the default) into a `natives` table passed to
`pic:activate(natives, compy.input)` (`occupy_keyboard`, `controller.lua:236`). `_generic_callback`
(`projectInputController.lua:99-113` region, tier 3): `local cb = ci[CHANNELS[event]] or
self.natives[event]; if cb then return cb(...) end` — confirmed precedence: explicit
`compy.input.on_*` wins, else the project's captured native, else noop+log. This is exactly the
"auto-provision" claim: no special-casing needed, tier 3's `or` already realizes both the
soliciting (tier-4 sink reached when tier 3 is absent/falsey) and non-soliciting (native fires)
cases uniformly.

**Axis 1 (fidelity):** superseded-by-shipped — landed exactly as specified, including the
precedence order.

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 10 (pure-wrap natives as
tier-3 default); `internals/user_input.md` "Dispatch chain."

---

### 7.4 — `isrepeat` reaches the keypressed path [forward — split m4/m5]

**Claim:** `isrepeat` restored in two steps: [m4] no longer dropped at the gateway; [m5] delivered
to `compy.input.on_key_pressed(k, keys_pressed, isrepeat)`. Whole path carries the uniform triple,
**sink included**. Plus an "open cross-reference gap": M4.md promises an m5 `keyreleased` dispatch
tier that M5.md never actually defines.

**Code check:**
- Gateway: `handlers.keypressed = function(k, sc, isr)` (`controller.lua:873`) — `isr` present at
  the very top of the chain, no longer dropped.
- `ProjectInputController:keypressed(k, sc, isr)` (`projectInputController.lua:257-260`) threads
  `isr` into `_dispatch('keypressed', k, k, Controller.held_keys(), isr)`; `_dispatch`'s `...`
  forwards `(k, held_keys, isr)` uniformly to `fw(...)`, `ph(...)`, `_generic_callback(event, ...)`
  (→ `cb(...)` = the project's `on_key_pressed`), **and** `_sink(event, ...)` (→
  `UserInputController:keypressed(k, keys_pressed, isr)`) — confirming "sink included," matching
  §9's already-RESOLVED open question.
- Combo tiers (1-2) do **not** gate dispatch on `isr` (the `combo_string(trigger,
  Controller.keys_pressed)` computation ignores it entirely) — but they *do* structurally receive
  it as a 3rd call argument via the shared varargs; `framework_submit`/`framework_cancel`
  (`function(_, keys_pressed)`) simply don't name/use the 3rd parameter. This matches the in-code
  `DEFERRED` marker (`projectInputController.lua:249-253`): *"whether the combo tiers (1-2) fire on
  key-repeat is unruled ... isrepeat is threaded to tier 3 only, combos keep current behaviour"* —
  i.e. "threaded to tier 3 only" describes *consumption*, not argument presence.
- **The m4↔m5 keyreleased cross-reference gap**: whatever the *design-spec documents'* wording
  mismatch was, the **shipped code has no such gap** —
  `ProjectInputController:keyreleased` (`projectInputController.lua:271-274`) runs the identical
  `_dispatch` four-tier chain as keypressed/textinput (same function, `_dispatch` is one shared
  implementation, `:198-207`); `framework_handlers.keyreleased` is initialized as a real (empty,
  since no structural return/escape maps to keyreleased) sub-table in `new()`
  (`projectInputController.lua:132`), symmetric with `keypressed`/`textinput`. The dispatch
  *mechanism* for keyreleased fully exists and is exercised identically to the other two channels —
  there is no missing tier in the implementation, regardless of what the M4/M5 spec prose says.

**Axis 1 (fidelity):** superseded-by-shipped for the main isrepeat-threading claim (both m4 and m5
steps landed, sink included). The cross-reference gap itself is a claim about *design documents*,
outside this worker's `src/**`-only verification scope — but the *code-level* consequence doc-A
worried about (a missing keyreleased dispatch tier) is confirmed **not present**: the tier exists.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Key state" section states the
uniform-triple-including-sink claim directly; the DEFERRED marker is cross-referenced from
`technical_debt/input.md` "Combo-tier key-repeat semantics are shipped unsettled." The spec
cross-reference gap itself has no corpus home (it's about `design/spec/M4.md`/`M5.md`, which are
frozen design inputs, not the persistent docs corpus) — see §9 below, same open question restated.

---

## 8. Out of #77 blast radius — four items

1. **The `keyreleased` console-only fork** (§5.3.2): re-confirmed in DI1-a
   (`consoleController.lua:1241-1244`, no `app_state=='editor'` branch, unlike `:keypressed`/
   `:textinput`). Still-true; matters exactly as doc-A frames it (future console/editor unification
   must resolve deliberately). **Axis 2: already-covered — home is `internals/user_input.md` "Key
   release" (lines 291-317), not `technical_debt/input.md`** (grepped the tech-debt doc for
   "keyreleased"/"console-only"/"fork" — only a tangential focus-loss mention at line 20-21, not
   this item).
2. **`inspect`-mode input suppression** (§5.4): re-confirmed in DI1-a (`get_user_input()`
   unconditional override, `ConsoleController:suspend()` physical slot swap). Still-true. **Axis 2:
   already-covered — home is `internals/user_input.md` "Dispatch chain" ("`inspect` mode overrides
   all of the above") + `decisions/input.md` Decision 12, not `technical_debt/input.md`** (grepped
   for "inspect" — zero hits in the tech-debt doc).
3. **The `search` sub-widget** (§5.8): re-confirmed in DI1-a (`SearchController`/`SearchModel`, no
   `keyreleased`, no evaluator, `clear()` reaching past its own controller). Still-true. **Axis 2:
   already-covered, near-verbatim — home is `internals/user_input.md` "Search — a third widget
   instance" (lines 319-336), not `technical_debt/input.md`** (zero "search sub-widget"/"third
   widget" hits there either — the tech-debt doc's own "tixy shift+click example-sequence behaviour
   unclear" item is unrelated).
4. **Four incompatible `reset()`/cancel implementations + cursor two-layer split** (§6.6): see full
   check under §6.6 above. Still-true for the reset-implementations half (unchanged, "carried as
   is" per the corpus's own words); **partially stale** for the cursor-layer half (`compy` cursor
   surface now exists, 0.1.0-m7 landed — doc-A's "compy: nothing yet" no longer holds). **Axis 2:
   already-covered — home is `internals/user_input.md` "Cursor manipulation and 'reset'" (lines
   77-119), which states the identical reset-implementations enumeration almost verbatim.
   `technical_debt/input.md` "Editor sets its input-widget cursor outside the project cursor API"
   covers only the narrower editor-vs-project-API angle of the cursor split, not the
   three-layer/four-reset-impl picture as a whole.**

**Consolidated Axis-2 note for all four §8 items:** the task brief anticipated
`technical_debt/input.md` as the likely home for these; **checked precisely, none of the four are
actually homed there** — all four are homed in `internals/user_input.md` instead (three different
named sections), with `technical_debt/input.md` only covering narrower adjacent debt angles (cursor
API asymmetry, focus-loss staleness) rather than these specific structural findings. This is a
correction to flag for the orchestrator, not a confirmation of the brief's hint.

---

## 9. Open questions

1. **"Should the bottom/default sink receive `keys_pressed`/`isrepeat`? RESOLVED: yes, uniformly."**
   Doc-A already marks this resolved. Re-confirmed directly against code in §7.4 above (`_dispatch`
   forwards the uniform triple to the sink via shared varargs). Axis 1: still-true (an
   already-resolved question, and the resolution holds). Axis 2: already-covered,
   `internals/user_input.md` "Key state."

2. **"Is `app_state=='starting'` ever observed by an input path?" — flagged UNCERTAIN by doc-A.**
   **Now answerable: NO, confirmed by code.** `love.load()` (`main.lua:283-286,319`) sets
   `love.state.app_state = 'starting'` at the very top of the function and reassigns it to
   `'ready'` at line 319, still inside the same synchronous `love.load()` call — LÖVE does not
   invoke `love.keypressed`/`textinput`/any input callback until `love.load()` returns and the
   event pump starts, so no input path can ever observe `'starting'`. This resolves doc-A's own
   flagged uncertainty. Axis 1: was UNCERTAIN in doc-A, now **resolved-true** (confirmed absent) by
   code, not a fidelity mismatch — worth surfacing as a genuinely closed question. Axis 2:
   unique-no-home (no corpus doc states this explicitly; a one-line note in `internals/
   user_input.md` "Dispatch chain" would close it if promoted).

3. **"Sink-as-default coupling — owner call."** A project overriding `on_key_pressed` may silently
   disable `on_limit_reached`. **Code check:** `_generic_callback` (tier 3): `local cb =
   ci[CHANNELS[event]] or self.natives[event]; if cb then return cb(...) end` — if the project's
   `on_key_pressed` returns a truthy value, `_dispatch` stops before reaching `_sink`
   (`projectInputController.lua:201-207`), and `on_limit_reached` (fired only from inside
   `UserInputController:keypressed`'s own body, `userInputController.lua:495`) never runs. If the
   project's handler returns nil/false (the common case for a side-effecting callback that doesn't
   `return`), the chain still falls through to the sink and `on_limit_reached` fires normally — so
   the coupling is real but conditional on the project's return-value convention. This matches
   doc-A's framing precisely: a real, unresolved design coupling, not asserted as a contract.
   **Axis 1: still-true** (an accurately-described, still-unruled owner-call — not resolved by
   anything shipped). **Axis 2: unique-no-home** — grepped `technical_debt/input.md` for
   "on_limit_reached"/"silent" — no entry captures this specific default-value/silent-disable
   coupling (the doc's "Silent config-key drop in `show{}`" item is a different silent-drop
   scenario). Candidate for promotion to technical_debt if doc-A is deleted.

4. **"Combo-tier key-repeat semantics — provisional leaning, not-yet-ruled."** **Code check:**
   `internals/user_input.md` "Key state" section states the *current* shipped behaviour precisely:
   *"Combo dispatch itself does not gate on `isrepeat`: tiers 1-2 fire on **every** repeat, not just
   fresh presses"* — i.e. the doc-A-recorded "provisional leaning" (fresh-only at tiers 1-2) was
   **considered and never adopted**; the actual shipped behaviour is the opposite (fires on every
   repeat), still marked `DEFERRED`/unruled in-code (`projectInputController.lua:249-253`). Axis 1:
   still-true as an *open question* (doc-A correctly declines to assert a contract here, and none
   has been set) — but the specific "leaning" it records as provisional reads as superseded by what
   actually shipped (the opposite behavior, still just as unruled). Axis 2: already-covered,
   verbatim heading match: `technical_debt/input.md` "Combo-tier key-repeat semantics are shipped
   unsettled" (line 131) — this is the cleanest already-covered/already-homed match in the whole
   dossier, down to matching the in-code `DEFERRED` comment's own cross-reference.

5. **"0.1.0-m4↔m5 `keyreleased` dispatch cross-reference gap."** See §7.4 above: the code-level
   dispatch tier for keyreleased exists and is symmetric with keypressed/textinput — whatever the
   M4.md/M5.md spec-document wording gap was, it did not result in a missing implementation. Axis 1:
   from a **code** perspective this reads as resolved (no gap in the shipped mechanism); the
   **spec-document** cross-reference itself (an artifact under `design/spec/`, a frozen input, not
   `src/**`) is out of this worker's verification scope — did not check whether M4.md/M5.md's prose
   was ever edited to close the gap explicitly. Axis 2: unique-no-home (this is a
   spec-authoring-process question, not a system-behaviour fact — no persistent corpus doc would
   restate it).

6. **"`combo_string`/`keys_pressed` have zero current `src/` callers ... noted so the rewrite does
   not assume an existing consumer."** This is the same underlying fact as §6.1/§6.2, framed
   forward-looking rather than as a stale claim. **Now inverted**: the rewrite the note anticipated
   *did* add the consumer (PIC's `_dispatch`) — doc-A's own caveat ("not asserted as a contract, only
   noted so the rewrite does not assume an existing consumer it would have to preserve") means this
   was never meant to survive the rewrite unchanged, and it hasn't: the "zero consumer" state was
   accurately temporary. Axis 1: superseded-by-shipped (identical disposition to §6.1/§6.2 — this
   is the same fact, not an independent one). Axis 2: already-covered (same citations as §6.1/§6.2).

---

## Uncertainties / thin spots

1. **§8's Axis-2 homes contradict the task brief's own hint.** The brief expected `technical_debt/
   input.md` to house §8's four items and §6.6's reset/cursor-split content; grepping that file
   precisely (keywords: "keyreleased", "console-only", "fork", "inspect", "search", "third widget",
   "reset()") turned up **no** matches for items 1-3 and only a partial match (cursor-API-asymmetry
   only) for item 4. All four are actually homed in `internals/user_input.md` under three specific
   named sections ("Key release", "Dispatch chain", "Search — a third widget instance", "Cursor
   manipulation and 'reset'"). I'm confident in this correction (direct grep + read of both files)
   but flagging it prominently since it inverts a stated expectation in the task brief itself.

2. **§7.4's spec-document cross-reference gap (M4.md vs M5.md) was deliberately left unverified.**
   Per the circularity guard I verified only `src/**`; the design-spec documents under
   `doc/development/wip/77-new-input-api/design/spec/` are a frozen input, and I did not check
   whether that specific prose mismatch was ever edited/resolved in the spec files themselves. The
   *code-level* consequence (a missing dispatch tier) is confirmed absent, which is the
   practically-relevant half, but the literal doc-cross-reference claim in §9 item 5 is unverified
   by me either way.

3. **`mcp__lua-lsp__references` on `combo_string`/`held_keys` returned heavy duplicate/noise output**
   (repeated hits inside a `.patch` file under `implementation/pr-slices/3a-routing-core.patch` and
   several `*.tmp.494.*` indexer artifacts that no longer exist on disk, per "Error reading file").
   I filtered these by hand and cross-checked every live-code hit against a direct grep + manual
   read of the cited line ranges in `controller.lua`/`projectInputController.lua` — the live-code
   citations in this dossier are grep+read-confirmed, not LSP-output-trusted verbatim. Net finding
   (real consumers exist) is high-confidence; the LSP tool itself is noisy on this repo's indexed
   history/patch files and would benefit from a narrower per-directory query if reused.

4. **`src/vadexamples/**` and `src/examples/{balloons,drawdebug,keyboard,maze}/` are untracked
   (`git status` shows `??`).** I treated these as out-of-scope scratch/leftover content (not part
   of the shipped, tracked `src/**`) for the §6.5 legacy-API-removal finding, since the *tracked*
   `src/examples/tixy` already reflects the migrated `compy.input.*` API and a dedicated
   tech-debt entry ("Untracked scratch examples call removed input globals") already exists for
   exactly this residue. If the orchestrator's scope for "CODE" is meant to include untracked
   working-tree files regardless of git status, this changes nothing about the Axis-1 disposition
   (the legacy API is still gone from the actually-runnable/tracked codebase) but is worth noting
   explicitly since I made a scope judgment call here.

5. **§6.6's "does the project's `on_key_pressed` truthy-return actually happen in practice
   anywhere in shipped project code (`src/examples/**`)?"** — I did not exhaustively check every
   example project's `on_key_pressed` handler for a `return true`/truthy pattern; the §9-item-3
   finding is about the *mechanism's* existence (confirmed structurally in
   `projectInputController.lua`), not about whether any current example project actually triggers
   the silent-disable case today.

6. **Line-citation drift**, as DI1-a already flagged for §1-§5: I did not audit every doc-A
   file:line citation in §6-§9 for staleness against current line numbers (e.g. §7.4's own
   `controller.lua:554` gateway citation predates the current file, which has no such line-554
   content relevant to this claim) — content was verified at current locations; citation-freshness
   as its own axis was out of this pass's scope, consistent with DI1-a's same disclaimer.
