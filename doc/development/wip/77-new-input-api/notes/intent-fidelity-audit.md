---
description: Intent-fidelity audit (prompt11) — does the derived #77 chain faithfully
  encode stakeholder intent, or has interpretation drifted? Independent cold pass.
status: active
audience: design / owner
---
# Feature #77 — Intent-fidelity audit

An independent, cold reading of the stakeholder sources, used to check whether the
derived design / contract chain encodes what the stakeholders asked for or whether
interpretation has drifted into encoding today's implementation mechanism.

Method note (integrity): Phase 1 below was written to disk in full **before** any
tier-4 derived document (`requirements.md`, `design.md`, `spec.md`, `spec/`,
`input-contracts.md`, `input-routing-model.md`) was read. It is not edited after the
fact. Phase 1 draws only on the tier-1/2/3 stakeholder sources plus the
`design/notes/decisions.md` dialogue — the latter read **solely** to contextualise
the tier-2 review (the owner confirmed it is the document stakeholder 2 was reacting
to), with the stakeholders' wants extracted, not the design's claims.

Sources read for Phase 1:
- Tier 1 (ground truth): `design/notes/input.md` — ticket, owner clarification, and
  feedback round 1.
- Tier 2 (architecture review): `design/notes/input/stakeholder2_notes.md` +
  `stakeholder2_structured.md`.
- Tier 3 (supportive concerns): `notes/stakeholder-3-input/` —
  `compy-input-quirks.md` (the four pains), `compy-lua-game-patterns.md` (the codified
  workaround), and `assessment.md` (read for its raw pain evidence; its own verdicts
  are derived processing, weighted as such).
- Contextual only: `design/notes/decisions.md` (the artifact under tier-2 review),
  including the owner/architect's proto-design sketch in D-3.

---

## Phase 1 — recorded intent model (written blind, never edited)

### 1.1 What the input API is meant to do for a project author

The problem, in the owner's own framing (tier 1): the current input API is
*inconsistent with the rest of LÖVE*, *handling keyboard events in parallel to
editing is a PITA*, and it is *not easy to hide or show the input area*. The feature
exists to remove those three frictions.

Positively, the owner wants an API that makes it *easy to build interfaces similar to
the command console or the editor* — ideally so that the console and editor could
themselves be re-implemented on it. The wording is *"allows for"* and *"ideally"*:
this is a capability/expressiveness target, **not** a commitment to migrate the
console or editor. The concrete surface the owner names:

- Set up an edit area with optional initial content, a syntax highlighter, and an
  input validator/verifier; receive callbacks when the user enters something.
- Callbacks for: Ctrl+key combinations; keys that do **not** insert or remove a symbol
  (navigation / control keys); the cursor *"hitting a wall"* (trying to move past the
  beginning or end of the edit area); and entering a line.
- Operations to: set up the edit area (initial text, cursor position, highlighter,
  verifier), remove the edit area, query and change the cursor position, and change
  the text.

The deeper intent visible across these: a project should be able to **drive a text
input and still see the keyboard in parallel** — modifier/command keys and non-text
keys reach project code while editing is going on. The pain being cured is precisely
that today the input area consumes the keyboard and the project is locked out of it.

### 1.2 The pivotal question — the widget's role in event dispatch

**Per stakeholder intent, the input widget is an operational surface, not a
dispatch-altering first-class entity. Events it does not itself handle are passed
through / observable in parallel — they are not swallowed.** The evidence:

- **Tier 1.** *"handling keyboard events in parallel to editing is a PITA"* — the
  stated goal is to make *parallel* handling easy. Parallel means the edit area does
  not monopolise the keyboard; the project sees key events alongside editing. The
  explicit asks for Ctrl-combo callbacks and non-text-key callbacks **while an edit
  area is up** only make sense if those events reach project code rather than being
  absorbed by the widget.
- **Tier 2 (D-3 / D-6).** The base approach is *"passing through what LÖVE does"*;
  modifier+character is *"two independent channels"* with *no exclusivity and no
  suppression*. The stakeholder later accepted a combo/handler/dispatch layer as a
  worthwhile *improvement* on bare pass-through — but as a layer over pass-through, not
  as a gate that swallows.
- **Owner proto-design (decisions.md D-3, the architect's own sketch, described as
  "the primary goal of the ticket").** A global `keys_pressed` table is updated on
  every `keypressed`/`keyreleased`; `love.keypressed/keyreleased/textinput` feed a
  single dispatch (`_on_key_pressed` etc.) that walks framework handlers → project
  handlers → a generic overridable callback whose **default is a noop with a debug
  log**. Nothing is swallowed; an unhandled event lands on an observable noop. Text
  editing is not a privileged gate in this sketch — at most it is a default behaviour
  the callback chain bottoms out in, overridable by the project.

So the widget "configures and collects"; the *active context* (project, and by
extension console/editor) drives it. The widget does not decide where events go.

On the swallowed-vs-passed-through sub-question the stakeholders are **explicit**, not
silent: pass through, two independent channels, no suppression (tier 2); unhandled
keys reach an observable default rather than disappearing (owner proto-design).

### 1.3 Mandated / preference / silent

**Mandated (tier 1, ground truth):**
- A new input API for building console-like / editor-like text interfaces;
  console/editor re-implementability is a *capability* target ("allows for",
  "ideally"), not a migration mandate.
- Edit-area setup with optional initial content, highlighter, and validator/verifier;
  submit/enter callbacks.
- Callbacks for Ctrl combos, for non-text keys, for cursor "hit a wall", for entering
  a line.
- Programmatic cursor query/set and text change; edit-area setup and removal.
- Keyboard events available **in parallel** with editing; easy hide/show of the input
  area.
- No backward compatibility (round 1, three-stakeholder consensus): the legacy
  text-input API is removed, not shimmed. Scope of breakage is *text fields only* —
  native keyboard handling is not to break ("won't break all keyboard input, only text
  fields").

**Mandated / high-weight (tier 2, architecture review):**
- Second `show()` while active is a no-op by default; an explicit `force` opt-in
  reconfigures. (Same point restated against the spec's `show()` line.)
- Base = pass through what LÖVE does; two independent channels (key, text); the
  combo/handler/dispatch layer is an accepted improvement, but no further convenience
  helpers in this effort.
- Dedicated named cancel/submit events, with a before/after structure around a
  framework-owned step the project cannot suppress.
- Cursor-boundary callback covering **both** vertical (up/down, first/last line) and
  horizontal (left/right, first/last char), at whole-input **or** line granularity.
- Scope is user code running in projects; the console run path is expected to converge
  on the project run path eventually (so project-first is the right staging, and it is
  also "project-only, for now").
- Naming: not `ProjectController`; an input controller should be `ProjectInputController`.
- Lifecycle: a persistent singleton widget is "very sensible."
- `keys_pressed` exposed as a read-only proxy that **allows read indexing** and blocks
  only writes (not iterator-only).

**Preference / evidence-of-need (tier 2 asides, tier 3):**
- `isrepeat` restored as the honest fresh-vs-repeat primitive (tier 3 P2; a regression
  to undo, not new scope).
- Combo dispatch as the sanctioned answer to "modifier chords emit no textinput" (tier
  3 P3).
- Real, corroborating pain that hand-rolling key-state and combo detection is the
  status quo the feature should dissolve (tier 3, the keyboard/maze examples).

**Silent — where the derived chain had to invent (mark, do not manufacture a
mandate):**
- The specific *internal routing topology* — a `ProjectInputController` sibling, a
  `UserInputController` "universal terminal sink", three controller branches sharing
  one dispatch. Stakeholders asked for callbacks/handlers and parallel key handling;
  the owner's own sketch was a **single global dispatch chain**, not a three-controller
  routing model. The three-controller "routing unification" is a derived mechanism.
- Combo-tier key-repeat semantics (fire-once-per-press vs fire-on-repeat at the
  handler tier). Tier 3 flags this as *the* open question; stakeholder voice is silent
  (a provisional human "leaning" exists but is marked provisional).
- Exact combo serialisation format (explicitly deferred to spec).
- Native-handler coexistence auto-provisioning (D-9) — a derived mechanism that
  *serves* the tier-1 "only text fields break" guarantee but was not itself asked for.
- The `compy.input.*` namespace (D-10) — a derived packaging choice.
- Whether `on_text_entered` carries the full key set vs a filtered `mods` subset; the
  `scope='line'` semantics in detail — beyond the broad endorsement, these are
  derived detail.

### 1.4 Conflicts and resolution by authority

The only live tension among the stakeholders is the round-1 backward-compatibility
exchange: stakeholder 3 worried about "going from an almost-good experience to not
having any, even temporarily." It is resolved **in the source itself** by authority —
stakeholders 1 and 2 (and ultimately 3's "okay, then it's less of a problem") reach
consensus to discard backward compatibility, on the narrowing facts that only text
fields break and old releases remain. Tier 3's pains corroborate need but do not
override the tier-1/2 ruling; the assessment that processes them explicitly parks the
heaviest one (P4 exit-hook / global-state leak) as a sibling concern outside this
feature's widget scope. No tier-1/2 conflict remains unresolved.

<!-- END PHASE 1 — recorded blind. Everything below was written after reading the
     tier-4 derived chain. -->

---

## Phase 2 — fidelity diff against the derived chain

Documents read for this phase: `requirements.md`, `design.md`, `spec.md`,
`spec/M4.md`, `notes/input-contracts.md`, `notes/input-routing-model.md`.

The single most important observation before the table: **the derived chain is not of
one mind about the widget.** The *design* documents (`design.md` §2, `spec.md` §6,
`spec/M4.md`) state a route-centric model in which the widget is the **sink** and
"routing does not change based on whether the singleton is visible … widget visibility
is a state on the singleton, not a gate." The *contract record* (`input-contracts.md`
§3/§4) still tabulates routing **keyed on widget presence** ("widget active → widget
only", EXCLUSIVE), i.e. the widget as a routing switch. The audit's suspicion — that
the contracts may encode today's mechanism rather than intent — lands squarely on
`input-contracts.md` §3/§4, not on the design docs. `input-routing-model.md` is a
prior-session note that already diagnosed exactly this split (its "Model A
widget-centric" vs "Model B route-centric").

### Material-claim classification

| # | Material claim (where) | Class | Trace to tier-1/2/3 (or silence) |
|---|---|---|---|
| 1 | Widget is the **sink**; visibility is a state, not a routing gate; the `if user_input then` overlay gate is removed (`design.md` §2; `spec.md` §6; `M4.md`) | **Faithful** | T1 "handling keyboard events **in parallel** to editing is a PITA" + the asks for Ctrl/non-text-key callbacks while editing; T2 D-3/D-6 "pass through what LÖVE does … no suppression"; owner proto-design (global dispatch, overridable default, nothing swallowed). The gate **is** the PITA being removed. |
| 2 | `input-contracts.md` §3.1–3.3: keyboard/text **EXCLUSIVE — "widget active → widget only"**, tagged `[stable-now]` / must-preserve | **Drift** | Contradicts T1 (parallel) and T2 ("no suppression"). This is today's `if user_input then` mechanism stated as the invariant. The record itself partially disavows it (the §3.1 **F-A caveat**: "read as exactly-one-consumer, **not** … preserve project-key-drop-under-widget"), but the table and the M4-0-03 suite still carry the widget-keyed form. |
| 3 | Three-level dispatch `framework_handlers → handlers → on_key_pressed` (`design.md` §4; `spec.md` §3) | **Faithful** | Direct reification of the owner proto-design in `decisions.md` D-3; T2 accepted the "combo / handlers / dispatch layer" as a worthwhile improvement over bare pass-through. |
| 4 | Two channels (key, text) fire **independently, no suppression**; `keys_pressed` read-only proxy, read-indexable, writes blocked (`spec.md` §1, §3) | **Faithful** | T2 D-6 "two independent channels … no exclusivity"; T2 note on the proxy ("permit read indexing, block only writes"). |
| 5 | `show()` no-op by default, `force` to override (`spec.md` §2, §7) | **Faithful** | T2 decision 2 (verbatim: block by default, flag for "I know what I'm doing"). |
| 6 | Named `before/after_submit · before/after_cancel`; framework owns the middle step, projects cannot suppress it (`spec.md` §3, §5) | **Faithful** | T2 D-4 "at first glance, definitely" + the before/after-teardown framing it confirmed. |
| 7 | `on_limit_reached(direction, scope)` — up/down/left/right × input/line (`spec.md` §4) | **Faithful** | T2 D-5: vertical **and** horizontal, "for the whole input or the line." |
| 8 | Persistent singleton, created once, never destroyed (`design.md` §3; NFR-1) | **Faithful** | T2 "the proposed lifecycle (persistent singleton widget) is very sensible." |
| 9 | Legacy text-input globals **removed**, no facades; break bounded to text fields (`spec.md` §5; `design.md` §6) | **Faithful** | T1 round-1 three-stakeholder consensus (D-1 discarded; "only text fields"). The chain correctly **dropped** the facade/reftable-compat path that an earlier `decisions.md` round had explored. |
| 10 | FR-11/FR-12 = **capability**, not a migration commitment (`requirements.md` §2.5; `design.md` §7) | **Faithful** | T1 wording "**allows for** … **ideally** … re-implemented." |
| 11 | **EXCLUSIVE (keyboard) vs BOTH (pointer)** stated as a durable invariant; "exactly one route per event" (`input-contracts.md` §2, §3.8) | **Invention** | Intent is **silent** on inter-route exclusivity. The owner's model is a single global dispatch chain, not a route-selection invariant. Reasonable as a derived design rule, but unmandated — and the word **"EXCLUSIVE"** collides with the stakeholder's own "**no exclusivity**" (which was about channels, a different axis). |
| 12 | Routing-unification **topology**: `ProjectInputController` sibling; `UserInputController` as "**universal terminal sink**" (`design.md` §2; `input-contracts.md` §2) | **Invention** | Intent never specifies an internal routing topology; the owner sketched one global chain. The three-controller shape is a derived mechanism, **consistent** with intent (the owner's chain folds into the project route's intra-route dispatch). The record already hedges "UIC universal sink" as a "recommended objective, not a present fact." |
| 13 | `on_key_pressed` / `on_text_entered` **default = the text-editing sink** (`design.md` §4; `spec.md` §3) | **Invention** | The owner proto-design's generic-callback default was **noop + debug log**, not the sink. Making the sink the default is a widget-specific specialisation — consistent with intent, but note the coupling it pins: overriding `on_key_pressed` silently disables `on_limit_reached`. |
| 14 | Native-handler coexistence (D-9) auto-provisioning, framed as a "**legacy** heuristic" (`spec.md` §6; `design.md` §2) | **Invention** (+ wording flag) | Serves the T1 "only text fields break" guarantee; not itself asked for. `input-routing-model.md` §5 flags the framing: a project setting its own `love.keypressed` is **legitimate, not legacy** — the contract is "no project handler set ⇒ default propagates to the active route's sink." |
| 15 | `inspect`-mode: console owns the input surface, project widget not honoured (`input-contracts.md` §3.4) | **Invention** (characterization) | Design-silent; the record correctly tags it **provisional, not preserve-forever**. Intent silent. No action beyond holding it provisional. |
| 16 | Combo-tier **key-repeat semantics** (fire-once-per-press at the handler tier) left open (`spec.md` carries `isrepeat` only to `on_key_pressed`; `input-contracts.md` §5.4) | **Invention — pending** | Intent **silent**. Flagged by tier-3 (`assessment.md`) as *the* one genuinely-open design question; a provisional human leaning exists but is marked provisional. Owner decision. |

### Adjudication of the pivotal question

**Does the derived chain treat the widget as a dispatch-altering first-class entity —
and if so, is that grounded in intent or an artifact of the implementation?**

The chain is split, and the split is the whole story:

- The **design** (`design.md` §2, `spec.md` §6, `M4.md`) does **not** treat the widget
  as dispatch-altering. It removes the widget-as-router gate and makes the widget the
  sink — an operational surface the active route drives. This is **grounded in intent**:
  the parallel-handling pain (T1), pass-through / no-suppression (T2 D-3/D-6), and the
  owner's own proto-design (`decisions.md` D-3) all describe a configurable collector
  with an overridable default, not a switch that reroutes by existing.

- The **contract record** (`input-contracts.md` §3/§4), and the M4-0-03 suite derived
  from it, **do** encode the widget as a dispatch-altering switch ("widget active →
  widget only"). That framing traces to **today's `if user_input then` gate**
  (`controller.lua`) — the implementation mechanism — **not** to any tier-1/2 line. It
  is the exact disease this feature exists to cure, mirrored one level up in the
  contract that is supposed to govern the cure.

The lines that settle it: T1 — *"handling keyboard events in parallel to editing is a
PITA"* (parallel access is the goal, so the widget must not monopolise the keyboard);
T2 D-3/D-6 — *"passing through what LÖVE does … two independent channels … no
exclusivity, no suppression."* Both place the widget on the operational side of the
line. The widget-as-router reading is **not** grounded in intent; it is an artifact of
the current implementation that leaked into the contract record at characterization
altitude and was inherited by the suite.

---

## Phase 3 — hypothesis verdicts

Tested against the **recorded Phase-1 reading** (not retrofitted to the hypotheses).

### Hypothesis A (owner's) — widget demoted to a purely operational collector that gathers input and invokes context-specific callbacks, without disrupting normal event flow and without swallowing events it does not know how to handle.

**Verdict: Supported.** This is, almost verbatim, the model Phase 1 derived from the
tier-1/2 sources and the owner's own proto-design. The collector-with-pluggable-
validators shape is the ticket itself (FR-1 highlighter/validator config; per-context
`configure()`). "Does not disrupt normal event flow / does not swallow what it does not
handle" is the direct reading of T2's *two independent channels, no suppression* and of
the proto-design, where an unhandled key lands on an observable default (noop + log),
never on a silent drop. No tier-1/2 line cuts against A.

### Hypothesis B (prior session's) — route-centric dispatch: every keyboard/text event reaches exactly one active route chosen by mode/context, never the widget by merely existing; the widget changes only intra-route handling, never inter-route dispatch.

**Verdict: Supported on its load-bearing claim; intent is silent on its strongest
formalisation.** B's core assertions — the widget never determines routing by merely
existing, and the widget changes only *intra-route* handling — are fully supported by
Phase 1 and are the same negative that A states. Where B goes beyond intent is the
positive invariant *"exactly one route per keyboard event, EXCLUSIVE, never two."* The
stakeholders never specify an inter-route dispatch topology or a one-route exclusivity
rule; the owner's model was a single global dispatch chain (which B legitimately
re-expresses as the project route's intra-route dispatch). So B is a **faithful
architectural reification** of intent's operational-widget stance, carrying one
**derived, unmandated** addition (the EXCLUSIVE-single-route invariant — see Phase-2
row 11). One terminology caution: B's "EXCLUSIVE" (route axis) and the stakeholder's
"no exclusivity" (channel axis) are the same word on different axes; they do not
conflict, but the collision invites misreading.

### The relationship between A, B, and the contract record

A and B **agree on the substance** — the widget is not a router; events are not
swallowed by widget existence — and both **contradict** the widget-centric model (Model
A) that `input-contracts.md` §3/§4 and the M4-0-03 suite encode. A is the more direct
match to stakeholder voice (it is the owner's proto-design restated); B is the same
stance cast as an internal routing invariant, plus one unmandated formalism. The audit
therefore does **not** return "the original widget-as-router reading was closer to
intent": it was not. The sources back the operational-widget reading.

---

## Bottom line

**Is the derived chain a faithful encoding of intent? Mostly yes — with one real
drift, already self-diagnosed, that still needs an owner ruling to close.**

The design layer (`requirements.md`, `design.md`, `spec.md`, `spec/M4.md`) faithfully
encodes what the sources asked for: a persistent, configurable input area with
callbacks instead of polling; key events available alongside editing; no backward
compatibility, bounded to text fields; the lifecycle, `force`-gate, named submit/cancel
chains, four-direction boundary hook, and read-indexable key proxy all trace cleanly to
tier-1/2. On the pivotal question, the design treats the widget as an operational sink,
which is the intended shape.

The drift is localised to the **contract record** and what was built on it. Items for an
owner decision, by severity:

**High — affects the architecture / the contract, not just wording:**

- **D-A (the central finding).** `input-contracts.md` §3/§4 record keyboard/text routing
  keyed on **widget presence** ("widget active → widget only", EXCLUSIVE) as a
  `[stable-now]` **preserve** contract, and the M4-0-03 suite materialised that as
  preserve rows. This encodes today's `if user_input then` mechanism as the invariant —
  the opposite of the route-centric model the design states and the sources intend.
  Left unamended, it would red-light the correct M4 gate removal. The fix is already
  drafted in `input-routing-model.md` §6 (re-state EXCLUSIVE on the **active route by
  mode/context**, demote widget-presence to a characterization, re-bucket the affected
  suite rows, add provenance to each surviving PRESERVE row). What is needed from the
  owner is the **ruling to amend the record**, not new analysis. *(Note: §2 vocabulary
  was already reframed route-centric in s27 and §3.1 carries a disavowing caveat — the
  vocabulary converged; the §3/§4 tables and the suite did not.)*

**Medium — a derived choice presented with more authority than intent grants:**

- **D-B.** The **EXCLUSIVE-keyboard / BOTH-pointer** invariant (`input-contracts.md` §2,
  §3.8) is a reasonable derived design rule, but intent is silent on inter-route
  exclusivity. Hold it as a **proposal**, confirm it is wanted, and disambiguate the
  term "EXCLUSIVE" from the stakeholder's "no exclusivity" (channels) to prevent the two
  senses being read as one.
- **D-C.** **Combo-tier key-repeat semantics** (do `handlers[combo]` /
  `framework_handlers` fire on every repeat or only fresh presses?) are genuinely open;
  intent is silent and tier-3 flagged it as the one substantive open question. Needs the
  owner's call (the provisional "fresh-only at the handler tier, `on_key_pressed` sees
  repeats" leaning is recorded but not ruled).

**Low — wording / altitude:**

- **D-D.** The D-9 native-coexistence path is framed as a "**legacy** heuristic"; a
  project that sets its own `love.keypressed` is legitimate, not legacy
  (`input-routing-model.md` §5). Reframe the contract as "no project handler set ⇒
  default propagates to the active route's sink." No behaviour change.
- **D-E.** Note the pinned coupling that overriding `on_key_pressed` disables
  `on_limit_reached` (the sink is the channel's default value). The spec records it; flag
  it for the owner as a deliberate-or-not call. The "universal terminal sink" objective
  for console/editor is already correctly hedged as an objective, not a present fact —
  keep it hedged.

Net: this audit **confirms** the doubt that prompted it for the contract record, and
**clears** the design layer. The remediation for the one high-severity item is already
written down (`input-routing-model.md`); the audit's contribution is to certify, from
the stakeholder sources directly, that the route-centric / operational-widget reading is
the one intent supports — the widget-as-router framing in §3/§4 is the part that drifted.

<!-- Findings only; no chain edits proposed. Remediation is the owner's call. -->

