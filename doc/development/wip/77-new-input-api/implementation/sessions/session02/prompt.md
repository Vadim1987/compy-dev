# session02 — prompt (M5c: the dispatch chain)

_Genesis handover, written by the commissioning brainlab architect session (session40, 2026-07-07),
on Gate-3 close. There is no predecessor `report.md` in this lineage since session01 (Fable's M4 run)
— the carryover below restates what you'd otherwise read there. **Read the mandate first:**
`../../prompts/M5c-M8-sweep-mandate.md` (the `agents/sweep.md` boot pointer routes you through it).
The topology changed after session01 — read the "how this differs from session01" note below before
you plan anything._

## Carryover — where the corpus stands

- **Gate 3 is CLOSED (2026-07-07).** The re-cut plan **M5c → M7 → M8** is approved and the
  `spec/M5c-dispatch-chain.md`, `spec/M7-02-recut.md`, `spec/M8-02-recut.md` slices are **frozen**.
  Post-freeze gaps route to an adjacent `-NN` slice with prior human approval (process §9.1) — never
  a retroactive rewrite.
- **Authority chain (binding, in order):** `design/notes/ratified-model.md` (canonical — R1–R14,
  five rulings, binding glossary) → `design/design.md` + `design/spec.md` (Gate-2 contract) →
  `design/spec/M5c-dispatch-chain.md` (your slice — Scope 1–10, AC-1…AC-43). On any divergence the
  higher authority wins; mint no architectural nouns outside the ratified glossary.
- **The M4 guardrail suite is the baseline you evolve** — `tests/input/input_contracts_spec.lua`
  was verified green **718 / 0 / 0 / 12 pending** (`outcomes/M4-0-05-suite-cleanup-verify.md`,
  `dfd95c7`). **But M5c intentionally changes it:** AC-36 and AC-39–43 invalidate some M4-landed
  green rows *by design* (human-confirmed). The retirement lifecycle is a hard rule (AC-43, no
  silent retirement): a row exercising deleted machinery goes **`#deprecated` → red on delete →
  `pending()`** (busted has no xfail) **→ deleted only when a green equivalent through the new chain
  lands**. AC-35 still mandates a green suite at the slice boundary — rows end `pending()`-or-deleted,
  never red at the boundary. Do not "fix" a green row by loosening it; retire it through the lifecycle.

## Human rulings already made — do NOT re-ask, do NOT re-open

The entire E29→E33 chain is settled. In particular:
- The four-tier chain, R1–R14, and the five architect rulings are **ratified** — build the model,
  nothing beyond it (Gate-2 closing ruling: no further architectural unification in-slice; that round
  is the console/editor migration).
- `on_text_entered` = widget output, **submit-time assembled text** (R1); the per-char chain callback
  is `on_text_input` (AC-40). Combo dispatch = **per-event sub-tables** (R14), three channels
  (AC-41) — the flat `handlers[combo]` table is forbidden.
- Legacy native captures = **precedence, not replace** (E30 R7): explicit `on_*` > captured native >
  noop; `love.*` read once at load, never overriding an installed `on_*`.
- The push-slice split (E32/§5 rework): the `push('userinput')` **producer** dies here at M5c
  (`on_text_entered` replaces the notification); the polling **consumer** idiom dies at M8/§9; the
  between-window is M8-02-recut's accepted dev-build window. Do not re-couple them.
- highlighter/validator are **functionally applied**, not merely settable (AC-42).

If implementation surfaces a genuine spec gap, corpus contradiction, or any in-slice design decision:
**stop and escalate to the brainlab architect / design plane** (guardrail 1 — an in-slice design
ruling is a gate failure). You set the schedule and hold the gates; you never re-architect.

## How this differs from session01 (topology correction, session35)

Session01 executed one pre-commissioned prompt (`M4.md`). **You do not do that.** There is a
`implementation/prompts/M5c.md`, but it was **demoted to an advisory outline** (session36) — it is a
14-step black-box commission that predates the topology correction and represents architect overreach
into your chunking. **Do not execute it as one prompt.** The **frozen `spec/M5c-dispatch-chain.md`
(Scope items 1–10 + AC-1…AC-43) is the architect's ordered decomposition and your authority** — carve
along it.

## Your task — carve, commission chunk 1, gate

Per the mandate (rules 1–3 in `agents/sweep.md`; the "a milestone is carved into multiple
independently-gated chunks" front-matter line):

1. **Orient.** Read the mandate, then the authority chain above, then the M5c slice end-to-end.
   M5c is the **widest slice in the plan (≈ 2× M4 by PERT)** — running it as one chunk defeats the
   reviewed-in-between discipline. It **must** be carved into several chunks.
2. **Carve M5c into small chunks along its Scope 1–10 sequence.** One chunk = the smallest step that
   is independently valuable *and* independently reviewable = one implementor run = one review = one
   gate. Present your proposed chunk decomposition to the human for approval before commissioning
   chunk 1 (the pre-run prompt gate).
3. **Commission chunk 1 to disk** as `implementation/prompts/M5c-01-<slug>.md` (tangible, never
   inlined — rule 1), test-first (red acceptance rows transcribing the relevant ACs precede
   implementation). Spawn the **Sonnet implementor** (`agents/dev.md`) for the grind; then the
   **Opus reviewer** (`agents/review.md`) on the finished diff + outcome ledger.
4. **Stop at the gate.** Present chunk 1 + its review to the human and wait for go/no-go before
   commissioning chunk 2. **Never chain two chunks past the gate.** Nested-checkout discipline
   (guardrail 7): `src/examples/maze/` migration (in M5c) is delivered as **uncommitted working-tree
   changes**, listed file-by-file in the outcome ledger — the human carries the patch upstream; never
   commit inside `src/examples/*/.git`.

## Wrap (mechanical)

After the human closes a chunk gate and you either continue or pause the session: write the successor
`session03/prompt.md` (running track + carryover), repoint `agents/sweep.md` CURRENT PROMPT
(session02 → session03), and end. Behavioural remarks stay raw in the track (no observation
distillation — that happens at brainlab reimport). Commit locally only on human approval
(Conventional Commits, no push, this repo only — guardrail 7).
