# Examples — Index

<!-- authored By LLM; human-approved NOT YET -->

All examples live under `src/examples/`. Each is a self-contained project with a `main.lua`. They demonstrate different combinations of framework capabilities.

Detailed docs for each are in this directory. For the project-author usage guide to the input API used throughout this table, see [Compy Input API](../../../input_api.md).

Input mode column uses `compy.input.*` **(supported since 1.0.0-rc20260712)** throughout; the legacy `user_input()`/`input_text()`/`input_code()`/`validated_input()`/`write_to_input()` poll-a-reftable API is **(deprecated, removed in 1.0.0-rc20260712)**.

> REMARK: naming 'guess' as 'pen-and-paper' would be exagerration. its pure terminal, no drawing field at all. pen-and-paper idiom only relates to the games where some drawing happens -- but on virtul canvas and on demand, not every tick. So just "no drawing, pure terminal", or something like that. Same about repl.
> REMARK: "repl.. echoing whatever user types" -- obviously executing whatever user types, not echoing

| Example | One-line description | Draw mode | Input mode |
|---|---|---|---|
| [balloons](balloons.md) | Real-time typing game — pop balloons before they fill the screen | real-time `love.draw` | `compy.input.show{}` continuous session |
| [clock](clock.md) | Animated digital clock with randomised color cycling | real-time `love.draw` + `love.update` | keyboard (`love.keyreleased`) |
| [guess](guess.md) | Number guessing game with per-character validation | pen-and-paper (no `love.update`) | `compy.input.show{ validator = LineValidators(...) }` continuous session |
| [life](life.md) | Conway's Game of Life with mouse and keyboard controls | real-time `love.draw` + `love.update` | `love.keypressed`, `love.mousepressed` |
| [paint](paint.md) | Pixel paint app with palette, brush/eraser, and line weight | real-time `love.draw`, draws to own canvas | `compy.singleclick`, `love.mousemoved`, `love.keypressed` |
| [pong](pong.md) | Full Pong game with AI opponent and fixed-timestep physics | real-time `love.draw` + `love.update` | keyboard + mouse; selectable AI strategy |
| [repl](repl.md) | Minimal REPL — echoes whatever text the user types | pen-and-paper (no `love.update`) | `compy.input.show{}` continuous session |
| [sapper](sapper.md) | Minesweeper (pen-and-paper) with click-driven board | pen-and-paper | `compy.singleclick`, `compy.doubleclick`, `love.mousepressed` |
| [sine](sine.md) | One-shot sine wave plot drawn at init, no update loop | pen-and-paper (init only) | none |
| [tixy](tixy.md) | Live-coded pixel grid — edit the tixy formula in-app | real-time `love.draw` + `love.update` | `compy.input.show{ highlighter = LuaHighlighter, validator = LuaSyntaxValidator }` |
| [turtle](turtle.md) | Turtle-graphics interpreter driven by typed commands | real-time `love.draw`, draws trails | `compy.input.show{}` one-shot (on `i`) + `love.keypressed` |
| [valid](valid.md) | Validator showcase — collects user input with custom rules | pen-and-paper (no `love.update`) | `compy.input.show{ validator = LineValidators(...) }` continuous session |
