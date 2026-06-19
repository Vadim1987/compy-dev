# feat/77 agentic dev stack

A small, human-managed Docker stack for working the feat/77 implementation
with an assistant CLI on board. **No brainlab process** — you drive it.

**One container, `codeinspect`:** a bash session with three interchangeable
CLIs — `claude` (Claude Code), `cursor-agent` (Cursor CLI), `agy`
(Antigravity). Each is oriented to the project's own rules via
`/repo/CLAUDE.md → AGENTS.md → agents/rules.md` (plus `orientation.md`,
seeded into agy's `GEMINI.md` and claude's user memory), and each spawns
the Lua MCP↔LSP bridge **locally over stdio** for token-cheap code
navigation (defs/refs/diagnostics).

`/repo` = the project root (`topics/git/`), mounted `rw` (develop / review
/ commit).

## Use

```sh
# from this directory. On a non-1000 host, prefix with HOST_UID/HOST_GID
# ($UID is readonly in bash, so the HOST_ prefix is required):
#   HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose build
docker compose up -d --build
docker compose exec codeinspect bash

# inside the container (cwd = /repo), launch one CLI and work:
claude                 # chat, or implement a spec, or review
cursor-agent           # (set CURSOR_API_KEY on the host)
agy                    # first run: interactive Google auth (persisted)
```

Specs / outcomes / reviews live under
`/repo/doc/development/wip/77-new-input-api/implementation/` (`prompts/`,
`outcomes/`, `reviews/`, `review-prompt.md`) — reachable via the baked
**`/impl`** symlink, so in a CLI chat you just say e.g.
`implement /impl/prompts/M2.md` or `run /impl/review-prompt.md`.

## Lua MCP↔LSP

No sidecar. Each CLI launches, over stdio (see `src/agent/mcp.json`):

```
mcp-language-server --workspace /repo --lsp lua-language-server \
  -- --logpath=/tmp/lua-ls-log --metapath=/tmp/lua-ls-meta
```

- `mcp-language-server` ([isaacphi], generic — takes any stdio LSP) is
  built in a Go stage and copied into the image.
- `lua-language-server` (LuaLS) is installed from its latest GitHub release.

**Picking up the agent's edits:** the bridge runs an fsnotify (→ inotify
on Linux) `WorkspaceWatcher`. When a CLI edits a `.lua` on disk — outside
the LSP — the watcher debounces and fires `didChangeWatchedFiles`, so LuaLS
reindexes that file. Writer (the CLI) and watcher share one container +
kernel + bind mount on a native-Linux host, so events are *not* crossing a
FUSE/VM boundary — this is reliable here (unlike host→container inotify on
Docker Desktop). Edits land asynchronously, hence the `sleep 1`-before-query
rule in `orientation.md`. If a session ever logs `too many open files`,
raise `fs.inotify.max_user_watches`/`max_user_instances` on the host.

> The earlier draft's `nzrsky/lsp-mcp-server` sidecar was dropped: its image
> isn't published (ghcr 403), it's a *stdio* server (no TCP container needed),
> and it doesn't support Lua.

### Is it working?

The bridge isn't a daemon — each CLI spawns it (and `lua-language-server`
under it) as a child of *that session* when the CLI starts, and tears it
down on exit. So check it from inside a CLI, not from the bash prompt:

```sh
# build-time sanity (binaries present):
docker compose exec codeinspect mcp-language-server --help
docker compose exec codeinspect lua-language-server --version

# while a CLI session is open, in a second shell:
docker compose exec codeinspect ps -ef | grep -E 'mcp-language|lua-language'
docker compose exec codeinspect cat /tmp/lua-ls-log   # LuaLS activity

# inside `claude`: /mcp  → lists `lua-lsp` + its connection status/tools
#   then ask it "find references to <fn>" and confirm it answers from
#   the LSP rather than re-reading files.
```

## Notes / assumptions to verify

- **API keys** come from the host env: `ANTHROPIC_API_KEY` (claude),
  `CURSOR_API_KEY` (cursor). agy auths interactively; its token persists
  in the `agy-config` volume.
- **Config persistence**: `~/.claude`, `~/.cursor`, `~/.gemini` are named
  volumes — image seeds (MCP wiring, orientation) land on first `up`,
  edits persist. claude's MCP entry (`~/.claude.json`) is re-seeded on
  container recreate (not volumed); MCP stays configured either way.
- **Arch**: the LuaLS download is the `linux-x64` asset — on arm64 swap to
  `-linux-arm64` in `src/agent/Dockerfile`.
- **Unverified from the build host** (paste errors if they bite): the
  `go install` of mcp-language-server; the LuaLS release URL/asset name;
  that the bridge drives lua-language-server cleanly with the `--logpath`/
  `--metapath` passthrough. The three CLIs run fine even if the `lua-lsp`
  MCP server fails to start (it just logs a connect error).
- **Build versions** track CI (`.github/workflows/package.yml`) +
  `DEVELOPMENT.md`: LuaJIT 5.1, luarocks 3.12.0, LÖVE 11.5, Node 20.

[isaacphi]: https://github.com/isaacphi/mcp-language-server
