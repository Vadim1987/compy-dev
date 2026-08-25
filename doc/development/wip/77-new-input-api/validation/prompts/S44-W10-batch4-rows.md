# S44 — W10 batch 4, the "rows" → "test cases" vocabulary sweep

**Worker:** Sonnet (explicit model). **Tree:** `/repo`, shared, serial — you are
the only worker running; do not create a worktree.

## The task

Remark R062 (owner): *"these things are called 'test cases', not vague 'rows'"*.
The test suite calls its table-driven cases "rows" in comments and in code, in
about **81 places across 12 files** under `tests/`. Retire the word where it
means a test case.

1. **Comments** — "row"/"rows" meaning a test case becomes "test case"/"test
   cases" (or just "case(s)" where the sentence already says test). Rewrite the
   sentence if a literal swap reads badly; the ask is vocabulary, not a
   find-replace.
2. **Code** — where a table of cases is named `rows` and the loop variable is
   `row` (e.g. `for _, row in ipairs(rows) do it(row.name, ...)`), rename to
   `cases` / `case`. Local names only.
3. **Leave genuine non-test-case uses alone** — an actual matrix row of data, a
   grid row, a row of a rendered display. `tests/input/highlight_regression_spec.lua`
   describes a real matrix and may hold several. **List every site you keep,
   with a one-line reason each**, in the deliverable.

## Hard constraints

- **`tests/` only** (including `tests/helpers/`). Nothing under `src/`, `doc/`.
- **The suite must stay `968 successes / 0 failures / 0 errors / 10 pending`** —
  run `busted tests` before you start and after you finish, and put both numbers
  in the deliverable. A different count is a finding to report, not to fix.
- **Comment lines stay ≤ 64 characters** (`agents/rules.md` hard limit). Re-wrap
  any comment you touch.
- **Do not add `INTERIM:` or `REMARK:` markers.** A marker in `tests/` fails a
  release gate. If something needs a decision, put it in the deliverable instead.
- Do not commit, do not push, do not touch git. The parent commits.
- Do not "improve" anything else you notice — report it in the deliverable's
  last section and move on.

## Tooling

- **The `lua-lsp` MCP server is available** (defs / refs / diagnostics / rename
  over a real AST of the `/repo` workspace) and is the correctness tool for Lua:
  grep to find candidates, then LSP to resolve a symbol or prove who references
  it. Use `rename_symbol` for the `rows` → `cases` local renames rather than
  hand-editing each site, and `diagnostics` on each file you changed.
- **After any `.lua` edit, `sleep 1` before calling refs/defs/diagnostics** —
  the language server needs a beat to re-index.

## Deliverable (required)

Write your report to
`doc/development/wip/77-new-input-api/validation/outcomes/S44-W10-batch4-rows.md`:

- suite count before and after;
- a table of files touched, with the number of comment sites and code renames in
  each;
- every site you deliberately **kept**, with its one-line reason;
- anything you noticed and did not act on.

The file is the durable artifact — your final chat message is not.
