# session71 — `MERGE-01-05`: import PR #45, and reconcile against it

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor
report [`../session70/report.md`](../session70/report.md).

Baseline **1055 / 0 / 0 / 10** (LuaJIT 2.1 in the container; **the owner runs PUC
Lua** — container-green is not their-machine green, and any suite claim states its
interpreter). A different count *before you start* is a finding. **After the import
it changes by design — see "The baseline moves" below.**

## Open by executing the delivery review's dispositions

[`../../../validation/reviews/S70-delivery-revalidation.md`](../../../validation/reviews/S70-delivery-revalidation.md)
— ten findings with a dispositions table. **Session70 applied the mechanical ones
before wrapping** (the merge plan's superseded row 3, `MERGE-01`'s stale prose, the
`REC-01`/`MERGE-01` headers and summary cells, four uncorrected counts, the two
unowned `PROP-01` carve-outs, and the `T-EPHEMERAL-IDS` line). **Read the table
first and verify that** — a disposition marked applied that is not is the first
finding of your session — then take what remains.

## Your task

**Execute the import of upstream PR #45 into this branch, then reconcile.** This is
`MERGE-01-05`, and it is the first execution-mode work in several sessions.

The plan is written and you are not re-deriving it. Read these four, in this order,
before touching anything:

1. [`../../../validation/reviews/S70-merge-plan.md`](../../../validation/reviews/S70-merge-plan.md) — order, gates, twelve risks
2. [`../../../validation/reviews/S70-import-strategy.md`](../../../validation/reviews/S70-import-strategy.md) — the import's mechanics and its one hole
3. [`../../../ANCHORS.md`](../../../ANCHORS.md) — every sha, ref and command
4. [`../../../validation/notes/S70-PR45-as-base.md`](../../../validation/notes/S70-PR45-as-base.md) — the trial merge, and what its 22 failures are

### The sequence

**Step 0 — `keyboard` first, because it is free.** One upstream commit
(`96d6629`, `.compy/build`, no source file), merges clean. Its own suite green.
That is `MERGE-01-02` and it closes **`T-DRIFT-KEYBOARD`** — retire that entry with
the merge, in the same commit. `maze` and `balloons` need
nothing; record that they were re-checked, do not re-measure them from scratch.

**Step 1 — the import, as one commit, and it is allowed to be red.**

```sh
git merge --squash upstream-pr/45      # …or git apply --3way; measured equivalent
```

Four files conflict — `controller.lua` (1 hunk), `editorController.lua` (2),
`userInputModel.lua` (2), `tests/mock.lua` (1). Resolve them **as the plan says**,
not as the trial did (the trial took whole sides as a probe and its 16 upstream-side
failures are the consequence):

| file | resolution |
|---|---|
| `tests/mock.lua` | union of both sides' exports |
| `userInputModel.lua` `set_text` | **ours**, plus their one-line `edit_history:reset()`. Settled by measurement — ours 1100/22, theirs 1094/28 |
| `userInputModel.lua` `new()` | ours plus their `editing` flag; **update every positional call site in the same commit** — `editorModel.lua` and two specs. A wrong positional binding fails two layers away and nothing raises |
| `editorController.lua` | theirs as the base, then re-apply our edits to that file deliberately |
| `controller.lua` | **neither side wholesale.** Express #45's editor reservations as entries in our `RESERVED` table — this is the one piece of real integration, and it is what `D-RESERVE-TABLE` exists for |

**`T-DRIFT-PR45` is the ACTIVE register entry whose whole content is this work.** It
carries the cost itemisation, the measured `set_text` verdict and the harness finding;
read it before step 1 and **update or retire it when the import lands** — an ACTIVE
entry describing work that is done is the failure mode this phase files entries to
avoid.

**The commit message states**: that it is a mechanical import of #45 at
`16eb33d79fd8711e8c467d8581d47e6632b1607e`, **authored upstream, not our work**; the
four resolutions; and **the expected failing count**, with the rows that close it.
Tag the imported head in the `wip77/` namespace in the same motion.

**Owner ruling, 2026-09-03: this commit is allowed to be red.** It is the standing
*green at every commit* rule's one-off exception, granted because fusing the import
with the reconciliation would hide someone else's 3000 lines inside our decisions.
**Green is required by the end of the sequence, not by the end of this commit.**

**Step 2 — the reconciliation, one concern per commit.**

- the `RESERVED` table integration (if not already inside step 1's conflict);
- **the Ctrl+S ruling** — ours closes the buffer, #45 reserves bare Ctrl+S for its
  checkpoint. **This is a product decision, not a merge resolution.** Record it in
  the decisions ledger *before* the guide is edited, and raise it with the owner:
  the rework's author is a party to it;
- the five editor-route spec re-pins — and read
  [`../../../validation/notes/S70-PR45-as-base.md`](../../../validation/notes/S70-PR45-as-base.md) §"The 22 failures" first: **five of the six are ours asserting an
  editor #45 replaces on purpose**, and re-pinning someone else's redesign from
  outside is how a merge acquires opinions nobody agreed to. Prefer stating what we
  asserted and letting the author say what the new expectation is;
- `doc/input_api.md` follows the ledger, never the merge.

**Step 3 — the two gates, both mechanical.**

```sh
# the invariant: our work and nothing else
git diff a8cb98e2f11f4435249f48bd71adfa62f4c26904 HEAD -- src/ tests/

# the audit: #45's own added lines that are absent from our result
git diff 945a5d1d..upstream-pr/45 -- <shared file> | grep '^+'
```

The second is the gate **no tool prompts for**: where our reconciliation drops #45's
content, the patch set carries a **silent revert of upstream work**, delivered as our
change. Measured at the crudest resolution it is **49 lines out of 1005**, in three
places, one of which we intend. **Account for every line it reports** — kept, or
dropped on purpose with the reason.

## The baseline moves, and this phase reasons from that number

After the import the tree carries both suites. The trial ran **1122 cases**
(1100 + 22). Every session boots by confirming a baseline, so:

- **state the new count and its arithmetic in the merge commit**, and
- **update the baseline line in `agents/validation.md` in the same commit** that
  reaches green. A phase that treats its baseline as a go-signal must not be left
  with a stale one.

## What is not yours to take

- **The landing order with upstream** (R1) — merging #45 while it is still open would
  put its 52 commits inside our own PR's diff. The mitigation is coordination, not
  code, and it is the owner's.
- **The edge remainder** (`MERGE-01-06`) — after the release, by owner decision.
  Verified to stack: 1108/22, the same 22.
- **`ACC-02`** — it runs *after* this, because #45 moves keys a hand-run checklist
  exercises.

## Numbers, and how this phase has been getting them wrong

**State the command beside any number you write, and do not cite a figure from a
roadmap cell or a ledger entry — re-run it.** This is S69's F8, which session70 was
asked to carry into this prompt and did not; the delivery review then found **four
uncorrected counts** in that same session's own range, every one of them the same
shape: *measured over set A, stated over a superset*. All four were caught by someone
asking how the number was derived, which is not a check the process contains. The
working form that has held is **command + explicit do-not-cite**, and the sites that
carry it have stayed right.

## Standing constraints

- **Never push** — the platform repo or either nested one. Nothing about the import
  changes that.
- **Stage explicit paths, and read `git status` before committing.** `git add` aborts
  the whole add on one unmatched pathspec: last session a commit claimed four
  repointed references and carried none.
- A behaviour change is **never** documented in the commit message alone.
- A finding goes to the debt ledger the moment it is found.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`; and
  **`agents/` is not the corpus either** (owner, 2026-09-03) — name the rule, do not
  point at its path.
- Say **widget**, not "field" or "overlay".
- The owner also works in this tree. Known scratch: `claude.sh`, `src/STEPS.md`,
  `repos.txt`, `worklog.md`, `broken-busted/`, `input-pr-slices.tar.gz`, and the
  three nested example repos.

## Method notes that cost the predecessor time

- **A clone of `/repo` does not populate its two submodules**, and the suite then
  fails 38 specs with *"module `util.string.string` not found"*. The recipe is in
  `ANCHORS.md` §4. It reads like a real defect and is not.
- **`git merge-tree --write-tree` predicts conflicts without a working tree** — no
  worktree under `/repo`, no LSP pollution.
- **A bare `git apply` invents conflicts** that a three-way application does not:
  measured, 8 rejected hunks in 5 files, one of them with no real conflict at all.
- **Trial merges belong in a throwaway clone outside `/repo`.** Never a worktree
  under it.

## Sub-agents

The host has **no CPU or memory ceiling** and agent fan-out has taken it down three
times. Every spawn prompt carries an explicit **"you are a leaf agent, do not use the
Agent tool"** clause **with its reason stated**. One at a time, never parallel
worktrees, model passed explicitly — **Sonnet** for anything mechanical; the Fable
tier is retired. Hard judgment calls are Opus work and are usually better done
in-session.

## Open with the owner

- **F6** — promoting the ephemeral-id re-derivation to a pre-PR gate. *"I need to
  discuss it."*
- **Two `agents/` scope calls** — is `agents/rules/ledgers.md` (9 citations from the
  corpus) in the surviving half? `roadmap.md` (2)?
- **Set 2 of the slice cut is `agents/`** — 17 files, now a scope decision rather
  than a routing rule.
- **`sync-input-proposal.md`** — cited by `doc/input_api.md`, absent from the tree.
