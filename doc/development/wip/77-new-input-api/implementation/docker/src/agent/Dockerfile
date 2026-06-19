# Agentic dev image for the feat/77 implementation workflow.
# NOT a dockerization of the canonical project — see M0 prompt.
#
# Provides: LuaJIT 5.1, LuaRocks 3.12.0, busted/luautf8/luafilesystem,
# LÖVE 11.5, just, Node 20 LTS, Claude Code.
# Unit tests (busted tests) do NOT need love — mock_love covers them.
# love src requires a display; wrap with xvfb-run for headless use.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── base utilities + LuaJIT ─────────────────────────────────────────
RUN apt-get update && apt-get install -y \
        ca-certificates \
        curl \
        wget \
        socat \
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

# ── LÖVE2D 11.5 (DEVELOPMENT.md) ────────────────────────────────────
RUN add-apt-repository ppa:bartbes/love-stable \
    && apt-get update \
    && apt-get install -y love \
    && rm -rf /var/lib/apt/lists/*

# ── just (task runner; CI: extractions/setup-just) ───────────────────
RUN curl --proto '=https' --tlsv1.2 -sSf \
        https://just.systems/install.sh \
    | bash -s -- --to /usr/local/bin

# ── Node.js 20 LTS (CI: node-version "lts/Iron") ────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

USER claude
VOLUME /home/claude/.local
RUN mkdir /home/claude/.local/bin
ENV PATH=/home/claude/.local/bin:/home/claude/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ── Claude Code (on-board implementation agent) ──────────────────────
RUN npm install -g @anthropic-ai/claude-code

RUN curl -fsSL https://antigravity.google/cli/install.sh | bash - 

WORKDIR /repo
VOLUME /repo
VOLUME /repo/.cursor

ADD mcp.json /home/claude/.cursor/mcp.json
ADD mcp.json /usr/share/claude/.mcp.json
ADD file_mcp_rule.md /usr/share/claude/rules/
add CLAUDE.md /usr/share/claude/CLAUDE.md

ENV CLAUDE_CONFIG_DIR=/usr/share/claude
ENV AGY_MCP_CONFIG=/usr/share/claude/.mcp.json
