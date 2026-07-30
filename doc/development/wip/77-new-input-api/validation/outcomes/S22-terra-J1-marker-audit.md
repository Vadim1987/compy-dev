# S22 Terra outcome — J1 persistent-marker audit

## Scope and evidence

Audited tracked persistent `src/`, `tests/`, and `doc/` only; the feature WIP
archive and untracked example scratch were excluded. The scan found 55 tagged
construction references: 14 `{jargon:...}` and 41 `{badspecref:...}`. Twelve
are in production source and 42 in tests (one overlapping count is caused by
the tracked binary swap file). No tagged construction reference is in the
permanent documentation corpus.

The tracked `tests/input/.input_nfr_forward_spec.lua.swp` is a binary recovery
artifact that matches the scan. It should not be silently deleted as part of
this wording sweep; decide its ownership/removal separately.

## Minimal cleanup plan

| Priority | Files | Work | Disposition |
| --- | --- | --- | --- |
| 1 | `tests/input/input_routing_spec.lua`, `input_widget_lifecycle_spec.lua`, `input_nfr_forward_spec.lua` | Remove the copied suite-level review instructions and historical milestone tags. Retain the asserted behaviour and cite the existing named permanent decision/section where a citation helps. The hidden-console concern is now resolved by Decision 11 and must be stated as current behaviour, not retained as a review question. | Mechanical now |
| 2 | `tests/input/input_reconfigure_spec.lua`, `keys_pressed_spec.lua`, `input_route_lifecycle_spec.lua`, `input_shortcuts_click_spec.lua`, `input_widgets_callbacks_spec.lua`, `input_events_spec.lua` | Replace milestone/review-file citations with the current contract wording and existing named permanent docs (`decisions/input.md`, `internals/user_input.md`, `tests.md`), or remove provenance that does not explain the assertion. Replace the few coined dispatch words with the documented route/widget terminology. | Mechanical now |
| 3 | `src/main.lua`, `src/controller/consoleController.lua`, `src/controller/userInputController.lua`, `src/util/key.lua`, `src/view/input/userInputView.lua` | Remove obsolete milestone and implementation-review backreferences. Keep only a permanent decision/technical-debt citation when it explains an intentional non-obvious shape. | Mechanical after confirming the referenced decision text |
| 4 | `tests/input/highlight_regression_spec.lua` | RVW-023's explanation is useful, but its `REVIEW/clarity` marker is stale after the evaluator/validator contract ruling. Rewrite the explanation in plain terms; do not retain the marker. | Mechanical now |

## REVIEW notes that need a durable disposition

The following are not merely vocabulary. Do not leave them as inline review
markers: either resolve them from current code/docs or move their still-open
question to `technical_debt/input.md` with a concise revisit trigger.

- `src/controller/controller.lua`: forwarding helper shape, ambiguous local
  names, and alternative combo dispatch. The technical-debt register already
  covers combo allocation and some combo migration, but not every naming and
  forwarding question; verify each before removing its marker.
- `src/util/key.lua`: alternative matcher and `mod_triples` naming. The
  current exact lookup is a documented Decision 8 choice; alternative matching
  is future design, so a single debt entry is sufficient if still desired.
- `src/view/input/userInputView.lua`: identity-based redraw avoidance already
  has a permanent debt entry at `technical_debt/input.md`, “View redraw
  suppression is keyed to widget identity”. Delete the inline review marker
  after preserving that named reference.
- `src/model/input/userInputModel.lua`, `src/controller/projectInputController.lua`,
  and `src/controller/userInputController.lua`: history/reset, parameter-name,
  and helper-name concerns need a short current-code check. They are unrelated
  to the public marker cleanup; move only genuine remaining work to debt.
- `src/controller/consoleController.lua`: `compy.before_exit` provenance is a
  design-intent question. Check its permanent sandbox/decision documentation
  before deciding whether it is resolved or deserves debt.
- `tests/helpers/input_fixture.lua`, `input_events_spec.lua`, and
  `input_shortcuts_click_spec.lua`: these are test-fidelity questions. The D4
  fixture correction and Decision 17 settle the default in favour of real
  paths. Delete remarks contradicted by that work; retain a debt item only for
  a specific remaining unavoidable fixture boundary.

## Boundaries

This audit recommends no production refactor and no test-behaviour change. It
is a wording/provenance pass, except where an inline question is found to name
a real future concern; that concern receives a permanent debt record instead
of an unowned `REVIEW` marker.
