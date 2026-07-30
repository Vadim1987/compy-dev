# S22 Terra — TF2 review-navigation slices

Generate the owner-approved TF2 review-navigation slice batch, not the final
Phase-G assembly. Read `agents/validation.md`, the session22 prompt,
`implementation/pr-assembly-guide.md`, and the relevant TF2/G plan sections.

Materialize this exact prompt and an outcome at
`validation/outcomes/S22-terra-TF2-navigation-slices.md`. Do not alter
production, tests, or persistent docs. Verify whether the guide's stale
`OUT=./pr-slices` needs correcting to the tracked
`implementation/pr-slices/` path. Regenerate sets 1, 2, and 3a–f from
`BASE=3256aac` and the current committed `HEAD`; do not capture nested example
repositories or touch owner/untracked scratch.

Run guide §4 completeness/disjoint verification, `git diff --check`, and
`busted tests` (expect 862 successes, 0 failures, 0 errors, 3 pending). Report
slice file statistics and exact verification. Commit only the guide, slices,
and validation artifacts as one conventional `docs(validation)` commit after
green; do not stage `session22/track.md` or owner dirt. These slices are
navigation-only and must be regenerated again at final Phase-G assembly.

Lua LSP MCP exists but this task does not touch Lua; no LSP work is needed.
