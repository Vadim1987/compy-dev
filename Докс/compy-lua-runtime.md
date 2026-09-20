---
description: Shared Lua 5.1 runtime and tooling reference for Compy game and platform code
status: active
audience: developer
---
# Compy Lua Runtime

## Target

- Write Lua 5.1 code that is LuaJIT-compatible.
- Do not use Lua 5.2+ language features.
- Use this doc for runtime facts shared by games and IDE platform code.

## Lua 5.1 Quirks

- No `goto`.
- No separate integer subtype; numbers are doubles, so `1` and `1.0`
  are the same value.
- No `//` integer-division operator; use `math.floor(a / b)`.
- No native bitwise operators in syntax; use the available `bit` or
  `bit32` library.
- No `\z` string escape.
- No `__pairs` or `__ipairs` metamethods.
- The `#` operator on tables with holes is implementation-defined.

## Libraries

- Prefer the standard Lua 5.1 library subset already used by the IDE.
- The IDE parser requires the `lua-utf8` rock, loaded as `lua-utf8`.
- Avoid adding runtime dependencies without a plan that covers the IDE,
  games, and device packaging.

## Tooling

- Parse-only smoke check: `luac5.1 -p <file>`.
- Lua 5.1 has no `lua5.1 -p` flag.
- Lua 5.1 Busted invocation:

  ```bash
  lua5.1 "$(luarocks --lua-version=5.1 config rocks_dir)"/busted/*/bin/busted <args>
  ```

- If more than one Busted version is installed in the Lua 5.1 rocks tree,
  replace the glob with the intended version directory.
- Installation and host-tool verification live in
  `dev/docs/compy-dev-toolchain.md`.
