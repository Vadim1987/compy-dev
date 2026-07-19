# Fable consult — input-fixture lifecycle refactor (S15/TF1 precursor)

## Your role
You are the wisdom oracle for a LÖVE2D (Lua) project's test-infrastructure design
decision. Judgment only — do NOT edit code. Return a design verdict I will
materialize on disk. Verify every factual claim against the actual source before
relying on it (LSP `lua-lsp` MCP is available: defs/refs/diagnostics over a real AST;
grep to find candidates, LSP to confirm "who calls this"; `sleep 1` after any .lua
edit before querying — but you are not editing, so mainly Read + grep + LSP refs).

## Context
Working dir `/repo`. A 2317-LoC test file `tests/input/input_contracts_spec.lua`
(815 of the suite's tests, top describe tagged `#input`, `before_each(F.reset)`) is
about to be **split into several human-reviewable files** along cognitive/topic seams
(task "TF1"). Behaviour-preservation contract: full suite must stay **815/0/0/4**,
same tags, same 4 pendings.

The shared fixture is `tests/helpers/input_fixture.lua` (READ IT IN FULL). Its problem:
it executes ALL its build code at **module-load time** (currently lines ~125–143:
`mock_runtime()`, `enrich_gfx()`, `build_cfg()`, `require_modules()`, `build_console()`,
six `Controller.set_love_*` setters, `build_singleton()`, `input_session.new()`), and
assigns file-scope locals `cfg/CC/singleton/session` that its methods close over. The
fixture's own REVIEW at line 123 asks whether this is safe.

`mock_runtime()` → `tests/mock.lua` `mock_love()` does **`_G.love = love`** and
`_G.TESTING = Dequeue()` — a GLOBAL clobber. Four other spec files
(`editor_spec`, `user_input_model_spec`, `keys_pressed_spec`, `highlight_shape_spec`)
also call `mock_love` at their own load/hook time. Because `require` is cached, the
fixture's load-time build fires exactly once, at whatever point in busted's file-load
order the first `require('tests.helpers.input_fixture')` lands. The suite is green today,
but the owner's concern is that splitting one file into N multiplies the load-order
surface over which `_G.love` (and the built controllers) can be clobbered → state
collisions.

Established busted idiom in this suite: `setup`/`teardown` (once per describe/context),
`before_each`/`after_each`, `lazy_setup`. Examples: `tests/input/history_spec.lua:21`,
`tests/editor/editor_spec.lua:10`.

## Owner's directive (the shape to pressure-test, not blindly implement)
"Wrap all top-level executable code of the fixture into a `setup()` method, create a
symmetric `teardown()` method, then call fixture setup/teardown explicitly from test
hooks (before_suite / before_each or analogs) so that module loading won't trigger
context/state collisions."

## Questions for your verdict
1. **Is the directive's shape correct** to eliminate the module-load collision? Confirm
   or improve. Specifically: build in a busted `setup()` (once per file's top describe)
   vs. lazy vs. `before_each` — which, and why, given the split multiplies files?
2. **Per-file fresh build vs. once-global:** today all 815 tests share ONE built
   CC/singleton (reset between via `F.reset()`). If each split file calls `F.setup()` in
   its own `setup()`, each file gets a FRESH CC/singleton. Is that equivalent-or-safer,
   or does it risk a hidden cross-describe coupling the plan warned about? What would you
   check to prove no test depends on cross-test accumulated fixture state beyond `reset`?
3. **What must `teardown()` symmetrically undo** to be truly symmetric and collision-safe,
   given: `_G.love`, `_G.TESTING`, global class registrations via `require_modules()`
   (cached — cannot un-require), `Controller` module-singleton mutations
   (`Controller.project_input`, `Controller._defaults`, the six `set_love_*` installs)?
   Is a full teardown even meaningful given require-caching, or is the honest symmetric
   partner "re-establish from scratch on next setup" + null out `_G.love`/`_G.TESTING`?
4. **Interaction with existing `before_each(F.reset)`:** any hazard in the ordering
   setup(build) → before_each(reset) → test → ... → teardown? Does `reset` need changes?
5. **Idempotency/re-entrancy:** setup will be called once per split file, sequentially,
   with teardown between. Any trap there (double-install of `set_love_*`, leaked
   references, `package.preload['view.view']` re-registration at line 13)?

## Deliverable
A crisp verdict: the recommended setup/teardown design (what setup does, what teardown
does, which busted hook, per-file vs global), the top 2–3 risks with how to detect each,
and an explicit callout of anything in the owner's directive you'd amend and why. Be
concrete (name functions/lines). This governs a refactor under 815 tests, so favor being
right over being fast.
