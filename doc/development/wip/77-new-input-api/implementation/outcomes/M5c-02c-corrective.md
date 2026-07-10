# Outcome — M5c-02c-corrective: chunk-2 review findings

_Executed as a one-shot corrective pass for
[`../prompts/M5c-02c-corrective.md`](../prompts/M5c-02c-corrective.md),
2026-07-10, applying all four findings from
[`../reviews/M5c-02.md`](../reviews/M5c-02.md) against the landed
`6a3215e`/`f280096` chunk-2 code. No new behaviour, no chunk-3 reach._

## Surprise note

Item 2 (the over-length `-- REVIEW:` comment) turned out to be the
trivial, in-scope resolution rather than the deferred one: the overlay
controller is a true singleton constructed once (`main.lua:364`), so
seeding `on_limit_reached = noop` at construction time changes only the
pre-any-write default (nil → no-op) and leaves `apply_config`'s existing
`if cfg.field ~= nil then self.field = cfg.field end` preserve-across-
hide/show pattern untouched. No test needed loosening to prove it; full
suite stayed green. Flagged here because it was the one item with real
risk of a silent semantics change, so it earned the closer look.

## The four items

### 1. `is_at_limit` body length (14-line hard limit)

- **Where:** `src/model/input/userInputModel.lua:559-573` (was 559-581,
  21-line body).
- **What:** Adopted the review's sketch with one change — kept `elseif`
  (house style; `agents/rules.md` formatting + existing `elseif` usage in
  this same file) instead of the review's `if`/`return false` tail.
  `get_cursor_pos()` now replaces the separate `get_cursor_y()` +
  `get_cursor_x()` calls; the horizontal branches collapsed to
  `cc == 1 and (req == 'line' or cl == 1)` and its `right` mirror.
- **Verification:** Traced both branches by hand against the original
  four-way `if req == 'line' … else …` nesting — identical truth table.
  Body is now exactly 14 lines (560-573).

### 2. Over-length `-- REVIEW:` comment — disposition: **install it**

- **Where:** `src/controller/userInputController.lua`.
- **Chosen path:** installed the noop default, per the marker's own
  suggestion, and deleted the marker (the "cleaner resolution" branch of
  the prompt's decision tree).
- **What:** `UserInputController`'s constructor (`new`) now seeds
  `on_limit_reached = noop` (the existing global `util.lua` noop;
  `require("util.lua")` added to this file's requires, matching how
  `userInputModel.lua` already requires it). `emit_limit` in `keypressed`
  dropped its `if on_limit then … end` guard and became an unconditional
  one-line alias: `self.on_limit_reached(dir, scope)`.
- **Why this is safe (the check that justified "trivial, in-scope"):**
  the published overlay controller is constructed exactly once
  (`main.lua:364`) and never recreated — `show()`/`hide()` only toggle
  `love.state.user_input`, not the controller object. So the default is
  seeded once, before any config/field write, and `apply_config`'s
  conditional assignment (`if cfg.on_limit_reached ~= nil then … end`,
  unchanged) still preserves a field- or config-set callback across a
  `hide()` → `show()` cycle that omits it from the next config — the
  starting value moved from `nil` to a no-op function, nothing else did.
  This is orthogonal to the M5c-01 outcome's caution against a stored
  noop default for the tier-3 dispatch chain (`on_* or native`
  precedence) — `on_limit_reached` has no native counterpart to precede
  over, it is called directly, so that R7 hazard does not apply here.
- **Verification:** full suite green; no assertion added/loosened for
  this item (it's a pure internal-default change, same as item 1).

### 3. Over-length test declaration

- **Where:** `tests/input/input_contracts_spec.lua:1229`.
- **What:** `'left at first-line start reports input scope'` (65 chars)
  → `'left at first-line start has input scope'` (61 chars). Same
  assertion body, unchanged; the sibling at `:1245` (63 chars) was
  already compliant and left untouched, per the prompt's note.

### 4. Incomplete slot-sharing coverage (AC-16 / review-trap 1)

- **Where:** `tests/input/input_contracts_spec.lua`, four new sibling
  `it` rows after the existing `show(config) and fields share one output
  slot` test (lines ~1133-1163).
- **What:** Added `show(config) shares on_text_entered slot`, `field
  write shares on_text_entered slot`, `show(config) shares validator
  slot`, `field write shares validator slot`. Each drives
  `F.compy_input()` (the real project-facing surface, real production
  ingestion, no stub) and asserts identity through both the `show({<key>
  = fn})` config-key path and a direct `compy.input.<field> = fn` write,
  mirroring the existing `on_limit_reached` (config path) / `highlighter`
  (field path) pattern but applying **both** paths to each of the two
  remaining outputs, per the review-trap wording. Both stay
  settable-only — no firing/gating assertion added (chunk 3's seam
  stayed intact); confirmed the shared slot genuinely exists for both
  before writing the assertions (it does — `consoleController.lua`'s
  `get_compy_input()` backs all four keys with the same `state` table
  regardless of write path), so no chunk-2 defect to report here.

## Commit refs

- `refactor(input): shrink is_at_limit to the 14-line body limit`
- `fix(input): install on_limit_reached noop default, drop REVIEW marker`
- `test(input): shorten over-length declaration; cover slot-sharing for on_text_entered/validator`
- (see `git log` on this branch for the actual hashes — filled in below
  after committing)

## Verification

- **Before (baseline, re-run at session start):** `busted tests` →
  `755 successes / 0 failures / 0 errors / 6 pending`.
- **After (full suite, all four items applied):** `busted tests` →
  `759 successes / 0 failures / 0 errors / 6 pending` (+4, the new
  slot-sharing rows; no row removed, none loosened).
- **Targeted:** `busted tests/input/input_contracts_spec.lua
  tests/input/user_input_model_spec.lua tests/input/user_input_view_spec.lua`
  → `138 successes / 0 failures / 0 errors / 6 pending`, confirming the
  AC-15 boundary matrix and the `is_at_limit`/view specs stayed green
  through the refactor.
- **LSP diagnostics:** re-ran on both touched source files after each
  edit (1s settle); no new diagnostics beyond the codebase's existing
  sparse-`@field`-annotation style (the same "fields cannot be injected"
  hint already present for `validator`/`on_text_entered` before this
  take, now also shown for `on_limit_reached`'s constructor seed —
  cosmetic, not a runtime concern, LuaJIT has no type checker).

## Technical debt ledger

- Closed the three open `M5c-02` rows in
  `implementation/technical_debt.md` (dispatch map + detail sections):
  the `is_at_limit` body-length item, the incomplete slot-sharing test,
  and the line-length violations. No new debt item opened — item 2
  resolved cleanly rather than deferring.

## Surfaced gaps

- None. All four items were confirmed real findings and closed within
  this take's boundaries; nothing reached into chunk 3 behaviour,
  chunk 4 lifecycle, or `src/examples/*`.
