# Worker task — build the REVIEW-marker inventory (INVENTORY ONLY, non-destructive)

You are a scoped worker in the compy LÖVE2D project (repo root `/repo`, your cwd). This is a
**mechanical inventory-building task**. Produce one deliverable file. **Delete/modify NOTHING
else** — do not remove or edit any `-- REVIEW:` marker, do not touch source or tests. Your only
write is the deliverable below.

## Standing hygiene (read, applies to you)
- **MCP-LSP (`lua-lsp`) exists** (defs/refs/diagnostics over a real AST). It has been **unreliable
  recently** (phantom/out-of-range refs). Use **grep as the ground-truth backstop**; use LSP only
  to confirm, never as sole evidence. After any `.lua` edit, `sleep 1` before querying it — but you
  are not editing `.lua`, so this shouldn't arise.
- Work in the shared `/repo` tree. Do **not** create git worktrees or bootstrap a luarocks env.
- Your deliverable is the durable artifact — write it to the named path, not just your final message.

## Background (why this exists)
The owner injected inline `-- REVIEW:` remarks across the input test/source files over many prior
sessions. No resolution-and-prune pass ever ran, so they've accumulated. We are building a
**persistent inventory** (lives until the PR) that will drive owner-gated cleanup: first sweeping
genuinely-dissolvable markers in small batches, then triaging the rest. Your job is **only** the
inventory — the first, complete, verbatim capture.

## Exact scope — the 138 markers (CORRECTED)
The owner's markers use a **taxonomy**, not just `REVIEW:`. The detector is **`REVIEW[:/]`** — i.e.
`REVIEW` followed by `:` OR `/kind:` (e.g. `REVIEW/clarity:`, `REVIEW/fidelity:`, `REVIEW/DOC:`,
`REVIEW/cosmetic:`, `REVIEW/nitpick:`, `REVIEW/consistency:`, `REVIEW/terminology:`,
`REVIEW/RESPONSE:`, `REVIEW/OPEN`, and compounds like `REVIEW/clarity/consistence:`). Enumerate:

```
grep -rn 'REVIEW[:/]' tests/ --include=*.lua
grep -rn 'REVIEW[:/]' src/ --include=*.lua | grep -v 'src/lib/'
```

**Expected 138 total: 114 in `tests/`, 24 in `src/`** (excluding vendored `src/lib/`). Per-file
self-check counts:
- tests/input/input_events_spec.lua = 48
- tests/helpers/input_fixture.lua = 16
- tests/input/input_routing_spec.lua = 11
- tests/input/input_widget_lifecycle_spec.lua = 10
- tests/input/input_nfr_forward_spec.lua = 10
- tests/input/highlight_shape_spec.lua = 9
- tests/input/input_cursor_text_spec.lua = 6
- tests/input/input_shortcuts_click_spec.lua = 4
- src/controller/controller.lua = 7
- src/controller/userInputController.lua = 6
- src/model/input/userInputModel.lua = 5
- src/controller/projectInputController.lua = 3
- src/util/key.lua = 2
- src/view/input/userInputView.lua = 1

If your count differs, note it. **EXCLUDE** these two uppercase-REVIEW lines — they are prose, NOT
markers: `tests/input/input_routing_spec.lua:13` ("SUITE-LEVEL REVIEW NOTES" header) and
`tests/helpers/input_fixture.lua:128` ("The line-123 REVIEW that used to sit here…"). **Do NOT**
inventory `doc/`, `wip/`, or vendored `src/lib/`. A remark may span **multiple lines** (continuation
lines have no token) — capture the FULL remark verbatim, not just the first line.

## Deliverable
Write `doc/development/wip/77-new-input-api/validation/notes/review-marker-inventory.md`.

Structure:

1. **Header block:** purpose (one paragraph); the maintenance protocol (this is a living doc,
   updated after each sweep — dispositions filled in the Disposition column, removed markers struck
   through not deleted); the exact scope + the two grep commands used; the total count; a one-line
   note that `doc/`/`wip/`/vendored were surveyed and excluded as citation-only/not-ours.

2. **One section per file** (natural batch boundary), files ordered `tests/` first then `src/`.
   Under each file, one entry per marker, in line order:

   - **ID** — stable, globally sequential: `RVW-001`, `RVW-002`, … (assign in file-then-line order
     over the whole inventory; never reused).
   - **Location** — `path:line`.
   - **Kind** — the marker's self-declared taxonomy suffix, verbatim: `plain` (bare `REVIEW:`),
     `clarity`, `fidelity`, `DOC`, `cosmetic`, `nitpick`, `consistency`, `coherence`, `quality`,
     `terminology`, `RESPONSE`, `OPEN`, or a compound (`clarity/consistence`, `fidelity/consistency`,
     …). Record it as written — it is bucketing signal (`cosmetic`/`nitpick`/`clarity` lean
     dissolvable; `fidelity`/`DOC`/`consistency`/`architecture` lean triage).
   - **Verbatim** — the complete remark text (all continuation lines), quoted. Do not paraphrase.
   - **Comments-on** — one line: the test name / function / code the marker sits above or within.
   - **Bucket** (provisional first cut — the owner re-decides, so be conservative):
     - `DISSOLVE?` — plausibly dissolvable WITHOUT owner judgment: the concern is already resolved
       by later code/tests (cite the current code you checked), obsolete, a trivially-answerable
       question, a pure cosmetic/typo note, or a duplicate superseded by another marker (cite its
       ID). **Only use this when you can point to concrete current-code evidence** — otherwise use
       TRIAGE.
     - `TRIAGE` — needs owner judgment: a live design/architecture/coverage concern, a proposed
       structural change, a relocate suggestion (e.g. "belongs under tests/editor"), or anything you
       are unsure about. Default here when in doubt.
   - **Rationale** — one line, evidence-anchored (e.g. "code at userInputController.lua:399 still
     names `gate`; naming Q stands → TRIAGE" or "R4 deleted this branch, concern moot → DISSOLVE?").
     For DISSOLVE?, name the file:line or decision you checked. Consult `decisions/input.md` and
     `internals/user_input.md` when a marker asks whether something is intended/documented.
   - **Disposition** — leave as `—` (filled during later sweeps).

3. **Summary table at the end:** counts by bucket, and a per-file count, so batches can be planned.

Keep it skimmable — this is a working index, not prose. Telegraphic is good.

## Report back
End with: the total marker count (and any deviation from 138 = 114 tests + 24 src), the
DISSOLVE?/TRIAGE split, the Kind distribution, any markers ambiguous to bucket, and the deliverable
path. Nothing else changed on disk.
