# P-21-01 + P-21-02 — execution (prompt of record)

Commissioned by session43, 2026-08-16. Worker: Sonnet, model passed explicitly.
**This step writes framework code.** Deliverable report:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-21-01-02-execution.md`.

## The ruling you are implementing

`doc/development/decisions/input.md`, **Decision 33 — a framework reservation
matches its modifier set exactly**. Read it. In one line: every combination the
framework reserves must match exactly — the modifiers it names are held and **no
other modifier is** — because a project's richer combo must not dissolve into a
framework one, and because framework shortcuts are non-overridable and so belong
on the narrowest possible condition.

The analysis of what this touches, **table included, already done for you**:
`../reviews/S43-P-21-00-blast-radius.md`. Nine reservations, their current
conditions with line numbers, their exact forms, and the extensions each stops
claiming. Work from that table. If the code disagrees with it, **the code wins
and you report the disagreement**.

## Two commits, in this order

### P-21-01 — the predicate, and the release gate (row 9)

Add a local predicate to `src/controller/controller.lua` that answers *exactly
these modifiers are held*. Name it for what it asserts (something like
`only_mods(...)` / `mods_exactly(...)`) — not for what it excludes. It reads
the device through `Key.ctrl()` / `Key.alt()` / `Key.shift()` like everything
else in this file (Decision 30); it does **not** take a table.

Then apply it to **row 9 only**: `handlers.keyreleased`'s Ctrl+Escape
(`:884-885`). Ctrl+Escape still quits/returns to console; Ctrl+Shift+Escape,
Ctrl+Alt+Escape and Ctrl+Alt+Shift+Escape stop being the framework's.

### P-21-02 — the `keypressed` gate (rows 1–6 and 8)

Apply the same predicate to quickswitch, suspend, quit-project, stop/finish,
reset, restart and the F10 overlay. **Row 7 (the profiler) is already exact —
do not touch it.** Two traps in the table, read it before editing:

- **Row 4**: `ctrl+s`'s Shift is *meaningful* in the editor branch (finish edit
  vs close buffer). Exactness there means excluding **Alt**, not Shift.
- **Rows 5 and 6**: `reset` (ctrl+shift+r) and `restart` (ctrl+alt+r) currently
  **both fire** on Ctrl+Alt+Shift+R. That is a live defect, not just looseness,
  and exactness closes it. Say so in the commit message with its evidence.

## Test coverage — the point of the exercise

The owner's words: *"we'd need test coverage, a few cases not caught before."*
The gap these tests close is that **nothing anywhere asserted what a reservation
does not claim**.

For each reservation you tighten, add two live cases in
`tests/input/input_global_shortcuts_spec.lua`:

1. the exact combo still does its thing (guards against over-tightening), and
2. the extension **no longer** does it — and, where a project binding exists in
   the fixture, that the project's binding is what runs instead.

Plus one case for the Ctrl+Alt+Shift+R double-fire: before, both `restart` and
`reset` run; after, neither does.

**Do not touch the seven `pending(...)` outlines in that file, and do not
convert any of them to live cases.** They name each reserved combo's *own
effect*, which is the framework's contract and deliberately outside this PR
(owner ruling, P15). The pending count must stay **10** — the boot ritual treats
a change in it as a finding. What you are adding is the **boundary**, not the
effect.

Tests first: write them against the current tree, watch them fail, record the
failing output, then make them pass.

## Constraints

- `agents/rules.md` hard limits: function body ≤ 14 lines, line ≤ 64 chars,
  params ≤ 4, nesting ≤ 4. The gate functions are already near the nesting
  limit — if a change would breach it, stop and report rather than restructuring
  the surrounding code.
- Comments per `agents/rules/commenting.md`: only where they carry what the code
  cannot, citing canonical `doc/…` paths and **named sections**, never a
  `wip/…` path. The predicate deserves one line naming Decision 33.
- Full suite green at **each** commit: `busted tests` → expect **949 / 0 / 0 /
  10** plus your new cases. State the arithmetic in each message.
- Commit only `src/controller/controller.lua` and
  `tests/input/input_global_shortcuts_spec.lua`, explicitly by path. Never
  `git add .`, never `git add doc/`. **NEVER push.** Leave the owner's untracked
  scratch alone (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Trailer on each commit: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`

## How to work

- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`. Grep to find candidates, then the LSP to resolve a symbol
  or prove who calls it. After editing a `.lua`, `sleep 1` before querying it.
- **Stop and report, do not improvise**, if: a reservation's intent is unclear,
  the table disagrees with the code, or exactness would change something the
  table did not predict. A design question inside this step belongs to the
  owner, not to you.

## Deliverable

The report: what changed per row, the failing output before and passing after,
the suite arithmetic, both commit hashes, and anything the table did not
anticipate. Do not commit the report — the parent session commits it.
