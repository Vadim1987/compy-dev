# Input Routing — Contracts (current behaviour, doc A)

<!-- authored by LLM (Sonnet 5), normalizing prior passes by
     Opus 4.8 into the shape `notes/plan.md`'s definition of
     done requires; human-approved: NOT YET.
     This is doc (A) of the two-part canonical doc `plan.md`
     describes: the current-behaviour half. Promotion
     candidate for `doc/development/internals/` at feature
     close. The editorial history of prior passes (per-session
     decision ids, which pass raised which question) is
     retired from this text — it carries no meaning to a
     reader without that session's memory; git history is the
     record of how this doc arrived at its current shape. -->

Companion (descriptive "how it works today"):
[user_input.md](../../../internals/user_input.md).
Factual basis (every claim here traces back to it):
[`input-contracts-inventory.md`](input-contracts-inventory.md),
cited by section (_inv §4_) rather than re-derived line numbers.
Deeper traces behind several corrections in this pass live under
[`assessment/`](assessment/); each is cited at the point it is
used.

---

## 1. Premise + how to read every entry

The compy input layer grew ad-hoc, with no up-front design
doc. Therefore **the current implementation is the canonical
specification** of the framework's input behaviour. Feature
#77 rewrites the routing (overlay-gate removal, a new
`ProjectInputController`, slot ownership/restoration). We can
only claim the rewrite preserves the framework if its
guarantees are written down first. This note is that record.

The governing discipline — read every entry through it:

> **OUTCOME vs MECHANISM.**
> - **OUTCOME = the contract.** For a given `(mode,
>   widget-state)`, *which consumer receives each event, and
>   under what exclusivity.* Binding; the rewrite must keep it
>   true.
> - **MECHANISM = today's realization.** The
>   `if get_user_input() then …` gate, the slot swap via
>   `set_handlers`/`hook_if_differs`, the `{ M, C, V }` handle,
>   the `app_state` branching. Free to change.

Outcomes are stated as contracts. Mechanism appears only as
**(current realization, non-binding)**, clearly marked, so no
reader mistakes today's code for the guarantee. A contract
written at outcome level survives the rewrite; one written at
mechanism level goes red the moment the mechanism changes,
guarding nothing.

**Stability tags.** Every contract is tagged:
- **[stable-now]** — holds against current code; the rewrite
  must preserve it.
- **[forward / 0.1.0-mN]** — does **not** hold today; the
  named version establishes it (§7). Never read a forward
  contract as a present guarantee.

Versions, not milestones, anchor the durable text: horizons
use semver pre-release markers (e.g. _0.1.0-m4_), never bare
"M4 does X" prose.

**Provenance tags** (the anti-drift gate). Every contract row
carries one of:
- **PRESERVE** — traces to a tier-1/2 stakeholder mandate
  (cited), to the ratified inter-route-exclusivity principle
  (§3), or to an explicit **owner ruling** (a fresh
  top-authority decision, cited as such and tagged
  *owner-minted* — legitimate, but **not** code-preserving; do
  not read it as a reverse-engineered invariant).
- **CHARACTERIZE-PROVISIONAL** — observed current behaviour
  with no mandate behind it; expected to change, no stakeholder
  mandate.
- **[characterized from current runtime — not yet ratified as
  desired]** — a plain descriptive finding (a trace through the
  code) with no design-corpus or stakeholder anchor at all; used
  for facts about today's mechanism rather than contracts.

A row with none of a mandate, the principle, or an owner ruling
behind it may **not** be tagged PRESERVE.

---

## 2. Keypressed vs. textinput — two channels, one compy convention

[characterized from current runtime — not yet ratified as
desired.] Source: `assessment/keypressed-vs-textinput.md`.

LÖVE2D fires `love.keypressed` for **every** physical key, textual
or not; `love.textinput` fires only for OS-processed,
character-producing keys (IME/layout aware). Pressing `q` fires
**both** `keypressed('q')` and `textinput('q')` — LÖVE2D itself
does not partition control keys from character keys.

The "keypressed = control channel, textinput = character channel"
split used throughout this doc is **compy's own convention, not a
LÖVE2D guarantee**. Nowhere does compy's `keypressed` code filter
out or ignore textual keycodes — every branch checks `k` against a
fixed set of named control keys, or a modifier+letter combo used
as a shortcut (e.g. Ctrl+C); a bare `keypressed('q')` with no
modifier matches nothing and falls through untouched. All literal
character insertion is reachable only from `textinput` handlers,
plus two `keypressed`-triggered paths that move **existing** text
(not the pressed key) into the model — clipboard paste (Ctrl+V)
and `load_selection` (Escape, editor mode). This holds uniformly
across console, editor-edit, and editor-search — none of the
three deviates.

---

## 3. Routing vocabulary

Routing selects **one route** per input event — keyboard, text,
**and** pointer; a route may have a **widget** up. An earlier
"two orthogonal activations (mode × widget)" framing is
**retired**: that orthogonality was an artifact of the global
overlay gate (a widget independent of mode). Once the widget is
**route-owned** it is not orthogonal to the route — it belongs to
the routed controller.

**The invariant, grounded in mode-exclusivity.** The screen is
always in exactly one mode — console / editor / project-running /
a special mode (e.g. `inspect`). Modes are mutually exclusive, so
the routes they bind are mutually exclusive, so **inter-route
dispatch is EXCLUSIVE for every event type**: each event reaches
exactly one route — the active one, fixed by mode/context. Never
zero (no silent drop), never two. The widget is an **operational
surface** the active route drives and configures; it never
determines routing by merely existing.

> **Provenance of this invariant [PRESERVE].** It is a **ratified
> design rule**, not a stakeholder mandate. Intent is *silent* on
> inter-route topology per se; the rule **derives** from
> mode-exclusivity (a real system property) plus the
> architect-ratified three-controller topology (Console / Editor /
> ProjectInputController), set out in
> [`design.md`](../design/design.md) §2. State it as design
> authority, not as something a stakeholder demanded.

> **"EXCLUSIVE" is on the route axis, not the channel axis.**
> Here EXCLUSIVE means one *route* per event. It does **not**
> collide with the stakeholders' "no exclusivity, no suppression",
> which is about the **channel** axis (key and text are two
> independent channels that both fire, §2 / `spec.md` §1). The
> only legitimate "both" is **intra-route** (a route delivering an
> event to its own logic *and* to a surface it activated — the
> "parallel handling" tier-1 asks for); that is the route's
> private affair and is invisible to the inter-route contract.

**Glossary.**
- **route** — the path a keyboard/text event takes to its
  consumer. Routing selects **exactly one route per event**.
  Current value set: `{ overlay, ConsoleController,
  EditorController }`; the rewrite replaces it with
  `{ ConsoleController, EditorController,
  ProjectInputController }` — the global overlay gate is
  removed and the project gains a first-class route.
  **Contract (intact across the rewrite): every keyboard/text
  event travels via exactly one route — never silently
  dropped, never more than one.**
- **sink** — the default / last-resort disposition a route
  provides and manages for an event it did not specifically
  handle (no matching handler or combo). Deliberately
  implementation-light: routes need **not** realize it
  identically — Console/Editor may differ from the project
  route. *Current realization:* `UserInputController` is
  purposefully a **global singleton** the active route takes
  control of; "UIC becomes the *universal* terminal sink"
  (`design.md` §2) is a **recommended objective**, not a
  present fact — Console/Editor routing-through-UIC is
  postponed and may be contested. A widget often serves as its
  route's sink, but not always.
- **widget** — the route-managed input *surface* that solicits
  text. Owned by the active route's controller, **not** a
  free-floating global. Today the project's widget is realized
  as the overlay singleton (`love.state.user_input`) — the
  mechanism the rewrite removes. A widget can serve as its
  route's sink (text editing), but the two notions are
  distinct. A widget **never occupies a LÖVE handler slot in
  any context** — the route's controller occupies the slot and
  forwards to the widget internally.

Pointer (mouse/touch) and wheel are **not** exceptions to
exactly-one-route: like keyboard/text they reach the single
active route. Any forwarding to a widget is **intra-route** (the
route's concern), not a second inter-route delivery (§5.5–5.7).

**(A) Routing — which consumer owns the event.** The
application `app_state` selects which **route** owns the event
slot: `ready` / `project_open` / `running` / `inspect` /
`snapshot` / `editor` / `shutdown` (_inv §2_). In every
non-running state the route is the single `ConsoleController`
(CC), which sub-routes console-vs-editor internally; while a
project runs, the project's route (the overlay today;
`ProjectInputController` after the rewrite) owns the
keyboard/text slots (§5). (Current realization: `app_state`
branching inside CC, the overlay gate, and `set_handlers` slot
swaps.)

**The slot occupant is the controller, not the widget**
(endorsed design). A **controller** (route) occupies the LÖVE
handler slot and dispatches each event **internally**: through
its **handlers**, then the **project slots** established on the
LÖVE clone, with **userinput as the final destination** (the
sink). The widget is one surface the controller may forward to
along that internal path — it is **never itself a slot
occupant**, in any context.

**(B) Widgets — a route-managed surface.** A **widget** (the
overlay singleton today) is shown / reset / hidden by the
active route. A widget changes only **intra-route handling** —
how the active route processes an event it has already received
(e.g. the project route delegating text editing to a soliciting
widget). It **never** changes inter-route dispatch. The present
realization — *widget up ⇒ the widget consumes its route's
keys/text, the route's own sink bypassed; a click reaching both
the widget and the route's other handling* — is **today's
mechanism** (the overlay gate on the keyboard path, the
un-gated mouse path), characterized per event in §5, **not** a
routing contract.

**(C) Hidden widget does not consume [owner-minted; PRESERVE].**
Owner ruling: a fresh top-authority decision, not a
code-preserved invariant. An event that reaches a widget while
the widget is **hidden** is **ignored or passed through by the
widget** — never used to mutate widget state. When the widget is
not on screen, no user intent to modify its state can be
assumed. This is an **intra-route** rule (the route's surface
declines the event); inter-route dispatch is unchanged. It
applies to **every** event type a widget might be offered.

**Two-step nature.** First a route is selected by mode/context;
then that route may have a widget (de)activated within it. The
widget never changes the route; the route (`inspect` open, §5.4)
governs whether a widget is honoured. "Widget up while in
console mode via a free-floating `show_widget()`" is therefore
an **incoherent scenario** under this model: a widget only
exists when its owning route is active.

**Reset semantics (widget re-activation).** Re-activating an
already-active widget is **not** a fresh activation:
- without `force` → the request is **suppressed and warned**,
  state untouched (warn-on-suppression is a contract, §6.6).
- with `force` → a live reconfiguration is applied (**today
  only the `text` subset** takes effect, other config ignored;
  the reconfiguration *scope* is forward-controllable, §6.6),
  and **no cancel chain fires**.
- a fresh activation (widget was inactive) with **no text
  supplied starts empty** — re-show does not inherit prior
  text.
(_inv §6_. Current realization: `show`/`open_fresh` in
`userInputController.lua`.)

---

## 4. Completeness table — every mode × channel

Every cell below is either a contract (with its section) or an
explicit gap/`pending` marker naming what is missing — no cell is
silently absent. "Out-of-radius" marks a cell classified as
foundation for later work, not enforced by #77 itself (§8).

| Mode | keypressed | textinput | keyreleased | pointer (mouse / touch / wheel) |
|---|---|---|---|---|
| console / REPL | PRESERVE §5.1 | PRESERVE §5.2 | PRESERVE §5.3 | mouse PRESERVE §5.5; touch `pending` §5.6; wheel CHARACTERIZE §5.7 |
| editor | PRESERVE §5.1 | PRESERVE §5.2 | **gap — out-of-radius** (CC-internal fork missing, §5.3, §8) | mouse PRESERVE §5.5 (no-op: `disable_selection`); touch/wheel as console |
| project-running | PRESERVE §5.1 (forward §7.1 removes the gate) | PRESERVE §5.2 (forward §7.1) | PRESERVE §5.3 (today diverted to the widget when one is up; forward §7.1) | mouse PRESERVE §5.5 (never gated); touch `pending` §5.6; wheel CHARACTERIZE §5.7 |
| inspect | **gap — out-of-radius**, mode override: console owns the whole surface, §5.4, §8 | same as keypressed, §5.4 | same as keypressed, §5.4 | same as keypressed, §5.4 |
| search (sub-widget) | **gap — out-of-radius**, undocumented triad, §5.8, §8 | **gap — out-of-radius**, §5.8, §8 | **gap — out-of-radius**, no `:keyreleased` method exists at all, §5.8, §8 | n/a — mouse disabled (`disable_selection`) |

---

## 5. The contract table — per active route, per event

Notation. **route** = the consumer the event is dispatched to
(§3; the mode route — Console/Editor — or the project route),
selected by mode/context. **widget** = the active input surface
*within* a route (§3B). **EXCLUSIVE** = exactly **one route**
receives the event — for **every** event type (keyboard, text,
pointer). There is **no inter-route "BOTH"**: the only "both" is
**intra-route** (a route forwarding an event it received to a
surface it activated), which is the route's concern and invisible
to this contract (§3).

All contracts in this section are **[stable-now]** unless a row
says otherwise.

### 5.1 keypressed — EXCLUSIVE on the active route [PRESERVE]

**Contract.** A `keypressed` reaches **exactly one route** — the
active one, fixed by mode/context (§3). Never zero, never two.
Global shortcuts (§6.3) and held-key tracking (§6.1) run first
but do **not** consume — the same key still arrives at that one
route. (_inv §4 keypressed_.)

**Provenance — PRESERVE.** Inter-route exclusivity is the
ratified principle (§3). The further tier-1 mandate it must
honour: *"no backward compat, but only TEXT FIELDS break; native
keyboard handling must keep working"* — stated **at the route
level**: a running project's route keeps receiving keys (its
native keyboard handling is not broken). The break is bounded to
text fields, not to keyboard dispatch.

> **What is NOT the contract — today's mechanism
> [CHARACTERIZE-PROVISIONAL].** Today routing is keyed on
> **widget presence**: *widget up ⇒ the widget consumes, the
> project sink bypassed entirely* — the `if get_user_input()
> then …` overlay gate at the dispatch point
> (`controller.lua:19-22`, `:554+`). That is **today's
> realization, expected to change, no stakeholder mandate** — it
> is the precise drift #77 exists to cure. The rewrite removes
> the gate and routes project keys to the `ProjectInputController`
> (§7.1). Read this section as "exactly one **route**," **never**
> as a contract to preserve project-key-drop-under-widget — that
> drop is a limitation being fixed, not a guarantee. Which surface
> the active route uses internally (a widget, its sink) is
> intra-route and invisible here.

### 5.2 textinput — EXCLUSIVE on the active route [PRESERVE]

Same shape and provenance as keypressed (§5.1): `textinput`
reaches exactly one route, the active one. The widget-presence
keying is the same today's-mechanism note as §5.1 —
CHARACTERIZE-PROVISIONAL, not the contract. (_inv §4 textinput_.)

### 5.3 keyreleased — EXCLUSIVE on the active route [PRESERVE]

**Contract.** A `keyreleased` reaches **exactly one route**, the
active one. The held-key removal (§6.1) and the Ctrl+Escape quit
guard (§6.3) run first and do not consume. (_inv §4
keyreleased_.)

**Today's mechanism — two distinct, separate gaps.**

1. **The overlay-widget diversion** (mirrors §5.1/§5.2): while a
   widget is active, the release is diverted to it and the
   project's route is bypassed entirely — same shape as
   keypressed/textinput's gate, same disposition (fixed at
   0.1.0-m4, §7.1). [CHARACTERIZE-PROVISIONAL.] Open: does any
   consumer consume `keyreleased` today at all under this path? —
   carried provisional.

2. **A second, independent gap: `ConsoleController:keyreleased`
   never forks on editor mode.** Unlike its `keypressed`/
   `textinput` siblings, `ConsoleController:keyreleased`
   (`consoleController.lua:1090-1093`) unconditionally calls its
   own instance's `:keyreleased` — there is **no
   `app_state == 'editor'` branch**. Editor's and search's own
   `UserInputController` instances **never** receive a release,
   under any circumstance, regardless of which mode is actually
   on screen. Currently inert — editor/search construct with
   `disable_selection = true` (so the selection-release job is
   moot for them) and their error state is also clearable via
   **any** `textinput` character including Space, which covers
   the release-triggered clear anyway — but it is a real routing
   asymmetry against the otherwise-mirrored dispatch discipline.
   **Out of #77 blast radius** — carried as foundation, not fixed
   here (§8). [characterized from current runtime — not yet
   ratified as desired.] Source:
   `assessment/keyreleased-isrepeat-events.md` §2.

### 5.4 Mode override: `inspect` — the console owns the input surface

[CHARACTERIZE-PROVISIONAL · OWNER RULING PENDING · out of #77
blast radius, §8]

> **Owner ruling: deliberately deferred, keep the assumption.**
> How `inspect` is meant to operate after unification is still not
> pinned, and the feature is dev-facing; the owner chose to
> **retain the current assumption** rather than rule now. Do
> **not** invent a contract — revisit when the routing model
> lands.

**Current behaviour.** When `app_state == 'inspect'`, the input
surface serves the **console REPL** (console-owned) for **every**
channel — keypressed, textinput, keyreleased, and pointer alike; a
project-set widget is **not honoured**. Input is not blocked — the
project is frozen and the REPL is live over it, so keyboard/text/
pointer all drive the console. This is the one place mode
overrides widget. (_inv §4 head, §11.2_.)

**Mechanism (current realization, non-binding).**
`controller.lua:19-22`:
```lua
local get_user_input = function()
  if love.state.app_state == 'inspect' then return end
  return love.state.user_input
end
```
This is an unconditional override, not "the overlay happens to be
closed": even a mid-session overlay (`love.state.user_input`
non-nil when the break happened) is reported as absent while
inspecting. Every `love.handlers.*` entry point falls back to the
console's own default handler during inspect, because
`ConsoleController:suspend()` (`consoleController.lua:809-826`)
physically swaps `love.keypressed`/`textinput`/`draw`/`update`
back to the console's own functions — the project's own callbacks
are not merely short-circuited, they are removed from the `love.*`
slots for the duration. The console additionally treats itself as
running the paused project's own environment while inspecting:
`get_effective_env()` and `evaluate_input()` both select
`project_env` (not the console env) when `app_state == 'inspect'`,
so REPL input mutates the paused project's globals — a live
debugger console, not a separate idle console.

This is **not currently documented** in either
`internals/console.md` or `internals/user_input.md`; this pass is
its first record in a durable doc. Full trace:
`assessment/inspect-mode-current-state.md`.

### 5.5 mousepressed / mousereleased / mousemoved — EXCLUSIVE on the active route [PRESERVE]

**Contract.** A pointer event reaches **the active route** — the
one fixed by mode/context (§3). **Intra-route forwarding to a
widget is the route's concern**, not a second inter-route
delivery: when a route has a widget up it may hand the pointer to
that widget *and* to its own logic, in parallel — that is the
route's private affair (§3), invisible to this contract.

**Provenance — PRESERVE** (ratified principle, §3).

> **No inter-route "BOTH".** An earlier draft tabulated pointer as
> inter-route **BOTH** ("a click reaches both a route and a
> widget"). That was **today's mechanism promoted to invariant**:
> the keyboard path has the overlay gate, the **mouse path does
> not**, so today a click happens to reach both the underlying
> controller and the widget. When a project is running, a click
> is **not** propagated to the editor route — the running mode
> owns the whole screen; there is no second top-level route to
> receive it. So pointer is EXCLUSIVE inter-route like every
> other event; the "both" is intra-route only. Today the widget
> is called before the sink, but nothing is owed to that ordering.
> Under `inspect` (§5.4) the route's intra-route forwarding to a
> project widget is suppressed; the active route is unaffected.
> (_inv §4 mouse*, §10_.)

### 5.6 touchpressed / touchreleased / touchmoved — EXCLUSIVE on the active route [PRESERVE]

Same contract and provenance as mouse (§5.5): touch reaches the
active route; intra-route forwarding to a widget is the route's
concern. (The widget's touch handlers are no-ops today — that is
mechanism, not part of the contract; the **delivery** to the
active route is what is guaranteed.) (_inv §4 touch*_.)

### 5.7 wheelmoved — reaches the active route [CHARACTERIZE-PROVISIONAL]

**Contract (route axis, PRESERVE):** `wheelmoved` reaches the
**active route**, like every other event (§3).

**Provisional today:** the framework **default is a no-op** —
nothing acts on a wheel move unless the project defines its own
`love.wheelmoved` handler; and the active route does not forward
wheel to a widget. The "widget is never offered wheel" framing is
**mechanism by omission** (no wheel entry in the gateway), **not**
a designed asymmetry — CHARACTERIZE-PROVISIONAL. (_inv §1, §4
wheelmoved, §11.1_.)

> **Intent: pass-through by default, project-opt-in to consume —
> do not structurally block.** The authoritative descriptive docs
> treat wheel as forwarded to project handlers via the standard
> LÖVE2D mechanism (`internals/user_input.md`), never as
> framework-consumed — so widget-bypass is **incidental
> by-omission**, not a designed asymmetry. Intended shape: **wheel
> passes through to the project; the framework consumes it only if
> the project explicitly opts in (no-op by default)**. Do **not**
> pin widget-never-sees-wheel as a preserve-forever guarantee.
> (System-owned surfaces such as the error explorer do consume
> mousewheel, but that is outside the project-input contract.)

### 5.8 search — a third full MVC triad, undocumented in the design corpus [CHARACTERIZE-PROVISIONAL · out of #77 blast radius, §8]

`EditorController.search` (`editorController.lua:16`) is a fully
independent `SearchController`/`SearchModel` pair wrapping its own
`UserInputController` instance — a **third** consumer of the
shared widget primitive, alongside console's own and editor's main
input. It is live only in `app_state == 'editor'` and
`EditorController.mode == 'search'`.

**Current behaviour:**
- `keypressed`: `EditorController:_search_mode_keys` forwards to
  `self.search:keypressed`.
- `textinput`: `EditorController:textinput` forwards to
  `self.search:textinput` when `mode == 'search'`.
- `keyreleased`: **no path exists at all** — `SearchController`
  defines no `:keyreleased` method (zero hits, grepped), and even
  if it did, `ConsoleController:keyreleased`'s missing editor fork
  (§5.3.2) would not route a release there anyway.
- No evaluator (`nil`); Enter jumps to the currently-selected
  result, not a submit of the typed query.
- `SearchController:clear()` reaches past its own controller
  straight into `self.model.input:clear_input()`, skipping
  `clear_error()` — currently harmless (no evaluator, so no error
  can ever be set), but a layering inconsistency against every
  other reset path in §6.6.

Zero mentions of "search" anywhere across `design.md`, `spec.md`,
or `roadmap.md` (grepped, case-insensitive) — this is not a narrow
gap in one walkthrough table, the whole design corpus never names
this surface. Source: `assessment/shared-input-widget-singleton.md`,
`assessment/keyreleased-isrepeat-events.md` §2.

### 5.9 The one rule — inter-route exclusivity for every event

There is **one** rule:

- **Every event type** — keypressed, textinput, keyreleased,
  mouse, touch, wheel — is **EXCLUSIVE inter-route**: it reaches
  exactly one route, the active one fixed by mode/context (§3).
  [PRESERVE — ratified principle.]
- The only **"both" is intra-route**: a route may forward an
  event it received to a widget it activated *and* run its own
  logic, in parallel — the route's private affair, invisible to
  inter-route dispatch (§3).
- **`inspect`** = console owns the input surface for every
  channel; project widget not honoured (§5.4, CHARACTERIZE-
  PROVISIONAL, OWNER RULING PENDING).
- **`search`** = a fourth route-internal surface, live only in
  editor/search mode, with its own gaps (§5.8).
- **Global shortcuts** = non-consuming (§6.3) — they fire and
  the key still reaches its active route.

---

## 6. Cross-cutting contracts

### 6.1 Held-key set lifecycle — [mechanism-guard, not a behavioural contract]

A held-key set (`Controller.keys_pressed`, a `{ name → true }`
table) is maintained around the keyboard path:
- a key is **added on press** and **removed on release**,
  always, **before** any shortcut or sink dispatch runs;
- names are raw LÖVE names with **left/right unfolded**
  (`lctrl` and `rctrl` are distinct entries).

This bookkeeping has **zero current `src/` consumers** outside
itself — `Key.ctrl()`/`shift()`/`alt()` query
`love.keyboard.isDown()` directly, bypassing it entirely
(`assessment/keyreleased-isrepeat-events.md` §1). It is inert
infrastructure staged ahead of the planned combo dispatch (§7.4),
not yet-consumed internal state — **label it mechanism-guard**,
not a preserve-forever behavioural contract. The forward,
consumer-facing form (the set handed to a route as a read-only
proxy) is §7.4 (I4), not yet wired.

Contract (mechanism-level, still worth guarding against
accidental breakage): at the moment any keypressed consumer runs,
the set reflects the key just pressed; at the moment any
keyreleased consumer runs, the released key is already gone.
(_inv §8_.)

### 6.2 Combo serialisation — [stable-now]

`Controller.combo_string(k, keys_pressed)` serialises a key
event to a canonical string: held modifiers in fixed
precedence **ctrl, alt, shift, gui**, then the key, joined by
`+`; left/right **folded** to the generic name; no modifiers →
the bare key name. Contract: the serialisation is **stable and
order-canonical** (`lctrl`+`s` → `"ctrl+s"`). (_inv §8_. Tested
in `tests/input/keys_pressed_spec.lua`, not the contracts suite —
see `notes/input-suite-validation-map.md`.) Note: today this
function and `keys_pressed` have **no in-`src/` consumer** — they
are staged for the planned dispatch, §7. The serialisation
*format* is the durable guarantee; its wiring is forward.

### 6.3 Global shortcuts are non-consuming — [stable-now]

The framework-level shortcuts intercepted on the keyboard path
(Ctrl+Pause suspend, Ctrl+Q quit-project, Ctrl+S
stop/close, Ctrl+Shift+R reset, Ctrl+Alt+R restart,
Ctrl+t quickswitch, profile keys; and Ctrl+Escape quit on
release) **fire their effect but do not consume the key** — it
still reaches its sink per §5. Play mode (`cfg.mode=='play'`)
narrows the active set to restart/profile; that mode gate is
itself a contract. (_inv §7_.) DEBUG-only view toggles live in
the route keypressed (not the framework shortcut layer); they
fire when the active route handles the key itself rather than
forwarding it intra-route to a soliciting widget — a consequence
of §5.1, recorded for completeness.

### 6.4 Slot restoration on project stop — [stable-now]

On project stop, the route for **every** slot is restored
to the framework default (CC-owned) — wholesale, not per-key:
whatever handlers a running project installed are overwritten
by the default set, and `update`/`draw`/widget handle are
reset. Contract: **after stop, no project handler remains
wired in any slot**; the console owns input again. (_inv §3
"Restore on stop"_. Current realization: `set_default_handlers`
reinstalls defaults; the project fns are overwritten, not
individually reverted. The forward, sink-named form of this is
§7.2.)

### 6.5 Legacy solicitation path — [stable-now]

The legacy text-solicitation API (`user_input()` returning a
reftable, then `input()` / `input_code()` / `input_text()` /
`validated_input()` / `astv_input()`, polled via
`r:is_empty()` / `r()`) guarantees:
- **one successful submit both fills the reftable and closes
  the widget** (a single Enter delivers the value and
  deactivates) (_inv §9, §5_);
- **warn-on-suppression, never silent** — each guarded refusal
  warns: `input()` with a widget already active, with no
  controller present, or with `user_input()` not called first;
  `write_to_input` with no active widget. The contract is the
  *warning*, not the specific message. (_inv §9_.)

This whole path is marked for removal at _0.1.0-m8_; until
then its guarantees above hold. (_inv §9_.)

### 6.6 Widget activation / reset guarantees — [stable-now]

Restating §3's reset semantics as standalone contracts:
- **already-active without `force` → warn + no-op** (state
  untouched).
- **already-active with `force` → live reconfiguration**;
  **today only the `text` subset takes effect** (other config
  ignored), no cancel chain.
- **fresh activation with no text → empty.**
- **`hide()` deactivates without firing a cancel chain.**
- **auto-close on submit:** a successful oneshot submit
  deactivates the widget (today via a pushed `userinput`
  event). (_inv §5, §6_.)

> **[stable-now; superseded FORWARD / 0.1.0-m6].** The "no cancel
> chain" facts above (and in §3's reset semantics) describe
> **today**. The rewrite introduces **named submit/cancel chains**
> (a design decision); from _0.1.0-m6_ `hide()` and cancel paths
> *do* fire a cancel chain. These are stable-now-**until-
> superseded**, not preserve-forever. (Source: [M6.md](../design/spec/M6.md).)

> **[stable-now contract = the flag-gate; reconfig scope
> FORWARD].** Live reconfiguration is permitted **only behind the
> explicit `force` flag** — that gate is the durable contract. The
> **scope** of what `force` reconfigures is a deliberately
> **code-controllable, evolving** question: today text-only, to
> widen/tighten as the `compy.input` API matures
> (0.1.0-m7 `configure()`). Read "text-only on force" as **today's scope,
> not a preserve-forever limitation** — the rewrite may
> legitimately expand it. **Open design read for 0.1.0-m7:** whether
> `force` itself widens, or `configure()` owns reconfigure.

**Four incompatible `reset()`/cancel implementations, and a
two-layer cursor split — out of #77 blast radius (§8).** Today
"reset the prompt" is four bespoke, mutually inconsistent
mechanisms (Console: Ctrl+L terminal-only / Escape content-reset,
history preserved / Ctrl+Q content, history preserved / Ctrl+
Shift+R content + history wiped; Editor: Ctrl+W content-only,
Escape repurposed for `load_selection` instead of resetting;
Search: its own `clear()` bypassing its own controller; Project:
no reset surface at all yet). Cursor access is split across three
layers that don't line up (Model: full primitive surface;
Controller: a narrower passthrough missing `jump_end`/
`cursor_left`/`right`/`move_cursor`; `compy`: nothing yet), and the
two current programmatic cursor-manipulation call sites
(`load_selection` via the controller API, `reject_oversized`
reaching straight into the model) don't even agree on which layer
to use. `UserInputModel:set_cursor(c)` is an unvalidated raw
assignment, safe today only because every current caller already
supplies a pre-validated `Cursor`. Full trace, and why this is the
gap `compy.input.configure()`/`clear()`/cursor surface (0.1.0-m7)
is meant to close: `assessment/cursor-and-reset-operations.md`.

### 6.7 Framework click detection — [stable-now]

Single/double-click detection is a framework guarantee
independent of the raw pointer delivery (§5.5):
- a single click is **confirmed only after a 0.4s window**
  with no second release — there is **no instant single
  click**;
- a click is **suppressed if the pointer drifts > 2.5px**
  between press and release;
- confirmation invokes the **project-defined** `compy.
  singleclick` / `compy.doubleclick` (looked up in the project
  `compy` table; default no-ops), **not** a LÖVE event.

This derived click delivery is a **third** path, separate from
the raw widget/sink delivery of §5.5. (_inv §10_. The 0.4s and
2.5px constants are mechanism; the *outcomes* —
delayed-confirm, drift-suppress, project-handler target — are
the contract.)

---

## 7. Forward contracts (do not exist yet — fenced)

These outcomes are **introduced by the rewrite**; they are
**not** present today. Each is tagged with the version that
establishes it. Do not read any of these as a current
guarantee.

> **Scope.** This forward set covers the **_0.1.0-m4/m5_
> horizon only** — enough to drive the 0.1.0-m4-scoped
> contract-test rewrite. The m6/m7 outcomes the design introduces (named
> submit/cancel chains + `compy.before_exit`, boundary callbacks
> `on_limit_reached`, 0.1.0-m7 `set_text` / cursor /
> `configure`) are
> **not** enumerated here; they are to be added before this note
> is promoted to `internals/`.

### 7.1 Project key/text reach a project sink
**[forward / 0.1.0-m4]**

A first-class `ProjectInputController` receives `keypressed` /
`textinput` / `keyreleased` for a running project and occupies
those slots during the run. Today there is no project-controller
tier distinct from the base slot, and while a widget is active
the project sink is bypassed entirely (EXCLUSIVE keyboard,
§5.1); the rewrite removes the overlay gate and makes the
project controller the slot occupant. (Source:
[M4.md](../design/spec/M4.md);
[M4-0-01](../design/spec/M4-0-01-front-tests.md).)

### 7.2 Slot restoration named to the console
**[forward / 0.1.0-m4]**

On project stop the keypressed/textinput slots are restored to
`ConsoleController` as a **named** contract (vs today's
wholesale default reinstall, §6.4). Same observable end state
today, but the rewrite makes the console the explicit
restoration target rather than an emergent property of
reinstalling defaults. (Source:
[M4.md](../design/spec/M4.md) — Deactivation.)

### 7.3 Native-handler coexistence
**[forward / 0.1.0-m4]**

A project setting its own `love.keypressed` / `love.textinput`
is **legitimate, not legacy**. The contract: **when the
project sets no `compy.input` handler, the default propagates to
the active route's sink**; a project that *does* set a native
handler has that handler driven by the project route.
`ProjectInputController` auto-provisions so the soliciting case
forwards intra-route to the widget and the non-soliciting case
reaches the project's native handler — the same observable end
state as today, after the gate is removed, founded on the active
route rather than on widget presence. (Source:
[M4.md](../design/spec/M4.md);
[M5-01-split.md](../design/spec/M5-01-split.md).)

### 7.4 `isrepeat` reaches the keypressed path
**[forward — split across 0.1.0-m4 / m5]**

`isrepeat` is **structurally dropped** today at the gateway /
slot signatures, which bind only `k` (_inv §8, §11.3_) — no
consumer sees it. The rewrite restores it in **two steps**:
- **[0.1.0-m4]** `isrepeat` is no longer dropped at the gateway
  (the `function(k)` slot signature at `controller.lua:554`
  widens) — it reaches the keypressed path.
- **[0.1.0-m5]** `isrepeat` is delivered to the project keyboard
  callback (`compy.input.on_key_pressed(k, keys_pressed,
  isrepeat)`), with fresh-vs-repeat dispatch keying.

The whole keypressed path is meant to carry the uniform
`(k, keys_pressed, isrepeat)` triple — **the sink included**,
not only the project callback (§9). (Source:
[M4.md](../design/spec/M4.md) test-guardrail;
[M5.md](../design/spec/M5.md);
[M5-01](../design/spec/M5-01-split.md).)

> **Open cross-reference gap (needs a decision, not made
> here).** [M4.md](../design/spec/M4.md)'s own Files section
> names a `ProjectInputController` `keyreleased` tier as "basic
> sink delegation only... 0.1.0-m5 adds dispatch" — but
> [M5.md](../design/spec/M5.md) never actually defines a
> `keyreleased` dispatch tier anywhere; `spec.md` mentions
> `keyreleased` only in the held-key-set context (§6.1). Either
> the 0.1.0-m4 spec's cross-reference is stale, or a scope item
> was silently dropped — checkable, not a matter of
> interpretation. See §9.

---

## 8. Out of #77 blast radius — foundation for future console/editor migration

Per `notes/plan.md`'s scope decision: whole-subsystem is already
mapped; residual one-more-blind-spot risk is accepted. The items
below are **captured, not dropped** — real findings from this
pass, deliberately **not** enforced or fixed by #77 itself, kept
as a starting point for the (separately commissioned, currently
unscheduled) console/editor migration onto the new API.

- **The `keyreleased` console-only fork** (§5.3.2) — matters
  because a future console/editor/search unification must resolve
  this asymmetry deliberately, rather than silently inherit it
  into whatever replaces `ConsoleController:keyreleased`.
- **`inspect`-mode input suppression** (§5.4) — matters because
  the routing unification may legitimately revise how inspect
  ownership works (e.g. one input widget reconfigured by owner
  rather than a separate console path); the owner has deferred a
  ruling, not pinned one.
- **The `search` sub-widget** (§5.8) — a third full MVC triad,
  absent from the whole design corpus; whoever picks up the
  console/editor migration needs this surfaced up front, not
  rediscovered from scratch the way a missing test for a
  different silently-absent surface was caught only by an
  independent review pass (`reviews/M4-0-04.md`).
- **Four incompatible `reset()`/cancel implementations and the
  cursor two-layer split** (§6.6) — matters because
  `compy.input.configure()`/`clear()`/cursor surface (0.1.0-m7) is
  meant to replace exactly this bespoke, disagreeing set with one
  shared, parameterized primitive; there is very little existing
  code to generalize from, and what exists disagrees with itself.

---

## 9. Open questions

Genuinely unresolved; not relitigating settled design.

- **Should the bottom/default sink receive `keys_pressed` (and
  `isrepeat`)? — RESOLVED: yes, uniformly.** The whole keypressed
  path carries `(k, keys_pressed, isrepeat)`, the bottom/default
  sink **included** — not only the project callback. Rationale:
  one signature across the path (so e.g. Shift+Enter can be
  handled in one place); the sink is the default value of
  `on_key_pressed`, which already binds the triple (`design.md`
  §4), so pinning it merely makes that explicit. (Source:
  [user_input.md](../../../internals/user_input.md) — "Key
  state" section.)
- **Is `app_state == 'starting'` ever observed by an input
  path?** The inventory flags this **UNCERTAIN**: by the time
  any event arrives, the state is already `ready` or later, so
  no contract is asserted for `starting`. Recorded so the
  rewrite does not assume one exists. (_inv §2, §Coverage_.)
- **Sink-as-default coupling — owner call.** The sink is the
  **default value** of `on_key_pressed` (`design.md` §4).
  Consequence: a project that **overrides `on_key_pressed`
  silently disables `on_limit_reached`** (the boundary hook the
  sink drove). Flagged for the owner as a **deliberate-or-not**
  decision — not asserted here as a contract.
- **Combo-tier key-repeat semantics — provisional leaning,
  owner-confirmed not-yet-ruled.** Do `handlers[combo]` /
  `framework_handlers` fire on every repeat or only on fresh
  presses? Intent is **silent**. The provisional leaning —
  *fresh-only at the handler tier; `on_key_pressed` sees
  repeats* — is **recorded as provisional, not ruled** (owner:
  settle it nearer implementation). **Added constraint (owner
  ruling): existing combos keep their current behaviour *unless*
  explicitly altered** — the provisional dispatch keying must not
  silently change a combo that works today. Do not promote the
  leaning to a contract.
- **0.1.0-m4↔0.1.0-m5 `keyreleased` dispatch cross-reference
  gap (§7.4).** The 0.1.0-m4 spec names a deliverable ("basic
  sink delegation... 0.1.0-m5 adds dispatch") that the 0.1.0-m5
  spec never actually specifies. Needs an explicit decision
  before the two milestones land — descope with a one-line note,
  or add the missing dispatch tier. Not decided here; surfaced
  for the human / the milestone-prompt owner. (See
  `plan-reevaluation-against-session-findings.md`, item 1, and
  `notes/plan.md` — "Forward path".)
- **`combo_string`/`keys_pressed` have zero current `src/`
  callers** outside their own bookkeeping (§6.1) — taken as a
  strong negative from exhaustive grep, not asserted as a
  contract, only noted so the rewrite does not assume an existing
  consumer it would have to preserve.
