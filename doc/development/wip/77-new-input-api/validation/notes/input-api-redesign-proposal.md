# Input-API redesign proposal — 3-component chain + widget callbacks (owner draft)

**Status:** proposal / side-product of TF2 human review (S15, 2026-07-20). NOT ratified.
Feeds Phase B (scaffolding-suspect bucket) and the next-session Fable analysis. The
frozen `design/` corpus is untouched; the 13 ratified decisions in
[`decisions/input.md`](../../../decisions/input.md) are the baseline this proposes to refine.

**Origin.** Reviewing the split contract suite, the owner found the same tensions
resurfacing across files (terminology collisions, internals-testing smells, symmetry
gaps). The hypothesis: a small *reshaping* of the shipped form — not a redesign — dissolves
most of them. "Ratified decisions (including terminology) were **stubs** that helped deliver
the initial form; now that the form has materialised they can be tightened before real
delivery — *if it makes sense*."

---

## 1. The vocabulary (a taxonomy with a rule, not just renames)

PRINCIPLE — reserve each word for one role:
- **handler** — combo-bound thing. `handlers[event][combo](...)`.
- **hook** — injected mid-chain; can intercept/modify/consume. `hooks[event](...)`.
- **callback** — fired by a trigger (a widget-lifecycle event). The widget's own outputs.
- **routing** — selection of the dispatcher (controller). Nothing more.

Renames that fall out of the rule:

| today | proposed | why |
|---|---|---|
| `singleton` | **widget** | one shared instance is an impl fact, not a name; "widget" is the role |
| `sink` (tier 4) | **widget** | the terminal component *is* the widget; two names for one thing |
| `on_key_pressed`/`on_text_input`/`on_key_released` (tier-3 generic callback) | **`hooks[event]`** | a table symmetric with `handlers[event]`; drops three ad-hoc field names |
| `native` (legacy love.* seeding tier-3) | **hook** (installed via sandboxed `love.*`) | "native" is misleading; it behaves exactly like a hook — naming of the install path is open ("project's sandboxed love.* hook"?) |
| `framework handlers` (tier 1) | **framework/global shortcut** (if only Enter/Esc, non-configurable) or **framework handler** (if it captures generic combos) | distinguish the two-key reserved case from a combo-capturing case |
| `generic callback` | **hook** / project hook | same as above |
| `proxy` (held-key read-only view) | describe by behaviour ("read-only pressed-keys view") | "proxy" names the mechanism, not the contract |

`routing` stays `routing`. `on_text_entered` vs `on_text_input` — the confusion Decision 5
itself flags — evaporates: the per-character thing is `hooks.textinput`; `on_text_entered`
is a widget **callback**, in a different namespace by construction.

---

## 2. The dispatch shape: four tiers → three components

Today (Decision 2): `framework_handlers` → `handlers` → generic `on_*` → `sink`.

Proposed chain (in order, truthy-consumes, falsey-falls-through — the DOM-style convention
is **kept**):

1. `input.handlers[event][combo](...)` — project combo handlers.
2. `input.hooks[event](...)` — project hooks (absorbs today's `on_*` generic callback **and**
   the legacy sandboxed `love.*` path, one slot, precedence: explicit hook wins, else the
   sandboxed-love seed, else default no-op).
3. `._widget.event(...)` — the widget (today's "sink"), terminal. No-ops when hidden.

**No standing framework tier.** Enter/Esc are not a reserved non-overridable tier. Instead:
- if the project wants Enter/Esc, it registers a **handler** — it wins (tier 1);
- otherwise the **widget** processes them (submit / cancel) as its default behaviour;
- if the widget is **not shown, it does not consume** — the key propagates to the **parent
  controller's dispatch**, which is what re-routes to console or triggers global exit.

That last rule is the load-bearer: **non-consumption-when-hidden is the propagation engine.**
The reserved-keys special case becomes an emergent consequence of "widget consumes when
shown, bubbles when hidden."

---

## 3. Widget callbacks (the "out" direction — Decision 5's insight, re-homed)

The widget runs its own callbacks, configured at **UIC (widget-controller) level**, and
the input API provisions them from a `compy.input.callbacks` table:

```
callbacks.on_text_entered
callbacks.before_submit / after_submit
callbacks.before_cancel / after_cancel
```

The chain routes events *in* (3 components); the widget reports results *out* (callbacks).
Decision 5's two-directions split is **preserved** — only renamed and moved into one table.
The call-order (not return-value) semantics of the submit/cancel chains (Decision 6) are kept.
The pattern is extensible by the same principle: before/after **validation**, error-handling,
etc. can be added as further widget callbacks.

---

## 4. How the original submit/cancel bug stays fixed (owner's clarification)

Decision 6 exists because the *old* widget-owns-Escape shape was a bug: the widget could
clear content but "could not actually dismiss" the session (lifecycle was "above its pay
grade"). This proposal does **not** regress that — it fixes it by **separation of concerns**:

- the **widget (UIC)** *detects* the trigger (rightly — it owns the text surface), *does its
  job*, **and communicates the event to the parent context** via the clear, unambiguous
  propagation chain (like the old "emit event" attempt, but now with unambiguous flow);
- the **parent context has full control**: it can capture text in `before_cancel` and restore
  it after, hide/show the widget, sequence lifecycle acts.

So "widget owns Enter/Esc" here means the **controller** owns detection-and-propagation, not
the raw model owning lifecycle. That layering is the whole ballgame — keep it precise.

---

## 5. The mutable/immutable boundary, loosened (owner's clarification)

Supersedes Decision 7's strict enumerated write-prohibition. **No special per-field rules
prohibiting writes on `compy.input` attributes.** Instead: **table keys are rewritable;
`compy.input` itself is not.** You may freely write `handlers[...]`, `hooks[...]`,
`callbacks.*`; you cannot replace the `compy.input` container (or, presumably, swap a
whole sub-table wholesale). One simple guard on the container replaces the enumerated slot
list.

---

## 6. Decision-by-decision map (baseline = the 13 in `decisions/input.md`)

| # | decision | disposition under this proposal |
|---|---|---|
| D1 | route-centric routing | **KEEP** — reinforced (`routing` = dispatcher selection) |
| D2 | four-tier chain, truthy-consume | **SUPERSEDE** — 3 components; truthy-consume kept; framework tier-1 dissolved; sink→widget |
| D3 | one boot-provisioned shared widget | **KEEP** — rename `singleton`→`widget` |
| D4 | callbacks replace polling | **KEEP** |
| D5 | two directions, two surfaces | **KEEP the insight, RE-HOME** — outputs → `callbacks` table at UIC; `on_text_entered` leaves the chain namespace |
| D6 | submit/cancel at framework tier, call-order chains | **RESOLVE** — no framework tier; UIC owns detect+propagate, context owns lifecycle; call-order semantics kept |
| D7 | strict mutable/immutable boundary | **SUPERSEDE/LOOSEN** — freeze the container, keys writable; drop enumerated slots |
| D8 | per-event combo tables + canonical serialisation | **KEEP** — `hooks[event]` now symmetric with `handlers[event]` |
| D9 | uniform signatures + `isrepeat` threading | **KEEP** |
| D10 | legacy natives pure-wrapped as tier-3 | **UNIFY** — fold into `hooks[event]` (precedence: explicit > sandboxed-love seed > no-op); name of the seed path open |
| D11 | route connects only while running | **KEEP** — non-consume-when-hidden bubbling generalises the propagation story |
| D12 | `inspect` is a mode-to-route line | **KEEP** |
| D13 | held-key set read-only proxy | **KEEP** — retire the word "proxy" in prose |

Net: **9 keep, 1 re-home, 3 supersede/resolve/unify.** The load-bearing insights (route-
centric routing, two directions, truthy-consume, shared widget, teardown invariant) all
survive; what's shed is the tier-1/tier-4 special-casing, the enumerated write guard, and
the jargon.
