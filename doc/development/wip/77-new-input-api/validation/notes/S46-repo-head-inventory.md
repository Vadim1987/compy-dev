# S46 — repo and head inventory, taken before any fetch

**Date:** 2026-08-26. **Taken by:** session46, at owner instruction, as the prerequisite to
Phase U reconnaissance.

## Why this exists

**A fetch moves ref *names*, not the shas already written down.** Every sha recorded in this
corpus is absolute and survives a fetch. What does not survive is a sentence like *"diffed
against `origin/dsent/dev`"* — after a fetch that name silently denotes something else while
the prose around it still reads as current. `doc/development/smoke_checklists.md` names two
such refs in its anchor table, and the plan names more.

This note pins what each name means **today**, with **full** shas (the corpus records short
ones, and a fetch can introduce prefix ambiguity). It is the pre-fetch photograph: after Phase U
recon, any disagreement between a doc and reality is resolvable here instead of by bisect.

**Ordering it belongs to (owner, 2026-08-26):** smoke pass → owner's PR-slice review → recon →
Phase U → Phase L → Phase G. Recon does **not** subsume the smoke pass — the two are orthogonal,
since recon measures upstream movement and the smoke pass tests device behaviour no suite can
reach.

---

## Platform — `/repo`

| what | value |
|---|---|
| branch | `feature/77-newapi-analysis-s20260615` |
| HEAD | `84c28e4ff3b4df9339d41e452e7466244061fa34` |
| working tree | clean but for the known untracked scratch (9 entries, all on the guardrail's leave-alone list) |
| tags | **169**, the project's own release tags — any tag we add must be namespaced |

**Remotes:** `origin` hleb-rubanau/compy-dev · `dsent` dsent/compy-ide · `upstream`
aldum/compy-dev · `official` compy-toys/compy · `vadim` Vadim1987/compy-dev.

**The refs that matter, and how stale our view of them is:**

| ref | full sha | dated | age at inventory |
|---|---|---|---|
| `dsent/dsent/dev` (the edge) | `9ed375d41338cf7dc71bcbbc6ad5c05ef1001ba5` | 2026-08-03 | **23 days** |
| `dsent/dsent/color-palette-64` | `ba587d69aa1177606f8b6cc379c7598b6fcfa59d` | 2026-08-04 | 22 days |
| `upstream/dev` (aldum) | `9cb27e0f81ece6d6d298f47d63b42e9eae39ef0a` | 2026-07-22 | **35 days** |
| `origin/feature/77-newapi-analysis` | `0b4a97c286778fc98a2e0d2715160f2fa4969281` | 2026-06-06 | 81 days |

**`dsent/dsent/dev` is NOT an ancestor of HEAD.** Our branch left the edge before `9ed375d4`;
the divergence is real and, until recon, unmeasured. The owner reports an editor overhaul at the
edge whose merge status upstream is unknown — **nothing in our local refs can show it**, since
the newest edge ref we hold predates today by more than three weeks.

---

## `balloons` — `/repo/src/examples/balloons` (detached, own PR)

| what | value |
|---|---|
| branch | `main` |
| HEAD | `99ad70f53a8f29f28c18ee774e0d3db643ea0715` (2026-08-25) |
| `origin/main` | `9e7a1e1a9218607e31400945dc55f705e6ec5854` (2026-05-11) |
| relationship | **5 ahead, 0 behind** — a clean fast-forward |
| working tree | 4 untracked docs (`ISSUES.md`, `implementation.md`, `docs/{implementation,requirements}.md`) |

The five commits ahead are exactly this feature's work, ending in the remark retirement:

```
99ad70f docs: retire the review remark, both halves already ruled
cb1dd26 human(TF2): code review
cc0dbd7 fix: submit delivers LINES, not a command string
94a5f02 fix: assign after_submit through compy.input.callbacks
56347d0 feat: migrate off legacy poll idiom onto compy.input.* continuous-session API
```

**This is the tidiest repo of the four**, and the reason to smoke it first: zero divergence to
reconcile, so its result cannot be invalidated by anything recon finds upstream. Note the local
branch `features/2_0` sits at `9e7a1e1a` — the same sha as `origin/main`.

---

## `keyboard` — `/repo/src/examples/keyboard` (detached, own PR)

| what | value |
|---|---|
| branch | `newinput` |
| HEAD | `e5689611a0fa8740ce4f39b6f32ac61d399f7fdc` (2026-08-12) |
| `origin/dsent/dev` | `025e85810f8e37fc300ad9d7c9e52a291795aa1b` (2026-08-02) |
| upstream snapshot branch | `upstream-dsent-dev-20260811` = `025e858…` (same sha) |
| pre-merge state | `newinput-backup-copy-20260811` = `05cedec1a6a1c1f3097d6e92b9ba1088aa31fda8` |
| working tree | **clean** |

**The S37 local-branch trap is still live.** The local branch named `dsent/dev` is
`eb90389515b86d994e3e3adda68919f986f064d7` (2026-08-03) and is **8 ahead / 36 behind**
`origin/dsent/dev`. It is not a tracking mirror and never was — it carries this feature's own
early migration commits. Take upstream from `origin/dsent/dev`, never from the local name.

---

## `maze` — `/repo/src/examples/maze` (detached, own PR)

| what | value |
|---|---|
| branch | **`newinput-edge`** |
| HEAD | `ca599032f4894175f7e2831b3710615c704ed432` (2026-08-25) |
| `dsent/dsent/dev` | `b8cc436fc9bf14713f5c91e31a158b9115cc28bd` (2026-07-24) |
| older branch `newinput` | `a045fdbf6196a69e49a47e04bf9a9fdda3b82bbf` (2026-08-10) |
| working tree | **clean** |

**Two findings here, both needing owner confirmation.**

**1. The maze upstream reconciliation is done — against a base that is itself 33 days old.**
Phase U records maze as *"still owed"* — the input reading, then the merge, before P17. But
`newinput-edge` sits **0 behind / 11 ahead** of `dsent/dsent/dev`: upstream is a strict ancestor,
with eleven of our input-migration commits on top.

**Owner attestation, 2026-08-26:** the reconciliation was made against whatever the **last fetch**
brought in — that fetch advanced the head — and **nothing has been fetched in any repo since**.
What upstream did in the weeks after is unknown.

So the plan's row is not simply *outdated*: maze is **reconciled as of `b8cc436`, 2026-07-24**,
and what remains is a **re-check at recon time, not a redo**. That distinction is the whole value
of the merge's shape — S37 kept ancestry deliberately *"because upstream is expected to move again
and every later re-merge is cheap only while `dsent/dev` stays an ancestor."* It is still an
ancestor. The mechanism is working as designed.

**This generalises to all four repos.** Every baseline below is a snapshot from the owner's last
fetch of that remote, not a live view. The dates differ per repo because the fetches did:

| repo | baseline | commit-dated | our view is at least this stale |
|---|---|---|---|
| platform | `dsent/dsent/dev` | 2026-08-03 | 23 days |
| platform | `upstream/dev` (aldum) | 2026-07-22 | 35 days |
| `keyboard` | `origin/dsent/dev` | 2026-08-02 | 24 days |
| `maze` | `dsent/dsent/dev` | 2026-07-24 | 33 days |
| `balloons` | `origin/main` | 2026-05-11 | 107 days |

These are **floors, not measurements**: a ref's date is when its newest commit was *authored*, so
it bounds how old our view is, and says nothing about what landed upstream afterwards. Only the
fetch answers that — which is exactly why the tags were laid before it.

**2. `newinput` was redone, not merged — and the branches have diverged.** `newinput` is **4
ahead / 37 behind** `newinput-edge`, and `a045fdb` is **not** an ancestor of it. The four old
commits look reworked into finer-grained equivalents on the newer base — e.g. `a045fdb` *"ask Key
for Shift instead of folding the pair by hand"* corresponds to `e2dacb0` *"ask the keyboard
whether Shift is down"* plus `3468f1f` *"drop the hand-written Shift fold"*. **That correspondence
is inferred from commit subjects, not proven by diff** — it is the one claim here that has not
been verified in code.

**The maze smoke pass must run against `newinput-edge`.** `da9d1c2` — the maze-side half of the
`Shift+Esc` fix that B8–B10 exercise — is contained in **`newinput-edge` only**. A pass run on
`newinput` would test a branch that does not carry the fix.

---

## Corpus pins checked against reality

`doc/development/smoke_checklists.md`, keyboard's four-commit anchor table:

| row | recorded | actual today | verdict |
|---|---|---|---|
| `keyboard` under test | `e568961` | `e5689611a0fa…` | ✅ current |
| `keyboard` upstream | `025e858` | `025e85810f8e…` | ✅ current |
| platform repo | `5128a4bf` | `84c28e4ff3b4…` | ⚠️ **stale by 3 commits** |
| platform edge | `9ed375d4` | `9ed375d41338…` | ✅ current |

The stale row is the document's own instruction firing as designed (*"refresh them if the tree
has moved before you run"*) — the three commits are session45's smoke-doc work and its wrap, none
of which touch behaviour. Refresh it when the pass is scheduled, not now: it will move again.

---

## Proposed protection, for owner approval

**Namespaced local tags**, so a fetch cannot overwrite what a name meant today. The platform repo
already carries 169 release tags, so ours must not collide with that space:

- platform: `wip77/pre-recon/edge-20260826` → `9ed375d4…`, `wip77/pre-recon/upstream-dev-20260826`
  → `9cb27e0f…`, `wip77/pre-recon/head-20260826` → `84c28e4f…`
- each example repo: `wip77/pre-recon/head-20260826` and one per upstream ref it tracks

Tags stay **local and unpushed**, like every other commit in this feature.

A second round belongs at **smoke-green** — the owner's own argument for smoking first is that it
yields a stable state worth pinning. Suggested shape: `wip77/smoke-green/<repo>-<date>`, applied
only to repos whose pass came back clean, so the tag means *"a human ran the checklist against
exactly this"*.

---

## Tags laid from this inventory

Sixteen local tags, four repos, namespace `wip77/20260826/*`. The registry —
**the** lookup for which tag to reach for — is
[`../../TAGS.md`](../../TAGS.md). It also carries the platform divergence
measurement this note lacked at first writing: **86 commits behind the edge,
22 behind aldum upstream, merge-base 2026-06-05**, and the 86 is a floor,
since it is what a 23-day-old view can see.
