# M8-03 — review note (traps to check) — THE TERMINAL CHUNK

_Reviewer boot (`agents/review.md`). Milestone id `M8-03`. Review the finished chunk (diff + ledger)
against `spec/M8-02-recut.md` **AC-1, AC-2, AC-7, AC-10** (+ AC-6/AC-8/AC-9) + the rules. **Verify-don't-
trust:** re-run `busted tests` yourself; **smoke-load all five migrated examples yourself**
(tixy/repl/guess/valid/balloons — they must still run with the globals GONE); read the diff; use lua-lsp
to confirm the zero-references claim. Edit ONLY `reviews/M8-03.md` + `technical_debt.md`; NEVER
feature/example code or `design/`. Verdict: approve / corrective-take / escalate + busted counts. **If you
APPROVE, the whole #77 sweep is COMPLETE — say so explicitly.**_

## Baseline / expected end state

- Entering: **809 / 0 / 0 / 4**. Exit: green, **N / 0 / 0 / 4** where N = 809 − deleted-legacy-rows +
  new-nil-call-rows. The **4 pending must stay 4** (routing-gap cells @101/@153/@161/@222 — NOT this
  chunk's). No new failures/errors.
- **Code change confined to `src/controller/consoleController.lua`** (per the spec Files list). Any edit to
  `evaluator.lua` / `userInputController.lua` / `projectInputController.lua` / `controller.lua` /
  `src/model/*` = scope-fence break → scrutinise / likely **corrective-take** (the removal is designed
  self-contained; a forced edit elsewhere is a finding the implementor should have reported, not silently made).

## Traps — the high-value checks

1. **AC-1: all SIX globals are gone as ordinary nil fields.** In `consoleController.lua` project-env
   builder, confirm `user_input`/`input_code`/`input_text`/`write_to_input`/`validated_input` **and**
   `astv_input` are removed — no shim, no deprecation stub. Verify the test asserts each is `nil` on the
   real `F.cc:get_project_env()`. Grep consoleController for each name → only comments (if any) remain, no
   `project_env.<name> =`.
2. **The machinery is fully gone + zero dangling refs.** `input_ref`, `create_input_handle`, and the
   `input(eval,prompt,init)` helper are removed. Use lua-lsp `references` + grep on all three → **zero**
   remaining. A leftover `input()` call (e.g. a missed `astv_input`) or an orphaned `input_ref` = corrective.
3. **AC-2: the dead write is gone with no reader/writer.** `compy_namespace.text_input = input_text` (was
   L887) removed; grep the whole tree for `.text_input` (excluding `on_text_input`) → zero. And no code
   reads/writes the reftable / `is_empty()` poll surface anywhere (grep `is_empty`/`new_reftable` in the
   project-facing paths).
4. **`astv_input` — the pinned ruling (surprise-first).** Confirm it was removed **with** the machinery and
   the ledger flags it surprise-first as the sixth global (not in the spec's five-census). It must NOT have
   been re-plumbed onto `compy.input` (that would be unrequested new surface) nor left dangling (it calls
   the removed `input()` → would break). Removed-and-flagged is the only correct outcome.
5. **AC-7: `love.state.user_input` reflects widget activation ONLY.** Confirm the overlay handle STILL
   works (it is set by show/hide, not the removed reftable). `controller.lua`'s `get_user_input()` + the
   mouse/touch handlers + `src/types.lua:144` must be **untouched** (they reference the overlay handle, not
   the globals). Verify no legacy path drives `love.state.user_input` after removal (the `result=input_ref`
   passthrough is gone). The migrated examples' widget activation still lighting up = the live proof.
6. **The legacy tests were correctly resolved.** The `#legacy` block became AC-1 nil-call assertions; the
   `'legacy solicitation still fills the reftable'` row was deleted (its subject is gone). Confirm no legacy
   WIRING test still calls `env.user_input()`/`env.input_text()` etc. (grep the spec → zero live calls).
   Confirm the deletion didn't drop real coverage the ledger doesn't account for (the submit-deactivates
   half is covered by the AC-26 no-hooks row — verify it's still there + green).
7. **AC-10 / AC-8: priority examples still run with the globals gone.** Smoke-load tixy/repl/guess/valid
   **and** balloons yourself → traceback-free, no straggler nil-call (a nil-call would traceback on load if
   any example still touched a removed global). Honest ceiling (no keystroke injection → human hand-play
   gate) — confirm the ledger states it, doesn't overclaim.
8. **AC-6 natives untouched; AC-9 nested `.git` untouched.** No pure-native or example file edited this
   chunk. balloons' detached `.git` unchanged (`cd src/examples/balloons && git log --oneline -1` → still
   `56347d0` on top, unpushed, no new M8-03 commit). No in-repo example file in the M8-03 diff.
9. **Doc sync is proportionate + honest.** `internals/user_input.md` (required) reflects `compy.input.*` as
   the sole project input surface with the legacy globals retired — verify it's actually updated, not just
   claimed. If the implementor flagged example-doc drift as a follow-up rather than doing it all, that's
   acceptable (bounded terminal chunk) — confirm the FLAG is explicit, not a silent skip of the required
   surface doc.
10. **`src/vadexamples/` correctly LEFT ALONE.** It's untracked scratch (not shipped) — the implementor
   should have noted it (it still uses the globals, would nil-crash if run) but NOT migrated/deleted it.
   Confirm no `vadexamples` file is in the diff. Editing untracked scratch would itself be a scope wander.
11. **Report-don't-fix respected.** The controller-side dead `result`/reftable path (now unreachable with
   `input()` gone) should be LOGGED as tech debt, NOT removed in this chunk (it's `src/controller/*`,
   outside the consoleController-only Files scope). If the implementor removed it, flag the scope wander
   (even if benign). If they missed it entirely, note it for the debt log.
12. **Rules limits** on any new/changed test + doc-adjacent code: line ≤64, fn body ≤14, params ≤4,
   nesting ≤4. The removal itself only deletes; the new nil-call test closures should be tidy.

## Verification you must do yourself (verify-don't-trust)

- Re-run `busted tests` → confirm green + the 4-pending unchanged + the nil-call rows real and green.
- lua-lsp `references` on `input` / `input_ref` / `create_input_handle` (in consoleController) → zero; grep
  the tree for the six global names → only `src/vadexamples/` (untracked) + comments remain, no live
  console/example/test caller.
- Smoke-load tixy/repl/guess/valid/balloons headless (`xvfb-run -a love src play src/examples/<name> 2>&1 |
  head -40`) → each traceback-free with the globals gone. Spot-check one pure-native (AC-6).
- Read `internals/user_input.md` → confirm the legacy globals are actually retired and `compy.input.*` is
  documented as the sole surface.
- `cd src/examples/balloons && git log --oneline -1` → confirm `56347d0` untouched (no M8-03 commit there).

## The close-out call

If the suite is green with all six globals gone, the machinery has zero refs, AC-1/2/7/10 hold, and the
examples still run: **APPROVE and state plainly that the #77 new-input-API sweep is COMPLETE.** If a real
defect survives, **CORRECTIVE-TAKE** with the minimal red-then-green fix. If a genuine design gap surfaced
(e.g. removal can't be self-contained), **ESCALATE**. Do NOT edit feature/example code or `design/`; do
NOT push; do NOT touch balloons `.git`.
