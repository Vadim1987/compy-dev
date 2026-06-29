<!--
  Input routing — the mental model, and the controversy that
  forced it into writing.

  Status: DRAFT for architect confirmation. Authored s27 (2026-
  06-29) by LLM(Opus 4.8) after the human's adversarial read of
  the M4-0-03 contract suite. NOT yet a contract. This note
  exists to converge the *model* before we trust §3/§4 of
  input-contracts.md, which the suite exposed as mechanism-framed.

  Why a separate note: input-contracts.md is the suite's source
  of truth and is human-blessed; this note must not silently
  rewrite it. It records the divergence and the proposed model so
  the architect can decide whether to amend the record.
-->

# Input routing — the mental model (and its controversy)

## 0. The trigger

The M4-0-03 suite was authored top-down from `input-contracts.md`
§3/§4 and passed cold review. On human read it drew a consistent
adversarial objection, sharpest on the keypressed rows:

> "does our design not presume that the **route** decides whether
> an event reaches the widget? In this form 'widget up → widget
> consumes' is **transitional** behaviour, not **preservable**.
> The preservable invariant is that the event reaches *some*
> consumer."

That objection is correct, and it is not a suite defect — the
suite faithfully renders the record. The defect is one level up:
§3/§4 describe **today's mechanism as if it were the invariant**.

## 1. Two models

**Model A — widget-centric routing (what the suite encodes).**
Routing is keyed on **widget presence**: widget up ⇒ the widget
consumes; widget down ⇒ the route consumes. The widget is a
first-class routing switch. This is literally the current gate:
`if love.state.user_input then user_input.C:keypressed(k) else …`
(`controller.lua`).

**Model B — route-centric dispatch (the target; the human's
model).** Routing is keyed on the **active route**
(ConsoleController / EditorController / ProjectInputController),
selected by app mode/context. A **widget** is a subordinate input
surface that the active route *activates to solicit input*; it
never determines routing by merely existing. The overlay gate is
a transient, crude simulation of "the running project's route"
via a global flag — and M4 **deletes** it.

The vocabulary lock of s27 (route / sink / widget) already states
Model B: widget = "route-managed surface." But §3/§4 of the
record still describe Model A. **The vocabulary converged; the
model did not.** That gap is what kept "non-controversial input
architecture" out of reach.

## 2. The invariant (Model B, stated to be memorised)

> **Every input event — keyboard, text, AND pointer — reaches
> exactly one route: the active one, fixed by the (exclusive)
> screen mode.** Never zero (no silent drop), never two.
> *Which surface a route uses internally — activating a widget, or
> delivering a click to a surface it has hit-tested — is
> intra-route and invisible to this invariant.*

The screen is always in exactly one mode — console, editor,
project-running, or a special/transitional mode (e.g. `inspect`).
Modes are mutually exclusive, so the routes they bind are mutually
exclusive, so **inter-route dispatch is exclusive for *every*
event type.** The active route is chosen by **mode/context**,
never by a global widget flag.

### 2.1 Correction (s27, cont.): pointer is exclusive too

An earlier draft of this very section asserted an asymmetry —
keyboard EXCLUSIVE but **pointer BOTH** ("a click reaches both a
route and a surface, because pointers are positional"). On the
architect's read that asymmetry does not survive: when a project
is running, a click is **not** propagated to the editor route; the
running mode owns the whole screen. There is no principle under
which a second top-level route would receive the pointer.

Where did "BOTH" come from? The same place every other drift in
this record came from — **the current implementation, promoted to
invariant without provenance.** The keyboard path has the overlay
gate; the mouse path does **not**, so today a click happens to
reach both the underlying controller and the widget. That accident
was read as "pointers are BOTH by nature." It is the *third*
instance of the same disease (after widget-presence keyboard
routing and the `keyreleased` drop): mechanism-as-contract,
pointer edition.

The only legitimate "both" is **intra-route**: an active route may
internally deliver one event both to its own logic and to a
surface it has activated — a project seeing modifier/nav keys *in
parallel* with an editing widget is the literal "parallel
handling" the ticket (tier-1) asks for. That parallelism is the
route's own business, applies to keyboard as much as pointer, and
is invisible to inter-route dispatch. So the durable distinction
is **not** keyboard-vs-pointer; it is **inter-route (exclusive,
all events) vs intra-route (the route's private affair)**.

Suite impact (adds to §5): the mouse **P4 "reaches BOTH route and
widget"** row, with its teeth (drop `user_input.C:mousepressed`
→ red), encodes the pointer accident and is **mis-bucketed**
exactly as the keyboard rows were. It must be re-derived as
"pointer reaches the active route; intra-route forwarding to a
widget is the route's concern" — not as an inter-route BOTH.

## 3. The precise cut: inter-route vs intra-route

The human's intuition, stated precisely:

- A widget **never** changes **inter-route dispatch** (which route
  gets the event).
- A widget **may** change **intra-route handling** (how the active
  route processes the event it received — e.g. the project route
  delegates text editing to a soliciting widget).

Therefore **"widget up in console mode"** — the way the suite sets
up via a free-floating `show_widget()` while `app_state='ready'` —
is an **incoherent scenario under Model B**. A widget only appears
when the project route is active. The genuinely preservable
behaviour (project running + soliciting ⇒ the project surface gets
keys, the console does not) must be founded on **which route is
active** (`app_state` / project-running), **not** on
`love.state.user_input ~= nil`. Re-expressed that way the
invariant survives *and* M4 stays free to remove the gate.

## 4. Where today's overlay gate fits

`love.state.user_input` (the singleton `UserInputController`
exposed globally) is **the running project's route, crudely
expressed as a global flag**. It is used only by a running
project. M4 replaces it with a first-class `ProjectInputController`
sibling to Console/Editor. So:

- "widget-up reroutes everything" = **transitional**, to be
  removed. It must **not** be a PRESERVE contract — preserving it
  would red the suite when M4 does the correct thing.
- The same `UserInputController` class serves **two roles** today
  — the console REPL line (`CC.input`) and the overlay widget
  (`love.state.user_input`). This dual role is the root of the
  "twisted / hard to follow" feel and of the sink/widget overload.

## 5. What this means for the M4-0-03 suite

The suite did the mechanical job well (real teeth, genuine
migration — old specs deleted not accreted, the method-name spy
gone, the four buckets present). But several Bucket-A rows encode
Model A and are therefore **mis-bucketed**:

- **keypressed/textinput "reaches only the widget when one is up"**
  (P1/P2 widget-up halves) — Model-A framing; re-found on active
  route, or demote to CHARACTERIZE-PROVISIONAL (changes at M4).
- **keyreleased "does not reach the route under a widget"** (P3) —
  the human reads this as "exactly the bug we are going to combat."
  Under Model B a release should reach the active route. Provisional
  at best; possibly a defect to fix, not preserve. (Open: is any
  consumer consuming `keyreleased` at all today? maybe do not route
  it.)
- **wheel "reaches the route, never the widget"** (CP2) — already in
  Bucket D, correct; but the *framing* "route not widget" is
  Model-A phrasing of a route-dispatch fact.

Independent of the model error, the read surfaced recurring themes
to carry into the re-derivation:

- **PRESERVE vs CHARACTERIZE confusion.** Several rows assert
  *observed* behaviour as *mandated* with no decision behind it
  (global shortcuts non-consuming P7; play-mode shortcut set). If
  no one decided it must hold → Bucket D, not A. Each PRESERVE row
  needs a provenance: *who mandated this?*
- **Fixture fidelity.** The ~35-line `main.lua` reproduction in
  `input_fixture` has no clean, referenced boundary (drift risk —
  wrap as a single `mock_compy_bootload`, cite the `main.lua`
  lines). `show_selectable_widget` hand-wires `love.state.user_input`
  instead of letting the singleton own it (mechanism coupling).
  The editor block-nav row drives `EditorSession` (the consumer's
  *internals*) rather than asserting the framework *delivers*
  events to the editor — wrong altitude; mixes concerns.
- **Forward-API naming.** `on_event`, `active_keyboard_route`,
  "legacy native handler" were invented by the author. Human's
  refinement: a project setting its own `love.keypressed` is
  **legitimate, not legacy** — the contract is that when the
  project sets no handler, the default propagates to the active
  route's sink; "legacy coexistence" is the wrong frame for I3/I5.

## 6. Recommended resolution

Fix the **model in the record first**, then re-derive — do **not**
patch the suite first (that would re-encode Model A in nicer prose):

1. Amend `input-contracts.md` §3/§4 so EXCLUSIVE is stated on
   **active route by mode/context**, with widget-presence demoted
   to a characterization of today's mechanism (§3.x notes), not the
   contract. Keep outcomes; change the framing.
2. Re-bucket: the Model-A rows move PRESERVE → CHARACTERIZE-
   PROVISIONAL (or are re-founded on active route). Add provenance
   to each surviving PRESERVE row.
3. Then re-derive the affected suite rows from the corrected record.

The mechanical scaffolding (fixture, buckets, teeth discipline,
pending-forward pattern) is sound and should be **kept**; this is a
framing correction, not a teardown.

## 7. Open questions for the architect

- **inspect mode route** — still design-silent; CP1 characterizes
  it. Which route owns inspect after unification?
- **keyreleased** — does any consumer consume it today? Route it,
  or route-without-processing, or not at all?
- **non-consuming global shortcuts** — mandated invariant, or
  incidental? (Framework may want case-by-case propagation.)
- **provenance discipline** — should every PRESERVE row cite *who
  mandated it*, to keep "observed" from masquerading as "required"?
