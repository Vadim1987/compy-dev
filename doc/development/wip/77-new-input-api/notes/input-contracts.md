# Input Routing — Contracts

<!-- authored by LLM (Opus 4.8); human-approved: NOT YET -->
<!-- P2 of 2: contracts distilled from the inventory. -->
<!-- candidate to promote to doc/development/internals/ at
     feature close. -->
<!-- s26 (orchestrator, Opus 4.8), two passes:
     (1) planned-vs-existing separation — forward caveats on
     §3.1 (F-A) + §4.6 (F-D); intent flags on §3.4/§3.7/order.
     (2) post cold-revalidation (P3) + human rulings — §3.7
     wheel = pass-through-by-default / project-opt-in (R1);
     §3.4 inspect = deliberate modal, outcome pinned + mechanism
     dropped + reversible (R2); §3.5/§3.8 within-event order =
     incidental (R3); §4.6 force = reconfig flag-gated, scope
     forward-controllable per SR2 (R6); §5 scope-fenced to
     m4/m5 (R7); widget/overlay glossary (R8); §6.1 reworked
     seed→resolutions. Stable-now OUTCOME contracts unchanged. -->
<!-- s27 (orchestrator, Opus 4.8): retired LLM-coined "base
     sink" (overlay-gate mechanism leaking into durable
     vocabulary — human contest). Canonical vocabulary =
     route / sink / widget (§2 glossary). §2 reframed (routing
     + route-owned widgets; the "mode × widget orthogonality"
     was an overlay artifact, dropped); §3 notation + tables
     "route" → "route". OUTCOMES UNCHANGED — vocabulary
     only. human-approved: pending. -->
<!-- prompt12 (cold pass, Opus 4.8): unbiased correction of the
     interpretation drift the intent-fidelity audit localized
     here (D-A..D-E). §2/§3 re-founded on SINGLE inter-route
     EXCLUSIVITY for EVERY event type (keyboard/text/pointer),
     grounded in mode-exclusivity + the ratified three-controller
     topology; widget-presence demoted to today's-mechanism
     notes; the EXCLUSIVE-keyboard/BOTH-pointer asymmetry retired
     (§3.5/§3.8). Per-row provenance tags added (PRESERVE vs
     CHARACTERIZE-PROVISIONAL). D-D reframed (native handling =
     legitimate, not legacy, §5.3); D-E + D-C carried as owner
     questions (§6). Ledger: notes/input-contracts-correction.md.
     human-approved: pending — STOP for owner blessing. -->

Companion (descriptive "how it works today"):
[user_input.md](../../../internals/user_input.md).
Factual basis (every claim here traces back to it):
[`input-contracts-inventory.md`](input-contracts-inventory.md).
That inventory carries the `file:line` citations; this note
cites it by section (e.g. _inv §4_) rather than re-deriving
line numbers.

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
  named version establishes it (§5). Never read a forward
  contract as a present guarantee.

Versions, not milestones, anchor the durable text: horizons
use semver pre-release markers (e.g. _0.1.0-m4_), never bare
"M4 does X" prose.

---

## 2. Routing — one route per event (all event types)

Routing selects **one route** per input event — keyboard, text,
**AND** pointer (see Glossary); a route may have a **widget** up.
The earlier "two orthogonal activations (mode × widget)" framing
is **retired**: that orthogonality was an artifact of the global
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

> **Provenance of this invariant (PRESERVE).** It is a **ratified
> design rule**, not a stakeholder mandate. Intent is *silent* on
> inter-route topology per se; the rule **derives** from
> mode-exclusivity (a real system property) + the architect-
> ratified three-controller topology (Console / Editor /
> ProjectInputController), endorsed via
> [`decisions.md`](../design/notes/decisions.md). State it as
> design authority, not as something a stakeholder demanded.

> **"EXCLUSIVE" disambiguation (D-B).** Here EXCLUSIVE is on the
> **route axis** (one *route* per event). It does **not** collide
> with the stakeholders' "**no exclusivity, no suppression**",
> which is on the **channel axis** (key and text are two
> independent channels that both fire — §4 / `spec.md §1`). The
> two senses are different axes; do not read one as the other.
> The only legitimate **"both" is intra-route** (a route
> delivering one event to its own logic *and* to a surface it
> activated — the "parallel handling" tier-1 asks for); that is
> the route's private affair and is **invisible** to this
> inter-route contract.

> **Glossary — canonical input-routing vocabulary (s27).**
> Reference these three terms from the suite and specs; do not
> coin alternates. (Supersedes the LLM-coined "route,"
> retired as overlay-gate mechanism leaking into durable vocab.)
>
> - **route** — the path a keyboard/text event takes to its
>   consumer. Routing selects **exactly one route per event**.
>   Current value set: `{ overlay, ConsoleController,
>   EditorController }`; the rewrite replaces it with
>   `{ ConsoleController, EditorController,
>   ProjectInputController }` — the global overlay gate is
>   removed and the project gains a first-class route.
>   **Contract (intact across the rewrite): every keyboard/text
>   event travels via exactly one route — never silently
>   dropped, never more than one.**
> - **sink** — the default / last-resort disposition a route
>   provides and manages for an event it did not specifically
>   handle (no matching handler or combo). Deliberately
>   implementation-light: routes need **not** realize it
>   identically — Console/Editor may differ from the project
>   route. *Current realization:* `UserInputController` is
>   purposefully a **global singleton** the active route takes
>   control of; "UIC becomes the *universal* terminal sink"
>   (`design.md §2`) is a **recommended objective**, not a
>   present fact — Console/Editor routing-through-UIC is
>   postponed and may be contested. A widget often serves as its
>   route's sink, but not always.
> - **widget** — the route-managed input *surface* that solicits
>   text. Owned by the active route's controller, **not** a
>   free-floating global. Today the project's widget is realized
>   as the overlay singleton (`love.state.user_input`) — the
>   mechanism the rewrite removes. A widget can serve as its
>   route's sink (text editing), but the two notions are
>   distinct. A widget **never occupies a LÖVE handler slot in
>   any context** — the route's controller occupies the slot and
>   forwards to the widget internally (see §2A).
>
> Pointer (mouse/touch) and wheel are **not** exceptions to
> exactly-one-route: like keyboard/text they reach the single
> active route. Any forwarding to a widget is **intra-route** (the
> route's concern), not a second inter-route delivery — outcomes
> in §3.5–3.7.

**(A) Routing — which consumer owns the event.** The
application `app_state` selects which **route** owns the event
slot: `ready` / `project_open` / `running` / `inspect` /
`snapshot` / `editor` / `shutdown` (_inv §2_). In every
non-running state the route is the single `ConsoleController`
(CC), which sub-routes console-vs-editor internally; while a
project runs, the project's route (the overlay today;
`ProjectInputController` after the rewrite) owns the
keyboard/text slots (§3). (Current realization: `app_state`
branching inside CC, the overlay gate, and `set_handlers` slot
swaps.)

**The slot occupant is the controller, not the widget**
(endorsed design). A **controller** (route) occupies the LÖVE
handler slot and dispatches each event **internally**: through
its **handlers**, then the **project slots** established on the
LÖVE clone, with **userinput as the final destination** (the
sink). The widget is one surface the controller may forward to
along that internal path — it is **never itself a slot
occupant**, in any context. So "the active route owns the slot"
and "a widget solicits input" are different layers: inter-route
slot ownership vs. intra-route forwarding.

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
un-gated mouse path), characterized per event in §3, **not** a
routing contract. Today the overlay is global and appears
independent of mode; that independence is mechanism, not
contract — forward, the widget is owned by the routed
controller.

**(C) Hidden widget does not consume.** [PRESERVE — owner ruling
(prompt12) + common logic.] An event that reaches a widget while
the widget is **hidden** is **ignored or passed through by the
widget** — never used to mutate widget state. When the widget is
not on screen, no user intent to modify its state can be assumed.
This is an **intra-route** rule (the route's surface declines the
event); inter-route dispatch is unchanged — the event still
reached its one active route (§3). It applies to **every** event
type a widget might be offered.

**Two-step nature.** First a route is selected by mode/context;
then that route may have a widget (de)activated within it. The
widget never changes the route; the route (`inspect` open —
§3.4) governs whether a widget is honoured. "Widget up while in
console mode via a free-floating `show_widget()`" is therefore
an **incoherent scenario** under this model: a widget only
exists when its owning route is active.

**Reset semantics (widget re-activation).** Re-activating an
already-active widget is **not** a fresh activation:
- without `force` → the request is **suppressed and warned**,
  state untouched (warn-on-suppression is a contract, §4.6).
- with `force` → a live reconfiguration is applied (**today
  only the `text` subset** takes effect, other config ignored;
  the reconfiguration *scope* is forward-controllable, §4.6),
  and **no cancel chain fires**.
- a fresh activation (widget was inactive) with **no text
  supplied starts empty** — re-show does not inherit prior
  text.
(_inv §6_. Current realization: `show`/`open_fresh` in
`userInputController.lua`.)

---

## 3. The contract table — per active route, per event

Notation. **route** = the consumer the event is dispatched to
(§2; the mode route — Console/Editor — or the project route),
selected by mode/context. **widget** = the active input surface
*within* a route (§2B). **EXCLUSIVE** = exactly **one route**
receives the event — for **every** event type (keyboard, text,
pointer). There is **no inter-route "BOTH"**: the only "both" is
**intra-route** (a route forwarding an event it received to a
surface it activated), which is the route's concern and invisible
to this contract (§2).

Each row carries a **provenance** tag (the anti-drift gate):
- **PRESERVE** — traces to a tier-1/2 mandate (cited) **or** to
  the ratified inter-route-exclusivity principle (§2).
- **CHARACTERIZE-PROVISIONAL** — observed current behaviour with
  no mandate; **expected to change, no stakeholder mandate**.
A row with neither a mandate nor the principle behind it may
**not** be PRESERVE.

All contracts in this section are **[stable-now]** unless a
row says otherwise.

### 3.1 keypressed — EXCLUSIVE on the active route [PRESERVE]

**Contract.** A `keypressed` reaches **exactly one route** — the
active one, fixed by mode/context (§2). Never zero, never two.
Global shortcuts (§4.3) and held-key tracking (§4.1) run first
but do **not** consume — the same key still arrives at that one
route. (_inv §4 keypressed_.)

**Provenance — PRESERVE.** Inter-route exclusivity = the ratified
principle (§2). The further tier-1 mandate it must honour: *"no
backward compat, but only TEXT FIELDS break; native keyboard
handling must keep working"* — stated **at the route level**: a
running project's route keeps receiving keys (its native keyboard
handling is not broken). The break is bounded to text fields, not
to keyboard dispatch.

> **What is NOT the contract — today's mechanism [CHARACTERIZE-
> PROVISIONAL] (was F-A, D-A).** Today routing is keyed on
> **widget presence**: *widget up ⇒ the widget consumes, the
> project sink bypassed entirely* — literally the `if
> get_user_input() then …` overlay gate at the dispatch point
> (`controller.lua`). That is **today's realization, expected to
> change, no stakeholder mandate** — it is the precise drift #77
> exists to cure. The rewrite removes the gate and routes project
> keys to the `ProjectInputController` (§5.1). Read §3.1–3.3 as
> "exactly one **route**," **never** as a contract to preserve
> project-key-drop-under-widget — that drop is a limitation being
> fixed, not a guarantee. Which surface the active route uses
> internally (a widget, its sink) is intra-route and invisible
> here.

### 3.2 textinput — EXCLUSIVE on the active route [PRESERVE]

Same shape and provenance as keypressed (§3.1): `textinput`
reaches exactly one route, the active one. The widget-presence
keying is the same today's-mechanism note as §3.1 — CHARACTERIZE-
PROVISIONAL, not the contract. (_inv §4 textinput_.)

### 3.3 keyreleased — EXCLUSIVE on the active route [PRESERVE]

Same shape and provenance: `keyreleased` reaches exactly one
route, the active one. The held-key removal (§4.1) and the
Ctrl+Escape quit guard (§4.3) run first and do not consume.
(_inv §4 keyreleased_.)

> **Today's mechanism [CHARACTERIZE-PROVISIONAL].** Today a
> release does **not** reach the route under a widget (same gate
> as §3.1). Under the route-centric model a release should reach
> the active route; this is **expected to change** (possibly a
> defect to fix, not preserve). Open: does any consumer consume
> `keyreleased` today at all? — carry provisional.

### 3.4 Mode override: `inspect` — the console owns the input surface [CHARACTERIZE-PROVISIONAL · OWNER RULING PENDING]

> **Owner ruling (prompt12): deliberately deferred — keep the
> assumption.** How `inspect` is meant to operate after
> unification is still not pinned, and the feature is dev-facing;
> the owner chose to **retain the current assumption** rather
> than rule now. Carried CHARACTERIZE-PROVISIONAL; do **not**
> invent a contract — revisit when the routing model lands.

**Current behaviour [provisional — not pinned, see ruling]:**
when `app_state == 'inspect'`, the input surface serves the
**console REPL** (console-owned); a project-set widget is **not
honoured**. Input is **not blocked** — the project is frozen and
the REPL is live over it, so keyboard / text / pointer drive the
console. This is the one place mode overrides widget. (_inv §4
head, §11.2_. Current realization: `get_user_input()` returns
nil under `inspect`, and suspend restores console handlers —
mechanism, non-binding.)

> **Provisional — kept for now, expected to change (s26 ruling,
> was F-C).** This is **current behaviour we retain as-is**, not
> a preserve-forever contract. The routing unification and the
> new singleton / `ProjectInputController` model may
> **legitimately revise** how inspect ownership works (e.g. one
> input widget reconfigured by owner — console vs project —
> rather than a separate console path). So it is **not** tagged
> `[stable-now]` must-preserve: **characterize** the current
> shape, do **not** write a regression guard that would red on a
> deliberate inspect change. Design-silent — no M4–M8 spec
> addresses inspect routing — revisit when the routing model
> lands (the REPL is itself an input surface, so "modal" here
> means console-owned, not input-disabled).

### 3.5 mousepressed / mousereleased / mousemoved — EXCLUSIVE on the active route [PRESERVE]

**Contract.** A pointer event reaches **the active route** — the
one fixed by mode/context (§2). **Intra-route forwarding to a
widget is the route's concern**, not a second inter-route
delivery: when a route has a widget up it may hand the pointer to
that widget *and* to its own logic, in parallel — that is the
route's private affair (§2), invisible to this contract.

**Provenance — PRESERVE** (ratified principle, §2).

> **No inter-route "BOTH" (was the §3.5 BOTH table; D + the
> pointer correction).** An earlier draft tabulated pointer as
> inter-route **BOTH** ("a click reaches both a route and a
> widget"). That was **today's mechanism promoted to invariant**:
> the keyboard path has the overlay gate, the **mouse path does
> not**, so today a click happens to reach both the underlying
> controller and the widget. When a project is running, a click
> is **not** propagated to the editor route — the running mode
> owns the whole screen; there is no second top-level route to
> receive it. So pointer is EXCLUSIVE inter-route like every
> other event; the "both" is intra-route only. Today the widget
> is called before the sink, but nothing is owed to that ordering
> (R3). Under `inspect` (§3.4) the route's intra-route forwarding
> to a project widget is suppressed; the active route is
> unaffected. (_inv §4 mouse*, §10_.)

### 3.6 touchpressed / touchreleased / touchmoved — EXCLUSIVE on the active route [PRESERVE]

Same contract and provenance as mouse (§3.5): touch reaches the
active route; intra-route forwarding to a widget is the route's
concern. (The widget's touch handlers are no-ops today — that is
mechanism, not part of the contract; the **delivery** to the
active route is what is guaranteed.) (_inv §4 touch*_.)

### 3.7 wheelmoved — reaches the active route [CHARACTERIZE-PROVISIONAL]

**Contract (route axis, PRESERVE):** `wheelmoved` reaches the
**active route**, like every other event (§2).

**Provisional today:** the framework **default is a no-op** —
nothing acts on a wheel move unless the project defines its own
`love.wheelmoved` handler; and the active route does not forward
wheel to a widget. The "widget is never offered wheel" framing is
**mechanism by omission** (no wheel entry in the gateway), **not**
a designed asymmetry — CHARACTERIZE-PROVISIONAL. (_inv §1, §4
wheelmoved, §11.1_.)

> **Intent (s26 ruling, was F-B): pass-through by default,
> project-opt-in to consume — do not structurally block.** The
> authoritative descriptive docs treat wheel as forwarded to
> project handlers via the standard LÖVE2D mechanism
> (`internals/user_input.md:169`, `event_routing.md:319-322`),
> never as framework-consumed — so widget-bypass is
> **incidental by-omission**, not a designed asymmetry. Intended
> shape: **wheel passes through to the project; the framework
> consumes it only if the project explicitly opts in (no-op by
> default)**. Structurally blocking wheel would be an exotic,
> hard-to-maintain solution and is not wanted; revise toward
> project-opt-in if/when wheel is unified — do **not** pin
> widget-never-sees-wheel as a preserve-forever guarantee.
> (System-owned surfaces such as the error explorer do consume
> mousewheel — `error_explorer.md:26` — but that is outside the
> project-input contract.)

### 3.8 The one rule — inter-route exclusivity for every event

The earlier "two canonical asymmetries (keyboard EXCLUSIVE vs
pointer BOTH)" is **retired** (D-A / pointer correction): it
encoded today's mechanism (keyboard gated, mouse un-gated), not
an invariant. There is **one** rule:

- **Every event type** — keypressed, textinput, keyreleased,
  mouse, touch, wheel — is **EXCLUSIVE inter-route**: it reaches
  exactly one route, the active one fixed by mode/context (§2).
  [PRESERVE — ratified principle.]
- The only **"both" is intra-route**: a route may forward an
  event it received to a widget it activated *and* run its own
  logic, in parallel — the route's private affair, invisible to
  inter-route dispatch (§2). This is the "parallel handling"
  tier-1 asks for.
- **`inspect`** = console owns the input surface; project widget
  not honoured (CHARACTERIZE-PROVISIONAL — §3.4, OWNER RULING
  PENDING).
- **Global shortcuts** = non-consuming (§4.3) — they fire and
  the key still reaches its active route.

---

## 4. Cross-cutting contracts

### 4.1 Held-key set lifecycle — [stable-now]

A held-key set (`Controller.keys_pressed`, a `{ name → true }`
table) is maintained around the keyboard path:
- a key is **added on press** and **removed on release**,
  always, **before** any shortcut or sink dispatch runs;
- names are raw LÖVE names with **left/right unfolded**
  (`lctrl` and `rctrl` are distinct entries).

Contract: at the moment any keypressed consumer runs, the set
reflects the key just pressed; at the moment any keyreleased
consumer runs, the released key is already gone. (_inv §8_.
Current realization: writes at the top of the gateway's
keypressed/keyreleased.)

### 4.2 Combo serialisation — [stable-now]

`Controller.combo_string(k, keys_pressed)` serialises a key
event to a canonical string: held modifiers in fixed
precedence **ctrl, alt, shift, gui**, then the key, joined by
`+`; left/right **folded** to the generic name; no modifiers →
the bare key name. Contract: the serialisation is **stable and
order-canonical** (`lctrl`+`s` → `"ctrl+s"`). (_inv §8_.
Note: today this function and `keys_pressed` have **no
in-`src/` consumer** — they are staged for the planned
dispatch, §5. The serialisation *format* is the durable
guarantee; its wiring is forward.)

### 4.3 Global shortcuts are non-consuming — [stable-now]

The framework-level shortcuts intercepted on the keyboard path
(Ctrl+Pause suspend, Ctrl+Q quit-project, Ctrl+S
stop/close, Ctrl+Shift+R reset, Ctrl+Alt+R restart,
Ctrl+t quickswitch, profile keys; and Ctrl+Escape quit on
release) **fire their effect but do not consume the key** — it
still reaches its sink per §3. Play mode (`cfg.mode=='play'`)
narrows the active set to restart/profile; that mode gate is
itself a contract. (_inv §7_.) DEBUG-only view toggles live in
the route keypressed (not the framework shortcut layer); they
fire when the active route handles the key itself rather than
forwarding it intra-route to a soliciting widget — a consequence
of §3.1, recorded for completeness.

### 4.4 Slot restoration on project stop — [stable-now]

On project stop, the route for **every** slot is restored
to the framework default (CC-owned) — wholesale, not per-key:
whatever handlers a running project installed are overwritten
by the default set, and `update`/`draw`/widget handle are
reset. Contract: **after stop, no project handler remains
wired in any slot**; the console owns input again. (_inv §3
"Restore on stop"_. Current realization: `set_default_handlers`
reinstalls defaults; the project fns are overwritten, not
individually reverted. The forward, sink-named form of this is
§5.2.)

### 4.5 Legacy solicitation path — [stable-now]

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

### 4.6 Widget activation / reset guarantees — [stable-now]

Restating §2's reset semantics as standalone contracts:
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

> **[stable-now; superseded FORWARD / 0.1.0-m6] (F-D).** The
> "no cancel chain" facts above (and in §2's reset semantics)
> describe **today**. The rewrite introduces **named
> submit/cancel chains** (design decision D-4); from
> _0.1.0-m6_ `hide()` and cancel paths *do* fire a cancel
> chain. These are stable-now-**until-superseded**, not
> preserve-forever. (Source: M6 spec. The m6 forward contract
> is not enumerated in §5 — see the §5 scope note, §6.1.)

> **[stable-now contract = the flag-gate; reconfig scope
> FORWARD] (R6).** Per SR2 (authoritative over the architect's
> "allow all hot reconfigs"), live reconfiguration is permitted
> **only behind the explicit `force` flag** — that gate is the
> durable contract. The **scope** of what `force` reconfigures
> is a deliberately **code-controllable, evolving** question:
> today text-only, to widen/tighten as the `compy.input` API
> matures (D-2 "force reconfigures"; M7 `configure()`). Read
> "text-only on force" as **today's scope, not a preserve-
> forever limitation** — the rewrite may legitimately expand
> it. (**M7 verification item:** whether `force` itself widens
> or `configure()` owns reconfigure is an open design read.)

### 4.7 Framework click detection — [stable-now]

Single/double-click detection is a framework guarantee
independent of the raw pointer delivery (§3.5):
- a single click is **confirmed only after a 0.4s window**
  with no second release — there is **no instant single
  click**;
- a click is **suppressed if the pointer drifts > 2.5px**
  between press and release;
- confirmation invokes the **project-defined** `compy.
  singleclick` / `compy.doubleclick` (looked up in the project
  `compy` table; default no-ops), **not** a LÖVE event.

This derived click delivery is a **third** path, separate from
the raw widget/sink delivery of §3.5. (_inv §10_. The 0.4s and
2.5px constants are mechanism; the *outcomes* —
delayed-confirm, drift-suppress, project-handler target — are
the contract.)

---

## 5. Forward contracts (do not exist yet — fenced)

These outcomes are **introduced by the rewrite**; they are
**not** present today. Each is tagged with the version that
establishes it. Do not read any of these as a current
guarantee.

> **Scope (R7).** This forward set covers the **_0.1.0-m4/m5_
> horizon only** — enough to drive the M4-scoped contract-test
> rewrite. The m6/m7 outcomes the design introduces (named
> submit/cancel chains + `compy.before_exit` (M6/M6-02, D-4),
> D-5 boundary callbacks `on_limit_reached`, M7 `set_text` /
> cursor / `configure`) are **not** enumerated here; they are
> to be added before this note is promoted to `internals/`.

### 5.1 Project key/text reach a project sink
**[forward / 0.1.0-m4]**

A first-class `ProjectInputController` receives `keypressed` /
`textinput` / `keyreleased` for a running project and occupies
those slots during the run. Today there is no project-controller
tier distinct from the base slot, and while a widget is active
the project sink is bypassed entirely (EXCLUSIVE keyboard,
§3.1); the rewrite removes the overlay gate and makes the
project controller the slot occupant. (Source:
[M4.md](../design/spec/M4.md);
[M4-0-01](../design/spec/M4-0-01-front-tests.md).)

### 5.2 Slot restoration named to the console
**[forward / 0.1.0-m4]**

On project stop the keypressed/textinput slots are restored to
`ConsoleController` as a **named** contract (vs today's
wholesale default reinstall, §4.4). Same observable end state
today, but the rewrite makes the console the explicit
restoration target rather than an emergent property of
reinstalling defaults. (Source:
[M4.md](../design/spec/M4.md) — Deactivation.)

### 5.3 Native-handler coexistence (D-9)
**[forward / 0.1.0-m4]**

A project setting its own `love.keypressed` / `love.textinput`
is **legitimate, not legacy** (D-D). The contract: **when the
project sets no `compy.input` handler, the default propagates to
the active route's sink**; a project that *does* set a native
handler has that handler driven by the project route.
`ProjectInputController` auto-provisions so the soliciting case
forwards intra-route to the widget and the non-soliciting case
reaches the project's native handler — the same observable end
state as today, after the gate is removed, founded on the active
route rather than on widget presence. (Source:
[M4.md](../design/spec/M4.md) — D-9;
[M5-01-split.md](../design/spec/M5-01-split.md).)

### 5.4 `isrepeat` reaches the keypressed path
**[forward — split across 0.1.0-m4 / m5 (s27 D-γ)]**

`isrepeat` is **structurally dropped** today at the gateway /
slot signatures, which bind only `k` (_inv §8, §11.3_) — no
consumer sees it. The rewrite restores it in **two steps**
(reconciling the roadmap, which threads it at M4, with the
prior single-m5 tag):
- **[0.1.0-m4]** `isrepeat` is no longer dropped at the gateway
  (the `function(k)` slot signature at `controller.lua:554`
  widens) — it reaches the keypressed path.
- **[0.1.0-m5]** `isrepeat` is delivered to the project keyboard
  callback (`compy.input.on_key_pressed(k, keys_pressed,
  isrepeat)`), with fresh-vs-repeat dispatch keying.

Per **s27 D-α**, the whole keypressed path carries the uniform
`(k, keys_pressed, isrepeat)` triple — **the sink included**,
not only the project callback (§6 Q1, resolved). (Source:
[M4.md](../design/spec/M4.md) test-guardrail;
[M5.md](../design/spec/M5.md);
[M5-01](../design/spec/M5-01-split.md).)

---

## 6. Open questions

Genuinely unresolved; not relitigating settled design.

- **Should the bottom/default sink receive `keys_pressed` (and
  `isrepeat`)? — RESOLVED (s27 D-α): yes, uniformly.** The
  whole keypressed path carries `(k, keys_pressed, isrepeat)`,
  the bottom/default sink **included** — not only the project
  callback. Rationale: one signature across the path (so e.g.
  Shift+Enter can be handled in one place); the sink is the
  default value of `on_key_pressed`, which already binds the
  triple (`design.md §4`), so pinning it merely makes that
  explicit. (Was: open, deferred to the m4/m5 design session —
  that session is s27. Source:
  [user_input.md](../../../internals/user_input.md) — "Key
  state" section.)
- **Is `app_state == 'starting'` ever observed by an input
  path?** The inventory flags this **UNCERTAIN**: by the time
  any event arrives, the state is already `ready` or later, so
  no contract is asserted for `starting`. Recorded so the
  rewrite does not assume one exists. (_inv §2, §Coverage_.)
- **Sink-as-default coupling (D-E) — owner call.** The sink is
  the **default value** of `on_key_pressed` (`design.md §4`).
  Consequence: a project that **overrides `on_key_pressed`
  silently disables `on_limit_reached`** (the boundary hook the
  sink drove). Flagged for the owner as a **deliberate-or-not**
  decision — not asserted here as a contract.
- **Combo-tier key-repeat semantics (D-C) — provisional leaning,
  owner-confirmed not-yet-ruled.** Do `handlers[combo]` /
  `framework_handlers` fire on every repeat or only on fresh
  presses? Intent is **silent**; tier-3 flagged it as the one
  substantive open question. The provisional leaning — *fresh-only
  at the handler tier; `on_key_pressed` sees repeats* — is
  **recorded as provisional, not ruled** (owner, prompt12: settle
  it nearer implementation). **Added constraint (owner ruling):
  existing combos keep their current behaviour *unless* explicitly
  altered** — the provisional dispatch keying must not silently
  change a combo that works today. Do not promote the leaning to a
  contract.

### 6.1 Revalidation outcomes (s26: P3 + human rulings)

The cold revalidation (P3,
[`input-contracts-revalidation.md`](input-contracts-revalidation.md))
verdict was **sound after listed corrections** — no factual
error against code, no contract invented or dropped. The s26
seed flags are now resolved and folded into the sections above:

- **(F-A) keyboard EXCLUSIVE / project-drop** → **confirmed**
  (R4): exactly-one-consumer is preserved; project-key-drop is
  fixed-not-preserved. §3.1 caveat stands.
- **(F-D) hide / no-cancel-chain** → **confirmed** (R5):
  superseded at _0.1.0-m6_. §4.6 caveat stands.
- **(F-B) wheel bypass** → **incidental** (R1): intended shape
  is project pass-through with project-opt-in consume (§3.7).
- **(F-C) inspect input ownership** → **provisional, not pinned**
  (R2): current behaviour (console/REPL owns input, project
  widget not honoured, input not dead) is **kept for now but
  expected to change** under routing unification + the singleton
  — characterize, do not regression-guard (§3.4).
- **(F-E) within-event order** → **incidental** (R3), not a
  guarantee (§3.5/§3.8). Cross-event textinput-before-keypressed
  order remains correctly **un-pinned** (E20/E9: no event-order
  guarantee owed).
- **(§5 scope)** → acceptable m4/m5 scoping for now; §5 is
  scope-fenced and the m6/m7 set is enumerated before
  `internals/` promotion (R7).
- **(R6, new — found by revalidation)** → `force` reconfigure:
  the flag-gate is pinned, the reconfigure *scope* is forward-
  controllable (§4.6). SR2 authoritative.

**Verification carried forward** (cannot be asserted from the
docs; resolve in the milestone that touches them):
- **R2 / M4** — inspect ownership is **provisional**: when the
  routing model lands, decide its inspect behaviour
  **deliberately** (a change is expected, not a silent break).
- **R6 / M7** — whether `force` itself widens or `configure()`
  owns live reconfigure is a design read.

---

_Items carried as UNCERTAIN from the inventory and left
unasserted here: (a) `starting` reachability by an input path
(above); (b) that `combo_string`/`keys_pressed` have zero
current `src/` callers — taken as a strong negative from
exhaustive grep, surfaced in §4.2 rather than asserted as a
contract._
