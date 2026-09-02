# session66 — keep moving on the roadmap

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session65/report.md`](../session65/report.md).

Baseline: **1048 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover — what changed under you

Session65 closed **`DEC-01`**: the decisions ledger is cited by name, not by number. Four
consequences you will meet before you meet the roadmap.

- **Decisions have `D-` slugs now.** `D-ROUTE-OWNS`, `D-CFG-BOUNDARY`, `D-AUTO-HIDE` and 28 others.
  `Decisions? [0-9]+` returns zero in `src/`, `tests/`, the persistent corpus and `agents/`. **Every
  document under `wip/` still cites numbers** — including this roadmap and every prompt before this
  one. The crosswalk at the end of `doc/development/decisions/input.md` is the translation, and it
  is the half that survives the tree.
- **Two new rules in `agents/rules/ledgers.md`.** *"What a decision records about its own past"* —
  what was not in a released version is considered never to have existed, except what stakeholders
  ratified — and *"Vacuuming is a move, not a deletion"*: a vacuumed entry goes to
  `validation/archive/`, which is a new artifact kind registered in `agents/validation.md`.
- **The defect brace is down to `FIX-01`, `FIX-02`, `CHG-01`.** `DEC-01` is done, so **the slice cut
  now waits on `CHG-01` alone**.
- **Three new rows exist**: `DEC-02` and `LEDGER-02` (the two vacuum sprints the rules above
  created) and `ACC-03` (see the reordering below).

## The reordering, because it changes what "next" means

**Owner, 2026-09-02.** Acceptance was split and the merges moved ahead of it:

`{ FIX-01 · FIX-02 · CHG-01 } → REC-01 → MERGE-01 → ACC-02 → FIX-03 → DEC-02 → LEDGER-02 → DOC-01 → ACC-03 → PR-01`

`ACC-02` is now **the device passes**; `ACC-03` is **the cold read**, still after `DOC-01`. The
merges precede the smoke because `ACC-02` smokes the three example repos that `MERGE-01-01/02/03`
merge into. **Everything after `ACC-02` is prose**, which is the property the order exists to buy.

## Your task, part 1 — a scoped revalidation, FIRST

**Owner, 2026-09-02.** Session65 was cognitive-heavy and its successor owes a revalidation
(`agents/sessions.md` §5), which the wrap initially skipped. Work
[`rules/revalidation.md`](../../../../../../agents/rules/revalidation.md), at the **delivery**
level — *did the outcome match the need, was anything overlooked, was anything unnecessary
delivered* — over **four subjects and no more**.

**Read this before you scope it wider.** Three of session65's deliverables are already proven and
re-checking them is the recursion `agents/validation.md` warns about:

- **the 554 substitutions** — the slug map drove the headings *and* the citations from one
  dictionary, so a wrong entry would have produced a visibly wrong heading, and all 31 headings were
  read. Verified by construction plus inspection;
- **the 68 reflowed comment blocks** — proved word-for-word identical to the pre-substitution text
  with only the slug applied, not eyeballed;
- **`DEC-02` and `LEDGER-02` as filed** — plans whose own first step re-derives them.

**The four subjects, in descending risk. Each was hand-written by one reader and reviewed by nobody.**

1. **`D-AUTO-HIDE`'s live-vs-churn split** (`d0f4e66c`, 132 → 77 lines). The judgement was *what is
   still in force* versus *what was interim*. **If a live ruling was dropped, the entry now
   under-specifies behaviour the suite pins and the suite stays green** — so the check is against
   the tests and the guide, not against the diff. The pre-rewrite text is in
   `validation/archive/decisions-vacuumed.md`; diff it *for meaning*, not for lines.
2. **The eleven re-pointed citations.** *"D-AUTO-HIDE's Amendment"* (6) and *"ruled edge N"* (4)
   were mapped onto numbered statements by reading. **Resolve each one**: does the statement now
   cited say what the citing comment or test asserts? A wrong statement number is silent and green.
3. **What the vacuum rehomed** — `D-ASK-THE-DEVICE`'s *"what it withdraws"* paragraph and
   `internals/user_input.md`'s *"inspect mode"* section, both written from entries that were then
   deleted, plus the seven code citations re-pointed at the latter. Check against the archive: **was
   anything lost, and is anything asserted there that the originals did not say?**
4. **The three additions to `agents/rules/ledgers.md`** — *"What a decision records about its own
   past"*, *"Vacuuming is a move, not a deletion"*, and §3's introduced-vs-pre-existing rule. They
   govern all future ledger work. Check them for overreach and for contradiction with what already
   stood.

**One mechanical sweep to run with it, cheap:** residual references to ids this session renumbered
or removed — `ACC-02-0[678]`, the six vacuumed decision numbers, and any heading citation that no
longer resolves. `ROADMAP.md` and `smoke_checklists.md` were fixed; nothing else was checked.

**Why this pass and not a general one.** Session65 had **two findings refuted at their premise by
the owner** — `T-DEVIATION-WHY` and the `D-ONE-LIFETIME` paragraph. The calls the owner reviewed are
settled; the four above are the same kind of call by the same reader, unreviewed. That is the whole
scope. **Findings go to the ledger, not to your track**, and the pass is closed when the four are
answered — do not let it grow into a re-verification of the feature (`agents/validation.md`,
guardrail 1).

## Your task, part 2 — then the roadmap

**Owner directive, 2026-09-02: move towards the roadmap** once the revalidation is closed. Confirm
the pick with the owner before starting — the choice is theirs.

**The recommendation is `FIX-02`**, the largest remaining row in the brace and the one gating the
most:

- **`FIX-02-05` blocks `LEDGER-02` outright** — it base-checks every retired debt entry, and that
  same check is `LEDGER-02`'s entire input. It also feeds `CHG-01-03`. One pass, two consumers; do
  not let anything re-derive it.
- **Four of its rows have unknown yield** (`-03`, `-04`, `-05`, and `-07`'s 37 dispositions), which
  is the ordering principle's definition of what goes first.
- **`FIX-02-25` ships a test**, so it is the one row left in the brace that touches `tests/`.

`FIX-01` (3 rows, citation hygiene) and `CHG-01` (the version question) are legitimate alternatives,
and `CHG-01` has the stronger claim if the owner wants the slice cut unblocked soonest.

**Re-derive any sizing before working it.** `FIX-02-05` says *"20 resolved entries"*; there are
**47**. `FIX-01-02` says *"~12 sites"* and admits it drifts. This happened to `DEC-01` too — it was
sized at 165 citations and executed at 554, and none of the gap was drift: the sizing grep could not
see three variant forms. **A count in a row is a lower bound written by someone who could only
grep the canonical form.**

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found.** If you fix it the same day the
  record is the RETIRED entry, but it lands in the ledger either way.
- **Before filing a surface finding, check whether a decision or a rule already draws that line.**
  Session65 filed `T-DEVIATION-WHY` against a position the owner had written into the ledger two
  lines above the entry being edited. Session64 did the same thing. **Read the ledger, not the
  commit trail** — the latter produces patch archaeology that looks like a finding.
- **A line citation is verified by resolving the exact line, or not at all.**
- **An errored or unsupported query is not an empty result.** Session65's first sweep for surviving
  references used `awk` word boundaries mawk does not support; it returned nothing and looked clean
  while four real references sat in the file. Same shape as an LSP `broken pipe`.
- **Prove a mechanical edit, do not eyeball it.** After bulk-reflowing 68 comment blocks, every
  `.lua` file's comment text was checked word-for-word against the pre-edit text. Cheap and decisive.
- Stage explicit paths. `git add -A` in `/repo` commits the nested example repos as gitlinks.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before citing it; if you rename or remove one, fix its citations in the same pass. Session65
  removed one section and owed **eleven**.
- **`FIX-02-09` must run LATE** and its scope is the whole persistent corpus.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.

## Environment facts, stated because they qualify every claim you will make

- **The container runs LuaJIT 2.1; the owner runs PUC Lua.** Container-green is not their-machine
  green. State the interpreter behind any suite claim.
- **`lua-lsp` was not needed in session65** (a documentation sprint) and its health is therefore
  unverified. If it fails, say so rather than silently substituting grep and implying coverage you
  did not have.
- **Markdown is not bound by the 64-character limit** — `agents/rules.md` scopes it to *coding*.
  Comment blocks in `.lua` are.
