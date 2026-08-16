# P-24-00 — `only_mods`'s positional API: how far it reaches, and what replaces it

Owner, 2026-08-16: the predicate's positional-boolean API is non-intuitive; how
widely is it used, and can it be made meaningful — `only_mods('ctrl','alt')` or
`only_mod('ctrl+alt')`, where what is not named must not be held?

## Reach: seven call sites, one file, one day old

`only_mods` is a **file-local** in `src/controller/controller.lua:400`,
introduced today by `b20a4c35`. Every use is inside the two gate handlers:

| Line | Call | Means |
|---|---|---|
| 781 | `only_mods(true, false, false) and k == 't'` | quickswitch |
| 803 | `only_mods(true, false, false)` (wraps `pause`, `q`) | suspend / quit project |
| 811 | `only_mods(true, false, false) and k == "s"` | stop run |
| 816 | `only_mods(true, false, true)` (wraps `r`) | reset |
| 824 | `only_mods(true, true, false) and k == "r"` | restart |
| 837 | `k == "f10" and only_mods(false, false, false)` | FPS overlay |
| 890 | `only_mods(true, false, false) and k == "escape"` | quit / back to console |

Nothing outside that file names it — no test, no doc, no other module. So this
is as cheap to change as it will ever be, and the cost of leaving it is that
`only_mods(true, false, true)` will be read by everyone who touches the gate
from now on, with the reader having to remember that the third slot is Shift.

## Three options

**1 — variadic names** (the owner's first form): `only_mods('ctrl')`,
`only_mods('ctrl', 'shift')`, `only_mods()` for none. Reads as what it asserts,
no positions to memorise, smallest possible change: the body becomes a lookup
over `MOD_HELD` instead of three comparisons. Keeps a bespoke predicate.

**2 — one modifier string**: `only_mods('ctrl+shift')`. Same benefit, and the
string looks like the combo vocabulary — but it only *looks* like it. It would be
a second grammar to parse, for the modifier half of a combo, next to the real one.

**3 — delete the predicate; compare the canonical combo string.** The project
already has a serialiser for exactly this: `combo_string(k)` builds
`"ctrl+shift+s"` from the device plus the trigger, in ratified precedence
(Decision 8; `controller.lua:402-411`). Verified against the live code:

```
bare f10      ->  f10
ctrl + s      ->  ctrl+s
ctrl+shift+s  ->  ctrl+shift+s
ctrl+alt+shift + r -> ctrl+alt+shift+r
```

So the gate becomes one hoist per event and a set of literal comparisons:

```lua
local combo = combo_string(k)
...
if combo == 'ctrl+t' then          quickswitch
if combo == 'ctrl+s' then          stop run
if combo == 'ctrl+shift+r' then    reset
if combo == 'f10' then             overlay
```

### Why option 3 is the recommendation

- **Exactness stops being a rule and becomes a property.** A string equality
  cannot tolerate an unnamed modifier; Decision 33 is enforced by construction
  rather than by remembering to call the right predicate with the right slots.
  The class of bug P-21 fixed cannot recur here.
- **One vocabulary** (Decision 27). The gate's reservations would be written in
  the *same notation a project writes* in `shortcuts.keypressed['ctrl+s']`. A
  reader moving between the two layers reads one language, and the reserved set
  becomes greppable as literals.
- **Fewer device reads.** Today up to seven calls × three accessors = 21
  `isDown` calls per keypress; hoisted, it is three.
- **It retires the `not not` question at the gate.** `combo_string` tests its
  modifiers for truthiness internally, so the zero-value return that bit
  `only_mods` during P-21 cannot reach it.
- **Flatter.** The two grouped blocks (`pause`/`q`, and `r` under Shift) become
  independent comparisons, removing a level of nesting each.

### What it costs, stated plainly

One table allocation per keypress at the gate — the same cost the register
already names for the dispatch path ("Combo-string dispatch allocates a table
per call"). It is one allocation per *event*, not per reservation, and it
replaces up to twenty-one device calls. If that trade is ever unwanted, the
allocation is the thing to fix in `combo_string` for both callers at once.

Also: seven literal strings instead of six grouped conditions. Slightly more
lines, each self-describing.

## Proposed step

| Step | Content | Gate |
|---|---|---|
| **P-24-01** | Replace `only_mods` with a hoisted `combo_string` comparison in both gate handlers; delete the predicate. Behaviour-preserving — the fifteen-plus live cases from P-21 and P-23 are the proof, and **not one of them should need changing**. If any does, stop and report: it means the rewrite is not equivalent | the suite must stay **968 / 0 / 0 / 10** with no test edited; a changed test is a finding, not a fix |

If the owner prefers option 1, the same step applies with a smaller diff and
without the vocabulary win; the tests are equally the proof either way.
