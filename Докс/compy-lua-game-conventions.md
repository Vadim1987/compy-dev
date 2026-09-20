---
description: Lua coding conventions for Compy games and IDE examples
status: active
audience: developer
---
# Compy Lua Game Conventions

## Scope

- Applies to Compy games under `repos/games/`, `repos/compy-ide/src/examples/`,
  `compy/compy-product/games-bundle/`, and `dev/templates/compy-game/`.
- For Compy IDE platform code, use `dev/docs/compy-ide-code-conventions.md`.
- Shared Lua 5.1 runtime facts live in `dev/docs/compy-lua-runtime.md`.

## Source Of Truth

- The Compy IDE editor is the arbiter for accepted game Lua.
- The CLI linter mirrors editor errors and adds advisory warnings.
- Published code must round-trip through the IDE editor unchanged.

## Testing

- Compy projects use automated tests sparingly.
- See `dev/docs/compy-testing-policy.md` for the project consensus.

## Rules

| Rule | Example | Enforcement | Status |
| --- | --- | --- | --- |
| Line length is at most 64 characters. | `local x = WIDTH / 2` | IDE editor + linter `E002` after upstream PR | Partially implemented |
| Parseable Lua is required. | no `if then end` | IDE editor + linter `E001` | Fully implemented |
| Lua block body is at most 14 lines. | split drawing helpers | intended IDE editor rule + linter `W101` | Partially implemented |
| Function parameter count is at most 4. | use a table for grouped data | linter `W102` | Partially implemented |
| Nesting is at most 4 levels. | return early or name a condition | linter `W103` | Partially implemented |
| File-level variables are global; module-scope `local` is forbidden. | `gfx = love.graphics`, `BALL = { }` | linter `W104` | Partially implemented |
| Use conventional aliases. | `gfx = love.graphics` | linter `W107` | Partially implemented |
| Use `sfx` for `compy.audio` when audio is used repeatedly. | `sfx = compy.audio` | linter `W107` | Partially implemented |
| Empty table literal is `{ }`. | `POINTS = { }` | convention | Planned |
| Multi-line table literals use one element per line. | one row per value | convention | Planned |
| String literals use double quotes. | `"hi"`, not `'hi'` | convention | Planned |
| Comments live on their own line. | `-- draw player` | linter `W105` | Partially implemented |
| Use at most one blank line between code blocks. | one visual pause | linter `W106` | Partially implemented |
| Pull compound conditions into named locals. | `local hit = left or right` | linter `W108` | Partially implemented |
| Use `Color[...]`, not raw color numbers. | `gfx.setColor(Color[2])` | linter `W109` | Partially implemented |
| Avoid metatables. | plain tables only | linter `W110` | Partially implemented |
| Do not define `love.load`. | initialize at module scope | linter `W111` | Partially implemented |
| Use `snake_case` for variable names. | `cell_size` | convention | Planned |
| Use `camelCase` for function names. | `drawBall` | convention | Planned |
| Use `ALL_CAPS` for constants. | `WIDTH` | convention | Planned |
| Prefer `ALL_CAPS` descriptive names for global state tables; short or lowercase names are allowed (exempt from `W112`). | `BALL`, `GS`, `grid` | convention | Planned |
| One-character names stay in the allow-list. | `x`, `y`, `t`, `dt`, `r`, `i`, `j`, `k` | linter `W112` | Partially implemented |

## Runtime

- Target Lua 5.1 / LuaJIT-compatible syntax.
- Use `dev/docs/compy-lua-runtime.md` for version-specific quirks,
  dependencies, parse checks, and the Lua 5.1 Busted invocation.

## Bundled assets

- Standard bundled assets (audio via `sfx` / `compy.audio`, fonts) must
  ship with Compy-IDE. Call them directly (`sfx.match()`); never wrap
  a standard asset in an existence check or silent fallback. A missing
  standard asset is a packaging defect and must fail loudly, not degrade
  quietly.

## Editor Block Limit

- The 14-body-line limit is enforced when saving an edited block.
- Existing files created outside the editor may contain oversized blocks.
- Such blocks must remain loadable into edit mode so the user can repair them.
- Saving stays blocked until the replacement block is within the limit.
- Canceling the edit leaves the original block intact.

## Block Decomposition

- When a block exceeds 14 lines, split it into named sub-functions.
- If no reasonable split exists, move the body to its own `.lua` file
  loaded with `readfile`. This is always possible.
- A function declared as

  ```lua
  function foo(a, b, c)
    first(a)
    second(b)
    return third(c)
  end
  ```

  moves to `foo.lua`:

  ```lua
  local a, b, c = ...
  first(a)
  second(b)
  return third(c)
  ```

  and the original declaration becomes:

  ```lua
  foo = readfile("foo.lua")
  ```

- Replace a long table constructor with an empty `{ }` table populated
  one entry at a time.

## Root-Access Placeholders

- Mark every code site that needs a privileged platform operation with
  `-- TODO(root-access): <what the call will do>`.
- Current canonical case: disabling the built-in trackpad on program entry.
- When root access lands, grep the whole repo for `TODO(root-access)`
  and replace each marker with the real call. The marker is the
  cross-program enrollment list; do not invent per-program names for
  it.

## No File-Level Locals

- All file-level variables are global, including aliases, constants,
  helpers, and state.
- Module-scope `local` is forbidden.
- Exception: performance-critical or generated code may use `local`.
- Reason: a file command must behave the same as the same command typed
  at the Compy console, and the console must be able to inspect program
  state after loading.
- Existing example files may still use module-scope `local`; leave them
  until the block is refactored.

## Naming Migration

- `camelCase` for functions is canon; much existing code uses
  `snake_case`.
- Apply `camelCase` to new and refactored functions.
- Do not rename existing functions solely for style; rename when the
  surrounding block is refactored or when asked.

## Editor Parity Roadmap

| Rule | Meaning | Upstream status |
| --- | --- | --- |
| `W101` | Lua block body longer than 14 lines | editor bug: oversized blocks currently save |
| `W102` | function has more than 4 parameters | not started |
| `W103` | nesting deeper than 4 levels | not started |
| `W104` | module-scope `local` used for a file-level variable | not started |
| `W105` | inline comment | not started |
| `W106` | multiple blank lines | not started |
| `W107` | repeated API use without `gfx` or `sfx` alias | not started |
| `W108` | compound inline condition | not started |
| `W109` | raw numeric color in drawing API | not started |
| `W110` | metatable use | not started |
| `W111` | `love.load` defined | not started |
| `W112` | one-character name outside allow-list | not started |
