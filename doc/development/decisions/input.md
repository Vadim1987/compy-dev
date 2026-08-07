---
description: The why behind Compy keyboard/text input routing and the project-facing input widget — the ratified decisions
status: active
audience: developer
authored: llm
reviewed: none
---

# Input subsystem — architecture & key decisions

The *why* behind Compy's keyboard/text input routing and the project-facing input widget.
For how it works under the hood — the exact dispatch order, the mechanism behind each
guarantee, file-by-file wiring — see [`../internals/user_input.md`](../internals/user_input.md).
For the project-author usage guide — the `show()` config table, worked examples — see
[`../../input_api.md`](../../input_api.md). This doc records the decisions those two describe;
it does not restate their mechanism.

The surface these decisions describe ships as **1.0.0-rc20260712**; "the input API" below
always means that surface.

The subsystem replaced an older input API that was polling-based and routed by widget
presence. Understanding what it was chosen *over* is most of the rationale, so the contrast
appears throughout.

---

## Vocabulary — hook, callback, handler

Three words name assignable functions in this subsystem; they are kept distinct on purpose.

- **hook** — a function keyed by a **LÖVE event name** (`hooks[event]`: `keypressed`,
  `textinput`, `keyreleased`). The namespace is **closed and externally defined**: it can only
  ever hold names LÖVE itself emits. You never invent a hook name.
- **callback** — a function keyed by a **Compy-chosen name** (`callbacks.on_text_entered`,
  `validator`, `highlighter`, `on_limit_reached`). The namespace is **open and Compy-defined**:
  the names are ours to extend, and none of them is a LÖVE event.

Both are mount points for a function, so it is tempting to collapse them into one concept. We
do **not** — the split records *which authority owns the name*. A closed, LÖVE-dictated event
set and an open, self-authored callback set are different contracts even where the assignment
mechanics coincide; merging the vocabularies would erase that boundary just where a reader most
needs it.

- **handler** — exactly what LÖVE means by it: the function occupying `love.<event>`, and the
  `love.handlers[name]` entry that dispatches to it. Compy adds no second sense; where this doc
  says "handler" it is always the runtime one.

**Where that trips people up.** A project writing `love.textinput = f` believes it is installing
a handler. It is not. While the project runs, the route owns `love.textinput`, and the project's
function is captured and seeded as `hooks.textinput` (Decision 10) — it runs in hook position,
with hook semantics (truthy consumes). Writing `compy.input.hooks.textinput = f` says the same
thing plainly, and is the encouraged form.

**Pointer events used to be the exception; they no longer are** (Decision 25). A project's
`love.mousepressed` and friends are seeded and run in hook position exactly like the keyboard
ones, so the paragraph above applies unchanged to every channel. The hook namespace is still
closed and externally defined, with one qualification: it also holds the two events the framework
*derives* rather than receives — `singleclick` and `doubleclick`. LÖVE does not emit those; the
click timer synthesises them and emits them through the gateway, so they are hooks by the same
rule that governs the rest.

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

## Decision 2 — a three-component chain with truthy-consume

**Decision.** Inside the active route, every keyboard/text event runs one chain of three
components, in order:

> REMARK: any real reason to treat widget specially? why not interpret it as any other chain element? I feel special treatment is an artifact of design hallucinations that were self-inflicted and dissolved. I see no reason to treat widget separately -- and if we discard decision 5, codebase change would be minimal and won't change any behaviour

1. **`shortcuts[event][combo]`** — per-combo functions the project registered (Decision 8's
   per-event keying and canonical-combo normalisation apply unchanged).
2. **`hooks[event]`** — one per-event hook, absorbing both the old per-event generic
   callback and the legacy project `love.*` handler seeding path into one hook (Decision 10).
3. **the widget** — terminal, always invoked while the route is active. Its *shownness*, not its
   return value, decides whether it consumed the event: shown → the widget runs and the chain
   reports consumed; hidden → the widget is skipped and the chain reports not-consumed (Decision
   5 explains why the widget's own return stays chain-meaningless).

> REMARK: now its more than three components, we are sending pointer events the same way!
A **truthy return at any component consumes** the event: it travels no further, the widget
included. A falsey return falls through. The same three-component shape runs on all three
channels (`keypressed`, `textinput`, `keyreleased`); a component with no participant simply
falls through.

> REMARK: "there was once" is irrelevant -- a history of hallucination, self-inflicted and dissolved during implementation. Does not have to be mentioned
**No framework tier.** There was once a fourth, leading component — `framework handlers` —
non-overridable and not exposed to project code, that claimed Enter/Escape unconditionally while
the widget was shown. It is deleted outright, code and tests: it existed solely to give
Enter/Escape special handling inside the route, and that job is now done by the widget's own
default behaviour (Decision 6) plus the gateway's power keys, which were never part of
this chain and are unaffected. A project shortcut can now be registered on Enter/Escape and win,
exactly as it can on any other combo — the DOM-style "handled stops propagation" convention below
now applies without a carve-out.

> REMARK: 'old four-component shape' was pure hallucination, remove its mentions from here

**Why.** One uniform shape on every channel is the predictability meta-rule made concrete:
nothing "special" gets its own routing rule; a released key and a typed character travel the
same path a pressed key does. The truthy-consume convention is the familiar DOM-style
"handled-stops-propagation" that projects already understand. The old four-component shape
special-cased exactly two keys (Enter, Escape) at a component that existed for no other purpose;
removing it doesn't lose capability — it removes a component that was purpose-built for a job the
widget can now do itself, uniformly, like any other chain participant.

> REMARK: "de-facto SDL articat" is vague and its not clear how its relevant here
**Recognized external constraint — no cross-channel ordering guarantee (an inherited
platform fact, not a decision of this subsystem's).** LÖVE/SDL documents *no* ordering
between the `keypressed` and `textinput` channels for a single keystroke — upstream's
`keypressed`-before-`textinput` is a de-facto SDL artifact, and the target device has been
observed delivering the reverse. The independent-channel shape above is what makes that a
non-issue rather than a hazard: a project judges typed text on the `textinput` channel (in
`on_text_entered`), never by gating a glyph on a `keypressed` flag, so the design is
order-*independent* — strictly safer than depending on an order the platform never promised.
The corollary for tests is binding: a spec must **not** bake a canonical
`keypressed`→`textinput` order in as an invariant, or a synchronous harness goes green while
the device fails.

> REMARK: 'consuming-is-not-removing' is an artifact of self-reasoning across hallucinations. nothing nowhere required 'consuming' to be 'removing', so defending against it makes no sense. I'd remove whole paragraph -- it speaks about what is *not* supported, while this not-supported was also never-requested or never-assumed
**A load-bearing distinction: consuming is not removing.** A component consuming an event
for *this* keystroke never removes a lower component from the configuration. Configuration is
permanent; flow is decided per-event. There is no replace-semantics anywhere in the chain —
assigning a hook replaces *that hook only*, it does not detach the widget beneath
it. This is what lets the widget be a permanent terminal fixture rather than something the project
wires up and can accidentally unwire.

> REMARK: this is proper approach and it contradicts with  formula few paragraphs before (supposedly stale) that says widget state is "checked at the end of chain, and bypassed if not shown" -- which was fully unnecessary complication hopefully dissolved since then
**A load-bearing decision about the widget: its hidden-check is internal.** The terminal widget is
always invoked; it decides for itself to no-op when it is hidden. There is no external
"is it shown?" wrapper gating the call. This is why widget visibility carries no routing weight
(Decision 1) — the branch lives inside the widget, where it mutates nothing and only debug-logs.

> REMARK: its really not exactly this way -- we still use 'ifs' because we decided not to plumb tables with 'no-ops' default. so this paragraph could be recalibrated to reality or removed
**Consequence.** Dispatch is the uniform short-circuit shape this design always aimed at:
`shortcuts(...) or hooks(...) or widget(...)`, because the widget's participation now derives
from a boolean (shown?) rather than needing a special nil-guard the way a sparse combo table
does.

## Decision 3 — one boot-provisioned shared widget, not per-session construction

**Decision.** The input widget is a **shared instance, created once at load** and reused across
every session — one boot-provisioned widget, not per-session construction. Projects reach it
through the `compy.input.*` surface and never hold the widget object.
`show()` / `hide()` are state flips on that one instance, not construction and teardown.

**Why.** A non-functional requirement forbids allocating a fresh object graph per input
session — the device is memory-constrained and the common pattern is repeated prompting. A
shared instance also makes the "hide and bring back with state intact" requirement fall out for
free: the state was never destroyed. And it is what makes Decision 1 cheap — a shared surface
whose show/hide are pure state changes has nothing to reconnect.

>REMARK: "same code" (which is kinda true? check) does not mean "same instance" -- and there are reason to limit 'singleton' to project widgets only. prose below was a pre-implementation vision -- but implementation at least currently ended with the different instances (console needs to maintain its own). So the prose below should be recalibrated to reality
**Consequence.** The same widget code backs the console REPL, the editor input strip, and
project overlays; what differs between them is the evaluator attached and which route handles
the result — not the widget. `show()` on an already-active session is a no-op (it *warns*
rather than swallowing — see Decision 7's discipline) unless `{force = true}` is passed.

## Decision 4 — callbacks replace polling

> REMARK: replace "input events" with "events originated at input widget" -- to not confuse inbound events and outbound ones. Or if we speak both classes, let's make the paragraph more clear about it . right now it reads like other input events are the same as 'submission' which is not true and confuses reader. rewrite the opening to be unambiguous about context -- message itself (the prose which follows the opening) is correct -- we discard polling idiom.

**Decision.** Submission and all other input events are delivered through **callbacks and
handler tables**, never through a polled reference. The legacy text-input globals and the
reference-variable idiom they fed are **removed outright** — no shim, no compatibility flag.

**Why.** Polling is inconsistent with LÖVE's event-driven style and forced every project into a
per-frame re-check. Callbacks eliminate the poll, and — combined with Decision 1 — eliminate the
keyboard lockout that made polling-plus-hotkeys impossible in the first place. The clean break
(rather than wrapping the old functions) was a deliberate stakeholder call: this is pre-1.0, the
full set of callers is known and small, the examples exist to demonstrate good code, and a
legacy shim left in a release would teach the pattern the feature exists to retire. The break is
bounded to text fields; the project's keyboard handling keeps working (Decision 10).

**Consequence.** The old globals (`input_text`, `input_code`, `validated_input`, `user_input`,
`write_to_input`) are gone from the project environment as ordinary `nil` fields. Their examples
migrate to `compy.input.*`; the replacement mapping is documented in the usage guide.

## Decision 5 — two directions, two surfaces; the limit signal travels fully through the output side

> REMARK: its the good moment to say "chain routes events into the route where they are consumed by shortcuts/hooks. The widgets reports results out through *callbacks*". Which is exactly the difference in terminology -- callbacks originate during input processing, shortcuts/hooks consume inbound OS events. Important part here is using term "callbacks" instead of "widget outputs" which are not defined anywhere.

**Decision.** The chain routes events *into* the active route. The widget reports results *out*
through its own configured **widget outputs**, which are **not** chain components:

- `on_text_entered(lines)` — fires at submit, with assembled line strings.
- `on_limit_reached(direction, scope)` — fires when the cursor tries to move past a boundary
  (`direction` up/down/left/right; `scope` whole-input or current-line).
- `validator(lines)` and `highlighter(lines)` — widget behaviour; the
  highlighter is display-only and the validator gates submit.

These are set at `show()` / `configure()`, or assigned as `compy.input.callbacks` fields — one
underlying callback, two ergonomics.

> REMARK: conflating them is not generally a trap -- so no need for this false rationalization. Just say we distinguish
> REMARK: overall this block has too much self-invented explanation, including 'student' passage. No need to overprotect the normal engineering decision.
 
**Why.** Routing has two genuinely different directions and conflating them is the trap this
subsystem was explicitly designed around. Events arriving are a chain concern; a *result* is the
widget's to announce. In particular:

- **`on_text_entered` is widget vocabulary, not the per-character chain callback.** The
  per-character textinput callback is `hooks.textinput` — the chain's hooks component (Decision
  2). The two names are never interchangeable — an easy and costly confusion, kept apart by
  naming on purpose.
- **Results never travel as chain return values.** The widget is terminal, so nothing sits above
  it to read a return; a boundary or submit condition therefore *cannot* report upward through
  the chain and must use the widget's own outputs. (This is the narrow thing the "no results via
  return values" rule fixes — it is a consequence of the widget being terminal, not a general ban
  on status returns.)
- **The limit signal travels exclusively through `on_limit_reached`.** `UserInputController:
  keypressed`'s return value used to carry a *second*, undocumented meaning alongside
  `on_limit_reached` — a vertical-limit flag — a quiet violation of this decision's own rule (the
  old code set the flag *and* fired `on_limit_reached` in the same branch, redundantly). That
  dual channel is retired: the return value now carries only the chain-consumption signal
  (Decision 2), and `on_limit_reached` — already a widget output under this decision, just
  underused before — is the sole notification path.

**Consequence.** A project gets soliciting input working with nothing but
`show{ ...callbacks... }` — no chain knowledge required. That "easy path" is the pedagogical
target the whole two-surface split protects. Console's history navigation (Page-equivalent
Up/Down at a boundary), the one live consumer of the old return-value channel, is wired through
its own instance's `on_limit_reached`, filtered to the vertical direction; no other consumer
exists — editor's search widget reads its own, unrelated return contract and is untouched
(a discovered, pinned behaviour; see Decision 14).


## Decision 6 — submit and cancel are widget-owned callback-driven flows, not a framework tier

> REMARK: if it does not differ from pre-feature behaviour, there's no decision to record at all.  Why this decision arrived -- attempt to combat design hallucination which assigned special roles. If as a result we just got back to normal platform behaviour, there was no decision worth standing in this register. IF we did de-facto change the behaviour -- the whole 'decision' block should be compressed 2-3 times and explain only change and why it was necessary/useful. Right now block of decision 6 is overbloated and its not clear which exact decision it describes and what was its rationale/consequences.

**Decision.** Enter and Escape are ordinary chain participants (Decision 2), not a framework
tier. The widget provides their *default* behaviour as callback-driven flows of its own, not
framework-owned ones:

```
submit_flow:  before_submit() → validator → on_text_entered → after_submit()
cancel_flow:  before_cancel()  →  clear (hardwired, unless vetoed)         →  after_cancel()
```

Three substantive changes from the original framework-tier shape:

- **`before_cancel` may veto.** A truthy return from `before_cancel` skips the clear step
  entirely — symmetric with the (still-reserved, unbuilt) `before_submit` veto below.
- **Auto-close default flips to OFF.** `after_submit` and `after_cancel` default to no-ops — the
  widget **stays open** unless a project explicitly hides it. There is deliberately no keep-open
  flag (that would be the old one-shot mechanism reborn with its polarity flipped); a project
  that wants the old "prompt once, then close" behaviour opts in with one line:
  `after_submit = function() compy.input.hide() end`.
- **Enter/Escape are shadowable.** A project shortcut registered on `'return'` or `'escape'` now
  wins over the widget's default, same as any other combo — a named, deliberate withdrawal of the
  old guarantee (below).

**Withdrawn guarantee — recorded explicitly, not left implicit.** Nothing any longer prevents a
project shortcut from shadowing Enter's submit or Escape's cancel while the widget is shown, and
a project overriding `after_submit`/`after_cancel` owns the lifecycle act itself. This was never
a stakeholder requirement: the round of requirements gathering that preceded this feature left
the cancel/dismiss notification explicitly unresolved, recorded verbatim as *"may be expected —
to be confirmed"*, and it was never confirmed. The non-overridable shape was a design-team fix
for an earlier `oneshot` two-role problem (below), not an external mandate. Withdrawing it is acceptable specifically because it is not the only safety
net: the gateway's **power keys** (Ctrl+Q, Ctrl+Break, etc. — `controller.lua`, pre-dating this
feature) remain unconditional and unshadowable, running before any route dispatch, chain
included. That is the actual, permanent escape hatch; the framework tier was never it.

**Uniform across every instance — no context reads global state to suppress the flows.**
`UserInputController:keypressed` runs **one** path regardless of caller: there is no
`love.state.app_state` branch inside the widget deciding whether submit/cancel run. A context
that must not run the flows arranges it itself, at its own layer, rather than the widget
interrogating global state:

- the **editor** consumes Enter/Escape **upstream** — each handled branch of its own `submit()`
  (plain Enter, Ctrl+Enter) and `load()` (plain/Shift Escape) calls `block_input()`, so the
  shared widget's `submit_flow`/`cancel_flow` never run for the keys the editor owns; the one
  Enter variant it does not handle (Alt+Enter) falls through to the widget harmlessly, because
  the editor sets no callbacks;
- **console** sets no `before_*`/`after_*` callbacks, so its own instance's flows run and are
  no-ops alongside its real work (`evaluate_input`, history navigation);
- the **project overlay** sets callbacks for real — that *is* its submit/cancel.

The editor-only Ctrl+D duplicate-line (`modify`) follows the same principle: it is a per-instance
**`allow_modify`** constructor flag (`UserInputController(model, disable_selection,
allow_modify)`), set only by the editor's own input and mirroring `disable_selection` — a widget
capability the owner enables at construction, not something the widget reads from global mode.

**Why.** The original framework-tier shape existed to solve a problem that no longer exists in
the same form: the pre-redesign widget served two incompatible roles (self-owned submit for the
project overlay vs. controller-owned submit for console/editor) with no shared dispatch layer
between them, encoded in a static `oneshot` flag — deliver-and-close and dismiss were
session-lifecycle acts placed above the widget's pay grade, and an earlier limitation where
Escape cleared content but could not actually dismiss came precisely from the widget owning
Escape. Once a uniform chain exists (Decision 2), that problem dissolves without needing a
reserved tier — the "widget owns detection, context owns lifecycle" separation that originally
fixed the Escape-can't-dismiss bug is preserved by making dismissal the callback's job, not the
framework's. A later refinement — briefly, the widget reading `app_state` to suppress its own
flows specifically in editor mode — reintroduced the same abstraction leak in a smaller shape: a
reusable input widget branching on global app-mode cannot be reasoned about, or migrated, without
knowing it is "the editor." Moving the suppression to the editor's own upstream interception
instead removes the fork from the widget entirely; the context owner decides interception, and
the widget stays unaware that interception can even happen.

**Consequence.** Deactivate-on-submit is no longer even a route-level policy question — it is
per-*callback* configuration, one level more granular, and console/editor inherit "stay open" for
free without fighting a hardcoded hide. Because `UserInputController:keypressed` is genuinely
uniform across every instance, a future editor migration (Decision 1) extends the same seam the
editor already uses for `disable_selection`/`allow_modify`, rather than having to rip out a
mode-read. `hide()` (the programmatic path) fires **no** cancel flow — cancel is the user-facing
Escape path only. A `before_submit` veto return remains a deliberately reserved extension —
ignored today, but not precluded; blocking bad input at submit is already the validator's job.

## Decision 7 — freeze the container and its sub-table identities; leaves are writable
> REMARK: the decision is very trivial, I do not think its worth documenting, or should be literally few lines

**Decision.** `compy.input` itself, and the *identity* of each of its three sub-tables
(`shortcuts`, `hooks`, `callbacks`), are frozen — a project cannot do
`compy.input.shortcuts = {}` or replace the container. Every **leaf** inside those sub-tables is
freely writable: `shortcuts[event][combo] = fn`, `hooks[event] = fn`, `callbacks[name] = fn`.
Everything else — `show`, `hide`, `configure`, `clear`, the cursor/text calls — is callable API
that **errors loudly on assignment**.

`callbacks` carries **eight** members — the five lifecycle fields (`on_text_entered`,
`before_submit`, `after_submit`, `before_cancel`, `after_cancel`) plus `on_limit_reached`,
`validator`, `highlighter` — unified under one definition: **a callback is any function the
widget itself invokes**, whether on a lifecycle trigger, at submit-time validation, or at render
for highlighting.

**Why.** The surface has to be simultaneously configurable (projects wire callbacks by plain
assignment, LÖVE-style) and tamper-resistant (a project must not be able to replace `show`, or
replace a whole sub-table wholesale). The original rule drew that line by hand-enumerating exactly
11 writable field names and refusing everything else — loudly, never a silent swallow, per the
house warn-don't-swallow discipline — which required keeping the list in sync with the API
surface. The current rule is one sentence and self-enforcing structurally: refuse all
direct-container and sub-table-identity writes; nothing to enumerate. The guard's *purpose* —
tamper-resistance against a project replacing callable API — is undiminished; it just moved from
a flat allowlist to a shape rule. The guard lives in the surface's metatable (one level down for
each sub-table), so a stray or mistyped assignment fails at the point of the mistake rather than
corrupting the API.

**Consequence.** `shortcuts.keypressed`'s normalising behaviour (Decision 8) must stay reachable
only through its combo-keyed leaves, never through wholesale sub-table replacement — the
frozen-identities clause exists specifically to protect that invariant.

## Decision 8 — per-event combo tables and canonical combo serialisation

> REMARK: rewrite -- now 'combo-tables' are reproduced without explanation. Instead the solution was to support combo-tables at all (to avoid stuffing all event-handling logic in a single hook and enable modularity). The way combo tables are assembled and checked is downstream tactical decision -- we took the simplest form. So the full block has to be rewritten 

**Decision.** The combo tables are keyed **event-type-first** and live on
`compy.input.shortcuts`: `shortcuts.keypressed[combo]`, `shortcuts.keyreleased[combo]`,
`shortcuts.textinput[combo]`. A single flat `[combo]` table serving all channels is forbidden.
Held keys and combo strings use two deliberately different representations:

- the **held-key set** keeps precise left/right names (`lctrl` ≠ `rctrl`);
- **combo serialisation** folds left/right and orders modifiers in fixed precedence
  (`ctrl`, `alt`, `shift`, `gui`), `+`-joined — `"ctrl+s"`, `"alt+shift+f4"`, bare `"escape"`.

`shortcuts` tables normalise assigned keys to canonical form on assignment, and dispatch matches
through an overloadable matcher (default exact match), left as a marked seam for future
glob/prefix needs.

**Substance unchanged; container renamed.** This decision's mechanics — per-event keying,
normalisation-on-assignment, the matcher seam — are exactly as originally ratified. Only the
container's name changed: the table was called `handlers`, now **`shortcuts`** — `handlers`
collided with LÖVE's own vocabulary (a local variable literally named `handlers`, bound to
`love.handlers`, sits in the very gateway function this subsystem's dispatch discusses), and the
combos are, in effect, project-registered shortcuts (`ctrl+s` etc.), so the new name reads
naturally. `hooks[event]` (Decision 10) is now symmetric with `shortcuts[event]`.

**Why.** One flat combo table across channels was a known derivation-drift attractor — it makes
a keypressed combo and a textinput combo collide in one namespace. Per-event keying keeps them
separate by construction. Folding l/r only at serialisation gives projects a stable, readable
combo string to register against while preserving the precise held set for anyone who needs to
tell the two Ctrls apart. Normalising on assignment means a project can register `['Ctrl+S']`
and still match.

**A second, adjacent naming collision, resolved.** The gateway's unconditional, pre-route keys
(Ctrl+Q, Ctrl+Break, etc.) are called **power keys** in this subsystem's own prose, deliberately
avoiding the bare word "shortcuts" for them — reusing "shortcuts" for both the gateway's
unconditional keys and `compy.input`'s project-registered, fully-overridable table would violate
this same taxonomy's own "reserve each word for one role" principle. The in-code comment
(`controller.lua`, already labelled "Power shortcuts") is unchanged; "power keys" is this
document's label for discussing the same concept without the collision.

## Decision 9 — uniform signatures and `isrepeat` threading

**SUPERSEDED, 2026-08-07** — see Decision 26. The number is kept so the citations that name it
still resolve; the content below is what was decided, not what the code does.

**Decision (superseded).** Every participant on a channel receives the same signature, the widget
included: keypressed carries `(k, keys_pressed, isrepeat)`, textinput `(text, keys_pressed)`,
keyreleased `(k, keys_pressed)`. On the project route, `isrepeat` is threaded through every
component of the chain (Decision 2).

**Why it was decided.** A single signature per channel is the uniformity that lets the widget be
just another participant rather than a special case. `isrepeat` was restored so a project can
distinguish a held-key repeat from a fresh press.

**Why it did not survive.** The signature was uniform across compy's three keyboard/text channels
and different from LÖVE's on all of them, while pointer channels already passed LÖVE's arguments
verbatim — so "uniform" held within a subset and broke at its edge. Decision 20 then made
`compy.input.keys_pressed` globally readable, which is where a project must read it anyway (a
per-frame draw has no event argument), leaving the threaded copy with no job. Decision 26 keeps
the uniformity and drops the invention: every consumer gets LÖVE's own list.

**What survives.** `isrepeat` still reaches every consumer, in LÖVE's own third position. And
`shortcuts` dispatch still does not gate on it — a shortcut fires on every repeat, and a binding
that wants once per physical press wraps itself in `compy.input.fn.ignore_repeat` (Decision 22),
which is the wrapper that replaced the deferred marker this entry once pointed at.

## Decision 10 — one `hooks[event]` table, seeded once at activation

> REMARK: these 'no' sound like protecting against alternatives not-requested-and-not-considered 
> REMARK:  now 'all' events are shaped this way
> REMARK: lets reframe the decision as "new api has more appropriate place for hooks -- so we silently re-wire old 'project-installed callbacks' there -- encouraging new usage but not disabling old one, if it's ever needed for pedagogical purposes 

**Decision.** A project's own `love.keypressed` / `love.textinput` / `love.keyreleased` handlers
auto-provision into `hooks[event]` (Decision 2's second chain component) — no widget-aware
gating, no lifecycle split, no custom logic. `hooks[event]` is a single table and the single
source of truth: at project activation, any event for which the project has not already set an
explicit hook gets seeded once with its captured project handler (if any); after that moment the
table **is** the whole story — nil-ing a hook clears it, full stop, with no fallback
resurrection.

> REMARK: nobody cares which exactly original intermittent shape decision had once if it was rewritten since and dissolved form never materialized in release/contract/doc
**Substance changed from the original pure-wrap.** The original decision resolved the hook
by precedence on **every event**: an explicit `compy.input.on_*` assignment won; otherwise the
captured handler seeded the hook; otherwise a no-op — nil-ing the explicit assignment resurrected
the handler. That two-store precedence rule, re-resolved live, is gone. "Read the handler once at
activation, never re-consult" — the part that matters for correctness — is unchanged; only the
fallback mechanics moved from per-event resolution to a one-time seed, and this is recorded as a
genuine semantic change, not a pure rename.

**Why.** Treating project handlers as ordinary chain participants keeps the model uniform (they consume on
truthy, fall through on falsey, like anything else) and is what makes the keyboard-lockout fix
(Decision 1) reach legacy code too: a project handler now sees events even while the widget is
shown. The alternative — a widget-aware wrapper that gated the native on visibility — would
reintroduce the exact special-case the subsystem exists to remove. "One table, one truth" is also
a strictly more predictable contract than a precedence rule invisible from the table's own
contents — a project (or a debugger) inspecting `hooks.keypressed` could not otherwise tell
whether a handler was silently active underneath a `nil`. The resurrection-on-nil behaviour was
never asked for; it was an artifact of two separate storage locations being resolved late.

**Consequence, accepted.** Because project handlers fire while the widget is shown, the two examples that
combined a project handler with widget solicitation changed behaviour and were migrated alongside
the change. Breaking-and-fixing the affected examples was the explicit expectation, not a
regression to avoid; handler-only projects (no widget) are unaffected.

## Decision 11 — the route is held by an open project, released at its stop
> REMARK: clean up self-arguing with past decisions that were than reshaped before release. WHat was not in released version is considered as never existing (except few bits explicitly ratified by stakeholders) 

**SUPERSEDED IN PART, 2026-08-03** — see Decision 25. The original decision released
keyboard/text at the `'running' → 'project_open'` boundary while exempting pointer, and justified
the asymmetry as inherited platform behaviour. That justification did not survive checking (below);
the release is gone and every channel now shares one lifetime. What stands unchanged is the
teardown invariant, which is the part later decisions depend on.

**Decision (as amended).** The project route occupies **every** input channel — keyboard, text,
pointer and the derived click events — from activation until the project stops. A non-blocking
project reaching `'project_open'` keeps them; `Ctrl+Esc` is the way back to the console. On project
stop, every handler restores to framework defaults and every project participant — handler tables,
callbacks, widget configuration — resets.

**Why the original rationale was withdrawn.** It read: *"This is the established platform
behaviour, adopted as a design constraint because no product ruling motivated changing it,"* and
called the keyboard/pointer asymmetry *"intentional and load-bearing"*. Checked against the PR base
`3256aac`: `set_default_handlers` is called from exactly two sites — `suspend()` and
`stop_project_run()` — and the `running → project_open` transition releases nothing. Both channels
stayed installed until suspend or stop. There was no asymmetry to inherit. `release_keyboard_route`
was introduced *by this feature*, keyboard-only, and pointer then had to be exempted from a release
that had not previously existed — so the exemption was a consequence of the new mechanism, not a
constraint on it. The asymmetry was also unreachable in practice: the release fired only when
`user_is_interactive()` was false, and that predicate is "an overlay or a pointer handler exists",
so at the only moment it ran there were no pointer handlers to exempt.

**Changed baseline behaviour.** Before this API, a running project without its own keyboard/text
handler left the console callback installed. With no shown project widget, unhandled input could
therefore accumulate in the hidden console and Enter could evaluate it. The project route now
occupies keyboard/text handlers for every running project: an event reaches a shortcut, hook, or
shown widget, otherwise it has no effect. A future fallback would need to be an explicit route
participant with its own contract; it must not return by omission.

**Consequence — a teardown invariant.** No callback, combo entry, or widget configuration
survives the project that installed it. Combined with the connection rule, stale configuration can
never act outside its creator's window: a disconnected route's participants receive nothing, and
a widget whose owning route is inactive goes unhonoured. `inspect` mode is the model case of the
latter (Decision 12).

## Decision 12 — `inspect` is a mode-to-route line, nothing more

> REMARK: if its the behaviour system had and keeps having, its not a decision -- its documented de-facto standard

**Decision.** `inspect` (a paused or broken-into project) is simply **the console route active,
bound over the project's environment**. The project route is disconnected exactly as the
connection rule (Decision 11) describes, and the project's own widget is unhonoured because its
owning route is inactive.

**Why.** Framing inspect as a routing state rather than a bespoke mode means it needs zero special
rules — it is the console route plus a choice of environment, and it matches the implementation
exactly (suspending a project restores all handlers to the console). The console running the paused
project's environment makes it a live debugger console rather than a separate idle one.

## Decision 13 — the held-key set is exposed read-only, callback-only

**Decision.** Downstream consumers never touch the live held-key table. Every chain signature's
second argument is a **read-only pressed-keys view**: reads pass through to the live set, writes
raise. There is no project-facing way to *poll* held keys outside a callback — the view only ever
arrives as a callback argument.

**Why.** The held set is framework-owned state maintained at the gateway; letting project code
mutate it would corrupt every downstream consumer. Read-only access covers the legitimate need
(a callback asking "is Ctrl down?") without exposing the write. Keeping it callback-only rather
than pollable is consistent with the callback-over-poll principle (Decision 4) — there is no
per-frame "is this key down?" surface by design.

**Recorded honestly:** on the shipping LuaJIT/Lua 5.1 runtime the view is index-only in
practice — `pairs()` ignores the metamethod that would make it iterable, so iteration yields
nothing; indexing works. The iteration support is kept for a future 5.2+ host. See the
technical-debt register.

**Allocation note.** The implementation caches the view while the backing
held-key table has the same identity, so normal dispatch does not allocate a
proxy per event. This is a non-functional requirement, not a project-facing
identity guarantee: a callback may rely on the view being read-only and
current, never on object equality across calls.

---

## Decision 14 — de-facto contracts: reverse-engineered behaviour is preserved and formalised, not silently changed

> REMARK: only historical correction -- we proactively reverse-engineered system behaviour and codified existing de-facto standards in a tests, and documented some -- therefore canonicalizing them *before* implementation; the fact that some of those came unnoticed until post-implementation controversies resolution is secondary . its mostly about historic accuracy of the first phrase, decision itself stands

**Decision.** Where post-implementation validation of this subsystem discovered behaviour that no
design document mandated — behaviour that fell out of how the code was built rather than from a
ruling — the standing rule is to **preserve it and record it as a contract**, not to "fix" it in
passing. Such behaviour is treated as a **de-facto standard set by the implementation**; documenting
and test-pinning it makes the implicit explicit. Changing any of it is a **separate, owner-gated
decision**, never a side effect of a refactor or cleanup.

**Why.** This subsystem reached its shipped shape partly by accretion — successive consumers (the
project overlay, console, editor, inspect) were integrated by local additions rather than by
extending a shared abstraction, so real, live behaviours existed that no decision named.
Reverse-engineering during validation surfaced them. Altering them opportunistically while "tidying"
would smuggle behaviour changes in under the banner of cleanup — the exact failure mode this
validation phase exists to prevent. Freezing and documenting them instead cleanly separates *what the
system does* (now pinned and reviewable) from *what we choose to change* (explicit rulings).

**Consequence.** Doc entries and tests that record a reverse-engineered behaviour carry this rationale
explicitly ("discovered as existing behaviour, no mandate to alter — de-facto standard per the
implementation"). Current members include: the submit guard being *Enter-without-Shift* (so Ctrl+Enter
and Alt+Enter submit, not only bare Enter); `SearchController:keypressed` returning a jump target up
its caller; and the overlay input view's per-frame-render workaround keyed by widget identity. Each is
individually revisable — but only by a named ruling, not by drift. See
[`../technical_debt/input.md`](../technical_debt/input.md) for the live list.

---

## Decision 15 — unrecognised show/configure configuration raises

> REMARK: its quite trivial and obvious tactical decision, is it even worth documenting?


**Status: in-flight (owner ruling, 2026-07-30); supersedes the warn-and-ignore
form below.**

**Decision.** A key outside the documented config table, supplied to
`show(config)` or `configure(config)`, **raises**. A recognised field that is
only writable by direct assignment — the lifecycle callbacks — is equally
unrecognised in this table and raises with a message naming
`compy.input.callbacks`. `force` is a `show`-only key and raises from
`configure`.

**Why — DevX: strict contract enforcement, explicit failure mode.**
Warn-and-ignore would be right if these functions took a general-purpose
document and applied whichever subset they understood. They do not: the config
table is small and closed, so a key outside it can only be an authoring error.
Ignoring it leaves the project running in a shape its author did not ask for,
with the evidence buried in a log line nobody is reading; raising stops it at
the typo. This also makes the surface uniform — `compy.input.shortcuts = {}`
already raises under Decision 7, so a structural violation raising here
is the rule, not a new one.

**Scope — violations raise, runtime states do not.** A raise means *the project
asked for something that does not exist*. A call that is a no-op because of the
runtime **state** is not that, and keeps warning per Decision 3: `show` on an
already-active overlay without `force`, and `set_text` / `set_cursor` / `clear`
while hidden. Those are legitimate calls at an inconvenient moment, not
mistakes in the project's source.

**Consequence.** `show` and `configure` raise on the first offending key, with
the trace on the project's own call line. A project's error surfaces the normal
way: raised from top-level project code it aborts the run and reports; raised
from a `love.*` handler it suspends the run with the message. The project guide
names the accepted keys, and the retired `eval` / `result` keys now raise
instead of warning.

> REMARK: no need to describe interim forms, invented and dissolved in-flight
### Superseded — the original warn-and-ignore form

**Decision.** An unrecognised key supplied to show(config) will emit a
warning and be ignored. A recognised field that is only writable by direct
assignment is also unrecognised in this table and warns with the same rule.

**Why.** Silent configuration typos have no visible effect and make an
otherwise simple API needlessly difficult to use. A warning gives the project
author an immediate, actionable explanation and follows the subsystem's
existing warn-don't-swallow discipline.

**Why it was revised.** The rationale above argues against silence, and a
warning is the weakest answer to it that still counts as "not silent". It also
left `configure` inconsistent: it dropped unknown keys with no signal at all,
so the same typo behaved differently depending on which function received it.

---

## Decision 16 — defer future input unification
> REMARK: this decision was fully overwritten and de-facto input was unified across events axis (to not be confused with postponed unification of routing mechanisms across cosnole/editor/project which is still deferred). So this block should be removed

**Status: owner-ratified in validation; not implemented in 1.0.0-rc20260712.**

**Decision.** Keep the existing asymmetry: derived singleclick and doubleclick
remain concise compy callbacks, while keyboard/text use the project input
hooks. Do not add click entries to the hooks table and do not route pointer
events through keyboard/text dispatching merely for symmetry.

**Why.** The present pointer system has no requested or feasibility-tested
unified target, combo, interception, or widget contract. Derived clicks are
primary-button timer notifications; raw mouse, drag, selection, touch, and
modifier behaviour follow separate live paths. A superficial shared table
would imply shared dispatch semantics and constrain a future design before a
real demand exists. Preserving the pre-feature split contains this API's scope and
does not worsen the current behaviour.

**Future trigger.** Reconsider only when a concrete demand and a feasible
design exist for unified pointer/click handling, such as modifier gestures,
pointer combos, interceptors, or common pointer-aware widgets. That work must
define raw versus synthetic timing and preserve drag, selection, and touch.

---

## Decision 17 — behavioural evidence is the default test evidence

**Status: implemented.**

**Decision.** Tests for the project input API prove observable project and
framework behaviour through real entry points and public surfaces. Do not add
test coverage merely because an internal edge is reachable; coverage is earned
by the feature's complexity, criticality, and externally meaningful behaviour.

**Exception.** A direct controller/model seam, mock, or interception is
allowed only when it is necessary to isolate a mechanism that cannot be
practically observed through the real path. The test must state why the seam
is used and must not present itself as an end-to-end contract test.

**Why.** Recreating lifecycle or routing logic in fixtures can validate the
fixture instead of the product. A behavioural default keeps the input suite
credible without demanding disproportionate coverage of rare, exotic, or
non-critical internals.

**Execution.** The bounded fixture pass uses real default installation and
project-stop teardown. It retains the narrow activation seam where a full
runner is inappropriate for an isolated handler test, with that reason stated.

---

> REMARK: is it an artifact block describing history which passed? (afaik now 'dispatch'  *is* reusable function) -- review and recheck if it belongs here

## Implementation note — making the mechanism reusable (non-normative, no project-facing contract change)

Two structural extractions rode this redesign, closing a gap between an earlier stated intent and
what had shipped: the roadmap promised a *shared* `dispatch()` reusable by console/editor "later,"
but the dispatch that had shipped was a `ProjectInputController` method reading its own instance
fields, not actually reusable. Neither extraction changes project-facing behaviour — both are pure
refactors:

- **Dispatch as a free function.** `dispatch(shortcuts, hooks, widget, event, trigger, ...)`
  operates over plain tables and a widget reference; `compy.input`'s guarded surface is a thin
  project-facing wrapper *over* it, not the mechanism itself.
- **The widget-method surface as a factory.** The methods `compy.input` exposes
  (`show`/`hide`/`configure`/`set_cursor`/`set_text`/`get_cursor`/`clear`) were hardwired to the one
  global project-overlay instance. A `build_widget_api(get_widget, get_active_flag)` factory,
  parameterized by instance, lets any adopter — not only the project overlay — get the same
  ergonomics over its own instance.

Multiple `UserInputController` instances remain required — console's REPL state must persist
independently through `inspect` mode (Decision 12) and would be clobbered by a single shared
instance. What these extractions share is the *wrapper shape*, never the instance. This resolves a
standing in-tree question about a shared dispatcher without committing to when — or whether —
console/editor actually migrate onto this surface; that migration remains deliberately deferred per
Decision 1's consequence text. Whether to unify further — one instance-record class holding
`shortcuts`/`hooks`/`callbacks`/methods together, with `dispatch` as a method rather than a free
function — was raised and deliberately left open (this codebase states a preference for functional
style over classes, `agents/rules.md`, versus the ergonomic appeal of one cohesive object); not
resolved here.

---

## The ergonomics payoff

The measure of the design is the before/after in project code. The old pattern set up a prompt,
then polled a reference every update tick and manually tore the prompt down; reacting to any key
while the prompt was shown was not possible at all. The new pattern is a single `show{...}` with
the callbacks inline:

```lua
compy.input.show{
  prompt = 'name?',
  on_text_entered = function(lines) greet(string.unlines(lines)) end,
}
```

No per-frame poll, no manual teardown, and — because the project route stays connected while the
widget is shown — the project's other key handlers keep firing throughout. The widget also stays
open by default after a submit or cancel (Decision 6), so continuous prompting needs
nothing more than clearing the field from `after_submit` — there is no re-`show()` involved at
all; richer uses layer on `validator`, `highlighter`, `on_limit_reached`, and the cursor/text
calls. The simple case stays one call; the expressive case is reachable without reading framework
internals.

---

## Implementation alignment

The public `show` table now matches the intended project surface: validation
and highlighting are separate callbacks, submitted values are line arrays,
and a project consumes them through `on_text_entered`. `eval` and `result`
are retired rather than carried as compatibility keys. The internal evaluator
objects used by console and editor remain implementation details.

---

## Decision 18 — the overlay answers one state question: `is_shown()`

> REMARK: let's fully retire ambiguous 'overlay' from everywhere. Its input widget.

**Status: implemented** (owner ruling, 2026-07-31).

**Decision.** `compy.input.is_shown()` returns whether the overlay is
currently up. It is the only state query on the surface, and it is read-only.

**Why.** A project cannot determine this any other way. Its `love` is a
sandboxed deep clone (`../internals/project_sandbox_env.md`), so
`love.state.user_input` read from inside a project is **always** `nil` — the
framework writes the real global, the project sees its copy. Two examples had
already written that read as a guard; it silently never fired, and one of them
therefore re-showed the overlay on every tick.

**Why only this one.** Everything else a project might poll — content, cursor,
error state — it already receives through callbacks, which is Decision 4's
whole point. Shownness is different: it is the one fact the framework changes
without telling the project (a stop tears the overlay down, a hide from another
callback lowers it), so a project that must not act twice has nothing to read.
The internal flag it exposes is the widget's own `is_shown()`, so the answer
cannot drift from the one the dispatch walk uses.

**Consequence.** `show` on an already-active overlay stays a warn-and-no-op
(Decision 3): a project that wants "open it only if it is closed" now writes
that, instead of relying on the warning as flow control.

---

## Decision 20 — a project can read the held-key set outside an event


**Status: implemented** (owner ruling, 2026-08-03).

**Decision.** `compy.input.keys_pressed` is the read-only pressed-keys view
(Decision 13), readable at any time — not only as a dispatch argument. Reads
pass through to the live held set; assignment raises. It resolves on every
access rather than being captured once, so it cannot go stale when the backing
table's identity changes.

**Why.** The same reason as Decision 18: a project's `love` is a sandboxed deep
clone, so it cannot reach the real held set on its own. Until now the view
arrived only as argument 2 of a shortcut/hook/widget call, which serves a
project that *reacts* to keys and fails one that *renders* them: a per-frame
`love.draw` runs between events with no argument in hand.

**The consumer that settled it.** `examples/keyboard` maintains its own
`INPUT.held` / `INPUT.shift` mirror, updated on every press and release, and
reads it during draw to decide whether to render shifted key labels
(`keyboard_view.lua`). It is a hand-built copy of a table the framework already
owns, and it exists because there was no way to ask.

**Placement.** On `compy.input`, beside `is_shown()`, rather than as a new
top-level `compy.keys_pressed`: it is input state, the input guide is where a
reader looks for it, and `compy`'s other members are subsystems. The ruling was
to expose the table; this placement is the implementation's choice.

**Not a new capability.** It is the same view, with the same read-through and
write-raise contract, reachable from a second place. Iteration remains inert on
the shipping LuaJIT runtime (`pairs` ignores `__pairs`), so it is index-only —
`keys_pressed['lctrl']`, not a loop over held keys.

---

## Decision 21 — a combo names modifiers plus one trigger, or a class

> REMARK: historical references (when exactly was something decided) bear no value, strip them

**Status: implemented** (owner ruling, 2026-08-03).

**Decision.** A combo string is modifiers plus **exactly one** trigger token.
A combo naming two triggers, or none, **raises at registration**. The trigger
may be the marker `*`, which binds the whole modifier class: `alt+*` is every
Alt chord. Dispatch tries the exact combo first and consults the class only on
a miss, so an exact binding always wins. A class never matches when the
trigger is itself a modifier.

**A bare `*` raises** (owner ruling, 2026-08-03). It satisfies the one-trigger
rule, and the empty modifier set is a class like any other, so it would bind
every *unmodified* key — `q` yes, `ctrl+s` no, that being the `ctrl+*` class.
But "every key on this channel" is exactly what `hooks[event]` is, and a
second spelling for it that reads like a narrow binding is the kind of thing a
reader has to be told about rather than can infer. A class needs modifiers to
be a class *of*; the raise says so and names the hook as the alternative.

**Why the rule is enforced rather than canonicalised.** The canonical form kept
the *last* non-modifier token and dropped the rest, silently: `ctrl+a+b` was
stored as `ctrl+b`, and `a+b+*` as a bare `*` — the widest binding there is,
from a string written to mean the narrowest. Raising is the treatment
`show`/`configure` already give an unrecognised key (Decision 15).

**Why classes.** Some rules are about a modifier class, not a key: *every*
`alt+x` is a chord, whatever `x` is. Without the class form a project writes
one entry per key, or keeps the rule in a hook and hand-tests the modifiers —
which `examples/keyboard` did, and which needed an explicit "and not Ctrl"
clause to keep `ctrl+alt+h` out of the Alt class. A class gets that exclusion
for free: a different modifier set is a different class.

**Why the trigger, not the modifiers, may be starred.** The ratified combo
format is a *serialisation* — modifier-first fixed precedence, l/r folded,
`+`-joined (frozen design, salvage register) — and the **matcher is a marked
extension seam**. A trailing `*` extends the matcher within that seam and
needs no change to the serialisation: `*` is simply a non-modifier token, so
`normalize_combo` already canonicalises `Ctrl+Alt+*` unchanged, and the class
key at dispatch is the same `combo_string` call with `'*'` as the trigger.

**Why exactly one trigger stays the rule.** Exact-lookup dispatch is sound
because a combo names every modifier that matters — `ctrl+s` deliberately does
not fire while Alt is held. Extending that to ordinary keys would make every
binding conditional on nothing else being held: hold `a` for movement, press
`space`, and the `space` binding stops firing because the combo is now
`a+space`. Multi-key chords therefore stay out of the combo grammar. A project
that wants them uses a hook, which receives the held-key view on **all three**
keyboard/text channels, and `compy.input.keys_pressed` (Decision 20) elsewhere.

**Consequence.** `shortcuts` stays the easy, predictable mechanism: exact
match, one optional class marker, no corner cases to design against. Anything
more sophisticated is a hook, with no capability lost.

---

## Decision 22 — `compy.input.fn.ignore_repeat`

> REMARK: ignore_repeat appears to be keypressed-specific wrapper, because its not passed anywhere else? worth mentioning.

**Status: implemented** (owner ruling, 2026-08-03).

**Decision.** Dispatch does **not** gate on `isrepeat`: a held combo fires on
every OS key repeat, and a hook sees every repeat too. A binding that should
act once per physical press wraps its handler in
`compy.input.fn.ignore_repeat(fn)`, which skips `fn` on a repeat.

**Scope: whether the handler runs, and nothing else.** A fresh press returns
whatever `fn` returned; a skipped repeat returns nothing, so the event carries
on down the chain exactly as an unhandled one would. Consumption is declared
separately (Decision 24) — the two are orthogonal and compose.

**Why not a dispatch rule.** Filtering repeats inside the shortcut tier was
weighed and rejected: it suppresses with no way to recover a hold-to-act
binding, and it would leave the same hand-written check in `hooks.keypressed`,
where commands are equally idiomatically bound. A wrapper has one signature
and composes across all three tiers.

**Withdrawn on the way here.** An earlier pass shipped `suppress_repeat`
(skip the handler *and* consume the repeat) and `bypass_repeat`. Measuring
them showed `suppress_repeat` offered an incoherent middle: with a
non-consuming handler the *fresh* press fell through to the hook while every
repeat was consumed, so press 1 behaved differently from presses 2+. Both are
gone; `ignore_repeat` is `bypass_repeat` renamed, because "bypass" claimed
something about where the event goes and that is no longer this wrapper's
business.

**On hooks.** It wraps a hook as readily as a shortcut. Whether that is wise
is the project's call: a *whole-channel* hook wrapped in it, combined with
`stop_here`, stops the widget's own held backspace and held arrows from
repeating. The guide states the caveat; it is not prevented.

**Prior art in the record.** The frozen design carried a provisional leaning
toward fresh-only at the combo tiers (salvage register, "Combo-tier repeat
semantics"), explicitly **not ruled** and parked to settle near
implementation. This settles it the other way, for the reasons above; the
constraint attached to it — existing combos keep current behaviour unless
explicitly altered — is satisfied, since the wrapper is opt-in.

---

## Decision 23 — an unhandled event is not logged

**Status: implemented as no change** (owner ruling, 2026-08-03).

**Decision.** `dispatch` does not log when an event is consumed by nobody. The
walk keeps its `nil` checks and gains no unhandled branch.

**What this settles.** The design's chain diagram gave tier 3 a "DEFAULT: noop
(+debug log)", and the design notes proposed *default noop + debug log* as the
standard for all project-facing callbacks, so that "silent failure is replaced
by a visible hint in debug mode". The tree implements the behaviour — an
unhandled event falls through and mutates nothing — but not the log.

**Why the log is declined.** Taken literally at the combo tier it is a line per
keystroke that is not a bound combo, i.e. on ordinary typing, every frame a key
repeats. That is not a hint. The one variant worth anything — the chain *has*
participants and the event still fell through all of them — is a
platform-debugging question, and a platform developer can add the line to
`dispatch` for the length of an investigation. A project developer lives
without it.

**Why the noop default is declined too.** The other half of the same proposal
was a `__index` returning a noop, so dispatch could always call. It is refused
for a reason that outweighs the tidier call site: **whether a hook is set is
information**. Code that installs or removes a handler depending on what
another part of the project already installed needs to read `nil` and get
`nil`. A defaulting `__index` does not hide a check, it removes an
introspection capability — and it would also silently break `seed_hooks`,
whose "is this unset?" test is what Decision 10's capture path runs on.

**Consequence.** The nil guards in `dispatch` are deliberate and documented as
such, not an oversight to tidy later.

---

## Decision 24 — `compy.input.fn.stop_here` and `.side_run`

**Status: implemented** (owner ruling, 2026-08-03).

**Decision.** Two combinators declare what becomes of the event, at the
registration site rather than inside the handler:

| wrapper | runs `fn` | returns |
|---|---|---|
| `stop_here([fn])` | if given | `true` — the event stops here |
| `side_run([fn])` | if given | `false` — the event carries on |

Both take the function optionally. `stop_here()` with none is a binding whose
only job is to swallow; `side_run` always lets the event through, **including
when the wrapped function returns truthy** — the declaration outranks the
handler, which is the point of declaring it.

**Why.** A binding that must not fall through otherwise says so by ending
every handler with `return true`. That is the dark side of the DOM idiom: it
forces the function to know its **propagation context** — a function that
merely toggles a pause has to know what happens after it returns, and carries
that knowledge wherever it is reused. These move the statement to the dispatch
map, where a reader of the registration table can see it:

```lua
sc['alt+p'] = compy.input.fn.stop_here(pauseToggle)
sc['alt+*'] = compy.input.fn.stop_here()
sc['f5']    = compy.input.fn.side_run(log_keystroke)
```

**Not a reversal of Decision 22.** That one refused to let a repeat wrapper
decide consumption behind the developer's back. This is the developer
deciding, explicitly, where the binding is declared. The difference is who
chooses, not where the `true` comes from.

**Composes with Decision 22, and that is the whole design.** One combinator
about invocation, two about propagation, none knowing about the others:

- `stop_here(ignore_repeat(fn))` — a reserved key: acts once per physical
  press, and nothing below ever sees it.
- `side_run(ignore_repeat(fn))` — a once-per-press side effect: acts on the
  fresh press and claims nothing, so the widget still receives every key.

**Naming.** They are named for their effect on the **event**, in dispatch
terms, rather than for their return value (`always_true`/`always_false`, which
is what they are underneath). A registration table is read to answer "what
happens to this key", and the names answer it there.

**Namespace.** They live under `compy.input.fn`, not on `compy.input`
directly: they are stateless functions *about* functions, not part of the
widget or dispatch surface, and grouping them says so. Writes to `fn` raise
like every other frozen sub-table.

## Decision 25 — one route, one chain, one lifetime for every input channel

**Decision.** Pointer events (`mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`,
`touchpressed`, `touchreleased`, `touchmoved`) and the framework's derived click events
(`singleclick`, `doubleclick`) are dispatched by the project route through the same chain as
keyboard and text, with the same error boundary and the same lifetime. Concretely:

- **The widget is the chain's terminal**, not a parallel recipient. Previously the gateway
  broadcast a pointer event to the widget *first* and then to the project's handler
  unconditionally. Delivery order therefore reverses: the project's hook runs first, the widget
  last, and an unconsumed event still reaches both.
- **A pointer hook consumes on a truthy return**, like any participant. This is new expressive
  power — a shown widget can now be starved of a click aimed past it — and it was free: no
  example pointer handler returned a value, and the return was discarded in any case.
- **No shortcuts tier for pointer.** A combo names a key; a pointer event has none. Pointer
  enters the walk at the hook tier, and `find_shortcut` answers nil for a missing table rather
  than each channel special-casing itself. A pointer combo grammar is deliberately not invented
  here.
- **Payloads are exactly LÖVE's arguments.** No held-key view is appended: a project reads that
  through `compy.input.keys_pressed` (Decision 20), and appending it would change the signature
  every existing pointer handler was written against.
- **Derived clicks are events, not a bespoke surface.** The click timer only decides *which*
  event the raw presses amount to and applies the drift check, then emits through
  `love.handlers.singleclick(x, y)` like any native event. `compy.singleclick` /
  `compy.doubleclick` are removed; projects bind `compy.input.hooks.singleclick`. The console and
  editor do not use these events, so on those routes the slot is empty and the emit is a silent
  no-op.
- **One error boundary, at route entry.** `guarded(CC, fn)` wraps the point where a route is
  entered rather than each participant. The chain itself has no error handling, so wrapping
  participants had left `shortcuts[...]` and directly-assigned `hooks[...]` — the two surfaces
  this guide teaches — unprotected, and made a raise in the third look like a falsey "did not
  consume", so the walk continued into the widget of a project that had just crashed.

**Why.** The keyboard/pointer split was this feature's own invention rather than inherited
behaviour (Decision 11, amended). Once that was established, every remaining argument for keeping
pointer outside the chain dissolved: the lifecycle difference was self-inflicted and unreachable,
the consume contract cost nothing because nothing returned a value, and the pieces that looked
like distinct machinery — a second wrapper, a second install path, a bespoke click surface —
existed only to serve the split. Unifying removes mechanism instead of adding it.

**Consequence, accepted.** A non-blocking project with no interaction surface keeps the keyboard
until it stops, where it previously handed it back at `'project_open'`. That is the pre-feature
behaviour, and `Ctrl+Esc` remains the documented exit.

**Settled since, see Decision 27.** The open question this entry left — whether pointer should
gain a combo vocabulary — is answered: it did, and it needed no vocabulary of its own.

## Decision 26 — every consumer receives LÖVE's own argument list

**Decision.** Shortcuts, hooks and the widget receive exactly the arguments LÖVE delivers for the
event, unchanged and in LÖVE's order: `keypressed(key, scancode, isrepeat)`,
`mousepressed(x, y, button, istouch, presses)`, and so on. No argument is added, removed or
reordered on the way through the chain. The held-key set is not among them: a consumer reads
`compy.input.keys_pressed`, which works inside a handler and outside one alike (Decision 20).

**Why.** The chain used to hand keyboard and text consumers a `(k, keys_pressed, isrepeat)` triple
of its own invention while pointer channels got LÖVE's arguments untouched — so the "uniform
signature" was uniform across three channels and different from LÖVE on all of them. Two costs
followed. A project's own `love.keypressed`, seeded as a hook (Decision 10), silently received
something other than what it was written against; and every per-channel method had to know its
own payload shape, which is what kept `keypressed`/`keyreleased`/`textinput` from collapsing into
the same generated channel as the other nine.

The `keys_pressed` argument in particular bought nothing once Decision 20 made the set globally
readable — and a project that RENDERS held state has to read it that way regardless, since a
per-frame draw has no event argument in hand.

**Consequence, accepted.** `scancode` reaches consumers although nothing inside compy reads it,
and combo triggers remain key-name-only (`doc/development/technical_debt/input.md`, "Combo
triggers are key-name-only"). That is the same bargain the pointer channels already made with
`istouch` and `presses`: passing LÖVE's list verbatim is the rule, and an unread argument is the
price of not having a second rule.

**Consequence, accepted.** The console/editor route still narrows to `CC:keypressed(k)`. It has no
widget tier to thread the rest to, and its own dispatch predates the feature.

## Decision 27 — one combo vocabulary, with the button as a trigger

**Decision.** Every channel carries a shortcuts tier, and every combo is written the same way:
modifiers plus a trigger, or modifiers plus `*` for the class. What differs is only what the
channel has to name. `mousepressed` and `mousereleased` name the **button**, serialised `mouse1` /
`mouse2` / `mouse3` — so `shortcuts.mousepressed['mouse2']` is a right-click and
`'ctrl+mouse1'` a ctrl-click. Channels with no discrete trigger — `mousemoved`, `wheelmoved`, the
touch events, the derived clicks — take modifier classes only, and with no modifier held there is
nothing to name, so the event goes to the hook tier.

**Why.** The guide had argued a pointer tier was impossible because "a combo needs a key to name".
It does not: `combo_string('*', keys)` already built a triggerless class key — that is what
`alt+*` has always been. The asymmetry was an accident of nobody wiring it, not a design.

Excluding the button was considered and rejected, on the owner's challenge. The argument for
excluding it — "the button already arrives as an argument, so the handler can test it" — applies
word for word to the keyboard, where the key also arrives as an argument and is a combo trigger
anyway. Taken seriously it abolishes the shortcuts tier entirely and puts every binding back
behind `if button == 2`, which is the string-tag dispatch `agents/rules.md` forbids in as many
words. A shortcuts tier exists precisely so a handler does not have to test what it was
registered for.

**Consequence, accepted.** A channel's trigger is read from a different argument position per
channel (first for keys and text, third for buttons). That is one table of accessor functions,
not a branch, and it is the only per-channel knowledge the route holds.

**Consequence, accepted.** The derived clicks name no button, because the click timer does not
carry one today. Extending it is a separate change; until then `singleclick`/`doubleclick` take
modifier classes only.

**Fast path preserved.** For a triggerless channel the held-modifier test runs before any combo
string is built, so an unmodified `mousemoved` allocates nothing. A bare `'*'` still raises on
every channel: it would mean "every event", which is what a hook is.
