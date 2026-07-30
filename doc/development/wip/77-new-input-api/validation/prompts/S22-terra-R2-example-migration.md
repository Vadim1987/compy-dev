# S22 Terra task — R2 tracked-example migration

## Scope

Migrate only the tracked `guess`, `valid`, and `tixy` examples from the
retired project-facing `eval` key to the ratified R2 overlay contract.

## Required change

- `guess` and `valid`: use `validator = LineValidators({...})`; callbacks
  receive line arrays and read their one submitted line.
- `tixy`: use `highlighter = LuaHighlighter` and
  `validator = LuaSyntaxValidator`; retain the line-array submit callback.
- Retain the examples' observable demo behaviour and continuous-session
  semantics. Remove stale evaluator terminology from their comments.

## Boundaries and evidence

Do not modify persistent docs, tests, frozen design input, untracked example
directories, or unrelated files. Record an outcome in the matching
`validation/outcomes/` path. The helpers are already exposed to project
environments by the R2 production commit. No tracked example execution
harness exists; run the full Busted suite as regression evidence and report
that limitation. Do not commit; the parent owns the commit seam.
