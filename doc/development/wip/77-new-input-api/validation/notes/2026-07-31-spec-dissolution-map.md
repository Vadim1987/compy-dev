# Restoration map — the two construction-named input specs (2026-07-31)

Owner instruction (session24, mid-TF2): re-prose and rename the lifecycle
spec so a cold reviewer can read it; **dissolve** the redesign-AC spec —
redistribute what only it covered, delete the duplicates. Evidence behind
the calls: [`2026-07-31-construction-named-specs.md`](2026-07-31-construction-named-specs.md).

Kept here so the move is reversible and auditable until the PR is up.

## Commits

| Commit | Concern |
| --- | --- |
| `eb43d34` | dissolve `input_redesign_ac_spec.lua` into subject homes |
| `0586a57` | wrap the rehomed rows to the 64-char limit |
| `88fa83f` | rename + re-prose `input_lifecycle_unfork_spec.lua` |

Suite **867 → 861 / 0 / 0 / 3**, green at every commit. No production code
touched; no assertion changed meaning.

## `input_redesign_ac_spec.lua` (deleted) — row-by-row disposition

| Was | Now |
| --- | --- |
| AC1 Escape clears, stays shown | dropped — `input_widgets_callbacks_spec.lua`, "Escape runs the cancel chain, clears, and stays shown" |
| AC2 `before_cancel` veto | **moved** → `input_widgets_callbacks_spec.lua`, "a truthy before_cancel vetoes the whole cancel" |
| AC3 submit stays open, no auto-clear | dropped — same file, "continuity across submit" group |
| AC4 `after_submit = hide` | **moved** → same file, "after_submit may hide, reproducing prompt-once" |
| AC5 shortcut on return shadows submit | dropped — same file, "a shortcut on return shadows the widget submit" |
| AC6 consumption follows shownness | **moved** → `input_events_spec.lua`, "the route consumes exactly while the widget is shown" |
| AC7 console Up → history recall | **moved** → `history_spec.lua`, new "console history navigation" group |
| AC8 handler fires via seeded hook | dropped — subsumed by the row below and by "a project handler fires whether or not the widget is shown" |
| AC8 nil does not resurrect handler | **moved** → `input_events_spec.lua`, "clearing a seeded hook does not resurrect the handler" |
| AC9 sub-table identity frozen | **merged** into `input_events_spec.lua`, "replacing the surface or a sub-table raises" (previously froze only `shortcuts`) |
| AC9 leaf writes succeed | **merged** into the same file's "leaf writes inside the sub-tables are accepted" (previously hooks only) |
| AC10 teardown re-seeds defaults | **moved** → `input_route_lifecycle_spec.lua`, "re-seeds the default callbacks for the next project" |

Arithmetic: 12 removed − 6 moved − 2 merged = 4 net-dropped duplicates,
suite 867 → 861.

The `#r4` tag is gone with the file; it was referenced nowhere else.

## `input_lifecycle_unfork_spec.lua` → `input_lifecycle_uniform_spec.lua`

Same 14 rows, same assertions. Renamed, tag `#lifecycle_unfork` →
`#lifecycle`, and the prose rewritten around the behaviour ("Enter and
Escape mean the same thing in every input surface") instead of the
refactor that produced it. Group/row names dropped `UIC`,
`_handle_submit`, "RED today", "un-forking", "light re-assert".

Citations updated to the new name: `doc/development/internals/user_input.md`,
`doc/development/technical_debt/input.md`. The debt ledger's overlay-shape
entry, which cited the deleted file, now cites
`input_widgets_callbacks_spec.lua`.

## Discovered, NOT fixed (reported per agents/development.md)

- `doc/development/tests.md:70` states the suite is **862**; the tree was
  867 before this session and is 861 now. The line was already stale.
- `doc/development/tests.md:53` names the nine split files, two of them by
  names that no longer exist: `input_dispatch_chain_spec` (now
  `input_events_spec`) and `input_widget_io_spec` (now
  `input_widgets_callbacks_spec`). Same two stale names appear in the file
  headers of `input_events_spec.lua` and `input_widgets_callbacks_spec.lua`,
  which point at each other by the retired names. Pre-existing drift; it is
  the same class of finding as session23's F1.
- **Erratum in `eb43d34`'s commit message:** its dropped-rows paragraph
  lists the hidden-widget consumption row as dropped. It was *moved*, as
  the table above records. Not amended — history is not rewritten in this
  tree; this note is the correction of record.
