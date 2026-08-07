# S28 — sub-agent prompt of record: smoke findings SM3/SM4/SM5, from code

Spawned: 2026-08-07, session28, P9. Model: **Sonnet** (explicit).
**Analysis only — do not edit any file except the deliverable.** The owner has
explicitly said they do not expect the app to be run: diagnose from the
description plus the code, propose fixes, and they will smoke-test later.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1) — "compy", a small self-contained
computer with a console, an editor and projects that run inside it. It is
finishing a **new input API** for a PR. Under that API a project binds input in
three ways:

- `compy.input.shortcuts[event][combo]` — a combo is modifiers plus one trigger
  (`'ctrl+s'`, `'ctrl+alt+up'`), or modifiers plus `'*'` for the whole class
  (`'alt+*'`). Serialisation and normalisation live in `src/util/key.lua`.
- `compy.input.hooks[event]` — one handler per event, receiving **LÖVE's own
  argument list** (`keypressed(key, scancode, isrepeat)`).
- the input widget — a terminal consumer that gets the event when it is shown.

The dispatch chain is `shortcuts → hooks → widget`, first truthy return
consumes; `src/controller/projectInputController.lua` is the whole of it, and
it is short — read it first, it will save you time.

Three example projects live in **nested git repositories** under
`src/examples/`: `balloons`, `maze`, `keyboard`. They were migrated to the new
API. **They are separate repos with their own remotes.** You may read them
freely. Do not commit, do not push, do not edit them.

## The findings, in the owner's own words

From a manual smoke test (`validation/reviews/S26-TF2-smoketest-results.txt`):

> **B3.** maze works ("Ctrl" shadows the screen", when project is launched from
> another project navigation symbols are glitchy). works through levels 1-3
> (real-time movement) and starting from level 4 (interactive prompt, hides when
> idle)

> **B5.** keyboard works *mostly* (including menu and help), except two paths
> never tested before — switching difficulty by Ctrl+Alt+`<arrow>`, and subgame
> #4 "alt keys" — it shows lowercase 'k' or 'q' and then does not react when I
> press this symbol (however when I press shift visual representation of
> keyboard changes)

Filed as:

- **SM3a** — maze: navigation symbols glitch when the project is launched **from
  another project** (not as the first project after boot). **The owner's
  hypothesis, to test before assuming a routing bug:** maze switches fonts, and
  the switch probably only takes effect on a first start, not after another
  project has run. Look for font state that survives a project stop.
- **SM3b** — maze: holding Ctrl alone dims/shadows the screen. Owner suspects
  this is maze's own UX bug rather than the platform. Not critical, but it must
  be **explained**, not left as a mystery.
- **SM4** — keyboard: the Ctrl+Alt+`<arrow>` difficulty switch does nothing.
  Suspected combo-serialisation gap: a **three-token combo** (two modifiers plus
  a trigger). This is a platform-behaviour suspicion, not an example bug, until
  proven otherwise.
- **SM5** — keyboard: subgame 4 "alt keys" displays a letter and does not react
  when that letter is pressed — but pressing Shift **does** change the on-screen
  keyboard, so *some* input is arriving.

## What to do

For **each** of the four, work from the code to a specific, falsifiable cause:

1. Find the code that implements the feature (the example's own binding, and the
   platform code it depends on).
2. State what the code actually does on the described input, step by step, from
   the LÖVE event to the effect. Name file:line at each hop.
3. Say what is wrong, or say clearly that **you could not find a defect** — an
   honest "the code looks correct on this path, here is what I ruled out" is a
   result, and a fabricated cause is worse than none.
4. Propose a fix as a **diff or a precise edit description** (which file, which
   lines, what changes) — but **do not apply it**. Say whether the fix belongs
   to the platform (`/repo/src`) or to the example repo, and whether it is
   testable by the busted suite without a display.

SM4 deserves particular care: check whether `'ctrl+alt+up'` survives the round
trip through `src/util/key.lua` — registration normalisation, the modifier set
built at dispatch, arrow-key naming — and whether what the example registers is
what the dispatcher will look up. If the platform mishandles a two-modifier
combo, that is a **platform defect with a suite test owed**, and the most
valuable thing you can produce is the exact input that demonstrates it.

For SM5, work out what event the letters would arrive as (`keypressed` vs
`textinput`) and what the subgame is listening for. The Shift clue is
informative: something reaches the game, so the wiring is not dead.

## Tools and rules

- **The `lua-lsp` MCP server is available** — definition / references / hover /
  diagnostics over a real AST of `/repo`. Grep to find candidates, LSP to
  resolve them and to answer "who calls this".
- `busted tests` runs the suite (**953 / 0 / 0 / 3** right now) — you may run it
  to understand behaviour, but change nothing.
- **Do not run the app.** No `love`, no `xvfb-run`. The owner has excluded it.
- **Edit nothing** except your deliverable. No `git add`, no commit, no push,
  in this repo or the nested ones.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/outcomes/S28-smoke-analysis.md`**:
one section per finding, each with the trace (file:line hops), the verdict
(**PLATFORM DEFECT** / **EXAMPLE DEFECT** / **NOT REPRODUCIBLE FROM CODE**), a
confidence statement, the proposed fix, and whether a suite test can pin it.

Your chat reply should be a short digest: the four verdicts and anything you
could not determine.
