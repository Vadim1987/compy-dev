---
description: every git anchor this reconciliation rests on — remotes, refs, PR heads, merge bases, derived trees and the commands that rebuild them
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# Git anchors — the objects this reconciliation is measured against

**Companion to [`TAGS.md`](TAGS.md), not a replacement for it.** `TAGS.md` is the
registry of the **local tags** this feature laid, and stays authoritative for those.
This file records the **remotes, upstream refs, pull-request heads, merge bases and
derived trees** the 2026-09-03 recon reasoned over, plus the commands that rebuild
each — so that a number quoted anywhere in this tree can be re-derived rather than
trusted.

**Every sha below is a snapshot taken 2026-09-03.** Upstream refs move. The
commands are the durable part.

---

## 1. Remotes

**Ten `-https` remotes were added on 2026-09-03 beside the existing SSH ones**, not
replacing them (owner: all repositories are public, and the work must not depend on
their SSH key). Consequence worth keeping: **no existing remote-tracking ref moved**,
so pre-2026-09-03 views remain comparable, and the live views live under the new
names.

### Platform — `/repo`

| remote | URL | what it is |
|---|---|---|
| `origin` / `origin-https` | `hleb-rubanau/compy-dev` | the owner's fork — where our branch lives |
| `upstream` / `upstream-https` | `aldum/compy-dev` | **the line we PR into** |
| `dsent` / `dsent-https` | `dsent/compy-ide` | the **edge** — most advanced, most experimental |
| `official` / `official-https` | `compy-toys/compy` | far behind; not a factor |
| `vadim` / `vadim-https` | `Vadim1987/compy-dev` | the author of PRs #45 and #41 |

### Examples

| repo | remote | URL |
|---|---|---|
| `balloons` | `origin` / `origin-https` | `hleb-rubanau/compy-balloons` |
| `maze` | `dsent` / `dsent-https` | `dsent/compy.maze` — **upstream** |
| `maze` | `hleb` / `hleb-https` | `hleb-rubanau/compy-games-maze` |
| `keyboard` | `origin` / `origin-https` | `dsent/keyboard` — **upstream, and renamed** |
| `keyboard` | `hleb` / `hleb-https` | `hleb-rubanau/compy-games-keyboard` |

**`dsent/keyboard` is now `dsent/compy.keyboard`.** The old address resolves by
redirect and `git ls-remote` returns byte-identical tips through either. Correct it
when that repository's PR opens.

**Two SSH views were stale when measured, and neither was used:** the platform edge
by 13 days, and `keyboard`'s upstream by **exactly the one commit that constitutes
its drift**.

---

## 2. Platform anchors

| anchor | sha | date | note |
|---|---|---|---|
| **our branch** `feature/77-newapi-analysis-s20260615` | `bb94c151…` | 2026-09-03 | moves; the branch name is the anchor |
| **the feature's PR base** | `3256aac4d6dfde3a6555b5d7e9b8375414183818` | — | what *"provenance: introduced in this branch"* is tested against |
| `upstream/dev` (aldum) | `af9a5782980cdb5684a8b434916da503a5b61b69` | author 2026-08-12, committed 2026-08-17 | **we are 0 behind it** |
| `dsent/dsent/dev` (edge) | `5a52cba254303c2d92fc8b9546b3d01a917fc2db` | 2026-09-03 | 71 ahead of `dev`, 6 behind |
| `official/main` | `0022004e98a890aeabc17c136323ddf910c61926` | 2026-03-08 | an ancestor of ours; not a factor |
| `vadim/dev` | `bd84a1f434e0d9b78d718f0830ea4b2c36ebdd84` | 2026-04-07 | the PR author's own fork default |

### Open pull requests on `aldum/compy-dev`, fetched to `refs/remotes/upstream-pr/*`

| PR | head | title | our relation |
|---|---|---|---|
| **#45** | `16eb33d79fd8711e8c467d8581d47e6632b1607e` | editor rework — explicit modes, undo/redo | **our new base by content** |
| **#41** | `ebc3117c114a0268051cbb9a41c1d8fa4c99f64a` | perf(input): per-character render cost | contained in the edge; merges clean |
| #22 | `0b4a97c286778fc98a2e0d2715160f2fa4969281` | *"Feature/77 new API analysis"* — **ours, draft** | **ignored by owner ruling**; will be superseded |
| #15 | `a5f6a781cb9bd5f3116691f053ebc5507ec7cf54` | doc(localization) — the owner's, unrelated | — |

```sh
git fetch --no-tags upstream-https "refs/pull/45/head:refs/remotes/upstream-pr/45"
```

### Merge bases

| pair | base | date |
|---|---|---|
| ours × `aldum/dev` | `af9a5782…` — **equals dev's head** | 2026-08-12 |
| ours × edge | `9cb27e0f81ece6d6d298f47d63b42e9eae39ef0a` | 2026-07-21 |
| ours × #45 | `945a5d1d765fac35b6360238077b214c5bbb8fcd` | 2026-07-09 |
| **#45 × `aldum/dev`** | `945a5d1d…` — **#45 forked here and is 7 behind** | 2026-07-09 |

### The derived tree everything is generated against

**`updev + #45` = tree `a8cb98e2f11f4435249f48bd71adfa62f4c26904`.**

This is the tree that exists the moment #45 lands, and it is **reachable two ways
that agree byte for byte** — merging #45 into `dev`, or rebasing #45 onto `dev`. It
is the base for the patch set, and it can be rebuilt at any time:

```sh
git merge-tree --write-tree upstream-https/dev upstream-pr/45     # prints the tree oid; exit 0 = clean
```

**The seven commits `dev` has that #45 lacks** — all seven already ours:
`af9a5782` (black's bright slot), `c120878b` (termcolor), `1a6eceb6` (colours
example), `f2958ecd` (64-slot palette), `1b0fb781` (repaint gate), `3e249423`
(checkpoint fs info), `9cb27e0f` (fs durability API).

**Two commits git itself drops when #45 is rebased** — *"patch contents already
upstream"*: `95186e57` (#45's copy of the fs durability API) and `1efd2cbe`
(flush on quit and background). 52 replay as **50**.

**Four edge commits that are patch-equivalent to work we already carry** (different
shas on each line): `38d7c754`, `6897d689`, `9693779a`, `ea6efd1d`.

---

## 3. Example-repo anchors

| repo | our head | branch | upstream ref | upstream head | drift |
|---|---|---|---|---|---|
| `balloons` | `c2bd9b99e7b2736be8ea41b376f31461e3a58f2e` | `main` | `origin-https/main` | `9e7a1e1a…` (2026-05-11) | **0** — frozen by owner attestation |
| `maze` | `28213c722622448c8bcc70300a5e5dd9a51a9b43` | `newinput-edge` | `dsent-https/dsent/dev` | `b8cc436f…` (2026-07-24) | **0 on every live branch** — see the two dead ones below |
| `keyboard` | `e5689611a0fa8740ce4f39b6f32ac61d399f7fdc` | `newinput` | `origin-https/dsent/dev` | `96d66292…` (2026-08-20) | **1 commit**, packaging only, merges clean |

**The `keyboard` trap, first recorded at session 37 and still live:** the **local**
branch named `dsent/dev` is `eb90389515b86d994e3e3adda68919f986f064d7` — **8 ahead and
37 behind** the real upstream (it was 8/36 at session 46; the extra one behind is the
packaging commit). It is not a tracking mirror. Take upstream from
`origin-https/dsent/dev`; never from the local name.

**`maze`, branch by branch — and two of the eleven are *not* ancestors, corrected
2026-09-04 after the peer review checked what I had generalised.** Ancestors of our
head: `dsent/dev`, `feat/reconcile`, `main`, `v2`, `v3`, `v3.1`, `v3.2`, `v3.3`,
`v3.4` — nine. **Not ancestors: `v1` (1 commit) and `v1.1` (21).** They are abandoned
release lines from February and March 2026, and **upstream's own `dsent/dev` does not
contain them either** — so there is nothing to merge *from* them and the drift verdict
is unchanged; what was wrong was the sentence, which named eleven branches on six
measurements.

```sh
for b in $(git for-each-ref --format='%(refname:short)' refs/remotes/dsent-https); do
  git merge-base --is-ancestor $b HEAD && echo "ancestor  $b" || echo "NOT       $b"
done
```

---

## 4. Submodules — the thing that breaks a fresh clone

The platform repo carries two, and **a clone of `/repo` does not populate them**; the
suite then fails 38 specs with *"module `util.string.string` not found"*, which reads
like a real defect and is not.

| path | upstream | pinned at |
|---|---|---|
| `src/util/string` | `compy-toys/stringutils` | `ff9be4b9e4cd3c20e9714f2e513b69d96bb03b90` |
| `src/lib/metalua` | `compy-toys/metalua` (branch `dev`) | `d0dbd0d982f87512b806949ea697ea71f39cd0b4` |

```sh
cp -r /repo/src/util/string/. <clone>/src/util/string/
cp -r /repo/src/lib/metalua/.  <clone>/src/lib/metalua/
rm -f <clone>/src/util/string/.git <clone>/src/lib/metalua/.git   # or git status breaks
```

---

## 5. The commands, so nothing here has to be trusted

```sh
# drift in both directions, and where the lines parted
git rev-list --left-right --count <ref>...HEAD
git merge-base HEAD <ref>

# conflicts predicted without touching a working tree
git merge-tree --write-tree HEAD <ref>            # exit 0 = clean

# CHANGES not in B, rather than COMMITS not in B — the two lines cherry-pick,
# so this is the count that means anything
git cherry HEAD dsent-https/dsent/dev

# the shipping surface: a two-tree diff, wip excluded. No history is read.
git diff <base> HEAD --name-only -- . ':(exclude)doc/development/wip/77-new-input-api/**'

# the import: THREE-WAY, either spelling. A bare `git apply` invents conflicts.
git merge --squash upstream-pr/45          # …or: git apply --3way <patch>

# the invariant, after the import and after every corrective commit
git diff <tree a8cb98e2…> HEAD -- src/ tests/     # must be OUR work and nothing else
```

## 6. Suite anchors, for comparing any future tree

All run in the container on **LuaJIT 2.1** — *the owner runs PUC Lua, so none of these
is a their-machine claim.*

| tree | suite |
|---|---|
| our branch | **1055** / 0 / 0 / 10 |
| `aldum/dev` alone | 693 / 0 |
| #45 alone (on its own stale base) | 753 / 0 |
| `dev` + #45 | **760 / 0** |
| ours + #45 | 1100 / 22 |
| ours + #45 + the whole edge | 1108 / 22 — *the same 22* |
