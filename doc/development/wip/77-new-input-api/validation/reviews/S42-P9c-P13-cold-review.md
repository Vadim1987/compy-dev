# S42 — P9c/P13 cold review

Reviewed commits `6c127229` and `5b580661`, the current tree, the session42
mandate, and the operative S27 plan. The Lua MCP-LSP bridge was not exposed in
this session, so concrete symbol and call-path claims were checked with `rg`,
line-level source inspection, and narrow test runs instead.

## Findings

### S2 — P13's promised real-shortcut proof is absent

`tests/harmony_input_spec.lua:34-37` replaces both production gateway handlers
with test-local functions. The assertion at `:41` therefore establishes only
that Harmony's synthetic `keypressed('t')` reaches that replacement while
`Key.ctrl()` reads true. It does not invoke the real shortcut matcher:
`Controller.setup_callback_handlers` installs the `ctrl+t` quickswitch at
`src/controller/controller.lua:766-875`, and Harmony's own toggle is `C-t` at
`src/harmony/init.lua:185-187` and is used by scenarios at
`src/harmony/scenarios/editor.lua:131`.

This misses session42's explicit requirement to prove a *real shortcut combo*
under the device-read matcher, and violates the test rule that a test exercise
a real production path. Retain the event-order and post-release assertions, but
install the real gateway with a suitably narrow controller double and assert an
observable quickswitch effect.

### S2 — The operative table was not updated to completed status

The session42 prompt requires amending both the operative sprint row and its
detailed step as each status changes. The detailed step says P9c is complete
at `validation/reviews/S27-triage-and-plan.md:837-845` and records P13's result
at `:848-853`, but the actual operative rows remain unclosed at `:599` and
`:612`. This leaves the single operative list reporting both as outstanding,
despite the two commits and the detailed completion text. Mark each row DONE
with its commit and gate result.

The session track is also unfinished at
`implementation/sessions/session42/track.md:27-33`, ending mid-sentence. It
does not substitute for the missing table status.

### S2 — New P13 code and its test exceed the repository's function limits

`src/harmony/init.lua:273-298` now makes `love_key` a 25-line function, beyond
the 14-line limit (16 only under the documented tolerance). The pre-change
function was already oversized, but P13 enlarged it while adding modifier
release. The new `setup_harmony` test helper is independently 21 lines at
`tests/harmony_input_spec.lua:7-28`.

This conflicts with `agents/rules.md`'s hard function-body limit. The P13
change should extract meaningful chord emission/setup helpers rather than add
to the existing oversized function.

## Verified scope and checks

- No S0/S1 production-behaviour defect was found in the modifier release
  sequence itself. `love_key` presses simulated modifiers before the trigger
  and releases them in reverse afterward (`src/harmony/init.lua:279-297`),
  while retaining `held` and `patch_isDown` as required (`:174-184`, `:243-255`).
- No unrequested production change was found: P9c changes only fixture
  restoration, and P13 removes only the requested manual release API/calls
  while adding modifier events.
- Narrow checks passed: `busted tests/harmony_input_spec.lua` (1 success),
  `busted tests/input/project_open_liveness_spec.lua --shuffle` (5 successes),
  and `busted tests/input/input_shortcuts_click_spec.lua --shuffle` (15
  successes). The broad suite was not rerun.

Apart from the three findings above, this review found no additional missing
P9c work, unrequested work, or unnecessary complexity.
