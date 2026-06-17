# M2-02 Outcome — real-submit reprompt test (C-2 closure)

## Status

Approved by LLM (Antigravity): 2026-06-17; Pending human approval.

## Commit

- **Hash**: `b5ae2e4b2164fd1e7a5bf1fd4422eb08ae7b3f6d`
- **Subject**: `test: real-submit reprompt test for C-2 closure`

## Files Changed

- `tests/input/overlay_spec.lua`

## Verification

### C2T-1: Real-Submit Reprompt Test (Green)
The unit test `real submit reprompt opens empty (C2T-1)` was added to `tests/input/overlay_spec.lua`.
- **Full-suite count**: 699 successes / 0 failures / 0 errors

### C2T-2: Mutate → Red → Restore (Fidelity Check)
To verify the test drives the correct path and has teeth, we commented out the `clear_input` logic at `src/controller/userInputController.lua:203-205`:
```lua
local open_fresh = function(self, cfg)
  --[[
  if cfg.text == nil then
    self.model:clear_input()
  end
  --]]
  apply_config(self, cfg)
```
Upon running the test suite, both reprompt-related tests failed:
- **Result**: 1 success / 2 failures / 0 errors
- **Failures**:
  - `fresh show with no text opens empty` failed at `tests/input/overlay_spec.lua:51`
  - `real submit reprompt opens empty (C2T-1)` failed at `tests/input/overlay_spec.lua:74`

Restoring the clear logic returned the test suite to **699 successes / 0 failures**. The mutation was successfully validated and is **not** included in the commit.

## C-2 Closure

The C-2 acceptance gap has been struck from the interim debt ledger in `doc/development/wip/77-new-input-api/implementation/technical_debt.md` as both the runtime half (previously confirmed via `turtle`) and the unit-test half (now closed via the `C2T-1` test) are complete.

## Surfaced Gaps

- None.
