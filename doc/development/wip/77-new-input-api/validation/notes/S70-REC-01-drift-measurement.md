---
description: REC-01 recon round 2 — live drift of all four repos plus the two open upstream PRs, measured 2026-09-03 with the commands behind every number
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# REC-01 — the live drift, measured 2026-09-03

**Scope, widened by the owner this session:** *"We need to recon and merge against
not only these repos, but against platform again — most likely our changes will be
combined with another PR, and drift evaluated towards edge. I need all this
measured and analyzed on recon stage."* Plus: **https remotes**, because the SSH
remotes depend on the owner's key.

Every figure below is followed by the command that produces it. **Do not cite
these numbers after a fetch** — re-derive; that is what the round-3 tags are for.

## 0. What was added to the repositories, and what was deliberately not

**`-https` remotes were added, not substituted.** Ten of them, one per existing
SSH remote across the four repos (`upstream-https`, `dsent-https`,
`official-https`, `origin-https`, `vadim-https` in the platform repo;
`origin-https`/`hleb-https`/`dsent-https` in the examples). All ten were
reachability-tested before being added.

Two consequences worth stating, because they are the reason this shape was chosen
over `url.<https>.insteadOf`:

- **The owner's SSH remotes and their push URLs are untouched.** Nothing about
  their workflow changes, and no credential is needed for anything we do.
- **No existing remote-tracking ref moved.** The stale views this phase reasons
  about — `upstream/dev`, `dsent/dsent/dev` — still point where they pointed
  before this session, so the pre-recon photograph is intact *by construction*
  and the round-1 tags remain comparable. The live views live under new names.

Fetches used `--no-tags` throughout: the round-1/round-3 `wip77/*` tags are local
and must not be diluted by upstream tag namespaces.

**Nothing was merged, and nothing was pushed.** This is the recon stage.

## 1. The platform repo — the headline is not the drift, it is who else is in the queue

`aldum/compy-dev` has **four open PRs**, and two of them are ours:

| PR | title | head | base | opened |
|---|---|---|---|---|
| **#45** | *Editor rework: explicit modes, line navigation, durable accepts, undo/redo (spec 1.0+1.1)* | `Vadim1987:deliver/editor-stage1` `16eb33d7` | `aldum:dev` | 2026-07-21 |
| **#41** | *perf(input): cut per-character render cost (D2)* | `Vadim1987:fix/d2-input-render-cost` `ebc3117c` | `aldum:dev` | 2026-07-02 |
| **#22** | *Feature/77 new API analysis* — **ours, and still a draft** | `hleb-rubanau:feature/77-newapi-analysis` `0b4a97c2` | `aldum:dev` | 2026-06-05 |
| #15 | *doc(localization): first draft* — the owner's, unrelated | `hleb-rubanau:feature/132-…` | `aldum:dev` | 2026-05-17 |

```sh
curl -s "https://api.github.com/repos/aldum/compy-dev/pulls?state=open&per_page=100"
git fetch --no-tags upstream-https "refs/pull/45/head:refs/remotes/upstream-pr/45"   # and 41, 22, 15
```

**PR #22 already exists**, on the branch **`feature/77-newapi-analysis`** — note the
name: our working branch is `feature/77-newapi-analysis-s20260615`, and the PR's
head commit `0b4a97c2` is an ancestor of ours, 1281 commits back. `PR-01-04` has a
decision to make that the assembly guide does not currently name: **reuse #22 or
open a new PR.**

### Ahead / behind, measured at `wip77/20260903/head` (`97839691`)

| against | behind | ahead | merge-base | dry merge |
|---|---|---|---|---|
| `upstream-https/dev` (aldum, `af9a5782`, 2026-08-17) | **0** | 1257 | `af9a5782` | **clean** |
| `dsent-https/dsent/dev` (edge, `5a52cba2`, **2026-09-03**) | **71** | 1263 | `9cb27e0f` (2026-07-22) | 7 files conflict |
| `upstream-pr/45` (`16eb33d7`) | 52 | 1264 | `945a5d1d` (2026-07-09) | 4 files conflict |
| `upstream-pr/41` (`ebc3117c`) | 1 | 1273 | `1a0261c9` | **clean** |
| `official-https/main` (compy-toys, 2026-03-08) | 0 | 1311 | — | ancestor; not a factor |

```sh
git rev-list --left-right --count <ref>...HEAD
git merge-base HEAD <ref>
git merge-tree --write-tree HEAD <ref>     # exit 0 = clean; no worktree needed
```

**`MERGE-01-04` still holds: we are zero behind `aldum/dev`, and it has not moved
since 2026-08-17.** A re-merge against the PR's own base is a no-op *today*. The
drift the owner asked about is entirely **towards the edge**.

### The edge already contains both input-touching PRs

```sh
git merge-base --is-ancestor upstream-pr/45 dsent-https/dsent/dev   # true
git merge-base --is-ancestor upstream-pr/41 dsent-https/dsent/dev   # true
git rev-list --left-right --count upstream-https/dev...dsent-https/dsent/dev   # 6  71
```

This is the single most useful fact of the round: **evaluating towards the edge
evaluates against PR #45 and PR #41 at the same time.** The edge is 71 ahead and 6
behind `aldum/dev`, and its 71 include #45's 52 and #41's one. It is, in effect,
*the tree that results if both PRs land*, plus edge-only work — which is exactly
the combination the owner expects.

## 2. What is in those 71, and where it lands on us

**17 of the 67 non-merge commits touch the files this feature restructured**
(`userInputController.lua`, `consoleController.lua`, `controller.lua`,
`src/model/input/`, `src/view/input/`):

```sh
git log --format='%h %ad %s' --date=short --no-merges \
  $(git merge-base HEAD dsent-https/dsent/dev)..dsent-https/dsent/dev -- \
  src/controller/userInputController.lua src/controller/consoleController.lua \
  src/model/input/ src/view/input/ src/controller/controller.lua
```

They are one body of work — the editor rework of spec 1.0/1.1 — and its named
pieces are: explicit **navigation/editing submodes** with an indicator, **text-level
undo** of the open block (new file `src/model/input/editHistory.lua`), **word
deletion** on Ctrl+Backspace / Ctrl+W, **checkpoints** on Ctrl+K / Ctrl+Shift+K,
**bare Home/End made line-scoped**, per-accept **fsync** durability, *"the editor's
1.1 extras no longer leak platform-wide"*, and *"bare Ctrl+S no longer closes the
editor"*.

### File overlap

```sh
git diff --name-only 3256aac..HEAD -- src/ tests/ | sort               # 87 files, ours
git diff --name-only $(git merge-base HEAD dsent-https/dsent/dev)..dsent-https/dsent/dev -- src/ tests/ | sort
comm -12 ours.txt edge.txt                                             # 25 files
```

25 files are touched by both sides; 11 of them are also in PR #45 alone.

### The dry merge, and what it says

`git merge-tree` against the edge conflicts in **7 files / 10 hunks**:
`.gitignore`, `controller.lua` (2), `editorController.lua` (2), `consoleModel.lua`,
`userInputModel.lua` (2), `examples/colors/main.lua` (add/add), `tests/mock.lua`.
Against PR #45 alone it is 4 files: `controller.lua`, `editorController.lua`,
`userInputModel.lua`, `tests/mock.lua`.

**`userInputController.lua` and `consoleController.lua` — the two files this
feature is most about — auto-merge.** That is the good news and it is real. But a
textual auto-merge is not a semantic one, and two collisions are visible in the
hunks themselves:

1. **`UserInputModel.new`'s signature is changed by both sides.** Ours is
   `new(cfg, eval, custom_label)`; the edge's is
   `new(cfg, eval, oneshot, custom_label, editing)` — it keeps the pre-existing
   `oneshot` positional (which is at the PR base too, so it is *not* the retired
   `auto_hide` predecessor this feature ruled on — check that before writing
   anything about it) and adds `editing`, the flag that gates the editor's rich
   input. **Reconciling this is a design call, not a merge resolution.**
2. **`set_text` was rewritten by both sides for different reasons.** Ours is
   `BUG-02-01`'s list normalisation; theirs resets `edit_history` and does its own
   `sanitize_utf8` + split. Both behaviours are wanted, and the combined function
   is somebody's design decision.

And one that no merge tool will report, because our branch did not touch those
lines: **the edge changes what keys do inside the widget** — bare Home/End become
line-scoped (Ctrl+Home/End does the block jump), Ctrl+Backspace/Ctrl+W delete a
word when `editing` is on, Ctrl+Y is taken for redo by the editor's controller.
`doc/input_api.md` documents key behaviour, including the combos the framework
keeps; **the guide, not the code, is where this merge will hurt.** Whether our
specs assert the old Home/End semantics is a question for the merge, and it is
cheap to answer then (`grep -rn "home\|jump_home" tests/input/`).

## 3. The three example repos — nearly nothing

```sh
git -C src/examples/<repo> rev-list --left-right --count <upstream>...HEAD
git -C src/examples/<repo> merge-tree --write-tree HEAD <upstream>
```

| repo | upstream | behind | ahead | dry merge |
|---|---|---|---|---|
| `balloons` | `origin-https/main` (`9e7a1e1`, 2026-05-11) | **0** | 8 | — |
| `maze` | `dsent-https/dsent/dev` (`b8cc436`, 2026-07-24) | **0** | 13 | — |
| `keyboard` | `origin-https/dsent/dev` (`96d6629`, 2026-08-20) | **1** | 37 | **clean** |

The one commit is `96d6629` *"keyboard: emit k, the same game under a name a
beginner can type"* — **32 added lines in `.compy/build`, no source file touched**.

**`MERGE-01-01`/`-02`/`-03` are therefore near-empty rows**: two have nothing to
merge and the third has a build-descriptor commit that applies cleanly. The
round-1 trap still stands and is re-verified — `keyboard`'s **local** branch named
`dsent/dev` is not a tracking mirror; take upstream from `origin/dsent/dev`.

## 4. Analysis — what this means for the sequence

- **The platform re-merge the owner asked for is not a merge today.** Against the
  PR's own base we are current. Everything the recon found is against the *edge*,
  which is not the PR base and does not have to be merged before shipping.
- **The real question is order of landing, and it is not ours to answer.** If #45
  lands in `aldum/dev` first, our PR reconciles against it — 4 conflicting files,
  two of which need a design call. If ours lands first, #45 reconciles against us.
  **The cost is roughly symmetric in files and asymmetric in knowledge**: we know
  what our side means, and the editor rework's author knows what theirs means.
  Either way, the merge is small in text and non-trivial in semantics, and the
  reconciliation cost is *the same work* whoever does it — which is an argument
  for saying so in the PR description rather than for delaying the PR.
- **What would change the picture: an upstream release.** `aldum/dev` has not
  moved in 17 days. If it moves before `PR-01`, re-run this measurement — the
  round-3 tags make that a two-command diff.
- **Nothing here delays `ACC-02`.** The device passes smoke the example repos, and
  those repos have no drift to take first — which was the whole reason `REC-01`
  and `MERGE-01` were moved ahead of them. That ordering can now be discharged
  cheaply.

## 5. Tags laid — round 3, `wip77/20260903/*`

Per `TAGS.md`'s own round-3 plan. The registry entry is in that file; these are
the shas.

| repo | tag | sha |
|---|---|---|
| platform | `head` | `97839691470a00e91f5a1e43d3e67206a35c927c` |
| platform | `base-upstream-dev` | `af9a5782980cdb5684a8b434916da503a5b61b69` |
| platform | `base-dsent-edge` | `5a52cba254303c2d92fc8b9546b3d01a917fc2db` |
| platform | `base-pr45` | `16eb33d79fd8711e8c467d8581d47e6632b1607e` |
| platform | `base-pr41` | `ebc3117c114a0268051cbb9a41c1d8fa4c99f64a` |
| platform | `mergebase-upstream-dev` | `af9a5782980cdb5684a8b434916da503a5b61b69` (**equals base** — the equality is the finding) |
| platform | `mergebase-dsent-edge` | `9cb27e0f81ece6d6d298f47d63b42e9eae39ef0a` |
| platform | `mergebase-pr45` | `945a5d1d765fac35b6360238077b214c5bbb8fcd` |
| `balloons` | `head` / `base` / `mergebase` | `c2bd9b99…` / `9e7a1e1a…` / `9e7a1e1a…` |
| `maze` | `head` / `base` / `mergebase` | `28213c72…` / `b8cc436f…` / `b8cc436f…` |
| `keyboard` | `head` / `base` / `mergebase` | `e5689611…` / `96d66292…` / `025e8581…` |

## 6. Two things the owner should see

- **PR #22 is open and draft** against `aldum:dev`, on a branch whose name lacks
  our `-s20260615` suffix. `PR-01-04` says *"open the coordinated PRs"*; it does
  not say what happens to the one that is already open.
- **The push URLs of the new remotes are the https URLs**, so a `git push` to one
  would prompt for credentials rather than silently succeeding. That is a
  side-effect of the shape, not a guard — **the standing rule is still that we
  never push**, in any of the four repositories.
