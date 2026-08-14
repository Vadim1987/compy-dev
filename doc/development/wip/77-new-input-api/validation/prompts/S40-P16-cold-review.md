# S40 P16 cold review

Review commits `d77be355` and `b33f9521` independently and cold.

Scope:
- `src/examples/paint/main.lua` hook registration.
- `src/examples/turtle/main.lua` removal of Ctrl+Escape quit.
- Their associated persistent docs and operative P16 plan updates.

Check:
- The actual dispatch wiring: explicit hooks must preserve captured-callback semantics.
- The mouse-state caveat remains correct and no unrelated behavior moved.
- The framework still owns Ctrl+Escape quit, and turtle had no additional effect.
- Documentation and plan claims match the code; no stale references remain.
- Code style and repository constraints.

Use grep for exploration. Lua MCP-LSP is available for concrete symbol facts; use it when available, and sleep one second after a Lua edit before LSP queries. This is read-only: do not edit files, stage, commit, reset, or otherwise change Git state. Grep remains the completeness backstop.

Write the full review to `doc/development/wip/77-new-input-api/validation/outcomes/S40-P16-cold-review.md`. Classify findings by severity, state evidence, and say explicitly if none. Return a short digest only after writing the artifact.
