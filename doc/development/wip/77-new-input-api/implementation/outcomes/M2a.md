# M2a — M1 follow-up hygiene — outcome ledger

_Filled by the implementation agent (Claude Sonnet 4.6): 2026-06-17._

**Status:** ✅ implemented — awaiting human approval
**Spec implemented:** [`../../design/spec/M2a.md`](../../design/spec/M2a.md)

---

## Commits

| Hash | Subject |
|---|---|
| `c7083dd` | `refactor: M2a — single source of truth for l/r modifier fold; drop dead profiler stub` |

## Files changed

- `tests/input/keys_pressed_spec.lua` — removed the `controller.profiler`
  preload block (10 lines) and its comment; the two load-bearing stubs
  (`view.view` and `love.handlers = {}`) were left intact.
- `src/util/key.lua` — added `local gui_k = { "lgui", "rgui" }` and
  `local mod_triples` (the four `{left, right, generic}` triples in
  ctrl→alt→shift→gui precedence order); exposed as `Key.mod_triples`.
- `src/controller/controller.lua` — replaced the 5-line local `COMBO_MODS`
  literal with `local COMBO_MODS = Key.mod_triples`.

## Verification

- **Before:** `busted tests` → 685 successes / 0 failures / 0 errors / 0 pending
- **After:**  `busted tests` → 685 successes / 0 failures / 0 errors / 0 pending
- Count held at 685 (zero behaviour change — no tests added or removed).
- All M1 `combo_string` tests pass unchanged: bare key, lctrl/rctrl folding,
  alt+shift ordering, ctrl-before-alt precedence, all-modifiers ordering.

## Surfaced gaps

None.
