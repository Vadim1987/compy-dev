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

## 2026-07-29 — G-1 complete

- Applied and committed `93330dc` (`fix(input): close hidden-console
  fallback`). The test now proves both the hidden widget and console
  line remain unchanged; a temporary inverted assertion failed exactly
  there before restoration.
- `busted tests`: 854 / 0 / 0 / 4. G-1 is **1 of 12** visible
  pre-TF2 items dispositioned. Next batch remains C1, R4, RVW-100.

## 2026-07-29 — C1 ruled; documentation gate scheduled

- Owner ruled that the persistent documentation corpus is the authoritative
  #77 contract now and after release; `wip/77` remains detailed, non-shipping
  working evidence. New rulings need a concise canonical form as they are
  made, while the working record preserves rationale and reversals.
- A retrospective authority/provenance sweep is now an explicit pre-TF2 gate:
  after all pre-TF2 items are ruled and executed, a cold Terra inventories
  persistent claims against the working record; the owning session integrates
  concise status/provenance into persistent docs and verifies they stand alone.
  Navigation-batch generation and the owner's TF2 begin only afterward.
- C1 is **2 of 12** visible pre-TF2 items dispositioned. Its planned sweep is
  an execution gate, not a remaining authority question.
