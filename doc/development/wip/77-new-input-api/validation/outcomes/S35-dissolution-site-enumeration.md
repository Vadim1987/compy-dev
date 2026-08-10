---
description: Complete site inventory for two pending changes — dissolving the framework-maintained held-key set (Change A) and withdrawing `gui` from the modifier set (Change B) — read-only enumeration, no edits made
status: complete
audience: developer
authored: llm
reviewed: none
---

# S35 — Dissolution site enumeration

Read-only inventory. No code was changed to produce this. Method: grep across
`src/`, `tests/`, `src/examples/` for `keys_pressed`, `held_keys`, `held_proxy`,
`held_backing`, `Controller.held`, `INPUT.held`, `gui`/`lgui`/`rgui`, and the
prose phrases "held set" / "held-key" / "pressed-keys table"; each hit read in
full file context; `mcp__lua-lsp__references` cross-checked against
`Controller.keys_pressed`, `Controller.held_keys`, `Key.mod_triples`, `gui_k`.

**Cross-check result: LSP and grep agreed on every symbol-shaped occurrence of
`Controller.keys_pressed` / `Controller.held_keys` — the LSP found nothing
grep missed there.** But the LSP is blind to the dynamic half of the picture,
exactly as flagged going in: it returns **zero** hits for the many
`compy.input.keys_pressed` / `input.keys_pressed` reads, because that name is
resolved through `build_input_surface`'s metatable dispatch
(`consoleController.lua:539-541`, string-key compare inside a closure) and
`examples/keyboard/input.lua`'s own `INPUT` proxy (`__index` on a plain
string key) — there is no AST edge from either use site to a declared field
called `keys_pressed`. Every occurrence under "compy.input.keys_pressed" and
every `INPUT.held`/`INPUT.shift`/`INPUT.ctrl`/`INPUT.alt` read below was found
by grep only. This is the disagreement the task asked to surface: **trust
grep as the completeness backstop for this feature's proxy-heavy surface;
treat the LSP's silence on `compy.input.keys_pressed` as expected, not as
evidence of absence.**

Two independent "held" tables exist in the tree that are **not** Change A's
target and are excluded below — see "Surprises".

---

## 1. WRITE — mutates the held-key set

| Site | Quote |
|---|---|
| `src/controller/controller.lua:788` | `Controller.keys_pressed[k] = true` |
| `src/controller/controller.lua:906` | `Controller.keys_pressed[k] = nil` |

Both are inside `Controller.setup_callback_handlers`, on the raw
`love.handlers.keypressed` / `love.handlers.keyreleased` gateway entries —
i.e. they run for **every** physical key event system-wide, not only while a
project runs. No other write site exists anywhere in `src/` or `tests/`
(non-test code never assigns into `Controller.keys_pressed`; tests do, see
§6).

Method: grep + LSP agree (LSP `references` on `keys_pressed` returns exactly
these two plus the read/plumbing sites below).

---

## 2. READ — reads the set's contents (direct index, or through a proxy)

### Framework (`src/`, non-example)

| Site | Quote |
|---|---|
| `src/controller/controller.lua:398` | `if keys_pressed[m[1]] or keys_pressed[m[2]] then` (inside `combo_string`) |
| `src/controller/controller.lua:413` | `if keys_pressed[m[1]] or keys_pressed[m[2]] then` (inside `any_mod`) |

These are the only two places in framework code that actually dereference a
key's boolean membership. Everything else that touches
`Controller.keys_pressed` in `src/` either mutates it (§1) or only holds/passes
the table reference without indexing it (§3, PLUMBING).

Method: grep + LSP agree.

### Examples (`src/examples/keyboard/`) — reported separately per instructions

All of these read `compy.input.keys_pressed` **indirectly**, through the
example's own `INPUT` proxy (`examples/keyboard/input.lua:54-62`) or its
`modHeld` helper (`:108-114`). Found by grep only — the LSP does not resolve
`INPUT.shift`/`INPUT.held` back to `compy.input.keys_pressed` (dynamic
`__index` dispatch on a string key).

| Site | Quote |
|---|---|
| `src/examples/keyboard/input.lua:110` | `if held[a] or held[b] then` (inside `modHeld`, the actual dereference) |
| `src/examples/keyboard/help.lua:11` | `return INPUT.held.h and INPUT.alt and not INPUT.ctrl` |
| `src/examples/keyboard/input.lua:192` | `if INPUT.alt then return end` |
| `src/examples/keyboard/input.lua:193` | `if INPUT.ctrl then return end` |
| `src/examples/keyboard/input.lua:195` | `dbgLog("TI " .. t .. " sh=" .. tostring(INPUT.shift))` |
| `src/examples/keyboard/input.lua:197` | `capsReconcile(t, INPUT.shift)` |
| `src/examples/keyboard/alt.lua:203` | `if k == "h" and INPUT.ctrl and INPUT.alt then` |
| `src/examples/keyboard/alt.lua:230` | `return INPUT.shift` |
| `src/examples/keyboard/alt.lua:240` | `if INPUT.shift then` |
| `src/examples/keyboard/keyboard_view.lua:171` | `if INPUT.shift then return not CAPS_STATE.on end` |
| `src/examples/keyboard/keyboard_view.lua:178` | `if KB_SHIFTLABEL and INPUT.shift and SHIFT_MAP[name] then` |

That is 11 read call sites in one example game, all downstream of the single
`compy.input.keys_pressed` proxy access at `input.lua:57`/`:109` (listed as
PLUMBING below, since those two lines hand the reference onward rather than
dereferencing it themselves).

---

## 3. PLUMBING — parameters, upvalues, accessor functions, the memoised view, anything that builds/caches/passes the set along

### Framework (`src/`, non-example)

| Site | Quote |
|---|---|
| `src/controller/controller.lua:395` | `local function combo_string(k, keys_pressed)` |
| `src/controller/controller.lua:411` | `local function any_mod(keys_pressed)` |
| `src/controller/controller.lua:429` | `local held_backing, held_proxy` |
| `src/controller/controller.lua:430` | `local function held_keys()` |
| `src/controller/controller.lua:431` | `local backing = Controller.keys_pressed` |
| `src/controller/controller.lua:432` | `if held_backing ~= backing then` |
| `src/controller/controller.lua:433` | `held_backing = backing` |
| `src/controller/controller.lua:434-440` | `held_proxy = setmetatable({ }, { __index = backing, __newindex = function() error('keys_pressed is read-only', 2) end, __pairs = function() return pairs(backing) end, })` |
| `src/controller/controller.lua:442` | `return held_proxy` |
| `src/controller/controller.lua:499` | `combo_string = combo_string,` (exported accessor) |
| `src/controller/controller.lua:500` | `any_mod = any_mod,` (exported accessor) |
| `src/controller/controller.lua:501` | `held_keys = held_keys,` (exported view-builder) |
| `src/controller/consoleController.lua:527` | `local function build_input_surface(state, methods, get_keys)` |
| `src/controller/consoleController.lua:540` | `if k == 'keys_pressed' then return get_keys() end` |
| `src/controller/consoleController.lua:829` | `local held = Controller.held_keys` |
| `src/controller/consoleController.lua:830` | `return build_input_surface(state, methods, held)` |
| `src/controller/projectInputController.lua:103` | `local keys = Controller.keys_pressed` |
| `src/controller/projectInputController.lua:105` | `if not Controller.any_mod(keys) then return end` |
| `src/controller/projectInputController.lua:106` | `return tbl[Controller.combo_string('*', keys)]` |
| `src/controller/projectInputController.lua:108` | `local sc = tbl[Controller.combo_string(trigger, keys)]` |
| `src/controller/projectInputController.lua:110` | `return tbl[Controller.combo_string('*', keys)]` |

22 rows (line 434-440 counted as one row, the proxy's `setmetatable` literal).

### Examples (`src/examples/keyboard/`)

| Site | Quote |
|---|---|
| `src/examples/keyboard/input.lua:54` | `INPUT = setmetatable({ upRecent = { } }, {` |
| `src/examples/keyboard/input.lua:55` | `  __index = function(_, k)` |
| `src/examples/keyboard/input.lua:57` | `if k == "held" then return compy.input.keys_pressed end` |
| `src/examples/keyboard/input.lua:58` | `if k == "shift" then return modHeld("lshift", "rshift") end` |
| `src/examples/keyboard/input.lua:59` | `if k == "ctrl" then return modHeld("lctrl", "rctrl") end` |
| `src/examples/keyboard/input.lua:60` | `if k == "alt" then return modHeld("lalt", "ralt") end` |
| `src/examples/keyboard/input.lua:108` | `function modHeld(a, b)` |
| `src/examples/keyboard/input.lua:109` | `local held = compy.input.keys_pressed` |

---

## 4. DECLARATION — type annotations, field declarations, exported table entries

| Site | Quote |
|---|---|
| `src/types.lua:251` | `--- @field keys_pressed table` (inside `@class CompyInput`) |
| `src/controller/controller.lua:393` | `--- @param keys_pressed table  { keyname -> true } live held-key set` |
| `src/controller/controller.lua:409` | `--- @param keys_pressed table` |
| `src/controller/controller.lua:498` | `keys_pressed = { },` (the `Controller` table's own field — the set's canonical home) |
| `src/controller/consoleController.lua:525` | `--- @param get_keys fun(): table` |

Note: the `--- @class Controller` annotation block (`controller.lua:445-455`)
declares `@field _defaults`, `@field _userhandler`, and five method fields —
it does **not** carry `@field keys_pressed table`, `@field combo_string
function`, `@field any_mod function`, or `@field held_keys function`, even
though all four are real fields on the `Controller` table assigned a few
lines below (line numbers 498-501). The type declaration for this set was
already incomplete before this change; see "Surprises".

---

## 5. PROSE — comments that name it (comment-only lines; code on the same line is cited under its own class above)

### Framework (`src/`, non-example)

| Site | Quote |
|---|---|
| `src/controller/controller.lua:386` | `--- Held modifiers are prepended in COMBO_MODS precedence, l/r folded to generic names.` |
| `src/controller/controller.lua:390-391` | `--- whether dispatch should match on keys_pressed directly` / `--- instead of serialising, is an open design question` |
| `src/controller/controller.lua:406-407` | `--- Is any modifier held? The cheap pre-check the triggerless` / `--- (pointer) shortcut lookup runs before building a combo` |
| `src/controller/controller.lua:420-428` | `-- Memoised read-only view over Controller.keys_pressed handed to` / `-- every chain consumer (doc/development/decisions/input.md, Decision 13):` / `-- reads pass through to the` / `-- live held set; assignment raises. Rebuilt only when the backing` / `-- identity changes (tests swap the table wholesale), so dispatch` / `-- allocates nothing per event. NOTE: under LuaJIT/Lua 5.1 \`pairs\`` / `-- ignores __pairs, so iterating this view yields nothing on this` / `-- platform; the load-bearing contract (read-through + write-raise)` / `-- holds, and __pairs is kept for 5.2+ hosts.` |
| `src/controller/consoleController.lua:515-522` | `--- Assemble the compy.input surface: reads resolve the three frozen` / `--- sub-tables (shortcuts / hooks / callbacks), the combinator` / `--- table, the live held-key view, or a callable method; every` / `--- write to the container itself is refused loudly (Decision 7` / `--- revised — frozen container, writable leaves).` / `--- \`get_keys\` is resolved on every read, never captured: the` / `--- view is rebuilt when its backing table identity changes` / `--- (Decision 13), so a reference taken at build time goes stale.` |
| `src/controller/consoleController.lua:825-828` | `-- doc/development/decisions/input.md, Decision 20: the` / `-- held-key view a project can read OUTSIDE an event. The same` / `-- read-only proxy the chain hands participants (Decision 13)` / `-- — a project cannot build one, its \`love\` being a clone.` |
| `src/controller/userInputController.lua:489-490` | `-- Its editing logic reads modifiers via Key.* (love.keyboard);` / `-- the held set is compy.input.keys_pressed.` |
| `src/controller/projectInputController.lua:490` | *(see decisions doc cross-reference note below — no additional site; the "held-modifier test comes first" comment at `projectInputController.lua:96` was evaluated and excluded, see Ambiguous)* |

### Examples (`src/examples/keyboard/`)

| Site | Quote |
|---|---|
| `src/examples/keyboard/input.lua:39-40` | `-- key from the held set at the gateway, before dispatch).` (part of a longer sentence starting `:38`) |
| `src/examples/keyboard/input.lua:42-48` | `-- Held modifier state is read live from` / `-- compy.input.keys_pressed through the INPUT proxy below. It` / `-- used to be a mirror this file maintained on every press and` / `-- release; the API exposes the set outside an event now` / `-- (Decision 20), which is what the key-cap renderer needs --` / `-- it reads INPUT.shift from draw, where there is no event` / `-- argument to consult.` |
| `src/examples/keyboard/input.lua:51-53` | `-- Reads pass through to the framework's held set. \`held\` is` / `-- that set; \`shift\`/\`ctrl\`/\`alt\` fold the l/r pair, which the` / `-- raw set deliberately does not. Only \`upRecent\` is ours.` |
| `src/examples/keyboard/input.lua:133-141` | `-- One glyph per key press reaches a scene. textinput carries no` / `-- isrepeat flag of its own, so a repeat has to be recognised` / `-- some other way, and the held set cannot do it: whether` / `-- keypressed or textinput arrives first is not fixed` / `-- (doc/development/internals/user_input.md, "Data flow" -- no` / `-- ordering guarantee between the two channels), so at a FRESH` / `-- glyph the producing key is already held on one build and not` / `-- yet held on another. Asking "is it held" therefore answers` / `-- the environment, not the question.` |
| `src/examples/keyboard/input.lua:162-165` | `-- isr is the API's isrepeat (third hook argument): a held key` / `-- is filtered at the source instead of inferred from the held` / `-- set. capslock is exempt (its release may not arrive, leaving` / `-- the set stale and freezing Caps). Scene input is also` |

Method: grep only for every prose row above (comments carry no AST edge the
LSP indexes).

---

## 6. TEST — everything under `tests/`

Sub-tagged in parentheses by what the line would be under §1-4 if it weren't
in a test file, since that shape is what determines fallout when the set is
removed.

### `tests/input/keys_pressed_spec.lua`

The file's own banner (line 2) calls this "the held-key set and combo
normalisation" — it is written entirely to characterize the set the platform
step removes.

| Site | Quote | Shape |
|---|---|---|
| `:55` | `Controller.keys_pressed = { }` (`before_each`) | WRITE |
| `:58-60` | `kp_handler('s')` / `assert.truthy(Controller.keys_pressed['s'])` | READ |
| `:63-66` | `Controller.keys_pressed['s'] = true` / `kr_handler('s')` / `assert.is_nil(Controller.keys_pressed['s'])` | WRITE+READ |
| `:69-77` | `assert.truthy(Controller.keys_pressed['lctrl'])` etc. (4 assertions) | READ |
| `:79-81` | `-- The table keeps RAW l/r names distinct; folding to a generic "ctrl" happens only in` / `-- combo_string, never in keys_pressed itself. ...` | PROSE |
| `:82-89` | `assert.truthy(Controller.keys_pressed['lctrl'])` / `assert.truthy(Controller.keys_pressed['rctrl'])` / `assert.equal('ctrl+x', Controller.combo_string('x', Controller.keys_pressed))` | READ |
| `:100-128` | `local cs = Controller.combo_string` + 6 `it(...)` rows building synthetic `held = {...}` tables and calling `cs(trigger, held)` | **Not a literal `Controller.keys_pressed` reference** — these pass ad-hoc local tables into `combo_string`, exercising its parameter contract, not the live global. Included because that parameter shape (`fun(k, keys_pressed): string`) is exactly what Change A's "the builder now asks the device directly" note (`user_input.md`, "PENDING" markers) says goes away. See Ambiguous. |
| `:130-137` | `it('all modifiers: ctrl alt shift gui', ...)` — `held = { lgui = true, lshift = true, lalt = true, lctrl = true }` / `local expected = 'ctrl+alt+shift+gui+s'` | **GUI** — see §7 |

### `tests/input/input_nfr_mechanism_spec.lua`

| Site | Quote | Shape |
|---|---|---|
| `:19` | `-- allocation, and the held-key table's own shape. Nothing here` | PROSE |
| `:48` | `-- intentionally poke internals (identity, allocation, the held-key` | PROSE |
| `:55-58` | `-- Held-key set lifecycle (mechanism). The set is dissolved by` / `-- doc/development/decisions/input.md, Decision 30, and the` / `-- internals guide no longer documents it — these guards go with` / `-- the set. Until then:` | PROSE (this comment already narrates the pending removal) |
| `:67-77` | `it('the pressed key is in the held set', ...)` — `seen = Controller.keys_pressed['x']` | READ |
| `:79-91` | `it('the released key is gone before dispatch', ...)` — `Controller.keys_pressed['x'] = true` (WRITE) then `seen = Controller.keys_pressed['x']` (READ) | WRITE+READ |
| `:93-96` | `it('reuses the held-key view for one backing table', ...)` — `local first = Controller.held_keys()` / `assert.equal(first, Controller.held_keys())` | PLUMBING (tests the memoisation mechanism directly) |
| `:98-101` | `-- Folding lctrl/rctrl to 'ctrl' is combo_string's` / `-- job (doc/development/decisions/input.md, Decision 8, covered in` / `-- keys_pressed_spec),` / `-- not the held set's.` | PROSE |
| `:106-113` | `it('left/right names stay raw in the held set', ...)` — `Controller.keys_pressed['lctrl']` / `['rctrl']` / `['ctrl']` (3 assertions) | READ |

### `tests/input/input_events_spec.lua`

| Site | Quote | Shape |
|---|---|---|
| `:557` | `seen = { k, isr, input.keys_pressed['lalt'] }` | READ (via `compy.input` surface) |
| `:616` | `seen = { k, isr, input.keys_pressed['lalt'] }` | READ |
| `:710-722` | `-- ---- signatures + read-only proxy of pressed-keys table` … `-- compy.input.keys_pressed, which is available everywhere,` | PROSE |
| `:734` | `seen[who] = { k, sc, isr, input.keys_pressed['a'] }` | READ |
| `:776-781` | `-- The held-key table as a participant sees it. It is no longer` / `-- handed over as an argument — a participant reads it from` / `-- compy.input.keys_pressed, the same table the project reads` / `-- outside an event ...` / `describe('the pressed-keys table', function()` | PROSE (comment) + TEST group label |
| `:787` | `proxy = input.keys_pressed; return true` | PLUMBING (captures reference) |
| `:788-791` | `assert.is_table(proxy)` / `assert.is_true(proxy['a'])` | READ |
| `:800` | `present = input.keys_pressed[k]; return true` | READ |
| `:811` | `proxy = input.keys_pressed; return true` | PLUMBING |
| `:812` | `assert.has_error(function() proxy['x'] = true end)` | READ (write-raise proof — exercises the proxy's `__newindex` guard) |
| `:818-825` | `-- The same held set, readable OUTSIDE an event` … `describe('compy.input.keys_pressed', function()` | PROSE + TEST group label |
| `:831` | `assert.is_true(input.keys_pressed['a'])` | READ |
| `:838` | `assert.is_nil(input.keys_pressed['a'])` | READ |
| `:842` | `-- the project observes the held set, it does not own it.` | PROSE |
| `:846` | `input.keys_pressed['x'] = true` (inside `assert.has_error`) | WRITE-attempt (proves read-only) |
| `:857` | `from_handler = input.keys_pressed['a']; return true` | READ |
| `:860-861` | `assert.equal(from_handler, input.keys_pressed['a']); assert.is_true(input.keys_pressed['a'])` | READ |

### `tests/input/input_widget_callbacks_spec.lua`

| Site | Quote | Shape |
|---|---|---|
| `:538` | `-- F.session.press keeps Controller.keys_pressed (combo_` | PROSE |

### `tests/helpers/input_session.lua`

| Site | Quote | Shape |
|---|---|---|
| `:6` | `-- Built on the keys_pressed_spec raw-handler pattern; NOT an` | PROSE (names the spec file, not the set directly — borderline, see Ambiguous) |

### `tests/helpers/input_fixture.lua`

| Site | Quote | Shape |
|---|---|---|
| `:272` | `Controller.keys_pressed       = { }` (inside `F.reset()`, runs before every test) | WRITE |

---

## 7. GUI — everything belonging to Change B (gui withdrawn as a modifier), in any shape

### `src/util/key.lua` — the modifier set's single source of truth

| Site | Quote | Shape |
|---|---|---|
| `:8-9` | `-- gui = super/cmd/win. Kept in the modifier set for parity with ctrl/alt/shift so` / `-- combo_string can serialise gui-combos; no shortcut registers one yet.` | PROSE |
| `:10` | `local gui_k   = { "lgui", "rgui" }` | DECLARATION |
| `:12-15` | `-- Single source of truth for left/right modifier folding. Each row is` / `-- { left-key, right-key, generic-name }; combo_string folds e.g. lctrl\|rctrl -> "ctrl"` / `-- (precedence order: ctrl, alt, shift, gui). This is the single` / `-- source shared by combo registration and dispatch.` | PROSE |
| `:16-21` | `local mod_triples = { { ctrl_k[1], ctrl_k[2], "ctrl" }, { alt_k[1], alt_k[2], "alt" }, { shift_k[1], shift_k[2], "shift" }, { gui_k[1], gui_k[2], "gui" }, }` — row 20 (`{ gui_k[1], gui_k[2], "gui" },`) is the one row that goes | DECLARATION (row 20 is *the* central write site for Change B) |
| `:24-26` | `-- Generic modifier names in combo-string precedence order` / `-- (doc/development/decisions/input.md, Decision 8: ctrl < alt < shift <` / `-- gui), and the l/r fold that maps held key-names onto` / `-- them ('lctrl' -> 'ctrl').` | PROSE |
| `:28` | `ctrl = 1, alt = 2, shift = 3, gui = 4,` (inside `mod_rank`) | DECLARATION |
| `:30` | `local mod_order = { 'ctrl', 'alt', 'shift', 'gui' }` | DECLARATION |
| `:31-35` | `local fold_mod = { }` / `for _, row in ipairs(mod_triples) do` / `  fold_mod[row[1]] = row[3]` / `  fold_mod[row[2]] = row[3]` / `end` | PLUMBING (derived table — iterates `mod_triples`, so it inherits the `gui` row structurally without naming it) |

No `Key.gui()` accessor exists anywhere — `Key` exports `shift`/`is_shift`,
`ctrl`/`is_ctrl`, `alt`/`is_alt` but nothing for `gui` (confirmed by
`Key = { ... }` at `key.lua:166-178`, and by grep for `Key.gui\b` returning
nothing in `src/` or `tests/`). See "Surprises".

### Tests

| Site | Quote | Shape |
|---|---|---|
| `tests/input/keys_pressed_spec.lua:130-137` | `it('all modifiers: ctrl alt shift gui', function()` … `local held = { lgui = true, lshift = true, lalt = true, lctrl = true, }` … `local expected = 'ctrl+alt+shift+gui+s'` … `assert.equal(expected, cs('s', held))` | TEST — this assertion fails (not crashes) once `gui` leaves `mod_triples`: `cs('s', held)` would return `'ctrl+alt+shift+s'` |

`tests/mock.lua:13-14` (`lgui = false, rgui = false,` in the `love.keyboard.isDown`
device mock) was checked and **excluded** — reasoning under "Surprises".

---

## Would break

If `Controller.keys_pressed` (the table, its writers, its accessors, and the
memoised view) were deleted and **nothing else** changed:

1. **`src/controller/controller.lua:788`** — `Controller.keys_pressed[k] = true`
   indexes a **nil** field (`Controller.keys_pressed` no longer exists) on
   **every keypress in the whole application**, not only during a project run
   — this is the raw `love.handlers.keypressed` gateway entry, installed
   unconditionally at `setup_callback_handlers` time. Crash:
   `attempt to index a nil value (field 'keys_pressed')`. The app would be
   unusable from the very first keystroke.
2. **`src/controller/controller.lua:906`** — same failure on
   `Controller.keys_pressed[k] = nil`, on every keyrelease.
3. **`src/controller/projectInputController.lua:103-110`** (`find_shortcut`)
   — `local keys = Controller.keys_pressed` becomes `keys = nil`. Every call
   into `find_shortcut` (i.e. **every** project-route dispatch: keypressed,
   keyreleased, textinput, mousepressed/released/moved, wheelmoved, touch*,
   singleclick/doubleclick — `dispatch()` calls it unconditionally as its
   first step) then either:
   - hits `Controller.any_mod(keys)` → `any_mod(nil)` → `keys_pressed[m[1]]`
     with `keys_pressed = nil` → `attempt to index a nil value (local
     'keys_pressed')`, for every **triggerless** event (mousemoved with no
     button, wheelmoved, touch, derived clicks), or
   - hits `Controller.combo_string(trigger, keys)` → `combo_string(k, nil)` →
     same nil-index crash, for every **triggered** event (every keypress,
     mouse button, etc.).
   Net effect: the entire project input route crashes on its first event
   once a project is running, independent of whether Change A's `keys_pressed`
   deletion also updates `combo_string`'s signature (this "would break"
   analysis assumes nothing else changes, per the prompt).
4. **`src/controller/controller.lua:429-442`** (`held_keys()`) — if only the
   `Controller.keys_pressed = { }` field (line 498) is deleted but
   `held_keys` itself survives unedited: `backing = Controller.keys_pressed`
   becomes `nil`; `setmetatable({ }, { __index = nil, ... })` does **not**
   error (Lua permits a nil `__index`) — instead `held_proxy` silently
   behaves as a permanently empty table. Every read through it (`compy.input.keys_pressed['x']`)
   returns `nil` forever, with **no crash and no signal** — the single
   clearest "silently reads nil" case in this inventory.
5. **`src/controller/consoleController.lua:540`** combined with a full
   deletion of `held_keys`/`Controller.held_keys` — `local held =
   Controller.held_keys` (line 829) becomes `nil`, passed as `get_keys` into
   `build_input_surface`. The first time any project code reads
   `compy.input.keys_pressed`, `get_keys()` is invoked on a nil upvalue:
   `attempt to call a nil value (upvalue 'get_keys')`. Concretely, this fires
   the moment `src/examples/keyboard` — a shipped example — is run and any
   scene calls `helpHeld()` (`INPUT.held.h`, `help.lua:11`) or anything
   touches `INPUT.shift`/`ctrl`/`alt` (`modHeld`, `input.lua:110`, reached
   from `appTextinput` on **every** textinput event and from
   `keyboard_view.lua`/`alt.lua` on every draw of the Alt scene): the whole
   example crashes on its first keystroke or first Alt-scene frame.
6. **Tests** — `tests/input/keys_pressed_spec.lua` and
   `tests/input/input_nfr_mechanism_spec.lua` assign/read
   `Controller.keys_pressed` and call `Controller.held_keys()` directly
   (§6 above); every such line raises "attempt to index/call a nil value"
   the moment the spec runs, not merely a failed assertion.
   `tests/helpers/input_fixture.lua:272`'s `F.reset()` — used in
   `before_each`/`teardown` across the input suite — assigns
   `Controller.keys_pressed = { }`; deleting the field does not itself break
   this line (assignment to a nonexistent field just creates a stray one),
   but it silently stops resetting anything real once other code stops
   reading that field, which would mask failures elsewhere rather than
   surfacing them.

For Change B (withdrawing `gui` from `mod_triples`), removing just row 20 of
`mod_triples` (`key.lua:20`) and nothing else: **no crash anywhere.**
`gui_k` (line 10) becomes an unused local (a lint warning, not a runtime
fault); `fold_mod`/`mod_rank`/`mod_order` derive from `mod_triples` so they
quietly stop recognizing `lgui`/`rgui` as modifiers; `combo_string` stops
prepending `gui`; and the one test that pins the old behavior
(`keys_pressed_spec.lua:130-137`) fails its `assert.equal` (expects
`'ctrl+alt+shift+gui+s'`, gets `'ctrl+alt+shift+s'`) — a test failure, not a
crash, the qualitatively different kind of "break" from all of Change A's
sites above.

---

## Ambiguous

- **`tests/input/keys_pressed_spec.lua:100-128`** (the "combo serialisation"
  `describe` block, minus the gui row already pulled into §7) passes
  hand-built local tables into `Controller.combo_string`, never touching
  `Controller.keys_pressed` by name. Whether these rows are in scope for
  Change A depends on a design decision this inventory was told not to make:
  does `combo_string` keep taking a `keys_pressed`-shaped table argument
  after the platform step, or does it move to reading `Key.ctrl()`/`alt()`/
  `shift()` directly (as `doc/development/internals/user_input.md`'s "PENDING"
  markers on `combo_string`/`any_mod` suggest is coming)? I could not
  determine this from code alone — it is a pending design step, not yet
  landed. Listed under TEST/§6 for visibility; whether it is "touched by
  Change A" turns on that undecided signature question.
- **`src/examples/keyboard/input.lua:18-29`** (the ordering-bug narrative
  about "drop the glyph if its key is HELD") uses "held" in a way that reads
  naturally as a reference to *some* held-check, but the block never says
  which one — it could equally describe a device-level `Key.shift()` check as
  the discarded design. I did not include it as PROSE naming the held-key
  set specifically; I could not confirm it from the text alone, and did not
  want to guess.
- **`tests/helpers/input_session.lua:6`** — `-- Built on the keys_pressed_spec
  raw-handler pattern` names the *spec file*, not the `keys_pressed` table
  itself. Included in §6 for completeness since the string literally contains
  "keys_pressed", but it is a filename reference, not a description of the
  mechanism — readers should weight it accordingly.
- **`src/controller/projectInputController.lua:109`** — `if sc or
  Key.is_mod(trigger) then return sc end`. `Key.is_mod` does not name `gui`
  anywhere in its own text, but its answer for `'lgui'`/`'rgui'` changes from
  `true` to `false` once Change B lands (because `is_mod` reads `fold_mod`,
  which stops containing those keys). I did not classify this line as a GUI
  site — no token in it says "gui" — but flag it here because its *behavior*
  is a direct, silent consequence of Change B and a reviewer sweeping only by
  grep for "gui" would miss it. (Per Decision 31 in
  `doc/development/decisions/input.md`, this behavior change — `lgui` become
  an eligible ordinary trigger — is the intended effect, not a bug; still,
  it's a non-obvious site.)

---

## Surprises

- **Two unrelated "held" tables share the vocabulary and would be false
  positives for a grep-only sweep.** `src/harmony/init.lua:174-184` — a
  separate automation/scripting harness (`Harmony`, screenshot/scenario
  scripting) — keeps its **own** `held` table used to patch
  `love.keyboard.isDown` for scripted key sequences (`patch_isDown`,
  `:242-254`), entirely independent of `Controller.keys_pressed`. It even
  lists `lgui`/`rgui` (`:182-183`) and a `Super`/`Hyper` mod-name table
  (`:170-172`) that echoes `key.lua`'s `gui_k` almost exactly, by
  coincidence. `tests/mock.lua:5-15` mocks `love.keyboard.isDown` the same
  way, with its own `held` table (also carrying `lgui = false, rgui =
  false`). Neither is a Change A or Change B site — they mock/drive the
  *device*, not the framework's tracked set — but both would show up in a
  naive `grep -i held` or `grep gui` sweep and need to be recognized and
  excluded, which is exactly what happened during this enumeration (see
  §6/§7 notes). A future editor doing a mechanical "delete every `held`
  table" pass should be warned explicitly.
- **`gui` has no `Key.gui()` accessor even though it is a full modifier row
  today.** `ctrl`/`alt`/`shift` each get a `Key.is_X`/`Key.X()` pair
  (`key.lua:136-164`); `gui` gets neither, despite occupying a row in
  `mod_triples`/`mod_rank`/`mod_order`/`fold_mod`. So even before Change B,
  no project or framework code could ask "is gui held" through the sanctioned
  API — the modifier existed structurally (it could be serialised into a
  combo string and folded/recognized as a modifier token) but had no query
  surface of its own. Decision 31 in the decisions doc calls this out
  explicitly as symmetry-without-use, which matches what the code shows.
- **`src/model/input/selection.lua:9,16,21-22`** (`--- @field held boolean`,
  `held = false`, `InputSelection:is_held()`) is a third, wholly unrelated
  "held" — text-selection held/drag state, nothing to do with keyboard input
  at all. Excluded from every section above; flagged only because "held" as
  a bare grep term is a noisy word in this codebase (at least three
  independent meanings: the framework's tracked key set, Harmony's
  device-mock table, and selection drag state).
- **The `Controller` LuaCATS class annotation never declared the fields
  being removed.** `@class Controller` (`controller.lua:445-455`) lists
  `_defaults`, `_userhandler`, and five method fields, but never `@field
  keys_pressed table`, `combo_string function`, `any_mod function`, or
  `held_keys function` — all four are real, load-bearing fields assigned a
  few lines later (`:498-501`). This means Change A's "every type
  declaration ... that names it" instruction has less to remove on the
  `Controller` class itself than the `CompyInput` class (`types.lua:251`,
  which *does* declare `@field keys_pressed table`) — the two type surfaces
  for the same concept are inconsistently documented today.
- **The dispatch-order comment at `projectInputController.lua:96`**
  ("the held-modifier test comes first, so an unmodified mousemoved never
  allocates a combo string") describes `any_mod`'s role but never says
  "keys_pressed" or "held set" by name — it was evaluated and left out of
  §5 for that reason, but it is worth a human's second look since it sits two
  lines above the literal `Controller.keys_pressed` plumbing at line 103.
- **`doc/development/decisions/input.md` and `doc/development/internals/user_input.md`
  already narrate both changes as decided** (Decision 30 for the held set,
  Decision 31, dated 2026-08-10 — today — for `gui`), including exact
  "PENDING" markers pointing at the surviving code (`user_input.md` around
  the "Key state" section and the "Key Files" table). Those docs are outside
  this inventory's requested scope (`src/`/`tests/`/`src/examples/`) but are
  worth the implementer's read before touching `combo_string`'s signature —
  they already settle the ambiguous `combo_string(k, keys_pressed)` question
  raised above ("the builder now asks the device through a named accessor
  per modifier").

---

## Totals (self-verified, not copied from any prior count)

| Class | Framework (`src/`, non-example) | Examples | Tests |
|---|---:|---:|---:|
| WRITE | 2 | 0 | 3 (incl. 1 write-attempt-that-raises, 1 fixture reset) |
| READ | 2 | 11 | ~19 |
| PLUMBING | 22 | 8 | 2 |
| DECLARATION | 5 | 0 | 0 |
| PROSE | 7 blocks | 5 blocks | 9 blocks |
| GUI | 7 rows (key.lua) | 0 | 1 test block |

Counts are rows/blocks as tabulated above, not raw line numbers — a
multi-line contiguous comment is one row; a multi-assertion test `it(...)`
is one row. Every row is individually citable to an exact `path:line` in the
tables above.
