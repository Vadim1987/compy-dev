# S32 — Decision 30 evidence bundle (cold check 1, mechanical)

Read-only fact verification of the load-bearing claims behind Decision 30
(`doc/development/decisions/input.md`). Base commit for all "pre-existing"
checks: `3256aac` (verified as an ancestor of HEAD via
`git merge-base 3256aac HEAD` → `3256aac4d6d...`, equal to `3256aac`
itself). `busted tests` baseline observed: **955 successes / 0 failures /
0 errors / 3 pending** — matches the expected baseline exactly, no
deviation.

No file was edited, created or deleted other than this one. All `git`
commands used were read-only (`show`, `log`, `diff`, `grep`, `ls-tree`,
`merge-base`).

---

## Task 1 — `tests/mock.lua` single-argument `isDown`, and its blast radius

**Verdict: the claim is TRUE, symmetric across all three accessors, and its
practical consequence is narrower than the framing implies — right-hand
modifiers are structurally unreachable through the mock, so making
`isDown` variadic would change the result of zero currently-passing test
cases.**

### 1.1 — exact definitions

- `tests/mock.lua:30` — `isDown = function(k) return held[k] end`.
  Single-argument: only the first positional arg is read; anything passed
  after it is silently discarded by Lua's normal call semantics (it isn't
  even a `...`-based function, so extra args are dropped, not ignored via
  varargs).
- `src/util/key.lua:141-144` —
  ```lua
  local function shift()
    return love.keyboard.isDown(unpack(shift_k))
  end
  ```
  where `shift_k = { "lshift", "rshift" }` (`key.lua:5`).
- `src/util/key.lua:151-154` — `ctrl()`, calling
  `love.keyboard.isDown(unpack(ctrl_k))`, `ctrl_k = { "lctrl", "rctrl" }`
  (`key.lua:6`).
- `src/util/key.lua:161-164` — `alt()`, calling
  `love.keyboard.isDown(unpack(alt_k))`, `alt_k = { "lalt", "ralt" }`
  (`key.lua:7`).

### 1.2 — true for all three, symmetrically

Yes. All three triples (`shift_k`, `ctrl_k`, `alt_k`) put the **left**
variant first, and `unpack(t)` expands to `(t[1], t[2])`. Since
`mock.lua:30`'s `isDown(k)` reads only its first parameter, every one of
`Key.shift()` / `Key.ctrl()` / `Key.alt()` under test resolves to
`held[<left-variant>]`, unconditionally ignoring the right-hand key. No
accessor is spared; the bug is uniform.

### 1.3 — blast radius, enumerated

**The mock exposes exactly one way to set a modifier that `Key.*` will
see: `keystroke()`'s `mods` table (`mock.lua:17-21`)**:
```lua
local mods = { C = 'lctrl', S = 'lshift', M = 'lalt' }
```
This table maps **only to the left variant** — there is no `R = 'rctrl'`
et al. `held` (`mock.lua:5-15`) is a `local`, never exported from the
module (`mock.lua:92-97` returns only `mock_love`, `keystroke`,
`textinput`, `release_keys`), so "direct `held` manipulation" from a test
file is **not possible** — the task prompt's phrasing of this as one of
two poll-shaped sub-paths does not correspond to anything reachable in
practice; the only poll-shaped path is `keystroke`/`release_keys`.

Two cleanly separated populations were found (confirmed by grep across
all of `tests/` for `Key\.\(ctrl\|shift\|alt\)\(`, `keys_pressed`, and
`lctrl|rctrl|lshift|rshift|lalt|ralt`, cross-checked file by file):

**Population A — poll-shaped path, reaches a `Key.*` accessor while
holding a modifier via `mock.keystroke`'s `C-`/`S-`/`M-` tokens (27 test
cases, 4 files):**

| File | Line(s) | Test case |
|---|---|---|
| `tests/util/mock_spec.lua` | 17-22 | `'Ctrl-S'` |
| `tests/util/mock_spec.lua` | 23-28 | `'Alt-up'` |
| `tests/util/mock_spec.lua` | 29-34 | `'Shift-esc'` |
| `tests/util/mock_spec.lua` | 35-41 | `'Ctrl-Shift-Q'` |
| `tests/editor/editor_spec.lua` | 375-381 | `'to top'` (`C-pageup`, :376) |
| `tests/editor/editor_spec.lua` | 394-401 | `'to bottom'` (`C-end`, :395) |
| `tests/editor/editor_spec.lua` | 402-407 | `'to top'` (`C-home`, :403) |
| `tests/editor/editor_spec.lua` | 417-421 | `"doesn't clear on move"` (`C-end`, :418) |
| `tests/editor/editor_spec.lua` | 423-431 | `'inserts'` (`S-escape`, :428) |
| `tests/editor/editor_spec.lua` | 500-513 | `'types a query and Enter jumps to its definition'` (`C-f`, :505) |
| `tests/editor/editor_spec.lua` | 514-529 | `'Escape leaves search without moving the selection'` (`C-f`, :520) |
| `tests/editor/editor_spec.lua` | 761-779 | insertion, `session:submit(new_func, true)` → `C-return` (:763, via `editor_session.lua:132-133`) |
| `tests/editor/editor_spec.lua` | 780-810 | insertion, `submit(new_code, true)` (:784) |
| `tests/editor/editor_spec.lua` | 811-828 | insertion, `submit(f_oversized, true)` (:813) |
| `tests/editor/editor_spec.lua` | 829-846 | insertion, `submit(mixed_content, true)` (:844) |
| `tests/input/input_widget_callbacks_spec.lua` | 543-559 | `'Shift+Return unconditionally adds a line without submitting'` (`S-return`, :548) |
| `tests/input/input_widget_callbacks_spec.lua` | 560-574 | `'a shortcut on shift+return intercepts the newline'` (`S-return`, :569) |
| `tests/input/input_widget_callbacks_spec.lua` | 865-889 | `'Ctrl+Enter applies the edit, no on_text_entered'` (`C-return`, :874) |
| `tests/input/input_widget_callbacks_spec.lua` | 892-911 | `'submits to nobody and leaves the text alone'` (`M-return`, :899) |
| `tests/input/input_widget_callbacks_spec.lua` | 913-933 | `'inserts a line-feed instead of submitting'` (`S-return`, :918) |
| `tests/input/input_widget_callbacks_spec.lua` | 989-999 | `'with the flag: Ctrl+D duplicates the line'` (`C-d`, :995) |
| `tests/input/input_widget_callbacks_spec.lua` | 1000-1021 | `'without it: Ctrl+D does nothing'` (`C-d`, :1006) |
| `tests/input/input_widget_callbacks_spec.lua` | 1023-1033 | `'overlay: Ctrl+Enter submits'` (`C-return`, :1030) |
| `tests/input/input_widget_callbacks_spec.lua` | 1034-1044 | `'overlay: Alt+Enter submits'` (`M-return`, :1041) |
| `tests/input/input_widget_callbacks_spec.lua` | 1045-1056 | `'console: Ctrl+Enter evaluates'` (`C-return`, :1054) |
| `tests/input/input_shortcuts_click_spec.lua` | 42-51 | `'a shortcut fires but does not consume'` (`C-pause`, :47) |
| `tests/input/input_shortcuts_click_spec.lua` | 64-84 | `'#play mode narrows the active shortcut set'` (`C-M-r` :79, `C-q` :80) |

Reach was confirmed by reading the production code, not assumed:
`src/controller/editorController.lua:817` (`EditorController:keypressed`)
calls `Key.ctrl()` **unconditionally on every keystroke** — so every
`editor_spec.lua` case above provably reaches a `Key.*` accessor at
minimum once, regardless of which specific branch the key itself hits.
Same pattern for `searchController.lua:99` (`Key.shift()` evaluated
before the `k == "pageup"` check — `and`'s left operand always runs) and
`controller.lua:791/813` (the gate, see Task 2) for the
`input_shortcuts_click_spec.lua` cases. One case, `editor_spec.lua:382`
(`'to bottom'`), has its `mock.keystroke('C-pagedown', press)` **commented
out** (`:383`) — it does not actually drive a modifier and is excluded
from the count above.

**Population B — `keys_pressed`-direct (event-tracked set), never
touches `mock.lua`'s `held` table at all:**

- `tests/input/keys_pressed_spec.lua` — 11 `it` blocks: 4 driving the raw
  `kp_handler`/`kr_handler` (`Controller.keys_pressed` writes, :58-89) and
  7 calling `Controller.combo_string` directly against a **synthetic,
  locally-constructed `held` table** (:100-138) — this bypasses
  `love.keyboard.isDown` and `Key.*` entirely; `combo_string` reads a
  plain table argument, not the device.
- `tests/input/input_nfr_mechanism_spec.lua` — 4 `it` blocks (:66-112)
  drive `F.session.press('x'|'lctrl'|'rctrl')`, which fires the **real**
  `love.handlers.keypressed` and asserts on `Controller.keys_pressed`.
- `tests/input/input_events_spec.lua` — the entire
  `compy.input.keys_pressed` and related describe blocks (~15 references,
  :551-861) drive `F.session.press(...)` with plain or modifier-named keys
  and assert on `input.keys_pressed[...]`, never on `Key.*`.
- `tests/helpers/input_fixture.lua:272` — `F.reset()` zeroes
  `Controller.keys_pressed` as teardown hygiene, not a test assertion.

`F.session.press` (`tests/helpers/input_session.lua:19`) calls
`h.keypressed(k, '', false)` directly against the real
`love.handlers.keypressed` — i.e. it drives **`controller.lua`'s own
gate** (Task 2), so `Key.ctrl()` etc. *are* incidentally invoked inside
these Population-B tests too (e.g. `controller.lua:791`/`813` runs on
every keystroke). But because `F.session.press` never goes through
`mock.lua`'s `keystroke()`, it never touches `held` — so those incidental
`Key.*` calls always read `false`, and the tests' assertions never depend
on the outcome. This is a real but **inert** overlap, not a case of a
test exercising both populations meaningfully.

**No file mixes the two populations in a load-bearing way.** One file,
`input_widget_callbacks_spec.lua`, explicitly documents driving *both*
tracks deliberately for the same behaviour, in its own comment
(`:537-542`):
> "Drives BOTH modifier tracks the production code reads: F.session.press
> keeps Controller.keys_pressed (combo_string) correct, mock.keystroke's
> 'S' token flips the separate love.keyboard.isDown mock the widget's own
> Key.shift() reads (tests/mock.lua — two distinct tables)."

This in-repo comment independently corroborates the two-track model
established here from first principles.

### 1.4 — the consequential question

**Determined, not undetermined: making `isDown` variadic
(`held[k1] or held[k2]`) would change the result of ZERO currently-passing
test cases.**

Reasoning, static and exhaustive: the *only* way any test can set
`held[<right-variant>] = true` is through `mock.lua`'s public API, and
that API (`mods` table, `mock.lua:17-21`) maps only `C`/`S`/`M` to
`lctrl`/`lshift`/`lalt`. There is no entry point that ever sets
`held.rctrl`, `held.rshift`, or `held.ralt` to `true` in the whole suite
(confirmed: `held` itself is a non-exported local, `release_keys` only
sets keys to `false`, and no test file installs a custom
`love.keyboard.isDown` — see 1.5). Therefore, in every state any test can
put `held` into, `held[<right-variant>]` is `false`, so
`held[k1] or held[k2]` reduces to `held[k1] or false`, which equals
`held[k1]` — identical to what single-argument `isDown` returns today.
The variadic and single-argument definitions are **extensionally equal
over every state the test suite can ever reach.**

This is a stronger, cleaner result than "undetermined": it isn't that the
consequence is hard to trace per-test, it's that the mock's own API makes
the distinguishing input class unreachable, so no individual test needs
tracing at all.

(Note this says nothing about production correctness — Decision 30's
underlying point about `error_explorer.lua:418`, task 2.6, and the
general risk of a device holding a right-hand modifier are real; this
finding is scoped strictly to "would the test suite's *pass/fail* results
change," which is what the task asks.)

### 1.5 — right-hand modifier assertions

**No test asserts a right-hand modifier through the `Key.*`/mock-poll
path** — this is structurally impossible (1.4). **Three test cases do
assert on right-hand modifiers, but exclusively through Population B**
(`Controller.keys_pressed` / a synthetic `combo_string` argument, never
`Key.*` or `love.keyboard.isDown`):
- `tests/input/keys_pressed_spec.lua:115-118` — `'ctrl+s from rctrl held'`
  (a fabricated `{ rctrl = true }` table passed straight to
  `Controller.combo_string`).
- `tests/input/input_nfr_mechanism_spec.lua:75` and `:109-111` — asserts
  `Controller.keys_pressed['rctrl']` is `nil`/`true` via the real
  keypressed handler with raw key name `'rctrl'`.

These bound the blast radius further: not only is the right-hand branch
of the bug never exercised through `Key.*`, the suite's only awareness of
"right-hand modifier" as a concept lives entirely in the unaffected,
already-correct-by-construction event-tracked population.

---

## Task 2 — the gate layer in `controller.lua`

**Verdict: the gate exists exactly as characterised — a block inside
`love.handlers.keypressed`/`keyreleased` (installed once, at
`main.lua:385`, via `Controller.setup_callback_handlers`) that runs before
`love.keypressed(...)` is invoked (the actual dispatch point). It reads
modifiers by raw `Key.*` polling. It has no shortcuts table. The mechanism
claim is confirmed.**

### 2.1 — where the gate is

`src/controller/controller.lua:780-923`, function
`setup_callback_handlers(CC)`. Two handler installations carry gate
logic:
- `handlers.keypressed = function(k, sc, isr) ... end` — `:787-897`.
- `handlers.keyreleased = function(k, sc) ... end` — `:905-915`.

Both are assigned onto `love.handlers` — LÖVE's raw event-pump table,
**not** `love.keypressed`/`love.keyreleased`, which hold the *routed*
handler (console default or project chain). `handlers.keypressed` calls
`love.keypressed(k, sc, isr)` only at its very end (`:894-896`), after all
gate logic has run — that call is the dispatch point this gate sits
upstream of.

### 2.2 — complete enumeration of combinations

All of the following live inside four `local function`s declared in
`handlers.keypressed` (`quickswitch`, `project_state_change`, `restart`,
`profile`) plus the `handlers.keyreleased` body. Whether all four
`keypressed` functions run depends on `playback = cfg.mode == 'play'`
(`:782`): in playback mode only `restart()` and `profile()` run (`:868-875`);
otherwise all four run (`:876-883`, including `quickswitch()` and
`project_state_change()`).

| Line(s) | Combination | Action |
|---|---|---|
| 791-810 | Ctrl+T (not Alt) | `quickswitch()`: toggles editor ↔ project route |
| 814-816 | Ctrl+Pause | `CC:suspend_run(...)` |
| 817-819 | Ctrl+Q | `CC:quit_project()` |
| 820-822 | Ctrl+S (app_state `running`) | `CC:stop_project_run()` |
| 823-827 | Ctrl+S, no Shift (app_state `editor`) | `CC:close_buffer()` |
| 823-826 | Ctrl+Shift+S (app_state `editor`) | `CC:finish_edit()` |
| 831-836 | Ctrl+Shift+R | `CC:reset()` |
| 840-842 | Ctrl+Alt+R | `CC:restart()` |
| 845-847 | Ctrl+Alt+Shift+P | `Prof.stop_profiler()` |
| 844-851 | Ctrl+Alt+P (no Shift) | `Prof.start_oneshot()` |
| 853-865 | F10 (no modifier) | cycles `love.PROFILE.fpsc` through a 6-state ring |
| **907-910** | **Ctrl+Escape (keyreleased)** | `love.event.quit()` |

11 keypressed combinations + 1 keyreleased combination = 12 total.

### 2.3 — every direct modifier read in this layer

Counting `Key.ctrl()`/`Key.alt()`/`Key.shift()` call **instances** (not
`if`-lines) inside `handlers.keypressed`/`handlers.keyreleased`
(`:787-915`): `:791`(×2, ctrl+alt), `:813`(×1), `:824`(×1), `:831`(×1),
`:840`(×2, ctrl+alt), `:845`(×2, ctrl+alt), `:846`(×1), `:907`(×1) = **11
call instances**, all `Key.*`, zero raw `love.keyboard.isDown` in this
layer.

Adjacent but **not** part of the gate proper: `set_love_keypressed`'s
closure (`:508-549`) has two more `Key.*` reads — `:514`
(`Key.ctrl() and Key.shift()`, debug toggles) and `:531`
(`Key.ctrl() and Key.alt()`, termdebug) — but this closure *is* one of the
things `love.keypressed(...)` dispatches **to** (the console's own route
handler) when the console owns the route, not upstream of dispatch. It
sits downstream, inside the console's own chain, and is included for
completeness because Decision 30 rule 3's phrasing ("upstream of route
dispatch") could otherwise be read to include it.

### 2.4 — the mechanism claim: no shortcuts table

**Confirmed.** `setup_callback_handlers` has no `shortcuts` reference of
any kind — every combination in 2.2 is a hand-written `if`/`elseif`
chain reading `k` and `Key.*` directly. What *is* there: an ad-hoc
sequence of local closures (`quickswitch`, `project_state_change`,
`restart`, `profile`), selected by the `playback` boolean.

The nearest shortcuts table is `self.compy_input.shortcuts`, read inside
`local function dispatch(shortcuts, hooks, widget, event, trigger, ...)`
at `src/controller/projectInputController.lua:132-142`, via
`find_shortcut(shortcuts[event], trigger)` (`:101-111`,`:133`). Call
chain from the gate to there (confirmed with the LSP,
`mcp__lua-lsp__references` on `occupy_input` and
`setup_callback_handlers`, cross-checked with grep):

```
love.handlers.keypressed        (controller.lua:787, the gate)
  → love.keypressed(k, sc, isr) (controller.lua:895, dispatch point)
      → [project route active] love[k] wrapper installed by
        occupy_input (controller.lua:236-250), itself called from
        set_handlers (controller.lua:301-306) → Controller.set_user_handlers
          → pic[k](pic, ...)                  (controller.lua:247)
              → ProjectInputController[event]  (metaprogrammed,
                projectInputController.lua:185-193, "channel(event)")
                  → self:_dispatch(event, trigger, ...) (:149-153)
                      → dispatch(self.compy_input.shortcuts, ...) (:132-142)
                          → shortcuts[event] read here (:133)
```
`Controller.setup_callback_handlers` itself is called exactly once in
production, at `main.lua:385` (`love.load()`), confirmed via
`mcp__lua-lsp__references` on `setup_callback_handlers`.

### 2.5 — gate's position relative to dispatch

`love.handlers.keypressed` (the gate) is LÖVE's raw event-pump entry —
whatever LÖVE calls first for every physical keypress. It runs its power
combos, then at `:894-896` calls `love.keypressed(k, sc, isr)`, which is
the actual *dispatch* point: `love.keypressed` holds whichever route
currently occupies it — the console's own handler
(`set_love_keypressed`, installed by `Controller.set_default_handlers`)
or the project's chain wrapper (installed by `occupy_input`, itself
reached from `Controller.set_user_handlers`/`set_handlers` when a project
run starts). The gate interposes strictly **before** that call; nothing
in the gate's own body ever reads `compy.input.shortcuts` or a project's
hooks/widget.

### 2.6 — modifier-polling sites outside the gate and `key.lua`'s accessors

Full `src/` sweep (`grep -rn "love\.keyboard\.isDown" src/`, excluding
`src/examples/` per instruction):

- **Confirmed as claimed: `src/lib/error_explorer.lua:418`** —
  ```lua
  if key == 'c' and love.keyboard.isDown('lctrl', 'rctrl') then
  ```
  A genuine bypass: raw device poll, correctly variadic (unlike the mock),
  outside both the gate and `Key.*`.
- **`src/probe/input_probe.lua:85,105`** — `love.keyboard.isDown(m[1],
  m[2])` and `love.keyboard.isDown(k)`. This is a **deliberate, temporary
  diagnostic tool** (its own header, `:1-2`: "DIAGNOSTIC, TEMPORARY.
  Delete when the polling-vs-tracking question is ruled on."), opt-in
  from the console (`require('probe.input_probe').install()`), whose
  entire purpose is to compare the device poll against
  `Controller.keys_pressed` — polling outside the seam is the point, not
  an oversight. It postdates `3256aac` (does not exist at base; see Task
  3). Reported separately from `error_explorer.lua`'s bypass since it is
  not shipped platform code in the same sense.
- **`src/harmony/init.lua:243,253`** — `patch_isDown` **monkey-patches**
  `love.keyboard.isDown` itself (replacing it with a variadic-correct
  wrapper: `for _, key in ipairs(keys) do if held[key] then return true
  end end`), rather than reading it. This changes what the primitive
  means globally instead of reading modifier state through it, so it
  isn't a "bypass of the seam" in the same sense as the other two — it's
  a distinct mechanism, noted for completeness and because it is itself
  a correct variadic pattern already present in the codebase.
- `src/lib/metalua/spec/ast_inputs.lua:218,264,813,824,826,827,840,850,
  852,853,855,856` — all **string literals**: Lua source fixtures the
  metalua analyzer test parses, not live polling code. Excluded, matching
  how `tests/editor/buffer_spec.lua` and
  `tests/interpreter/analyzer_inputs.lua` were excluded from Task 1 for
  the identical reason.
- **Excluded, per instruction: `src/examples/`** — `turtle/main.lua:34,92`,
  `clock/main.lua:68`, `pong/main.lua:330`, `pong/strategy.lua:35,37`,
  `maze/main.lua:517,564` all poll `love.keyboard.isDown` directly; these
  are project code, exempt by the ruling. `src/examples/keyboard`,
  `maze`, `balloons` were not otherwise touched by this task — they carry
  their own git history as nested repos and were out of scope for the
  gate/bypass question specifically.

No other bypass was found in `src/` outside these four categories.

---

## Task 3 — "pre-existing" checks against `3256aac`

### 3.1 — the gate's modifier polls: pre-existing, byte-for-byte

**Verdict: pre-existing, confirmed with a real diff, not a re-derivation.**

`git show 3256aac:src/controller/controller.lua` has exactly **10**
`Key.ctrl/alt/shift()` sites, at lines **163, 180, 531, 553, 564, 571,
580, 585, 586, 643** — matching the session31 count and line numbers
exactly (verified with `grep -n "Key\.\(ctrl\|shift\|alt\)("` against the
base blob).

`diff <(base :528-631) <(today :787-897)` (the `handlers.keypressed`
body) shows the **only** differences are: the function signature gaining
`sc, isr` parameters, one added line (`Controller.keys_pressed[k] =
true`), and the final dispatch mechanism (base used
`get_user_input()`-based routing to `user_input.C:keypressed(k)`, today
forwards to `love.keypressed(k, sc, isr)` — reflecting the route-centric
refactor). **All four local functions — `quickswitch`,
`project_state_change`, `restart`, `profile` — including every
combination, every nested `if`, every `Key.*` call, are diff-identical,
character for character**, lines 2-97 of the diff (98 lines total) show
zero deltas.

Same for `handlers.keyreleased` (base `:642-654` vs today `:905-915`):
the Ctrl+Escape → `love.event.quit()` body is byte-identical; only the
signature and the forwarding tail differ.

The remaining two of the ten base sites (`:163`,`:180`) are inside
`set_love_keypressed` (today `:514`,`:531`) — also diff-confirmed
byte-identical (modulo the enclosing function signature).

**Today's gate has these same combos at new line numbers** (`:791, 813,
824, 831, 840, 845, 846, 907` in the `handlers.*` layer, plus `:514, 531`
in `set_love_keypressed`) — same count (10 sites, 8 in the gate + 2 in
the console handler, matching the base split), same code.

### 3.2 — `compy.input.keys_pressed` does not exist at `3256aac`

**Verdict: pre-existing check confirms the claim — new-in-this-feature,
whole-tree.**

`git grep -n "keys_pressed" 3256aac -- .` returns **zero hits**, anywhere
in the base tree — the string `keys_pressed` does not occur at all, let
alone as `compy.input.keys_pressed`. Further, `git grep -c
"compy.input\|compy_input" 3256aac -- .` also returns zero hits: the
entire `compy.input` namespace (shortcuts/hooks/keys_pressed) is new to
this feature, not just the one field.

### 3.3 — `tests/mock.lua`'s poll-shaped fake predates the feature

**Verdict: pre-existing, and — this is the load-bearing part — the
single-argument `isDown` line is untouched by this branch.**

`git diff 3256aac -- tests/mock.lua` shows the entire diff is: `keystroke`
gaining an `opts` parameter (for `isrepeat`/`scancode` forwarding, unused
by the modifier-fold logic), a new `textinput()` function, and cosmetic
alignment of the returned table. **`held`, `mods`, `release_keys`, and
`isDown = function(k) return held[k] end` do not appear in the diff at
all** — confirmed with `git show 3256aac:tests/mock.lua`, which is
character-identical to today's file for every line the diff doesn't
touch. The single-argument `isDown` was never edited on this branch; it
predates the feature verbatim.

### 3.4 — `src/util/key.lua`'s three accessors predate the feature

**Verdict: pre-existing, confirmed.**

`git show 3256aac:src/util/key.lua` contains `shift()`, `ctrl()`, `alt()`
with bodies identical to today's (`return
love.keyboard.isDown(unpack(<pair>))`), plus `is_enter`, `is_shift`,
`is_ctrl`, `is_alt`. `git diff 3256aac -- src/util/key.lua` is
**additive only** — the whole diff is new code (`gui_k`, `mod_triples`,
`mod_rank`/`mod_order`/`fold_mod`, `split_combo`, `normalize_combo`,
`check_combo`, `new_handler_table`, `is_mod`) inserted around the
untouched originals; grepping the diff for removed/changed lines touching
`function shift`/`ctrl`/`alt` returns nothing.

Platform call-site check at base (`git show 3256aac:<file> | grep -n
"Key\.\|love\.keyboard"`) for `controller.lua`, `consoleController.lua`,
`editorController.lua`, `userInputController.lua`: **every** modifier
check in all four already went through `Key.*` at base — no raw
`love.keyboard.isDown` in any of them. The one platform-level exception,
`src/lib/error_explorer.lua:418`, **already existed at base**
(`git grep` at `3256aac` finds it verbatim) — so this bypass is itself
pre-existing, not a defect introduced by the feature. `searchController.lua`
and `userInputController.lua` both exist at base as complete files (not
newly added).

---

## Task 4 — sizing counts for the dissolution

Counts below are `grep -c` (lines containing the string; multiple
matches on one line still count as one line, noted separately where it
matters) for the literal string `keys_pressed`, current tree state.

**Verdict: `src/` (22, 7 files) and `tests/` (38, 6 files) match the
quoted counts exactly. `technical_debt/` (15) and `doc/input_api.md` (8)
match exactly. `doc/development/decisions/input.md` and
`doc/development/internals/user_input.md` do NOT match the quoted counts
— one is explained by a dated snapshot, the other is simply wrong.**

### `src/` — 22 total, 7 files (matches claim exactly)

| File | Count | Kind |
|---|---|---|
| `src/controller/controller.lua` | 13 | mixed: live reads/writes (`:395,398(×2),411,413,431,437,498,788,906`), doc comments (`:388,393,409,420`) |
| `src/examples/keyboard/input.lua` | 3 | 1 comment (`:43`), 2 live reads (`:57,109`) |
| `src/probe/input_probe.lua` | 2 | 1 live read (`:81`), 1 comment (`:124`) |
| `src/types.lua` | 1 | type annotation (`:251`, `--- @field keys_pressed table`) |
| `src/controller/consoleController.lua` | 1 | live code (`:540`, `if k == 'keys_pressed' then return get_keys() end` — proxy field dispatch, not prose) |
| `src/controller/projectInputController.lua` | 1 | live read (`:103`) |
| `src/controller/userInputController.lua` | 1 | comment (`:490`) |

1+2+13+3+1+1+1 = 22, 7 files — exact match to the quoted "22× src/ (7
files, incl. examples/keyboard/input.lua)".

### `tests/` — 38 total, 6 files (matches claim exactly)

| File | Count |
|---|---|
| `tests/input/input_events_spec.lua` | 15 |
| `tests/input/keys_pressed_spec.lua` | 12 |
| `tests/input/input_nfr_mechanism_spec.lua` | 8 |
| `tests/helpers/input_session.lua` | 1 (comment only, `:6`) |
| `tests/helpers/input_fixture.lua` | 1 (live write, `:272`, teardown) |
| `tests/input/input_widget_callbacks_spec.lua` | 1 (comment only, `:538`) |

15+12+8+1+1+1 = 38 — exact match. Line-level detail for the two largest
files is in Task 1.3 above (Population B enumeration).

### `doc/development/technical_debt/` — 15 (matches exactly)

All 15 in `doc/development/technical_debt/input.md`; `general.md` and
`README.md` have zero.

### `doc/input_api.md` — 8 (matches exactly)

### `doc/development/decisions/input.md` — claim 15, actual 17 (mismatch, explained)

Current: **17 lines / 19 occurrences** (`grep -c` vs `grep -o | wc -l`
diverge because two lines each contain the string twice: `:1232` and one
other). Splitting the file at the point Decision 30 begins (`:1220`):
lines **1-1219 contain exactly 15 lines / 16 occurrences** —
matching the quoted "15×" exactly — and **Decision 30's own section
(:1220-1303) adds 2 more lines / 3 more occurrences** (`:1220` the
section heading itself names `keys_pressed`; `:1232` names both
`compy.input.keys_pressed` and `Controller.keys_pressed` in one line).

This is not a wrong claim — it is a **snapshot taken before Decision 30
was written into the document that records the dissolution it mandates**.
The session31 count of 15 was accurate at the time; committing Decision
30's own prose (which necessarily mentions the thing it dissolves)
mechanically raised the file's own count by 2. Report the current number
(17) as ground truth going forward.

### `doc/development/internals/user_input.md` — claim 12, actual 10 (mismatch, unexplained)

Current: **10 lines / 10 occurrences** (`:171, 241, 243, 264, 284, 292,
409, 410, 536, 846`). `git log --oneline -- doc/development/internals/
user_input.md` shows the file's last touch was the Decision 29 commit
(`1d5d7d0e`), predating Decision 30 entirely — unlike `decisions/input.md`
there is no "the ruling's own prose inflated the count" explanation
available here; the file has not changed since well before Decision 30
was written. **This count in the quoted dissolution surface appears to
simply be incorrect** — actual is 10, not 12, and no plausible
recent-edit explanation closes the gap. Flagging this prominently per the
task's instruction to surface a wrong claim rather than infer around it.

### Summary table

| Surface | Claimed | Actual | Match? |
|---|---|---|---|
| `src/` | 22 (7 files) | 22 (7 files) | yes |
| `tests/` | 38 | 38 | yes |
| `decisions/input.md` | 15 | 17 (15 pre-Decision-30 + 2 from Decision 30 itself) | explained mismatch |
| `internals/user_input.md` | 12 | 10 | **unexplained mismatch — claim appears wrong** |
| `technical_debt/` | 15 | 15 | yes |
| `doc/input_api.md` | 8 | 8 | yes |
