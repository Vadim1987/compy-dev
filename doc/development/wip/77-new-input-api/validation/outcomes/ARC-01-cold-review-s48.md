# ARC-01 cold review (session 48) — the per-run project widget

Reviewed commits (top of `feature/77-newapi-analysis-s20260615` at review time):

```
e684458b  feat(input): compy.input resolves the widget's stores instead of capturing them
314fca05  feat(input): the project widget is built at the run seam and dropped at the stop
e28a20f6  docs(decisions): amend Decision 3 for a per-run widget, scope Decision 7's "frozen"
```

Cold review: no access to ROADMAP.md, session48 implementation notes, or the
ARC-01-01/03 validation notes/ledger drafts. Verified everything below directly
against `src/`, `tests/`, the ratified `doc/development/decisions/input.md`,
`doc/development/internals/user_input.md`, and the PR base `3256aac`.

## Verdict

**Approve.** The lifetime mechanism is correct at every seam I could reach —
built once per run, destroyed once at the run's end, resolved dynamically
everywhere it's read — and both of its headline claims are backed by tests
that I confirmed are load-bearing by breaking the corresponding production
code and watching them fail. The one real defect is non-blocking: a piece of
now-dead teardown code with a comment that flatly contradicts what this PR
just did. I'd fix it before or shortly after merge, but it doesn't justify
holding the PR.

## Findings

### 1. Dead teardown code + a comment that states the pre-PR premise as current fact (verified, low severity)

`reset_widget_outputs()` (`src/controller/controller.lua:348-358`) and the two
`UserInputController` methods it exclusively calls — `reset_callbacks`
(`userInputController.lua:481`) and `clear_pending` (`userInputController.lua:492`,
confirmed via grep as their only call site) — are reached from exactly one
place: `clear_user_handlers` (`controller.lua:1066-1072`). `clear_user_handlers`
in turn is called from exactly two places, both in `consoleController.lua`:

- `stop_project_run` (line 1412), three lines after `destroy_input_widget()` (line 1409)
- the failed-top-level-code path in `run_project` (line 348), seven lines after `destroy_input_widget()` (line 341)

`destroy_input_widget()` unconditionally sets `love.state.user_input_controller
= nil`. `reset_widget_outputs` opens with:

```lua
local ui = love.state.user_input_controller
if not ui then return end
```

Since both callers destroy the widget first, `ui` is always `nil` by the time
`reset_widget_outputs` runs, so its body (re-seed callbacks to stay-open
defaults, clear the pending draft, clear `custom_label`/`highlighter`) never
executes. **Verified, not suspected:** I diffed against this branch's
immediate parent (`f1cfa852`, before all three reviewed commits) — at that
point `stop_project_run` called `hide_input_widget()` (hide only; the widget
was still the single boot-provisioned instance), so `reset_widget_outputs`
ran against a live widget and was load-bearing — it was *the* mechanism that
prevented one project's output state leaking into the next. Commit
`314fca05` swapped that one call to `destroy_input_widget()` (correctly — the
whole point of the row) but left the `reset_widget_outputs` call chain
sitting downstream, now permanently inert.

This is not a behavioral bug: a freshly built widget already carries clean
defaults (`default_callbacks()` in `userInputController.lua`), so nothing
leaks — the structural fix (destroy-and-rebuild) subsumes the manual wipe.
But the comment directly above `reset_widget_outputs`
(`controller.lua:339-347`) ends with *"...and the widget is one
application-lifetime instance"* — the exact premise Decision 3's amendment
overturns. Left as-is, a future reader has no signal that this function is
dead, and the comment actively asserts something this PR proves false.

**What I'd do:** delete `reset_widget_outputs` (and `reset_callbacks`/
`clear_pending` if nothing else calls them — confirmed nothing else does) and
its call in `clear_user_handlers`, or at minimum correct the comment and add
a note that the call is now a no-op kept only for [reason], if there's a
forward-looking reason to keep it (e.g. a planned adopter that reuses the
widget across shows without destroying it). I did not find such a reason in
the current code.

### 2. Minor: commit e28a20f6 miscounts its own citation sweep (cosmetic)

The commit message claims "All 13 Decision 3 citations in src/ and tests/
cite the number, not the heading." I grepped `src/` and `tests/` for
`Decision 3\b` (excluding `Decision 3\d`) and count **12**, not 13: `main.lua`
(1), `consoleController.lua` (3), `userInputController.lua` (1),
`input_nfr_mechanism_spec.lua` (1), `input_route_lifecycle_spec.lua` (3),
`input_fixture.lua` (3). The substantive claim holds regardless — every one
of the 12 cites the number, not the old heading text, so none dangles — the
count itself is just off by one. Not worth a follow-up commit on its own.

### 3. Pre-existing, out-of-scope: another "boot-provisioned" comment, untouched by this PR

`src/view/input/userInputView.lua:288-291`, the comment above
`UserInputView:draw()`, still calls the currently-published input widget
"the boot-provisioned input widget." That's no longer accurate for the
project widget. This file is not part of any of the three reviewed commits
(not in their diffs), so this predates the PR and the PR wasn't obligated to
touch it — flagging only because the review brief specifically asked about
stale "boot-provisioned" language, and this is one more instance of it,
elsewhere.

## What I checked and found sound

**Every run/stop seam.** Walked and verified in code (all in
`consoleController.lua` unless noted):

- `run_project` (success path): `build_input_widget(self.cfg)` runs after
  `app_state = 'running'` and before `run_user_code(f, ...)` — so the
  project's top-level code always sees a live widget, including on its first
  line. Re-entrancy is guarded (`app_state == 'inspect' or 'running'` bails
  early), so a run can't double-build.
- `run_project` (top-level raise): `release_keyboard_route` then
  `destroy_input_widget()` runs before `clear_user_handlers`, so a widget the
  raising code managed to show first is still torn down. Confirmed by the
  passing test `'leaves no input widget behind'`
  (`input_route_lifecycle_spec.lua`), which now asserts
  `love.state.user_input_controller == nil` (strengthened from the old
  `is_shown() == false`).
- `stop_project_run`: `destroy_input_widget()` runs *after*
  `framework_before_exit(compy)`, so the project's own `before_exit` hook can
  still legally drive `compy.input` — verified by reading
  `framework_before_exit`'s call to `compy.before_exit` and confirming the
  ordering (`destroy_input_widget()` at line 1409, `framework_before_exit` at
  line 1403).
- `quit_project` → `stop_project_run`: no separate widget handling; inherits
  the above.
- `restart()` → `stop_project_run()` + `run_project()`: destroys then
  rebuilds; `run_project`'s re-entrancy guard doesn't block it because
  `stop_project_run` always leaves `app_state = 'project_open'`.
- `suspend()`/`suspend_run` (→ `'inspect'`): does **not** touch the widget at
  all — only `Controller.project_input:deactivate()` (detaches routing) and
  handler save/restore. The widget stays alive and resolvable through the
  whole `'inspect'` session, matching the requirement that a suspended run's
  widget must survive. `project_env.continue()` (resume) likewise never
  touches it. `project_env.run()` from `'inspect'` (a full restart, not a
  resume) does `stop_project_run(); run_project()` — destroy-then-rebuild,
  same as `restart()`.
- Non-blocking projects settling in `'project_open'` (sapper is the concrete
  example — confirmed the example exists at `src/examples/sapper`): the
  non-blocking branch of `run_project` (`if not
  self.main_ctrl.user_is_blocking() then love.state.app_state =
  'project_open' end`) does not call hide/destroy on anything. The passing
  test `'a non-blocking run keeps its widget at project_open'` confirms this
  directly.
- Ctrl+T quickswitch (`controller.lua`, `reserved_quickswitch`): traced by
  hand — `running`/`inspect`/`project_open` → `stop_project_run()` (destroy)
  then `edit()`; `editor` (normal mode) → `finish_edit()` then
  `run_project()` (rebuild). I additionally built a throwaway, uncommitted
  probe spec that drove the real `ConsoleController` through
  `Controller.setup_callback_handlers` + `mock.keystroke('C-t', ...)` and
  confirmed the first half empirically: `app_state` flips to `'editor'` and
  `love.state.user_input_controller` becomes `nil`. The reverse half
  (editor → running rebuild) hit an unrelated fixture gap (the shared
  `F.run_project` helper resets `P.current` to `nil` on return, and
  `CC.editor:finish_edit()` needs editor-state fields the minimal stub
  didn't have) — I did not force it through, so that half is verified by
  code-reading and by reuse of `run_project()`'s own five passing lifetime
  tests, not by a direct empirical run. The probe file was deleted and
  `git diff` on `src/`/`tests/` is empty.

**No remaining capture of the old widget.** Grepped `user_input_controller`,
`widget.callbacks`, `widget.pending` across `src/`. The only places
`love.state.user_input_controller` is read are: resolved fresh per call
(`get_widget`/`widget_store`/`get_active` closures in `consoleController.lua`,
`_dispatch` in `projectInputController.lua`), or resolved fresh per frame
(`userInputView.lua:294`, inside `draw()`). LSP `references` on
`reset_widget_outputs` and `clear_user_handlers` under-reported (missed the
two production call sites in `consoleController.lua`, matching the
CLAUDE.md warning that Lua LSP refs can be incomplete) — grep caught what the
LSP missed, and I cross-checked both.

**Nil-widget guards.** `merge_callback_keys`, `consume_pending`,
`stash_hidden_configure`, `widget_store`, `get_active`, all five
`build_widget_api` methods, and `dispatch()`'s `if widget and
widget:is_shown()` all treat "no widget" as "nothing to do," never a raise.
Confirmed by the passing test `'with no widget there is no store, and no
raise'`. I looked specifically for a path where a raise here would be
swallowed by `with_canvas_and_errors`/`suspend_run` (the masking the review
brief warned about) rather than failing a test, and didn't find one — every
reachable reader on the dispatch path is guarded.

**Decision 7's frozen-container / writable-leaf contract still holds** for
`callbacks` specifically: `compy.input.callbacks = {}` still raises (the
container's `__newindex` refuses every key unconditionally), while
`compy.input.callbacks.on_text_entered = fn` succeeds by writing straight
onto the live widget's table — read via `build_input_surface`'s special-cased
`if k == 'callbacks' then return state.callbacks end`, distinct from the
generic `resolve` table for `shortcuts`/`hooks`/`fn`.

**Allocation claim, verified against `3256aac`.** The PR-base
`input_text`/`input_code` path (superseded API, not `compy.input`) built a
fresh `UserInputModel` + `UserInputController` + `UserInputView` on every
`input()` call (`consoleController.lua:565-576` at `3256aac`), gated only by
"no other one currently shown." Per-run construction is strictly less
allocation than that, as Decision 3's amendment claims.

**Rewritten tests are not vacuous.** Read every rewrite in `314fca05`'s test
diff. The callback/hooks-survive-teardown cases still assert a real
guarantee — now phrased across the run boundary (`next_run.callbacks.X is
nil` after a fresh `F.activate_project()`) rather than "wiped on the same
object in place" — and one case (`'leaves no input widget behind'`) was
strengthened, not weakened, from `is_shown() == false` to
`user_input_controller == nil`.

**Mutation-tested both headline claims directly**, via temporary `Edit`
changes to `src/controller/consoleController.lua`, restored after each
(`git diff` clean afterward, confirmed with `git status --short`):

- Reverting the stop seam from `destroy_input_widget()` back to the old
  `hide_input_widget()` → 4 failures, all in `input_route_lifecycle_spec.lua`
  (lines 101, 146, 256, 263).
- Reverting `compy.input.callbacks` from resolve-per-access back to a
  captured-once local → 17 failures across `input_nfr_mechanism_spec.lua`,
  `input_route_lifecycle_spec.lua`, `input_widget_callbacks_spec.lua`, and
  `input_widget_control_spec.lua`.

**Suite.** `busted tests` → `978 successes / 0 failures / 0 errors / 10
pending`, matching the stated baseline exactly, both before and after my
probing.

**House rules.** No `INTERIM:`/`REMARK:` markers in the diff. No line over 64
chars, no function body over 14 lines, no function over 4 params in the added
code (spot-checked `build_input_widget`, `destroy_input_widget`,
`widget_store`, and the diff's added lines by line-length sweep).

## Could not determine

- **Ctrl+T's editor→running half**, empirically — see above. Code-reading
  says it's correct (it's the same `run_project()` already covered five ways
  over), but I couldn't force a clean empirical run through the shared test
  fixture in the time I spent on it. Settling this needs either a fixture
  extension (stub whatever `editorController.lua:218`'s `.system` field
  needs) or a manual `xvfb-run love src` pass through both quickswitch
  directions.
- **Whether finding #1 (dead `reset_widget_outputs`) was already known and
  deliberately deferred.** I have no visibility into session48's own notes
  (out of scope for a cold review) — it's possible the author already flagged
  this and chose not to act on it in this row, the same way Decision 3's
  stale heading was explicitly deferred in `e28a20f6`. Worth a direct
  question rather than assuming it's an oversight.
