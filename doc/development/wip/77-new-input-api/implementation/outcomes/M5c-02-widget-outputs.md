# Outcome — M5c-02: widget outputs (chunk 2 of the M5c carve)

_Executed as a one-shot implementation pass for
[`../prompts/M5c-02-widget-outputs.md`](../prompts/M5c-02-widget-outputs.md),
2026-07-09. Test-first: chunk-2 rows added red, then implementation,
then full-suite verification._

## What will surprise the architect (read first)

1. **`compy.input.show(config)` now normalizes output slots before
   delegating to `UserInputController:show()`.** The four widget output
   keys (`on_text_entered`, `on_limit_reached`, `validator`,
   `highlighter`) are copied into the same backing `compy.input` state
   table and then passed back into `show()`, so config-key and field
   assignment are one slot (AC-16, spec §4, R3/D-b).
2. **`highlighter` lands as a live evaluator override, not a separate
   model path.** `show{ highlighter = fn }` (or the field slot) updates
   `model.evaluator.highlighter`; existing `text_change -> highlight()`
   then surfaces transformed highlight output via
   `model:get_highlight()` with no duplicate pipeline (AC-42(a)).
3. **Boundary signaling is now emitted at the sink and remains
   observational.** `UserInputController:keypressed()` emits
   `on_limit_reached(direction, scope)` when movement attempts cross a
   boundary; callback returns are ignored and never affect chain flow
   (AC-15 + AC-14 boundary half, R12).
4. **`is_at_limit` now accepts `direction + scope`, while preserving
   old no-arg callers.** `UserInputModel:is_at_limit(dir, scope)` was
   widened for `left/right` and `line/input`, but `is_at_limit()` with
   no direction still returns legacy top-or-bottom behaviour to keep
   existing tests and callers stable (D-5 + no-regression seam).

## Commit refs

- _Pending local commit in this session_.

## Files changed

- `src/controller/consoleController.lua`
- `src/controller/userInputController.lua`
- `src/model/input/userInputModel.lua`
- `tests/helpers/input_fixture.lua`
- `tests/input/input_contracts_spec.lua`

## Verification

- **Target red/green pass:** `busted tests/input/input_contracts_spec.lua`
  - red after adding chunk-2 rows: `60 successes / 5 failures / 6 pending`
  - green after implementation: `65 successes / 0 failures / 6 pending`
- **Full suite:** `busted tests`
  - `750 successes / 0 failures / 0 errors / 6 pending`
- **Manual check (headless):**
  - exercised `highlighter` via `show{ highlighter = fn }` and observed
    transformed `get_highlight().hl` in contract row
  - exercised `on_limit_reached` by driving left-boundary attempts and
    asserting `(direction, scope)` for input and line scopes

## Per-AC checklist (chunk scope)

| AC | Status | Evidence |
|---|---|---|
| AC-16 | met | `the four widget output fields are assignable`; `show(config) and fields share one output slot` |
| AC-15 | met | `left boundary fires output; return is ignored`; `left line boundary fires scope line` |
| AC-42(a) | met | `a custom highlighter transforms queried highlight` |
| AC-14 (boundary half) | met | `left boundary fires output; return is ignored` |
| AC-17 / AC-42(b) | deferred-to-chunk-3 | `on_text_entered delivers the submitted text` remains pending |

## Per-pinned-remark disposition table (chunk-home remarks only)

| Remark id | Disposition | Note |
|---|---|---|
| Scope-4 widget outputs surface | fixed | config-key + field slots widened and wired |
| Scope-7 allowlist widening | fixed | mutable boundary now admits all four widget outputs |
| Submit/validator gate remarks | note-only | owned by chunk 3 per commissioned seam |

## Suite `-- REVIEW:` reconciliation ledger (this chunk only)

- No existing `-- REVIEW:` rows in this chunk's touched suite area
  expressed a contradiction with AC-15/16/42(a).
- Existing submit/cancel and M7 notes remain untouched and continue to
  point at their owning chunks.

## `>> REVIEW` marker removal ledger

- No `>> REVIEW` markers were present in the code sections reshaped by
  this chunk.

## Surfaced gaps

- None in-slice; chunk-3 seam (submit firing and validator gate) stayed
  deferred as commissioned.

