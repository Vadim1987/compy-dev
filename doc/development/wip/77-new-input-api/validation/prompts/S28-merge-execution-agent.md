# S28 — sub-agent prompt of record: execute the merge plan

Spawned: 2026-08-07, session28, P8 tail. Model: **Sonnet** (explicit).
Executes a plan that has already been cold-reviewed and corrected. Works **one
step at a time and stops after each**, so the parent can verify and commit
before the next begins.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1) finishing a new input API for a PR. Its
owner asked for the input test suite to be regrouped into three named surfaces
and for two pairs of spec files to be merged. Every case was inventoried, a plan
was written, and a cold reviewer checked it and corrected four things. You are
executing the corrected plan.

**Your specification is the plan. Read it in full before touching anything:**
`doc/development/wip/77-new-input-api/validation/reviews/S28-merge-plan.md`

Supporting evidence, read as needed:
- `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-inventory.md`
  — every row of the four files, with describe path and helper dependencies.
- `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-plan-review.md`
  — the review. Its corrections are already folded into the plan; read it for
  the reasoning behind the two assertion changes.

Pay particular attention to the plan's **§5b revision log**: two rows gain
assertions during the move, and the helper used matters
(`F.is_widget_visible()` reads the user-observable overlay handle;
`F.widget:is_shown()` reads the widget's own internal flag — they are
deliberately different checks, and that distinction is why one deletion was
nearly a lost assertion).

Baseline: `busted tests` → **954 successes / 0 failures / 0 errors / 3 pending**.
`busted <path>` runs one file.

**The `lua-lsp` MCP server is available** (definition / references / hover /
diagnostics over a real AST). After editing a `.lua` file, `sleep 1` before
querying it.

## Step 1 — and only step 1 for now

Execute **§5 step 1** of the plan: create
`tests/input/input_widget_control_spec.lua` from
`tests/input/input_widget_lifecycle_spec.lua` (all 27 rows) and
`tests/input/input_reconfigure_spec.lua` (rows 1-12 only), grouped into the nine
describes the plan's §2A table specifies, under the root describe
`input surface: widget control #input`. Delete `input_widget_lifecycle_spec.lua`
and — **only if its rows 13-16 are preserved verbatim somewhere for step 2** —
leave `input_reconfigure_spec.lua` in place holding just those four rows for now.
Say clearly in your report which of those two you did and why.

**Move rows verbatim.** Their bodies, their comments and their titles come across
unchanged. This step adds no assertions and deletes no rows: it is a regrouping,
and the suite count must be **954** when it is done. If a row needs a
file-local helper (`arm`, `open_on`), the helper moves with it.

Expected after step 1: `busted tests/input/input_widget_control_spec.lua` → **39
successes**, and `busted tests` → **954 / 0 / 0 / 3**, unchanged.

**Then stop and report.** Do not start step 2. Do not commit.

## Rules — non-negotiable

- **Never commit, never `git add`, never push.** The parent commits.
- Do not touch anything outside the spec files named in the step you are on.
  This tree carries untracked scratch and three nested git repos under
  `src/examples/` — leave all of it alone.
- **Do not "improve" a row while moving it.** No rewording titles, no tightening
  assertions, no modernising helpers. The only content changes in this whole
  plan are the two the revision log names, and they belong to step 2.
- If the suite count does not come out as predicted, **stop and report the
  discrepancy** rather than adjusting a row to make the number match. A count
  that is off by one means a row was lost or duplicated, and that is the finding.
- If anything in the plan turns out to be wrong or impossible, stop and say so.
  You are not required to make a broken instruction work.

## Report

Reply with: what you did, the two counts, and anything that did not go as the
plan described. The parent verifies and commits, then sends you step 2.
