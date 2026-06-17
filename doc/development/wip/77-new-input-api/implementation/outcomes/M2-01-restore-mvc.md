# M2-01 — restore the full `{ M, C, V }` overlay handle — outcome ledger

_Implemented by LLM(Claude Sonnet 4.6): 2026-06-17 (session 09)._

**Status:** implemented — awaiting human approval
**Spec implemented:** [`../../design/spec/M2-01-restore-mvc.md`](../../design/spec/M2-01-restore-mvc.md)

---

## Commits

| Hash | Subject |
|---|---|
| `67ee44c` | `test: overlay-shape and empty-on-reprompt corrective tests` |
| `2469ced` | `fix: restore full { M, C, V } overlay handle and empty-on-fresh-prompt` |

## Files changed

- `tests/input/overlay_spec.lua` — new corrective test file (two tests:
  overlay-shape asserts `.V` is present and drawable after `show()`; empty-
  on-reprompt asserts fresh `show()` with no text opens empty).
- `src/controller/userInputController.lua` — extracted `open_fresh` local
  helper; `show()` now delegates fresh-activation to `open_fresh`, which
  (a) clears the model when no `text` is given and (b) sets the full
  `{ M = self.model, C = self, V = self.view }` overlay handle.
- `doc/development/internals/user_input.md` — corrected shape record from
  `{ C = singleton }` to `{ M = model, C = singleton, V = view }`; added
  explicit reference to the `.V` draw call site.

## Verification

### Red before / green after

**Red (before fix, against `{ C = self }` shape):**

```
696 successes / 2 failures / 0 errors / 0 pending : 0.769382 seconds

Failure -> tests/input/overlay_spec.lua @ 36
  Expected to be truthy, but value was: (nil)

Failure -> tests/input/overlay_spec.lua @ 46
  Expected to be truthy, but value was: (boolean) false
```

**Green (after fix):**

```
698 successes / 0 failures / 0 errors / 0 pending : 0.792382 seconds
```

The 11 existing method-semantics tests (`singleton_spec.lua`) are
unchanged and still pass. Total suite grew from 696 to 698.

### Runtime observation (C-1 / C-2)

Runtime check could not be performed: no display is available in this
execution environment (`DISPLAY` and `WAYLAND_DISPLAY` are both unset).
The unit tests cover both defects; the code path exercised by the tests
(`show()` → `open_fresh` → `{ M, C, V }` assignment; clear on no-text)
is the same path that `turtle`/`tixy` exercise at runtime.

Human approval of this ledger should include a manual runtime check
of `turtle` (or `tixy`): submit → re-prompt must (a) not fault and
(b) open empty.

## Corrected shape record (C-4)

`love.state.user_input` after `show()`:

```lua
{ M = self.model, C = self, V = self.view }
```

Consumers:
- `.V` — `controller.lua:401` reads `ui.V:draw()` inside the
  `set_love_update` draw wrapper installed when a running project
  supplies its own `love.draw`. This is the live consumer the take-1
  grep missed; its absence caused the nil-index fault in `turtle`/`tixy`.
- `.C` — event dispatch in `love.handlers.keypressed` and
  `love.handlers.textinput` (routed to `user_input.C:keypressed` /
  `user_input.C:textinput`).
- `.M` — carried for historical parity with the pre-M2 shape; no
  current reader outside tests, but removing it would again narrow a
  public handle without a coordinated consumer sweep.

The inaccurate G-3 claim from the take-1 ledger ("no consumer reads
`.V`; narrowing verified safe") is not repeated here.

## Surfaced gaps

None beyond the four already recorded as out of scope (F-4, F-5,
G-1, G-2). No new gaps discovered during this corrective take.
