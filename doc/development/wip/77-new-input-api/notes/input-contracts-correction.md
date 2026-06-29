---
description: Provenance ledger for the prompt12 correction of the
  input contract record + bucket spec — the row-by-row trace of
  every PRESERVE / CHARACTERIZE-PROVISIONAL decision, what changed
  framing, what did not, and the open rulings left provisional.
status: active — STOP for owner blessing
audience: design / owner
---
# Input contracts — correction ledger (prompt12)

A cold, unbiased correction of the interpretation drift the
intent-fidelity audit (`notes/intent-fidelity-audit.md`)
localized to the **contract record** (`notes/input-contracts.md`
§2/§3/§4) and the **bucket spec**
(`design/spec/M4-0-03-contract-suite.md`). The design layer was
found faithful and is **untouched**.

Two things had been tabulated as `[stable-now]` PRESERVE
invariants that are in fact **today's implementation mechanism**:
(1) keyboard/text routing keyed on **widget presence** ("widget
active → widget only") — the `if get_user_input() then …` overlay
gate; (2) pointer routing as inter-route **BOTH** — an artifact
of the mouse path lacking the gate the keyboard path has. Both
encoded the mechanism as the invariant — the exact disease #77
exists to cure, leaked into the contract meant to govern the cure.

## The principle corrected toward, and its provenance

> **Inter-route dispatch is EXCLUSIVE for every event type
> (keyboard, text, pointer): every event reaches exactly one
> route — the active one, fixed by the exclusive screen mode.**
> The widget is an operational surface the active route drives;
> it never determines routing by merely existing. The only
> legitimate "both" is **intra-route** (a route delivering one
> event to its own logic *and* to a surface it activated — the
> "parallel handling" tier-1 asks for); intra-route handling is
> invisible to the routing contract.

**Provenance (recorded honestly):** this is a **ratified design
rule**, not a stakeholder mandate. Intent is *silent* on
inter-route topology per se. The rule **derives** from
mode-exclusivity (a real system property) + the architect-ratified
three-controller topology (Console / Editor / ProjectInput-
Controller), endorsed via `design/notes/decisions.md`. Stated as
design authority, never as something a stakeholder demanded.

## The provenance gate (applied to every routing/dispatch row)

- **PRESERVE** — only if it traces to a tier-1/2 mandate (cited)
  **or** to the ratified principle above.
- **CHARACTERIZE-PROVISIONAL** — observed current behaviour with
  no mandate; "expected to change, no stakeholder mandate."

A row with neither a mandate nor the principle may **not** be
PRESERVE. The absence of this gate is what let the drift in.

## Row-by-row trace

| Corrected claim (where) | Tag | Provenance |
|---|---|---|
| keypressed reaches exactly one route, the active one (§3.1) | PRESERVE | ratified principle (§2) + tier-1 "only text fields break; native keyboard handling must keep working," stated at route level |
| textinput reaches exactly one route, the active one (§3.2) | PRESERVE | ratified principle (§2); same tier-1 mandate |
| keyreleased reaches exactly one route, the active one (§3.3) | PRESERVE | ratified principle (§2) |
| "widget up → widget consumes, project sink bypassed" (§3.1–3.3 notes) | CHARACTERIZE-PROVISIONAL | today's overlay gate; no mandate — the drift itself; the limitation #77 fixes |
| keyreleased dropped under a widget today (§3.3 note) | CHARACTERIZE-PROVISIONAL | today's mechanism; possibly a defect, not a guarantee; provisional |
| mouse pressed/released/moved reaches the active route (§3.5) | PRESERVE | ratified principle (§2) |
| pointer reaches "BOTH route and widget" inter-route (former §3.5 table) | **removed** | today's mechanism (un-gated mouse path) promoted to invariant; no mandate, no principle — fails the gate |
| touch pressed/released/moved reaches the active route (§3.6) | PRESERVE | ratified principle (§2) |
| intra-route forwarding to a widget (parallel handling) (§2, §3.5/3.8) | not a dispatch contract | tier-1 "parallel handling" — but it is intra-route, invisible to inter-route dispatch |
| wheelmoved reaches the active route (§3.7) | PRESERVE (route axis) | ratified principle (§2) |
| wheel "never the widget" / no-op default (§3.7) | CHARACTERIZE-PROVISIONAL | mechanism by omission (no gateway wheel entry); intended pass-through (R1) is provisional |
| `inspect`: console owns the surface, project widget not honoured (§3.4) | CHARACTERIZE-PROVISIONAL · OWNER RULING PENDING | design-silent; provisional/silent |
| global shortcuts non-consuming (§4.3) | PRESERVE (carried as-is) | observed + recorded; the key still reaches its active route — open whether mandated vs incidental (§7 of model note) |
| native-handler coexistence: "no project handler set ⇒ default propagates to the active route's sink" (§5.3, D-D) | forward / 0.1.0-m4 | reframed from "legacy" — a project setting its own `love.keypressed` is legitimate; serves tier-1 "only text fields break" |
| sink-as-default coupling: overriding `on_key_pressed` disables `on_limit_reached` (§6, D-E) | flagged, not asserted | derived coupling (`design.md §4`); owner deliberate-or-not call |
| combo-tier key-repeat semantics (§6, D-C) | OWNER RULING PENDING | intent silent; tier-3's one open question; provisional leaning recorded, not ruled |

## Rows whose bucket / framing changed

In **`input-contracts.md`**:
- §2 invariant — from "one route per **keyboard/text** event" +
  "pointer/wheel are exceptions" → **single inter-route
  exclusivity for every event type**, grounded in
  mode-exclusivity; added the EXCLUSIVE-vs-"no exclusivity"
  axis disambiguation (D-B).
- §2(B) widget paragraph — "widget takes its route's keys/text;
  pointer reaches both" → demoted to **intra-route handling**;
  widget-presence framing labelled today's mechanism.
- §3 notation — removed the inter-route BOTH definition; added
  the per-row provenance gate.
- §3.1/3.2/3.3 — re-founded EXCLUSIVE on the **active route**;
  widget-presence drop demoted to a CHARACTERIZE-PROVISIONAL note
  (D-A, the central fix).
- §3.5/3.6 — **BOTH tables removed**; collapsed to active-route
  delivery + intra-route forwarding as the route's concern.
- §3.7 wheel — "reaches the route, never the widget" → active-route
  delivery; widget-bypass relabelled mechanism-by-omission.
- §3.8 — the "two canonical asymmetries (keyboard EXCLUSIVE vs
  pointer BOTH)" **retired**; replaced with the one rule.
- §5.3 — D-D reframe (legitimate, not legacy).
- §6 — D-E and D-C added as owner questions.

In **`M4-0-03-contract-suite.md`** (owner-authorized edit to the
otherwise-frozen spec, this correction only):
- Bucket EXCLUSIVE/BOTH definitions (authoring discipline §3) —
  EXCLUSIVE = exactly one route, all event types; no inter-route
  BOTH (intra-route only, not the dispatch contract).
- P1/P2 — tightened to active-route; widget-up half not asserted.
- P3 keyreleased — active-route framing; widget-up drop not
  asserted (provisional).
- P4 mouse / P5 touch — **BOTH → active-route EXCLUSIVE**;
  intra-route forwarding not asserted as inter-route delivery.
- CP2 wheel — reframed to active-route delivery.
- Acceptance "teeth" — "one BOTH row" → "one pointer EXCLUSIVE
  row."

## What I did NOT change, and why

- **The design layer** (`requirements.md`, `design.md`, `spec.md`,
  `spec/M4.md`): the audit found it faithful (widget = operational
  sink, gate removed). Out of scope; no drift to correct.
- **OUTCOMES of the non-routing cross-cutting contracts** (§4.1
  held-key set, §4.2 combo serialisation, §4.4 slot restoration,
  §4.5 legacy solicitation, §4.6 widget activation/reset, §4.7
  click detection): not routing/dispatch rows; unaffected by the
  drift. Left as-is.
- **§1 premise** ("current implementation is the canonical
  specification"): a general justification for writing guarantees
  down, already governed by the OUTCOME-vs-MECHANISM discipline;
  editing it would overreach this correction.
- **The forward contracts §5.1/5.2/5.4**: already route-/sink-
  framed and correct; only §5.3 (D-D wording) needed reframing.
- **`src/`, tests, any other design doc**: out of bounds (the
  suite is regenerated downstream by M4-0-04, separately).

## Open rulings left provisional

- **inspect/overlay boundary** (§3.4) — which route owns
  `inspect` after unification. CHARACTERIZE-PROVISIONAL · OWNER
  RULING PENDING.
- **combo-tier key-repeat semantics** (D-C) — fire on every
  repeat vs fresh-only at the handler tier. Provisional leaning
  recorded, not ruled. OWNER RULING PENDING.
- **keyreleased under a widget** (§3.3) — provisional; possibly a
  defect to fix rather than preserve; open whether any consumer
  consumes `keyreleased` today.
- **sink-as-default coupling** (D-E) — deliberate-or-not call for
  the owner; flagged, not asserted.
- **global shortcuts non-consuming** (§4.3) — carried as-is;
  open whether mandated invariant or incidental.

---

_Authored by LLM (Opus 4.8), prompt12 cold pass, 2026-06-29.
Two files edited in one reviewable change. **Not final** — STOP
for owner blessing; revise on contest._
