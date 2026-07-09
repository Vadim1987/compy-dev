# Review — M5c-01: the dispatch chain (chunk 1 of the M5c carve)

_Commissioned by the opus-sweeper PM, session02, 2026-07-07. **Target reviewer: Claude Opus**,
running `agents/review.md`. Follow the generic bootloader
[`../review-prompt.md`](../review-prompt.md) for the mechanics (verify-don't-trust, re-run the
suite, re-verify red-before, scope fence, rules check, tech-debt + docs). This note fills its
placeholders and pins the chunk-specific traps — the review surface here is narrow but sharp._

## Fill-ins (for the bootloader)

- **Under review:** `M5c-01 — the dispatch chain` (chunk 1 of the M5c carve).
- **Spec (authoritative):** `design/spec/M5c-dispatch-chain.md` — **Scope 1, 2, 6[native-mechanism],
  7, 10**; **AC-1…AC-11, AC-31, AC-33, AC-36, AC-38, AC-40, AC-41**. Authority chain above it:
  `design/notes/ratified-model.md` (canonical — R7/R12/R13/R14) → `design/spec.md` §1/§2/§7/§8.
- **Commission:** [`M5c-01-dispatch-chain.md`](M5c-01-dispatch-chain.md) — read its **Boundaries**;
  much of M5c is **deferred to later chunks** and must NOT appear here.
- **Outcome to review:** `implementation/outcomes/M5c-01-dispatch-chain.md`.
- **Commits:** the hashes the outcome lists (review the **diff**).

## This is chunk 1, not the slice — judge against the chunk's scope

Do **not** dock the chunk for absent submit/cancel, widget outputs, route-lifecycle changes, or the
turtle/maze migration — those are **later chunks by design** (commission Boundaries). Confirm the
implementor did **not** reach into them (scope fence): no `on_text_entered`, no `oneshot`/`push`
deletion, no `before_/after_` chains, no `validator`/`highlighter`, no removal of the M4 ruling-1
`app_state` forwarding, no `src/examples/*` edits.

## Chunk-specific traps — verify these hard

1. **The suppress-while-shown flip (chief semantic trap).** The M4-landed green row `a native
   handler coexists with the sink` (was L775, `-- STALE` L767) encoded the **reversed**
   suppress-while-shown mutation. It must be **flipped** to AC-31/AC-36, not preserved. **Grep the
   whole suite for any surviving green assertion of replace/suppress semantics** (widget-shown ⇒
   callback/native suppressed) — R13 forbids it. A single survivor is a corrective-take.
2. **Two install paths + precedence (AC-31/AC-36/R7), not "replace".** Verify tier-3 is populated by
   `on_*` **or** captured native, mutually exclusive by **precedence** (`on_*` > native > noop): the
   native seeds tier-3 **only** when no `on_*`; an `on_*` never has the native override it; `love.*`
   is read **once at load**. Confirm there is **no** "assignment replaces the wrapped native"
   relationship anywhere. Confirm `native_split` and the external gating wrapper are **deleted**.
3. **Four cases × three channels × both paths (AC-36) actually asserted** — not a thin subset. For
   the populating participant on each channel: (a) invoked regardless of widget-shown state; (b)
   truthy intercepts (sink skipped); (c) falsey falls through to the sink; (d) default noop ≡
   non-intercepting. Check the tests **drive real production dispatch**, not a stubbed proxy that
   only asserts a mock was called (empty-test gate, `agents/review.md`).
4. **R14 — per-event sub-tables, no flat table.** `handlers.keypressed`/`.keyreleased`/`.textinput`
   are distinct; AC-41's flat-table pending row is expanded to three real rows. **No** `handlers[combo]`.
5. **R12 — sink return carries no chain meaning.** The sink is terminal with an **internal**
   hidden-check; its return must not leak into propagation. AC-11/AC-13: hidden ⇒ debug-log only,
   **nothing mutates**.
6. **AC-8 proxy is genuinely read-only** — `keys_pressed.__newindex` raises at every tier incl. the
   sink. AC-9: keyreleased consumers see the key already gone. **AC-38:** `isrepeat` passed through
   to tier 3 only; combo-on-repeat is DEFERRED and must **not** be asserted.
7. **AC-33 is intentionally incremental here.** The guard must raise on unknown `compy.input`
   assignment, allowlisting **only** chunk-1 slots (`handlers.*` + three `on_*`). Later chunks extend
   it — confirm the ledger says so; do **not** flag missing `before_*`/widget-output slots as a defect.
8. **AC-40 split honoured.** `on_text_input` (per-char tier-3) is real and tested; `on_text_entered`
   (submit output) stays **pending** (chunk 3) — a per-character `on_text_entered` body is the R1 trap
   and a corrective-take if present.

## Hygiene to confirm (chunk-1 subset)

- **Test-first red-before** re-verified (`<hash>~1`) for the new/flipped rows.
- **AC-37 reconciliation** for the rows this chunk touched: every `-- REVIEW:` either removed with a
  ledger line citing an AC, or escalated — **none silently deleted, none dangling**.
- **`>> REVIEW` markers** in `projectInputController.lua`/`controller.lua` that the rebuild resolves
  are removed with a citing ledger line; unresolved ones remain.
- **Per-pinned-remark disposition table** present, each with a remark id; later-chunk remarks marked
  `note-only` with a pointer, not silently claimed `fixed`.
- **Suite green at the boundary** (AC-35 discipline): later-chunk rows pending, nothing red.
- Hard limits, `feat(input):` conventional commits, `internals/user_input.md` updated for the landed
  chain shape.

## Write the review

`implementation/reviews/M5c-01.md` — verdict (approve / corrective-take / escalate) + explicit
approval-scope note, per-AC ✔/⚠/✗ with file:line, scope-fence + rules findings, tech-debt + docs
verdict. Present a short verdict and stop — the PM holds the human gate.
