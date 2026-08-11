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

**[Owner, 2026-08-11] Justification, for the PR's justification table.** It **reduces boilerplate
every example keeps reinventing** and **encourages fewer moving parts** in the code that uses it.
It is syntactic sugar, and valuable sugar; **the addition itself is extra cheap — a few lines**.

**[Owner, 2026-08-11] SYNTAX RULED IN FAVOUR OF VARIADIC TOKENS — no serialised separators at
all:**

```lua
Key.pressed('ctrl', '!shift', 'h')
```

Reasons given: it **saves string splitting**, and it is **less ambiguous** — the only special case
left is a **leading `!`**. This supersedes the `'ctrl-leftalt-!shift-h'` spelling above.

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

**C1 — WITHDRAWN by the owner's variadic ruling, and the ruling is better than my counter.**
I had objected that `-` collides with the hyphen key (a real LÖVE key name) and that a second
separator competes with the API's `+` vocabulary, and recommended `+`. **Variadic tokens beat
both spellings**, and for a reason neither of us had stated — **verified in the engine, not
argued**:

```
love.keyboard.isDown('shfit')  →  error: Invalid key constant: shfit
love.keyboard.isDown('ctrl')   →  error: Invalid key constant: ctrl
love.keyboard.isDown('lctrl', 'rctrl')  →  false
```

So an implementation that resolves the fold names it knows (`ctrl`/`alt`/`shift`) and **passes
every other token straight through to the device** inherits **loud failure on a typo for free**:
`Key.pressed('shfit')` raises, where a proxy-table read (`keys.shfit`) would have quietly meant
"not held". That is the strongest available argument against the table form of C4 as well, and it
exists only in the variadic shape — a separator-joined string would have to split and validate by
hand to get the same behaviour, which is precisely the string work the owner's ruling avoids.

**One consequence to state deliberately rather than inherit:** the query vocabulary now *differs*
from the binding vocabulary (`shortcuts.keypressed['ctrl+h']` versus `Key.pressed('ctrl','h')`).
That divergence is **a feature under this ruling** — passing a whole combo string into the query
by mistake (`Key.pressed('ctrl+h')`) raises rather than silently answering the wrong question —
but the guide must say so explicitly, or it reads as an inconsistency someone will later "fix".

**C2 — exclusivity is still unanswered, and the variadic form does not settle it.** Is
`Key.pressed('ctrl','h')` *"ctrl and h are down, don't care what else"* (permissive) or *"ctrl and
h and nothing else"* (exclusive)? The shortcut vocabulary answers this with `*`: `'shift+*'` means
shift **and no other modifier**. My recommendation stands in the variadic shape —
**`Key.pressed('shift','*')` = shift and no other modifier**, so `!` carries explicit negatives
and `*` carries exclusivity, with one meaning per symbol across both surfaces. The alternative,
exclusive-by-default, makes the common case longer and gives `!` nothing to do.

**C3 — WITHDRAWN as framed (owner, 2026-08-11), and replaced by a different objection.**
I called `Key.pressed('!ctrl','!alt','!shift')` "horizontal sprawl merely relocated". The owner's
correction is right and the distinction matters: **it is ONE call**. P5's complaint was never
verbosity — it was *chained* conditions composed with `and`/`not` across call sites, and physical
state consulted fifty lines from the condition that motivated it. A single call listing three
negations is one place, one evaluation, atomic and readable. Verbosity is not sprawl, and I
conflated them.

**What survives is a coupling objection, not a style one — and it is sharper.** Writing
`'!ctrl','!alt','!shift'` asserts *"these are all the modifiers there are"*. That is **the fold
reinvented one level up**: the project now hard-codes the framework's modifier-set membership.
It is true today and was false eight days ago — Decision 31 closed the set and removed `gui`, so
the same call written before that ruling would have been silently incomplete. The framework's own
class key never has this problem, because `'shift+*'` delegates set membership to the matcher.
**So an exclusivity token is worth having for correctness, not for brevity**, and that is a better
argument for C2's `*` than the one I originally gave.

**[Owner, 2026-08-11] Further labels are available if wanted** — `'!*'`, `'nothing'`, `'![mod]'`,
`'![a-z]'` and the like — added only if a real call site needs them. **Assistant's caution, for
the record:** each label is individually cheap, but together they become a **query mini-language**,
which is itself a moving part the frame asks us to justify. `'!*'` / `'nothing'` are one concept
(exclusivity) and are cheap; `'![a-z]'` is a different concept (classes of keys) and would need a
defined vocabulary, a documented list, and a story for what `[a-z]` means on a non-Latin layout.
**Recommendation: ship exclusivity, defer classes until something asks.**

**C8 — the minimal `Key.pressed(k)` wrapper has an arity trap, and it would poison the name.**
`love.keyboard.isDown('a','b')` means **OR** — *either* is down. §P5.1's proposed
`Key.pressed('ctrl','h')` means **AND** — *both*, with negation. So a wrapper shipped now as a
plain pass-through would establish **OR** semantics under the very name the proposal needs for
**AND**, and the later primitive would have to either break compatibility or take a worse name.

**Recommendation: ship it single-argument only, and raise on a second.** `Key.pressed('h')` is
then exactly `isDown('h')`, the multi-argument meaning stays **unclaimed**, and the proposal can
later extend it compatibly — single-argument behaviour is identical under both readings. This
costs one guard clause and preserves the design space; the alternative is a name collision we
would meet at the worst moment.

**C3b — three boundary cases the signature should answer before it ships**, each cheap now:

- **Zero arguments.** `Key.pressed()` should raise, not return true or false.
- **Mouse buttons.** Combos name them (`'ctrl+mouse1'`), so someone will write
  `Key.pressed('ctrl','mouse1')`. Either support it via `love.mouse.isDown` or refuse it
  explicitly; silently passing `mouse1` to the keyboard would raise with a confusing message.
- **The pass-through contract.** "Unknown tokens go to the device, which raises" is the property
  C1 rests on, so it is a **documented behaviour**, not an implementation accident.

**C4 — `compy.input.keys` is already claimed by a different proposal, with a different shape, and
the variadic ruling settles which one should win.** Yesterday's register entry proposes
`compy.input.keys` as a **held-state table** (`keys.h`, `keys.shift`); P5.1 proposes the same name
for the **`Key` module**. The query subsumes the table — `keys.pressed('h')` answers everything
`keys.h` would — and C1's verified property decides it: **a table read cannot fail loudly.**
`keys.shfit` is `nil`, i.e. "not held", silently, in a boolean position; `keys.pressed('shfit')`
raises. **Recommendation: keep the module, drop the table.** The other half of that entry — swapping the implementation from
polling to a mirror behind the same surface — survives either way and is worth preserving in the
promoted text.

**C5 — naming, weakened to a preference.** `Key.pressed` reads like an *event*
(`keypressed`), while it answers *physical state*; `Key.held(...)` matches the guide's existing
"Held keys" heading and cannot be misread as edge semantics. In the variadic spelling the reading
is less strained (`Key.pressed('ctrl','h')` — "ctrl and h are pressed"), so this is a preference,
not a contest. Cheap now, expensive after it ships.

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

### 2.3 RETRACTED — my sapper claim was self-contradictory (Fable, 2026-08-11)

I wrote that P5.1 "dissolves sapper's problem without touching its timing… **no synthesis-time
modifier hole, no behaviour change at all**". **Those two halves cannot both be true**, and the
oracle was right to kill it: respelling four boolean chains as four queries, at the same call
sites, evaluated at the same moments, changes nothing — so it cannot remove a defect that is part
of what it preserves.

**What is true, and is worse than what I claimed — verified in code, 2026-08-11:** the hole is
**in the shipped example already**, and always was.

- `love.mousepressed` flags the cell at press when Shift is held.
- The gateway counts the release and synthesises a single-click **0.4 s later**
  (`controller.lua`, `click_delay`).
- If Shift is released inside that window, the derived click serialises with **no modifiers**,
  passes the hook's own *"nothing held"* guard, and runs `single` again.
- `actionFlag` → `flowToggleFlag` **toggles**, so the second run **un-flags the cell**.

**Net effect: shift-click appears to do nothing if you let go of Shift promptly** — a plausible
human timing, in the example's original code, unrelated to anything this feature did.

So the honest statement of P5.1's value for sapper is narrower and still real: **it answers the
owner's actual complaint** — reinvented folding and chained conditions — **at zero behavioural
risk**, and it neither causes nor cures the toggle defect. The defect is sapper's own and belongs
to its step. Recorded in the persistent register so it is not lost with this document.

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


---

## 4. What this is, for the PR (owner's framing, corrected 2026-08-11)

**Do not say "we replaced a tracked mirror".** There was **no tracked mirror before this PR** —
verified: zero occurrences of `keys_pressed` in `src/` at the base `3256aac`, entering in
`2a156025`, the feature's own first milestone.

**The accurate account, in the owner's terms.** The tracked mirror was introduced out of an early
*feeling* that polling needed to be a legitimate, centralised method — a feeling that was **never
analysed at the time**. The analysis was effectively deferred to *"we will see how it is used"*.
**Now we see**, and this document is that deferred analysis arriving: four examples, three
independent re-implementations of the left/right fold, and three defects of the shape P2 names.

**So the shape of the episode is: the feature introduced a surface, use disclosed what was
actually needed, and the surface was withdrawn in favour of stating the need properly.** The
mirror came and went **inside the branch**. On that axis the diff is net-zero, and the residue is
not code but understanding — the principles, plus a filed proposal for the primitive the original
feeling was groping toward.

**The consequence for the PR description, which is not net-zero and needs saying.** The *code*
leaves no trace, but the **ledger does**: Decisions 13, 20 and 29 established the surface, and 30
and 31 withdrew it, and all five are in the persistent corpus and therefore in the diff. A
stakeholder reading the decision log will meet five decisions about a surface that **never
ships**. Tombstone discipline says they stay — so the justification table owes a line that says
plainly what happened: *an implementation-time surface was introduced, its need was tested against
real use, and it was withdrawn; the decisions are kept because the reasoning is the durable part.*
Without that line, the ledger reads as churn rather than as a question asked and answered.


---

## 5. Adoption rules — the operational form of the principles (2026-08-11)

Written as **question → action** so they can be applied to code by someone who has not read the
reasoning, and **reused when the editor and the console are evaluated later**. Each rule is marked
**[universal]** (true of any code that reads input, framework included) or **[project surface]**
(depends on `compy.input`, so a framework-side migration must translate rather than copy it).

### The questions

**Q1 [universal] — Does it keep its own copy of held state?** A boolean mirroring a key, a table
of keys currently down, a `*_was_down` companion.
→ **Delete it and ask at the point of use.** A mirror has no reconciliation path: focus loss, a
missed release, or an unexpected event order leaves it lying, and nothing corrects it.

**Q2 [universal] — Does it re-implement the left/right fold?** `isDown('lshift','rshift')`,
`is_shift_down()`, `modHeld(a, b)`, or any helper meaning "either of the pair".
→ **Call `Key.shift()` / `Key.ctrl()` / `Key.alt()`.** The fold already ships; a local copy also
hard-codes which keys are modifiers, and that set has changed once already (Decision 31).

**Q3 [universal] — Does one expression mix `Key.*` with raw `love.keyboard.isDown`?**
→ **Route both through `Key`.** Two spellings of one question in one line reads as two mechanisms.
(Requires `Key` to answer non-modifier keys — see the note under "What this needs" below.)

**Q4 [universal] — Does it answer *"did this just happen"* by polling plus edge detection?** A
per-frame poll with a previous-value companion, deriving a transition.
→ **That is an event.** Use the channel — a hook, or a shortcut if it names a combo. The poll and
its companion both go.

**Q5 [universal] — Does it answer *"is this held right now"*?** Drawing a pressed key cap, a
modifier gating a drag, a paddle held down.
→ **Poll the device, and leave it alone.** This is the correct shape, not a rung to climb.

**Q6 [universal] — Does it enable a state on one channel and disable it on the mirrored one with
the same combo?** `keypressed['alt+h']` sets, `keyreleased['alt+h']` clears.
→ **Antipattern — replace it.** Poll the condition instead, or restructure so the ending does not
depend on a matching event arriving in the shape its sibling expects. A modifier's own release
cannot be bound at all, so the closing half is sometimes not even writable.

**Q7 [universal] — Is physical keyboard state consulted deep inside game logic?**
→ **Lift it.** Read the keyboard early — top of the hook, shortcut, or `update` — into named flags
carrying game semantics, then run the logic on the flags. Keeps the non-deterministic input at a
visible level instead of scattered through deterministic code.

**Q8 [project surface] — Does one hook demultiplex several orthogonal combos by hand?** A chain of
`if key == … and modifier …` branches.
→ **Split into shortcuts, one per combo.** This is what shortcuts are *for*: decomposition, not
capability.

**Q9 [project surface] — Is a binding on the release channel?**
→ **Legitimate, if it is a choice.** Reacting on release is a fair UX decision and removes any need
to filter repeats. Two cautions: `fn.ignore_repeat` on press does the same job, and a *modified*
combo can be missed on release when a modifier comes up first — so prefer the release channel for
bare keys.

**Q10 [project surface] — Does it re-implement *"this modifier and none of the others"*?**
→ **For a binding, use the class key** (`'shift+*'`): it means exactly that, folded over every
modifier the framework knows. **For a query**, spell the exclusion explicitly and accept that it
hard-codes the modifier set until a query primitive exists.

### Rules of restraint, which apply to every answer above

- **Behaviour-preserving or recorded.** If a conversion is not obviously behaviour-preserving, it
  is not a sweep item: record it with its reasoning and defer it to a step that can rule on it.
- **A deviation is stated in the workspace**, in the document or the code — not only in a commit.
- **Purpose beats shape.** Code whose *shape* matches an antipattern may exist for a reason nobody
  wrote down. Ask the author before converting; sapper's touch fallback looked exactly like a
  hand-rolled cascade and was not one.
- **An example that demonstrates a path is not a candidate for converting off it.** `turtle`
  deliberately keeps its handlers on the captured `love.*` path (owner ruling, 2026-07-31) because
  it is the only example showing that path works.

### What this needs that does not exist yet

**Q3 assumes `Key` can answer a non-modifier key**, which today it cannot — `Key` exposes the three
folds, and everything else goes to `love.keyboard.isDown` directly. The minimal addition is a
**single-key** wrapper (`Key.pressed(k)`), deliberately *without* the token language of §P5.1.
**It must accept exactly one argument** — see §2.2 C8.
