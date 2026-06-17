# M2-01 review — restore the full `{ M, C, V }` overlay handle (corrective take)

_Reviewer: LLM(Claude Opus 4.8): 2026-06-17. Scope: the two commits
implementing the corrective spec
[`../../design/spec/M2-01-restore-mvc.md`](../../design/spec/M2-01-restore-mvc.md)._

Commits reviewed:

| Hash | Subject |
|---|---|
| `67ee44c` | `test: overlay-shape and empty-on-reprompt corrective tests` |
| `2469ced` | `fix: restore full { M, C, V } overlay handle and empty-on-fresh-prompt` |

## Verdict

**Code approved (reviewer); one acceptance gate still open.** The take
corrects both regressions take 1 introduced, without re-opening the scope
it was warned away from. The `{ M, C, V }` handle is restored exactly
where the overlay expects it, the empty-on-fresh-prompt clear is placed
correctly, and the test gap that hid F-1 is closed with two tests that
genuinely fail against the pre-fix code. The fix is small and localised;
the documentation is corrected; the scope fence held. **The open gate:**
C-2's empty-re-prompt behaviour — a spec-mandated *runtime* acceptance
criterion — is verified by neither the suite (proxy test) nor the human
smoke test (which covered C-1 only). The fix logic is sound, but that
criterion is not yet met, so M2-01 is not formally closeable until it is.
Independently re-verified below.

**Approval-scope note.** This is the reviewer verdict. The human check
to date was **manual smoke-testing of `tixy`/`turtle`** and confirmed
**C-1 only** (no-fault); the empty-re-prompt step (C-2) was not an
obvious part of it and was not clearly verified. The outcome ledger's
original "✅ approved by human" line overstated this as full milestone
approval; it did not exercise M2-01's actual deliverables (the C-3
regression net, the C-4 record). M2-01 is therefore not yet formally
closed. Now tracked in [`../technical_debt.md`](../technical_debt.md) as
two **open** items — the approval-scope/record-accuracy item (Status
line now corrected) and the C-2-unverified acceptance gap — both to
clear before sign-off.

## Spec compliance

### C-1 — full `{ M, C, V }` overlay handle ✔

`show()` now delegates fresh activation to a new `open_fresh` local
(`userInputController.lua:202`), which sets
`love.state.user_input = { M = self.model, C = self, V = self.view }`.
The live consumer is confirmed present: `controller.lua:401` reads
`ui.V:draw()` inside the `set_love_update` draw wrapper installed when a
running project supplies its own `love.draw`. The narrowed `{ C = self }`
that caused the nil-index fault is gone. The spec's explicit
prohibition — *do not instead rewrite the overlay to reach the view
through the controller* — was respected; the overlay contract is
untouched and only the handle was restored.

### C-2 — empty-on-fresh-prompt ⚠ (fix correct; end-to-end verification outstanding)

The clear is placed correctly: `open_fresh` calls
`self.model:clear_input()` only when `cfg.text == nil`, and only on the
inactive→active transition. `hide()` (`:233`) still merely nils the
state, and the already-active `force` path (`:220-227`) is unchanged —
both preserve content exactly as `M2.md` specifies. The root cause the
spec cites is real: `UserInputModel:handle` (`userInputModel.lua:803`)
pushes the `userinput` event on a successful oneshot submit but never
clears `self.entered`, so without this fix a re-prompt re-opens
pre-filled. The clear lands at the fresh-activation boundary the spec
designates, not at submit — an equally valid choice from the two the
review offered, and the less invasive one.

The fix logic is sound, but the **end-to-end submit → empty path is
verified by neither runtime nor suite**: the human smoke test confirmed
C-1 (no-fault) only, not the empty re-prompt; and the unit test uses a
`show/hide` proxy rather than driving `handle(true)`. M2-01's spec makes
runtime confirmation of C-2 an explicit acceptance requirement, so this
is an open gate, not a closed criterion — tracked as an **open**
acceptance gap in [`../technical_debt.md`](../technical_debt.md). Closure
is a real-submit unit test plus a runtime re-check; I withhold the C-2
tick until both land.

### C-3 — tests first, covering the previously-uncovered path ✔ (with a residual-coverage note)

Both tests are genuinely red before the fix and green after — I
re-verified this directly by running `tests/input/overlay_spec.lua`
against the pre-fix controller (`67ee44c~1`): **0 successes / 2
failures**, matching the ledger's recorded red trace at lines 36 and 46.
After the fix the full suite is **698 successes / 0 failures** (run
locally), and `singleton_spec.lua`'s 11 method-semantics tests are
untouched on this branch (last modified in `2245aa5`).

One observation, not a blocker — see *Residual coverage* below: both
tests run against an ad-hoc `make_ctrl` controller with a stub
`draw`-only view, not the `main.lua`-wired startup singleton or the real
`controller.lua:401` overlay wrapper. The spec set this as the floor
(".V present and drawable") and named the singleton/overlay path only as
the *ideal*, so this meets the contract — but it leaves a thin slice of
the originally-broken path still un-driven.

### C-4 — corrected outcome record ✔

The outcome ledger
([`../outcomes/M2-01-restore-mvc.md`](../outcomes/M2-01-restore-mvc.md))
records the real `{ M, C, V }` shape and its consumers (`.V` at
`controller.lua:401`, `.C` for event dispatch, `.M` carried for
historical parity), and explicitly does not repeat take 1's inaccurate
"no consumer reads `.V`" claim. `internals/user_input.md` is corrected
from `{ C = singleton }` to `{ M = model, C = singleton, V = view }`,
with the `.V` draw site now named, and no milestone ref-ids leaked into
the prose.

## Scope fence

Held. The diff touches only the four files M2-01 lists
(`userInputController.lua`, `tests/input/overlay_spec.lua`,
the outcome ledger, `internals/user_input.md`). The out-of-scope items
(F-4 per-env `compy.input` build, F-5 `force`-only-text, G-1/G-2 dead
code) were not touched. Two new gaps (G-A tixy shift+click sequence, G-B
editor buffer not cleared on Escape) were *reported* in the ledger, not
fixed — exactly the discipline `development.md` asks for and the one
take 1 missed.

## Rules check

- **Hard limits.** `open_fresh` body is 8 lines (≤14), nesting depth 2,
  one parameter pair. The only line >64 chars in the file (`:405`) is
  pre-existing and outside this change. ✔
- **Formatting.** Spaced-brace table literal, one field per line;
  doc-comment on its own lines; the helper sits in the singleton-API
  section under the existing banner. ✔
- **Design / "no C accent".** `open_fresh` is a plain sequence — clear,
  apply, expose, render — no tag dispatch, no string-keyed indirection.
  Extracting it keeps `show()` readable (no nested conditionals). ✔
- **Commit hygiene.** `test:` precedes `fix:`, documenting the
  red→green order; both subjects are accurate. Committer identity
  unchanged. ✔

## Residual coverage (non-blocking)

1. **Overlay-shape test runs against a stub, not the real wiring.** It
   asserts `ui.V` is truthy and calls `ui.V:draw()` on a mock whose
   `draw` is a no-op. This would catch a future re-narrowing of the
   handle to `{ C }`, which is the main regression to guard — good. It
   would *not* catch a break in the actual `controller.lua:401`
   integration or the `main.lua` singleton wiring, which is the precise
   path that faulted at runtime. The runtime confirmation on `turtle`/
   `tixy` covers it for this take, but the regression net is shape-level,
   not integration-level. A later milestone that drives the real
   `set_love_update` wrapper would close the slice take 1 first exposed.

The second gap is no longer a mere coverage note — see *C-2 verification*
below.

## C-2 verification — open acceptance gap

The empty-on-reprompt unit test uses `show({text})` → `hide()` →
`show()`, not an actual oneshot submit, so it does not reproduce the real
trigger C-2 describes (submit leaves `entered` populated, re-prompt
re-opens it). I had initially treated the human runtime check as covering
that end-to-end path — but the smoke test confirmed C-1 (no-fault) only;
the empty-re-prompt step was not obvious to the tester and was not clearly
exercised. So C-2's real submit → empty path is verified by **neither**
the suite (proxy test) **nor** runtime. M2-01's spec makes runtime
confirmation of C-2 an explicit acceptance criterion, so this is an open
gate. Closure: a unit test driving `model:handle(true)` then `show()` with
no `text`, **plus** a runtime re-check on `tixy`/`turtle`. Tracked as an
**open** acceptance gap in
[`../technical_debt.md`](../technical_debt.md).

The overlay-stub item (1) remains a genuine coverage note, logged as an
*anticipated* item to close when the real `set_love_update` path is next
driven (≈M4 dispatch).

## Acceptance checklist

- [x] `love.state.user_input` carries `{ M, C, V }` after `show()`;
  `turtle`/`tixy` no longer fault on the input frame (runtime-confirmed
  by human — C-1).
- [ ] Fresh prompt with no `init` opens empty after a prior submit —
  **not verified end-to-end** (proxy unit test only; runtime not clearly
  checked). Open C-2 acceptance gap. `hide()` and `show({force=true})`
  preserve content unchanged (verified).
- [x] Both corrective tests were red before the fix and green after —
  independently re-verified (0/2 → green).
- [x] All previously-passing tests still pass (698/0/0/0); the
  method-semantics suite is unchanged.
- [x] The outcome ledger records the real `{ M, C, V }` shape and its
  consumers; no repeat of the inaccurate "verified safe" claim.
