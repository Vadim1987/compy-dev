---
description: the platform's three lines and how they actually relate — #45 is based on a stale dev, and counting drift by sha overstated it
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# The platform's ancestry, sorted

**Owner, 2026-09-03:** *"you've mentioned a commit that is at our merge-base but not
in the #45. it means #45 is based on stale aldum/dev, not its head?"*

**Yes.** And chasing it down corrected two numbers I had published, in the direction
of less work rather than more.

## 1. The shape

```
                945a5d1d (2026-07-09)  <- where #45 forked from dev
                   |
     dev ──────────┼──── 9cb27e0f ── 3e249423 ── 1b0fb781 ── f2958ecd ──
                   |     (7 commits: fs durability, editor fs info, the
                   |      repaint gate, the 64-slot palette, termcolor,
                   |      the colours example, black's bright slot)
                   |                                        └─ af9a5782 (dev HEAD)
                   |                                              │
                   └── #45 (52 commits) ── 16eb33d7                │
                                                                   └── OUR BRANCH
```

| fact | value |
|---|---|
| where #45 forked from `aldum/dev` | `945a5d1d`, 2026-07-09 |
| `aldum/dev` head | `af9a5782` — author date 2026-08-12, committed 2026-08-17 |
| **#45 behind / ahead of `aldum/dev`** | **7 behind**, 52 ahead |
| are those 7 in our branch? | **all 7, yes** — we are 0 behind dev |
| does #45 merge into `aldum/dev` cleanly? | **yes** — `git merge-tree` exits 0 |
| commits in `dev + #45` we do not already have | **52** — exactly #45's own |

So the commit that started the question — the filesystem durability API at our
merge base with the edge — is in **dev** and in **us**, and **not** in #45, purely
because #45 forked before it landed.

## 2. What this changes for the patch set

**Our real base after #45 lands is `dev + #45`, not #45.** Generated against bare
#45, our patch set would carry **seven commits that are already upstream** — either
as review noise or as patches that fail to apply. Generated against `dev + #45`, it
carries exactly our own work.

Two conveniences fall out of the measurement:

- **The stack trial already used the right base.** Merging #45 *into our branch*
  gives `dev + #45 + ours`, because our branch contains dev's head. The 1100/22 and
  1108/22 figures stand.
- **Upstream's own merge is clean**, so `dev + #45` is a well-defined tree we can
  construct locally at any time to generate against, without waiting.

## 2a. Can we predict #45's post-force-push form? **Yes — it is built, and it is green**

The worry this raised is reasonable and it turns out not to hold: *"we cannot predict
the form of #45 until it is force-pushed, because it now has a merge conflict with
upstream."* **It has no conflict with upstream, in either form.** Both were built and
run:

| tree | result |
|---|---|
| `aldum/dev` alone | **693 / 0** |
| **`dev` + #45, merged** | **760 / 0** — no conflicts |
| **#45 rebased onto `dev`** | **760 / 0** — 52 commits replay, **zero conflicts** |

And the two are not merely both green: **the resulting trees are byte-identical**
(`a8cb98e2f11f4435249f48bd71adfa62f4c26904`). Merge or rebase, the integrated
content of #45-on-current-dev is **fully determined** — so its future form is
predictable today, and constructible in about a minute.

Two details the rebase volunteered. Git dropped **two of the 52 commits** itself,
reporting *"patch contents already upstream"* — the filesystem durability API and
the flush-on-quit commit, which reached `dev` by another route. That is the same
cherry-pick duplication §4 describes, confirmed by the tool rather than by
inspection, and it leaves **50 commits** on top of `dev`.

**Our analysis transfers to that future form unchanged.** Merging our branch into
the *rebased* #45 produces **exactly the same four conflicts** as against today's
head — `controller.lua`, `editorController.lua`, `userInputModel.lua`,
`tests/mock.lua`.

**What remains genuinely unpredictable** is not the integration: it is commit
boundaries, messages and hashes (which is what *"force-push for commit hygiene"*
means, and which nothing we ship depends on), plus any **new content** the author
adds for review feedback. Only the second could move our numbers, and re-running the
stack costs minutes.

## 3. What it changes for the risk of #45 moving

**It raises it.** #45 has not been rebased since 2026-07-09 and is missing seven
commits of dev, among them the **64-slot palette** and the **terminal repaint
gate** — both of which touch drawing, which is what a 3000-line editor rework also
touches. When its author rebases onto current dev (or merges dev into it), **#45
itself will change**, and not only in commit hashes.

This is the concrete reason behind the plan's *"re-run the stack, do not just
re-apply the patches"*: the base can move **and change behaviour** in one step.

## 4. The counting error, and the correction

**I counted drift by sha. Content is what matters, and the two lines cherry-pick
between each other**, so the same work exists on both with different hashes.

`git cherry HEAD dsent-https/dsent/dev` — patch-id equivalence rather than hash
identity — over the 67 edge-only commits:

- **4 are already ours by content**, with different shas on each line: the editor's
  checkpoint filesystem info, the extended-palette termcolor fix, the terminal
  repaint gate, and black's own bright slot.
- The rest are new.

Applied to the 15-commit remainder beyond #45: **11 are new by content, not 15.**
And **three of those 11 are alternate versions of colour work we already carry** —
the palette expansion, the colours example and its layout fix exist on both lines in
*different form*, which is exactly why the example collides as an add/add of 245
lines against 247 rather than applying.

**The same pattern appears inside #45**: it carries its own copy of the filesystem
durability API (`95186e57`) which is **not** patch-identical to dev's (`9cb27e0f`) —
dev's version also patches the controller's quit path to flush; #45's touches only
the filesystem utility. Upstream resolves that when #45 lands, and the dry merge says
it resolves cleanly.

**The lesson for every count in this workspace:** *"commits in A not in B"* answers a
question about hashes. When two lines exchange work by cherry-pick, the question we
actually mean is *"changes in A not in B"*, and the command for that is `git cherry`.

## 5. Corrections applied

- `technical_debt/general.md`, the edge entry: 15 shas, **11 by content**, with the
  four duplicates named.
- `doc/development/upstream_drift.md`: same, at stakeholder altitude.
- The merge plan: generate against **`dev + #45`**, and R2's likelihood is raised
  with the rebase-changes-behaviour trap stated.
