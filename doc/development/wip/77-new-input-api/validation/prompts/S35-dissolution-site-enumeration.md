# S35 — cold enumeration of the held-key-set and `gui` sites (prompt of record)

**Spawned:** 2026-08-10, session35. **Model: Sonnet** (mechanical, scoped). **Read-only.**
**Deliberately cold:** the agent is given no plan, no prior site list, and none of the parent's
reasoning — the point is an inventory derived from the code, so that agreement with the existing
plan is confirmation and disagreement is a finding.

---

## Brief given to the agent (verbatim)

You are enumerating code sites in a LÖVE2D/Lua project at `/repo`. **Read-only: change nothing.**

Two related changes are about to be made to this codebase, and your job is to produce the
**complete, verified inventory of everything they touch**. You are being asked *only* to find and
classify sites — not to plan the change, not to judge whether it is a good idea, and not to make
any edit.

**Change A — the framework-maintained held-key set is being removed entirely.** Today the
framework keeps a table of currently-held keys, maintained from key events, and exposes it in
several forms. All of it goes: the table, everything that writes it, everything that reads it,
every view or proxy over it, every place it is handed to something else, every type declaration
and comment that names it. After the change, code that needs to know whether a modifier is held
asks the device instead (`love.keyboard.isDown`, or the `Key.*` helpers that wrap it).

**Change B — `gui` (the super/cmd/win key) stops being treated as a modifier.** Today it appears
as a fourth modifier alongside ctrl/alt/shift in the key-handling utility. It is being removed
from that set entirely, so `lgui`/`rgui` become ordinary key names.

### What to produce

Write your deliverable to
**`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S35-dissolution-site-enumeration.md`**.

For **every** site, give: `path:line`, the exact code or comment text (short quote), and a
classification. Group by classification, and within each group sort by file. Use these classes:

1. **WRITE** — code that mutates the held-key set.
2. **READ** — code that reads it (directly, or through a view/proxy/parameter).
3. **PLUMBING** — code whose only job is to pass it along: parameters, upvalues, closures,
   accessor functions, the memoised view and anything that exists to build or cache it.
4. **DECLARATION** — type annotations, field declarations, exported table entries.
5. **PROSE** — comments (and only comments) that name it.
6. **TEST** — anything under `tests/`.
7. **GUI** — everything belonging to Change B, in any of the above shapes.

Then add three sections of your own judgment:

- **"Would break"** — sites that, if the set were deleted and nothing else changed, would
  produce a runtime error or silently read `nil`. State which, and why. This is the most valuable
  part of your report: be concrete about the failure (e.g. "indexes a nil value at X").
- **"Ambiguous"** — anything you could not classify confidently, with what you would need to
  decide it. **Do not guess.** An honest "I could not tell" is worth more than a wrong class.
- **"Surprises"** — anything that struck you as unexpected, inconsistent, or out of place while
  looking. You have no context about this project's history or intentions; report what looks odd
  to a fresh reader, even if you suspect it is fine.

### How to search — both tools, cross-checked

A `lua-lsp` MCP server is available (`mcp__lua-lsp__definition`, `references`, `hover`,
`diagnostics`) and gives you defs/refs over a real AST of the `/repo` workspace. **Use both it and
grep, and cross-check them.**

- grep first to find candidate names, then the **LSP** to resolve a symbol precisely and to answer
  "who calls this".
- **The LSP is known to be incomplete on this codebase** — it cannot disambiguate a method name
  shared across tables, and it has previously missed occurrences hiding in type annotations,
  comments, computed string-key indirection (`t[k]` where `k` is a variable), and proxy paths
  where a field is resolved dynamically. **Grep is your completeness backstop. Trust neither
  alone**, and where the two disagree, say so explicitly in your report — that disagreement is
  itself a finding.
- Search `src/` and `tests/`. Also search `src/examples/` but **report it as a separate section**,
  because those are example programs rather than framework code.

### Reporting rules

- **Do not deduplicate by judgment.** If two lines look like "the same thing", list both.
- Quote what is actually in the file. Do not paraphrase code.
- If a count is stated anywhere, verify it yourself rather than repeating it.
- State the method that found each group (grep / LSP / both), so gaps in either are visible.
