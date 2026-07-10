# Outcome — M5c-04: route connection lifecycle (chunk 4 of the M5c carve)

_Executed as a continuation pass for
[`../prompts/M5c-04-route-lifecycle.md`](../prompts/M5c-04-route-lifecycle.md),
2026-07-10. A prior agent session landed the red test rows and removed the M4
ruling-1 forwarding branches but stopped before implementation, outcome ledger,
or commit. This pass completed the controller/stop-path work, verified green, and
committed._

## What will surprise the architect (read first)

1. **Slot restore is explicit reassignment, not a new route abstraction.** AC-27
   disconnects the project keyboard/text route by calling the new
   `Controller.release_keyboard_route(CC)` — it runs `project_input:deactivate()`
   then reinstalls the three console `set_love_*` handlers. Pointer slots are
   intentionally untouched (AC-28). The old per-event `app_state ~= 'running'`
   forward to `Controller._defaults.*` in `projectInputController.lua` is gone
   because it compensated for slots that were never restored at the transition;
   now they are (spec §8, ratified-model ruling 3).
2. **AC-29 teardown extends `clear_user_handlers(CC)`, not a parallel reset path.**
   Stop already called `set_default_handlers` + `love.state.user_input = nil`;
   this chunk adds `reset_compy_input` (wipe `compy.input.handlers.*` + every
   project-mutable callback field) and `reset_widget_outputs` (clear the
   singleton's mirrored widget-output fields) inside `clear_user_handlers`. Widget
   hide at stop remains a direct `nil` of `love.state.user_input` — not
   `UserInputController:cancel()` — so no cancel chain fires (spec §10 edge case).
3. **`compy.before_exit` lives on the `compy` namespace via a metatable slot, not
   on `compy.input`.** Default = noop + debug log (`M6-02-before-exit.md`). Fires
   once at the top of `stop_project_run` while `app_state` is still `'running'`,
   before `set_default_handlers`; reset to default after cleanup in the same stop
   cycle.
4. **`active_keyboard_route()` is dropped (C23).** The suite row retargeted from
   "stop names the console as restored route" to `stop leaves no project handler
   wired in any slot` (E30 Scope-10(a): stop's distinctive contract is full
   teardown, not keyboard-route identity). **LOUD IMPACT:** the untracked local
   driver `src/tests/autotest.lua:133/212` still calls
   `Controller.active_keyboard_route()` — this repo does not own that file; the
   human must update it.
5. **Route-equivalence REVIEW markers were left untouched** (`controller.lua`
   L190/191/192/195/197/207/695) — they question whether PIC should be
   de-specialised / routes unified; that is the deferred console/editor migration,
   explicitly out of scope (Gate-2 no-opportunistic-unification).
6. **Fixture isolation fix rides here:** `F.reset()` now clears
   `love.state.suspend_msg` so the AC-30 inspect row does not inherit a stale
   suspend message from an earlier test's `suspend_run()`.

## Commit refs

- `TBD-test` — `test(input): red rows for route lifecycle (M5c chunk 4)`
- `TBD-feat` — `feat(input): route connection lifecycle, before_exit (M5c chunk 4)`

Independently revertible; in-repo files only; no push; no `src/examples/*`.

## Files changed

- `src/controller/controller.lua` — `release_keyboard_route`; extended
  `clear_user_handlers(CC)` with `reset_compy_input` / `reset_widget_outputs`;
  dropped `active_keyboard_route` accessor.
- `src/controller/consoleController.lua` — `compy.before_exit` slot on namespace;
  `stop_project_run` fires/resets hook; `run_project` calls
  `release_keyboard_route` on non-blocking exit / run error.
- `src/controller/projectInputController.lua` — removed M4 ruling-1 per-event
  forwarding branches; updated route-lifecycle comments (resolved L213-214
  REVIEW+TODO).
- `tests/helpers/input_fixture.lua` — `love.state.suspend_msg = nil` in `F.reset()`.
- `tests/input/input_contracts_spec.lua` — retargeted stop row; new
  `route connection lifecycle #m5c` block (AC-27..30 + M6-02).

## Verification

- **Full suite (`busted tests`):**
  - **Before (HEAD, pre-chunk): 771 successes / 0 failures / 0 errors / 5 pending.**
  - **After: 779 successes / 0 failures / 0 errors / 5 pending.**
  - Net: +8 live rows (the `route connection lifecycle #m5c` block).
- **Red-for-the-right-reasons (inherited from prior session):** with only test
  rows + forwarding removal, the lifecycle block showed `release_keyboard_route`
  nil, handler fields surviving stop, and `before_exit` never firing — 3
  successes / 3 failures / 2 errors on the block filter before this pass's
  implementation landed.
- **LSP diagnostics** (`mcp_lua-lsp_diagnostics`): clean on touched files except
  pre-existing warnings (duplicate-set-field from `class.create` style, undefined
  `compy` on env tables, deprecated `setfenv`/`package.loaders` noise in
  `consoleController.lua`).
- **Manual check:**
  - **Headless smoke:** `timeout 5 xvfb-run -a love src --headless` boots to
    timeout without a load-time traceback (ALSA noise only).
  - **Interactive route transitions** (non-blocking-return → REPL typing; stop →
    teardown) are exercised by acceptance rows driving the real gateway and
    production `release_keyboard_route` / `stop_project_run` / `suspend` — not
    simulated. Full 4-mode + turtle/maze hand-play is chunk 5.

## Per-AC checklist (in-scope ACs)

| AC / item | Status | Row(s) |
|---|---|---|
| AC-27 connect/disconnect at running boundary | met | `the console regains text entry when a non-blocking run exits` |
| AC-28 pointer excluded from disconnect | met | `pointer stays hooked when a non-blocking run ends` |
| AC-29 full teardown at stop | met | `stop clears every project-installed handler and hook`; `stop silently hides a shown widget without firing the cancel chain`; `stop resets the widget's own output fields`; `stop leaves no project handler wired in any slot` |
| AC-30 inspect disconnect + widget unhonoured | met | `inspect disconnects the project route and its widget goes unhonoured` |
| M6-02 `compy.before_exit` | met | `compy.before_exit fires once on stop before cleanup`; `compy.before_exit resets to noop after stop` |

## Per-pinned-remark disposition (chunk-4 surface)

| Location | Disposition | Notes |
|---|---|---|
| `projectInputController.lua` L213-214 REVIEW+TODO (`_defaults` forward) | **dissolved-by-rework** | AC-27 removes the forwarding; slots restored at transition instead |
| `controller.lua` L190/191/192 (occupy_keyboard purpose) | **note-only** | Deferred route-equivalence migration — left in place |
| `controller.lua` L195/197/207 (wrap-vs-assign, `_keyboard_route`) | **note-only** | Deferred migration |
| `controller.lua` L695 (`set_default_handlers` console-as-pet) | **note-only** | Deferred migration |
| `controller.lua` L998-999 (`active_keyboard_route`) | **fixed** | Accessor dropped per C23 |

## Suite `-- REVIEW:` reconciliation ledger

| Marker | Action |
|---|---|
| `input_contracts_spec.lua` stop-row REVIEW ("artifact of deviated development") | **removed** with row retarget to AC-29 teardown wording |
| L495/508-510 console-as-hidden-sink musings | **left** — console-migration follow-on, not resolved by AC-29/30 |
| Route-equivalence markers in `controller.lua` | **left** — see disposition table |

## `>> REVIEW` marker removal ledger

None on this chunk's production surface beyond the dissolved L213-214 pair (covered
above). No `>> REVIEW` markers were introduced.

## Surfaced gaps

- **`src/tests/autotest.lua` breakage from `active_keyboard_route` removal** — untracked,
  human-owned; update required at L133/212.
- **None otherwise** for in-slice AC coverage.
