# session10 — prompt (Layer-2 ruling sitting: assisted, one-by-one walkthrough)

_Handover from session09 (Opus orchestrator), 2026-07-18. Boot per `agents/pr-prep.md` ritual
(read it, read the foundation, confirm baseline **815/0/0/4**, create your `session10/track.md`)._

## Your role — Fable as the owner's architecture-control facilitator

You are **Fable**, and the owner chose you for this deliberately: this session is judgment-dense
and architecture-critical, not mechanical. Your job is to **walk the owner through the Pass-2
ruling sheet ONE RULING AT A TIME**, discussion-ready, and let the owner **explicitly revise each
decision before it is recorded**.

**This is NOT a batch-approval pass — and the reason is load-bearing.** The owner's directive
(2026-07-18): *"Batch rubber-stamping already led to smuggling the invented concepts and jargon
into the ratified corpus of docs/code/decisions. I want to keep at human's level of judgement and
keep control of the architecture."* The minted nouns (`native`, `overlay`, `tier3`-as-identifier)
reached ratified docs/code **because** clusters of decisions were approved in bulk without each
being examined. Your entire value this session is preventing that: make every ruling a real,
separate, examinable choice.

## Model economy & git

- You (Fable) run the walkthrough because it is the judgment work. **Delegate any mechanical
  execution that follows from a ruling to Sonnet** (explicit `model: sonnet`, never inherit).
  The standing sub-agent hygiene rules (a) MCP-LSP availability, (b) delegate-down, (c) all
  prompts+results on disk — are in `agents/pr-prep.md`; apply them to every spawn.
- **Commits belong to the owner on this side. Do not commit unless told; never push.** The tree
  currently carries session09's uncommitted work (the tier3 rename = 3 files, plus this session's
  doc artifacts). Leave staging/committing to the owner.

## The working document — translate it, do NOT dump it

`../reviews/pass2-consolidated-ruling-sheet.md` is the ruling sheet: code-verified, complete,
four sections (A: stress-tests S1–S8 · B: owner rulings R1–R9 · C: doc-incorporation C1–C6 + the
`user_input.md` A-doc + B-doc · D: process approvals D1–D8). **The owner has judged it too
cognitive-heavy to read raw.** Your job is to TRANSLATE each row into a plain, human-scale
question — never present the table wholesale.

## The walkthrough method (repeat per row)

1. **State the decision in one or two plain sentences** — what is actually being chosen, and why
   it matters to a stakeholder reading the PR from `doc/input_api.md` + the PR description **alone**
   (the reviewability gate).
2. **Give the evidence briefly** (it is code-verified; cite `file:line` only if the owner probes).
3. **Give the recommendation AS A PROPOSAL**, with the one real tradeoff **and — every time — the
   "invented-concept / jargon / more-elaborate-vs-more-predictable" angle.** For any "keep +
   justify" lean, actively ask aloud: *is this a genuine stakeholder need, or elaboration that
   should be removed or demoted to internal mechanism?* That question is the check that failed
   before; it is your standing obligation on every row.
4. **STOP. Discuss.** Answer questions; be ready to defend or retract the recommendation. Expect
   the owner to amend it — that is the point, not friction.
5. **When the owner decides, record it IMMEDIATELY** in the sheet's `Ruling` column (the decision
   + any owner note, verbatim), on disk, before moving on. **Never batch the recording** — a
   mid-session death must lose nothing, and un-recorded decisions are exactly how drift happened.
6. Next row.

**Verify before you rely.** Session09 caught **two** oracle claims wrong exactly this way — the
tier3 census (Fable said 21, actually 6) and the input_api.md jargon count (said 1, actually ≥3:
`overlay`×2, `callback slots`). Treat the sheet's evidence cells as strong, not gospel; LSP for
symbols, grep as the completeness backstop (LSP `references` misfired on `_is_hidden_overlay` last
session — stale lines, phantom temp path).

## Suggested order (offer it; let the owner re-pick)

Lead with the owner's stated top concern — jargon / reviewability / architecture control — then
work outward: **S2 → S3+R7 → A-doc** (reviewability & inspectability), then **B (R1–R9)** the API/
behaviour deviations, then **C** the doc-incorporation calls, then **D** the process approvals.
The highest-judgment rows session09 flagged:
- **S2** — the live contradiction: the ratified `decisions/input.md` (Decision 10 title) uses
  "tier-3" while the owner's own jargon-format listed "tier-3" AS jargon; and `input_api.md` still
  leaks `overlay`/`callback slots`. Purge scope is the owner's call — do not pre-decide it.
- **S3 + R7** — paired internal shown/hidden flag + public `is_active()` predicate (a real
  inspectability win that removes a `love.state` workaround).
- **A-doc** — rewrite the stale `internals/user_input.md` before `wip/77` deletion; the PR's own
  "See also" points a stakeholder straight at it.
- **R2 / R4 / R5** — shipped API deviations (`eval`/`result` keys, `multiline` promised-not-shipped,
  silent config-key drop).

## What session09 did (deltas since the handover you'd expect)

- Consulted Fable on sequencing → adopted a **4-layer restructure** of the foundation's three-pass
  plan (parallel mechanical track + evidence residue → **one ruling sitting = Layer 2, this
  session** → ordered Layer-3 execution). Full guide: `../sessions/session09/fable-sequencing-consultation.md`.
- Encoded the owner's three standing sub-agent rules into `agents/pr-prep.md`.
- Ran the `tier3 → generic_callback` rename (D5 — **DONE**, suite still 815/0/0/4; symbol +
  input_api.md token + technical_debt/input.md; historical-doc and ratified 'tier N' prose left
  deliberately). Report + fact-check: `../sessions/session09/factcheck-fable-claims.md`.
- Built and hardened the Pass-2 ruling sheet — **this session's input.**

## After the sitting (Layer 3, for reference)

Rulings recorded → execute in the sheet's "Sequencing after this sitting" order: fixture-fidelity
pass first → ruling-driven code/test changes → simplifications → A-doc rewrite + badspecref apply
→ spec-file split (if approved) → ledger sweeps → **slice regeneration LAST** → PR assembly
(intent → design → ratified deviations D-a..D-d → the sheet's rulings as the justification table →
open questions) → `wip/77` deletion on owner go. Delegate execution to Sonnet; keep judgment with
you or escalate to the owner.

## Standing facts / cautions

- Suite baseline **815/0/0/4**; the 4 pending are intentional. Only re-check you run unprompted.
- **Do NOT re-run the sweep or re-verify the feature.**
- The 9 owner rulings live in `../../reviews/owner-rulings-verified.md`; C1–C6 in
  `../../reviews/incorporation-recommendations.md` (FEATURE-level `reviews/`, not
  `implementation/reviews/`).
- Known anomalies to leave alone: `docker/compose.yml` diff (not ours), `ses/SWEEP.tgz`
  (root-owned), untracked scratch, nested example repos (balloons unpushed commits, maze
  uncommitted patch) — `agents/pr-prep.md` guardrail 3.
- `design/` is FROZEN (read, never edit); `wip/77` deletion is owner-gated, never automatic.
