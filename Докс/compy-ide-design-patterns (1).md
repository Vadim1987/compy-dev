---
description: Lua design patterns for Compy IDE platform code
status: active
audience: developer
---
# Compy IDE Design Patterns

## Scope

- Applies to IDE-owned platform Lua under `repos/compy-ide/src/`, excluding
  `src/examples/**`, `src/lib/**`, and `src/util/string/**`.
- Applies to IDE developer utilities under `repos/compy-ide/util/**/*.lua`
  and `repos/compy-ide/doc/util/**/*.lua`.
- Games, IDE examples, and game templates use
  `dev/docs/compy-lua-game-patterns.md`, not these patterns.
- Shared Lua 5.1 runtime facts live in `dev/docs/compy-lua-runtime.md`.

## Mouse Pointer

- IDE platform code does **not** use the games' relative-mode pointer
  workaround for the Android system-bar edge reveal; the shell keeps the
  absolute pointer. That reveal is handled device-wide, tracked in Beads
  `compy-systembar-lockdown`. (Games' recipe, for reference only:
  `dev/docs/compy-lua-game-patterns.md` → Mouse Pointer.)

## Class Constructor

Calibrated against `repos/compy-ide/src/util/class.lua`.

```lua
local class = require("util.class")

local function new(dependency)
  local obj = { dependency = dependency }
  return obj
end

ExampleModel = class.create(new)
```

## Class With Bases

Calibrated against the `class.newclass(...)` support in `src/util/class.lua`.

```lua
local class = require("util.class")

local Base = class.newclass()

local function new()
  return Base()
end

ExampleController = class.create(new)
```

## Class Header

Calibrated against controller and model files that use LuaCATS annotations.

```lua
---@class ExampleController
---@field model EditorModel
---@field view EditorView
ExampleController = class.create(new)
```

## Method Signature

Use annotations when a method crosses a module boundary.

```lua
---Move the editor selection.
---@param dir integer
---@param by integer
---@return boolean moved
function ExampleController:move_selection(dir, by)
  return self.model:move_selection(dir, by)
end
```

## Nested Helper In Method

Use a nested helper when it captures controller state and has no use outside
the method.

```lua
function ExampleController:handle_key(key)
  local function apply(action)
    return action(self.model, key)
  end

  return apply(self.actions[key])
end
```

## Private Module Helper

Prefer a module-local helper when no controller state is captured.

```lua
local function normalize_key(key)
  return string.lower(key)
end
```

## Graphics Alias

The platform uses the same graphics alias as games.

```lua
local gfx = love.graphics
```

## Import Alias

Calibrated against `repos/compy-ide/src/main.lua`.

```lua
local OS = require("util.os")
local FS = require("util.filesystem")
```

## Anti-Patterns

- Do not invent a parallel OOP system; use `util.class`.
- Do not add new platform files under `src/lib/**`.
- Do not lint or reformat third-party libraries.
- Do not apply game-only limits to IDE controllers, models, or views.
