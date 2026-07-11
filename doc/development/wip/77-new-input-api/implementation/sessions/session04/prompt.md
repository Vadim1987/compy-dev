# session04 — prompt (M7 → M8, autonomous sweep)

_Handover from session03 (opus-sweeper PM), 2026-07-11. Read the mandate first
(`../../prompts/M5c-M8-sweep-mandate.md`; the `agents/sweep.md` boot pointer routes you through it),
then the authority chain, then this prompt. Predecessor running track:
[`../session03/track.md`](../session03/track.md) — read it, it is your carryover in full._

## What you are

You are the **opus-sweeper PM** continuing the sweep, now on its **final two milestones M7 → M8**. You
**orchestrate**; you do not implement or review with your own hands. You spawn a **Sonnet implementor**
and an **Opus reviewer** per chunk, hold the seam between them, and commit after each chunk. See "How to
run the sub-agents" below — that mechanism is the core of this session.

## Standing authorization — carried verbatim (human, 2026-07-10; still in force)

The human **lifted the per-chunk human gate for this lineage** and authorized fully autonomous
operation. You inherit all of it:

1. **Run autonomously through M7 → M8** without stopping for a human go/no-go between chunks. The human
   reviews **post-factum in git**.
2. **You and your sub-agents may commit locally after each chunk or corrective take** (Conventional
   Commits, **no push, this repo only**). Never commit inside a nested checkout (`src/examples/*/.git`)
   — guardrail 7.
3. **Fable-5 advisor is available for genuinely hard calls only** (see "The Fable-5 advisor" below).
4. **The "no silent in-slice design ruling" guardrail still holds** (mandate guardrail 1). The gate that
   was lifted is the *scheduling* gate, not the *design-authority* gate. On a real spec gap / corpus
   contradiction / irreversible design decision: consult the Fable advisor; then if it is still a
   genuine design ruling, make the **most conservative, most reversible** choice, **flag it loudly** in
   the chunk's outcome ledger under "what will surprise the architect" (surprise-first), and continue.
   Never quietly re-architect, never retroactively edit `design/`.

## Carryover — where the corpus stands (2026-07-11)

- **M5c is COMPLETE** — all five chunks landed, reviewed, and (where needed) correctively fixed, fully
  autonomous. Suite at **779 / 0 / 0 / 5** (5 pending = the M7-family rows this session converts to
  green). Chunk history (session03 track has the detail):
  - Chunk 3 submit-cancel — `9bb6d29`, Opus APPROVE.
  - Chunk 4 route-lifecycle — feat `386cfe1`, review **corrective-take** `fbbef86` (AC-29 highlighter
    leak), corrective `d3c2adb`.
  - Chunk 5 example-migration — turtle feat `88ab1df`, review **corrective-take** `8cdb876` (maze
    escape/cancel latch bricked the editor), corrective `d6e8c3d`. **maze delivered UNCOMMITTED** in its
    nested checkout (guardrail 7 — `M controls.lua`/`M main.lua`, ledgered for the human to carry
    upstream; `.git` pristine at `12f675f`).
- **Authority chain (binding, in order):** `design/notes/ratified-model.md` (canonical — R1–R14, five
  rulings, binding glossary) → `design/design.md` + `design/spec.md` (Gate-2 contract) → the slice spec.
  For **M7**: `design/spec/M7-02-recut.md` (frozen; supersedes `M7.md`). For **M8**:
  `design/spec/M8-02-recut.md` (frozen; carries a **REVALIDATE-AT-COMMISSIONING** flag). Higher authority
  wins; mint no architectural nouns outside the ratified glossary. `design/` is frozen — read, never edit.
- **INFRA — lua-lsp MCP is RESTORED** (commit `08a3d93 fix MCP-lsp-lua`; session03 chunks 4/5 reviewers
  and correctives used it live). This **supersedes** session03's earlier "lua-lsp DOWN" note. **Use the
  LSP for correctness** (`definition`/`references`/`hover`/`diagnostics`); `sleep 1` after any `.lua`
  edit before MCP calls (re-index); grep as the completeness backstop.

## M7 — the slice + a proposed carve (verify, then write it up as a first-class artifact)

`spec/M7-02-recut.md` is purely **additive** — five `compy.input` callables + one model fix + a doc +
the M7-01 boundary-close. 12 ACs, no routing/dispatch change. **The M7-01 boundary decision is already
RATIFIED in the spec** (Contract + "Riding decision": Option B — `validator` and the widget-output
callbacks ARE live-updatable; `text`/`cursor` immutability via `configure()` stands). So implementing it
is **not** an in-slice ruling — only a concrete need to *diverge* from Option B is a stop-and-gate.

**Proposed 2-chunk carve (PM analysis, session03 — not yet committed; write it as
`implementation/M7-chunk-plan.md` before commissioning, and first check the 5 pending m7 rows in
`tests/input/input_contracts_spec.lua` to seed the test-first work):**

- **M7-01 — cursor + text surface.** `get_cursor` / `set_cursor` / `set_text` on `compy.input` **plus**
  the `UserInputModel:set_text` **`keep_cursor` model fix** (the spec's one flagged risk — de-risk it
  first). AC-6/7/8; AC-9 (warn-on-refuse) + AC-10 (assignment errors loudly) for these three; D-8 2D
  `(line,col)` 1-based **source-line** coordinate contract. Model fix lands in
  `src/model/input/userInputModel.lua`.
- **M7-02 — live reconfigure + M7-01 boundary close.** `configure` / `clear` on `compy.input`. AC-1/2/3/
  4/5; the **M7-01 boundary-close** (AC-11 — document the decided `configure` semantics in
  `doc/development/internals/`, **no milestone ids in prose**, and **strike F-5 from
  `implementation/technical_debt.md`**); AC-9/AC-10 for these two; then the milestone close-out **AC-12**
  (all m7-family pending rows green, full suite green, no observable routing change). Both methods are
  independent of chunk M7-01, so this order is a de-risking choice, not a hard dependency.

Expected files (overreach = stop + record): `src/controller/userInputController.lua` (the five methods),
`src/model/input/userInputModel.lua` (`set_text` fix), the `compy` namespace setup (expose the five
callables **under the same assignment-protection** as the existing surface — AC-10), `tests/input/*`,
`doc/development/internals/` (the re-target contract line).

## M8 — the terminal slice (REVALIDATE FIRST)

`spec/M8-02-recut.md` was authored **before** M5c and M7 landed. **Before carving M8**, diff its
mechanics against the **M5c + M7 outcome ledgers**; if they drifted, that is an adjacent-slice /
escalation matter, not a silent adaptation. M8 deletes the legacy globals (`input_text`, `user_input`,
`validated_input`, `write_to_input`) + the poll-a-reftable idiom, and migrates the **remaining** legacy
consumers **tixy + balloons** onto `compy.input.*`. **`balloons` is a nested checkout** → migrate as
**uncommitted working-tree changes**, file-by-file in the ledger (guardrail 7), same as maze. `keyboard`
is pure-native — never migrated. M8 depends on **both** M5c and M7 (the migration needs the full
surface).

## Pinned seams / debts to carry into commissions

- **The M7-01 boundary decision is PRE-RATIFIED (Option B)** — implement it; do not treat it as an open
  gate. Only a *concrete need to diverge* stops-and-gates.
- **Tech debt logged in `technical_debt.md` (session03, M5c-05 review):** `submit()` deliver-then-hide
  ordering (`userInputController.lua` ~L341-342) forces a project to defer an invalid-input reshow one
  frame — an **M7 live-reconfigure candidate**. If the M7 work naturally resolves or touches it, note it;
  do not scope-creep to fix it unless an AC requires.
- **F-5** must be **struck** as part of M7-02 (AC-11) — the M7-01 re-target decision resolves it.
- **Guardrail 7 nested checkouts:** `src/examples/balloons/` (M8) migrates as uncommitted working-tree
  changes, listed file-by-file in the outcome ledger. (maze already delivered this way in M5c-05 —
  same discipline.) Never `git add`/`git commit` inside a `src/examples/*/.git`.
- **Legacy globals stay until M8** — M7 adds surface only; do not remove any global in M7.
- **Human hand-play gates still open (report-don't-block):** turtle input + maze show→Escape→reopen
  (M5c-05) await interactive human confirmation — flagged in the M5c-05 ledger, not a blocker for M7/M8.

## The per-chunk cycle (repeat for each M7 chunk, then each M8 chunk)

1. **Carve if needed.** M7 and M8 are **not** carved yet — write each carve as a first-class artifact
   (`M7-chunk-plan.md`, `M8-chunk-plan.md`, like `M5c-chunk-plan.md`) before commissioning. For M8,
   **revalidate the spec against the M5c+M7 ledgers first** (above).
2. **Write the commission to disk** — `prompts/<id>-<slug>.md` (never inline it). Shape it like
   `prompts/M5c-05-example-migration.md`: scope, in-scope ACs, the seam/boundary section, "read first"
   authority chain, "do in this order" (test-first: red rows precede implementation), outcome-ledger
   spec, scope fence, an escalation-boundary section. Add a `<id>-review.md` note pinning the chunk's
   traps (recommended — it sharpened every session03 review). Commit the commission
   (`docs(input): commission …`).
3. **Spawn the Sonnet implementor** (below). It implements test-first, commits locally, records
   `outcomes/<id>.md`, reports back.
4. **Spawn the Opus reviewer** (below) on the finished diff + ledger. It writes `reviews/<id>.md`, may
   correct `technical_debt.md`, reports a verdict.
5. **Act on the verdict.** APPROVE → commit review artifacts, `TaskUpdate` done, next chunk.
   CORRECTIVE-TAKE → commission a corrective (like `M5c-04`/`M5c-05` correctives: hand the implementor
   the exact finding, test-first red-then-green), re-run implementor, light-confirm (a precise corrective
   matching the reviewer's recommendation with red-then-green proof does not always need a full second
   review round — PM judgement). ESCALATE / real design gap → consult Fable advisor; conservative-
   reversible choice + loud surprise-first flag; continue.
6. **Commit the review artifacts** (`docs(input): land <id> review …` — the reviewer usually commits its
   own review; you commit anything left).
7. **PM sanity-checks before spending the reviewer** paid off every time in session03: run `busted
   tests` yourself, run the review-boot's key greps, read the ledger — catch scope-fence breaks and
   miscounts before the Opus spend.

## How to run the sub-agents (the mechanism)

There is no bespoke "dev"/"review" agent type. Use the **`general-purpose`** agent type with a **model
override** and have the agent **boot from the charter file**:

- **Implementor** — `Agent(subagent_type: "general-purpose", model: "sonnet", run_in_background:
  false)`. Prompt it: *"Boot exactly as `agents/dev.md` instructs. Your milestone id is `<id>`. Read and
  follow `…/implementation/prompts/<id>.md` (self-contained, authoritative). rules.md + development.md
  auto-load via repo-root CLAUDE.md — follow them (hard limits line ≤64 / fn ≤14 / params ≤4 / nesting
  ≤4, no string-tag dispatch, tests-first, report-don't-fix, Conventional Commits, commit locally NEVER
  push). Never edit `design/`. Tests are headless `busted tests` (never xvfb for the suite; there is no
  standalone `lua`). **lua-lsp MCP is RESTORED — use it; `sleep 1` after a `.lua` edit before MCP
  calls.** Record `outcomes/<id>.md`, commit locally, report back: per-item summary, commit hashes,
  before/after busted counts. If anything forces a design choice, STOP and report."*
- **Reviewer** — `Agent(subagent_type: "general-purpose", model: "opus", run_in_background: false)`.
  Prompt it: *"Boot exactly as `agents/review.md` instructs. Milestone id `<id>`. If a filled
  `prompts/<id>-review.md` exists, follow it; else clone `review-prompt.md`. Verify-don't-trust: re-run
  `busted tests` yourself; use lua-lsp `references` to confirm no caller regressions. Edit ONLY your
  review + `technical_debt.md`; NEVER feature code or `design/`. Write `reviews/<id>.md`, report a
  verdict (approve / corrective-take / escalate) + the busted counts."*
- **Run them `run_in_background: false`** (synchronous) — the chunk pipeline is strictly serial
  (implement → review → decide).
- **One cold run per role per chunk.** Do not reuse an implementor as its own reviewer. A sub-agent
  returns an `agentId`; you *may* `SendMessage` it to continue that same context (e.g. a one-line nit)
  rather than spawning cold — but keep implement and review as **separate** agents.
- **Budget discipline:** Sonnet for the grind, Opus for the judgement. Don't churn.

## The Fable-5 advisor (expensive — hard calls only)

Fable 5 is the smartest and **most expensive** model. Use it **only** when a genuinely hard call needs
the best available reasoning — not routine orchestration, not to double-check an obvious decision.
Legitimate triggers: a real spec-gap / corpus-contradiction you cannot resolve from the authority chain;
a design-shaped judgment where a wrong call is costly and hard to reverse; **the M8 revalidation
surfacing real drift**; a concrete need to diverge from the M7-01 Option-B ruling.

- **Invoke as an advisor, not an implementor:** `Agent(subagent_type: "general-purpose", model:
  "fable", run_in_background: false)` with a **tight, self-contained question** — hand it the exact
  corpus refs (authority-chain paths + conflicting lines), state the decision and options you see, ask
  for a recommendation **with reasoning and the corpus citation**. It advises; **you** (the PM) own the
  call; the human reviews post-factum. Record the advice + your decision in the chunk's outcome ledger.
- **Do not** use Fable for mechanical work (implementing, reviewing, running tests).

## Wrap (mechanical, when you pause or finish)

Keep the running track current as you go (start `session04/track.md`; `[project]` / `[behavioural]`,
behavioural stays raw). When you pause or the sweep completes: write `session05/prompt.md` (carryover +
these same permissions), repoint `agents/sweep.md` CURRENT PROMPT (session04 → session05), commit the
wrap. Only the session number changes in the sweep pointer:

```
sed -i -E 's#(CURRENT PROMPT:.*/)session[0-9]+(/prompt.md`)#\1session05\2#' agents/sweep.md
```

**When M8 lands and the full suite is green with the legacy globals gone: the sweep is COMPLETE** —
say so plainly in the final track entry and the wrap, and leave the human a crisp "what remains"
(the open human hand-play gates; the uncommitted nested-checkout patches — maze, balloons — awaiting
upstream carry).
