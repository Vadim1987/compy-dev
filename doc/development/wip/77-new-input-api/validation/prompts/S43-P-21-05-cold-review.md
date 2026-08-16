# P-21-05 — cold review of the Decision 33 sweep (prompt of record)

Commissioned by session43, 2026-08-16, per the owner's standing directive that
every execution step gets a cold review. Worker: Sonnet, model passed
explicitly, **read-only**. Deliverable:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-21-05-cold-review.md`.

This one carries more risk than the last: it is a **framework behaviour change**,
user-visible, made inside a feature whose mandate is the project-facing input
API. The session that wrote the ruling's analysis also wrote the commission, so a
shared blind spot between them is what you exist to catch.

## What landed

Two commits: **`b20a4c35`** (the `only_mods` predicate + the release gate) and
**`77aed369`** (the `keypressed` gate). Both touch only
`src/controller/controller.lua` and `tests/input/input_global_shortcuts_spec.lua`.

The ruling: `doc/development/decisions/input.md`, **Decision 33**. The analysis
with the nine-row table: `../reviews/S43-P-21-00-blast-radius.md`. The
commission: `S43-P-21-01-02-execution.md`. The worker's report:
`../outcomes/S43-P-21-01-02-execution.md`.

## What to check

1. **Row by row against the table.** Nine reservations. For each: is the exact
   form what the table specifies, and does the code now say it? Two are traps —
   **row 4** (`ctrl+s`) must exclude **Alt only**, because Shift chooses finish
   edit vs close buffer; **row 7** (the profiler) was already exact and must be
   **untouched**. Confirm both, and confirm nothing outside the nine changed.
2. **`only_mods` itself.** Read it (`controller.lua:388-403`). Is the `not not`
   normalisation right, and is its stated reason true — that a patched `isDown`
   (Harmony's lock mode) returns *no value* rather than `false`? Check
   `src/harmony/init.lua`'s `patch_isDown`. Would `==` without it have been a
   real bug, or did the worker paper over something else? Is the predicate's
   own name honest about what it asserts?
3. **The tests, hardest first.** Fifteen new live cases. For each, ask **what
   change would make it fail** — a case that passes whether or not the gate is
   exact is worthless. Then ask what is **missing**: is there a tightened
   reservation with no negative case, or one whose positive case rests on a
   pre-existing P15 case that does not actually cover it?
4. **The pendings.** Seven `pending(...)` outlines in that file, ten suite-wide.
   They must be **untouched and unconverted** — they name each reserved combo's
   own effect, which is the framework's contract and outside this PR (P15). The
   suite must read **964 / 0 / 0 / 10**.
5. **What the change breaks that nobody looked for.** The table predicted the
   only affected registrations in the tree are maze's and draw's, in their
   favour. Verify by searching `src/examples/` and the nested repos for any
   binding that extends a reserved combo, and check the console/editor paths do
   not depend on the gate's old tolerance — `set_love_keypressed`'s debug
   hotkeys at `controller.lua:493,510` are deliberately **out of scope**, but
   confirm the sweep did not touch them by accident.
6. **Hard limits and comments.** `agents/rules.md` (body ≤ 14 lines, line ≤ 64,
   params ≤ 4, nesting ≤ 4) on both changed files, and
   `agents/rules/commenting.md` on the comments added — canonical `doc/…` paths
   with named sections, never `wip/…`.

## How to work

- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`. Grep to find candidates, then LSP to resolve a symbol or
  prove who calls it; cross-check with grep where completeness matters.
- **Read-only.** No edits, commits or pushes. Do not touch the owner's untracked
  scratch (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Verify in code, not in prose. Where a document and the code disagree, the code
  wins and the disagreement is a finding.
- Severity: S1 = broken behaviour, or a claim its evidence does not support;
  S2 = rule or contract violation; S3 = bookkeeping drift.

## Deliverable

Verdict first — **is the sweep complete, exact, and defended by its tests?** —
then findings by severity with file:line evidence, then what you verified clean,
then what you could not check. If it is sound, say so plainly and stop.
