# session62 — the project environment lifecycle, as an architecture discussion

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session61/report.md`](../session61/report.md).

Baseline: **1032 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Carryover

Session61 revalidated the `BUG-01` sprint one level up — delivery, not code — and the sprint holds.
Suite arithmetic reconciled exactly, the debt ledger survived its section-heading scar with every
entry on the right side of the release-scope boundary, and both of the sprint's re-framings stood.

Four things it changed that you may meet:

- **`BUG-02` is open**, a one-row sprint in the defect brace. `set_text`'s list branch does not
  split embedded newlines while the string branch now does. Pre-existing, unreachable from in-tree
  callers, filed **unslugged** — the row opens by weighing fix-vs-postpone, and that call has not
  been made. It carries a conditional constraint: **if it goes to *fix*, it finishes before
  `CHG-01`**.
- **Decision 8 now records that canonical combo form is lower-case** — always assumed, owner-ruled,
  written down only because leaving it unwritten cost a defect.
- **The persistent corpus is defined by a rule, not a list** (`agents/validation.md`): everything
  under `doc/` that is not under `wip/`. Do not re-enumerate it anywhere.
- **The CHANGELOG is what the PR description is written from** — not the debt register. Session61
  had this backwards for one exchange.

Sequence now:
**`{ BUG-02 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01`**.

## Your task — an architecture discussion the owner is bringing

**The topic is the project environment lifecycle.** The owner opens it; the shape of the question
is theirs and is not scoped here, so do not pre-decide what it is or start work against a guess.
What is asked of you is to be in a position to discuss it well.

- **Mode is `architecture_assistance` at the start** — `agents/architecture_assistance.md` is the
  register. Default work is cognitive: evidence, verification in code, judgment presented and then
  the owner's ruling. Not execution.
- **Read the intent sources before reverse-engineering.** `doc/development/overview.md` and
  `doc/development/internals/*` say *why* and what the intended shape is; the code says *what*.
  For this topic the relevant ones are **`internals/project_sandbox_env.md`** first, then
  `internals/event_dispatch_layers.md` and `internals/console.md`; `internals/user_input.md` carries
  the run-scoped lifetime rules the input work established (Decision 11's teardown, the widget not
  surviving a run, `love.state.user_input` being a sandbox clone the project never sees).
- **The `lua-lsp` MCP server is the correctness tool** for "who calls this" and "what breaks if this
  changes" — grep to find candidates, LSP to resolve them, and grep again as the completeness
  backstop, because Lua refs can be thin. Verify every factual claim in code before acting on it;
  two verdicts in this phase were overturned exactly that way.
- **Name the mode when it changes.** An open-ended architecture discussion that quietly becomes
  research, then a plan, then a tool, is session30's rabbit-hole precisely. Say when you cross a
  boundary and let the owner decide whether to continue or hand over cold.

## The roadmap — know its shape, you may need to change it

You are not being asked to execute the roadmap, but **you must know it exists and how it is
shaped**, because an architecture question about environment lifecycle can legitimately land on it.

- The live roadmap is **`doc/development/wip/77-new-input-api/ROADMAP.md`** — read it for *what
  next*; `validation/plan.md` for *why*.
- **`agents/rules/roadmap.md` is the authority on its shape**: one nested roadmap and never a second
  ledger; numbering that matches execution order, with a crosswalk on every renumber; ordering by
  **blast radius, not severity**; the `KIND-sprint-task` id convention; and *a retirement takes its
  citations with it*.
- Two outcomes are legitimate and they are the owner's call, not yours to take silently:
  **amend the roadmap** (a new sprint in the brace, a row, a re-ordering — `BUG-02` was opened this
  way last session) or **hand the question over** as work outside this feature, in which case say so
  explicitly rather than filing a row nobody will run. **Omission is not a ruling** — if something
  is dropped, the reasoning is written down.
- Remember what the roadmap is *for*: this feature's release. A lifecycle question that is
  genuinely bigger than `#77` should not be quietly absorbed into `#77`'s plan to make it
  actionable.

## Facts worth having up front (verified 2026-08-31 — re-verify before relying on them)

- **`BUG-01` is COMPLETE** — all eleven rows. Three fixes with **three different provenances**,
  base-checked against `3256aac` and confirmed by a cold review: `-09` **inherited**, `-04`
  **entirely ours**, `-05` **mixed** (a pre-existing inert bound our own wrappers made reachable by
  copying its convention on purpose). The PR description needs these kept apart.
- **"Suite green" here means green under LuaJIT with `lua-utf8`**, not on the owner's PUC Lua.
  Three `utf8` implementations are selected at load by `src/util/string/utf.lua`;
  `internals/text_encoding.md` is the write-up.
- **`FIX-02-09` must run LATE** and its scope now includes comments in `src`, `tests` and the
  examples. The vocabulary is still being minted, which is the whole reason.
- **Deliberately unfixed, not gaps to re-file:** maze's level-jump defect and its dead `SYSTEM_KEYS`
  lookup (in **maze's own `ISSUES.md`**), and the error highlight's byte-vs-character comparison
  (BACKLOG, **no slug**, owner ruling).

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before you cite it; session61 got one wrong from memory and caught it only by listing them.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.
