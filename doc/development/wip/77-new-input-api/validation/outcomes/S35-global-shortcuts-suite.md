---
description: New suite tests/input/input_global_shortcuts_spec.lua — a project cannot suppress a global/platform shortcut by naming the same combo; enumeration verification and the pending-count reconciliation the owner's scope correction requested
status: complete
audience: developer
authored: llm
reviewed: none
---

# S35 — global shortcuts suite

## Scope actually delivered (owner correction applied mid-task)

The briefing (`S35-global-shortcuts-suite.md` prompt) originally asked for a
live "the effect happens" case per reserved combo (claim A) plus the
suppression claim (claim B) plus a non-consumption claim (claim C). Partway
through, the coordinator relayed an owner scope correction: claim A is
**cancelled as live tests** — the framework's own effects are not this PR's
duty, only the one thing nothing tests today: **a project cannot suppress a
platform combo by naming it**. Claim A survives only as named `pending` rows,
one per reserved combo, and claim C folds into claim B's route-destroying
cases (documented in a comment, not a separate assertion). That correction is
what shipped; the paragraphs below describe the final shape, not the
originally-briefed one.

## What's in the file

`tests/input/input_global_shortcuts_spec.lua`, `#input` tagged, built on the
shared `input_fixture`/`input_session` helpers exactly like its siblings.

**Two live tests** (`describe 'a project cannot suppress a platform combo'`):

1. **`ctrl+pause` — route-preserving.** A project registers
   `input.shortcuts.keypressed['ctrl+pause']` returning `true` (a normal
   "consume" signal). Fired via `F.session.press('lctrl')` +
   `F.session.press('pause')`. Both the platform effect
   (`love.state.app_state == 'snapshot'`) and the project's own binding ran —
   proof the platform effect isn't gated on nothing else having claimed the
   combo.
2. **`ctrl+q` — route-destroying.** Same registration pattern on `ctrl+q`.
   `quit_project` tears the project route down (`stop_project_run`
   reinstalls the console's own `love.keypressed` before the gateway's
   `if love.keypressed then return love.keypressed(...) end` line runs), so
   the project's own binding **never fires** — asserted explicitly
   (`project_ran` stays `false`), with a comment stating this is the route
   disappearing, not suppression: the project could not have blocked the
   quit either way, which is the same claim, argued from the other side.

Two combos, one from each side of the route-preserving/route-destroying
split, per the owner's "prefer at least one of each" guidance. `ctrl+t`
(quickswitch) was considered as a third (also route-destroying, and it's the
combo the briefing itself named as the example) but left out — `ctrl+q`
already carries the destroying-side argument, and a second same-shaped case
would have been the exact kind of bloat both the original briefing and the
correction warn against.

**`ctrl+pause` and `ctrl+q` are intentionally absent from the pending list**
below: their own platform effect is asserted live by these two tests already
(`app_state == 'snapshot'` / `== 'project_open'`), and `ctrl+pause`'s is also
asserted independently in `input_shortcuts_click_spec.lua`. Listing them
again as pending gaps would misstate what the suite covers.

**Seven pending rows** (`describe 'reserved combos, own effect not yet
asserted'`), one per remaining reserved combo, each a bare
`pending('one-line effect')` with no test body, matching the house style at
`input_routing_spec.lua:69,145,215`:

- `ctrl+alt+r` restarts the current project
- `ctrl+t` quickswitches run ↔ editor
- `ctrl+alt+p` / `ctrl+alt+shift+p` start/stop the oneshot profiler
  (love.PROFILE gated) — combined into one row; same gate, same local
  function, mirror-image effect
- `f10` cycles the FPS-corner overlay (love.PROFILE gated) — carries the
  enumeration disagreement below as its comment
- `ctrl+s` stops a run, or saves/closes an editor buffer, depending on
  `app_state` — one row for one combo; the three state-dependent branches
  are noted in the one line rather than split into three rows
- `ctrl+shift+r` resets: quits and wipes console history
- `ctrl+escape` (release) asks love to quit — distinct from the two
  already-tested `Ctrl+Esc` cases in `project_open_liveness_spec.lua`, which
  exercise the `love.quit()` **callback**'s abort/no-abort logic directly;
  this row is about the gateway's `keyreleased` handler actually invoking
  `love.event.quit()` in the first place, which nothing exercises today

## Enumeration verification

Read `src/controller/controller.lua:780-915` (`setup_callback_handlers`,
`handlers.keypressed` and `handlers.keyreleased`) in full against the
enumeration handed down from the parent session. Every clause matched the
code **except one**:

**Disagreement: `f10` has no modifier gate at all.** The enumeration states
item 3 as "`k == 'f10'` with NO modifier at all". The code (`profile()`,
`controller.lua:844-866`) has two independent `if` blocks: one gated on
`Key.ctrl() and Key.alt() and k == "p"` (the `p` combos), and a **second,
unconditional** `if k == "f10" then ... end` with no modifier check
whatsoever — not even a check that *no* modifier is held. Holding Ctrl (or
any other modifier) while pressing F10 still cycles `love.PROFILE.fpsc`. The
enumeration's "with NO modifier at all" reads as a description of the
*expected* or *typical* binding shape, not what the source does. Recorded as
the `f10` pending row's comment so it isn't lost, but not asserted live
(claim A is out of scope per the correction).

Everything else — `restart()`'s exact condition, `quickswitch()`'s three
`app_state` branches and their calls, `profile()`'s `p`/`shift+p` split, all
four `project_state_change()` branches (`pause`, `q`, `s`'s
running/editor/shift split, `shift+r`), the playback-mode narrowing
(`restart()` + `profile()` only, plus the `shutdown` quit), and the
`keyreleased` `ctrl+escape` → `love.event.quit()` line — matched the code
exactly, including which effects run under `Key.ctrl()` versus which need an
additional `Key.shift()`/`Key.alt()`.

## Route-preserving vs. route-destroying, as found

| Combo | Effect | Category |
|---|---|---|
| `ctrl+pause` | `suspend_run` (sets `app_state`/`suspend_msg` only) | preserving |
| `ctrl+alt+p` / `ctrl+alt+shift+p` | `Prof.start_oneshot`/`stop_profiler` | preserving |
| `f10` | cycles `love.PROFILE.fpsc` | preserving |
| `ctrl+q` | `quit_project` → `stop_project_run` + `close_project` | destroying |
| `ctrl+alt+r` | `restart` → `stop_project_run` + `run_project` | destroying |
| `ctrl+t` | `quickswitch` → `stop_project_run` + `edit`/`finish_edit`+`run_project` | destroying |
| `ctrl+shift+r` | `reset` → `quit_project` + history wipe | destroying |
| `ctrl+s` | `stop_project_run` (running) — destroying; `close_buffer`/`finish_edit` (editor) — not applicable, see below |

"Destroying" here means: `stop_project_run` (or a caller of it) reassigns
`love.keypressed`/etc. back to the console's own handler *before* the
gateway's own forwarding line runs, so a project's `compy.input.shortcuts`
entry on the same combo never gets dispatched to for that event — the walk
that would have reached it isn't the active `love.keypressed` by the time
the gateway checks.

**`ctrl+s`'s editor-mode branches (`close_buffer`/`finish_edit`) are outside
the route-preserving/destroying split entirely**, not merely uncategorized:
they only fire while `app_state == 'editor'`, a mode in which there is no
active *project* route to begin with (the project route only exists while
`app_state == 'running'`), so "can a project's own shortcut suppress this"
doesn't apply — there's no project shortcut table live to compete. Same
reasoning excludes the editor-mode combos generally from claim B's scope.

## What I could not test, and why

- **All seven pending rows** — by owner correction, not a limitation; see
  "Scope actually delivered" above.
- The `ctrl+alt+(shift+)p` profiler pending row's eventual test will need to
  drive the real `love.profiler` (`src/lib/profile.lua`), which installs
  `debug.sethook(profile.hooker, "cr")` on start. That hook must be
  explicitly cleared (`love.profiler.stop()`) before the test returns, or it
  keeps firing on every Lua call/return for the rest of the suite run —
  worth flagging for whoever picks the row up, since it isn't obvious from
  `Prof.start_oneshot`'s guarded wrapper alone.

## Suite totals

Baseline: 940 successes / 0 failures / 0 errors / 3 pending.

This file adds: 2 successes (the two live claim-B tests), 0 failures, 0
errors, 7 pending.

New total, confirmed by `busted tests`: **942 successes / 0 failures / 0
errors / 10 pending**. Also ran the new file standalone
(`busted tests/input/input_global_shortcuts_spec.lua`): 2 successes / 0
failures / 0 errors / 7 pending, consistent with the full-suite delta.

The pending count moving from 3 to 10 is deliberate and owner-approved (see
"Scope actually delivered"), not a regression — flagging per the
briefing's "pending count is tracked" instruction and the correction's
explicit request that this be stated for the parent to reconcile in the
commit message and `doc/development/tests.md`.

## Other observations, not acted on

- `tests/input/input_route_lifecycle_spec.lua` prints an `ERROR:
  compy.before_exit raised: ...boom` line to stderr during a full `busted
  tests` run (a deliberately-raised test fixture, not a real failure — the
  run's final tally is still 0 errors). Pre-existing, unrelated to this
  file; noted only because it's easy to misread in the console output while
  reviewing this change.
- No production code was touched. No existing test file was edited.
