---
description: Lua coding conventions for Compy IDE platform code
status: active
audience: developer
---
# Compy IDE Code Conventions

See `dev/docs/compy-lua-runtime.md` for Lua 5.1 specifics shared with
game code.

## Scope

- Applies to IDE-owned Lua under `repos/compy-ide/src/`, excluding
  `src/examples/**`, `src/lib/**`, and `src/util/string/**`.
- Applies to IDE developer utilities under `repos/compy-ide/util/**/*.lua`
  and `repos/compy-ide/doc/util/**/*.lua`.
- Game examples use `dev/docs/compy-lua-game-conventions.md`.

## Naming

- Module-level class globals use `PascalCase`: `EditorController`,
  `BufferModel`.
- Filenames use the existing `camelCase` platform style:
  `editorController.lua`, `bufferModel.lua`.
- Locals and methods generally use `snake_case`.
- Imported helper locals may use `ALL_CAPS` or `PascalCase`; `src/main.lua`
  uses `local OS = require("util.os")` and
  `local FS = require("util.filesystem")`.
- The codebase is descriptive, not aspirational; match the neighboring file.

## Classes

- Use `src/util/class.lua`.
- Construct classes with `class.create(constructor)`.
- Use `class.newclass(...)` when extending bases.
- Do not add a parallel OOP framework.

## Annotations

- LuaCATS / EmmyLua annotations are encouraged for public API surfaces.
- Common tags: `---@class`, `---@field`, `---@param`, `---@return`,
  and `---@alias`.
- Annotation coverage is not currently enforced.
- Calibration for coverage and naming checks is tracked in Beads.

## Shape

- Long methods are allowed when that matches the controller or model style.
- Parameter counts are descriptive, not capped; `BufferModel` has a
  seven-argument constructor path.
- Nested functions are allowed when scoped to a controller method or closure.
- Line length over 80 should be treated as a platform lint error once
  platform-mode linting lands.
- The game 64-character target is a voluntary convergence goal for platform
  files, not a platform rule.

## Third-Party Code

- Do not apply platform conventions to `src/lib/**`; those are vendored
  libraries.
- Do not apply platform conventions to `src/util/string/**`; that subtree is
  upstream string utility code.
- Coordinate upstream if either subtree genuinely needs a change.

## Linter Source

- `repos/compy-ide/util/lualint/`, when present, is IDE platform code.
- It may use `util.class`, LuaCATS annotations, and platform-length methods.
- It must not be held to game conventions.

## Testing

- Compy projects use automated tests sparingly.
- See `dev/docs/compy-testing-policy.md` before adding a new spec file.
