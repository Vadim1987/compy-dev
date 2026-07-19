# S15-TF1 consult verdict — input-fixture lifecycle (setup/teardown refactor)

Consulted: 2026-07-19. Baseline verified: `busted tests` = **815/0/0/4** (4 pendings,
2 of them at `tests/input/input_contracts_spec.lua:202` and `:268`).

## Headline finding — the threat model in the prompt is factually wrong, in a good way

Busted 2.3.0 (the installed runner) **insulates every spec file**: before a file's
chunk executes it snapshots all of `_G` *and* `package.loaded`, and after the file's
tests finish it restores both. Verified in source and by experiment:

- `busted.register('file', file, { envmode = 'insulate' })` —
  `/usr/local/share/lua/5.1/busted/init.lua:63`.
- `save()` / `restore()` — `/usr/local/share/lua/5.1/busted/context.lua:3-28`:
  restore rewrites every `_G` key back to its pre-file value **and** resets
  `package.loaded` to the pre-file snapshot (modules required inside a file are
  evicted afterward).
- File chunks are **not** all executed up-front at collection; each file's chunk runs
  lazily, immediately before its own tests
  (`/usr/local/share/lua/5.1/busted/block.lua:134-160`, `busted/init.lua:4-9`,
  registered via `test_file_loader.lua:85`). Only *compilation* happens up-front.
- Empirical probe (two scratch spec files): `_G.love` set in file A is `nil` when
  file B runs, and a module required in file A is re-required (re-executed) in
  file B. Confirmed.
- Empirical confirmation in-repo: `busted tests/input/project_open_liveness_spec.lua`
  passes standalone (4/0/0/0) — that file *already* builds its own private fixture:
  its `require('tests.helpers.input_fixture')` at line 13 re-executes the whole
  build because the contracts file's copy was evicted at that file's boundary.

Consequences:

1. **Cross-file `_G.love` clobbering does not exist under this runner.** The
   `mock_love` calls in `editor_spec.lua:20` (run-time, inside `setup`),
   `keys_pressed_spec.lua:23`, `user_input_model_spec.lua:28`,
   `highlight_shape_spec.lua:29`, `user_input_view_spec.lua:19`, `mock_spec.lua:14`
   are all reverted at their file boundary. The comment in
   `keys_pressed_spec.lua:48` ("other spec files replace `_G.love` during
   collection") describes busted-1-era / pre-insulation behaviour and is stale.
2. **Splitting the 2317-LoC file into N files does not multiply the collision
   surface.** Each split file's `require('tests.helpers.input_fixture')` will
   trigger a complete fresh build inside that file's insulation bubble — exactly
   what `project_open_liveness_spec.lua` already does today, green.
3. The refactor is therefore justified by **explicitness, standalone-runnability
   and independence from a busted implementation detail** — not by an active bug.
   That reframing matters: nobody should "fix" phantom cross-file coupling during
   the split, and any split-file failure is a *within-file* or *fresh-build* issue.

## Answers to the five questions

### Q1 — Is the directive's shape correct? Which hook?

**Yes, with amendments.** Wrap the load-time build (`input_fixture.lua:125-143`:
`mock_runtime()`, `enrich_gfx()`, `build_cfg()`, `require_modules()`,
`build_console()`, the six `Controller.set_love_*` installs at 135-140,
`build_singleton()`, `input_session.new()` at 143) into an explicit `F.setup()`,
and call it from a busted **`setup()`** in each split file's top describe — the
suite's established idiom (`tests/editor/editor_spec.lua:10`,
`tests/input/history_spec.lua:21`).

- **`setup()` (strict), not `before_each`.** Rebuilding the whole MVC 815 times
  changes lifecycle semantics the suite deliberately encodes: the tests
  characterise ONE long-lived singleton widget across many events (mirroring
  `main.lua`'s one-instance wiring, `input_fixture.lua:112-121`), and
  `F.reset` (line 287) exists precisely to define what *is* shared between tests.
  Per-test rebuild would silently mask the leak class `F.reset` guards (e.g. the
  "sticky callbacks" behaviour reset at lines 312-315).
- **`lazy_setup` is an acceptable variant** (skips the ~70ms build when a file's
  tests are filtered out by tags), but strict `setup` matches the existing idiom
  and the build cost is trivial (whole suite: 1.6s). Uniformity wins; don't mix.
- **One exception: keep `package.preload['view.view']` (input_fixture.lua:13) at
  module scope.** It must be registered before *any* `require` of view modules,
  and consumer files may require view-dependent modules at chunk scope, before
  hooks run. It is a pure idempotent assignment; leaving it at load time is safe
  and necessary. Everything else moves into `F.setup()`.

### Q2 — Per-file fresh build vs once-global

**Per-file fresh build is not a change — it is already today's cross-file
semantics** (insulation evicts the fixture between files; proof above). What the
split changes is *intra*-old-file sharing: today all describes in the 2317-LoC file
share one CC/singleton; after the split, describes landing in different files get
different builds. That is equivalent-or-safer **provided no test depends on state
accumulated by an earlier describe that `F.reset` does not clear.**

Candidates `F.reset` does *not* clear (verified against `input_fixture.lua:287-316`):
editor-model buffers opened by `CC:edit(...)` (only `CC.editor.input:clear()` runs,
line 304), console history accumulated by submits (only `CC.input:clear()`, line
303), `Controller._userhandlers.update` and the `user_update`/`user_draw`/
`user_pointer` file-locals in `controller.lua` (reset only via
`set_default_handlers`, controller.lua:850-858, which the fixture never calls),
and `Controller._defaults.update`'s first-install latch (controller.lua:722).

**How to prove no hidden coupling — the gate:**
1. Full suite stays **815/0/0/4** after the split (necessary, not sufficient —
   order is preserved, so order-dependence can hide).
2. **Run every split file standalone** (`busted tests/input/<file>_spec.lua`) and
   require green. A file that passes in-suite but fails alone depended on a
   sibling file's leftovers. This is the decisive check and it is cheap.
3. Optional belt-and-braces: `busted --repeat 2 tests` (exercises suite_reset +
   re-execution; catches once-only latches).
Do **not** use `--shuffle` as a gate: several suites in this repo legitimately
sequence `it`s inside one describe (`user_input_model_spec.lua:33-60` style).

### Q3 — What must `teardown()` undo?

**The owner's second reading is the correct one:** the honest symmetric partner is
"re-establish from scratch on next setup, and null the globals we own." A "full"
teardown is neither possible nor needed:

- `require_modules()` (input_fixture.lua:93-101) cannot be un-required, and its
  class globals (`ConsoleModel`, `UserInputModel`, `Controller`, ...) plus
  `Controller.project_input = ProjectInputController()` (controller.lua:1192) are
  reverted by busted's file-boundary restore anyway.
- `Controller._defaults` / the six `set_love_*` installs bind closures over the
  file's CC; next file's `F.setup()` overwrites them (except the update latch —
  see Q5), and busted reverts the `Controller` global regardless.

So `F.teardown()` should do exactly:
1. `Controller.project_input:deactivate()` — semantic cleanup of the one stateful
   object the fixture activates (mirrors `reset_chain`, input_fixture.lua:262).
2. `_G.love = nil`, `_G.TESTING = nil` — undo `mock_love`'s two global writes
   (`tests/mock.lua:45-46`). Under busted this is redundant (insulation), but it
   makes the fixture honest in any non-insulated harness (a REPL, a future runner,
   `--helper`-level requires) and costs nothing.
3. Nil the fixture's own module-locals (`cfg`, `CC`, `singleton`, `session`) or
   leave them — they die with the module eviction either way; nil-ing them makes
   a double-`setup`/use-after-`teardown` bug crash loudly instead of running
   against a stale world. Recommended.

Do **not** attempt to restore `package.loaded`, un-register classes, or rebuild
`Controller._defaults` in teardown — that duplicates busted's job badly.

### Q4 — Interaction with `before_each(F.reset)`

**The ordering is sound and guaranteed by busted:** for each file,
file chunk → describe body → `setup()` → per-test `before_each` → tests →
`teardown()` (`block.execute`, block.lua:146-160). `F.reset` hard-requires a built
fixture — it dereferences `Controller._defaults.*` (`restore_native_slots`,
input_fixture.lua:235-241), `Controller.project_input` (line 263), and calls
`love.update(1.0)` (line 302), which exists only after `set_love_update`
(controller.lua:646, installed at fixture line 140). With build in `setup()`,
that precondition is structurally guaranteed per file.

**`F.reset` itself needs no changes.** Two consumer-side notes:
- Every split file must carry its own `before_each(function() F.reset() end)`
  (today only `input_contracts_spec.lua:74` has it; verified via grep + LSP that
  `F.reset`'s sole caller is that line). A split file that forgets it inherits
  dirty state from its *own* earlier tests — same-file hazard, not cross-file.
- Consider adding `Controller.set_love_quit(CC)` (controller.lua:756) to
  `F.setup()`'s install list: `project_open_liveness_spec.lua:27` currently
  re-installs it per test precisely because the fixture's six installs omit it.
  Idempotent, behaviour-preserving, removes a per-file workaround.

### Q5 — Idempotency / re-entrancy traps

Sequential per-file setup→teardown cycles are safe **because insulation re-executes
the fixture module itself per file** (fresh `mx, my` at line 29, fresh `F` table,
fresh preload registration — line 13's re-registration is a plain idempotent
assignment). The real traps:

1. **Describe-body access to `F` fields before `setup()` runs.** Describe bodies
   execute before hooks. Concrete existing breakage:
   `project_open_liveness_spec.lua:16` — `local saved_stop = F.cc.stop_project_run`
   in the describe body will nil-crash once the build moves into `F.setup()`.
   That line must move into the file's `setup()`/`before_each`. Audit every split
   file for `F.<field>` reads outside function bodies (grep `F\.` at describe
   scope). This is the single most likely way the refactor breaks.
2. **`Controller._defaults.update` latch** (controller.lua:722:
   `if not Controller._defaults.update then`): a *second* `F.setup()` in the same
   file would leave `_defaults.update` bound to the first CC. Today it is only
   identity-compared (controller.lua:270), so it is benign — but make `F.setup()`
   guard against double-call anyway (`assert(not built)` or early-return), and the
   trap never fires. The other five setters overwrite cleanly (e.g.
   controller.lua:488, 505, 518, 540, 556).
3. **Build order inside `F.setup()` must stay exactly the current line order
   125→143**, in particular `input_session.new(CC)` **last**: `emitters()` captures
   `local h = love.handlers` (`tests/helpers/input_session.lua:15`) and `new()`
   assigns `love.handlers = {}` on the *current* `_G.love`
   (input_session.lua:32) — running `mock_runtime()` after `session.new` would
   strand the emitters on a dead table.
4. `_G.TESTING` must be set before `require_modules()` — several src modules gate
   on it at load time (`src/util/filesystem.lua:74`, `src/model/lang/lua/parser.lua:28`).
   `mock_runtime()` (which calls `mock_love` → sets TESTING, mock.lua:46) already
   precedes `require_modules()` in the current order; preserving line order covers this.

## Recommended design (concrete)

`tests/helpers/input_fixture.lua` becomes:
- Module scope: `package.preload['view.view']` stub (lines 13-22), `local mock/TU`
  requires, `local mx, my`, helper function definitions, `local F = {}`, and the
  method definitions (`F.reset`, `F.compy_input`, ...). **No build execution.**
- `function F.setup()` — guard against double-call; then exactly the current
  125-143 sequence (plus, optionally, `Controller.set_love_quit(CC)`); assigns the
  module-locals `cfg, CC, singleton, session` and populates `F.cc/F.console/
  F.editor/F.singleton/F.session/F.cfg` (fields set here, since they cannot exist
  before build).
- `function F.teardown()` — `Controller.project_input:deactivate()`;
  `_G.love, _G.TESTING = nil, nil`; nil the module-locals and the F fields.
- Each split file:
  ```lua
  local F = require('tests.helpers.input_fixture')
  describe('input contracts: <topic> #input', function()
    setup(F.setup)
    teardown(F.teardown)
    before_each(function() F.reset() end)
    ...
  end)
  ```
- Fix `project_open_liveness_spec.lua:16` (move the `saved_stop` capture into a
  hook) and adopt the same setup/teardown there.

## Top risks and how to detect each

1. **Describe-body reads of unbuilt `F` fields** (Q5.1). Detection: run each split
   file standalone — nil-deref crashes at collection of that file, immediately and
   unambiguously. Known instance to fix: `project_open_liveness_spec.lua:16`.
2. **Hidden cross-describe coupling surfaced by fresh per-file builds** (Q2 list:
   editor buffers, console history, `_userhandlers.update`, `user_*` flags).
   Detection: per-file standalone runs green + full suite at 815/0/0/4; a
   standalone-only failure pinpoints the dependent test and the leaked state.
3. **Tag/pending drift in the split itself.** Contract: every split file's top
   describe keeps `#input`; the 4 pendings survive verbatim. Detection:
   `busted tests | tail -1` = `815 successes / 0 failures / 0 errors / 4 pending`
   and `busted --list tests | grep -c <pending names>`; also compare
   `busted --tags=input` totals before/after.

## Amendments to the owner's directive (explicit)

1. **Rationale correction:** "module loading triggers context/state collisions"
   is not the live failure mode — busted 2.3.0 file insulation already reverts
   `_G` and `package.loaded` per file (proven above). Adopt the refactor for
   explicitness and runner-independence; do not expect it to change suite
   behaviour, and treat any behaviour change during the split as a regression.
2. **"before_suite or analogs" → busted `setup()` per split file's top describe**
   (busted has no cross-file before_suite short of a `--helper`; a helper-level
   build would *escape* insulation and genuinely create the cross-file shared
   mutable state the directive fears — avoid it).
3. **Symmetric teardown is intentionally shallow** (deactivate PIC + nil
   `_G.love`/`_G.TESTING` + nil locals). Full unwind is impossible
   (require-caching) and redundant (insulation); document that in the fixture
   where the line-123 REVIEW comment sits today.
4. **Keep `before_each(F.reset)` in every split file** — setup/teardown replaces
   the *build's* lifecycle, not the *between-tests* contract.
5. While in there, update the stale isolation comments that this consult
   invalidated: `keys_pressed_spec.lua:48-50` and the fixture's line-123 REVIEW.
