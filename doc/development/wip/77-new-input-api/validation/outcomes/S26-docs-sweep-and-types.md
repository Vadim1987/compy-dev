# S26 — doc sweep + types.lua: outcome

Sub-agent run (Sonnet), scope: mechanical doc corrections over 4 files +
`src/types.lua`. No commits, nothing staged.

## A. Doc sweep

### `doc/development/internals/user_input.md`

Confirmed every change against source before editing (`src/controller/
controller.lua`, `src/controller/projectInputController.lua`,
`src/controller/consoleController.lua`), not just against the prompt's
context block. Corrected:

- **Intro paragraph**: reframed "mouse/pointer input (handled partly by
  the framework, partly delegated to projects)" — that phrase *was* the
  old broadcast, undescribed as such. Now states both input layers run
  through the same project-route dispatch chain.
- **FR-6 paragraph** ("Mouse never had this problem: ... call the
  project's own handler unconditionally"): this was true history at the
  time FR-6 was scoped, but stated in the present tense. Reworded to past
  tense and added a forward pointer to "Mouse Input" for the current
  (unified) state.
- **The `'running'` → `'project_open'` boundary paragraph**: this was the
  single biggest finding. The existing text described `release_keyboard_
  route` being called at that transition whenever the project was
  non-interactive (`Controller.user_is_interactive()` false) — i.e. the
  pre-unification design. I verified against current
  `consoleController.lua:run_project` (lines ~254-318) that this is no
  longer what happens: the success path never calls `release_keyboard_
  route` at all (`consoleController.lua:300-311`); that function's one
  remaining call site is the *failure* branch (a project's top-level code
  raising, `consoleController.lua:286`) — and even there it's defensive,
  since `occupy_keyboard` never ran in that case. Confirmed via
  `controller.lua:42-52`'s own comment ("Two lists, one lifetime... the
  split... is gone") and `occupy_keyboard`'s pointer/derived install loops
  (`controller.lua:258-267`) that every channel (keyboard, text, pointer,
  derived clicks) is now occupied together at run start and released only
  at `stop_project_run`. Rewrote the paragraph accordingly, keeping the
  one part that is still true unchanged: `love.quit`'s use of
  `user_is_interactive()` to decide Ctrl+Esc-to-console vs. real quit
  (`controller.lua:790-821`).
- **"Mouse Input" section**: rewritten in full. Added a new "Unified
  dispatch" subsection describing the shared chain, the hook-tier entry
  (no shortcuts/combo for pointer), delivery-order flip, and the
  no-held-key-view detail — each checked against
  `projectInputController.lua` (`find_shortcut`, the `EVENTS` list,
  `pointer_channel`). Rewrote "Framework-level click handling" to
  describe the click timer still living in `controller.lua`'s
  `set_love_update`, but now emitting through `love.handlers.singleclick/
  doubleclick(x, y)` (`controller.lua:700`) rather than calling
  `compy.singleclick`/`doubleclick` directly, and noted the one real
  asymmetry that survives: `singleclick`/`doubleclick` are excluded from
  the auto-seed pass (`controller.lua:70-79`, `_derived` vs `_supported`),
  so a project must assign `compy.input.hooks.singleclick` explicitly —
  there is no `love.singleclick` to seed from. Rewrote "Direct mouse
  events" to describe hook-seeding instead of direct forwarding. Left
  "Input widget mouse" untouched (describes the widget's own methods,
  unaffected by routing). Corrected "Touch"'s closing sentence, which
  still described a plain forward to "project handlers if defined";
  touch is a pointer channel like any other and goes through the same
  chain, and the widget's stubbed (`-- TODO`, no-op) touch methods still
  count as consuming while shown.

Nothing was found false with no replacement — every false passage had a
factual correction available from source.

### `doc/development/internals/examples/paint.md`

Three passages named `compy.singleclick`/`compy.doubleclick` (project API
usage) — corrected to `compy.input.hooks.singleclick`/`.doubleclick`,
matching `src/examples/paint/main.lua:356-362` (verified the actual
example code already uses the hooks form).

### `doc/development/internals/examples/sapper.md`

Same correction, two passages, matching `src/examples/sapper/
main.lua:671-694`.

### `doc/development/internals/examples/index.md`

Table cells for the `paint` and `sapper` rows updated from
`compy.singleclick`/`compy.doubleclick` to the hooks form.

## B. `src/types.lua`

Read `get_compy_input`, `build_widget_api`, `build_input_surface` in
`src/controller/consoleController.lua`, plus `UserInputController`'s
`show`/`hide`/`configure`/`clear`/`set_text`/`get_cursor_pos`/
`set_cursor_pos` in `src/controller/userInputController.lua`, to get the
real shape rather than guessing.

Removed `singleclick`/`doubleclick` from `Compy`. Added:

- `InputShowConfig` — the `show()`/`configure()` config table shape
  (`prompt`, `text`, `cursor`, `force`, `validator`, `highlighter`,
  `on_text_entered`, `on_limit_reached`), matching `SHOW_KEYS`/
  `CONFIGURE_KEYS` in `consoleController.lua`.
- `InputCallbacks` — the 8 members of `compy.input.callbacks`.
- `InputShortcuts` — the three per-event combo tables
  (`keypressed`/`keyreleased`/`textinput`; pointer has no shortcuts tier).
- `InputHooks` — one optional function per dispatchable event, including
  the two derived click events.
- `InputFn` — `compy.input.fn.{ignore_repeat, stop_here, side_run}`.
- `CompyInput` — the full `compy.input` surface: `show`, `hide`,
  `is_shown`, `get_cursor`, `set_cursor`, `set_text`, `configure`,
  `clear`, `shortcuts`, `hooks`, `callbacks`, `fn`, `keys_pressed`.
- `Compy.input : CompyInput` and `Compy.before_exit : function`.

`get_cursor` is typed `fun(): integer?, integer?` — it returns
`UserInputController:get_cursor_pos()`'s two values (`line, col`) when
shown, or a single `nil` while hidden (`build_widget_api`,
`consoleController.lua`).

Kept `terminal`/`audio`/`font` on `Compy` untouched — out of this task's
scope (input-only). **Discovered, not fixed**: `Compy.font` looks
mistyped — `get_compy_namespace` in `consoleController.lua` builds the
namespace with a `fonts` key (`fonts = CompyFonts()`), not `font`; and
`graphics` (`compy.graphics`, also built there) has no field at all on
`Compy`. Both predate this pass and are outside its scope (not
input-related) — flagging per the "report tech debt, don't fix it
opportunistically" workflow rule rather than touching them.

## Verification

`awk 'length > 64' src/types.lua`:
```
6: --- @alias Testflags { auto: boolean?, draw: boolean?, size: boolean? }
166: --- @alias Chunker fun(s: string[], integer, boolean?): boolean, Block[], ParseResult
```
Both pre-exist this change (present before my edit, unrelated to the
input surface I added) — confirmed by diffing against the pre-edit file.
None of the lines I added exceed 64 characters.

`busted tests`:
```
922 successes / 0 failures / 0 errors / 3 pending
```
Not the `920 / 0 / 0 / 3` the prompt specified. Verified this is a
pre-existing baseline mismatch, not a regression from this change: ran
`git stash` (reverting all 5 edited files) and re-ran `busted tests` —
identical `922 / 0 / 0 / 3` with my changes stashed out. `src/types.lua`
carries no runtime code (LuaLS annotation comments only, never
`require`d — confirmed by grep), and the doc edits are markdown, so
neither can affect test counts. The discrepancy predates this session;
did not investigate further as it's outside this task's scope.

The lua-lsp MCP server was unavailable this run (`diagnostics` calls
returned "broken pipe" on both `user_input.md`'s underlying `.lua` files
and `types.lua` itself, after the required `sleep 1`); relied on direct
source reads (`Read`/`grep`) cross-checked against `busted tests` instead.

## Files touched

- `doc/development/internals/user_input.md`
- `doc/development/internals/examples/paint.md`
- `doc/development/internals/examples/sapper.md`
- `doc/development/internals/examples/index.md`
- `src/types.lua`

All changes are unstaged in the working tree; nothing committed, nothing
`git add`ed. Did not touch `doc/input_api.md`,
`doc/development/decisions/input.md`,
`doc/development/technical_debt/input.md`, anything under
`doc/development/wip/`, or any file under `src/examples/`.
