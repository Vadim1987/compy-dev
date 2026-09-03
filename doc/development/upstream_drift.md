---
description: How far this branch has drifted from each upstream it must reconcile with, what each drift contains, and what closing it costs
status: active
audience: stakeholder
authored: llm
reviewed: none
---

# Upstream drift — where we stand against each line we merge with

**Measured 2026-09-03.** Four repositories, four upstreams, one question each:
*how far apart are we, what is in the gap, and what does closing it cost?*

Everything below was measured against live remotes on that date, and the states
compared are pinned as local tags so the same comparison can be repeated later and
give the same answer. **Numbers age.** Re-measure before acting on any of them.

## The short version

| drift | size | what it touches | cost to close | when |
|---|---|---|---|---|
| **toward the platform's editor rework** | 52 commits, 20 files | the editor route's keys; **not** the project-facing input API | one integration point, one signature merge, one key decision, five test re-pins, and a repeat of the typing part of the device pass | **before this release** — we build on it |
| **toward the platform's experimental line** (beyond the rework) | 16 commits | colours, packaging, filesystem durability, Android exit; **one** input-surface interaction | three files by hand, one surface decision | **after this release** |
| **toward the maze game's upstream** | **nothing** | — | none | — |
| **toward the keyboard game's upstream** | 1 commit | packaging only | one clean merge | before that repository's pull request |

**The headline is that the input API itself is not in dispute with anyone.** Every
collision found is in the editor, in packaging, or in the terminal's colours.

## 1. Toward the platform's editor rework — the one that matters

The rework is an open pull request against the platform's development line:
*explicit navigation and editing modes, line navigation, durable accepts,
undo/redo*. It is **52 commits, 20 files, roughly 3000 added lines**, and **11 of
those files are files this branch also changed**.

**It is built on a development line that has since moved.** The rework branched on
2026-07-09 and is **seven commits behind** the platform's development head — among
them the colour palette and the terminal's repaint change, both of which touch
drawing, which is what a 3000-line editor rework also touches. **We already have all
seven.** Two consequences, and neither is alarming: our work must be delivered as
patches against *the development line plus the rework*, not against the rework
alone, or it would carry seven commits that are already upstream; and the rework
**will change** when its author catches it up, so the reconciliation described below
is re-run rather than assumed at that point. The rework merges into the development
line cleanly today.

**The decision of record (2026-09-03) is to build on it, so that the two ship
together.** That decision was taken against a measurement rather than an estimate:
the merge was performed in a throwaway clone, resolved, and **run**.

| tree | test suite |
|---|---|
| this branch | 1055 pass, 0 fail |
| the rework, alone | 753 pass, 0 fail |
| the two merged | **1100 pass, 22 fail** |

**None of the 22 is in the project-facing input API.** The public surface, the way
events reach a project, the hooks and shortcuts tables, the widget's configuration
and every non-editor lifecycle case pass unchanged in the merged tree. What fails
is the **editor route's key semantics**, which the rework redefines deliberately:

- typing no longer inserts by default — the editor now has an explicit navigation
  mode and an editing mode;
- Enter is rewritten around accepting a block, with new meanings for its
  Ctrl and Shift variants;
- Escape discards or closes rather than loading the selection;
- the Ctrl+S family is reassigned.

Six of our tests assert the behaviour it replaces. **Five of those are re-pins** —
the rework is entitled to change what it changed, and its author is the right
person to say what the new expectation is. **One is a real disagreement:** bare
Ctrl+S in the editor closes the buffer in our line and is reserved for the rework's
checkpoint in theirs. That is a product question, not a merge question.

### What closing it costs

1. **One integration point.** The rework reaches into the framework's
   power-shortcut block. This branch restructured that block into a privileged
   reservation table — consulted before any project route exists, and never
   overridable by one — so the work is to express the rework's editor reservations
   as entries in that table. This is what the table was built for.
2. **One mechanical merge** of the input model's constructor, which both sides
   changed for unrelated reasons.
3. **One key-meaning decision** — bare Ctrl+S, above.
4. **One resolution of the editor controller**, whose rewrite is a superset of our
   edits to the same file.
5. **Five test re-pins.**
6. **A repeat of the typing part of the on-device pass**, because the keys move.

Two things were settled by measurement rather than by preference, and both are
worth knowing before anyone re-opens them. The function that seats content
programmatically was rewritten by both sides: keeping ours and adding the rework's
one-line history reset gives 1100/22, while taking theirs gives 1094/28 — the six
extra failures being our own content-handling guarantees. And the two test
harnesses are **not** interchangeable: adopting the rework's wholesale adds 145
errors on our side and fixes none of its own.

## 2. Toward the platform's experimental line — deferred on purpose

The experimental line runs **71 commits** ahead of the base we develop against. **52
are the editor rework above**, and **15** are this section, which ships **after**
this release.

**Fifteen is the count of commits; the count of *changes* is eleven.** The two lines
copy work between each other, so the same change appears on both with a different
identity — four of the fifteen are already in our tree under other names, and three
more are **alternate versions** of colour work we already carry, which is why the
colours example collides rather than simply applying. Counting commits overstates
this drift by a third; the number that matters is eleven.

They contain: the 64-slot colour palette and the terminal-colour fixes that follow
it, a colours example, the editor checkpoint's filesystem information, packaging
changes, a test-runner launcher that pins the Lua version, the Android exit path, a
terminal repaint gate, a per-character input render-cost fix that is its own open
pull request, and a storage-fallback label at the prompt.

**These were read one by one for what they would do to our code, not only for
whether they would merge — and the two questions give different answers.** Three
things came out of that reading.

**One change is silently lossy against our work.** The Android exit path reroutes
every full exit so the device returns to its launcher before closing. One of the
places it reroutes is the Ctrl+Escape handler — and that is a line this branch
**moved**, into the privileged table of shortcuts the framework keeps for itself.
The result is that a merge tool sees no problem: a project's typed `quit()` picks
up the new route cleanly, and our relocated shortcut quietly keeps the old one. It
would fail **only on the device**, where no automated test can see it. **One line
fixes it**, and the fix is proven in a built tree. This is the clearest example of
why "it merges" is not the same as "it still works".

**One change reaches a documented part of our surface, without breaking it.** The
storage-fallback commit widens the widget's label from a string to *either* a
string *or* a `{ text, tone }` pair, and the status line colours the tone. The
project-facing `prompt` setting documented in
[the input API guide](../input_api.md) writes exactly that field. Verified: the
widened form works through our code. So the decision is whether the guide
**admits** it, refuses it, or stays silent — all three defensible, none automatic.

**Two changes cannot be judged by any automated test we have.** The
render-cost fix and the terminal's repaint gate are both **drawing** changes, and
this environment has no display. Their failure mode is a stale or mis-drawn frame.
They are named for the on-device pass rather than cleared.

Everything else is additive or outside this subsystem. Merging the rest needs three
files by hand: the console model, an add/add collision on the colours example — the
same file arriving by two routes, 245 lines against 247 — and `.gitignore`.

### Do the three stack?

The expected release order is **the editor rework, then this feature, then the rest
of the experimental line**. That order was built and run rather than assumed:

| tree | test suite |
|---|---|
| this branch | 1055 pass |
| the rework, alone | 753 pass |
| this branch on the rework | 1100 pass, 22 fail |
| **all three together** | **1108 pass, 22 fail** |

**The 22 failures at the end are the same 22 as in the middle.** The experimental
line adds **no new failure** to the stack — its only casualties were two of its own
tests written against a function signature the rework changed, mechanical and fixed
in place. **They stack.**

## 3. Toward the maze game's upstream — nothing to do

**Every branch of the upstream repository is an ancestor of ours**, checked one by
one rather than only on the branch we track: the development branch (last moved
2026-07-24), the release branches, the reconciliation branch and the default
branch. We are ahead of all of them and behind none.

This is worth stating rather than omitting: *"no drift"* measured across every
branch is a different claim from *"no drift"* measured on one, and only the first
is safe to plan against.

## 4. Toward the keyboard game's upstream — one packaging commit

Upstream is **one commit ahead** (2026-08-20): it adds a build script, 32 lines, and
**touches no source file**. It follows the convention the maze repository set — one
source tree emitting two shipped projects, the long name and a one-letter alias, so
that reaching a game which teaches typing does not itself demand typing eight
letters. It **merges clean**.

**"Merges clean" and "costs nothing" are different claims, so the second was checked
too.** The script copies every `.lua` file plus the README from a flat source tree.
Our work in that repository is 37 commits ahead and its **file set is identical to
upstream's**: every commit changed the contents of a file that already existed, and
none added a file or a folder. So the script emits our version of the game
correctly, and the cost really is one merge.

Two incidental findings. That repository has been **renamed** upstream — the address
we use still resolves, by redirect, so nothing is broken today, and it is worth
correcting when its pull request is opened. And the **maze** repository, which set
this packaging convention first, does it the fragile way: **its build script lists
its source files by name** instead of copying them all, so a file added there and
not added to the list would be silently missing from the shipped game. Nothing is
missing today. It is a note for whoever adds the next file, not a cost of this
release.

## How this was measured, for anyone repeating it

- Live remotes were added **alongside** the existing ones rather than replacing
  them, so no existing view of an upstream moved and the previous snapshot stayed
  comparable.
- Each comparison is a commit-count in both directions plus a **dry merge that
  writes no files**, so conflicts are predicted without touching a working tree.
- The editor-rework result is a **real merge, resolved and run** in a disposable
  clone outside the working repository. Two of its four conflict resolutions were
  probes chosen to make the tree runnable — the failures they cause are counted
  above as an upper bound on the work, not as defects.
- Every state compared is pinned as a local tag in its own repository, so the same
  comparison repeats exactly.

**Nothing was merged, committed or pushed in any of the four repositories.**
