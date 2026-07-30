# S22 R5 -- unknown show keys execution plan

## Ruling

Owner-ratified 2026-07-30: unrecognised keys in show(config) warn and are
ignored. The rationale is direct user-experience benefit: a misspelled or
misplaced key must not fail silently.

## Deferred execution

Execute after the remaining pre-TF2 triage, alongside the R2 correction
chunk. Keep this as one small, test-first concern:

1. Add a real project-surface test that passes an unknown show key and proves
   one actionable warning.
2. Add a companion test for a field-write-only callback placed in show(config).
3. Make configuration application enumerate its accepted show keys and warn
   for each other supplied key, without changing recognised-key behaviour.
4. Update the public guide with the show-key versus direct-field boundary;
   remove the resolved technical-debt and drift wording; run the full suite.

The warning text should name the rejected key and direct the author either to
the documented show table or to the callbacks field where applicable. Do not
invent coercion, aliases, or a compatibility path for misspellings.
