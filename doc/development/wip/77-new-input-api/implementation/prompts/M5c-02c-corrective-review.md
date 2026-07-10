# Review — M5c-02c: corrective take on chunk-2 findings

_Commissioned by the opus-sweeper PM, session02, 2026-07-10 (autonomous). **Target reviewer: Claude
Opus**, `agents/review.md`. This reviews the **corrective take** (`b88bbbc`, `0186986`, `c3f3e5c`,
`b8fb8af`) that resolves the three findings in `reviews/M5c-02.md`, and — since chunk 2's landed diff
was only ever reviewed by the Antigravity experiment, not the standing Opus reviewer — it doubles as
the **standing Opus sign-off on chunk 2 as a whole**. Follow `../review-prompt.md` mechanics
(verify-don't-trust, re-run suite, scope fence, rules, tech-debt + docs)._

## Fill-ins

- **Under review:** the corrective take `M5c-02c` **and** chunk-2 (`M5c-02 — widget outputs`) in its
  corrected final state.
- **Spec (authoritative):** `design/spec/M5c-dispatch-chain.md` — Scope 4 (non-submit half), Scope 7;
  **AC-14, AC-15, AC-16, AC-42(a)**. Authority above: `design/notes/ratified-model.md` (R12, D-5, D-b,
  R3) → `design/spec.md` §4/§7.
- **Commissions:** [`M5c-02-widget-outputs.md`](M5c-02-widget-outputs.md) (the chunk) +
  [`M5c-02c-corrective.md`](M5c-02c-corrective.md) (the take). Read the chunk-2 review note
  [`M5c-02-widget-outputs-review.md`](M5c-02-widget-outputs-review.md) for the original 7 traps.
- **Outcomes:** `outcomes/M5c-02-widget-outputs.md` + `outcomes/M5c-02c-corrective.md`.
- **Commits to diff:** `b88bbbc b8fb8af 0186986 c3f3e5c` (corrective) over the chunk-2 base
  `6a3215e`/`f280096`.

## Verify the four corrections landed and are complete

1. **`is_at_limit` ≤14 body lines, behaviour unchanged.** Confirm the refactored body is within limit
   **and** the full AC-15 matrix (up/down/left/right × input/line, single-line collapse) still holds —
   the implementor kept `elseif` and swapped in `get_cursor_pos()`. Re-run the boundary rows; hand-check
   one horizontal + one line-scope case against the pre-refactor logic. A silent behaviour change here
   is the only real correctness risk in this take.
2. **CHIEF TRAP — item-2 became a behaviour change, not a comment fix.** The implementor did **not**
   just wrap/log the over-length `-- REVIEW:` marker; they **installed the noop default it suggested**
   — seeding `on_limit_reached = noop` at the overlay singleton's construction and dropping
   `emit_limit`'s `if on_limit then` guard. Scrutinise this hard:
   - Does seeding the default **only** change the pre-any-write state (`nil` → noop), or can it
     **clobber** a user-set callback across a `hide()`→`show()`/`apply_config` cycle? Trace
     `apply_config` and the singleton lifecycle (`main.lua:364`) yourself — do not trust the ledger.
   - Is a **noop default** consistent with the ratified default-callback shape chunk 1 established
     (AC-10/AC-26) and with R12/AC-14 (return ignored)? Confirm it is not a new *public* default that
     needs a named consumer (guardrail 5) — it is an internal slot seed.
   - Did any existing row that asserted "no `on_limit_reached` set ⇒ nothing happens" change meaning?
     It should still pass (noop fires nothing observable), but verify, don't assume.
   If this seed is unsafe or out of scope, that is a finding — the safe fallback was note+debt-log.
3. **Over-length lines gone.** `userInputController.lua:322` marker resolved; the reworded test row
   (`input_contracts_spec.lua`, "left at first-line start has input scope") ≤64; grep the touched files
   for any remaining >64 line.
4. **Slot-sharing now covers all four (AC-16 / trap 1).** Four new sibling rows must prove
   `on_text_entered` **and** `validator` each reach the **same** slot via a `show({key=fn})` config key
   **and** a `compy.input.<field>` write — real production ingestion, not a stub. Confirm they assert
   **settability only** (no firing/gating — chunk-2/3 seam intact). Flag any "empty test" (asserts a
   mock was called without exercising the real slot).

## Re-confirm the chunk-2 whole still holds (condensed — full traps in the chunk-2 review note)

- Suite green at the boundary: **759/0/0/6** claimed — re-run `busted tests`, confirm; chunk-3+ rows
  still `pending`, nothing red.
- AC-33 boundary still loud, allowlist admits exactly the 4 outputs on top of chunk 1's three `on_*`;
  no accidental widening (the item-2 seed must not have opened a data key that bypasses `__newindex`).
- `is_at_limit` callers un-regressed (`editorController.lua:511-512`, view L308, controller L69) — LSP
  `references` as backstop.
- AC-42(a) highlighter proven on live text (reused model application, not duplicated); R12/AC-14
  widget-output returns carry no chain meaning.
- Scope fence: no reach into submit/cancel, validator gate, route lifecycle, M7 surface, or
  `src/examples/*`.

## Write the review

Append/extend `reviews/M5c-02.md` **or** write `reviews/M5c-02c.md` (your call — cross-link either
way): verdict (approve / corrective-take / escalate) + explicit approval-scope note stating this is now
the Opus sign-off on chunk 2, per-AC ✔/⚠/✗ with file:line, the item-2 verdict called out separately,
scope-fence + rules findings, tech-debt + docs verdict. Present a short verdict and stop — the PM holds
the (now autonomous) gate.
