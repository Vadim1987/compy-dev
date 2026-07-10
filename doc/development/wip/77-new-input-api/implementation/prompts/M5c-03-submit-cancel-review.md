# Review — M5c-03: submit / cancel (chunk 3 review boot)

_For the **Opus reviewer** (`agents/review.md`). Milestone id `M5c-03`. Chunk 3 of the M5c carve —
the submit/cancel path (Scope 3). Review the finished diff + `outcomes/M5c-03-submit-cancel.md`
against the frozen `design/spec/M5c-dispatch-chain.md` (Scope 3, AC-17…AC-26/39/42(b)/43) + the rules.
Verdict only — **never rewrite feature code**; edit only your review + `technical_debt.md`._

## Verify-don't-trust (do these yourself, first)

- **Re-run `busted tests`** and record real counts. Baseline entering chunk 3 was **759/0/0/6**. The
  two `#deprecated` rows must end **`pending()`-or-deleted, never red** at the boundary (AC-35/AC-39);
  m7 rows stay pending. If any row is red, the chunk is not done.
- **`grep -n oneshot src/`** — the ONLY surviving `oneshot` occurrences may be `profiler.lua` and
  `lib/metalua/*` (a different, unrelated symbol). Any remaining `model.oneshot` / `is_oneshot` /
  view `self.oneshot` reader ⇒ AC-25 / M6-01 incomplete. Use lua-lsp `references` to confirm no live
  caller of the deleted symbols survives.
- **`grep -n "push('userinput')\|love_event('userinput')" src/`** — the *producer* must be gone
  (AC-25). But confirm the *polling consumer* idiom still exists (E32 producer-m5c/consumer-m8 split —
  removing the consumer here is an over-reach, flag it).

## The traps (rank the review around these)

1. **R1 — `on_text_entered` is the SUBMIT output, not per-char.** It must fire **once** at Enter with
   the **full assembled** text. `on_text_input` is the separate per-char tier-3 callback `(text,
   keys_pressed)`. AC-40 requires **both** tested and distinct. A greening that keeps a per-character
   `on_text_entered` body re-encodes the R1 trap the split was meant to kill — **reject it.**
2. **AC-17 order is exact:** `before_submit(keys_pressed)` → validator → `on_text_entered(text)` →
   **deactivate** → `after_submit(text)`. AC-25 observable order: `on_text_entered` sees the session
   **still active**, `after_submit` sees it **deactivated**. Verify the sequencing in a test, not just
   that the calls exist.
3. **AC-18/42(b) validator reject:** error shown, input **locks** until acknowledged, `on_text_entered`
   AND `after_submit` do **NOT** fire, session stays active. Confirm a rejecting validator is proven to
   gate (functionally, not just settable).
4. **AC-39/AC-43 retirement lifecycle:** the two `#deprecated` rows (`a submit fills the handle and
   closes` L365, `a oneshot submit deactivates the widget` L477) must be **deleted only after** an
   equivalent new-chain green row exists — verify the replacement green row actually covers
   submit→validator→on_text_entered→deactivate. A silent delete without a green replacement, or a row
   left red, is a finding. `a refused solicitation warns` must **stay**.
5. **Chunk-3/4 seam — over-reach check.** Chunk 3 owns **submit-time** deactivate + Escape-dismiss
   only. If the diff removed the `app_state ~= 'running'` forwarding
   (`projectInputController.lua:143-168`), built the project-stop reset of `handlers.*`/callbacks, added
   `compy.before_exit`, or touched the projectInputController REVIEW markers (L66/70/76/97/117/141/142)
   — that is **chunk-4 scope pulled in early**: flag it. AC-24 requires callbacks/handlers **persist
   across deactivation**; the stop-*reset* is chunk 4.
6. **AC-20/21/22 tier-1 gating:** Enter/Escape are framework entries **only while shown** (hidden ⇒
   ordinary keys down the chain); not shadowable by project handlers (framework-first);
   **Shift+Return is NOT intercepted** (reaches the sink → newline when multiline). Verify all three.
7. **AC-23 no cancel chain on `hide()`/`show()`;** `{force=true}` reconfigures in place. **AC-24**
   continuous-session idiom (`after_submit` re-`show`) re-activates in the same sequence.
8. **R12/R13:** the sink/widget-output return still carries no chain meaning; consuming never removes a
   tier. No re-introduced replace/suppress semantics.
9. **Hard limits + hygiene:** line ≤64, fn body ≤14, params ≤4, nesting ≤4; no string-tag dispatch;
   pinned-remark dispositions present and citable; every `-- REVIEW:` this chunk homes reconciled (not
   silent-deleted); M6-01 view snapshot + `@field` actually gone.

## Ledger discipline (guardrail 2/3)

The outcome must open with "what will surprise the architect", then carry a **per-AC checklist**, the
**AC-39/43 retirement ledger**, the **remark-disposition table**, and the **`-- REVIEW:` / `>> REVIEW`
reconciliation ledgers**. Every non-obvious bullet cites a corpus ref. Uncitable ⇒ a judgment call
that should have been a stop — call it out.

## Verdict

`approve` / `corrective-take` (list the exact findings with file:line and the AC/rule each violates) /
`escalate` (a real spec-gap/contradiction the implementor should have stopped on). Report the busted
counts. Write `reviews/M5c-03.md`.
