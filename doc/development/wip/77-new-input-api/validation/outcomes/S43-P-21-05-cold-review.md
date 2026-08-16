# P-21-05 — cold review of the Decision 33 sweep (outcome)

Cold reviewer, read-only, Sonnet. Reviewed `b20a4c35` and `77aed369` against
Decision 33 (`doc/development/decisions/input.md`), the nine-row table in
`../reviews/S43-P-21-00-blast-radius.md`, and the six checks in
`../prompts/S43-P-21-05-cold-review.md`.

## Verdict

**The sweep is complete, exact, and defended by its tests.** All nine rows
match the table exactly, `only_mods`'s `not not` normalisation fixes a real
bug (verified against Harmony's `patch_isDown`), row 7 is genuinely
untouched, and the suite is 964/0/0/10 with the seven `pending()` outlines
byte-for-byte unchanged. I found one real, if narrow, test-coverage gap
(S2) and one factual inaccuracy in the outcome report's own hard-limit
bookkeeping (S1 by this prompt's definition, but not a behaviour defect —
the two numbers it cites don't match the code). Neither blocks the sweep;
both are worth a line in the record.

## Findings

### S2 — Row 4's Shift-preservation has no negative case

`controller.lua:812` (`77aed369`): `if Key.ctrl() and not Key.alt() and k
== "s" then` — correctly excludes only Alt, matching the table and the
prompt's named trap ("Shift chooses finish-edit vs close-buffer"). This is
verified correct by reading.

But no test — new or pre-existing — drives `ctrl+shift+s`. The 15 new
cases include an Alt-exclusion pair for row 4 (`input_global_shortcuts_
spec.lua:186` positive, `:194` negative), and the outcome report
(`../outcomes/S43-P-21-01-02-execution.md:72-79`) explains why the pair
exercises the running-state branch, not the editor branch. Reasonable as
far as it goes — but it defends only the *Alt* exclusion. Nothing proves
the gate does **not** also exclude Shift. Every other tightened row in
this sweep (1, 2/3, 5, 6) drops Shift as part of its exact-match tuple, so
`not Key.shift()` creeping into row 4's condition (matching the pattern
used everywhere else) would be an easy mistake — and one the full suite
would not catch: I confirmed by grep across `tests/input/*.lua` and
`tests/editor/editor_spec.lua` that `ctrl+shift+s` is pressed nowhere,
live or in a pre-existing case. A single added case — `ctrl+shift+s still
stops a running project` — would close this at the cost of one `it()`
block, using the same running-state shortcut as the existing pair.

Everything else in check 3 held up. I traced all 15 new cases against
"what change would make it fail": each negative case fails against the
pre-fix tree for the reason its comment claims (confirmed against the
outcome report's own before/after failure transcript, and independently
re-derived from the diff for a sample: `ctrl+shift+t`, `ctrl+alt+pause`,
`ctrl+alt+s`, `ctrl+f10`, both `ctrl+alt+shift+r` cases). The two rows
that lean on pre-existing cases (2 and 3, `ctrl+pause`/`ctrl+q`, reusing
`:62-95`) genuinely cover the positive claim — those pre-existing cases
press the exact combo with no other modifier held, which is what row 2/3's
positive case needs, and the test file says so explicitly at `:270-275`.
That reuse is sound, not a gap.

### S1 (per this prompt's definition — a claim its evidence does not support)

`../outcomes/S43-P-21-01-02-execution.md:40-46` claims, for
`project_state_change()`: *"nesting depth is unchanged (still 4 on the
deepest, the editor+shift sub-branch of row 4), body line count is
unchanged (25 lines, matching the pre-edit function)."*

Measured directly from the two trees:

| | before (`b20a4c35^`) | after (`77aed369`) |
|---|---|---|
| body lines | 25 (`:791-815`) | **27** (`:802-828`) |
| max nesting in the editor/shift branch | 4 (`ctrl` → `s` → `running`/`editor` → `shift`) | **3** (the merged `Key.ctrl() and not Key.alt() and k=="s"` condition removes one level) |

Body count grew by 2 (the two new `only_mods`/Decision-33 comment lines at
`:810-811`), not "unchanged." Nesting actually improved by one level
(merging the old two-level `if Key.ctrl() then … if k == "s" then` into
one condition), not "still 4." Both are independently verifiable by
`sed -n '791,815p'` / `'802,828p'` on the two revisions plus a manual walk
of the `if`/`elseif` structure — done above.

This doesn't change the substantive fact the report was defending: the
function already violated the 14/16-line body limit before this PR
(pre-existing tech debt, correctly not fixed here — see `agents/
development.md`'s "report, don't fix" instruction), and still does after.
Neither commit newly *crosses* a hard limit that was previously clean. But
the specific numbers cited to support "got no worse" are wrong in both
directions, and this is exactly the kind of self-report the cold-review
step exists to catch when the analysis and the fix came from related
sessions. `quickswitch()` (`:779-800`), by contrast, is genuinely
unchanged at 20 body lines (verified: only its guard condition's text
changed, same line count) — the report's claim about that function, made
in the same paragraph, holds.

## What I verified clean

- **All nine rows, exact match.** `only_mods(true,false,false)` (rows 1,
  2, 3, 9), `only_mods(true,false,true)` (row 5), `only_mods(true,true,
  false)` (row 6), `only_mods(false,false,false)` (row 8), and the
  hand-written `Key.ctrl() and not Key.alt()` (row 4) all match the
  table's "exact form" column precisely (`controller.lua:780,802,812,823,
  831,844,897`). Confirmed via `git diff b20a4c35^ 77aed369` — exactly 5
  hunks, none outside the nine rows plus the predicate's own definition.
- **Row 4 trap.** Confirmed in code: only Alt is excluded from the outer
  `ctrl+s` gate; Shift is untouched and still gates `finish_edit` vs
  `close_buffer` inside the unmodified editor branch (`:816-820`).
- **Row 7 trap.** `Key.ctrl() and Key.alt() and k == "p"` (`:836`) is
  byte-identical before and after both commits — confirmed no diff hunk
  touches it.
- **`only_mods`'s `not not` is a real fix, not paper-over.** Traced
  Harmony's `patch_isDown` (`src/harmony/init.lua:249-260`): when `lock`
  is true and a queried key isn't in `held`, `isDown(...)` falls off the
  end of the function with no explicit return — Lua callers see `nil`,
  not `false`. A bare `Key.alt() == false` then reads `nil == false` as
  `false`, misreading an actually-unheld Alt as "doesn't match." The
  pre-existing hand-written idiom (`Key.ctrl() and not Key.alt() and …`)
  tolerates this because `not nil` is `true` in Lua — which is exactly
  why row 4's hand-written exclusion (not routed through `only_mods`)
  needs no `not not` of its own. `tests/harmony_input_spec.lua`'s
  `'queues on push, drains before the app sees it'` case runs with
  `lock=true` and a bare `C-t` (no Alt/Shift in `held`), which is the
  scenario that breaks under a straight `==` — confirmed this is the
  live path, not a hypothetical.
- **`only_mods`'s name.** Honest: it asserts an exact tuple match against
  ctrl/alt/shift, which for a fully-specified triple is equivalent to
  "only these are held" — matches Decision 33's own language.
- **The pendings.** Zero lines touched — `git diff b20a4c35^ 77aed369 --
  tests/input/input_global_shortcuts_spec.lua | grep 'pending('` returns
  nothing. Suite: `964 successes / 0 failures / 0 errors / 10 pending`
  (ran locally, matches the outcome report exactly).
- **Blast radius, confirmed.** Grepped `src/examples/` for every extended
  combo named in the table; only `maze_main.lua` and `draw_main.lua`
  register on the freed Ctrl+Shift+Escape / Ctrl+Alt+Shift+Escape family
  (`:227,229` and `:371,373`), matching the table's prediction. Their
  stale "RISK" comment (`maze_main.lua:214-220`) is now factually
  resolved by `b20a4c35` but its removal is P-21-03, correctly out of
  scope for these two commits. No other example or nested repo
  registration extends a reserved combo.
- **Out-of-scope code, untouched.** `set_love_keypressed`'s debug hotkeys
  at `:501` (Ctrl+Shift+digit) and `:522` (Ctrl+Alt+D) are outside both
  diffs' five hunks — confirmed by hunk header line ranges, none overlap
  `480-540`.
- **Hard limits — line length and params.** No line in either diff
  exceeds 64 chars (checked every added line programmatically).
  `only_mods(ctrl, alt, shift)` — 3 params, within the ≤4 limit.
- **Comments.** Every added comment cites the canonical
  `doc/development/decisions/input.md` path (never `wip/…`), and each
  carries a payload under `agents/rules/commenting.md`'s four-payload
  test (non-local context: Decision 33's citation; intent/constraint: the
  `not not` rationale and the Shift-stays-meaningful note).
- **LSP diagnostics.** Ran `mcp__lua-lsp__diagnostics` on
  `controller.lua`: 21 pre-existing hints/warnings (undefined `compy`
  field, redundant-parameter on pointer handlers, unused locals), none on
  any line either commit touches.

## What I could not check

- Whether `EditorController:save_state()`/`close()` behave correctly when
  driven live through `ctrl+shift+s` in `app_state == 'editor'` — no
  fixture in this suite stands that up (pre-existing gap, per the outcome
  report's own note, not something either commit was obligated to add).
  The S2 finding above is about the modifier gate proving Shift isn't
  excluded, which needs only the running-state branch already used by the
  existing pair — not this deeper editor fixture.
