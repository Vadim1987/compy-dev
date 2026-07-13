# Input subsystem — architecture & key decisions

The *why* behind Compy's keyboard/text input routing and the project-facing input widget.
For how it works under the hood — the exact dispatch order, the mechanism behind each
guarantee, file-by-file wiring — see [`../internals/user_input.md`](../internals/user_input.md).
For the project-author usage guide — the `show()` config table, worked examples — see
[`../../input_api.md`](../../input_api.md). This doc records the decisions those two describe;
it does not restate their mechanism.

The subsystem replaced an older input API that was polling-based and routed by widget
presence. Understanding what it was chosen *over* is most of the rationale, so the contrast
appears throughout.

---

## The problem this shape solves

The previous input API had three structural faults that projects tripped over:

- **Polling, not events.** A project called `input_text()` / `input_code()` /
  `validated_input()` / `user_input()`, then re-checked a reference variable on every update
  tick to notice a submission. There was no way to be *told* when the user submitted.
- **Keyboard lockout during input.** While a prompt was on screen, the project's own
  `love.keypressed` / `love.textinput` handlers were not called at all — routing was gated on
  widget presence, so a shown widget swallowed the project's key events wholesale. Reacting to
  a hotkey *while* soliciting text was impossible.
- **No show/hide without teardown.** A prompt could not be hidden and brought back with its
  state intact; dismissing it meant tearing it down and rebuilding.

The design goal was an event-driven input surface consistent with LÖVE's own callback style,
expressive enough that the console REPL and the editor input strip *could* be rebuilt on it,
while keeping the simple case simple — a student shows a prompt and gets the result through
one callback, with no framework internals in view.

---

## Decision 1 — routing is route-centric, not widget-centric

**Decision.** The application mode selects **exactly one active route** — console, editor, or
project — and every keyboard/text event is dispatched to that one route. A widget never
selects the route. Widget visibility is *state on the widget*, never a routing condition.

**Why.** The old model routed by asking "is a widget shown?" at the gateway, which is what
produced the keyboard lockout above: the widget's mere presence diverted events away from the
project. Making the *mode* the sole routing authority means showing or hiding a prompt is a
state change with no routing consequence — the project route stays connected and keeps
receiving key events whether or not its widget is up. This is the single structural change the
whole subsystem hangs off of: the overlay gate is gone.

**Consequence.** The three routes are siblings. Today the editor is still reached through the
console route's internal fork rather than as a fully independent third sibling; converging the
console and editor onto the same chain the project route already uses is deliberately left as a
follow-on, not attempted in the pass that introduced this model. The project route is the
proving ground for the shape.

## Decision 2 — a four-tier dispatch chain with truthy-consume

**Decision.** Inside the active route, every keyboard/text event runs one chain of four tiers,
in order:

1. **framework handlers** — structural keys the route reserves (the project route claims Enter
   and Escape while its widget is shown); non-overridable, not exposed to project code.
2. **project combo handlers** — per-combo functions the project registered.
3. **a per-event generic callback** — `on_key_pressed` / `on_text_input` / `on_key_released`;
   default is a no-op that only debug-logs.
4. **the sink** — the widget's text editor; always terminal, permanently configured.

A **truthy return at any tier consumes** the event: it travels no further, the sink included.
A falsey return falls through. The same four-tier shape runs on all three channels
(`keypressed`, `textinput`, `keyreleased`); a tier with no participant simply falls through.

**Why.** One uniform shape on every channel is the predictability meta-rule made concrete:
nothing "special" gets its own routing rule; a released key and a typed character travel the
same path a pressed key does. The truthy-consume convention is the familiar DOM-style
"handled-stops-propagation" that projects already understand.

**A load-bearing distinction: consuming is not removing.** A higher tier consuming an event
for *this* keystroke never removes a lower tier from the configuration. Configuration is
permanent; flow is decided per-event. There is no replace-semantics anywhere in the chain —
assigning a generic callback replaces *that callback only*, it does not detach the sink beneath
it. This is what lets the sink be a permanent tier-4 fixture rather than something the project
wires up and can accidentally unwire.

**A load-bearing decision about the sink: its hidden-check is internal.** The terminal sink is
always invoked; it decides for itself to no-op when the widget is hidden. There is no external
"is it shown?" wrapper gating the call. This is why widget visibility carries no routing weight
(Decision 1) — the branch that used to live at the gateway now lives inside the sink, where it
mutates nothing and only debug-logs.

## Decision 3 — one boot-provisioned shared widget, not per-session construction

**Decision.** The input widget is a **singleton, created once at load** and reused across every
session. Projects reach it through the `compy.input.*` surface and never hold the widget object.
`show()` / `hide()` are state flips on that one instance, not construction and teardown.

**Why.** A non-functional requirement forbids allocating a fresh object graph per input
session — the device is memory-constrained and the common pattern is repeated prompting. A
shared instance also makes the "hide and bring back with state intact" requirement fall out for
free: the state was never destroyed. And it is what makes Decision 1 cheap — a shared surface
whose show/hide are pure state changes has nothing to reconnect.

**Consequence.** The same widget code backs the console REPL, the editor input strip, and
project overlays; what differs between them is the evaluator attached and which route handles
the result — not the widget. `show()` on an already-active session is a no-op (it *warns*
rather than swallowing — see Decision 7's discipline) unless `{force = true}` is passed.

## Decision 4 — callbacks replace polling

**Decision.** Submission and all other input events are delivered through **callbacks and
handler tables**, never through a polled reference. The legacy text-input globals and the
reference-variable idiom they fed are **removed outright** — no shim, no compatibility flag.

**Why.** Polling is inconsistent with LÖVE's event-driven style and forced every project into a
per-frame re-check. Callbacks eliminate the poll, and — combined with Decision 1 — eliminate the
keyboard lockout that made polling-plus-hotkeys impossible in the first place. The clean break
(rather than wrapping the old functions) was a deliberate stakeholder call: this is pre-1.0, the
full set of callers is known and small, the examples exist to demonstrate good code, and a
legacy shim left in a release would teach the pattern the feature exists to retire. The break is
bounded to text fields; native keyboard handling keeps working (Decision 10).

**Consequence.** The old globals (`input_text`, `input_code`, `validated_input`, `user_input`,
`write_to_input`) are gone from the project environment as ordinary `nil` fields. Their examples
migrate to `compy.input.*`; the replacement mapping is documented in the usage guide.

## Decision 5 — two directions, two surfaces

**Decision.** The chain routes events *into* the active route. The widget reports results *out*
through its own configured **widget outputs**, which are **not** chain tiers:

- `on_text_entered(text)` — fires at submit, with the full assembled text.
- `on_limit_reached(direction, scope)` — fires when the cursor tries to move past a boundary
  (`direction` up/down/left/right; `scope` whole-input or current-line).
- `validator(text)` and `highlighter(text)` — behaviour configured on the widget.

These are set at `show()` / `configure()`, or assigned as `compy.input` fields — one underlying
slot, two ergonomics.

**Why.** Routing has two genuinely different directions and conflating them is the trap this
subsystem was explicitly designed around. Events arriving are a chain concern; a *result* is the
widget's to announce. In particular:

- **`on_text_entered` is widget vocabulary, not the per-character chain callback.** The
  per-character textinput callback is `on_text_input` (chain tier 3). The two names are never
  interchangeable — an easy and costly confusion, kept apart by naming on purpose.
- **Results never travel as chain return values.** The sink is terminal, so nothing sits above
  it to read a return; a boundary or submit condition therefore *cannot* report upward through
  the chain and must use the widget's own outputs. (This is the narrow thing the "no results via
  return values" rule fixes — it is a consequence of the sink being terminal, not a general ban
  on status returns.)

**Consequence.** A project gets soliciting input working with nothing but
`show{ ...callbacks... }` — no chain knowledge required. That "easy path" is the pedagogical
target the whole two-surface split protects.

## Decision 6 — submit and cancel are framework-tier, with call-order semantic chains

**Decision.** Enter and Escape on the project widget are **tier-1 framework handlers**, engaged
only while the widget is shown. Each is wrapped in a **semantic chain that orders by call
position**, not by return values:

```
submit:  before_submit  →  validate → deliver via on_text_entered → deactivate  →  after_submit
cancel:  before_cancel   →  clear content → hide                                  →  after_cancel
```

The framework owns the middle step; a hook cannot suppress it. All four hooks default to a
no-op that debug-logs.

**Why.** Placing submit/cancel at the non-overridable tier makes their semantics *guaranteed*
while the widget is shown: Enter always submits and Escape always dismisses, and no project
participant can shadow them. Deliver-and-close and dismiss are session-lifecycle acts above the
widget's pay grade — an earlier limitation where Escape cleared content but could not actually
dismiss came precisely from the widget owning Escape. Ordering the hooks by position (rather than
by a consume convention) keeps the "before/middle/after" reading obvious.

**Auto-close on submit is unconditional — and is *route policy*, not widget nature.** A
successful submit synchronously validates, delivers through `on_text_entered`, and hides, all
within the one Enter keypress. There is deliberately **no keep-open flag** (such a flag would be
the old one-shot mechanism reborn with its polarity flipped). A project that wants continuous
prompting re-activates from its `after_submit` hook — `compy.input.show{...}` on the next line,
which starts empty and reuses the persistent callbacks, so it is one line, not a re-setup. What
is *uniform* across every present and future adopter of this chain is the submit **shape** (the
widget never owns submit; the route's tier-1 handler does, in the hook chain). Deactivate-on-
submit is the *project route's* middle-step policy specifically; when the console and editor
migrate onto this chain they will mint their own middle steps and keep their widgets shown.

**Reserved, not built.** A `before_submit` veto return is a deliberately reserved extension —
ignored today, but the design does not preclude it; blocking bad input at submit is already the
validator's job. `hide()` (the programmatic path) fires **no** cancel chain — cancel is the
user-facing Escape path only.

## Decision 7 — a strict mutable/immutable API boundary

**Decision.** The project-mutable surface of `compy.input` is **exactly** the `handlers` tables
plus the callback fields (`on_key_pressed` / `on_text_input` / `on_key_released`,
`on_text_entered` / `on_limit_reached` / `validator` / `highlighter`, and the four
`before_*` / `after_*` hooks). Everything else — `show`, `hide`, `configure`, `clear`, the
cursor/text calls, the `handlers` container itself — is callable API that **errors loudly on
assignment**.

**Why.** The surface has to be simultaneously configurable (projects wire callbacks by plain
assignment, LÖVE-style) and tamper-resistant (a project must not be able to replace `show`).
Enumerating the writable slots and refusing everything else — loudly, never a silent swallow, per
the house warn-don't-swallow discipline — draws that line unambiguously. The guard lives in the
surface's metatable, so a stray or mistyped assignment fails at the point of the mistake rather
than corrupting the API.

## Decision 8 — per-event combo tables and canonical combo serialisation

**Decision.** The combo tiers are keyed **event-type-first**: `handlers.keypressed[combo]`,
`handlers.keyreleased[combo]`, `handlers.textinput[combo]` (and the framework tier likewise). A
single flat `[combo]` table serving all channels is forbidden. Held keys and combo strings use
two deliberately different representations:

- the **held-key set** keeps precise left/right names (`lctrl` ≠ `rctrl`);
- **combo serialisation** folds left/right and orders modifiers in fixed precedence
  (`ctrl`, `alt`, `shift`, `gui`), `+`-joined — `"ctrl+s"`, `"alt+shift+f4"`, bare `"escape"`.

Handler tables normalise assigned keys to canonical form on assignment, and dispatch matches
through an overloadable matcher (default exact match), left as a marked seam for future
glob/prefix needs.

**Why.** One flat combo table across channels was a known derivation-drift attractor — it makes
a keypressed combo and a textinput combo collide in one namespace. Per-event keying keeps them
separate by construction. Folding l/r only at serialisation gives projects a stable, readable
combo string to register against while preserving the precise held set for anyone who needs to
tell the two Ctrls apart. Normalising on assignment means a project can register `['Ctrl+S']`
and still match.

## Decision 9 — uniform signatures and `isrepeat` threading

**Decision.** Every participant on a channel receives the same signature, the sink included:
keypressed carries `(k, keys_pressed, isrepeat)`, textinput `(text, keys_pressed)`, keyreleased
`(k, keys_pressed)`. On the project route, `isrepeat` is threaded through all four tiers.

**Why.** A single signature per channel is the uniformity that lets the sink be just another
participant rather than a special case. `isrepeat` was restored to the signature so a project can
distinguish a held-key repeat from a fresh press.

**Where it stops — recorded honestly.** `isrepeat` reaches the project route's generic callback
and sink, but the combo tiers (framework and project) do **not** gate on it — they fire on every
repeat. Whether combos *should* fire fresh-only is left unruled, with existing behaviour kept as
the safe default; the code carries this as a deferred marker. See the technical-debt register for
the open call.

## Decision 10 — legacy native handlers are pure-wrapped as tier-3 participants

**Decision.** A project's own `love.keypressed` / `love.textinput` / `love.keyreleased` handlers
**auto-provision as plain tier-3 participants** — no widget-aware gating, no lifecycle split, no
custom logic. The tier-3 slot resolves by precedence: an explicit `compy.input.on_*` assignment
wins; otherwise the captured native seeds the slot; otherwise the default no-op. The native is
read **once at activation** and never re-consulted, and it seeds the slot **only** when the
project set no `on_*` — the two are mutually exclusive by precedence, not by overwrite.

**Why.** Treating natives as ordinary chain participants keeps the model uniform (they consume on
truthy, fall through on falsey, like anything else) and is what makes the keyboard-lockout fix
(Decision 1) reach legacy code too: a native handler now sees events even while the widget is
shown. The alternative — a widget-aware wrapper that gated the native on visibility — would
reintroduce the exact special-case the subsystem exists to remove.

**Consequence, accepted.** Because natives now fire while the widget is shown, the two examples
that combined a native handler with widget solicitation change behaviour and are migrated
alongside the change. Breaking-and-fixing the affected examples was the explicit expectation, not
a regression to avoid; pure-native projects (no widget) are unaffected.

## Decision 11 — the route connects only while the project is actively running

**Decision.** The project route occupies the **keyboard/text** slots only while the application
is in the `'running'` state. When a non-blocking project's `main.lua` returns (nothing hooked
into update/draw), the state drops to `'project_open'` and the keyboard/text slots are restored
to the console route. On project stop, every slot restores to framework defaults and every
project participant — handler tables, callbacks, widget configuration — resets.

**Why.** This is the established platform behaviour, adopted as a design constraint because no
product ruling motivated changing it. The precise scope matters and is binding: the disconnect
covers **keyboard/text slots only** — pointer natives stay hooked until the project actually
stops, so pen-and-paper projects (which draw on click while otherwise idle) remain interactive in
`'project_open'`. An implementer must **not** "tidy up" by unifying pointer disconnection into
this boundary; the asymmetry is intentional and load-bearing for those projects.

**Consequence — a teardown invariant.** No callback, combo entry, or widget configuration
survives the project that installed it. Combined with the connection rule, stale configuration can
never act outside its creator's window: a disconnected route's participants receive nothing, and
a widget whose owning route is inactive goes unhonoured. `inspect` mode is the model case of the
latter (Decision 12).

## Decision 12 — `inspect` is a mode-to-route line, nothing more

**Decision.** `inspect` (a paused or broken-into project) is simply **the console route active,
bound over the project's environment**. The project route is disconnected exactly as the
connection rule (Decision 11) describes, and the project's own widget is unhonoured because its
owning route is inactive.

**Why.** Framing inspect as a routing state rather than a bespoke mode means it needs zero special
rules — it is the console route plus a choice of environment, and it matches the implementation
exactly (suspending a project restores all slots to the console). The console running the paused
project's environment makes it a live debugger console rather than a separate idle one.

## Decision 13 — the held-key set is exposed read-only, callback-only

**Decision.** Downstream consumers never touch the live held-key table. Every chain signature's
second argument is a **read-only proxy**: reads pass through to the live set, writes raise. There
is no project-facing way to *poll* held keys outside a callback — the proxy only ever arrives as a
callback argument.

**Why.** The held set is framework-owned state maintained at the gateway; letting project code
mutate it would corrupt every downstream consumer. Read-only access covers the legitimate need
(a callback asking "is Ctrl down?") without exposing the write. Keeping it callback-only rather
than pollable is consistent with the callback-over-poll principle (Decision 4) — there is no
per-frame "is this key down?" surface by design.

**Recorded honestly:** on the shipping LuaJIT/Lua 5.1 runtime the proxy is index-only in
practice — `pairs()` ignores the metamethod that would make it iterable, so iteration yields
nothing; indexing works. The iteration support is kept for a future 5.2+ host. See the
technical-debt register.

---

## The ergonomics payoff

The measure of the design is the before/after in project code. The old pattern set up a prompt,
then polled a reference every update tick and manually tore the prompt down; reacting to any key
while the prompt was shown was not possible at all. The new pattern is a single `show{...}` with
the callbacks inline:

```lua
compy.input.show{
  prompt = 'name?',
  on_text_entered = function(text) greet(text) end,
}
```

No per-frame poll, no manual teardown, and — because the project route stays connected while the
widget is shown — the project's other key handlers keep firing throughout. Continuous prompting
is one re-`show()` from `after_submit`; richer uses layer on `validator`, `highlighter`,
`on_limit_reached`, and the cursor/text calls. The simple case stays one call; the expressive
case is reachable without reading framework internals.

---

## Where the shipped system differs from the design intent

A design corpus preceded the implementation. Two of its stated intents did not fully land; both
are captured in the technical-debt register and are noted here only so a reader is not misled:

- A `multiline` configuration flag was specified to gate Shift+Enter newline insertion. It was
  **not implemented** — Shift+Enter inserts a newline unconditionally, and the widget carries a
  standing to-do for the flag.
- The design's config table lists `validator` / `highlighter` as the behaviour keys; the shipped
  `show()` additionally accepts `eval` and `result` keys (an evaluator object and a legacy result
  reference), which are real and working but unrecorded in the design contract.

Separately, config keys that `show{}` does not recognise are silently dropped rather than warned
about — an inconsistency against the warn-don't-swallow discipline applied elsewhere on this
surface (the cursor/text calls do warn when refused). These, and the open combo-repeat and
proxy-iteration items noted above, live in [`../technical_debt/input.md`](../technical_debt/input.md).
