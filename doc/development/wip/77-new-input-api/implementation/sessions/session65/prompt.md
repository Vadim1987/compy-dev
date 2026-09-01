# session65 — resume the roadmap

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session64/report.md`](../session64/report.md).

Baseline: **1048 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover — where the feature stands

Session64 ran a **delivery-level revalidation of sessions 61 and 63** and closed it. Most of what
those sessions shipped held up; five findings came out, four are disposed and one is registered
debt. The details are in the report — what matters here is that **the revalidation arc is finished
and nothing it raised blocks the next row.**

Two things it changed that you will meet:

- **`DOC-01` is a new roadmap stage** — the documentation compaction sweep, restored by owner ruling.
  It sits **after `FIX-03`, before `ACC-02`**. Nothing to do about it now; know it exists so you do
  not compact anything opportunistically. **Documentation volume is not a defect** and is not weighed
  before that row.
- **The callable config keys are `wontfix`** by owner ruling, and **Decision 38 was amended** to say
  so — it previously called the check *"unscheduled work"*, which read as a pending obligation.

The defect brace is down to **`FIX-01`, `FIX-02`, `DEC-01`, `CHG-01`**. Two hard constraints still
stand: **`DEC-01` and `CHG-01` finish before any slice is cut**, and **`CHG-01` gates `ACC-02`**.
The live roadmap is [`../../../ROADMAP.md`](../../../ROADMAP.md); read `validation/plan.md` for *why*.

## Your task — execution, not another review

**Owner directive, 2026-09-01: move on with the roadmap.** This deviates from the standard handover
(`agents/sessions.md` §5 makes a revalidation's successor a wait-for-human placeholder) and the
deviation is deliberate — the revalidation is closed and the owner has released the next row.

**The recommendation is `DEC-01` — the decisions ledger's numbers→names conversion.** Confirm it
with the owner before starting; the pick is theirs, and `FIX-01`/`FIX-02` are legitimate
alternatives. The case for `DEC-01`:

- **Largest blast radius in the brace**, which is the roadmap's ordering principle — its scope is
  the ledger, ~10 persistent docs, and **`src/` + `tests/` (165 citations)**. It is the only
  remaining row that edits code comments at scale.
- **It blocks slice cutting**, and `FIX-03` waits on it.
- **It is the best-prepared row on the board** — six steps with per-step gates, a spec, and a
  drafted inventory: [`validation/reviews/DEC-01-ledger-denoising-spec.md`](../../../validation/reviews/DEC-01-ledger-denoising-spec.md).
- Its debt goal is `T-DEC-NUMBERED` (`technical_debt/general.md`), and the argument there is the one
  session64 ran into twice: **a citation by a coordinate that moves resolves to the wrong thing
  instead of dangling.**

**Re-derive the sizing before working it.** The row says 165 citations and 29 slugs + 4 removals;
both numbers are from an earlier session. `DEC-01-03`'s inventory also needs Decisions 9 and 12
added — the roadmap says `RETIRED` holds six entries, not four.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found**, not to your track. If you fix it the
  same day, the record is the RETIRED entry — but it lands in the ledger either way.
- **Before filing a surface finding, check whether a decision already draws that line.** Session64
  filed one built on the commit trail when Decision 35 had settled it; the owner refuted the premise
  rather than the fix. Reading history instead of the ledger produces patch archaeology.
- **A line citation is verified by resolving the exact line, or not at all.** Printing a range and
  spotting the expected symbol is not a check — that is how a wrong answer survived inside session64.
  Relevant here: `DEC-01` rewrites citations for a living.
- Stage explicit paths. `git add -A` in `/repo` commits the nested example repos as gitlinks.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before citing it; if you rename one, fix its citations in the same pass.
- **`FIX-02-09` must run LATE** and its scope is the whole persistent corpus, not `doc/input_api.md`
  alone — corrected in session64, and the corpus is `#77`'s own creation in full.
- Re-derive any sizing a row states before working it.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.

## Environment facts, stated because they qualify every claim you will make

- **The container runs LuaJIT 2.1; the owner runs PUC Lua.** Container-green is not their-machine
  green. State the interpreter behind any suite claim.
- **`lua-lsp` recovered in session64** — `references` returned real AST hits after a session63 spent
  entirely on `broken pipe`. Use it; `DEC-01` is a rename sweep and AST refs are the right tool, with
  grep as the completeness backstop. If it fails again, say so rather than silently substituting
  grep and implying coverage you did not have.
