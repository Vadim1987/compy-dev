# Compy — agent orientation (feat #77 implementation container)

You are running inside the feat/77 agentic dev image, in the **compy**
LÖVE2D project. The project root is mounted at **/repo** and is your cwd.

## Where the rules live — read on demand, do NOT duplicate them here

- **/repo/CLAUDE.md → /repo/AGENTS.md** — entry pointer to the rule chain.
- **/repo/agents/rules.md** — authoritative coding rules: hard limits
  (line ≤64, fn body ≤14 lines, params ≤4, nesting ≤4), formatting,
  design principles (file = console equivalence; functional > OOP;
  no string-tag dispatch), commit conventions, and an index of
  `/repo/doc/development/*`.
- **/repo/agents/development.md** — coding workflow: KISS; tests-first
  (start with a breaking test, then implement); report discovered
  non-blocking tech debt rather than fixing it; commit locally, never push.
- **/repo/agents/architecture_assistance.md** — the rules when doing
  analysis / inspection / review instead of writing code.
- **/repo/agents/context.md** — system overview + the command cheatsheet.

Reference docs under **/repo/doc/development/** (overview, conventions/,
internals/, drawing_system). Load on demand, not upfront.

## This workflow — human-managed, no brainlab process

- Specs to implement, outcome ledgers, and review prompts live under
  **/repo/doc/development/wip/77-new-input-api/implementation/**:
  `prompts/` (the task handed to you), `outcomes/` (where you record the
  result), `reviews/`, and `review-prompt.md` (the reusable review boot).
- Tests: `busted tests` (uses mock_love — no display needed).
- App, headless: `xvfb-run love src` (LÖVE needs a display).
- `doc/development/wip/77-new-input-api/design/` is a **frozen input** —
  read it, never edit it.

## Lua MCP↔LSP (the `lua-lsp` MCP server)

A local stdio bridge (`mcp-language-server` → `lua-language-server` over
the `/repo` workspace) gives you defs/refs/diagnostics over an AST —
prefer it to re-reading files; it cuts token churn.

After a bash/script edit to any `.lua` or `.luarc.json` file, **pause
~1s (`sleep 1`) before** calling the MCP refs/defs/diagnostics tools —
the language server needs a beat to re-index the workspace.
