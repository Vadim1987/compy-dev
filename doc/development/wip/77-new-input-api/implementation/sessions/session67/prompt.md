# session67 — move on the roadmap: `FIX-02` half (a)

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session66/report.md`](../session66/report.md).

Baseline: **1048 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover — what changed under you

Session66 ran the revalidation session65 owed, executed its findings, and collected **five owner
rulings**. Its findings document is
[`validation/reviews/S66-session65-delivery-revalidation.md`](../../../validation/reviews/S66-session65-delivery-revalidation.md);
read the disposition table there before you touch anything it names.

- **The sequence moved twice and is now settled.** `{ FIX-01 · FIX-02 (a) · CHG-01 } → REC-01 →
  MERGE-01 → ACC-02 → FIX-02 (b) → FIX-03 → DEC-02 → LEDGER-02 → DOC-01 → ACC-03 → PR-01`.
- **`FIX-02` runs in two halves across the device passes**, owner 2026-09-02, on the ground that
  *incorrect prose confuses troubleshooting more than missing prose does*. The split is stated in
  `ROADMAP.md`'s `FIX-02` section under **"Execution order"**, which is the **order of record** —
  the row numbers no longer follow execution order inside that sprint and **are deliberately not
  renumbered**. Do not renumber them; the rows are cited from four live debt goals.
- **The acceptance order is a ruling made twice.** The merges precede the smoke and the cold read
  runs last. `REC-01`'s upstream-delta document is written onto the row **as the condition that
  order stands on** — if you work `REC-01`, that document is the deliverable, not a by-product.
- **Four ledger entries were retired and one provenance question ruled** — `T-ONESHOT` and
  `T-ONESHOT-SCOPE` are swept by `LEDGER-02` despite the outside request behind them, because the
  contradiction never existed at base. Recorded on `T-NEVER-SHIPPED`; `ledgers.md` §3 is unchanged.

## Your task — start executing, and confirm only the first pick

**Owner directive, 2026-09-02: move towards the roadmap.** This is a working session, not a
placeholder — the owner asked for one explicitly, so `agents/sessions.md` §5's revalidation→placeholder
default does not apply.

**Work `FIX-02` half (a), and `CHG-01` with it.** The rows, from `ROADMAP.md`'s "Execution order"
note: `FIX-02-03` · `-04` · `-06` · `-17` · `-22` · `-23` · `-24` · `-25`, plus the
`smoke_checklists.md` slice of `-09`. **Confirm the starting row with the owner; the order within
the half is yours to propose.**

Two recommendations, either defensible:

- **`CHG-01` first** — it gates `ACC-02` *and* the slice cut, and it is the last thing in the brace
  doing so. `FIX-02-17` feeds it, so they are one sitting.
- **`-22` first** — the sharpest of the prose defects: three documents say a hidden widget keeps its
  content and the code clears it, so a pass that sees a cleared draft is told by the docs it found a
  bug. One of the three sites is in the persistent corpus.

**`-25` is the only row in the half that ships code** — a test pinning that the accept-side and
apply-side key sets agree. Scoped as *pin the agreement*, **not** *unify the lists*: unifying crosses
the surface/widget boundary the architecture keeps separate. Tests-first, and if the test finds a key
the surface accepts and the widget ignores, that is a production defect and **its own commit**.

**Re-derive every sizing before working the row.** `FIX-02-05` says *"20 resolved entries"*; there
are **51**, counted 2026-09-02. `FIX-02-09` was sized against `doc/input_api.md` and its scope is the
whole persistent corpus. **A count in a row is a lower bound written by someone who could only grep
the canonical form** — `DEC-01` was sized at 165 and executed at 554.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found.** Fixed the same day, the record is the
  RETIRED entry; it lands in the ledger either way.
- **Before filing a surface finding, check whether a decision or a rule already draws that line.**
  Three sessions running have filed against a position the ledger already held. **Read the ledger,
  not the commit trail.**
- **A line citation is verified by resolving the exact line, or not at all.** An errored or
  unsupported query is not an empty result.
- **A citation sweep's scope is where the citations are, not where the code is** (session66's F1 and
  F3, both missed by an `src/`+`tests/` grep). When you rename or remove a named section, resolve
  its citations across `doc/` and the planning tree too.
- **Prove a mechanical edit, do not eyeball it** — and read a substitution to the end of the
  *sentence*, not the end of the token it replaced (F5).
- Stage explicit paths. `git add -A` in `/repo` commits the nested example repos as gitlinks.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
  `FIX-02-09` is the sweep for this; do not pre-empt its (b)-half scope.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before citing it.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.

## Environment facts, stated because they qualify every claim you will make

- **The container runs LuaJIT 2.1; the owner runs PUC Lua.** Container-green is not their-machine
  green. State the interpreter behind any suite claim.
- **`lua-lsp` was not needed in session66** (documents and ledgers) and its health is therefore
  unverified. `FIX-02-25` will need it. If it fails, say so rather than silently substituting grep.
- **Markdown is not bound by the 64-character limit** — `agents/rules.md` scopes it to *coding*.
  Comment blocks in `.lua` are.

## Left open by session66, deliberately

- **F6** — `ROADMAP.md`'s section bodies no longer run in sequence order (`DOC-01` → `ACC-02` →
  `ACC-03` → `REC-01` → `MERGE-01`). The sequence line is correct; the move is a large diff in a file
  the owner reads, so it is theirs to call. Do not take it unprompted.
