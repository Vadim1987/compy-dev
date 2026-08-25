# S45 — overlay retirement in `src/` and `tests/`

Worker: Sonnet, prompt of record
`../prompts/S45-overlay-retirement-code.md`. No git operations performed;
the parent commits.

## 1. Numbers

- **Occurrences at start:** 56 (case-insensitive `overlay`, `src/` +
  `tests/`, excluding `src/examples/` and `src/lib/`). The prompt's
  estimate of "about 72" ran high; 56 is the exhaustive count via
  `grep -rniI --include='*.lua' 'overlay' src tests` minus the excluded
  trees. No plural/participle forms (`overlays`, `overlaid`) exist in
  scope, so word-occurrence count equals line count.
- **Changed:** 46, across 11 files.
- **Deliberately kept:** 10, across 3 files — all three of the prompt's
  named verified sites.
- **`input_widget_overlay` uses:** 0. Every site that needed the word
  admitted a plain "widget" or "input widget" without the compound; see
  §4.

Baseline and final suite line (identical):
`968 successes / 0 failures / 0 errors / 10 pending`.

## 2. The changed list (46), grouped by file

### `src/main.lua`
- `:376` — `the overlay draw path resolve the` → `the widget draw path resolve the`

### `src/controller/userInputController.lua`
- `:298` — `love.state.user_input is the overlay CONTRACT` → `... is the widget CONTRACT`

### `src/controller/controller.lua`
- `:630` — `The overlay is painted on top of the console frame` → `The widget is painted on top of the console frame`
- `:1020` — `has an active input overlay or a pointer/click handler` → `has an active input widget or a pointer/click handler`

### `src/controller/consoleController.lua`
- `:296` — `take down any overlay the project managed to show first` → `take down any widget the project managed to show first`
- `:597` — `Runtime STATE no-ops (an active overlay, a hidden widget)` → `(an active widget, a hidden widget)`
- `:684` — `not only the project overlay — gets the same` → `not only the project widget — gets the same`
- `:689` — `The project overlay closes the two resolvers` → `The project widget closes the two resolvers`
- `:700` — `the one state question a project may ask the overlay` → `... may ask the widget`
- `:773` — `callbacks IS the overlay widget's OWN table` → `callbacks IS the widget's OWN table`
- `:798` — `get_active resolves the overlay's OWN shown flag` → `... resolves the widget's OWN shown flag`

### `src/controller/projectInputController.lua`
- `:123` — `not only the project overlay) can reuse it` → `not only the project widget) can reuse it`

### `tests/helpers/input_fixture.lua`
- `:261` — `the overlay's shownness included` → `the widget's shownness included`
- `:284` — `production teardown hides the overlay but deliberately keeps its text` → `... hides the widget but ...`

### `tests/input/input_nfr_mechanism_spec.lua`
- `:56` — `only the overlay widget is wired` → `only the input widget is wired`

### `tests/input/input_widget_control_spec.lua` (14)
- `:112` — `configure() has no inactive overlay to force` → `... no inactive widget to force`
- `:477` — `"Live changes": the overlay answers whether it is up` → `... the widget answers whether it is up`
- `:484` — `it('reports the overlay state across a show/hide cycle'` → `it('reports the widget state across a show/hide cycle'`
- `:495` — `act only when the overlay is down` → `act only when the widget is down`
- `:569` — `it('the echo does not reach an overlay it opened'` → `it('the echo does not reach an input widget it opened'`
- `:579` — `eaten while the overlay is still closed` → `eaten while the widget is still closed`
- `:616` — `A shown overlay must be PAINTED` → `A shown widget must be PAINTED`
- `:619` — `which paints the overlay after the project's own frame` → `... paints the widget after ...`
- `:624` — `the overlay's own view is the only surface` → `the widget's own view is the only surface`
- `:627` — `the frame reaches the overlay's view` → `the frame reaches the widget's view`
- `:629` — `describe('a shown overlay is painted'` → `describe('a shown widget is painted'`
- `:631` — `it('the console draw path paints a shown overlay'` → `it('... paints a shown widget'`
- `:639` — `it('a hidden overlay is not painted'` → `it('a hidden widget is not painted'`
- `:652` — `it('an overlay is not painted under inspect'` → `it('a widget is not painted under inspect'` (article also fixed: "an" → "a", forced by the word change, no other wording touched)

### `tests/input/input_route_lifecycle_spec.lua` (10)
- `:180` — `starts its first project WITHOUT an overlay` → `... WITHOUT an input widget`
- `:183` — `The overlay must come up with the SECOND project's text` → `The widget must come up ...`
- `:187` — `it('a second project gets its overlay after the first '` → `it('a second project gets its input widget after the first '`
- `:205` — `An overlay the project already showed is part of that teardown` → `An input widget the project already showed ...`
- `:212` — `a chunk that shows an overlay and then raises` → `... shows an input widget and then raises`
- `:214` — `` `extra` runs after the overlay is up`` → `` `extra` runs after the widget is up``
- `:244` — `show() is a no-op over an active overlay (Decision 3)` → `... over an active widget (Decision 3)`
- `:246` — `it('lets the next run show its own overlay'` → `it('lets the next run show its own input widget'`
- `:317` — `the overlay handle the draw path reads are both left` → `the widget handle the draw path reads are both left`
- `:414` — `a crashed project's overlay edited the very` → `a crashed project's widget edited the very`

### `tests/input/input_widget_callbacks_spec.lua` (5)
- `:118` — `it('LuaHighlighter colors Lua overlay text'` → `it('LuaHighlighter colors Lua input widget text'`
- `:898` — `the console and the project overlay are driven` → `the console and the project widget are driven`
- `:931` — `describe('project overlay: the same Enter and Escape'` → `describe('project widget: the same Enter and Escape'`
- `:994` — `it('overlay: Ctrl+Enter submits'` → `it('input widget: Ctrl+Enter submits'`
- `:1005` — `it('overlay: Alt+Enter submits'` → `it('input widget: Alt+Enter submits'`

### `tests/input/input_cursor_text_spec.lua`
- `:45` — `the route a real project's overlay is fed through` → `... a real project's widget is fed through`
- `:184` — `(the overlay handle is not re-published;` → `(the widget handle is not re-published;`

## 3. The kept list (10) — every site, with reason

### `src/view/canvas/terminalView.lua` (5) — the verified `terminal_draw` site
- `:7` — `--- @param overlay boolean?`
- `:8` — `local function terminal_draw(terminal, canvas, overlay)`
- `:12` — `-- if terminal.dirty or overlay then`
- `:35` — `if overlay then`
- `:43` — `if not overlay then`

Reason (one, covering all five): this is the prompt's first named verified
site — the console's own compositing-layer parameter, not the input
widget. Also out of scope to rename regardless (a parameter, not a
comment/description string).

### `src/controller/controller.lua` (3) — the verified FPS-overlay site
- `:424` — `-- FPS-corner overlay cycle (love.PROFILE.fpsc), in display`
- `:833` — `local function reserved_overlay()`
- `:858` — `['f10']              = reserved_overlay,`

Reason: the FPS-corner overlay (`love.PROFILE.fpsc`), the prompt's second
named verified site — a different thing entirely from the input widget.
`:833`/`:858` are a function definition and its table reference, not
comment text — out of scope to rename in any case, and correctly not
requested by the prompt (no other `reserved_*` renames were named).

### `tests/input/input_global_shortcuts_spec.lua` (2) — the verified FPS-overlay test site
- `:269` — `it('f10 still cycles the FPS overlay unmodified',`
- `:344` — `pending('f10 cycles the FPS-corner overlay'`

Reason: the prompt's third named verified site — same FPS overlay as
above, described from the test side.

## 4. `input_widget_overlay` uses

None. Every site that named the widget being drawn over the console
(`controller.lua:630`, `input_widget_control_spec.lua:616-654`) admitted
plain "the widget" without ambiguity — the surrounding sentence already
carried enough context (a `describe`/`it` about painting, a citation to
"Widget lifecycle") that the compound was not needed. Per the prompt's
own preference ("prefer saying it plainly"), the compound was never
reached for.

## 5. Found but not touched

- **No dangling citations.** Every doc heading cited in a comment I
  touched or read nearby was checked with `grep -n '^#' <doc>` and
  resolves: `doc/development/internals/user_input.md` — "Widget
  lifecycle", "Cursor manipulation and \"reset\"", "Dispatch chain", "Key
  release", "Search — a third widget instance, live only in
  editor/search mode"; `doc/input_api.md` — "Live changes";
  `doc/development/decisions/input.md` — Decision 3, Decision 11;
  `doc/development/technical_debt/input.md` — "ruling (a)". None are
  stale.
- **No false comment claims found** in the sites touched or read for
  context.
- **No overlay-meaning hidden behind a synonym** ("the overlay strip",
  "the floating input") was found anywhere in scope — checked with a
  follow-up grep for `floating (input|widget)`, `overlay strip`,
  `overlaid`, `drawn over`, `painted over`, `shown atop`, `on top of`,
  `floating`; the only hits were the two lines I had just edited myself
  (`controller.lua:630-631`, now reading "painted on top of").
- **Two markers from a prior inventory were already resolved before I
  started**, confirming the prompt's note that the parent had already
  done one rename: `doc/.../validation/outcomes/S45-P11-inventory.md`
  lists `src/controller/consoleController.lua:180` and
  `tests/input/input_widget_callbacks_spec.lua:730` as open "retire
  overlay" markers. Both sites read clean today (`hide_input_widget`
  and a widget-only comment, respectively, no "overlay" present) — no
  action needed, noted here only so the inventory isn't treated as
  still-open by a future reader.
- **Three lines now exceed 64 characters** as a direct, unavoidable
  consequence of "overlay" (7 chars) becoming "input widget" (13 chars)
  inside an already near-limit line — all in
  `tests/input/input_route_lifecycle_spec.lua`: `:180` (69 chars),
  `:187` (69 chars), `:212` (68 chars). I did not rewrap them: the
  prompt's "do not compress or rewrite beyond the word change" reads as
  covering line-reflow too, and the file already had multiple
  85+-character comment lines before I touched it (e.g. `:6`, `:8`),
  so this is not a regression against the file's own prevailing state.
  Flagging for the compaction pass rather than fixing here.
- **One resulting phrase reads slightly redundant** —
  `src/controller/consoleController.lua:597`: `"Runtime STATE no-ops (an
  active widget, a hidden widget) are NOT this"` now says "widget" twice
  where the original paired "overlay" with "widget" as two words for the
  same concept. A literal word-for-word swap was the only option that
  did not rewrite the sentence; flagging in case the parent wants a
  different second word (e.g. "an active one") in the compaction pass.

## Suite

`968 successes / 0 failures / 0 errors / 10 pending` — unchanged from
baseline, confirmed after all edits.

## Deliverable path

`doc/development/wip/77-new-input-api/validation/outcomes/S45-overlay-retirement-code.md`
(this file).
