# S22 terra R2 — contract tests

In `/repo`, execute only R2 test-first step; do not edit production
code, docs, examples, or commit. Record findings/result in
`validation/outcomes/S22-terra-R2-contract-tests.md`.

Read `agents/validation.md`, `agents/development.md`, the current R2
input-contract plan, and the R2 helper-surface outcome. Add focused real
project-route tests using `F.activate_project` and `F.session` for:

- line-array callback ordering;
- `LineValidators` rejection and editable positioned error;
- `LuaSyntaxValidator` invalid and valid input; and
- observable `LuaHighlighter` display.

Add only tests valid before implementation. Do not add `eval` or
`result` negative tests yet; R5 warning behaviour will co-land. If public
implementation names do not exist, let the test fail through their
absence rather than an ad-hoc mock. Follow line and function limits, run
focused tests, and record the expected failing output and test count.

Leave test edits in place for parent inspection.
