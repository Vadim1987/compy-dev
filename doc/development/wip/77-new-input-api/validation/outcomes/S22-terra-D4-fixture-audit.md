# S22 D4 fixture audit

## Scope and method

Bounded audit of the D4 items named by
`validation/notes/S22-D4-behavioural-test-plan.md`: fixture
default-handler setup/reset and project activation. No production or test
Lua was changed and no test suite was run. Candidates were found with `rg`;
their concrete production counterparts and every `F.running_project` call
site were then cross-checked in code. The `lua-lsp` MCP tools are not exposed
in this agent session (tool catalogue had no Lua/LSP entry), so no AST query
was possible; grep plus the cited implementations is the backstop.

## Evidence and verdicts

| Fixture path | Production path / observable route | Verdict |
| --- | --- | --- |
| `tests/helpers/input_fixture.lua:150-161` installs six selected `set_love_*` functions. | `Controller.set_default_handlers(CC, CV)` at `src/controller/controller.lua:811-859` first deactivates `project_input`, installs the complete supported default event set, resets user-presence flags, and installs update/draw/quit. `ConsoleController:stop_project_run()` calls it with `self.view` at `src/controller/consoleController.lua:1126-1138`. | **Must change.** The fixture is an unjustified partial simulation of an available real entrypoint. Use `Controller.set_default_handlers(CC, CC.view)` after the real console view has been constructed. Keep only genuine LÖVE/graphics boundaries (`mock_love`, canvas/font/view stubs): they permit construction without a display, but do not simulate input routing. |
| `tests/helpers/input_fixture.lua:261-326` restores five callbacks, manually deactivates and clears the project route, wipes `compy.input` tables, and separately resets widget outputs. | The same complete lifecycle is production teardown: `ConsoleController:stop_project_run()` invokes `before_exit`, `set_default_handlers`, clears the active widget, calls `clear_user_handlers`, and reaches `reset_compy_input` / `reset_widget_outputs` at `src/controller/consoleController.lua:1126-1138` and `src/controller/controller.lua:1173-1180`. Feature lifecycle assertions already call that entrypoint in `tests/input/input_route_lifecycle_spec.lua:88-143`. | **Must change.** Replace the route/output portion of `F.reset` with `CC:stop_project_run()` while the prior run state is still intact; set the fixture's baseline state afterward and retain only test-owned cleanup (held keys, mock click timer, console/editor buffers, and mock globals). The current duplicated teardown can drift from the real stop path. |
| `tests/helpers/input_fixture.lua:235-239` sets the running state and calls `Controller.set_user_handlers(handlers, CC)`. | A real project run sets the state then reaches precisely that installer after user code executes in the private local `run_user_code` at `src/controller/consoleController.lua:108-135`; the installer is exposed as `Controller.set_user_handlers` at `src/controller/controller.lua:1136`. Tests then send real events through `love.handlers` via `tests/helpers/input_session.lua:1-34` and assert widget/project outcomes (for example `tests/input/input_events_spec.lua:31-36`). | **Retain, with a one-line mechanism reason.** It calls the real activation routing mutation and preserves controlled project-handler input. The only fuller route is private `run_user_code` plus project code loading/execution, which cannot practically isolate arbitrary handlers for these contract rows. The hand-set state is the minimal precondition, not a replacement dispatcher. |
| `tests/helpers/input_fixture.lua:227-230` assigns a callback directly to top-level `love[name]`. | Actual activation passes sandboxed project `love` handlers through `Controller.set_user_handlers`; keyboard/text are seeded into the project route and pointer handlers are installed by the same route (`src/controller/projectInputController.lua`, `project_handlers` / activation path). `F.running_project` is used by the four routing rows in `tests/input/input_routing_spec.lua:173-220` and the stop row in `tests/input/input_shortcuts_click_spec.lua:144-153`. | **Must change.** This bypasses the real project activation/route and is not needed: each row can call retained `F.activate_project({ [event] = fn })`, then drive the existing real `love.handlers` gateway. Remove `F.running_project` after migrating these five call sites. |

## Recommended execution

1. Add a breaking fixture/lifecycle test that distinguishes the real default/stop route from the old partial reset, then replace setup with `Controller.set_default_handlers(CC, CC.view)` and make reset enter through `CC:stop_project_run()` before test-only cleanup.
2. Migrate the five `F.running_project` users in `input_routing_spec.lua` and `input_shortcuts_click_spec.lua` to `F.activate_project({ [event] = fn })`; delete the obsolete helper.
3. Retain `F.activate_project`, but replace its review marker with the narrow mechanism justification above. Run `busted tests` after the change and record the result.

No broad fixture rewrite is recommended. Direct widget construction/showing, graphics stubs, and any unrelated D4 markers were outside this bounded audit.
