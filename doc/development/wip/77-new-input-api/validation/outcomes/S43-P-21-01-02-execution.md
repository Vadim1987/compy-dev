# P-21-01 + P-21-02 — outcome

Commits: `b20a4c35` (P-21-01) and `77aed369` (P-21-02). Branch
`feature/77-newapi-analysis-s20260615`. Not pushed.

## What changed, per row

Table numbering from `../reviews/S43-P-21-00-blast-radius.md`.

- **Predicate.** `only_mods(ctrl, alt, shift)` added to
  `src/controller/controller.lua`, next to `MOD_HELD`. Reads
  `Key.ctrl()/alt()/shift()` (Decision 30), no table argument.
  Uses `(not not X) == want` rather than a bare `X == want` —
  see "Not anticipated by the table" below for why.
- **Row 9** (keyreleased, Ctrl+Escape, `:884-885` pre-edit):
  `if Key.ctrl() then if k == "escape" ...` → `if
  only_mods(true, false, false) and k == "escape" then`.
- **Row 1** (quickswitch, ctrl+t): `Key.ctrl() and not Key.alt()`
  → `only_mods(true, false, false)` — now also excludes Shift.
- **Row 2** (suspend, ctrl+pause) and **row 3** (quit, ctrl+q):
  shared outer `if Key.ctrl() then` → `if only_mods(true, false,
  false) then`, both branches inside unchanged.
- **Row 4** (stop/close, ctrl+s): `Key.ctrl()` (shared with rows
  2/3 pre-edit) → its own `Key.ctrl() and not Key.alt()`, left as
  a hand-written exclusion (not `only_mods`) because Shift stays
  meaningful in the editor sub-branch (finish edit vs close
  buffer) — the trap the prompt flagged. Only Alt is now
  excluded, per the table.
- **Row 5** (reset, ctrl+shift+r): `Key.shift()` (nested inside
  the old shared `Key.ctrl()`) → its own `only_mods(true, false,
  true)` — now also excludes Alt.
- **Row 6** (restart, ctrl+alt+r): `Key.ctrl() and Key.alt()` →
  `only_mods(true, true, false)` — now also excludes Shift.
- **Row 7** (profiler, ctrl+alt+p): untouched, confirmed by
  `git diff` showing no change to that condition.
- **Row 8** (F10 overlay): `if k == "f10" then` → `if k == "f10"
  and only_mods(false, false, false) then` — now requires no
  modifier at all.

`project_state_change()`'s three conditions (pause/q, s, r) went
from one shared `if Key.ctrl() then` wrapping all three to three
independent top-level `if`s, each carrying its own exact
condition — nesting depth on the deepest branch (the
editor+shift sub-branch of row 4) improved from 4 to 3, because
merging the outer `Key.ctrl()` guard and the `k == "s"` check
into one condition removed a level. Body line count grew from 25
to 27 (the two comment lines above the row-4 condition noting
Shift stays meaningful), so the pre-existing size debt is
unaffected but not literally unchanged either.

**Correction (2026-08-16, S43-P-21-06):** the paragraph above
originally claimed nesting was "unchanged (still 4)" and body
line count "unchanged (25 lines)". Both were wrong. Measured by
counting the lines strictly between `local function
project_state_change()` and its closing `end`
(`src/controller/controller.lua:801-829`, currently 27 such
lines; pre-edit at `77aed369^:src/controller/controller.lua`,
25 such lines) and by counting `if`-nesting depth in the
editor+shift sub-branch (pre-edit 4, via `git show
77aed369^:src/controller/controller.lua`; post-edit 3, current
file). The pre-existing size debt is correctly left unfixed —
only the cited numbers were wrong, corrected in place above.

## The double-fire defect (rows 5/6)

Confirmed live, not just asserted from the table: pre-fix,
`ctrl+alt+shift+r` satisfied both `Key.ctrl() and Key.alt()`
(restart) and the old shared `Key.ctrl()` + nested `Key.shift()`
(reset), so one event ran **both** `CC:restart()` and
`CC:reset()`. The new test `'ctrl+alt+shift+r fires neither
restart nor reset'` asserts both are nil after the fix; run
against the pre-fix tree it asserted both `true` (see the
failing-output block below). Exactness makes the two gates
mutually exclusive by construction — no separate fix needed.

## Test coverage

Both commits added live cases to
`tests/input/input_global_shortcuts_spec.lua`, under a new `'a
reservation matches its modifier set exactly'` describe. Per
tightened reservation: the exact combo still fires (control), and
the extension no longer does — with a project's own binding
registered on the extended combo, proving the event now reaches
the route rather than merely going silent. Rows 2 and 3 already
had a live "exact combo" case from the pre-existing
non-suppression describe, so only their extension case was new.

Row 4's pair uses the running-state branch (`ctrl+s` stops a
running project) rather than the editor branch, to avoid
exercising `EditorController:save_state()/close()` from a bare
`app_state = 'editor'` with no real buffer loaded; both branches
share the one outer condition that changed, so this is sufficient
evidence for the row's own tightening. The editor branch's own
effect stays the named pending gap it already was (line 91,
untouched).

Rows 5, 6, and the double-fire case use a small local
`drive_stub(combo)` helper (a stub controller table + a temporary
`love.handlers` swap, restored after) instead of the real
`ConsoleController`, because `CC:restart()`/`CC:reset()` reach
real project execution (`run_project`) and console-history
teardown that this fixture does not stand up. This is the
Decision-17 named-seam exception, and it isn't a new idiom —
`input_shortcuts_click_spec.lua`'s `#play mode narrows the active
shortcut set` row already uses the identical stub-and-swap
technique for `restart`/`quit_project`.

**Untouched, verified:** the seven `pending(...)` outlines in the
spec file (`git diff` shows zero changes to any `pending(` line),
and the suite's pending count stayed at 10 throughout.

## Evidence: failing before, passing after

P-21-01 (row 9), against the pre-fix tree:

```
3 successes / 1 failure / 0 errors / 7 pending : 0.062186 seconds

Failure -> ... ctrl+shift+escape no longer quits; the project
binding runs instead
Expected objects to be equal.
Passed in:   (number) 1
Expected:    (number) 0
```

After the P-21-01 commit: `951 successes / 0 failures / 0 errors
/ 10 pending`.

P-21-02 (rows 1-6, 8 + double-fire), against the tree at
`b20a4c35` (P-21-01 landed, P-21-02 not yet):

```
9 successes / 8 failures / 0 errors / 7 pending : 0.071749 seconds

Failure -> ... ctrl+shift+t no longer quickswitches ...
Passed in: 'project_open'   Expected: 'running'

Failure -> ... ctrl+alt+pause no longer suspends ...
Passed in: 'snapshot'       Expected: 'running'

Failure -> ... ctrl+shift+q no longer quits ...
Passed in: 'project_open'   Expected: 'running'

Failure -> ... ctrl+alt+s no longer stops the run ...
Passed in: 'project_open'   Expected: 'running'

Failure -> ... ctrl+f10 no longer cycles ...
Passed in: 'T_L_B'          Expected: 'off'

Failure -> ... ctrl+alt+shift+r no longer restarts
Passed in: (boolean) true   Expected: nil

Failure -> ... ctrl+alt+shift+r no longer resets
Passed in: (boolean) true   Expected: nil

Failure -> ... ctrl+alt+shift+r fires neither restart nor reset
Passed in: (boolean) true   Expected: nil
```

All 8 "exact combo still works" controls passed even before the
fix (expected — the old tolerant gates already accept the exact
form), confirming the pairs isolate the boundary, not the effect.

After implementing rows 1-6/8: `964 successes / 0 failures / 0
errors / 10 pending` (949 baseline + 2 from P-21-01 + 13 new
here).

## Not anticipated by the table

`only_mods`'s first implementation (`Key.ctrl() == ctrl and
Key.alt() == alt and Key.shift() == shift`) broke
`tests/harmony_input_spec.lua`'s `'queues on push, drains before
the app sees it'` test — a full-suite regression the blast-radius
table did not (and could not, being pre-code) predict.

Root cause: Harmony's `patch_isDown` (`src/harmony/init.lua`)
answers a held key from its own table, and otherwise — **only
when `not lock`** — falls through to the original
`love.keyboard.isDown`. `harmony.utils.load_key` scenarios run
with `lock = true` (set by `Harmony(true)`, this spec's setup),
so for a modifier Harmony's own table doesn't have held, the
patched function returns **no value at all**, not `false`. `Key.
alt()`/`Key.shift()` tail-call straight through to that, so they
too return zero values in that case. The *old* per-row code
(`Key.ctrl() and not Key.alt() and ...`) tolerated this silently
— `not nil` is `true` in Lua, same as `not false` — but my `==
false` comparison did not: `nil == false` is `false`, so
`only_mods` read a genuinely-unheld Alt/Shift as "doesn't match,"
and quickswitch silently stopped firing under Harmony's lock
mode.

Fixed by normalising each read with `not not` before comparing
(`(not not Key.alt()) == alt`), which collapses "no value" and
`false` to the same boolean ahead of the `==`. Caught by running
the **full** suite after wiring the predicate into the keypressed
rows, not by the row-level tests themselves (none of which drive
Harmony) — worth flagging since it means the row-level tests
alone would not have caught it; the full-suite gate did its job.

## Suite arithmetic

| Point | Suite |
|---|---|
| Baseline | 949 / 0 / 0 / 10 |
| After P-21-01 (`b20a4c35`) | 951 / 0 / 0 / 10 |
| After P-21-02 (`77aed369`) | 964 / 0 / 0 / 10 |

Pending count 10 throughout, all 7 file-local pendings untouched.

## Commits

- `b20a4c35` — `fix(input): exact modifiers on the release-gate
  quit combo` (P-21-01: predicate + row 9).
- `77aed369` — `fix(input): exact modifiers on the keypressed
  power-shortcut gate` (P-21-02: rows 1-6, 8, double-fire fix).

Both touch only `src/controller/controller.lua` and
`tests/input/input_global_shortcuts_spec.lua`, staged explicitly
by path. Neither pushed.
