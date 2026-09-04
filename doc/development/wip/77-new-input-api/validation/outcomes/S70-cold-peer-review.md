---
description: cold peer review of session70's own commits — integrity and arithmetic, not the plan
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# S70 cold peer review — findings

**Scope confirmed first.** `git log --oneline 1299ed2b..HEAD` is 34 commits (the
prompt's "roughly 25" undershoots; not itself a defect, just noting the actual count).
`git diff --stat 1299ed2b..HEAD -- src/ tests/` is empty — the range is documentation
only, as claimed.

**A note on method, because it changed how this review was done.** Partway through,
`git status` showed five files with uncommitted working-tree changes
(`ROADMAP.md`, `session70/track.md`, `S70-edge-essence-and-stack.md`,
`S70-platform-ancestry.md`, `upstream-drift.md`) that were **not present** at the
start of this session (the initial status snapshot did not list them) — someone is
actively editing this same working tree concurrently with this review, continuing the
"drift document is working-tree, not corpus" theme from commit `ea0c05c0`. One of my
early checks (the citation-link check on `upstream-drift.md`) read the live working
tree and was **contaminated by this in-flight edit** — it reported the link as
resolving when the *committed* version does not. Every finding below was re-verified
against `git show HEAD:<path>` / `git cat-file` (i.e., the actual committed range
under review), not the live working tree. Findings 1 and 2 exist **only** in the
committed state; the in-flight edit appears, incidentally, to already fix them, but
that fix is uncommitted and out of the range this review covers.

Three findings survive verification against the committed range. Everything else
checked — dozens of shas, merge bases, drift counts, suite numbers, and citations —
reproduced exactly.

---

## Finding 1 — check D fails as committed: one broken outward link and four stale references to the old path

**`validation/notes/upstream-drift.md`'s own outward link is broken, as committed.**
Line 143 (`git show HEAD:.../upstream-drift.md`):

```
[the input API guide](../input_api.md)
```

From `doc/development/wip/77-new-input-api/validation/notes/`, `../input_api.md`
resolves to `doc/development/wip/77-new-input-api/validation/input_api.md`, which
does not exist in `HEAD`:

```sh
git cat-file -e HEAD:doc/development/wip/77-new-input-api/validation/input_api.md
# fatal: ... does not exist in 'HEAD'
```

The real target, `doc/input_api.md`, needs five `../` segments, not one.

**Four documents in the committed range still cite the pre-move path**
`doc/development/upstream_drift.md`, which no longer exists in `HEAD`
(`git cat-file -e HEAD:doc/development/upstream_drift.md` → does not exist):

```sh
git grep -n "doc/development/upstream_drift" HEAD -- doc/
```
```
HEAD:doc/development/wip/77-new-input-api/ROADMAP.md:1602
HEAD:.../implementation/sessions/session70/track.md:192
HEAD:.../validation/notes/S70-edge-essence-and-stack.md:33
HEAD:.../validation/notes/S70-platform-ancestry.md:140
```
(a fifth hit, in the review prompt itself, narrates the move rather than citing the
document and is not a defect).

**Size:** this is exactly the pair of things check D was commissioned to verify
("nothing still points at the old path", "its one outward link works") and both fail
in the committed state — five sites total. Not hypothetical: a reader following any
of these four references, or the document's own citation, hits a dead path today. As
noted above, an uncommitted edit already sitting in this working tree appears to fix
all five, but it is not part of the reviewed range.

---

## Finding 2 — ANCHORS.md: "All are ancestors of our head" is false for two of the eleven `maze` branches

**File:** `doc/development/wip/77-new-input-api/ANCHORS.md:135-137`

> **`maze` was checked branch by branch**, not only on the tracked one — `dsent/dev`,
> `feat/reconcile`, `main`, `v1`, `v1.1`, `v2`, `v3`, `v3.1`, `v3.2`, `v3.3`, `v3.4`.
> **All are ancestors of our head.**

`v1` and `v1.1` are not ancestors of our head (`newinput-edge`,
`28213c722622448c8bcc70300a5e5dd9a51a9b43`):

```sh
cd src/examples/maze
git merge-base --is-ancestor dsent-https/v1   newinput-edge   # exit 1 (not an ancestor)
git merge-base --is-ancestor dsent-https/v1.1 newinput-edge   # exit 1 (not an ancestor)
git merge-base --is-ancestor dsent-https/v2   newinput-edge   # exit 0, for contrast
```

`v1` (`5523384c`, 2026-02-25) and `v1.1` (`cd4d91d0`, 2026-03-17) diverge from our head
at `75c4a611`, with real content on the far side — `git diff 75c4a611 dsent-https/v1`
shows 33 insertions/24 deletions across `graphics.lua` and `main.lua`, not a rename or
no-op. The other nine branches in the list (`dsent/dev`, `feat/reconcile`, `main`,
`v2`–`v3.4`) are genuinely ancestors; only these two fail.

**Size:** this is the file the review prompt names as "most likely to be trusted
later," and the claim is a direct, checkable falsehood, not a rounding or staleness
issue. Practical impact looks low (`v1`/`v1.1` read as abandoned pre-`v2` tags, and the
drift claim that actually matters — `dsent/dev` 0-behind — is independently correct),
but "all are ancestors" is not a hedged claim and does not hold as written.

---

## Finding 3 — S70-slices-do-not-need-history.md: the partition table was not updated when the total was corrected, and no longer sums to itself

**File:**
`doc/development/wip/77-new-input-api/validation/notes/S70-slices-do-not-need-history.md:44-52`

The table states **shipping surface: 113 files** (corrected down from 114 by commit
`ea0c05c0`, after the drift document moved out of the enumeration). The very next
line, untouched by that same commit, still reads:

> Partition: Set 1 **26** · Set 2 **17** · 3a **21** · 3b **22** · 3c **1** · 3d **3** ·
> 3e **4** · 3f **8** · 3g **12**.

`26+17+21+22+1+3+4+8+12 = 114`, not 113 — the partition line was left at its
pre-correction value while the headline total and the delta line two paragraphs down
(`+13 files`, also touched by `ea0c05c0`) were both updated.

Re-running the classifier from `pr-assembly-guide.md` §1.0 against
`upstream-https/dev` (`BASE=af9a5782980cdb5684a8b434916da503a5b61b69`,
`TIP=$(git rev-parse HEAD)`) gives:

```sh
git diff $BASE $TIP --name-only -- . ':(exclude)doc/development/wip/77-new-input-api/**' | wc -l
# 113
```

with 0 unclassified and **3a = 20**, not 21 — the drift document (the file the
`doc/*.md` catch-all had misrouted into `3a`, per the same note's §3b) was the one
file removed from the enumeration, so `3a` is the row that should have decremented.
`26+17+20+22+1+3+4+8+12 = 113`, which matches the corrected headline.

**Size:** one stale digit in one table cell, contained to this document; nothing
downstream (`track.md`, `ROADMAP.md`, the debt entries in `general.md`) repeats the
114-summing partition, so this did not propagate.

---

## What else was checked and held

- **All ANCHORS.md shas** (remotes' branch tips, PR heads `#45/#41/#22/#15`, all four
  merge bases, the derived tree `a8cb98e2…`, the three example-repo heads/upstreams)
  reproduce exactly via `git rev-parse` / `git merge-base` / `git merge-tree
  --write-tree`.
- **The rebase-drop mechanics**: actually performed `git rebase --onto
  upstream-https/dev 945a5d1d… upstream-pr/45` in a scratch worktree. Git drops
  `95186e57` and `1efd2cbe` with the exact wording *"patch contents already
  upstream"*; 52 replay as 50; the resulting tree is byte-identical to `a8cb98e2…`.
- **The four patch-equivalent edge commits** (`38d7c754`↔`3e249423`,
  `6897d689`↔`c120878b`, `9693779a`↔`1b0fb781`, `ea6efd1d`↔`af9a5782`): `git patch-id`
  matches exactly on all four pairs, and `git cherry HEAD dsent-https/dsent/dev`
  independently returns exactly these four as duplicates — matching both the "git
  cherry duplicates: 4" claim and the debt-ledger's "11, not 15" content count.
- **The edge/dev drift** (71 ahead, 6 behind) and **the 15-commit edge remainder**
  (`git rev-list --count --no-merges HEAD..dsent-https/dsent/dev ^upstream-pr/45`):
  both reproduce exactly, including the explicit 15-commit listing.
- **The `git apply --3way` conflict claim** (4 files, hunks 1/2/2/1 =
  `controller.lua`/`editorController.lua`/`userInputModel.lua`/`tests/mock.lua`):
  reproduced by actually applying `git diff 945a5d1d…upstream-pr/45` with `--3way` in
  a scratch worktree — same 4 files, same hunk counts. The base patch size claim
  ("19 files, 92 hunks") also reproduces exactly.
- **The revert-risk audit** (49 lines absent, split 35/10/3/1 over 842/114/34/15):
  arithmetic closes both ways (842+114+34+15=1005, 35+10+3+1=49), and the "340 → 49"
  correction states plainly what was wrong with the earlier number (wrong metric —
  total lines removed vs. #45's own additions specifically lost). No other document
  in the tree still carries "340" in this context (F check, this item).
- **The `PR-01` import-mechanism revision** (bare `git apply` → `git apply --3way`
  or `merge --squash`, either): no document recommends the discarded two-way approach
  (F check, this item).
- **Citations, re-run against `git show HEAD:` for every `.md` touched in the range**
  (not the live working tree — see the method note above): every link resolves except
  the one in Finding 1.
- **The corpus rule on `wip/`/`design/`/sprint-id citations**: the T-EPHEMERAL-IDS
  re-derive command, run against the working tree (these files are untouched by the
  concurrent edit), returns hits only inside `general.md` itself (its own
  illustrations of already-fixed cases), zero live violations elsewhere.
- **The marker gate**: `grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/`
  returns nothing (`src/`/`tests/` are untouched by the concurrent edit).
- **Suite claim**: `busted tests` on this container's LuaJIT 2.1 (confirmed via
  `luajit -v`; the container is not the owner's PUC Lua, matching the note in
  `ANCHORS.md` §6 that flags exactly this) gives **1055 successes / 0 failures / 0
  errors / 10 pending** — matches both the prompt and `ANCHORS.md` exactly.
- **The suite numbers produced in throwaway clones** (693/0, 753/0, 760/0, 1100/22,
  1108/22): not rebuilt, per the prompt's instruction. Every document quoting them
  (`ANCHORS.md`, `S70-PR45-as-base.md`, `S70-platform-ancestry.md`,
  `S70-edge-essence-and-stack.md`, `S70-import-strategy.md`, `S70-merge-plan.md`,
  `session70/track.md`) quotes them consistently, and the one arithmetic performed on
  them (1094−1100 = the 6 "our own" extra failures on the "theirs" side) closes.
- **`TAGS.md` round-3 tags**: all eight platform tags and all three example-repo
  round-3 tag sets (`base`/`head`/`mergebase`) exist and match the shas quoted in both
  `TAGS.md` and `ANCHORS.md`, including `keyboard`'s three-way mergebase
  `025e8581…`, independently re-derived.

## Checks A–F: what was and was not completed

- **A (ANCHORS.md shas/refs/counts):** completed. One finding (Finding 2).
- **B (suite numbers, consistency + arithmetic):** completed. `busted tests`
  reproduces the one directly-checkable number; the throwaway-clone numbers are
  quoted consistently everywhere they appear.
- **C (mid-session-corrected counts):** completed. All five items (15/11 edge
  remainder, 4 cherry duplicates, 7-behind-and-all-ancestors, 49-line revert-risk
  split, 113-file/0-unclassified shipping surface) were independently re-derived.
  The shipping-surface re-run surfaced Finding 3 (the partition row).
- **D (citations):** completed, against the committed tree, not the live working
  tree (see method note). This is where Finding 1 came from — the check the prompt
  asked for is exactly the one that fails.
- **E (corpus rules):** completed for the `wip/`/`design/`/sprint-id sweep and the
  marker gate — both clean. The `agents/` filed-count cross-check (19 citations) is
  **partially** verified: the by-citing-document breakdown's three smaller entries
  (`decisions/input.md` 5, `technical_debt/input.md` 4,
  `technical_debt/README.md` 1) match a raw `git grep -c` exactly, and the by-target
  breakdown's five rows sum to 19 as stated. `general.md`'s own claimed count (9) is
  not mechanically re-derivable without repeating the same "citation vs. illustration"
  judgment call the entry itself makes (it discusses `agents/` citations at length
  while also containing several); I could not independently confirm that specific
  sub-count and am not reporting it as a finding for that reason, only flagging it as
  unverified rather than verified.
- **F (internal contradictions):** completed for both named revisions (import
  mechanism, revert-risk metric) — both are corrected in place with the prior version
  named and no other document still carrying the superseded value. Finding 3 is a
  related but distinct case: not a superseded claim left standing, but a total that
  was corrected without correcting the breakdown feeding it.

**Tools note:** the `lua-lsp` MCP server was not needed — this range has no `.lua`
changes, matching the prompt's expectation, so no MCP query was attempted and there is
no outage to report.
