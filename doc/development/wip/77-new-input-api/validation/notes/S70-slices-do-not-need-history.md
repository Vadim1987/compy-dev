---
description: why concern-based slices survive a 1276-commit branch and a squashed import — they are cut from content, not from history — plus what today's ruling does to Set 2
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# Concern slices do not need history, and never did

**The owner's question, 2026-09-03:** *"slices by concern are ideal… but they require
undistorted history, and we are now at 1000+ commits ahead of `updev`, most of which
produce `wip/`. How is that achievable?"*

**They do not require history.** The premise is the only thing wrong here, and it is
a reasonable premise — most branch-to-PR workflows do work from commits.

## 1. What the assembly procedure actually does

`pr-assembly-guide.md` §1.0 is explicit about it, and it was made explicit by an owner
correction on 2026-08-26: *"the pathspecs are an **output**"*. The procedure is:

```
enumerate  →  classify  →  assert nothing is unclassified  →  cut
```

- **Enumerate** is a **two-tree diff** with `wip/` excluded by pathspec —
  `git diff <base> <tip> --name-only -- . ':(exclude)…/wip/77-new-input-api/**'`.
  No commit is read. No range is walked.
- **Classify** is a `case` over **directory rules**, so a file that did not exist when
  the rules were written classifies itself.
- **Assert** is a hard gate: an unclassified file stops the cut.
- **Cut** produces one patch per concern from the same two trees.

**Nothing in that chain touches our commit graph.** 1276 commits, 901 `wip/` files of
churn, a squashed import of someone else's 50 commits, three corrective commits after
a force-push — none of it is visible to the procedure. Only the two trees are.

## 2. Verified against today's tree, with the new base

Run just now, `aldum/dev` → our head:

| | |
|---|---|
| commits on the branch | **1276** |
| `wip/` files touched | **901** — all excluded |
| **shipping surface** | **113 files** — 114 before the drift document moved to the working tree |
| unclassified | **0** — the gate passes unchanged |

Partition: Set 1 **26** · Set 2 **17** · 3a **21** · 3b **22** · 3c **1** · 3d **3** ·
3e **4** · 3f **8** · 3g **12**.

Against the 2026-08-26 verification (100 files: 3a 11, 3b 21, 3d 3, 3e 4, 3f 7, 3g 12,
Set 1 26, Set 2 15) the change is **+13 files**, almost all in `3a` (the persistent
docs this phase has been writing) — no new *kind* of content, and **no rule needed
changing**.

**So the answer to the question is: this already works, today, at this size.** The only
edit the import forces is the **base**: `$BASE` becomes the tree of `updev + #45`
instead of the old anchor sha.

## 3. Two things the run turned up that are not about history

**(a) Set 2 is `agents/`, and this morning's ruling says `agents/` is not promoted
upstream.** The set is 17 files — `AGENTS.md`, `CLAUDE.md` and the whole rule chain.
The owner ruled today that the rule chain is *"a working surface that is not promoted
to upstream… carved out alongside `wip/`"*, with **generic rules possibly surviving**
(commenting, the coding guide, doc formatting) and workflow, boot pointers and
operational limits not.

**That ruling lands exactly on Set 2, and it was made after the set was drawn.** Three
possible dispositions, and it is an owner call, not a classifier fix:

- **drop Set 2 entirely** — consistent with *"not promoted upstream"*;
- **keep the generic half** — `rules.md` (minus its commit conventions), `commenting.md`,
  and the documentation-format rules; drop the six boot planes, `sessions.md`,
  `revalidation.md`, `materialization.md`, and probably `roadmap.md`;
- **keep it whole** — which contradicts the ruling and should then say why.

Whatever is chosen, **the classifier's `agents/*` rule stops being a routing rule and
becomes a scope decision**, and the split does not follow file boundaries — `rules.md`
holds both halves.

**(b) The classifier's `doc/*.md` rule crosses directories.** In a shell `case`, `*`
matches `/`, so `doc/*.md` swallows everything under `doc/` that the earlier, more
specific Set 1 cases did not already claim. That is why the gate passes with zero
unclassified even for files nobody has considered: today's new drift document landed
in **3a, the input-documentation slice**, which is not where it belonged by concern —
it is a release-process document, not part of the input API's prose.

The gate is doing its job (nothing is silently omitted), but **a catch-all that never
fires is not a gate**. Worth a narrower rule before the cut, so that a genuinely new
kind of document surfaces as `UNCLASSIFIED` instead of being absorbed.

*(That example has since resolved itself the other way: the owner moved the drift
document into the working tree, where it is excluded from the enumeration entirely.
The finding stands without it — the catch-all still cannot fail for anything new
under `doc/`, and the shipping surface is now **113** files, not 114.)*

## 4. What actually changes for `PR-01-01`

1. `$BASE` becomes the **tree of `updev + #45`** — constructible locally, and pinned.
2. Re-run §1.0's derivation. Expect a handful of new files in `3a` and **zero**
   unclassified; if that is not what happens, the difference is the finding.
3. Settle Set 2 against the `agents/` ruling **before** cutting, since it changes what
   ships rather than how it is grouped.
4. Narrow `doc/*.md` so the gate can still fail.
5. The two hunk-level carve-outs in §1.1 are unaffected — they were never derived from
   history either.
