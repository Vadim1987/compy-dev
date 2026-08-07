# S28 — sub-agent prompt of record: test-case inventory for the P8 merges

Spawned: 2026-08-07, session28, P8 tail. Model: **Sonnet** (explicit).
Mechanical inventory only — **no judgment, no edits, no commits**. Its output
feeds a merge plan the owner reviews before anything moves.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1) whose input subsystem is being finished
for a PR. The owner reviewed the test suite and left two remarks asking whether
duplicated suites should be merged:

- **R074** — `tests/input/input_widget_lifecycle_spec.lua` vs
  `tests/input/input_reconfigure_spec.lua`: "There was another test suite on
  reconfiguration — worth merging here and possibly de-duplicating?"
- **R078** — `tests/input/input_widgets_callbacks_spec.lua` vs
  `tests/input/input_lifecycle_uniform_spec.lua`: "don't we have another test
  suite which also tests submit and cancel? consider merging, unification and
  deduplication of cases"

The owner has approved merging, on the condition that **every case is
inventoried first** and the merge plan is written down and cold-reviewed before
a single line moves. You are the inventory step. Losing a test row in an
800-line move is the failure this guards against, so completeness matters more
than brevity.

The suite runs with `busted tests` and is currently **954 successes / 0
failures / 0 errors / 3 pending**. `busted <path>` runs one file. Do not change
the count — you are not editing anything.

**The `lua-lsp` MCP server is available** (definition / references / hover /
diagnostics over a real AST of `/repo`) if you need to resolve what a helper or
fixture function actually does. Grep to find candidates, LSP to resolve them.

## What to produce

### Part 1 — full case inventory of the four files

For **each** of:

- `tests/input/input_widget_lifecycle_spec.lua`
- `tests/input/input_reconfigure_spec.lua`
- `tests/input/input_widgets_callbacks_spec.lua`
- `tests/input/input_lifecycle_uniform_spec.lua`

list **every** `it(...)` row, in file order, as a table with these columns:

| # | line | describe path | row title | what it asserts | fixture/helpers used |

- **describe path** — the nested describe titles, joined with ` > `, so the
  row's grouping is visible without opening the file.
- **what it asserts** — one sentence, concrete: the behaviour, not the API name.
  "a hidden widget ignores keypressed" beats "tests hide()".
- **fixture/helpers used** — `F.activate_project`, `F.show_widget`,
  `F.session.press`, a local factory defined in the file, etc. Name local
  helpers explicitly; a row that depends on a file-local helper cannot move
  without it.

End each file's section with its `setup`/`teardown`/`before_each` blocks and any
file-local helper functions, quoted in full — these are what a merge has to
reconcile, and they are the most common thing to lose.

### Part 2 — candidate duplication

Across the four files, list every **pair** of rows that appear to assert the
same behaviour, as: `fileA:line (title)` ↔ `fileB:line (title)` + one sentence
on how they differ (different driver, different assertion depth, one is a
control for the other, or genuinely identical). **Do not recommend deletions** —
flag candidates and state the difference; the deduplication call is the owner's
and is made in the plan, not here.

### Part 3 — the other input specs, one line each

For every remaining `tests/input/*_spec.lua`, one line: file, top-level
`describe` title(s), row count, and a one-clause statement of its subject.
No case-level detail.

## Rules

- **Read-only.** No edits to any spec, source, fixture or config file. No
  `git add`, no commit, no push, ever.
- The tree carries untracked scratch and three nested git repos under
  `src/examples/` — do not touch any of it.
- Report what is there, including rows whose purpose you cannot determine —
  mark those `UNCLEAR` rather than guessing. An honest `UNCLEAR` is useful; an
  invented rationale is a trap for the merge that follows.
- Count the rows and state the totals per file. The plan will check your totals
  against `busted` output, so they have to be real counts, not estimates.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-inventory.md`**.
Your chat reply should be a short digest: the four totals, the duplicate-pair
count, and anything you marked UNCLEAR.
