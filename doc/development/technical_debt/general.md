---
description: Cross-cutting technical debt outside the input subsystem
status: active
audience: developer
authored: llm
reviewed: none
---

# General

Debt not tied to one subsystem — load-order/aliasing assumptions and shared-utility
semantics.

---

> REMARK: its not a defect, but convention -- gfx is alias for love.graphics, sfx is alias for compy.audio 

## `gfx` implicit global in `controller.lua`

- **Where:** `src/controller/controller.lua` — `set_love_update` / `set_love_draw` (and
  other drawing call sites in the same file) use `gfx`, a free variable not set in the file
  or any of its requires; it must exist at call time (set by the app's load sequence).
- **State:** Works because of load order, not because the file declares its dependency.
- **Why it stands:** Long-standing wiring assumption; changing it risks the load sequence
  for no behavioural gain.
- **Revisit:** When the controller's load/aliasing is next reworked — prefer a module-top
  `local gfx = love.graphics` per the standard-aliases convention.

## The test suite passes only in declaration order

- **Where:** the whole suite, not one file. `busted tests` is green; `busted tests --shuffle`
  fails 29–55 rows per run, varying with the shuffle. Concentrated in `input model spec`
  (~23 rows), `Editor #editor` (~10) and a few `Dequeue` rows, but the set is not stable
  between runs.
- **State:** pre-dates any current feature work. Checked against the PR base `3256aac`,
  before the input-API branch existed: **674/0/0/0 ordered, 29–48 failures shuffled** — the
  same condition at a third the suite size. So rows leak state into their successors
  somewhere below the per-file boundary busted insulates (`insulate` restores `_G` and
  `package.loaded` per spec file, not mutations to a required module's own tables).
- **Why it stands:** every run anyone makes — local, CI, `busted tests` — is in declaration
  order, so it costs nothing today. Finding the leaks is a suite-wide investigation across
  subsystems that no single feature owns, and it would be started for a property nothing
  currently depends on.
- **Revisit:** before enabling `--shuffle`, test sharding, or any parallel runner in CI —
  each of those turns this from dormant into a source of false failures. Also worth a pass
  whenever a subsystem's fixtures are next reworked, since the leaks are fixture-shaped.

## The console's terminal self-test is unreachable

- **Where:** `src/controller/consoleController.lua` — `terminal_test`'s opening guard,
  `love.state.app_state ~= 'ready' or love.state.app_state ~= 'project_open'`. A state
  cannot be both, so the disjunction holds for every value and the function always returns
  before its body.
- **State:** the whole feature is dormant. `Ctrl+Alt+T` in DEBUG does nothing;
  `util/test_terminal.lua` is never called, so `love.state.testing` is never set and its
  readers — the `'running'` / `'waiting'` branches in `ConsoleController:keypressed` and
  `src/view/input/statusline.lua` — cannot fire. Present at the PR base `3256aac`, so it
  pre-dates the input-API branch and no current work touches it. The intent reads as `and`.
- **Why it stands:** a developer-facing self-test with no caller in normal use; nothing
  observable regressed when it stopped running, which is why it went unnoticed. Fixing the
  operator re-animates a display path nobody has exercised in months — worth doing
  deliberately, with a look at the output it paints, rather than as a drive-by.
- **Revisit:** when the console's debug affordances or the terminal widget are next worked
  on. Fix is one operator; the work is confirming the revived path still renders sensibly.

## `table.protect(love.handlers)` is a no-op on the passed table

- **Where:** `src/controller/controller.lua` — end of `setup_callback_handlers`.
- **State:** `table.protect` returns a read-only proxy but does not mutate the original
  table; the call's return value is unused, so `love.handlers` is not actually protected.
- **Why it stands:** No observed breakage, and the proxy-vs-mutate semantics are a broader
  `util/table` question.
- **Revisit:** If/when read-only enforcement on `love.handlers` is actually wanted — either
  consume the returned proxy or change `table.protect`'s semantics.
