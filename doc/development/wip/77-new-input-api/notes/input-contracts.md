# Input Routing — Contracts

<!-- authored by LLM (Opus 4.8); human-approved: NOT YET -->
<!-- P2 of 2: contracts distilled from the inventory. -->
<!-- candidate to promote to doc/development/internals/ at
     feature close. -->

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

## 2. The two activation families (orthogonal axes)

Routing is governed by **two independent activations**. Model
them as two axes, not one chain.

**(A) Mode activation — the base sink.** The application
`app_state` selects which consumer owns the event slot:
`ready` / `project_open` / `running` / `inspect` / `snapshot`
/ `editor` / `shutdown` (_inv §2_). Mode determines the
**base sink** — the consumer an event reaches when no input
widget intercepts. In every non-running state the base sink
is the single `ConsoleController` (CC), which sub-routes
console-vs-editor internally; a running project may take over
individual slots (§3). (Current realization: `app_state`
branching inside CC, and `set_handlers` slot swaps.)

**(B) Widget activation / reset — the override.** An input
**widget** (the overlay singleton today) is shown / reset /
hidden **orthogonally** to mode. While active it **overrides**
the base sink for keyboard and text, and is **added alongside**
it for pointer events (§3). Mode and widget are independent:
any mode can have the widget up or down.

**Two-step nature.** First a mode is active (a base sink is
chosen); then a widget may be (de)activated *on top of* it.
The widget never changes the mode; the mode (except `inspect`,
§3.4) never changes whether the widget is honoured.

**Reset semantics (widget re-activation).** Re-activating an
already-active widget is **not** a fresh activation:
- without `force` → the request is **suppressed and warned**,
  state untouched (warn-on-suppression is a contract, §4.6).
- with `force` → only the `text` subset is applied live;
  other config is ignored, and **no cancel chain fires**.
- a fresh activation (widget was inactive) with **no text
  supplied starts empty** — re-show does not inherit prior
  text.
(_inv §6_. Current realization: `show`/`open_fresh` in
`userInputController.lua`.)

---

## 3. The contract table — `(mode × widget-state)` per event

Notation. **base sink** = the mode-selected consumer (§2A).
**widget** = the active input widget (§2B). **EXCLUSIVE** =
exactly one consumer receives the event. **BOTH** = widget and
base sink each receive it. "widget active" means a widget is
shown **and** not suppressed by mode (§3.4).

All contracts in this section are **[stable-now]** unless a
row says otherwise.

### 3.1 keypressed — EXCLUSIVE

| widget active? | receives |
|---|---|
| yes | widget only |
| no  | base sink only |

The key reaches **one** consumer, never both. Global shortcuts
(§4.3) and held-key tracking (§4.1) run first but do **not**
consume — the same key still arrives at exactly one of the two
above. (_inv §4 keypressed_. Current realization:
`get_user_input()` gate at the dispatch point.)

### 3.2 textinput — EXCLUSIVE

Same shape as keypressed: widget-only when active, else base
sink only. Never both. (_inv §4 textinput_.)

### 3.3 keyreleased — EXCLUSIVE

Same shape. The held-key removal (§4.1) and the
Ctrl+Escape quit guard (§4.3) run first and do not consume.
(_inv §4 keyreleased_.)

### 3.4 Mode override: `inspect` suppresses the widget

When `app_state == 'inspect'`, the widget is **suppressed**:
keyboard/text/pointer events flow to the base sink **as if no
widget were active**, even when one is set. This is the one
place mode overrides widget. **[stable-now]** (_inv §4 head,
§11.2_. Current realization: `get_user_input()` returns nil
under `inspect`.)

### 3.5 mousepressed / mousereleased / mousemoved — BOTH

| widget active? | receives |
|---|---|
| yes | widget **and** base sink (widget first) |
| no  | base sink only |

Pointer delivery is **non-exclusive**: an active widget does
not deny the base sink. Order is widget-then-sink. Under
`inspect` the widget half is suppressed (§3.4); the base sink
half is unaffected. (_inv §4 mouse*, §10_.)

### 3.6 touchpressed / touchreleased / touchmoved — BOTH

Same BOTH contract and order as mouse (§3.5). (The widget's
touch handlers are no-ops today — that is mechanism, not part
of the contract; the **delivery** is what is guaranteed.)
(_inv §4 touch*_.)

### 3.7 wheelmoved — base sink only (widget never sees it)

| widget active? | receives |
|---|---|
| yes | base sink only |
| no  | base sink only |

Wheel is **EXCLUSIVE to the base sink**: the widget is **never**
offered wheel events, regardless of activation. This is an
asymmetry vs the other pointer events (which are BOTH). It is a
real present-state guarantee, not an oversight to silently
"fix" — note it explicitly so the rewrite preserves or
deliberately revises it. (_inv §1, §4 wheelmoved, §11.1_.
Current realization: there is no wheel entry in the gateway, so
wheel bypasses the widget by omission.)

### 3.8 The two canonical asymmetries, stated as one rule

- **Keyboard / text** (keypressed, textinput, keyreleased) =
  **EXCLUSIVE** — widget XOR base sink.
- **Mouse / touch** (pressed/released/moved) = **BOTH** —
  widget and base sink, widget first.
- **Wheel** = base sink only, widget never.
- **`inspect`** = widget suppressed everywhere (§3.4).
- **Global shortcuts** = non-consuming (§4.3) — they fire and
  the key still reaches its consumer.

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
the base-sink keypressed (not the framework shortcut layer) and
so are only reachable when the widget does **not** intercept
(EXCLUSIVE keyboard path) — a consequence of §3.1, recorded
for completeness.

### 4.4 Slot restoration on project stop — [stable-now]

On project stop, the base sink for **every** slot is restored
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
- **already-active with `force` → text-only live update**, no
  other config applied, no cancel chain.
- **fresh activation with no text → empty.**
- **`hide()` deactivates without firing a cancel chain.**
- **auto-close on submit:** a successful oneshot submit
  deactivates the widget (today via a pushed `userinput`
  event). (_inv §5, §6_.)

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

### 5.3 Legacy native-handler coexistence (D-9)
**[forward / 0.1.0-m4]**

A project defining a native `love.keypressed` /
`love.textinput` but none of the new `compy.input` surfaces is
treated as legacy: `ProjectInputController` auto-provisions so
the singleton-shown case routes to the widget and the
singleton-hidden case routes to the project's native handler —
reproducing today's gated behaviour after the gate is removed.
(Source: [M4.md](../design/spec/M4.md) — D-9;
[M5-01-split.md](../design/spec/M5-01-split.md).)

### 5.4 `isrepeat` reaches the keypressed path
**[forward / 0.1.0-m5]**

`isrepeat` becomes available to the project keyboard callback
(`compy.input.on_key_pressed(k, keys_pressed, isrepeat)`, with
fresh-vs-repeat dispatch keying). Today `isrepeat` is
**structurally dropped** at the gateway/slot signatures, which
bind only `k` (_inv §8, §11.3_) — no consumer sees it.
(Source: [M5.md](../design/spec/M5.md);
[M5-01](../design/spec/M5-01-split.md).)

---

## 6. Open questions

Genuinely unresolved; not relitigating settled design.

- **Should the base/bottom sink receive `keys_pressed` (and
  `isrepeat`)?** The forward project callback receives the
  held-key set and repeat flag (§5.4); whether the bottom
  input sink should also receive them uniformly (e.g. to handle
  Shift+Enter at one place) is flagged **not yet settled** in
  the companion doc, to be resolved in the 0.1.0-m4/m5 design
  session. (Source:
  [user_input.md](../../../internals/user_input.md) — "Key
  state" section.)
- **Is `app_state == 'starting'` ever observed by an input
  path?** The inventory flags this **UNCERTAIN**: by the time
  any event arrives, the state is already `ready` or later, so
  no contract is asserted for `starting`. Recorded so the
  rewrite does not assume one exists. (_inv §2, §Coverage_.)

---

_Items carried as UNCERTAIN from the inventory and left
unasserted here: (a) `starting` reachability by an input path
(above); (b) that `combo_string`/`keys_pressed` have zero
current `src/` callers — taken as a strong negative from
exhaustive grep, surfaced in §4.2 rather than asserted as a
contract._
