# M7-01 — review note (traps to check)

_Reviewer boot (`agents/review.md`). Milestone id `M7-01`. Review the finished chunk (diff + ledger)
against `spec/M7-02-recut.md` AC-6/7/8/9/10 + the rules. **Verify-don't-trust:** re-run `busted tests`
yourself; use lua-lsp `references` to confirm no caller regressions. Edit ONLY `reviews/M7-01.md` +
`technical_debt.md`; NEVER feature code or `design/`. Verdict: approve / corrective-take / escalate +
busted counts._

## Baseline / expected end state

- Entering: **779 / 0 / 0 / 5**. Expected exit: **779 + N / 0 / 0 / 5** (N = the new cursor/text rows;
  the **5 pending must stay 5** — the four routing-gap pendings @101/@153/@161/@222 AND the m7-family
  **anchor** @1681 all remain; M7-01 must NOT retire @1681).

## Traps — the high-value checks

1. **The model fix is the one behaviour-changing edit — scrutinise it hardest.** `set_text` gated its
   tail `jump_end()` on `not keep_cursor`. **Verify via lua-lsp `references` on
   `UserInputModel:set_text`** that no existing caller depended on the old *unconditional* jump when it
   passed a truthy `keep_cursor`. Known callers include `apply_config` (`userInputController.lua`, via
   `cfg.text` — passes **no** keep_cursor → still jumps to end, unaffected). Confirm the full caller set;
   a caller that passed `keep_cursor=true` AND relied on the jump would be a silent regression. This is
   the AC-29-highlighter-leak-class risk for this chunk — an incomplete refs result hiding a caller. Grep
   `:set_text(` as the backstop.
2. **AC-10 must be satisfied by placement, not new guard code.** The three callables must be in the
   `methods` table (`consoleController.lua get_compy_input`), NOT in `INPUT_CALLBACKS`. Confirm
   `compy.input.set_text = fn` **raises**. If any new callable was added to `INPUT_CALLBACKS`, that is a
   **corrective-take** (makes it assignable — AC-10 regression).
3. **AC-6 hidden → `nil`, not `(nil, nil)` accidental / not a warn.** get_cursor on a hidden session
   returns `nil` (spec: returns nil when hidden) — it is the one method whose hidden path is *not* a
   warn-noop. Confirm the ledger/test distinguishes it from set_cursor/set_text (which DO warn on hidden,
   AC-9). Do not let a blanket "warn on hidden" leak into get_cursor.
4. **AC-7 clamp semantics.** `set_cursor` should route through `move_cursor` (which clamps), not the raw
   `set_cursor(Cursor)` primitive (no clamp). Confirm an out-of-range `col`/`line` **lands at the
   boundary**, not silently no-ops at the previous position in a way that violates "clamp to the valid
   range." If the implementor flagged a divergence between move_cursor's fallback-to-previous and
   clamp-to-range, check they chose the spec wording and tested the clamped landing.
5. **AC-8 "view reflects the change without a re-show."** Confirm `set_text` triggers a `update_view`
   (or equivalent) — not a full `show()`/teardown. And that `set_text(t, true)` preserves + clamps the
   cursor (test with new text shorter than the old cursor col).
6. **AC-9 warnings are real `Log.warn` (or the project's warn channel), asserted in tests** — not a
   comment, not a silent return. Each of set_cursor/set_text hidden branch logs.
7. **Scope fence.** No `configure`/`clear`; F-5 NOT struck; internals boundary doc NOT written; @1681
   anchor NOT retired; no `INPUT_CALLBACKS` addition; no legacy global removed; no routing/dispatch edit.
   Files limited to userInputController / userInputModel / consoleController / tests. Any overreach into
   M7-02's AC-11/AC-12 territory is a finding.
8. **Rules limits** — line ≤64, fn body ≤14, params ≤4, nesting ≤4 on the new methods. `set_cursor(line,
   col)` is 2 params + self; fine. Watch the `set_text` wrapper doesn't balloon.

## Report-don't-fix already logged

The `set_text` multiline-**string** branch (`self.entered` not reassigned for `n_added > 1`) is
pre-existing and explicitly out of scope — confirm the implementor **noted, did not fix** it. If they
fixed it, that is an (albeit benign) scope-fence break worth flagging.
