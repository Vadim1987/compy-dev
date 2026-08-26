# Tag registry — which tag to reach for, in which repo

**The single inventory of the local tags this feature laid.** Four repositories, one namespace,
one date-stamped snapshot per round. If you are looking for "the state we developed against" or
"where our branch left upstream", it is in a table below.

**All tags here are LOCAL and are never pushed** — the same rule that governs every commit in
this feature. They exist so that a `git fetch` cannot silently change what a *name* means.

## Why tags and not just written-down shas

A sha in a document is absolute, and safe. A **ref name** is not: after a fetch,
`dsent/dsent/dev` denotes a different commit while every sentence citing it still reads as
current. The corpus names refs in several places — `doc/development/smoke_checklists.md` names
two in its anchor table. These tags freeze the *meaning* those names had when the inventory was
taken, so a post-fetch disagreement is resolved by lookup instead of by bisect.

Full shas are recorded because the corpus elsewhere records short ones, and a fetch can
introduce prefix ambiguity.

**Every `base` tag here is a snapshot from the owner's last fetch of that remote — not a live
view** (owner attestation, 2026-08-26: nothing has been fetched in any repo since the work was
reconciled against it). The dates differ per repo because the fetches did. So a `base` tag says
*"this is what we developed against"*, never *"this is what upstream is"*, and the gap between
those two is what recon exists to measure.

## Naming scheme

```
wip77/<YYYYMMDD>/<kind>[-<qualifier>]
```

Date first, so one round is one photograph: `git tag -l 'wip77/20260826/*'` lists the whole set
in any repo. Kinds are uniform across repos:

| kind | means |
|---|---|
| `head` | the branch under test at inventory time |
| `base` / `base-<remote>` | the upstream baseline that branch develops against |
| `mergebase` | where our line left that baseline |
| `premerge` | state before a reconciliation merge, where one happened |
| `alt-<name>` | a diverged sibling branch kept for comparison |

`mergebase` is laid even when it equals `base` — the equality *is* the finding (no divergence),
and uniformity means one command works in every repo.

**Namespacing is not optional in the platform repo**, which carries 169 of the project's own
release tags. `wip77/` keeps our snapshot out of that space.

---

## Round 1 — `20260826`, taken before any fetch

Companion evidence note, with the ahead/behind analysis and its findings:
[`validation/notes/S46-repo-head-inventory.md`](validation/notes/S46-repo-head-inventory.md).

### Platform — `/repo`

| tag | sha | what it is |
|---|---|---|
| `wip77/20260826/head` | `2560a819a0e0608fd76fdacb9ee0d780dca6c396` | `feature/77-newapi-analysis-s20260615`, at the inventory commit |
| `wip77/20260826/base-dsent-edge` | `9ed375d41338cf7dc71bcbbc6ad5c05ef1001ba5` | `dsent/dsent/dev` as our local view held it — **dated 2026-08-03, 23 days stale** |
| `wip77/20260826/base-upstream-dev` | `9cb27e0f81ece6d6d298f47d63b42e9eae39ef0a` | `upstream/dev` (aldum) — **dated 2026-07-22, 35 days stale** |
| `wip77/20260826/mergebase` | `01ac1429198008bc81449364e4ac8134dcf483fa` | where our line left **both** baselines (2026-06-05, local branch `updev`) |

**The divergence, measured against our stale view — the real size of Phase U:**

| against | we are behind | we are ahead |
|---|---|---|
| `dsent/dsent/dev` (edge) | **86** | 838 |
| `upstream/dev` (aldum) | **22** | 838 |

Both baselines share one merge-base, so our branch left the common line on 2026-06-05 — **just
under three months**. The 838 is inflated by this feature's own session/wip commits and is not a
measure of code change. **The 86 is the number that matters, and it is a floor, not the
figure** — it is what a 23-day-old view can see. The editor overhaul reported at the edge is
not in it.

### `balloons` — `/repo/src/examples/balloons`

| tag | sha | what it is |
|---|---|---|
| `wip77/20260826/head` | `99ad70f53a8f29f28c18ee774e0d3db643ea0715` | `main`, branch under test |
| `wip77/20260826/base` | `9e7a1e1a9218607e31400945dc55f705e6ec5854` | `origin/main` |
| `wip77/20260826/mergebase` | `9e7a1e1a9218607e31400945dc55f705e6ec5854` | **equals base** — 5 ahead, 0 behind |

The only repo of the four with **no divergence to reconcile**, which is why its smoke pass is
scheduled first: its result cannot be invalidated by anything recon finds upstream.

### `keyboard` — `/repo/src/examples/keyboard`

| tag | sha | what it is |
|---|---|---|
| `wip77/20260826/head` | `e5689611a0fa8740ce4f39b6f32ac61d399f7fdc` | `newinput`, branch under test |
| `wip77/20260826/base` | `025e85810f8e37fc300ad9d7c9e52a291795aa1b` | `origin/dsent/dev` |
| `wip77/20260826/mergebase` | `025e85810f8e37fc300ad9d7c9e52a291795aa1b` | **equals base** — the S37 merge kept ancestry, exactly as intended |
| `wip77/20260826/premerge` | `05cedec1a6a1c1f3097d6e92b9ba1088aa31fda8` | state before the S37 upstream merge |

**Trap, still live (first recorded S37):** the local branch named `dsent/dev` is **not** a
tracking mirror — it is `eb90389515b86d994e3e3adda68919f986f064d7`, 8 ahead and 36 behind
`origin/dsent/dev`, carrying this feature's own early migration commits. Take upstream from
`origin/dsent/dev`; never trust the local name.

### `maze` — `/repo/src/examples/maze`

| tag | sha | what it is |
|---|---|---|
| `wip77/20260826/head` | `ca599032f4894175f7e2831b3710615c704ed432` | **`newinput-edge`**, branch under test |
| `wip77/20260826/base` | `b8cc436fc9bf14713f5c91e31a158b9115cc28bd` | `dsent/dsent/dev` |
| `wip77/20260826/mergebase` | `b8cc436fc9bf14713f5c91e31a158b9115cc28bd` | **equals base** — upstream is a strict ancestor, 11 ahead / 0 behind |
| `wip77/20260826/alt-newinput` | `a045fdbf6196a69e49a47e04bf9a9fdda3b82bbf` | the diverged older `newinput`, 4 ahead / 37 behind the edge |

**Reach for `head`, not `alt-newinput`, for anything behavioural.** `da9d1c2` — the maze half of
the `Shift+Esc` fix that smoke rows B8–B10 exercise — is on `newinput-edge` **only**. A pass run
on `newinput` tests a branch without the fix.

---

## Rounds planned

**Round 2 — `smoke-green`.** After a human smoke pass comes back clean, tag the exact state it
ran against, per repo, as `wip77/smoke-green/<YYYYMMDD>`. Applied **only** where the pass was
clean, so the tag carries a claim: *a human ran the checklist against exactly this commit.* This
is the "stable version worth pinning on our side" the ordering was chosen to produce.

**Round 3 — `pre-recon` / `post-recon`.** If recon and Phase U move any baseline, take a fresh
dated round **before** the fetch that moves it, so each reconciliation has both endpoints pinned.

## Housekeeping

Add a round by appending a section here; do not retro-edit an earlier round's table — a
photograph that gets touched up is no longer evidence.

**These tags outlive `wip/77`.** When the owner rules on deleting the feature tree, the tags
remain in four repositories with their registry gone. Delete them in the same motion
(`git tag -d $(git tag -l 'wip77/*')` per repo), or promote this file — but do not leave them
orphaned.
