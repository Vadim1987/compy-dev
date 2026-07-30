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

# --- Set 1 · generic docs-corpus (22 files) ---
git diff $BASE $TIP -- \
  doc/development/internals/event_dispatch_layers.md \
  doc/development/conventions/architecture_principles.md \
  doc/development/conventions/code.md \
  doc/development/conventions/git.md \
  doc/development/docs.md \
  doc/development/drawing_system.md \
  doc/development/overview.md \
  doc/development/internals/console.md \
  doc/development/internals/editor.md \
  doc/development/internals/project_sandbox_env.md \
  doc/development/internals/examples/ \
  > "$OUT/1-generic-docs.patch"

# --- Set 2 · agentic set (10 files) ---
git diff $BASE $TIP -- \
  AGENTS.md CLAUDE.md agents/ \
  > "$OUT/2-agentic.patch"

# --- Set 3 · Main feature, six orthogonal slices ---
# 3d · TESTS FIRST (see §2 for why the test slice leads)
git diff $BASE $TIP -- \
  tests/editor/editor_spec.lua tests/editor/editor_spec_fwd.lua \
  tests/input/ tests/helpers/input_fixture.lua tests/helpers/input_session.lua tests/mock.lua \
  > "$OUT/3d-tests.patch"

# 3a · routing / dispatch core
git diff $BASE $TIP -- \
  src/controller/controller.lua src/controller/editorController.lua \
  src/controller/projectInputController.lua \
  > "$OUT/3a-routing-core.patch"

# 3b · widget sink + compy.input.* singleton + boot provisioning
git diff $BASE $TIP -- \
  src/controller/userInputController.lua src/controller/consoleController.lua src/main.lua \
  > "$OUT/3b-widget-surface.patch"

# 3c · model / view / util
git diff $BASE $TIP -- \
  src/model/input/userInputModel.lua src/model/consoleModel.lua src/model/editor/searchModel.lua \
  src/model/interpreter/eval/evaluator.lua \
  src/view/input/userInputView.lua src/util/key.lua \
  > "$OUT/3c-model-view-util.patch"

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

## 2. Assembly order — tests precede code

Build the reassembled branch by applying the slices as one commit each, in **this** order. The test
slice (`3d`) leads the feature commits: it lands **before** the implementation, matching the project's
tests-first discipline (`agents/development.md`: start from a breaking test, then implement). The test
commit is intentionally **red** against `BASE` and goes green once `3a`–`3c` land — that red→green
transition is the point, not an accident to hide.

| # | Commit | Slice | Suggested message |
|---|--------|-------|-------------------|
| 1 | generic docs | Set 1 | `docs: refresh development doc-corpus` |
| 2 | agentic tooling | Set 2 | `chore(agents): add agent charters + process docs` |
| 3 | **input contract suite** | **3d** | `test(input): add the #input contract suite + fixtures` |
| 4 | routing/dispatch core | 3a | `feat(input): gateway + four-tier dispatch + route restoration` |
| 5 | widget + singleton surface | 3b | `feat(input): widget sink + compy.input.* surface + boot provisioning` |
| 6 | model/view/util | 3c | `feat(input): held-keys, combos, text model/view` |
| 7 | tracked example migrations | 3e | `refactor(examples): migrate tracked examples to the input API` |
| 8 | input docs | 3f | `docs(input): input API guide, internals, decisions, debt ledger` |

Notes on ordering:
- **Sets 1–3 are disjoint by file** (§4), so `git apply` never conflicts regardless of order — the
  sequence is for *review narrative* (tests-first, then core→surface→periphery→docs), not for
  mechanical correctness.
- Sets 1 and 2 are separable PRs; they can precede the feature or ship as their own mini-PRs. Steps
  1–2 are listed here only to reproduce the full branch in one pass.
- Apply each with `git apply "$OUT/<slice>.patch"` then `git add -A && git commit`. Because the tree
  starts at `BASE`, every slice applies cleanly.

```sh
git switch -c input-delivery-reassembled $BASE
for slice in 1-generic-docs 2-agentic 3d-tests 3a-routing-core 3b-widget-surface \
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
# Union of the eight Set 1–3 slice pathspecs, file list:
for s in 1-generic-docs 2-agentic 3a-routing-core 3b-widget-surface 3c-model-view-util \
         3d-tests 3e-examples-tracked 3f-input-docs; do
  git apply --numstat "$OUT/$s.patch" | awk '{print $3}'
done | sort -u > /tmp/_sliced.txt
diff /tmp/_all.txt /tmp/_sliced.txt && echo "OK: complete + disjoint"
```

At authoring time this yielded **61 files**, no diff — the eight slices reconstruct the entire
wip-excluded change set exactly. If `diff` reports lines, a new file landed outside every pathspec
(add it to the right slice) or a file moved sets (fix the overlap).

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
| 1 generic docs | 22 | +218 / −73 |
| 2 agentic | 10 | +513 |
| 3d tests | 6 | +2615 / −5 |
| 3a routing-core | 2 | +542 / −32 |
| 3b widget-surface | 3 | +566 / −103 |
| 3c model-view-util | 5 | +164 / −56 |
| 3e examples-tracked | 5 | +60 / −43 |
| 3f input-docs | 8 | +1669 / −35 |

Churn drifts as the branch evolves; the pathspecs in §1 are the stable contract. When re-running,
trust §1 + §4, not these numbers.
