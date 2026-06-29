# Outcome — M4-0-02: keyboard/text routing matrix (gap-fill)

_Executor: Claude Sonnet 4.6 — 2026-06-29 (session 26)._

## Commits

| Hash | Subject |
|---|---|
| `30cd9ca` | test: complete keyboard/text EXCLUSIVE matrix in routing suite |

## Files changed

- `tests/input/input_routing_spec.lua` — 6 new `it()` blocks
  + 1 `describe('inspect ownership')` with `pending`
- `tests/helpers/input_session.lua` — added `mousepressed`
  emitter

No `src/` changes.

## What was added

### Group 1 — keyboard/text EXCLUSIVE matrix (required, green)

All added inside the existing `must-not-degrade` describe block,
driven through the real gateway slots, asserting real consumers.

**textinput EXCLUSIVE (§3.2)**
- `active overlay receives textinput` — with overlay active,
  `session.type('Z')` reaches `overlay_c:textinput`.
- `active overlay blocks native textinput` — with overlay
  active, wrapping `love.textinput` confirms it fires 0 times.

**keyreleased EXCLUSIVE (§3.3)**
- `console keyreleased reaches the console` — no overlay,
  `session.release('a')` reaches `CC:keyreleased`.
- `active overlay receives keyreleased` — overlay active,
  `session.release('a')` reaches `overlay_c:keyreleased`.
- `active overlay blocks native keyreleased` — overlay active,
  wrapping `love.keyreleased` confirms it fires 0 times.

### Optional collateral — mousepressed BOTH (§3.5, included)

- `mousepressed reaches widget and base sink` — overlay active,
  `session.mousepressed(100,200,1,false,1)` delivers to both
  `overlay_c:mousepressed` (widget) and `love.mousepressed`
  (base sink). Order not asserted (R3). Included because it is
  cheap and has clear teeth: the widget half is the half the
  M4 gate-removal could silently kill.
- `input_session.lua` extended with `mousepressed` emitter
  (varargs through `love.handlers.mousepressed`).

### Inspect ownership (§3.4, characterization pending)

Added `describe('inspect ownership')` with a single
`pending('inspect: console owns input — provisional')`. Block
comment documents current behaviour
(`get_user_input()` → nil under `inspect`, controller.lua:20)
and the provisional tag from contract §3.4.

## Verification

**Final run:** `714 successes / 0 failures / 0 errors / 5 pending`
(5 pending = 1 new inspect + 4 carried from M4-0-01)

**Perturb → red → restore (6 cycles):**

| # | Perturbation (src/controller/controller.lua) | Test that reddened |
|---|---|---|
| 1 | drop `user_input.C:textinput(t)` | `active overlay receives textinput` |
| 2 | move `love.textinput` outside `else` | `active overlay blocks native textinput` |
| 3 | drop `user_input.C:keyreleased(k)` | `active overlay receives keyreleased` |
| 4 | move `love.keyreleased` outside `else` | `active overlay blocks native keyreleased` |
| 5 | drop `love.keyreleased` call entirely | `console keyreleased reaches the console` |
| 6 | drop `user_input.C:mousepressed(...)` | `mousepressed reaches widget and base sink` |

All src/ files restored exactly before commit; pre-commit hook
ran the suite and passed.

## Contract-note feedback

No §3 row proved unobservable or contradicted by code. All
stable-now rows tested here are straightforwardly black-box
observable through the existing real gateway slots. No findings
for the orchestrator on the contract record.
