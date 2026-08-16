# S42 — P9c/P13 follow-up cold review prompt

Perform a cold, read-only peer review of the follow-up commits after the
first P9c/P13 cold review: `5f1ef541`, `ca7b26f0`, `7826a0e5`, `b31e99a9`,
and `29561c75`. Work in `/repo`. Assess against the user mandate,
`agents/rules.md`, `agents/development.md`, `agents/validation.md`, the
session42 prompt, and the operative S27 plan. Focus explicitly on:

- work done but not requested or expected;
- requested or expected work missing;
- incomplete or improper work; and
- excessive or unnecessary complexity.

Verify claims in code and tests. Do not edit production or test code, and do
not commit. Preserve unrelated untracked scratch and nested repositories.
Use grep and the Lua MCP-LSP when it is exposed; otherwise record that it was
unavailable. Run only narrow tests if they are needed. Write this exact prompt
to `doc/development/wip/77-new-input-api/validation/prompts/S42-P9c-P13-followup-cold-review.md`
and findings, including severity and path/line evidence or a clear no-findings
statement, to
`doc/development/wip/77-new-input-api/validation/reviews/S42-P9c-P13-followup-cold-review.md`.
