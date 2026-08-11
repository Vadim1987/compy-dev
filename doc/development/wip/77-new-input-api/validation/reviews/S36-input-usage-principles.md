# PROPOSAL — principles for using the input API (owner, 2026-08-11)

**Status: proposal under discussion. Not ratified, not in the persistent corpus.** Destination if
it survives: `doc/input_api.md` (the project-facing half) and `doc/development/decisions/input.md`
(whatever is decision-shaped). Route agreed with the owner: **write down → assistant's assessment
→ cold Fable review → promotion to the persistent docs → replan**, with the explicit expectation
that the principles **may revert work already done and shrink or discard steps not yet started**.

Provenance is kept strict in this document: **§1 is the owner's**, stated in their terms; **§2 is
the assistant's assessment**, including contests; **§3** is what would have to change elsewhere if
the principles are ratified. A reviewer should be able to tell at a glance whose claim is whose.

---

## 1. The principles (owner, 2026-08-11)

### P1 — Shortcuts are for one-off, stateless transitions of *game* state

A shortcut suits an **independent, persistent transition in the game universe**: start the game,
end the game, toggle the mode. Its purpose is **decomposition of logic** — so that orthogonal
combos are not stuffed into one hook and demultiplexed by hand.

**"Stateless" here means transaction/trigger statelessness**, not absence of effect: the trigger
causes a transition that stands on its own afterwards. It is *not* the right instrument for
activating a mutable state that stops being true when the triggering condition dissolves.

### P2 — Shortcuts that depend on each other are a sign of bad architecture

Interdependent shortcuts are an attempt to manage hidden mutable state with an instrument that
**does not guarantee consistency**.

**Antipattern:** mirrored logic that enables a state on `keypressed` and disables it on
`keyreleased` with the same combo.

**Rationale:** the mirrored event is not guaranteed to arrive in the shape its sibling expects —
an extra modifier held at release, a release order the binding does not match, or the window
losing focus (a notification is enough).

### P3 — Choosing `keyreleased` is legitimate; *pairing* it is not

Reacting on release is a fine deliberate choice — for UX, and as easy protection against a held
key re-firing: if the intent is to act once, putting the shortcut on the release channel removes
the need to think about repeat filtering.

**Never as the logical counterparty of `keypressed`.** (The owner's note says "counterparty of
`keyreleased`"; the meaning is plainly *of `keypressed`*, i.e. never as the closing half of a
mirrored pair — recorded here corrected, and flagged so the correction is visible.) Rationale as
in P2.

### P4 — Device polling remains legitimate

For **continuous mutable states** and for checking the **physical state of the keyboard**, polling
the device is the right paradigm: the state is **self-correcting**, and the abstraction is honest
and minimal — it masks nothing.

### P5 — The real problem with today's `Key.shift()` chains

The owner's objection was never that projects ask the device. It is threefold:

- **constant reinvention of folding** (each project writing its own left/right merge);
- **horizontal sprawl** — `Key.shift() and not Key.alt() and not Key.ctrl()` spelled at every
  call site;
- **vertical sprawl** — physical keyboard state consulted deep inside an algorithm.

#### P5.1 — A single query primitive: `Key.pressed(...)`

One function answering an **arbitrary combo/chord question in one pass from the physical state of
the keyboard**, including **negative filters**:

```lua
Key.pressed('ctrl-leftalt-!shift-h')
```

It encourages **horizontal composition**, supports **folded and unfolded** queries (`ctrl` as well
as `leftalt`), supports **negative** checks, and answers **single-key** cases too. The whole `Key`
module can be exposed as **`compy.input.keys`**, giving a controlled surface and removing the need
for a separate import.

#### P5.2 — The vertical problem is met with a recommendation, not a mechanism

It cannot be prohibited technically — nothing stops a call to the keyboard from deep inside an
algorithm. The mitigation is a **recommendation**: early in the hook / shortcut / `love.update`,
**translate keyboard reality into feature flags that carry game semantics**, then run the complex
game logic on those flags.

Not a hard rule, and **not a reason to rewire every example** — a couple of demonstrations is the
right dose. Its wider value: it teaches **separating deterministic contexts from
non-deterministic ones**, lifting non-deterministic reality to a visible upper level instead of
mixing it in at arbitrary depth.

---

## 2. Assistant's assessment (2026-08-11)

### 2.1 Where the principles are strongest

**P2 is the most valuable thing here, and it is already paid for in evidence.** Three independent
findings in this session are instances of exactly the failure it names, and none of them was
reasoned from the others:

- the `alt+h` overlay pair, where releasing Alt first leaves the flag stuck and **no second
  binding can close it**, because a modifier's own release has no expressible combo;
- the project guide's own flag-shortcut example (bare `'space'` on both channels), missed whenever
  an unrelated modifier is held at release;
- sapper's derived-echo problem, where the swallow keyed on `'shift+*'` is missed if the modifier
  is released inside the double-click window.

A principle that predicts three independent defects found before it was written is not a style
preference.

**P4 and P1 together resolve a tension this feature has been carrying.** Decision 30 established
that the *matcher* reads the device; P4 says plainly when a *project* should. The pair leaves no
gap where "just poll it" reads as a failure to use the API.

**P5's diagnosis is correct and is better than the one the work was operating on.** The
reconciliation treated `Key.*` as "permitted but a symptom", which mislabels the disease: the
symptom is the *chain*, not the call.

### 2.2 Contests

**C1 — the separator collides with a real key name, and with the API's own vocabulary.**
`'ctrl-leftalt-!shift-h'` uses `-`, while every combo elsewhere uses `+` (`'ctrl+alt+s'`,
`'alt+*'`, `'ctrl+mouse1'`), normalised by Decision 8. Two spellings for one concept is a cost the
guide will pay forever. Worse, **`-` is itself a LÖVE key name** (the hyphen key), so
`Key.pressed('ctrl--')` is ambiguous where `Key.pressed('ctrl+-')` is not. **Recommendation: `+`
as separator, `!` for negation** — `'ctrl+leftalt+!shift+h'`. If the intent of `-` was to signal
"this is a query, not a binding", the function name already does that.

**C2 — the same string would mean two different things on two surfaces. This is the sharpest
risk.** In shortcuts, `'shift+*'` is **exclusive**: shift and nothing else. If `Key.pressed` is
**permissive** by default (`'ctrl+h'` = "ctrl and h are down, don't care what else"), then two
surfaces read similar strings with opposite defaults, and the difference is invisible at the call
site. Three ways out, and one is clearly best:

- **(a) Keep `*` meaning the same in both.** `Key.pressed('shift+*')` = shift and no other
  modifier — identical to the shortcut class key. Then `!` handles explicit negatives and `*`
  handles exclusivity, with **one vocabulary and no contradiction**. *Recommended.*
- (b) Make the query exclusive by default — then "don't care" needs new syntax, and the common
  case gets longer.
- (c) Accept the divergence and document it — cheapest now, most expensive later.

**C3 — "nothing held" is the most common query in the tree and is the ugliest to write.** Under
permissive-plus-negation it is `Key.pressed('!ctrl+!alt+!shift')` — which is the horizontal sprawl
P5 exists to remove, merely relocated. sapper alone needs it twice. Under (a) it may be spellable
as `Key.pressed('*')`, but note that **bare `'*'` is currently *refused* in shortcut registration**
(Decision 21) — so this either needs a deliberate exception for queries or a named helper. The
matcher already has `any_mod()` internally; exposing it (`not Key.any_mod()`) is close to free.

**C4 — `compy.input.keys` is already claimed by a different proposal, with a different shape.**
Yesterday's register entry proposes `compy.input.keys` as a **held-state table** (`keys.h`,
`keys.shift`). P5.1 proposes the same name for the **`Key` module**. They must be reconciled, and
I think the collision is fortunate: **the query function subsumes the table.** `keys.pressed('h')`
answers everything `keys.h` would, in one vocabulary, and avoids the silent-nil hazard the table
form has (a typo in a table read is `nil`, i.e. "not held", with no error). **Recommendation: keep
the module, drop the table.** The other half of that entry — swapping the implementation from
polling to a mirror behind the same surface — survives either way and is worth preserving in the
promoted text.

**C5 — naming.** `Key.pressed` reads like an *event* (`keypressed`), but it answers *physical
state*. `Key.held(...)` matches the guide's existing "Held keys" vocabulary and cannot be
misread as edge semantics. Cheap now, expensive after it ships.

**C6 — P3 carries a caveat it does not state.** A release-channel binding serialises with the
modifiers held **at release**, so `shortcuts.keyreleased['ctrl+s']` is missed when Ctrl comes up
first — the same mechanism as P2, one severity lower (the action does not happen; nothing is left
stuck). Also, the platform already offers `fn.ignore_repeat` for the "act once" need, so the guide
must say when to prefer the release channel over the wrapper rather than presenting release as the
only route. **Suggested wording: prefer the release channel for bare keys and for UX reasons;
for modified combos, expect the miss or use `ignore_repeat` on press.**

**C7 — P5.2 and the `compy.states` sketch are the same idea at two levels, and should be
cross-linked rather than left to look like rivals.** P5.2 is the discipline that needs no new API;
`compy.states` would be the mechanism if the discipline is ever worth automating — and, notably,
**`compy.states` is the safe form of what P2 forbids**: a condition polled and reported at its
transitions, self-correcting per P4, instead of a mirrored pair of events.

### 2.3 The consequence nobody has stated yet, and it is large

**P5.1 dissolves sapper's problem without touching its timing.** The four guards become one query
each — the press path stays exactly where it is, on `love.mousepressed`, at press time, on any
button. No derived-click channel, no swallow, no synthesis-time modifier hole, **no behaviour
change at all**, and the owner's actual objection (reinvented folding, horizontal sprawl) is fully
answered. That is strictly better than both options considered yesterday, and it is available only
because the diagnosis moved from "the call is a symptom" to "the chain is the symptom".

---

## 3. What ratification would change elsewhere

Listed so the replanning has a starting point, not as decisions:

- **The project guide's flag-shortcut section becomes the antipattern.** It currently teaches the
  mirrored pair P2 forbids. It would be rewritten, not annotated — and the P10 member already
  filed for its clearing-path defect is absorbed by that rewrite.
- **`helpHeld`'s filed recommendation inverts.** The register says the flag-shortcut shape is its
  top rung; under P2 + P4 **the poll it has today is correct**, and the entry should say so.
- **sapper's step (P19) narrows sharply** — from "decide whether to convert, and how to close the
  platform hole" to "collapse four chains into four queries", pending the author's eyes.
- **maze's tab poll stays a conversion candidate** under P1 (advancing a level is a one-off
  transition), with the trigger-narrowing caveat already recorded.
- **The examples' `Key.*` chains stop being "a symptom to be onboarded"** and become "spell them
  with the query primitive" — which is a smaller, mechanical, behaviour-preserving job than the
  onboarding steps currently assume, and may shrink P16/P17/P18.
- **A new primitive is new API surface**, which the strategic frame requires to be justified in the
  PR description — or deliberately deferred past this release. **That question is unruled and is
  the biggest open one:** the principles are documentation, but P5.1 is code.
