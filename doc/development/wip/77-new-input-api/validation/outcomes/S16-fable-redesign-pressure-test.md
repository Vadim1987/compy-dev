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

> **CORRECTION (iteration 1, owner ⇄ Fable, same day):** F3 overstated the collision's
> blast radius. `editorController.lua:493` is a **SearchController**, not a UIC — its
> `jump`-table return is a different class's own contract, unaffected. The **only live
> consumer** of `UIC:keypressed`'s return is console history navigation
> (`consoleController.lua:1209-1217`); editor input (`editorController.lua:804`) and
> the editor-input forward (`controller.lua:44`) already ignore it. See the
> iteration-1 section below for the owner's superseding resolution.

1. Escape on shown widget with default config → content cleared **and hidden**
   (kills the F1 regression — the single highest-value test);
2. Ctrl+Q reaches the gateway with a shown widget and a greedy project handler
   installed (pins F2/F4's escape hatch);
3. hidden widget + unhandled key → chain returns non-consumed; shown widget +
   plain key → consumed, and console/editor limit-flag callers still see their
   flag (pins F3);
4. hook nil-ing after explicit assignment behaves per the F5 choice.

---

## Iteration 1 (owner ⇄ Fable, 2026-07-20) — owner refinements + Fable verification

### F2 refined — CONFIRMED: tier-1 was invented solely for Enter/Esc-in-route

Owner's reading verified in code: `install_tier1` (`projectInputController.lua:119-123`)
populates exactly `kp['return']` and `kp['escape']`, once, at construction; nothing else
ever writes `framework_handlers`. With the gateway pre-tap handling recovery
unconditionally *before* routing, tier-1 has no other purpose — the reshape removes it
and its tests outright. Owner's shape: `compy.input.callbacks` = **direct exposure of
the widget instance's callbacks table, pre-populated with framework defaults** (e.g.
after_cancel default performs the dismissal); projects control the lifecycle through
callbacks only, never reaching the controller/model. Fable caveats accepted into the
obligations:
- **(a) D11 teardown must RE-SEED defaults, not wipe to nil** — `reset_compy_input`
  currently wipes surface state; a nil'd after_cancel would silently lose dismissal.
- **(b)** "5 callbacks" — the lifecycle five; `on_limit_reached`/`validator`/
  `highlighter` (writable today) still need their F6 membership ruling (8 leaves, or a
  deliberate narrowing).
- **(c)** The dropped guarantee widens slightly: not only can a project handler shadow
  Enter/Esc (F4), a project overriding `after_submit`/`after_cancel` now *owns* the
  lifecycle act itself (keep-open becomes "don't hide" instead of "re-show") — same
  named ruling, stated fully.

### F1 refined — pre-feature canon verified in `devupstream`

`devupstream:src/controller/userInputController.lua:153-154` — pre-feature
`UIC:cancel()` is `model:cancel()` **only** (model = `handle(false)` + `reset`,
`userInputModel.lua:795-798`). **No hide existed anywhere: clear-only IS the
pre-feature canon, and that was precisely the recorded limitation.** The `+hide()` in
today's `UIC:cancel()` is feature #77's addition (the D6 fix), currently reachable only
through tier-1. So neither current shape is "the old canonical dismiss" — dismissal has
no pre-feature precedent and must be preserved deliberately.

Owner's proposed sequence — `keypressed('esc') → callbacks.before_cancel() →
input:cancel() (clear) → callbacks.after_cancel()` with the default after_cancel
performing dismissal — **matches Fable's interpretation**, with one correction:
- the default `after_cancel` should be **hide/dismiss only**, NOT `UIC:cancel()` —
  the middle step already cleared; calling `UIC:cancel()` there re-runs
  `model:cancel()` (double `handle(false)` + `reset`, observable via history/error
  state) and muddles the before→middle→after reading.
- ordering is right for §4's capture-and-restore: before_cancel fires **before** the
  clear, so the context can capture text; hardwired middle = clear; overridable
  after = dismiss-by-default. Submit mirrors it: before_submit → validate → deliver
  (`on_text_entered`) → after_submit (default: hide; reject path still skips after,
  as today).

### F3 refined — owner's redefinition SUPERSEDES Fable's F3(a); verified cleaner

Owner: let the widget's return **universally mean consumed**; the limit signal moves
to `on_limit_reached` (already exists as a D5 widget output — the return flag was a
*parallel* channel all along). Verified consequences:
- The dual channel is redundant today: `vertical()` **both** sets the returned flag
  **and** fires `emit_limit` (`userInputController.lua:572-581`). Retiring the return
  channel is a deletion, not a migration.
- **This is D5-purifying:** the limit *result* was leaking upward through a return
  value — the exact thing D5 forbids for results. After the change, results travel
  only via widget outputs; the return carries the consumption signal (a chain concern,
  not a result). D5's supersede-entry writes itself.
- Blast radius (verified, post-correction): **console history nav only**
  (`consoleController.lua:1209-1217`). Tweak: configure the console instance's
  `on_limit_reached = function(dir) …history_back/fwd… end`, filtered to vertical
  dirs (emit_limit also fires left/right). Synchronous (fires during keypressed) —
  same-keystroke semantics preserved.
- Per-surface: **editor input strip** — return already ignored, no tweak;
  **editor search** — SearchController, own class/contract, unaffected (its own
  jump-via-return is the same *pattern*, optional later cleanup, out of scope);
  **inspect mode** — D12: console route over project env, same console instance →
  covered by the console tweak automatically; **project route** — widget returns
  shown→truthy / hidden→falsy, enabling the uniform OR-chain dispatch the owner's
  in-code REVIEW (`projectInputController.lua:197`) already asks for.
- One rule to pin in the delta-spec: **shown → consumed for EVERY key** (even keys
  the widget did nothing with), matching today's terminal-sink semantics; "true only
  when it acted" would invite per-branch bookkeeping and observable flakiness.

### Obligations delta after iteration 1

Obligation (3) is superseded: consumption = **widget return value** (owner's rule),
not shownness-at-dispatch-step; D5 amended as above. New sub-obligations: teardown
re-seeding (F2-a), default-after_cancel = dismiss-only (F1), the widened F4 wording
(F2-c), and the console `on_limit_reached` tweak rides in the same execution unit as
the return-channel retirement.

---

## Iteration 2 (owner clarifying round, 2026-07-20) — Q&A, code-verified

Owner posed numbered sub-questions (1.a–6.b) against the five obligations; answers
verified in code/design docs, not asserted from memory. Full detail in chat; key
verified facts recorded here for the record:

- **1.a/1.b** — gateway pre-tap confirmed pre-feature too (`devupstream:src/
  controller/controller.lua:528-622`, same shape); today at `controller.lua:862`
  (`setup_callback_handlers`) / `:874` (`handlers.keypressed` gateway). Shortcuts run
  unconditionally before route forwarding; their own bodies read `app_state` for
  their own branching, which is not a routing gate.
- **2.a** — approved: extend Decision 6's already-reserved `before_submit` veto
  convention to `before_cancel` symmetrically; no new mechanism.
- **2.b** — owner proposes flipping the shared auto-close default to OFF (stay
  open unless `after_submit`/`after_cancel` explicitly hides), mirroring the
  pre-feature `oneshot` flag verified in `devupstream:src/model/input/
  userInputModel.lua` (`oneshot=false` REPL/editor stayed open; `oneshot=true`
  project overlay auto-closed; deleted outright by #77, replaced with a hardcoded
  unconditional hide in `UIC:submit()`). Feasible and zero-cost to console: console
  never calls `UIC:submit()`/`cancel()` (has its own `evaluate_input()`), so the
  flip only changes the project widget's behaviour. Folded into obligation 2.
- **3.a** — confirmed: exactly one function patched, `ConsoleController:keypressed`
  around `consoleController.lua:1209`.
- **4.a** — verified NOT stakeholder-mandated: `design/requirements.md:201-205`
  records the cancel/dismiss notification as explicitly **unresolved** by
  stakeholders ("to be confirmed"); the non-overridable framework-tier shape was a
  design-team fix (`design/notes/enter_escape_routing.md:10-58`) for a
  self-inflicted structural problem (`oneshot` two-role widget, no shared dispatch
  layer) — not an external ask. Withdrawing it contradicts no stakeholder ruling.
- **6.a/6.b** — confirmed via a pass over every obligation against console/editor
  code: only obligation 3's console patch touches them; items 1/2/5 are scoped to
  the project widget / `compy.input` surface, which console/editor never call into.
  The Decision-1 "console/editor migration deliberately deferred" consequence is
  undisturbed.

### New finding (owner's final question): migratability of console/editor onto
### handlers/hooks/callbacks — YES, and the redesign fixes a broken promise

Owner's framing: original requirement was "API should make migration of console/
editor possible without forcing it now." Verified this was explicit design intent —
`design/roadmap.md:330` (M5c spec): "the shared `dispatch()` function is written and
used by ProjectInputController… ConsoleController and EditorController will migrate
to it later"; `design/status.md:126` names console/editor migration as "the
designated venue for the next round" (Gate-2 closing ruling), a scheduled venue, not
a forced task; Decision 6's consequence text (`decisions/input.md:183-185`)
anticipates it minting its own middle-step policy.

**But the shipped code does not deliver on "shared":** `ProjectInputController:
_dispatch` (`projectInputController.lua:198-207`) is a PIC **method**, reading
`self.compy_input`, `self.framework_handlers`, `self.natives` — entirely
project-sandbox-specific state. It is not callable by console/editor today despite
the roadmap's stated intent; the "later migration" promise is currently aspirational,
not actually enabled.

**The redesign is an opportunity to actually deliver it, and arguably makes it
easier than today's shape**, for two reasons: (1) obligation 2's default-flip (stay
open unless a callback hides) means console/editor's eventual migration inherits the
correct behaviour for free — no override needed, whereas under today's hardcoded
auto-close, migrating onto `UIC:submit()` as-is would immediately break their
required "stay open" behaviour; (2) the `handlers`/`hooks` tables and the guarded
`compy.input` metatable (D7) are conflated today — console/editor don't need the
project-facing sandboxed-guard ceremony, only the plain 3-step mechanism.

**Recommendation for the delta-spec / Phase E:** extract the chain as a genuinely
shared function — `dispatch(handlers, hooks, widget, event, trigger, ...)` — taking
plain tables/instance, not reading PIC's `self.*`. `compy.input`'s guarded surface
becomes a thin project-facing wrapper *over* that shared function, not the function
itself. This costs nothing extra now (PIC still calls it with its own tables) and is
what actually keeps the "possible, not forced" promise honest for whenever console/
editor migration is picked up. Added as an implementation obligation, not a new
phase — folds into Phase E's existing execution units (E-r1/E-r2).
