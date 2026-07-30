# session23 — pre-TF2 gate revalidation

Read and strictly respect `agents/sessions.md`, `agents/validation.md`, and
`agents/rules/revalidation.md`. Boot normally: read this prompt, the complete
`../session22/report.md`, the session22 commissioning prompt and track, then
create `session23/track.md`. Do not edit any historical session artifact.

## Your task

Revalidate session22's outcome before the owner begins TF2. The commissioning
intent was to settle every PR-shaping decision and execute the agreed work so
the owner reviews the final candidate once, from a fresh navigation batch.

Follow the full revalidation checklist. This is a **delta check**, not a
feature sweep: verify the completed C1 authority integration, J1
plain-vocabulary cleanup, persistent contract corpus, code/test alignment, and
the TF2 navigation slices. Use code/doc evidence rather than trusting prior
reports. Confirm the slice partition against the current feature tip excluding
the unrelated owner Dockerfile commit if appropriate; distinguish the current
navigation batch from final Phase-G regeneration.

Write the structured result to
`doc/development/wip/77-new-input-api/validation/reviews/S23-revalidation-pre-TF2-gates.md`.
Run `busted tests` as the routine baseline check; expected result is **862 / 0 /
0 / 3**, with the three documented routing pendings. Report exact divergences
or corrections. Do not launch TF2, rewrite the feature, regenerate slices, or
make a new owner ruling without the human. If clean, explicitly ask the human
to accept the revalidation and open TF2 from the navigation slices.

## Carryover

Session22 completed all 12/12 pre-TF2 dispositions and its required execution;
the concise outcome and non-obvious caveats are in `../session22/report.md`.
The fresh navigation batch is commit `4c002e8`, but it is only a review aid;
final PR assembly regenerates it after later work settles. Owner scratch and
the Dockerfile-only commit `16546af` are out of scope.
