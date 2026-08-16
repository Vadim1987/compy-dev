# P-24-00b — the gate as a shortcuts table, the allocation, and sharing the combo

Owner's three follow-ups, 2026-08-16. Short answers first: **yes but it is its
own step and needs a decision amendment; yes and it is surgical; no, and there
is a ruled reason.**

---

## 1. "if-then is a bad paradigm — use the shortcuts table"

Agreed on the merits, and **Decision 33 is what made it possible**: while
reservations tolerated unnamed modifiers, `ctrl+alt+shift+r` matched two of them
and a combo→function table would have had no well-defined entry for it. Now that
each reservation is exact, every reserved chord maps to exactly one action — the
table is well-defined by construction.

**But this is not a refactor, it is the thing Decision 30 point 3 declined.**
That text names this exact shape — the gate "could build its own table", the
introspectability argument applies to it too — and then rules: *"That is not
committed to (owner, 2026-08-09): naming the layer does not oblige the table,
and building one is out of scope for this feature's PR and may never be done. If
it ever is, it must be visibly a second, privileged table, structurally separate
from a project's own and stating its non-overridability where it lives."*

So the owner is free to reverse it, but it is **a ruling to amend, not a step to
slip in**. What the work would be, bounded honestly:

- Two tables, per event, mirroring the project shape:
  `reserved.keypressed['ctrl+t']`, `reserved.keyreleased['ctrl+escape']`.
- Nine bodies move out of the two handlers into named functions. State
  conditions (`app_state == 'running'`, `love.PROFILE`) move **inside** each
  function, where they read better than as surrounding nesting.
- **One contract difference that must be stated where it lives:** a project's
  shortcut *consumes* by returning truthy; a reservation **never consumes** —
  the key still reaches the route afterwards. Same table shape, opposite
  consumption rule. This is the single most misleading thing about the design
  and belongs in a comment at the table, not only in a decision.
- Order collapses: today `restart()` runs before `quickswitch()` before
  `profile()` before `project_state_change()`. With one entry per chord there is
  no order to preserve — which is only true because exactness removed the
  double-match.

**Scope: medium, not surgical.** Bounded and mostly mechanical, but it changes
the shape of the framework's own input layer and needs its own cold review. It
also makes the reserved set *listable*, which is what the P10 guide section
owes — that is real value, not tidiness.

---

## 2. "Is the allocation the combo string? Can a fixed slot table be reused?"

The allocation is `local parts = { }` in `combo_string`
(`controller.lua:409-419`) — one table per call. The `table.concat` result is a
string, and Lua interns strings, so a repeated `'ctrl+s'` costs a hash lookup
rather than a new object. **The table is the garbage; the string mostly is not.**

Note it is already up to **two** per event in the dispatch path today, not one:
`find_shortcut` builds the exact combo and then, on a miss, the `'*'` class
(`projectInputController.lua:104-114`).

Both fixes are surgical, inside one function, with the existing suite as proof:

- **A module-level buffer table**, cleared and refilled per call. Removes the
  allocation entirely. Cost: shared mutable state in a function that must then
  never be called re-entrantly — true today, and a footgun to be commented.
- **No table at all** — build the string by concatenation over the three
  modifier tests. No shared state, no reentrancy question; a couple of
  intermediate strings, which interning makes cheap.

**Recommendation: no table at all.** It removes the allocation *and* the
reentrancy hazard, and it makes the "fixed four slots" implicit in the code
rather than a buffer someone must not disturb.

---

## 3. "Why assemble it again in the route? Could it be singleton state?"

**Recommend against**, and not on taste — on this feature's own ruling.

A shared "current combo" is a **cache of device state with no path back to the
truth**: valid only for the event that filled it, invalid the moment anything
reaches `_dispatch` by another path, and impossible to detect as stale from
inside. That is precisely the shape Decision 30 dissolved `keys_pressed` for —
*"a stateful abstraction model over an entity we do not control… the only way to
detect drift in the tracked model is to compare it against the device poll"*.
Re-introducing one to save an allocation would trade the property this feature
spent its length establishing for a micro-optimisation.

It is not theoretical: `_dispatch` is reachable without passing the gate. Tests
drive `ProjectInputController` directly, and the walk is deliberately written as
a free function so *"any adopter (not only the project overlay) can reuse it over
its own instance"* (`projectInputController.lua:118-124`). Each of those paths
would read a stale or absent singleton.

**Passing the combo down explicitly is also ruled out**, which is worth knowing
before it looks attractive: payloads are exactly LÖVE's arguments, and *"a
project that wants it asks the device… appending it would change the signature
every existing handler was written against"* (Decision 27's payload clause).

Once the allocation is gone (item 2), recomputing costs three device reads and a
string interning — cheaper than the bookkeeping any sharing scheme would need.

---

## Proposed shape of P-24

| Step | Content | Scope |
|---|---|---|
| **P-24-01** | Remove the allocation from `combo_string` (no table). Behaviour-preserving; existing suite is the proof | surgical |
| **P-24-02** | Replace `only_mods` with canonical combo-string comparison at the gate, per P-24-00 | surgical |
| **P-24-03** | **Owner-gated:** amend Decision 30 point 3 and build the privileged reservation table. Stating the non-consumption contract at the table is part of the deliverable, not a nicety | medium; own cold review |

-01 and -02 are independent of -03 and worth doing whichever way -03 is ruled;
-03 subsumes the if-then question entirely, since the comparisons disappear into
table keys.
