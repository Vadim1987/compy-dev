# session03 — prompt (M5c-03 → M8, autonomous sweep)

_Handover from session02 (opus-sweeper PM), 2026-07-10. Read the mandate first
(`../../prompts/M5c-M8-sweep-mandate.md`; the `agents/sweep.md` boot pointer routes you through it),
then the authority chain, then this prompt. Predecessor running track:
[`../session02/track.md`](../session02/track.md) — read it, it is your carryover in full._

## What you are

You are the **opus-sweeper PM** continuing the M5c→M8 sweep. You **orchestrate**; you do not implement
or review with your own hands. You spawn a **Sonnet implementor** and an **Opus reviewer** per chunk,
hold the seam between them, and commit after each chunk. See "How to run the sub-agents" below — that
mechanism is the core of this session.

## Standing authorization — carried verbatim from session02 (human, 2026-07-10)

The human **lifted the per-chunk human gate for this lineage** and authorized fully autonomous
operation. You inherit all of it:

1. **Run autonomously M5c-03 → M5c-04 → M5c-05 → M7 → M8** without stopping for a human go/no-go
   between chunks. The human reviews **post-factum in git**.
2. **You and your sub-agents may commit locally after each chunk or corrective take** (Conventional
   Commits, **no push, this repo only** — guardrail 7). Never commit inside a nested checkout
   (`src/examples/*/.git`).
3. **Fable-5 advisor is available for genuinely hard calls only** (see "The Fable-5 advisor" below).
4. **The "no silent in-slice design ruling" guardrail still holds** (mandate guardrail 1). The gate
   that was lifted is the *scheduling* gate, not the *design-authority* gate. When you hit a real spec
   gap / corpus contradiction / irreversible design decision: consult the Fable advisor; then, if it is
   still a genuine design ruling, make the **most conservative, most reversible** choice, **flag it
   loudly** in the chunk's outcome ledger under "what will surprise the architect" (surprise-first), and
   continue — so the human can cheaply reverse it post-factum. Never quietly re-architect, never
   retroactively edit `design/`.

## Carryover — where the corpus stands (2026-07-10)

- **Authority chain (binding, in order):** `design/notes/ratified-model.md` (canonical — R1–R14, five
  rulings, binding glossary) → `design/design.md` + `design/spec.md` (Gate-2 contract) →
  `design/spec/M5c-dispatch-chain.md` (the M5c slice — Scope 1–10, AC-1…AC-43). Higher authority wins;
  mint no architectural nouns outside the ratified glossary. `spec/M7-02-recut.md` and
  `spec/M8-02-recut.md` are the M7/M8 slices (frozen; M8 carries a REVALIDATE-AT-COMMISSIONING flag).
- **The chunk carve** is `implementation/M5c-chunk-plan.md` (5 chunks along Scope 1–10). **Chunk 1
  (dispatch-chain)** and **chunk 2 (widget-outputs)** are **landed + reviewed + approved**:
  - Chunk 1 — `b9bcc16`, Opus APPROVE (`reviews/M5c-01.md`), one deferral flagged → chunk 4
    (`active_keyboard_route()` accessor / "stop names the console" deviation).
  - Chunk 2 — `6a3215e`/`f280096` + corrective take `b88bbbc`/`0186986`/`c3f3e5c`/`b8fb8af`, Opus
    APPROVE (`reviews/M5c-02c.md`, standing sign-off). Suite **759/0/0/6**.
- **Remaining M5c chunks:** **3 submit-cancel** (Scope 3) → **4 route-lifecycle** (Scope 5) → **5
  example-migration** (Scope 6 turtle+maze). Then **M7** (additive widget surface — carve it), then
  **M8** (terminal — revalidate, then carve).
- **Pinned seams / debts to carry into commissions** (from session02 track + chunk-1 review):
  - **Chunk-3/4 deactivate seam:** chunk 3 owns the *submit-time* deactivate step; chunk 4 owns
    *route-level* connect/teardown + **removal of the M4 ruling-1 forwarding**
    (`projectInputController.lua:141-142`, the `app_state ~= 'running'` → `Controller._defaults`
    branch). Name this in both commissions so neither silently re-scopes the other.
  - **Chunk-1 deferral → chunk 4:** the `active_keyboard_route()` accessor / "stop names the console"
    deviation (`reviews/M5c-01.md`).
  - **Human REVIEW markers on `projectInputController.lua`** (session02 track): L66+L117 (install
    natives as callbacks) are **design-adjacent / not free** — escalate-or-leave, do not
    materialize into public slots (violates R7/activate docstring). L70/77/78/97 cosmetic → final pass.
  - **Suite `-- REVIEW:` markers** (`input_contracts_spec.lua`): reconcile only those homed in the
    chunk you are running; leave L401 (M7 prompt-labelling), L495/508-510 (chunk-4 console-as-sink),
    L536 (editor block-nav, kept-OPEN) for their owners. Guardrail 4: reconcile-or-escalate, never
    silent-delete.
  - **Chunk 3 specifically deletes `oneshot` and dissolves the `push('userinput')` producer**; the
    polling **consumer** idiom survives until M8 (E32 push-slice split — do not re-couple).
  - **Guardrail 7 nested checkouts:** `src/examples/maze/` (chunk 5) and `src/examples/balloons/`
    (M8) migrate as **uncommitted working-tree changes**, listed file-by-file in the outcome ledger —
    the human carries the patch upstream. `keyboard` is pure-native — never migrated.
- **M8 REVALIDATE-AT-COMMISSIONING:** `spec/M8-02-recut.md` was authored before M5c/M7 landed. Before
  carving M8, diff its mechanics against the M5c + M7 outcome ledgers; if they drifted, that is an
  adjacent-slice / escalation matter, not a silent adaptation.

## The per-chunk cycle (repeat for 3, 4, 5, then each M7 / M8 chunk)

1. **Carve if needed.** M5c is already carved (chunk-plan). M7 and M8 are **not** — when you reach
   them, carve each into small independently-reviewable chunks along its spec's scope, write the carve
   as a first-class artifact (like `M5c-chunk-plan.md`), before commissioning.
2. **Write the commission to disk** — `prompts/M5c-03-<slug>.md` (never inline it). Follow the shape of
   `prompts/M5c-02-widget-outputs.md`: scope, in-scope ACs, the seam/boundary section, "read first"
   authority chain, "do in this order" (test-first: red rows precede implementation), outcome-ledger
   spec, boundaries. Optionally a `<id>-review.md` note pinning the chunk's traps (recommended — it
   sharpened the chunk-2 review). Commit the commission (`docs(input): commission …`).
3. **Spawn the Sonnet implementor** (see below). It implements test-first, commits locally, records
   `outcomes/<id>.md`, reports back.
4. **Spawn the Opus reviewer** (see below) on the finished diff + ledger. It writes `reviews/<id>.md`,
   may correct `technical_debt.md`, reports a verdict.
5. **Act on the verdict.** APPROVE → commit any review artifacts, `TaskUpdate` done, go to next chunk.
   CORRECTIVE-TAKE → commission a corrective take (like `M5c-02c`), re-run implementor, re-review.
   ESCALATE / real design gap → consult Fable advisor; conservative-reversible choice + loud
   surprise-first flag; continue.
6. **Commit the review artifacts** (`docs(input): land <id> review …`).

## How to run the sub-agents (the mechanism)

There is no bespoke "dev"/"review" agent type. Use the **`general-purpose`** agent type with a **model
override** and have the agent **boot from the charter file**:

- **Implementor** — `Agent(subagent_type: "general-purpose", model: "sonnet", run_in_background:
  false)`. Prompt it: *"Boot exactly as `agents/dev.md` instructs. Your milestone id is `<id>`. Read
  and follow `…/implementation/prompts/<id>.md` (self-contained, authoritative). rules.md +
  development.md auto-load via repo-root CLAUDE.md — follow them (hard limits, tests-first,
  report-don't-fix, Conventional Commits, commit locally NEVER push). Never edit `design/`. Tests are
  headless `busted tests` (never xvfb; there is no standalone `lua`). `sleep 1` after a `.lua` edit
  before lua-lsp MCP calls. Record `outcomes/<id>.md`, commit locally, report back: per-item summary,
  commit hashes, before/after busted counts. If anything forces a design choice, STOP and report."*
- **Reviewer** — `Agent(subagent_type: "general-purpose", model: "opus", run_in_background: false)`.
  Prompt it: *"Boot exactly as `agents/review.md` instructs. Milestone id `<id>`. If a filled
  `prompts/<id>-review.md` exists, follow it; else clone `review-prompt.md`. Verify-don't-trust: re-run
  `busted tests` yourself; use lua-lsp `references` to confirm no caller regressions. Edit ONLY your
  review + `technical_debt.md`; NEVER feature code or `design/`. Write `reviews/<id>.md`, report a
  verdict (approve / corrective-take / escalate) + the busted counts."*
- **Run them `run_in_background: false`** (synchronous) so you get the result and orchestrate the next
  step in one flow — the chunk pipeline is strictly serial (implement → review → decide).
- **One cold run per role per chunk.** Do not reuse an implementor as its own reviewer. If a sub-agent
  returns an `agentId`, you *may* `SendMessage` it to continue that same context (e.g. ask the
  implementor to apply a one-line review nit) rather than spawning cold — cheaper and context-preserving
  — but keep implement and review as **separate** agents.
- **Budget discipline** (mandate): Sonnet for the grind, Opus for the judgement. Don't churn.

## The Fable-5 advisor (expensive — hard calls only)

Fable 5 is the smartest and **most expensive** model. Use it **only** when a genuinely hard call needs
the best available reasoning — not for routine orchestration, not to double-check an obvious decision.
Legitimate triggers: a real spec-gap / corpus-contradiction you cannot resolve from the authority
chain; a design-shaped judgment where a wrong call is costly and hard to reverse; the chunk-3/4 seam
turning out to genuinely collide; the M8 revalidation surfacing real drift.

- **Invoke as an advisor, not an implementor:** `Agent(subagent_type: "general-purpose", model:
  "fable", run_in_background: false)` with a **tight, self-contained question** — hand it the exact
  corpus refs (authority-chain paths + the conflicting lines), state the decision and the options you
  see, and ask for a recommendation **with reasoning and the corpus citation**. It advises; **you**
  (the PM) still own the call and the human still reviews post-factum. Record the advice + your decision
  in the chunk's outcome ledger (cite it like any other source).
- **Do not** use Fable for mechanical work (implementing, reviewing, running tests) — that is
  Sonnet/Opus. Fable is the escalation plane's stand-in this session, nothing more.

## Wrap (mechanical, when you pause or finish)

Keep the running track (`session03/track.md`) current as you go (`[project]` / `[behavioural]`,
behavioural stays raw). When you pause or the sweep completes: write `session04/prompt.md` (carryover +
these same permissions), repoint `agents/sweep.md` CURRENT PROMPT (session03 → session04), commit the
wrap. Only the session number changes in the sweep pointer.
