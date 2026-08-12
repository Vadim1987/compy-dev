# session39 — P-17: do for `maze` what session37 did for `keyboard`

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session38/report.md` in full, then the session38 commissioning
prompt and its track. Create `session39/track.md`. Do not edit any historical session artifact.

Baseline: `busted tests` → **946 / 0 / 0 / 10**. It has not moved for three sessions. The 10 pending
are sanctioned; an **eleventh** is a finding.

## Where the sprint stands

**P-18, the keyboard deepfix, is DONE and closed** — across sessions 37 and 38, through four
independent cold revalidations. Its record: `../session38/report.md`, and §§8-11 of
`../../../validation/reviews/P-18-00-triage-and-plan.md`. Two things from it you inherit:

- **`keyboard` is at `e568961`, clean, nothing pushed**, and its gesture behaviour is **provably
  identical to upstream** (a parity harness over 385 stimuli, zero differences). Do not reopen it.
- **What it still owes is a human's:** `doc/development/smoke_checklists.md` has **eighteen `[new]`
  rows** and nothing in that work has ever run in a game scene. That is the owner's to schedule, not
  yours to satisfy.

## Your task — P-17, and the method is the point

**P-17-00 is `maze`'s merge, evaluation and plan** — the same three moves `keyboard` had. The owner's
instruction for this session is explicit and is about **process, not just outcome**:

1. **Find out which session created `P-18-00`** and what it did first. *(It was **session37** — that
   is not a secret and you may take it. What you may not take is a summary of how it worked.)*
2. **Read that session's report in full** — `../session37/report.md` — and its track,
   `../session37/track.md`, which is where the *sequence* is visible: a prerequisite discovered at
   boot, an upstream **input assessment written before anything was merged**, the merge and its
   correction as separate commits, then the analysis-and-design pass, then a triage that decomposed
   the step into numbered children. Read the artifacts that pass produced, not only the account of
   them: `../../../validation/reviews/S37-keyboard-upstream-input-assessment.md`,
   `../../../validation/reviews/P-18-00-keyboard-deepfix-design.md`, and
   `../../../validation/reviews/P-18-00-triage-and-plan.md`.
3. **Apply the same process to `maze`.** The shape, in the order session37 found it necessary:
   - **Assess the upstream first, for input, before merging anything.** The owner's own words at the
     time: *"we'd have to review/reprocess updated code because there could be more places for new
     API adoption. But first of all I need your evaluation of what's new in the origin commits since
     merge-base: did the author invent new input mechanisms, reconsider old input practices? This
     validation is important to do before any merges."* That assessment is a written deliverable,
     and it is what makes the merge a decision rather than an event.
   - **Then the merge**, if the owner rules it, in the shape they ruled for `keyboard`: a real merge
     onto a new branch so later re-merges stay cheap, with **any defect it introduces corrected in
     its own commit**. `keyboard`'s clean merge produced a *broken tree* — upstream's new code called
     a function this branch had deleted, and no hunk touched both files, so git could not see it.
     **Expect the same class of fault and look for it deliberately.**
   - **Then the analysis-and-design pass and the triage**, producing numbered children (`P-17-01`,
     `P-17-02`, …) with the rulings the owner owes named explicitly, before any of them starts.

**Stop and raise, do not decide:** whether the merge happens, and its shape, are the owner's. So is
every behaviour question the assessment turns up.

## What is known about `maze` at wrap (verify it, do not trust it)

- On branch `newinput` at **`a045fdb`**, clean. Its own remote; **`origin/v3.4` is its current PR
  base**, and it is **4 ahead / 0 behind** that.
- Its upstream for this work is **`dsent/dsent/dev`** (the `dsent` remote, *not* `origin` —
  `repos.txt`, untracked, names it). **4 ahead / 26 behind**, merge-base `12f675f`; the delta is
  **37 files, +4920 / −1208**.
- **`pr-assembly-guide.md` §5.1 governs the slice ref**: `diff <upstream>..HEAD` is a reviewable
  change only while `<upstream>` is an **ancestor** of `HEAD`. The guide keeps `origin/v3.4` for
  `maze` today and says switch to `dsent/dsent/dev` **only when P-17-00 merges it**. Check with
  `git merge-base --is-ancestor <ref> HEAD`.
- **`maze` has never been examined for input** the way `keyboard` was. It is the last example the
  sprint owes that treatment.

## Standing constraints

- **NEVER push** — not this repo, not the nested three. Commit locally at your discretion, one
  concern per commit, suite stated in every message even when untouched.
- **A deviation lives in the workspace**, not only in a commit message.
- **No comment in an example repo may cite a platform doc** (owner ruling, 2026-08-12;
  `agents/rules/commenting.md`, "Citations"). A `doc/…` path cannot be followed from a repository
  that does not contain it.
- **Adoption is the point of the sprint** (owner ruling, 2026-08-12): the test for a remaining
  `love.*` call is *"is the replacement justified on its own terms"* — not *"can the project avoid the
  API"*, and not renaming for its own sake.
- **The game's rules are not ours.** *"Would a player notice a difference?"* If yes, it is out of
  scope — raise it, do not do it. This is `keyboard`'s ruling and it generalises.
- **Delegate the mechanical down** (Sonnet, model passed explicitly, prompt of record on disk, worker
  never touches git state, parent reviews the diff site by site and commits). **Cold reviews are
  worth their cost, and a review that builds an instrument beats one that inspects** — session38's
  four passes are the evidence, §§8-11 of the triage.
- Smoke with `stdbuf -oL`: `timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/maze`.
  Run it from `/repo`. Without line buffering the kill discards the output and a raising project
  looks healthy.
- The owner works in this tree: **name the paths you stage**, never `git add -A` in a directory they
  also use. Session38 swept an untracked file of theirs into a commit exactly that way.

## A note on this prompt's shape

`agents/sessions.md` would make the successor of a judgment-heavy session a **revalidation** task.
That revalidation was performed *inside* session38 — four independent cold passes, the last of them
narrow — so the owner named this session's task directly instead. If you disagree after reading the
report, say so before starting rather than after.
