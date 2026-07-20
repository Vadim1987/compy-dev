# R4/U2 — compy.input surface rename sweep in TEST files — outcome

**Result: `busted tests` → 819 successes / 0 failures / 0 errors / 4 pending** (target met exactly).

## Files touched (renamed)

- `tests/input/input_events_spec.lua` — 26 renames.
  - `input.on_key_pressed` → `input.hooks.keypressed` (9)
  - `input.on_key_released` → `input.hooks.keyreleased` (1)
  - `input.on_text_input` → `input.hooks.textinput` (3)
  - `input.handlers.*` → `input.shortcuts.*` (7, incl. `handlers.keypressed/textinput/keyreleased['combo']`)
  - `input.handlers = {}` (frozen-write probe) → `input.shortcuts = {}` (1)
  - final `has_no.errors` block reassigning all three hooks (3)
- `tests/input/input_widgets_callbacks_spec.lua` — 25 renames.
  - `input.on_text_entered` → `input.callbacks.on_text_entered` (5)
  - `input.on_limit_reached` → `input.callbacks.on_limit_reached` (1)
  - `input.validator` → `input.callbacks.validator` (4)
  - `input.highlighter` → `input.callbacks.highlighter` (2)
  - `input.before_submit` / `input.after_submit` → `input.callbacks.before_submit` / `.after_submit` (7)
  - `input.before_cancel` / `input.after_cancel` → `input.callbacks.before_cancel` / `.after_cancel` (4)
  - `input.handlers.keypressed[...]` → `input.shortcuts.keypressed[...]` (2)
- `tests/input/input_reconfigure_spec.lua` — 5 renames.
  - `input.on_text_entered` (read) → `input.callbacks.on_text_entered` (1)
  - `input.validator` (read) → `input.callbacks.validator` (1)
  - `input.after_submit = function() input.show({}) end` → `input.callbacks.after_submit = ...` (3, the continuous-session idiom rows)
- `tests/input/input_route_lifecycle_spec.lua` — 11 renames.
  - `input.on_text_input` → `input.hooks.textinput` (1)
  - `input.handlers.keypressed['a']` → `input.shortcuts.keypressed['a']` (1, write + read-back assertion = 2 occurrences)
  - `input.on_key_pressed` → `input.hooks.keypressed` (2)
  - `input.before_submit` / `input.validator` → `input.callbacks.before_submit` / `.callbacks.validator` (4)
  - `input.before_cancel` / `input.after_cancel` → `input.callbacks.before_cancel` / `.callbacks.after_cancel` (2)

Every rename above is a bare `input.<field>` access where `input` is the value
returned by `F.activate_project(...)` or `F.compy_input()` — a genuine
compy.input-surface access per the frozen-guard's rejection message
(`compy.input: '<k>' is not assignable`) that busted reported before this
sweep.

## Left as false friends (unchanged, verified by inspection)

- `input_route_lifecycle_spec.lua` lines 129–133: `F.show_widget({ validator
  = ..., on_text_entered = ..., highlighter = ... })` — config-table keys
  inside `F.show_widget{...}`, stays flat per the rules.
- `input_route_lifecycle_spec.lua` lines 135–138: `F.singleton.validator`,
  `F.singleton.on_text_entered`, `F.singleton.on_limit_reached`,
  `F.singleton.model.evaluator.highlighter` — UserInputController INSTANCE
  fields, not the surface. Left flat.
- `input_widgets_callbacks_spec.lua` / `input_reconfigure_spec.lua`: every
  `on_text_entered` / `on_limit_reached` / `validator` / `highlighter` key
  that appears as a literal key inside a `{ ... }` table literal passed to
  `input.show({...})` or `input.configure({...})` — left flat (dozens of
  occurrences; not individually counted since they were never touched by
  the sweep — the regex used only matched the `input.<field>` dotted form,
  which config-table keys never take).
- `keys_pressed_spec.lua`, `input_shortcuts_click_spec.lua`,
  `input_widget_lifecycle_spec.lua`, `input_nfr_forward_spec.lua`,
  `input_routing_spec.lua`: every `.handlers` occurrence in these five files
  is `love.handlers` or `F.session.handlers` (the LÖVE gateway table) —
  confirmed via targeted grep for the full mapping-table pattern set; none
  had a genuine surface access. No edits made to any of the five.
- `tests/helpers/input_fixture.lua`, `tests/helpers/input_session.lua`,
  `tests/mock.lua`, `tests/interpreter/*`, `tests/input/input_redesign_ac_spec.lua`,
  any `src/` file, any `src/examples/*`: not touched, per the hard rules.

## Ambiguous calls

None. Every occurrence resolved unambiguously by its base identifier: a
local named `input` bound from `F.activate_project()`/`F.compy_input()` →
surface access, renamed; `F.singleton.*` / config-table literal keys →
false friend, left alone. No case required judgment calls beyond that rule.

## Method

Comment lines (`--` prose, including old-vocabulary example snippets like
`` `input.on_key_pressed = ` `` inside REVIEW comments) were deliberately
excluded from the rename regex so documentation prose was not touched —
only executable code lines were rewritten. Verified per-file via `git diff`
that no `show{...}`/`configure{...}`/`F.show_widget{...}` config keys and
no `F.singleton.*` lines were altered.

## Final tally

```
819 successes / 0 failures / 0 errors / 4 pending
```

No residual failures or errors after the sweep — nothing to escalate.
