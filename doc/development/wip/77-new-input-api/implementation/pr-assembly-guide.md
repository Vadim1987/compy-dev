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

## 1.0 [S46] Derive the classification, do not maintain it — the pathspecs are an OUTPUT

**Owner correction, 2026-08-26.** What is static in this procedure is the **anchor baseline sha**,
not the pathspecs. The pathspecs were never meant to be a list somebody keeps up to date; they are
meant to be **worked out as a discovery step each time, from the change itself**, immediately
before the slices are built.

**Why this is not a style preference.** Three times now a file has fallen outside every pathspec
(§4.1). Each time the cause was identical: a list of filenames cannot see a file that did not exist
when the list was written. A maintained list makes silent omission the *default* and correctness
contingent on remembering to run a check afterwards. Deriving the classification makes omission
**impossible to express** — an unclassified file stops the build.

**So the order is: enumerate → classify → assert nothing is unclassified → cut.** Run this first;
everything in §1 below is its output.

```sh
# 1 · enumerate the WHOLE change, wip excluded. This is the authority.
git diff $BASE $TIP --name-only -- . ':(exclude)doc/development/wip/77-new-input-api/**' \
  | sort > /tmp/_all.txt

# 2 · classify by RULE, not by filename list. Directory patterns, so a new
#     file in a known area classifies itself.
classify() {
  case "$1" in
    AGENTS.md|CLAUDE.md|agents/*)                                      echo 2 ;;
    doc/development/conventions/*|doc/development/docs.md)             echo 1 ;;
    doc/development/drawing_system.md|doc/development/overview.md)     echo 1 ;;
    doc/development/internals/event_dispatch_layers.md)                echo 1 ;;
    doc/development/internals/console.md)                              echo 1 ;;
    doc/development/internals/editor.md)                               echo 1 ;;
    doc/development/internals/project_sandbox_env.md)                  echo 1 ;;
    doc/development/internals/examples/*)                              echo 1 ;;
    CHANGELOG.md|doc/*.md)                                             echo 3a ;;
    doc/development/internals/user_input.md)                           echo 3a ;;
    doc/development/smoke_checklists.md|doc/development/tests.md)      echo 3a ;;
    doc/development/decisions/*|doc/development/technical_debt/*)      echo 3a ;;
    tests/input/highlight_regression_spec.lua)                         echo 3c ;;
    tests/*|.gitignore)                                                echo 3b ;;
    src/controller/controller.lua|src/controller/editorController.lua) echo 3d ;;
    src/controller/projectInputController.lua)                         echo 3d ;;
    src/controller/userInputController.lua)                            echo 3e ;;
    src/controller/consoleController.lua|src/main.lua|src/types.lua)   echo 3e ;;
    src/examples/*)                                                    echo 3g ;;
    src/model/*|src/view/*|src/util/*|src/harmony/*)                   echo 3f ;;
    *)                                                                 echo UNCLASSIFIED ;;
  esac
}

# 3 · HARD GATE. An unclassified file is a stop, not a warning.
while read -r f; do
  [ "$(classify "$f")" = UNCLASSIFIED ] && echo "UNCLASSIFIED: $f"
done < /tmp/_all.txt | tee /tmp/_unclassified.txt
[ -s /tmp/_unclassified.txt ] && { echo "STOP: classify these before cutting slices"; exit 1; }
```

**When a file lands in `UNCLASSIFIED`, that is the procedure working.** Decide which set it
belongs to, add a *rule* covering its area (not its name), and re-run. If it belongs to no set,
that is a finding about the change, not about this guide.

**Verified 2026-08-26 at tip `388e161d`:** the classifier assigns all **100** files with zero
unclassified, and its partition matches the existing slices exactly — 3a 11, 3b 21, 3d 3, 3e 4,
3f 7, 3g 12, Set 1 26, Set 2 15.

**One limit, by construction.** This classifier is a *file* → set map, so it governs file-level
completeness only. The two carve-outs in §1.1 split *within* a file — `userInputModel.lua`
legitimately appears in both `3c` and `3f` — and remain hunk-level operations layered on top. That
is the one place where `3c`'s content is not derivable from the classification.

---

## 1. Regenerate the slices (pathspec = source of truth)

> **[S46] Heading kept for its inbound references; the claim in it is superseded by §1.0.** The
> pathspecs below are the *output* of the classification, not its source of truth. When they
> disagree with §1.0's rules, §1.0 wins and these lines get regenerated.


Each command writes one patch. The pathspecs are exhaustive and disjoint — together they equal the
full wip-excluded diff (verification in §4). Regenerate all of them:

```sh
OUT=doc/development/wip/77-new-input-api/implementation/pr-slices
mkdir -p "$OUT"

# --- Set 1 · generic docs-corpus (22 files), split 1a / 1b — see §1.1 ---
SET1="doc/development/internals/event_dispatch_layers.md
  doc/development/conventions/
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

# --- Set 3 · Main feature, seven orthogonal slices ---
# Letters follow APPLY ORDER (§2): docs → tests → code → examples.
# Renumber them if the order ever changes; the letter is the position.

# 3a · input permanent docs
# [S46] doc/tall_blocks.md and doc/development/smoke_checklists.md added --
# both are feature-era docs that fell outside every pathspec. See §4.1.
git diff $BASE $TIP -- \
  CHANGELOG.md doc/input_api.md doc/tall_blocks.md \
  doc/development/internals/user_input.md doc/development/smoke_checklists.md \
  doc/development/decisions/ doc/development/technical_debt/ doc/development/tests.md \
  > "$OUT/3a-input-docs.patch"

# 3b · tests, BEFORE the code they cover (see §2 for why)
# .gitignore rides here: its only feature-era change is the editor-artifact
# entry added when a stray tests/input/*.swp was untracked.
# The highlight regression spec is EXCLUDED — it rides 3c with its fix (§1.1).
# [S46] harmony_input_spec.lua and util/key_spec.lua added -- both were
# outside every pathspec. See §4.1.
git diff $BASE $TIP -- \
  tests/editor/editor_spec.lua \
  tests/input/ ':(exclude)tests/input/highlight_regression_spec.lua' \
  tests/helpers/input_fixture.lua tests/helpers/input_session.lua tests/mock.lua \
  tests/harmony_input_spec.lua tests/util/key_spec.lua \
  .gitignore \
  > "$OUT/3b-tests.patch"

# 3c · highlight nil-index regression — the guard AND its test, carved out
# of 3f and 3b so the fix reads as one self-contained commit (§1.1).
git diff $BASE $TIP -- src/model/input/userInputModel.lua | awk '
  /^diff --git|^index |^--- |^\+\+\+ /{print;next}
  /^@@/{keep=($0 ~ /function UserInputModel:highlight\(\)$/)} keep' \
  > "$OUT/3c-highlight-regression.patch"
git diff $BASE $TIP -- tests/input/highlight_regression_spec.lua \
  >> "$OUT/3c-highlight-regression.patch"

# 3d · routing / dispatch core
git diff $BASE $TIP -- \
  src/controller/controller.lua src/controller/editorController.lua \
  src/controller/projectInputController.lua \
  > "$OUT/3d-routing-core.patch"

# 3e · widget sink + compy.input.* singleton + boot provisioning
git diff $BASE $TIP -- \
  src/controller/userInputController.lua src/controller/consoleController.lua src/main.lua \
  src/types.lua \
  > "$OUT/3e-widget-surface.patch"

# 3f · model / view / util — MINUS the highlight() hunk, which rides 3c (§1.1)
UIM=src/model/input/userInputModel.lua
HLRE='function UserInputModel:highlight\(\)$'
git diff $BASE $TIP -- $UIM | awk -v re="$HLRE" '
  /^diff --git|^index |^--- |^\+\+\+ /{print;next}
  /^@@/{keep=!($0 ~ re)} keep' > "$OUT/3f-model-view-util.patch"
# [S46] src/harmony/ added -- production code that fell outside every
# pathspec and would have shipped a PR missing it. See §4.1.
git diff $BASE $TIP -- \
  src/model/consoleModel.lua src/model/editor/searchModel.lua \
  src/model/interpreter/eval/evaluator.lua \
  src/view/input/userInputView.lua src/util/key.lua src/harmony/ \
  >> "$OUT/3f-model-view-util.patch"

# 3g · tracked example migrations
# The whole directory, NOT a file list: paint and sapper joined the set when
# compy.singleclick was retired, and a file list cannot see a file added
# after it was written. Nested repos (balloons/maze/keyboard) are invisible
# to this diff anyway — they are separate repos, see Set 4.
git diff $BASE $TIP -- src/examples/ \
  > "$OUT/3g-examples-tracked.patch"
```

Set 4 (nested example repos — invisible to the parent `git diff`, become PRs in their own repos):

```sh
# Set 4 is NOT a slice of this PR. Each nested example is its own repo with
# its own remote, and ships as its OWN PR, landing alongside the platform PR
# (owner, 2026-07-31), sliced the same way this one is (owner, 2026-08-03) —
# so their local commit churn does not need tidying first. Nothing here is
# pushed by this guide; the patches are for review convenience only.
#
# One patch per repo, cut from the DIFF against that repo's remote branch —
# not format-patch of the local commits, which is what "sliced the same way"
# means: each repo's PR is one reviewable change, and the intermediate churn
# (a migration, then its own corrections) does not reach the reviewer.
#
# [S37] THE REF MUST BE THE UPSTREAM THAT REPO WILL PR TO, AND IT IS ONLY SAFE
# ONCE THAT UPSTREAM IS AN ANCESTOR OF HEAD. See §5.1 before touching these
# three lines. Check first, per repo:
#   git -C src/examples/<repo> merge-base --is-ancestor <ref> HEAD
git -C src/examples/balloons diff origin/main..HEAD \
  > "$OUT/4a-balloons.patch"
# [S39] maze: SWITCHED. The working branch is now `newinput-edge`, forked
# from dsent/dsent/dev — there was no merge, see §5.1. The ref is an
# ancestor by construction, so this diff is exactly our change.
git -C src/examples/maze diff dsent/dsent/dev..HEAD \
  > "$OUT/4b-maze.patch"
# [S37] keyboard: origin/dsent/dev is now an ancestor (merge 17289e9), so this
# diff is exactly our change. Before that merge the same line would have
# produced a patch that DELETED 36 upstream commits' work — see §5.1.
git -C src/examples/keyboard diff origin/dsent/dev..HEAD \
  > "$OUT/4c-keyboard.patch"
```

### 5.1 [S37] The detached repos have upstreams now, and the slice base follows them

**The upstreams that matter** are named in the untracked `repos.txt` at the repo root: `keyboard`'s is
**`origin/dsent/dev`**, `maze`'s is **`dsent/dsent/dev`** (the `dsent` remote, not `origin`, which is
`nagydani/Compy-maze`). `balloons` has no new upstream and was not part of Phase U's example half.

**The rule, and it is a trap otherwise:** a `diff <upstream>..HEAD` is a *reviewable change* only
while `<upstream>` is an **ancestor** of `HEAD`. If it is not — if upstream has moved and has not been
merged — the diff also contains the *reversal* of everything upstream added, so the patch reads as
"and delete the author's last 26 commits". Always check first:

```sh
git -C src/examples/<repo> merge-base --is-ancestor <ref> HEAD && echo safe
```

**State at 2026-08-12:**

| repo | slice ref | ancestor of HEAD? | note |
|---|---|---|---|
| `balloons` | `origin/main` | yes | untouched by Phase U |
| `maze` **[S39]** | `dsent/dsent/dev` | **yes, by construction** | **There was no merge.** P-17-00 was reshaped (`validation/reviews/P-17-00-shape-and-plan.md`): the merge was found inapplicable (`main.lua` modify/delete; 48 of our 53 globals redefined by upstream's split), so the owner ratified **forking** `newinput-edge` off `dsent/dsent/dev` @ `b8cc436` as the working branch. The old `newinput` @ `a045fdb` (based on `origin/v3.4`) is kept as the record of the previous attempt and is **not** the slice. Note the maze source root **no longer emits a runnable project** — `.compy/build` produces `maze/` and `draw/` — so what the slice *delivers* is a question the step still owes |
| `keyboard` | `origin/dsent/dev` | **yes, since `17289e9`** | the merge landed 36 upstream commits (24 files, +5227/−804); the pre-merge state is `05cedec` and the upstream snapshot is on branch `upstream-dsent-dev-20260811` |

**Why the patch, not `format-patch`, is still the right artifact** (owner, 2026-08-11): the delivery
for each detached repo is *"a diff against upstream, on a brand-new branch off upstream, carrying a
single new commit or two"*. The local branches keep their ancestry deliberately so later re-merges
stay cheap — so the local commit graph is working state, and the **patch** is the deliverable. A
`format-patch` of the local commits would ship the churn, including commits that cancel each other
out (in `keyboard`, `5de5a6d` and `f938fbc` do exactly that).

Apply each in its own repo, from that repo's remote branch:
`git -C src/examples/<repo> apply "$OUT/4<x>-<repo>.patch"`. Paths inside the
patch are relative to the nested repo, so it will NOT apply from `/repo`.
Verify the same way Set 1–3 is verified (§4) — apply to a temporary index and
compare against that repo's `HEAD`:

```sh
for r in balloons:4a-balloons maze:4b-maze keyboard:4c-keyboard; do
  d=src/examples/${r%%:*}; p="$OUT/${r##*:}.patch"
  ( cd "$d" && GIT_INDEX_FILE=$(mktemp) \
    && export GIT_INDEX_FILE \
    && git read-tree "$(git rev-parse @{u} 2>/dev/null || git rev-parse origin/dsent/dev)" \
    && git apply --cached "$OLDPWD/$p" \
    && git diff --stat "$(git write-tree)" HEAD )   # must be empty
done
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
NOT YET -->` line after each H1.

**That marker is no longer how provenance is recorded.** The 2026-07-31 ruling
replaced it with a YAML front-matter block (`doc/development/conventions/docs.md`),
applied to the persistent corpus and two internals docs. This does **not** invalidate
`1a`: every one of its 21 files still carries the comment at `$TIP`, so the slice is
still "one line repeated 21 times". It does mean two things for the reviewer, and both
belong in `1b` because they are meaningful, not mechanical:

- the files whose provenance form *changed* (in Set 1: `event_dispatch_layers.md`,
  `project_sandbox_env.md`) show a marker removed and a described block added;
- the convention itself (`conventions/docs.md`) is a new file — which is why `SET1`
  above names the `conventions/` **directory** rather than its three original files.
  A pathspec that lists files cannot see a file that did not exist when it was written.

Before regenerating, confirm the premise still holds — if this prints anything, those
files' markers were replaced too and they must be dropped from `1a`'s pathspec:

```sh
for f in $(git diff --name-only 6c766da^ 6c766da -- $SET1); do
  grep -q "authored By LLM" "$f" || echo "no longer stamped at TIP: $f"
done
```

So:

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

### 3c — the highlight regression, fix and test together

The nil-index highlight guard is two hunks in `UserInputModel:highlight()` plus
`tests/input/highlight_regression_spec.lua`. Split across `3f` and `3b` it reads as
noise in two unrelated commits; together it is a one-screen bug fix with its own
proof, which is how it should be reviewed.

The selector is git's own hunk **funcname context** — the `@@` header of the guard's
hunk ends in `function UserInputModel:highlight()`, so `awk` can keep that hunk for
`3c` and its complement for `3f` (both commands are in §1 above). This is the only
place the guide filters hunks rather than paths; if `highlight()` ever grows a second
feature-era hunk, the filter silently takes it too — check
`grep '^@@' "$OUT/3c-highlight-regression.patch"` after regenerating.

Apply `3c` **before** `3f`. `3f`'s remaining hunks then land with a small line
offset, which `git apply` resolves by context (verified 2026-07-31: the pair
reproduces `userInputModel.lua` at `$TIP` byte for byte).

---

## 2. Assembly order — docs, tests, code, examples

Owner ruling (2026-08-03): order the commits **docs → tests → code → examples**, and keep the
messages as **sections in a markdown document** rather than a table — easier to review in an editor.

**The messages live in [`pr-commit-messages.md`](pr-commit-messages.md)**, one section per commit in
apply order. This section is the mechanism; that file is the content.

**Set-3 letters encode the apply order** (owner, 2026-08-07): `3a` is the first Set-3 commit,
`3g` the last. Re-lettering is part of any reordering — a slice whose letter disagrees with its
row number is a bug in this table, not a naming preference.

| # | Slice | Group |
|---|---|---|
| 1 | `1a-generic-docs-rubberstamping` | docs |
| 2 | `1b-generic-docs` | docs |
| 3 | `2-agentic` | docs |
| 4 | `3a-input-docs` | docs |
| 5 | `3b-tests` | tests |
| 6 | `3c-highlight-regression` | code (self-contained; see below) |
| 7 | `3d-routing-core` | code |
| 8 | `3e-widget-surface` | code |
| 9 | `3f-model-view-util` | code |
| 10 | `3g-examples-tracked` | examples |

Constraints the order must respect — everything else is review narrative:

- **`1a` before `1b`.** `1b` is *defined* as the remainder after `1a` is applied (§1.1), so it
  cannot be generated, let alone applied, first.
- **`3c` before `3f`.** They split `userInputModel.lua` between them (§1.1); nothing else in the
  sequence shares a file.
- **`3b` is RED where it lands**, and green once 7–9 are in. That is tests-first working as
  intended (`agents/development.md`), not a broken commit to apply out of order.
- **`3c` carries a fix and its test together**, so it is green on its own and is the one commit that
  does not depend on `3b`'s red→green arc. Splitting it would leave a test proving nothing and a fix
  proving nothing.

Apply each with `git apply "$OUT/<slice>.patch"`, then `git add -A && git commit -F -` with the
message from `pr-commit-messages.md`. Because the tree starts at `BASE`, every slice applies cleanly.

```sh
git switch -c input-delivery-reassembled $BASE
# 1a first, then regenerate 1b against it — see §1.1
for slice in 1a-generic-docs-rubberstamping 1b-generic-docs 2-agentic 3a-input-docs \
             3b-tests 3c-highlight-regression 3d-routing-core 3e-widget-surface \
             3f-model-view-util 3g-examples-tracked; do
  git apply "$OUT/$slice.patch" && git add -A && git commit -q -m "apply $slice"   # replace msg
done
```

**Verified 2026-08-03** (regeneration at Phase G): all ten slices apply in this order against
`BASE`, and the resulting tree is **byte-identical to the branch tip** outside
`doc/development/wip/`. The check does not need a branch — apply them to a temporary index and
compare trees:

```sh
export GIT_INDEX_FILE=$(mktemp)
git read-tree $BASE
for slice in <the ten above>; do git apply --cached "$OUT/$slice.patch" || echo "FAIL $slice"; done
git diff --stat $(git write-tree) $TIP -- . ':(exclude)doc/development/wip/'   # must be empty
unset GIT_INDEX_FILE
```

---

## 3. Dangler fixes — do before the Main PR

File-level pathspec exclusion drops wip/77 *files* but not textual *citations* of wip/77 paths inside
surviving files. 14 such lines survive across the sets; only **3 block the Main feature PR**:

- **`3b`** — `tests/helpers/input_fixture.lua`, `tests/input/input_contracts_spec.lua`
- **`3a`** — `doc/development/tests.md`

All three cite `wip/77/notes/input-contracts.md`, whose durable content now lives in the corpus.
**Repoint to `doc/development/internals/user_input.md` / `doc/development/decisions/input.md`, or drop
the citation**, inside the `3b`/`3a` commits (fix inline so the branch never references a deleted path).

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
for s in 1a-generic-docs-rubberstamping 1b-generic-docs 2-agentic 3a-input-docs \
         3b-tests 3c-highlight-regression 3d-routing-core 3e-widget-surface \
         3f-model-view-util 3g-examples-tracked; do
  git apply --numstat "$OUT/$s.patch" | awk '{print $3}'
done | sort -u > /tmp/_sliced.txt
diff /tmp/_all.txt /tmp/_sliced.txt && echo "OK: complete + disjoint"
```

At authoring time this yielded **61 files**, no diff — the slices reconstruct the entire
wip-excluded change set exactly. If `diff` reports lines, a new file landed outside every pathspec
(add it to the right slice) or a file moved sets (fix the overlap).

**This is the check that catches a file the pathspecs cannot see, and it has already caught
one.** `doc/development/conventions/docs.md` (the front-matter convention, 2026-07-31) fell
outside every slice because `SET1` named three `conventions/` files individually; it would have
been dropped from the PR silently. `SET1` now names the directory. Run this check after **any**
commit that adds a file, not only before Phase G — a pathspec written against a tree cannot
anticipate one.

### 4.1 [S46] The check fired a third time — five files, one of them production code

Run 2026-08-26 against tip `dd43697c`: **100 files in the change, 95 in the union of the
slices.** Five fell outside every pathspec and would have been dropped from the PR silently:

| file | + | belongs in | why it was missed |
|---|---|---|---|
| `src/harmony/init.lua` | 8 | `3f` | **production code**; no code slice named `src/harmony/` |
| `doc/development/smoke_checklists.md` | 462 | `3a` | added later; `3a` listed `tests.md` but not its sibling |
| `tests/harmony_input_spec.lua` | 119 | `3b` | added later; `3b` lists `tests/input/` and named helpers only |
| `tests/util/key_spec.lua` | 43 | `3b` | added later; `tests/util/` was in no pathspec |
| `doc/tall_blocks.md` | 72 | `3a` | added later; `3a` named `doc/input_api.md` individually |

**This is the same failure a third time**, and the pattern is now unmistakable: *a pathspec that
names files cannot see a file that did not exist when the pathspec was written.* It first cost
`conventions/docs.md`, which is why `SET1` names a directory. It has now cost four more docs and
tests, and — new, and worse — **eight lines of production code**.

**The mitigation is not just these five additions.** Prefer a **directory** over a file list
wherever the directory's contents are all in-scope (`3g` already does this deliberately, and says
so). Where a file list is genuinely required, this check is the only thing standing between the
list and a silent omission, so **run §4 after any commit that adds a file** — which is what the
section above already says, and what was not done between session27 and now.

`sort -u` above hides the two intentional file-level overlaps introduced in §1.1 — Set-1 docs appear
in both `1a` and `1b`, and `userInputModel.lua` in both `3f` and `3c`. The completeness half of the
check is unaffected; for the disjointness half, the stronger test is the one that actually matters:
**assemble the branch per §2 and confirm the tip matches `$TIP`**, which catches a dropped *or*
duplicated hunk, not just a file:

```sh
git diff HEAD $TIP -- . ':(exclude)doc/development/wip/'   # must be empty at the assembled tip
```

---

## 5. Set 4 — the nested example repos, one PR each

They are separate repositories with separate remotes, so their work **cannot**
ride this PR's diff. Each carries its own local commits and opens its own PR,
tracking the platform PR closely — ideally landing with it, since the
migrations depend on the platform's `1.0.0-rc20260712` surface.

**These migrations are our work product, held to this PR's standard** (owner,
2026-08-01): complete, reviewable on their own, and carrying no homework for
the repo's author. A consequence of *our* API change is ours to finish — we
suggest migrations, we do not hand the author a question we created.

**Each repo is sliced for its PR the same way the platform is** (owner,
2026-08-03), by the recipes in §1–§2 applied to that repo. Their local commit
history is therefore **not** squashed or tidied in advance — the slices are cut
from the diff, so churn in the intermediate commits does not reach the PR. This
supersedes the standing offer to squash `keyboard`'s helper-naming churn: there
is nothing to squash.

| Repo | Remote | Branch | Local commits (unpushed) |
|---|---|---|---|
| balloons | `hleb-rubanau/compy-balloons` | `main` | `56347d0` migration off the poll idiom · `94a5f02` assign `after_submit` through `compy.input.callbacks` (the load-time raise from smoke report 5) · `cc0dbd7` submit delivers lines, not a command string |
| maze | `nagydani/Compy-maze` | `v3.4` | `790ac19` migration off the poll idiom, with the shown-guard on `compy.input.is_shown()` · `d2ce7a0` idle-gated prompt, `need_reopen`/`reopen_text` retired |
| keyboard | `dsent/keyboard` | `dsent/dev` | 8, from `4814407` run on the Compy input API through the `compy.input.fn` adoption |

Notes per repo:

- **balloons** — the migration commit predates the strict-config ruling, which
  is why the second commit exists: `compy.input.after_submit = …` raises now
  (frozen container, Decision 7 / Decision 15) and lifecycle callbacks live
  under `compy.input.callbacks`. The third came out of reviewing the first two
  end-to-end: `on_text_entered` delivers an **array of line strings**, while
  the retired `terminal()` returned one string, and the migration passed the
  array straight through. Nothing raised — `game_commands` is an `action_map`,
  so a table key just misses and returns the fallback, i.e. every command
  silently re-prompted instead of running. `deliver` now joins with
  `string.unlines`. Untracked `ISSUES.md` / `docs/*` / `implementation.md` are
  the owner's working notes and are deliberately not captured.
- **maze** — the migration was an uncommitted working tree until 2026-07-31.
  Its per-tick re-arm guard read `love.state.user_input`, which is **always
  nil inside a project** (sandboxed `love` clone), so it never fired and
  `show()` was re-issued every tick; it now asks `compy.input.is_shown()`
  (Decision 18). The two consequences that commit left open are closed by
  `d2ce7a0`: `need_reopen`/`reopen_text` are retired, because submit no longer
  closes or clears, so a rejected command's text stays in the field with the
  player still idle and the prompt stays up on its own; and "prompt only while
  idle" is now explicit — `rearm_input` syncs the overlay to `player_is_idle()`
  each tick, hiding it while a move plays out. Reopening is what clears, since
  `show()` with no `text` empties the field.
- **keyboard** — defines `love.keypressed` / `love.keyreleased` /
  `love.textinput` and uses `compy.audio`; it never shows an overlay and uses
  no `compy.input` at all. It does **not** bypass the routes (smoke report 7's
  question): a project's keyboard `love.*` functions are captured and run as
  hooks inside the project route (Decision 10). It also keeps that route,
  which is the part worth checking rather than assuming — it defines
  `love.update` and `love.draw`, so `user_is_blocking()` holds it
  (`controller.lua`). **Nothing to commit *yet*, but "nothing to migrate" was
  wrong** — it hand-rolls combo dispatch with its own l/r modifier fold, a
  key-repeat filter that exists because the pre-feature gateway dropped
  `isrepeat` (it no longer does), a mirror of the held-key set, and it leaks
  global key-repeat state believing no exit hook exists (`compy.before_exit`
  does). Scope and evidence:
  [`../validation/reviews/S25-keyboard-verdict-overturned.md`](../validation/reviews/S25-keyboard-verdict-overturned.md).
  **The migration is done** (`4814407`, owner's call 2026-08-03): hooks
  instead of `love.*` globals, the three reserved chords as shortcuts,
  `isrepeat` instead of edge tracking, and the held-set mirror replaced by a
  proxy over `compy.input.keys_pressed` — which is the *platform* change this
  repo's review produced (Decision 20), since its key-cap renderer reads held
  modifiers from `love.draw`, where no event argument exists. It is the
  acceptance case for the API, and the only sibling repo whose review changed
  the platform.

Each repo's diff is cut as one Set-4 patch — `4a-balloons`, `4b-maze`,
`4c-keyboard` (§1) — so the three sit alongside the Set 1–3 slices in
`pr-slices/` and are reviewable without cloning anything. The letters follow
the table order above and carry no apply-order meaning: the three repos are
independent of each other and of the platform slices.

Do **not** push any of these; opening the PRs is the owner's call.

---

## 6. Set inventory (file-level, for reference)

| Set / slice | Files | Churn (authoring-time) |
|---|---|---|
| 1a docs rubber-stamping | 21 | +42 (one marker + blank per file) |
| 1b generic docs | 10+ | the rest of Set 1 — grew with the front-matter conversion and `conventions/docs.md` |
| 2 agentic | 10 | +513 |
| 3a input-docs | 8 | +1669 / −35 |
| 3b tests | 6 | +2615 / −5 (minus the highlight spec) |
| 3c highlight regression | 2 | the `highlight()` hunk + its spec |
| 3d routing-core | 2 | +542 / −32 |
| 3e widget-surface | 3 | +566 / −103 |
| 3f model-view-util | 5 | +164 / −56 (minus the `highlight()` hunk) |
| 3g examples-tracked | 5 | +60 / −43 |
| 4a balloons · 4b maze · 4c keyboard | own repos | one patch per repo, §1 / §5 |

Churn drifts as the branch evolves; the pathspecs in §1 are the stable contract. When re-running,
trust §1 + §4, not these numbers.
