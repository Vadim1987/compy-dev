# Task 4b — Incorporation check (pre-deletion doc curation)

_Commissioned by the opus-sweeper PM (session06), 2026-07-13. You are a **cold analyst**
(Opus). Read-only curation over the #77 feature doc corpus. Repo root = cwd. **You produce ONE
recommendations doc; you move/edit/delete NOTHING.**_

## Why this task exists

The #77 code sweep is COMPLETE and the owner intends to **delete `doc/development/wip/77-new-input-api/`
before opening the PR**. Before that deletion he needs assurance that **nothing durable is lost** —
that any content worth keeping in the permanent docs corpus has been identified and given a
promotion target. That is your job: decide **what, if anything, should be promoted out of `wip/77`
into the main docs corpus before the wip dir is deleted.**

You are NOT deciding whether to delete (that is the owner's call, after reading your output). You are
NOT ruling on any open design question. You produce a curation recommendation.

## Inputs — read these, in order

1. **`doc/development/wip/77-new-input-api/WIP-DOC-INDEX.md`** — the navigable index of all 253 wip
   docs. Its **"Likely incorporation candidates (reviewer shortlist)"** section (tiered 1-4) is your
   primary worklist. You do **not** need to read all 253 docs; read the index, then read in full only
   the shortlist candidates you're weighing (and spot-open anything the index leaves ambiguous).
2. The **tier-1/2/3/4 keep candidates** the index already flags — weigh each:
   - **Tier-1** `design/notes/ratified-model.md` (strongest keep), `design/notes/input.md` (verbatim
     stakeholder ticket), plus `design/spec.md`, `design/design.md`, `design/requirements.md`.
   - **Tier-2** `notes/input-contracts.md` (self-nominates `internals/` promotion; read with its
     applied `input-contracts-correction.md` + `input-contracts-revalidation.md`),
     `notes/stakeholder-3-input/{compy-input-quirks,compy-lua-game-patterns}.md`.
   - **Tier-3** the frozen impl specs (`design/spec/M5c-dispatch-chain.md`, `M7-02-recut.md`,
     `M8-02-recut.md`) — keep only if per-milestone spec history is wanted beyond the shipped code +
     `spec.md`.
   - **Tier-4** the process/methodology retros (`notes/retro-contract-provenance.md`,
     `notes/talk/two-tier-test-strategy.md`) — keep only if the cross-cutting SDLC lesson is wanted.
3. The **target corpus layout**: `doc/development/{overview,conventions/,internals/,drawing_system}`,
   the top-level `doc/` (user-facing guides — `doc/input_api.md` is the shipped input user guide),
   and `doc/development/tests.md`. Know where a promoted doc would actually live.

## Two specific sub-questions you MUST answer

- **A. `doc/development/internals/user_input.md` is pre-sweep stale.** It still describes the deleted
  `oneshot`/`push('userinput')` auto-hide as the *current* mechanism and (lines ~430-432) asserts the
  `compy.input.*` callbacks "do not exist in `src/` yet" — false post-sweep. This is an **existing
  main-corpus doc, not a wip doc**, but its fate is entangled with this curation: recommend one of
  **(a) rewrite it to the landed system** (and if so, does any wip doc — e.g. `notes/input-contracts.md`
  — become the source material?), or **(b) supersede it** with `doc/input_api.md` + a fresh internals
  doc, or **(c) leave for a later pass**. Give a reasoned pick; the owner rules.
- **B. This session's two committed review artifacts live under `wip/77/reviews/` and will be deleted
  with the dir**: `reviews/intent-alignment-verdict.md` (the Fable intent-alignment verdict) and
  `reviews/owner-rulings-verified.md` (the PM's fact-checked owner-rulings list). Decide whether either
  belongs in the permanent record (promoted somewhere durable, folded into the PR description, or
  allowed to die with the wip dir). The 8 owner rulings in the latter are still open — factor that in.

## Output — write exactly one file

`doc/development/wip/77-new-input-api/reviews/incorporation-recommendations.md`, with:

- A short **top-line**: how many keep-candidates, and the single most important one not to lose.
- A **table**, one row per keep-candidate: *what it is* · *recommended target path* · *action*
  (straight move / merge-into-existing / distill-then-promote / keep-in-place / drop) · *one-line
  rationale, citing the index entry or the doc*.
- A **"safe to let die with the wip dir"** list — the process ephemera / superseded drafts / session
  logs you are affirmatively saying carry no durable value, so the owner can delete with confidence.
- Answers to sub-questions **A** and **B** above, each a reasoned recommendation.
- A **controversies / gaps** section: anything you couldn't resolve, any candidate where the call is
  genuinely the owner's, any place the index and the docs disagree. **Do not auto-resolve these.**

## Boundaries (hard)

- **Read-only.** Do not move, edit, rename, or delete any doc. Do not `git rm`. Your only write is the
  recommendations file above. Do not touch the nested example checkouts' `.git`.
- **Recommend, don't rule.** Where a keep/drop call is really a design or product judgment, say so and
  route it to the owner via the controversies section — don't bury a ruling inside a recommendation.
- **Cite.** Every keep/drop recommendation names the index entry (or the doc + line) it rests on, so
  the PM can spot-check without re-reading the corpus.
- When done, your final message to the PM: the top-line count, sub-question A/B picks, and any
  controversy that needs the owner — concise; the file holds the detail.
