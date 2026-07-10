# Review — M5c-04: route-connection lifecycle (chunk 4 review boot)

_For the **Opus reviewer** (`agents/review.md`). Milestone id `M5c-04`. Chunk 4 of the M5c carve —
route-connection lifecycle (Scope 5). Review the finished diff + `outcomes/M5c-04-route-lifecycle.md`
against `design/spec.md §8` (authoritative) + frozen `design/spec/M5c-dispatch-chain.md` (Scope 5,
AC-27…AC-30) + `design/spec/M6-02-before-exit.md` + the rules. Verdict only — **never rewrite feature
code**; edit only your review + `technical_debt.md`. **lua-lsp is DOWN this session — use grep
backstop, do not fabricate LSP output.**_

## Verify-don't-trust (do these yourself, first)

- **Re-run `busted tests`** and record real counts (baseline entering chunk 4 = **771/0/0/5**). No red
  rows at the boundary; m7 rows stay pending.
- **`grep -n "app_state ~= 'running'" src/controller/projectInputController.lua`** — must be **gone**
  (AC-27 forwarding removed). Then confirm the slots are actually **restored at the transition**
  instead (grep the non-blocking-return path in `consoleController.lua` / `set_default_handlers`), not
  merely deleted leaving a hole.
- **`grep -rn active_keyboard_route src/ tests/`** — the accessor + its committed-suite assertion
  should be gone (C23); the only surviving reference may be the **untracked** `src/tests/autotest.lua`
  (which the diff must NOT commit). Verify the `stop names the console` row was **retargeted to AC-29
  teardown**, not just deleted.
- **`grep -rn before_exit src/`** — `compy.before_exit` added on the `compy` namespace (not
  `compy.input`), default noop+log, reset on stop.

## The traps (rank the review around these)

1. **Scope-fence / over-reach — THE headline check.** Chunk 4 delivers AC-27/28/29/30 + M6-02 and
   **nothing else**. The route-equivalence REVIEW markers (`controller.lua:190/191/192/195/197/207/695`)
   must be **left in place, untouched** — if the diff renamed `occupy_keyboard`, de-specialised PIC,
   unified console/editor/project routes, or reshaped wrap-vs-assign, that is the Gate-2-forbidden
   opportunistic unification: **finding / escalate**. The L213-214 `_defaults`/TODO marker MAY be
   resolved (AC-27 removes that forwarding) — confirm it was resolved *by the forwarding removal*, not
   by a redesign.
2. **AC-27 mechanism is real, not cosmetic.** After a non-blocking `main.lua` returns, typing must
   reach the REPL because the slots were **restored to the console route**, proven by a row that drives
   the real gateway and asserts REPL receipt — not by the deleted forwarding still secretly present
   elsewhere. Confirm the pointer slots are **still hooked** in `'project_open'` (AC-28) — a row must
   show a pointer example stays clickable; pointer disconnect must NOT have been unified in.
3. **AC-29 teardown is complete.** Stop resets `compy.input.handlers.*` **and every mutable field**
   (`on_*`/`before_*`/`after_*` + the four widget outputs), a shown widget is **silently hidden with NO
   cancel chain** (AC-19's chain must not fire at teardown), and nothing project-installed survives.
   Verify the teardown invariant with a row that installs participants, stops, and asserts they are
   gone — not just that `clear_user_handlers` was called.
4. **M6-02 `compy.before_exit`** fires **once**, **before** framework cleanup (so `love.*` is still
   safe), default noop, **reset on stop** (part of teardown), return **ignored** (cannot suppress
   stop), no args. Verify timing (before cleanup) and the reset, not just existence.
5. **AC-30 inspect:** project route disconnected, widget unhonoured; no special rules. Confirm a row.
6. **Did chunk 3 get undone?** The submit-time deactivate + Escape-dismiss are chunk 3's; chunk 4 adds
   route-level teardown *around* them. Verify chunk-3 rows still green and the submit/cancel chains
   intact.
7. **Hard limits + hygiene:** line ≤64, fn body ≤14, params ≤4, nesting ≤4; no string-tag dispatch;
   pinned-remark dispositions present and citable (incl. the L213-214 resolution and the explicitly
   left-in-place route-equivalence markers); every `-- REVIEW:` this chunk homes reconciled or left with
   a reason.

## Escalation check

If the implementor **stopped and escalated** on the route-model seam (spec §8 not closing without a
redesign), that is a legitimate outcome — assess whether the escalation is real (a genuine §8 gap) or
whether AC-27 was in fact implementable as spec'd. If they made a **conservative-reversible call** on a
small ambiguity and flagged it surprise-first, verify it is genuinely reversible and low-blast — not a
route-model ruling smuggled in under "conservative."

## Ledger discipline (guardrail 2/3)

The outcome must open with "what will surprise the architect" (incl. explicitly that the route-
equivalence markers were left in place), then per-AC checklist + remark-disposition table +
`-- REVIEW:`/`>> REVIEW` reconciliation ledgers + the `active_keyboard_route`/autotest.lua impact note.
Every non-obvious bullet cites a corpus ref. Uncitable ⇒ a judgment call that should have been a stop.

## Verdict

`approve` / `corrective-take` (exact findings: file:line + the AC/rule each violates) / `escalate`
(a real §8 spec-gap the implementor should have — or did — stop on). Report the busted counts. Write
`reviews/M5c-04.md`.
