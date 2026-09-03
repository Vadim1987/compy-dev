---
description: Cold peer review of session68's own changes (c610805b..HEAD) — integrity and sanity of the diff, not the plan
status: sub-agent outcome
audience: developer
authored: llm
session: 68
date: 2026-09-03
---

# S68 cold peer review

**Verdict: holds, with one real gap.** Every specific factual claim I checked — line citations,
function signatures, arithmetic within a single computation, code-vs-doc correspondence — resolved
exactly as written, including several with exact-to-the-line-number precision (`F.reset()`'s eleven
lines, `controller.lua:67`, `user_pointer`'s three line numbers, `love.event.push('userinput')` at
`userInputModel.lua:819`). The one substantive problem is **F0**: the session's central
verification claim — "56 retired entries walked... no resolution claim failed" — undercounts the
actual `RETIRED` sections by two entries that existed in the tree by the time the claim was
committed, via commits that are direct ancestors of it. **F1** is a second, lower-severity
arithmetic-presentation issue in the same neighbourhood (a "23 → 17" figure that omits three
additions the same session's own commit message names). Both are about a session that otherwise
verified its own work unusually rigorously — the same rigor is what makes the gap findable at all.

## Suite claim

Ran `busted tests` once. Result: **1055 successes / 0 failures / 0 errors / 10 pending** —
matches the claim exactly. Confirmed.

## Findings

Most serious first.

### F0. "56 retired entries verified" undercounts — two pre-existing RETIRED entries were never walked by the sweep

**Claim as written** (`7727674f`'s message, and `S68-FIX-02-05-base-evidence.md`'s opening): *"56
entries walked (50 in `input.md`, 6 in `general.md` ... every earlier figure ... was right when
written) ... This supersedes every earlier count cited elsewhere (20/46/47/51/55) per the
commission — this is the one to use."* The commit message adds: *"no resolution claim failed."*

**What I ran**: counted `### ` headings under `## RETIRED` directly against the git blob at the
evidence commit itself (`7727674f`), the same method the doc describes
(`awk 'NR>=<header-line>' <file> | grep -c '^### '`), then cross-referenced against the evidence
doc's own per-entry list to see which headings it actually covers.

**What I found**: at `7727674f`, `input.md`'s `RETIRED` section has **51** entries, not 50;
`general.md`'s has **8**, not 6 (**59** total, not 56). Diffing the heading text (not just counts)
against the evidence doc's per-entry list identifies the gap precisely: two entries that exist in
the tree at `7727674f` are **absent from the evidence doc's list**:

- `input.md`: *"The guide and the CHANGELOG carried a migration from an `eval` key no project could
  write (RESOLVED, 2026-09-03)"* — added by `5bab6f4e`, a **direct ancestor** of `7727674f`
  (confirmed with `git merge-base --is-ancestor 5bab6f4e 7727674f`). Its insertion also explains why
  the evidence doc's entry-#1 citation `input.md:1331` (for *"A project cannot read the widget's
  content except at submit"*) is now stale — that entry sits ~34 lines lower in the `7727674f` tree
  because this uncounted entry landed above it.
- `general.md`: *"The changelog's version number has never been settled against the scale of the
  change (RESOLVED, 2026-09-03)"* (filed as `T-VERSION-NUM`) — moved from `ACTIVE` into `RETIRED` by
  `0ca356af`, likewise a **direct ancestor** of `7727674f` (same ancestry check). Read the diff
  directly: `0ca356af` deletes the `### T-VERSION-NUM` block from the file's `ACTIVE`-region
  (`general.md` old lines 33-45) and re-adds it verbatim, with a `Resolution` clause, under
  `## RETIRED`.

A third extra entry, *"The register's resolved entries claim resolution that was never verified"*
(`T-RETIRED-UNVER`), is legitimately absent from the sweep — it is the entry whose own resolution
**is** this verification pass, and `7727674f`'s own message says it retires it in the same commit
("`T-RETIRED-UNVER` is `RETIRED`... in this commit"), so it could not have been a subject of its own
sweep. I do not count that one against the claim.

The commission's own scope document (`S68-FIX-02-05-base-evidence-commission.md`) states the sweep's
scope plainly: *"everything under `## RETIRED`"* in both files, no cutoff date or pinned commit. The
two missed entries were both already under `## RETIRED`, via commits that are direct ancestors of
the commit that ships the "56, verified, no failures" claim — so by the time that claim was
committed, it was already false as stated: two RETIRED entries existed that the sweep never walked.
The likely mechanism is ordinary and not a competence failure — the delegated worker was probably
dispatched against an earlier tree snapshot, and `5bab6f4e`/`0ca356af` landed afterward, before the
parent committed the aggregate result — but the shipped claim does not disclose this, and the
"supersedes every earlier count... this is the one to use" framing asserts a completeness the commit
graph contradicts.

**Confidence**: high. Verified by three independent methods that agree: (1) direct `awk`/`grep -c`
recount against the exact git blob of the commit that ships the claim, using the doc's own stated
method; (2) heading-text diff against the evidence doc's explicit per-entry list, identifying the
two specific missing entries by name; (3) `git merge-base --is-ancestor` confirming both missed
entries' introducing commits are ancestors of the commit that asserts completeness. This is not a
reading of ambiguous prose — it is a reproducible count mismatch with named, located culprits.

### F1. "`project_env`'s keys went 23 → 17" understates HEAD's actual key count (20, not 17)

**Claim as written** (`ROADMAP.md`, FIX-02-17 row, and echoed in the commission): *"the check is a
set difference, not a grep — `project_env.*` assignments at `3256aac` against HEAD (23 keys →
17)"*.

**What I ran**: extracted every `project_env\.[A-Za-z_]+` assignment target from both revisions
directly:

```
git show 3256aac:src/controller/consoleController.lua | grep -oE "project_env\.[A-Za-z_]+" | sort -u | wc -l
git show HEAD:src/controller/consoleController.lua     | grep -oE "project_env\.[A-Za-z_]+" | sort -u | wc -l
```

**What I found**: base = **23** distinct keys, confirmed exactly as claimed. HEAD = **20**, not
17. The 20 = the 17 base keys that survived (23 minus the six removed: `user_input`,
`input_code`, `input_text`, `write_to_input`, `validated_input`, `astv_input`) **plus three new
keys added at HEAD**: `LuaHighlighter`, `LuaSyntaxValidator`, `LineValidators`. The same session's
own `b920eafa` commit message names these three explicitly ("LuaHighlighter, LuaSyntaxValidator
and LineValidators made the opposite trip, from accidentally reachable to deliberately exported")
— so the additions were known, just not folded into the "23 → 17" figure or the FIX-02-17 roadmap
row's arithmetic, which also never mentions them (it only notes "the `compy` namespace itself lost
nothing," which is a different, narrower claim than "`project_env` gained nothing").

Read as "17 of the base's 23 keys survived unchanged," the number is defensible. Read the natural
way — as a before/after delta of the *set's size*, which is how "23 keys → 17" and "23 down to 17"
both read on a first pass, and how the commission's own paraphrase ("`project_env`'s keys went 23
→ 17") reads — it is wrong: HEAD's `project_env` has 20 keys, not 17. Nowhere in the FIX-02-17 row,
across two commits (`b9978b11`, later amended in `b920eafa`) that both touch this exact row, is the
count of 20 (or the fact of +3) stated. A reader relying on the roadmap's own words would conclude
`project_env` shrank from 23 to 17 members; it shrank to 20.

**Confidence**: high that the raw counts (23 base, 20 HEAD, three additions, six removals) are
correct — verified by direct regex extraction against both git revisions, not by re-reading prose.
Lower confidence on whether this rises to "wrong" versus "incomplete phrasing the author would
defend as a survivor-count" — I flag it as a finding either way because the commission asked
specifically to re-derive this arithmetic, and the number that's actually printed in the shipped
roadmap text does not match the current tree under the most natural reading of the words used.

## Checked and found correct

- **`get_text()` implementation and its five tests** (`55adbfb3`, `41852371`). Read
  `build_widget_api`'s `get_text` (`src/controller/consoleController.lua:907-910`):
  `if not get_active_flag() then return nil end; return string.unlines(get_widget():get_text())`.
  The five `tests/input/input_cursor_text_spec.lua` cases (seated content, typed-not-submitted
  content, multiline join, empty-string, nil-when-hidden) match the implementation and match
  `doc/input_api.md`'s stated contract (`''` empty, `nil` hidden, `\n`-joined, round-trips through
  `set_text`) exactly. `string.unlines`'s join-with-`\n` behaviour is independently pinned by
  `tests/util/string_spec.lua:192-193` (pre-existing, not part of this session's diff). The
  frozen-shell case correctly gained a fourth assignment-raises assertion for `get_text`. No
  uncovered case found in the five.

- **"The four evaluator objects were reachable at base and are withheld now."** At base (`3256aac`),
  `InputEvalText`, `InputEvalLua`, `ValidatedTextEval` and `LuaEditorEval` are bare (non-`local`)
  globals in `src/model/interpreter/eval/evaluator.lua:157-168`, so `table.clone(getfenv())` would
  carry them into `project_env`; no withholding loop exists in `src/controller/consoleController.lua`
  at base. At HEAD, `src/controller/consoleController.lua:1273-1280` withholds exactly these four
  names via `for _, name in ipairs({...}) do project_env[name] = nil end`. Both halves confirmed
  directly.

- **`F.reset()` is eleven executable lines, not nine, with the specific line numbers given.** Read
  `tests/helpers/input_fixture.lua:325-357` in full and counted non-comment, non-blank lines by
  hand: exactly `:329`, `:330`, `:336`, `:340`, `:341`, `:342`, `:347`, `:348`, `:349`, `:350`,
  `:356` — eleven lines, matching the evidence doc's own line-number list precisely, not just its
  count.

- **Three spot-checked `PRE-EXISTING` entries in `S68-FIX-02-05-base-evidence.md`** (entries #11,
  #12, #27 of the nine). Entry 11 (`set_text`'s table branch: `InputText(text)`, no split) — read
  base `src/model/input/userInputModel.lua:128-145` directly, table branch is verbatim
  `elseif type(text) == 'table' then self.entered = InputText(text) end`, confirmed. Entry 12
  (string/table cursor-update asymmetry) — same base read confirms the string branch alone calls
  `self:_update_cursor(true)`. Entry 27 (`love.handlers.userinput` dead code) — `git grep -n
  "love.event.push('userinput')" 3256aac -- src` returns exactly one hit, at
  `userInputModel.lua:819`, matching the entry's own citation precisely, and zero hits at HEAD in
  the two files named. All three check out, including exact cited line numbers.

- **The `smoke_checklists.md` sweep: "25 grep hits, 21 sites, four are the help overlay."** Grepped
  the base file (`c610805b:doc/development/smoke_checklists.md`) for `field` (21 hits, case- and
  occurrence-insensitive — confirmed with both `grep -in` and `grep -io | wc -l`) and for
  `overlay`/`area` (4 hits, all four in the "D — the reserved chords and the help overlay" section,
  Alt+H). 21 + 4 = 25 exactly. At HEAD, all 21 `field` occurrences are gone (swept to `widget`) and
  all 4 `overlay` occurrences are untouched, verbatim. The arithmetic closes exactly, and the
  "sentence meaning preserved" spot-check on the visible diff hunks (`field`→`widget`,
  `open`/`active`→`shown`, "on an empty field"→"with nothing typed"/"with the widget empty") reads
  as faithful rewording, not a meaning change.

- **`internals/examples/turtle.md`'s corrected mechanism against `src/examples/turtle/main.lua`**
  (`a43632ac`). The doc's inline code sample (`arm_echo_guard`, `after_submit = arm_echo_guard`,
  `love.keyreleased` with `auto_hide = true` in the `show` table, `prompt = "TURTLE"`,
  `on_text_entered = function(text) eval(text) end`) matches `src/examples/turtle/main.lua:61-99`
  essentially verbatim. The corrected prose ("auto-hiding... a mode, not a one-off... set once at
  the `show`, in force for every submit after it") matches the actual code and the actual
  `after_submit` role (echo-guard re-arm only, not the close). The claim holds.

- **The revert/re-apply pair (`c013f07f`/`af3c8b14`), a self-disclosed failure mode.** `c013f07f`
  backs out a workflow-doc change (`agents/validation.md`'s three-step closing order) that had
  ridden along on the turtle-doc commit (`a43632ac`, via `git add -u`) under a message that said
  nothing about it. Diffed both commits: the revert removes exactly what the turtle commit added
  (byte-identical block), and `af3c8b14` re-adds the identical 29-line block under its own,
  accurately-titled commit. Final `agents/validation.md` has exactly one copy of the section
  (`git grep -c` = 1), no duplication. Clean self-correction, handled the way the project's own
  commit rules ask (no `--amend`, a visible trail).

- **Three specific line/name citations, spot-checked as exact-text resolution (not just
  existence), per the commission's "citation that resolves to the wrong thing" trap:**
  `controller.lua:67` (CHG-01-03's claim, `xpcall(f, user_error_handler, ...)`) — resolves exactly.
  `user_pointer` "sits at `:40`, set at `:253` and `:261`" (F2 commit `3b879746`) — resolves
  exactly (`local user_pointer` at 40, `user_pointer = true` at 253 and 261).
  `chain_project_handler` "no longer exists at all" — zero hits in `src` via `git grep`, only the
  debt-doc's own sentence naming its absence; `project_handler(userlove, key)` (the claim's other
  half) matches `controller.lua:188` exactly.

- **The example-README drift (`51264e3a`, `T-EXAMPLE-README`/`FIX-02-27`).** Claim: both
  `src/examples/repl/README.md` and `src/examples/valid/README.md` still teach `user_input()`,
  `input_text()`, `input_code()`, `validated_input()`. `git grep` on both files confirms all four
  names present as claimed (repl: `user_input()`, `input_text()`, `input_code()`; valid:
  `user_input()`, `validated_input()`).

- **`FIX-02-07`'s marker recount ("34 across 12 files"), checked against the exact stated command
  at the exact commit that makes the claim.** `git grep -c` for `REMARK:|REVIEW:` under `doc`
  (excluding `wip`) at `7e1bc94a` gives exactly 34 hits across 12 files, matching the roadmap cell
  precisely. (At current HEAD the same command gives 32 across 11 — two markers were legitimately
  resolved by the later `CHG-01-04` commit, `0ca356af`, which names both explicitly. The roadmap
  cell's own wording — "was 37; re-count when the row opens" — does not claim to track HEAD live,
  so this drift is not a finding.)

- **`FIX-02-05`'s classification arithmetic sums correctly**: `39` introduced-in-branch `+ 9`
  pre-existing `+ 5` mixed `+ 3` cannot-tell `= 56` (the count the doc itself claims to have
  walked), and the by-file breakdown also sums correctly (`general.md`: `5 + 1 = 6`; `input.md`:
  `34 + 9 + 4 + 3 = 50`). The internal arithmetic of the classification is consistent — the problem
  identified in **F0** is that the base count of 56 itself is short two entries, not that the
  percentages/sums built on top of it are wrong.

- **Retired-entry convention (claim 9).** Entries that had a prior separate filing (`T-VERSION-NUM`,
  `T-RETIRED-UNVER`, `T-CONTENT-READ`) all open with *"Filed as `T-XXX`. Everything down to
  **Resolution** is the filing as written,"* followed by the original filing fields unchanged and
  then a `Resolution` field — convention followed. Entries with no prior filing — found and fixed
  in the same motion (the turtle.md doc-drift entry, the four-evaluator-objects/CHANGELOG entry,
  the `eval`-key migration entry) — consistently use a parallel but distinct shape (`Where` /
  `State` / `Found...` / `Resolution` / `Provenance`, no `Filed as` line) across all three
  instances I read in full. This is a legitimate variant, not a violation: the convention's point
  is preserving an *existing* filing unchanged, and these entries never had one to preserve.

## Not verified

- **The full 51 entries of `input.md`'s `RETIRED` section and all 8 of `general.md`'s** were not
  each individually re-checked by me — I spot-checked three of the nine `PRE-EXISTING` proposals
  (all three held, including exact line citations) and separately located the two entries the
  sweep skipped (**F0**), but did not re-derive resolution-at-HEAD or presence-at-base for the
  other ~44 entries the evidence doc does cover. The commission asked for a spot-check of three; I
  did that, plus the coverage-gap check, and stopped there by design.

- **The roadmap's full tick sweep** (claim 8) — I read and spot-checked the `FEAT-03`, `FIX-02-17`,
  `FIX-02-07`, `CHG-01-01` through `-04`, and `FIX-02-05` cells in detail (all specific citations
  within them checked out, aside from the `23 → 17` figure in `FIX-02-17`, **F1**). I did **not**
  read every ticked cell across the ~217-line `ROADMAP.md` diff — `FIX-02-03`, `-04`, `-06`, `-13`,
  `-22` are marked complete from **earlier** sessions and were only touched by this session for
  citation-sweep purposes, not re-verified by me as a description of what those earlier sessions
  did.

- **`get_text`'s underlying `string.unlines` and `get_widget():get_text()` implementation** — I
  confirmed `string.unlines` joins with `\n` via the pre-existing `tests/util/string_spec.lua`
  spec (not part of this session's diff) rather than reading its definition, which I could not
  locate anywhere under `src/` by name (`git grep -n "unlines" -- src` returns only call sites,
  never a definition — it must be a monkeypatch or C-side extension outside the paths this
  commission scoped me to). This does not affect confidence in the `get_text` claim itself (the
  join behaviour is independently pinned by an existing, passing test and by `get_text`'s own five
  new tests), but I could not trace `string.unlines` to its source.

- **The twelve resolution claims the evidence doc itself flags as not independently re-derived**
  (listed in its own "Entries whose resolution claim... could not be fully confirmed" section) —
  I did not attempt to re-derive any of these; the evidence doc is honest about the gap and I take
  it at face value rather than re-doing the same-scoped work.

- **`lua-lsp` was not used.** Every claim in this review was checkable by direct `git show`/`git
  grep`/`git diff` against specific commits and line numbers, which the commission's own examples
  favour, and grep-based verification was sufficient and more directly auditable for a diff-integrity
  review than an AST query would have been. No `references`/`definition` call was made, so I have
  no `broken pipe` or false-negative incident to report from this session.

- **Everything outside the `c610805b..HEAD` range** — base-commit (`3256aac`) reads were done only
  as comparison points for claims made in-range; I did not independently audit anything the base
  evidence doc inherited from earlier sessions beyond the specific spot-checks and the coverage-gap
  check above.
