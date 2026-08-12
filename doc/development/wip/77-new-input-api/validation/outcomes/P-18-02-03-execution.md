# P-18-02/03 execution record — dissolve the `INPUT` proxy, `isMod` → `Key.is_mod`

Executed per `../prompts/P-18-02-03-proxy-and-ismod.md`. Mechanical, Sonnet. Nothing committed —
working tree left with the edits uncommitted, as instructed.

## Sites changed (all nine reads, verified equivalent — same `Key` call the proxy already made)

| file:line | before | after |
|---|---|---|
| `alt.lua:215` | `INPUT.ctrl and INPUT.alt` | `Key.ctrl() and Key.alt()` |
| `alt.lua:242` | `return INPUT.shift` | `return Key.shift()` |
| `alt.lua:252` | `if INPUT.shift then` | `if Key.shift() then` |
| `help.lua:18` | `h and INPUT.alt and not INPUT.ctrl` | `h and Key.alt() and not Key.ctrl()` |
| `input.lua:237` | `if INPUT.alt then return end` | `if Key.alt() then return end` |
| `input.lua:238` | `if INPUT.ctrl then return end` | `if Key.ctrl() then return end` |
| `input.lua:240` | `tostring(INPUT.shift)` | `tostring(Key.shift())` |
| `input.lua:242` | `capsReconcile(t, INPUT.shift)` | `capsReconcile(t, Key.shift())` |
| `keyboard_view.lua:286` | `if INPUT.shift then …` | `if Key.shift() then …` |

No site needed adaptation — all nine were the same `Key.shift()`/`Key.ctrl()`/`Key.alt()` call the
proxy's `__index` already made, so behaviour is unchanged.

## Proxy deletion (`input.lua`)

Deleted the `INPUT = setmetatable({ }, { __index = … })` block (was `input.lua:55-62`) and, inside
it, the marker `---> REMARK: WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?`. Along with the
block I also removed its two-line lead-in comment (`-- Reads ask Key, which folds each l/r modifier
pair the way a combo string does (doc/input_api.md, "Held keys").`) — it existed only to introduce
the deleted block and would otherwise dangle in front of an unrelated function (`claimChord`). Its
factual content ("reads ask `Key`, which folds l/r pairs") is subsumed by the rewritten header
paragraph below, minus the `doc/input_api.md` citation, which is a minor loss I'm flagging rather
than silently preserving by other means (the prompt did not ask for it to be kept, and re-adding it
to the header would have lengthened that paragraph, which the prompt forbids).

## Header paragraph rewrite (`input.lua`, was lines 43-50)

Before:
```
-- Held modifier state is asked of the keyboard through the
-- INPUT proxy below, which folds the l/r pairs via Key. It used
-- to be a mirror this file maintained on every press and
-- release, and then a read of a set the framework tracked; the
-- framework tracks nothing now (Decision 30) and the device is
-- the answer outside an event -- which is what the key-cap
-- renderer needs, since it reads INPUT.shift from draw, where
-- there is no event argument to consult.
```
After:
```
-- Held modifier state is asked of the keyboard through Key,
-- which folds each l/r pair the way a combo string does. It
-- used to be a mirror this file maintained on every press and
-- release, and then a read of a set the framework tracked; the
-- framework tracks nothing now (Decision 30) and the device is
-- the answer outside an event -- which is what the key-cap
-- renderer needs, since it reads that state from draw, where
-- there is no event argument to consult.
```
Same line count (8), no new claims, every changed line stays ≤64 chars (checked: max 63). The two
concrete `INPUT`/`INPUT.shift` mentions are gone; everything else (the mirror history, Decision 30,
the draw-time rationale) is untouched prose, per "state the fact that survives … do not add new
claims."

## `isMod` (`input.lua:120`, was `:132`)

Before:
```lua
function isMod(k)
  return k == "lshift" or k == "rshift"
    or k == "lctrl" or k == "rctrl"
    or k == "lalt" or k == "ralt"
end
```
After:
```lua
function isMod(k)
  return Key.is_mod(k)
end
```
No comment sat above `isMod` enumerating the names, so there was nothing to adjust there. Verified
equivalent via `/repo/src/util/key.lua`: `is_mod(k)` (`:147`) tests `fold_mod[k] ~= nil`, and
`fold_mod` (`:29-32`) is built from `shift_k = {"lshift","rshift"}`, `ctrl_k = {"lctrl","rctrl"}`,
`alt_k = {"lalt","ralt"}` (`:5-7`) — the same six names, no more, no fewer.
The six call sites did **not** move: `alt.lua:205`, `astrocore.lua:145`, `findkey.lua:132`,
`hide.lua:275`, `bubble.lua:147`, `train.lua:240` (confirmed by grep before and after — all six
lines still read `elseif not isMod(k) and k ~= "capslock" then` at the same file:line).

## Marker counts

- **Before:** `grep -rn "REMARK:\|INTERIM:" *.lua` → 2 hits: `input.lua:57` (the retired one, inside
  the proxy) and `input.lua:123` (`--> REMARK: what is it for? (setTextInput)`, untouched).
- **After:** 1 hit: `input.lua:111` (the `setTextInput` marker, same text, shifted up by the earlier
  deletion). No other `REMARK:`/`INTERIM:` line anywhere in the repo was touched.

## Verification run

- `grep -rn "INPUT\." *.lua` in the game directory: **no hits** (not even in comments — none of the
  surviving comments mention `INPUT` by name).
- `grep -rn "setmetatable" input.lua`: **no hits** — the proxy is gone.
- `mcp__lua-lsp__diagnostics` on all four edited files (`input.lua`, `alt.lua`, `help.lua`,
  `keyboard_view.lua`), run after `sleep 1`: only pre-existing `INFO lowercase-global` notices
  (repo-wide style, present on every top-level `function foo()`, unrelated to this edit) and one
  pre-existing `WARNING redundant-parameter` at `keyboard_view.lua:363` (predates this change, not
  touched). No new diagnostics, no errors.
- Confirmed via `Key.is_mod`/`Key.shift`/`Key.ctrl`/`Key.alt` definitions in `/repo/src/util/key.lua`
  that all replacements are behaviourally identical to what the proxy called.

### Smoke run

From `/repo`:
```
timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/keyboard
```
Exit code 124 (killed by timeout — success per the prompt). Output included the three expected
framework lines:
```
Project play opened
Press Ctrl-Esc to exit
INFO : Running 'play'
```
and no Lua error. (ALSA "cannot find card" warnings and the final `XIO: fatal IO error … on X
server` are the headless-audio and Xvfb-killed-by-timeout noise this container always produces, not
project errors.)

**Not verified:** reaching any game scene — this container cannot inject keystrokes, so only the
load (through `Running 'play'`) was confirmed; scene behaviour (Alt-keys chord, Caps reconciliation,
keycap highlighting, etc.) was not exercised and rests on the file:file equivalence check above.

## Deviations from the prompt

None in the required edits. One judgment call, noted above: removing the two-line comment
immediately preceding the deleted proxy block (not explicitly named in the prompt's site list, but
left dangling and inaccurate otherwise) and not carrying its `doc/input_api.md` citation into the
header rewrite (would have lengthened the header, which is forbidden).

## Files touched

- `/repo/src/examples/keyboard/input.lua`
- `/repo/src/examples/keyboard/alt.lua`
- `/repo/src/examples/keyboard/help.lua`
- `/repo/src/examples/keyboard/keyboard_view.lua`

All edits are uncommitted in the working tree.
