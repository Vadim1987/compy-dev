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

## 1. Do the import with `merge --squash`, not `diff | apply`

A two-way `git apply` of `updev..updev+#45` onto our branch **will fail** in the four
files where both sides changed the same regions — no merge base, no three-way
resolution, just context mismatch. `git merge --squash <pr45>` does the correct
three-way merge against the true base (`945a5d1d`), surfaces exactly those four
conflicts, and leaves **one staged changeset** — which is the same single commit the
plan asks for, reached by the mechanically correct route.

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

## 3. The failure mode this scheme creates — and no tool warns about it

**Anywhere our reconciliation drops #45's content, the patch set contains a silent
revert of upstream work, delivered as our change.** Conflict markers do not warn
about this: the conflict is resolved, the tree is green, and the deletion looks like
an ordinary line of our diff.

This is not hypothetical. In the trial tree, resolving `controller.lua` by taking our
side wholesale produces, in the generated patch:

```
removed lines in src/controller/controller.lua: 340
  - local ed_state = CC:finish_edit()
  - --- checkpoint (rework spec 2.6); saving
  - if Key.shift() then ...
```

That is #45's editor checkpoint and Ctrl+Shift+S handling, deleted by us, inside a
patch offered as *our* feature. It would land, apply cleanly, and quietly undo part
of the pull request we are stacking on.

**The gate:** before the patch set ships, **every deletion in the ten shared files is
read and justified.** Ten files is a cheap review, and it is the one review nothing
will prompt for — the merge is done, the suite is green, and the diff looks like
work.

## 4. The import commit is red, and the phase's rule says commits are green

The import lands the editor rework's suite next to ours: measured, **~1100 passing /
22 failing** until the reconciliation commits follow. The standing rule is *suite
green at every commit, count stated in the message*.

Three ways out, and this is the owner's call:

- **(a) Ratify a one-off exception** — the import is not authored work, its message
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
