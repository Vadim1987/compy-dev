# S28 — cold review of the merge RESULT (post-move)

Reviewed 2026-08-07, session28. Read-only throughout: no spec, source, doc
or config file was touched; no `git add`/commit/push. Commits reviewed,
oldest first: `90f632cf` (step 1), `25f70175` (step 2), `b0c9d032` (tag
fix), `bc5b97ae` (citation repointing), `a246c170` (step 3). Documents
compared against: the plan
(`../reviews/S28-merge-plan.md`), the inventory
(`S28-merge-inventory.md`), and the pre-move review
(`S28-merge-plan-review.md`).

Method: the four source files were pulled from `90f632cf^` via `git show
90f632cf^:tests/input/<file>` into a scratch directory (`/tmp/.../scratchpad/orig/`,
outside the repo) since they no longer exist in the working tree. A
paren-depth-aware Python extractor (not a title-line grep, which breaks on
the several multi-line `it(...)` titles in these files) pulled every
`it(...)` call's full title and body from both the four originals and the
two current merged files, keyed by title, and diffed normalized bodies
(each line stripped, blank lines dropped) title-by-title. `busted` was run
against the scratch copies directly (they resolve fine from `/repo` because
`.busted`'s `ROOT` only sets the default scan dir; an explicit file path
overrides it and `require()` paths still resolve against the repo root) to
get authoritative per-file and per-tag row counts, matching the inventory's
own methodology of trusting `busted`'s tally over a source-text grep.

---

## 1. No row was lost or silently altered — CONFIRMED

Extracted all 93 `it(...)` rows from the four originals (line numbers and
titles matched the inventory exactly) and all 91 rows from the two current
merged files, and matched every original title against the merged files.

Result of the automated diff:
- 93 original rows → 91 found in the merged files, 2 correctly absent
  (the two named deletions, confirmed not lingering in either merged file
  under any title).
- 0 originals missing that aren't a declared deletion.
- 0 merged rows with no original counterpart (no unexplained additions).
- Of the 91 surviving rows, **89 have byte-for-byte-identical bodies**
  (structurally normalized: whitespace/indentation differences from the
  new nesting level are ignored, content is not).
- **2 rows differ**, and both are exactly the two authorised survivors
  from §5b (see check 2) — no other row's body changed.

Evidence: diff script and its output are reproducible from
`/tmp/.../scratchpad/{extract_rows2.py,diff_rows.py}` (scratch, not
committed); the underlying facts are the `git show 90f632cf^:tests/input/*.lua`
originals vs. the current `tests/input/input_widget_control_spec.lua` and
`tests/input/input_widget_callbacks_spec.lua`.

## 2. The three authorised content changes are exactly as specified — CONFIRMED

Both deletions land as specified: `input_widgets_callbacks_spec.lua:629`
("after_submit may hide, reproducing prompt-once") and
`input_widgets_callbacks_spec.lua:613` ("stays open after submit; a
project clears in after_submit") are absent from the merged files under
any title.

The two survivors gained exactly what §5b names, confirmed by reading the
merged source directly:

- **`input_widget_callbacks_spec.lua:647-659`** ("after_submit is what
  closes the widget", ex-`reconfigure:279`) — gained
  `assert.is_false(F.is_widget_visible())` on line 658, immediately after
  the pre-existing `assert.is_false(F.widget:is_shown())` on line 657.
  Correct helper (`is_widget_visible`, the `love.state.user_input`
  overlay-observable), not the internal `is_shown()` — this is the
  distinction the pre-move review caught.
- **`input_widget_callbacks_spec.lua:677-696`** ("the re-armed session
  observes a second submit", ex-`reconfigure:308`) — gained
  `assert.is_true(F.is_widget_visible())` and
  `assert.is_true(F.widget:is_empty())` twice: after the **first** submit
  (lines 690-691, before `F.session.type('b')`) and after the **second**
  (lines 694-695, before the final `assert.same`). Correct helper again
  (`is_widget_visible`, matching what the deleted `:613` used, per the
  pre-move review's explicit naming), and at both positions — the
  faithful fold, not the weaker "only after the second" the plan's
  original prose left ambiguous.

`F.is_widget_visible()` (`tests/helpers/input_fixture.lua:209`) and
`UserInputController:is_shown()` (`src/controller/userInputController.lua:440`)
remain two distinct helpers reading different state; confirmed both still
exist and are not aliased.

## 3. Tags — CONFIRMED (including the fix)

Enumerated every actual busted tag (a `#word` inside a `describe`/`it`
title string, not prose) in the four originals by grepping every
`describe(`/`it(` line for `#`:

| tag | files carrying it (root describe) | row count |
|---|---|---|
| `#input` | all four (`input_widget_lifecycle_spec`, `input_reconfigure_spec`, `input_widgets_callbacks_spec`, `input_lifecycle_uniform_spec`) | 27+16+36+14 = 93 |
| `#lifecycle` | `input_lifecycle_uniform_spec` only | 14 |

No third tag exists in these four files as an actual tag. The one other
string that looks like one — `input_widget_lifecycle_spec.lua:202`,
"...and were tagged `#disputable` because..." — is prose inside a
**comment**, not a `describe`/`it` string; a full grep for `#` across all
four originals turned up no other candidate (the remaining hits are all
`#seen`/`#reached`/`#order` Lua length-operator uses, unrelated). Whole-
suite `busted tests --tags=disputable` today selects 2 rows, both in
`input_shortcuts_click_spec.lua`, which none of these four files touch —
confirms `#disputable` was never live in the merge's scope.

Confirmed each tag still selects the same total post-merge, run against
the actual files (not estimated):

- `busted tests/input/input_widget_control_spec.lua --tags=input` → **39**
- `busted tests/input/input_widget_callbacks_spec.lua --tags=input` → **52**
  (39 + 52 = 91 = 93 − 2 deletions, both originally `#input`-tagged)
- `busted tests/input/input_widget_control_spec.lua --tags=lifecycle` → **0**
- `busted tests/input/input_widget_callbacks_spec.lua --tags=lifecycle` → **14**
  (matches the original 14; this is the tag `b0c9d032` restored — confirmed
  live at `input_widget_callbacks_spec.lua:755`,
  `describe('the same lifecycle on every route #lifecycle', ...)`, which
  holds exactly the 14 rows moved from `input_lifecycle_uniform_spec.lua`)

Both merged files' full (untagged) row counts equal their `--tags=input`
counts exactly (39 and 52), i.e. every surviving row is still `#input`-
tagged via its new root describe — no row silently lost the file-level tag.

## 4. Helpers and requires — CONFIRMED

Grepped both merged files for the five named helpers and the `TU` require:

- `arm` and `open_on` (defined `input_widget_control_spec.lua:560,568`,
  called at lines 576/582/593/605/616/620) — present only in the control
  file, which is the only one that needs them (the echo-guard rows).
- `bare_uic`, `driver`, `open_doc` (defined
  `input_widget_callbacks_spec.lua:758,771,777`, called throughout the
  `the same lifecycle on every route` describe) — present only in the
  callbacks file, which is the only one that needs them.
- `local TU = require('tests.testutil')` is present at
  `input_widget_callbacks_spec.lua:25`, alongside `F` (line 23) and `mock`
  (line 24) — the fourth correction from the pre-move review, carried
  through. `input_widget_control_spec.lua:20` requires only `F`, which is
  all it needs (no `open_doc` in that file).
- No row in either file calls a helper not defined or required in that
  same file — confirmed by the grep above turning up every call site
  co-located with its definition, and by `busted` on both files reporting
  0 errors (an undefined-helper call would raise, not fail an assertion).

## 5. Dangling references — CONFIRMED, one out-of-scope non-issue noted

`grep -rl` for each of the four dissolved filenames
(`input_widget_lifecycle_spec`, `input_reconfigure_spec`,
`input_widgets_callbacks_spec`, `input_lifecycle_uniform_spec`) across the
whole repo, excluding `doc/development/wip/`, found:

- **Zero** hits in any comment, doc, or source file.
- One hit each for three of the four names (not
  `input_lifecycle_uniform_spec`) in `.claude/settings.local.json` — a
  cached Bash-permission allowlist entry (e.g. `"Bash(busted
  tests/input/input_reconfigure_spec.lua)"`), not a comment or doc citation
  and not something a reader would follow as authoritative. Flagged for
  completeness since it is a literal surviving mention, but it is outside
  what check 5 asks about (comments/docs) and does not point anyone at a
  file that no longer exists in any way that misleads.
- `input-pr-slices.tar.gz` (untracked, repo root) was also checked with
  `grep -a`: no match for any of the four names inside the archive.

Repointed citations (from `bc5b97ae`) all resolve — checked each named
describe group actually exists at the stated location:

| citation | now names | resolves? |
|---|---|---|
| `doc/development/internals/user_input.md:401` | `input_widget_callbacks_spec.lua`, "the same lifecycle on every route" | yes — `input_widget_callbacks_spec.lua:755` |
| `doc/development/technical_debt/input.md:552` | `input_widget_control_spec.lua`, "the documented echo guard" | yes — `input_widget_control_spec.lua:558` |
| `doc/development/technical_debt/input.md:772` | `input_widget_callbacks_spec.lua` (file only) | yes — file exists |
| `doc/development/technical_debt/input.md:878` | `input_widget_control_spec.lua`, "show(): activation and reset" | yes — `input_widget_control_spec.lua:35` |
| `doc/development/technical_debt/input.md:1081` | `input_widget_callbacks_spec.lua`, "the same lifecycle on every route" | yes — as above |
| `doc/development/tests.md` (multiple) | `input_widget_control_spec`, `input_widget_callbacks_spec`, both by surface | yes — files exist, three-surface prose matches §4 of the plan |
| `tests/input/input_events_spec.lua:21` | `input_widget_callbacks_spec.lua` (file only) | yes |
| `tests/input/input_widget_callbacks_spec.lua:753` | credits the method-patch technique to `input_events_spec.lua`'s "one widget-signature row" | yes — `input_events_spec.lua:29` documents exactly that row |
| `tests/input/input_widget_callbacks_spec.lua:930` | "this file's 'submit' and 'cancel — the Escape chain' groups" | yes — both describes exist in the same file (lines 262, 443) |
| `tests/editor/editor_spec.lua:719` | generic "the input contract suite (tests/input/)", no longer names a specific file | trivially resolves (no longer a path-shaped claim) |

## 6. The suite still means what it did — CONFIRMED

`busted tests` → **952 successes / 0 failures / 0 errors / 3 pending**
(live run), matching the plan's expected end state exactly, and the same
3 pending rows as before (`input_routing_spec.lua`, unrelated to this
merge).

Per-file counts match the plan's targets exactly:
`busted tests/input/input_widget_control_spec.lua` → 39;
`busted tests/input/input_widget_callbacks_spec.lua` → 52.

No duplicate `describe` titles within either merged file (checked both
files' full `describe(` title lists for duplicates — none). No duplicate
`it` titles within either file — checked via the same paren-aware
extractor used for check 1, which builds a title-keyed map per file; had
any file produced two rows with the same title the extractor would have
overwritten one and reported a count mismatch against `busted`'s tally
(39 and 52 both matched exactly, and the extractor's per-file counts
matched `busted`'s independently-verified totals), so no collision exists
at any nesting depth, not just at the root.

---

## Overall

The merged suite preserves the pre-merge suite's coverage, minus exactly
the two authorised deletions — every row's body, tag membership, helper
availability, and citation network check out against the plan and the
source, and the one previously-caught regression (the `#lifecycle` tag)
is confirmed fixed and stable.
