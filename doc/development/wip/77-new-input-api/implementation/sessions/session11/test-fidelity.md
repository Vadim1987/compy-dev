# A2 — test-fidelity audit (S7 precondition)

Scope: `tests/input/` (all 9 spec files) plus a spot-check of
`tests/editor/editor_spec.lua` and `tests/editor/buffer_spec.lua` for
routing/callback coupling to the input API. `tests/editor/editor_spec_fwd.lua`
was left untouched per instructions (owner scratch).

Method: grepped for the owner's `REVIEW:`/`#disputable`/`pending` markers
(all of them live in `tests/input/input_contracts_spec.lua` — no other
input/editor spec carries any), read every flagged block in context, then
read the fixture (`tests/helpers/input_fixture.lua`,
`tests/helpers/input_session.lua`) and the production code each test
claims to exercise (`src/controller/controller.lua`,
`consoleController.lua`, `userInputController.lua`) to verify whether the
test drives the real path or reimplements it. The remaining eight input
spec files (`cursor_spec`, `input_spec`, `input_text_spec`, `history_spec`,
`highlight_shape_spec`, `keys_pressed_spec`, `project_open_liveness_spec`,
`user_input_view_spec`) were read in full: all of them either call real
production functions/methods directly and assert on real return values, or
(one case, `highlight_shape_spec.lua`) deliberately and explicitly document
why they replicate a view's raw unguarded field access as a shape/crash
regression guard — not a fidelity problem.

## Fixed (mechanical)

| File:line | What was wrong | What changed | Why it's now faithful |
|---|---|---|---|
| `tests/input/input_contracts_spec.lua:467` (`it('hide deactivates the widget', ...)`) | Description/body mismatch, flagged by the owner's own `REVIEW/DOC` at line 462: the test name claims "hide deactivates the widget" but the body only asserted a side-effect (typed text lands in the console afterward) — it never checked the widget's own deactivated state. A reader can't tell from the assertions that the widget itself was deactivated, only that routing moved on. | Added `assert.is_false(F.singleton:is_shown())` right after `input.hide()`, using the real `UserInputController:is_shown()` method (`src/controller/userInputController.lua:451`, already used elsewhere in this same file at line 2214) — a direct, existing production accessor, not a new/stubbed one. Kept the pre-existing console-routing assertion, since the owner's remark explicitly says "concern-under-test is valid, prose description is misorienting" — i.e. the routing check itself is legitimate, it just wasn't what the *name* promised. | The test now asserts the literal claim in its own description (widget deactivated) via a real method call, in addition to the routing side effect, so it fails if either the deactivation or the routing regresses. No new coverage was invented and no existing assertion was removed or weakened. |

Busted count unaffected by this change: same `it` block, one added
assertion — no change to pass/pending counts.

## Judgment-required (Phase C)

| File:line | Fidelity problem | Why an owner ruling is needed | What the ruling would decide |
|---|---|---|---|
| `tests/input/input_contracts_spec.lua:258-271` — `describe('global shortcuts do not consume the key (#disputable))')`, `it('a shortcut fires but does not consume')` | Test wraps `love.keypressed` inline (`local orig = love.keypressed; love.keypressed = function(k) n = n + 1; orig(k) end`) and sets `love.state.app_state = 'running'` directly, rather than going through `F.running_project`/`F.activate_project`. It *does* drive the real gate (`love.handlers.keypressed`, `src/controller/controller.lua:874`) and the real `ConsoleController:suspend_run` (verified: `suspend_run` guards on `app_state == 'running'`, so the direct state poke is a genuine precondition, not a bypass of logic under test) — so this is not a case of the test re-deriving framework behaviour. The open question, per the owner's own `REVIEW` at line 257 and the `#disputable` tag already on the `describe`, is purely methodological: is manually wrapping the native slot the sanctioned way to observe "did tier-3 still fire", or should the fixture grow a helper for this (mirroring `F.running_project` but preserving the original instead of replacing it)? | Owner already marked this `#disputable` and asked "is it how in real scenarios handlers are altered?" — deciding the answer requires a call on fixture API shape (should `F.running_project` gain a "wrap, don't replace" variant?), which is a design decision about the test-helper surface, not a mechanical swap. | Whether to add a fixture helper (e.g. `F.wrap_native(name, fn)`) that both suites here and any future "shortcut still reaches route" test should use, vs. leaving the inline wrap as acceptable idiom given it already targets the real slot. |
| `tests/input/input_contracts_spec.lua:283-305` — `it('#play mode narrows the active shortcut set')` | Builds a private stub controller (`cfg.mode='play'`, hand-rolled `restart`/`quit_project`/`keypressed`), saves/restores `love.handlers` and `love.keypressed`, then calls `Controller.setup_callback_handlers(stub)` directly to re-wire the gate onto the stub for the duration of one test. This *is* the real gate/dispatch function under test (not reimplemented), but it substitutes a stub `CC` for the shared fixture's real `ConsoleController` because the shared fixture is built once, in `'dev'` mode, at file-require time — there is no way today to get a `'play'`-mode `CC` without either this kind of ad hoc rewiring or a second fixture build. | Owner's `REVIEW` at line 284 already asks "should not test execute a few real framework methods instead and check their results?" — resolving this means deciding whether `tests/helpers/input_fixture.lua` should support a `'play'`-mode variant (a fixture-architecture change) or whether a scoped stub-and-restore is acceptable for a single mode-boundary test. Either path is a design call, not a one-line fix. | Whether to extend the shared fixture with a `cfg.mode` override capability (cleaner, but touches the frozen-adjacent fixture and every other test's assumptions about `mode='dev'`), or to keep this test's local stub-and-restore pattern as the accepted idiom for one-off mode variance. |

### Verified, no action needed
`tests/input/input_contracts_spec.lua:321` — `REVIEW: why not setup via
'running_project'? unification is good. or it does not work with mouse
events?` (in the `'framework click detection'` block). Checked
`src/controller/controller.lua:646-680` (`set_love_update`'s click-timer
logic): click detection is driven entirely by `love.update` + the
project's own `compy.singleclick`/`compy.doubleclick` fields, with no
dependency on `app_state`. `F.set_compy_handler` already assigns
`CC:get_project_env().compy[name] = fn` — exactly what a real project does
by writing `compy.singleclick = fn` — so these tests already exercise the
real path; `running_project`/`activate_project` (which gate on
`app_state == 'running'`) are the wrong tool here, not a missing
unification. Not listed as a Phase C item since there is nothing to rule
on — the existing test is already faithful, just using a different
(correct) fixture entry point than the reviewer expected.

## Summary

```
815 successes / 0 failures / 0 errors / 4 pending : 1.4084 seconds
```

No delta from the 815/0/0/4 baseline. The one mechanical fix added an
assertion inside an existing `it` block rather than adding a new test, so
the success/pending counts are unchanged. The 4 pending rows are the
same intentional ones (`tests/input/input_contracts_spec.lua` lines 118,
172, 185, 246) — untouched, as instructed.
