# Owner question (2026-07-31, during TF2) — the two construction-named input specs

**Asked:** what do `tests/input/input_lifecycle_unfork_spec.lua` and
`tests/input/input_redesign_ac_spec.lua` test; are they necessary for the
released feature or mid-implementation leftovers; if necessary, is a
rename + prose refresh feasible? (Answer only — no edits made.)

## Verdict

Neither is a leftover. Both assert **shipped, project-facing behaviour** and
both hold rows that are the suite's **sole witness** for a contract. What is
construction-era about them is their **framing** — file name, tag, and section
headings are organized by *the change that produced them* (Phase R's AC list;
the removal of the `app_state` fork), not by subject like the rest of
`tests/input/`. The redundant fraction is rows, not files.

## `input_redesign_ac_spec.lua` — 12 tests, tag `#r4`

The ten Phase-R acceptance criteria pinned as tests ("these tests ARE the ACs").

Sole witness (deleting the file loses the contract entirely):

| Row | What only this file covers |
| --- | --- |
| AC2 | `before_cancel` returning truthy **vetoes** — the only place the veto return value is exercised (`widgets_callbacks` uses `before_cancel` for call-order only; `route_lifecycle` for teardown counting). |
| AC7 | console Up at the vertical limit → `on_limit_reached('up')` → `history_back` — the **only end-to-end console history-navigation test in the tree** (`history_spec` tests the History model in isolation). |
| AC8 | `hooks[event] = nil` clears with **no resurrection** of the captured handler. `input_events_spec` pins explicit-hook *precedence*, never the clear. |
| AC9 | identity-freeze of `hooks` and `callbacks`. `input_events_spec:551` freezes only `shortcuts`. |
| AC10 | teardown re-seeds `DEFAULT_CALLBACKS` at the **project-facing** surface (no cross-project leak). `route_lifecycle` covers the widget-side field reset only. |

Redundant with the thematic files: AC1 (= `widgets_callbacks` "Escape runs the
cancel chain, clears, and stays shown"), AC3/AC4 (≈ "continuity across submit"),
AC5 (= "a shortcut on return shadows the widget submit"), AC6 (≈
`widget_lifecycle` "a hidden widget does not consume").

## `input_lifecycle_unfork_spec.lua` — 14 tests, tag `#lifecycle_unfork`

Regression net for the Phase-R **option E** resolution: deleting the
`love.state.app_state == 'editor'` branch from `UserInputController:keypressed`
so one uniform lifecycle runs, with the editor consuming Enter/Escape upstream.

Sole witness:

- `allow_modify` / Ctrl+D duplicate-line — the **only** exercise of that
  constructor flag anywhere in `tests/` (`src/controller/userInputController.lua:684`).
- editor Escape loads the selection **without** running `model:cancel`.
- editor plain/Ctrl Enter submit locally and do **not** double-fire
  `on_text_entered` through the widget.
- editor Shift+Enter inserts a line-feed; Alt+Enter reaches a callback-less
  `submit_flow` harmlessly.
- non-shift Enter **breadth** (Ctrl/Alt submit too — guard is `is_enter and not
  shift`) for overlay and console.

Redundant: §6 "console + a light overlay re-assert" — self-declared, owned by
`input_widgets_callbacks_spec`.

## Rename / prose refresh — feasible, cheap, low-risk

- **No runner depends on the names or tags.** `.busted` selects by
  `pattern = "_spec.lua$"` and excludes only `delay`; `justfile` passes an
  arbitrary `--tags`. `#r4` and `#lifecycle_unfork` appear **nowhere** outside
  the two files.
- **References to update: three lines in the persistent corpus**, plus the two
  files' own headers/describes:
  `doc/development/technical_debt/input.md:245`, `:540`;
  `doc/development/internals/user_input.md:331`;
  `input_lifecycle_unfork_spec.lua:9` (cross-reference to its sibling).
  The `pr-slices/` copies carry the old names but Phase G regenerates them.
- Suite behaviour is unaffected: file names and tags are not load-bearing.

Naming candidates (subject-shaped, matching the rest of the directory):

- `input_lifecycle_unfork_spec.lua` → e.g. `input_lifecycle_uniform_spec.lua`
  ("one lifecycle across console / editor / overlay + the per-instance modify
  flag"). Its prose needs a pass regardless — "RED today", "un-forking",
  "app_state-fork removal" describe a refactor event, not a behaviour.
- `input_redesign_ac_spec.lua` → two shapes:
  1. **keep as one file**, renamed for what it is to a cold reader (e.g.
     `input_api_contract_spec.lua`), AC numbers demoted from headings to
     decision citations;
  2. **dissolve it** — fold the five sole-witness rows into their subject homes
     (AC2/AC10 → `input_widgets_callbacks_spec`, AC8/AC9 → `input_events_spec`,
     AC7 → a console-history home) and drop the seven duplicates.
     Honest end-state for a PR reviewed without `wip/` access; cost is losing
     the "these tests ARE the ACs" traceability the closed Phase-R gate rests
     on — documentary value now, since the gate is accepted.

Effort: (1) is one mechanical Sonnet unit; (2) is test surgery plus a judgment
call and belongs with the postponed jargon/vocabulary cluster (plan Phase C/D),
not an ad-hoc fix.
