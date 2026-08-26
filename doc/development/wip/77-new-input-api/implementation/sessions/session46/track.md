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
