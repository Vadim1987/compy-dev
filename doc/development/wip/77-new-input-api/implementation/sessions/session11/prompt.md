# session11 — prompt (validation-phase execution, Phase A onward)

_Handover from session10 (Fable, 2026-07-18). Boot per `agents/validation.md` ritual
(formerly `agents/pr-prep.md` — older prompts use the old name): read it, create
`session11/track.md`, confirm baseline **815/0/0/4**, read predecessor
`session10/track.md` (short — session10 was a planning pivot, not execution)._

## Your mandate

Execute **`doc/development/wip/77-new-input-api/validation/plan.md`** — read it end-to-end
first; it is the plan of record and embeds owner decisions you must not re-ask (jargon
postponed to the sitting; design retrospectively challengeable via owner-gated proposals;
Pass-2 sheet consumed via disposition table; commit-at-discretion authority granted —
see the grant at the bottom of `agents/validation.md`).

Start at **Phase A** (mechanical integrity: A1 spec-reference sweep, A2 test-fidelity
audit — Sonnet workers, explicit `model: sonnet`, hygiene rules a/b/c per
`agents/validation.md`). Then Phase B (convergence check — your judgment, no code edits),
then Phase C (principle sheet + disposition table). **Phase D is an interactive owner
sitting — do not start it unprompted; tell the owner when C is ready.**

## What session10 did

- Owner pivoted the phase away from the row-by-row Pass-2 walkthrough (the original
  session10 mandate) to the principle-level plan. Owner's raw notes preserved as
  `validation/plan_notes.txt`; the actionable successor is `validation/plan.md`.
- Fixed the stale wrap-rule `sed` path in `agents/validation.md` (targeted the old
  `agents/pr-prep.md` name — would have silently failed your wrap).
- No code or test changes; suite untouched at 815/0/0/4.
- Verified a stale handover claim: session09's tier3→generic_callback rename is already
  committed (`41709c0`), not pending in the tree as the session10 prompt stated.
- The owner granted explicit commit authority to all sessions (recorded at the bottom of
  `agents/validation.md`); session10's wrap was committed under it.

## Standing facts / cautions

- Suite baseline **815/0/0/4** (4 pending intentional) — the only unprompted re-check.
  Do NOT re-run the sweep or re-verify the feature.
- Pass-2 sheet: `../../reviews/../implementation/reviews/pass2-consolidated-ruling-sheet.md`
  — i.e. `implementation/reviews/`. The 9 owner rulings: FEATURE-level
  `reviews/owner-rulings-verified.md`; C1–C6: `reviews/incorporation-recommendations.md`.
- Verify before you rely: sheet evidence cells are strong, not gospel (two oracle claims
  overturned in session09). LSP for symbols (`sleep 1` after `.lua` edits before
  refs/diagnostics), grep as completeness backstop.
- Known anomalies to leave alone: `agents/validation.md` guardrail 3. `design/` files
  stay unedited (history); challenges to design go through Phase C/D as proposals.
- `wip/77` deletion is owner-gated, never automatic.

WRAPPED 2026-07-19 → handover: ../session12/prompt.md
