# S23 sub-agent prompt — J1 / persistent-corpus mechanical sweep (Sonnet, read-only)

**Materialized prompt of record** (validation.md hygiene c). Worker: Sonnet.
Scope: **verification only — make NO edits to any file except your one
outcome file.**

## Context you do not inherit

You are a sub-agent in the LÖVE2D project at `/repo` (cwd). You do **not**
inherit the repo's CLAUDE.md or the parent session's context, so:

- **MCP-LSP is available.** The `lua-lsp` MCP server gives defs / refs /
  diagnostics over a real AST of the `/repo` workspace. Use grep to find
  candidates, then the LSP to resolve a concrete symbol or prove "who calls
  this". (You are making no edits, so no re-index wait applies.)
- Do not run the test suite; the parent already has the baseline.

## Background

Session22 ran a "J1" cleanup: removing **construction-era marker
vocabulary** (in-code `REVIEW:` remarks, `{jargon:}` / `{badspecref:}`
tags, WIP/milestone citations such as references to `wip/77`, phase names
like "R-phase", "B-COV", "TF2", "S19", milestone/batch IDs, `RVW-0NN`
marker IDs) from the **shipping corpus** — tracked `src/`, `tests/`, and
the persistent docs — without changing behaviour. Commits: `c09f590`
(tests), `e28f58d` (source), `7b9920c`, `59de87b` (debt wording).

The **persistent docs corpus** (the only docs that survive deletion of
`doc/development/wip/77-new-input-api/`) is exactly:
`doc/input_api.md`, `doc/development/internals/user_input.md`,
`doc/development/decisions/input.md`,
`doc/development/technical_debt/input.md`,
`doc/development/technical_debt/general.md`,
`doc/development/tests.md`.

Everything under `doc/development/wip/` is working evidence and is **out of
scope** — it is allowed and expected to contain marker vocabulary.

## Your task

Verify, from the tree at HEAD, that the J1 cleanup is **complete and
uniform** and that the persistent corpus stands alone.

1. **Marker residue.** Sweep tracked `src/` and `tests/` (use
   `git ls-files` so untracked scratch such as `src/STEPS.md`,
   `src/examples/balloons|keyboard|maze` is excluded) for construction-era
   vocabulary: `REVIEW:`, `{jargon:`, `{badspecref:`, `RVW-`, `wip/77`,
   `77-new-input-api`, `TF2`, `TF3`, `B-COV`, `B-E`, `B-I`, `B-F`,
   `S19`/`S20`/`S21`/`S22`, "milestone", "phase R", "R-phase", "sweep",
   "mop-up". Report every hit with `file:line` and classify each as
   **residue** (construction-era, should have been cleaned) or **benign**
   (an ordinary English use of the word, e.g. "review the value"). Be
   honest about ambiguity rather than forcing a verdict.
   - Known and sanctioned exception: a **tracked binary swap artifact**
     was deliberately left untouched. Identify it by name if you hit it and
     mark it sanctioned rather than a finding.
2. **Same sweep over the six persistent doc files** listed above. Any
   reference from a persistent doc into `wip/77` or to a session/phase ID
   is a **finding** — those docs must resolve without the wip tree.
3. **Cross-reference integrity of the persistent corpus.** For each of the
   six files, extract every relative link / file path it cites and verify
   the target exists in the tree. Report broken or stale targets.
4. **Diff-level check of the J1 commits.** For `c09f590` and `e28f58d`,
   confirm from `git show --stat` and the diffs that they changed only
   comments/prose — no assertion, expression, or control-flow change. Any
   line that alters executable behaviour is a finding. Note that pure
   comment removal inside a function may change line counts; that is fine.

## Deliverable

Write your report to
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S23-marker-corpus-sweep.md`.

Structure: one section per numbered task, each opening with a one-line
verdict (CLEAN / FINDINGS: n), then a table of `file:line` → quoted text →
classification. Close with an overall verdict and an explicit list of
anything you could not verify. **Do not fix anything you find** — the
parent session rules on it. State plainly if a check came out clean; do
not manufacture findings to look thorough.
