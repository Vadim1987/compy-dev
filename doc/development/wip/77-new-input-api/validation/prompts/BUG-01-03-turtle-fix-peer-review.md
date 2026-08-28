# Peer Review Request: BUG-01-03 / T-TURTLE-DUP Fix in turtle/main.lua

## Context & Mandate

You are a COLD peer-reviewer. You are evaluating a recent fix for defect `BUG-01-03` (`T-TURTLE-DUP` / `FIX-02-11`) in `src/examples/turtle/main.lua`.

Do NOT assume the fix is correct just because tests pass. Critically analyze the fix against design contracts, input API architecture, edge cases, and pre-existing project idioms.

## The Problem

`src/examples/turtle/main.lua` uses both native/hook key handlers (`love.keypressed`/`love.keyreleased`) and an input widget prompt (`compy.input.show{ prompt = "TURTLE", ... }`).

When the user activates the input prompt (by pressing `i`), the input widget is shown on screen.
Previously, `love.keyreleased` had an `is_shown` guard:
```lua
function love.keyreleased(key)
  if key == "i" and not compy.input.is_shown() then
    compy.input.show{ ... }
    return true
  end
end
```
However, `love.keypressed(key)` had no guard:
```lua
function love.keypressed(key)
  if Key.shift() then
    if key == "r" then
      tx, ty = midx, midy
    end
  end
  if key == "space" then
    debug = not debug
  end
  if key == "pause" then
    pause()
  end
end
```

Because the dispatch chain evaluates shortcuts (Tier 1) -> hooks / `love.*` handlers (Tier 2) -> input widget (Tier 3), any key press while typing in the shown text field evaluates Tier 2 (`love.keypressed`) first. Because `love.keypressed` returned `nil`/falsy, the event fell through to Tier 3 (the widget).
As a result, typing space inside the text field toggled `debug = not debug` in `turtle` while typing space, and typing `Shift+r` reset the turtle position while typing `R`.

## The Fix Applied

An `is_shown()` guard was added to `love.keypressed`:
```lua
function love.keypressed(key)
  if compy.input.is_shown() then return end
  if Key.shift() then
    if key == "r" then
      tx, ty = midx, midy
    end
  end
  if key == "space" then
    debug = not debug
  end
  if key == "pause" then
    pause()
  end
end
```

## Your Review Questions

1. **Correctness**: Does adding `if compy.input.is_shown() then return end` to `love.keypressed` cleanly resolve the double-handling issue without introducing new bugs or regressions?
2. **Completeness & Edge Cases**: Are there any remaining event handlers (e.g. `love.textinput`, mouse handlers, `after_submit`, echo guards) in `turtle/main.lua` or other migrated examples that suffer from a similar double-handling or leakage problem when the widget is active?
3. **Idiomatic Consistency**: Is this guard consistent with the input API architecture described in `doc/input_api.md` and test suite idioms in `tests/input/input_widget_control_spec.lua`?
4. **Tooling Hygiene**: Check with LSP (`lua-lsp` MCP server) if needed to verify symbol definitions and references. (Pause 1s after any edits if modifying files).

## Instructions

Write your detailed peer-review report to:
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/BUG-01-03-turtle-fix-peer-review.md`

State a clear verdict at the end: **APPROVE**, **APPROVE WITH COMMENTS**, or **REJECT / NEEDS REVISION**.
