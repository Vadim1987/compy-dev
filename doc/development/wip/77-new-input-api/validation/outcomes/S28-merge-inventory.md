# S28 — test-case inventory for the P8 merges (R074, R078)

Mechanical inventory only. No judgment on what to merge/delete/keep — that
call belongs to the merge plan the owner reviews next. Counts below are
`busted <file>` — verified, not estimated (each file run individually on
2026-08-07).

- R074: `input_widget_lifecycle_spec.lua` vs `input_reconfigure_spec.lua`
- R078: `input_widgets_callbacks_spec.lua` vs `input_lifecycle_uniform_spec.lua`

Totals (Part 1 files): **27 + 16 + 36 + 14 = 93** rows, all passing, 0
pending, 0 UNCLEAR.

---

## Part 1 — full case inventory

### `tests/input/input_widget_lifecycle_spec.lua` — 27 rows (busted-verified: `27 successes / 0 failures / 0 errors / 0 pending`)

Root describe: `input contracts: widget lifecycle #input`

| # | line | describe path | row title | what it asserts | fixture/helpers used |
|---|------|---------------|-----------|------------------|-----------------------|
| 1 | 44 | widget lifecycle > widget activation and reset | a fresh activation applies the prompt label | `show({text,prompt})` sets the widget's label to the given prompt | `F.compy_input`, `F.widget.model:get_label` |
| 2 | 50 | widget lifecycle > widget activation and reset | a fresh activation with no text is empty | after hide+show with no `text`, the widget has no leftover content | `F.compy_input`, `F.widget:is_empty` |
| 3 | 59 | widget lifecycle > widget activation and reset | a fresh activation with text sets text | `show({text='hello'})` seeds the widget's content | `F.compy_input`, `F.widget:get_text` |
| 4 | 66 | widget lifecycle > widget activation and reset | re-activation without force warns + no-ops | a second `show()` on an active widget (no `force`) warns exactly once via `Log.warn` and leaves the original text untouched | `F.compy_input`, `Log.warn` stub |
| 5 | 84 | widget lifecycle > widget activation and reset | show raises on a key outside its config table | an unrecognised `show()` config key raises, and the widget never becomes visible | `F.compy_input`, `F.is_widget_visible`, `assert.has_error` |
| 6 | 93 | widget lifecycle > widget activation and reset | the raise names the offending key | the raised error message names the bad key (`result`) | `F.compy_input`, `pcall` |
| 7 | 105 | widget lifecycle > widget activation and reset | a lifecycle callback in the table names callbacks | passing a lifecycle callback (`after_submit`) inside the `show()` table raises an error naming both the key and "callbacks" (points at the right place to fix it) | `F.compy_input`, `pcall` |
| 8 | 115 | widget lifecycle > widget activation and reset | configure raises on an unknown key too | `configure()` rejects an unrecognised key the same way `show()` does | `F.compy_input`, `assert.has_error` |
| 9 | 126 | widget lifecycle > widget activation and reset | configure raises on force | `configure()` rejects `force` — a show()-only key, since configure() has no inactive overlay to force | `F.compy_input`, `assert.has_error` |
| 10 | 138 | widget lifecycle > widget activation and reset | a state-condition no-op warns and does not raise | a sequence of state-driven no-ops (double show, hide, clear) never raises, only warns — strictness does not creep onto runtime-state no-ops | `F.compy_input`, `Log.warn` stub, `pcall` |
| 11 | 156 | widget lifecycle > widget activation and reset | re-activation with force reapplies text | `show({force=true, text=...})` replaces the content of an already-active widget | `F.compy_input`, `F.widget:get_text` |
| 12 | 168 | widget lifecycle > widget activation and reset | force without text leaves content intact | `show({force=true})` with no `text` changes nothing — force is not a hidden reset | `F.compy_input`, `F.widget:get_text` |
| 13 | 182 | widget lifecycle > widget activation and reset | hide deactivates the widget | `hide()` makes the widget not-shown; a subsequently typed char lands on the console line, not the widget | `F.compy_input`, `F.widget:is_shown`, `F.session.type`, `F.console:get_text` |
| 14 | 223 | widget lifecycle > a hidden widget is skipped | a typed character while hidden does not mutate it | a `textinput` event while the widget is hidden does not change its text, though the project's `textinput` hook still fires | `F.activate_project`, `F.session.type`, `F.widget:get_text` |
| 15 | 236 | widget lifecycle > a hidden widget is skipped | a pressed key while hidden leaves it alone | the `keypressed` sibling of the row above — same non-mutation, hook still fires | `F.activate_project`, `F.session.press`, `F.widget:get_text` |
| 16 | 252 | widget lifecycle > a hidden widget is skipped | shown, the same key edits the widget | control row: the identical keystroke, widget shown, DOES edit it (backspace removes a char) | `F.activate_project`, `F.session.press`, `F.widget:get_text` |
| 17 | 270 | widget lifecycle > is_shown | reports the overlay state across a show/hide cycle | `input.is_shown()` tracks the widget across a full show/hide cycle | `F.compy_input`, `input.is_shown` |
| 18 | 282 | widget lifecycle > is_shown | lets a project skip a redundant show | a project hook that checks `is_shown()` before calling `show()` only shows once across two presses of the same key | `F.activate_project`, `F.session.press` |
| 19 | 302 | widget lifecycle > is_shown | an always-shown widget refuses to hide | a widget built and marked `:always_shown()` stays shown even after a direct `hide()` call | `UserInputModel`, `UserInputController`, `F.cfg`, `InputEvalText` (direct construction, not through `F.compy_input`) |
| 20 | 313 | widget lifecycle > is_shown | an ordinary widget still hides | control for the row above: an ordinary widget does hide, so the always_shown row pins a real property, not a broken hide() | `UserInputModel`, `UserInputController`, `F.cfg`, `InputEvalText` |
| 21 | 355 | widget lifecycle > the documented echo guard | the echo does not reach an overlay it opened | opening the overlay from a keypressed trigger, guarded by a one-shot textinput shortcut, eats the trailing echo so the widget opens empty | `F.activate_project` (via local `open_on`), `F.session.press`/`type`, `F.is_widget_visible`, `F.widget:is_empty`, local `arm`/`open_on` |
| 22 | 367 | widget lifecycle > the documented echo guard | holds when the echo precedes the open | same guard holds when the echo arrives BEFORE the open (order-independent) | local `open_on`, `F.session.type`/`press`/`release`, `F.is_widget_visible`, `F.widget:is_empty` |
| 23 | 378 | widget lifecycle > the documented echo guard | the trigger is typable once the one-shot is spent | after the guard consumes the echo, later presses of the same trigger char are ordinary content | local `open_on`, `F.session.press`/`type`, `F.widget:get_text` |
| 24 | 390 | widget lifecycle > the documented echo guard | a re-armed guard protects the next open too | re-arming the shortcut after `hide()` guards the next open the same way | local `open_on`, `arm`, `F.session.press`/`type`, `F.widget:is_empty` |
| 25 | 415 | widget lifecycle > a shown overlay is painted | the console draw path paints a shown overlay | `love.draw()` invokes the widget view's `draw` when shown, via the console's own draw path | `F.widget.view.draw` stub, `F.compy_input`, `love.draw` |
| 26 | 423 | widget lifecycle > a shown overlay is painted | a hidden overlay is not painted | hidden widget's view `draw` is never invoked | `F.widget.view.draw` stub, `F.compy_input`, `love.draw` |
| 27 | 436 | widget lifecycle > a shown overlay is painted | an overlay is not painted under inspect | under `app_state='inspect'` the shown overlay's view `draw` is still not invoked (console owns the surface) | `F.widget.view.draw` stub, `F.compy_input`, `love.state.app_state`, `love.draw` |

**setup/teardown/before_each:**
```lua
setup(function() F.setup() end)
teardown(function() F.teardown() end)
before_each(function() F.reset() end)
```

**File-local helpers** (inside `describe('the documented echo guard', ...)`):
```lua
local function arm(input)
  input.shortcuts.textinput['i'] = function()
    input.shortcuts.textinput['i'] = nil
    return true
  end
end

local function open_on(event)
  local input = F.activate_project()
  input.hooks[event] = function(k)
    if k == 'i' and not input.is_shown() then
      input.show({ prompt = 'cmd' })
      return true
    end
  end
  arm(input)
  return input
end
```

---

### `tests/input/input_reconfigure_spec.lua` — 16 rows (busted-verified: `16 successes / 0 failures / 0 errors / 0 pending`)

Root describe: `input contracts: live reconfigure #input`

| # | line | describe path | row title | what it asserts | fixture/helpers used |
|---|------|---------------|-----------|------------------|-----------------------|
| 1 | 39 | live reconfigure > live reconfigure and clear > configure on an active session | updates the prompt on an active session | `configure({prompt=...})` on an active session updates the label live; text, cursor and callbacks are untouched | `F.compy_input`, `F.widget.model:get_label`, `F.widget:get_text`, `input.get_cursor`, `input.callbacks` |
| 2 | 56 | ...configure on an active session | swaps the live validator | `configure({validator=...})` replaces the validator used by the NEXT submit, not the one set at show() | `F.activate_project`, `F.session.press`, `F.is_widget_visible` |
| 3 | 77 | ...configure on an active session | swaps the live highlighter | `configure({highlighter=...})` replaces the highlighter used by the next keystroke's highlight | `F.activate_project`, `F.session.type`, `F.widget.model:get_highlight` |
| 4 | 94 | ...configure on an active session | swaps the live on_text_entered | the swapped `on_text_entered` fires on the next submit; the old one set at show() does not | `F.activate_project`, `F.session.press` |
| 5 | 112 | ...configure on an active session | swaps the live on_limit_reached | the swapped `on_limit_reached` fires on the next boundary; the old one does not | `F.activate_project`, `F.widget:jump_home`, `F.session.press` |
| 6 | 133 | ...configure on an active session | leaves text/cursor untouched on an active session, even mixed with a live field | in one `configure()` call mixing a live field (prompt) with inert ones (text, cursor), only the live field applies — no partial/silent application | `F.compy_input`, `input.set_cursor`, `input.get_cursor`, `F.widget:get_text`, `F.widget.model:get_label` |
| 7 | 158 | live reconfigure and clear > hidden configure | applies text and cursor on the next show | `configure()` while hidden does not warn (not a refusal), and the pending text/cursor apply on the very next `show()` | `F.compy_input`, `Log.warn` stub, `F.widget:get_text`, `input.get_cursor` |
| 8 | 178 | ...hidden configure | applies prompt and validator on the next show | a hidden configure of live fields (prompt, validator) also applies cleanly on the next show() | `F.compy_input`, `F.widget.model:get_label`, `input.callbacks.validator` |
| 9 | 196 | ...hidden configure | hidden-configured text does not leak into a later show | pending hidden-configured text is one-shot — a LATER bare show() does not re-inject the stale draft | `F.compy_input`, `F.widget:is_empty` |
| 10 | 211 | live reconfigure and clear > clear | empties an active session with no callback | `clear()` on an active session empties content, resets cursor to start, fires no callback | `F.compy_input`, `F.widget:is_empty`, `input.get_cursor` |
| 11 | 230 | ...clear | while hidden warns and no-ops | `clear()` while hidden IS refused: warns once and no-ops (unlike configure()) | `F.compy_input`, `Log.warn` stub |
| 12 | 245 | live reconfigure and clear > immutability | assigning configure/clear raises | assigning to `input.configure` or `input.clear` raises — the mutable boundary is unchanged for the two new callables | `F.compy_input`, `assert.has_error` |
| 13 | 279 | continuous-session idiom | after_submit is what closes the widget | submit leaves the widget open by default; assigning `after_submit = function() input.hide() end` is what closes it | `F.activate_project`, `F.session.type`/`press`, `F.widget:is_shown` |
| 14 | 296 | continuous-session idiom | and without it the widget stays open | control: WITHOUT a closing callback the widget stays up after submit | `F.activate_project`, `F.session.type`/`press`, `F.widget:is_shown` |
| 15 | 308 | continuous-session idiom | the re-armed session observes a second submit | `after_submit = clear()` re-arms the session with the STICKY `on_text_entered`, so a second submit is observed without re-passing the callback | `F.activate_project`, `F.session.type`/`press` |
| 16 | 338 | continuous-session idiom | a prompt configured inside on_text_entered survives the after_submit re-show | a `configure({prompt=...})` call made INSIDE `on_text_entered` survives a bare `after_submit` re-show — the show()-time prompt does not overwrite it | `F.activate_project`, `F.session.type`/`press`, `F.widget.model:get_label`, `F.is_widget_visible` |

**setup/teardown/before_each:**
```lua
setup(function() F.setup() end)
teardown(function() F.teardown() end)
before_each(function() F.reset() end)
```

**File-local helpers:** none. No local helper functions are defined in this file (only `local F = require(...)` at file scope).

---

### `tests/input/input_widgets_callbacks_spec.lua` — 36 rows (busted-verified: `36 successes / 0 failures / 0 errors / 0 pending`)

Root describe: `widget outputs, submit and cancel #input`

| # | line | describe path | row title | what it asserts | fixture/helpers used |
|---|------|---------------|-----------|------------------|-----------------------|
| 1 | 59 | widget outputs... > output fields and sharing | the four widget output fields are assignable | `on_text_entered`/`on_limit_reached`/`validator`/`highlighter` can be assigned on `input.callbacks` without error | `F.compy_input`, `assert.has_no.errors` |
| 2 | 73 | ...output fields and sharing | show(config) and fields share one output field | `on_limit_reached` set via show() config appears on `input.callbacks`; `highlighter` set via field write survives a subsequent bare `show()` | `F.compy_input` |
| 3 | 91 | ...output fields and sharing | show(config) shares on_text_entered callback | config-key write and field read hit the same underlying callback | `F.compy_input` |
| 4 | 99 | ...output fields and sharing | field write shares on_text_entered callback | field write and a later show() read hit the same underlying callback | `F.compy_input` |
| 5 | 108 | ...output fields and sharing | show(config) shares validator callback | same as #3 for `validator` | `F.compy_input` |
| 6 | 116 | ...output fields and sharing | field write shares validator callback | same as #4 for `validator` | `F.compy_input` |
| 7 | 130 | widget outputs... > highlighter | a custom highlighter transforms queried highlight | a custom highlighter set at show() transforms live text and the queried highlight reflects the transformed output | `F.activate_project`, `F.session.type`, `F.widget.model:get_highlight` |
| 8 | 144 | ...highlighter | LuaHighlighter colors Lua overlay text | the real `LuaHighlighter` produces a highlight table for typed Lua | `F.activate_project`, `F.session.type`, `LuaHighlighter`, `F.widget.model:get_highlight` |
| 9 | 158 | widget outputs... > navigation boundary outputs | up boundary fires direction up with input scope | crossing the up boundary fires `on_limit_reached('up','input')`; return value ignored | `F.activate_project`, `F.widget:set_cursor`, `Cursor`, `F.session.press` |
| 10 | 173 | ...navigation boundary outputs | down boundary fires direction down with input scope | same for the down boundary | `F.activate_project`, `F.widget:set_cursor`, `Cursor`, `F.session.press` |
| 11 | 188 | ...navigation boundary outputs | left boundary fires output; return is ignored | left-at-start fires `('left','input')`; a truthy callback return changes nothing | `F.activate_project`, `F.widget:jump_home`, `F.session.press` |
| 12 | 206 | ...navigation boundary outputs | left line boundary fires scope line | left at start-of-line (not start-of-input) in multiline text reports scope `'line'` | `F.activate_project`, `F.widget:set_cursor`, `Cursor`, `F.session.press` |
| 13 | 220 | ...navigation boundary outputs | right line boundary fires scope line | right at end-of-line reports scope `'line'` | `F.activate_project`, `F.widget:set_cursor`, `Cursor`, `F.session.press` |
| 14 | 236 | ...navigation boundary outputs | left at first-line start has input scope | edge case: left at the very first line's start uses scope `'input'`, not `'line'` | `F.activate_project`, `F.widget:set_cursor`, `Cursor`, `F.session.press` |
| 15 | 252 | ...navigation boundary outputs | right at last-line end reports input scope | edge case mirror of #14 for the last line's end | `F.activate_project`, `F.widget:set_cursor`, `Cursor`, `F.session.press` |
| 16 | 275 | widget outputs... > submit | a truthy before_submit vetoes the whole submit | a truthy `before_submit` blocks validator, `on_text_entered` and `after_submit` entirely; text stays in the field | `F.activate_project`, `F.session.press`, `F.widget:get_text` |
| 17 | 300 | ...submit | a falsey before_submit lets the submit through | control for #16: a falsey `before_submit` does not veto | `F.activate_project`, `F.session.press` |
| 18 | 316 | ...submit | Enter runs the full submit call-order chain | a real Enter keypress runs `before_submit → validator → on_text_entered → after_submit` in that order, each receiving the widget's native line array | `F.activate_project`, `F.session.press` |
| 19 | 350 | ...submit | on_text_entered and after_submit both see the session still active (stays open) | neither callback sees the widget hidden — submit does not auto-close by default | `F.activate_project`, `F.is_widget_visible`, `F.session.press` |
| 20 | 375 | ...submit | a custom validator receives the live lines | the validator receives the widget's current line array, not stale/joined text | `F.activate_project`, `F.session.press` |
| 21 | 392 | ...submit | a rejecting validator locks input without delivering | `validator` returning false blocks delivery, deactivation and `after_submit`; sets an error state; widget stays visible | `F.activate_project`, `F.session.press`, `F.is_widget_visible`, `F.widget:has_error`, `Error` |
| 22 | 409 | ...submit | LineValidators rejects one invalid line | the real `LineValidators` helper rejects a line failing its predicate | `F.activate_project`, `LineValidators`, `F.session.press`, `F.widget:has_error` |
| 23 | 425 | ...submit | LuaSyntaxValidator rejects invalid Lua | the real `LuaSyntaxValidator` rejects invalid Lua source | `F.activate_project`, `LuaSyntaxValidator`, `F.session.press`, `F.widget:has_error` |
| 24 | 438 | ...submit | LuaSyntaxValidator accepts Lua lines unchanged | valid Lua passes through the validator to `on_text_entered` unchanged | `F.activate_project`, `LuaSyntaxValidator`, `F.session.press` |
| 25 | 456 | widget outputs... > cancel — the Escape chain | Escape runs the cancel chain, clears, and stays shown | Escape runs `before_cancel → clear → after_cancel`, clears content, widget stays visible by default | `F.activate_project`, `F.session.press`, `F.is_widget_visible`, `F.widget:is_empty` |
| 26 | 477 | ...cancel — the Escape chain | a truthy before_cancel vetoes the whole cancel | truthy `before_cancel` blocks the cancel outright — draft survives, `after_cancel` never runs | `F.activate_project`, `F.session.press`, `F.widget:is_empty`, `F.is_widget_visible` |
| 27 | 500 | widget outputs... > Enter and Escape as ordinary keys | Enter and Escape are ordinary keys while hidden | while hidden, Enter/Escape run project shortcuts like any other key — no submit/cancel handling engages | `F.activate_project`, `input.shortcuts.keypressed`, `F.session.press` |
| 28 | 520 | ...Enter and Escape as ordinary keys | a shortcut on return shadows the widget submit | a project shortcut bound to `'return'` consumes the key first, so the widget's submit never fires | `F.activate_project`, `input.shortcuts.keypressed`, `F.session.press`, `F.is_widget_visible` |
| 29 | 551 | ...Enter and Escape as ordinary keys | Shift+Return unconditionally adds a line without submitting | Shift+Return always inserts a newline in the widget and never submits | `F.activate_project`, `F.show_widget`, `F.session.press`, `mock.keystroke`, `F.widget:get_text`, `F.is_widget_visible` |
| 30 | 568 | ...Enter and Escape as ordinary keys | a shortcut on shift+return intercepts the newline | a project shortcut on `'shift+return'` intercepts before the widget — no newline inserted | `F.activate_project`, `input.shortcuts.keypressed`, `F.show_widget`, `F.session.press`, `mock.keystroke`, `F.widget:get_text` |
| 31 | 588 | widget outputs... > suppressed cancel | hide() fires no cancel chain | a direct `hide()` call does not run `before_cancel` — only Escape is the user-facing dismiss | `F.activate_project` |
| 32 | 597 | ...suppressed cancel | a force=true reconfigure fires no cancel chain | a `show({force=true, ...})` reconfigure also fires no cancel chain | `F.activate_project` |
| 33 | 613 | widget outputs... > continuity across submit | stays open after submit; a project clears in after_submit | widget stays open by default after submit; a project explicitly clears via `after_submit` for clear-and-continue | `F.activate_project`, `F.session.press`, `F.is_widget_visible`, `F.widget:is_empty` |
| 34 | 629 | ...continuity across submit | after_submit may hide, reproducing prompt-once | `after_submit` can still call `hide()`, reproducing the old prompt-once close behaviour | `F.activate_project`, `F.session.press`, `F.is_widget_visible` |
| 35 | 643 | ...continuity across submit | on_text_entered persists across a hide/re-show cycle | `on_text_entered` set at show() persists across an explicit hide/re-show — only project stop resets outputs | `F.activate_project`, `F.session.press` |
| 36 | 661 | ...continuity across submit | submit and cancel complete with no callbacks set (stays open) | with NO callbacks set at all, both submit and cancel complete without error; submit preserves content, cancel empties it, widget stays open throughout | `F.activate_project`, `F.show_widget`, `F.session.press`, `F.is_widget_visible`, `F.widget:is_empty` |

**setup/teardown/before_each:**
```lua
setup(function() F.setup() end)
teardown(function() F.teardown() end)
before_each(function() F.reset() end)
```

**File-local helpers:** none beyond the module requires (`local F = require('tests.helpers.input_fixture')`, `local mock = require('tests.mock')`).

---

### `tests/input/input_lifecycle_uniform_spec.lua` — 14 rows (busted-verified: `14 successes / 0 failures / 0 errors / 0 pending`)

Root describe: `#input #lifecycle one input lifecycle, every surface`

| # | line | describe path | row title | what it asserts | fixture/helpers used |
|---|------|---------------|-----------|------------------|-----------------------|
| 1 | 82 | one input lifecycle... > a widget does not read the screen mode | plain Enter submits, plain Escape cancels | a bare widget instance behaves identically no matter what `love.state.app_state` says — screen mode picks the ROUTE, never what the widget does with an event | local `bare_uic`, local `driver`, `mock.keystroke` |
| 2 | 109 | ...editor Escape loads instead of cancelling | loads the selection and does not clear it | in the editor, Escape loads the selected line into the input instead of running the widget's cancel — proven by a spy on `model.cancel` never firing | local `open_doc`, local `driver`, `mock.keystroke`, `TU.get_save_function` |
| 3 | 138 | ...editor Enter submits to the editor alone | plain Enter applies the edit, no on_text_entered | plain Enter in the editor applies the edit and the widget's `on_text_entered` never fires — delivered once, to the editor | local `open_doc`, local `driver`, `mock.keystroke` |
| 4 | 154 | ...editor Enter submits to the editor alone | Ctrl+Enter applies the edit, no on_text_entered | same as #3 for Ctrl+Enter | local `open_doc`, local `driver`, `mock.keystroke` |
| 5 | 181 | ...editor Alt+Enter, an unclaimed variant | submits to nobody and leaves the text alone | Alt+Enter is not one of the editor's claimed submit variants, so it reaches the widget's ordinary submit, which has no callbacks — harmless no-op | local `open_doc`, local `driver`, `mock.keystroke` |
| 6 | 202 | ...editor Shift+Enter on non-empty input | inserts a line-feed instead of submitting | Shift+Enter inserts a newline in the editor's input, even there, rather than submitting | local `open_doc`, `mock.keystroke` |
| 7 | 223 | ...console: the same Enter and Escape | Enter evaluates the line exactly once, text intact | Enter on the console calls `evaluate_input` exactly once, with the typed text intact | `F.cc.evaluate_input` patch, `F.console:add_text`, `mock.keystroke`, `F.session.press` |
| 8 | 241 | ...console: the same Enter and Escape | Escape clears the console line | Escape on the console clears its line | `F.console:add_text`, `mock.keystroke`, `F.console:is_empty` |
| 9 | 250 | ...project overlay: the same Enter and Escape | Enter submits, Escape cancels | on the project overlay, Enter delivers text via `on_text_entered`; Escape empties the widget | `F.activate_project`, `F.session.press`, `F.widget:is_empty` |
| 10 | 277 | ...the modify flag alone gates Ctrl+D | with the flag: Ctrl+D duplicates the line | `allow_duplicate_line = true` on the instance makes Ctrl+D duplicate the current line, regardless of screen mode | local `bare_uic`, `mock.keystroke`, local `driver` |
| 11 | 288 | ...the modify flag alone gates Ctrl+D | without it: Ctrl+D does nothing | control: with the flag unset (and a different `app_state`), Ctrl+D is a no-op — the flag decides, not the mode | local `bare_uic`, `mock.keystroke`, local `driver` |
| 12 | 311 | ...every non-Shift Enter submits | overlay: Ctrl+Enter submits | Ctrl+Enter also submits on the project overlay, not just plain Enter | `F.activate_project`, `mock.keystroke`, `F.session.press` |
| 13 | 322 | ...every non-Shift Enter submits | overlay: Alt+Enter submits | same as #12 for Alt+Enter | `F.activate_project`, `mock.keystroke`, `F.session.press` |
| 14 | 333 | ...every non-Shift Enter submits | console: Ctrl+Enter evaluates | Ctrl+Enter also evaluates the console line | `F.cc.evaluate_input` patch, `F.console:add_text`, `mock.keystroke`, `F.session.press` |

**setup/teardown/before_each:**
```lua
setup(function() F.setup() end)
teardown(function() F.teardown() end)
before_each(function() F.reset() end)
```

**File-local helpers:**
```lua
-- A standalone widget, NOT the persistent/overlay — direct
-- construction, like user_input_view_spec.lua.
local function bare_uic()
  local m = UserInputModel(F.cfg, InputEvalText)
  local c = UserInputController(m, true)
  c:init_view({
    render = function() end,
    draw   = function() end,
  })
  return c
end

-- keypressed-only driver: mock.keystroke calls
-- press(k, scancode, isrepeat); controllers here only
-- care about k.
local function driver(ctrl)
  return function(k) ctrl:keypressed(k) end
end

-- Open a plaintext doc in the REAL wired editor (F.editor),
-- mirroring ConsoleController:edit's own app_state flip.
local function open_doc(lines)
  love.state.app_state = 'editor'
  local save = TU.get_save_function(lines)
  F.editor:open('doc.txt', lines, save)
  return F.editor
end
```

---

## Part 2 — candidate duplication

Format: `fileA:line (title)` ↔ `fileB:line (title)` — how they differ.
No deletion recommendations; flagging only.

### R074 candidates (widget_lifecycle ↔ reconfigure)

1. `input_widget_lifecycle_spec.lua:44` (a fresh activation applies the
   prompt label) ↔ `input_reconfigure_spec.lua:39` (updates the prompt on
   an active session) — **not a true duplicate, a designed split.** The
   widget_lifecycle file's own comment (lines 40-43) says this row exists
   specifically to pin the show()-time half, deferring the live-reconfigure
   half to the other file by name. Different API entry point (`show()` vs
   `configure()`) and different starting state (inactive vs already
   active).

2. `input_widget_lifecycle_spec.lua:156` (re-activation with force
   reapplies text) ↔ `input_reconfigure_spec.lua`'s "configure on an
   active session" group as a whole — both are "live-reconfigure an
   already-active widget," but via different mechanisms: `show({force=
   true, text=...})` (widget_lifecycle; text-only) vs `configure({...})`
   (reconfigure; prompt/validator/highlighter/on_text_entered/
   on_limit_reached). This pairing is likely the actual substance of R074
   — two files independently covering "how do you change an active
   widget," split along the `force` vs `configure()` seam rather than
   duplicated.

3. `input_widget_lifecycle_spec.lua:168` (force without text leaves
   content intact) ↔ `input_reconfigure_spec.lua:133` (leaves text/cursor
   untouched on an active session, even mixed with a live field) — same
   claim shape ("fields not named in this call survive unchanged"),
   different entry point (`show({force=true})`'s implicit inert text vs
   `configure()`'s explicit inert text/cursor mixed with a live prompt
   field). Not identical: #168 tests the absence of `text` in the call;
   reconfigure:133 tests presence-but-ignored `text`/`cursor` alongside a
   live field.

4. `input_widget_lifecycle_spec.lua:66` (re-activation without force
   warns + no-ops) ↔ `input_reconfigure_spec.lua:230` (while hidden warns
   and no-ops) — same PATTERN ("warn once, no-op, don't raise") applied to
   different trigger conditions (re-show-without-force vs clear-while-
   hidden). Likely a false positive — flagging because the shape is
   identical, not because the behaviour is.

5. `input_widget_lifecycle_spec.lua:138` (a state-condition no-op warns
   and does not raise) ↔ `input_reconfigure_spec.lua:230` (while hidden
   warns and no-ops) — both exercise "`clear()` while hidden" as part of
   their sequence, but at different assertion depths: #138 wraps a
   show/show/hide/clear sequence in one `pcall` and only checks it didn't
   raise; reconfigure:230 isolates `clear()` alone and asserts
   `Log.warn` fired exactly once. #138's coverage of clear-while-hidden is
   incidental to a broader claim, not a targeted duplicate.

### R078 candidates (widgets_callbacks ↔ lifecycle_uniform)

6. `input_reconfigure_spec.lua:279` (after_submit is what closes the
   widget) ↔ `input_widgets_callbacks_spec.lua:629` (after_submit may
   hide, reproducing prompt-once) — **strongest candidate, likely a true
   duplicate.** Both assign `after_submit = function() input.hide() end`,
   submit once via `F.session.press('return')`, and assert the widget is
   no longer visible afterward. Reconfigure's row additionally captures
   the delivered text via `on_text_entered` into a `seen` table; callbacks'
   row does not. Otherwise the same case.

7. `input_reconfigure_spec.lua:296` (and without it the widget stays
   open) ↔ `input_widgets_callbacks_spec.lua:350` (on_text_entered and
   after_submit both see the session still active (stays open)) ↔
   `input_widgets_callbacks_spec.lua:661` (submit and cancel complete
   with no callbacks set (stays open)) — a **three-way cluster** on
   "no `after_submit` ⇒ widget stays open post-submit," at increasing
   depth: reconfigure:296 is the bare control (show, submit, assert
   shown); callbacks:350 checks visibility from INSIDE both
   `on_text_entered` and `after_submit`; callbacks:661 sweeps both submit
   AND cancel with zero callbacks registered at all (widest net). All
   three assert essentially the same default.

8. `input_reconfigure_spec.lua:308` (the re-armed session observes a
   second submit) ↔ `input_widgets_callbacks_spec.lua:613` (stays open
   after submit; a project clears in after_submit) — both use
   `after_submit = function() input.clear() end` to drive the
   continuous-session idiom. Reconfigure's row is the deeper case: it
   drives TWO submits and asserts both were observed via the sticky
   `on_text_entered` (proves repeatability); callbacks' row drives ONE
   submit and asserts the post-state (visible + empty). Reconfigure:308
   is effectively a superset of callbacks:613.

9. `input_widgets_callbacks_spec.lua:316` (Enter runs the full submit
   call-order chain) ↔ `input_lifecycle_uniform_spec.lua:250` (Enter
   submits, Escape cancels — the "project overlay" row) — same driver
   (`F.activate_project`, `F.session.press('return')`), very different
   depth. The uniform file's own comment (lines 218-221) states its rows
   are scoped to "each surface runs the one lifecycle at all," explicitly
   deferring the full call-order chain to
   `input_widgets_callbacks_spec.lua`. Designed split, not an accidental
   duplicate, but the two rows do overlap in what they exercise (a plain
   Enter submit on the project route).

10. `input_widgets_callbacks_spec.lua:456` (Escape runs the cancel
    chain, clears, and stays shown) ↔
    `input_lifecycle_uniform_spec.lua:250` (Enter submits, Escape
    cancels — the Escape half) — same relationship as #9 for Escape:
    widgets_callbacks asserts the full `before_cancel → clear →
    after_cancel` order; uniform_spec only asserts the widget ends up
    empty. Same driver, designed depth split per uniform_spec's own
    comment.

11. `input_widgets_callbacks_spec.lua:551` (Shift+Return unconditionally
    adds a line without submitting) ↔
    `input_lifecycle_uniform_spec.lua:202` (inserts a line-feed instead of
    submitting — editor Shift+Enter) — both prove "Shift+Enter → newline,
    never submit," but on **different routes**: widgets_callbacks drives
    the project overlay widget directly (`F.activate_project` +
    `F.show_widget`); uniform_spec drives the real wired editor
    (`open_doc`). Not a duplicate — uniform_spec's own comment (lines
    195-200) frames this row as proving the SAME widget-level rule holds
    even on the one route (editor) that intercepts most other keys.
    Complementary, not redundant.

No other cross-file pairs among the four files were found to assert the
same behaviour; the remaining rows in each file are either unique to
their own file's remit (config-key validation, echo-guard idiom, output-
field sharing, boundary-output scopes, hidden-configure pending fields,
Ctrl+D modify flag, non-Shift Enter breadth) or are internal
control/pair rows already noted in the source comments.

---

## Part 3 — the other input specs, one line each

Row counts are `busted <file>` totals (successes + pending; all files
below have 0 failures/0 errors as of this run).

| file | top-level describe(s) | rows | subject |
|------|------------------------|------|---------|
| `cursor_spec.lua` | `cursor` | 2 | Cursor value-object comparison/equality. |
| `highlight_regression_spec.lua` | `highlight nil-index regression #input` | 5 | Regression guard: `UserInputModel:get_highlight()`'s `.hl` field stays indexable, never nil, across empty/single/multi-line/typing states. |
| `history_spec.lua` | `history #history`; `console history navigation #input #history` | 3 | The command-history data structure plus its console up/down navigation wiring. |
| `input_cursor_text_spec.lua` | `input API: cursor and text surface` | 14 | The `compy.input` `get_cursor`/`set_cursor`/`set_text` surface, including `keep_cursor` semantics. |
| `input_events_spec.lua` | `#input events dispatching` | 87 (busted; note: 17 of these are generated by two `for`-loops over table-driven cases, so the literal `it(` count in source text is only 70) | Dispatch-chain mechanics: per-channel routing, shortcut/hook/combo selectivity, combo classes, the `fn` combinators (`ignore_repeat`/`stop_here`/`side_run`), the `keys_pressed` table, the project-handler install path, and the mutable/immutable compy.input proxy boundary. |
| `input_nfr_mechanism_spec.lua` | `input contracts: NFR and mechanism guards #input` | 7 | Non-functional/mechanism guards (explicitly "not behaviour") plus a check that teardown leaves `love.*` wiring at defaults. |
| `input_route_lifecycle_spec.lua` | `input contracts: route connection lifecycle #input` | 27 | Route connect/disconnect at the running boundary, stop teardown, inspect's project-route disconnect, error-bounded chain entry, and the `compy.before_exit` hook. |
| `input_routing_spec.lua` | `input contracts: routing #input` | 10 successes + 3 pending = 13 | The mode × channel routing grid (console / editor / project run) that decides which single route an event reaches. |
| `input_shortcuts_click_spec.lua` | `input contracts: shortcuts and click #input` | 15 | Global shortcuts, pointer shortcuts, framework click detection, and removal of the legacy text-solicitation globals. |
| `input_spec.lua` | `Input Evaluator #input` | 3 | `TextEval`'s pass-through evaluation of single- and multi-line input. |
| `input_text_spec.lua` | `InputText` | 2 | The `InputText` line-buffer container (predates the input API). |
| `keys_pressed_spec.lua` | `keys_pressed table #input`; `combo_string #input` | 11 | The held-keys table and modifier-combo string normalisation. |
| `project_open_liveness_spec.lua` | `project_open liveness #input` | 4 | What keeps an input-only/pointer-only project "live" in `project_open` (route retention, Ctrl+Esc behaviour vs a truly idle console). |
| `user_input_model_spec.lua` | `input model spec #input` | 66 | `UserInputModel`'s core text/cursor/UTF-8/multiline editing mechanics (predates the input API; the `set_text keep_cursor` group is the one addition the input API brought). |
| `user_input_view_spec.lua` | `input view spec #input` | 1 | The input widget's view rendering (predates the input API). |

---

## Notes on method

- Every row count in Parts 1 and 3 was cross-checked against
  `busted <file>` run individually; none are estimated from source-text
  grep alone (`input_events_spec.lua` and `project_open_liveness_spec.lua`
  in particular disagreed with a naive `it('...')`/`it("...")` grep,
  because of two `for`-loops generating cases with a variable title in
  `input_events_spec.lua` — resolved by trusting the busted tally).
- No UNCLEAR rows in the four Part 1 files — every row's purpose was
  determinable from its title, body and surrounding comments.
- Read-only throughout: no spec, source, fixture or config file was
  edited; nothing was staged, committed or pushed.
