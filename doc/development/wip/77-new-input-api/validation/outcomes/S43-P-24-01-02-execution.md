# P-24-01 + P-24-02 — outcome

Commits: `737d8316` (P-24-01) and `f31bd312` (P-24-02). Branch
`feature/77-newapi-analysis-s20260615`. Not pushed. Both touch only
`src/controller/controller.lua`, staged explicitly by path.
`src/controller/projectInputController.lua` is untouched — see
"find_shortcut's double build" below for why.

## P-24-01 — `combo_string` stops allocating (`737d8316`)

`combo_string` (`src/controller/controller.lua`) built a `parts`
table and `table.concat`'d it per call. Rewritten to concatenate a
string accumulator directly over the three `COMBO_MODS` rows — no
table, no module-level buffer, so no reentrancy hazard to comment
around. Output is byte-for-byte the same (same precedence walk,
same trailing trigger). The `--- NOTE:` above it, calling the
allocation "an open design question", is replaced with a line
stating there is no longer one; the technical_debt.md entry it cited
("Combo-string dispatch allocates a table per call") is left for the
parent session to retire, per the prompt.

Suite after this commit: **968 / 0 / 0 / 10**, zero tests edited.

## P-24-02 — the reservation table (`f31bd312`)

`only_mods(ctrl, alt, shift)` is deleted. The gate's two handlers
(`handlers.keypressed`, `handlers.keyreleased` inside
`setup_callback_handlers`) now look up one canonical combo string in
`RESERVED.keypressed` / `RESERVED.keyreleased` — a table built fresh
per call to `setup_callback_handlers` (so it can close over that
call's `CC` and `cfg`), keyed by the same combo strings a project
writes into `compy.input.shortcuts`.

**All nine reservations carried over as separate named functions,**
one per combo, each replacing the surrounding `if`/`elseif` it used
to sit inside:

| Combo | Function | State condition moved inside |
|---|---|---|
| `ctrl+t` | `reserved_quickswitch` | `playback`, then the `app_state` running/inspect/project_open vs `editor` branches |
| `ctrl+pause` | `reserved_suspend` | `playback` |
| `ctrl+q` | `reserved_quit` | `playback` |
| `ctrl+s` | `reserved_stop_run` | `playback`, then `app_state == 'running'` |
| `ctrl+shift+r` | `reserved_reset` | `playback` |
| `ctrl+alt+r` | `reserved_restart` | none (ran in both branches before) |
| `ctrl+alt+p` | `reserved_profile_start` | `love.PROFILE` |
| `ctrl+alt+shift+p` | `reserved_profile_stop` | `love.PROFILE` |
| `f10` | `reserved_overlay` | `love.PROFILE` |
| `ctrl+escape` (release) | inline `function() love.event.quit() end` | none (unconditional before too) |

**`playback` (`cfg.mode == 'play'`) is a state condition the prompt
and the two prior analysis docs did not name**, but it was load-
bearing in the original code: the old `if playback then restart();
profile() else restart(); quickswitch(); profile();
project_state_change() end` split meant five of the nine
reservations (quickswitch, suspend, quit, stop-run, reset) never ran
during playback, while restart and the three profiler/overlay
reservations ran in both branches. That split is preserved — each
of the five checks `if playback then return end` as its first line,
mirroring how `app_state`/`love.PROFILE` moved inside per the
prompt's instruction. This is exercised live by
`tests/input/input_shortcuts_click_spec.lua`'s `'#play mode narrows
the active shortcut set'` test, which stayed green with **no edit**
and is as much a proof of equivalence here as the fifteen-plus in
`input_global_shortcuts_spec.lua`.

One more non-combo effect had to stay outside the table entirely:
in playback mode, `if love.state.app_state == 'shutdown' then
love.event.quit() end` used to run unconditionally at the top of
`handlers.keypressed`, on **every** key, not one combo — it cannot
be a table entry by construction (no combo to key it on), so it
stays as a guard clause ahead of the reservation lookup, unchanged.

**FPS-overlay cycle.** The five-armed `if/elseif` chain stepping
`love.PROFILE.fpsc` became a lookup table (`FPSC_CYCLE`, module-
level, next to `MOD_HELD`) plus one `if nxt then ... end`. Checked
the one behavior that is easy to get wrong here: the old chain did
**nothing** when `fpsc` held a value outside the five named ones (no
`else` arm); `FPSC_CYCLE[unknown]` is `nil`, and the `if nxt`
guard preserves that "leave it alone" behavior rather than falling
back to `'off'`.

**The privileged-table requirements, verified against the diff:**
- `RESERVED` is its own local, distinct in shape and name from
  `compy.input.shortcuts` (which lives on the frozen project-env
  container, not in this file at all).
- The comment directly above `RESERVED` states the never-consumes
  contract in the vocabulary the prompt specified — "a project's
  entry CONSUMES the key by returning truthy; a reservation NEVER
  CONSUMES" — and that the key still reaches the route afterward.
- Both handlers carry a table; Ctrl+Escape is in
  `RESERVED.keyreleased`, on the release side, matching the original.

Suite after this commit: **968 / 0 / 0 / 10**, zero tests edited
(confirmed by `git status`/`git diff` touching only
`controller.lua`, and by rerunning `busted tests` after the commit).

**One pre-existing test comment now names a removed identifier:**
`tests/input/input_global_shortcuts_spec.lua:208` reads "...the
run-stop reservation becomes exact (only_mods)..." — a comment
from the P-23-02 step, referencing the predicate this step deletes.
It requires no edit for the suite to pass (comments don't execute),
so per the proof rule I left it untouched rather than editing a test
file; flagging it here as drift for whoever next touches that file.

## Device reads, counted (not estimated)

**At the gate**, per keypress/keyrelease: exactly **3** — one
`combo_string(k)` call, which walks `COMBO_MODS` (ctrl, alt, shift)
once via `MOD_HELD[m[3]]()`. This is now a *fixed* cost, not a
worst-case one: before, the cascade called `only_mods` up to seven
times in `handlers.keypressed` alone (each three reads) plus two
bare `Key.ctrl()/Key.alt()` reads in `profile()`, for up to
**23** reads on the branch that reached every predicate; now it is
always 3 regardless of which combo (or none) matches.

**At the route** (`find_shortcut` in `projectInputController.lua`,
reached from `ProjectInputController:dispatch` for the `keypressed`/
`keyreleased` channel), unchanged by this work:
- **3** on an exact-combo hit — one `combo_string(trigger)` call.
- **6** on a miss that falls through to the `'*'` class check — two
  `combo_string` calls (exact, then `'*'`), each walking all three
  modifiers again.

So one keypress that misses every project shortcut costs **3 (gate)
+ 6 (route on a miss) = 9** device reads total; one that hits an
exact project shortcut costs **3 + 3 = 6**.

## `find_shortcut`'s double build: not fixable within the rules

Left unchanged, and `projectInputController.lua` is not touched by
either commit. `find_shortcut` calls `Controller.combo_string`
twice on a miss — once for the exact trigger, once for `'*'` — and
both calls redo the identical three-modifier walk; only the trailing
token differs. Reusing the first walk's result would need one of:

- **A parameter or extra return on `combo_string`** exposing the
  modifier prefix separately (e.g. returning `combo, prefix`, or
  taking a precomputed prefix) — explicitly ruled out by the prompt
  ("without adding shared state or a parameter to `combo_string`'s
  public shape").
- **Shared/cached state** (a module-level "last prefix" or the
  cached-combo idea `S43-P-24-00b-table-and-sharing.md` already
  rejects for the gate/route sharing question, item 3) — same
  staleness problem one level down: `find_shortcut` is reachable
  directly in tests and from any adopter's own instance
  (`projectInputController.lua:118-124`'s stated design), so a
  cached prefix would need its own invalidation story for no
  measured benefit.
- **A second, independent modifier-prefix helper** duplicating
  `combo_string`'s loop outside it — avoids touching `combo_string`'s
  signature, but forks the one place Decision 8's precedence is
  encoded into two, which is a correctness liability of its own for
  the code this task is trying to make *more* trustworthy, not less.

None of the three is available without touching what the prompt
fenced off. The double build stays: 6 device reads on a route-side
miss, same as before this task, and orthogonal to the gate's cost
(which dropped from up to 23 to a flat 3).

## Suite arithmetic

| Point | Suite |
|---|---|
| Baseline (before this task) | 968 / 0 / 0 / 10 |
| After P-24-01 (`737d8316`) | 968 / 0 / 0 / 10 |
| After P-24-02 (`f31bd312`) | 968 / 0 / 0 / 10 |

Pending count 10 throughout; `git diff` on both commits touches only
`src/controller/controller.lua`, confirming the seven file-local
`pending(...)` outlines are untouched and no test file changed.

## Not anticipated by the prior analysis

- **`playback`/`cfg.mode == 'play'` is a fourth state condition**
  that needed moving inside reservation functions, alongside the
  three the prompt named (`app_state == 'running'`, `love.PROFILE`,
  the editor/running branches). Neither
  `S43-P-24-00-only-mods-api.md` nor
  `S43-P-24-00b-table-and-sharing.md` mentions play-mode narrowing;
  it only surfaced from reading `setup_callback_handlers` itself and
  cross-checking `input_shortcuts_click_spec.lua`'s `'#play mode
  narrows the active shortcut set'` test. Missing it would have made
  `restart`/`ctrl+alt+p`/`ctrl+alt+shift+p`/`f10` correct but
  `quickswitch`/`suspend`/`quit`/`stop_run`/`reset` fire in playback
  when they must not — a real behavior change the fifteen-plus
  `input_global_shortcuts_spec.lua` cases would **not** have caught,
  since none of them sets `cfg.mode = 'play'`. That test file's
  narrow-play-mode row is the only thing in the suite that exercises
  this path, which makes it as load-bearing to this step as the
  fifteen-plus cases the prompt names.
- **The playback-mode unconditional shutdown-quit check** (`if
  love.state.app_state == 'shutdown' then love.event.quit() end`,
  keyed to no combo at all) doesn't fit a combo-keyed table by
  construction and had to stay as a guard ahead of the lookup —
  worth flagging since Decision 34's text describes the gate
  becoming "a table" without carving out this one non-combo
  exception.
- The FPS-overlay chain's "no `else`, so an unknown `fpsc` value is
  left alone" behavior was easy to lose converting to a lookup table
  (an `or 'off'` fallback would have been the natural-looking but
  wrong translation); confirmed by reading the original chain's
  five arms with no trailing `else` rather than assuming a table
  rewrite is automatically equivalent.
