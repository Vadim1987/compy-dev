# TF1 amendment — nested-describe subgrouping map

Owner (S15, 2026-07-19) hand-nested `input_cursor_text_spec.lua` into
method-named `describe` blocks (`get_cursor` / `set_cursor` / `set_text`,
with `with keep_cursor` nested inside `set_text`) purely for
comprehensibility — no provisioning logic. Directive: mirror that
organizing over the remaining split files. I map the `it`s; Sonnet carves.

## Idiom being mirrored (from the owner's cursor_text edit, verified in 265a5ba)
- Wrap **contiguous** runs of `it`s (in file order — **no reordering**) in a
  nested `describe` named after the concept they share.
- When the group name lifts a **redundant leading prefix** off the child
  `it` labels and the shortened label still reads as a sentence, strip it
  (e.g. `get_cursor reports …` → describe `get_cursor` + it `reports …`).
  Otherwise leave the label verbatim.
- **No `it` body changes. No new hooks** on nested describes (setup /
  teardown / before_each stay on the existing outer describe and inherit).
- Preserve every comment verbatim, especially owner `REVIEW`/`{jargon:}`
  markers and the `-- ----` section markers (the marker becomes the group;
  keep its text as a comment above/inside the new describe so nothing is
  lost).
- Contract unchanged: full suite **815/0/0/4**, each file standalone-green,
  per-file `it`+`pending` counts unchanged.

## Owner rulings (S15, 2026-07-19)
- Light-touch files (`widget_lifecycle`, `nfr_forward`): **leave flat** — not nested.
- Lone single-it groups (`highlighter`, `inspect`, `hide`, `immutability`,
  `cancel`): **keep as-is** — honest 1-test describes, no folding.
- Net scope: **4 files** nested (events, widgets_callbacks, reconfigure,
  route_lifecycle).

## Files NOT touched
- `input_routing_spec.lua` — already nested by mode (console/editor/search/
  project), ≤4 its each. Finer nesting would over-structure. Leave.
- `input_shortcuts_click_spec.lua` — already 4 sub-describes, ≤3 its each. Leave.
- `input_cursor_text_spec.lua` — the exemplar, done by owner.
- `input_widget_lifecycle_spec.lua` — owner ruling: leave flat.
- `input_nfr_forward_spec.lua` — owner ruling: leave flat.

## Files to nest

### input_events_spec.lua — inner describe `#input events dispatch chain` (26 its → 7 groups on existing `-- ----` seams)
1. `order, consume, fall-through` — `a framework handler consumes before lower tiers` … `assigning a callback replaces only it; sink still runs` (5)
2. `combo tables and normalisation` — `a keypressed combo fires …` … `the combo tables are per-event, not one flat table` (4)
3. `signatures and the read-only proxy` — `keypressed carries (k, keys_pressed, isrepeat)` … `a keyreleased participant sees the key already gone` (5)
4. `defaults and the hidden sink` — `the default callback neither edits nor consumes` … `no participant + hidden widget mutates nothing` (2)
5. `tier-3: the on_* generic callback` — `on_text_input fires per character …` … `a truthy on_text_input intercepts; falsey reaches sink` (2)
6. `tier-3: the native install path` — `a native fires whether or not the widget is shown` … `an explicit on_* takes precedence over the native` (5)
7. `the mutable/immutable boundary` — `assigning an unknown slot raises` … `assigning an allowed callback slot is accepted` (2)

### input_widgets_callbacks_spec.lua — inner `dispatch chain: widget outputs and submit/cancel #m5c #input` (27 its → 8 groups, two existing sections)
Section "widget outputs (Decision 5)":
1. `output field slots and sharing` — `the four widget output fields are assignable` … `field write shares validator slot` (6)
2. `highlighter` — `a custom highlighter transforms queried highlight` (1)
3. `navigation boundary outputs` — `up boundary fires direction up with input scope` … `right at last-line end reports input scope` (7)

Section "submit and cancel":
4. `submit` — `Enter runs the full submit call-order chain` … `a rejecting validator locks input without delivering` (4)
5. `cancel — the Escape chain` — `Escape runs the full cancel call-order chain` (1)
6. `Enter and Escape as ordinary keys` — `Enter and Escape are ordinary keys while hidden` … `Shift+Return is not intercepted; the sink edits` (3)
7. `suppressed cancel` — `hide() fires no cancel chain` … `a force=true reconfigure fires no cancel chain` (2)
8. `continuity across submit` — `after_submit can re-activate the widget mid-sequence` … `submit and cancel complete with no hooks set` (3)

### input_reconfigure_spec.lua — inner `live reconfigure and clear #m7` (12 its → 4 groups); leave `continuous-session idiom #m8` (3 its) flat
1. `configure on an active session` — `configure updates the prompt on an active session` … `configure leaves text/cursor untouched on an active session` (6)
2. `hidden configure` — `hidden configure applies text and cursor …` … `hidden-configured text does not leak into a later …` (3)
3. `clear` — `clear empties an active session with no callback` … `clear while hidden warns and no-ops` (2)
4. `immutability` — `assigning configure/clear raises` (1)

### input_route_lifecycle_spec.lua — inner `route connection lifecycle #m5c` (8 its → 4 groups)
1. `connection at the running boundary` — `the console regains text entry …` … `pointer stays hooked when a non-blocking run …` (2)
2. `stop teardown` — `stop clears every project-installed handler …` … `stop resets the widget's own output fields` (3)
3. `inspect` — `inspect disconnects the project route …` (1)
4. `compy.before_exit` — `compy.before_exit fires once on stop …` … `compy.before_exit resets to noop after stop` (2)

(`input_widget_lifecycle_spec.lua` and `input_nfr_forward_spec.lua` — owner
ruled leave flat; not nested.)
