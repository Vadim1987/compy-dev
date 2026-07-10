# Review — M5c-02: widget outputs (chunk 2 of the M5c carve)

_Commissioned by the opus-sweeper PM, session02, 2026-07-09. **Target reviewer: Claude Opus**,
running `agents/review.md`. Follow the generic bootloader
[`../review-prompt.md`](../review-prompt.md) for the mechanics (verify-don't-trust, re-run the suite,
re-verify red-before, scope fence, rules check, tech-debt + docs). This note fills its placeholders
and pins the chunk-specific traps — the surface here is narrow (an additive output layer) but the
chunk-2/3 seam is the sharp edge._

## Fill-ins (for the bootloader)

- **Under review:** `M5c-02 — widget outputs` (chunk 2 of the M5c carve).
- **Spec (authoritative):** `design/spec/M5c-dispatch-chain.md` — **Scope 4 (non-submit half), Scope
  7 (allowlist)**; **AC-14, AC-15, AC-16, AC-42(a)**. Authority above it:
  `design/notes/ratified-model.md` (canonical — R12, D-5, D-b, R3) → `design/spec.md` §4/§7.
- **Commission:** [`M5c-02-widget-outputs.md`](M5c-02-widget-outputs.md) — read its **Boundaries** and
  the **chunk-2/3 seam** section; much of Scope 4's *behaviour* is deferred to chunk 3 and must NOT
  appear here.
- **Outcome to review:** `implementation/outcomes/M5c-02-widget-outputs.md`.
- **Commits:** the hashes the outcome lists (review the **diff**).

## This is chunk 2, not the slice — judge against the chunk's scope

Do **not** dock the chunk for absent submit/cancel, the validator **gate**, `on_text_entered`
**firing**, route-lifecycle changes, or the turtle/maze migration — those are **later chunks by
design**. Confirm the implementor did **not** reach into them (scope fence): no `before_/after_`
chains, no Enter/Escape framework entries, no validator gate / reject-lock, no `oneshot`/`push`
deletion, no M4 ruling-1 forwarding removal, no M7 `configure`/cursor surface, no `src/examples/*`
edits.

## Chunk-specific traps — verify these hard

1. **The settable-here / behaves-in-chunk-3 seam (chief trap).** `validator` and `on_text_entered`
   must be **settable + stored** (AC-16) but must **not fire/gate** in this chunk. Verify: no green
   row asserts `on_text_entered` was *called*, and no green row asserts the validator *rejected/locked*
   the session — those are chunk-3 rows and must stay **pending** if present. Conversely, a real
   settability assertion (config key **and** field both reach the same slot) **must** exist for all
   four outputs. If the implementor pulled submit wiring in to make storage work, that is a seam
   collision that should have been an **escalation** — flag it.
2. **AC-16 one-slot-two-ergonomics actually proven.** For each of the four outputs, check a `show()`
   config key **and** an assignable `compy.input.<field>` write land on the **same** underlying slot
   (not two divergent paths). Drive real production ingestion, not a stubbed proxy.
3. **AC-33 boundary still loud, now +4.** The `INPUT_CALLBACKS` (or output-field) allowlist admits
   **exactly** the four output fields on top of chunk 1's three `on_*`; every **other** `compy.input`
   assignment still raises. Grep for an accidental widening (a blanket accept, a data key that
   bypasses `__newindex`). The chunk-1 comment (was `consoleController.lua:349-352`) should now read as
   landed, not "NOT part of chunk 1".
4. **AC-15 `on_limit_reached(direction, scope)` — full matrix, return ignored.** `direction ∈
   up/down/left/right`, `scope ∈ input/line`, single-line collapses; verify **horizontal** (left/right)
   is genuinely exercised, not just the pre-existing vertical. Confirm its **return value is ignored**
   (observational — R12/AC-14): a truthy return from `on_limit_reached` must **not** consume or alter
   the chain.
5. **`is_at_limit` extension didn't regress its callers (D-5).** The signature grew from vertical-only
   to two scopes. Re-check every caller — `editorController.lua:511-512` (block-nav), view L308,
   controller L69 — still behaves. LSP `references` on `is_at_limit` as a backstop; a silent break here
   is the highest-blast-radius risk of an otherwise-additive chunk.
6. **AC-42(a) highlighter proven on live text, not just stored.** The queried highlight
   (`get_highlight()` / viewdata) must reflect `highlighter(text)` as text composes — an
   upper-casing (or similar) highlighter yields transformed output, asserted through the real query
   surface. A row that only asserts `compy.input.highlighter == fn` is insufficient (settability ≠
   AC-42). Confirm the model's existing application (L385–392) is **reused**, not duplicated.
7. **R12 / AC-14 boundary half.** Widget-output returns carry no chain meaning. Confirm no output
   callback's return leaks into propagation. (The submit half of AC-14 — `on_text_entered` as the
   submit-condition surface — is chunk 3; absence here is correct.)

## Hygiene to confirm (chunk-2 subset)

- **Test-first red-before** re-verified (`<hash>~1`) for the new rows.
- **`-- REVIEW:` reconciliation** for the rows this chunk touched: removed with a citing ledger line
   **or** escalated; the non-widget-output markers (e.g. L401 prompt-labelling = M7, the console
   hidden-sink musings = chunk 4 / console-migration) correctly **left in place**, not silently deleted.
- **`>> REVIEW` markers** in the code this chunk reshaped removed with a citing ledger line; unresolved
   ones remain.
- **Per-pinned-remark disposition table** present, each with a remark id; later-chunk remarks marked
   `note-only` with a pointer, not silently claimed `fixed`.
- **Suite green at the boundary** (AC-35): chunk-3+ rows pending, nothing red.
- Hard limits (line ≤64, fn ≤14, params ≤4, nesting ≤4), **no string-tag dispatch**, table-driven
   over near-duplicate blocks, `feat(input):` conventional commits, `internals/user_input.md` updated
   if the widget-output surface changed the documented shape.

## Write the review

`implementation/reviews/M5c-02.md` — verdict (approve / corrective-take / escalate) + explicit
approval-scope note, per-AC ✔/⚠/✗ with file:line, scope-fence + rules findings, tech-debt + docs
verdict. Present a short verdict and stop — the PM holds the human gate.
