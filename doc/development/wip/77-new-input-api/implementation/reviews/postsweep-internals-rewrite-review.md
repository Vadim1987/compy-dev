# Review — internals/user_input.md rewrite (post-sweep)

_Reviewer: Claude Opus 4.8 (cold, `agents/review.md` charter), 2026-07-13. Subject: commit
`f53c344` (`docs(input): rewrite internals/user_input.md to the landed system`) + its outcome
ledger. Verdict-only; no edits. Fact-checked against landed `src/` via grep + lua-lsp (~30
`file:line` cites resolved)._

## VERDICT: APPROVE

Factually faithful to the landed system. **Zero factual errors.** Every spot-checked citation
resolved to exactly the claimed construct. Safe to ship as the user-facing internals reference.

## What was verified against code

- **Four-tier chain** — `ProjectInputController:_dispatch` (`projectInputController.lua:170-179`):
  `framework_handlers[event][combo]` → `compy.input.handlers[event][combo]` → `_tier3` → `_sink`,
  truthy-consume at each tier. ✓
- **`compy.input.*` singleton surface** — `get_compy_input` (`consoleController.lua:462`),
  `build_input_surface` write-raise (`:382`), `set_cursor`/`set_text` warn-while-hidden
  (`:495`/`:505`), `get_cursor` nil-while-hidden. ✓
- **Submit/cancel tier-1 chains** — `framework_submit`/`framework_cancel` installed at construction;
  `submit()` (`userInputController.lua:380-389`) validate→deliver→hide synchronously; `after_submit`
  only on non-nil return. ✓
- **Route restoration** — `release_keyboard_route` (`controller.lua:730-735`) reinstalls console
  slots at `'running'→'project_open'`, called from `consoleController.lua:256/261`. ✓
- **held_keys proxy** — read-through/write-raise (`controller.lua:354`); LuaJIT `__pairs`-ignored
  caveat present. ✓
- **isrepeat threading** — gateway keeps `(k, sc, isr)`; threaded to tier-3 + sink; combos don't
  gate on it; console fallback drops it. ✓
- **`UserInputModel.new`** — no `oneshot` param (`userInputModel.lua:45`). ✓

## Ledger surprises + dead-code bug — all confirmed

Surprises 1–7 confirmed (no console-forward in `project_open`; `active_keyboard_route()` does not
exist — only inert `_keyboard_route`; `on_limit_reached` fires from the sink; FR-1 cursor via
`open_fresh`; isrepeat threaded-but-not-uniform; oneshot/`push('userinput')` gone; citation drift
re-verified). **Dead-code bug CONFIRMED:** `love.handlers.userinput` (`controller.lua:976-981`) is
unreachable — zero `love.event.push('userinput')` in `src/`. Doc notes it as a vestige (report-don't-fix). ✓

## 7 didn't-land gaps — all stated accurately

`compy.keys_pressed` absent from `get_compy_namespace`; `eval`/`result` in `apply_config`; combo
repeat-fires-every-repeat (in-code DEFERRED); `multiline` unimplemented (`userInputModel.lua:499`);
no public `is_active()` (internal `is_shown()` at `:415`); proxy index-only on LuaJIT; silent
config-key drop vs `set_cursor`/`set_text` warn. Each matches `owner-rulings-verified.md` + code.

## Hygiene — confirmed

`grep -c wip/77` = 0; `grep -c '^> '` = 0. Absorbed-inline content genuinely present (inspect
override, search triad, keyreleased fork, four-way reset split, blast-radius map). No "do not exist
yet" residue. Rules on nothing; `human-approved NOT YET` marker correctly left for the human.

## Micro-nits (non-blocking — do NOT gate)

1. ~line 44: gateway forward called "unconditionally (`controller.lua:899-900`)" — the *args* are
   unconditional but the call is inside `if love.keypressed then`. Harmless imprecision.
2. `set_cursor_pos` cited `:124-139` spans the doc-comment; body is `:132-139`. Whole-unit convention.
3. Submit trace omits the empty-input→nil short-circuit (no `after_submit`) that precedes the
   validator gate. Minor omission.
