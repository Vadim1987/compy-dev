# S42 — P9c/P13 cold review prompt

Perform a cold, read-only peer review of the completed P9c and P13 work in
`/repo`. Review against the user mandate, `agents/rules.md`,
`agents/development.md`, `agents/validation.md`, the session42 prompt, and the
operative plan `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`.
Inspect commits `6c127229` and `5b580661` plus the current tree. Focus
specifically on: (a) work done though not requested/expected; (b)
requested/expected work absent; (c) incomplete/improper work; (d)
unnecessary complexity/excess. Verify factual claims in code/tests. Do not edit
any production or test code; do not commit. First write the exact review prompt
you used to
`doc/development/wip/77-new-input-api/validation/prompts/S42-P9c-P13-cold-review.md`.
Write your findings, with severity, evidence paths/lines, and a clear "no
findings" statement if applicable, to
`doc/development/wip/77-new-input-api/validation/reviews/S42-P9c-P13-cold-review.md`.
The Lua MCP-LSP server is available for concrete Lua symbol/refs/diagnostics:
use grep to locate candidates then LSP; sleep 1s after Lua edits (you should
not edit Lua). It may be unavailable through this interface; if so state that
limitation and use code inspection carefully. Preserve all unrelated untracked
scratch and nested repositories. Do not rerun broad tests unless required for a
specific finding; narrow read-only tests are okay. Return a concise chat summary
after materializing both artifacts.
