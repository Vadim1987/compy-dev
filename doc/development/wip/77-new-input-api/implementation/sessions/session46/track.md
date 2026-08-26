# session46 track

## 2026-08-26 — boot

- Fresh start: no prior `session46/track.md`, no `report.md`. Guardrail clean.
- Read: `agents/validation.md`, `agents/sessions.md`, own `prompt.md`,
  `session45/report.md` (handover, per prompt — track not re-derived).
- HEAD `84c28e4f` (docs(session45): wrap). Branch
  `feature/77-newapi-analysis-s20260615`.
- Working tree: only the known untracked scratch (`claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`,
  `src/examples/{balloons,keyboard,maze}`) — matches the guardrail's
  "leave alone" list. Nothing mid-flight.
- Baseline confirmed: **968 / 0 / 0 / 10** (`busted tests`), the 10 pending
  being the owner-ruled set.
- Sprint state per prompt + `validation/reviews/S27-triage-and-plan.md`:
  P11 closed, marker gate clean, P25/P26 empty. The only sprint item left is
  the **human smoke pass**; then the parent plan's gated **B→C→D collapse
  ruling**.
- Mode declared: **evaluation + replanning**, not execution.
- Reported the task to the owner and am waiting before proceeding.

## 2026-08-26 — owner rulings on sequencing

- **Recon goes AFTER smoke + PR review**, not before. My proposed
  recon-first ordering overruled.
- **Owner reviews the diff AS PR SLICES** — separation of review surface.
  My "review content now, slice later" partly overruled; the objection
  dissolves because the assembly guide is re-runnable (machine cost, not
  human). Only the FINAL cut must stay last.
- **Fetch hazard, owner's**: corpus may rely on current HEADs that move
  silently. Sharpened: shas are absolute and safe; **ref NAMES** are the
  trap. Inventory + local tags is the fix.
- Owner's own argument for smoke-first: a green pass yields a stable state
  worth tagging/branching on our side.
- Asked whether recon could make smoke unnecessary → **no**, orthogonal.
  Recon measures upstream drift; smoke tests device behaviour no suite
  reaches. Recon could make it premature, never unnecessary.
- Agreed order: smoke → PR-slice review → recon → U → L → G (collapse
  ruling as step zero of G).

## 2026-08-26 — inventory taken (pre-fetch photograph)

Wrote `validation/notes/S46-repo-head-inventory.md`. Four repos, full shas.
Findings:

- Platform `dsent/dsent/dev` is **23 days stale**, `upstream/dev` **35
  days**; edge is **not an ancestor** of HEAD. The editor overhaul the
  owner mentions is invisible in our refs — cannot be assessed pre-fetch.
- **balloons: 5 ahead / 0 behind `origin/main`** — cleanest repo, zero
  divergence, so its smoke result cannot be invalidated by recon. Smoke
  it first.
- **maze: Phase U's "still owed" looks outdated.** `newinput-edge` is
  0-behind/11-ahead of `dsent/dsent/dev` — the merge appears done.
- **maze `newinput` diverged**: 4 ahead / 37 behind edge, `a045fdb` NOT an
  ancestor. Work looks REDONE not merged; correspondence inferred from
  subjects only — **unverified in code**, flagged as such.
- **maze smoke must run on `newinput-edge`** — `da9d1c2` (Shift+Esc,
  B8–B10) is on that branch ONLY.
- keyboard: S37 local-branch trap still live (`dsent/dev` 8 ahead / 36
  behind `origin/dsent/dev`).
- Smoke checklist anchor table: 3 of 4 rows current; platform row stale by
  3 commits (its own refresh instruction, working as designed).

## 2026-08-26 — tags laid, TF2 sprint closed

**Tags (owner-directed):** 16 annotated local tags, 4 repos, scheme
`wip77/<date>/<kind>`. head + base + mergebase everywhere, plus keyboard
`premerge` and maze `alt-newinput`. Registry = `wip/77-new-input-api/TAGS.md`
(single doc, as asked). Never pushed.

- Laying them produced the missing number: platform is **86 behind the
  edge / 838 ahead**, **22 behind aldum upstream**, one shared merge-base
  `01ac1429` (2026-06-05, ~3 months). 838 is inflated by our own wip
  commits. **86 is a FLOOR** — what a 23-day-old view can see.
- base == mergebase in all three example repos = zero divergence. Kept the
  redundant tag for uniform lookup; the equality is itself the finding.

**Sprint close (owner directive, "right now"):** S27 gets a ⛔ terminal
block; TF2 closes with it. Argued as §0's OWN promotion rule firing
("release-shaped work is promoted up, not carried here"), not an override.
Acceptance → new **Phase ACC** in plan.md, running FIRST, before U.
Added STATUS BLOCK II rather than editing the deliberately-stale 2026-08-09
block — that one kept unedited as record.

**Rename: advised AGAINST, evidence-based; owner had anticipated it.**
- 2,563 P-id citations / 221 files; **786 in frozen session dirs**.
- Plan already ratified the principle when naming Phase U (B–G
  load-bearing across frozen prompts).
- S45 precedent: heading rename → 31 dangling citations. This is ~80x.
- **Collision:** `src/examples/maze/levels.lua` uses P10–P19 as PUZZLE ids,
  another author's file. Any regex sweep hits them.
- Real fix for the owner's actual pain (switching timelines): the close
  itself leaves ONE live timeline. Added a crosswalk table instead.

**Leak found, not acted on:** 3 bare P-id citations escaped into the
persistent corpus (`technical_debt/input.md` x2, `agents/rules/commenting.md`
x1). They go dangling if wip/77 is deleted. Zero wip/ *paths* leaked, so
the comment-reference rule is holding. Flag for Phase L / wip-deletion.

## 2026-08-26 — owner attestation: no fetch since the reconciliations

Owner: maze was reconciled against whatever the **last fetch** brought (that
fetch advanced the head); **nothing fetched in any repo since**. What upstream
did in the weeks after is unknown.

Corrects my finding #1. Maze's Phase U row is NOT simply outdated — maze is
**reconciled as of `b8cc436` (2026-07-24)** and owes a **re-check, not a
redo**. S37's ancestry-preserving merge shape is paying off exactly as
argued: upstream is still a strict ancestor, so the re-merge stays cheap.

**Generalised:** every baseline in this feature is a last-fetch snapshot, not
a live view; dates differ per repo because the fetches did. Staleness floors
(a ref's date bounds how old our view is, and says NOTHING about what landed
upstream after):

- platform `dsent/dsent/dev` 2026-08-03 (23d) · `upstream/dev` 2026-07-22 (35d)
- keyboard `origin/dsent/dev` 2026-08-02 (24d)
- maze `dsent/dsent/dev` 2026-07-24 (33d)
- balloons `origin/main` 2026-05-11 (107d)

Recorded in the inventory note, plan.md Phase U, and TAGS.md ("a base tag says
what we developed against, never what upstream is").

**Still unverified:** maze `newinput` divergence — redone-vs-merged is
inferred from commit subjects only. The attestation makes fetch-then-rebuild
plausible but does not prove content was carried. Flagged in plan.md.

## 2026-08-26 — Phase FIX created (owner ruling)

Owner: bare P-id citations in the persistent corpus are a **defect**; add a
**FIX step after ACC** and put it there. Rationale given: "i would anyway
spot it on review."

**Swept the whole class before writing the row** (the S45 "one claim, three
homes" lesson). My earlier "3 citations" was UNDER-COUNTED — the real set is
**10**, and the worst are not bare ids but **wip/ PATHS**:

- `doc/development/smoke_checklists.md` — **7 of the 10**, incl. **4 paths**
  (lines 8, 142, 154, 261) + bare ids (15, 42, 233)
- `technical_debt/input.md` — 141 (`P-18-05`), 1609 (`P10`)
- `agents/rules/commenting.md` — 197 (`P-18-10`)

**Excluded deliberately, with reason stated in-plan:** `agents/validation.md`
and `agents/sweep.md` cite sessions + wip/ paths BY DESIGN — they are the
workflow docs that *govern* wip/77. A boot pointer naming the tree it manages
is not dangling. But `agents/rules/commenting.md` IS in scope: generic project
rule, not feature-scoped, no business citing a step id.

**Ordering confirmed sound:** FIX after ACC is right, not a compromise — the
wip/ paths still RESOLVE while wip/ exists, so the smoke pass is unaffected,
and fixing earlier = rewriting a doc while the owner is running it.

**Correction shape stated:** not deletion. Each citation carries provenance;
restate the fact + cite a persistent doc's NAMED section. Where nothing
persistent holds it → that fact needs a home → Phase L.

**Left OPEN for owner, not assumed:** ~4 session-provenance mentions
("the session25 claim", "amended in place (session34)") in
technical_debt/input.md + decisions/input.md. These read as *when*, not as
pointers to follow. Fold into FIX-1 or accept as provenance?

**Proposed as a FIX candidate:** P11's deferred 8-item editorial marker list
— currently homeless and FIX-shaped. Pending owner nod.

Ordering now: **ACC → FIX → recon → U → L → G**.

## 2026-08-26 — maze coverage gap found; id scheme adopted; FIX-01-02

**My wording caused a false alarm, corrected:** "newer base" compared
`newinput-edge` to the OLD `newinput` branch, not to upstream. Maze IS
reconciled against the latest head we hold — **0 behind** `dsent/dsent/dev`.
(The v1/v1.1 "behind" hits are ancient release branches, not advance.)

**But the owner's instinct found a REAL gap.** Between the old upstream point
`12f675f6` (2026-05-25) and the reconciled base `b8cc436` (2026-07-24)
upstream landed **4,920 insertions / 37 files**:
- the whole `draw` game (5 modules)
- `main.lua` split → `maze_{main,logic,render,constants,plan}.lua`
- a spec suite, more levels
- **`9911a27 align ux: Shift-Esc only exits mini-games`** — upstream doing
  its OWN Shift+Esc work, same area as Decision 33

**The gap:** checklist covers `draw` (§A) but **nothing covers the
plan-a-path key-tile buffer (Track 2)**, which is input-driven in exactly our
territory:
- `maze_plan.lua:141` `plan_key(k, _, isrepeat)` — comment: "A held key
  repeats keypresses; act on the edge only... tracking which keys are down"
- `maze_main.lua:208` "plan buffer needs to know whether it is a fresh press"
- **our migration already edited it**: `569204e refactor(input): let the press
  say whether it is a repeat, in the plan buffer`

**This is the keyboard breakage's exact shape** — upstream `words.lua` broke
on `inputStale` (the held-key filter we deleted); the plan buffer likewise
reasons about "which keys are down", which session35 dissolved. Rows needed
BEFORE running ACC-01-03.

**ID scheme adopted (owner):** `KIND-sprint-task`.
- ACC-01-01 balloons · -02 keyboard · -03 maze+draw · -04 sapper ·
  -05 slice regeneration (review cut) · -06 owner slice review
- FIX-01-01 ephemeral citations (10) · FIX-01-02 session numbers ·
  FIX-01-03 deferred editorial list (candidate)

**FIX-01-02 = owner ruling, and it OVERTURNS my proposal.** I had offered to
accept session mentions as provenance; owner: session numbers NEVER belong in
the persistent corpus. Owner is right and more consistent — unresolvable
after wip deletion is the same defect regardless of whether it reads as a
pointer or a date. 4 sites (technical_debt/input.md 249, 632;
decisions/input.md 798, 1255). Correction: **keep the date, drop the
session**. Flagged: re-sweep wider before closing (S-form + src/ + tests/).

## 2026-08-26 — all four smoke checklists written/updated; FIX-01-03 live

**Self-correction, important:** my "no row covers Track 2" claim was WRONG.
The grep was for `plan-a-path|key-tile|plan field`; the checklist names it
**"Track 2 (plan)"**. Rows **D5 and D7 already cover** the plan buffer's
held-key edge + lost-release recovery — i.e. exactly the `isrepeat`
mechanism `569204e` touched. Corrected in plan.md rather than quietly
narrowed. Real remaining gap was smaller: plan submit/run end-to-end, and
Shift+Esc from a plan level. Added **B11, D8, D9**.

**Written (new): `balloons`** — 4 sections. Structure driven by what the
migration actually is: continuous session stays open (A), lines-vs-string
join in `terminal.lua` (B — note the failure is SILENT: every answer reads
wrong, no crash), ESC clears-but-keeps-open (C), exit + echo (D).

**Written (new): `sapper`** — the interesting one. Feature diff is TINY (two
registration lines, `compy.singleclick` → `compy.input.hooks.singleclick`),
so A-rows are really a PLATFORM routing check, stated as such. B covers the
press-time touch fallback incl. the "this modifier and neither other" guard.
**C documents the P19 defect as an EXPECTED result** with instructions to
report only deviation FROM the description — otherwise the owner files a
known accepted defect as new.

**Updated:** header (all four lists exist; ACC run order by upstream
sensitivity; tag-a-green-pass pointer to TAGS.md). Anchors refreshed —
platform row was `5128a4bf` in 2 tables, now `c7e065c3` (4 tables total).

**FIX-01-03 live (owner).** Flagged in-plan: the 8 items were named as a
COUNT, never enumerated on disk. Must be re-derived before sizing — same
failure mode as W10 batch 3 ("~50 ids" → 13 already-covered + 8 real).

## 2026-08-26 — ACC-01-01/02 executed: slices + cold PR review

Owner unavailable for smoke for hours → asked for a device-free acceptance
step. Renumbered ACC (none had run): slices=01, cold review=02, smokes
03–06, owner review 07.

**ACC-01-01 slice regeneration — the guide's §4 check EARNED ITS KEEP.**
100 files in the change, **95 in the slices**. Five outside every pathspec,
would have been SILENTLY DROPPED from the PR:
- `src/harmony/init.lua` (+8) — **PRODUCTION CODE** → 3f
- `doc/development/smoke_checklists.md` (+462) → 3a
- `tests/harmony_input_spec.lua` (+119) → 3b
- `tests/util/key_spec.lua` (+43) → 3b
- `doc/tall_blocks.md` (+72) → 3a
Same failure as `conventions/docs.md` — **third occurrence**, first to cost
code. Root cause each time: a pathspec naming FILES cannot see a file that
did not exist when it was written. Guide §4.1 records it + the mitigation
(prefer directories; run §4 after any commit adding a file — the guide
already said this; not run since session27). Now 100/100.

**Process note:** first branch-dance attempt ABORTED (dirty tree) and the
`cp` still ran → clobbered 1b with an empty diff. Caught it, restored from
git, committed slices first to clean the tree, redid it. No damage. Lesson:
`set -e` does not catch a failure inside `cmd 2>&1 | tail`.

**Avoided the session45 trap:** guide says `git add -A` for the reassembly
commit. Did NOT — used explicit adds from `git apply --numstat`. `git add -A`
there would have swept the 3 embedded repos + owner scratch again.

**ACC-01-02 cold review.** Kit outside repo: spec (verbatim ticket first) +
slices minus set 2 + `git archive` baselines (no .git → no history). Agent
FORBIDDEN `/repo` and lua-lsp (= the answer key). Verdict **merge with
changes**.

**Verified 2 claims in code myself before relaying:**
- `keys_pressed` in pr-description line 71 w/ justification; **zero hits in
  src/** → CONFIRMED, description describes a member that does not exist.
- `state.pending`: built in `get_compy_input()` closure ← `prepare_project_env`
  ← `ConsoleController.new` line 80, called ONCE → app-lifetime. Found no
  code clearing it. Structurally CONFIRMED; **reachability not traced** —
  flagged as such, not asserted.

## 2026-08-26 — owner correction: pathspec is DERIVED, not maintained

Owner: they never assumed the pathspec was static — expected it **figured out
as a first discovery step** preceding the slice build. **Static = the anchor
baseline shas only.** Better design, and it makes the §4.1 defect class
*impossible to express* rather than merely detectable.

Implemented as guide **§1.0**: enumerate → classify by RULE (directory
patterns) → **hard gate on UNCLASSIFIED** → cut. An unclassified file exits 1.
Verified: classifies all 100, zero unclassified, partition matches existing
slices exactly (3a 11, 3b 21, 3d 3, 3e 4, 3f 7, 3g 12, S1 26, S2 15).
Stated limit: file→set map only; §1.1's two carve-outs are hunk-level
(`userInputModel.lua` legitimately in both 3c and 3f) and layer on top.

**Answered the owner's question — review NOT undermined, do not repeat.**
Checked rather than recalled: the 5-file fix landed in `16aa25e2` BEFORE the
kit was built. All five present in the kit's patches. **85 kit files + 15
withheld agentic = 100.** Reviewer saw the complete change set minus exactly
what we intended to withhold.

**PR description rewritten** (the blocker). Both claims verified in code first:
- `keys_pressed`: line 71, zero hits in src/ → replaced with the real surface,
  `Key.any_pressed`/`shift`/`ctrl`/`alt`, + why it lives on `Key` not
  `compy.input` (asking the device is not a routing concern).
- "No pointer shortcuts": **FALSE**. `projectInputController.lua:53-54`
  serialises `mouseN`; its own comment line 45 says "'ctrl+s' and
  'ctrl+mouse2' are one vocabulary, not two." Rewritten as the true narrower
  claim (no modifier-only/button-less form). Open question 2 rewritten — it
  asked for a capability half-shipped.
- Counts 923/0/3 → **968/0/0/10** + the 3-and-7 pending explanation.
- Smoke plan claim now concrete (smoke_checklists.md ships in 3a).

## 2026-08-26 — ACC-01-02 findings triaged (triage only, no fixes)

Owner: triage not fix. Also flagged highlighter as a bug (agreed), and was
**suspicious of the convention-collision finding** — rightly.

**Owner's challenge was half-right, and checking it changed the finding.**
`conventions/docs.md` DOES literally say "The block is the only place
provenance is recorded. Do not re-add the HTML comment." So the reviewer's
claim is textually true. BUT it forbids the **FORM**, not the owner's
purpose — `authored: llm` + `reviewed: none` carries exactly what "authored
By LLM; human-approved NOT YET" carried, and the `reviewed` field's own
description says so. Owner's intent is preserved, just relocated.

**The real shape is bigger and different.** Surveyed all 53 docs under doc/
(wip excluded): front-matter **9** · HTML-only **22** · both **1** ·
neither **21**. All 21 of slice 1a's files are HTML-only with NO
front-matter → **incomplete migration, not a duplicate/contradiction**.
44 of 53 non-compliant. Our own `smoke_checklists.md` is in "neither".

**Biggest finding is one the reviewer under-rated: FIX-02-01.** 10 committed
`> REMARK:` blocks ship in slice 3a — 8 in `decisions/input.md`, 2 in
`tests.md`. **The owner's OWN voice**, several substantive (one argues
Decision 5 should be discarded: "codebase change would be minimal and won't
change any behaviour"). Two problems: unaddressed remarks, AND **the marker
gate never covered doc/** — it greps src/ + tests/ only. P11 reported clean
CORRECTLY; doc/ was out of scope. Gate needs widening or this recurs.

**Proposed split (owner's own boundary):** BUG-01 (2 runtime defects needing
investigation) vs FIX-02 (5 doc/process, mechanical once ruled). FIX-01 left
alone — different batch, different source.

**Honesty markers in the triage doc:** BUG-01-02 (highlighter) and FIX-02-05
(byte/char clamping) are NOT parent-verified — carried at the reviewer's word
and labelled so. BUG-01-01 verified structurally, reachability NOT traced.

**Compounding find on BUG-01-01:** the debt-ledger entry covering it rests on
the premise "compy.input is rebuilt per project environment" — which the call
graph contradicts (built once, ConsoleController.new:80). A ledger entry on a
false premise is worse than none: it closes the question.

Verified this round: pong/README 316/316 lines but **2/2 with
--ignore-all-space** (CRLF rewrite hiding a 2-line change); CHANGELOG
Unreleased has only `### Changed`, no `Removed`.

## 2026-08-26 — owner ruling on provenance: scope collapses 44 → 3

Owner's four points: (1) stamping was HTML; (2) convention came after;
(3) files added/changed LATER respect it, older stamps stay unless changed;
(4) a formal violation does not displace more important work.

**Consequence: slice 1a is NOT a defect.** It faithfully reproduces a commit
predating the rule; re-cutting it to satisfy a later convention would
misrepresent the history it exists to record. The reviewer's framing is
retired.

Applied rule 3 mechanically (docs touched since convention commit `8d665fe4`,
2026-07-31, lacking front-matter) → **13**, split by ownership:
- **3 ADDED after the convention = unambiguously ours** → the whole row:
  `internals/examples/keyboard.md` (08-07), `smoke_checklists.md` (08-12),
  `tall_blocks.md` (08-16). All three ship in this PR. ~6 lines each.
- 10 pre-existing but changed → in scope by the LETTER of rule 3, deferred
  under rule 4.
- 31 untouched → rule 3 does not reach them. Not in scope.

Kept the 44/53 survey figure in the doc explicitly labelled as describing the
CORPUS not a defect — so a future session does not re-derive it and re-open
a question the owner has closed.

## 2026-08-26 — REMARK triage (owner: "I was told nothing remains")

**Owner is right to push back, and the explanation is specific — not an
excuse.** The remarks were NOT missed by TF2: all are in the 187
(`S27-remark-inventory.md` doc/ section = **R080–R109 + R166**), and several
carry triage verdicts already (R080: "S1, recommend declining for this
release"). TF2 handled the CONTENT.

**What failed: the removal pass, then the check.** Most doc/ blocks were
removed; 14 were not; nothing caught it because **the gate greps src/ +
tests/ only**. P11 reported the gate clean and was CORRECT — doc/ was never
in scope. So "nothing remains" was true of the GATE and false of the CORPUS.
The scope was the defect, not the report.

**Count correction: 14, not 10** (12 in decisions/input.md + 2 in tests.md).
My earlier figure came from a truncated `head`.

**Verdict: NONE is stale.** Grep-verified that every target still exists in
the shipping text — "widget outputs" ×2, "student" ×2, "de-facto SDL" ×2,
"checked at the end" ×1, "bypassed if not shown" ×1.

Split: 1 already-ruled design question (R080) · 11 live editorial · 2
rule-shaped (one owner principle stated twice: strip historical
self-argument — overlaps the parent plan's collapsed-decisions row, so treat
together or the file gets swept twice by two rules disagreeing at the edges).

**Highest value = `:153`** — a shipping decisions ledger states the widget
hidden-check TWO INCOMPATIBLE WAYS. Not a wording preference; the doc
contradicts itself on load-bearing behaviour.

**False alarm I nearly raised, checked instead:** decisions/input.md has 16
`keys_pressed` mentions — same retired name that was the PR description's
blocker. But Decisions 13/20/29 correctly carry `SUPERSEDED by Decision 30`
in their headings. **The ledger is working**; those are legitimate historical
record. Wrote an explicit caution into the triage so the "strip history"
remarks (:429/:749) do not delete the supersession trail.

## 2026-08-26 — owner: triage ALL review findings; ACC splits

**Owner caught me short-changing the triage.** I had registered **7** defects,
taken from the reviewer's SUMMARY rather than its body. The report carries
**13 numbered findings + 3 analysis sections** (Vocabulary, guide gaps, Tests)
raising more. Owner expected "not less than a dozen" — correct, it is **19**.

**What I had missed entirely:**
- #5 `show{force=true, prompt=…}` silently drops the prompt
- #6 two docs in 3a disagree about route release at `running → project_open`
- #9 **turtle double-handles its keys** (owner named this)
- #11 channel list exists twice — the duplication the comment rules forbid
- #13 `textinput` shortcut cannot bind an upper-case char
- **Vocabulary: tier/chain/"the walk"** (owner's "tripled terminology") +
  overlay/widget/area/field quartet + "combinator"
- 3 guide gaps: shown-widget-always-consumes (keyboard side), callbacks
  cannot be un-set, hide() vs teardown / singleton
- Test gaps: no test covers the pending leak; a routing `pending()` deferred

**Lesson, recorded:** triaging from an agent's summary instead of its document
loses more than half. The summary is a chat convenience; the file is the
deliverable — which is exactly why hygiene (c) demands the file.

**Registered my OWN document findings in the plan too** (owner asked): the 5
unsliced files (closed), the doc/ gate blind spot, FIX-01-01/02/03. They were
living only in this track.

**Vocabulary rows are NOT nits** — they are the strategic frame's own clause
failing ("no vocabulary beyond the ask without a one-line justification").
Noted that 07 (overlay quartet) is a KNOWN unclosed item: 1b's own remark
flags it, S45 retired "overlay" from src/tests, docs half stayed open.
Recorded which terms the reviewer judged EARNED (reservation, derived event,
route/occupy) so nobody sweeps them by association.

**ACC split (owner):** ACC-01 = device-free (slices + cold review) **COMPLETE**.
ACC-02 = smoke ×4 + slice regen + owner review, **BLOCKED on BUG-01/FIX-02**.
Owner: "we have enough defects to fix before I put my hands on keyboard."
Repointed the smoke ids in plan.md AND smoke_checklists.md.

**BUG-01-05 (turtle) flagged for sibling check** — it is a finding about the
MIGRATION, so other migrated examples may share it. Do not fix only turtle.

## 2026-08-26 — DEC-01 specified (ledger renumbering); ACC-02 opens with a cold review

Owner: remove decision tombstones + renumber BEFORE next slicing. Sentinel
algorithm supplied. Also: **ACC-02 starts with a NEW cold review** before they
touch a keyboard.

**Verdict: doable, owner's algorithm is right.** The sentinel wrap solves the
real problem (renaming 26→13 while a real 13 still exists) by making old/new
namespaces disjoint.

**Survey:** 33 headings, highest number **34** (sequence ALREADY has a gap).
**4 tombstones: 13, 16, 20, 29** (all SUPERSEDED). 117 mentions in ledger,
**165 in src/+tests across 18 files**, ~10 persistent doc files, 1328 in wip/.
Result: 29 entries, gapless 1–29.

**My contribution — the gate belongs at step 2, not the end.** The hazard is
inverted from the usual rename: a missed citation does NOT dangle, it
**silently names a different EXISTING decision**. Worse than dangling because
it reads authoritative. So: once wrapping is provably complete, everything
after is safe. Gate = no unwrapped `Decisions?` anywhere in scope.

**Three hazards the algorithm doesn't cover by itself:**
1. **Line-broken mentions — owner anticipated, CONFIRMED 3** (ledger lines
   117, 230, 1444: "(Decision\n30)"). Must be joined as its OWN commit first —
   a reflow inside a rename diff is unreadable.
2. **Case/plural variants**: "Decisions 25 and 27" (one mention, two ids);
   lowercase `decision 5` ×4, `decision 2` ×3.
3. **wip/ must NOT be renumbered** — frozen history, and it carries a SEPARATE
   dead namespace `D-1..D-10` (1328 hits, design/spec.md only, zero in
   persistent corpus or code). Do not conflate.

**Inventory = deliverable, not worksheet.** Must outlive the op (commit
messages + wip cite old numbers) → **append to the ledger itself**, the only
place surviving wip deletion.

**Flagged for DEC-01-04:** 3 of 4 tombstones are superseded BY Decision 30,
which is itself renumbering. And **Decision 20's body is the last full
description of `compy.input.keys_pressed`** — deleting it removes the record
of WHY it went. Decide per entry in the inventory, not during the sweep.

**Contested, non-blocking, recorded so the trade is visible:** removal is
mandatory, renumbering is optional. Gaps are self-evidently gaps; renumbering
buys a clean sequence at the cost of 165 code citations where a miss is
silent. **If the job is cut short, cut the renumbering and keep the removal.**

## 2026-08-26 — owner: drop decision NUMBERS, use names. Endorsed.

**Endorsed, and on a stronger ground than the owner's own (tidiness):
SAFETY. Missed-citation failure mode inverts.**
- renumbering: a miss still reads `Decision 8`, which **still exists and now
  means something ELSE** → silently wrong, reads authoritative
- naming: a miss still reads `Decision 8` when no numbers exist → **visibly
  dangling**, greppable
With **165 citations in src/+tests**, that difference decides it. Renumbering
hides the failure; naming makes it loud.

Also: naming **dissolves** the tombstone gap + id drift rather than solving
them. Renumbering is a cost paid EVERY removal; naming is paid ONCE.

**Owner's "corpus already annotates them" is HALF true — checked:**
- **headings DO**: `## Decision 8 — per-event combo tables and canonical
  combo serialisation`. So names are **promoted, not invented**.
- **citation sites do NOT**: src/tests read bare `Decision 30`, `(Decision
  21`, `Decision 11's teardown`. The sweep must SUPPLY the name; it cannot
  just delete the number.

**Hard constraint found by measuring — full names cannot go inline:**
- heading names: min 25 / **median 52** / max 98 chars
- src+tests lines already carrying a citation: **median 59**, max 66, against
  the **64-char hard limit**
→ citations must use a **short kebab slug**, full name stays as heading prose.
Recommended `## combo-tables — per-event combo tables and …`, cited as
`(see combo-tables)` ≈20 chars. Bonus: says WHAT IT IS at the point of use,
which `Decision 8` never did.

**Open for owner: how the slug is declared** (slug-first heading vs separate
slug line).

Carried over unchanged: the step-2 gate, the 3 line-broken mentions, plural/
lowercase variants, wip/ out of scope, crosswalk appended to the ledger (needed
MORE under naming — commit messages cite numbers that will exist nowhere), and
the Decision 20 / keys_pressed history question.
**Simpler now:** no one-at-a-time renaming — names cannot collide with
numbers, so substitution is one pass per file once the wrap is proven.
Renumbering spec retained in-file as superseded; its survey/hazards/gate all
still apply.

## 2026-08-26 — slug convention set; inventory drafted

Owner: **short mnemonic slugs, `D-BE-GOOD` / `D-NO-HARM` shape**. Also noted
surprise that citation sites don't use names (asked NOT to spend tokens on
blame forensics — complied, just recorded the fact).

**`D-` prefix earns its 2 chars twice over:** greppable as a class
(`\bD-[A-Z]`), AND cannot be confused with the dead `D-1..D-10` design
namespace in wip/ — digits vs letters, one regex separates them forever.

**Length budget — a consequence worth stating before execution.**
`Decision 8` = 10 chars, `Decision 21` = 11; drafted slugs average ~14.
That is **+3/+4 at EVERY citation site**, against src/tests lines at median
59 / max 66 in a 64-char limit. So **some citation lines will need
reflowing**, and a few already exceed today. → **capped slugs at 16 chars**
and re-tightened the long ones (D-BUTTON-IS-TRIGGER→D-BUTTON-TRIGGER,
D-TEST-BY-BEHAVIOUR→D-BEHAVIOUR-TEST, D-HOOKS-SEEDED-ONCE→D-HOOKS-SEEDED,
D-ISREPEAT-THREADED→D-ISREPEAT). Reflow must land in the SAME commit as the
substitution for that file, never later.

**Drafted the full DEC-01-03 inventory: 29 slugs + 4 removals.** Explicitly
framed as "exists to be argued with, not approved silently."

**Confirmed the pre-existing gap: 19 does not exist.** 33 headings, highest
34. This is exactly the condition naming makes permanent and HARMLESS.

**Surfaced a 5th removal candidate for owner ruling: Decision 12.** Its own
heading says "NOT A DECISION, de-facto behaviour". By conventions/docs.md's
own rule (behaviour predating the feature, merely written down, deserves no
ledger entry) it belongs in an internals guide, not the ledger. Listed with a
slug anyway so the count works either way.

## 2026-08-26 — four open calls closed by owner; ROADMAP.md created

Owner closed all four, each with a TRIGGER rather than an answer:
- **slug table** — no review needed, "I can always grep-and-rename"
- **Decision 12** — STAYS in place; requires context; owner disposes during
  their own review
- **highlighter sentinel** — discuss when we fix the defect (BUG-01-02)
- **ruled-or-swept (14 remarks)** — discuss when we enter that step

Recorded all four in the roadmap's "Parked, with the moment each gets
answered" table — deliberately NOT as open questions, since each has a
trigger. An open question with no trigger is what rots.

**Created `wip/77-new-input-api/ROADMAP.md`** — owner asked to "stabilize a
roadmap I can use to move". Deliberately a SEPARATE doc from plan.md:
plan.md is reasoning + record, carries 3 dated status blocks, never
retro-edited → unusable as a "what next" view. Roadmap = one page, ordered,
current. Added a NAVIGATION block at the top of plan.md's Phases section
pointing to it ("come here for why, go there for what next").

Roadmap contents: state table (HEAD/suite/gate/slices/tags/upstream-86) ·
ACC-01 done · the 4 sprints with **all 28 rows** · ACC-02 (7 steps, blocked) ·
release path · parked-with-triggers · one-line sequence.

Carried the per-row gotchas INTO the roadmap so they are not lost in the
detail docs: BUG-01-05 sibling check · FIX-02-09 fix-with-BUG-01-05 ·
ACC-02-04 must run on `newinput-edge` · **ACC-02-05 sapper section C is
EXPECTED to fail (P19)** · DEC-01 blocks slice cutting · wip/ out of DEC-01
scope.

## 2026-08-26 — OWNER RULING: phases B, C, D DISSOLVE

Owner caught that the roadmap already omitted B/C/D — i.e. I had silently
presupposed the collapse. Owned it: that is exactly the drift the plan
forbids ("never silently drifted from"). Now a RULING, not an omission.

**Owner's framing (recorded verbatim in-plan):** B/C/D were "an attempt to
predict the shape of work before release so it won't be forgotten. This shape
effectively emerged — similar to the guess but different. We do not need
these placeholders any more."

**Not "collapsed into" — DISSOLVED.** The distinction matters and the plan
says so:
- **B (intent check)** → the COLD REVIEWS do it. ACC-01-02 was literally a
  delta check vs the original ask, with satisfied/deviated buckets and
  scaffolding-suspect hunting under "Vocabulary". And done by a reviewer with
  **no stake** — which B, a self-check, could never have been.
- **C2 (disposition table)** → emerged as the defect register. Ids instead of
  principle-mappings; same function.
- **C1 + D** → dissolved outright. "Principles enforced without abstract
  encoding. D was absolutely an abstract guess about how addressing B and C
  outcomes can look."

**Consequence stated so it is not lost:** C1's named "jargon policy" now
exists as 3 concrete rows (FIX-02-06/07/08) rather than one principle. Owner
ruled that acceptable — enforce at the row, do not encode abstractly first.

**This DISCHARGED A GATE AHEAD OF SCHEDULE.** The B→C→D collapse ruling was
scheduled as *step zero of Phase G*. It is settled now. G no longer opens
with it, and the 2026-08-09 status block's "OPEN, GATED DECISION" +
"pending question, not a settled substitution" are superseded — the answer is
that the artifacts were never needed.

**Phase F goes with them** — its "final revalidation, one page" is what
ACC-02-01 (second cold review) is.

**Still pending owner nod:** my U/L/G rename proposal (REC-01 / MERGE-01 /
retire L / PR-01). Note the same dissolution logic applies hardest to **L**:
2 of its 3 items are absorbed (DEC-01-04 supersets its excision list) or
parked (Decision 12), leaving one prose edit. U is NOT analogous — that work
genuinely has not happened.

## 2026-08-26 — rename approved and applied; Decision 11 trail assessed

**Rename applied (owner approved):** `recon` → **REC-01** and LIFTED OUT of
the release path (it is discovery that can spawn defects, not release work) ·
Phase U → **MERGE-01** (4 sub-steps, one per repo) · Phase G → **PR-01**
(5 sub-steps, shrunk — its opener was the collapse ruling, now settled) ·
**Phase L RETIRED**. Applied in ROADMAP.md + plan.md ordering line.

**Phase L retires losing nothing** — its 3 items:
1. excise collapsed decisions → DEC-01-04 (a SUPERSET: also removes 16)
2. Decision 11's withdrawn-rationale trail → **already a row: REMARK `:429`**
   inside FIX-02-01. Same item, second source.
3. demote Decision 12 → parked, owner disposes during review

**Owner asked: is the Decision 11 item important? Answer: no — but there is a
TRAP in how it gets removed.** The passage is TWO paragraphs and only one goes:
- *"Why the original rationale was withdrawn"* → **REMOVE**. Quotes and argues
  against a draft justification that never shipped = exactly what the owner's
  rule retires.
- *"Changed baseline behaviour"* immediately after → **KEEP**. Records a real
  **pre-feature** deviation: a running project without its own keyboard
  handler used to leave the console callback installed → unhandled input
  accumulated in the hidden console and **Enter could evaluate it**. That is
  the plan's own "deviation from pre-feature functionality" category. A
  wholesale block sweep would take it.

**One fact inside the removed paragraph, noted as already-generalised:** the
keyboard/pointer asymmetry was INTRODUCED by this feature, not inherited
(`release_keyboard_route` did not exist at the PR base). That is precisely the
error `conventions/docs.md`'s "de-facto behaviour has a boundary" rule exists
to prevent — lesson already captured, only the instance is being deleted.
Wrote the two-paragraph caution into the FIX-02-01 triage.
