# session22 — track

## 2026-07-29 — boot

- Booted per `agents/validation.md` and `agents/sessions.md`.
  Re-entrance guardrail: no prior `track.md` or `report.md` in
  `session22/` — fresh start; this entry opens the track.
- HEAD `fcaf61b` (`docs(session21): wrap — mop-up CLOSED`);
  working tree has the sanctioned Dockerfile edit and sanctioned
  untracked scratch only. No changes made by this session yet.
- Suite: `busted tests` → **854 / 0 / 0 / 4**, matching the
  session22 prompt. The four intentional pendings remain in
  `tests/input/input_routing_spec.lua`.
- Read: `agents/validation.md`, `agents/sessions.md`,
  `session22/prompt.md`, `session21/prompt.md`, `session21/track.md`,
  and `session21/report.md`.
- Current task: assemble the owner-facing Part-1 back-filter before
  TF2. It must distinguish decisions that would force re-reading the
  same review files if deferred from decisions safe to leave for the
  later collapsed sitting; then wait for owner rulings.

## 2026-07-29 — revised pre-TF2 disposition pass

- Owner rejected the narrow reread-only back-filter. The operative
  criterion is whether a later ruling reshapes the PR candidate. Every
  known item must be executed, retained with an explanation, or
  explicitly excluded before TF2.
- Sol consultation: `validation/outcomes/S22-sol-pre-TF2-ruling-order.md`.
  First batch opened with 0 of 12 items dispositioned.

## 2026-07-29 — G-1 ruled and execution started

- Owner ruled G-1 a resolved #77 fix, not a contested inspect redesign:
  `updev` let unhandled running-project keyboard/text fall into the
  hidden console; #77's unconditional project route replaces it with a
  no-op. Inspect is the retained pre-feature debugger route.
- Required disclosure: Decision 11, code rationale, regression test,
  ledger closure, and initial `CHANGELOG.md` entry. Suite + commit
  pending.
