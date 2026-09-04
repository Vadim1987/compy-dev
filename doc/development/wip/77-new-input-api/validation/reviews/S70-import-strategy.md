---
description: assessment of the owner's import plan — squash #45's content into our branch, deliver as content-derived patches; what makes it safe and the one failure mode it creates
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# Importing #45 as one commit, delivering by content

**The owner's plan, 2026-09-03:** take the diff of `updev` against `updev + #45`,
apply it to our branch as a **single commit** named for what it is; keep working and
testing against that *"future-merged"* tree; generate the PR from **content**, sliced
into patches, so the delivered form is exactly what lands on `updev + #45`; and if a
force-push brings new content, add a **corrective commit**. *"It's an unconventional
move which normally would fuck up mergeability of our branch."*

**Verdict: it works, and the unconventional part is safe for a stated reason.**
Because delivery is by content, our branch's ancestry is not part of the product. The
squash's usual cost — that git no longer knows #45 is an ancestor, so later merges
re-apply everything — is a cost **we never pay, because we never merge this branch
into anything.** It also buys something real: a runnable, smokable tree in the place
where the device pass and the reconciliation actually happen.

Four additions, one of which is not optional.

## 1. Use a **three-way** application — `git apply --3way` or `merge --squash`, either

**Corrected 2026-09-03 after measuring it.** An earlier draft said *"use
`merge --squash`, not `diff | apply`"*. That was too coarse: the distinction that
matters is **two-way versus three-way**, not patch-level versus git-level. Staying in
the patch idiom is entirely possible, and the owner's instinct to do so was right.

The patch is `git diff <updev> <tree of updev+#45>` — **19 files, 92 hunks**. Applied
to our branch three ways:

| route | result |
|---|---|
| `git apply` (two-way) | **refuses 5 files.** With `--reject`: **8 hunks rejected**, and one of the five is `consoleController.lua`, which has **no real conflict at all** — the rejection is context lost to our own edits nearby. It is also **all-or-nothing**: one error rolls back the entire application |
| `git apply --3way` | **4 files with conflicts — `controller.lua` 1 hunk, `editorController.lua` 2, `userInputModel.lua` 2, `tests/mock.lua` 1** — `consoleController.lua` applies cleanly, and `#45`'s new `editHistory.lua` is created |
| `git merge --squash <pr45>` | **identical**: the same 4 files, the same 6 hunks |

So: **`git apply --3way` and `merge --squash` produce the same tree and the same
conflicts here.** Choose on secondary grounds:

- **`--3way` needs the pre-image blobs present locally.** They are, because we fetch
  #45. Generate the patch somewhere without that object context and `--3way` silently
  degrades to the two-way behaviour above.
- **`merge --squash` works from the true merge base over the whole tree**, so renames,
  deletions and mode changes are handled uniformly rather than only as far as the diff
  encoded them.
- **Neither records ancestry.** This is the reassurance worth stating plainly:
  `merge --squash` creates **no merge parent and no `MERGE_HEAD`** in the result. The
  commit is an ordinary commit whose *content* happens to include #45's changes. It
  does not make git believe #45 is merged, and it does not contaminate the
  content-level model the plan is built on.

**Recommendation: `merge --squash`, for the whole-tree handling — but if the patch
idiom is preferred, `git apply --3way` is measured to be equivalent and the plan does
not change.** What must not be used is a bare `git apply`, which invents conflicts
that are not there.

## 2. The invariant that makes the whole scheme checkable

After the import, and after every corrective commit:

```sh
git diff <tree of updev+#45> HEAD -- src/ tests/     # must be OUR work, and nothing else
```

This is not a slogan — it is the generation command for the deliverable *and* its own
audit. Verified against today's stacked tree: **49 files**, of which **10 are files
#45 also touched** — correct, because those ten are exactly where our reconciliation
lives.

**Make the invariant the gate on corrective commits too.** Each correction is derived
mechanically as the diff between the old and new #45 trees; after applying it, the
invariant must still hold, and the stack must be re-run. That keeps the branch honest
across any number of force-pushes.

## 3. The failure mode this scheme creates — real, and **much smaller than first stated**

**The risk:** anywhere our reconciliation drops #45's content, the patch set contains
a **silent revert of upstream work, delivered as our change**. Conflict markers do
not warn about it — the conflict is resolved, the tree is green, and the deletion
reads as an ordinary line of our diff.

**The size, corrected.** An earlier draft of this note reported *"340 removed lines in
`controller.lua`"* and called it lost upstream work. **That number measured the wrong
thing.** `git diff <updev+#45> HEAD` counts every line our branch removes, and the
overwhelming majority of those are **our own restructuring removing pre-existing
code** — the inline `handlers.keypressed` body that became the reservation table.
Those deletions are our work and belong in the patch set. The conflict surface really
is small, as measured; the two statements were never in tension, my metric was.

**The right metric** is not *"how many lines does our patch remove"* but *"how many of
**#45's own additions** are absent from our result"*:

```sh
# per file both sides touched:
#   lines #45 added        = git diff 945a5d1d..pr45 -- <file> | grep '^+'
#   lost                   = those lines, not present in our resolved file
```

Measured against the crudest defensible resolution — `merge --squash`, then **keep
our side of every conflicted hunk** and nothing else:

| file | lines #45 adds | absent from our result | what they are |
|---|---:|---:|---|
| `editorController.lua` | 842 | **35** | their Ctrl+Enter block-accept rewrite (spec 2.7) — **must be kept**; it is their subsystem |
| `userInputModel.lua` | 114 | **10** | the `editing` flag and its documentation, plus their `set_text` branch — **partly intentional**: we keep our `set_text`, measured better, and we do want `editing` |
| `controller.lua` | 34 | **3** | the comment stating bare Ctrl+S is the checkpoint — the **key decision** in prose form |
| `tests/mock.lua` | 15 | **1** | a `played_sounds` export — a pure union oversight |
| **total** | **1005** | **49** | |

**Five percent, in three identifiable places, one of which we intend.** That is
protocol-able exactly as the owner suggested, and it is a review of a page, not of a
patch set.

**The gate, restated as a command rather than a habit:** before the patch set ships,
run the audit above over the shared files and account for **every** line it reports —
kept, or dropped on purpose with the reason. The expected end state is *"lost: only
the `set_text` branch, deliberately, because keeping ours measured 1100/22 against
theirs 1094/28"*.

## 4. The import commit is red, and the phase's rule says commits are green

The import lands the editor rework's suite next to ours: measured, **~1100 passing /
22 failing** until the reconciliation commits follow. The standing rule is *suite
green at every commit, count stated in the message*.

**RULED (owner, 2026-09-03): (a) — the import commit is allowed to be red.** The
options below are kept as the reasoning behind that ruling, not as an open question.

- **(a) Ratify a one-off exception** — **taken** — the import is not authored work, its message
  states the expected failing count and names the rows that close it, and green is
  required by the end of the reconciliation sequence. **Recommended:** it keeps the
  import mechanical and the reconciliation reviewable, which is the whole point of
  splitting them.
- **(b) Import and reconcile in one commit** — green, but it fuses someone else's
  3000 lines with our decisions in a single object, which is what the plan is trying
  to avoid.
- **(c) Reconcile on a scratch branch, land one green commit** — same fusion, plus a
  branch nobody reads.

## 5. Two smaller notes

**Attribution.** A squash erases fifty commits' authorship inside our branch. The
message must say plainly: *mechanical import of #45 at `16eb33d7`, authored upstream,
not our work* — and the sha must be pinned as a tag in the same motion, so *"which
#45 is in here"* stays answerable after a force-push. We never push this branch, so
nothing misleading reaches anyone; the record is for us.

**Slicing by file is a different scheme from the one this phase built.** The existing
slices are cut **by concern**, with their apply order encoded. Patches cut **by file**
are order-independent and always apply — genuinely simpler — but they lose the
property that a reviewer can read one slice as one idea. Both are defensible; they
are not the same product, and the choice belongs to whoever answers *"what makes this
reviewable from the guide plus the description alone"*.

## What the plan gets right, stated plainly

- It puts the reconciliation where it can be **run**, which is the only way the editor
  key collisions get settled honestly.
- It makes the deliverable independent of a base that is going to be rewritten.
- It makes the edge comparison cleaner: once our branch carries #45's content, a
  `git cherry` against the edge shows only what is genuinely left.
- And the corrective-commit answer to a force-push is right, provided §2's invariant
  is re-checked each time.
