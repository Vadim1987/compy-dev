Perform the serial second half of J1: persistent production-source marker
cleanup only. Remove construction-era `{jargon:...}`, `{badspecref:...}`,
`REVIEW`/`DOC` markers, and implementation-WIP citations from tracked
`src/**/*.lua`. Keep plain current rationale or a permanent decision/debt
citation only when it explains non-obvious code. Do not change behaviour.

For genuine open architectural questions, record concise technical debt with a
revisit trigger only when not already covered. Inspect Decision 8 and the input
technical-debt register. Use grep then Lua LSP for concrete symbols; sleep one
second after Lua edits before diagnostics. Verify with `busted tests`,
`git diff --check`, and an empty source-marker grep, then commit the isolated
source/debt/artifact change without staging owner work.
