# Sub-agent A1 — spec-reference sweep (Sonnet, worktree isolation)

_Prompt of record (hygiene c). Spawned by session11/Opus. Model: sonnet._

You are a Sonnet worker in the **compy** LÖVE2D project (repo root `/repo`, your cwd is an
isolated git worktree branched from HEAD). Feature #77 = new input API, now in pre-PR
validation. You do NOT inherit the project's CLAUDE.md — everything you need is below.

## Task: A1 spec-reference sweep

Comments in **code (`src/`) and tests (`tests/`)** that cite spec/design/docs must reference
the **persistent docs corpus** (below) with a **named section**, NOT `wip/` drafts, milestone
marks (e.g. `M3`, `sweep`), or `badrefspec`-flagged targets.

**Persistent docs corpus** (the ONLY legitimate reference targets):
- `doc/input_api.md`
- `doc/development/internals/user_input.md`
- `doc/development/decisions/input.md`
- `doc/development/technical_debt/input.md`
- `doc/development/technical_debt/general.md`
- `doc/development/tests.md`

Two outcomes per reference found:
1. **A persistent home exists** → fix the reference mechanically (point it at the corpus doc +
   named section). Prefer citing an actual heading that exists in the target — open the target
   and confirm the section is real before writing it.
2. **No persistent home exists** (it references content that only lives in `wip/` or nowhere)
   → **do NOT invent a target and do NOT delete the comment.** INVENTORY it in your report
   (file:line, current text, why it has no home). These become Phase C evidence.

Scope discipline: only touch *reference strings inside comments*. Do not refactor code, rename
symbols, or edit test logic. `design/` files are FROZEN (read, never edit).

## How to work

- Grep is the right opening move to find candidates: search `src/` and `tests/` for `wip/`,
  `design/`, `77-new-input-api`, milestone tokens, `badrefspec`, `TODO`/`spec`/`see doc`
  patterns, and doc-path fragments. Cast a wide net, then judge each hit.
- **MCP LSP is available** (`lua-lsp` server: defs/refs/diagnostics over a real AST of `/repo`).
  You likely won't need it for a comment sweep, but it's there if a reference's meaning depends
  on what a symbol actually does. After any `.lua` edit, `sleep 1` before LSP refs/diagnostics
  (the server re-indexes).
- Coding rules if you touch a line: `/repo/agents/rules.md` (line ≤64 chars — if fixing a
  comment would push a line over 64, wrap it, don't leave it long).

## Do NOT touch (owner scratch / known anomalies)
`src/STEPS.md`, `claude.sh`, `input-pr-slices.tar.gz`, `src/examples/*`, `src/vadexamples/`,
`tests/editor/editor_spec_fwd.lua`, `docker/compose.yml`, `implementation/ses/`, anything
under `design/`.

## Sanity check
After edits, run `busted tests` — must stay **815/0/0/4**. Comment-only edits cannot change
that; if the count moves, you edited something you shouldn't have — revert and note it.

## Deliverable (the durable artifact — your chat message is lost when context rolls)
Write a report to **`doc/development/wip/77-new-input-api/implementation/sessions/session11/spec-ref-sweep.md`**:
- **Fixed** — table: file:line, old ref → new ref (corpus doc + section).
- **Inventory (no persistent home)** — table: file:line, current text, why no home / what it
  needs. This is the Phase C hand-off; be precise.
- **Summary** — counts, and the exact `busted` line you observed at the end.
Leave your worktree with the edits in place (do not commit unless you find it natural to; the
parent reconciles). End your final message with the report path and the busted count.
