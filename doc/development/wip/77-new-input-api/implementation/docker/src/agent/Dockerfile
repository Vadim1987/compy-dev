# Agentic dev image for the feat/77 implementation workflow.
# NOT a dockerization of the canonical project — see ../../prompts/M0.md.
#
# Hosts THREE interchangeable assistant CLIs over the compy toolchain:
#   - claude        (Claude Code, global npm)
#   - cursor-agent  (Cursor CLI, ~/.local/bin)
#   - agy           (Google Antigravity, ~/.local/bin)
# Exec a bash session in, launch whichever one, then: chat about the
# code, hand it a spec from /repo/.../implementation/prompts/, or run a
# review. Each CLI keeps its own config dir; compose.yml mounts those as
# named volumes, so the image-baked seeds (MCP wiring, orientation) land
# on first `up` and the human's later edits + auth tokens persist.
#
# Lua MCP↔LSP (token-saving code nav): each CLI spawns, over stdio,
# `mcp-language-server --workspace /repo --lsp lua-language-server`
# (no sidecar, no network — see mcp.json).
#
# Toolchain: LuaJIT 5.1 / luarocks 3.12.0 / busted+luautf8+luafilesystem
# / LÖVE 11.5 / just / Node 20 LTS.
# Unit tests (busted) do NOT need LÖVE — mock_love covers them.
# `love src` needs a display; wrap with `xvfb-run` for headless use.

# ── stage 1: build the generic MCP↔LSP bridge (Go) ──────────────────
# Built here, copied as a static binary into the final image — keeps Go
# out of the runtime layer.
FROM golang:1.24-bookworm AS lspbridge
RUN go install github.com/isaacphi/mcp-language-server@latest

# ── final image ──────────────────────────────────────────────────────
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Host-matching uid/gid so files written into the /repo bind mount stay
# owned by the human. Override (note HOST_ prefix — $UID is readonly in bash):
#   HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose build
ARG UID=1000
ARG GID=1000
ARG USER=agent

# ── base utilities + LuaJIT ─────────────────────────────────────────
RUN apt-get update && apt-get install -y \
        ca-certificates \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        unzip \
        xvfb \
        luajit \
        libluajit-5.1-dev \
    && rm -rf /var/lib/apt/lists/*

# ── LuaRocks 3.12.0 (matches CI luarocksVersion: "3.12.0") ─────────
RUN wget -q \
        https://luarocks.org/releases/luarocks-3.12.0.tar.gz \
    && tar xzf luarocks-3.12.0.tar.gz \
    && cd luarocks-3.12.0 \
    && ./configure \
        --lua-version=5.1 \
        --with-lua-interpreter=luajit \
    && make install \
    && cd .. \
    && rm -rf luarocks-3.12.0 luarocks-3.12.0.tar.gz

# ── Lua rocks (system-wide; --local unneeded in single-purpose image)
RUN luarocks install busted \
    && luarocks install luautf8 \
    && luarocks install luafilesystem

# ── LÖVE2D 11.5 (DEVELOPMENT.md; ppa love-stable currently 11.5) ─────
RUN add-apt-repository ppa:bartbes/love-stable \
    && apt-get update \
    && apt-get install -y love \
    && rm -rf /var/lib/apt/lists/*

# ── just (task runner; CI: extractions/setup-just) ───────────────────
RUN curl --proto '=https' --tlsv1.2 -sSf \
        https://just.systems/install.sh \
    | bash -s -- --to /usr/local/bin

# ── Node.js 20 LTS (CI: node-version "lts/Iron") ────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_26.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Lua MCP↔LSP: generic bridge (from stage 1) + lua-language-server ─
# x86_64 asset; on arm64 swap the LuaLS asset suffix to -linux-arm64.
COPY --from=lspbridge /go/bin/mcp-language-server /usr/local/bin/mcp-language-server
RUN ver=$(curl -fsSL https://api.github.com/repos/LuaLS/lua-language-server/releases/latest \
            | grep -oP '"tag_name":\s*"\K[^"]+') \
    && wget -q -O /tmp/luals.tar.gz \
        "https://github.com/LuaLS/lua-language-server/releases/download/${ver}/lua-language-server-${ver}-linux-x64.tar.gz" \
    && mkdir -p /opt/lua-language-server \
    && tar -xzf /tmp/luals.tar.gz -C /opt/lua-language-server \
    && rm /tmp/luals.tar.gz \
    && ln -s /opt/lua-language-server/bin/lua-language-server \
        /usr/local/bin/lua-language-server

# ── unprivileged agent user ──────────────────────────────────────────
# uid 1000 ships taken by the default `ubuntu` user on 24.04 — remove it first.
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd -g ${GID} ${USER} \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}
USER ${USER}
ENV HOME=/home/${USER}
ENV PATH=/home/${USER}/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
VOLUME /home/${USER}

# ── Cursor CLI (cursor-agent → ~/.local/bin) ────────────────────────
RUN curl https://cursor.com/install -fsS | bash

# ── Google Antigravity CLI (agy → ~/.local/bin) ─────────────────────
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

USER root
# ── Claude Code ─────────────────────
RUN ACTUALIZE=20260701 npm install -g @anthropic-ai/claude-code
USER ${USER}

# ── MCP wiring ───────────────────────────────────────────────────────
# One mcp.json (lua-lsp via the local stdio bridge) seeded into each
# CLI's native MCP config path — all three accept the same {mcpServers}
# shape. These dirs are named volumes (compose.yml): seed lands on first
# `up`, edits persist after.
COPY --chown=${USER}:${USER} mcp.json /home/${USER}/.cursor/mcp.json
COPY --chown=${USER}:${USER} mcp.json /home/${USER}/.gemini/antigravity-cli/mcp_config.json
COPY --chown=${USER}:${USER} mcp.json /home/${USER}/.claude.json

# ── orientation pointer (no rule duplication — points at /repo's own
#    rule chain + the LSP re-index protocol). claude/cursor auto-load
#    /repo/CLAUDE.md + /repo/AGENTS.md from cwd; agy needs an explicit
#    global context file, and claude's user-memory reinforces the LSP
#    rule, so seed both. ──────────────────────────────────────────────
COPY --chown=${USER}:${USER} orientation.md /home/${USER}/.gemini/GEMINI.md
COPY --chown=${USER}:${USER} orientation.md /home/${USER}/.claude/CLAUDE.md

WORKDIR /repo
