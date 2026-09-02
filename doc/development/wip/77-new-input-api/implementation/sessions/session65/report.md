# session65 — report

**Date:** 2026-09-01 → 2026-09-02 · **Suite:** 1048 / 0 / 0 / 10 throughout, LuaJIT 2.1 in the
container (the owner runs PUC Lua) · **Mode:** execution, twice interrupted by the owner reopening a
category — which is where most of the value came from. Twenty commits, none pushed.

---

## 1. What this session was

`DEC-01` — the decisions ledger's numbers→names conversion — executed and closed, then four owner
rulings that grew out of it and reshaped work well beyond the row.

## 2. `DEC-01`, complete

31 decisions carry a `D-` slug declared first in the heading; `Decisions? [0-9]+` returns **zero**
across `src/`, `tests/`, the persistent corpus and `agents/`; the crosswalk from every number the
ledger ever issued is an appendix to the ledger, so it outlives `wip/77`.

**Two method changes, both the owner's.** No sentinel wrapping — we were not renumbering, so the
substitution ran directly in descending numeric order with a word-boundary match as the second belt,
and `DEC-01-02` was **not executed**; its completeness burden moved to `DEC-01-01`. And the
conversion map lives in `wip/` for forensics, resolved as two artifacts since the owner's own caveat
was that the forensic file may itself be changed later: reasoning and counts in `validation/`, the
bare crosswalk in the ledger.

**The sizing was 165 citations across 18 files. It was 554 across 36, and none of the gap was
drift.** Three forms are invisible to a `Decision N` grep, which is what the earlier sizing used:
**18 line-broken citations** (the spec knew of 3, all in the ledger; they were in five files), 11
plural mentions, and **8 bare back-references** — a decision cited by number with no `Decision` word
anywhere near it, every one in a sentence unpacking a plural. Joining the line-broken ones alone
moved the occurrence count 510 → 528, which is the proof they were invisible.

**All six retired entries were vacuumed, not four.** The one in doubt was Decision 16, which
recorded the Gate-2 scope ruling keeping pointer out of this pass; the owner's ground for sweeping
it is the sentence to carry: *"if it's not in stakeholders' verbatim attestations, it's my interim
ruling and I reverted it with reason."*

## 3. The four rulings, in the order they arrived

**(a) Technical justification does not live in `wip/`.** Met immediately, because vacuuming
Decision 16 would have deleted the only persistent record that a ratified position was reversed.
Then bounded rather than chased: the *"Ratified deviations"* table is six rows and **all six "Why"
cells are technical**, so the directive's reach is a sprint of its own — `FIX-02-26`.

**(b) …which was then refuted at its premise, by checking.** The owner reopened it — *"we do not
make archaeology; 'X, why not Y' only makes sense if Y is a likely option to be considered again."*
Reading the five decisions instead of assuming showed the second half of my claim was **false**:
`D-ROUTE-LIFETIME` marks itself SUPERSEDED IN PART and quotes the superseded claim, `D-NO-LOG-NOISE`
names the design's proposed debug log and declines it, `D-HOOKS-SEEDED` argues the seed against a
precedence rule by name. The PR table *summarises* the ledger. `T-DEVIATION-WHY` retired NOT DEBT,
`FIX-02-26` withdrawn, the paragraph I had added removed again. **The answer was two lines above the
decision I was editing** — the owner's own `REMARK` at `decisions/input.md:462`. Second time in two
sessions the ledger had already drawn the line and I read the commit trail instead.

**(c) The inverse is the real defect, and it is now a rule.** `agents/rules/ledgers.md`, *"What a
decision records about its own past"*: what was not in a released version is considered never to
have existed, except what stakeholders explicitly ratified. **The owner's correction to their own
phrasing is load-bearing** — the defect is arguing with an **interim, overwritten** past, not
"arguing with itself", which is too wide and catches the legitimate cases. Carried by
`T-ARGUES-INTERIM` / `DEC-02`, then extended to the debt register (`T-NEVER-SHIPPED` / `LEDGER-02`)
on the owner's *"introduced-then-paid never existed for the outer world"*.

**(d) Vacuuming is a move, not a deletion.** A vacuumed entry goes to an archive under `wip/`. The
reason I had not weighed: **a ruling made and overruled is work that happened**, and once its entry
is gone it leaves no trace in the corpus, so the effort reads as if it never occurred. `DEC-01-04`'s
six deletions were recovered into `validation/archive/decisions-vacuumed.md` (356 lines) together
with `D-AUTO-HIDE`'s overruled half. It still leaves the release, which is the point.

## 4. `D-AUTO-HIDE` rewritten — `DEC-02`'s first instance

On the owner's framing that replacing `oneshot` with `auto_hide` is **one decision from a
stakeholder's perspective**. 132 lines → 77: five numbered statements in force, instead of a
decision diffed against itself over one day.

**The cost that was not in the estimate: eleven citations.** Six named *"D-AUTO-HIDE's Amendment"*
and four *"ruled edge N"*, across two production files, two specs, the internals doc and two retired
debt entries. They cited the entry **as a diff**, because with the rule existing in two versions
that was the only stable handle. **Self-arguing prose teaches the code to cite it that way**, which
is what makes the class expensive rather than untidy. Recorded on the goal and the row.

## 5. The replan — acceptance split

The owner asked for smoke and the remaining recon ahead of slicing and docs finalisation. Delivered
as a **split, not a move**: the old `ACC-02` bundled two activities with opposite ordering needs —
device passes want to run early (everything downstream is prose), the cold review wants to run late
(on the prose that ships, which is `DOC-01`'s own 2026-09-01 placement argument). So `ACC-02` is the
device passes and `ACC-03` the cold read, with `DOC-01` between them.

**It also fixed an inversion nobody had noticed:** `ACC-02` smokes `balloons`, `keyboard` and
`maze`, and `MERGE-01-01/02/03` merge upstream **into those same repos** — sequenced as they were,
the smoke ran against a tree that then changed. `REC-01`/`MERGE-01` now precede it.

New order: `{ FIX-01 · FIX-02 · CHG-01 } → REC-01 → MERGE-01 → ACC-02 → FIX-03 → DEC-02 →
LEDGER-02 → DOC-01 → ACC-03 → PR-01`.

## 6. Non-obvious points worth carrying

- **An unsupported regex is not an empty result.** The first sweep for references to the vacuumed
  ids used `awk` with `\\<`/`\\>`; mawk does not support them. It returned nothing and looked exactly
  like a clean result — four real references were in the file.
- **Prove a mechanical rewrap, do not eyeball it.** After reflowing 68 comment blocks, every `.lua`
  file's comment text was checked to be word-for-word identical to the pre-substitution text with
  only the slug applied. Cheap, and the right check for any bulk reformat.
- **Look for the pass that already produces your input.** `LEDGER-02` enumerates nothing because
  `FIX-02-05` already base-checks every retired debt entry, and the same check answers *did this
  exist at the base?* One pass, two consumers — `CHG-01-03` takes the pre-existing half, `LEDGER-02`
  the other.
- **A recommendation drifts by staying still.** The guide led with `after_submit = hide` and
  trailed `auto_hide`; nothing was false, so no grep would have found it. Adding a surface does not
  re-rank the advice around it.
- **Markdown is not bound by the 64-char limit** — `agents/rules.md` scopes it to *coding*, and the
  prose corpus runs 96 to 1158 characters wide.

## 7. Artifacts

- Track: `session65/track.md` — boot, each ruling as it arrived, the two category reopenings
- **Twenty commits**, `65281671`..`5f97485b`, suite green and stated at each; **none pushed**
- New: `validation/reviews/DEC-01-03-inventory.md` (forensic conversion map),
  `validation/archive/decisions-vacuumed.md` (the vacuumed entries), the ledger's crosswalk appendix
- Rules amended: `agents/rules/ledgers.md` (three additions), `agents/validation.md` (the new
  artifact kind)
