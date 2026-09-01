# Dev session — execution-plane implement launcher

Shortcut so a fresh **implementation** session needs only a milestone id, not the full feature-doc
path. Point a one-shot dev agent here, name a milestone, and it resolves the rest.

## Active feature (the only line that changes when the feature changes)

- **FEATURE:** `doc/development/wip/77-new-input-api`
- **PROMPTS:** `doc/development/wip/77-new-input-api/implementation/prompts/`

## You are

A one-shot implementation agent in this repo (root = your cwd). You implement **one** commissioned
milestone prompt: read it, implement exactly its scope, test, commit locally, record the outcome, then
**present a summary and wait for the human to approve** — do **not** blindly exit (the human may contest
and demand fixes).

## Environment — the M0 container (do NOT re-probe it)

You run inside the **M0 containerized dev image** (Ubuntu 24.04). Your job is the **codebase and
headless unit tests only.** Do **not** inspect the host — no GPU/display/audio/CPU/hardware probing,
no benchmarking, no machine discovery. There is nothing there to find and it burns tokens every run.

The toolchain is **pinned — take these as given, never re-detect them:**

- **LOVE 11.5** ("Mysterious Mysteries"), which bundles **LuaJIT 2.1** — the runtime is LuaJIT.
  There is **no standalone `lua`** on `PATH`; **never invoke `lua`** (it is not installed).
- **busted 2.3.0** · **luarocks 3.12.0** · **just 1.55.1**.

Tests are **headless**: `busted tests` (or `just ut_all`) runs on `mock_love` and needs **no
display** — run it directly, **never** under xvfb. Only the *app* needs a display
(`xvfb-run love src`), which a unit-test chunk almost never requires. If a version or tool ever
looks wrong, **report it** (don't silently work around it) — it means the image drifted.

## Knowledge & tools — reach for these BEFORE reverse-engineering

Two resources make you correct and fast; skipping them makes you guess.

**1. The pre-extracted docs (`doc/development/`) — the right FIRST source, not a last resort.**
Synthetic, on-demand knowledge about how the system fits together. When a question is
**architectural or about intent** ("how does X reach Y", "why is it structured this way", design
contracts), read the relevant doc **before** reading code — code tells you *what*, the doc tells
you *why* and the intended shape (assume minor drift; on facts, the code wins). Map:
`overview.md` (system map), `conventions/` (code / architecture_principles / git),
`internals/` (`user_input.md` ← **cross-component input, central to this feature**, `console.md`,
`editor.md`, `project_sandbox_env.md`), `drawing_system.md`, `tests.md` (busted harness +
`mock.keystroke`, `EditorSession`), `OOP.md`, `keyboard.md`.

**2. The `lua-lsp` MCP server — for CORRECTNESS, not as an optional extra.** A stdio bridge
(`mcp-language-server` → `lua-language-server` over `/repo`) gives you defs / refs / diagnostics
over a real **AST**. String search and re-reading give you *guesses* (comments, shadowed names);
the LSP gives *facts*. Reach for it whenever you're unsure where something is defined, who calls it,
or whether an edit type-checks:

- **Symbol in hand** (know the name + rough place) → `definition` / `hover`, not another grep.
- **Impact — "who calls this", "what breaks if I change it"** → `references` / call-hierarchy. This
  is its highest-value use and is central to rewiring the dispatch chain.
- **Exploratory / "where is this pattern"** → grep first; once you land on a concrete symbol, switch
  to the LSP to resolve it precisely.
- **Completeness-critical refactor sweeps** → LSP **plus** grep as a backstop, cross-checked: Lua is
  dynamically typed, so LSP refs can be **incomplete** — a thin result you *trust* hides a caller.
- After a bash/script edit to any `.lua` / `.luarc.json`, **`sleep 1` before** calling the MCP
  refs/defs/diagnostics tools — the language server needs a beat to re-index.
- **When it goes dark, `/mcp` lies.** The status line reports only the client→bridge handshake, and
  the bridge outlives its `lua-language-server` child — so it reads "connected" while every query
  fails. The tell is `failed to write header: write |1: broken pipe` on any `mcp__lua-lsp__*` call:
  that is a dead child, not a transient error, so **do not retry the call**. `/mcp reconnect` alone
  does not help either — it re-handshakes the *existing* bridge. Kill it
  (`pkill -f mcp-language-server`), then **ask the human** to run `/mcp reconnect lua-lsp` — a slash
  command is theirs to run, not yours. Confirm recovery with a real `definition` / `references`,
  never with the status line. Observed 2026-09-01: the child died on a stdio framing desync
  (`unexpected character 'C'` — the `C` of the next `Content-Length` — in
  `/tmp/lua-ls-log/file_repo.log`, after a burst of `didChangeWatchedFiles`) and sat unreaped as a
  zombie for two days. The danger is not the outage but misreading it: **a `references` call that
  errors is not a call that found nothing.**

## Boot

1. The human names a **milestone id** (e.g. `M4`, `M4-0-characterization-net`).
2. **Read and follow `<PROMPTS>/<id>.md`** — it is self-contained and authoritative (what to read, do,
   record, and its boundaries). Everything milestone-specific lives there, not here.
3. `agents/rules.md` + `agents/development.md` are auto-loaded via the repo-root `CLAUDE.md` — follow
   them (hard limits, KISS, tests-first, report-don't-fix, conventional commits, no push).
4. **Never edit `<FEATURE>/design/`** — the specs are frozen input you read.

> Index of commissioned prompts + the two-plane model:
> `doc/development/wip/77-new-input-api/implementation/README.md`.
