# Test Suite Review

<!-- authored By LLM; human-approved NOT YET -->

Assessment of `tests/` relative to the codebase and the knowledge base under `doc/development/`. Organised into: relevant infrastructure, coverage map, gaps.

---

## Test Infrastructure Worth Knowing

**`EditorSession`** (`tests/helpers/editor_session.lua`) — A keystroke-driven test harness for the editor. Drives `EditorController` via simulated key events. Key methods: `open(src, nb)` asserts block count on open; `select_block(n)` navigates to block n; `select_and_open_block(n)` selects and presses Escape (asserts `buffer.loaded == n`); `submit(newtext)` alters input and sends Return; `assert_cursor_at(line, col)` checks cursor position and visibility in the input's scroll range. The comment in `select_block` notes it works reliably only before the input multiline buffer is activated (before Escape is pressed) — a known limitation tracked in issue #117.

**`mock.lua`** — `mock_love(t)` injects a minimal `love` global. `mock.keystroke(keystr, press)` parses strings like `"C-return"`, `"S-escape"`, `"M-up"` (prefixes: `C`=Ctrl, `S`=Shift, `M`=Alt) into modifier state + key call. Primary driver for all editor and input tests.

**`testutil.lua`** — Shared constants: `wrap=64` (screen width, matching the code convention line limit), `LINES=16` (buffer display height), `SCROLL_BY=8`. `get_save_function(init)` returns a save callback paired with a `reftable` handle — the same callable-table-as-mutable-reference pattern used by `user_input()` handles in project code.

**`input_fixture.lua`** (`tests/helpers/input_fixture.lua`) — full input standup for the `#input` contract suite (feature #77). Stands up the REAL `love.handlers` gate over a REAL `ConsoleController` (gfx/font stubbed, never a real display), the persistent singleton input widget exactly as `main.lua` wires it, and the click/update path — module-level, once, shared across the whole spec file. Exposes `F`: `F.activate_project(natives)` drives the real project-activation path (`Controller.set_user_handlers`) and returns the project-facing `compy.input` surface; `F.compy_input()` resolves the same surface a project sees; `F.show_widget(opts)` / `F.show_selectable_widget(lines)` activate the singleton or a selection-enabled widget; `F.session` is the keypress-level driver (see below); `F.reset()` (called `before_each`) stops the real project route, then clears fixture state. Consumed, never copied — the ~175 lines of MVC/gfx/font boilerplate this replaces used to live inline in the spec file.

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
| Input routing / dispatch contracts (feature #77) | the `input_*_spec.lua` contract suite (`#input`; see Input Contract Suite below), `keys_pressed_spec` |

`analyzer_spec.lua` tests `parser.ast_to_src` — the pretty-printer central to the editor submit pipeline. It is the primary executable specification for that function's formatting behaviour.

### Not covered

| Area | Notes |
|---|---|
| `ConsoleController` | Deeply coupled to LÖVE2D runtime state; exercised by harmony integration tests instead. The input contract suite now stands up a REAL instance (gfx/font stubbed) as its routing target, but only its input-routing role is exercised — its own save/restore/snapshot behaviour is not |
| `Controller.lua` | Draw override detection. Click detection timer + handler registration are now covered by `input_shortcuts_click_spec`'s "framework click detection" and the `input_dispatch_chain_spec` rows |
| `ProjectService` | File I/O, project open/create, filesystem mount |
| `SearchController` | Editor Search is characterized through Ctrl+F, typed text, Enter jump, and Escape in `editor_spec`; it is an editor contract, not project input API |
| `SearchModel` | Narrowing and selection scroll have no direct unit tests |
| Drawing system | Depends on LÖVE2D graphics context |
| Views (rendering) | Expected; view testing requires LÖVE2D |

---

## Input Contract Suite (feature #77)

The `#input` contract suite for the new input API originally lived in one large file (`input_contracts_spec.lua`); in feature-#77 validation (TF1) it was split along cognitive seams into nine `input_*_spec.lua` files under `tests/input/`: `input_routing_spec`, `input_shortcuts_click_spec`, `input_widget_lifecycle_spec`, `input_nfr_forward_spec`, `input_dispatch_chain_spec`, `input_widget_io_spec`, `input_route_lifecycle_spec`, `input_cursor_text_spec`, and `input_reconfigure_spec`. Each carries the file-level `#input` tag and builds the shared `input_fixture` from a `setup()` hook (torn down in `teardown()`, reset per test in `before_each`) — so every file is runnable standalone. The suite enforces the input contract — every test tracing to a corpus clause cited in a comment (never in the test description). It drives the real production path throughout: the REAL `love.handlers` gate, a REAL `ConsoleController`, and the real project-activation call (`Controller.set_user_handlers`) via the `input_fixture`/`input_session` helpers described above — never a spy on an internal method except one deliberately-noted sink-signature row.

Tests carry four labelled organising buckets (in-comment labels; the file split largely follows them), so a reader can tell a stable guarantee from a forward-looking one at a glance:

- **A PRESERVE** — stable-now contracts, green today (e.g. routing exclusivity, widget activation/reset, hidden-widget non-consumption).
- **B IMPLEMENT** — forward contracts, carried `pending` until the named milestone lands.
- **C MECHANISM-GUARD** — NFR/object-lifecycle guards (identity, allocation, the held-key table), labelled so nobody mistakes internals-poking for a behaviour contract.
- **D CHARACTERIZE** — factual-today behaviour with no stakeholder mandate to stay this way; asserted live (not pending) so an accidental change still fails the build.

Tags beyond the file-level `#input`, matching implementation milestones:

- `#legacy` — proves the retired poll-idiom globals (`user_input`, `input_code`, `input_text`, `write_to_input`, `validated_input`, and the debug-only `astv_input`) are gone as ordinary `nil` fields (removed at 0.1.0-m8, M8-03) — no shim, no deprecation path. The replacement surface (`compy.input`) is exercised throughout the rest of the suite, so the "Not covered: `user_input` overlay API" row from the previous version of this doc no longer applies.
- `#m5c` — the four-tier dispatch chain (framework handler → combo table → generic `on_*` callback → sink) and the route connection lifecycle (connect/disconnect at the `running` boundary, full teardown at stop, `inspect`, `compy.before_exit`).
- `#m7` — the cursor/text surface (`get_cursor`/`set_cursor`/`set_text`) and live reconfigure/clear (`configure`/`clear`) on an active or hidden session.
- `#m8` — the continuous-session idiom (`on_text_entered` consumes and `after_submit` clears the next draft), the recipe every migrated example project (tixy, repl, guess, valid) relies on.
- `#editor` — one row testing editor-internal block navigation at the buffer limit; flagged in-file as owner-call territory for relocation to `tests/editor/`, kept for now as a regression guard.

**The 3 pending tests are named gaps, not failures.** `busted tests` reports `862 successes / 0 failures / 0 errors / 3 pending` (confirmed by a live run). Each pending row documents a cell in the mode × channel routing grid that is either out of #77's scope or not black-box observable today:

| Location | Row | Why it's pending, not red |
|---|---|---|
| `input_routing_spec.lua:80` | `routes the key release to the console` | A key release carries no text, so console delivery has no observable mutation to assert on — only the project-route release is directly witnessed |
| `input_routing_spec.lua:145` | `routes the pointer to the editor` | The production editor widget disables selection, so pointer delivery has no observable outcome without extra scaffolding |
| `input_routing_spec.lua:224` | `touch reaches the active route` | Touch has no gateway entry yet; both the widget and route touch handlers are no-ops, so delivery isn't black-box observable. Greens when a touch consumer lands |

---

## Gaps — Areas Worth Filling

**SearchModel** narrowing (`Search:narrow` with case-insensitive substring match) and selection scroll could be unit-tested similarly to `history_spec`.

**Tag organisation** — `.busted` excludes `delay`-tagged tests by default. Tags in active use: `#parser`, `#chunk`, `#analyzer`, `#ast`, `#src`, `#editor`, `#input`, `#markdown`, `#visible`, plus the feature #77 milestone tags `#legacy`, `#m5c`, `#m7`, `#m8` (across the `input_*_spec.lua` contract files; see the Input Contract Suite section above). No tests currently use the `delay` tag, so the exclude is defensive rather than active.
