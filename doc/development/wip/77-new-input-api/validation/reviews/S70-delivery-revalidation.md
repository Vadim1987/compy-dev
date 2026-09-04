---
description: delivery-level review of session70 — roadmap integrity, omission, and drift from purpose (step 3 of the closing order)
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-04
---

# S70 delivery revalidation — did the session do what it was for

## Verdict

**Yes on purpose and on conduct; no on the state it left the roadmap in.**

The session was told to execute the S69 dispositions and stop. It ended up rehearsing a
platform merge and rewriting the assembly plan, and **every one of those transitions was
owner-directed** — verified commit by commit: each commit in the range names the
instruction that caused it, and no commit opens a subject the owner had not asked for.
There is **no self-initiated scope growth in this range**. The five dispositions the
session owned (F2, F3, F4, F7, F8) were *worked*, not declared — each has a diff behind
it — and F5 came back from the owner into `conventions/docs.md` and a register entry,
which is the right shape: a successor meets it in the persistent corpus, not in a commit
message. The reconnaissance itself is the session's best work, and its distinguishing
quality is that it **built things instead of arguing about them**: the trial merge, the
rebase-versus-merge construction, the three-way stack.

What did not hold is the **roadmap**. `MERGE-01-05` was redefined mid-session from *"the
edge"* to *"the #45 import"* and its section's standing prose was never re-read, so the
sprint now tells the successor the opposite of what the successor's own prompt tells it,
in two places. The same shape — a row rewritten, its other homes not read — is the shape
of S69's F4, which this session was executing at the time. Five statements in `ROADMAP.md`
and one in the merge plan describe a plan that no longer exists.

And on the question this review was asked to weigh above the rest: **the method that
produced the two corrected metrics is sound in its instrument and unsound in its sentence,
it is unchanged, and it left four more instances standing in this same range** — one of
which the session created *after* writing the cell that warns against exactly it. See
Finding 6.

---

## Findings

### 1 — The merge plan's order table prescribes a merge commit and a zero-failure gate. The owner replaced both, and the table was never revisited.

**What.** `validation/reviews/S70-merge-plan.md` §1, row 3:

> | 3 | **merge PR #45's head into our branch** as one merge commit | `MERGE-01-05` | **both suites present, 0 failures** |

Both halves are superseded. The import is **one squashed commit** — the plan's own §2
explains at length why a merge parent must not be created (*"a merge commit's second
parent can become unreachable… treat the merge as disposable"*), and `session71/prompt.md`
says `git merge --squash`. And the commit **is allowed to be red** by owner ruling; green
is required by the end of the sequence, not by the end of that commit.

**Evidence.** `git log -L 25,34:…/S70-merge-plan.md` shows row 3 unchanged since the
plan's first commit `799d17e7`. §2 was revised twice after it (`23b87b1e`, `bb94c151`) and
the red-commit ruling landed later still. `git grep -n "allowed to be red"` returns
`session71/prompt.md` and `session70/report.md` **only** — the ruling is nowhere in the
merge plan, and `S70-import-strategy.md` §4 still presents it as an **open owner call with
three options**, recommending (a).

**Why it matters at delivery level.** `session71/prompt.md` names the merge plan as
reading #1 and the import strategy as #2, in that order, "before touching anything". A
successor that reads its reference documents in the order it is told to reads *merge
commit, gate at zero failures, and the red-commit question still open* before it reaches
the prompt's own instructions. This is the single step the next session exists to execute,
and its plan of record contradicts its commission on the two most mechanical points in it.

---

### 2 — `MERGE-01`'s standing prose says the platform tree is not touched again and that `MERGE-01-05` is deliberately not scheduled before the PR. Both are now false.

**What.** `ROADMAP.md:1633-1640`, the two paragraphs closing the `MERGE-01` section:

> **`MERGE-01-04` is already done**, so what moves is only the example half — the platform
> tree is not touched again, and the platform slice cut is unaffected either way.
>
> …The platform half is `MERGE-01-05`, and it is deliberately **not** scheduled before the PR.

`MERGE-01-05` is now the #45 import: it touches the platform tree by roughly 3000 upstream
lines, it changes the platform slice cut (`PR-01-01` is re-based on `updev + #45` because
of it), and it is scheduled **before** `ACC-02` and therefore well before the PR — that is
step 3 of the merge plan and the whole of session71.

Third instance in the same section: **"Mechanic, standing: pull each upstream into its own
branch; never merge into the working branch as the first move."** The import does exactly
that, deliberately, and nothing reconciles the two.

**Evidence.** `git log -S "deliberately **not** scheduled before the PR"` →
`c898e12f` only, the commit where `MERGE-01-05` still meant *the edge*. The row was
redefined at `345b0861` and `eff15aaf`; the surrounding prose was not touched again.

**Why it matters at delivery level.** This is S69's F4 recurring inside the session that
was executing F4 — *a pass that edits a row owes a read of the row's other homes*
(`agents/rules/roadmap.md` §5, applied one degree out). A reader who lands on the section
prose rather than the row gets the opposite instruction, and the section prose is the part
that reads like settled policy.

---

### 3 — `REC-01`'s header, status paragraph and summary cell, and `MERGE-01`'s summary cell, all still describe the pre-session state.

**What.** Four statements, all stale as of this session's own work:

| where | says | actual |
|---|---|---|
| `ROADMAP.md:37` (summary table, `REC-01`) | *"platform repo **done**; the three example repos remain"* | all four repos measured, `REC-01-01/-02/-03` all read **DONE (2026-09-03)** |
| `ROADMAP.md:1540` (section header) | *"**PARTIALLY COMPLETE (Session 55)**"* | every row in the sprint is now DONE |
| `ROADMAP.md:1542` (section body) | *"Its remaining half is the three example repos"* | there is no remaining half |
| `ROADMAP.md:1560` (*Session 55 status*) | *"Recon for external example submodules… remains pending"* | not pending |
| `ROADMAP.md:38` (summary table, `MERGE-01`) | *"`maze`, `keyboard`, `balloons` remain"* | `maze` and `balloons` need nothing; and *"platform repo done"* is now the misleading half, because `MERGE-01-05`/`-06` are platform work |

**Why it matters at delivery level.** `ROADMAP.md`'s own header says *"this file is the
sequence"*, and the summary table is the cell most readers reach first — S69's F4 said
exactly that about the same table. A sprint whose rows read DONE under a header that reads
PARTIALLY COMPLETE is the contradiction F4 was raised about, one sprint over.

---

### 4 — `DOC-01-07` is not in the `DOC-01` table. It is a lone pipe-row between two blank lines.

**What.** `ROADMAP.md:1398-1401`: the `DOC-01` table ends at `DOC-01-06`, then a blank
line, then the `DOC-01-07` row, then another blank line. A single `| … |` line with no
header/delimiter pair above it is not a table — it renders as literal pipe-separated text.

**Evidence.** `sed -n '1397,1402p' ROADMAP.md`; the blank lines are present in the commit
that introduced the row (`9287cee8`) and were never closed.

**Why it matters at delivery level.** `DOC-01-07` is the one row the owner instructed by
name at boot (*"plan as separate non-design step in documentation block of the roadmap"*),
it is `PROP-01`'s only discharged carve-out, and it is cited from three other places in
the file. It is the one row in the range that must be visible in a rendered read of a file
the owner reads, and it is the one that is not. Purely mechanical to fix.

---

### 5 — Two of `PROP-01`'s three pre-PR carve-outs are owned by no row, and one of them is unreachable as written.

**What.** `ROADMAP.md:1731-1739` names three carve-outs that stay pre-PR.

- **Carve-out 1** (`DOC-01-07`) is a row. ✔ (subject to Finding 4)
- **Carve-out 2** — the destination of the proposal block — is attributed to
  `PR-01-02`/`-03`. **Neither row mentions it.** `PR-01-02` is *"the justification table in
  the PR description"*; `PR-01-03` is *"reviewability gate: `doc/input_api.md` + the
  description, alone"*. The carve-out exists only in the `PROP-01` prose.
- **Carve-out 3** — the contract-or-defect ruling on Escape — is owned by nothing before
  `PR-01`. The only row that names it is `PROP-01-05`, and `PROP-01` runs **after**
  `PR-01` by the ruling this session recorded. `PROP-01-05`'s own text reads
  *"implementation of whatever the pre-PR ruling decided"* — it presupposes a ruling that
  no row schedules and no sprint before it holds.

**Evidence.** `grep -n "Escape\|destination" ROADMAP.md` returns the summary cell, the
`PROP-01` prose and `PROP-01-05` — and nothing in `DOC-01`, `ACC-03` or `PR-01`.

**Why it matters at delivery level.** These are the three things the placement argument
*bought* by moving `PROP-01` after the PR; the whole recommendation rests on them being
taken first. Two of them are unowned, and one is scheduled into the sprint it was carved
out of. Concretely: carve-out 2 is what keeps the proposal block — author handles, a
`remark:` line, unresolved alternatives, and a citation of `sync-input-proposal.md` that
does not exist in the tree (`doc/input_api.md:934`) — out of the guide the PR is reviewed
from. That dangling citation is recorded in **five `wip/` documents and zero ledgers**, so
if the carve-out is never taken, nothing outside a deletable tree remembers it.

---

### 6 — The method behind the two corrected metrics is unchanged, and it left four more instances standing in this same range. One was created after the cell warning against it was written.

This is the review's answer to the question it was asked to weigh above the rest.

**The instrument is sound and is the session's best quality.** Both corrections came from
*measuring*, and the measurements are correct: the 49-of-1005 audit closes both ways
(842+114+34+15 = 1005; 35+10+3+1 = 49), and the three-way finding was established by
running all three application routes. Nothing about the evidence-gathering needs changing.

**The failure is not in the measurement, it is in the sentence that reports it**, and it
has one shape every time: **a measurement is taken over set A, and the claim is stated
over a set that contains A.**

| instance | measured | claimed | caught by |
|---|---|---|---|
| revert risk | every line our diff removes | *"340 lines of lost upstream work"* | **owner** asked how it was derived |
| import mechanism | bare `git apply` failed | *"`merge --squash`, not `diff \| apply`"* — a whole category ruled out | **owner** asked whether the git machinery was needed |
| `maze` branches | six of eleven | *"all eleven are ancestors of our head"* | **cold peer review** |
| `keyboard` cost | *"merges clean"* | *"costs nothing"* | **owner** asked whether it had been checked |

Four instances, and **every single catch was external** — three owner questions and one
commissioned reviewer. The session's own process contains no check for this class, which
is why the two it caught were caught late and the ones below were not caught at all.

**Four uncorrected instances survive in the committed range:**

- **`ROADMAP.md:1649` (`PR-01-01`) says "114 shipping files".** The figure was corrected to
  **113** at `ea0c05c0` when the drift document left the corpus, and the note the row cites
  says 113. Re-derived at HEAD with the row's own classifier command: **113**. This is a
  roadmap cell quoted after its subject moved — which is verbatim the lesson the same
  session wrote into `FIX-02-07` at `3871cb4d`: *"every count that has gone wrong in this
  phase has been a roadmap cell quoted after its subject moved."*
- **`ROADMAP.md:1608` says the merge plan carries "ten risks".** It carries twelve
  (`R1`–`R9`, `R11`, `R12`, then `R10` out of order at the end). `session71/prompt.md` says
  twelve. The roadmap cell was written at `799d17e7`, when it was ten.
- **`technical_debt/general.md:249`, the BACKLOG heading, reads "The branch is 16 commits
  behind…"** while its own first bullet reads *"**15** are this entry. *(Not 16 …)*"*. The
  heading states the number the body exists to reject, and the heading is the part a ledger
  reader scans. Related: that bullet's decomposition — *"71 commits ahead; 52 are the
  rework, 15 are this entry"* — does not close (52+15 = 67). The gap is four merge commits
  (`git rev-list --count --no-merges HEAD..5a52cba2` = 67), and nothing says so.
- **`DOC-01-07`'s re-derivation command names the wrong number of unwanted hits.** The row
  says `git grep -n 'experimental' -- doc/ CHANGELOG.md ':!doc/development/wip/'` returns
  *"two more the row does not want"*. It now returns **three**: `clock.md`, the proposal
  block's own line, and **`technical_debt/general.md:249`** — the heading in the bullet
  above, which **this same session added, at `2a8ddc11`, after writing the row at
  `9287cee8`**. The one instance where the session invalidated its own re-derivation
  command inside the same day.

**Judgement.** The method *does* produce more of these, and the two that were corrected
are not the last two. But the diagnosis "be more careful" is wrong and the session knew it:
its own remedy, stated in the `FIX-02-07` cell, is **state the command and forbid citing
the figure**. That remedy was applied to exactly one cell. It was not applied to
`PR-01-01`'s 114, to the *ten risks*, to the BACKLOG heading, or — most consequentially —
to the successor's prompt (Finding 7). The gap between *knowing the rule* and *the rule
being an instrument the next session runs* is the whole finding.

---

### 7 — S69's F8 was half-discharged: the roadmap clause landed, the successor-prompt line did not, and `session71/prompt.md` carries no numeric discipline at all.

**What.** F8's disposition reads: *"Fold into F1's rewrite: the working form is **command +
explicit do-not-cite**, and it belongs on roadmap cells… **Worth one line in `session71`'s
prompt.**"* The first half landed (`3871cb4d`, the `FIX-02-07` clause). The second half was
not written.

**Evidence.** `session71/prompt.md` contains no instruction to state a command beside a
number, no do-not-cite clause, and no re-derivation discipline. Its only occurrence of the
word "command" is in the reading list. For contrast, `session70/prompt.md` opened with the
lesson at length (*"Record the exact command beside any number you state"*, *"Say which
grep you mean"*, *"A count is not a scope statement"*, *"Do not assert a number in a commit
that lands before the change that makes it true"*) — four paragraphs, all dropped.

**Why it matters at delivery level.** Session71 is a session that will produce numbers: a
new suite baseline and its arithmetic, a 49-line audit to account for line by line, a
re-generated slice cut. It boots without the one discipline its predecessor concluded
(carry-forward #3 of its own report) that it was missing, and F8 was the disposition that
asked for it in writing.

---

### 8 — The successor prompt does not name `T-DRIFT-PR45`, and nothing routes the successor to this review.

**What.** Two gaps in `session71/prompt.md`:

- It closes `T-DRIFT-KEYBOARD` by name at step 0 but **never mentions `T-DRIFT-PR45`**, the
  ACTIVE register entry whose entire content — the 52 commits, the 11 shared files, the
  five re-pins, the Ctrl+S decision, the 1100/22 measurement — *is* the work being
  commissioned. Nothing tells session71 to retire or update it when the import lands, so
  the ledger will read ACTIVE over work that is done.
- The prompt was written at `a9218cda`, **before** the delivery review was commissioned at
  `61a95112`. It points at the cold peer review's outcome by way of the report, but there
  is no path from session71's boot to this document.

**Why it matters at delivery level.** The commissioning prompt for this review states that
*"the successor opens by executing that table"*. As the tree stands, it does not, because
nothing in its boot path reaches the table. That has to be repaired by hand before
session71 boots, and it is the one disposition below that must be taken first.

---

### 9 — F6 came back from the owner and is recorded only in the session chain.

**What.** F6 (*promote the ephemeral-id re-derivation to a pre-PR gate*) was answered
*"I need to discuss it"* and held. It is recorded in `session70/report.md` (*Left open,
deliberately*), in `session70/track.md`, and in `session71/prompt.md` (*Open with the
owner*). It is **not** on `T-EPHEMERAL-IDS`, not in `agents/validation.md`, and not in
`conventions/docs.md`.

**Why it matters at delivery level.** Contrast F5, handled in the same session and
correctly: it went into `conventions/docs.md` **and** a register entry, so it survives the
tree. F6's held state survives only as long as each session copies it into the next
prompt — a chain with one break in it and the question is gone, and the class it guards
(`T-EPHEMERAL-IDS`, 116 citations) is one of the largest still open. One line on
`T-EPHEMERAL-IDS` — *"a pre-PR gate for this was proposed 2026-09-03 and is with the owner"*
— closes it. This is a difference of kind, not degree, from F5, and the session met the
standard once on the same day.

---

### 10 — Drift from purpose: clean on substance, incomplete on the mode rule's second half.

**What.** Test D's question is answered in the session's favour. Walking the range commit
by commit, every transition names its instruction: `c898e12f` (*"Owner widened the scope
this session"*), `345b0861` (*"Owner direction: build on top of PR #45"*), `4dabdabe`
(*"Owner, 2026-09-03: some proposals can be weighed"*), `aba72cc5` (*"Owner refinement,
same day"*), `2a8ddc11` (*"Owner, 2026-09-03: every drift can be described as a debt
entry"*), `db926377` (*"Owner asked for an evaluation… that can be shown"*), `edfad40d` /
`d6e76dfb` / `9590f89a` / `56f451c2` (each opens with the owner's question), `5b0d93d4`
(*"did you analyze all drifts by essence"*), `23b87b1e` (*"The owner's scheme"*),
`633370c4` (*"Owner asked for the anchors… to be recorded"*). **Nothing in the range is
self-initiated scope growth.** The one place the session chose its own method rather than
its subject — throwaway clones outside `/repo`, `merge-tree --write-tree` instead of a
worktree — is method, and it was the right call under the no-parallel-worktrees rule.

**What was not discharged** is the second clause of `agents/validation.md`'s operational
modes rule: *"When a session notices it has crossed one, **say so and let the owner decide
whether to continue or hand over cold** — a fresh session is cheap next to a design built
inside a long, heterogeneous context."* `session70/track.md`'s **Mode** section still reads,
unchanged from boot:

> Execution (S69 dispositions F1–F4, F9) then evaluation + replanning (the proposal block's
> placement). Both named; the second stops at a recommendation and waits for the owner.

That was accurate for the first two commits of thirty-eight. It was never re-named after
the session became a four-repository reconnaissance, three trial merges, a built three-way
stack, an import-strategy assessment and a rewritten assembly plan — research-and-analysis
at the largest scale this phase has run. **This is not a scope finding; it is the rule's
own diagnostic going unread.** Given the outcome — Findings 1, 2 and 3 are all *"a plan
rewritten late in a long context, and its neighbours not re-read"* — the hand-over-cold
option the rule offers was the one worth putting to the owner, and it was never put.

---

## What held, stated because it is load-bearing

- **`ANCHORS.md` is usable.** Every command in it was run: `git merge-tree --write-tree
  upstream-https/dev upstream-pr/45` prints `a8cb98e2…` exactly; the invariant command
  `git diff a8cb98e2… HEAD -- src/ tests/` executes as written; all **ten** `-https`
  remotes exist across the four repositories (5 + 1 + 2 + 2); all **twelve** round-3 tags
  exist and resolve. It is the strongest artifact the session produced and the successor
  can execute from it.
- **The three cold-peer-review findings are genuinely applied**, not declared: the outward
  link in `upstream-drift.md` now resolves (`../../../../../input_api.md`), `git grep
  "doc/development/upstream_drift" HEAD -- doc/` returns only the review documents that
  narrate the move, and the partition row now reads `3a` **20** and sums to 113.
- **F2/F3/F4/F7/F8 were worked, with diffs** — `dd630d4a`, `580b56b2`, `c2a8aa83`,
  `3871cb4d` — not asserted. F1 and F9 were correctly identified as already applied by
  session69 at `924efc43`, and that was verified rather than assumed.
- **F5 is recorded where a successor meets it**: `conventions/docs.md` (persistent corpus)
  plus a BACKLOG entry with the split's target-by-target table. This is the model F6 should
  have followed.
- **`agents/validation.md` carries the moving baseline correctly** — it states 1122
  (1100 + 22), names the commit that must update it, and says why a stale one is dangerous.

## What could not be checked

- **The throwaway-clone suite numbers** (693/0, 753/0, 760/0, 1100/22, 1108/22) were not
  rebuilt — same reasoning step 1 gave. They are quoted consistently everywhere they appear
  and the one piece of arithmetic on them (1094 vs 1100 → six of our own contracts) closes.
- **Whether the owner said each quoted thing.** Owner rulings are recorded here, not
  weighed, per this review's scope.
- **`lua-lsp` was not queried** — no `.lua` changed in the range, so there is no
  language-server outage to report.
- One count worth flagging without acting on it: the session's own commit total is stated as
  **33** in `session70/report.md` and **36** in `agents/validation.md`, and the range is now
  **38** (`git rev-list --count 1299ed2b..HEAD`). 36 was true when written; 33 never was.
  The `agents/validation.md` one is in the shipping corpus. Folded into Finding 6's class
  rather than raised separately.

---

## Dispositions

| # | finding | action | owner |
|---|---|---|---|
| **8** | successor prompt names no `T-DRIFT-PR45`, and nothing routes session71 to this review | **Take this one first.** Add to `session71/prompt.md`: a pointer to this document as the opening task, and a step retiring/updating `T-DRIFT-PR45` when the import lands | **successor session**, before session71 boots |
| **1** | merge plan §1 row 3 says *merge commit* and *gate at 0 failures* | Rewrite row 3 to *one squashed commit, three-way, allowed to be red; green by the end of step 4*. Record the owner's red-commit ruling in `S70-import-strategy.md` §4, replacing the three-option question with the decision taken | **successor session** |
| **2** | `MERGE-01`'s standing prose contradicts `MERGE-01-05` | Rewrite the two closing paragraphs of the `MERGE-01` section; add a clause to the standing mechanic saying the import is the stated exception to *never merge into the working branch* | **successor session** |
| **3** | `REC-01`/`MERGE-01` headers, status paragraph and summary cells are pre-session | Mark `REC-01` complete or say what remains; update both summary-table cells; retire or date-stamp the *Session 55 status* paragraph | **successor session** |
| **4** | `DOC-01-07` sits outside the `DOC-01` table | Delete the two blank lines. One-line fix | **successor session** |
| **5** | carve-outs 2 and 3 of `PROP-01` are owned by no row; the Escape ruling is unreachable | Give the Escape ruling a row **before** `PR-01` (a `DEC-` or `PR-01-0x` row, not `PROP-01-05`), and put the block's destination on `PR-01-02` or `-03` in words. **Which sprint holds the Escape ruling is the owner's call** — it decides whether the release documents a data-loss path as intended behaviour | **successor session** (rows) / **owner** (where the Escape ruling sits) |
| **6** | four uncorrected instances of the corrected metrics' own class | Fix the four: `PR-01-01`'s **114 → 113**; *"ten risks"* → **twelve**; the `general.md` BACKLOG heading **16 → 15**, and state that 71 includes four merge commits; `DOC-01-07`'s *"two more"* → **three**, naming `general.md:249`. Apply the `FIX-02-07` treatment (command + do-not-cite) to each figure rather than replacing one number with another | **successor session** |
| **7** | S69 F8's successor-prompt line was never written | Add the numeric discipline to `session71/prompt.md` — *state the command beside any number; do not cite a roadmap or ledger figure, re-run it* — in the same edit as Finding 8 | **successor session** |
| **9** | F6 recorded only in the session chain | One line on `T-EPHEMERAL-IDS` recording that a pre-PR gate was proposed 2026-09-03 and is with the owner. Then it survives a break in the prompt chain | **successor session** (the line) / **owner** (the ruling itself, still held) |
| **10** | the mode rule's second half went unread; substance is clean | **No action on scope** — the record is that every transition was owner-directed. The transferable half is that a session running a large mode change should put the hand-over-cold option to the owner while the context is still short. Worth one line in a future prompt; not worth a row | **no action** |
| — | `ANCHORS.md`, the peer-review fixes, F2/F3/F4/F7/F8's execution, F5's placement, the moving baseline | Checked; sound | **no action** |
