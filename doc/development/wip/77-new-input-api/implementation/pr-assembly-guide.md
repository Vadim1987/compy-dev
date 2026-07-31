# PR-assembly guide — regenerating and reassembling the input delivery from the landed branch

_PM (Opus), session06. A **re-runnable procedure** for splitting the landed work into the four
orthogonal PR sets and reassembling them into a clean, per-change-zone branch. This is the durable
tool: the patch files themselves are transient (regenerated from git), but this guide reproduces them
from scratch, so re-run it whenever the landed branch changes and the split must be redone._

The wip corpus is deleted before the real PR (history survives locally). Keep this guide with the wip
history so the procedure can be replayed; the commands below depend only on git, not on any cached
patch file.

---

## 0. Inputs

- **`BASE=3256aac`** — the reassembly baseline: updev tip (`01ac142`) + 1
  ("docs: add development documentation…"). Verified: `parent(3256aac) == 01ac142`, and `01ac142` is
  a linear ancestor of the landed HEAD. Every slice below is `git diff $BASE <landed-HEAD>` narrowed
  to a pathspec.
- **`TIP`** — the landed feature branch tip that carries all the work (at authoring time `d0c6152`;
  substitute the current tip when re-running).
- Run everything from the repo root. Sets 1–3 apply with `git apply`; Set 4 (nested repos) is handled
  in its own repo with `git am` / `git apply`.

```sh
BASE=3256aac
TIP=$(git rev-parse HEAD)        # or the specific landed tip you are slicing
```

---

## 1. Regenerate the slices (pathspec = source of truth)

Each command writes one patch. The pathspecs are exhaustive and disjoint — together they equal the
full wip-excluded diff (verification in §4). Regenerate all of them:

```sh
OUT=doc/development/wip/77-new-input-api/implementation/pr-slices
mkdir -p "$OUT"

# --- Set 1 · generic docs-corpus (22 files), split 1a / 1b — see §1.1 ---
SET1="doc/development/internals/event_dispatch_layers.md
  doc/development/conventions/architecture_principles.md
  doc/development/conventions/code.md
  doc/development/conventions/git.md
  doc/development/docs.md
  doc/development/drawing_system.md
  doc/development/overview.md
  doc/development/internals/console.md
  doc/development/internals/editor.md
  doc/development/internals/project_sandbox_env.md
  doc/development/internals/examples/"

# 1a · rubber-stamping only — reproduce commit 6c766da, narrowed to Set 1.
# Generated from the stamping commit itself, NOT from $BASE (see §1.1).
git diff 6c766da^ 6c766da -- $SET1 \
  > "$OUT/1a-generic-docs-rubberstamping.patch"
# 1b is generated in §1.1 — it is the remainder AFTER 1a is applied.

# --- Set 2 · agentic set (10 files) ---
git diff $BASE $TIP -- \
  AGENTS.md CLAUDE.md agents/ \
  > "$OUT/2-agentic.patch"

# --- Set 3 · Main feature, six orthogonal slices ---
# 3d · TESTS FIRST (see §2 for why the test slice leads)
# .gitignore rides here: its only feature-era change is the editor-artifact
# entry added when a stray tests/input/*.swp was untracked.
# The highlight regression spec is EXCLUDED — it rides 3g with its fix (§1.1).
git diff $BASE $TIP -- \
  tests/editor/editor_spec.lua \
  tests/input/ ':(exclude)tests/input/highlight_regression_spec.lua' \
  tests/helpers/input_fixture.lua tests/helpers/input_session.lua tests/mock.lua \
  .gitignore \
  > "$OUT/3d-tests.patch"

# 3g · highlight nil-index regression — the guard AND its test, carved out
# of 3c and 3d so the fix reads as one self-contained commit (§1.1).
git diff $BASE $TIP -- src/model/input/userInputModel.lua | awk '
  /^diff --git|^index |^--- |^\+\+\+ /{print;next}
  /^@@/{keep=($0 ~ /function UserInputModel:highlight\(\)$/)} keep' \
  > "$OUT/3g-highlight-regression.patch"
git diff $BASE $TIP -- tests/input/highlight_regression_spec.lua \
  >> "$OUT/3g-highlight-regression.patch"

# 3a · routing / dispatch core
git diff $BASE $TIP -- \
  src/controller/controller.lua src/controller/editorController.lua \
  src/controller/projectInputController.lua \
  > "$OUT/3a-routing-core.patch"

# 3b · widget sink + compy.input.* singleton + boot provisioning
git diff $BASE $TIP -- \
  src/controller/userInputController.lua src/controller/consoleController.lua src/main.lua \
  > "$OUT/3b-widget-surface.patch"

# 3c · model / view / util — MINUS the highlight() hunk, which rides 3g (§1.1)
UIM=src/model/input/userInputModel.lua
HLRE='function UserInputModel:highlight\(\)$'
git diff $BASE $TIP -- $UIM | awk -v re="$HLRE" '
  /^diff --git|^index |^--- |^\+\+\+ /{print;next}
  /^@@/{keep=!($0 ~ re)} keep' > "$OUT/3c-model-view-util.patch"
git diff $BASE $TIP -- \
  src/model/consoleModel.lua src/model/editor/searchModel.lua \
  src/model/interpreter/eval/evaluator.lua \
  src/view/input/userInputView.lua src/util/key.lua \
  >> "$OUT/3c-model-view-util.patch"

# 3e · tracked example migrations
git diff $BASE $TIP -- \
  src/examples/guess/main.lua src/examples/repl/main.lua src/examples/tixy/main.lua \
  src/examples/turtle/main.lua src/examples/valid/main.lua \
  > "$OUT/3e-examples-tracked.patch"

# 3f · input permanent docs
git diff $BASE $TIP -- \
  CHANGELOG.md doc/input_api.md doc/development/internals/user_input.md \
  doc/development/decisions/ doc/development/technical_debt/ doc/development/tests.md \
  > "$OUT/3f-input-docs.patch"
```

Set 4 (nested example repos — invisible to the parent `git diff`, become PRs in their own repos):

```sh
# In the balloons checkout:
git -C src/examples/balloons format-patch -1 56347d0 -o "$OUT"        # the migration commit
git -C src/examples/balloons diff > "$OUT/4-balloons-uncommitted-worktree.patch"   # ⚠ extra +32 main.lua, see §5
# In the maze checkout (migration is uncommitted working tree):
git -C src/examples/maze diff > "$OUT/4-maze-worktree.patch"
```

---

## 1.1 Two carve-outs a pathspec alone cannot express

Every other slice is a pathspec narrowing of one `git diff`. These two are not: they
split *within* a file, and both exist because a reviewer should be able to skip one
half without reading the other.

### 1a / 1b — rubber-stamping apart from meaning

**Standing rule: whenever a docs slice contains a mechanical, repo-wide annotation
pass, it ships as its own commit and the meaningful changes are built on top of it.**
A reviewer who sees `23 files changed` in a docs commit must be able to tell at a
glance whether it is one line repeated 23 times or 23 arguments to check.

Here the mechanical pass is commit **`6c766da`** ("mark LLM-authored dev docs as
pending human approval"), which inserted one `<!-- authored By LLM; human-approved
NOT YET -->` line after each H1. So:

- **`1a`** = that commit, narrowed to the Set-1 pathspec — 21 files, one added line
  (plus a blank) each. Generated from `6c766da^..6c766da`, **not** from `$BASE`:
  the `$BASE..6c766da` range also drags in unrelated content from the 60 commits
  in between (e.g. `project_sandbox_env.md` +56), which is precisely what must not
  land in a rubber-stamping commit.
- **`1b`** = everything else in Set 1, and it can only be computed **after `1a` is
  applied**, because its starting point is "BASE plus the stamps":

  ```sh
  git switch -c input-delivery-reassembled $BASE
  git apply "$OUT/1a-generic-docs-rubberstamping.patch"
  git add -A && git commit -m "docs: mark LLM-authored dev docs as pending human approval"
  git diff HEAD $TIP -- $SET1 > "$OUT/1b-generic-docs.patch"   # 10 files
  ```

`1a` applies cleanly to a `$BASE` checkout, and `1a + 1b` reproduces the Set-1 half
of `$BASE..$TIP` exactly (verified 2026-07-31).

The `1a-generic-docs-rubberstamping.patch` currently sitting in `pr-slices/` was split
by hand and holds **14** files, not 21: seven example docs that also carry meaningful
edits kept their marker line in `1b`. The recipe above supersedes it — regenerating at
Phase G moves those seven markers into `1a`, which is the point of the split. As
everywhere in this guide, the patch files are transient; §1 is the contract.

### 3g — the highlight regression, fix and test together

The nil-index highlight guard is two hunks in `UserInputModel:highlight()` plus
`tests/input/highlight_regression_spec.lua`. Split across `3c` and `3d` it reads as
noise in two unrelated commits; together it is a one-screen bug fix with its own
proof, which is how it should be reviewed.

The selector is git's own hunk **funcname context** — the `@@` header of the guard's
hunk ends in `function UserInputModel:highlight()`, so `awk` can keep that hunk for
`3g` and its complement for `3c` (both commands are in §1 above). This is the only
place the guide filters hunks rather than paths; if `highlight()` ever grows a second
feature-era hunk, the filter silently takes it too — check
`grep '^@@' "$OUT/3g-highlight-regression.patch"` after regenerating.

Apply `3g` **before** `3c`. `3c`'s remaining hunks then land with a small line
offset, which `git apply` resolves by context (verified 2026-07-31: the pair
reproduces `userInputModel.lua` at `$TIP` byte for byte).

---

## 2. Assembly order — tests precede code

Build the reassembled branch by applying the slices as one commit each, in **this** order. The test
slice (`3d`) leads the feature commits: it lands **before** the implementation, matching the project's
tests-first discipline (`agents/development.md`: start from a breaking test, then implement). The test
commit is intentionally **red** against `BASE` and goes green once `3a`–`3c` land — that red→green
transition is the point, not an accident to hide.

| # | Commit | Slice | Suggested message |
|---|--------|-------|-------------------|
| 1 | docs rubber-stamping | **1a** | `docs: mark LLM-authored dev docs as pending human approval` |
| 2 | generic docs | **1b** | `docs: refresh development doc-corpus` |
| 3 | agentic tooling | Set 2 | `chore(agents): add agent charters + process docs` |
| 4 | **input contract suite** | **3d** | `test(input): add the #input contract suite + fixtures` |
| 5 | highlight regression | **3g** | `fix(input): keep the highlight table indexable` |
| 6 | routing/dispatch core | 3a | `feat(input): gateway + four-tier dispatch + route restoration` |
| 7 | widget + singleton surface | 3b | `feat(input): widget sink + compy.input.* surface + boot provisioning` |
| 8 | model/view/util | 3c | `feat(input): held-keys, combos, text model/view` |
| 9 | tracked example migrations | 3e | `refactor(examples): migrate tracked examples to the input API` |
| 10 | input docs | 3f | `docs(input): input API guide, internals, decisions, debt ledger` |

Notes on ordering:
- **Sets 1–3 are disjoint by file** (§4) with **one deliberate exception** — `3g` and `3c` split
  `userInputModel.lua` between them (§1.1) — so `git apply` never conflicts regardless of order,
  except that `3g` must precede `3c`. Otherwise the sequence is for *review narrative* (tests-first,
  then core→surface→periphery→docs), not for mechanical correctness.
- `1a` before `1b` is likewise mandatory, and for the same reason: `1b` is *defined* as the remainder
  after `1a` (§1.1).
- `3g` carries both a test and a source fix, so it is self-contained and green on its own — it is the
  one feature commit that does not depend on the red→green arc of `3d`.
- Sets 1 and 2 are separable PRs; they can precede the feature or ship as their own mini-PRs. Steps
  1–3 are listed here only to reproduce the full branch in one pass.
- Apply each with `git apply "$OUT/<slice>.patch"` then `git add -A && git commit`. Because the tree
  starts at `BASE`, every slice applies cleanly.

```sh
git switch -c input-delivery-reassembled $BASE
# 1a first, then regenerate 1b against it — see §1.1
for slice in 1a-generic-docs-rubberstamping 1b-generic-docs 2-agentic 3d-tests \
             3g-highlight-regression 3a-routing-core 3b-widget-surface \
             3c-model-view-util 3e-examples-tracked 3f-input-docs; do
  git apply "$OUT/$slice.patch" && git add -A && git commit -q -m "apply $slice"   # replace msg per table
done
```

---

## 3. Dangler fixes — do before the Main PR

File-level pathspec exclusion drops wip/77 *files* but not textual *citations* of wip/77 paths inside
surviving files. 14 such lines survive across the sets; only **3 block the Main feature PR**:

- **`3d`** — `tests/helpers/input_fixture.lua`, `tests/input/input_contracts_spec.lua`
- **`3f`** — `doc/development/tests.md`

All three cite `wip/77/notes/input-contracts.md`, whose durable content now lives in the corpus.
**Repoint to `doc/development/internals/user_input.md` / `doc/development/decisions/input.md`, or drop
the citation**, inside the `3d`/`3f` commits (fix inline so the branch never references a deleted path).

The other 11 danglers are each their own set's concern, not the Main PR's: 1 in Set 1
(`project_sandbox_env.md`), 10 in Set 2 (the agent charters legitimately describe a process tied to the
wip dir — genericize, keep, or hold Set 2 back per that PR's call).

---

## 4. Verification — complete and disjoint

Re-run after regenerating, to prove the split still equals the whole and no file is double-counted:

```sh
# Full wip-excluded diff, file list:
git diff $BASE $TIP --name-only -- . ':(exclude)doc/development/wip/77-new-input-api/**' \
  | sort > /tmp/_all.txt
# Union of the ten Set 1–3 slice pathspecs, file list:
for s in 1a-generic-docs-rubberstamping 1b-generic-docs 2-agentic 3a-routing-core \
         3b-widget-surface 3c-model-view-util 3d-tests 3g-highlight-regression \
         3e-examples-tracked 3f-input-docs; do
  git apply --numstat "$OUT/$s.patch" | awk '{print $3}'
done | sort -u > /tmp/_sliced.txt
diff /tmp/_all.txt /tmp/_sliced.txt && echo "OK: complete + disjoint"
```

At authoring time this yielded **61 files**, no diff — the slices reconstruct the entire
wip-excluded change set exactly. If `diff` reports lines, a new file landed outside every pathspec
(add it to the right slice) or a file moved sets (fix the overlap).

`sort -u` above hides the two intentional file-level overlaps introduced in §1.1 — Set-1 docs appear
in both `1a` and `1b`, and `userInputModel.lua` in both `3c` and `3g`. The completeness half of the
check is unaffected; for the disjointness half, the stronger test is the one that actually matters:
**assemble the branch per §2 and confirm the tip matches `$TIP`**, which catches a dropped *or*
duplicated hunk, not just a file:

```sh
git diff HEAD $TIP -- . ':(exclude)doc/development/wip/'   # must be empty at the assembled tip
```

---

## 5. Set 4 caveats (nested repos)

- `4-balloons-56347d0.patch` — `format-patch` of the migration commit; `git am` in the balloons repo
  (preserves message + authorship).
- `4-balloons-uncommitted-worktree.patch` — ⚠ an **extra uncommitted `main.lua` edit (+32)** sitting
  on top of `56347d0` in the balloons working tree, **not** part of the commit. Decide: fold into the
  migration, keep as a separate commit, or discard.
- `4-maze-worktree.patch` — maze's migration is an **uncommitted** working tree (`controls.lua`,
  `main.lua`); `git apply` in the maze repo, then commit there.
- Deliberately **not captured**: balloons `ISSUES.md` / `docs/*` / `implementation.md`, and the
  `keyboard` / `drawdebug` checkouts (scratch / untouched).

---

## 6. Set inventory (file-level, for reference)

| Set / slice | Files | Churn (authoring-time) |
|---|---|---|
| 1a docs rubber-stamping | 21 | +42 (one marker + blank per file) |
| 1b generic docs | 10 | the rest of Set 1 |
| 2 agentic | 10 | +513 |
| 3d tests | 6 | +2615 / −5 (minus the highlight spec) |
| 3g highlight regression | 2 | the `highlight()` hunk + its spec |
| 3a routing-core | 2 | +542 / −32 |
| 3b widget-surface | 3 | +566 / −103 |
| 3c model-view-util | 5 | +164 / −56 (minus the `highlight()` hunk) |
| 3e examples-tracked | 5 | +60 / −43 |
| 3f input-docs | 8 | +1669 / −35 |

Churn drifts as the branch evolves; the pathspecs in §1 are the stable contract. When re-running,
trust §1 + §4, not these numbers.
