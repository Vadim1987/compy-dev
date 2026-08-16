# P-20-01 — session38 outcome review (prompt of record)

Commissioned by session43, 2026-08-16. Worker: Sonnet, model passed explicitly,
**read-only**. Deliverable:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-20-01-session38-outcome-review.md`.

## Why this exists

Session42 landed a defect whose proof was a **test fixture that modelled a
mechanism the system does not have** — its `love.event.push` dispatched
handlers synchronously, while the real loop queues and drains a frame later. The
fixture passed; the harness it validated was broken
(`../notes/S43-harmony-p13-timing-finding.md`).

Session38 closes with a structurally similar claim: that the `keyboard` game's
gesture behaviour is **provably identical to upstream**, *"measured, not
argued"*, via a **parity harness the session built for the purpose**. The claim
is only as good as the harness. That is what you are here to test.

This is an **outcome review, not a full revalidation** — the session was
pedantic about reviewing its own steps (four independent cold passes) and its
work is confined to the nested `keyboard` repo. Escalate only if the harness
turns out unsound.

## Scope

Platform repo `/repo`: session38's commits, `dd7a7548~22..dd7a7548` — all
documentation and plan records; the session states **no platform code was
touched**, which is itself worth confirming.
Nested repo `/repo/src/examples/keyboard` (its own git repo): the landed work,
notably `e568961`, `80bca7b`, `7b0d542`, `d9ecdb0`, `f09f1e7`, `1033252`.

Its record: `../reviews/P-18-00-triage-and-plan.md` §§8–11, and the four reports
`../outcomes/S38-P18-final-revalidation{,-2,-3}.md`, `../outcomes/S38-P18-narrow-review.md`.
Session report: `../../implementation/sessions/session38/report.md`.

## What to check — in this order

1. **The parity harness.** Find it (it is referenced by the third cold pass).
   Then answer one question: **does it drive the game the way the game is
   actually driven at runtime?** Specifically — does it deliver events through
   the same path as the real love loop (queue → pump → handler), or does it call
   handlers directly? Does it read modifier state the way production reads it?
   If the harness short-circuits any mechanism the real path uses, the parity
   result it produced does not mean what the report says it means, and that is
   an S1 finding. **This is the whole point of the task — spend your budget
   here.**
2. **The last batch's review.** The step was reopened three times
   (`P-18-07…13`, `P-18-14…18`, `P-18-19…21`), each batch reportedly ending in
   an independent review. Verify that the **last** one actually did: is there a
   review artifact covering `P-18-19…21`, dated after them, or did the session
   close on its own assessment? An unreviewed final batch is the plausible weak
   point — say so plainly if you find it.
3. **The two regressions.** The menu-digit `textinput` fix and the six
   modifier-tolerant gestures. Confirm each fix is present in the code and that
   the sixth gesture (`Ctrl+Alt+Shift+H`) and fifth (`Alt+Shift+P`) are
   genuinely restored — not merely recorded as restored.
4. **The no-platform-code claim.** `git log dd7a7548~22..dd7a7548 --name-only`
   over `src/` and `tests/` should be empty. Confirm or refute.

## How to work

- **The `lua-lsp` MCP server is available** (defs / refs / diagnostics over a
  real AST of the `/repo` workspace). Grep to find candidates, then LSP to
  resolve a symbol or prove "who calls this". LSP refs can be incomplete in Lua —
  cross-check with grep when completeness matters. (`sleep 1` after any `.lua`
  edit before querying — you should not be editing.)
- **Read-only.** No modifications, commits or pushes in `/repo` or any nested
  repo. Do not touch the owner's untracked scratch (`claude.sh`, `worklog.md`,
  `src/STEPS.md`, `doc/tall_blocks.md`, `repos.txt`, `input-pr-slices.tar.gz`).
- **Verify in code, not in prose.** Every claim cites a file and line, or a
  commit. Where a document and the code disagree, the code wins.
- Severity: S1 = broken or player-visible regression, or a claim whose evidence
  does not support it; S2 = rule or contract violation; S3 = bookkeeping drift.

## Deliverable

Write the report to the path above. Verdict first — **is the parity claim
sound?** — then findings by severity with file:line evidence, then what you
verified clean, then what you could not check and why. If the harness is sound,
say so in one paragraph and stop; do not manufacture findings.
