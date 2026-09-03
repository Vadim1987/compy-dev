---
description: commissioning prompt for the session70 cold peer review — integrity and arithmetic over the session's own commits
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# Prompt of record — S70 cold peer review (step 1 of the closing order)

Model: **Sonnet**. Spawned once, synchronously, with the leaf-agent clause.
Deliverable: `validation/outcomes/S70-cold-peer-review.md`.

---

You are reviewing one session's own changes in a Lua/LÖVE2D repository at `/repo`.
Your job is **integrity and sanity, not judgment about the plan**: do the claims hold
against the code and against git, do the citations resolve, does the arithmetic close,
is anything internally contradictory. You read the diff, not the strategy.

**You are a leaf agent. Do NOT use the Agent tool to spawn sub-agents.** This is a
strict rule and it protects the host, not a preference: agent fan-out has taken this
container's machine down three times, it has no CPU or memory ceiling, and a runaway
takes the machine rather than the box.

## The range

`git log --oneline 1299ed2b..HEAD` — roughly 25 commits, **all documentation**; no
`.lua` under `src/` or `tests/` was touched. Confirm that claim first
(`git diff --stat 1299ed2b..HEAD -- src/ tests/`), and if it is false, that is your
first finding.

## What the session did, so you know what to check

1. Executed the dispositions of `validation/reviews/S69-delivery-revalidation.md`.
2. Planned a `PROP-01` sprint for the proposal block the owner committed into
   `doc/input_api.md`, placed after `PR-01`.
3. Ran an upstream reconnaissance across four repositories and two open upstream PRs,
   added ten `-https` remotes, laid round-3 tags, and produced:
   `validation/notes/S70-REC-01-drift-measurement.md`,
   `validation/notes/S70-PR45-as-base.md`,
   `validation/notes/S70-edge-essence-and-stack.md`,
   `validation/notes/S70-platform-ancestry.md`,
   `validation/notes/S70-slices-do-not-need-history.md`,
   `validation/notes/upstream-drift.md`,
   `validation/reviews/S70-merge-plan.md`,
   `validation/reviews/S70-import-strategy.md`,
   `ANCHORS.md`, and three debt entries in `doc/development/technical_debt/general.md`.

## What to verify — in this order

**A. Every sha, ref and count in `ANCHORS.md`.** It is the file most likely to be
trusted later. Re-derive each: `git rev-parse`, `git merge-base`,
`git rev-list --left-right --count`, `git merge-tree --write-tree`. The example-repo
figures need `git -C src/examples/<repo> …`. Report any that do not reproduce.

**B. The suite numbers.** The session claims: ours 1055/0/0/10; `aldum/dev` alone
693/0; #45 alone 753/0; `dev`+#45 760/0; ours+#45 1100/22; ours+#45+edge 1108/22.
You can verify the first directly (`busted tests`). The others were produced in
throwaway clones outside `/repo` — **do not rebuild them**; instead check that every
document quoting them quotes them **consistently**, and that the arithmetic each
document performs on them closes.

**C. The counts that were corrected mid-session, which is where errors cluster.**
- the edge remainder: **15 commits, 11 by content** — check both derivations;
- `git cherry` duplicates: **4**;
- #45 is **7 behind** `aldum/dev`, and all 7 are ancestors of our head;
- the revert-risk audit: **49 of #45's added lines** absent under the crude
  resolution, and the per-file split 35/10/3/1 over 842/114/34/15;
- the shipping surface: **113 files, 0 unclassified**, and the per-set partition.
  Re-run the classifier from `pr-assembly-guide.md` §1.0 against
  `upstream-https/dev`.

**D. Citations.** Every link in the new documents must resolve from its own
directory. `validation/notes/upstream-drift.md` was **moved** from
`doc/development/upstream_drift.md` late in the session — check that nothing still
points at the old path and that its one outward link works.

**E. The corpus rules the session itself invoked.**
- `doc/` outside `wip/` must not cite `wip/`, `design/`, `agents/`, or bare sprint
  ids. Run: `git grep -nE 'wip/77|design/|agents/' -- doc/ ':!doc/development/wip/'`
  and the sprint-id pattern from `T-EPHEMERAL-IDS`. The `agents/` hits are a **known,
  filed** class — confirm the filed count matches what you find.
- The marker gate must stay clean:
  `grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/`.

**F. Internal contradictions.** The session revised its own advice twice — on the
import mechanism (`merge --squash` vs `git apply --3way`) and on the revert-risk
metric (340 vs 49). Check that **no document still carries the superseded version**,
and that where a correction is recorded, it says what it corrected.

## What NOT to do

- Do not re-litigate the plan, the ordering, or the owner's rulings.
- Do not fix anything. Report.
- Do not run the app; there is no display.
- Do not push anything, anywhere.

## Tools

`lua-lsp` MCP is available (defs / refs / diagnostics over a real AST) and is the
correctness tool for Lua — but this range has no Lua changes, so you will mostly need
`git` and `grep`. If an MCP query returns `broken pipe`, the language server child is
dead: **say so, do not work around it**, and do not read an errored query as an empty
result.

## Deliverable

Write `doc/development/wip/77-new-input-api/validation/outcomes/S70-cold-peer-review.md`
with front matter (`description`, `status: active`, `audience: developer`,
`authored: llm`, `session: 70`, `date: 2026-09-03`). Findings numbered, each with:
what, the command that shows it, and how big it is. **State explicitly which of A–F
you checked and which you could not.** An empty finding list is an acceptable result
if it is true; a confident wrong claim is not.
