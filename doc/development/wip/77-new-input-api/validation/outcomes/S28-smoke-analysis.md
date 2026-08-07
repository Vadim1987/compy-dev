# S28 — smoke findings SM3a/SM3b/SM4/SM5: code-only analysis

Sub-agent, read-only, per
`doc/development/wip/77-new-input-api/validation/prompts/S28-smoke-analysis-agent.md`.
No file was edited except this one. The app was never run (no `love`, no
`xvfb-run`); one busted probe was run against the real production gate to
settle SM4 empirically without touching any tracked file — see that section
for the exact command and why it's in-bounds ("you may run [busted] to
understand behaviour, but change nothing").

---

## SM4 — keyboard: Ctrl+Alt+`<arrow>` difficulty switch

**Verdict: NOT REPRODUCIBLE FROM CODE.** Confidence: high on the platform
round trip (empirically probed against the real dispatch gate, not just read),
moderate on ruling out the example.

### Trace

1. `src/examples/keyboard/input.lua:76-88` (`register_reserved`, called once
   from `inputInit` at `main.lua:74`) registers
   `compy.input.shortcuts.keypressed["ctrl+alt+up"]` and `["ctrl+alt+down"]`
   as `fn.stop_here(fn.ignore_repeat(...))`.
2. Registration goes through `Key.new_handler_table`'s normalising
   `__newindex` (`src/util/key.lua:111-118`): `split_combo`
   (`key.lua:46-57`) folds `ctrl`/`alt` into the modifier set, leaves `up` as
   the one trigger (`n == 1`), so `check_combo` (`key.lua:89-102`) does not
   error, and `normalize_combo` (`key.lua:66-74`) stores it as
   `"ctrl+alt+up"` — precedence order `ctrl, alt, shift, gui`
   (`key.lua:23-30`).
3. On a real key event, `Controller.setup_callback_handlers`'s
   `handlers.keypressed` (`src/controller/controller.lua:787-897`) sets
   `Controller.keys_pressed["up"] = true` (line 788) *before* forwarding to
   `love.keypressed` (line 894-896), which for a running project is
   `ProjectInputController.keypressed` (installed by `occupy_input`,
   `controller.lua:236-250`).
4. `ProjectInputController:_dispatch` (`src/controller/projectInputController.lua:149-153`)
   → `dispatch` (`projectInputController.lua:132-142`) →
   `find_shortcut(shortcuts.keypressed, "up")`
   (`projectInputController.lua:101-111`) → `Controller.combo_string("up", keys)`
   (`controller.lua:395-404`), which walks `COMBO_MODS` (= `Key.mod_triples`,
   same precedence order as step 2) and, with `lctrl`/`lalt` held, produces
   `"ctrl+alt+up"` — an exact match on the table from step 2, returned and
   invoked immediately (exact match short-circuits before the `alt+*` class
   fallback).
5. The shortcut fires `fn.stop_here(fn.ignore_repeat(function() notchAdjust(1) end))`
   (`input.lua:80-82`); `notchAdjust` (`input.lua:120-123`) calls
   `SCENES[ACTIVE].onNotch(delta)`. Every scene that plausibly needs it has
   one: `alt.lua:304`, `find.lua:51`, `hunt.lua:472`, `press.lua:64`.

Every hop matches: same modifier-precedence table (`Key.mod_triples`) feeds
both registration and dispatch, the arrow key's LÖVE name (`"up"`) is used
identically on both sides, and the exact-combo lookup wins before any class
fallback is even consulted.

### What I ruled out, and how

- **Registration rejected as malformed** — ruled out by reading
  `check_combo`; a two-modifier-plus-one-trigger combo is exactly the legal
  shape (`key.lua:89-102`), and this is independently exercised by
  `tests/input/input_events_spec.lua:336-345` (`sc['Ctrl+Alt+S']` accepted).
- **Two-modifier combos never actually dispatch, only classes do** —
  the existing suite only exercises the *class* form
  (`input_events_spec.lua:403-410`, `'ctrl+alt+*'`), never an *exact*
  two-modifier combo. That was a real coverage gap, so I closed it with a
  throwaway probe rather than trusting the reading alone (see below).
- **Some low-level power-shortcut swallows the event first** —
  `controller.lua:787-897`'s `restart`/`profile`/`quickswitch`/
  `project_state_change` closures run ahead of forwarding, but none matches
  `k == "up"`/`"down"`, and none of them gates the forward to
  `love.keypressed` — they run as side effects only.
- **The example never wires the class/exact shortcuts at all for some
  scenes** — `onNotch` is present on every gameplay scene
  (`alt.lua`, `find.lua`, `hunt.lua`, `press.lua`).

### Empirical probe (read-only)

Wrote a scratch spec, **not under `/repo`**
(`/tmp/claude-1000/-repo/381960c5-f8da-40f4-b934-65ba6c1f1e1b/scratchpad/sm4_probe_spec.lua`),
driving the fixture's real production gate (`tests/helpers/input_fixture.lua`
+ `tests/helpers/input_session.lua`, which install
`Controller.setup_callback_handlers` onto `love.handlers` exactly as
`main.lua` does, then call `Controller.set_user_handlers` →
`occupy_input`, the same code path a running project takes):

```
$ busted /tmp/.../scratchpad/sm4_probe_spec.lua \
    --lpath="./src/?.lua;./src/?/init.lua;./?.lua"
2 successes / 0 failures / 0 errors / 0 pending
```

Test 1 registers `shortcuts.keypressed['ctrl+alt+up']`, presses `lctrl`,
`lalt`, `up` through `love.handlers.keypressed`, and asserts the handler
fired with trigger `'up'`. Test 2 registers both `ctrl+alt+up` and
`ctrl+alt+down` and confirms holding Ctrl+Alt and pressing Down fires only
the Down handler. Both pass. This is the same mechanism the keyboard
example uses, driven through the same gateway a real keystroke takes — no
mock of `find_shortcut`/`combo_string`/`dispatch` themselves. No repo file
was created or modified; the spec lives entirely in the scratchpad and was
pointed to directly on the `busted` command line.

Corroborating fact already in the codebase: `controller.lua:839-843`
(`restart`, Ctrl+Alt+R) and `:844-852` (`profile`, Ctrl+Alt+P) already
depend on simultaneous Ctrl+Alt being read correctly via `Key.ctrl()` /
`Key.alt()`, via a different (live `isDown`) mechanism — a second,
independent confirmation that two-modifier chords reach this app correctly
in general.

### Proposed fix

None on the platform or the example — I found nothing to change. What I
*would* propose, as a coverage gap rather than a defect: add an exact
two-modifier-combo dispatch test (my probe's test 1, or equivalent) to
`tests/input/input_events_spec.lua`'s "combo classes" describe block, since
today only the class form (`ctrl+alt+*`) is exercised end-to-end there and
the exact form was, until this probe, dispatch-untested. That is a `/repo`
suite change (testable headlessly, no display) — I have not applied it, per
the read-only rule.

### What I could not determine

Whether the reported "does nothing" is an **OS/window-manager interception**
of Ctrl+Alt+Arrow before it ever reaches SDL/LÖVE — a very common desktop
binding (virtual-desktop switching on GNOME/Unity and workspace/rotate
shortcuts elsewhere). This is invisible to both the code and to a headless
busted probe; it would require an actual on-device retest (excluded from
this task) to confirm or rule out. Given the round trip is demonstrably
correct end-to-end in-process, this is the leading candidate for what the
owner saw.

---

## SM3b — maze: holding Ctrl alone dims/shadows the screen

**Verdict: EXAMPLE — explained, and it is not Ctrl.** Confidence: high that
the dim is Shift-triggered, by design; moderate that this fully accounts for
what the owner saw (can't rule out a same-session mix-up of which key was
held).

### Trace

1. `src/examples/maze/controls.lua:10-13` — control mode `keys()` (used for
   levels 1-3, "real-time movement" per B3) sets `ctrl_pressed = handle_key`.
2. `src/examples/maze/main.lua:568-578` — the project's raw `love.keypressed`
   (old-style handler; the framework seeds it as a hook automatically, per
   the comment at `src/examples/keyboard/input.lua:1-8` describing the same
   mechanism) calls `ctrl_pressed(k)` for any key that is not `escape` and
   has no `SYSTEM_KEYS` entry.
3. `src/examples/maze/macro.lua:72-83` (`handle_key`) — the **only** branch
   that sets `macro_state.shift_held = true` is `if SHIFT_KEYS[k]`, and
   `SHIFT_KEYS` (`macro.lua:5-8`) contains exactly `lshift`/`rshift`. There
   is no `ctrl`/`lctrl`/`rctrl` branch anywhere in this file.
4. `src/examples/maze/graphics.lua:344-357` (`draw_macro_ui`) — `draw_dim()`
   (`graphics.lua:317-321`, a 50%-alpha black rectangle over the whole
   screen) is called *only* when `macro_state.shift_held` is true.
5. `src/examples/maze/macro.lua:87-92` (`release_shift`) clears
   `shift_held` on `lshift`/`rshift` release, and `main.lua:580-582`
   (`love.keyreleased`) is the only caller.

I grepped every `ctrl`/`Ctrl` occurrence in `src/examples/maze/*.lua`; the
only ones are `keyboard_graphics.lua:125,260` (`key("lctrl", "Ctrl")` — a
label for the on-screen macro-keyboard rendering, cosmetic, unconnected to
`draw_dim`) and the `ctrl_pressed`/`ctrl_update` *variable names* in
`controls.lua`/`main.lua`, which are per-level **control-mode** callbacks
(unrelated to the physical Ctrl key — poor naming, not a bug: `ctrl_pressed`
is called for every non-system key, Shift included).

### What is wrong

Nothing, as coded: the dim overlay is Shift-gated, by design — it is the
"hold Shift to start recording a macro" cue (`macro.lua`'s own header
comment: "Start recording: Shift + key pressed"). There is no code path
anywhere in the maze project that ties screen-dimming to Ctrl. The
`"Ctrl"` in the owner's smoke notes (quoted, i.e. already flagged as
uncertain in the source note) most likely names Shift — an easy mix-up
mid-session, and the two keys are adjacent on the physical layout the
maze on-screen keyboard renders (`layout[5]`/`layout[6]` in
`keyboard_graphics.lua:107-137`, `lshift` and `lctrl` are stacked).

### Proposed fix

None needed on the code. If the owner wants the finding itself closed out
crisply: rename `ctrl_pressed`/`ctrl_update` in `controls.lua`/`main.lua` to
something not evocative of the physical Ctrl key (e.g. `mode_key`/
`mode_update`) — purely a readability fix in the example repo, zero
behaviour change, not testable (nothing to assert), not urgent.

---

## SM3a — maze: navigation symbols glitch when launched from another project

**Verdict: NOT REPRODUCIBLE FROM CODE.** Confidence: low — I could not
confirm or rule out a mechanism; this needs a runtime check the owner is
better placed to run than I am to infer.

### What I checked

1. **The owner's own hypothesis (font state, first-start-only switch).**
   `src/examples/maze/keyboard_graphics.lua:32-43` creates `FONT1`/`FONT2`/
   `FONT3` via `gfx.newFont(...)` as **module-level** statements, so they run
   exactly once per Lua `require` of that module. Every glyph draw
   (`letter`/`single`/`double`/`double2`, `keyboard_graphics.lua:223-247`)
   explicitly calls `gfx.setFont(FONTx)` right before printing — so *if*
   `FONT1..3` are valid objects, nothing downstream depends on "first start"
   specifically; the font is set fresh on every draw call.
2. **Whether a stale `require` cache could hand maze old font objects.**
   `ConsoleController:evacuate_required` (`src/controller/consoleController.lua:1333-1347`)
   clears `package.loaded[modname]` for every `.lua` file of
   `self:get_current_project()` — but only inside `stop_project_run`
   (`consoleController.lua:1349-1361`), and only for the project that is
   itself *being stopped*, keyed by that project's own filenames. Tracing
   the switch path `run_project` (refuses to start while
   `app_state == 'running'`, `consoleController.lua:282-288`) →
   (user stops the current project first, which evacuates *its own*
   modules) → `open_project` (`consoleController.lua:1271-1305`) →
   `close_project` (`consoleController.lua:1308-1325`, unregisters the old
   project's loader, calls `_reset_executor_env`, `1183-1185`, which
   rebuilds `compy`/`compy.input` from `base_env` — but does **not** touch
   `package.loaded`) — I found no path where a *different* project's
   `require`d modules leave a stale `package.loaded['keyboard_graphics']`
   entry for maze to inherit. This mechanism is scoped correctly for the
   case it's built for (re-running the *same* project), which is not quite
   the reported scenario (maze after *another*, different project).
3. **Whether any global graphics state is left unreset between a stop and
   the next project's run.** I found no call that resets LÖVE's *active*
   font (`love.graphics`'s current-font register) between
   `stop_project_run` and the next `run_project`. The only place the
   platform explicitly sets a font outside a project's own code is
   `View.end_draw` (`controller.lua:661-667`, `gfx.setFont(CC.cfg.view.font)`),
   which only runs on the final quit screen, never on an ordinary
   project-to-project transition. This is a real gap, but I could not
   connect it to "glitchy navigation symbols" specifically: maze's own
   arrow-glyph draws always set their own font first (point 1), so a leaked
   *active* font wouldn't corrupt those particular draws — only calls that
   read `gfx.getFont()` without having set it themselves first
   (`graphics.lua:257-259` `legend_lines`-adjacent, `graphics.lua:301-304`
   `draw_macros_list`) would be affected, and neither of those is the
   macro-keyboard's arrow keys.

### A directly relevant precedent in this codebase

`doc/development/wip/77-new-input-api/validation/notes/S24-W7-A1-second-project-overlay.md`
documents a **previously real, previously fixed** bug of exactly this
shape: `love.state.user_input` (the framework's overlay handle) was cleared
on project stop, but the widget's own internal `shown` flag was not — so
"the first project of a session always works and every later one fails"
(quoting that note), because the flag starts correctly-false at boot and is
never actively reset thereafter. That note's own follow-up section says
explicitly: "the fix removes today's only known divergence but not the
possibility of another." SM3a is structurally the same shape of complaint
(works first, breaks after a prior project ran) and is worth taking
seriously for exactly that reason — but I have not found *this* instance
of it; I've only established that the general failure class has precedent
here, and that I could not locate the specific stale-state field for fonts
the way that note pinned `UserInputController.shown`.

### Proposed fix

None — I have no diff to propose because I could not identify the
mechanism. Recommended next step (for the owner, not something I can do
read-only): reproduce with a debug print of `tostring(gfx.getFont())` at
`keyboard_graphics.lua:32` (right after `FONT1` is created) and at
`graphics.lua`'s two `gfx.getFont()` call sites, comparing a first-launch
run of maze against a run preceded by another project. If the identities
differ in the second case where they shouldn't, that pinpoints it exactly;
if `FONT1` is a fresh object both times, the bug is downstream of font
creation (e.g. layout/scale math) and the search should move to
`init_grid` (`main.lua:29-41`) and `GRID.cell`/`GRID.scale`, which do depend
on `gfx.getDimensions()` at level start and could plausibly read a stale
window/canvas size if a prior project changed it.

### Suite testability

Not testable by `busted tests` as it stands — the platform suite has no
fixture that runs two *different* nested example projects back-to-back (the
`tests/` fixtures build a synthetic project env, not `src/examples/*`'s real
files), and the mechanism itself is unconfirmed. If the debug-print step
above pins a specific stale-state field, a regression test could likely be
added in `/repo`'s own suite mirroring `S24-W7-A1`'s pattern: drive
`run_project` → `stop_project_run` → `run_project` with two stub project
chunks and assert whatever the culprit field is has been reset.

---

## SM5 — keyboard: subgame 4 "alt keys" — glyph shown but not accepted

**Verdict: EXAMPLE DEFECT.** Confidence: high — the mechanism is exact, and
the codebase's own platform documentation independently names precisely
this failure mode as a hazard to avoid.

### Trace

1. The target is a **printable** glyph (owner reports lowercase `k`/`q`).
   `alt.lua:298-306` (`registerScene("alt", ...)`) wires both `keypressed`
   and `textinput`, but for a plain lowercase letter, `altKeypressed`
   (`alt.lua:205-215`) calls `altPlayKey` (`alt.lua:191-199`), which returns
   immediately at line 193 (`if not altIsKeyTarget(gaugeCurrent(ALT)) then
   return end`) because lowercase letters are **not** in `ALT_KEYTARGET`
   (`alt.lua:42-44`, only `backspace`/`tab`/`return`). So `keypressed` never
   judges a letter target — by design, per the file's own header comment
   (`alt.lua:1-14`): printable targets are judged on `textinput`.
2. `Controller.setup_callback_handlers`'s `handlers.keypressed`
   (`controller.lua:787-788`) sets `Controller.keys_pressed["k"] = true`
   **unconditionally, before** forwarding to `love.keypressed` — this runs
   whether or not any scene consumes the keypress.
3. `keyboard/input.lua:142-150` (`appKeypressed`) then runs (as the seeded
   hook), calls the scene's `keypressed`, which — per step 1 — does nothing
   for a letter.
4. The actual judgment happens when `textinput` fires:
   `appTextinput` (`input.lua:163-174`) → `alt.lua:175-185`
   (`altTextinput`) → line 176: `if inputStale(altBaseKey(ch)) then return
   end`. `inputStale` (`input.lua:130-135`) checks `INPUT.held[k]`, which
   (`input.lua:47-55`) resolves to `compy.input.keys_pressed[k]` — the exact
   flag step 2 already set to `true` for this same key, for this same
   physical press, **before** `textinput` was even reached.
5. So `inputStale("k")` returns `true` — the fresh glyph is classified as a
   "held/repeat" glyph and dropped at line 176, before `ch ==
   gaugeCurrent(ALT)` is ever evaluated. Neither channel judges the press:
   `keypressed` skips it by design (step 1), `textinput` skips it by
   accident (step 5).
6. Shift's visual feedback is unaffected because it never goes through this
   path: `altHintDeco`/`altHintReady` (`alt.lua:231-253`) read
   `INPUT.shift` (`input.lua:51`, `compy.input.keys_pressed` directly) at
   **draw** time, live, with no `textinput`/`inputStale` involvement — which
   is exactly why the owner saw the keyboard's Shift-glow update while
   letters produced nothing: two different mechanisms, only one broken.

### What is wrong

`input.lua`'s own header comment (`input.lua:18-33`) states the design
premise explicitly: *"the IDE delivers textinput BEFORE the matching
keypress (the reverse of desktop LOVE)"* — and `inputStale` was built for
that ordering: a glyph is "stale" if its key is already marked held by a
**later**-arriving `keypressed`. On desktop LÖVE (`xvfb-run love src`,
stock SDL event pump, no custom `love.run` in this codebase — verified: no
`love.run`/`love.event.pump` override anywhere in `src/`), `keypressed`
fires *first*. So the very flag meant to catch a *second, repeated* glyph
is already set on the *first* one, and every fresh letter is swallowed.

This is independently, explicitly called out as a hazard in the platform's
own design record — **not by me, by the codebase**:
`doc/development/decisions/input.md:146-157`:

> Recognized external constraint — no cross-channel ordering guarantee...
> LÖVE/SDL documents *no* ordering between the `keypressed` and `textinput`
> channels for a single keystroke — upstream's `keypressed`-before-
> `textinput` is a de-facto SDL artifact, and the target device has been
> observed delivering the reverse... a project judges typed text on the
> `textinput` channel..., **never by gating a glyph on a `keypressed`
> flag**, so the design is order-*independent*... The corollary for tests
> is binding: a spec must **not** bake a canonical `keypressed`→`textinput`
> order in as an invariant, or a synchronous harness goes green while the
> device fails.

`inputStale` does precisely the thing this decision warns against: it gates
a `textinput` glyph's acceptance on a flag that only `keypressed` writes,
and whose write time relative to `textinput` is exactly the property the
platform documents as unordered/reversed-on-device. The example was written
for one observed ordering and fails on the other, standard one — which is
also the one the dev/smoke-test environment (`xvfb-run love src`, plain
desktop SDL) actually delivers.

### Why `press`/`find`/`hunt` are unaffected

They judge exclusively via `keypressed` (`press.lua:63`, `find.lua:50`,
`hunt.lua:471` — no `textinput` wiring at all), so they never consult
`INPUT.held`/`inputStale`. `alt.lua` is the only scene that needs
`textinput` (it must match the *produced glyph*, e.g. Shift+2 → `@`, not
the physical key), and it is the only one carrying this bug.

### Proposed fix

**File:** `src/examples/keyboard/input.lua` (the shared `inputStale`/
`INPUT.upRecent` mechanism) and its one caller, `src/examples/keyboard/alt.lua:176`.

Replace the "is the key currently held" check (order-dependent, and per the
platform's own decision doc, exactly the pattern to avoid) with an
order-independent "have I already judged a glyph for this physical
press-cycle" flag, set by *whichever* channel (keypressed or textinput)
sees the key first, and cleared only on `keyreleased`:

```lua
-- input.lua
local judged = { }                    -- new: per-key "already judged this press"

function appKeyreleased(k)
  dbgLog("KR " .. k)
  INPUT.upRecent[k] = DBG_FRAME
  judged[k] = nil                     -- was: nothing here for `judged`
  local s = SCENES[ACTIVE]
  if s and s.keyreleased then s.keyreleased(k) end
end

-- new: exposed for alt.lua, replaces the inputStale held-check
function inputAlreadyJudged(k)
  if judged[k] then return true end
  judged[k] = true
  return false
end
```

```lua
-- alt.lua:175-185
function altTextinput(ch)
  local k = altBaseKey(ch)
  if inputAlreadyJudged(k) then return end     -- was: inputStale(k)
  if fkDone(ALT) then return end
  if not gaugeGlowing(ALT) then return end
  if altIsKeyTarget(gaugeCurrent(ALT)) then return end
  if ch == gaugeCurrent(ALT) then
    altHit()
  else
    altWrong()
  end
end
```

This keeps `INPUT_UP_GRACE`/`upRecent` for whatever else may still want a
"was this key just released" read (nothing does today —
`grep -rn upRecent` shows only its own definition and `inputStale`'s use of
it — so a fuller cleanup could drop `upRecent`/`INPUT_UP_GRACE` entirely,
but that's beyond this fix's scope) and removes the ordering dependency:
whichever event for a given press arrives first marks it judged; the
second (whichever channel, whichever order) is then correctly treated as
either "same press, already handled" or an OS auto-repeat.

Caveat I want to be explicit about: I have reasoned through this fix
carefully but have not run it — the owner should verify it against both
orderings (a synthetic press with `textinput` first, and one with
`keypressed` first) before trusting it, per the same decision doc's own
warning about tests baking in one order.

**This is example code, not a platform defect** — the platform's dispatch
chain delivers both channels with their real arguments in whatever order
LÖVE/SDL produces them (by design, per Decision noted above); it makes no
promise to normalize channel order, and correctly doesn't. The fix belongs
entirely in `src/examples/keyboard/`.

### Suite testability

Not testable by `busted tests` today — the keyboard project is a separate,
nested git repository (`src/examples/keyboard/.git`) with no test harness
of its own (`find ... -iname "*spec*"` / `"*test*"` in that tree: nothing
but this exercise's own game files). The fix's core logic (`judged` table
keyed by press/release, order-independent by construction) is pure Lua with
no LÖVE/graphics dependency, so it is easily unit-testable in isolation —
but that would mean standing up a test harness inside the keyboard repo,
which does not exist yet and is out of scope for this read-only pass.

---

## Summary of verdicts

| Finding | Verdict | Confidence | Fix proposed | Suite-testable (headless) |
|---|---|---|---|---|
| SM3a (maze, font/nav glitch after another project) | NOT REPRODUCIBLE FROM CODE | low | none — needs a runtime probe | not yet — mechanism unconfirmed |
| SM3b (maze, Ctrl "shadows" screen) | EXAMPLE — explained (it's Shift, by design) | high | optional rename only, no behaviour change | n/a |
| SM4 (keyboard, Ctrl+Alt+arrow does nothing) | NOT REPRODUCIBLE FROM CODE | high (platform round trip empirically verified) | none — propose closing the exact-combo coverage gap in `tests/input/input_events_spec.lua` | yes, for the coverage-gap addition |
| SM5 (keyboard, Alt-keys glyph not accepted) | EXAMPLE DEFECT | high | `inputStale` → order-independent `judged` flag, `input.lua` + `alt.lua:176` | not today (no test harness in that nested repo); fix is pure-Lua and unit-testable in principle |
