# S44 — W10 batch 4 outcome: the "rows" → "test cases" sweep

## Suite count

- Before: `968 successes / 0 failures / 0 errors / 10 pending`
- After: `968 successes / 0 failures / 0 errors / 10 pending`

Unchanged, as required. (`busted tests` run twice, before and after all
edits.)

## What was found vs. the brief

The brief estimated "about 81 places across 12 files." An exact
occurrence count (`grep -oniE '\brows?\b' tests/`) gives **82**
occurrences across the same 12 files — the earlier "81" undercounted
by one because one line
(`input_events_spec.lua`, the old "delivered-triple row, the textinput
rows" sentence) held two occurrences on a single matched line, and a
line-count grep undercounts that. 12 files, 82 occurrences: **75
retired, 7 kept**.

All 82 occurrences were in **comments**. No local variable or table in
`tests/` was actually named `row`/`rows` — every table-driven case
list already used `cases`/`case` (e.g.
`input_events_spec.lua`'s `local cases = { ... } for _, case in
ipairs(cases) do`). So `rename_symbol` was not needed; the task was
pure comment-vocabulary editing. I still confirmed this by grepping for
`rows?\s*=`, `for .* rows?`, `ipairs(rows?)`, `rows?\.` across `tests/`
before starting — zero code-identifier hits.

## Per-file table

| File | Occurrences | Renamed | Kept | Code renames |
|---|---|---|---|---|
| tests/input/input_global_shortcuts_spec.lua | 3 | 2 | 1 | 0 |
| tests/input/input_events_spec.lua | 20 | 20 | 0 | 0 |
| tests/input/input_nfr_mechanism_spec.lua | 5 | 5 | 0 | 0 |
| tests/input/user_input_model_spec.lua | 2 | 0 | 2 | 0 |
| tests/input/input_route_lifecycle_spec.lua | 11 | 11 | 0 | 0 |
| tests/helpers/input_fixture.lua | 6 | 6 | 0 | 0 |
| tests/input/input_widget_callbacks_spec.lua | 12 | 12 | 0 | 0 |
| tests/input/history_spec.lua | 1 | 1 | 0 | 0 |
| tests/input/input_widget_control_spec.lua | 11 | 11 | 0 | 0 |
| tests/input/highlight_regression_spec.lua | 4 | 0 | 4 | 0 |
| tests/input/input_shortcuts_click_spec.lua | 3 | 3 | 0 | 0 |
| tests/input/input_cursor_text_spec.lua | 4 | 4 | 0 | 0 |
| **Total** | **82** | **75** | **7** | **0** |

Where a swap pushed a touched comment line over 64 characters (either
because "case"/"cases" is longer than "row"/"rows", or because the
paragraph I was editing was already mis-wrapped), the whole paragraph
was rewrapped to ≤64 chars. Pre-existing over-length comment lines I
did **not** otherwise touch were left as found (see "Noticed" below).

## Sites kept, with reason

1. **`tests/input/user_input_model_spec.lua:654`** —
   `-- second last row ( in this case, first )`. Genuine text/cursor
   row: `cl` is the cursor's line number in the edited text, not a
   test case.
2. **`tests/input/user_input_model_spec.lua:664`** —
   `-- second row`. Same: refers to line 2 of the model's text under
   `cursor_vertical_move`, not a test case.
3. **`tests/input/highlight_regression_spec.lua:21`** — "The rows
   below are the resulting matrix: [lua parser || plain text] x
   [highlighter returning nil || highlighter absent] ...". Explicitly
   frames the `it()` blocks below as cells of a real 2×2 (×2)
   condition matrix, not the generic "row = test case" shorthand seen
   elsewhere — this is the file the brief flagged as holding genuine
   matrix rows.
4. **`tests/input/highlight_regression_spec.lua:58`** — "One row per
   highlighter condition ...". Continues the same matrix framing from
   site 3, listing the matrix's cells 1–4.
5. **`tests/input/highlight_regression_spec.lua:65`** — "...one row
   for empty text and one for non-empty." Still enumerating cells of
   the same matrix (the standard-Lua-eval cell split by empty/non-
   empty text).
6. **`tests/input/highlight_regression_spec.lua:82`** — "...split into
   their own rows so each states which one it covers...". Same matrix
   vocabulary, describing the empty/non-empty split as two matrix
   cells.
7. **`tests/input/input_global_shortcuts_spec.lua:313`** — "The defect
   this closes (blast-radius review, rows 5/6)". Refers to literal row
   numbers in an external review document's table, not to a test case
   in this spec file.

Sites 3–6 are one continuous editorial choice: the file's own prose
commits to a "matrix" framing (rows × columns of test conditions), so
"row" there is a load-bearing mathematical term, not the vague
placeholder the brief is retiring. All four were left untouched
verbatim.

## Noticed but not acted on

- **Pre-existing `REMARK:` markers already in `tests/`** (not added by
  me, not touched, unrelated to "row" vocabulary — task forbids adding
  new ones but doesn't ask me to remove existing ones): 14 markers
  across `input_widget_callbacks_spec.lua` (lines 5, 27, 728, 729),
  `input_widget_control_spec.lua:4`, `history_spec.lua:72`,
  `highlight_regression_spec.lua` (lines 1–3),
  `input_shortcuts_click_spec.lua:6`, `input_cursor_text_spec.lua:1`,
  `input_events_spec.lua:194`, `input_session.lua` (lines 1, 13, 39),
  `input_fixture.lua:200`, and `editor_spec.lua:715`. Per the brief's
  own hard constraint ("A marker in tests/ fails a release gate"),
  these look like an existing release-gate blocker independent of this
  batch — worth a dedicated pass.
- **Widespread pre-existing comment lines over 64 characters** in
  `tests/`, especially `input_events_spec.lua`,
  `input_widget_callbacks_spec.lua`, `input_widget_control_spec.lua`,
  `input_route_lifecycle_spec.lua`, `input_shortcuts_click_spec.lua`,
  and `input_nfr_mechanism_spec.lua`. I rewrapped every paragraph I
  edited for the "row" swap, but left unrelated over-length lines
  alone (out of scope per the brief: "Do not 'improve' anything else
  you notice"). A dedicated re-wrap pass would be a reasonable
  follow-up batch.
- **Unrelated uncommitted changes already present in the shared tree**,
  outside `tests/` and outside anything I touched: modified (not
  committed) `doc/development/internals/project_sandbox_env.md`,
  `doc/development/internals/user_input.md`,
  `src/controller/consoleController.lua`, and
  `src/controller/userInputController.lua`. I discovered these via a
  `git stash`/`git stash pop` round-trip used only to diff original vs.
  edited occurrence counts (the round-trip restored everything
  correctly — verified `tests/` diffs and the 968/0/0/10 suite count
  were unchanged after the pop). I did not create, inspect the
  content of, or touch these four files. Flagging since the
  conversation's initial `git status` snapshot showed only untracked
  files, not these modifications — the parent may want to confirm this
  is expected (earlier session's uncommitted work) rather than
  something to lose.
- `lua-lsp` `diagnostics` on all 10 touched files came back clean of
  new issues — all reported WARNING/HINT items (duplicate-set-field on
  `Log.warn`/`love.event.quit` stub reassignment, undefined-field on
  `assert.has_no.errors`, a few pre-existing type mismatches, one
  unused vararg, two trailing-space hints) are pre-existing and
  unrelated to the comment-only edits made here.

## Tooling notes

- `mcp__lua-lsp__diagnostics` was run on all 10 files with edits
  (`input_fixture.lua`, `history_spec.lua`, `input_cursor_text_spec.lua`,
  `input_events_spec.lua`, `input_global_shortcuts_spec.lua`,
  `input_nfr_mechanism_spec.lua`, `input_route_lifecycle_spec.lua`,
  `input_shortcuts_click_spec.lua`, `input_widget_callbacks_spec.lua`,
  `input_widget_control_spec.lua`) after a `sleep 1` re-index pause;
  no new diagnostics attributable to the edits.
- `rename_symbol` was not invoked — there were no `row`/`rows`
  code identifiers in `tests/` to rename (see above).
