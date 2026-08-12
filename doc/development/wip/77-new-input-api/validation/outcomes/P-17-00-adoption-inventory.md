# P-17-00 — cold inventory: input touch sites in `src/examples/maze` (`newinput-edge`, `b8cc436`)

Cold, mechanical pass against `doc/development/conventions/input_adoption.md` (Q1-Q10 + Rules of
restraint). No verdicts. Branch confirmed with `git -C src/examples/maze branch --show-current` ->
`newinput-edge`, head `b8cc436`.

Build classification (from `.compy/build`, read directly, not inferred):

- **CORE** (both `maze/` and `draw/`): `core_constants core_sprites core_render core_editor
  core_anim player script` + the four `ROBOT_03_*` sprite parts.
- **MAZE** only: `maze_constants maze_decorations maze_render maze_logic maze_plan controls levels
  menu macro keyboard_graphics` + sprite/level data files; `maze_main.lua` -> `maze/main.lua`.
- **DRAW** only: `draw_constants draw_levels draw_menu draw_render keyboard_graphics`;
  `draw_main.lua` -> `draw/main.lua`.
- `keyboard_graphics.lua` is **not** in the CORE group but is copied into *both* MAZE and DRAW as
  its own source file (a keyboard-diagram renderer; it draws key caps, it does not read input — see
  "swept, no site" below). Tagged **MAZE+DRAW** in this document to distinguish it from true CORE.

Confirmed by reading `maze_main.lua` / `draw_main.lua` `require(...)` lists directly: `controls.lua`,
`macro.lua`, `maze_plan.lua`, `menu.lua`, `levels.lua`, `maze_logic.lua` are required only by
`maze_main.lua`. **`draw_main.lua` never requires any of them** — this matters for reachability
below (`ctrl_pressed` is structurally always `nil` in draw).

Whole-repo fact, checked by grep with no hits: **`Key.*` (the `compy.input` folded modifier
accessor) is not referenced anywhere in this repo.** Every modifier question here is answered with
raw `love.keyboard.isDown`.

---

## Table of contents

- CORE sites: [C1](#c1) [C2](#c2)
- MAZE sites: [M1](#m1) [M2](#m2) [M3](#m3) [M4](#m4) [M5](#m5) [M6](#m6) [M7](#m7) [M8](#m8)
  [M9](#m9) [M10](#m10) [M11](#m11) [M12](#m12) [M13](#m13) [M14](#m14) [M15](#m15) [M16](#m16)
  [M17](#m17) [M18](#m18) [M19](#m19)
- DRAW sites: [D1](#d1) [D2](#d2) [D3](#d3) [D4](#d4) [D5](#d5) [D6](#d6) [D7](#d7) [D8](#d8)
- [Counts](#counts)
- [Anything the checklist has no question for](#anything-the-checklist-has-no-question-for)

---

## CORE sites (land in both `maze/` and `draw/`)

### C1
**Location:** `core_editor.lua:98-103` (`arm_editor`), also `core_editor.lua:54-60`
(`reject_program`) and `:84-93` (`rearm_input`), which call the same `input_text(...)` global.
CORE.

**The code:**
```lua
function arm_editor(text)
  ctrl_pressed = nil
  ctrl_update = process_user_input
  GS.input = user_input()
  input_text("Commands:", string.lines(text))
end
```

**What it does:** Enters "editor" control mode: clears the key-dispatch slot, installs a per-tick
poller, and opens a text field via `user_input()` / `input_text(...)`.

**Checklist match:** none of Q1-Q10 directly — `user_input()` and `input_text()` are not project
API at all in the current framework. They are the **retired** globals named in `doc/input_api.md`'s
Migration table: `"user_input() plus a per-frame poll"` -> `on_text_entered = function(lines) ...
end`, and `"input_text(prompt, text)"` -> `show{ prompt = prompt, text = text, on_text_entered =
fn }`. This whole editor flow predates `compy.input` and is not expressed in its vocabulary at all.

**What the platform offers:** `compy.input.show{ prompt = ..., text = ..., on_text_entered =
fn }` (`doc/input_api.md`, "Quick start" and "Migration").

**Reachability:** Runs whenever `cur_controls == editor` calls `editor()`/`rearm_editor()`, which
happens on every level with `controls = editor` in `levels.lua` (MAZE side; see M-track notes
below) and unconditionally in `draw_main.lua` (`resetDrawProgramState` always sets
`cur_controls = editor`, both `startFreeDraw` and `startPictureLevel` call `editor()`) — so in
DRAW this is the **only** control mode that ever exists.

### C2
**Location:** `core_editor.lua:43-49`. CORE.

**The code:**
```lua
function process_user_input()
  if GS.input:is_empty() then
    rearm_input()
    return
  end
  start_program(string.unlines(GS.input()))
end
```

**What it does:** Installed as `ctrl_update`, so it runs every `love.update` tick while the editor
is armed: asks the (retired) input object whether it is empty, and if not, reads its content and
runs it as a program.

**Checklist match:** none. It is a per-tick poll, but not of device state and not deriving a
press/release edge (Q4's shape) — it polls the old input widget's own emptiness, which is that
widget's replaced-by-callback lifecycle, not a keyboard/pointer read.

**What the platform offers:** N/A directly; superseded by `on_text_entered` firing once on submit
instead of being polled every tick (`doc/input_api.md`, "Submit lifecycle").

**Reachability:** Runs every tick that `ctrl_update == process_user_input`, i.e. whenever editor
mode is active in either program (see C1).

---

## MAZE-only sites (`maze_main.lua` and files it alone requires)

### M1
**Location:** `maze_main.lua:73-88`. MAZE.

**The code:**
```lua
tab_was_down = false

function poll_tab_progression()
  local down = love.keyboard.isDown("tab")
  local edge = down and not tab_was_down
  if edge then
    ...
  end
  tab_was_down = down
end
```

**What it does:** Polls whether Tab is held every `love.update` tick and derives a press-edge by
comparing against the previous tick's value, stored in a module global.

**Checklist match:** **Q1** (a boolean mirroring key state, `tab_was_down`, with no reconciliation
path) and **Q4** (answering "did this just happen" by polling plus edge detection — this is exactly
the poll-plus-previous-value shape the question describes).

**What the platform offers:** Q4's action — "That is an event. Use the channel — a hook, or a
shortcut if it names a combo" — a `shortcuts.keypressed['tab']` binding, with `fn.ignore_repeat`
if repeats must be excluded (`doc/input_api.md`, "A held key repeats").

**Reachability:** Called unconditionally from `love.update` whenever `GS.mode == "game"`
(`maze_main.lua:113-119`) — every level, every control mode (keys/plan/editor), since the gate is
only on `GS.mode`, not on which control mode is active.

### M2
**Location:** `maze_main.lua:113-123` (`love.update`). MAZE.

**The code:**
```lua
function love.update(dt)
  ensure_init()
  if GS.mode ~= "game" then
    return
  end
  poll_tab_progression()
  step_program(dt)
  if ctrl_update then
    ctrl_update(dt)
  end
end
```

**What it does:** The per-tick indirection point: calls whatever `ctrl_update` currently holds.
Not itself a read of device state, but the dispatch hub that the mode functions in `controls.lua`
and `core_editor.lua` wire into.

**Checklist match:** none — infrastructure, not an input read.

**What the platform offers:** N/A directly. Recorded per the prompt's instruction to trace the
indirection: **the full set of values `ctrl_update` can take in MAZE** is `nil` (from `keys()`,
`celebrate()`, `to_menu()`, `enter_failed()` in `maze_logic.lua`, and `finish_run()` in
`maze_logic.lua`), `plan_update` (from `plan()`), and `process_user_input` (from `arm_editor()`).

**Reachability:** Every frame while `GS.mode == "game"`.

### M3
**Location:** `maze_main.lua:136-143`. MAZE.

**The code:**
```lua
SYSTEM_KEYS = { }

function SYSTEM_KEYS.menu()
  cur_grid = not cur_grid
  sfx.sword()
end

love.mousepressed = SYSTEM_KEYS.menu
```

**What it does:** Assigns `love.mousepressed` directly to a zero-argument function reference,
ignoring the `(x, y, button, ...)` LÖVE delivers. Any mouse button, anywhere on screen, toggles the
grid overlay.

**Checklist match:** none of Q1-Q10 by shape. Worth flagging mechanically: `love.mousepressed` is
**not gated by `GS.mode`** or `GS.init` anywhere in this file — a click on the title menu (before
`GS.init` is even true) runs this handler too, since LÖVE calls `love.mousepressed` unconditionally
and nothing here checks screen state.

**What the platform offers:** `compy.input.hooks.mousepressed` — "an existing
`function love.mousepressed(x, y, btn)` keeps working untouched" (`doc/input_api.md`, "Pointer and
click hooks"), since a project's own `love.*` handler seeds the matching hook at activation.

**Reachability:** Unconditional — every mouse press, every screen, from the menu screen onward.

### M4
**Location:** `maze_main.lua:145-148`. MAZE.

**The code:**
```lua
function is_shift_down()
  local d = love.keyboard.isDown
  return d("lshift") or d("rshift")
end
```

**What it does:** Hand-folds left/right Shift into one boolean by two direct `love.keyboard.isDown`
calls.

**Checklist match:** **Q2** — "re-implement[s] the left/right fold" exactly as the question
describes it (`isDown('lshift','rshift')`).

**What the platform offers:** `Key.shift()` — "Each folds its own left/right pair, so you never
name `lshift` and `rshift` yourself" (`doc/input_api.md`, "Held keys", rung 2).

**Reachability:** Called once per `love.keypressed`, unconditionally, for every key (see M7) — so
every keystroke pays for this fold whether or not the key is `escape`.

### M5
**Location:** `maze_main.lua:157-161` (`on_escape`), read together with the calling site at
`maze_main.lua:172-177`. MAZE.

**The code:**
```lua
function on_escape()
  if GS.mode == "game" then
    to_menu()
  end
end
...
if k == "escape" then
  if is_shift_down() then
    on_escape()
  end
  return
end
```

**What it does:** A hand-written combo check — "is this key Escape, and is Shift currently held" —
implemented as an `if`/`if` inside the top-level `keypressed` hook rather than as a registered
combo.

**Checklist match:** **Q8** — "Does one hook demultiplex several orthogonal combos by hand?" This
is exactly one branch of that demultiplexing (see M6, M7 for the rest of the same hook). The
comment at `maze_logic.lua:150-155` explains the modifier choice ("Shift+Esc steps back one level
... leaving the game to the console is Ctrl+Esc / the host") — a stated reason, not a guess.

**What the platform offers:** `compy.input.shortcuts.keypressed['shift+escape']` as one registered
combo — "A combo is its modifiers plus **one** trigger" (`doc/input_api.md`, "Event hooks and
shortcuts").

**Reachability:** Reached on every `escape` press regardless of `GS.mode` (the check runs before
the mode branch), but the *effect* (`to_menu()`) only fires when `GS.mode == "game"` — i.e. any
active level, any control mode.

### M6
**Location:** `maze_main.lua:163-170` (`game_key`). MAZE.

**The code:**
```lua
function game_key(k)
  local fn = SYSTEM_KEYS[k]
  if fn then
    fn()
  elseif ctrl_pressed then
    ctrl_pressed(k)
  end
end
```

**What it does:** Looks up the pressed key by name in a table (`SYSTEM_KEYS`), and if nothing
matches, falls through to whatever `ctrl_pressed` currently holds.

**Checklist match:** **Q8** — a hand-rolled per-key dispatch table inside the raw `keypressed` hook,
the same shape the question names (demultiplexing by hand instead of one shortcut per combo).
Mechanical note, not a guess: `SYSTEM_KEYS` currently has exactly one field, `menu` — the string
key `"menu"` coincides with the "context-menu" key labeled `"menu"` in `keyboard_graphics.lua`'s
layout row 6. Whether LÖVE ever actually delivers a `keypressed` event named `"menu"` is **unclear
from code** (not verified against LÖVE's `KeyConstant` list here), but if it does, `SYSTEM_KEYS.menu`
would be reachable from **both** a keypress and any mouse click (M3) through this one table entry —
recorded as observed, not asserted.

**What the platform offers:** Each `SYSTEM_KEYS[k]` entry is a shortcut candidate:
`compy.input.shortcuts.keypressed[k]`; the `ctrl_pressed` fallback is the project's own
mode-dispatch layer, which the API does not replace (it is domain state, not an input concept).

**Reachability:** Only reached when `GS.mode == "game"` (the `else` branch of the outer
`love.keypressed`, see M7). `ctrl_pressed`'s value set in MAZE, traced through every assignment
site in the repo: `handle_key` (from `controls.keys()`, active on levels with `controls = keys` —
`levels.lua`'s Track 1 `direct1`..`direct20`, and sandbox levels `intro`, `one_turn`, `two_turns`,
which inherit `keys` forward since `apply_attrs` at `maze_logic.lua:162-174` only overwrites
`cur_controls` when a level sets `maze.controls`), `plan_key` (from `controls.plan()`, active only
on Track 2's `plan1`..`plan20`), and `nil` (from `arm_editor()` — every level with
`controls = editor`, which is `two_turns2` onward through the rest of the sandbox track, and from
`to_menu()`).

### M7
**Location:** `maze_main.lua:172-184` (`love.keypressed`). MAZE.

**The code:**
```lua
function love.keypressed(k)
  if k == "escape" then
    if is_shift_down() then
      on_escape()
    end
    return
  end
  if GS.mode == "menu" then
    menu_key(k)
  else
    game_key(k)
  end
end
```

**What it does:** The single raw `love.keypressed` hook for the whole program: branches on the
literal key `escape`, then on `GS.mode`, routing to `menu_key` (M19) or `game_key` (M6).

**Checklist match:** **Q7** — physical keyboard state (`is_shift_down()`) is consulted, but notably
**already at the top of the handler**, its first line — the position Q7 recommends ("Read the
keyboard early — top of the handler ... into names carrying domain meaning"), not "deep inside
logic." Recorded as a shape match on subject matter, not as a violation. **Q8** — the handler as a
whole is the hand-rolled demultiplexer that M5/M6 are branches of.

**What the platform offers:** The hook is exactly what `compy.input.hooks.keypressed` is —
"one fallback function per event ... seeded when no explicit hook was supplied" — with the combo
branches (M5) split into `shortcuts.keypressed[...]` entries per "Choosing the mechanism: a
shortcut is for a one-off transition ... one binding per thing, listable as data, instead of one
hook demultiplexing a dozen combos by hand."

**Reachability:** Every keypress, every screen, unconditionally (LÖVE's own `love.keypressed`).

### M8
**Location:** `maze_main.lua:186-189` (`love.keyreleased`). MAZE.

**The code:**
```lua
function love.keyreleased(k)
  release_shift(k)
  plan_key_up(k)
end
```

**What it does:** Forwards every key-release event to two consumers unconditionally: the macro
system's shift-release handler (M13) and the plan mode's held-key clear (M17).

**Checklist match:** none by itself — pure fan-out. The two functions it calls are the sites with
checklist shape (see M13, M17).

**What the platform offers:** `compy.input.hooks.keyreleased` — same seeding rule as `keypressed`
(`doc/input_api.md`, "Event hooks and shortcuts").

**Reachability:** Every key release, unconditionally, every screen — note this is **not** gated by
`GS.mode`, unlike `game_key`. `release_shift` and `plan_key_up` are themselves no-ops when their
respective mode isn't active (see M13, M17), so the gating happens inside the callees, not here.

### M9
**Location:** `controls.lua:10-13` (`keys()`). MAZE.

**The code:**
```lua
function keys()
  ctrl_pressed = handle_key
  ctrl_update = nil
end
```

**What it does:** One of the "control mode initializer" functions named in the file's header
comment (`ctrl_pressed(k)` from `love.keypressed`, `ctrl_update()` from `love.update`) — assigns the
key-dispatch indirection to `handle_key` (M12) for direct keyboard control.

**Checklist match:** none — an assignment site for the indirection, not an input read.

**What the platform offers:** N/A directly (domain wiring).

**Reachability:** Called as `cur_controls()` whenever a level sets `controls = keys` or inherits it
(see M6's reachability note for the exact level list).

### M10
**Location:** `controls.lua:18-22` (`plan()`). MAZE.

**The code:**
```lua
function plan()
  ctrl_pressed = plan_key
  ctrl_update = plan_update
  plan_reset()
end
```

**What it does:** Wires plan-a-path mode: key dispatch to `plan_key` (M16), per-tick update to
`plan_update`, and resets the plan buffer.

**Checklist match:** none — assignment site.

**What the platform offers:** N/A directly (domain wiring).

**Reachability:** Called as `cur_controls()` on Track 2 levels (`plan1`..`plan20`) only — no
sandbox level sets `controls = plan`.

### M11
**Location:** `macro.lua:5-8` (`SHIFT_KEYS`). MAZE.

**The code:**
```lua
SHIFT_KEYS = {
  lshift = true,
  rshift = true
}
```

**What it does:** A lookup table naming both shift scancodes, used by `handle_key` and
`release_shift` (M12, M13) to recognize a shift key by name.

**Checklist match:** **Q1** (a table mirroring which physical keys count as "shift" — the
"hard-codes *which keys are modifiers*" case Q2's action explicitly calls out) and **Q2** (this
*is* the left/right fold, done as a membership table instead of an `isDown` pair, but the same
re-implementation).

**What the platform offers:** `Key.shift()` — no local modifier-set table needed (`doc/input_api.md`,
"Held keys", rung 2; also Decision 31, "a set that has changed once," cited by Q2).

**Reachability:** Consulted only inside `handle_key`/`release_shift`, i.e. only when the macro
system is live — see M12 reachability.

### M12
**Location:** `macro.lua:72-83` (`handle_key`). MAZE.

**The code:**
```lua
function handle_key(k)
  if SHIFT_KEYS[k] then
    macro_state.shift_held = true
    return
  elseif macro_state.recording then
    record_key(k)
  elseif macro_state.shift_held then
    start_recording(k)
  else
    execute_key(k)
  end
end
```

**What it does:** The `ctrl_pressed` handler for "keys" mode. On a shift key, sets a held flag and
returns; while recording, appends to the macro body; if shift is (still) held and a non-shift key
arrives, starts recording under that key's name; otherwise executes the key as a command.

**Checklist match:** **Q1** — `macro_state.shift_held` is a boolean mirroring Shift's held state,
maintained by hand across two separate event channels (see M13). **Q6** — this is the *opening*
half of a state opened on `keypressed` and closed on the mirrored `keyreleased` (M13) for the same
key: pressing Shift sets `shift_held = true` here; releasing it clears it and finishes recording in
`release_shift`. This is precisely the shape Q6 and the "Choosing the mechanism" DON'T example
describe (`compy.input.shortcuts.keypressed['alt+h']` paired with a mirrored `keyreleased` entry).

**What the platform offers:** Q6's action — "Antipattern; replace it ... Poll the condition
instead." For "is Shift held right now" specifically: `Key.shift()`
(`doc/input_api.md`, "Held keys").

**Reachability:** `handle_key` is the value of `ctrl_pressed` only while `keys()` is the active
control mode — Track 1 (`direct1`..`direct20`) and sandbox `intro`/`one_turn`/`two_turns` (see M6).
It is reached via `game_key`'s `ctrl_pressed(k)` fallback (M6), so only on keys with no
`SYSTEM_KEYS` entry, and only while `GS.mode == "game"`.

### M13
**Location:** `macro.lua:87-92` (`release_shift`). MAZE.

**The code:**
```lua
function release_shift(k)
  if SHIFT_KEYS[k] then
    macro_state.shift_held = false
    finish_recording()
  end
end
```

**What it does:** The *closing* half paired with M12: on a shift key release, clears the held flag
and, if a macro was being recorded, finishes and saves it.

**Checklist match:** **Q6** — the mirrored-close half of the same antipattern shape as M12. Also
notable against the "Rules of restraint" > "Purpose beats shape" caution: this pairing has a stated
purpose (macro recording keyed by holding Shift), so it may be intentional design rather than an
accidental antipattern — recorded as a shape match, not a verdict.

**What the platform offers:** Same as M12 — Q6's action, or (per "Choosing the mechanism")
polling `Key.shift()` at the point a key is pressed instead of tracking state across two channels.
Note the doc's own caution applies here nearly verbatim: "A modifier's own release cannot even be
bound" for the *shortcut* mechanism, so a direct shortcut-based replacement of this exact pairing is
not literally possible — this would need restructuring, not a 1:1 swap (recorded as observed
friction, not a recommendation).

**Reachability:** Called unconditionally from `love.keyreleased` (M8) for every key release on every
screen; the body only acts when `k` is a shift key AND `macro_state.recording` was already true —
which requires having been in "keys" mode with shift held down first (see M12's reachability).
Because M8 is not gated by `GS.mode`, a shift-release *after* leaving "keys" mode (e.g. after
`to_menu()`) would still run this function, though `SHIFT_KEYS[k]` and prior recording state make
the effect a no-op outside the macro flow — unclear from code whether that no-op is ever actually
exercised in practice.

### M14
**Location:** `macro.lua:19-29` (`start_recording`). MAZE.

**The code:**
```lua
function start_recording(key)
  local name = key:upper()
  if PRIMITIVES[name] then
    sfx.wrong()
    return
  end
  macro_state.recording = true
  macro_state.name = name
  ...
end
```

**What it does:** Called from `handle_key` (M12) when Shift is held and a non-shift key arrives —
i.e. detects the two-key chord "Shift + arbitrary letter" via the imperative `shift_held` flag
rather than any combo mechanism.

**Checklist match:** none of Q1-Q10 directly (the state it consumes is M12's Q1/Q6 site). Matches
`doc/input_api.md`'s explicit callout instead: "Combos of ordinary keys ... are deliberately not
expressible [in the shortcut vocabulary] ... Anything beyond exact-or-class matching belongs in a
hook, which sees every event on its channel." A "Shift + any letter" chord is exactly that case.

**What the platform offers:** Nothing documented as a direct combo (the trigger set is unbounded —
any letter), so this stays a hook-level concern per the quoted passage; no single-line replacement
is named.

**Reachability:** Same as M12 — "keys" mode only, and only reached when `shift_held` is already
true and the key is not itself a shift key.

### M15
**Location:** `maze_plan.lua:16`. MAZE.

**The code:**
```lua
plan_held = { }
```

**What it does:** A module-global table of keys currently down, scoped to plan mode, reset by
`plan_reset()`.

**Checklist match:** **Q1** — "a table of keys currently down," the question's own example
phrase.

**What the platform offers:** Q1's action — "Delete it; ask at the point of use" — or, since this
table exists specifically to detect a press-edge under key repeat, a shortcut with
`fn.ignore_repeat` (see M16).

**Reachability:** Read/written only by `plan_key`/`plan_key_up` (M16/M17), i.e. only while plan mode
is active — Track 2 only.

### M16
**Location:** `maze_plan.lua:139-148` (`plan_key`). MAZE.

**The code:**
```lua
function plan_key(k)
  if plan_held[k] then
    return
  end
  plan_held[k] = true
  if plan_locked() then
    return
  end
  plan_dispatch(k)
end
```

**What it does:** The `ctrl_pressed` handler for plan mode. Comment above it: "A held key repeats
keypresses; act on the edge only." Uses `plan_held` (M15) as the previous-value companion to derive
a press-edge, then dispatches once per physical press.

**Checklist match:** **Q1** (the companion table) and **Q4** — textbook "per-frame poll [here,
per-event poll] plus a previous-value companion, deriving a transition." The doc's own caution under
Q4 is directly relevant: "a bare-key binding matches only when no modifier is held, where the poll
fired regardless" — `plan_key` currently fires for a bare key name (e.g. `"f"`) whether or not
Shift/Ctrl/Alt is also held (LÖVE delivers the same `k` either way), so a literal `shortcuts.keypressed['f']`
replacement would narrow behaviour versus today's code — flagged per "A narrowing is a change,"
not decided here.

**What the platform offers:** `fn.ignore_repeat(f)` for the edge behaviour without a companion
table at all — "skip `f` on a repeat" (`doc/input_api.md`, "A held key repeats").

**Reachability:** `plan_key` is `ctrl_pressed`'s value only while `plan()` is the active control
mode — Track 2 (`plan1`..`plan20`) exclusively, reached via `game_key`'s fallback (M6).

### M17
**Location:** `maze_plan.lua:150-152` (`plan_key_up`). MAZE.

**The code:**
```lua
function plan_key_up(k)
  plan_held[k] = nil
end
```

**What it does:** Clears the held-key mirror on release — the companion-clear half of M15/M16.

**Checklist match:** **Q1** — this is precisely the "`*_was_down` companion" the question names,
just per-key instead of one global boolean.

**What the platform offers:** Same as M15/M16 — no companion table needed if the transition is read
as an event (Q4's action) or the state as a poll (`Key.any_pressed(k)`).

**Reachability:** Called unconditionally from `love.keyreleased` (M8) for every key, every screen;
the write is harmless outside plan mode (clears a key that was never set), but it does run outside
plan mode too, same caveat as M13.

### M18
**Location:** `maze_plan.lua:109-135` (`PLAN_ACTS` table and `plan_dispatch`). MAZE.

**The code:**
```lua
PLAN_ACTS = {
  backspace = plan_backspace,
  ["return"] = plan_submit,
  ["."] = plan_jump,
  [","] = plan_jump
}
...
function plan_dispatch(k)
  local act = PLAN_ACTS[k]
  if act then
    act(k)
    return
  end
  local c = k:upper()
  if plan_movement(c) then
    plan_append(c)
  end
end
```

**What it does:** A dispatch table keyed by literal key name for the four non-movement plan
actions, with a fallback that appends any other recognized movement letter as a plan tile.

**Checklist match:** **Q8** — a hand-rolled per-key dispatch table, called from `plan_key` (M16),
one level removed from the raw hook. Each `PLAN_ACTS` entry is a candidate one-per-combo shortcut,
though note it is reached only after the edge-detection in M16, so any shortcut-based rewrite would
need to fold in that edge behaviour too, not just this table.

**What the platform offers:** `compy.input.shortcuts.keypressed[k]` per entry (`doc/input_api.md`,
"Event hooks and shortcuts").

**Reachability:** Same as M16 — Track 2 only, and only for keys that were not already filtered as
repeats.

### M19
**Location:** `menu.lua:43-50` (`menu_key`). MAZE.

**The code:**
```lua
function menu_key(k)
  for _, t in ipairs(TRACKS) do
    if t.key == k then
      start_track(t)
      return
    end
  end
end
```

**What it does:** Scans `TRACKS` (`levels.lua:784-800`, keys `"1"`, `"2"`, `"3"`) for a matching
key name and starts that track.

**Checklist match:** **Q8** — a hand-iterated table keyed by input, called directly from the raw
`love.keypressed` hook (M7) rather than three registered shortcuts.

**What the platform offers:** Three `compy.input.shortcuts.keypressed['1']` /
`['2']` / `['3']` entries, one per track — "decomposition, not capability"
(`doc/input_api.md`, "Choosing the mechanism").

**Reachability:** Only reached while `GS.mode == "menu"` — the title screen, before a track is
picked.

---

## DRAW-only sites (`draw_main.lua` and `draw_menu.lua`)

Structural note established above: `draw_main.lua` never requires `controls.lua`, `macro.lua`, or
`maze_plan.lua`. Tracing every assignment to `ctrl_pressed` in the files DRAW actually loads (only
`arm_editor` in `core_editor.lua`, value `nil`, and `toDrawMenu` in `draw_main.lua`, value `nil`)
shows **`ctrl_pressed` is always `nil` in DRAW** — a fact read from the code, not a guess.

### D1
**Location:** `draw_main.lua:261-270`. DRAW.

**The code:**
```lua
tab_was_down = false

function pollPictureProgression()
  local down = love.keyboard.isDown("tab")
  local edge = down and not tab_was_down
  if edge and GS.won then
    nextPictureLevel()
  end
  tab_was_down = down
end
```

**What it does:** Same shape as M1, a separate global in this file: polls Tab, derives a press-edge
against a stored previous value, and advances the picture level on that edge if `GS.won`.

**Checklist match:** **Q1** and **Q4**, identically to M1.

**What the platform offers:** Same as M1 — a `shortcuts.keypressed['tab']` shortcut.

**Reachability:** Called from `love.update` whenever `GS.screen == "game"` (both `free` and
`picture` draw modes), but the edge only *acts* when `GS.won` — which `finish_run()`
(`draw_main.lua:64-75`) only ever sets when `currentDrawLevel()` is non-nil, i.e. `GS.draw_mode ==
"picture"`. So the poll runs in both modes; the action is reachable only in picture mode.

### D2
**Location:** `draw_main.lua:272-282` (`love.update`). DRAW.

**The code:**
```lua
function love.update(dt)
  ensure_init()
  if GS.screen ~= "game" then
    return
  end
  pollPictureProgression()
  stepDrawProgram(dt)
  if ctrl_update then
    ctrl_update(dt)
  end
end
```

**What it does:** Same dispatch-hub role as M2.

**Checklist match:** none — infrastructure.

**What the platform offers:** N/A. Recorded value set: `ctrl_update` in DRAW is `process_user_input`
(from `arm_editor`, always — see C1) or `nil` (from `toDrawMenu` at `draw_main.lua:219-228`, and
from `finish_run` at `draw_main.lua:64-75`).

**Reachability:** Every frame while `GS.screen == "game"`.

### D3
**Location:** `draw_main.lua:293-303`. DRAW.

**The code:**
```lua
SYSTEM_KEYS = { }

function SYSTEM_KEYS.menu()
  if GS.draw_mode ~= "picture" then
    return
  end
  GS.hint = not GS.hint
  sfx.sword()
end

love.mousepressed = SYSTEM_KEYS.menu
```

**What it does:** Same raw-assignment shape as M3, DRAW's own copy. Guards on picture mode before
toggling the hint.

**Checklist match:** none by shape (same as M3).

**What the platform offers:** `compy.input.hooks.mousepressed`, same as M3.

**Reachability:** Unconditional mouse-press handler, every screen including DRAW's own menu screen;
body is a no-op in free-draw mode and on the menu screen (`GS.draw_mode` is `nil` there).

### D4
**Location:** `draw_main.lua:305-308`. DRAW.

**The code:**
```lua
function is_shift_down()
  local down = love.keyboard.isDown
  return down("lshift") or down("rshift")
end
```

**What it does:** Byte-for-byte the same fold as M4, duplicated in this file.

**Checklist match:** **Q2**, identically to M4.

**What the platform offers:** `Key.shift()`, same as M4.

**Reachability:** Same as M4 — called once per keypress from the escape branch (D7).

### D5
**Location:** `draw_main.lua:310-314` (`on_escape`), read with the call site at `:325-330`. DRAW.

**The code:**
```lua
function on_escape()
  if GS.screen == "game" then
    toDrawMenu()
  end
end
```

**What it does:** Same shape as M5 — Shift+Escape steps back to the draw menu.

**Checklist match:** **Q8**, same reasoning as M5.

**What the platform offers:** `shortcuts.keypressed['shift+escape']`, same as M5.

**Reachability:** Reached on every `escape` press, effect gated to `GS.screen == "game"`.

### D6
**Location:** `draw_main.lua:316-323` (`drawGameKey`). DRAW.

**The code:**
```lua
function drawGameKey(key)
  local fn = SYSTEM_KEYS[key]
  if fn then
    fn()
  elseif ctrl_pressed then
    ctrl_pressed(key)
  end
end
```

**What it does:** Same table-then-fallback shape as M6.

**Checklist match:** **Q8**, same reasoning as M6. Mechanical addition specific to DRAW, established
above: since `ctrl_pressed` is always `nil` here, **the `elseif` branch is dead code** — every
keypress reaching this function during a game screen does nothing unless it happens to match a
`SYSTEM_KEYS` key (only `"menu"`, same "menu"-key-name coincidence as M6, unclear from code whether
LÖVE ever names a key that). This is a code-grounded observation, not a guess: the assignment sites
for `ctrl_pressed` in every file DRAW requires never set it to anything but `nil`.

**What the platform offers:** Same as M6 for the `SYSTEM_KEYS` half; the fallback has no
counterpart to offer since it is unreachable.

**Reachability:** Reached only when `GS.screen == "game"` (the `else` branch of D7). As established,
its body is functionally inert for ordinary keys.

### D7
**Location:** `draw_main.lua:325-337` (`love.keypressed`). DRAW.

**The code:**
```lua
function love.keypressed(key)
  if key == "escape" then
    if is_shift_down() then
      on_escape()
    end
    return
  end
  if GS.screen == "menu" then
    drawMenuKey(key)
  else
    drawGameKey(key)
  end
end
```

**What it does:** Same umbrella shape as M7.

**Checklist match:** **Q7** (modifier check already at the top, same nuance as M7) and **Q8** (the
demultiplexer as a whole).

**What the platform offers:** Same as M7.

**Reachability:** Every keypress, unconditionally. Note DRAW has **no `love.keyreleased` at all**
(confirmed by the earlier grep sweep) — there is no DRAW counterpart to M8/M13/M17, consistent with
DRAW never loading the macro or plan-mode files that would consume a release event.

### D8
**Location:** `draw_menu.lua:38-45` (`drawMenuKey`). DRAW.

**The code:**
```lua
function drawMenuKey(key)
  for _, choice in ipairs(DRAW_MODES) do
    if choice.key == key then
      startDrawMode(choice.mode)
      return
    end
  end
end
```

**What it does:** Same scan-a-table-by-key shape as M19, over `DRAW_MODES` (keys `"1"`, `"2"`).

**Checklist match:** **Q8**, same reasoning as M19.

**What the platform offers:** Two `shortcuts.keypressed['1']` / `['2']` entries, same as M19.

**Reachability:** Only while `GS.screen == "menu"`.

---

## Swept, found no input site

Read in full and grepped; neither directly reads input nor is on the dispatch chain, recorded for
completeness per the method's exhaustiveness requirement:

- `keyboard_graphics.lua` (MAZE+DRAW) — a static keyboard-diagram renderer (`draw_key`,
  `draw_keycap_banner`, `draw_keyboard`). Draws key caps; reads no device state.
- `maze_logic.lua`'s `CMD_HANDLERS` (`:345-353`) and `draw_main.lua`'s `CMD_HANDLERS` (`:126-135`)
  — dispatch tables keyed by **command character**, fed exclusively by `execute_next`
  (`core_anim.lua:133-139`) pulling from `player.queue`. The queue is filled by decoded program
  text (`script.lua`), decoded macro playback (`macro.lua:execute_key`), or decoded plan tiles
  (`maze_plan.lua:plan_enqueue`) — never directly by a keypress. Not an input site; explicitly
  excluded rather than silently skipped, since it sits exactly where the prompt warned an
  indirection could hide one.
- `maze_render.lua`, `draw_render.lua`, `core_render.lua`, `core_sprites.lua`, `player.lua`,
  `core_constants.lua`, `maze_constants.lua`, `draw_constants.lua`, `maze_decorations.lua`,
  `draw_levels.lua` — grepped for `key|mouse|touch|input|shift|ctrl|escape` and for any `love.*`
  call; hits are either comments/labels (e.g. "Tab keycap" prose, `readfile("legend.txt")`) or
  non-input code (`targetEdgeKey`, an unrelated data-table key). No site found.

---

## Counts

Recomputed directly from the entries above; a CORE site is one site, counted once, and noted as
reachable from both programs rather than doubled into per-program totals.

| Question | CORE | MAZE | DRAW |
|---|---|---|---|
| Q1 | 0 | 6 (M1, M11, M12, M15, M16, M17) | 1 (D1) |
| Q2 | 0 | 2 (M4, M11) | 1 (D4) |
| Q3 | 0 | 0 | 0 |
| Q4 | 0 | 2 (M1, M16) | 1 (D1) |
| Q5 | 0 | 0 | 0 |
| Q6 | 0 | 2 (M12, M13) | 0 |
| Q7 | 0 | 1 (M7) | 1 (D7) |
| Q8 | 0 | 5 (M5, M6, M7, M18, M19) | 4 (D5, D6, D7, D8) |
| Q9 | 0 | 0 | 0 |
| Q10 | 0 | 0 | 0 |
| none | 2 (C1, C2) | 6 (M2, M3, M8, M9, M10, M14) | 2 (D2, D3) |
| **Total sites** | **2** | **19** | **8** |

(M1/D1 and M4/D4 etc. are counted once per program even though the same *shape* recurs — the code
is duplicated, not shared, between `maze_main.lua` and `draw_main.lua`; CORE sites C1/C2 apply to
both programs' totals if a combined per-program figure is wanted: MAZE-effective = 21, DRAW-effective
= 10.)

Some sites match two questions (e.g. M1 matches both Q1 and Q4); the table counts each match, so
column sums exceed "Total sites" for MAZE and DRAW.

---

## Anything the checklist has no question for

- **Pre-`compy.input` API usage, wholesale.** C1/C2 (`user_input()`, `input_text()`,
  `GS.input:is_empty()`) are not shaped like any Q1-10 antipattern — they are simply calls to
  globals `doc/input_api.md`'s own Migration table lists as **retired**, with no compatibility
  shim ("The retired polling globals have no replacement compatibility layer"). This is the single
  largest finding: the entire text-entry path in both programs, which is the *only* way either
  program solicits typed commands, predates the new input surface and is written entirely against
  the old one.
- **Zero `Key.*` usage anywhere in the repo**, confirmed by grep with no hits. Every modifier
  question in this codebase (M4, M11, D4, and the shift/macro pairing M12/M13) is answered with raw
  `love.keyboard.isDown`, never the folded accessor the new API ships. This is a whole-repo fact,
  not a single site.
- **Two independent copies of the same shapes.** `is_shift_down`, `tab_was_down` /
  `poll_tab_progression`, `SYSTEM_KEYS.menu` / `love.mousepressed`, `on_escape`, and the top-level
  `love.keypressed` demultiplexer all exist twice — once in `maze_main.lua`, once in
  `draw_main.lua` — byte-for-byte or near-identical. Not itself a checklist question (nothing in
  Q1-10 is about duplication across files), but mechanically true and visible from the entries
  above (M1/D1, M3/D3, M4/D4, M5/D5, M6/D6, M7/D7).
- **A "menu"-named `SYSTEM_KEYS` entry that could be dual-reachable** (M6, D6): the only
  `SYSTEM_KEYS` field, `"menu"`, is bound to mouse clicks via direct assignment, but its table key
  also matches the label of a physical key drawn in `keyboard_graphics.lua`. Whether that creates a
  real second reachability path depends on LÖVE's actual key-name constants, which is outside what
  this repo's code can confirm — recorded as "unclear from code," per the rules, rather than
  guessed either way.
- **Q6's own replacement is not always available.** M13's caution applies generally: for any
  Shift-open/Shift-close pairing (M12/M13), the shortcut mechanism the checklist recommends cannot
  bind the closing half at all ("A modifier's own release cannot even be bound"), so a mechanical
  Q6 conversion is not a straightforward swap for this specific pair — it would need restructuring,
  which is exactly the class of change the "Rules of restraint" say to record and defer rather than
  sweep.

---

## Parent review (session39, 2026-08-12) — verified, plus one addition

The worker's report is not the tree, so the headline claims were checked in code before anything
was built on them.

**Confirmed:**

- **`ctrl_pressed` is structurally always `nil` in DRAW, so `drawGameKey`'s fallback branch is dead
  code.** Verified two ways: `ctrl_pressed` is assigned non-`nil` in exactly two places, both in
  `controls.lua` (`keys()` → `handle_key`, `plan()` → `plan_key`); and `controls.lua` is neither in
  `draw_main.lua`'s `require` list nor in `.compy/build`'s `DRAW` set — it is MAZE-only. So in the
  emitted `draw/` project the *only* live branch of `drawGameKey` is `SYSTEM_KEYS[key]`, which no
  key name can reach (`SYSTEM_KEYS.menu` is bound to `love.mousepressed`). **Draw's entire in-game
  keyboard surface is therefore the editor field, the Escape branch, and the Tab poll.** This is a
  real find and it was not in the parent's own earlier reading.
- **Zero `Key.*` usage in the repo** — independently confirmed by grep over the working tree.
- **Counts are self-consistent** and recomputed from the table (2 + 19 + 8 = 29), with the
  double-matching caveat stated rather than hidden.
- **Read-only was honoured:** `maze` is still on `newinput-edge`, working tree clean, no commits.

**One addition — the `shift_held` mirror has a THIRD consumer, and it is a display.**
`maze_render.lua:221` (`draw_macro_ui`) reads `macro_state.shift_held` to call `draw_dim()` — the
screen dims while Shift is held, which is how the game says *"you are about to name a macro"*. The
inventory records M12/M13 as the mirror's write sites and its `keys()`-mode reachability, and
classifies `maze_render.lua` under "swept, found no site"; that is defensible (the mirror is one
site, not one per reader) but it **understates the conversion**, because the two consumers ask
different questions:

- **event-time** (`handle_key`): *was Shift down when this key arrived?*
- **frame-time display** (`draw_macro_ui`): *is Shift down now?*

`Key.shift()` answers both, but they are separate call sites with separate timing, and the current
mirror's failure mode differs accordingly: a lost `keyreleased` does not only break macro naming, it
**leaves the screen permanently dimmed**. That matters under the owner's calibration (a) — this is
not a focus-shaped risk whose only cost is a missed event, it is a **stuck visible UI state**, so
"leave a comment with a warning" is a weaker answer here than it was for `keyboard`'s `bubble.lua`.
Recorded as evidence for the analysis, **not** as a verdict; the ruling is the owner's.
