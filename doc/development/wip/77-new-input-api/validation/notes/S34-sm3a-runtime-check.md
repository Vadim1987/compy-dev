# SM3a — the runtime check. The font hypothesis is NOT reproduced

**Session34, 2026-08-10.** A **diagnostic**, per session33's ruling: the deliverable is
confirming or killing the hypothesis, not a fix. Nothing was changed in the platform or in
maze; the instrumentation and the driver scenario were removed after the run and the tree is
back to where it started.

## The question

Session28 left SM3a open: *maze's nav symbols glitch when launched after another project*,
with an owner hypothesis that a font is not reset between consecutive project runs. Reading
the code could neither confirm nor refute it (`S28-smoke-findings.md`, SM3a) — there is no
explicit font reset between runs, which is consistent with the hypothesis without
demonstrating it. The named next step was to print the font identity at the start of two
consecutive maze runs with another project run in between.

## What the nav symbols actually are, and why the hypothesis was structurally plausible

The symbols are in `legend.txt` — `L:↺ R:↻ F:↑ B:↓` around a compass rose — loaded as
`LEGEND_FULL` (`constants.lua:59`) and drawn by `draw_legend` (`graphics.lua`). That function
takes the font from **`gfx.getFont()`**: maze never sets a font for the legend, so the glyphs
are rendered with **whatever font is current when the project draws**. Maze does create three
fonts of its own in `keyboard_graphics.lua`, but `draw_keyboard` **is never called anywhere in
maze** — that module's drawing side is dead code, and its fonts never reach the legend.

So the hypothesis was not a guess about an unrelated mechanism: the legend genuinely inherits
ambient graphics state.

## The check

Driven through **harmony** (`love src harmony`, under `xvfb-run -a`) — the only way to get two
project runs in one process. A temporary scenario ran: **maze → another project → maze**, each
started from the console with `run("…")` and ended with Ctrl+Q, printing at the first legend
draw of each maze run the font's identity, height, glyph coverage of `↺↻↑↓`, and the pixel
width of the legend string. Two intervening projects were tried, in separate runs:

- **turtle**, which never touches fonts;
- **clock**, which creates a **172px** font (`main.lua:32`) and sets it (`:49`) and never
  restores it — the sharpest available test of "the previous project leaves a font behind".

## Result — negative, and identically so both times

| | run 1 (maze first) | run 3 (maze after the other project) |
|---|---|---|
| font object | `Font: 0x…437e0` | **the same pointer** |
| height | 32 | 32 |
| `hasGlyphs("↺↻↑↓")` | true | true |
| legend width (px) | 216 | 216 |

Screenshots taken at both maze runs (harmony's own capture) are **byte-identical PNGs**, and
the legend renders correctly in both — compass rose, both rotation arrows, both direction
arrows. Under `clock`, the run that leaves a 172px font current, the result was the same.

**The hypothesis as stated does not reproduce here.**

## Why it is stable — the part worth keeping

Nothing in `stop_project_run` resets the font; session28 was right about that. What makes the
two runs agree is that **the console draws between them**, and the console's own draw path sets
its font every frame (`terminalView`, `util/view.lua`). Quitting a project always returns to
the console, so a project's first frame always inherits the console's font rather than the
previous project's. The stability is real but it is a **consequence of the return path**, not
a guarantee anyone stated — which is the honest reading of both this result and session28's
code-only pass.

## What this does not settle

- **The owner's observation is not explained.** It was made in the interactive app; this check
  drove the app synthetically through harmony's patched `love.run`. The draw path is the real
  one and the screenshots are real frames, but the input path is not.
- **Two intervening projects, not all of them.** Neither the owner's report nor session28 names
  which project preceded the glitchy maze run. `sapper`, `balloons` and `keyboard` also create
  and set fonts.
- **A different symptom may have been read as this one.** "Nav symbols glitch" was recorded
  second-hand; the legend is the only place maze draws those glyphs, and it draws them
  correctly here.

**Recommended disposition:** SM3a is **not confirmed, and not closed by this**. It costs
nothing to leave the observation on record as unreproduced; what it must not do is authorise a
state-reset fix, which is precisely the mistake session28 warned about (`wrap_handler`,
session26 — machinery changed because it looked like the cause).

## Reproducing it

The driver scenario, verbatim, in `src/harmony/scenarios/sm3a.lua` (temporary; deleted after
the run, along with the four-line print in maze's `draw_legend`). Harmony runs **every** file in
that directory, so the other four scenarios were moved aside for the run and moved back.

```lua
local h = love.harmony.utils or error()

local function sm3a()
  local function state()
    return tostring(love.state.app_state)
  end

  scenario('maze-font', function(wait)
    wait(.5)
    print('[SM3a] --- run 1: maze, first project of the process')
    print('[SM3a] state before run 1: ' .. state())
    h.love_text('run("maze")')
    wait(.5)
    h.love_key('return')
    wait(3)
    print('[SM3a] state during run 1: ' .. state())
    h.screenshot('maze-first')
    wait(1)
    h.love_key('C-q')
    wait(.5)
    h.release_keys()
    wait(2)

    print('[SM3a] --- run 2: clock, between the two maze runs')
    print('[SM3a] state before run 2: ' .. state())
    h.love_text('run("clock")')
    wait(.5)
    h.love_key('return')
    wait(3)
    print('[SM3a] state during run 2: ' .. state())
    h.love_key('C-q')
    wait(.5)
    h.release_keys()
    wait(2)

    print('[SM3a] --- run 3: maze again, after another project')
    print('[SM3a] state before run 3: ' .. state())
    h.love_text('run("maze")')
    wait(.5)
    h.love_key('return')
    wait(3)
    print('[SM3a] state during run 3: ' .. state())
    h.screenshot('maze-after-clock')
    wait(1)
    h.love_key('C-q')
    wait(.5)
    h.release_keys()
    wait(1)

    hm_done()
  end)
end

sm3a()
```

The instrumentation, in maze's `draw_legend` right after `local font = gfx.getFont()`:

```lua
  if not SM3A_SEEN then
    SM3A_SEEN = true
    print(("[SM3a] legend font=%s height=%s glyphs=%s width=%s")
      :format(tostring(font), tostring(font:getHeight()),
        tostring(font:hasGlyphs("↺↻↑↓")),
        tostring(font:getWidth(cur_legend))))
  end
```

## Two things that cost time and are worth knowing next time

- **`hasGlyphs` on the whole legend string answers `false`** — the string contains newlines and
  spaces, which are not glyphs. The first run of this check reported a false positive for the
  hypothesis for exactly that reason. Test the symbols, not the text.
- **Harmony holds a modifier until something releases it, and `love.event.push` is queued, not
  immediate.** Calling `release_keys()` on the line after `love_key('C-q')` clears `lctrl`
  *before* the queued keypress is dispatched, so the shortcut never sees Ctrl and the project
  never quits — silently, with the scenario continuing to type into a running project. Wait a
  beat between the combo and the release. This is a property of the harness worth carrying into
  P13, which owns harmony.
