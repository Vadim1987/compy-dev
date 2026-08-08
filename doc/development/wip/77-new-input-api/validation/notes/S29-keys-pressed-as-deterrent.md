# S29 — was `keys_pressed` the wrong instrument for discouraging `Key.*`?

Owner question, 2026-08-08. The intent behind exposing
`compy.input.keys_pressed` was twofold: give projects a **controllable** surface
for held keys, and **discourage** them from querying `Key.*` directly — because
that had been spawning cascades of C-style, if-dispatched code, where the wanted
shape was data-driven (shortcuts / combos).

**Answer: the instrument is right, but it was assigned a job it cannot do.** The
deterrent failed, and the tree shows why.

## The two use cases are different, and only one of them is the problem

**Event-time modifier discrimination** — *"this click, with Ctrl held, means
something else"*. This is where the if-cascades live, and the instrument that
removes them is the **shortcuts/combo tier**, not a held-key table. Decision 27
extended combos to every channel precisely so this is expressible everywhere.

**Frame-time state** — *"draw the Shift cap lit while it is held"*, *"paint with
the background colour while the button is down"*. There is no event in hand; a
draw must poll. This is Decision 20's own stated rationale for making the set
globally readable — *"a per-frame draw has no event argument"* — and shortcuts
cannot serve it by construction.

So the two mechanisms are complementary, not competing. A polling table cannot
discourage if-cascades, because **a polling table is itself an if-cascade
surface**: `if keys['lctrl'] then` is the same shape as `if Key.ctrl() then`. It
relocates the pattern; it does not replace it. Only the combo replaces it.

## Why the deterrent failed, with the evidence

**Every example that wants a modifier reaches for `Key.*`, and none uses
`keys_pressed`:**

| project | site | shape |
|---|---|---|
| `sapper` | `main.lua:672`, `:690` — inside `hooks.singleclick` / `hooks.doubleclick` | `if not Key.shift() and not Key.alt() and not Key.ctrl()` |
| `sapper` | `main.lua:697` — inside `love.mousepressed` | `if Key.shift() and not Key.alt() and not Key.ctrl()` |
| `paint` | `main.lua:407` — in a keypressed path | `if Key.shift() then c = c + 8` |
| `tixy` | `main.lua:197` | `if Key.shift() then` |
| `keyboard` | `input.lua:108` | hand-rolls `modHeld` over `keys_pressed` |

**Sapper's three cascades are exactly what the new tier was built to replace.**
"Unmodified click" and "shift-click" are the two cases, and Decision 27 already
expresses both: an unmodified event has nothing to name and goes to the hook
tier, while `shortcuts.singleclick['shift+*']` names the other. The example
hand-writes a triple negation in three places instead.

**And the incentive points the wrong way.** The documented surface is
**unfolded**; the undocumented `Key.*` is **folded**. So the sanctioned path is
more awkward than the unsanctioned one for the same question — and
`doc/input_api.md:375` teaches the awkward one by example:

```lua
local shifted = compy.input.keys_pressed['lshift']
    or compy.input.keys_pressed['rshift']
```

Nothing anywhere says *"for event-time modifier logic, write a combo"*. A
deterrent that is never stated, against an alternative that is easier to type,
is not a deterrent.

## The drift is a framework gap, not an argument for `Key.*`

`keys_pressed` can go stale-true when a key is released while the window is
unfocused. That is real — and unmitigated: the gateway explicitly skips the
focus callback (`controller.lua:752`, `--- SKIPPED focus`), so the set is never
cleared. `Key.*` polls `love.keyboard.isDown` and cannot drift.

But the conclusion is not "prefer the device poll". It is that the framework
owes the set a reset on focus loss. Pushing projects to a second source of truth
to route around a framework gap is how two sources of truth become permanent.

## Options, for the owner — none taken

1. **Clear `keys_pressed` on focus loss.** Closes the drift, framework-side, no
   API change. The honest fix for the only real objection to the instrument.
2. **Migrate `sapper` (and `paint`) to combos.** The deterrent was never going to
   be the existence of a table — it is what the examples demonstrate. This is
   also W11 territory, and it would make the data-driven path the shown default.
3. **Fold at the documented surface** (a folded modifier query on
   `compy.input`). Removes the perverse incentive, but adds a moving part to an
   API whose brief was to get simpler — so it needs the justification-table
   treatment if taken.
4. **Say what `Key` is.** It is reachable from projects, used by three of them,
   and absent from `doc/input_api.md`. Either document it or state that it is
   internal; leaving it unmentioned but reachable is what produced the split.

**Recommendation: 1 and 2.** They serve the stated intent without growing the
API — one closes the real defect, the other makes the intended pattern the one
projects can see. 3 is the only one that touches the public surface, and the
strategic frame argues against it unless 2 proves insufficient.
