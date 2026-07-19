# session12 — track

## Boot — 2026-07-19

- HEAD: `9c70107` (session11 wrap chain complete; validation/reviews routing rule committed).
  Tree carries owner scratch + known anomalies (`agents/validation.md` guardrail 3) plus
  additional untracked owner dirs (`wip/clarification/`, `wip/pull-26/`, `doc/tall_blocks.md`,
  `src/examples/drawdebug|keyboard/`) — treated as owner scratch, not swept.
- Suite baseline confirmed: **815 / 0 / 0 / 4** (4 pending intentional). Go-signal.
- Model: **Fable** (per session12 prompt — judgement tier). No prior `session12/track.md` —
  clean boot, no mid-flight death.
- Read in order: `agents/validation.md`, `session12/prompt.md`, `session11/track.md`.
- Mandate: **plan-refinement judgement only** — evaluate the owner's proposed doc-integrity +
  test-fidelity gate before Phase B; deliver a plan revision proposal on disk for owner
  ratification. No code/test edits, no Phase B/D execution.

## Unit 1 — plan-revision proposal (2026-07-19)

Evidence read: owner note, A1/A2 outcomes, `validation/plan.md`, doc A (all 859 lines),
corpus headings (`input_api.md`, `internals/user_input.md`, `decisions/input.md`,
`tests.md`), spec describe-block map, `notes/input-suite-validation-map.md` head.
Facts verified in code/tree (not taken from reports):
- `get_user_input` **survives** in shipped `controller.lua:21-24`, reinterpreted as the
  console route's intra-route widget forward; `ProjectInputController` instantiated at
  `controller.lua:1192` → doc A's temporal frame ("forward" §7) largely landed; its
  mechanism notes are stale in both directions. Promotion-as-is would import a stale doc.
- Doc A self-declares unmet promotion preconditions (header "human-approved: NOT YET";
  §7 scope note: m6/m7 to be added before promotion).
- Corpus drift: `tests.md` suite section says 808 + stale pending line numbers
  (real 815/0/0/4; pendings 118/172/185/246 — same rows by content).
- Validation map records an open masked coverage gap (editor keypressed test drives
  textinput) — evidence for the owner's "smells were missed" suspicion.

Judgement delivered (both files, marked PROPOSED, owner ratification pending):
- `validation/reviews/plan-revision-2026-07-19-doc-test-gate.md` — reasoning of record:
  owner's 7 steps consolidated to two phases (DI: fidelity audit → promotion ruling →
  execute + re-sweep; TF: split → owner review → hint-scoped triage), gate = step 7.
  Four additions: circularity guard (validate doc A vs CODE, not suite), split
  behaviour-preservation contract (identical 815/0/0/4; fixture require-time coupling is
  the real risk), explicit non-absorption of the ~25 non-doc-A inventory refs (stay Phase
  C), Phase-B-consumes-DI1 wiring (overlap resolved by consumption, B slims). A2's two
  fixture-architecture questions pooled into TF3 triage — not lost. DI2 options (a)
  promote re-baselined / (b) merge into corpus / (c) reword refs; session12 prior: (b).
  Phase letters B–G deliberately untouched (labels load-bearing in frozen records) — new
  phases named DI/TF.
- `validation/plan.md` amended in place: revision banner, Phase DI + TF inserted between
  A and B, gate line, PROPOSED addendum on Phase B.

Escalated (owner queue, in order): ratify/amend this revision; DI2 promotion form; TF2
sitting; TF3 triage rulings. Standing gates unchanged (Phase D, jargon, wip/77 deletion).
Suite untouched this session (no code/test edits; baseline confirmed at boot only).

## Wrap up

Plan approved by human, implementing first step carried over to session12 (recommendation on models injected into plan)
