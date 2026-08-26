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
