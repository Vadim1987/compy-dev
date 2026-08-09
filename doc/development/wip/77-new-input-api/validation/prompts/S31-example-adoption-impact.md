# S31 — per-example adoption impact census

**Prompt of record** (hygiene c). Spawned 2026-08-09, session31, model **Opus**,
explicitly passed (judgement-bearing: it must *judge* impact, not merely count).
Deliverable: `doc/development/wip/77-new-input-api/validation/outcomes/S31-example-adoption-impact.md`.

---

You are auditing a LÖVE2D/Lua project at `/repo` (branch
`feature/77-newapi-analysis-s20260615`, PR base `3256aac`). **Read-only**: do not
edit source, do not commit, do not push, do not run the app.

## Why this exists — the owner's metric

A new project-facing input API is about to ship. The owner has ruled that **the
net impact of adoption across the bundled examples is what characterises the
quality and usefulness of the feature.** Their categories, verbatim in substance:

- **Positive** — adoption *simplifies* the example's code, or *increases its
  stability / correctness*.
- **Negative** — adoption brings *unjustified complication* or *destabilisation*;
  this argues strongly against adopting.
- **Mild negative (overhead)** — adoption done *solely* to stop the example
  breaking, with no impact benefit of its own.
- **Bad outcome** — shipping the API while leaving examples *broken* or
  *not improved*.

Not all examples are equal: **`keyboard` and `maze` are primary student-facing
features.** Breaking those defeats the delivery. Less important examples *may* be
temporarily broken **if** they are eventually fixable **and** the platform-level
benefit (stability, removing accidental complexity) outweighs deferring the fix.

Your census is the evidence base for that judgement. **You do not make the
ruling** — you produce the per-example impact assessment the owner rules from.

## The API being shipped

- `compy.input.hooks[event]` — one hook per event (`keypressed`, `textinput`,
  `keyreleased`, pointer channels…). Third hook argument is LÖVE's `isrepeat`.
- `compy.input.shortcuts` — per-event tables keyed by **combo strings**
  (`'ctrl+s'`, `'alt+*'`, `'ctrl+*'`); shortcuts run **ahead of** hooks; a
  shortcut consumes by returning truthy.
- `compy.input.keys_pressed` — a read-only proxy over the framework's
  **event-tracked** held-key set (raw LÖVE key names → `true`). Readable
  **outside an event**, e.g. from `draw`.
- Reference: `doc/input_api.md` and `doc/development/internals/user_input.md`.

**Backward compatibility, already verified — build on it, but re-check it:**
`seed_hooks` (`src/controller/projectInputController.lua:65-71`) seeds a
project's own `love.keypressed` / `love.textinput` / … into `hooks[event]` when
the project set no explicit hook. So a legacy example that defines plain `love.*`
handlers appears to keep working untouched. **Confirm or refute this**, and find
any case where it is *not* true.

The pre-feature mechanism was **device polling**: `Key.ctrl/alt/shift()`
(`src/util/key.lua`, i.e. `love.keyboard.isDown`) and direct
`love.keyboard.isDown`. Both still work and are not being removed.

## The examples

Tracked in this repo, under `src/examples/`: `clock`, `guess`, `life`, `paint`,
`pong`, `repl`, `sapper`, `sine`, `tixy`, `turtle`, `valid`.

**Untracked nested repos** (separate git repos with their own remotes — read them,
never commit in them): `src/examples/keyboard`, `src/examples/maze`,
`src/examples/balloons`.

## What to produce, per example

A row with:

1. **Input surface used today** — which of: `love.*` handlers, `Key.ctrl/alt/shift()`,
   direct `love.keyboard.isDown`, `compy.input.*` (already adopted), mouse/touch,
   or none. Cite `file:line`.
2. **Timing class of every non-event read** — is the poll taken at **frame time**
   (`love.update`), **draw time** (`love.draw`), or **event time** (inside a
   `love.keypressed`/`keyreleased`/`textinput` handler)? **Resolve this by
   following callers, not by where the function is defined** — a previous pass
   got two of four wrong exactly that way (`clock/main.lua:68` and
   `maze/main.lua:564` are event-time despite looking like polls;
   `pong/strategy.lua:35` and `maze/main.lua:517` are genuinely frame-time).
3. **Does it break if the API ships and this example is NOT adapted?** Yes / no /
   already broken. If yes, name the mechanism and the `file:line`.
4. **Impact of adopting**, in the owner's four categories above, with the
   reasoning made concrete: *what lines would be deleted*, *what would get
   simpler*, *what correctness bug would be fixed or introduced*. Estimate the
   size of the change (lines added / removed, roughly).
5. **Verdict:** adopt / leave as-is / adopt-later, and **why in one sentence**.

Pay particular attention to the case where **leaving it alone is right**:
continuous, level-triggered reads (e.g. holding a key to move a paddle every
frame) are a legitimate use of device polling that events serve badly. An example
that correctly *should not* adopt is a valuable finding, not a gap — the API's
documentation is stronger if it can point at one.

`keyboard` and `maze` deserve the deepest treatment; both are known to contain
in-project machinery that duplicates platform mechanisms
(`maze/main.lua:516-526 poll_tab_progression` hand-rolls edge detection over a
device poll from `love.update`; `keyboard/input.lua` carries `spendGlyph`,
`GLYPH_CLAIMED`, `INPUT.upRecent`, `INPUT_UP_GRACE`). Quantify what adoption
would subtract from each.

## Tools and discipline

- The **`lua-lsp` MCP server** is available: defs / refs / diagnostics over a real
  AST of `/repo`. Grep to find candidates, then LSP to resolve a concrete symbol
  and answer "who calls this". Lua is dynamically typed, so LSP refs can be
  **incomplete** — cross-check with grep, trust neither alone. It also cannot
  disambiguate a method name shared across tables. (`sleep 1` after any `.lua`
  edit before querying — you should not be editing.)
- `git show 3256aac:<file>` reads the **PR base**. Any "this is pre-existing"
  claim must be checked that way.
- `busted tests` runs the platform suite (955 / 0 / 0 / 3). The nested example
  repos have **no suite** — reasoning there is unproven by construction, and you
  must say so rather than implying test-backed confidence.
- Verify every claim in code before writing it down. Where you are inferring
  rather than verifying, **mark it as inference**.

## Output

Write the deliverable to
`doc/development/wip/77-new-input-api/validation/outcomes/S31-example-adoption-impact.md`.
Lead with a **summary table** (example / surface today / breaks if unadapted /
impact of adopting / verdict), then the per-example detail, then a short closing
section: **which examples make the feature look good, which make it look like
overhead, and any example whose correct answer is "do not adopt"**. The file is
the deliverable — your final chat message is discarded.
