---
description: Cold delivery-level revalidation of session68 — roadmap integrity, omission, and drift from the strategic frame, over c610805b..HEAD
status: revalidation report
audience: developer
authored: llm
session: 68
date: 2026-09-03
---

# S68 — delivery-level revalidation

**Commission:** [`validation/prompts/S68-delivery-revalidation-commission.md`](../prompts/S68-delivery-revalidation-commission.md).
Step 3 of the closing order. Cold reader: `sessions/session68/track.md` was opened only for the two
specific questions the commission put (the rulings, and the peer review's place in the record).
Range read: `c610805b..HEAD` (`1a864137`), **31 commits** by `git rev-list --count` — 29 to
`882ba6c3` as the report claims, plus the wrap and this commission. The cold peer review
([`validation/outcomes/S68-cold-peer-review.md`](../outcomes/S68-cold-peer-review.md)) was read
first so its ground is not re-walked; **none of its clearances is overturned below**, and its two
findings are confirmed applied.

## Verdict

**Yes — the session leaves the feature materially closer to a releasable PR, and the plan it hands
forward is sound in its ordering and honest about its own limits. The single most important delivery
fact is not the one the report leads with.** The report leads with `CHG-01` completing, which
discharges the gate on `ACC-02` **and every slice cut** — that is true, verified, and the largest
structural move in the range. But the fact that will cost someone something is the one underneath
it: **`compy.input.get_text()` — the only public surface change in this release that no example
project calls and no manual checklist mentions — shipped with five container unit tests as its
entire evidence, and the roadmap row that ships it asserts that `ACC-02` exercises it on the device.
Nothing in `ACC-02` does.** `ACC-02`'s lists are `doc/development/smoke_checklists.md`; the same
session edited that file at 21 sites and added no step for the function it had shipped four commits
earlier. The suite is confirmed at **1055 / 0 / 0 / 10** on LuaJIT 2.1.1703358377 in 2.38 s; `lua`
is not on `PATH` in this container, so **PUC Lua — the interpreter the owner actually runs — is
unverifiable here** and no claim below implies otherwise.

The record-keeping is, again, unusually good, and the heaviest integrity check passes: **every row
this session ticked preserves its original filing**, verbatim where the convention applies
(`FIX-02-05`, `FIX-02-17`, `FIX-02-22`), and the two rows whose own text was edited — `CHG-01-02`
lost the word *"four"*, `FIX-02-07` lost the number *37* — **both disclose the edit in the same
cell, name the superseded figure, and say why**. **No row was redefined to match what was done.**
Three cells state a limit against the row's own interest (`CHG-01`'s third defect found after the
tick, `FIX-02-05`'s snapshot-versus-section correction, `FIX-02-17`'s lowercase-only grep), and the
report's §7 "Mistakes" is a truthful list rather than a ritual one. The nine dispositions from the
S67 delivery review all landed, each in its own commit or folded into the row it belonged to, and
**none was marked done on the strength of an adjacent edit** — I checked each individually.

**Seven findings, none blocking.** One is a record-integrity gap in the workflow's own first
execution (F1: the peer review of record was never committed, and the wrap carried no track entry).
One is the verification gap above (F2). One will cost the session that opens `LEDGER-02` an hour and
a recount (F3). The rest are stale prose and a homeless ruling. **On drift from purpose: the new
public call is a net gain for the frame, not a cost** — see the drift section — but it landed with
its device-side verification unscheduled, and that is the trade to put back to the owner.

---

## F1. The peer review of record was never committed, and the wrap commit carried no track — the first run of the new closing order left step 1 outside git

**Claimed / planned.** `report.md` §9 lists, among the session's new artifacts,
*"`validation/outcomes/S68-FIX-02-05-base-evidence.md`, **`validation/outcomes/S68-cold-peer-review.md`**,
two commissions in `validation/prompts/`"*. `agents/validation.md`, *"Closing a session — the
three-step review order"*, closes with: *"Both prompts and both outputs are materialized on disk —
`validation/prompts/`, `validation/outcomes/` for the peer review, `validation/reviews/` for the
delivery review."* Its wrap rule is explicitly mechanical: *"commit the wrap (**track** + successor
prompt + repointed pointer) as one `docs` commit."*

**What I checked.** `git status --porcelain`; `git ls-files` over
`validation/outcomes/`; `git show ace9a6b8 --stat`; `git log --oneline -- .../session68/track.md`;
and the tracked state of the S67 equivalent as the precedent.

**What I found.** **`doc/development/wip/77-new-input-api/validation/outcomes/S68-cold-peer-review.md`
is untracked (`??`).** It exists in this working tree and nowhere in the history. Everything else the
session produced is committed — both commissions (`e7fd2af7`, `1a864137`), the delegated evidence
document (`7727674f`), the report, the successor prompt — and `S67-cold-peer-review.md` **is**
tracked, so this is a break in the file's own precedent rather than a convention I am inventing.

The second half compounds it. The wrap commit `ace9a6b8` contains exactly three files:
`agents/validation.md`, `session68/report.md`, `session69/prompt.md`. **No `track.md`.** The track's
last commit is `61f9d0eb`, which lands *before* the peer-review commission `e7fd2af7`, so
`session68/track.md` ends at *"F2 finished last, and nearly did not happen"* and contains **no entry
for the peer review being commissioned, for its two findings, for the wrap, or for this delivery
commission**. `agents/sessions.md` §3's trigger is *"worthy, re-checked every turn"*; a cold review
returning two confirmed findings against the session's central claim is worthy by any reading, and
`agents/validation.md`'s wrap rule names the track as one of the three things the wrap commit
carries.

**Why this ranks first.** The peer review is the evidence behind two corrections that are now
asserted as fact in four persistent documents (`ROADMAP.md`'s `FIX-02-05` and `FIX-02-17` cells,
`technical_debt/general.md`, `technical_debt/input.md`) — every one of them says *"peer review,
2026-09-03"* and points at a document a fresh clone does not have. A `git clean -fd`, a new
container, or the owner's own machine loses it. And `session69/prompt.md` tells its successor it is
**the first session to run the three-step order end to end**: the precedent it will copy is one
where step 1's output never entered the repository.

**Correction I propose.** Commit the file at its existing path (its content is already referenced by
path from the commission and from four cells, so the path must not change), and append the missing
closing entries to `session68/track.md` — the peer review, the wrap, the delivery commission — in
session69's first commit, dated as the late record they are. Add one line to `session69/prompt.md`
noting that step 1's artifact was committed a session late, so the first end-to-end run does not
teach the omission. **Nothing needs re-doing**; this is a `git add` and three track bullets.

**How sure.** Certain on every fact. `git status` and `git ls-files` are not interpretable two ways,
and the wrap commit's file list is three lines long.

---

## F2. `get_text()` shipped with no manual or on-device coverage, and its own roadmap row says `ACC-02` covers it

**Claimed / planned.** `ROADMAP.md:27` (the `FEAT-03` stage row): *"it changes the public surface, so
`CHG-01` carries its line, **`ACC-02` exercises it**, and a slice cut before it lands is cut twice."*
The section body repeats it: *"it changes the **public surface**, so `CHG-01` must carry its line,
**`ACC-02` should exercise it on the device**"* (`:583`–`:584`).

**What I checked.** `ACC-02`'s own section (`ROADMAP.md:1397`–`1440`), which names its source
document in one line — *"Lists: [`doc/development/smoke_checklists.md`]"* — and enumerates its five
steps as per-project smokes (`balloons`, `keyboard`, `maze`+`draw`, `sapper`, `turtle`). Then
`grep -n "get_text" doc/development/smoke_checklists.md`; the file's full heading outline; and
`git grep -n "get_text" -- src/examples` plus a scoped `grep` over the three untracked nested repos
(`balloons`, `keyboard`, `maze`).

**What I found.** **`get_text` appears nowhere in `doc/development/smoke_checklists.md`**, and **no
example project calls it** — the only `get_text` hits under `src/examples` are `widget_text_label` /
`widget_text_line` in `balloons/graphics.lua`, unrelated names. The checklist is organised strictly
by example project and exercises the API only through what those projects do, so there is no step
that could exercise `get_text` even incidentally. `ACC-02` therefore cannot exercise it, and the
`FEAT-03` row's assertion that it does is not true of any scheduled step.

The precedent cuts against the omission rather than excusing it: when `FEAT-02` changed the surface,
the checklist was updated for it — `smoke_checklists.md:479` records *"Last mechanism change:
2026-08-30, `FEAT-02` — the prompt now closes itself through `auto_hide`"*, and `ACC-02-05`'s note
in the roadmap is written around that change. `FEAT-03` did the analogous surface change and did not
do the analogous update, **in the same sitting in which it edited that very file at 21 sites** for
`FIX-02-09`'s vocabulary slice. The two passes were hours apart.

So the release's one new public call has, as its entire evidence: five unit tests in
`tests/input/input_cursor_text_spec.lua` under mock LÖVE, run on **LuaJIT 2.1.1703358377** in this
container, plus one scratch spec that was executed and deleted. **PUC Lua, which the owner runs, has
never seen it** (`lua` is not on `PATH` here), and neither has a display.

**Correction I propose.** Two edits and one question. (1) Add a `get_text` row to
`smoke_checklists.md` — the natural home is `turtle`'s section, which already drives a `compy.input`
widget with a callback, or `balloons`' section B, which is about what submit delivers; a two-line
check (type, read back without submitting, and read after a `hide` for `nil`) is enough and costs
the owner seconds during a pass they are running anyway. (2) Soften the two `FEAT-03` sentences to
what is true — that `ACC-02` *should* gain a step, naming it — or, if the step is added, leave them
alone. (3) **The question for the owner:** a public call with no manual coverage is a defensible
trade for a read-only getter with five unit tests, but it should be a *decision*, not an artefact of
the sprint finishing in one sitting. `ACC-03`'s cold read is the backstop the `CHG-01` section
already leans on for the same reason, and it reads prose, not behaviour.

**How sure.** Certain that `get_text` is absent from `smoke_checklists.md` and from every example.
Certain that `ACC-02`'s lists are that file, because its section says so in one unambiguous line.
The judgement — that this rises to a finding rather than to routine deferral — rests on the row
having *claimed the coverage*; without that claim I would have filed it as a note.

---

## F3. `LEDGER-02` — the row `FIX-02-05` exists to feed — is still sized on numbers this session superseded, and its debt goal still carries the count the peer review disproved

**Claimed / planned.** `FIX-02-05` ran precisely so `LEDGER-02` and `CHG-01-03` would not each
re-derive the base check: *"One pass, one classification, **two consumers**"*, and
`LEDGER-02-01`'s cell says *"take `FIX-02-05`'s base-check classification — **do not re-derive it**;
re-deriving is how one check becomes two walks that disagree."* The peer review's **F0** was
confirmed and applied: the walked set was 56, the section held **59** when the claim was written and
**61** now.

**What I checked.** Recounted both `RETIRED` sections at HEAD by the documents' own method
(`awk` from the `## RETIRED` line, `grep -c '^### '`): `input.md` **53**, `general.md` **8** —
**61**, matching the corrected claim exactly. Then read every place that sizes `LEDGER-02` or states
the retired count, and diffed each against `c610805b` to see which the session updated.

**What I found.** The correction landed in **three** places — `ROADMAP.md`'s `FIX-02-05` cell,
`T-RETIRED-UNVER`'s `Resolution` in `general.md`'s `RETIRED` section, and the `FIX-02-17` cell for
the companion `23 → 20` figure — and **not in the two that size the next row**:

- **`technical_debt/general.md:81`, `T-NEVER-SHIPPED`'s `Where`** — the *live* `ACTIVE` debt goal
  `LEDGER-02` is filed against — still reads *"**56 entries, 50 + 6, counted 2026-09-03**"*. That is
  the exact figure the peer review disproved, dated the exact day it was wrong on, sitting **235
  lines above** the retired entry in the same file that says the section *"stands at 61"*. One
  document, two counts, no cross-reference. It is mitigated — the same bullet adds *"**Do not trust
  this number either — count it when the row opens**"*, which is S67's F3 disposition in its durable
  form and is why this is F3 and not F1 — but a reader who takes the number takes a wrong one.
- **`ROADMAP.md:1316`, `LEDGER-02`'s section body** — *"**Sized on measurement, 2026-09-01:** 47
  retired entries (45 in `input.md`, 2 in `general.md`). **Fourteen already state the defect was
  ours, seven state pre-existing**, and ten cite the base explicitly."* Untouched in this range
  (`git log -S` puts it at `e00784e4`, before the session). It is **30% short** of the true 61, and
  its 14/7 proportions are now **superseded outright** by the classification the session produced —
  39 / 9 / 5 / 3 — which the same section, five paragraphs above, correctly says exists and must be
  taken rather than re-derived. The row therefore tells its executor to take a classification of 56
  and, further down, to size itself against a measurement of 47.
- The same stale pair survives inside `T-NEVER-SHIPPED` itself (`general.md:101`): *"Measured
  2026-09-01… 47 retired entries **(51 today — see *Where*…)**"* — and *Where*, twenty lines up, now
  says 56. Three numbers for one set inside one entry.

**Why it matters at delivery altitude.** This is the same defect class the session named twice and
wrote into `session69/prompt.md` as its first lesson (*"a count in a document is a snapshot, and
yours will be too"*), applied one row downstream. `LEDGER-02` *moves entries out of a persistent
register* — the one row in the plan whose mis-sizing costs more than time, because
`LEDGER-02-02`'s inbound-citation check (S67's F9, correctly landed) is run per entry, and an
executor who believes there are 47 will not notice that fourteen were never considered.

**Correction I propose.** One edit each, no re-derivation: (a) `T-NEVER-SHIPPED`'s `Where` →
*"61 entries, 53 + 8, counted 2026-09-03; the pass walked a 56-entry snapshot — see
`T-RETIRED-UNVER`'s resolution for the five outside it"*, keeping the *"do not trust this number"*
sentence verbatim; (b) delete or date-stamp the *"Measured 2026-09-01… 47"* bullet in both the entry
and `ROADMAP.md:1316`, replacing the 14/7 proportions with a pointer to the real classification
(39 / 9 / 5 / 3 over the walked 56, five unwalked and dispositioned); (c) carry the five unwalked
entries' disposition into `LEDGER-02-01`'s cell in one clause, so the row that consumes the
classification knows its input covers 56 of 61 and where the other five are argued.

**How sure.** Certain on the counts (recounted at HEAD, 53 + 8 = 61, by the documents' own method)
and on which documents were and were not updated (diffed against `c610805b`). The ranking — that
this outranks the stale prose below it — is a judgement, and it rests on `LEDGER-02` being a row
that deletes things.

---

## F4. The disposition of the five unwalked entries holds, but it is argued in a retired entry and the row that consumes it does not know

*(This is the commission's question 3, answered, and it is a clearance with one carry.)*

**Claimed / planned.** *"All five are `INTRODUCED-IN-BRANCH` and the check is not close: every one is
about `CHANGELOG.md`, `doc/input_api.md`, this register, or `auto_hide` — three of those four do not
exist at `3256aac` at all."*

**What I checked.** The claim's load-bearing half, directly: `git cat-file -e 3256aac:<path>` for
`CHANGELOG.md`, `doc/input_api.md`, `doc/development/technical_debt/input.md` and
`doc/development/technical_debt/general.md`.

**What I found.** **All four are absent at the PR base** — not three of four; the register files are
absent too, so the disposition is *stronger* than stated. A defect whose subject is a file that does
not exist at base cannot have existed at base. `auto_hide` is this feature's by construction. **The
five need no further pass**, and the row does not owe one: re-walking them would produce the same
answer by the same command, which is exactly the *"one check becomes two walks that disagree"* the
plan is written to avoid.

**The carry.** The argument lives in `T-RETIRED-UNVER`'s `Resolution` — a **retired** entry in
`general.md`'s `RETIRED` section. `LEDGER-02-01` says *"take `FIX-02-05`'s base-check
classification"* and points at the evidence document, which covers **56**, not 61. Nothing in
`LEDGER-02`'s own text says *"and five more are dispositioned in the retirement note of the entry
this row's sibling paid"*. That is the commission's *"a consequence named in one document and not
carried into the one that acts on it"*, in its mildest form — one clause, folded into F3's proposal
(c) above.

**How sure.** Certain that the four subject files are absent at base — `git cat-file -e` either
resolves or it does not. Certain that `LEDGER-02` does not name the five. My reading that the
disposition is sufficient is a judgement, and I hold it firmly: the classification question for
these five is not close enough to be worth a session's time.

---

## F5. `ROADMAP.md` now asserts twice, of two different rows, that each is "the last surface change"

**Claimed / planned.** `ROADMAP.md:26`, the `FEAT-02` stage row (✅, session58): *"**leads for the
same reason `FEAT-01` did, and it is the last surface change**: it moves a key out of the show-only
category, so `FIX-02-01`'s neighbours and **every slice are sized against it**."* `ROADMAP.md:584`,
the `FEAT-03` section body (✅, this session): *"It is the **third and last** surface change."*

**What I checked.** `git grep -n "last surface change"` across the tree; the two cells in full; and
whether the session touched the `FEAT-02` row in this range (`git diff c610805b..HEAD` on
`ROADMAP.md`) — it did not.

**What I found.** Two live, mutually exclusive claims in one file, twenty-two lines and one stage
table apart, both in ✅ rows. The only other occurrence in the tree is
`sessions/session59/prompt.md`, a frozen historical record where it was true when written. The
`FEAT-02` row is the one a reader meets first — it is in the top-of-file stage table, which is what
the roadmap's own preamble sends a reader to for *what next* — and its version carries the
consequence: *"every slice is sized against it"*. Slices are sized against `FEAT-03` now. Nothing
has actually been cut (`PR-01-01` is the shipping cut and is last by construction), so the practical
damage is zero today and the hazard is entirely in what a slice-cutting session would believe.

**Correction I propose.** One clause in the `FEAT-02` row: *"the last surface **break**"* — which is
what it actually was, and what distinguishes it from `FEAT-03`, an addition — or *"the last surface
change until `FEAT-03`, 2026-09-03"*. Do not un-tick anything. This is `roadmap.md` §5's second
failure mode exactly (*"a citation that still resolves, to a heading that no longer means what it
did"*), one level up: a sentence that still parses and no longer holds.

**How sure.** Certain on the facts; the two sentences are quoted verbatim above and `git grep`
returns exactly the three hits named. Low consequence, high confidence — ranked here rather than
lower because it is the only case in the range where a completed cell says something now false, as
opposed to something merely stale.

---
