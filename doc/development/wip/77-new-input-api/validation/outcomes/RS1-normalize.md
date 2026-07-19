# RS1 — normalize persistent-doc citations to repo-root-relative (Sonnet worker outcome)

Executed per `validation/prompts/RS1-normalize-paths-prompt.md`. Not committed —
left for the orchestrator to review and commit.

## Method

Baseline grep (`(decisions|internals|technical_debt)/[A-Za-z0-9_]+\.md` in
`tests/` and `src/` `.lua`, excluding `src/examples/**` and
`src/vadexamples/**`) confirmed exactly the inventoried 210 bare refs across
the 11 named files, and exactly 3 unique bare filenames in use:
`decisions/input.md`, `internals/user_input.md`, `technical_debt/input.md`
(no other `internals/*.md` / `decisions/*.md` bare form occurs). Verified
every bare hit sits in a `--`/`---` comment (none in string literals,
`require(...)`, or other live code — zero skips/anomalies of that kind).
Verified no bare corpus path sits inside a `{badspecref: ...}` wrapper
anywhere in the tree (the `{badspecref: internals/…}`-nesting case in the
prompt's hard-constraints section does not occur in practice), so no
wrapper text needed special handling.

Applied a single Perl substitution per file, guarded by a negative
lookbehind so already-prefixed refs are left untouched:

```
perl -i -pe 's{(?<!doc/development/)(decisions|internals|technical_debt)/([A-Za-z0-9_]+\.md)}{doc/development/$1/$2}g' <file>
```

Correctness was verified two ways, not just by eyeballing the diff:
1. Reversing the transform (stripping `doc/development/` back off every
   `(decisions|internals|technical_debt)/...md` occurrence in the edited
   file) and diffing against `git show HEAD:<file>` reproduces the original
   byte-for-byte, except on the 4 lines that already carried the correct
   prefix before this change (those diverge only because the reversal
   over-strips *all* occurrences, including ones this task never touched —
   confirmed by inspecting each of those 4 diffs directly: each is exactly
   one of the pre-existing already-root-relative lines, untouched by the
   edit).
2. Pre/post `mcp__lua-lsp__diagnostics` snapshots per file (after `sleep 1`)
   are identical in count and content for all 11 files — no new diagnostics,
   confirming no live code was touched.

## Per-file counts (bare refs normalized)

| File | Refs normalized |
|---|---:|
| `tests/mock.lua` | 1 |
| `tests/input/keys_pressed_spec.lua` | 1 |
| `tests/helpers/input_fixture.lua` | 3 |
| `tests/input/input_contracts_spec.lua` | 120 |
| `src/view/input/userInputView.lua` | 1 |
| `src/model/input/userInputModel.lua` | 3 |
| `src/util/key.lua` | 3 |
| `src/controller/consoleController.lua` | 16 |
| `src/controller/projectInputController.lua` | 23 |
| `src/controller/userInputController.lua` | 20 |
| `src/controller/controller.lua` | 19 |
| **Total** | **210** |

(One line in `tests/input/input_contracts_spec.lua` — the "corpus (...)"
line — carries two bare refs on the same line; 210 changed lines therefore
correspond to 211 individual ref-occurrences normalized, consistent with the
final occurrence-level grep count below.)

No double-prefixing: the 4 refs already written `doc/development/...` that
fall inside these 11 files (in `input_contracts_spec.lua`,
`consoleController.lua`, `controller.lua`, `projectInputController.lua`)
were left untouched — confirmed both by the reverse-diff check above and by
direct inspection. (A 5th pre-existing root-relative ref lives in
`tests/input/project_open_liveness_spec.lua`, outside the 11-file inventory
and outside this task's scope; left untouched.)

No skips/anomalies: no bare corpus path was found in live code, and no bare
corpus path was found nested inside a `{badspecref: ...}` wrapper.

## Final grep proof

```
$ grep -rnE '(decisions|internals|technical_debt)/[A-Za-z0-9_]+\.md' tests src --include='*.lua' \
    | grep -v 'src/examples' | grep -v 'src/vadexamples' \
    | grep -vE 'doc/development/(decisions|internals|technical_debt)/' | wc -l
0

$ grep -rnoE 'doc/development/(decisions|internals|technical_debt)/[A-Za-z0-9_]+\.md' tests src --include='*.lua' \
    | grep -v 'src/examples' | grep -v 'src/vadexamples' | wc -l
216
```

Zero bare corpus refs remain. Root-relative occurrence count rose from 5
(pre-existing) to 216 — i.e. +211 occurrences, matching the 210 changed
lines (one line held 2 refs).

## Suite result

`busted tests`: **815 successes / 0 failures / 0 errors / 4 pending** —
unchanged from baseline (same 4 pending tests, same names/locations). Ran
both before and after the edit.

## git diff --stat

```
 src/controller/consoleController.lua      |  32 ++--
 src/controller/controller.lua             |  38 ++---
 src/controller/projectInputController.lua |  46 +++---
 src/controller/userInputController.lua    |  40 ++---
 src/model/input/userInputModel.lua        |   6 +-
 src/util/key.lua                          |   6 +-
 src/view/input/userInputView.lua          |   2 +-
 tests/helpers/input_fixture.lua           |   6 +-
 tests/input/input_contracts_spec.lua      | 240 +++++++++++++++---------------
 tests/input/keys_pressed_spec.lua         |   2 +-
 tests/mock.lua                            |   2 +-
 11 files changed, 210 insertions(+), 210 deletions(-)
```

Comment/docstring-only changes; no code lines touched (verified via
reverse-diff reconciliation against `HEAD` and via unchanged LSP
diagnostics, both above). No skip/anomaly beyond the notes above. Not
committed.
