# Synthetic system diff — manifest

Auditable record for `synthetic-system-diff.patch` (same directory): what
went in, what was stripped, and how to reproduce every piece.

- **Baseline:** `3256aac` — "docs: add development documentation,
  conventions and internals guides" (parent `01ac142`, the `updev` branch
  tip). This is the documentation corpus snapshot the diff starts from.
- **Target:** `HEAD` — `ced38bd` — "docs(input): version the input API at
  1.0.0-rc20260712 + add usage guide".
- **Generated:** 2026-07-12.

## 1. Main-repo diff

Full `3256aac..HEAD` diff, excluding `doc/development/wip/77-new-input-api/**`
(the feature's working directory: prompts, outcomes, reviews, session logs —
process artifacts, not shipped system change), then with LLM-header-only
files stripped (see §2).

**`--stat` of the cleaned main diff (43 files):**

```
 AGENTS.md                                        |   13 +
 CLAUDE.md                                        |    3 +
 agents/architecture_assistance.md                |   13 +
 agents/context.md                                |   68 +
 agents/dev.md                                    |   75 +
 agents/development.md                            |    8 +
 agents/inspect.md                                |   47 +
 agents/review.md                                 |   78 +
 agents/rules.md                                  |  133 ++
 agents/sweep.md                                  |   66 +
 doc/development/internals/console.md             |   46 +-
 doc/development/internals/examples/balloons.md   |    6 +-
 doc/development/internals/examples/guess.md      |   27 +-
 doc/development/internals/examples/index.md      |   18 +-
 doc/development/internals/examples/repl.md       |   26 +-
 doc/development/internals/examples/tixy.md       |   35 +-
 doc/development/internals/examples/turtle.md     |   27 +-
 doc/development/internals/examples/valid.md      |   23 +-
 doc/development/internals/project_sandbox_env.md |   57 +
 doc/development/internals/user_input.md          |  388 +++-
 doc/development/technical_debt.md                |   55 +
 doc/input_api.md                                 |  354 ++++
 src/controller/consoleController.lua             |  307 +++-
 src/controller/controller.lua                    |  338 +++-
 src/controller/projectInputController.lua        |  236 +++
 src/controller/userInputController.lua           |  349 +++-
 src/examples/guess/main.lua                      |   21 +-
 src/examples/repl/main.lua                       |   16 +-
 src/examples/tixy/main.lua                       |   31 +-
 src/examples/turtle/main.lua                     |   10 +-
 src/examples/valid/main.lua                      |   25 +-
 src/main.lua                                     |   13 +
 src/model/consoleModel.lua                       |    2 +-
 src/model/editor/searchModel.lua                 |    2 +-
 src/model/input/userInputModel.lua               |  117 +-
 src/util/key.lua                                 |   89 +-
 src/view/input/userInputView.lua                 |   10 +-
 tests/helpers/input_fixture.lua                  |  295 +++
 tests/helpers/input_session.lua                  |   43 +
 tests/input/input_contracts_spec.lua             | 2084 ++++++++++++++++++++++
 tests/input/keys_pressed_spec.lua                |  131 ++
 tests/input/user_input_model_spec.lua            |   40 +
 tests/mock.lua                                   |   27 +-
 43 files changed, 5421 insertions(+), 331 deletions(-)
```

For reference, the raw (uncleaned, wip/77-excluded-only) diff before header
stripping was **57 files changed, 5449 insertions(+), 331 deletions(-)**
(`--stat` captured in the repro commands below). The 14 header-only files
account for the 28-insertion / 0-deletion gap (14 files × 2 lines each).

## 2. Stripped: wip/77 working directory

Excluded via pathspec, not itemized file-by-file here (it's the entire
feature working directory, by design out of scope for a *system* diff):
**258 files changed, 40969 insertions(+)** under
`doc/development/wip/77-new-input-api/**`.

## 3. Stripped: LLM-header-only files (14)

Each of these files' *entire* diff was one `<!-- authored By LLM;
human-approved NOT YET -->` line plus one adjacent blank line inserted after
the H1 title — no other content changed (verified individually; each showed
exactly `2 insertions(+), 0 deletions(-)` and a two-line hunk). Dropped from
the synthetic diff as pure attribution-header noise:

1. `doc/development/conventions/architecture_principles.md`
2. `doc/development/conventions/code.md`
3. `doc/development/conventions/git.md`
4. `doc/development/docs.md`
5. `doc/development/drawing_system.md`
6. `doc/development/internals/editor.md`
7. `doc/development/internals/examples/clock.md`
8. `doc/development/internals/examples/life.md`
9. `doc/development/internals/examples/paint.md`
10. `doc/development/internals/examples/pong.md`
11. `doc/development/internals/examples/sapper.md`
12. `doc/development/internals/examples/sine.md`
13. `doc/development/overview.md`
14. `doc/development/tests.md`

No occurrence of the second header form (`_Generated by LLM(...)_`) was
found anywhere in the `3256aac..HEAD` main-repo diff.

**Kept despite carrying the same header line**, because each has real
content changes beyond it (verified by inspecting the full diff — every one
of these has deletions as well as insertions, i.e. substantive edits, not
just an appended line):

- `doc/development/internals/console.md` (27 insertions, 19 deletions)
- `doc/development/internals/examples/balloons.md` (5 insertions, 1 deletion)
- `doc/development/internals/examples/guess.md` (16 insertions, 11 deletions)
- `doc/development/internals/examples/index.md` (11 insertions, 7 deletions)
- `doc/development/internals/examples/repl.md` (16 insertions, 10 deletions)
- `doc/development/internals/examples/tixy.md` (25 insertions, 10 deletions)
- `doc/development/internals/examples/turtle.md` (19 insertions, 8 deletions)
- `doc/development/internals/examples/valid.md` (16 insertions, 7 deletions)
- `doc/development/internals/user_input.md` (large rewrite, 388 lines touched)
- `doc/input_api.md` (new file, 354 lines — header is incidental to a whole
  new doc, not the entire change)

The header hunks in these files were left in place (not surgically split
out) since the header is a single two-line, cleanly-ignorable prefix in each
file and splitting it out risks producing a non-reviewable partial hunk for
no material benefit — reviewers can visually skip the one header line.

## 4. Nested example-game repos (separate git checkouts)

`src/examples/{balloons,maze,keyboard}` are independent git repositories
nested under the main repo's working tree; the parent repo's git history
cannot see into them, so their #77 changes are invisible to `git diff
3256aac HEAD` above and are appended separately.

### Included: balloons

- Repo: `src/examples/balloons`
- Change: commit `56347d0` — "feat: migrate off legacy poll idiom onto
  compy.input.* continuous-session API" (3 files changed, 18 insertions(+),
  15 deletions(-): `main.lua`, `terminal.lua`, `ui.lua`).
- This is the #77 migration commit, and only that commit — the working tree
  in that checkout also has an uncommitted `main.lua` change (pre-existing
  test/print cruft, deliberately left out of the migration commit per its
  own commit message) and several untracked docs/*.md files; neither is
  included.

### Included: maze

- Repo: `src/examples/maze`
- Change: **uncommitted working-tree diff** (`controls.lua`, `main.lua`; 2
  files changed, 42 insertions(+), 14 deletions(-)) — the M5c-05 migration
  onto `compy.input.*` (deferred re-show via `need_reopen`/`reopen_text`,
  `open_editor_input`/`rearm_input` replacing the old poll loop).
- Checked `git -C src/examples/maze log --oneline -5`: tip is `12f675f`
  "Minor update main.lua", with no #77-related commit in recent history —
  so the working-tree diff is the actual change, not a duplicate of
  something already committed.
- Working tree has no untracked files in this checkout, so `git diff`
  (tracked files only) is the complete change.

### Excluded: keyboard

- Repo: `src/examples/keyboard`
- Verified via `git -C src/examples/keyboard status --short` → clean
  working tree (no output), and `git -C src/examples/keyboard log --oneline
  -5` → no #77-related commits (all pre-existing native-input feature work:
  alt-character folding, keycap rendering, etc.).
- Pure-native example, not touched by #77. No diff included.

## 5. Reproduction commands

```sh
# Main repo, raw (wip/77 excluded only, before header stripping):
git diff 3256aac HEAD -- . ':(exclude)doc/development/wip/77-new-input-api/**'
git diff 3256aac HEAD --stat -- . ':(exclude)doc/development/wip/77-new-input-api/**'

# wip/77 exclusion size, for reference:
git diff 3256aac HEAD --stat -- 'doc/development/wip/77-new-input-api/**'

# Cleaned main-repo --stat (header-only files also excluded):
git diff 3256aac HEAD --stat -- . \
  ':(exclude)doc/development/wip/77-new-input-api/**' \
  ':(exclude)doc/development/conventions/architecture_principles.md' \
  ':(exclude)doc/development/conventions/code.md' \
  ':(exclude)doc/development/conventions/git.md' \
  ':(exclude)doc/development/docs.md' \
  ':(exclude)doc/development/drawing_system.md' \
  ':(exclude)doc/development/internals/editor.md' \
  ':(exclude)doc/development/internals/examples/clock.md' \
  ':(exclude)doc/development/internals/examples/life.md' \
  ':(exclude)doc/development/internals/examples/paint.md' \
  ':(exclude)doc/development/internals/examples/pong.md' \
  ':(exclude)doc/development/internals/examples/sapper.md' \
  ':(exclude)doc/development/internals/examples/sine.md' \
  ':(exclude)doc/development/overview.md' \
  ':(exclude)doc/development/tests.md'

# Per-file check for any header-only candidate, e.g.:
git diff 3256aac HEAD -- doc/development/conventions/architecture_principles.md

# Nested repos:
git -C src/examples/balloons show 56347d0
git -C src/examples/balloons log --oneline -5
git -C src/examples/balloons status --short

git -C src/examples/maze diff
git -C src/examples/maze log --oneline -5
git -C src/examples/maze status --short

git -C src/examples/keyboard status --short
git -C src/examples/keyboard log --oneline -5
```

## 6. Totals summary

| Section | Files | Insertions | Deletions |
|---|---|---|---|
| Main repo (cleaned) | 43 | 5421 | 331 |
| Excluded: wip/77 (not itemized) | 258 | 40969 | 0 |
| Excluded: LLM-header-only | 14 | (28, all dropped) | 0 |
| Nested: balloons (56347d0) | 3 | 18 | 15 |
| Nested: maze (working tree) | 2 | 42 | 14 |
| Nested: keyboard | — excluded, unchanged — | | |
