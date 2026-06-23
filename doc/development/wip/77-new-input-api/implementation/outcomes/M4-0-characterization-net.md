# Outcome — M4-0: feature-global characterization net + harness extension

_Executed: 2026-06-23. Executor: Claude Sonnet 4.6._

## Commit(s)

- `9ac075e` — `test: M4-0 feature-global characterization net + harness extension`

## Files changed

All under `tests/`:
- `tests/helpers/input_session.lua` — **new**: keypress-level driver
- `tests/mock.lua` — **extended**: textinput emitter + isrepeat/scancode
- `tests/input/characterization_spec.lua` — **new**: characterization net (16 green + 1 pending)

No production code (`src/`) touched.

## Harness shape

### `tests/helpers/input_session.lua`

Driver API (returned by `InputSession.new(cfg?)`):
- `session.press(k)` — fires `love.handlers.keypressed(k, '', false)`
- `session.release(k)` — fires `love.handlers.keyreleased(k)`
- `session.type(t)` — fires `love.handlers.textinput(t)`
- `session.repeat_press(k)` — fires `love.handlers.keypressed(k, '', true)`
  _(currently dropped at controller.lua:554; threaded by M4)_

Pattern: installs real handlers via `Controller.setup_callback_handlers`
and captures the installed closure refs. Caller must set up mock_love +
view.view stub before calling `new()`.

### `tests/mock.lua` additions

- **`mock.textinput(t, press?)`** — emits textinput through
  `love.handlers.textinput` (or custom `press` function). Independently
  orderable relative to keypressed (P1 compliant).
- **`mock.keystroke(s, press?, hold?, opts?)`** — backward-compatible
  extension: `opts.isrepeat` (bool) and `opts.scancode` (string) are
  forwarded to the keypress call. All existing callers continue to work
  (extra args ignored by Lua functions that don't declare them).

## Coverage

### Part B flows pinned (all green):

| Behaviour | Test location |
|---|---|
| D-9 native coexistence (pong) — keypressed/textinput/keyreleased route to love.* when no overlay | `D-9 native coexistence`, 3 tests |
| tixy `input_code` — text submit via overlay + reftable population | `tixy input_code`, 1 test |
| balloons `input_text` — text-eval overlay submit | `balloons input_text`, 1 test |
| turtle `input_text` + Esc — cancel clears model, no reftable write | `turtle input_text + Esc`, 2 tests |
| editor REPL submit (running mode) | `editor REPL submit`, 1 test |
| keyboard once-per-press debounce (edge-tracking pattern, P2 surface) | `keyboard once-per-press debounce`, 4 tests |
| maze legacy idiom: `is_empty` polling, native keypressed, Shift+Enter multiline | `maze legacy idiom`, 3 tests |
| editor `is_at_limit` vertical block-nav via EditorSession | `editor is_at_limit vertical block-nav`, 1 test |

### B-3 forward assertion (pending):

```
pending('isrepeat reaches keypressed path (M4 threads it)', ...)
-- DEFERRED (0.1.0-m4): isrepeat threading — M4 threads isrepeat at
-- controller.lua:554; convert this pending → live assertion then.
```

M4's prompt will convert this to a live `it(...)` once isrepeat is
threaded.

### Flows not characterized (with reason):

- **Full tixy/balloons project loading** — not attempted; the spec
  correctly identified these as overlay-path tests (same mechanism),
  not full project simulations. Covered adequately via make_overlay.
- **Maze's `editor` control mode** — maze's Lua-scripted commands via
  the editor require loading maze's chunker/parser. Covered the
  input-path aspects (is_empty, native keypressed, Shift+Enter multiline)
  without loading the full project. Acceptable for M4-0 scope.

## Verification

### Test counts

- **Before:** 701 successes / 0 failures / 0 errors / 0 pending
- **After:** 717 successes / 0 failures / 0 errors / 1 pending

### C-2 perturb → red → restore

**Perturbation 1 — overlay submit path broken** (`userInputController.lua:447`, commented `res(t)`):
- Tests that turned red: `tixy input_code`, `balloons input_text`, `editor REPL submit` (3 failures + 1 error for Shift+Enter follow-on)
- Assertion that fired: `Expected objects to be equal. Passed in: (nil) Expected: (string) 'start'`
- Restore: uncommented `res(t)` → 717 green ✓

**Perturbation 2 — native coexistence routing broken** (`controller.lua:657`, commented `love.keypressed` call):
- Tests that turned red: D-9 native coexistence + keyboard debounce (6 failures)
- Assertion that fired: `D-9 native coexistence keypressed routes to love.keypressed`, `keyboard first press fires`, etc.
- Restore: uncommented the call → 717 green ✓

Both perturbations confirmed the net has teeth.

## Surfaced gaps

- **view.view stub duplication** — the stub is now in two spec files (`keys_pressed_spec.lua` and `characterization_spec.lua`) and commented as an open A8 item. Already tracked.
- **Maze's `ctrl_update` / Lua command path** — the maze's `process_user_input` → `input_text` → re-arm loop requires the full maze environment. Not characterizable at black-box level without loading the project. Not blocking M4 (D-9 and is_empty covered; the Lua-command path is M8-scope).
- The 3 pre-existing `UserInputController:show ignored` warnings remain (from `singleton_spec`); unrelated to this slice.
