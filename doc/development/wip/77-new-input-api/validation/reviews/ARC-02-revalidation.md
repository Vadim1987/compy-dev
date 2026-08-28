# ARC-02 Revalidation Report — `show` composes `configure`

**Date:** 2026-08-28  
**Scope:** Revalidation of the ten `ARC-02` commits (`b325826d` .. `ee59ccdc`) per [`agents/rules/revalidation.md`](../../../../../agents/rules/revalidation.md) and task mandates in `session51/prompt.md` / `session53/prompt.md`.  
**Baseline:** `990 successes / 0 failures / 0 errors / 10 pending` (clean).

---

## 1. Intent Reconstruction

`ARC-02` aimed to establish a clean, predictable configuration boundary between `compy.input.show` and `compy.input.configure` by ensuring user content (`text`, `cursor`) is owned by `show` alone (activation baseline), while project-owned settings (`prompt`, `highlighter`, `validator`, `on_text_entered`, `on_limit_reached`) are set-if-given, persistent until replaced, and processed symmetrically by both entry points (`show` composing `configure`).

---

## 2. Intent-vs-Outcome Coherence

- **Internal Coherence:** The implementation cleanly separates activation (`reset_content`) from project options (`configure_core`). `show` composes `configure_core` rather than duplicating options logic.
- **Coherence toward Intent:** All arbitrary retention/deferral hacks (`state.pending`, `re_show`, `stash_hidden_configure`, `PER_SHOW_KEYS`, `live` table) were deleted. A forced `show` (`force=true`) performs a clean, full re-setup.
- **Coherence toward Surrounding Context:** The boundary integrates seamlessly with `ProjectInputController` dispatch and `UserInputController` lifecycle without introducing extra state stores.
- **Updated-Surroundings Self-Coherence:** `doc/input_api.md`, `doc/development/internals/user_input.md`, `doc/development/decisions/input.md` (Decision 35), `doc/development/technical_debt/input.md`, `CHANGELOG.md`, and `ROADMAP.md` are aligned with exact code facts and cross-references.

---

## 3. Review of the 3 Specific Judgment Calls (Session 50)

1. **Malformed Cursor Shapes Raise (`ARC-02-07` / `3bade47a`):**
   - **Fact:** `checked_cursor` in `consoleController.lua` requires `type(pair[1]) == 'number'` and `type(pair[2]) == 'number'`. Invalid shapes (`{}`, `{1}`, `{nil, 2}`, scalars, strings) raise `fname .. ': cursor must be a {line, col} pair of numbers'` at level 4 depth.
   - **Verdict:** **RATIFIED.** Defaulting invalid shapes to line 1 / col 1 would create silent errors and defeat predictable configuration rules. Out-of-range numbers still clamp as promised in `doc/input_api.md`.

2. **`cursor = false` Treated as Unset:**
   - **Fact:** `checked_cursor` returns `nil` when `not cursor`, which extends Decision 35's uniform unset rule (`false` = unset) to the `cursor` field.
   - **Verdict:** **RATIFIED.** Allows safe idioms like `cursor = computed_cursor or false`.

3. **Decision 35 Text Alignment:**
   - **Fact:** `ARC-02-01` was ruled as an **addition** to Decision 15 rather than an amendment, because Decision 15 already raised for `force` at `configure`, and `configure{text}` was never in the warn list. Decision 35 text in `decisions/input.md` was updated accordingly.
   - **Verdict:** **RATIFIED.** Eliminates contradictions between Decision 15 and Decision 35.

---

## 4. Integrity Check on Deletions & Hidden `configure` Persistence

- **Deletions Verified:** Grep searches across `src/` confirmed zero residual occurrences of `re_show`, `state.pending`, `consume_pending`, `stash_hidden_configure`, `PER_SHOW_KEYS`, or `live`.
- **Named Risk (Hidden `configure` with `validator`/`prompt`):**
  - Checked `merge_callback_keys` and `api_configure`.
  - When `configure` is called while the widget is hidden, `merge_callback_keys` writes into `state.callbacks` (resolving to `w.callbacks`), and `configure_core` updates `self.callbacks`.
  - On a subsequent `show({})`, `merge_callback_keys` retrieves sticky callbacks and passes them to `open_widget`.
  - **Verdict:** **VERIFIED & CLEAN.** Pinned by `tests/input/input_widget_control_spec.lua` (`"applies prompt and validator on the next show"`).

---

## 5. Gap Check & `BUG-01-09` Status

- `BUG-01-09` (`T-MULTILINE-STR`): `set_text` ignores multi-line string input.
- **Status:** Left unfixed during `ARC-02` and recorded as an `ACTIVE` technical debt item in `doc/development/technical_debt/input.md`.
- **Assessment:** Correct scope decision for `ARC-02`. `ARC-02` restructured configuration ownership, while string splitting in `set_text` is a distinct model defect. It remains the top-priority ACTIVE defect before release.

---

## 6. Summary Checklist Result

| Check | Result | Notes |
|---|---|---|
| 1. Intent reconstruction | PASS | Single-sentence intent verified |
| 2. Intent-vs-outcome coherence | PASS | All 4 sub-checks (a-d) clean |
| 3. Consistency check | PASS | Closed config tables, error depth, cursor shape checks uniform |
| 4. Integrity check | PASS | Deletions clean; hidden `configure` persistence verified |
| 5. Gap check | PASS | `BUG-01-09` accurately categorized in ACTIVE debt |
| 6. Artifact check | PASS | 10 commits clean; test suite 990/0/0/10 |

**Conclusion:** `ARC-02` revalidation is **COMPLETE and CLEAN**. No code or documentation corrections are required for `ARC-02`.
