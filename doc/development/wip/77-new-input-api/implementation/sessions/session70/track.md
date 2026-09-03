---
description: session70 running track — S69 delivery dispositions, then the proposal block's roadmap placement
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# session70 — track

## Boot — 2026-09-03

- Fresh start: `prompt.md` only, no `track.md`/`report.md` on disk. No
  re-entrance reconciliation needed.
- HEAD `1299ed2b` *"new suggestions (feedback on documented input_api shape)"* —
  **the owner's own commit**, landed after session69 wrapped at `6ca5c53d`.
  53 added lines in `doc/input_api.md`: a new `## Proposed updates/changes`
  section carrying two proposal sets (`@dsent` DevX amendments 1–5, `@nagydani`
  minimalistic surface) and a resolution paragraph.
- Tree: clean but for the known scratch (`broken-busted/`, `claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`, the three
  nested example repos).
- Suite: `busted tests` → **1055 / 0 / 0 / 10**, LuaJIT 2.1 in the container.
  Baseline confirmed, not a finding.
- Read in full: `agents/validation.md`, `agents/sessions.md`, `prompt.md`,
  session69's `report.md`, `validation/reviews/S69-delivery-revalidation.md`.

## Owner instruction at boot — a second workstream

The session opened with an API outage; the owner re-issued the task and added
one:

> "we have new design calls (just committed 'proposal' section in the input_api
> doc) — it should be planned as roadmap step. ideally before the PR, but not
> blocking current stabilization and cleanup work. maybe it should be *after*
> PR (but one of those proposals promotes the status of already shipped feature,
> so at least one documentation fix will be required — plan as separate
> non-design step in documentation block of the roadmap)"

Reading of it, to be confirmed with the owner before execution:

- The proposal block is **planning work, not execution work** — it becomes a
  roadmap sprint of its own, and the placement (pre-PR vs post-PR) is the
  question to settle.
- The promoted feature is `get_text()` (`FEAT-03`, session68), which
  `doc/input_api.md` currently marks **experimental / may be withdrawn** at
  session69's own ruling. Proposal item 1 says the "until somebody needs it"
  condition has now occurred. That retraction is **documentation, not design**,
  and goes in `DOC-01` as its own row.

## S69 delivery dispositions — executed

F1 and F9 were **already applied by session69 itself** (`924efc43`), which the
review's own commit message says; nothing to redo. Verified the `FIX-02-07` cell
before touching it.

- **F2** `dd630d4a` — the two `design/` citations in `technical_debt/input.md`.
  Both are references, not defect locations, so both take the `FR-n` treatment.
  Re-ran the widened pattern afterwards: the only remaining hits in the
  persistent corpus are the six handed to `LEDGER-02` plus the new entry's own
  illustration lines.
- **F2 + F3** `580b56b2` — three ledger bullets. `T-EPHEMERAL-IDS` gains the
  path class's closure and the pattern that covers it; `T-NEVER-SHIPPED` gains
  the six citations and the conditional repoint; `T-ARGUES-INTERIM` gains
  `D-HOOKS-SEEDED`'s *"never asked for"*.
- **F4** `c2a8aa83` — `DOC-01` runs before `ACC-03` in all three places. Both
  stale cells kept the 2026-09-01 reasoning verbatim and say which row renamed.
- **F7 + F8** `3871cb4d` — recorded on the rows, not in a note: `FIX-02-07` gains
  the do-not-cite clause, `DOC-01-06` drops its own 119 and carries the `-05`
  ordering wrinkle to be decided when the row opens.
- **F5, F6** — owner rulings, raised, not taken.

## The proposal block

Assessment on disk: `validation/reviews/S70-proposal-block-placement.md`
(`5b03cb33`). Seven items, three kinds of work. The two things the block does not
say about itself:

- **Item 2 reverses Decision 37**, which `FIX-02-01` closed against and `FEAT-01`
  implemented — and the `serial` consumer already migrated to the payload split.
  Reopening pre-PR migrates it twice.
- **Item 4 is the one with a severity argument**: Escape clearing is a
  *documented* contract and the proposal calls it a P1 data-loss path. Ruling on
  it is cheap; implementing it is not. Recommended as a pre-PR ruling with no
  implementation.

Recommendation: `PROP-01` **after `PR-01`**, three pre-PR carve-outs — the
`get_text` promotion (`DOC-01-07`, landed `9287cee8`), the destination of the
block itself, and item 4's ruling.

Found while reading: **`sync-input-proposal.md` is cited by `doc/input_api.md`
and is not in the tree.**

## Owner rulings — 2026-09-03, four questions put, four answered

1. **`PROP-01` runs after `PR-01`.** The recommendation stood. Sprint written
   (`97839691`), seven rows, three carve-outs named.
2. **`REC-01`/`MERGE-01` — scope widened.** *"recon and merge against not only
   these repos, but against platform again — most likely our changes will be
   combined with another PR, and drift evaluated towards edge. I need all this
   measured and analyzed on recon stage."* Plus **https remotes**, all repos
   public, so nothing depends on their SSH access.
3. **F5 — `agents/` is NOT in the corpus.** *"Agents are not in the corpus and
   will be carved out alongside with wip/. They can bear references into wip/.
   It's a working surface that is not promoted to upstream."* Recorded in
   `conventions/docs.md`; **the ruling creates a class the same minute** — 19
   citations of `agents/…` sit in documents that do ship. Filed unslugged.
4. **F6 — the pre-PR gate: *"I need to discuss it."*** Held. Nothing written to
   `agents/validation.md`.

## REC-01 — executed the same session

Measurement: `validation/notes/S70-REC-01-drift-measurement.md` (`c898e12f`),
round-3 tags in all four repos, `TAGS.md` updated.

Shape of the answer, in the order it changed my picture:

- **0 behind `aldum/dev`.** The re-merge against the PR base is a no-op today.
- **Four open PRs upstream, two of them input-touching**, and **the edge already
  contains both**. So *"drift towards edge"* is the right instrument and it was
  the owner's instinct — one measurement covers #45 and #41.
- **The two files this feature is most about auto-merge.** The collisions are
  semantic and small in number: the constructor signature, `set_text`, and the
  key semantics the guide documents.
- **The example repos are empty rows.** That discharges the 2026-09-02 ordering
  argument (merge before smoke) almost for free.

Method note worth keeping: **`git merge-tree --write-tree` predicts conflicts with
no worktree**, which is how the dry merges were taken without violating the
no-parallel-worktrees rule or touching the tree the LSP indexes.

## Second owner round — three corrections and a question

1. **`agents/` splits, it does not leave whole.** *"Generic rules like commenting
   and code guides and doc formatting may survive; workflow and pointers and
   operational limitations (git rules) should not — they are local to my work."*
   So the F5 finding stops being "19 sites" and becomes a table by target:
   **4 confirmed defects** (3 cite `agents/validation.md`, 1 `development.md`),
   **11 waiting on two calls** (`ledgers.md` 9, `roadmap.md` 2), 4 likely fine
   (`rules.md`, whose commit-convention half is still local). `aba72cc5`.
   The repair — *state the rule instead of pointing at it* — is immune to the
   split, which is why it need not wait for the two calls.
2. **`PROP-01` is an analysis sprint first.** *"Some props can be weighed,
   disputed or reshaped as remarks already suggest."* `-01` is now the holistic
   pass; declining an item with a reason is a result. `4dabdabe`.
3. **Build on #45, ship together; the edge's remainder later.** Answered by trial
   merge rather than by argument — `validation/notes/S70-PR45-as-base.md`,
   `345b0861`.

## The #45 trial — method notes worth keeping

- **Throwaway clone outside `/repo`**, never a worktree under it. The shared tree
  never held a merge and the LSP index was never polluted.
- **`src/util/string` and `src/lib/metalua` are submodules.** A fresh clone fails
  38 specs until they are copied in. Cost me one wrong hypothesis.
- **Both suites in one tree is the instrument.** Ours 1055, theirs 753, merged
  1100/22 — and the *shape* of the 22 is the answer, not the number.
- **Two candidate causes were falsified rather than assumed**: `set_text` (tested
  both ways, editor failures identical) and `tests/mock.lua` (their harness adds
  145 errors in our specs and fixes none of theirs). What remained was the
  probe's own `--ours` on `controller.lua`.
- The convergence nobody planned: **`D-EXACT-RESERVE` chose `ctrl+s` /
  `ctrl+shift+s` as its worked example, and #45 uses the same pair differently.**

## Third owner round — inventory, stakeholder doc, merge plan

Instruction: recon the example repos **again** and deeper (`dsent`'s keyboard and
maze specifically; **balloons is frozen — owner guarantee**); describe every drift
as a **debt entry with blast radius and cost**, so prioritisation becomes
replanning; produce a **stakeholder-showable doc in this repo** evaluating all four
drifts; **ignore PR #22**, it will be superseded; then a **merge plan evaluated for
risks**.

Measured, deeper than the first pass:

- **maze: zero, on every branch** — `dsent/dev`, `feat/reconcile`, `main`, `v1`
  through `v3.4`, all ancestors. The first pass checked only the tracked branch;
  the answers agree, but only the second one is safe to plan against.
- **keyboard: one commit**, `.compy/build`, no source. And its upstream repo has
  been **renamed** — `dsent/keyboard` → `dsent/compy.keyboard`, resolving today by
  redirect only. Found by an API call that returned *"Moved Permanently"*.
- **the edge beyond #45 is 16 commits and is not input-free.** The storage-fallback
  commit widens the widget label to `{text, tone}` — and **our public `prompt` key
  writes exactly that field**. A surface widening arriving from another line, by
  accident.
- **after #45 is merged, the edge remainder conflicts in 5 files**, two of them my
  probe's artifacts; genuinely the console model, an **add/add on the colours
  example** (same file, two routes, 245 vs 247 lines) and `.gitignore`.

Landed: `2a8ddc11` three register entries (2 ACTIVE, 1 BACKLOG; **maze gets none —
zero drift is not debt**), `db926377` `doc/development/upstream_drift.md` in the
**persistent** corpus and citation-clean by construction, `799d17e7` the merge plan
with ten risks.

**The risk worth the owner's eye is R1** and it is not technical: merging #45 while
it is open puts its 52 commits inside our PR's diff, which defeats the
reviewability gate. Mitigation is landing order, which is not ours to execute.

## Fourth owner round — "by essence, not by merge"

The question that earned the most: *"did you analyze all drifts by essence?
exactly not only 'will it merge cleanly' but 'will the changes interfere/break our
tree'?"* **Honest answer at the time: #45 yes** (a merge resolved and run), **keyboard
yes at its scale** (what the build script emits), **maze not applicable**, **the edge
no** — conflict prediction plus a reading of commit subjects. Closed it:
`validation/notes/S70-edge-essence-and-stack.md`, `5b0d93d4`.

**The finding the whole exercise exists to catch, and it was there.** The edge's
Android exit commit reroutes every full exit through a request the quit handler
consumes. One of the call sites it rewrites is the `ctrl+escape` handler — **a line
this branch moved** into the reservation table. Their rewrite lands on the old
location; our reservation does not conflict with it and keeps calling
`love.event.quit()` directly, so the device stops returning to its launcher.
**The defect is in the line that does *not* conflict.** Invisible to the merge tool,
invisible to a headless suite, one line to fix — and the fix is in the built tree.
Generalised into the plan as R11: *for every upstream commit that rewrites a call
site, ask where that call site is in our tree.*

**The stack was built, not argued:** ours 1055 → +#45 1100/22 → +the whole edge
**1108/22, the same 22**. The edge adds no new failure; its own two casualties were
positional call sites against #45's changed signature (R6 biting a second time).

**Two corrections to my own published numbers.** The remainder is **15**, not 16 —
the FS durability API is already an ancestor of our head, and an *edge-minus-#45*
range does not subtract *ours*. And the phase's stakeholder doc and register both
carried the wrong figure for an hour.

**Landscape clarifications absorbed** (owner): #45 is the target base **by content**
and is **force-pushable**; we stay on this branch for continuity and **ship a patch
set** — *"slices" were always patches*; release order is #45 → ours → the edge
remainder, and they must stack. Plan mechanics rewritten accordingly: the merge is
**disposable reconciliation**, nothing shipped may depend on ancestry, every
generation base is pinned, and a moved base means **re-run the stack**, not merely
re-apply.

## Open — the owner's message ended mid-sentence

*"3) for keyboard and maze"* — truncated. Asked rather than guessed.

## Mode

Execution (S69 dispositions F1–F4, F9) then evaluation + replanning (the
proposal block's placement). Both named; the second stops at a recommendation
and waits for the owner.
