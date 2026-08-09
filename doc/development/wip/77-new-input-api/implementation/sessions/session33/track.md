# session33 — track

## 2026-08-09 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: session33
  held only `prompt.md`; no `track.md` / `report.md` (sessions §2 row 1).
- HEAD `1130418c` "docs(session32): wrap — report, session33 prompt, repointed pointer",
  branch `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked
  modifications** — only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the three nested
  example repos (`src/examples/{balloons,keyboard,maze}`).
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
- Read in full: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, this prompt, session32's `report.md` + `prompt.md` +
  `track.md`.
- **Mode declared:** Part 1 = **research/analysis** (revalidation of the plan — produces
  findings, not commitments). Part 2 = **execution**, and only after Part 1 is reported
  and the owner has responded. The boundary is crossed deliberately and will be named
  when it happens.
- Task as understood, stated to the owner before proceeding — the two halves, the six
  revalidation checks with check 2 (intent-vs-outcome, plan vs session32's report) as the
  weighted one, the five named suspicions, and P9b as the execution start.

## 2026-08-09 — Part 1 opens; cold check 1 spawned (mechanical, Sonnet, explicit model)

Prompt of record: `../../../validation/prompts/S33-p14-citation-verification.md`;
deliverable `../../../validation/outcomes/S33-p14-citation-verification.md`. Read-only,
seven tasks: every line number / count / id list quoted in §11 verified against code and
docs, with the **completeness** question (which `src/` `keys_pressed` occurrences no P14d/e
bullet accounts for) as the finding it exists to produce. Ordered first because suspicion #5
— that quoted numbers are riding on unverified inheritance — cannot be judged without it.

## 2026-08-09 — findings from my own half, before the check returns

**F1 (structural, the main one) — §11.3 still uses the PRE-RULING lettering.**
Mechanism verified in git, not inferred: in `24170aec` the rows were P14a docs / **P14b
tests** / P14c code / P14d examples / P14e debt register. `d348b505` re-lettered them —
its own message says so: *"Rows re-lettered accordingly: P14a docs+debt, P14b design
ruling, P14c tests, P14d platform code, P14e examples."* It applied the re-lettering to
§11.4 and §11.5 and **left §11.3 untouched**. Four stale references survive, all meaning
"the tests step", all now reading as the deferred design ruling:
- `:942` P8 ×2 — *"test-restructuring territory that **P14b** now also touches"*, *"owed
  before **P14b** starts"*;
- `:945` P9c ×2 — *"**P14b** moves and deletes test cases … re-check after **P14b**"*.
Not cosmetic: P14b is **DEFERRED by owner ruling** ("raise when it blocks"), so as written
§11.3 gates P8's owed check on a step that may not start for a long time — while §11.4's
unblocked list (`:966-969`) names that same check as **proceeding now**. §11.3 and §11.4
contradict each other under the current lettering and agree under the intended one.
Session32's own successor prompt says **P14c** in both places: report and plan diverged,
and the plan is what executes.

**F2 — `plan.md` Phase U (`:344-347`) carries an open item the same session closed.**
It says P13's disposition "is an **open item for the session32 replan**" and lists three
possible outcomes. One of them happened: `d348b505` reduced P13 to revalidation and kept it
in the sprint. The parent plan still asks the question. (Check 2d — the session edited the
surrounding doc, then ruled on its open item and did not come back.)

**F3 — §4's table, the operative list since session27, was annotated selectively.**
[S32] markers landed on exactly the four rows that were *withdrawn / promoted / reduced*
(P9d, P9e, P12, P13). The four rows that *gained obligations* — P8 (a per-id check now
owed), P9c (its timing moved), P10 (grows, and its Decision-30 slice left for P14a), P11
(gate currently failing 22+5) — carry **no [S32] marker at all**, and P14a–e are **not in
§4's table**. An executor reading §4 sees none of it. This is the prompt's "visible enough
to survive a handover" question, answered: **no.**

**F4 — a report-level insight that never reached the plan.** Session32's report closes with
*"the comment-bloat subset (~50 ids) inside W10's block of 92 is never separately enumerated
and must be re-derived before P11."* The plan says "~50 remarks" (`:464`) and P11's §4 row
says nothing about re-derivation. The report is a session artifact; the plan is what the
P11 executor reads.

**F5 (gap, minor) — nothing schedules the internals backfill.** P14a defers the shape-
dependent internals passage by writing "to the level of *the matcher reads the device*";
P14b resolves the shape; **no row commits to writing the concrete shape back into
`internals/user_input.md`** afterwards. P10's remainder is W9 ledger + W10 batches 1/2/4,
which does not cover it.

**Verified, not a finding — the pre-existing check on the whole ruling.** `keys_pressed`
appears **nowhere in the tree at PR base `3256aac`** (whole-tree `git grep`, machinery
sanity-checked against `love.keyboard`, `3256aac` confirmed an ancestor of HEAD). The
tracked set is entirely feature-introduced, so its dissolution cannot be a pre-feature
regression. This is the load-bearing "deviation from pre-feature functionality" red flag,
and it **clears**. (Incidental: controllers live at `src/controller/` at base, `src/model/`
now.) All ten `../` links in §11 resolve; `doc/development/internals/examples/keyboard.md`
(P9b's design of record) exists.

## 2026-08-09 — suspicion #4 answered by reading the actual internals passage

**F6 — the P14b trigger is concrete and fires EARLY; the deferral buys less than stated.**
`internals/user_input.md` §"Key state: `Controller.keys_pressed` and `combo_string`"
(`:241-296`) is the passage P14a must rewrite, and it documents **`Controller.combo_string(k,
keys_pressed)` by signature** plus a whole *"Why the event-tracked set and not
`love.keyboard.isDown`"* subsection (the two-clocks argument, cited to Decision 29 — which
Decision 30 supersedes). Under fork **(a)** `combo_string` keeps its second parameter and is
handed a proxy; under fork **(b)** it calls `Key.*` itself and the parameter goes. **The
signature is shape-dependent**, so this passage cannot be written at the "matcher reads the
device" altitude without either omitting the signature — in the one doc whose job is
signatures — or picking a fork. The trigger therefore *works*: it fires. But §11.4's framing
that the fork blocks "**only** the one internals passage in P14a" understates it — that
passage is the section's centre of gravity, not a marginal line.

**The useful refinement: P14a splits cleanly in two.** Its **project-facing half**
(`doc/input_api.md` §"Held keys", rule-4 teaching, the false `:268` claim, the debt register,
the Decision 21 tombstone, the rule-3 softening) is **genuinely shape-independent** — projects
never see the matcher — and is unblocked exactly as the plan says. Its **internals half** is
fork-blocked from the first paragraph. Recommend the plan say that, rather than "except one
passage".

**F7 (vocabulary, small but PR-facing) — "rule 4" is ours, and `doc/input_api.md` has never
cited the ledger.** Verified: the string "rule 4"/"Rule 4" appears **nowhere** in the
persistent corpus — Decision 30 has an unnamed numbered list 1–4, so "rule 4" is session
shorthand, not ratified vocabulary (the red-flag checklist's *unratified terminology* item,
firing mildly). And `doc/input_api.md` contains **zero** occurrences of "Decision" — the
project-facing doc has never referenced ledger numbering. P14a's instruction *"teach rule 4
for the first time in the corpus"* is right about the **pattern** and must not carry the
**label**: a stakeholder reading only `input_api.md` + the PR description would meet a
numbered rule with no visible list. Same for §11.7's PR-description obligation.

Incidental, verified in passing: `internals/user_input.md:251` carries one of the 22 open
`REMARK:` markers, inside the section P14a rewrites. And `:409-410` shows
`submit_flow(keys_pressed)` / `cancel_flow(keys_pressed)` — a production site **not named by
any P14d bullet**; held for cross-check against the running completeness audit.

## 2026-08-09 — check 1 returns; F1 emerges and it inverts the commission's concern

Deliverable: `../../../validation/outcomes/S33-p14-citation-verification.md`. Read-only,
grep + LSP, 22-count and 10-count confirmed exact. **Every load-bearing claim re-verified by
me before use** — and its most valuable output was a *side note* it flagged as "outside this
task's literal ask".

**F1 (new, and the one that changes work) — P8's nine-id obligation rests on a row session28
had already retired.** §6 amendment 1 (`:688`, session28, 2026-08-07) says **"P8 marked
done"** and names 8 of the 9 ids as discharged. The 9th, **R079**, is separately held open —
`S28-merge-plan.md:170`: *"unchanged pending R079 (open ruling)"*. **§4's P8 row was never
edited** despite §6 opening with *"the phase table above … is amended in place"*. Session32
walked §4, read the unamended row, reproduced all nine into §11.3 **and into
`notes/S32-plan-map.md:74` — the map the owner ratified from**. So the check is real but its
**size** was manufactured: at most one id, not nine. Verified myself: the §6-vs-§4
contradiction, the R079 carve-out, the merge's two reviews on disk. NOT verified (and said so
in the review): that each of the eight is discharged in the tree — that IS the per-id check,
now small.

**F1 and F2 are the same failure**: a document amended in one place and read from another.
Named as a working rule in the review — *when a row is amended, the amendment goes in the row.*

Audit also produced: 6 wrong line ranges (worst: `input_nfr_mechanism_spec.lua:66-105` stops
at the **opening line** of the 4th test — deleting to `:105` orphans 7 lines), 2 misattributed
debt pairs + the unlisted `:719` entry, and **5 unaccounted `keys_pressed` sites** — of which
`types.lua:251` (`@field keys_pressed` on the `CompyInput` type) and
`examples/keyboard/input.lua:109` (`modHeld`, a distinct site from the `__index` branch P14e
names) are real code. **LSP missed 4 of the 22** (type annotation, comment, computed-string-key
indirection, `compy.input.*` proxy path) — grep-as-backstop was load-bearing, exactly as the
standing rule says.

**Correction against myself:** my earlier entry said controllers moved to `src/model/`. Wrong
— `src/controller/` in both base and HEAD; `src/model/` is unrelated model files. The error
reached the sub-agent prompt; it caught it and said so. Recorded in the review's closing
section.

Review written to `../../../validation/reviews/S33-plan-revalidation.md`: verdict **sound in
substance, defective in navigation**; 11 findings; 5 mechanical corrections ready to apply and
5 owner-gated. Part 1 reported; **no correction applied and Part 2 not started** — awaiting
the owner.
