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
internals/, drawing_system) are pre-extracted, synthetic knowledge —
on-demand, not upfront, **but they are the right first source, not a last
resort**. When a question is **architectural or about intent** ("how does
X reach Y", "why is this structured this way", design contracts), or when
you're **unsure how a subsystem fits together**, read the relevant doc
**before** reverse-engineering from code — code tells you *what*, the doc
tells you *why* and the intended shape (assume minor drift; the code wins
on facts). `internals/user_input.md` covers cross-component input usage
directly relevant to this feature.

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
the `/repo` workspace) gives you defs / refs / diagnostics over a real
**AST**. Reach for it for **correctness**, not as an optional optimization
— string search and re-reading files give you *guesses* (comments,
shadowed names, drifted memory); the LSP gives you *facts*. **You can
always use it when unsure** — if you're not certain where something is
defined, who calls it, or whether an edit type-checks, ask the LSP rather
than inferring.

Use the right tool for the query:

- **Exploratory / multi-symbol / "where is this pattern"** → grep first
  (correct opening move). Once you've **landed on a concrete symbol**,
  switch to the LSP to resolve it precisely — don't keep grepping a name
  you already have.
- **A symbol in hand** (you know the name + rough place) → LSP
  `definition` / `hover`, not another grep.
- **Impact / "who calls this", "what breaks if I change it"** → LSP
  `references` / call-hierarchy. This is its highest-value use and is
  central to **this** feature (unifying controller topology + rewiring
  event propagation = exactly this question).
- **Completeness-critical refactor sweeps** → LSP **plus** grep as a
  backstop, cross-checked. Lua is dynamically typed; LSP refs can be
  **incomplete**, and a thin result you *trust* will hide a caller. Treat
  refs as a strong hint, not ground truth — grep confirms you missed none.

After a bash/script edit to any `.lua` or `.luarc.json` file, **pause
~1s (`sleep 1`) before** calling the MCP refs/defs/diagnostics tools —
the language server needs a beat to re-index the workspace.
