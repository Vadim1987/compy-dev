# P-24-01 + P-24-02 — the allocation, and the reservation table (prompt of record)

Commissioned by session43, 2026-08-16, on the owner's ruling recorded as
**Decision 34** (`doc/development/decisions/input.md` — read it first; it states
what is being built and, more importantly, what must not change). Worker:
Sonnet, model passed explicitly. Deliverable:
`../outcomes/S43-P-24-01-02-execution.md`.

Background analysis, already done — work from it, and report any disagreement
with the code rather than working around it:
`../reviews/S43-P-24-00-only-mods-api.md` and
`../reviews/S43-P-24-00b-table-and-sharing.md`.

## Two commits, in this order

### P-24-01 — `combo_string` stops allocating

`src/controller/controller.lua:409-419` builds `local parts = { }` per call.
Rebuild it **without a table** — concatenate over the three modifier tests
directly. Not a reused module-level buffer: that trades the allocation for
shared mutable state in a function that must then never be called re-entrantly.

While you are in there: `find_shortcut`
(`src/controller/projectInputController.lua:104-114`) calls `combo_string`
**twice** on a miss — once for the exact combo, once for the `'*'` class — so it
asks the device twice for one event. If you can make the second lookup reuse the
first read **without** adding shared state or a parameter to `combo_string`'s
public shape, do it; if it needs either, leave it and say why in the report.

The `--- NOTE:` comment above `combo_string` about the allocation being an open
question, and the debt entry it cites ("Combo-string dispatch allocates a table
per call"), both become false — update the comment; **leave the debt entry to
the parent session.**

### P-24-02 — the reservation table

Replace the gate's predicate cascade with the table Decision 34 specifies:
per-event tables keyed by canonical combo string, one entry per reservation, in
`src/controller/controller.lua`. `only_mods` is then dead and goes.

Requirements that are not negotiable, all from Decision 34:

- **It must be visibly a second, privileged table** — structurally separate from
  a project's `compy.input.shortcuts`, named so nobody confuses them.
- **State a reservation never consumes**, in a comment at the table. A project's
  shortcut consumes by returning truthy; a reservation does not, and the key
  continues to the route afterwards. Same shape, opposite contract — this is the
  most misleading thing in the design and the comment is part of the deliverable.
- **State conditions move inside each reservation's function** (`app_state ==
  'running'` for stop-run, `love.PROFILE` for the overlay, the editor/running
  branches for the others) rather than remaining as surrounding nesting.
- Both handlers: `keypressed` and `keyreleased` (Ctrl+Escape lives on the
  release side).
- Nothing about *which* combos are reserved, what each does, or when each
  applies may change. This is representation, not behaviour.

## The proof rule

The live cases from the Decision 33 sweep — fifteen-plus in
`tests/input/input_global_shortcuts_spec.lua`, plus the editor pair — are the
proof of equivalence. **No existing test may need editing.** If one does, stop
and report: it means the rewrite is not equivalent, and that is a finding rather
than something to fix by changing the test.

Suite is **968 / 0 / 0 / 10** before you start and must read exactly that after
each commit. The seven `pending(...)` outlines stay untouched.

## Constraints

- `agents/rules.md` hard limits (body ≤ 14 lines, line ≤ 64 chars, params ≤ 4,
  nesting ≤ 4). The table's per-reservation functions should come in well under
  the limit — if one does not, that is a signal the reservation is doing too
  much, so report it rather than restructuring anything around it.
- Comments per `agents/rules/commenting.md`: canonical `doc/…` paths and **named
  sections**, never `wip/…`.
- Commit only `src/controller/controller.lua` and, if the `find_shortcut` change
  happens, `src/controller/projectInputController.lua` — explicitly by path.
  Never `git add .`, never `git add doc/`. **NEVER push.** Leave the owner's
  untracked scratch alone (`claude.sh`, `worklog.md`, `src/STEPS.md`,
  `doc/tall_blocks.md`, `repos.txt`, `input-pr-slices.tar.gz`).
- Trailer on each commit: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- **The `lua-lsp` MCP server is available**; `sleep 1` after a `.lua` edit before
  querying refs/diagnostics, and check diagnostics before each commit.

## Deliverable

Per commit: what changed, the suite line, the hash. Plus: how many device reads a
keypress now costs at the gate and in the route (count them in the code, do not
estimate), whether `find_shortcut`'s double build was fixable within the rules,
and anything the analysis did not anticipate.
