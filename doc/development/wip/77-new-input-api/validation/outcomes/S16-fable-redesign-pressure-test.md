# Fable pressure-test — input-API redesign proposal (S16, 2026-07-20)

Commission: `validation/prompts/S16-fable-redesign-pressure-test.md`. Subject:
[`../notes/input-api-redesign-proposal.md`](../notes/input-api-redesign-proposal.md) +
[`../notes/input-api-redesign-evaluation.md`](../notes/input-api-redesign-evaluation.md).
Every code citation below was read this session; line numbers are at HEAD `25b0475`.

**Overall verdict: SOUND and worth doing pre-PR — under one specific reading of the
propagation story (finding F2), with five delta-spec obligations that must be written
down before any code moves.** The 9-keep / 1-re-home / 3-supersede map is accurate
with the amendments below. The evaluation's risk list was right in direction;
the code adds three concrete facts it didn't have.

---

## F1. The D6 layering seam — the safety condition HOLDS, and the code already
## contains the counterexample proving why it must be stated

The proposal's §4 claim ("widget owns Enter/Esc" = the *controller* owns
detect-and-propagate; the parent context owns lifecycle) is correct, and it is not a
nicety — the shipped tree contains **both cancel shapes side by side**:

- `UserInputController:cancel()` (`userInputController.lua:179-182`) =
  `model:cancel()` **+ `hide()`** — genuine dismissal. Today only the PIC tier-1
  escape entry calls it (`projectInputController.lua:100-110`).
- The sink's own escape branch (`userInputController.lua:678-682`, fired from the
  non-editor arm at `:719`) calls **`input:cancel()` — the model's cancel, clear-only,
  no hide**. That is the *exact* shape of the original "Escape cleared content but
  could not dismiss" bug, surviving intentionally as console/editor local behaviour.

**Consequence:** if tier-1 is dissolved and Enter/Esc simply "fall through to the
widget" via the *existing sink editing path*, the default Escape lands on the
model-level cancel → the old bug returns, precisely as the evaluation feared. The
reshape is safe iff the widget's *default* Enter/Esc handling is defined as the UIC
**methods** `submit()` / `cancel()` (validate→deliver→hide / clear→hide), invoked as a
first-class default handler in the widget's chain entry — never the sink's current
editing-branch locals.

Two further precisions for the delta-spec:

- **D6's "route policy, not widget nature" insight survives** — as *per-adopter
  middle-step configuration*. Verified: the console route's submit today is not in
  UIC at all — `consoleController.lua:1218-1220` handles Enter itself and calls
  `evaluate_input()`. So "widget default submit" must mean: each adopting instance is
  configured with its middle step (project overlay: validate→deliver→hide; console
  REPL instance, at future convergence: evaluate→keep-shown). The widget carries the
  *shape*; the adopter supplies the *policy*. Losing this would make console/editor
  convergence impossible without re-forking.
- **UIC must not gain context-awareness.** The owner's own REVIEW notes
  (`userInputController.lua:430-434, 698`) already flag `_is_hidden_overlay`'s
  `love.state` peeking and the `app_state == 'editor'` branch as encapsulation leaks.
  The reshape should *remove* branching-by-global (config at show/activate instead),
  not add "which context am I in" knowledge. See F3 for how the hidden-check moves.

## F2. The propagation engine — the proposal's load-bearer does not match the shipped
## topology; adopt the modest reading and say so explicitly

Proposal §2: "if the widget is not shown, it does not consume — the key propagates to
the **parent controller's dispatch**, which is what re-routes to console or triggers
global exit." Verified facts:

- **There is no parent dispatch.** While running, `love.keypressed` *is* the project
  route (`controller.lua:239-241`); `_dispatch`'s return goes back to LÖVE and is
  discarded. A non-consumed event dies at the sink.
- **Global exit / back-to-console is a gateway PRE-tap, not a fallback.** The power
  shortcuts (Ctrl+Q quit, Ctrl+Pause break, Ctrl+S stop, Ctrl+Shift+R reset — with the
  in-code comment "Ensure the user can get back to the console") live in
  `love.handlers.keypressed` (`controller.lua:874-984`) and run **unconditionally
  before** the route dispatch. No route participant can shadow them.
- **Non-consume-when-hidden already exists** — at tier-1: `shown_widget()`
  (`projectInputController.lua:71-74`) makes the return/escape entries return false
  when hidden, so Enter/Esc already fall through to project handlers → tier-3 → sink
  no-op today.

Two readings of "propagates to the parent":

- **(i) Modest (ADOPT THIS):** "propagation" = the mode-based routing that already
  exists (D1 route selection + D11 connect-while-running: when the project route is
  not connected, the console route holds the slots). Nothing new is built; the actual
  change is *relocating Enter/Esc detection from PIC tier-1 to the widget's default* —
  cheap and bounded. The "reserved keys become emergent" story stays true *within the
  route*.
- **(ii) Strong:** per-event bubbling to a real parent dispatcher. New machinery,
  explicitly out of today's topology — and if global-exit were ever moved from pre-tap
  to bubble-fallback, a project handler returning truthy on Ctrl+Q would shadow the
  user's escape hatch: a **safety regression** against a deliberate guarantee.

**Obligation:** the delta-spec must state reading (i) and that the gateway pre-tap is
retained, out of chain and out of scope. (Vocabulary bonus: the pre-tap keys are
exactly the proposal's "framework/global shortcut" row — name them *global shortcuts*,
gateway-owned, out-of-chain. That completes the story: the chain has no framework
tier; the gateway keeps global shortcuts.)

## F3. Consumption signal — "widget consumes when shown" must be decided by
## SHOWNNESS, not by the widget's return value (new finding)

For the 3-component chain, "widget consumes when shown" must be a chain-visible fact.
But today `_sink` **discards** the widget's return (`projectInputController.lua:181-184`,
per D5 "the sink's return carries no chain meaning") — and that return slot is
**already occupied with a different meaning elsewhere**: `UIC:keypressed` returns the
vertical-limit flag (`userInputController.lua:723`), consumed by the console route
(`consoleController.lua:1209` `local limit = input:keypressed(k)`) and editor search
(`editorController.lua:493`). Overloading it as "consumed" collides with live callers.

**Resolution (recommend a):** (a) the *dispatch step* decides: if the widget is shown,
invoke it and consume (`return true`); if hidden, skip and fall through. Consumption
derives from shownness, the widget's return keeps carrying no chain meaning — D5's
ratified sentence stays literally true, zero UIC signature churn. (b — rejected) a
separate chain-entry wrapper returning consumed: more surface for no gain.

Note this **relocates D2's "internal hidden-check" to the chain step**. That is safe
w.r.t. Decision 1: the old bug was the *gateway* gating the whole route on widget
presence (keyboard lockout); a shown-check at the route's **terminal** step gates only
the widget's own participation — routing has already happened, tiers 1–2 fire
regardless. Semantically identical to today's internal no-op, and it lets UIC drop
`_is_hidden_overlay`'s global-peeking (the owner's REVIEW `:430-434, 480-483` asks for
exactly this — an internal flag / dispatch-level check). D2's supersede entry must
amend this clause explicitly.

## F4. The dropped D6 guarantee is a real trade — record it as a named ruling

Today Enter/Esc are non-overridable while shown ("Enter always submits… no project
participant can shadow them", D6). Under the proposal a project handler **wins**:
`handlers.keypressed['return'] = function() return true end` suppresses submit while
the widget is shown — user types, hits Enter, nothing happens. That is now *possible
by design* (DOM-uniformity; project freedom). Acceptable **only because** the gateway
pre-tap (F2) remains the guaranteed recovery path. This is a genuine Phase-D-style
owner ruling to record, not a detail: "uniform chain + project freedom outrank
guaranteed submit/cancel semantics; the gateway stays the non-negotiable escape
hatch." (Today's edge — tier-1 consumes Enter even on validator-reject — is preserved
trivially under F3(a): shown → consumed.)

## F5. D10 unification — the seed semantics must be CHOSEN, they don't fall out

Today natives live on PIC (`self.natives`), are **never copied onto compy.input**
(deliberate — `projectInputController.lua:215`, "No handler is copied onto
compy.input"), and precedence is **re-resolved per event**
(`_generic_callback:160`: `ci[CHANNELS[event]] or self.natives[event]`). Observable
consequence: assign `on_key_pressed`, later nil it → the native *resumes*. D10's
"mutually exclusive by precedence, not by overwrite" is implemented literally.

Folding both into one `hooks[event]` slot forces a choice:

- **(a) two stores + per-event resolution** (today's shape renamed): semantics
  preserved exactly, but `hooks[event]` reads nil while a seed is active — the table
  is not the whole truth (mild asymmetry, confusing introspection).
- **(b) seed-by-copy at activation** (only if the slot is empty — timing works:
  `occupy_keyboard` runs after the project's `main.lua`, so explicit assignments from
  top-level code are already in place): the table **is** the whole truth, introspectable;
  but nil-ing a hook no longer resurrects the native (precedence became overwrite —
  a semantic change to D10's letter).

**Lean: (b)** — "one table, one truth" is the more predictable contract, and
fallback-on-nil is an exotic edge nobody asked for. But it must be recorded as an
amendment to D10's precedence wording, not discovered later. "Read native once at
activation" survives either way; D11 teardown already wipes per-run state.

## F6. Loosened D7 — coherent, SIMPLER than today, but only BECAUSE of the
## restructure; and the callbacks table is currently incomplete

Verified today's guard: `compy.input` is an empty proxy; `__newindex` allows exactly
the 11 enumerated `INPUT_CALLBACKS` keys (`consoleController.lua:380-422`), errors on
everything else. The proposal's "freeze the container, keys writable" works **iff**
every writable leaf moves into the three sub-tables — then the rule is one line:
*compy.input's direct fields are all frozen (methods + the three sub-table
identities); sub-table leaves are writable* (`handlers.<event>[combo]`,
`hooks[<event>]`, `callbacks.<name>`). The guard implementation *shrinks* (refuse all
container writes; no allowlist). Two obligations:

- **Frozen set must include event-level identities.** `handlers.keypressed` is a
  *normalising* table (`Key.new_handler_table`); allowing
  `handlers.keypressed = {}` would silently drop combo normalisation. Writable =
  leaves only; identities at every level are frozen. (This answers the evaluation's
  "clarify the exact frozen set.")
- **The callbacks table omits `on_limit_reached`, `validator`, `highlighter`** — all
  three writable today (D5/D7). `on_limit_reached` fits "fired by a trigger";
  validator/highlighter do not (they are gates/transforms, not notifications).
  Recommend: admit all three to `callbacks.*` and phrase the taxonomy rule as
  **callback = a function the widget invokes** (validator is invoked at submit,
  highlighter at render) — one table, one rule, no fourth vocabulary word. The
  legacy direct-field ergonomics (`compy.input.on_text_entered = fn`) should NOT
  survive alongside (clean break, pre-1.0, same precedent as D4's no-shim ruling).

## F7. Vocabulary — consistent after F6's amendment; two residuals

- **"widget" is overloaded in-tree:** `UserInputController` has at least two live
  instances — the published project overlay singleton and the console REPL's own input
  (`userInputController.lua:442-444`). The glossary entry must distinguish the widget
  *class/role* from **the** project widget (the one published instance the project
  chain terminates in). Cheap, but skipping it re-imports the singleton/sink/widget
  ambiguity the rename exists to kill.
- **"hook" migration hazard:** today's code and D6 prose call before/after_submit/
  cancel "hooks" (`run_hook`, decisions text). The new taxonomy correctly reclassifies
  them as **callbacks** (widget-invoked), and `hooks` comes to mean the chain-injected
  tier. The rename sweep must be complete — a half-migrated tree where "hook" means
  both is worse than either endpoint. Grep-backstopped sweep, per charter.
- `proxy` → "read-only pressed-keys view": fine; D13 substance untouched.
- `routing` unchanged: correct.

---

## Verdict summary + the five delta-spec obligations

The reshape holds together. It is *more* than a rename (three ratified decisions
amended), *less* than a redesign (no topology change under F2 reading (i); the
propagation story is today's routing, restated). The decision-map amendments:

| decision | proposal says | amend to |
|---|---|---|
| D2 | supersede: 3 components | + relocate the hidden-check to the chain step (F3) |
| D5 | keep | keep — true only via F3(a): consumption = shownness, widget return stays meaningless to the chain |
| D6 | resolve via layering | + widget default = UIC `submit()`/`cancel()` methods, never model-level ops (F1); + middle step stays per-adopter config (F1); + the dropped no-shadow guarantee is a named ruling (F4) |
| D7 | loosen | + frozen set = all identities, writable = leaves only; + callbacks absorbs on_limit_reached/validator/highlighter, definition "widget-invoked" (F6) |
| D10 | unify | + choose seed semantics explicitly; lean seed-by-copy-at-activation, recorded as a precedence-wording change (F5) |

Obligations before code moves: **(1)** F2 reading (i) + gateway pre-tap retention
stated; **(2)** F1's two layering precisions; **(3)** F3(a) consumption rule;
**(4)** F4 recorded as an owner ruling; **(5)** F5 seed choice + F6 frozen-set/
callbacks-membership spelled out. All five belong in the delta-spec (addendum to
`decisions/input.md`; frozen `design/` untouched).

**Tests-first anchors** (the breaking tests that pin the risky seams):
1. Escape on shown widget with default config → content cleared **and hidden**
   (kills the F1 regression — the single highest-value test);
2. Ctrl+Q reaches the gateway with a shown widget and a greedy project handler
   installed (pins F2/F4's escape hatch);
3. hidden widget + unhandled key → chain returns non-consumed; shown widget +
   plain key → consumed, and console/editor limit-flag callers still see their
   flag (pins F3);
4. hook nil-ing after explicit assignment behaves per the F5 choice.
