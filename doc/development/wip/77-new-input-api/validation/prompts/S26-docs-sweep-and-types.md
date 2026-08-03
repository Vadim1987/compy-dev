# Sub-agent prompt — S26 doc sweep + types.lua (Sonnet)

Model: **sonnet** (explicit). Task: mechanical, scoped. Judgment documents
(`decisions/input.md`, `doc/input_api.md`, `technical_debt/input.md`) are NOT
yours — the parent session handles those.

## Context you need (do not re-derive)

The compy input subsystem was just unified. What changed, all landed:

1. Pointer events (`mousepressed`, `mousereleased`, `mousemoved`,
   `wheelmoved`, `touchpressed`, `touchreleased`, `touchmoved`) now run the
   SAME dispatch chain as keyboard events, through
   `ProjectInputController`. Previously the gateway broadcast them: the
   widget got the event first, then the project's handler unconditionally,
   and neither could stop the other.
2. Consequences: delivery order flipped (project hook first, widget LAST as
   the chain's terminal); a pointer hook can now CONSUME by returning truthy;
   pointer has NO shortcuts tier and no combo trigger, so it enters the walk
   at the hook tier.
3. `compy.singleclick` / `compy.doubleclick` are REMOVED. Single and double
   clicks are still synthesised by the framework's click timer, but are now
   EMITTED as ordinary events through `love.handlers.singleclick(x, y)` and
   reached via `compy.input.hooks.singleclick` / `.doubleclick`.
4. The project route is no longer released at `running -> project_open`.
   Every channel now has ONE lifetime and is released at the project's stop.
5. Pointer payloads are exactly LÖVE's own arguments — no held-key view is
   appended.

## Your tasks

### A. Doc sweep (4 files)

- `doc/development/internals/user_input.md`
- `doc/development/internals/examples/paint.md`
- `doc/development/internals/examples/sapper.md`
- `doc/development/internals/examples/index.md`

Find every passage made false by the five points above and correct it.
`grep -n 'singleclick\|doubleclick\|broadcast\|pointer\|mouse' <file>` is your
starting point, but read enough surrounding text to judge — some passages
describe the OLD routing without naming it.

Rules:
- Correct statements of fact; do not restructure or "improve" prose.
- Keep each file's existing voice, heading style and citation conventions.
- Citations must point at persistent docs (`doc/…`), never at
  `doc/development/wip/…`.
- Lines: markdown here wraps at ~80; match the file you are editing.
- If a passage is now simply wrong and has no replacement, say so in your
  report rather than inventing a claim.

### B. `src/types.lua` (197 lines)

It currently declares `singleclick` / `doubleclick` on the compy class and
knows nothing of `compy.input`. Update it to describe the surface as it now
is. Read `src/controller/consoleController.lua` (`get_compy_input`,
`build_widget_api`, `build_input_surface`) for the real shape — do not guess.
Cover at least: `compy.input.show/hide/configure/is_shown/clear/set_text/
get_cursor/set_cursor`, `compy.input.shortcuts`, `compy.input.hooks`,
`compy.input.callbacks`, `compy.input.keys_pressed`, `compy.input.fn.*`, and
`compy.before_exit`. Remove the two click fields.

Lua lines are **≤64 characters, hard limit**. Verify with:
`awk 'length > 64' src/types.lua`

## Constraints

- `busted tests` must be **920 / 0 / 0 / 3** when you finish. Run it.
- Do NOT commit. Leave changes in the working tree; the parent commits.
- Do NOT touch: `doc/input_api.md`, `doc/development/decisions/input.md`,
  `doc/development/technical_debt/input.md`, anything under
  `doc/development/wip/`, or any file in `src/examples/`.
- Stage nothing. Never run `git add -A`.

## Tooling

An MCP language server for Lua (`lua-lsp`) is available: use
`mcp__lua-lsp__definition`, `references`, `hover`, `diagnostics` to resolve
symbols precisely instead of guessing from names. Grep to find candidates,
then the LSP to confirm. After editing a `.lua` file, `sleep 1` before asking
the LSP for diagnostics — it needs a moment to re-index.

## Deliverable

Write your report to
`doc/development/wip/77-new-input-api/validation/outcomes/S26-docs-sweep-and-types.md`:
what you changed per file and why, anything you found false but could not fix,
the final `busted` line, and the `awk` line-length check for `types.lua`.
