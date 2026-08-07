# session28 — revalidate session27's judgment, then finish the commission

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session27/report.md` in full, then the
session27 commissioning prompt and its track. Create `session28/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **953 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Where things stand

The owner reviewed the whole branch and left **187 inline remarks** in code,
tests and docs. Session27 extracted them verbatim, triaged them by severity into
twelve workstreams, had the triage and the plan cold-reviewed, and then executed
the architectural half of the plan.

What that produced: **three new ratified decisions** (26, 27, 28), **five
defects fixed**, and a large structural simplification — 183 lines removed from
the dispatch and wiring with the suite unchanged. The suite went 923 → 953.

Three things about it that a successor needs and cannot infer:

1. **The remarks are questions, not a task list.** Two would have caused a wrong
   change if executed literally — the doc claim R135 called stale was correct,
   and four `project_env.X = nil` lines that read as dead code are a sandbox
   boundary. Answer with evidence; do not implement a remark because it exists.
2. **The owner challenges arguments, not conclusions.** Three landed decisions
   were questioned; twice the stated reasoning failed and the decision changed.
   Re-derive in the open rather than defending.
3. **Decision numbers are load-bearing.** 179 comments cite decisions by number.
   The ledger is pruned by **tombstoning in place, never renumbering**.

Full account: `../session27/report.md`. Owner attestations given in chat, each
a ruling to honour: `../../../validation/notes/S27-owner-attestations.md`. The
plan and its revision log:
`../../../validation/reviews/S27-triage-and-plan.md`. Session27 also left an
`observations.md` beside its track — self-assessment, outside the workflow, not
a source of project fact; read it only if the three process failures in it are
of interest.

## Your task, part 1 — revalidation (do this first)

Session27 was cognitive-heavy and its outputs are things downstream work will
trust without re-reading the source. `agents/rules/revalidation.md` applies.
Work the checklist there, scoped to what is most expensive to have wrong:

- **Decisions 26, 27 and 28.** All three were ratified in-flight, and two of
  them **reversed a position taken earlier in the same session**. Check the
  evidence each cites actually says what the entry claims, and that the code
  matches the decision as written rather than as intended.
- **The five defect fixes and their tests.** Each claims a breaking test first.
  For each, ask what the test could distinguish — this feature has produced
  **four blind rows** so far, and two of this session's own additions pass both
  before and after their commit (stated honestly in those messages, but they are
  regression pins, not proofs). The `before_exit` ordering row is the one to
  imitate: it was mutation-checked, and the check is recorded in the row.
- **The triage's coverage claim.** All 187 ids assigned to exactly one
  workstream. It was verified by script twice; verify it a third time rather
  than trusting the record, and spot-check that ids marked resolved really are.
- **The severity calls that were changed under review.** R135 dropped, R088 and
  R081 promoted to S3, R110 re-kinded. Two cold reviewers disagreed with the
  original filing; check they were right.

**Do not skip to part 2 because part 1 finds nothing.** Report findings to the
owner, then proceed.

## Your task, part 2 — finish the commission

`../../../validation/prompts/S27-human-commission.md` is the standing
commission and is not complete. The phase table in the triage document (§4)
carries the sequencing; the short form:

- **P8 tail** — R057 (regroup the input specs into the three named surfaces,
  pairs with R172), R074/R078/R079 (merge and dissolve), R047, R063, R064,
  R069, R075.
- **P9** — the smoke findings SM1–SM5 and the nested example repos. Needs the
  real app (`xvfb-run love src`), not the suite. The three nested repos carry
  **no automated tests**, so committing is not verification. The owner's
  hypothesis on the maze finding is recorded in the plan and should be checked
  before treating it as a route bug.
- **P10** — ledger pruning and the doc/vocabulary batches (retire "overlay";
  remove historical contrast against shapes that never shipped).
- **P11** — the commission's own tail: comment sweep by sub-agent against
  `agents/rules/commenting.md`, slice regeneration, and **two** cold
  revalidation rounds over groups 3 and 4 — the first autofixes serious
  concerns, the second is presented to the owner unfixed.
- **Close-out** — PR description refreshed (it predates Decisions 26/27/28),
  then the owner's ruling on deleting `wip/77`.

**Ordering matters and is deliberate:** code → tests → docs → comments. P8 and
P9 still move code, so P10's prose and P11's comment sweep must not start
early or they are written twice.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is its own commit with its breaking test.
- **Stage explicit paths, never a directory.** This tree permanently carries the
  owner's untracked scratch and three nested example repos. Session27 broke this
  and swept the repos in as gitlinks.
- **Sequence sub-agents; do not run one concurrently with your own edits** —
  even a read-only agent mutates temporarily to run experiments, and your
  commits move its baseline. Session27 broke this too.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones.
- `design/` is frozen — read, never edit.
- **A row asserting an absence needs a mutation check and a control.**
- **When a document claims behaviour is pre-existing, check it against the PR
  base** — `git show 3256aac:<file>`. That defence overturned conclusions in
  three consecutive sessions.
- **The `lua-lsp` MCP server was unreachable for all of session27.** Try it; if
  it works, re-check `handlers.userinput`'s deletion, which is the one
  completeness claim resting on grep alone.

## Slices and the PR

Both are **stale**. The slices were last regenerated at `264e0c6c` and the tree
has moved far past it; Set 4 now needs cutting as `4a-balloons` / `4b-maze` /
`4c-keyboard` per the revised `pr-assembly-guide.md`. The PR description
predates all three new decisions. Regeneration stays the LAST step.
