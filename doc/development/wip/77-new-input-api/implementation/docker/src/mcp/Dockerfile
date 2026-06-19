# MCP <-> LSP bridge for Lua. Exposes an MCP server (lsp-mcp-server)
# driving lua-language-server over the /repo workspace, reachable on TCP
# 5000 — the agent container dials it via `socat STDIO TCP:lsp-mcp:5000`
# (see ../agent/mcp.json).
#
# ⚠ UNVERIFIED against the actual base image — confirm before relying on
#   diagnostics:
#     - is the base Alpine? (`apk` assumed) — switch to apt if not
#     - the lsp-mcp-server binary name / path on PATH
#     - whether it takes the workspace root as an arg/env (here: WORKDIR
#       /repo + the :ro /repo mount from compose.yml)
# Fixes vs the draft: port 500 (privileged) -> 5000 (matches mcp.json);
# folded the quoted `EXEC:'/lsp-mcp-server'` CMD into the ENTRYPOINT
# (the quotes were taken literally by socat); dropped the stray VOLUME.

FROM ghcr.io/nzrsky/lsp-mcp-server:latest

RUN apk add --no-cache socat lua-language-server

WORKDIR /repo

# Bridge stdio<->TCP: every TCP connection forks a fresh lsp-mcp-server.
ENTRYPOINT ["socat", "TCP-LISTEN:5000,fork,reuseaddr", "EXEC:lsp-mcp-server"]
