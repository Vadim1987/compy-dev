---
description: Cold peer review of the BUG-01-03 / T-TURTLE-DUP fix in src/examples/turtle/main.lua
status: outcome
audience: reviewer record
---

# Peer Review: BUG-01-03 / T-TURTLE-DUP Fix in `turtle/main.lua`

## Context

Reviewed cold, per
`doc/development/wip/77-new-input-api/validation/prompts/BUG-01-03-turtle-fix-peer-review.md`.
I did not read `ROADMAP.md`, `session56/track.md`, the technical-debt entries, or
`git show 71c8069c` — everything below is derived from `src/`, `tests/`,
`doc/input_api.md`, `doc/development/internals/user_input.md`, and
`doc/development/decisions/input.md` as read during this review.

Current state of the file (`src/examples/turtle/main.lua:33-46`):

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

`love.keyreleased` (`:80-94`) already carried an `is_shown()` guard before this
fix and is unchanged.

Test baseline reproduced: `busted tests` → **1011 successes / 0 failures / 0
errors / 10 pending**, matching the number stated in the review request. Run
under **LuaJIT** (`/usr/bin/luajit`, `busted 2.3.0`) — no PUC Lua interpreter
was found in this container (`lua` is not on `PATH`), so this is a
container-green result only; per standing project note, that does not
imply the same on the owner's own PUC-Lua machine.

---

## Q1 — Correctness

**Yes, for the two failure modes the report describes**, and cleanly:
placing `if compy.input.is_shown() then return end` as the function's first
statement means every other branch (`Key.shift()`+`r`, `space`, `pause`) is
unreached while the widget is up, with no partial execution or reordering
side effects. Verified by reading the full function body — nothing after the
guard has been touched.

**One real, unstated behaviour change, not called out anywhere in the fix's
own comments: `pause` goes inert too.** The guard is a single blanket
`return`, so it suppresses `key == "pause"` exactly as it suppresses `space`
and `shift+r` — but `pause` is not a text-producing key. LÖVE never fires
`textinput` for it (confirmed: it's a non-alphanumeric control key, no glyph),
so it cannot echo into the field and had no double-handling defect to fix.
Before this change, pressing the physical Pause key while the prompt was open
called the project's `pause()` global (`src/examples/turtle/action.lua:17-19`
→ `project_env.pause`, defined `src/controller/consoleController.lua:1145`) —
a legitimate, harmless action while typing. After this change, that no longer
happens: the ability to pause the run while the prompt is up has been
silently removed as a side effect of the blanket guard's shape, not as a
consequence of the actual defect. A narrower fix — guarding only the two
branches that read `key` values reachable via `textinput` (or moving `space`
and `shift+r` behind the guard while leaving `pause` outside it, or binding
`pause` as a `compy.input.shortcuts.keypressed['pause']` entry, which runs
*before* the widget regardless of shownness) would have fixed the reported
bug without this side effect.

This is not disqualifying — `pause`-while-prompt-open is a minor affordance,
not a documented contract — but it is a real, uncalled-out regression in
scope, and the review should say so plainly rather than wave it through as
"clean."

## Q2 — Completeness & Edge Cases

Checked every event surface `turtle/main.lua` registers:

- **`love.textinput`** — not defined in this file at all (confirmed by
  reading the full 101-line file and grepping for it). Nothing to guard.
- **Mouse handlers** — none defined (no `love.mousepressed` / `mousemoved` /
  etc. anywhere in the file). Nothing to guard.
- **`after_submit`** (`:70-73`) — runs only inside the widget's own
  `submit_flow` (`UserInputController:submit_flow`,
  `src/controller/userInputController.lua:438-453`), never through
  `love.keypressed`/`keyreleased`. It calls `compy.input.hide()` then
  re-arms the echo guard; unaffected by, and not in need of, the new guard.
- **The echo guard** (`arm_echo_guard`, `:55-61`) — a one-shot
  `compy.input.shortcuts.textinput['i']` entry. Shortcuts run *before* hooks
  and the widget (`doc/input_api.md:54-73`, Dispatch chain), so it is
  structurally immune to the keypressed/keyreleased double-handling class
  this bug is about; it addresses a different, already-solved problem (the
  trigger key's own echo — `doc/input_api.md`, "Worked example: the trigger
  key echoes into the widget it opened", `:648-678`).
- **`love.keyreleased`** (`:80-94`) — its only branch is already gated
  `if key == "i" and not compy.input.is_shown()`, functionally the same
  shape as the new keypressed guard (early-exit via the boolean, not an
  early `return`, but equivalent effect). Unchanged by this fix, and
  correct as-is.

Within this file, the fix is complete: nothing else was double-handling.

## Q3 — Idiomatic Consistency

**Yes — this is the framework's own documented and test-pinned idiom, not an
ad hoc symptom patch.**

- `doc/input_api.md:171-186` ("Live changes") gives almost this exact shape
  as the canonical use of `is_shown()`: guard a hook with
  `if key == 'i' and not compy.input.is_shown() then ... end`.
- `tests/input/input_widget_control_spec.lua:621-637` (`describe('is_shown()'`,
  case *"lets a project skip a redundant show"*) pins **exactly** the
  `if input.is_shown() then return end` early-exit shape at the top of a
  hook, with the comment "The guard the ruling asks an example to write."
  This is first-class, behaviourally-tested API guidance, not an
  improvisation local to turtle.

The reviewer's framing question — "is every migrated example required to
hand-write this guard?" — the answer, verified against the decisions doc, is
**yes, and that is a ratified, accepted trade-off, not a framework defect**:

- Decision 1 (`doc/development/decisions/input.md:93-110`): "Widget
  visibility is *state on the widget*, never a routing condition" — the
  chain cannot special-case a shown widget for you, by design.
- Decision 10 (`:406-436`), Consequence: *"Because project handlers fire
  while the widget is shown, the two examples that combined a project
  handler with widget solicitation changed behaviour and were migrated
  alongside the change. Breaking-and-fixing the affected examples was the
  explicit expectation, not a regression to avoid."*
- Decision 23 (`:790-822`) independently rejected a defaulting/no-op wrapper
  for a related reason ("whether a hook is set is information") — reinforcing
  that the framework deliberately does not paper over this for a project.

So: every example that keeps a native `love.keypressed`/`hooks.keypressed`
*and* shows the widget must hand-write this guard (or an equivalent — see
maze's alternative below), and that requirement is documented in
`doc/input_api.md` and pinned by a real test, not merely implied.

## Q4 — Tooling Hygiene (LSP)

- `mcp__lua-lsp__definition` on `UserInputController.is_shown` resolves
  cleanly to `src/controller/userInputController.lua:474-476`
  (`return self.shown`), matching Decision 18's contract that
  `compy.input.is_shown()` reads the widget's own internal flag.
- `mcp__lua-lsp__diagnostics` on `turtle/main.lua` returns 4 `duplicate-set-field`
  **warnings** for `draw`, `keypressed`, `keyreleased`, `after_submit`. I
  checked whether this is specific to the fix or pre-existing workspace
  noise: `grep -l "^function love.draw" src/examples/*/main.lua` shows
  `colors`, `keyboard`, `paint`, `turtle`, `life` all define a top-level
  `love.draw`. Every example is loaded by the LSP as one flat workspace, but
  each runs in its own sandboxed project environment at runtime and never
  coexists with another example's globals — so this is **pre-existing
  cross-file analysis noise inherent to the examples directory's layout**,
  not something this fix introduced and not a real duplicate-definition bug.
  Safe to disregard for this review; worth a standing note if the LSP's
  signal-to-noise on `src/examples/` ever becomes a real friction point.

---

## Stress-test points (per the review's own mandate, beyond the four questions)

### 1. The guard's cost

Turtle registers **no** `compy.input.shortcuts.keypressed[...]` entries
(confirmed: no `shortcuts` table access anywhere in the file), so tier 1
does not swallow `space`, `shift+r`, or `pause` before they reach
`love.keypressed`. The guard is the only thing standing between the widget
and these three branches.

- `space` produces `textinput(' ')` — the guard is necessary and correct.
- `shift+r` produces `textinput('R')` — the guard is necessary and correct.
- `pause` produces **no** `textinput` at all — the guard was not necessary
  for correctness and its inclusion here is a scope-creep side effect (see
  Q1). This directly answers the mandate's framing: yes, a working, harmless
  behaviour (pausing via the Pause key while the prompt is open) has been
  silently removed, and no upstream tier would have swallowed it anyway.

### 2. Idiomatic fix or symptom patch?

Idiomatic — see Q3. It is the API's own documented pattern
(`doc/input_api.md:171-186`) and is test-pinned
(`tests/input/input_widget_control_spec.lua:621-637`). The "tier 2 runs
before tier 3" ordering that makes the guard necessary is Decision 1's
deliberate, ratified shape (widget-shown-ness carries no routing weight), and
Decision 10's own consequence text says explicitly that migrated examples
combining a native handler with a shown widget were *expected* to need this
kind of fix. This is an accepted, documented trade-off, not a framework
defect and not a one-off patch invented for turtle.

### 3. No test proves this fix

Confirmed no test targets any example by name: `ls tests` shows no
`examples/` directory and no `*turtle*` spec exists anywhere under `tests/`.
This isn't specific to turtle — **no example in this codebase has direct
spec coverage**, which is consistent with (if unstated by) `agents/rules.md`'s
example-code-as-demonstration framing.

A test is feasible in principle: `tests/input/input_widget_control_spec.lua`'s
`F` harness (`tests/helpers/input_fixture.lua`) already drives exactly this
scenario generically — `F.session.press('i')`, `input.is_shown()`,
`F.session.type(...)` — for a *synthetic* hook (see the "is_shown()" and
"the documented echo guard" describe blocks). Extending that pattern to load
`turtle/main.lua`'s actual `love.keypressed`/`love.keyreleased` into a
project sandbox and asserting e.g. "space typed while the widget is shown
does not flip `debug`" would directly pin this fix. But doing so would be a
**new category of test for this codebase** — an example-under-test, not an
API-surface test — since no existing spec loads example source at all. Given
project convention ("report discovered non-blocking tech debt rather than
fixing it," `agents/development.md`), I'm flagging the absence as real and
the fix as feasible-but-untested, not asserting it should have blocked this
change.

### 4. Sibling examples

Checked every file under `src/examples/` that touches
`compy.input.show`/`hooks` (via grep, then read each candidate in full):

| File | Uses `show`? | Native `love.*`/hook handler? | Verdict |
|---|---|---|---|
| `guess/main.lua`, `repl/main.lua`, `valid/main.lua` | yes | none defined | no conflict — nothing to double-handle |
| `tixy/main.lua` | yes (widget shown at load, never hidden in-file) | `love.mousepressed` only | no `keypressed`/`textinput` handler exists, so the turtle bug shape doesn't apply; did not verify mouse-hook/widget-click interaction is fully harmless — lower confidence, out of this review's depth |
| `paint/main.lua`, `sapper/main.lua` | **no** `compy.input.show` anywhere in file | keypressed/mouse hooks defined | no conflict possible — no widget to double-handle against |
| `turtle/main.lua` | yes | `love.keypressed`/`keyreleased` | fixed by this change |

**Untracked directories** (`git status --porcelain` shows `balloons/`,
`keyboard/`, `maze/` as `??` — not committed to this repo's history, unlike
`turtle/`, which is clean/tracked):

- `balloons/terminal.lua` calls `compy.input.show`; grepped the *entire*
  `balloons/` tree for `love.keypressed`/`keyreleased`/`textinput`/
  `mousepressed` — none exist anywhere in the directory. No conflict.
- `keyboard/input.lua` uses `compy.input.hooks.*` exclusively and the
  directory contains no `compy.input.show`/`is_shown` call at all — the
  widget is never used, so there is nothing to double-handle.
- `maze/` (a large multi-file project) is the one place I found the *same
  shape* of risk, resolved by a **different mechanism**:
  `maze/core_editor.lua:59-74` already guards with an explicit
  `if compy.input.is_shown() then ... else open_editor(text) end` — same
  idiom as turtle's fix, pre-existing. But `maze/draw_main.lua:376-385` and
  `maze/maze_main.lua:233-242` register `compy.input.hooks.keypressed`
  functions that are **not** gated on `is_shown()` at all; they dispatch to
  a project-level `ctrl_pressed(key)` slot. Tracing the one path I found
  that opens the editor (`arm_editor`, `maze/core_editor.lua:146-150`), it
  sets `ctrl_pressed = nil` immediately before opening the field, so the
  hook's `elseif ctrl_pressed then ctrl_pressed(key)` branch is a no-op
  while editing — functionally the same isolation as an `is_shown()` guard,
  achieved through clearing a different piece of state instead. I did
  **not** exhaustively verify every path that can (re)open the editor
  preserves `ctrl_pressed == nil` (e.g. `reject_program` calls `set_prompt`
  directly rather than through `arm_editor`) — I could not rule out an edge
  case with turtle's original bug shape there. This is a genuine, if
  lower-confidence, open question, and it sits in code that is not
  currently part of this repository's tracked tree, so it's reported here
  as an FYI, not as something blocking this review.

---

## Anything else found

- The four `duplicate-set-field` LSP warnings (Q4) are pre-existing noise
  across the whole `src/examples/` tree, not introduced by this fix.
- `balloons/`, `keyboard/`, `maze/` are present in the working tree but
  untracked by git — worth flagging to whoever manages this branch, since
  it's easy to mistake "present on disk" for "part of the shipped example
  set" (I did, until I checked `git status`).
- The container's `busted` runs under **LuaJIT**, not PUC Lua — noting per
  standing project practice that container-green here doesn't by itself
  prove the same on a PUC-Lua target.

---

## Verdict

**APPROVE WITH COMMENTS.**

The fix correctly resolves the reported defect (`space` and `Shift+R`
leaking into the open text field), uses the framework's own documented and
test-pinned idiom for doing so, and is complete for every event surface this
file actually registers. Nothing about it is structurally wrong, and it
matches the accepted, ratified cost of the input API's design (Decision 1 /
Decision 10): a project combining a native handler with a shown widget must
guard itself.

Two comments, neither blocking:

1. The guard silently disables the Pause key's `pause()` action while the
   prompt is open — a real behaviour change with no textinput-collision
   reason to justify it, and not mentioned in the fix's own comments. Worth
   a one-line comment in the code (or narrowing the guard) so a future
   reader doesn't have to reconstruct why Pause stopped working while
   typing.
2. No test pins this fix, and none can, without introducing a new
   example-under-test pattern this codebase doesn't currently have anywhere.
   Flagged as non-blocking tech debt per project convention, not a reason to
   reject.

---

## Addendum — parent-session verification (session56, 2026-08-30)

*Not the reviewer's text. The charter requires the parent to verify a
sub-agent's factual claims in code before acting on them; this is that pass.
Everything above is left as delivered.*

**Confirmed in code:**

- The dispatch contract the review rests on is documented exactly as claimed:
  `doc/input_api.md:69` (*"The input widget, when shown, always consumes — it
  is the terminal consumer"*) and the tier diagram at `:320-322`. The section
  **"Why the widget sits at tier 3"** (`:333`) then puts the onus on the
  project in so many words — a shown field *"does not lock out your project's
  custom hotkeys or event guards unless your handlers explicitly allow them to
  fall through"*. So the guard is the shape the design asks for, not a patch
  over a framework defect. **Q3 stands.**
- `tests/input/input_widget_control_spec.lua:621-637` pins the identical
  `if input.is_shown() then return end` shape in a hook, with a comment naming
  it *"the guard the ruling asks an example to write"*. **Confirmed.**
- The container's `busted` runs on **LuaJIT 2.1** (`lua` is not on PATH at
  all). The reviewer's caveat is correct and is standing knowledge here:
  container-green is not the owner's-machine-green, which is PUC Lua.

**Corrected — the review's one substantive miss, and it defuses its own main
comment.** Q1 says the ability to suspend the run while the prompt is up *"has
been silently removed"*. It has not. `pause` is a **framework reservation**:
`ctrl+pause` → `reserved_suspend` → `CC:suspend_run(messages.user_break)`
(`src/controller/controller.lua:812-815, 868`), and reservations sit **above**
tier 1 and never consume, so they are unreachable by any project guard and
work while the widget is shown. The example's own bare `pause` key
(`project_env.pause` → `cc:suspend_run`, `consoleController.lua:1145`) is a
convenience duplicate of that reservation with a different message. What the
blanket guard costs is therefore the *shortcut*, not the *capability*.

**Disposition:** comment 1 is accepted as a **comment, not a narrowing** — the
guard stays blanket, and the consequence is written at the guard, where the
file already explains every other non-obvious line with a doc citation. That
also satisfies the standing directive that a behaviour change is never
documented in the commit message alone. Comment 2 (no test pins the fix) is
recorded as-is: examples carry no spec coverage anywhere in this codebase, and
introducing an example-under-test genre is out of scope for a defect row.

**Left open for the owner:** the reviewer could not fully trace `maze`'s two
hook sites (`draw_main.lua`, `maze_main.lua`), which neutralise via
`ctrl_pressed = nil` rather than an `is_shown` guard. `maze` is an untracked
nested repo and is covered by `ACC-02-04`'s smoke; not blocking here.
