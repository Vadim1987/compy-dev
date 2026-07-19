# Sub-agent A2 — test-fidelity audit + fixes (Sonnet, worktree isolation)

_Prompt of record (hygiene c). Spawned by session11/Opus. Model: sonnet._

You are a Sonnet worker in the **compy** LÖVE2D project (repo root `/repo`, your cwd is an
isolated git worktree branched from HEAD). Feature #77 = new input API, now in pre-PR
validation. You do NOT inherit the project's CLAUDE.md — everything you need is below.

## Task: A2 test-fidelity audit + fixes (the S7 precondition)

Find tests under **`tests/`** (focus on the input feature: `tests/input/`, plus any editor /
routing / callback tests that exercise the input API) that are **unfaithful**:

- **Reimplementation smell**: the test steps through / re-derives framework behaviour inline
  (rebuilds what a real method does, hand-rolls dispatch, asserts against its own copy of the
  logic) instead of **calling the real method** and asserting on its observable result. Such a
  test passes even if the real code is broken — it tests the test.
- **Description mismatch**: the `describe`/`it` text claims to verify X but the body asserts Y
  (or asserts nothing meaningful).

Two outcomes per finding:
1. **Mechanical fix** (obvious, low-judgment: swap the inline reimplementation for a call to
   the real method; tighten an assertion to match the description) → fix it. The test must
   still pass for the *right* reason afterward.
2. **Judgment-required** (fixing it needs a design/intent call, or the "right" behaviour is
   itself in question) → do NOT fix. **List** it in your report for Phase C, with enough
   detail that an owner ruling can be written against it.

Do NOT weaken tests to make them pass, and do NOT delete coverage. `design/` is FROZEN.

## How to work — LSP is your correctness tool here

- **MCP LSP is available** (`lua-lsp` server: defs / refs / diagnostics / rename over a real
  AST of `/repo`). This task is exactly where it earns its keep: to know whether a test calls
  the *real* method, resolve the symbol with LSP `definition`/`hover` and confirm the call
  targets production code, not a local stub. Use `references` to see how the real method is
  used elsewhere as a model for the faithful call.
- Grep to find candidate tests; LSP to resolve the concrete symbols once you have them.
- After ANY `.lua` edit, **`sleep 1` before** LSP refs/diagnostics (the server re-indexes).
- Coding rules: `/repo/agents/rules.md` (line ≤64, fn body ≤14, params ≤4, nesting ≤4).

## Do NOT touch (owner scratch / known anomalies)
`src/STEPS.md`, `claude.sh`, `input-pr-slices.tar.gz`, `src/examples/*`, `src/vadexamples/`,
`tests/editor/editor_spec_fwd.lua`, `docker/compose.yml`, `implementation/ses/`, anything
under `design/`.

## Suite gate (hard)
Baseline is **815/0/0/4** (4 pending are intentional — do NOT "fix" them). After your fixes,
`busted tests` must end **green**. Any change to the counts must be **explained** in your
report (e.g. "added 1 assertion-bearing test, +1 success"), never waved through. If you can't
keep it green and explained, stop and report rather than forcing it.

## Deliverable (the durable artifact — your chat message is lost when context rolls)
Write a report to **`doc/development/wip/77-new-input-api/implementation/sessions/session11/test-fidelity.md`**:
- **Fixed (mechanical)** — table: file:line, what was wrong, what you changed, why it now
  tests the real thing.
- **Judgment-required (Phase C)** — table: file:line, the fidelity problem, why fixing needs
  an owner ruling, what the ruling would decide.
- **Summary** — final `busted` count line verbatim + any delta from 815/0/0/4 with its
  one-line explanation.
Leave your worktree with the edits in place (do not commit unless natural; the parent
reconciles). End your final message with the report path and the busted count.
