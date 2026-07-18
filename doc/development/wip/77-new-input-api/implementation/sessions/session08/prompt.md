# session08 — PR pre-review: owner REVIEW-remark triage

_Cold boot 2026-07-18 (Fable-5, session "New input API: PR pre-review").
No handover file existed for the work between session07 (2026-07-15)
and now; this note reconstructs the gap. Repo root = cwd; commit
locally only on owner request, never push._

## Gap since session07 (untracked work)

- PR slices assembled and committed for history (`aa1d002`), balloons
  patch hand-fixed (`4d8c240`); three code fixes landed (`1a2a9a3`,
  `e38f8bb`, `e9adce9`).
- **Owner ran a manual pre-review pass** (2026-07-17/18) over the
  files touched by the load-bearing `3*` PR slices, spreading fresh
  `REVIEW:` / `REVIEW/DOC:` remarks across src, tests and helpers.
  (These are NEW owner remarks — unrelated to the 31 markers session07
  cleared.) The pass stopped mid-file in
  `tests/input/input_contracts_spec.lua` around **L604**; remarks
  below that line are from previous runs and may be desynchronized.

## Owner's marking format (from input_contracts_spec.lua L75–76)

- `{badspecref: <original ref>}` — spec reference not resolvable to
  the persistent docs corpus (formal signs: `§` paragraph character;
  abbreviation+number like `AC-25`, `M7-01`, `doc A`, `0.1.0-m5`,
  `#77`, `Decision 8` with no doc path).
- `{jargon: <phrase>}` — invented/LLM jargon (`slot`, `sink`,
  `native`, `overlay`, `tier-3`, `gate`, …).
- Occasional `{better: <suggestion>}` and `{oudated: …}` variants.

## This session's mandate

1. Map + triage all fresh REVIEW remarks: cosmetic (prose/refs/jargon
   in comments) vs conceptual (behaviour, architecture, identifier
   naming, test adequacy — owner-gated).
2. Subagents fix cosmetic remarks and sweep the `3*`-slice files for
   unmarked bad spec refs / jargon by the formal signs, wrapping them
   in the owner's format; produce a badspecref→persistent-doc fix
   plan. Reports land in this directory (`cosmetic-{a,b,c}.md`).
3. Summarize conceptual remarks for the owner (intent-drift check).
4. Owner discussion decides next steps; findings materialized after.

## WRAPPED 2026-07-18 → handover: `../session09/prompt.md`;
## judgment materialized: `../../reviews/pre-review-drift-assessment.md`

## Status (updated 2026-07-18, in-session)

Mandate items 1–3 DONE. Cosmetic pass complete over all `3*`-slice
files (reports: `cosmetic-{a,b,c}.md` here); only conceptual
REVIEW lines remain in the tree; suite 815/0/0/4. Drift assessment
delivered to owner in-session: submit/cancel placement = ratified
deviation D-a (design.md §9, Gate-2); 'tier/sink/slot' = ratified
§10 glossary, but 'native'/'overlay'/'tier3'-as-identifier are
minted outside it (real drift); UIC hidden-check may violate
Decision 2's "no external gate" (audit pending); hidden-console
tests likely console-route-correct, prose misleading (audit
pending); fixture fidelity = confirmed common-sense drift.
Corrective plan proposed; owner decisions pending on: two audits,
tier3→generic_callback rename, vocabulary-purge scope. NOTE:
`pr-slices/3*.patch` are now stale vs the working tree — must be
regenerated per `pr-assembly-guide.md` once the tree settles.

Persistent docs corpus for ref resolution: `doc/input_api.md`,
`doc/development/internals/user_input.md`,
`doc/development/decisions/input.md`,
`doc/development/technical_debt/{input,general}.md`,
`doc/development/tests.md`. Everything under `wip/77-new-input-api/`
is ephemeral (design/ frozen, read-only).
