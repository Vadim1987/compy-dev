# The P-18 gesture-parity harness — preserved, and runnable

This is the instrument behind session38's claim that the `keyboard` game's
gesture behaviour is identical to upstream. **It was not in the workspace.** It
lived only in a session-scoped `/tmp` scratchpad from 2026-08-12 and was one
cleanup away from gone, taking the reproducibility of the claim with it — copied
here by session43 (P-20-01) with the absolute `dofile` paths made relative.

## Running it

```
cd doc/development/wip/77-new-input-api/validation/notes/S38-parity-harness
luajit run_up.lua  > /tmp/up.txt     # upstream input.lua, verbatim at 025e858
luajit run_new.lua > /tmp/new.txt    # the live /repo/src/examples/keyboard/input.lua
diff /tmp/up.txt /tmp/new.txt        # expect zero diff over 108 stimuli
```

Re-run by session43 on 2026-08-16 against `keyboard` HEAD `e568961`: **108
lines each, zero diff.**

## What it proves, and what it does not

- `run_new.lua` drives the **real** `ProjectInputController`, the real
  `src/util/key.lua`, and the real `input.lua` from the game.
- It **bypasses** `love.event.push` → queue → `love.run` pump →
  `love.keypressed`, and the `with_canvas_and_errors` route boundary. It is a
  **dispatcher-level** parity proof, not an end-to-end one. Session38's review
  chain discloses this in three separate "Limits" sections; its report headline
  ("provably identical to upstream") does not.
- `drive_new.lua:9-27` **copies `combo_string` / `any_mod` verbatim** from
  `src/controller/controller.lua` instead of calling them. Verified identical to
  production on 2026-08-16 (`controller.lua:382-424`) — faithful today, but a
  copy, so a future change to the production builder will not show up here.
  Check that first if this harness ever disagrees with the app.

`up_base.txt` / `new_f4.txt` are the session's own recorded outputs, kept for
comparison.
