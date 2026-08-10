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

## 2026-08-09 — owner walks the decisions; five rulings, two of them against my recommendation

Mechanicals applied first (`2eaa0163`, `c54dc0e7`), then the owner asked to be walked through
the judgement calls one at a time. **Behavioural note worth carrying: the owner rejected my
first framing outright** — *"i do not understand this taxonomy, cannot reason over bare
paragraphs and ref-ids… reference their essence not only identifiers."* Correct, and it is a
standing lesson for this phase: P-ids and §-numbers are our filing system, not a language to
reason in. Every subsequent decision was put in terms of *what step, what document, what
changes* and each was answered immediately.

**The five rulings:**

1. **P8 — walk all nine ids; do NOT re-baseline to R079.** Against my recommendation, and the
   reasoning is better than mine: §6's "P8 marked done" is *itself* an unverified claim, so
   trusting it over the row would repeat the very failure I had just documented. Both are
   unverified; the walk settles it. My contribution survives as method — start from §6's claim
   as a hypothesis rather than re-deriving.
2. **The step list becomes the truth.** Rows rewritten, P14 + probe added (`c65c2269`).
3. **Take the design ruling NOW** rather than split the docs step — against my recommendation
   (I proposed moving internals to the code step). Owner went to the root: the deferral's
   premise was that the fork blocked one corner; once that was false, the deferral was not
   worth its machinery.
4. **Matcher shape (b)** — `Key.ctrl()/alt()/shift()` called directly. **Against my
   recommendation of (a).** I argued test cost (7 cases rewritten, matcher stops being
   source-blind, mock fix becomes load-bearing); the owner took symmetry with the gate and one
   literal source of truth over an adapter, and accepted the costs knowingly. **Consequence I
   had to reverse in the plan: session32's "zero edits needed" evidence was a property of the
   REJECTED shape and is withdrawn.** Also reinstates, precisely scoped, the "prerequisite"
   paragraph session32 refuted — recorded in the ledger in place (`2dddb8ff`).
5. **Flag-shortcut pattern taught under a plain descriptive name** — as recommended.

**Evidence gathered before ruling 4, verified by me in code, not inherited:** `combo_string`/
`any_mod` index `keys_pressed[m[1]] or keys_pressed[m[2]]` over 4 triples and never call
`Key.*`; `Key.ctrl/alt/shift` are `isDown(unpack(pair))`; `find_shortcut` is the single site
and holds 3 call instances; **harmony's `patch_isDown` is `function(...)` and loops all
arguments — so it works under BOTH shapes**, which removed it as a differentiator and
independently confirms P13's reduction to revalidation; the mock's `isDown` is single-arg and
its `mods` map has only left variants while `held` already carries the right-hand slots.

Commits: `2dddb8ff` (ledger), `0247cdb5` (rulings into §11 + new §12), `c65c2269` (step list).
Suite 955/0/0/3 at every one. Nothing pushed. `S33-plan-revalidation.md` closed with a
disposition table. **Part 1 complete. Part 2 (execution, starting at P9b) not yet begun.**

## 2026-08-09 — MODE CROSSING: execution. Probe deleted, P8 walked, P9b scoped out

Owner: run the probe deletion and the P8 walk; **P9b needs its own session or spinoff** —
the fix requires a design decision *and* its validation, which does not belong inside a
session already carrying the dissolution. Recorded in the plan (§12.5) so it reads as scoped
out, not deprioritised.

**Probe deleted (`ba5c94e4`).** Verified before removing, not after: zero refs in `src/`/
`tests/`, zero in the persistent corpus (the three "probe" hits in `technical_debt/input.md`
are the ordinary word, not the file), no directory-scanning loader, `src/probe/` empty
otherwise, introduced by `f8c15c4e` so it postdates base. Suite green + **headless boot** —
a deletion the suite cannot fail on needs the smoke check.

**P8 walk (`../../../validation/reviews/S33-p8-walk.md`): all nine discharged, P8 is DONE.**
Did the evidence-gathering inline rather than briefing an agent — 8 targeted greps tightly
coupled to the judgement; a spawn would have cost more than the work.

**And it overturned MY OWN claim.** I reported R079 "separately and explicitly held open" and
recommended re-baselining P8 to it. Wrong: `S28-merge-plan.md:170`'s *"unchanged pending
R079"* is a **merge-scoping** line saying that merge would not touch the file — R079 was
discharged the same day in its own commit (`ae176dd1`), by rewrite, with a coverage gap filled
and mutation-checked. **I inherited a planning table's phrase without checking the commits —
inside a review whose subject was that exact failure.** Had the owner taken my recommendation,
P8's sole remaining content would now be a phantom open ruling. The conservative ruling caught
an error the confident recommendation would have shipped.

**The walk's real product — three P14c interactions invisible from the id list:**
1. **`tests/helpers/input_fixture.lua:272` — `Controller.keys_pressed = { }`**, live code in
   the SHARED fixture reset, on every input test's path. P14c's cell named 35 of 38
   occurrences; this is the consequential omission.
2. `tests/helpers/input_session.lua:6` cites *"the `keys_pressed_spec` raw-handler pattern"* —
   rots when P14c empties that spec.
3. `input_widget_callbacks_spec.lua:537-541` documents driving **two distinct modifier
   tracks** — which shape (b) **collapses into one**. Not merely stale: it is evidence the
   ruled shape *simplifies* the test surface, which its cost accounting had not credited.
Plus: deleting the held-key-set `describe` leaves `keys_pressed_spec.lua` misnamed for its
only survivor (R057's surface vocabulary lives partly in that file).

All folded into P14c's step. Suite 955/0/0/3 throughout. Nothing pushed.

## 2026-08-09 — three closing instructions, then WRAPPED

**Owner, at the wrap — three instructions, all recorded in the plan (§12.6) and in the
affected steps:**

1. **The docs step runs BEFORE P9b's design substep.** Reasoning: *"P9b may include reasoning
   which should better be done towards the currently approved design."* Otherwise P9b argues
   against docs that still teach the tracked-set model the sprint is reversing. Sequencing is
   now **P14a → P9b (own session) → the rest of P14**. Both rows updated.
2. **Unimplemented prose is marked `PENDING`** until the code lands. This is the guard the
   docs-first ordering needed and nobody had named: writing the spec before the tree behaves
   that way means the document describes behaviour that does not exist. **P11's gate absorbs
   `PENDING`** — and note that extends the marker sweep to `doc/`, which it has never scanned,
   since `INTERIM:`/`REMARK:` only ever lived in `src/` and `tests/`.
3. **`xvfb-run` sanctioned for SM3a**, conditional on availability and usefulness. **Both
   confirmed and stated as fact, not assumption:** `/usr/bin/xvfb-run` and `/usr/bin/Xvfb`
   exist, and `xvfb-run -a love src` was exercised earlier in this session to boot the app
   after the probe deletion. It stays a **diagnostic** — the note's own warning is that fixing
   state-reset code on an unreproduced hypothesis is how the `wrap_handler` mistake happened.

**Wrapped per `agents/sessions.md` §5.** Report distilled to `report.md`; successor commissioned
as session34 and the pointer repointed in `agents/validation.md`. Successor's shape follows the
owner's instruction: **it opens with a choice they make with the session** — A the docs step
(recommended), B SM3a's runtime check, C the tests + platform code, D P9b in its own session —
each with its ordering constraints stated, rather than a single assigned task.

Eleven commits, one of them a deletion, the rest docs. Suite **955 / 0 / 0 / 3** at every one.
Nothing pushed. Track kept raw per §3.

## Sub-agents

One, Sonnet, explicit model, read-only, prompt of record and deliverable on disk:
`validation/prompts/S33-p14-citation-verification.md` →
`validation/outcomes/S33-p14-citation-verification.md`. It confirmed the counts the plan rests
on and found eight wrong citations, six of them ranges a later session would have deleted.
**Its most valuable output was a side note it flagged as outside its own remit** — the §6-vs-§4
contradiction on P8, which became this session's largest finding. Every load-bearing claim was
re-verified by me before use; the P8 walk was deliberately NOT delegated, being eight greps
tightly coupled to judgement.
