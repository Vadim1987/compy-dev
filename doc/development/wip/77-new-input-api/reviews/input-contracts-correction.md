---
description: Cold, reviewer-not-co-author review (prompt13) of the prompt12
  contract correction — does the correction state intent not implementation,
  with sound provenance, and is any drift residue left behind?
status: review — findings only, no chain edits
audience: design / owner
---
# Review — input-contracts correction (prompt12), cold pass

**Stance.** Independent. I did not write the correction and was not told its
author's reasoning; I read the intent ground truth
(`notes/intent-fidelity-audit.md`), the provenance ledger
(`notes/input-contracts-correction.md`), and the **change itself** via
`git diff 7e35612^..HEAD` on `notes/input-contracts.md` and
`design/spec/M4-0-03-contract-suite.md`. Verdicts below are tested against
intent, not against how well the prose reads.

**Scope note (what the correction *is*).** The correction under review is the
doc change in commits `7e35612`, `3146d05`, `45e4034` (input-contracts.md §2/§3/§4
+ the M4-0-03 suite). An interleaved commit `4c8e1d0` also touched
`tests/input/input_routing_spec.lua`, two test helpers, and added
`notes/retro-contract-provenance.md`; those are **outside** this review's charter
(the suite is regenerated downstream by M4-0-04) and outside the ledger's own
declared scope. Flagged for honesty in F3 below, not judged here.

---

## Test 1 — Provenance gate held

**Verdict: PASS, with one row to surface (F1).**

Every inter-route routing PRESERVE row cites the ratified principle and/or a
tier-1/2 mandate:

- §3.1 keypressed — PRESERVE: ratified principle (§2) **+** tier-1 "only text
  fields break; native keyboard handling must keep working," stated at route
  level. Cited. ✓
- §3.2 textinput, §3.3 keyreleased — PRESERVE: ratified principle (§2). ✓
- §3.5 mouse, §3.6 touch, §3.7 wheel (route axis) — PRESERVE: ratified principle
  (§2). ✓

No surviving PRESERVE routing row asserts *observed behaviour with no mandate* —
that is exactly the disease the gate was installed to catch, and the
widget-presence "drop" framing that carried it is now demoted to
CHARACTERIZE-PROVISIONAL everywhere (§3.1 note, §3.2, §3.3 note). ✓

**F1 (surface, not a failure).** §2C / suite-P12 **"hidden widget does not
consume"** is tagged **PRESERVE**, but its provenance is *"owner ruling
(prompt12) + common logic"* — **neither** a tier-1/2 mandate **nor** the ratified
inter-route principle. It survives the gate only because it is (a) an owner
ruling (legitimate top authority) and (b) an **intra-route** rule, which the
routing-row gate does not govern. That is defensible, but it is a *newly minted*
invariant wearing the same PRESERVE tag as genuinely *preserved* ones. The gate's
own text ("PRESERVE only if it traces to a tier-1/2 mandate or the ratified
principle") does not, as written, admit "fresh owner ruling." Owner-actionable:
either widen the gate's PRESERVE definition to name "owner ruling" as a third
admissible source, or tag P12 distinctly (e.g. PRESERVE — owner-minted) so it is
not read as code-preserving.

---

## Test 2 — No mechanism-as-contract residue

**Verdict: PASS.**

- No PRESERVE row is keyed on widget presence. The `if get_user_input() then …`
  gate appears **only** inside explicitly-labelled CHARACTERIZE-PROVISIONAL notes
  ("today's realization, expected to change, no stakeholder mandate," §3.1/§3.3)
  and in the §2(B) paragraph, which now names it "today's mechanism … not a
  routing contract." ✓
- No inter-route keyboard-vs-pointer asymmetry. §3.8's "two canonical
  asymmetries (keyboard EXCLUSIVE vs pointer BOTH)" is **retired**; one rule
  replaces it. ✓
- No current-code behaviour promoted to invariant: the suite's P4/P5 flipped
  **BOTH → active-route EXCLUSIVE**, the bucket EXCLUSIVE/BOTH definition (§3) was
  rewritten to deny any inter-route BOTH, and the acceptance "teeth" changed from
  "one BOTH row" to "one pointer EXCLUSIVE row." ✓

The §4.3 re-wording (DEBUG view-toggles: "only reachable when the widget does not
intercept (EXCLUSIVE keyboard path)" → "fire when the active route handles the key
itself rather than forwarding it intra-route") is a correct, in-scope removal of
the same widget-intercept framing — not residue.

---

## Test 3 — Pointer collapse is principled

**Verdict: PASS.**

Pointer (§3.5) and touch (§3.6) are stated as inter-route EXCLUSIVE on the active
route; intra-route forwarding to a widget is named "the route's concern …
invisible to this contract." The collapse is **argued, not asserted**: the §3.5
note explains *why* today's "both" was an artifact — the keyboard path has the
overlay gate, the mouse path does not — and gives the positive reason it is
EXCLUSIVE inter-route: "when a project is running, a click is **not** propagated to
the editor route — the running mode owns the whole screen; there is no second
top-level route to receive it." That is a sound, mode-exclusivity-grounded reason,
not a restatement. Intra-route parallel delivery (widget *and* the route's own
logic) is preserved as the route's private affair — the "parallel handling" tier-1
actually asked for. ✓

---

## Test 4 — Honesty of the principle's provenance

**Verdict: PASS, with one precision item (F2).**

The inter-route exclusivity rule is labelled, verbatim, a **"ratified design
rule, not a stakeholder mandate,"** and states **"Intent is silent on inter-route
topology per se."** That is the honest core and it matches the audit (Phase-2 rows
11–12: the EXCLUSIVE-single-route invariant and the three-controller topology are
**Invention / derived**, intent silent). The EXCLUSIVE-vs-"no exclusivity"
disambiguation (D-B) is carried (route axis vs channel axis), defusing the
terminology collision the audit flagged. The "UIC = universal terminal sink"
objective stays correctly hedged as "a recommended objective, not a present fact."
✓

**F2 (precision of one citation).** The provenance sentence grounds the rule in
"mode-exclusivity + the architect-ratified three-controller topology (Console /
Editor / ProjectInputController), **endorsed via `decisions.md`**." Per the audit
(intent ground truth, §1.3 + Phase-2 row 12), `decisions.md`'s own sketch (D-3) is
a **single global dispatch chain**, *not* a three-controller routing model; the
three-controller shape is a **design.md-level derivation**. `decisions.md` /
tier-2 endorse the *naming* (`ProjectInputController`, not `ProjectController`) and
the project↔console run-path convergence — they do **not** endorse the
three-controller *routing topology*. So "endorsed via `decisions.md`" slightly
overstates the citation: the topology's actual home is the derived design layer,
not `decisions.md`. This does **not** undermine the rule (the "design authority,
not mandate, intent silent" framing is exactly right) — it is a citation-precision
fix. Owner-actionable: point the topology endorsement at `design.md §2` (derived,
owner-ratified through the design process) and reserve the `decisions.md` cite for
the naming + run-path-convergence it actually supports.

---

## Test 5 — No over-reach

**Verdict: PASS.**

- The **design layer** (`requirements.md`, `design.md`, `spec.md`, `spec/M4.md`)
  is untouched — `git diff` over the correction commits shows only
  `M4-0-03-contract-suite.md` changed under `design/`, which the prompt explicitly
  authorised. The audit's **Faithful** rows (Phase-2 rows 1, 3–10) all live in
  that untouched design layer. ✓
- The non-routing cross-cutting OUTCOME contracts the audit did **not** fault
  (§4.1 held-key, §4.2 combo serialisation, §4.4 slot restoration, §4.5 legacy
  solicitation, §4.6 widget activation/reset, §4.7 click detection) are unchanged
  in substance. ✓
- `design.md` is not contradicted: the correction moves the contract record
  *toward* the design layer's already-faithful "widget = operational sink, gate
  removed" stance — it closes the split the audit diagnosed, rather than opening a
  new one. ✓
- In-scope edits that are *not* over-reach: §5.3 (D-D "legitimate, not legacy")
  and the §4.3 re-wording are both within the audit's named drift items (D-D,
  D-A consequence). The §1 premise was deliberately **left** (ledger says so) —
  correct restraint.

One pre-existing item the correction *carried as-is* and did not introduce: §4.3
"global shortcuts non-consuming" is tagged PRESERVE while §6/open-questions still
records "open whether mandated invariant or incidental." That is honestly flagged
and was not in the correction's drift scope, so carrying it is correct — noted only
so the owner does not mistake it for a correction product.

---

## Test 6 — Open rulings preserved

**Verdict: PASS.**

- **inspect (§3.4)** — left `CHARACTERIZE-PROVISIONAL · OWNER RULING PENDING`,
  with an explicit "deliberately deferred — keep the assumption" owner note; suite
  CP1 mirrors it ("owner kept the current assumption; revisit when the routing
  model lands"). No contract invented. ✓
- **combo-repeat (D-C)** — §6 records the leaning "fresh-only at the handler tier;
  `on_key_pressed` sees repeats" as **provisional, not ruled**, and adds the owner
  constraint "existing combos keep their current behaviour unless explicitly
  altered" with "Do not promote the leaning to a contract." Not manufactured into
  an invariant. ✓
  - *Watch item (not a failure):* the suite's Bucket B row **I7** ("`handlers[combo]`
    dispatch … fresh-only keying", m5b-deferred) is pre-existing, was **not** touched
    by this correction, and is a *forward* IMPLEMENT row, not a PRESERVE — so it does
    not violate "do not promote the leaning to a contract." But its wording ("fresh-only
    keying") is the very leaning §6 says is unruled. Worth a downstream glance when
    M4-0-04 regenerates the suite, so the deferred row's phrasing tracks §6's provisional
    status rather than reading as settled.
- **D-E sink-as-default coupling** — carried as a flagged owner question, "not
  asserted here as a contract." ✓

---

## Overall: **APPROVE**

The correction does the job the audit set: it removes the mechanism-as-contract
drift (widget-presence keying; inter-route pointer BOTH), re-founds §2/§3/§4 and
the suite on a single inter-route-exclusivity rule, and — critically for an
*unbiased* correction — labels that rule honestly as derived design authority with
intent explicitly marked silent, rather than smuggling it in as a stakeholder
mandate. Every surviving PRESERVE routing row carries a real provenance citation;
the open rulings (inspect, combo-repeat, D-E) are left provisional, not invented;
the faithful design layer is untouched. No mechanism residue survives as a
contract.

The three findings below are **precision / labelling** items, not drift — none
blocks approval; each is owner-actionable when the record is blessed.

### Owner-actionable residue

1. **F1 — P12 PRESERVE provenance.** "Hidden widget does not consume" (§2C / suite
   P12) is tagged PRESERVE on "owner ruling + common logic," which is neither gate
   criterion. It is a *newly minted* invariant, not a preserved one. **Action:**
   widen the gate's PRESERVE definition to admit "owner ruling" as a third source,
   **or** tag P12 distinctly so it is not read as code-preserving.

2. **F2 — topology citation precision (§2 provenance).** "Architect-ratified
   three-controller topology … endorsed via `decisions.md`" overstates the cite:
   per the intent audit, `decisions.md` holds a single-chain sketch and endorses
   the *naming* + run-path convergence, not the three-controller routing shape
   (that is a `design.md` derivation). **Action:** cite `design.md §2` for the
   topology; keep `decisions.md` for naming/convergence. (Honesty of the "not a
   mandate / intent silent" framing is unaffected and correct.)

3. **F3 — ledger scope vs interleaved test commit.** The ledger states "`src/`,
   tests, any other design doc: out of bounds." An interleaved commit (`4c8e1d0`)
   nonetheless edited `tests/input/input_routing_spec.lua` + two helpers and added
   `notes/retro-contract-provenance.md`. Not part of the prompt12 correction
   commits and outside this review — but the ledger's "I did NOT change tests"
   claim reads as contradicted by the surrounding history. **Action:** confirm the
   test edits were a separate, intended step (not silent suite-editing under the
   "frozen" fence) when blessing the record.

---

_Reviewer: LLM (Opus 4.8), prompt13 cold pass, 2026-06-29. Read-only; no chain
edits; no subagents; no GitHub. Findings only — remediation is the owner's call._
