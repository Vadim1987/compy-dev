---
description: Opus delivery-level review of session69 — roadmap integrity, omissions, drift from purpose (step 3 of the closing order)
status: active
audience: developer
authored: llm
session: 69
date: 2026-09-03
---

# S69 delivery revalidation

Range `1a864137..HEAD`, 33 commits, no `.lua` touched. Step 3 of the three-step
closing order; the cold peer review (`validation/outcomes/S69-cold-peer-review.md`)
is step 1 and its four findings were applied at `82a65b9d` — I did not re-derive
them, I checked whether the corrections closed.

## 1. Verdict

**The session did what it was for.** All three parts of its mandate are
discharged and checkable: the seven S68 delivery dispositions land as named
commits under five recorded owner rulings; `FIX-01`'s three rows are worked, not
declared; and the stop held — nothing in the range touches `REC-01`/`MERGE-01`,
and both the report and the successor prompt raise them as owner territory. The
re-entrance guardrail worked as designed after the first incarnation died. The
scope call on the ~120 sprint-id citations was **right, and it was raised in the
right order** — the escalation is recorded in the track *before* the execution
commits, not narrated afterwards, which is the opposite of the silent-drift
failure `agents/validation.md` warns about; the session changed mode from
housekeeping to execution to rule-making and named each transition to the owner
first. The new standing rule in `conventions/docs.md` is sound on its merits:
short, reachable from `agents/rules.md`'s index, non-contradictory with
`ledgers.md` §5 (which fixes the citation direction as roadmap→register only),
and it states its own escape hatch. And the prose rewrites that deleted material
do not lose it — I spot-checked the `configure(config)` field list and the
`compy.input` inventory against `doc/input_api.md` and the peer review's own
D-TWO-SURFACES diff, and the deletions are restatements, not sources.

What it did *not* do is close its own floor. `FIX-01-02` is ticked complete over
**two live sites of its own class that its derivation never saw** (F2) and over a
residue whose only home is an ephemeral note (F3); the marker arithmetic the peer
review was commissioned to fix is **still not internally consistent** and now
asserts a gate that does not exist (F1); and the roadmap still contradicts itself
about where `DOC-01` runs, in a cell this session edited around (F4). None of
these is blocking and none changes a decision the session made. All are
counting-and-citation defects in the session's *own subject*, which is why they
are worth the successor's first hour.

## 2. Findings

---

**F1 — the `FIX-02-07` marker series still does not close, and the correction
that answered the peer review invented a gate that does not exist.** `correction`

*What.* `ROADMAP.md:844` now narrates: *"**29 across 10 files** at session69's
boot, and **24 across 10 files at 2026-09-03** — `FIX-01-01` retired five … and
`FIX-01-02`'s `FR-n` translation retired two more."* Five plus two is seven;
twenty-nine minus seven is twenty-two. The series does not close because **29 is
the anchored count and 24 is the raw count** — two different questions, presented
as one before-and-after.

*Evidence.*

```sh
git grep -o 'REMARK'    1a864137 -- 'doc/' ':!doc/development/wip/' | wc -l   # 31
git grep -o '^> *REMARK' 1a864137 -- 'doc/' ':!doc/development/wip/' | wc -l  # 29
git grep -o 'REMARK'    HEAD     -- 'doc/' ':!doc/development/wip/' | wc -l   # 24
git grep -o '^> *REMARK' HEAD     -- 'doc/' ':!doc/development/wip/' | wc -l  # 22
```

Both series drop by exactly 7, matching the attribution. Either 31→24 or 29→22 is
correct and internally consistent; 29→24 is neither.

Compounding it, the caveat added at `82a65b9d` says *"the gate counts
`^> REMARK`"*. **There is no `doc/` gate.** `agents/rules/commenting.md:154` is
`grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/` — unanchored, and
scoped to `src/` and `tests/`. `ROADMAP.md:54` says so itself: *"marker gate
(`src`/`tests`) — clean, but it never covered `doc/`, which is `FIX-02-07`."* The
`^>` form is how markers happen to be written in Markdown, not a rule anyone can
cite.

*Why it matters at delivery level.* This cell is the answer to a question the
**owner asked directly**, it is the row's size estimate for a sprint that has not
opened, and it is the one number in the range that a peer review specifically
looked at and corrected. The correction added true sentences beside a series it
left mixed, and grounded the distinction in a gate that will not survive being
looked up. A successor sizing `FIX-02-07` from this cell inherits both.

---

**F2 — `FIX-01-02` is ticked complete over two live sites of its own class that
the derivation never saw.** `correction`

*What.* Two ephemeral path citations remain in the persistent corpus, both in
`technical_debt/input.md`, both pointing into the **frozen `design/` tree** that
leaves with `wip/77`:

- `:1432` — *"(`design/notes/decisions.md`) — restated in two project-facing documents…"*
- `:1437` — *"The frozen `design/spec.md` names `validator` / `highlighter` as the project-facing configuration…"*

*Evidence.*

```sh
git grep -nE 'design/|pr-slices|pr-assembly|sessions/session' -- 'doc/' ':!doc/development/wip/'
```

Both predate the session (`5bab6f4e`, session68) — so this is a **miss, not a
regression**. `validation/notes/FIX-01-02-03-rederivation.md:30` lists
`technical_debt/input.md`'s class-A sites as `:1557`, `:2046` only. The
re-derivation caught relative `validation/…`, `ROADMAP.md` and `plan.md` forms —
the session's own best insight, *"a path citation does not have to spell the
path"* — and then stopped one directory short of `design/`, which is the one
sub-tree of `wip/77` the phase treats as authoritative and therefore the one most
likely to be cited by name.

*Why it matters at delivery level.* The row's stated subject is *"ephemeral
citations in the persistent corpus"*. It is ticked ✅ COMPLETE in three places, no
ACTIVE debt entry covers ephemeral **paths** any more (`T-EPHEMERAL-IDS` scopes
itself to ids), and no downstream row owns these — `FIX-03-05` is retired ids,
`DOC-01-06` is live ids. They ship unless someone re-runs a grep nobody is
scheduled to run. This is precisely the shape the row existed to end.

---

**F3 — `FIX-01`'s residue lives only in documents that die with `wip/77`.**
`correction`

*What.* Two hand-offs, both recorded only in ephemeral files:

1. **Six path citations → `LEDGER-02`.** Argued well and in the right place
   (`ROADMAP.md:1343`, with the conditional obligation *"if this row keeps
   either, that entry owes the repoint"*). But `T-NEVER-SHIPPED`
   (`technical_debt/general.md:79–125`) — the debt goal `LEDGER-02` serves —
   **does not mention them.** I read the entry end to end; its `Revisit` line is
   a bare `LEDGER-02` and nothing else.
2. **R100's residue → `DEC-02`.** `FIX-01-01-enumeration.md:24` parks
   `D-HOOKS-SEEDED`'s *"never asked for"* on `DEC-02`. `grep -n 'HOOKS-SEEDED'`
   over `ROADMAP.md`'s `DEC-02` section and over `T-ARGUES-INTERIM` returns
   nothing in either. The class has a live goal, so this one is covered
   generically; the specific site is not.

*Evidence.* `awk '/^### T-NEVER-SHIPPED/,/^### T-EPHEMERAL/' doc/development/technical_debt/general.md`;
`grep -n 'HOOKS-SEEDED\|never asked for' doc/development/wip/77-new-input-api/ROADMAP.md doc/development/technical_debt/general.md`.

*Why it matters at delivery level.* The session's own `prompt.md:62` handed it
this exact lesson: *"A finding parked against another row's opening leaves with
that row. A disposition said 'take it when `FIX-02-05` opens that file anyway';
`FIX-02-05` closed and it had not been taken."* The standing rule is the same —
a finding goes to the ledger the moment it is found, because a plan document is
not where state lives. Two residues were parked against future openings and
neither reached a persistent register. The roadmap prose is better than a
disposition table was, and it is still `wip/`.

---

**F4 — the roadmap contradicts itself about where `DOC-01` runs, in the same
cells this session edited.** `correction`

*What.* Three statements, two of them wrong:

- `:11` (the one-line sequence, which the session edited): `… ACC-02 → FIX-02 (b) → FIX-03 → DEC-02 → LEDGER-02 → DOC-01 → ACC-03 → PR-01`
- `:1365` (the section header): *"runs after FIX-03, before **ACC-03**"* ✓
- `:36` (the summary table): *"and **before** `ACC-02` because a cold reviewer should read the prose that ships"* ✗
- `:1619`: *"`DOC-01`, which runs after `FIX-03` and before `ACC-02`"* ✗

*Evidence.* `grep -n 'before `ACC-02`' doc/development/wip/77-new-input-api/ROADMAP.md`.
Both stale cells are byte-identical at `1a864137` — they are leftovers from the
2026-09-01 placement, orphaned by the 2026-09-02 `ACC-02`/`ACC-03` split, and
**pre-date this session**.

*Why it matters at delivery level.* I raise it here rather than leaving it to
`FIX-03-05` because this session **added a step to `DOC-01`** and **rewrote the
one-line sequence** in the same range, so `DOC-01`'s placement was under its hand
twice. The rule it fails is `agents/rules/roadmap.md` §5, *the pass that causes
the orphan owes the fix*, applied one degree out: a pass that edits a row owes a
read of the row's other homes. Two of the three sentences a reader can land on
give the wrong ordering, and the wrong one is the one in the summary table most
readers reach first.

---

**F5 — `agents/` survives `wip/77` but sits outside the corpus rule the new
convention uses, and a standing rule already cites a path that will dangle.**
`note`

*What.* The persistent-corpus rule (`agents/validation.md`) is *"everything under
`doc/` that is not under `doc/development/wip/`"*, and `T-EPHEMERAL-IDS`'s
re-derivation command inherits it verbatim (`-- doc/ ':!doc/development/wip/'`).
`agents/` is excluded by construction — yet it is the rule chain, it is more
durable than the ledgers, and it carries 28 `wip/77` path citations.

Most of those are in the feature's own boot planes (`dev.md`, `review.md`,
`sweep.md`, `validation.md`), which are arguably as ephemeral as the tree they
point at. **One is not:** `agents/rules/ledgers.md:69` states where the vacuum
archive lives — `doc/development/wip/77-new-input-api/validation/archive/` — from
a standing rules document that outlives the feature. The sprint ids in
`agents/rules/` are all illustrative (`roadmap.md:66`, `:81`), the same exemption
`conventions/docs.md`'s own two illustrations get.

*Evidence.* `git grep -nE 'wip/' -- agents/rules/`;
`git grep -ohE '\b(ACC|ARC|LEDGER|FEAT|BUG|FIX|CHG|DEC|OP|REC|MERGE|PR|DOC)-0[0-9](-[0-9]{2})?\b' -- agents/rules/`.

*Why it matters at delivery level.* The session minted a rule about what dangles
when the tree is deleted and scoped it to a corpus definition that omits the
files that most obviously survive. One concrete instance, and a scope question
that is the owner's: is `agents/` in the persistent corpus, or is it a fourth
thing?

---

**F6 — the new rule reproduces the enforcement model that demonstrably failed for
its own sibling class.** `note`

*What.* The ephemeral-**path** rule has existed in `conventions/docs.md` for the
whole phase. Under it, 20 path citations accumulated in the persistent corpus
undetected, and were found only because a row was opened to look. The remedy
chosen for the **id** class is the same instrument — a paragraph in the same
file, with no check attached and a one-shot sweep scheduled at `DOC-01-06`.
Meanwhile `ACC-03` and `PR-01` both write into the corpus *after* that sweep, and
`DOC-01-06`'s own cell asserts *"the rule … landed 2026-09-03 so the interval
adds none"* — a prediction about future compliance, stated as a fact about a
five-row interval.

*Evidence.* The class reached ~116 citations with the sibling rule in force
(`technical_debt/general.md:126–145`); `ROADMAP.md:1397`; the marker gate at
`ROADMAP.md:54` is the phase's only example of a citation rule with a mechanical
check, and it is the only one that has stayed clean.

*Why it matters at delivery level.* This is the strategic-frame question applied
to the highest-consequence artifact in the range: *does it make the system more
predictable, or merely more elaborate?* The rule's **content** makes it more
predictable — it is short, mechanical and states its escape. The rule's
**enforcement** makes it merely more elaborate, because the phase now holds two
rules of the same shape and one gate, and the gate is over the corpus that never
had the problem. `T-EPHEMERAL-IDS` already carries the exact command; promoting
it to a pre-PR gate line beside the marker gate costs one line and converts a
convention into a check.

---

**F7 — `DOC-01-06`'s placement argument holds; the intra-row ordering has one
wrinkle.** `note`

*What.* I was asked to test the argument, not accept it. **It holds.** The
sequence at `:11` is `FIX-03 → DEC-02 → LEDGER-02 → DOC-01`, so `FIX-03-05` does
run before the two vacuuming passes, and `T-EPHEMERAL-IDS`'s own distribution
puts **104 of 116** citations inside the two registers those passes rewrite
(`technical_debt/input.md` 52 + `general.md` 40 + `decisions/input.md` 12).
Sweeping at `FIX-03-05` would sweep prose scheduled for deletion. `DOC-01-06` is
also correctly distinguished from `FIX-03-05` on subject — retired ids versus
live ones — and the cell says to re-derive rather than trusting its own number.
The one weak link is that `LEDGER-02` and `DEC-02` vacuum *some* of those two
registers, not most of them, so "most of these ids leave first" is unproven; the
argument survives anyway, because the cost being avoided is doing the sweep twice
and that holds at any fraction above zero.

The wrinkle: **`DOC-01-05` is the citation check *"over everything this row
rewrote"*, and `DOC-01-06` rewrites after it.** The cell already orders
compaction (`-02`) before the sweep; it does not order the sweep before the
citation check.

*Evidence.* `ROADMAP.md:11`, `:1392–1397`; `technical_debt/general.md:128–132`.

---

**F8 — "record the command beside the number" is the right diagnosis, stated one
notch weaker than the phase's own working form, and applied unevenly in the
commit that adopted it.** `note`

*What.* The report argues the countermeasure for drifting counts is not the
warning but recording the command. **I agree the warning is refuted** — the
evidence is clean and it is the strongest reasoning in the range: session68 was
told the lesson and reproduced it; session69 wrote the lesson into its own note
and reproduced it anyway. A warning that fails twice under direct transmission is
not a remedy.

Two qualifications the report does not make.

1. **It was applied to one number and not the other, in the same commit** —
   `82a65b9d` gave `T-EPHEMERAL-IDS` its re-derivation command and left the
   `FIX-02-07` cell command-less. The command-less number is the one that is
   still wrong (F1). That is not an argument against the diagnosis; it is the
   strongest available argument *for* it, and the report does not use it.
2. **The command fixes reproducibility, not staleness.** A number with a command
   beside it is stale the moment the subject moves; what it buys is cheap
   re-derivation. The form that actually works is already in this phase, twice —
   `T-NEVER-SHIPPED`: *"Do not trust this number either — count it when the row
   opens. The figure is here to size the row, not to be cited"*; `T-EPHEMERAL-IDS`:
   *"Re-derive when the row opens; do not cite these numbers."* **Command plus an
   explicit do-not-cite.** The roadmap cells have neither, and every count that
   has failed this phase has been a roadmap cell.

*Evidence.* `git show 82a65b9d --stat`; `technical_debt/general.md:80–85`, `:128–139`;
`ROADMAP.md:844`.

---

**F9 — one of the two locations the peer review named for its F4 was left
uncorrected.** `note`

*What.* Peer review F4 named `FIX-01-01-enumeration.md` **and**
`session69/track.md` as carrying *"ten live citations … (2 `src/`, 7 `tests/`, 1
debt register)"*. The enumeration note was corrected to nine (2/6/1) and the
report says nine. `track.md:72` still says ten and 2/7/1.

*Evidence.* `git grep -n 'live citations name' -- doc/development/wip/77-new-input-api/`.

*Why it matters.* Low. A track is a log and arguably records what was believed at
the time — but then it should say so, and the peer review named it as a site to
fix, not as a log to leave. It is the successor's first read after the report.

---

## 3. The two things I was asked to be specific about

**The `FIX-01-01` yield.** *Fair, and slightly over-generalised.* The find is
real and confirmed in code — `SearchController:textinput` calls
`self.input:add_text(t)`; the paragraph claimed it reached the instance's own
`textinput`, and the claim had been true when written. The method claim
(*"answering a remark re-reads the code, and that is where the yield was"*) is
sound reasoning about **why** it was caught: a reflow preserves a sentence, a
rewrite has to resolve it. But it is n=1 across a three-site row, the other two
sites yielded nothing but prose, and the prose *was* the row's stated deliverable
and did land. It is now standing advice in `session70/prompt.md` on that single
instance. I would keep the advice and drop the implication that the prose was
incidental — the row delivered what it promised and found one thing extra.

**The scope call.** *Raising was right, and the split is the right shape.* Four
grounds, all checkable: the class is ~10× the row's size; it required **extending
a rule rather than applying one**, which is a plan change and therefore the
owner's; its subject sits in two registers that `DEC-02`/`LEDGER-02` are about to
rewrite; and — the part that distinguishes this from avoidance — it was raised
**before** executing, with the recommendation attached, and the track records the
escalation between the derivation commit and the execution commits rather than
after them. Avoidance looks like a row closing quietly with the class unnamed;
this closed with the class named, ruled, registered and scheduled. The release
carries the class either way, and it is carried **visibly**, with a re-derivation
command and a row that owns it. My one reservation is F6: the half of the split
meant to stop accrual is a convention with no check, which is the instrument that
already failed for paths.

**Drift from purpose.** The session began as housekeeping (owner instruction, in
the track's boot section), became execution, and produced a persistent-corpus
rule, a slugged debt entry and a roadmap step. **Each transition was named to the
owner before it was taken**, and each artifact landed as its own commit citing
the ruling. That is the documented remedy in `agents/validation.md`'s operational
modes working exactly as written, and it is worth saying plainly: this is not
session30.

## 4. Dispositions

| # | finding | proposed action | owner |
|---|---|---|---|
| **F1** | `FIX-02-07`'s marker series mixes anchored and raw counts (29→24 with a 7-point attribution), and cites a `doc/` gate that does not exist | Restate the cell on **one** series — recommend raw, 31→24 — with the anchored figures as a parenthetical; delete *"the gate counts `^> REMARK`"* and say instead that `agents/rules/commenting.md`'s gate covers `src/`/`tests/` only, which is why this row exists. Add the two commands beside the numbers and the do-not-cite clause (F8) | **successor session** |
| **F2** | two live `design/…` path citations survive in `technical_debt/input.md:1432,:1437`; `FIX-01-02` is ✅ over them | Re-run the class-A derivation with `design/` in the pattern; fix both in place (the referent is a frozen design document — name it in prose, as `FIX-01-02` did for `FR-n`). If they cannot be fixed now, they need a home: either a line on an ACTIVE entry or an explicit reopen of `FIX-01-02` — do not leave the class without a register | **successor session** |
| **F3** | `FIX-01`'s two residues (six paths → `LEDGER-02`; R100 → `DEC-02`) live only in `wip/` documents | Add one line to `T-NEVER-SHIPPED` naming the six citations and the conditional repoint obligation, and one line to `T-ARGUES-INTERIM` naming `D-HOOKS-SEEDED`'s *"never asked for"* as a third measured instance. Both are two-sentence edits and both are the standing rule (*a finding goes to the ledger the moment it is found*) | **successor session** |
| **F4** | `ROADMAP.md:36` and `:1619` say `DOC-01` runs before `ACC-02`; the sequence and `:1365` say after | Correct both to *"after `FIX-03`, before `ACC-03`"*, preserving the 2026-09-01 reasoning verbatim — only the row name changes. One commit, `docs(roadmap)` | **successor session** |
| **F5** | `agents/` survives `wip/77` but is outside the corpus rule; `agents/rules/ledgers.md:69` cites a `wip/77` path from a standing rule | **Ask the owner** whether `agents/` is in the persistent corpus. If yes: `T-EPHEMERAL-IDS`'s scope and command widen, and `ledgers.md:69` is repointed to name the archive by description rather than path. If no: say so in `conventions/docs.md` so the next sweep does not re-open it | **owner ruling** |
| **F6** | the id rule has no check, which is the instrument that already failed for the path class | Propose promoting `T-EPHEMERAL-IDS`'s re-derivation command to a **pre-PR gate**, listed beside the marker gate in `agents/validation.md` and re-run at `ACC-03`/`PR-01` — so the class cannot regrow between `DOC-01-06` and the PR. This changes a release gate, so it is not the successor's to take unilaterally | **owner ruling** |
| **F7** | `DOC-01-06` placement holds; `DOC-01-05`'s citation check precedes the sweep that rewrites after it | One clause on `DOC-01-06`: it runs before `-05`, or `-05` re-runs after it. Take it when `DOC-01` opens — **not now**, and record it on the row rather than in a note, per F3's lesson | **successor session** (at `DOC-01`) |
| **F8** | the recurring-lesson diagnosis is right but weaker than the phase's own working form | No standalone action. Fold into F1's rewrite: the working form is **command + explicit do-not-cite**, and it belongs on roadmap cells, which are where every failed count in this phase has lived. Worth one line in `session71`'s prompt | **successor session** (with F1) |
| **F9** | `session69/track.md:72` still carries the ten / 2-7-1 figure the peer review corrected elsewhere | Either correct it or mark it *"corrected to nine — see the enumeration note"*. A log may record what was believed; it should not read as current | **successor session** |
| — | the stop on `REC-01`/`MERGE-01`, the mode transitions, the rule's merits, the deleted prose, the `FIX-01-01` yield | Checked; sound. **No action** | **no action** |
