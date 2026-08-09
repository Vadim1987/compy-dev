# S31 — Fable consultation: challenge the operational boundary

**Prompt of record** (hygiene c). Spawned 2026-08-09, session31, model **Fable**,
explicitly passed. Deliverable path:
`doc/development/wip/77-new-input-api/validation/reviews/S31-boundary-challenge-fable.md`.

---

You are consulting on a LÖVE2D/Lua project at `/repo` (branch
`feature/77-newapi-analysis-s20260615`, PR base `3256aac`). You are **not**
implementing anything. Your job is to **try to break one claim**.

## Tools available to you

- The **`lua-lsp` MCP server** — defs / refs / diagnostics / rename over a real
  AST of the `/repo` workspace. Use grep to find candidates, then the LSP to
  resolve a symbol and prove "who calls this". Lua is dynamically typed, so LSP
  refs can be **incomplete** — cross-check with grep, trust neither alone.
  (`sleep 1` after any `.lua` edit before querying — you should not be editing.)
- `git show 3256aac:<file>` reads the **PR base**. "Pre-existing" is a claim to
  check that way, and it has overturned conclusions in six consecutive sessions.
- `busted tests` runs the suite (955 / 0 / 0 / 3 expected). Read-only work; do
  not commit, do not push, do not edit source.

## Context you need

The feature adds a project-facing input API: `compy.input.hooks.*`,
`compy.input.shortcuts` (combo-string keyed), and `compy.input.keys_pressed`
(a read-only proxy over an **event-tracked** held-key set, written in exactly two
places — `src/controller/controller.lua` `handlers.keypressed` / `keyreleased`).

Before the feature, **all** modifier querying was **device polling**:
`Key.ctrl/alt/shift()` in `src/util/key.lua`, which are `love.keyboard.isDown`.

The two live on **different clocks**. The project overrides `love.run`
(`src/harmony/init.lua`, and LÖVE's own default does the same shape): the whole
OS event batch is pumped, *then* dispatched one event at a time. SDL updates its
key-state array during the pump. So a device poll taken while dispatching event 1
of N reports the state after event N — "a value from the future". This is
**structurally verified but never measured**; frequency is unknown.

The owner wants to **ship the project-facing input API now** and defer:
(i) rebuilding editor/console onto it, (ii) the polling problem and its
mitigation, (iii) `src/harmony` reconciliation (a dev-only automation harness
that fakes modifiers by patching `love.keyboard.isDown` and never puts them in
the event stream), (iv) a general staleness-recovery path for the held set.

## The claim you must attack

> **Every deferred item is purely *additive* under the shipped API surface.
> Shipping now therefore cannot force any of the shipped work to be redone.**

The sub-claims, as argued:

1. The shipped surface is `compy.input.hooks`, `compy.input.shortcuts` (combo
   strings), and `compy.input.keys_pressed` (a table of raw LÖVE key names → true).
2. A future **staleness reconcile** *writes to the same table*; the surface does
   not change.
3. **Enrolling editor/console later** means those sites *read the same table* at
   event time instead of polling. `find_shortcut` in
   `src/controller/projectInputController.lua` is deliberately written as a free
   function over plain tables + a widget reference so a non-project adopter can
   reuse it — the reuse seam is already designed in.
4. **Harmony** enrollment means harmony *feeds the same event stream* (push real
   modifier events instead of patching `isDown`). Harmony-side only; the API
   surface is untouched. `git diff 3256aac HEAD -- src/harmony/` is empty.
5. The pre-existing polled gates in the gateway (`controller.lua` — quickswitch
   Ctrl+T, Ctrl+Alt+R/P, Ctrl+Esc on keyreleased, the Ctrl+Shift+N debug hotkeys)
   are **verbatim pre-existing at `3256aac`** and sit **upstream of project
   dispatch**, so a wrong-clock false positive there can steal an event from a
   running project — but that is **today's behaviour**, not a regression the
   feature introduces.

## What would falsify it

Find any of these and say so plainly, with file:line evidence:

- A deferred fix that would **change the shape or semantics of
  `keys_pressed`** (e.g. requires counts instead of booleans, requires folding
  l/r modifier pairs, requires iteration the read-only proxy cannot provide).
- A deferred fix that would **change the combo-string vocabulary** or the
  shortcut table shape.
- A case where enrolling editor/console **cannot** reuse the event set and would
  force the project-facing dispatch to be rewritten.
- A way the **pre-existing** polled upstream gates interact with the **new**
  event-tracked path such that the combination is worse than either alone —
  i.e. the feature does make something worse, contradicting sub-claim 5.
- Anything in the shipped API that **assumes** the held set is reliable in a way
  that a later recovery path would have to break.

## Also judge, briefly

Two claims a previous session made that this session found **wrongly scoped** —
confirm or correct:

- It censused `Key.ctrl/alt/shift()` over the 5 controllers only (70 sites) and
  concluded "the platform contains **zero** frame-time or draw-time keyboard
  polls, so Decision 29 clause 3's justification is theoretical". A whole-`src`
  census finds **76**, six of them in `src/examples/`, and several **projects**
  do poll at frame time (`examples/pong/strategy.lua:35`,
  `examples/clock/main.lua:68`, `examples/maze/main.lua:517,564`). Also
  `src/examples/keyboard/input.lua:47` states it reads `INPUT.shift` **from
  draw**, resolving to `compy.input.keys_pressed`. Does that overturn the
  "theoretical" verdict?
- Is the seam between the polled tier and the event-tracked tier actually
  **clean**, given the pre-existing gates sit upstream of project dispatch?

## Output

Write your verdict to
`doc/development/wip/77-new-input-api/validation/reviews/S31-boundary-challenge-fable.md`.
Structure: **verdict on the claim** (holds / holds with conditions / breaks),
then each falsification attempt with evidence, then the two scoping judgements,
then anything you think the session is not seeing. Be concrete and cite
`file:line`. **If you cannot break the claim, say so** — a clean confirmation is
a useful result. Do not soften a real break to be agreeable, and do not
manufacture one to look thorough.
