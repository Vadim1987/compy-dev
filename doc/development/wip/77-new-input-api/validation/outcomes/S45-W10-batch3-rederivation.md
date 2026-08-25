# S45 — W10 batch 3 (comment bloat) re-derived

**Author:** session45 sub-agent (Sonnet), read-only over the repo except this
file. **Commission:** `../prompts/S45-W10-batch3-rederivation.md`.

**Universe used.** The appendix line in `../reviews/S27-triage-and-plan.md`
(`W10 every id not listed above (92): …`) is labelled `(92)` but its own
token list, extracted verbatim (`grep -oE 'R[0-9]{3}'` over lines 727–733,
deduplicated), contains **85** distinct ids, not 92. Cross-checked
independently: summing every other workstream's membership (W1 10, W2 6, W3
6, W4 9, W5 7, W6 3, W7 19 — 20 named in W7's prose minus R044, which the
appendix itself moves to W6 — W8 16, W9 16, W11 10) against the 187 total
gives `187 − 102 = 85`, the same number. The `(92)` label is stale — most
likely a leftover from before the two-in/two-out swap the same revision
records (`R081`, `R088` out to W9; `R110`, `R135` in from W9), which is
net-zero and would not by itself explain the gap, but the label was not
recomputed at any point on record. Per the prompt's instruction to "use that
list verbatim as your universe," **the 85-id list is what was worked**, not
92. This is a bookkeeping fact about the source document, not a finding
about the code, and is flagged here rather than silently reconciled.

---

## 1. Headline numbers

- **W10 universe (verbatim list):** 85 ids (not 92 — see above).
- **Batch 3 (comment bloat), confidently classified:** **23** ids.
- **Not batch 3, confidently classified:** **57** ids.
- **Disputed / could not classify confidently:** **5** ids.
- 23 + 57 + 5 = 85. ✓

Of the 23 batch-3 ids:

- **Live marker still present:** **21**
- **Live site, marker gone:** **0**
- **Gone entirely (marker and the described bloated text both gone):** **2**
  (`R032`, `R046`)

21 + 0 + 2 = 23. ✓

**A gate caveat found in passing:** the standing gate
(`grep -rniE 'INTERIM|REMARK' src/ tests/ --exclude-dir=lib
--exclude=words_corpus.lua`) returns 23 hits today, confirmed. But one live
batch-3 marker — `R034` (`src/controller/controller.lua:527`) — reads
`---> comment describing what code does NOT do is absolutely of no use;
delete if it has no positive info` and contains neither the literal string
`REMARK` nor `INTERIM`. The gate misses it for the same reason session36
found it missing colon-less `REMARK`s in P11: a gate that matches on the
marker word cannot see a marker that doesn't use that word. It was found here
only because its text is quoted in the inventory and grepped for directly.
Reported as a fact about gate coverage, not a fix.

---

## 2. The live table (batch 3, still has work attached)

One row per batch-3 id with a live marker or site. Ordered by file. Every
line number below was read from the file today; none are copied from the
inventory.

| id | current file:line | what the remark asks | marker present? | note |
|---|---|---|---|---|
| R085 | `doc/development/decisions/input.md:159` | "consuming is not removing" defends against a misconception nobody held; remove the whole paragraph | yes (unchanged line) | classified batch 3 as "why is this comment here at all" |
| R091 | `doc/development/decisions/input.md:234` | drop the "conflating them is a trap" self-justification; just state that the two directions are distinguished | yes (unchanged line) | same class as R092/R100 below — unnecessary defensive prose, not an explicit "too verbose" complaint |
| R092 | `doc/development/decisions/input.md:235` | this "Why" block (incl. the "student" passage) over-explains a normal engineering decision; trim it | yes (unchanged line) | explicit "too much self-invented explanation" |
| R100 | `doc/development/decisions/input.md:410` (was `:444` — file shifted -34 lines, other editorial work already landed above it) | the "no X, no Y, no Z" list reads as defending against alternatives nobody proposed | yes | same defensive-prose class as R091/R092 |
| R143 | `doc/development/internals/user_input.md:211` (was `:207`) | the paragraph below is too big and unreadable; simplify/compress or dissolve | yes | explicit verbosity complaint |
| R150 | `doc/development/internals/user_input.md:462` (was `:440`) | the paragraph below is heavy and unreadable; rewrite | yes | explicit verbosity complaint |
| R162 | `doc/development/internals/user_input.md:725` (was `:701`) | the "one vestige... `love.handlers.userinput`" paragraph is confusing archeology; remove it | yes | "serves no purpose except confusion" — "why is this here" class |
| R164 | `doc/development/internals/user_input.md:744` (was `:720`) | trim this section to state only what `compy.input` is and where it's built/described, not restate the API's shape (duplication) | yes | |
| R001 | `src/controller/consoleController.lua:135` (was `:134`) | the doc-comment above `default_before_exit` doesn't match the code AND is too verbose | yes | **also asks for a factual correction** — comment/code mismatch, not only length |
| R003 | `src/controller/consoleController.lua:181` (was `:144`) | same comment as R001/R002: state only the invocation context, not a re-explanation; "prose length is x5 longer than code length" | yes | |
| R034 | `src/controller/controller.lua:527` (was `:528`) | the "Straight to the console, with no widget test in front of it" comment is phrased as what the code does NOT do; delete if it has no positive info | **yes — but see gate caveat above** | marker text contains neither `REMARK` nor `INTERIM`; standard gate misses it |
| R050 | `tests/helpers/input_session.lua:1` (unchanged) | simplify the file-header comment; drop the "what it is not" contrastive framing | yes | |
| R051 | `tests/helpers/input_session.lua:13` (was `:12`) | simplify `emitters()`'s comment to a one-liner about exposing an API to invoke LÖVE events via handlers | yes | |
| R052 | `tests/helpers/input_session.lua:39` (was `:32`) | simplify `new(CC)`'s comment to a one-liner: it installs the real gate into a fresh `love.handlers` | yes | |
| R054 | `tests/input/highlight_regression_spec.lua:2` (unchanged) | simplify the file's prose and describe the actual behavioural bug path, not an internal-only check | yes | **also asks for a content/framing correction**, not only length |
| R056 | `tests/input/history_spec.lua:72` (unchanged) | is the comment above this history-navigation test even needed? code reads as self-explanatory | yes | "why is this comment here at all" |
| R065 | `tests/input/input_widget_callbacks_spec.lua:729` | dry up the file's prose; make test cases more self-evidently readable | yes | file moved: was `tests/input/input_lifecycle_uniform_spec.lua:2` — that file no longer exists, content merged (per plan §"P8", four input specs → two) |
| R071 | `tests/input/input_shortcuts_click_spec.lua:6` (unchanged) | the file-header prose looks copy-pasted from elsewhere and is "very excessive" | yes | |
| R072 | `tests/input/input_widget_control_spec.lua:4` | file-header prose seems copy-pasted, without much relevance to this suite | yes | file renamed: was `tests/input/input_widget_lifecycle_spec.lua:4` — old name no longer exists |
| R076 | `tests/input/input_widget_callbacks_spec.lua:5` | remove the copy-pasted, irrelevant prose that follows | yes | file renamed (plural → singular): was `tests/input/input_widgets_callbacks_spec.lua:8` |
| R077 | `tests/input/input_widget_callbacks_spec.lua:27` | this prose looks like another copy-pasted artifact; distill to only what's relevant | yes | same file rename as R076 (was `:29`) |

---

## 3. The discharged list (marker and site both gone)

- **R032** — `src/controller/controller.lua` (was `:1070`). Original
  complaint: the comment above the `mousepressed`-family handler explained
  what the code does *NOT* do ("Pointer has NO three-consumer chain: this is
  an unstructured broadcast...") and was stale. Neither that text nor any
  `REMARK`/`INTERIM` marker exists anywhere in the tree today (checked with
  `grep -rn` for both the marker and the distinctive phrase "unstructured
  broadcast" / "NO three-consumer"). The handler's comment was rewritten
  entirely: it now reads (lines 912–914) "The gateway entry: hand the event
  to whoever occupies the slot. Under a project run that is the project
  route's chain; otherwise the console's own handler." — current, short,
  positive-framed. Evidence the original text is gone, not merely
  unmarked: a fresh grep for its exact wording returns nothing tree-wide.

- **R046** — `src/model/input/userInputModel.lua` (was `:840`, marker typo
  `REMARL`). Original complaint: the doc-comment above the
  `_apply_eval` cursor-seating helper was verbose; compress it. Neither
  `REMARL` nor `REMARK` appears anywhere in the file (checked with
  `grep -rn "REMARL" src/ tests/ doc/` — the only hits left are in the
  inventory document itself, not in code). The comment at the site today
  (lines 839–843) is four lines: `--- @private`, `--- On a reject, seat the
  cursor on the error position.`, plus two `@param`/`@return` tags — already
  short. Whether this is the result of a deliberate compression pass or was
  simply always this size cannot be determined from the tree alone (the
  inventory doesn't quote the pre-remark comment), but both the marker and
  any verbose form of the comment are absent today.

---

## 4. Disputed or ambiguous

Five ids where the remark's own wording did not cleanly separate "the
comment is too long/unnecessary" (batch 3) from a different kind of ask.
Not guessed; both readings are stated.

- **R048** — `tests/editor/editor_spec.lua:715` (live marker, unchanged
  line). Text: *"rewrite and simplify prose: 'later' is no more relevant
  when feature is delivered. Just 'guards compatibility of block navigation
  with widget's internal limits processing'"*.
  - **Reading A (batch 3):** "simplify prose" is explicit, and the suggested
    replacement is offered as a one-liner.
  - **Reading B (not batch 3 — W10 batch 2, historical contrast):** the
    complaint's substance is that "later" describes an intermediate,
    now-shipped state ("no longer relevant... feature is delivered"), which
    is exactly the "no longer / used to" pattern the triage document assigns
    to batch 2, not batch 3. The suggested replacement is not materially
    shorter than the original.

- **R053** — `tests/input/highlight_regression_spec.lua:1` (live marker,
  unchanged line). Text: *"remove references to input API release cycle,
  completely. its just a regression test accompanying bugfix"*.
  - **Reading A (batch 3):** "remove... completely" reads as the "why is
    this here at all" pattern the task description names as in-scope.
  - **Reading B (not batch 3):** the stated reason is that the content is
    contextually wrong for what the file is (a bugfix regression test, not
    release-cycle-scoped content) — a relevance/accuracy correction, not a
    length complaint. Nothing in the remark says the release-cycle text is
    long.

- **R138** — `doc/development/internals/user_input.md:135` (live marker; not
  independently re-verified line-by-line beyond the grep above, which shows
  it unchanged in substance at line 135). Text: *"'project overlay' ->
  'project input widget'. This paragraph has to be rewritten into more
  readable form and actualized (i.e. project now can set prompt)"*.
  - **Reading A (batch 3):** "more readable form" could mean shorter/denser.
  - **Reading B (not batch 3):** the remark is dominated by a vocabulary
    swap (batch 1/4) and a factual actualization — the paragraph must
    additionally say a project can now set its own prompt, which is new
    content, not a trim. "More readable" reads as a general quality
    instruction attached to that rewrite, not a standalone bloat complaint.

- **R163** — `doc/development/internals/user_input.md:734` (live marker;
  same line as inventory, `:710` in the inventory's numbering — file has
  shifted, confirmed present via grep above at current line 734). Text:
  *"hook names are actual I hope. Formula still sounds weird. And I am not
  sure what paragraph tries to communicate -- remove it?"*
  - **Reading A (batch 3):** "not sure what... tries to communicate --
    remove it?" matches "why is this comment here at all."
  - **Reading B (not batch 3):** the remark opens with a factual-accuracy
    question ("hook names are actual I hope") — it is at least partly asking
    for verification/correction of content, with removal offered only as one
    of three reactions (accuracy check, phrasing complaint, removal
    proposal), not a clean verbosity complaint. The inventory's own
    "Provisional kind" for this entry is "unclear (mixes...)," which is the
    same judgment.

- **R173** — `doc/input_api.md:164` (not independently line-checked beyond
  the extraction; classification-only dispute, no state check performed
  since it is not confidently batch 3). Text: *"why developer would even
  think of reading love.state?"*
  - **Reading A (batch 3):** could be read as "why is this warning here at
    all" — questioning whether the whole cautionary paragraph is needed.
  - **Reading B (not batch 3):** more plausibly a genuine content question —
    asking the doc to explain *why* a developer might be tempted to read
    `love.state`, i.e. requesting the warning be motivated, not removed or
    shortened. The inventory's own "Provisional kind" is "question," and
    nothing in the remark's wording asks for less text.

Per the task's instruction, no state check (marker/site liveness) was
performed for these 5 — they are not classified as batch 3, and the task
only calls for state on ids classified into that bucket.

---

## Note on the 57 ids classified "not batch 3"

Not individually enumerated here — the task's deliverable structure asks
only for headline counts plus the live/discharged/disputed detail on the
batch-3 subset. The excluded 57 fall into recognizable non-batch-3 buckets
already named by the triage document itself (vocabulary/overlay-retirement
already covered by W10 batches 1/4; "no historical contrast" phrasing
covered by W10 batch 2 — e.g. `R082`, `R083`, `R103`, `R104`, `R108`, `R110`,
`R113`, `R139`–`R142`, `R144`, `R149`, `R156`, `R157`, `R159`; plain factual
corrections such as `R007`, `R049`, `R055`, `R087`, `R101`, `R106`, `R117`,
`R135`, `R147`, `R153`; and content-addition asks such as `R126`, `R151`,
`R175`, `R180`, `R182` which ask for *more* text, the opposite of bloat).
