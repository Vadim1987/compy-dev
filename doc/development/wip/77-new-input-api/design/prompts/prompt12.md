# Prompt 12 — Unbiased correction of the input contract record (and the bucket spec)

**Target executor: Claude Opus.** This is an **authoring** task (not a review): you
**edit** the contract record and the bucket spec to remove a diagnosed interpretation
drift, governed by a strict provenance gate. It is a **cold pass on purpose** — you
must not inherit the working sessions' phrasing; you re-derive each corrected row from
the cold intent audit and one stated principle. Paths are relative to the repo root.

---

## Why this correction exists

An intent-fidelity audit (cold, blind — `notes/intent-fidelity-audit.md`) found the
**design layer faithful** but localized one drift to the **contract record**
`notes/input-contracts.md` (§2/§3/§4) and the bucket spec derived from it. Two things
were tabulated as `[stable-now]` **preserve** invariants that are in fact **today's
implementation mechanism**:

1. **Keyboard/text routing keyed on WIDGET PRESENCE** ("widget active → widget only",
   EXCLUSIVE) — literally the `if love.state.user_input then …` overlay gate in
   `controller.lua`.
2. **Pointer routing as inter-route BOTH** (route + widget) — an artifact of the mouse
   path lacking the gate the keyboard path has.

Both encode the mechanism as the invariant — the exact disease #77 exists to cure,
leaked one level up into the contract meant to govern the cure. Your job: correct the
record so it states **intent, with provenance**, then **stop for the owner to bless**.

---

## Read first (in this order)

1. `notes/intent-fidelity-audit.md` — the cold audit. **This is your intent ground
   truth for this task.** Findings **D-A..D-E** and the pivotal-question adjudication
   say exactly what drifted and why.
2. `notes/input-routing-model.md` — the model note. §2/§2.1 state the corrected
   invariant; §6 drafts the remediation. **Treat this as a PROPOSED remediation, not
   authority** — verify each correction against the audit and the tier-1/2 lines it
   cites, never against this note's phrasing.
3. `agents/rules.md` — tone (matter-of-fact, senior audience) and line limits.
4. `agents/architecture_assistance.md` — role and limits.

---

## The single principle you correct toward

> **Inter-route dispatch is EXCLUSIVE for EVERY event type (keyboard, text, pointer):
> every input event reaches exactly one route — the active one, fixed by the exclusive
> screen mode** (console / editor / project-running / special, e.g. `inspect`). The
> **widget is an operational surface** the active route drives and configures; it never
> determines routing by merely existing. The only legitimate **"both" is intra-route**
> (a route delivering one event to its own logic *and* to a surface it activated — the
> "parallel handling" tier-1 asks for); intra-route handling is invisible to the routing
> contract.

**Provenance of this principle, to record honestly:** it **derives** from
mode-exclusivity (a real system property) + the architect-ratified three-controller
topology (tier-2, endorsed via `design/notes/decisions.md`). Intent is **silent** on
inter-route topology per se — so state the principle as a **ratified design rule**, not
as a stakeholder mandate.

---

## The provenance gate (the anti-bias mechanism)

Every routing/dispatch row in the corrected record must carry a provenance tag:

- **PRESERVE** — only if it traces to a **tier-1/2 mandate** (cite it) **or** to the
  ratified principle above.
- **CHARACTERIZE-PROVISIONAL** — observed current behaviour with no mandate; tag
  "expected to change, no stakeholder mandate."

A row with **neither a mandate nor the principle** behind it **may not be PRESERVE.**
The absence of this gate is precisely what let the drift in.

**Forbidden:** deriving any routing contract from current-implementation behaviour;
promoting observed behaviour to invariant; (re)introducing a keyboard-vs-pointer
*dispatch* asymmetry. Current code (the `controller.lua` gate, the mouse path) may be
consulted **only** as a preserve-checklist for the one genuine tier-1 mandate — *"no
backward compat, but only TEXT FIELDS break; native keyboard handling must keep
working"* — and that preservation must be stated **at the route level**, never as
widget-presence.

---

## The corrections to make

In **`notes/input-contracts.md`**:

- **§2 invariant / vocabulary:** replace EXCLUSIVE-keyboard-vs-BOTH-pointer with **single
  inter-route exclusivity (all events)**, grounded in mode-exclusivity. Disambiguate the
  word **"EXCLUSIVE"** (route axis) from the stakeholders' **"no exclusivity"** (channel
  axis) — **D-B**.
- **§3.x keyboard/text routing** (incl. the §3.1 **F-A caveat** already present):
  re-found EXCLUSIVE on **active route by mode/context**; demote widget-presence to a
  §3.x note characterizing today's mechanism — **D-A** (the central fix).
- **§3.7 wheel / §3.8 + the mouse (pointer) rows:** collapse to *"pointer reaches the
  active route; intra-route forwarding to a widget is the route's concern."* Remove
  inter-route BOTH — the pointer correction (`input-routing-model.md` §2.1).
- **D-D wording:** "legacy heuristic" → *"no project handler set ⇒ default propagates to
  the active route's sink"* (legitimate, not legacy).
- **D-E:** flag that overriding `on_key_pressed` disables `on_limit_reached`
  (sink-as-default coupling) — a deliberate-or-not note for the owner.
- Add the **per-row provenance** tag described above.

In **`design/spec/M4-0-03-contract-suite.md`** (you are **explicitly authorized by the
owner to edit this otherwise-frozen design spec, for this correction only**):

- Fix the bucket **definitions** of EXCLUSIVE / BOTH to match the corrected record
  (EXCLUSIVE = exactly one route, *all* event types; "BOTH" belongs to **intra-route**
  only, not the dispatch contract). Re-bucket the drifted PRESERVE rows — **P1/P2
  widget-up halves, P3 keyreleased, P4 mouse, CP2 wheel** — to active-route framing or
  CHARACTERIZE-PROVISIONAL.

**Open rulings — do NOT invent; carry as provisional placeholders, tagged
`OWNER RULING PENDING`:**

- **inspect/overlay boundary** (which route owns `inspect`; §3.4) — keep
  CHARACTERIZE-PROVISIONAL.
- **combo-tier key-repeat semantics** (D-C) — keep the provisional leaning marked
  provisional.

---

## Output

- **Edit the two files** in a single reviewable, locally-committed change (Conventional
  Commits: `docs(contracts): …`). Do **not** treat the blessed record / frozen spec as
  final — **stop for owner blessing.**
- **Write a provenance ledger** to `notes/input-contracts-correction.md`: a row-by-row
  table {corrected claim → PRESERVE / CHARACTERIZE-PROVISIONAL → tier-1/2 mandate, or
  "ratified principle", or "provisional/silent"}; the list of rows whose bucket/framing
  changed; what you **did not** change and why; the open rulings left provisional.
- Present a short summary and **wait for the owner.** Revise on contest; done only when
  the owner blesses.

---

## Boundaries

- Edit **only** `notes/input-contracts.md`, `design/spec/M4-0-03-contract-suite.md`, and
  the new `notes/input-contracts-correction.md`. Touch **no** other design doc, **no**
  `src/`, **no** tests (the suite is regenerated downstream, separately, by M4-0-04).
- Read-only git for history; no history-modifying ops; no `.git` tampering; no
  GitHub; **no agent/subagent spawning.**
- If a correction can't be stated without an owner ruling, mark it `OWNER RULING
  PENDING` — do not guess.

<!-- OWNER: confirm the principle's provenance line (mode-exclusivity + tier-2 topology) -->
<!-- and that editing design/spec/M4-0-03-contract-suite.md is authorized, before launch. -->
