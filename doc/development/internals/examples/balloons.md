# balloons

<!-- authored By LLM; human-approved NOT YET -->

**Real-time typing game.** Balloons carrying words fall from the top of the screen; the player types the words to pop them before they reach the bottom.

## Architecture

Multi-file project (`config`, `challenges`, `stats`, `ui`, `helpers`). `main.lua` is thin orchestration — it wires together `love.draw` and `love.update` via hook tables.

```lua
hooks.draw = game_state_router(ui_renderers)
love.draw = hooks["draw"]
love.update = hook("update")
```

The state router pattern (`game_state_router`) dispatches draw/update calls to different handlers depending on `game_state` (`"loaded"`, `"active"`, `"finished"`). This avoids conditionals inside the per-frame functions themselves.

## Input

Uses `compy.input.*` **(supported since 1.0.0-rc20260712)**, wrapped by `terminal.lua`'s `terminal_init()` (called once, at `ui.lua` require-time, to build `ui.terminal`). `terminal_init()` activates the continuous-session idiom: `compy.input.after_submit = function() compy.input.show({}) end` (a **field-write**, not a `show{}` key) re-arms the overlay after every submit, and `compy.input.show({ on_text_entered = deliver })` starts the session. `deliver(text)` forwards each submitted line to whatever handler `terminal_set_handler(handler)` last installed — `main.lua`'s `game_init()` wires this to `game_state_router(on_input)`, which dispatches by `game_state` to `game_validate_input` (`"active"`) or `game_command` (`"loaded"`/`"finished"`), the same way `hooks.update`/`hooks.draw` are dispatched. `game_validate_input` checks the submitted text against the active challenge. Live prompt changes go through `ui_draw_hint()` → `ui.terminal.write(hint)` → `terminal_write(msg)` → `compy.input.configure({ prompt = msg })` — a live-reconfigure, not a new `show`.

See [Compy Input API](../../../input_api.md) for the general usage pattern. The old `user_input()`/`input_text()` polling API is **(deprecated, removed in 1.0.0-rc20260712)**.

## Points of attention

- `game_state` doubles as both game FSM state and the dispatch key for `on_tick` / `on_input` maps. Adding a new game phase requires entries in both maps.
- The `hooks.update` function is a closure that holds both the state updater and the input reader — be careful if extracting these.
- `sfx.gameover()` / `sfx.correct()` etc. come from `compy.audio`.

## Files

`src/examples/balloons/` — main.lua, config.lua, challenges.lua, stats.lua, ui.lua, helpers.lua, debugfunc.lua, colors.lua, parameters.lua, tasks.lua, terminal.lua
