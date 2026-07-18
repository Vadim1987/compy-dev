# session09 — prompt (pre-review triage DONE; evidence audits + owner ruling sheet next)

_Handover from session08 (Fable-5, "New input API: PR pre-review"), 2026-07-18. Boot as
**Opus orchestrator**; spawn **Sonnet** workers for mechanical/scoped work — ALWAYS pass the
model explicitly (session08 burned its limit by letting three cosmetic agents inherit Fable;
owner directive: Fable only for judgment passes, and prefer the main session for those).
Repo root = cwd; commits belong to the owner on this side — do not commit unless told;
never push. MCP-LSP available; `busted tests` baseline **815/0/0/4**._

## What session08 did

1. **Cosmetic pass over the `3*`-slice files is DONE.** The owner's 2026-07-17/18 pre-review
   pass left ~170 `REVIEW:` remarks; all cosmetic ones are resolved and deleted; bad spec refs
   are wrapped `{badspecref: …}` / `{jargon: …}` in the owner's uniform format (including the
   previously-unreviewed slice files). Only **conceptual** REVIEW lines remain in the tree.
   Reports + badspecref→corpus mapping proposals: `../sessions/session08/cosmetic-{a,b,c}.md`.
2. **Drift assessment + corrective plan + design stress-test plan** materialized at
   `../reviews/pre-review-drift-assessment.md` — READ IT FIRST; it is the working plan.
   Headline: submit/cancel placement = ratified deviation D-a (design.md §9, Gate-2), NOT
   implementor drift; hidden-console behaviour = likely the owner's own intra-route model with
   misleading prose (audit pending); real drift = minted nouns outside the §10 closed glossary,
   the ignored `tier3→generic_callback` rename, possibly the UIC hidden-check vs Decision 2
   (audit pending), and fixture infidelity (confirmed).

## Owner's strategic frame (drives everything next)

The PR must be **stakeholder-reviewable** from `doc/input_api.md` + PR description alone, and
must not carry moving parts/vocabulary beyond the stakeholders' ask (*simpler and more robust
input API*) without one-line justification. design.md was validated against stakeholder intent
but **never against post-implementation common sense** — the assessment's §3 defines the
stress-test (S1–S8) and a three-pass process: evidence audits → one consolidated owner ruling
sheet (folding in the 9 owner rulings + C1/C2) → focused execution.

## Next actions (in order; all owner-gated where marked)

1. [owner go?] Pass-1 evidence: audits A1 (UIC hidden-check vs Decision 2), A2 (hidden-widget
   test `app_state` + project-mode non-leak test + `love.harmony.utils` check), S1
   visibility/impact sketch, S7 fixture census. Sonnet-sized; evidence notes → this directory.
2. [owner go?] `tier3 → generic_callback` rename (mechanical, LSP + grep sweep).
3. Draft the **Pass-2 consolidated ruling sheet** from the assessment §3.2 + owner rulings 1–9.
4. [after rulings] Fixture-fidelity pass; badspecref mapping application (proposals in the
   cosmetic reports need owner approval first); ledger entries per assessment item 5.
5. LAST: regenerate `pr-slices/3*.patch` per `../pr-assembly-guide.md` — current patches are
   **stale** vs the working tree.

## Standing facts / cautions

- Owner's REVIEW remarks were never committed — `git diff HEAD` cannot reconstruct which were
  deleted; the cosmetic reports inventory current state instead.
- Stale REVIEW remarks remain below the owner's stop-boundary in `input_contracts_spec.lua`
  (listed in cosmetic-c.md) — owner to re-review or discard.
- Open from session07 unchanged: 9 owner rulings (`../../reviews/owner-rulings-verified.md`),
  C1/C2 incorporation calls, `wip/77` deletion (owner-gated), `ses/SWEEP.tgz` root-owned
  anomaly, untracked scratch files.
- Subagent self-reports of their own model are unreliable (they echo the session's environment
  text); judge by burn rate, and report a harness bug if an explicit `model: sonnet` override
  ever burns Fable-like.
