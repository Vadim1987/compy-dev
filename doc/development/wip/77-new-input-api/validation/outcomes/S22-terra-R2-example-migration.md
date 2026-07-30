# S22 Terra outcome — R2 tracked-example migration

## Result

Completed the approved migration in the three tracked examples only:

- `guess` and `valid` now supply their existing per-line predicates through
  `LineValidators`; their one-line callbacks read `lines[1]`.
- `tixy` now supplies `LuaHighlighter` and `LuaSyntaxValidator`; its existing
  array-aware `submit_body` callback is unchanged.
- Comments no longer describe `ValidatedTextEval` or `InputEvalLua` as the
  project API, while preserving continuous-session behaviour.

## Verification

`busted tests` passed: **862 successes, 0 failures, 0 errors, 3 intended
pending**. There is no tracked example-launch harness; the project suite is
the available regression evidence. A separate `luac -p` pass was attempted,
but `luac` is not installed in this container. The Lua MCP/LSP tool was not
exposed to this worker, so it could not provide diagnostics.

## Boundaries

No persistent documentation, tests, frozen design files, untracked example
directories, or unrelated files were changed. No commit was made; the parent
owns the migration commit seam.
