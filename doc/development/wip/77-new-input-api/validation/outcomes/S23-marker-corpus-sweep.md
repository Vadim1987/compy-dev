# S23 — J1 marker-corpus sweep (Sonnet, read-only)

Verification run against HEAD (`2942147`). No files edited except this one.

## 1. Marker residue — tracked `src/` and `tests/`

**Verdict: FINDINGS: 1** (plus 1 sanctioned exception; all other hits benign)

Swept `git ls-files src tests` (213 files) for: `REVIEW:`, `{jargon:`,
`{badspecref:`, `RVW-`, `wip/77`, `77-new-input-api`, `TF2`, `TF3`, `B-COV`,
`B-E`, `B-I`, `B-F`, `S19`/`S20`/`S21`/`S22`, `milestone`, `phase R`,
`R-phase`, `sweep`, `mop-up` (case-insensitive).

| file:line | quoted text | classification |
|---|---|---|
| `src/util/graphics/bentley_ottmann.lua:4,265,268,275,379,381,384,393,395,402,403,414,425,813` | `bo_sweep`, "Sweep state", "Main sweep loop", "via Bentley-Ottmann sweep line algorithm" | **benign** — "sweep" is the geometry-algorithm term (Bentley–Ottmann sweep-line), unrelated to construction-era vocabulary |
| `tests/editor/editor_spec.lua:712` | `-- (S21/B-F): this is editor-internal behaviour, not an input` | **residue** — a session/phase-ID citation (`S21/B-F`) left in a comment explaining a test relocated from the input suite. Not touched by either J1 commit (`c09f590`/`e28f58d`), both of which only changed files under `tests/input/` and `src/controller|model|view|util|main.lua` — this file was out of their diff scope entirely. |
| `tests/input/.input_nfr_forward_spec.lua.swp` | (binary content, 2 raw-byte matches under `grep -a`, silently skipped by the text sweep) | **sanctioned** — this is the tracked binary Vim swap-file artifact named in the task's known exception. Confirmed binary via `grep -qI` (no text match) and traced to commit `64e5af4` ("test(input): B-F — structural mop-up, 14 markers (owner-ruled)"), itself an example of the pre-J1 marker style, now embedded only inside binary swap bytes that ordinary text tools don't surface. Left untouched, as instructed. |

No other hits: `REVIEW:`, `{jargon:`, `{badspecref:`, `RVW-`, `wip/77`,
`77-new-input-api`, `TF2`, `TF3`, `B-COV`, `B-E`, `B-I`, `B-F` (outside the
one line above), `S19`/`S20`/`S22`, `milestone`, `phase R`, `R-phase`,
`mop-up` — zero hits in tracked `src/`/`tests/`. The J1 test/source commits
did what they claimed inside their own diff scope; the one miss
(`editor_spec.lua:712`) is in a file neither commit touched.

## 2. Same sweep over the six persistent doc files

**Verdict: FINDINGS: 3 categories, ~25 individual hits**

Files: `doc/input_api.md`, `doc/development/internals/user_input.md`,
`doc/development/decisions/input.md`, `doc/development/technical_debt/input.md`,
`doc/development/technical_debt/general.md`, `doc/development/tests.md`.

### 2a. Literal pattern-list hits

| file:line | quoted text | classification |
|---|---|---|
| `doc/development/technical_debt/input.md:50` | "renaming these under a mechanical sweep would either bless the smell..." | **benign** — ordinary English ("sweep" = pass over the code), not a phase marker |
| `doc/development/technical_debt/input.md:447` | "...intent-revealing names ... in one sweep." | **benign** — same, ordinary English |
| `doc/development/tests.md:58` | "carried `pending` until the named milestone lands" | **benign** — generic description of the test-tag taxonomy, no specific milestone ID cited |
| `doc/development/tests.md:62` | "Tags beyond the file-level `#input`, matching implementation milestones:" | **benign** — same, generic |
| `doc/development/technical_debt/input.md:570` | "...both cite `doc/development/wip/77-new-input-api/validation/…`. Rehome to the persistent" | **finding, with nuance** — this line itself contains a literal `wip/77-new-input-api` path. It is a debt-catalog entry *describing* two `src/controller/` comments that improperly cite the wip tree (a real, still-open debt item, not fabricated) — so it is legitimately quoting the problem, not a leftover of the doc's own construction. Still, per the task rule ("any reference from a persistent doc into wip/77 ... is a finding — those docs must resolve without the wip tree"), this line is a literal wip/77 path inside a persistent doc and is flagged as such. It does not itself need the wip tree to *resolve* (it's prose, not a working link), but it is the kind of reference the corpus is supposed to be free of. |

### 2b. `#77` / `TF1` / milestone-ID hits (found via extended search, not in the literal pattern list, but squarely inside task 2's broader rule: "...or to a session/phase ID is a finding")

23 bare `#77` references across four of the six files, plus one `TF1` and
one `M8-03`/`0.1.0-m8` pair. None are markdown links (they don't break page
navigation), but they are feature/session-ID citations of exactly the kind
J1 was chartered to remove from the persistent corpus.

| file:line | quoted text | classification |
|---|---|---|
| `doc/development/internals/user_input.md:273` | "separate #77 scope item: only keyboard..." | **finding** — feature-ID reference |
| `doc/development/internals/user_input.md:365` | "...is untouched by feature #77)." | **finding** |
| `doc/development/internals/user_input.md:383` | "...different class, out of feature #77's scope" | **finding** |
| `doc/development/internals/user_input.md:389` | "...design documents for feature #77 mention this" | **finding** |
| `doc/development/internals/user_input.md:395` | "Feature #77 makes a later editor migration possible..." | **finding** |
| `doc/development/decisions/input.md:444` | "Before #77, a running project without..." | **finding** |
| `doc/development/decisions/input.md:543` | "owner-ratified in validation; no #77 implementation." | **finding** |
| `doc/development/decisions/input.md:555` | "...the pre-feature split contains #77 scope and" | **finding** |
| `doc/development/decisions/input.md:580` | "...a behavioural default keeps the #77 suite" | **finding** |
| `doc/development/technical_debt/input.md:22` | "This asymmetry predates #77 and is not worsened by it." | **finding** |
| `doc/development/technical_debt/input.md:118` | "(pre-`0022004`) — not a #77 regression. The" | **finding** |
| `doc/development/technical_debt/input.md:119` | "...call site is new on the #77 branch" | **finding** |
| `doc/development/technical_debt/input.md:487` | "Pointer never had the #77 widget-lockout..." | **finding** |
| `doc/development/technical_debt/input.md:488` | "...pre-existing behaviour, deliberately out of #77 scope." | **finding** |
| `doc/development/technical_debt/input.md:490` | "...explicitly not in #77 scope." | **finding** |
| `doc/development/technical_debt/input.md:558` | "...a different class, out of #77 scope." | **finding** |
| `doc/development/technical_debt/input.md:563` | "...tracked future concern, out of #77 scope." | **finding** |
| `doc/development/tests.md:17` | "full input standup for the `#input` contract suite (feature #77)." | **finding** |
| `doc/development/tests.md:33` | "Input routing / dispatch contracts (feature #77)" | **finding** |
| `doc/development/tests.md:51` | "## Input Contract Suite (feature #77)" | **finding** (section heading) |
| `doc/development/tests.md:53` | "...in feature-#77 validation (**TF1**) it was split..." | **finding** — both `feature-#77` and `TF1` (the latter is the same phase-ID family as the already-listed `TF2`/`TF3`, just missing from the enumerated pattern list) |
| `doc/development/tests.md:64` | "...removed at **0.1.0-m8, M8-03**) — no shim..." | **finding** — `M8-03` is confirmed a construction-era batch ID (also appears in `agents/sweep.md:61`, an out-of-corpus rules doc, as a milestone label); `0.1.0-m8` does not match any real version string in `CHANGELOG.md` and is the same milestone-label family, not product semver |
| `doc/development/tests.md:70` | "...either out of #77's scope or not black-box observable today" | **finding** |
| `doc/development/tests.md:84` | "...plus the feature #77 milestone tags `#legacy`, `#m5c`, `#m7`, `#m8`" | **finding** — note `#legacy`/`#m5c`/`#m7`/`#m8` themselves are **not** flagged: these are live `.busted` tags actually used in the tracked spec files, not vestigial markers |

`doc/input_api.md` and `doc/development/technical_debt/general.md`: **zero**
hits in either sweep — clean.

## 3. Cross-reference integrity of the persistent corpus

**Verdict: FINDINGS: 2**

Extracted every markdown link (`[text](path)`) and every backtick-quoted
path-like citation from the six files and resolved each relative to its
source file.

**Markdown-style links** (all resolve):

| source | target | result |
|---|---|---|
| `doc/input_api.md` | `development/internals/user_input.md` | OK |
| `doc/development/internals/user_input.md` | `../../input_api.md` (×2) | OK |
| `doc/development/internals/user_input.md` | `event_dispatch_layers.md` | OK |
| `doc/development/decisions/input.md` | `../internals/user_input.md` | OK |
| `doc/development/decisions/input.md` | `../../input_api.md` | OK |
| `doc/development/decisions/input.md` | `../technical_debt/input.md` | OK |

**Bare-name / prose path citations** — findings:

| file:line | citation | issue |
|---|---|---|
| `doc/development/technical_debt/input.md:243` | `` `tests/input/overlay_spec.lua` `` | **broken** — no file by this name exists anywhere in the tree (`find tests -iname '*overlay*'` returns nothing). Either the test was renamed/merged/removed without updating this debt entry, or the entry itself is stale. |
| `doc/development/decisions/input.md:257` | `` `design/requirements.md` `` | **stale/fragile** — the only matching files in the tree are `doc/development/wip/77-new-input-api/design/requirements.md` and `.../design/notes/requirements.md` (both inside the wip tree the six docs are supposed to survive without). This citation only resolves today because the wip tree still exists; it will dangle the moment `doc/development/wip/77-new-input-api/` is deleted, contradicting the persistent-corpus contract stated in this task's background. |

**Other bare-name citations checked and OK** (all resolve unambiguously to
a single tracked file in context, even though cited without a full path):
`editor.md` → `doc/development/internals/editor.md`; `console.md` →
`doc/development/internals/console.md`; `conventions/code.md` →
`doc/development/conventions/code.md`; `agents/rules.md`;
`tests/input/input_lifecycle_unfork_spec.lua`;
`tests/input/input_routing_spec.lua`; `tests/helpers/input_fixture.lua`;
`tests/input/input_widget_lifecycle_spec.lua`;
`tests/helpers/editor_session.lua`; `tests/helpers/input_session.lua`;
`tests/mock.lua`; `tests/testutil.lua`; and the bare source filenames
(`controller.lua`, `consoleController.lua`, `userInputController.lua`,
`editorController.lua`, `searchController.lua`, `key.lua`,
`projectInputController.lua`, `userInputModel.lua`, `inputText.lua`,
`cursor.lua`, `selection.lua`, `history.lua`, `userInputView.lua`) — each
resolves to exactly one tracked file under `src/`.

One additional observation, not raised as a finding: `doc/development/internals/user_input.md:611`
cites `` `examples/maze/main.lua` `` as a usage example. The file exists on
disk (`src/examples/maze/main.lua`) but is **untracked** (`git status`
shows `?? src/examples/maze/`) — i.e. it is not part of the committed tree
this doc is meant to describe. This is scratch/example content per the
S23 prompt's own carve-out, not corpus residue, but the doc's citation is
resting on something outside version control.

## 4. Diff-level check of the J1 commits

**Verdict: CLEAN**

- `c09f590` ("test(input): remove construction-era test markers") — 13
  files under `tests/`, 75 insertions / 176 deletions, plus two new
  `S22-terra-J1-test-cleanup.md` docs under `wip/` (out of scope, additive
  only). Read the full diff: every hunk removes or rewords a `-- REVIEW`,
  `{jargon:`, `{badspecref:` comment block, or reworks a multi-line comment
  into a shorter one. The one hunk that changes a non-comment line
  (`input_shortcuts_click_spec.lua`, the `it('#play mode narrows...')`
  call) only re-joins the function literal onto one line after deleting
  the comment between its two arguments — the call signature and body are
  byte-for-byte identical, no assertion/expression/control-flow change.
- `e28f58d` ("docs(input): remove construction-era source markers") — 8
  files under `src/`, 50 insertions / 70 deletions, plus two new
  `S22-terra-J1-source-cleanup.md` docs under `wip/`. Read the full diff:
  every hunk is a comment deletion or comment reword (`DEFERRED
  ({badspecref: ...})`, `REVIEW/...`, `{badspecref: ...}` blocks removed or
  compressed to plain prose). No line outside a `--`/`---` comment changed.

Both commits are comment/prose-only, as claimed. Line-count churn is
consistent with pure comment removal, not hidden behavioural edits.

## Overall verdict

**Not fully clean.** The J1 commits themselves (`c09f590`, `e28f58d`) are
exactly what they claim — comment-only marker removal, verified line by
line. The gaps are:

1. One tracked-test residue miss outside the J1 commits' diff scope
   (`tests/editor/editor_spec.lua:712`, an `S21/B-F` citation).
2. The persistent-doc corpus is **not** free of construction-era
   vocabulary: four of six files (`internals/user_input.md`,
   `decisions/input.md`, `technical_debt/input.md`, `tests.md`) carry ~23
   bare `#77` feature-ID citations, one `TF1` phase-ID citation, and one
   `M8-03`/`0.1.0-m8` milestone-ID citation, plus the one literal
   `wip/77-new-input-api` path inside a debt-catalog entry.
   `doc/input_api.md` and `technical_debt/general.md` are clean.
3. Two stale/broken cross-references in the persistent docs: a dead
   `tests/input/overlay_spec.lua` citation, and a `design/requirements.md`
   citation that only resolves inside the wip tree.

Sanctioned and out of scope: the tracked `.swp` binary artifact
(`tests/input/.input_nfr_forward_spec.lua.swp`); everything under
`doc/development/wip/`; the `#legacy`/`#m5c`/`#m7`/`#m8` busted tags (live
infrastructure, not markers); the Bentley–Ottmann "sweep" vocabulary
(algorithm name, not a phase marker).

## Could not verify / out of scope

- Did not run `busted tests` (per instructions — parent holds the
  baseline); the "no behavioural change" verdict for the J1 commits rests
  on manual diff reading, not a green-test confirmation.
- Did not audit the *content accuracy* of the six persistent docs beyond
  marker vocabulary and path resolution (e.g., whether the described
  mechanisms still match current `src/` behaviour) — out of this task's
  scope.
- Did not chase whether `tests/input/overlay_spec.lua` was renamed (e.g.
  to something inside `input_widget_lifecycle_spec.lua` or similar) — only
  confirmed no file by that name exists; determining the correct rehome
  target is the parent's call, not verified here.
