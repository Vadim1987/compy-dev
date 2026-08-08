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

## First, what "folded" means here

LÖVE reports the two physical keys of each modifier separately: `lshift` and
`rshift`, `lctrl` and `rctrl`, `lalt` and `ralt`, `lgui` and `rgui`. **Folding**
is collapsing that pair into one logical modifier — "Shift is down" being either
of them.

- `Key.shift()` is **folded**: one call, either key.
- `compy.input.keys_pressed` is **unfolded**: it carries `lshift` and `rshift` as
  separate entries, so a project asking "is Shift held" must OR them itself.
- **`combo_string` folds** — `COMBO_MODS` holds the l/r pair plus the folded name,
  and the combo it builds says `shift`, never `lshift`.

That last point is the inconsistency in one line: **the combo vocabulary a project
writes is folded, and the table the same project reads is not.** `'ctrl+s'` on one
side, `keys_pressed['lctrl'] or keys_pressed['rctrl']` on the other, for the same
concept.

## [CORRECTED] What the examples do and do not prove

> **Owner correction, 2026-08-08.** An earlier version of this note read the
> examples' `Key.*` usage as evidence that the deterrent had failed. **That
> inference is wrong.** The examples were migrated to the new API by an assistant
> under instruction; low uptake of combos measures how thoroughly (or how
> conservatively) that migration was done, not what a project author would
> naturally reach for. Adoption by a migrator is not adoption by a user.

What the sites below **do** establish is a **migration gap** — pre-migration
modifier cascades left standing where the new tier can express them. That is
W11 work, not a verdict on the design:

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
hand-writes a triple negation in three places instead. Whoever migrated it left
that behind — which is a task for W11 and says nothing about the API's shape.

## What stands independently of who wrote the examples

Two properties of the API and its documentation, true regardless of adoption:

**The incentive points the wrong way.** The documented surface is unfolded; the
undocumented `Key.*` is folded. For the same question, the sanctioned path is the
more awkward one. That is a property of the surfaces, not of their users.

**The guide teaches the hand-rolled fold.** `doc/input_api.md:375`:

```lua
local shifted = compy.input.keys_pressed['lshift']
    or compy.input.keys_pressed['rshift']
```

Nothing anywhere says *"for event-time modifier logic, write a combo"*. A
deterrent that is never stated cannot deter — and this one is aimed at readers of
the guide, so it is the guide that has to state it.

## The drift is a framework gap, not an argument for `Key.*`

`keys_pressed` can go stale-true when a key is released while the window is
unfocused. That is real — and unmitigated: the gateway explicitly skips the
focus callback (`controller.lua:752`, `--- SKIPPED focus`), so the set is never
cleared. `Key.*` polls `love.keyboard.isDown` and cannot drift.

But the conclusion is not "prefer the device poll". It is that the framework
owes the set a reset on focus loss. Pushing projects to a second source of truth
to route around a framework gap is how two sources of truth become permanent.

## Why not add folded entries to the same table?

Owner question: if the mismatch is folded-vs-unfolded, why not write
`keys_pressed.shift = true` beside `lshift` / `rshift`?

**Because it breaks the one property that justifies a table at all** — see the
section below. `for k in pairs(keys_pressed)` would then yield `lshift` **and**
`shift`; "all keys held" double-counts, and anything filtering the set sees a
member no `keypressed` event ever delivered. A derived value stored inside a set
of observations is the same category error as a computed column in a raw log.

It also breaks the surface's stated invariant — `doc/input_api.md` describes it
as *"keyed by LÖVE key name"*, and `shift` is not one.

And **physical is the right primitive**, because folding is lossy in the
direction that matters for rendering: a keyboard renderer wants to light the cap
that is actually down, which a folded flag cannot tell it. Going
physical → logical is one `or`; going back is impossible.

If folded access is wanted it belongs in a **separate accessor**, and that is an
API addition needing the justification table. The cheaper move that costs no
surface: stop the guide demonstrating the hand-rolled `or`, and route event-time
modifier questions to combos, which are folded already.

## Do we need the table at all? Yes — and the reason is temporal, not ergonomic

Owner question: the table was originally meant to be **passed** to hooks and
shortcuts; Decision 26 removed it from the payload in the name of signature
unification. Combos could be assembled from `Key.*` instead, if a combo is always
"trigger plus mods". The remaining argument for a table is that "all keys held"
is filterable and iterable.

That argument is real but secondary. **The decisive one is that the two sources
answer questions on different clocks.**

- `Key.shift()` / `.ctrl()` / `.alt()` call `love.keyboard.isDown`
  (`src/util/key.lua:140-164`) — the **device, now**.
- `compy.input.keys_pressed` is updated inside the gateway's own handler
  immediately before dispatch — the state **at this event**.

LÖVE's run loop pumps the *entire* event queue and then dispatches the events one
at a time (this project installs no custom `love.run`). So when two events land in
one frame — press `a`, release `a` — a device poll taken while dispatching the
**press** already reports `a` as up. The event-tracked table, replayed in order,
does not.

**So for a combo, which is an event-time question, the table is the temporally
correct source and the device poll is not.** Assembling combos from `Key.*` would
be correct only in the common case where nothing else is queued behind the event
being dispatched.

This also reverses the naive reading of the staleness problem: the table can go
**stale across focus loss** (P9d fixes that), while the poll is **stale by
construction relative to queued events**. Neither is simply better; each is
correct on its own clock — the table at event time, the poll at frame time.

**Consequence worth recording, because the wrong fix is the plausible-looking
one:** do **not** close P9d by switching `combo_string` to `Key.*`. It would look
like it removes a source of truth and fixes the drift in one move, and it would
trade a bounded, fixable staleness for an unbounded, unfixable one.

**And the framework currently does what we would tell a project not to do:** the
gateway's own event-time gates read the device poll — `Key.ctrl()` / `Key.alt()`
/ `Key.shift()` inside `handlers.keypressed` and `handlers.keyreleased`
(`controller.lua:514, 531, 791, 813, 824`) — while dispatch beside them builds
combos from the event-tracked set. Same mismatch, in the platform's own code.
Small in practice; worth a ruling on whether to unify while P9d is open.

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
