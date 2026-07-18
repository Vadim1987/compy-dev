# A1 — spec-reference sweep

Sweep of `{badspecref: …}`-flagged (and a few plain `wip/`-pointing)
comments in `src/` and `tests/`, per `subagent-A1-prompt.md`. Every
flagged reference was inspected in context and either (1) fixed to
cite the persistent docs corpus with a named, real section, or (2)
left untouched and inventoried here because no persistent home
exists for it. `design/`, `src/examples/*`, and the other
owner-scratch paths listed in the task were not touched. No files
were staged or committed.

Persistent corpus used as fix targets:
- `doc/input_api.md`
- `doc/development/internals/user_input.md`
- `doc/development/decisions/input.md`
- `doc/development/technical_debt/input.md`
- `doc/development/tests.md`

## Fixed

Grouped by target section; each row's "old ref" is the tag content
that was replaced (file:line = the tag's first line after the fix).
Where several occurrences shared one target and file, lines are
comma-listed.

### src/util/key.lua

| file:line | old ref | new ref |
|---|---|---|
| key.lua:25,53,71 | `spec §1`, `spec §1` + `R14` | decisions/input.md, Decision 8 |

### src/controller/projectInputController.lua

| file:line | old ref | new ref |
|---|---|---|
| :8 | `spec §2` | decisions/input.md, Decision 2 |
| :12 | `spec §5` | decisions/input.md, Decision 6 |
| :16-17 | `R14`, `§1` | decisions/input.md, Decision 8 |
| :20 | `R7` | decisions/input.md, Decision 10 |
| :29 | `R13` | decisions/input.md, Decision 2 |
| :30 | `R12` | decisions/input.md, Decision 5 |
| :49,53 | `spec §5, AC-26`, `spec §5 scope note` | decisions/input.md, Decision 6 |
| :67 | `AC-20` | internals/user_input.md, "Submit and cancel — the framework tier-1 chains" |
| :76 | `spec §5, AC-17/20/21` | internals/user_input.md, same section |
| :94 | `spec §5, AC-19/20/21` | internals/user_input.md, same section |
| :111 | `spec §5` | internals/user_input.md, same section |
| :144,147 | `spec §8 R7`, `AC-10` | decisions/input.md, Decision 10 |
| :174 | `AC-11/13` | decisions/input.md, Decision 2 |
| :176 | `R12` | decisions/input.md, Decision 5 |
| :210 | `R7` (pure wrap) | decisions/input.md, Decision 10 |
| :224 | `AC-27/29` | decisions/input.md, Decision 11 |
| :241 | `AC-27, ratified-model ruling 3` | decisions/input.md, Decision 11 (the "ratified-model ruling 3" sub-citation had no persistent equivalent and was dropped, not preserved) |
| :250 | `0.1.0-m5` | technical_debt/input.md, "Combo-tier key-repeat semantics are shipped unsettled" |

### src/controller/controller.lua

| file:line | old ref | new ref |
|---|---|---|
| :34 | `spec §2`, `AC-8` | decisions/input.md, Decision 9 and Decision 13 |
| :74 | `ruling a` | technical_debt/input.md, "Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)" |
| :170 | `C3/C14` | decisions/input.md, Decision 2 |
| :201 | `R7` | decisions/input.md, Decision 10 |
| :376-378 | `0.1.0-m5 (three-level dispatch)` + `implementation/reviews/M2-human-review.md (A6)` | technical_debt/input.md, "Combo-string dispatch allocates a table per call" |
| :393-394 | `spec §1`, `AC-8` | decisions/input.md, Decision 13 |
| :453 | `Decision 8` (already correct, mis-wrapped) | decisions/input.md, Decision 8 (unwrapped) |
| :775 | `ruling a` | technical_debt/input.md, same ruling-a section |
| :793-794 | `AC-27`, `AC-28` | decisions/input.md, Decision 11 |

### src/controller/consoleController.lua

| file:line | old ref | new ref |
|---|---|---|
| :262 | `ruling a` | technical_debt/input.md, ruling-a section |
| :369-374 | `spec §7 / R3`, `chunk 2`, `chunk 3, AC-26/33`, `AC-33` | decisions/input.md, Decisions 5/6/7 (split per clause; see diff) |
| :396,399 | `R3`, `AC-33` | decisions/input.md, Decision 7 |
| :424-428 | `D-b`, `M5c`, `M7` | decisions/input.md Decision 5; doc/input_api.md "Sticky callbacks"; internals/user_input.md "configure(config)" |
| :456 | `AC-3/AC-4` | internals/user_input.md, "configure(config)" |
| :472 | `AC-4` | internals/user_input.md, "configure(config)" |
| :486-488 | `spec §2`, `R14`, `§1` | decisions/input.md, Decisions 2 and 8 |
| :515-518 | `AC-6/D-8`, `spec.md §6` | internals/user_input.md, "Cursor manipulation and 'reset'" |
| :525 | `AC-7/AC-9` | internals/user_input.md, same section |
| :534-536 | `AC-8/AC-9`, `AC-8` | doc/input_api.md, "Live reconfigure …" |
| :547 | `AC-1/2/3/4/9/11` | internals/user_input.md, "configure(config)" |
| :563 | `AC-5/AC-9` | internals/user_input.md, "clear()" |

Not fixed (left as-is, no persistent home): `0.1.0-m7` and `m7
design session` at consoleController.lua:365,368 — an unresolved
"pre-stub not-yet-implemented methods" design question that has no
corpus record.

### src/controller/userInputController.lua

| file:line | old ref | new ref |
|---|---|---|
| :125 | `AC-7` | internals/user_input.md, "Cursor manipulation and 'reset'" |
| :172 | `AC-19` | decisions/input.md, Decision 6 |
| :226 | `0.1.0-m5/m6` | decisions/input.md, Decision 4 |
| :251 | `spec.md §3` | internals/user_input.md, "Cursor manipulation and 'reset'" (FR-1 paragraph) |
| :271 | `0.1.0-m8` | internals/user_input.md, "Singleton lifecycle" |
| :290 | `C2` | decisions/input.md, Decision 3 |
| :299 | `0.1.0-m7` | internals/user_input.md, "configure(config)" |
| :322-323 | `AC-1/2/11`, `M7-01` | internals/user_input.md, "configure(config)" |
| :346 | `Spec §5 (AC-17/18/42(b))` | decisions/input.md, Decision 6 |
| :353 | `AC-18/AC-42(b)` | internals/user_input.md, "Submit and cancel — the framework tier-1 chains" |
| :378-383 | `AC-17`, `spec §5 mechanism note`, `M8`, `AC-25` | internals/user_input.md, same section |
| :400 | `AC-17/18/42(b)` | decisions/input.md, Decision 6 |
| :431 | `AC-11/AC-13` | decisions/input.md, Decision 2 |
| :446 | `AC-20/21` | internals/user_input.md, "Submit and cancel …" |
| :457,715,736 | `spec §1` (×3, param docs) | decisions/input.md, Decision 13 |
| :461-462 | `spec §2 / AC-8` | decisions/input.md, Decision 9 |
| :501 | `AC-18` | internals/user_input.md, "Error state" |
| :660 | `spec §5 AC-19` | internals/user_input.md, "Editor-specific keys" |
| :677 | `AC-25` | internals/user_input.md, "UserInputController keypressed (shared)" |
| :717 | `spec §2 / AC-8` | decisions/input.md, Decision 9 |

Not fixed: `A5` / `M2-human-review.md` / `0.1.0-m4` clusters at
:274-276 and :317-318 (open naming/factoring question, no corpus
record); `AC-17..26` at :407 (explicit non-claim, nothing to point
at); `m4/m5 A2` at :466 (open note, no record); `#77` at :486 (scope
disclaimer, not a citation with a target).

### src/model/input/userInputModel.lua

| file:line | old ref | new ref |
|---|---|---|
| :413 | `AC-25` | internals/user_input.md, "Submit and cancel — the framework tier-1 chains" |
| :515-517 | `AC-8`, `M7-01` | doc/input_api.md, "Live reconfigure: `configure`, `set_text`, `clear`, cursor" |
| :843-845 | `AC-25` | internals/user_input.md, "Submit and cancel …" |
| :872-878 | `AC-25`, `spec §5` | internals/user_input.md, "Submit and cancel …" |

### src/view/input/userInputView.lua

| file:line | old ref | new ref |
|---|---|---|
| :286-287 | `M6-01`, `AC-25` | internals/user_input.md, "Submit and cancel — the framework tier-1 chains" |

Not fixed: `commit 7b4422c` at :292 — a bare git-commit citation, no
doc record.

### tests/mock.lua

| file:line | old ref | new ref |
|---|---|---|
| :79 | `P1` | internals/user_input.md, "Data flow" |

### tests/input/project_open_liveness_spec.lua

| file:line | old ref | new ref |
|---|---|---|
| :1 | `Ruling (a)` | technical_debt/input.md, "Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)" |

Also corrected the file's own follow-up prose (originally quoted a
**stale, inverted** heading — "…are non-interactive in
project_open" — when the resolved heading says the opposite,
"…stay live in `project_open`").

### tests/input/keys_pressed_spec.lua

| file:line | old ref | new ref |
|---|---|---|
| :96-100 | `A6` + `0.1.0-m5` + `M2-human-review.md` | technical_debt/input.md, "Combo-string dispatch allocates a table per call" |

Not fixed: `A8` / `M2-human-review.md` clusters at :5-6, :47, :61-65
(test-infrastructure dedup/isolation notes, no corpus record).

### tests/input/user_input_model_spec.lua

| file:line | old ref | new ref |
|---|---|---|
| :144,147 | `M7-01`, `AC-8` | doc/input_api.md, "Live reconfigure: `configure`, `set_text`, `clear`, cursor" |

### tests/helpers/input_fixture.lua

| file:line | old ref | new ref |
|---|---|---|
| :310 | `AC-24` | doc/input_api.md, "Sticky callbacks" |

Not fixed: `doc A §5.5` (:137), `doc A §6.7` (:168), and the "doc A"
definition itself (:9-10) — see Inventory.

### tests/input/input_contracts_spec.lua

This file carries the overwhelming majority of tags (~180
occurrences). Rather than a 180-row table, the fixes are grouped by
target below; every occurrence within a group was individually
inspected before mapping (not blanket-applied by token). See the
diff for exact line-by-line wording.

| Target | What it covers | Approx. occurrences fixed |
|---|---|---|
| decisions/input.md, Decision 2 | four-tier chain, truthy-consume, hidden-check-is-internal | ~14 |
| decisions/input.md, Decision 5 | widget outputs (on_text_entered/on_limit_reached/validator/highlighter), on_text_input vs on_text_entered | ~10 |
| decisions/input.md, Decision 6 | submit/cancel framework-tier, hooks, "hide() fires no cancel chain" | ~9 |
| decisions/input.md, Decision 7 | mutable/immutable boundary, raises loudly | ~4 |
| decisions/input.md, Decision 8 | per-event combo tables, normalisation, l/r fold | ~7 |
| decisions/input.md, Decision 9 | uniform (k, keys_pressed, isrepeat) signature | ~5 |
| decisions/input.md, Decision 10 | native tier-3 precedence, fires while shown | ~9 |
| decisions/input.md, Decision 11 | running/project_open boundary, pointer excluded, teardown | ~9 |
| decisions/input.md, Decision 12 | inspect is console-bound-over-project | 2 |
| decisions/input.md, Decision 13 | read-only held-key proxy | ~2 |
| internals/user_input.md, "Submit and cancel — the framework tier-1 chains" | tier-1 gating, validator-reject lock, observable order | ~9 |
| internals/user_input.md, "configure(config)" | live-reconfigure semantics, one-shot pending stash | ~10 |
| internals/user_input.md, "clear()" | clear() semantics | 2 |
| internals/user_input.md, "Cursor manipulation and 'reset'" | get_cursor/set_cursor clamp/nil-when-hidden | ~4 |
| internals/user_input.md, "Key release" | released key already gone from held set | 1 |
| internals/user_input.md, "Dispatch chain" | non-consuming global shortcuts (§6.3 quote) | 1 |
| internals/user_input.md, "Framework-level click handling" | 0.4s/2.5px click detection | 1 |
| internals/user_input.md, "Key state …" | held-key add/remove-before-dispatch ordering | 1 |
| internals/user_input.md, "Search — a third widget instance …" | search widget absent-from-design-corpus | 1 |
| internals/user_input.md, "Multiline input" | Shift+Return always inserts newline | 1 |
| doc/input_api.md, "Activating the widget: `show`" | show()/force semantics | 3 |
| doc/input_api.md, "Migration from the legacy globals" | legacy globals gone, no shim | 1 |
| doc/input_api.md, "The continuous-session idiom" | on_text_entered/after_submit recipe | 3 |
| doc/input_api.md, "Sticky callbacks" | output-callback persistence across hide/re-show | 2 |
| doc/input_api.md, "Live reconfigure …" / "API reference" | set_text/set_cursor no-op+warn-when-hidden | 5 |
| tests.md, "Input Contract Suite (feature #77)" | Bucket B/C/D header citations | 5 |

Not fixed (left in place, see Inventory below): all `doc A §N.N`
citations (the large majority of remaining tags), plus scattered
milestone/process tokens (`E30`, `C23`, `NFR`-style codes already
resolved where matched, `ratified-model …`, `M5c-dispatch-chain.md`,
`design.md §4`, `spec §10`, `M6-02…`, `M7-01`/`M7-02-recut`,
`M8-01`, `0.1.0-mN`, `0.1.0-m5c`/`chunk 4`).

One correction beyond mechanical retargeting: :176-179 ("Search")
and :662 previously cited "doc A" / "design corpus" generically;
the search-widget claim has an actual, better-than-doc-A persistent
home (internals/user_input.md's own "Search" section states, almost
verbatim, "no corresponding entry in the design corpus"), so that
one was fixed rather than inventoried.

`{jargon: …}` tags were left untouched everywhere — they flag
invented terminology per the file's own header REVIEW/DOC note
(line 77), not spec/doc citations, and are out of this task's scope.

## Inventory (no persistent home)

Every remaining `{badspecref: …}` (and the two plain `doc/…/wip/…`
paths) after the fixes above. Grouped by root cause.

### "doc A" — the frozen design contract record itself

`tests/helpers/input_fixture.lua:9-10` defines "doc A" as
`doc/development/wip/77-new-input-api/notes/input-contracts.md` —
a wip-only file, not part of the persistent corpus. Every `doc A
§N.N` citation below traces to that one non-persistent document;
there is no clause-by-clause persistent mirror to point at. This is
the single largest inventory item by count (~30 occurrences).

| file:line | current text |
|---|---|
| input_fixture.lua:9-10 | `"doc A" = {badspecref: doc/development/wip/77-new-input-api/notes/input-contracts.md}` |
| input_fixture.lua:137 | `{badspecref: doc A §5.5}` |
| input_fixture.lua:168 | `{badspecref: doc A §6.7}` |
| input_contracts_spec.lua:82,85,97,106,113,124,146,154,167,203,216,230,242,278,581,662 | assorted `{badspecref: doc A §N.N}` routing/mechanism citations |
| input_contracts_spec.lua:146 | also carries `reviews/M4-0-04.md finding 1` (same non-persistent family) |
| input_contracts_spec.lua:1657 | `{badspecref: design.md §4}` (same "frozen design doc" family, different filename) |

**What it needs:** a Phase-C decision on whether "doc A"'s clause
numbering gets ported into the persistent corpus (e.g. as an
appendix in `tests.md` or `decisions/input.md`), or whether these
citations are simply dropped/reworded to cite behaviour instead of
clause numbers (as was done for the ~140 occurrences that already
had an independent persistent-doc description of the same fact).

### Milestone / version marks (`M#`, `0.1.0-m#`, `chunk N`, etc.)

No persistent doc tracks milestone numbering — by design, the
corpus records decisions and behaviour, not the schedule they
landed on.

| file:line | current text |
|---|---|
| src/util/key.lua:15 | `{badspecref: 0.1.0-m2a}` |
| src/controller/consoleController.lua:365,368 | `{badspecref: 0.1.0-m7}`, `{badspecref: m7 design session}` |
| tests/input/keys_pressed_spec.lua:64 | `{badspecref: 0.1.0-m4}` |
| tests/input/input_contracts_spec.lua:313 | `{badspecref: M4}` |
| tests/input/input_contracts_spec.lua:691 | `{badspecref: 0.1.0-mN}` |
| tests/input/input_contracts_spec.lua:1622-1623 | `{badspecref: 0.1.0-m5c}`, `{badspecref: chunk 4}` |
| tests/input/input_contracts_spec.lua:746 | `{badspecref: 0.1.0-m5c}` |
| tests/input/input_contracts_spec.lua:1945-1946 | `{badspecref: M7-01}`, `{badspecref: M7-02-recut}` |
| tests/input/input_contracts_spec.lua:2177,2245 | `{badspecref: M8-01}` (×2) |

### `M2-human-review.md` / review-doc citations

A per-milestone human-review artifact, not part of the corpus.

| file:line | current text |
|---|---|
| src/main.lua:365-366 | `{badspecref: A5}` question — see `{badspecref: implementation/reviews/M2-human-review.md}` |
| src/main.lua:376 | `{badspecref: A5}` (paired with the same review doc above) |
| src/controller/userInputController.lua:274-276 | `{badspecref: A5}`, `{badspecref: M2-human-review.md}`, `{badspecref: 0.1.0-m4}` |
| src/controller/userInputController.lua:317-318 | `{badspecref: A5}`, `{badspecref: M2-human-review.md}` |
| tests/input/keys_pressed_spec.lua:5-6 | `{badspecref: A8}`, `{badspecref: M2-human-review.md}` |
| tests/input/keys_pressed_spec.lua:61-65 | `{badspecref: A8}`, `{badspecref: 0.1.0-m4}`, `{badspecref: M2-human-review.md}` |
| tests/input/input_contracts_spec.lua:1632 | `{badspecref: M6-02-before-exit.md}` |
| tests/input/input_contracts_spec.lua:1748,1766 | `{badspecref: M6-02}` (×2) |

**What it needs:** these are open architecture/process questions
(controller-owns-construction, test-infra dedup, `before_exit`
lifecycle) that a human reviewer flagged but never resolved into a
committed decision. They belong in `decisions/input.md` or
`technical_debt/input.md` *once ruled on* — until then there is
nothing to cite.

### "Ratified-model" / scope-item citations (internal process artifacts)

| file:line | current text |
|---|---|
| tests/input/input_contracts_spec.lua:700-710 | `{badspecref: E30}`, `{badspecref: Scope item 10(a)}` (also `-- M5c-dispatch-chain.md`, `-- C23` in the surrounding prose, not separately braced) |
| tests/input/input_contracts_spec.lua:1123 | `{badspecref: E30}` |
| tests/input/input_contracts_spec.lua:1641 | `ratified-model ruling 3` (inline, folded into the Decision 11 fix above but the process-artifact label itself has no home) |
| tests/input/input_contracts_spec.lua:1692 | `{badspecref: spec §10}` |
| tests/input/input_contracts_spec.lua:1734 | `ratified-model R11` (inline, same treatment as ruling 3 above) |

### Miscellaneous, no clear persistent equivalent

| file:line | current text | why |
|---|---|---|
| src/view/input/userInputView.lua:292 | `{badspecref: commit 7b4422c}` | bare commit-hash citation; corpus doesn't track commits |
| src/controller/userInputController.lua:407 | `{badspecref: AC-17..26}` | explicit *non*-claim ("not an AC-17..26 concern") — nothing to point at |
| src/controller/userInputController.lua:466 | `{badspecref: m4/m5 A2}` | open note, never resolved into a doc |
| src/controller/userInputController.lua:486 | `{badspecref: #77}` | scope disclaimer ("pre-existing, not part of #77"), not a citation |
| tests/input/input_contracts_spec.lua:164 | `{badspecref: this feature}` | empty/self-referential tag, nothing concrete cited |
| tests/input/input_contracts_spec.lua:76 | `{badspecref:}` | the file's own meta-instruction describing the tagging convention, not a real reference |

## Summary

- Files touched: 13 `src/`+`tests/` files (`src/util/key.lua`,
  `src/controller/{controller,consoleController,
  projectInputController,userInputController}.lua`,
  `src/model/input/userInputModel.lua`,
  `src/view/input/userInputView.lua`,
  `tests/mock.lua`,
  `tests/input/{input_contracts_spec,keys_pressed_spec,
  project_open_liveness_spec,user_input_model_spec}.lua`,
  `tests/helpers/input_fixture.lua`).
- `src/main.lua` was inspected; both its citations are inventory
  items (no edit made).
- Fixed: roughly 150 individual `{badspecref: …}` reference
  strings, retargeted to a real, confirmed section in one of the
  five persistent corpus docs. Nothing outside comment-embedded
  reference strings was touched (no symbol renames, no logic
  changes, no `design/` edits).
- Inventoried (left in place, Phase C evidence): ~55 occurrences,
  dominated by the "doc A" wip-contract-record family (~30) plus
  milestone marks, review-doc citations, and internal process
  artifacts with no committed persistent-doc equivalent.
- `{jargon: …}` tags: untouched throughout — out of scope (they flag
  invented terminology, not spec/doc citations).
- Sanity check: `busted tests` → **815 successes / 0 failures / 0
  errors / 4 pending** (unchanged from the pre-sweep baseline),
  confirmed after every batch of edits, not just at the end.
