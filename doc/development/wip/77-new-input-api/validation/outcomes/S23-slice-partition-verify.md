# S23 — TF2 navigation slice partition verification

Read-only verification of the session22 review-navigation slices
(`pr-slices/`, committed at `4c002e8`) against the guide
(`implementation/pr-assembly-guide.md` §1/§4) and against the current tree
(`HEAD` = `2942147`). No slices were regenerated; no patches were really
applied. `BASE=3256aac` throughout, per the guide.

## 1. Reviewable file set — CLEAN

`git diff $BASE <tip> --name-status -- . ':(exclude)doc/development/wip/77-new-input-api/**'`
(the wip corpus has no other subtree, so `doc/development/wip/**` gives an
identical result):

- At `HEAD` (`2942147`): **89 files**.
- At the slice-generation tip `4c002e8`: **89 files**.
- Set difference between the two file lists: **empty** — the two sets are
  byte-identical in membership, not just count (`diff` of the sorted path
  lists exits 0 both ways).

Why nothing moved: `16546af` (Dockerfile tweak) only touches
`doc/development/wip/77-new-input-api/implementation/docker/src/agent/Dockerfile`
— itself under the wip/77 subtree, so it was never in the reviewable set to
begin with (it's doubly out of scope, not just "unrelated to the feature").
`a4197db` touches only `implementation/sessions/session22/track.md` (wip/77,
excluded). `2942147` adds two new files under `implementation/sessions/`
(wip/77, excluded) and modifies one file that **is** in scope,
`agents/validation.md` — but that file was already present in the diff at
`4c002e8` (it's part of Set 2), so touching it again doesn't add a new path
to the set. See §5 for the content-level consequence of that last point.

## 2. Partition verification — CLEAN

8 slices in `pr-slices/` for Sets 1–3 (plus 2 separate Set-4 nested-repo
patches, `4-balloons-upgrade.patch` and `4-maze-worktree.patch`, which are
out of scope for this parent-repo partition check per the guide §5):

| Slice | Files (via `git apply --numstat`) |
|---|---:|
| 1-generic-docs | 23 |
| 2-agentic | 14 |
| 3a-routing-core | 3 |
| 3b-widget-surface | 3 |
| 3c-model-view-util | 6 |
| 3d-tests | 26 |
| 3e-examples-tracked | 5 |
| 3f-input-docs | 9 |
| **Sum** | **89** |

- **Completeness**: union of all slice file paths, sorted, diffed against
  the §1 file list for `4c002e8` → **empty diff**. Every one of the 89
  reviewable files appears in some slice.
- **Disjointness**: sorted concatenation of all slice file paths has **89**
  lines total and **89** unique lines (`uniq -d` on the sorted list produced
  no output) — no file appears in two slices.
- **Extras**: none — no slice contains a path outside the expected 89-file
  set (same empty-diff result covers this).
- The same union also matches the `HEAD` file list exactly (§1), so the
  partition is still complete/disjoint at current `HEAD`, not just at
  `4c002e8`.

## 3. "89 files / 8 slices" arithmetic — CONFIRMED

23+14+3+3+6+26+5+9 = **89**, with 89 unique paths and 89 total non-header
`numstat` lines (no double-count). The claim is exact, both by count and by
set identity, matching the §1 reviewable set at both `4c002e8` and `HEAD`.

Note for context, not a discrepancy: the assembly guide's own §6 inventory
table (authoring-time) lists 22/10/2/3/5/6/5/8 = 61 files. The branch grew
by 28 files between guide-authoring time and session22's slice generation
(mostly `tests/input/*` and doc/agent-corpus growth) — the guide itself
flags its §6 numbers as drift-prone and says to trust §1+§4 instead, which
is what this check does.

## 4. Applicability spot-check — FINDINGS: 1

A true cumulative `git apply --check` against `$BASE` isn't directly
possible with the working tree pinned at `HEAD` and no `checkout`/`reset`
in the allowed read-only git set. Worked around it without touching `/repo`
or its `.git`: reconstructed the 89 files' `$BASE`-state content (via
`git show $BASE:<path>`, all reads) into a disposable scratch directory
outside the repo, then ran `git apply --check` there per slice, applying
each *only in scratch* after a clean check so later slices see the
cumulative tree (order used: 3d, 3a, 3b, 3c, 3e, 3f, 1, 2 — the guide notes
order is immaterial since the sets are file-disjoint, which §2 above
reconfirms). `/repo` itself was never modified; only `--check` was ever
used on `/repo`'s own working tree via the earlier steps.

Results:

- **1-generic-docs, 2-agentic, 3a-routing-core, 3b-widget-surface,
  3c-model-view-util, 3e-examples-tracked, 3f-input-docs**: all apply
  cleanly (`git apply --check` exit 0). Minor non-blocking warnings only:
  trailing-whitespace warnings on a handful of lines in `3a`, `3c`, `2`
  (pre-existing content, not apply blockers), and a file-mode warning on
  `3e-examples-tracked` (`src/examples/guess/main.lua` patched as `100644`,
  working copy is `100755`) — noted, not a failure.
- **3d-tests**: `git apply --check` **fails**:
  ```
  error: cannot apply binary patch to
    'tests/input/.input_nfr_forward_spec.lua.swp' without full index line
  error: tests/input/.input_nfr_forward_spec.lua.swp: patch does not apply
  ```
  `tests/input/.input_nfr_forward_spec.lua.swp` is a tracked vim swap file
  (binary blob) added between `$BASE` and `HEAD`, caught by the `tests/input/`
  pathspec. `git diff` without `--binary` can't produce an applicable patch
  for it, so the slice as committed cannot be applied whole. Isolated check:
  excluding just that one path (`git apply --check --exclude=...`), the
  remaining 25 files of `3d-tests` apply cleanly. So the blocker is exactly
  and only this one stray swap file, not the test suite content.

This is an applicability defect in the current slice batch, not touched or
fixed here per scope.

## 5. Staleness delta

A reviewer reading these slices at `HEAD` would not miss or see stale *any
file* — the reviewable set is identical in membership at `4c002e8` and
`HEAD` (§1), and `16546af`'s Dockerfile edit is inside the excluded wip/77
tree so it was never reviewable content to begin with. The one real drift
is **content-level, one line, cosmetic**: `2942147` edited
`agents/validation.md` (captured in slice `2-agentic`) to repoint its
"CURRENT PROMPT" pointer from `.../session22/prompt.md` to
`.../session23/prompt.md`; a reviewer reading `2-agentic.patch` as committed
sees the session22 pointer, one line behind the same file's current `HEAD`
content. It carries no bearing on the input feature itself.

## Overall verdict

CLEAN on partition arithmetic, completeness, disjointness, and file-set
staleness (tasks 1, 2, 3, 5 all clean/confirmed). FINDINGS: 1 on
applicability (task 4) — the `3d-tests` slice as committed fails to apply
whole because it carries a tracked binary vim-swap file
(`tests/input/.input_nfr_forward_spec.lua.swp`) that `git diff` can't patch
without `--binary`; the other 25 files in that slice, and all other 7
slices, apply cleanly against `$BASE`. Not fixed — reported per scope.

**Could not verify:** a true single-pass cumulative `git apply --check`
directly against `/repo` at `$BASE` (would require `checkout`/`reset`,
outside the allowed read-only git command set) — worked around via an
out-of-repo scratch reconstruction (§4); Set 4 (nested `balloons`/`maze`
example repos) applicability — explicitly out of scope for this parent-repo
partition per the guide's own §5 caveats and the task's framing.
