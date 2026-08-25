# S45 — P11 inventory: every site the row owns

**Written before any comment was edited**, which is the point of it: session44
found two of P10's four "remaining" members already done or already ruled, and
the only reason that was cheap is that they were checked before they were
worked. This document is the same check applied to the largest row in the sprint.

Measured 2026-08-25 at HEAD `1be0d310`. Line numbers are current, not inherited.

## 0. The gate, and what it can and cannot see

```
grep -rniE 'INTERIM|REMARK' src/ tests/ --exclude-dir=lib --exclude=words_corpus.lua
```

23 hits. The exclusions are the owner's ruling of 2026-08-25 (`547c30c6`) and
cover content we did not author: vendored libraries, and the Alice-in-Wonderland
prose corpus the `keyboard` example types against, where *"she remarked"* is a
line of a story.

**One of the 23 is not a marker and stays:** `src/examples/keyboard/help.lua:6`
— *"Alt+H is the interim help chord (F-keys are blocked on current hardware)"* —
is the example author's own comment, introduced in `c9b4e1b` (dsent,
2026-06-09), months before this feature touched that repo. Its claim is true:
`doc/development/keyboard.md` marks F1–F9 unavailable on the device. **22
markers, therefore, and the gate reads 23 when clean.**

The same false-positive shape exists in the docs: three prose uses of the word
"remark" in `technical_debt/input.md` are not markers. Excluding them, the doc
corpus holds **70** markers, which confirms plan §17.5's census exactly.

## 1. What P11 owns — six parts, and only two of them were ever sized

| # | Part | Size | Sized before today? |
|---|---|---|---|
| A | Markers in `src/` + `tests/` | **22** | yes (§17.5) |
| B | Markers in `doc/input_api.md` | **8** | yes — but assigned to **P10**, which closed without them |
| C | Factual markers in the dev-facing docs | **12** | no — derived here from the S36 table |
| D | W10 batch 2 — historical contrast | **~22 sites** | as a cluster, not as a list |
| E | W10 batch 3 — comment bloat | re-derivation running | **no** |
| F | Example-repo comment compaction | **157 comment lines** in `maze`/`draw` | **no** |

Parts B and C are the finding of this inventory and are argued in §3.

## 2. Part A — the 22 markers in `src/` and `tests/`

Kinds: **F** = the comment states something false, **B** = bloat / compression
ask, **V** = vocabulary, **Q** = a question to the owner, **S** = a structural
proposal about the suite. Disposition per §17.5: **every one of these goes** —
resolved into a payload-carrying comment, acted on and deleted, or promoted to a
durable record.

| where | kind | what it asks |
|---|---|---|
| `src/controller/consoleController.lua:135` | F+B | comment does not match the code, and is too verbose |
| `src/controller/consoleController.lua:180` | V | retire "overlay"; `input_widget_overlay` if the console context needs the word |
| `src/controller/consoleController.lua:181` | B | prose is 5× the length of the code it describes |
| `src/controller/consoleController.lua:473` | F | not *where the event goes* but *whether it propagates* |
| `src/examples/balloons/terminal.lua:4` | Q | can the deliver-handler setup be one function instead of three? (its second half — an `update_prompt` endpoint — is **already ruled and recorded** in `technical_debt/input.md`, "An `update_prompt` endpoint was asked for and declined") |
| `tests/editor/editor_spec.lua:715` | B+F | "later" is not relevant once the feature is delivered; simplify |
| `tests/helpers/input_fixture.lua:200` | F | "console route forwards…" is no longer true; only the rendering half is |
| `tests/helpers/input_session.lua:1` | B | simplify; do not narrate what the helper is |
| `tests/helpers/input_session.lua:13` | B | say it exposes an API to fire `love` events through the handlers |
| `tests/helpers/input_session.lua:39` | B | say it invokes the production function that connects controller to LÖVE |
| `tests/input/history_spec.lua:72` | B | is this comment needed at all? |
| `tests/input/highlight_regression_spec.lua:1` | B | drop the input-API release-cycle framing entirely |
| `tests/input/highlight_regression_spec.lua:2` | **S** | describe the **behavioural** bug path (a project supplying X gets an exception on Y), not the internal check |
| `tests/input/highlight_regression_spec.lua:3` | **S** | acceptance criterion is "does not break the way it used to", not "highlight stays indexable" |
| `tests/input/input_cursor_text_spec.lua:1` | **S** | reorganise the suite into three named groups (inbound interception / widget management / widget-originated events) |
| `tests/input/input_events_spec.lua:194` | Q | does the interception-matrix block supersede the dispatch tests above it? |
| `tests/input/input_shortcuts_click_spec.lua:6` | B | preamble recites routing rules the suite does not test, and is excessive |
| `tests/input/input_widget_callbacks_spec.lua:5` | B | remove copy-pasted irrelevant prose |
| `tests/input/input_widget_callbacks_spec.lua:27` | B | artefact prose from elsewhere; distil to what is relevant |
| `tests/input/input_widget_callbacks_spec.lua:729` | B | dry up the prose; make the cases self-evident |
| `tests/input/input_widget_callbacks_spec.lua:730` | V | avoid "overlay" entirely — "project input widget" |
| `tests/input/input_widget_control_spec.lua:4` | B | preamble copied from elsewhere, little relevance here |

**Three of these are not comment work** and must not be swept as if they were.
`highlight_regression_spec.lua:2` and `:3` ask for the test's *framing* to change
— a behavioural rewrite of what it asserts — and `input_cursor_text_spec.lua:1`
proposes reorganising the suite into three named groups. The first two are a
small unit of test work; the third is a structural proposal whose neighbourhood
was already reworked (see `../notes/2026-07-31-construction-named-specs.md`) and
which needs an owner call before anyone moves a `describe`. **Raised, not
assumed.**

Two are questions the owner asked and only the owner can close
(`input_events_spec.lua:194`, `balloons/terminal.lua:4`).

## 3. Parts B and C — what P10 closed over

**P10 was declared closed in session44 (§17.4) on the strength of its named
members** — the reserved-combo section, W10 batches 1/2/4, the flag-shortcut
defect, W9(a), W9(b). Its scope also included, in the plan's own words,
*"this sprint's share of the marker question (§16.2)"*, and
`../outcomes/S36-marker-disposition.md` is the binding table that resolves what
that share is. Against that table, P10 closed with **20 markers of its own still
standing**.

### Part B — `doc/input_api.md`, 8 markers, all P10's, none cleared

S36's rule for this file is not split by kind: *"SPRINT (P10) for every kind"* —
it is the one document a stakeholder is promised, and §17.5 restates it as
**every marker goes**.

| where | kind | what it asks |
|---|---|---|
| `:11` | prose | rewrite the intro to be dev-friendly: an API for configuring and interacting with text solicitation, and for reacting to input events — usable for hotkeys even when the widget is never shown |
| `:17` | **structural** | should the guide say the API is three surfaces — dispatch/intercept, widget state, widget-originated callbacks? (matches R172, accepted in principle) |
| `:165` | question | why would a developer think of reading `love.state` at all? |
| `:258` | vocabulary | retire "overlay" — *"stop reaching the input widget too"* |
| `:372` | vocabulary | "input widget", not "overlay" |
| `:373` | prose | frame the section as solving an unconventional problem (a modifier hotkey echoing into the widget), not as a recommended convention |
| `:403` | vocabulary | "re-arm" is invented — define it upfront or drop it |
| `:572` | **answered** | S36 verified both halves already done (R181); this one is a deletion, not an edit |

**This is the PR's own promise.** The stated frame is that the PR must be
reviewable from `doc/input_api.md` plus the description alone. Shipping that
document with eight owner review remarks still in it fails the frame on its face,
and `:11`/`:17` are not sweep-sized: one is an intro rewrite, the other a
question about the guide's top-level structure.

### Part C — the dev-facing docs: 12 factual markers, P10's by kind

S36's split for `internals/user_input.md` and `decisions/input.md`: **factual →
SPRINT (P10)**, editorial → PARENT. The factual ones still standing, verified
present today:

| where | what is wrong |
|---|---|
| `internals/user_input.md:12` | says the widget is "shared"; four separate `UserInputController` instances exist |
| `internals/user_input.md:13` | "both now run" is true of the project route only |
| `internals/user_input.md:48` | "defining its own" is a compatibility layer — those functions are reinstalled as hooks |
| `internals/user_input.md:135` | paragraph is stale on a real capability (a project can set the prompt) |
| `internals/user_input.md:240` | the next paragraph describes `forward_*` calls; **no such function exists in the tree** |
| `internals/user_input.md:309` | claims an in-code `DEFERRED` marker records something; **no `DEFERRED` marker exists** |
| `internals/user_input.md:559` | "removed" understates it — the firing was *repositioned* onto `love.handlers.*` |
| `decisions/input.md:120` | Decision 2's "three components" excludes pointer, which runs the same dispatch (R081) |
| `decisions/input.md:173` | the short-circuit framing is not the implementation, which is an `if` chain |
| `decisions/input.md:192` | "same code" is not "same instance"; the prose is pre-implementation vision |
| `decisions/input.md:411` | Decision 10's framing understates that this is now universal |
| `decisions/input.md:838` | `ignore_repeat` is `keypressed`-specific, since `isrepeat` is a `keypressed`-only argument (an addition, not a correction — S36 marks it UNSURE) |

Two of these (`:240`, `:309`) are the same defect class this phase exists to
catch: **a persistent doc describing a mechanism the code does not have.**

R086 (`decisions/input.md:167` in the S36 table) is **gone** — cleared since,
correctly.

### What I recommend, and it is the owner's call

**P11 absorbs Parts B and C rather than reopening P10.** P11 is the last row
before slice regeneration, its gate already demands zero markers in the guide's
neighbourhood, and reopening a row that was closed on its named members would
re-litigate a closure that was correct on its own terms. What was wrong is not
the closure — it is that the marker share was never anybody's concrete list.
This document is that list.

## 4. Part D — W10 batch 2, historical contrast

Ruled into P11 in session44 (§17.1). The sites are already enumerated as
**Cluster B, 22 markers**, in `../outcomes/S36-marker-disposition.md` §"Cluster B
— No historical contrast / hallucination-residue". Not re-listed here: the
binding table is the list, and re-deriving it would be the exact tax §17.1
refused to pay. The rule is the owner's: **if it was not in a released version,
write as if it never existed.**

## 5. Part E — W10 batch 3, comment bloat

Never enumerated by anyone; the "~50 ids" figure is a guess inherited from the
S27 triage. Re-derivation commissioned to a Sonnet worker
(`../prompts/S45-W10-batch3-rederivation.md`), deliverable
`S45-W10-batch3-rederivation.md`. **Numbers land here when it returns.**

The expectation to hold lightly: most of those ids' markers are already gone
from the tree — only 22 markers survive in `src/`+`tests/` — so batch 3's live
remainder is likely far smaller than 50, and the value of the pass is knowing
*which* remainder, not the count.

## 6. Part F — the example repos, measured for the first time

**`maze` (which contains `draw`).** Our input migration is ten commits,
`ca7210d`…`c23cb59`, over the base `b8cc436`. They add **280 lines, of which 157
are comment lines** — 56% of everything the migration wrote into that repo:

| file | comment lines added |
|---|---|
| `maze_main.lua` | 67 |
| `draw_main.lua` | 38 |
| `core_editor.lua` | 32 |
| `macro.lua` | 15 |
| `maze_plan.lua` | 5 |

That is the compaction target, and it is the honest one: **only what our work
wrote.** The repo's own comments belong to its authors (`Vadim1987`, `Vadim`,
`dsent`, `Daniel A. Nagy`) and are not ours to compress.

**`balloons`.** No comparable body: the repo is entirely owner-authored, our
migration added little comment volume, and its whole P11 debt is the one marker
in `terminal.lua:4`.

**`keyboard`.** Done in-step as `P-18-10` (177 → 101 comment lines in
`input.lua`; it stands at 105 today). It is the model for ambition — **and it was
self-assessed.** No cold reader ever checked that no argument was lost, so it is
not evidence that the method is safe.

## 7. The order this should run in

1. **Owner call on Parts B and C** — who owns them, and whether `input_api.md:11`
   and `:17` are in scope or deferred as a named list. Everything else can start
   without it.
2. **Part A's three non-comment items** raised for a ruling
   (`highlight_regression_spec.lua:2,3`; `input_cursor_text_spec.lua:1`) and the
   two questions answered (`input_events_spec.lua:194`,
   `balloons/terminal.lua:4`).
3. **Part A's remaining 17**, file by file — the bulk, and mechanical once the
   rule is fixed.
4. **Parts B, C, D** in the docs, factual before editorial.
5. **Part F**, the `maze`/`draw` 157 lines, last of the editing work — an
   example's comments are the least load-bearing thing in the delivery and the
   most likely to be revisited by its own smoke pass.
6. **Re-run the gate**, then hand to slice regeneration.

Throughout, the floor from `agents/rules/commenting.md` (2026-08-25): **a
reference is not an annotation** — every citation keeps at least a clause saying
what is true here. And the standing rule that made this cheap in session44: any
rationale a compaction removes must already exist in the persistent corpus, or
land there first.
