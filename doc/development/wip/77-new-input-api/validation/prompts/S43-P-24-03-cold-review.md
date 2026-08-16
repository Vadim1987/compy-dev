# P-24-03 — cold review of the reservation table (prompt of record)

Commissioned by session43, 2026-08-16. Worker: Sonnet, model passed explicitly,
**read-only**. Deliverable: `../outcomes/S43-P-24-03-cold-review.md`.

This is the largest structural change of the session: the pre-dispatch gate's
predicate cascade became a table. It is claimed to be **representation only** —
no behaviour changed. Your job is to find any place that claim is false.

## What landed

- **`737d8316`** — `combo_string` rebuilt without a `parts` table (string
  accumulation).
- **`f31bd312`** — `only_mods` deleted; both gate handlers now look up one
  canonical combo string per event in `RESERVED.keypressed` /
  `RESERVED.keyreleased`, one named function per reservation.

Ruling: `doc/development/decisions/input.md`, **Decision 34**. Analysis:
`../reviews/S43-P-24-00-only-mods-api.md`, `../reviews/S43-P-24-00b-table-and-sharing.md`.
Worker's report: `../outcomes/S43-P-24-01-02-execution.md`.

## What to check

1. **Equivalence, reservation by reservation.** Diff `f31bd312^` against the
   current tree and walk all nine plus the release-side one. For each: same
   trigger, same modifiers, same state conditions, same action, same order of
   effects. Anything that changed is a finding.
2. **The playback narrowing — check this hardest.** The old code ran
   `restart()` and `profile()` in **both** the `playback` and dev branches, and
   `quickswitch()` / `project_state_change()` in the dev branch **only**. The
   rewrite moves that split into per-reservation `if playback then return end`
   guards. Verify the set of guarded reservations is exactly the set that was
   dev-only, and that the unguarded ones are exactly those that ran in both. The
   worker reports this was missed by both analysis documents and caught only by
   `input_shortcuts_click_spec.lua`'s play-mode case — so it is the place a
   second mistake is most likely to be hiding.
3. **The `f10` overlay cycle.** The old `if/elseif` chain had **no `else`**, so
   an unrecognised `fpsc` value was left alone. The rewrite uses a lookup table
   (`FPSC_CYCLE`). Confirm an unrecognised value is still left alone and not
   reset to a default.
4. **Never consumes.** Decision 34 requires that a reservation does not consume
   the key. Confirm every reservation function returns nothing that could be
   read as consumption, and that both handlers still forward to the route in all
   cases — including when a reservation fired.
5. **The playback `shutdown` guard.** It fires on *any* key, not one combo, so
   it stayed outside the table. Confirm it still runs before the lookup and its
   condition is unchanged.
6. **No test was edited.** `git show --stat` on both commits must show only
   `src/controller/controller.lua`. The suite must read **968 / 0 / 0 / 10** with
   the seven `pending(...)` outlines untouched. A rewrite that needed a test
   edited would not be representation-only.
7. **Decision 34's own requirements:** the table is visibly a second, privileged
   table, structurally separate from a project's `compy.input.shortcuts`, and the
   never-consumes contract is stated **at the table** in code.
8. **`combo_string` without the table.** Confirm the accumulator produces
   identical strings for zero, one, two and three held modifiers, and that
   nothing else consumed the old `parts` behaviour.
9. **Hygiene.** `agents/rules.md` limits on the changed file, comments per
   `agents/rules/commenting.md` (canonical `doc/…` paths, named sections, never
   `wip/…`), LSP diagnostics.

Also worth a look, unprompted by the commission: `RESERVED` is rebuilt on every
call to `setup_callback_handlers`, closing over that call's `CC`. Say whether
that is correct and whether it costs anything that matters.

## How to work

- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`. Grep to find candidates, LSP to resolve symbols and prove
  callers; cross-check with grep where completeness matters.
- **Read-only.** No edits, commits or pushes. Do not touch the owner's untracked
  scratch (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Verify in code, cite file:line or commit. Where a document and the code
  disagree, the code wins and the disagreement is a finding.
- Severity: S1 = behaviour changed, or a claim its evidence does not support;
  S2 = rule or contract violation; S3 = bookkeeping drift.

## Deliverable

Verdict first — **is this representation-only?** — then findings by severity with
evidence, then what you verified clean, then what you could not check. If it is
sound, say so plainly and stop.
