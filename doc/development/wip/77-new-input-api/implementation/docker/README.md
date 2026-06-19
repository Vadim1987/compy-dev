# feat/77 agentic dev stack

A small, human-managed Docker stack for working the feat/77 implementation
with an assistant CLI on board. **No brainlab process** — you drive it.

Two services:

| Service | What it is | /repo mount |
|---|---|---|
| `codeinspect` | bash container with three interchangeable CLIs: `claude` (Claude Code), `cursor-agent` (Cursor CLI), `agy` (Antigravity) | `rw` (develop/review/commit) |
| `lsp-mcp` | MCP↔LSP bridge for Lua (defs/refs/diagnostics) to cut token churn | `ro` |

`/repo` = the project root (`topics/git/`). Each CLI is wired to the same
`lua-lsp` MCP server and oriented to the project's own rules via
`/repo/CLAUDE.md → AGENTS.md → agents/rules.md` (plus `orientation.md`,
seeded into agy's `GEMINI.md` and claude's user memory).

## Use

```sh
# from this directory. On a non-1000 host, prefix with UID/GID:
#   UID=$(id -u) GID=$(id -g) docker compose build
docker compose up -d
docker compose exec codeinspect bash

# inside the container (cwd = /repo), launch one CLI and work:
claude                 # chat, or implement a spec, or review
cursor-agent           # (set CURSOR_API_KEY on the host)
agy                    # first run: interactive Google auth (persisted)
```

Specs / outcomes / reviews live under
`/repo/doc/development/wip/77-new-input-api/implementation/`
(`prompts/`, `outcomes/`, `reviews/`, `review-prompt.md`).

## Notes / known-open

- **API keys** come from the host env: `ANTHROPIC_API_KEY` (claude),
  `CURSOR_API_KEY` (cursor). agy auths interactively; its token persists
  in the `agy-config` volume.
- **Config persistence**: `~/.claude`, `~/.cursor`, `~/.gemini` are named
  volumes — image seeds (MCP wiring, orientation) land on first `up`,
  edits persist. `claude`'s MCP entry (`~/.claude.json`) is re-seeded on
  container recreate (not volumed); MCP stays configured either way.
- **`lsp-mcp` is unverified** against its base image (port/entrypoint/
  workspace wiring — see `src/mcp/Dockerfile`). `codeinspect` builds and
  runs independently of it; verify it first, then iterate on `lsp-mcp`.
- **Build versions** track CI (`.github/workflows/package.yml`) +
  `DEVELOPMENT.md`: LuaJIT 5.1, luarocks 3.12.0, LÖVE 11.5, Node 20.
