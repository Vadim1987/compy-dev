# P-21-06 — close the two cold-review findings (prompt of record)

Commissioned by session43, 2026-08-16, after the P-21-05 cold review
(`../outcomes/S43-P-21-05-cold-review.md`) returned the sweep sound with two
non-blocking findings. Worker: Sonnet, model passed explicitly. Both findings
verified by the parent session before commissioning.

## Finding 1 (S2) — the untested half of row 4

`ctrl+s`'s reservation deliberately excludes **Alt only**, because Shift is
meaningful there: in the editor, `ctrl+shift+s` finishes the edit and `ctrl+s`
closes the buffer (`src/controller/controller.lua:807-820`). Every *other*
tightened reservation excludes Shift, so `not Key.shift()` creeping into this one
to match its siblings is the easy mistake — and **nothing in `tests/` presses
`ctrl+shift+s` at all** (verified: no hit for `C-S-s` or `ctrl+shift+s`).

Add live case(s) to `tests/input/input_global_shortcuts_spec.lua`, in the same
`describe` and fixture style as the fifteen cases already there, pinning that
**Shift is not excluded** by this reservation. The property is the branch being
reached with Shift held — e.g. in editor state `ctrl+shift+s` finishes the edit
while `ctrl+s` closes the buffer. Prefer the smallest set of cases that fails if
someone adds `not Key.shift()` to that condition; one may be enough, two if the
close/finish pair reads clearer.

**Check the test fails for the right reason:** temporarily add `not Key.shift()`
to the row-4 condition, confirm your new case fails, then remove it again. Report
that output. Do not commit the temporary change.

## Finding 2 (S1 by the review's own scale) — numbers in the outcome report

`../outcomes/S43-P-21-01-02-execution.md:40-46` states that
`project_state_change`'s body was "unchanged (25 lines… still 4)". Measured: the
body **grew** (two comment lines) and nesting **improved** to 3, because merging
the condition removed a level. The pre-existing size debt is correctly left
unfixed — only the cited numbers are wrong.

Correct them **in place**, and add one line marking the correction and its date
so the record shows it was amended rather than silently rewritten. Do not restate
the whole section; fix the numbers and the claim. Measure before you write:
report the method you used (which lines you counted as the body) so the next
reader can reproduce it.

## Constraints

- `agents/rules.md` hard limits apply to the test file (body ≤ 14 lines, line ≤
  64 chars, params ≤ 4, nesting ≤ 4).
- **Do not touch the seven `pending(...)` outlines** and do not change the suite
  pending count — it must stay **10**. Suite is **964 / 0 / 0 / 10** before your
  change; state the arithmetic after.
- Commit **only** `tests/input/input_global_shortcuts_spec.lua`, explicitly by
  path. The outcome-report correction is a doc edit — leave it **uncommitted**;
  the parent session commits documentation. Never `git add .`, never `git add
  doc/`. **NEVER push.** Leave the owner's untracked scratch alone (`claude.sh`,
  `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`, `repos.txt`,
  `input-pr-slices.tar.gz`).
- Trailer: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`; `sleep 1` after a `.lua` edit before querying it.
- **Do not touch `src/controller/controller.lua`.** The sweep was just reviewed
  clean; if you believe production code needs changing, stop and report instead.

## Deliverable

Append your account to `../outcomes/S43-P-21-01-02-execution.md` under a clearly
marked section for this step, or write
`../outcomes/S43-P-21-06-review-fixes.md` — your choice, but say which. Include
the failing output from the deliberate-break check, the suite arithmetic, and the
commit hash.
