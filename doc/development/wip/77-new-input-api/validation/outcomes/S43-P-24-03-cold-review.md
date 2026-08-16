# S43-P-24-03 — cold review of the reservation table (outcome)

Worker: Sonnet (cold, read-only). Commits reviewed: `737d8316` (combo_string
without a table), `f31bd312` (RESERVED table replaces the predicate cascade).

## Verdict

**Representation-only. No behaviour change found.** Both commits touch only
`src/controller/controller.lua` (`git show --stat` on each), the suite is
**968 successes / 0 failures / 0 errors / 10 pending** (re-run locally), and
the reservation-by-reservation, combo-string, FPS-overlay, never-consumes and
shutdown-guard checks all confirm equivalence with the pre-image
(`f31bd312^:src/controller/controller.lua`). No findings at any severity.

## What was verified clean

**Check 1 — reservation-by-reservation equivalence.** Full before/after diff
(`f31bd312^` vs current) read in one pass. Nine keypressed reservations plus
the keyreleased one, each traced from old predicate/state condition to new
combo-string key and guarded body:

| combo | old site | new fn (controller.lua) | guard |
|---|---|---|---|
| `ctrl+t` | `quickswitch()` | `reserved_quickswitch` L780 | `if playback then return end` |
| `ctrl+pause` | `project_state_change()` (`k=="pause"`) | `reserved_suspend` L797 | playback-guarded |
| `ctrl+q` | `project_state_change()` (`k=="q"`) | `reserved_quit` L802 | playback-guarded |
| `ctrl+s` | `project_state_change()` (`k=="s"`, state check inside) | `reserved_stop_run` L807 | playback-guarded, `app_state=='running'` check preserved |
| `ctrl+shift+r` | `project_state_change()` (`only_mods(T,F,T)`, `k=="r"`) | `reserved_reset` L814 | playback-guarded |
| `ctrl+alt+r` | `restart()` | `reserved_restart` L821 | **unguarded** |
| `ctrl+alt+p` | `profile()`, ctrl+alt+p, no shift | `reserved_profile_start` L825 | `love.PROFILE` only |
| `ctrl+alt+shift+p` | `profile()`, ctrl+alt+p, shift held | `reserved_profile_stop` L830 | `love.PROFILE` only |
| `f10` | `profile()` fpsc if/elseif | `reserved_overlay` L835 | `love.PROFILE` only |
| `ctrl+escape` (release) | `keyreleased` inline `only_mods(T,F,F)+escape` | `RESERVED.keyreleased['ctrl+escape']` L865 | unguarded (matches old, which was never playback-split) |

`quickswitch`'s nested `if/elseif` with no trailing `else` inside the
`editor` branch was rewritten as `elseif st=='editor' and is_normal_mode()`
— behaviourally identical since the old inner `if` had no `else` either
(controller.lua:789-790 vs pre-image).

The `ctrl+alt+p`/`ctrl+alt+shift+p` split deserves a note: the *old* code
did not call `only_mods()` for this pair, it read `Key.ctrl() and Key.alt()`
directly and branched on `Key.shift()` — but since ctrl/alt/shift are the
only three modifiers `combo_string` ever encodes, that raw check was already
exact given `k=="p"`. Mapping it onto two exact combo-string keys changes
representation, not behaviour.

**Check 2 — playback narrowing (checked hardest).** Old code ran `restart()`
and `profile()` (start/stop/overlay) unconditionally in **both** the
`playback` and dev branches, and `quickswitch()` + `project_state_change()`
(suspend/quit/stop_run/reset) in the **dev branch only**
(pre-image, `handlers.keypressed`, the `if playback … else …` split).

Guarded set in the rewrite (`if playback then return end`):
`reserved_quickswitch, reserved_suspend, reserved_quit, reserved_stop_run,
reserved_reset` — exactly the 1 (quickswitch) + 4 (project_state_change
sub-cases) that were dev-only.

Unguarded set: `reserved_restart, reserved_profile_start,
reserved_profile_stop, reserved_overlay` — exactly restart() (1) +
profile()'s three sub-cases, the both-branches set.

The two sets partition the nine keypressed reservations exactly along the
old dev-only / both-branches line. `input_shortcuts_click_spec.lua:64`
(`#play mode narrows the active shortcut set`) exercises `ctrl+alt+r`
(expects `calls.restart == true`) and `ctrl+q` (expects `calls.quit == nil`)
in a stub with `cfg.mode = 'play'` — passes. No second mistake found here.

**Check 3 — f10 overlay, no-else preserved.** `FPSC_CYCLE` (controller.lua
~L424) has no `off`-catchall entry; `reserved_overlay` (L835-839) does
`local nxt = FPSC_CYCLE[love.PROFILE.fpsc]; if nxt then love.PROFILE.fpsc =
nxt end` — an unrecognised `fpsc` value yields `nxt == nil` and the field is
left untouched, exactly the old if/elseif chain's behaviour (no `else`
clause existed).

**Check 4 — never consumes.** Every `reserved_*` function is either a bare
statement sequence or ends on early `return` with no value; the call sites
(`if reservation then reservation() end`, L877 and L901) discard whatever a
reservation returns. Both handlers unconditionally forward to
`love.keypressed`/`love.keyreleased` afterward (L888-890, L902-904),
regardless of whether a reservation fired — unchanged from before.

**Check 5 — playback shutdown guard.** `if playback and love.state.app_state
== 'shutdown' then love.event.quit() end` (L873-875) runs before the
`RESERVED.keypressed` lookup, on every key, condition byte-for-byte the same
predicate the old code had nested one level inside `if playback then`.
Correctly excluded from the table, as required.

**Check 6 — no test edited.** `git show --stat` on both commits: only
`src/controller/controller.lua` in each. `busted tests` locally:
`968 successes / 0 failures / 0 errors / 10 pending`. The pending list is
the same 10 outlines as before (7 `#input reserved combos, own effect not
yet asserted` rows in `input_global_shortcuts_spec.lua` + 3 routing-mode
outlines in `input_routing_spec.lua`) — none newly added, none removed.

**Check 7 — Decision 34's own requirements.** `RESERVED` (L850-867) is a
`local` table scoped to `setup_callback_handlers`, never merged with or
derived from a project's `compy.input.shortcuts` (that table lives entirely
in `projectInputController.lua`, consumed via a different mechanism —
confirmed no cross-reference either way). The never-consumes contract is
stated in a comment directly above the table declaration (L841-849), at the
table as required, not only in the decision doc.

**Check 8 — combo_string without the table.** Traced by hand for 0/1/2/3
modifiers: old `table.concat(parts, '+')` and new `combo .. m[3] .. '+'`
accumulation produce identical strings at every arity (e.g. two modifiers:
old `{'ctrl','alt',k}` → `"ctrl+alt+"..k`; new `combo` becomes
`"ctrl+"`→`"ctrl+alt+"`, then `.. k` — same string). `grep -n "only_mods\|
parts\b" src/controller/controller.lua` returns nothing — no leftover
references to the deleted predicate or the deleted table.

**Check 9 — hygiene.** No line in the two commits' added/changed hunks
exceeds 64 columns (checked the whole file for >64-char lines; all hits are
pre-existing comment lines outside the changed regions). Function bodies:
the largest, `reserved_quickswitch`, is 14 lines (L781-794), at the limit,
not over it; all others are 1-4 lines. Zero parameters on every `reserved_*`
function. Max nesting inside `reserved_quickswitch` is 3 levels. Comments
cite canonical `doc/development/decisions/…` and `doc/development/
technical_debt/…` paths, no `wip/` references. LSP diagnostics
(`mcp__lua-lsp__diagnostics` on `controller.lua`): 21 hits, all pre-existing
(unused locals, LÖVE dynamic-field warnings on `love.textinput` etc.,
redundant-parameter on stock LÖVE callback signatures) and none inside the
changed region beyond what already existed — none attributable to this
diff.

## Unprompted: RESERVED rebuilt per `setup_callback_handlers` call

Correct, and cheaper than before, not more expensive. `setup_callback_
handlers` is called exactly once in production (`src/main.lua:385`, during
app boot) — so `RESERVED` and its ~11 closures are built once per process
lifetime, closing over that single call's `CC`/`playback`, which are
invariant for the app's lifetime. In tests it's called once per test that
needs a fresh stub, each call correctly isolated.

This is actually a reduction in allocation churn versus the pre-image:
the old `quickswitch`/`project_state_change`/`restart`/`profile` closures
were declared **inside** `handlers.keypressed`'s function body, so they were
reallocated on **every keypress event**. The rewrite moved allocation from
per-keypress to per-setup-call. Nothing that matters is spent here either
way, but if anything the change is a minor win, not a cost.

## What could not be checked

Nothing material. The full pre/post diff for both commits was read in
whole; every reservation's trigger, modifier set, state condition and
effect was traced by hand against the pre-image; the suite was re-run
locally rather than taken on faith.
