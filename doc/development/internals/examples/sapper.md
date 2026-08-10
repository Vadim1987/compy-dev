# sapper

<!-- authored By LLM; human-approved NOT YET -->

**Minesweeper** implemented entirely in pen-and-paper mode. The board is drawn once at init and updated incrementally on each user action.

## Architecture

Single large file (~700 lines). No `love.draw` or `love.update` override. All game logic runs in the `compy.input.hooks.singleclick` / `.doubleclick` handlers, with the modifier-held variants registered as class shortcuts on the single-click channel (see "Click handling"). The terminal output is never used.

## Draw model

Drawing is event-driven: click a cell → the cell's appearance is redrawn in place. The full board is only redrawn on `actionInit()` (new game) and mode changes. Individual cell functions (`drawCellLocked`, `drawCellFlagged`, `drawCellUnlocked`, `drawCellBlown`, `drawCellExposed`) draw directly to the virtual canvas. The status panel is redrawn on every state change via `redrawStatus`.

This is a clean illustration of pen-and-paper mode: no wasted per-frame work, canvas retains state.

## Iterator pattern

Cell traversal uses closure iterators throughout:

```lua
function all_cells()
  local row, col = 1, 0
  return function()
    col = col + 1
    if config.cols < col then col = 1; row = row + 1 end
    if config.rows < row then return nil end
    return col, row
  end
end
```

`cell_filter(iterator, predicate)` wraps any iterator with a filter. `neighbors(i,j)`, `unlockable_neighbors(i,j)`, `all_mined_cells()` are all composed from these. No intermediate tables — pure iterator chaining. Good functional Lua pattern for students.

## Click handling

> REMARK: why not align the hooks assignment and set mousepressed via hooks or shortcuts? it makes sense to discourage using love.<event> path, while keeping it supported as backwards-compatibility layer

`compy.input.hooks.singleclick` → flag cell. `compy.input.hooks.doubleclick` → unlock cell (or restart if game over). The modifier-held variants — the alternative input for touch devices with no double-click — are `compy.input.shortcuts.singleclick['shift+*']` → flag and `['ctrl+*']` → unlock, both `fn.stop_here`, so the plain-click hook does not fire as well.

Those four handlers used to be two guarded hooks plus a `love.mousepressed`, each spelling out *this modifier and none of the other two*. A class key already means exactly that — `combo_string` folds every held modifier, so `'shift+*'` matches Shift and nothing else — so the guards were re-implementing the matcher and were removed with it.

**Two behaviour differences that came with the conversion, accepted deliberately** (they are why this is written down rather than left to the diff):

- **The modified clicks are now derived clicks.** They are button 1 only, counted on release, resolved after the double-click window has passed, and discarded if the pointer drifts between presses — the framework's own click synthesis. The removed `love.mousepressed` acted on **any** button, at press time, immediately.
- **An unclaimed modified click is no longer inert.** The old cascade's implicit *"every other combination does nothing"* has no shortcut expression: Alt-click, or Ctrl+Shift-click, now misses both class bindings and falls through to the plain-click hook, flagging a cell. Harmless in this game, and the alternative — re-growing a guard inside the hook — would keep the cascade the conversion exists to remove.

Mine placement uses probabilistic streaming: iterate all mineable positions once, at each position place a mine with probability `mines_remaining / cells_remaining`. No shuffle needed.

## Files

`src/examples/sapper/main.lua`
