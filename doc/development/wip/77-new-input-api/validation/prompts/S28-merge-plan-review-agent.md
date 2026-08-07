# S28 — sub-agent prompt of record: cold review of the merge plan (pre-move)

Spawned: 2026-08-07, session28, P8 tail. Model: **Sonnet** (explicit).
**Read-only. Nothing has moved yet and nothing may move.** The owner required a
cold review of the plan *before* any test file is touched.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1) finishing a new input API for a PR. Its
owner reviewed the test suite and asked whether two pairs of spec files should
be merged (**R074**: widget lifecycle ↔ reconfigure; **R078**: widget callbacks
↔ lifecycle uniform), and whether the input suite should be regrouped into three
named surfaces (**R057**): *inbound events*, *widget control*, *widget
callbacks*.

The owner approved merging, on the condition that every case be inventoried
first, a written plan be produced, and the plan be cold-reviewed **before**
anything moves. You are that review.

Two documents:

- **The plan you are reviewing:**
  `doc/development/wip/77-new-input-api/validation/reviews/S28-merge-plan.md`
- **The evidence it was built from:**
  `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-inventory.md`
  (a full row-by-row inventory of the four files, produced by a different
  agent).

The suite is **954 successes / 0 failures / 0 errors / 3 pending** (`busted
tests`; `busted <path>` for one file). The plan predicts 952 after the merge.

**The `lua-lsp` MCP server is available** (definition / references / hover /
diagnostics over a real AST) if you need to resolve what a helper or fixture
function does.

## What to check — in this order

1. **The two deletions, against the source files, not against the plan's
   description of them.** The plan deletes
   `input_widgets_callbacks_spec.lua:629` and `:613`, arguing that
   `input_reconfigure_spec.lua:279` and `:308` respectively are stronger and
   survive. **Open all four rows and read them.** For each deletion, answer: does
   the surviving row assert everything the deleted one did? If not, name the
   fact that would be lost. This is the highest-value check in the review — a
   silently dropped assertion is the failure mode the whole process exists to
   prevent.
2. **The three-way cluster the plan KEEPS** (`input_reconfigure_spec.lua:296`,
   `input_widgets_callbacks_spec.lua:350` and `:661`). The plan argues each pins
   a distinct fact. Read them and say whether that holds, or whether two of them
   really are the same row twice. Disagreeing with the plan here is a useful
   result — it was written by the same agent that will execute it.
3. **Row arithmetic.** The plan claims 93 rows in, 91 out, and per-describe
   counts in its two tables. Check the totals add up and that every source row
   has a destination. Any row present in the inventory but absent from the
   plan's tables is a finding.
4. **Helper dependencies.** `input_lifecycle_uniform_spec.lua` defines
   `bare_uic`, `driver` and `open_doc`; `input_widget_lifecycle_spec.lua`
   defines `arm` and `open_on`. Check for name collisions or fixture
   incompatibilities between files being merged, and for rows that depend on a
   helper the plan does not move with them.
5. **The grouping calls.** The plan self-flags the echo-guard block as its one
   reversible judgment call. Say whether you agree, and flag any other row whose
   assigned surface looks wrong.
6. **Anything the plan does not mention** that would break during execution:
   shared `setup`/`before_each` differences between the merging files, module
   requires present in one file and not the other, a row that depends on being
   in a particular file's `describe` scope.

## Rules

- **Read-only.** Do not edit, create or delete any spec, source or config file.
  No `git add`, no commit, no push. The only file you write is the deliverable.
- The tree carries untracked scratch and three nested git repos under
  `src/examples/` — leave all of it alone.
- You may run `busted` to read counts. Do not change any count.
- **Disagree where you disagree.** The plan's author will execute it, so an
  agreeable review is worth nothing. If the plan is sound, say so plainly and
  say which parts you verified rather than assumed; do not invent objections to
  look thorough.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-plan-review.md`**:
each numbered check above with a verdict (CONFIRMED / CORRECTION / UNCLEAR),
the evidence you read for it (file:line), and — for corrections — what the plan
should say instead. Finish with one line: is the plan safe to execute as
written, safe with the corrections you name, or not safe.

Your chat reply should be a short digest: the verdicts and the final line.
