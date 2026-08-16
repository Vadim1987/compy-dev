# P-13-01 + P-13-02 — outcome

Commit: `3befd556` — `fix(harmony): revert P13's release-discipline
retirement`. Branch `feature/77-newapi-analysis-s20260615`. Not pushed.

## What changed

- **P-13-01 revert**: `git checkout 5b580661^ -- src/harmony/`, restoring
  `init.lua` (undoing both `5b580661` and the `b31e99a9` helper split) and
  the `release_keys()` calls in `scenarios/{console,editor,inspect}.lua`.
  `git diff 5b580661^ -- src/harmony/` is empty after the checkout —
  confirmed byte-identical to that tree. No re-implementation; modifier
  press/release events are not reintroduced.
- **P-13-02 rewrite**: `tests/harmony_input_spec.lua` replaced with a
  queue-then-drain fixture (`mock_state` / `queue_recorder` /
  `setup_harmony`, none over 13 body lines, splitting the old 23-line
  `setup_harmony`) and 3 `it` blocks pinning:
  1. `love.event.push` enqueues; the gateway (`Controller.
     setup_callback_handlers`) has not fired before `drain()` runs, and
     has after.
  2. Only `'keypressed:t'` / `'keyreleased:t'` reach the event stream —
     the modifier never does.
  3. `Key.ctrl()` is true after the chord and false only after
     `harmony.utils.release_keys()` — release is the scenario's job.

## Evidence: failing before, passing after

Against the pre-revert (broken) tree, `busted
tests/harmony_input_spec.lua`:

```
0 successes / 3 failures / 0 errors / 0 pending : 0.025989 seconds

Failure -> ... queues on push, drains before the app sees it
Expected objects to be the same.
Passed in:  { }
Expected:   { edit = true, stop = true }

Failure -> ... puts only the trigger key on the event stream
Passed in:  { 'keypressed:lctrl', 'keypressed:t',
              'keyreleased:t', 'keyreleased:lctrl' }
Expected:   { 'keypressed:t', 'keyreleased:t' }

Failure -> ... keeps the modifier held until release_keys
Passed in:  (nil)
Expected:   (boolean) true
```

All three failures match the finding exactly: the gateway never fires,
modifier press/release leak into the event stream, and `held` is not
observable at handler time.

After the revert, same command:

```
3 successes / 0 failures / 0 errors / 0 pending : 0.013232 seconds
```

## Full suite

`busted tests` from `/repo`: **949 successes / 0 failures / 0 errors /
10 pending** (baseline before this change: 947/0/0/10 — the +2 is the
spec growing from 1 case to 3; the 10 pending are pre-existing and
unrelated, in `tests/input/input_global_shortcuts_spec.lua` and
`tests/input/input_routing_spec.lua`).

## LSP check

`mcp__lua-lsp__diagnostics` on both changed files after the revert:
`tests/harmony_input_spec.lua` — clean. `src/harmony/init.lua` — one
pre-existing HINT (`unused-local _cls` in the `setmetatable(Harmony,
{ __call = ... })` block, line 123), inherited verbatim from the
`5b580661^` tree via the revert, not introduced by this change.

## Things the prompt did not anticipate

- `assert.is_falsy(Key.ctrl())` cannot be called directly on the
  no-modifier-held path: `Key.ctrl()` -> `love.keyboard.isDown(...)` ->
  the harmony `patch_isDown` shim falls off the end with **no return
  statement** (not even an explicit `nil`) when nothing is held and the
  run is locked. Lua then splices that zero-value call as the last
  argument to `assert.is_falsy(...)`, which errors with "requires a
  minimum of 1 arguments, got: 0" instead of failing/passing normally.
  Fixed the same way the pre-P13-era spec already did: capture to a
  local first (`local ctrl = Key.ctrl(); assert.is_falsy(ctrl)`), which
  collapses the multi-return to a single `nil`. Not a defect in the
  revert — pre-existing shim behavior — but worth flagging since it's an
  easy trap for any future assertion written directly against
  `Key.ctrl()`.
- Everything else in the prompt matched the code as found; nothing else
  to report.
