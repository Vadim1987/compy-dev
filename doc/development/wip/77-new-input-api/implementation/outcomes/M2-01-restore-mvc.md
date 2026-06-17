# M2-01 — restore the full `{ M, C, V }` overlay handle — outcome ledger

_Implemented by LLM(Claude Sonnet 4.6): 2026-06-17 (session 09)._

**Status:** runtime smoke-test by human (`tixy`/`turtle`, 2026-06-17)
confirmed **C-1 only** — no fault on the input frame. **C-2 (empty
re-prompt) was not clearly verified at runtime** and remains
outstanding (the spec requires runtime confirmation, not only the
suite; the unit test exercises a `show/hide` proxy, not the real submit
path). Not a full milestone sign-off: the C-3 regression tests and C-4
record were not part of the smoke test, and no review-acceptance gate
has run. Formal approval pending (see review
`../reviews/M2-01-restore-mvc.md` and the open items in
`../technical_debt.md`).
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

Human on 2026-06-17:
- `tixy` and `turtle`: no fault on the input frame (C-1 ✅)
- submit → re-prompt opens empty (C-2 — **not clearly verified**; the
  empty-re-prompt check was not an obvious step in the smoke test and
  may or may not have been exercised). C-2 runtime confirmation is
  outstanding; the spec requires it and the unit test only covers a
  `show/hide` proxy, not the real submit path.
- REPL and editor unaffected

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

Two new gaps spotted during runtime approval; neither is blocking for
this take and neither touches M2-01's file set.

**G-A — tixy shift+click: example-sequence behaviour unclear.**
In `tixy`, shift+click is expected to advance through the built-in
sequence of examples, but the intended order is not obvious from the
UI and may not match user expectations. Observed during approval run;
not reproducible or characterised fully. Worth a dedicated investigation
before the input API surface is considered stable for project authors.

**G-B — editor buffer not cleared on Escape.**
After pressing Escape in the editor, the input buffer retains its
content rather than emptying. A fix was believed to exist but is not
present on this branch (`feature/77-newapi-analysis-s20260615`). May be
on a different branch or may not have landed yet. Needs a branch-level
search before filing as a new defect.
