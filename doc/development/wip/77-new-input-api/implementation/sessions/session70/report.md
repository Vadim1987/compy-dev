---
description: session70 report — the S69 dispositions, the proposal block's placement, and a full upstream reconnaissance that turned into the merge plan
status: active
audience: developer
session: 70
authored: llm
date: 2026-09-04
---

# session70 — report

**Outcome: the platform reconciliation is planned, measured and rehearsed, and the
next session executes it.** What began as *"execute the S69 dispositions, then raise
`REC-01`"* became, on the owner's direction, a full reconnaissance of four
repositories and two open upstream pull requests — and then the decision to **build
this release on top of upstream PR #45** and ship the two together.

Baseline **1055 / 0 / 0 / 10** (LuaJIT 2.1 in the container; **the owner runs PUC
Lua**) held across all 33 commits. **No `.lua` under `src/` or `tests/` was touched.**

## What was done

**The S69 delivery dispositions.** F1 and F9 were already applied by session69
itself. F2 fixed the two `design/` citations its pattern never matched; F3 put
`FIX-01`'s two residues into the registers rather than leaving them in `wip/`; F4
corrected `DOC-01`'s placement in the two cells that still said *before `ACC-02`*;
F7 and F8 landed as clauses on the rows they belong to. F5 and F6 went to the owner.

**`PROP-01`, the proposal block.** The owner committed a `## Proposed
updates/changes` section into `doc/input_api.md`. It is now a sprint placed **after
`PR-01`**, and — on the owner's second instruction — an **analysis sprint first**:
weighing, disputing or reshaping an item is an admissible outcome. Three carve-outs
stay pre-PR, none of them design: `DOC-01-07` (the `get_text` promotion), the
destination of the block itself, and a contract-or-defect ruling on Escape.
Assessment: `validation/reviews/S70-proposal-block-placement.md`.

**The reconnaissance.** Ten `-https` remotes added beside the SSH ones (owner: the
work must not depend on their key), round-3 tags in all four repositories, and five
evidence notes. The findings that changed the plan:

- **We are 0 behind `aldum/dev`.** The platform re-merge is a no-op against the PR
  base.
- **Four open PRs upstream, two input-touching**, and the **edge already contains
  both** — so evaluating towards the edge evaluates against #45 and #41 at once,
  which was the owner's instinct and is what made one measurement do the work of two.
- **#45 is based on a stale `dev`** — seven commits behind, all seven already ours.
  So our real base is `dev + #45`, and the patch set is generated against that.
- **#45's future form is predictable today.** Merged into `dev` or rebased onto it,
  the trees are **byte-identical** and green at 760/0. Our branch meets the rebased
  form with exactly the same four conflicts as today's.
- **The example repos are near-empty rows**: `maze` nothing, `balloons` frozen by
  owner attestation, `keyboard` one packaging commit that merges clean.

**The stack was built, not argued:** ours 1055 → +#45 **1100/22** → +the whole edge
**1108/22, the same 22**. Nothing in `compy.input` collides; the collisions are the
editor route's key semantics, which #45 redefines on purpose.

**Inventory and plan.** Three debt entries carry the drift with its blast radius and
cost; `validation/reviews/S70-merge-plan.md` carries the order, the gates and twelve
risks; `validation/reviews/S70-import-strategy.md` assesses the owner's import
scheme; `ANCHORS.md` records every git object the whole thing rests on.

## The four things worth carrying forward

**1. A change that merges cleanly can still stop working, and the defect hides in
the line that does *not* conflict.** The edge's Android-exit commit reroutes every
full exit so the device returns to its launcher first. One of the call sites it
rewrites is the `ctrl+escape` handler — which this branch **moved** into the
reservation table. The rewrite lands on the old location, our reservation does not
conflict with it, and it keeps calling `love.event.quit()` directly. Invisible to the
merge, invisible to a headless suite, one line to fix. Generalised into the plan as
R11: *for every upstream commit that rewrites a call site, ask where that call site
is in our tree.*

**2. Count changes, not commits, when two lines cherry-pick between each other.**
`git rev-list A..B` answers a question about hashes. The edge remainder is **15
commits and 11 changes**; four are already ours under different shas. `git cherry`
is the command that means what we mean.

**3. Two metrics were wrong in this session and both were caught by being
questioned.** The revert risk was reported as *"340 removed lines"* — that counted
our own restructuring, not lost upstream work; the real figure is **49 of #45's added
lines**, in three places, one intended. And *"use `merge --squash`, not
`diff | apply`"* was too coarse: the distinction is **three-way versus two-way**, and
`git apply --3way` is measured equivalent. **Both corrections came from the owner
asking how a number was derived.**

**4. A commit message asserting an edit is worth nothing without the diff.** The
move of the drift document claimed *"four references repointed"* and repointed none:
its `git add` named a pre-move path first, git aborts the whole add on an unmatched
pathspec, and no `git status` was read before committing. The peer review found it —
on its second pass, because its first read the working tree where the fixes sat
unstaged.

## Owner rulings recorded this session

1. **`PROP-01` runs after `PR-01`**, and is an analysis sprint before an
   implementation one.
2. **`REC-01`/`MERGE-01` widened** — recon and merge against the platform again,
   drift evaluated towards the edge, measured and analysed at the recon stage, and
   **https remotes** so nothing depends on the owner's SSH access.
3. **`agents/` is not the persistent corpus, and it splits**: generic rules may
   survive (commenting, the coding guide, documentation formatting); workflow,
   pointers and operational limits do not. It may cite `wip/` freely. **The ruling
   created a class the same minute** — 19 citations of `agents/…` sit in documents
   that do ship, filed unslugged.
4. **Build on #45 and ship together**; the edge's remainder afterwards.
5. **PR #22 is ignored** — it will be superseded by the PR this phase prepares.
6. **`balloons` is frozen** — no recon needed there.
7. **The import commit is allowed to be red.**
8. **F6 — the pre-PR gate for ephemeral ids: *"I need to discuss it."*** Held.

## What the successor does

`MERGE-01-05` — the import itself, and it is spelled out in `session71/prompt.md`.
The reference documents are the merge plan, the import strategy, the anchors, and
the essence note; the peer review of this session is
`validation/outcomes/S70-cold-peer-review.md`, whose three findings are applied.

## Left open, deliberately

- **F6**, awaiting the owner's discussion.
- **Two `agents/` scope calls** — is `ledgers.md` (9 citations) in the surviving
  half, and `roadmap.md` (2)?
- **Set 2 of the slice cut is `agents/`**, 17 files, and the ruling above makes it a
  scope decision rather than a routing rule.
- **The classifier's `doc/*.md` case crosses directories**, so it cannot fail for
  anything new under `doc/`.
- **`sync-input-proposal.md`** is cited by `doc/input_api.md` and is not in the tree.
- **R1 of the merge plan** — the landing order with upstream, which is coordination
  rather than code, and not ours to execute.
