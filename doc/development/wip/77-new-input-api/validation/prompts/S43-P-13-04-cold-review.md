# P-13-04 — cold review of the P-13 execution (prompt of record)

Commissioned by session43, 2026-08-16, per the owner's standing directive that
every execution step gets a cold review. Worker: Sonnet, model passed
explicitly, **read-only**. Deliverable:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-13-04-cold-review.md`.

You did not do this work and should not assume the session that did got it
right. The session that produced the *finding* also wrote the commission, so a
shared blind spot is the specific risk you exist to catch.

## What landed

One commit: **`3befd556`** *"fix(harmony): revert P13's release-discipline
retirement"* — `src/harmony/` reverted to `5b580661^`, and
`tests/harmony_input_spec.lua` rewritten.

Its record: the finding `../notes/S43-harmony-p13-timing-finding.md`, the
commission `S43-P-13-01-02-execution.md`, the worker's report
`../outcomes/S43-P-13-01-02-execution.md`, and rows P-13-00…04 in
`../reviews/S27-triage-and-plan.md`.

## What to check

1. **Is the restored contract actually the pre-P13 one?** `git diff 5b580661^ --
   src/harmony/` should be empty — confirm, and confirm that is the right
   baseline (that nothing between `5b580661^` and today touched `src/harmony`
   for an unrelated reason that has now been thrown away).
2. **Does the new fixture model the real loop?** The load-bearing claim is that
   `love.event.push` **queues** and a separate drain calls the handlers, because
   the old fixture dispatched at push time and that is what let the defect pass.
   Read `tests/harmony_input_spec.lua` and decide whether the fixture matches
   what `src/harmony/init.lua`'s `main_loop` and `love_key` actually do —
   including *when* the scenario step runs relative to the poll
   (`src/controller/controller.lua`, the harmony timer update).
3. **Do the three cases pin the contract, or only restate the implementation?**
   A test that would still pass if the defect returned is worthless here. For
   each case, ask: what change would break it?
4. **Is anything of P13 left?** Grep the tree for leftovers — modifier event
   emission, `press_modifier`/`release_modifier`, scenario files still missing
   their `release_keys()` calls, stale references in docs or plan rows that now
   describe a tree that no longer exists.
5. **Arithmetic and hygiene.** Suite is 949/0/0/10, up from 947 because the spec
   grew 1 case to 3 — verify that reconciles. Check the hard limits in
   `agents/rules.md` on the changed test file (function body ≤ 14 lines, line ≤
   64 chars, params ≤ 4, nesting ≤ 4) and the comment rules in
   `agents/rules/commenting.md`. Note that two over-length lines in
   `src/harmony/init.lua` are **inherited from the reverted baseline**, not new.
6. **The one thing the commission did not anticipate**, reported by the worker:
   harmony's `patch_isDown` has no explicit return on its default path, so
   `Key.ctrl()` returns *zero values* rather than `nil` under a locked harmony
   run. Confirm that is pre-existing at `5b580661^`, and say whether it has any
   consequence beyond test ergonomics.

## How to work

- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`. Grep to find candidates, then the LSP to resolve a symbol
  or prove who calls it; cross-check with grep where completeness matters.
- **Read-only.** No edits, no commits, no pushes. Do not touch the owner's
  untracked scratch (`claude.sh`, `worklog.md`, `src/STEPS.md`,
  `doc/tall_blocks.md`, `repos.txt`, `input-pr-slices.tar.gz`).
- Verify in code, not in prose. Where a document and the code disagree, the code
  wins and the disagreement is a finding.
- Severity: S1 = broken behaviour or a claim its evidence does not support;
  S2 = rule or contract violation; S3 = bookkeeping drift.

## Deliverable

Verdict first — **is the revert complete and does the spec defend it?** — then
findings by severity with file:line evidence, then what you verified clean, then
what you could not check. If it is sound, say so plainly and stop; do not
manufacture findings.
