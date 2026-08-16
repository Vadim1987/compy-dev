# P-20-03 — sessions 40 and 41, cheap sweep

Done in-session by session43 (not delegated — three small diffs). **Verdict:
clean.** No finding at any severity.

## What landed, and whether it matches the claims

**`d77be355` — paint registers handlers as hooks (P16).** Two conversions:
`love.mousemoved` → `compy.input.hooks.mousemoved`, `love.keypressed` →
`compy.input.hooks.keypressed` (`src/examples/paint/main.lua:364,387`). The
mouse-button poll is retained, as the message says, and it is the right call —
it answers continuous drag state, which is a device question (Decision 32).

- Both names are real dispatched hook events — `EVENTS` at
  `projectInputController.lua:34-39` lists them and `dispatch` reads
  `hooks[event]` (`:135-139`). The conversion cannot have silently disconnected
  either handler.
- **The one thing worth checking was error semantics**, since a seeded
  `love.*` handler arrives through the caller's error-wrapped table while a
  directly-assigned hook does not. It is not a difference: the canvas/error
  boundary is applied **where the route is entered**, not per participant, and
  `controller.lua:155-171` names "a directly-assigned `hooks[...]`" as the exact
  case that boundary exists to cover. Same protection either way.

**`b33f9521` — turtle drops its duplicate Ctrl+Escape quit.** The claim is that
the framework keeps the release-side path and turtle had no distinct effect.
Confirmed: `handlers.keyreleased` gates `Key.ctrl()` + `escape` →
`love.event.quit()` (`src/controller/controller.lua:883-888`), it is the raw
pump entry so it runs before the route is forwarded to, and turtle's deleted
block was on `keyreleased` with the identical effect.

**`c08350e7` — sapper (P19).** One comment above the `singleclick` hook,
recording that delayed clicks sample modifiers on arrival rather than at press
(`src/examples/sapper/main.lua:672`). Matches the ruling the session reports,
and carries information the code cannot.

**P16's cold review was real:** `../prompts/S40-P16-cold-review.md` and
`../outcomes/S40-P16-cold-review.md` both exist, and its three documentation
findings were reconciled in `1f371d2d`.

## Not checked

Headless smoke launches for paint and turtle are claimed by both session
reports; not re-run here, since P-17/P-18 already establish that a container run
cannot inject a key or enter a game scene, which is what a smoke run would need
to prove anything beyond "it starts".
