# S28 — sub-agent prompt of record: defect-fix mutation checks

Spawned: 2026-08-07, session28 part 1 (revalidation of session27).
Model: **Sonnet** (explicit). Scope: mechanical verification, no judgment calls,
no commits.

---

## Context you do not have

You are working in `/repo`, a LÖVE2D project (Lua 5.1) on branch
`feature/77-newapi-analysis-s20260615`. A long-running feature (#77, a new input
API) is in its pre-PR validation phase. The previous session (session27) fixed
five defects, each claiming it wrote a **breaking test first**. My job this
session is to check that claim. Yours is the mechanical half of it.

A "breaking test" is one that **fails without the production fix**. Some rows in
this feature have turned out to be *regression pins* — they pass both before and
after the fix, so they lock in behaviour but prove nothing about the defect.
Four such "blind rows" have been found on this feature already. Telling the two
apart is the entire point of this task.

**Tools:**
- `busted tests` runs the whole suite (no display needed). Current baseline:
  **953 successes / 0 failures / 0 errors / 3 pending**. `busted <path>` runs one
  spec file.
- The **`lua-lsp` MCP server** is available and working: `definition`,
  `references`, `hover`, `diagnostics` over a real AST of `/repo`. Use it
  whenever you need to know where a symbol is defined or who calls it — grep
  gives guesses, the LSP gives facts. After editing any `.lua` file, `sleep 1`
  before querying it (the server re-indexes).

## The five commits

| # | commit | defect |
|---|---|---|
| 1 | `276f0075` | `compy.input = {}` was silently accepted, corrupting framework state |
| 2 | `41747ac0` | a **nil** `compy.before_exit` raised at the first statement of teardown, wedging every later stop |
| 3 | `df3f9119` | a **raising** `compy.before_exit` did the same, still open after #2 was fixed |
| 4 | `25b9742e` | `always_shown()` guaranteed nothing — any `hide()` would clear it |
| 5 | `953d0e9f` | a reconfigure test row that could not fail, replaced by a discriminating pair |

Commit 5 is a **test-only** change (a blind row replaced). For it, the question
is different — see below.

## What to do, per commit (1–4)

Work them **one at a time**. Never have two mutations live at once.

1. `git show <commit> --stat` and `git show <commit>` — separate the **production**
   hunks (`src/…`) from the **test** hunks (`tests/…`).
2. Revert **only the production hunks** in the working tree, leaving the tests as
   they are now. `git show <commit> -- src/ | git apply -R` is the clean way; if a
   hunk no longer applies because later commits moved the code, say so and instead
   reproduce the pre-fix behaviour by hand (a minimal edit that restores the old
   logic), stating exactly what you changed.
3. Run the spec file(s) the commit touched. Record: does it now **fail**, and
   which row(s) fail, with the assertion message.
4. Restore the tree: `git checkout -- <the src paths you touched>` and confirm
   `git diff --stat` is empty for `src/`.
5. Verdict for that commit: **DISCRIMINATING** (a row fails without the fix — name
   the row) or **PIN** (all rows still pass — the test does not prove the defect).

For commit 5, instead: check out the **pre-commit** version of the replaced row
(`git show 953d0e9f^:tests/…`), and determine what production mutation makes the
**new** rows fail. Session27 claims it re-mutated after writing and confirmed the
new pair fails when it should. Verify that: find a small production mutation that
the old row would have survived and the new pair does not, and state it.

## Rules — non-negotiable

- **Never commit. Never push. Never `git stash`, `git reset`, or `git checkout`
  a branch or a whole directory.** Restore only the exact `src/` paths you
  edited, by path.
- This tree permanently carries untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, several `doc/development/wip/`
  dirs) and **three nested git repos** under `src/examples/` (balloons, maze,
  keyboard). **Do not touch any of them.** Do not `git add` anything, ever.
- At the end, run `busted tests` and confirm **953 / 0 / 0 / 3** is restored, and
  `git status --short` shows no modified tracked files. Report both.
- If a mutation makes the suite hang or explode, restore first, report second.

## Deliverable — write it to disk, do not only reply

Write your report to
**`doc/development/wip/77-new-input-api/validation/outcomes/S28-mutation-checks.md`**

Structure: one section per commit, each stating (a) the production hunk you
reverted, verbatim or as a short diff, (b) the exact command you ran, (c) the
raw pass/fail output, (d) the verdict DISCRIMINATING or PIN, and for PIN
verdicts (e) what a row *would* have to assert to discriminate — one sentence,
no implementation. Finish with the restored-baseline confirmation.

Report facts, including inconvenient ones. A PIN verdict is a useful result, not
a failure — session27 stated honestly in two of its own commit messages that the
rows pass both before and after, so expect at least two PINs and do not
manufacture a DISCRIMINATING verdict to be agreeable.
