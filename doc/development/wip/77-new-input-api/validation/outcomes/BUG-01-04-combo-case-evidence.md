# BUG-01-04 — evidence: does `combo_string` fail to normalise textinput case?

Investigates `T-COMBO-CASE` (`doc/development/technical_debt/input.md:136-154`).
Read-only pass; no files changed except this one.

## Summary up front

**The defect is real, exactly as described, and it is not inherited from
anywhere — this feature introduced both halves of the asymmetry itself.**
At the PR base (`3256aac`) neither `combo_string` nor `normalize_combo` /
`split_combo` / `new_handler_table` existed at all (see §7). The feature
that added the combo mechanism wrote a lower-casing registration path and
a non-lower-casing dispatch path in the same body of work, so this is a
fresh bug in new code, not drift in old code.

## 1. Is the defect still real, exactly as described?

Yes. Current code:

`src/controller/controller.lua:383-391`:
```lua
local function combo_string(k)
  local combo = ''
  for _, m in ipairs(COMBO_MODS) do
    if MOD_HELD[m[3]]() then
      combo = combo .. m[3] .. '+'
    end
  end
  return combo .. k
end
```
`k` is appended verbatim — no `:lower()` anywhere in this function.

`src/util/key.lua:113-120` (registration side, `Key.new_handler_table`'s
`__newindex`):
```lua
local function new_handler_table()
  return setmetatable({ }, {
    __newindex = function(t, k, v)
      check_combo(k)
      rawset(t, normalize_combo(k), v)
    end,
  })
end
```
`normalize_combo` (`src/util/key.lua:67-75`) calls `split_combo`
(`src/util/key.lua:46-57`), which does `combo:lower():gmatch('[^+]+')`
(line 48) — the **entire input string** is lower-cased before splitting.
So `tbl['shift+I'] = fn` is stored under key `'shift+i'`, while
`combo_string` dispatching a real `shift`+`I` textinput event produces
the literal string `'shift+I'`. Lookup by `'shift+I'` misses the
`'shift+i'` slot. The debt entry's description is accurate.

## 2. Both directions — what exactly gets lower-cased

- **Registration** (`split_combo`, key.lua:48): lower-cases the **whole
  combo string** — mods and trigger token alike — before tokenising.
  There is no separate mod-only or trigger-only step; `:lower()` runs
  once over the full string.
- **Dispatch** (`combo_string`, controller.lua:383-391): lower-cases
  **nothing**. The modifier prefixes it emits (`'ctrl'`, `'alt'`,
  `'shift'`) are already-lowercase literals baked into `mod_triples`
  (`src/util/key.lua:16-20`, generic names `"ctrl"`, `"alt"`, `"shift"`),
  so they happen to come out lowercase by construction — but that is
  incidental, not a `:lower()` call. The trigger `k` is concatenated
  as-is (`combo .. k`, controller.lua:390), with whatever case it
  arrived in.

So: registration folds case symmetrically over the whole string;
dispatch folds case nowhere — its apparent lowercase mod prefix is just
"the literals were written lowercase," not normalisation.

## 3. Does this affect `keypressed` combos too, or only `textinput`?

Confirmed: **only `textinput`.** LÖVE key constants for `keypressed`
and `keyreleased` are drawn from a fixed lowercase vocabulary
(`"a"`..`"z"`, `"f1"`, `"escape"`, …); there is no code path in this
tree that could hand `combo_string` an upper-case `k` for those two
channels — it comes straight from LÖVE's own event pump argument, never
derived from `love.keyboard.isDown`/shift state. `textinput`, in
contrast, delivers the actual composed character (`t` in
`love.textinput(t)`), which **is** shift/caps-lock-sensitive — pressing
Shift+I with the US layout delivers `"I"` on `textinput`, but `"i"` on
`keypressed`'s `key` argument (unaffected by Shift). This split is real
and is exactly what the debt entry implies but does not spell out.

## 4. Who calls `combo_string` — full call-site list

Cross-checked LSP `references` against `grep -rn "combo_string"` — both
found the same three call sites, no disagreement:

| Call site | Channel(s) | Token source | Can be upper-case? |
|---|---|---|---|
| `controller.lua:891` `RESERVED.keypressed[combo_string(k)]` | keypressed | `k` = raw LÖVE keypressed arg, from `handlers.keypressed = function(k, sc, isr)` (controller.lua:884) | **No** — LÖVE key constant |
| `controller.lua:915` `RESERVED.keyreleased[combo_string(k)]` | keyreleased | `k` = raw LÖVE keyreleased arg (controller.lua:914) | **No** — LÖVE key constant |
| `projectInputController.lua:110` `tbl[Controller.combo_string('*')]` | any channel, no-trigger class lookup | literal `'*'` | No — literal |
| `projectInputController.lua:113` `tbl[Controller.combo_string(trigger)]` | **every** `EVENTS` channel via `find_shortcut` | `trigger = TRIGGER[event](...)`; for `textinput`, `TRIGGER.textinput = function(t) return t end` (projectInputController.lua:52) — the raw composed character | **Yes, for `textinput` only.** `keypressed`/`keyreleased` triggers are the LÖVE key constant (lowercase); `mousepressed`/`mousereleased` triggers are `'mouse' .. b` (no letters) |
| `projectInputController.lua:115` `tbl[Controller.combo_string('*')]` | fallback class lookup, same channels as above | literal `'*'` | No — literal |

`combo_string` is exported once, at `controller.lua:471`
(`combo_string = combo_string` inside the `Controller` table), which is
what `projectInputController.lua` calls through `Controller.combo_string`;
the two `controller.lua` internal call sites use the local upvalue
directly. Same function either way.

**Only `projectInputController.lua:113`, on the `textinput` channel,
can carry an upper-case token into `combo_string`.**

## 5. Reservation / global-shortcut path — same normalisation?

`RESERVED` (`controller.lua:865-882`) has exactly two sub-tables,
`keypressed` and `keyreleased`:
```lua
local RESERVED = {
  keypressed = {
    ['ctrl+t'] = reserved_quickswitch, ...
  },
  keyreleased = {
    ['ctrl+escape'] = function() love.event.quit() end,
  },
}
```
**There is no `RESERVED.textinput` table at all.** The reservation
mechanism never dispatches on textinput, so it cannot be exposed to the
case bug — it is structurally excluded, not incidentally safe. Its
keys are plain hand-written lowercase Lua string literals (not run
through `normalize_combo`/`Key.new_handler_table`); they work only
because `combo_string(k)` on the keypressed/keyreleased channels always
receives an already-lowercase `k` (§3), so no folding is needed on this
path. `tests/input/input_global_shortcuts_spec.lua:49-350` pins this
reservation behaviour — every `it(...)` name in that file (`ctrl+pause`,
`ctrl+q`, `ctrl+escape`, `ctrl+t`, `ctrl+alt+r`, `f10`, …) is a
keypressed/keyreleased combo; none touches textinput.

## 6. Existing test coverage

`tests/input/input_combo_serialisation_spec.lua` (pins `combo_string`
directly, `describe` at line 46): all seven `it(...)` cases use only
already-lowercase input —
`'bare key escape'`, `'bare key s'`, `'ctrl+s from lctrl held'`,
`'ctrl+s from rctrl held'`, `'alt+shift+f4 ordering'`,
`'ctrl before alt precedence'`, `'all modifiers: ctrl alt shift'`
(lines 55-92). **No case is asserted anywhere in this file** — every
call is `cs('s')`, `cs('f4')`, `cs('escape')`, all lowercase.

`tests/input/input_events_spec.lua:270-279`, `'a textinput combo fires
on the normalised combo'`, registers `input.shortcuts.textinput['Ctrl+J']`
(upper-case at registration) but then drives it with
`F.session.press('lctrl'); F.session.type('j')` — **lower-case `'j'`**.
This test proves registration-side normalisation (`'Ctrl+J'` ->
`'ctrl+j'`) but never drives an upper-case character through dispatch,
so it does not exercise the bug.

`tests/input/input_widget_control_spec.lua:718-786`, "the documented
echo guard" — pins the exact idiom the debt entry cites (`T-COMBO-CASE`
"Why it stands"). `arm(input)` (line 720-725) registers
`shortcuts.textinput['i']` (bare lower-case), and every driving call is
`F.session.type('i')` (lines 744, 754, 767-769, 779, 783) — always
lower-case. No test types an upper-case echo character.

`tests/input/input_events_spec.lua:930-940` uses
`F.session.type('X')` / `F.session.type('Y')`, but against
`input.hooks.textinput`, not `input.shortcuts.textinput` — the hooks
path calls the hook function directly (`dispatch`,
`projectInputController.lua:141-142`, `hk(...)`) with no `combo_string`
involved at all, so case is irrelevant there.

**Verdict: no test in the suite drives an upper-case character through
the `shortcuts.textinput` combo-matching path. If dispatch started
lower-casing the textinput trigger before calling `combo_string`,
nothing in the current 1025-case suite (`busted tests`, reconfirmed
during this pass: `1025 successes / 0 failures / 0 errors / 10 pending`)
would break.**

## 7. Base check — ours or pre-existing? (reported prominently per instructions)

PR base is `3256aac4d6dfde3a6555b5d7e9b8375414183818`
("docs: add development documentation, conventions and internals
guides"). Direct comparison:

```
git show 3256aac:src/controller/controller.lua | grep -n combo_string   -> no matches
git show 3256aac:src/util/key.lua | grep -nE "normalize_combo|split_combo|new_handler_table|:lower\(\)"  -> no matches
```

`git show 3256aac:src/util/key.lua` in full (53 lines) has only
`is_enter`, `is_shift`/`shift`, `is_ctrl`/`ctrl`, `is_alt`/`alt` — no
`mod_triples`, no `normalize_combo`, no `split_combo`, no
`new_handler_table`, no lower-casing of anything. `git show
3256aac:src/controller/controller.lua` (819 lines) has no
`combo_string` and no `RESERVED` table.

**Neither side of the asymmetry existed at base.** The combo mechanism
— `combo_string` (dispatch, non-lower-casing) and
`normalize_combo`/`split_combo`/`Key.new_handler_table` (registration,
lower-casing) — was added wholesale by this feature. This is not
inherited drift and not a widened pre-existing gap: **this feature
introduced the asymmetry**, by writing a lower-casing registration path
and a non-lower-casing dispatch path within the same body of new code.

## 8. Blast radius of the obvious fix

The obvious fix is lower-casing the `textinput` trigger before (or
inside) the `combo_string` lookup. Concretely, what runs through the
affected code:

- **`combo_string` itself is shared** by all `RESERVED` lookups
  (keypressed/keyreleased) and all `find_shortcut` lookups (every
  `EVENTS` channel), via the single call sites in §4. If the fix is
  placed *inside* `combo_string` (lower-casing `k` unconditionally),
  every caller is affected — but for keypressed/keyreleased/mouse/`*`
  callers `k` is already lowercase or non-alphabetic (§3, §5), so
  `:lower()` on those inputs is a no-op. No observed change to
  keypressed/keyreleased/mouse/reservation matching.
- **The only live-behaviour change is on `shortcuts.textinput`
  lookups.** `combo_string`'s return value is used **only as a table
  key for `find_shortcut`** (`projectInputController.lua:106-116`); it
  is never passed to the hook, the shortcut handler's own arguments, or
  the widget. The varargs `...` that reach `sc(...)`, `hk(...)`, and
  `widget[event](widget, ...)` in `dispatch`
  (`projectInputController.lua:138-148`) are the **original, uncased**
  event arguments — so the actual character that lands in the input
  widget (`compy.input`'s userInputController/userInputModel) is
  **unaffected** by this fix. The fix only changes *which registered
  shortcut function fires*, never what text is typed.
- **No new collisions at registration**: since `Key.new_handler_table`
  already lower-cases at write time (§1), `shortcuts.textinput['I']`
  and `shortcuts.textinput['i']` already collide into one slot today —
  the second write silently overwrites the first. Fixing dispatch does
  not create any new ambiguity that registration didn't already force;
  it only makes the single surviving slot reachable from both cases of
  keystroke.
- **Turtle's echo guard** (`src/examples/turtle/main.lua:61-67`,
  registers bare `shortcuts.textinput["i"]`) and the identically-shaped
  spec in `input_widget_control_spec.lua:718-786` are the one in-tree
  consumer on this path (§9). Both register only the bare lower-case
  slot, so the fix would change turtle's behaviour only for an
  upper-case echo (e.g. caps-lock-produced `"I"` from a bare `i`
  keystroke, or a genuinely shift-modified trigger, which today leaks
  through unguarded); it does not change the already-tested lower-case
  cases at all — nothing in `input_widget_control_spec.lua`'s "the
  documented echo guard" block should regress since it never drives
  upper-case input (§6).
- **`Key.is_mod(trigger)` guard** (`projectInputController.lua:112`)
  runs before the fix would apply and is case-sensitive against
  `fold_mod` keys (`lctrl`/`rctrl`/etc., always lowercase); textinput
  triggers are printable characters, never modifier key names, so this
  guard is unaffected either way.

Net: the fix is narrowly scoped in actual effect (only
`shortcuts.textinput` matching changes; nothing else observably moves),
even though `combo_string` is structurally shared code.

## 9. In-tree consumers of a textinput combo

`git grep`/plain grep for `shortcuts.textinput` and `shortcuts['textinput']`
/`shortcuts["textinput"]` across `/repo/src`, `/repo/tests`, `/repo/doc`:

- **`src/examples/turtle/main.lua:62-63`** — the only production/example
  consumer: `compy.input.shortcuts.textinput["i"] = function() ... end`,
  re-armed via `compy.input.callbacks.after_submit = arm_echo_guard`
  (line 81). **Bare lower-case `"i"` only** — no upper-case combo
  registered anywhere in this file.
- **`tests/input/input_widget_control_spec.lua:721-722`** — the spec
  pinning the same idiom, also bare lower-case `'i'`.
- **`tests/input/input_events_spec.lua:274`** —
  `input.shortcuts.textinput['Ctrl+J']`, upper-case at the source, but
  (§6) driven only with a lower-case `'j'` keystroke, so it never
  exercises the mismatch.
- **`doc/input_api.md:738-739`** — documents the same turtle idiom,
  bare lower-case `'i'` (documentation, not code).
- No other file under `src/examples/` (balloons, maze, keyboard,
  tixy, pong, clock, colors, guess, life, paint, repl, sapper, sine,
  valid) registers anything on `shortcuts.textinput`.
  `src/examples/keyboard/*` uses `compy.input.hooks.textinput` (the
  hook path — `input.lua:97`, `alt.lua:298`, `words.lua:348`), which
  bypasses `combo_string`/`find_shortcut` entirely (§6) and does its
  own case-sensitive character matching in game logic, unrelated to
  this defect.

**No in-tree consumer registers an upper-case textinput combo that is
also driven by an upper-case keystroke.** The one real consumer
(turtle's echo guard) is a bare lower-case slot whose only exposure to
this bug is an upper-case/caps-lock-produced echo it currently fails to
catch — consistent with the debt entry's "Why it stands" note that the
paired-shortcut idiom is "a real textinput-combo consumer... confined
to bare triggers," though note that even a `shift+i`-typed echo does
not reach this guard today for an unrelated reason: the guard is keyed
bare (`'i'`), not `'shift+i'`, so a genuinely shift-held echo would miss
on the *modifier* prefix regardless of this case bug — only a
same-modifier-state (bare), different-case token (i.e., caps-lock) hits
the case bug specifically for this consumer.

## Corrections to the debt entry

1. **"the registration side... lower-cases through `normalize_combo`"**
   is correct but incomplete: the entry doesn't state that the
   lower-casing happens over the *whole string* inside `split_combo`
   (key.lua:48), not `normalize_combo` itself — `normalize_combo` just
   reassembles what `split_combo` already lowered. Minor, doesn't
   change the verdict.
2. **The entry's illustrative scenario ("shift held and `I` typed...
   dispatch looks up `shift+I`") is a fair generic illustration but
   does not correspond to the one real in-tree consumer.** Turtle's
   guard registers a bare `'i'`, not `'shift+i'` — a shift-held echo
   would already miss on the modifier prefix, independent of case. The
   scenario that actually triggers the bug for turtle's guard is an
   upper-case character with **no** modifier held (caps-lock), not a
   shift-held combo. The entry should either use a bare-key example or
   note this distinction, since as written a reader would conclude the
   shift+I example directly explains why turtle's guard can fail,
   which it does not.
3. **No claim in the entry about provenance (base vs. new).** This is
   the most important gap: a reader could assume this is long-standing
   drift. It is not — the entire combo mechanism (§7), both the
   lower-casing side and the non-lower-casing side, was introduced by
   this feature. This should be stated in the entry.
4. Everything else in the entry — the unreachable-slot mechanics, that
   bare lower-case tokens are unaffected, and that `keypressed`
   combos are unaffected — is confirmed accurate by this pass.
