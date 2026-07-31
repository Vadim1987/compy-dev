# Test Suite Review

<!-- authored By LLM; human-approved NOT YET -->

Assessment of `tests/` relative to the codebase and the knowledge base under `doc/development/`. Organised into: relevant infrastructure, coverage map, gaps.

---

## Test Infrastructure Worth Knowing

**`EditorSession`** (`tests/helpers/editor_session.lua`) — A keystroke-driven test harness for the editor. Drives `EditorController` via simulated key events. Key methods: `open(src, nb)` asserts block count on open; `select_block(n)` navigates to block n; `select_and_open_block(n)` selects and presses Escape (asserts `buffer.loaded == n`); `submit(newtext)` alters input and sends Return; `assert_cursor_at(line, col)` checks cursor position and visibility in the input's scroll range. The comment in `select_block` notes it works reliably only before the input multiline buffer is activated (before Escape is pressed) — a known limitation tracked in issue #117.

**`mock.lua`** — `mock_love(t)` injects a minimal `love` global. `mock.keystroke(keystr, press)` parses strings like `"C-return"`, `"S-escape"`, `"M-up"` (prefixes: `C`=Ctrl, `S`=Shift, `M`=Alt) into modifier state + key call. Primary driver for all editor and input tests.

**`testutil.lua`** — Shared constants: `wrap=64` (screen width, matching the code convention line limit), `LINES=16` (buffer display height), `SCROLL_BY=8`. `get_save_function(init)` returns a save callback paired with a `reftable` handle — the same callable-table-as-mutable-reference pattern used by `user_input()` handles in project code.

**`input_fixture.lua`** (`tests/helpers/input_fixture.lua`) — full input standup for the `#input` contract suite (Compy input API, 1.0.0-rc20260712). Stands up the REAL `love.handlers` gate over a REAL `ConsoleController` (gfx/font stubbed, never a real display), the persistent singleton input widget exactly as `main.lua` wires it, and the click/update path — module-level, once, shared across the whole spec file. Exposes `F`: `F.activate_project(natives)` drives the real project-activation path (`Controller.set_user_handlers`) and returns the project-facing `compy.input` surface; `F.compy_input()` resolves the same surface a project sees; `F.show_widget(opts)` / `F.show_selectable_widget(lines)` activate the singleton or a selection-enabled widget; `F.session` is the keypress-level driver (see below); `F.reset()` (called `before_each`) stops the real project route, then clears fixture state. Consumed, never copied — the ~175 lines of MVC/gfx/font boilerplate this replaces used to live inline in the spec file.

**`input_session.lua`** (`tests/helpers/input_session.lua`) — the keypress-level driver `input_fixture.lua` builds `F.session` from. One emitter per gateway entry (`press`, `repeat_press`, `release`, `type`, `mousepressed`, `mousereleased`, `touchpressed`), each firing a REAL event through `love.handlers.*` — never straight into a controller — so a contract test exercises the same path a keystroke takes from LÖVE. Distinct from `EditorSession`: that helper bypasses the `love` slots and drives `EditorController` directly, below the gate.

---

## Coverage Map

### Well covered

| Area | Spec files |
|---|---|
| Utilities | `util/string_spec`, `table_spec`, `dequeue_spec`, `range_spec`, `tree_spec`, `class_spec`, `wrap_spec`, `termcolor_spec`, `debug_spec`, `fs_spec`, `mock_spec` |
| Interpreter pipeline | `parser_spec`, `chunker_spec`, `analyzer_spec` (incl. `ast_to_src`), `ast_spec`, `eval_spec`, `error_spec`, `markdown_spec` |
| Editor model + view | `buffer_spec`, `chunker_spec`, `editor_spec`, `visible_content_spec`, `visible_structured_content_spec` |
| Input widget | `input_text_spec`, `cursor_spec`, `history_spec`, `input_spec`, `user_input_model_spec`, `user_input_view_spec` |
| Input routing / dispatch contracts (Compy input API) | the `input_*_spec.lua` contract suite (`#input`; see Input Contract Suite below), `keys_pressed_spec` |

`analyzer_spec.lua` tests `parser.ast_to_src` — the pretty-printer central to the editor submit pipeline. It is the primary executable specification for that function's formatting behaviour.

### Not covered

| Area | Notes |
|---|---|
| `ConsoleController` | Deeply coupled to LÖVE2D runtime state; exercised by harmony integration tests instead. The input contract suite now stands up a REAL instance (gfx/font stubbed) as its routing target, but only its input-routing role is exercised — its own save/restore/snapshot behaviour is not |
| `Controller.lua` | Draw override detection. Click detection timer + handler registration are now covered by `input_shortcuts_click_spec`'s "framework click detection" and the `input_events_spec` rows |
| `ProjectService` | File I/O, project open/create, filesystem mount |
| `SearchController` | Editor Search is characterized through Ctrl+F, typed text, Enter jump, and Escape in `editor_spec`; it is an editor contract, not project input API |
| `SearchModel` | Narrowing and selection scroll have no direct unit tests |
| Drawing system | Depends on LÖVE2D graphics context |
| Views (rendering) | Expected; view testing requires LÖVE2D |

---

## Input Contract Suite (Compy input API)

The `#input` contract suite originally lived in one large file (`input_contracts_spec.lua`); in validation it was split along cognitive seams into ten `input_*_spec.lua` files under `tests/input/`: `input_routing_spec` (which route an event reaches), `input_events_spec` (the dispatch chain and consumption), `input_shortcuts_click_spec`, `input_widget_lifecycle_spec` (show/hide/reset), `input_route_lifecycle_spec` (connect, disconnect, teardown, `compy.before_exit`), `input_lifecycle_uniform_spec` (Enter and Escape mean the same thing in every surface), `input_widgets_callbacks_spec` (widget outputs, submit and cancel), `input_cursor_text_spec`, `input_reconfigure_spec`, and `input_nfr_forward_spec`. Each carries the file-level `#input` tag and builds the shared `input_fixture` from a `setup()` hook (torn down in `teardown()`, reset per test in `before_each`) — so every file is runnable standalone. The suite enforces the input contract — every test tracing to a corpus clause cited in a comment (never in the test description). It drives the real production path throughout: the REAL `love.handlers` gate, a REAL `ConsoleController`, and the real project-activation call (`Controller.set_user_handlers`) via the `input_fixture`/`input_session` helpers described above — never a spy on an internal method except one deliberately-noted sink-signature row.

Nearly every row is a behaviour contract, asserted live. Two kinds of row are not, and `input_nfr_forward_spec.lua` collects both under headings that say so, precisely so nobody reads them as promises:

- **characterized behaviour** — factual today, with no stakeholder mandate to stay this way (e.g. `inspect` keeping the console's surface, the missing `wheelmoved` gateway entry). Asserted live, not pending, so an accidental change still fails the build while a deliberate one reads as expected.
- **mechanism / NFR guards** — identity, allocation and held-key-table checks that deliberately poke internals, which is what an NFR guard is for.

Tags beyond the file-level `#input`:

- `#legacy` (`input_shortcuts_click_spec`) — proves the retired poll-idiom globals (`user_input`, `input_code`, `input_text`, `write_to_input`, `validated_input`, and the debug-only `astv_input`) are gone as ordinary `nil` fields — no shim, no deprecation path. The replacement surface (`compy.input`) is exercised throughout the rest of the suite, so the "Not covered: `user_input` overlay API" row from an earlier version of this doc no longer applies.
- `#lifecycle` (`input_lifecycle_uniform_spec`) — the one-lifecycle claim: Enter submits and Escape cancels identically in the console, the editor and a project overlay.
- `#history` (`history_spec`) — history recall, including the console's Up-at-the-top recall through the real key path.
- `#disputable` (`input_shortcuts_click_spec`, `input_widget_lifecycle_spec`) — marks a contract whose *desirability* is contested even though the assertion is factually true. Two groups: global shortcuts fire without consuming the key, and the console line receiving what a hidden widget declined (recorded in `technical_debt/input.md`, "On the console route, a hidden widget's input falls to the console line").

**The 3 pending tests are named gaps, not failures.** `busted tests` reports `861 successes / 0 failures / 0 errors / 3 pending` (confirmed by a live run). Each pending row documents a cell in the mode × channel routing grid that is either out of the input API's scope or not black-box observable today:

| Location | Row | Why it's pending, not red |
|---|---|---|
| `input_routing_spec.lua:68` | `routes the key release to the console` | A key release carries no text, so console delivery has no observable mutation to assert on — only the project-route release is directly witnessed |
| `input_routing_spec.lua:144` | `routes the pointer to the editor` | The production editor widget disables selection, so pointer delivery has no observable outcome without extra scaffolding |
| `input_routing_spec.lua:214` | `touch reaches the active route` | Touch has no gateway entry yet; both the widget and route touch handlers are no-ops, so delivery isn't black-box observable. Greens when a touch consumer lands |

---

## Gaps — Areas Worth Filling

**SearchModel** narrowing (`Search:narrow` with case-insensitive substring match) and selection scroll could be unit-tested similarly to `history_spec`.

**Tag organisation** — `.busted` excludes `delay`-tagged tests by default. Tags in active use: `#parser`, `#chunk`, `#analyzer`, `#ast`, `#src`, `#editor`, `#input`, `#markdown`, `#visible`, plus `#legacy`, `#lifecycle`, `#history` and `#disputable` (across the `input_*_spec.lua` contract files; see the Input Contract Suite section above). No tests currently use the `delay` tag, so the exclude is defensive rather than active.
