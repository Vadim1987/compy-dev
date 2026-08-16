# S42 — P9c/P13 follow-up cold review

Reviewed `5f1ef541`, `ca7b26f0`, `7826a0e5`, `b31e99a9`, and `29561c75` with
the current tree, the session42 mandate, and the operative S27 plan. The Lua
MCP-LSP bridge was not exposed in this session, so symbol facts were verified
with `rg` and line-level source inspection.

## Finding

### S2 — the P13 test helper still breaks the function-size rule

The first cold review found that the P13 test helper exceeded the 14-line
function limit. The follow-up expands `setup_harmony` instead of resolving it:
its 23-line body is at `tests/harmony_input_spec.lua:18-42`. This violates the
hard limit in `agents/rules.md`; the 16-line tolerance cannot cover it. The
production `love_key` extraction is now within the limit, but the original
test-side part of that finding remains incomplete.

Split the environment setup into meaningful helpers (for example the mocked
LÖVE state and the event recorder), preserving the real-gateway assertion.

## Verified completion and scope

- P9c remains complete: `F.reset()` restores the liveness fixture before each
  case (`tests/input/project_open_liveness_spec.lua:45-51`), while the
  play-mode case restores the shared `love.handlers` table in place
  (`tests/input/input_shortcuts_click_spec.lua:73-82`). The operative table
  marks P9c and P13 done at
  `validation/reviews/S27-triage-and-plan.md:599,612`; the detailed P9c
  completion and P13 revalidation are at `:837-853`.
- P13 now drives the real `Controller.setup_callback_handlers` gateway and
  observes its Ctrl+T quickswitch effect
  (`tests/harmony_input_spec.lua:44-70`; `src/controller/controller.lua:766-875`).
  The modifier sequence and post-chord state are asserted at
  `tests/harmony_input_spec.lua:62-70`.
- The production extraction preserves the required press, trigger, reverse
  release ordering (`src/harmony/init.lua:224-261,302-310`), keeps
  `patch_isDown` (`:272-284`), and removes the Harmony `release_keys` API and
  calls. The new production helpers are within the 14-line limit.
- No unrequested production behaviour, missing P9c work, or further material
  unnecessary complexity was found in the five follow-up commits.
- Narrow shuffled verification passed:
  `busted --shuffle tests/harmony_input_spec.lua tests/input/project_open_liveness_spec.lua tests/input/input_shortcuts_click_spec.lua`
  — 21 successes, 0 failures, 0 errors, 0 pending.
