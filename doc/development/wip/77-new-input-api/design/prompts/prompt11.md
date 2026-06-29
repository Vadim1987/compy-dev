# Prompt 11 — Intent-fidelity audit: do the derived docs match stakeholder intent?

**Target executor: Claude Opus.** This is a judgment-heavy reading-and-adjudication
task, not transcription. It is a **fresh, cold pass on purpose** — you must not be
told the conclusions the owner's working sessions have reached, because the whole
point is to check whether the *derived* design and contracts faithfully encode what
the stakeholders actually asked for, or whether interpretation has drifted.

This file is an **actionable task** (unlike `prompt10.md`, which was handover
context). Paths are relative to the repo root unless noted.

---

## Why this audit exists

Feature #77 has a long derived chain (`design.md`, `spec.md`, `roadmap.md`, plus a
formal input-contract record under `notes/`). A downstream test suite was authored
*from* the contract record and then read critically — and the read surfaced a
suspicion that the contracts may encode **today's implementation mechanism** rather
than **stakeholder intent**: specifically, whether the *input widget* is a
first-class entity that alters event dispatch, or merely an operational surface the
active context drives. That single doubt may be local — or it may be a symptom of a
broader interpretation drift. **This audit determines which.**

The governing risk, stated plainly: the same disease this feature exists to cure
("implementation is the de-facto contract") may have a twin one level up —
**"our interpretation has become the de-facto stakeholder intent."** Your job is to
be the independent oracle for that.

---

## Read first (orientation)

1. `CLAUDE.md` — project overview and collaboration rules (points to the files below).
2. `agents/rules.md` — coding rules and **tone**. Read the tone section before writing
   anything: matter-of-fact and analytic, no blame; the audience is the senior people
   who built the system. Apply its **Summaries for Stakeholders** rules to any
   summary section (mirror their words, no internal jargon, no second person, do not
   re-explain their own requests back to them).
3. `agents/architecture_assistance.md` — the assistant role and its limits.

Do **not** read the derived chain (`design.md`, `requirements.md`, `spec.md`,
`spec/`, `roadmap.md`, `notes/input-contracts.md`, `notes/input-routing-model.md`)
until Phase 2. Phase 1 is deliberately blind to it.

---

## Collaboration rules (the process)

- Role: assistant to a senior architect — **reviewer, not co-author.** Do **not**
  rewrite the document chain. Your deliverable is an analysis report written to disk.
- **Git:** read-only operations (`git show`/`diff`/`log`) are expected and
  **encouraged** — in particular, use history to recover the *version* of `design.md`
  that a given stakeholder review was reacting to (see the authority model). No
  history-modifying operations, no staging unless explicitly asked, no `.git`
  tampering.
- Local file reads/writes/greps are permitted. Write your report **to disk**, do not
  just print it.
- No GitHub interaction. **No agent/subagent spawning.**

---

## The authority model (whose intent counts, and how much)

Authority gates on *whether a human with decision rights actually decided* — not on
which file a line sits in. From highest to lowest:

1. **Ground truth — `notes/input.md`.** The original ticket/clarification **and**
   "FEEDBACK AFTER FIRST ITERATION" (round 1). May not be overruled. This is the
   decision-owning stakeholder's voice.
2. **Architecture review — `notes/input/stakeholder2_notes.md` +
   `stakeholder2_structured.md`.** This is a stakeholder's **review of the proposed
   architecture** (it reacts to a then-current `design.md`). Authoritative on
   architectural critique: the preferences and corrections it states are intent
   signals of high weight. To read it correctly, use `git log`/`show` to find the
   `design.md` it was reviewing — but extract the *stakeholder's wants*, not that
   design's claims.
3. **Supportive concerns — `notes/stakeholder-3-input/`** (`assessment.md`,
   `compy-input-quirks.md`, `compy-lua-game-patterns.md`). From an **interested party
   who does NOT own architectural decisions** — real, corroborating pain-points
   (notably mouse/keyboard interaction difficulties), to be weighed as **evidence of
   need, not as mandates**. Do not let tier-3 material override tier-1/2.
4. **Derived (under audit) — `requirements.md`, `design.md`, `spec.md`, `spec/`,
   `roadmap.md`, `notes/input-contracts.md`.** These must *trace to* the tiers above.
   They are what you are auditing; they carry **no** independent authority.

The early ingest notes (`notes/event_routing.md`, `routing_unification.md`,
`solution_sketch.md`, `input/evaluation00.md`, `input/summary00.md`, etc.) are **our
own prior analysis**, not stakeholder voice — treat them as tier-4 derived, Phase 2
material, not Phase 1 evidence.

---

## The task — three phases, in order

### Phase 1 — Derive intent, blind

Read **only** the tier-1/2/3 stakeholder sources above (and git history of `design.md`
solely to contextualize the tier-2 review). From them alone, derive an **independent
intent model** for feature #77's input system. Answer at minimum:

- What is the input API meant to *do* for a project author (the problem being solved)?
- **The neutral pivotal question:** per stakeholder intent, what role does the *input
  widget* play in event dispatch? Is it an entity that *changes where events go*, or
  an operational surface that an owning context (console / editor / project) drives
  and configures — and what, if anything, do the stakeholders say about events the
  widget does not handle (swallowed vs passed through)?
- What is genuinely **mandated**, what is **preference**, and what do the stakeholders
  **not address at all** (silence — important to mark, so we know where the derived
  chain had to invent).
- Where tiers conflict, say so and resolve by authority.

**Write the Phase 1 intent model to disk first, as its own section of the report,
before reading anything in Phase 2 or 3.** Do not revise it afterward. If a later
phase changes your mind, record that as a Phase-3 note — never edit the recorded
blind reading. This ordering is the integrity mechanism of the whole audit.

### Phase 2 — Fidelity diff against the derived chain

Now read the tier-4 derived docs (`requirements.md`, `design.md`, `spec.md`, `spec/`,
`notes/input-contracts.md`, and the prior-session note `notes/input-routing-model.md`).
For each material claim about input routing / the widget / the event contracts,
classify it:

- **Faithful** — traces cleanly to a tier-1/2/3 mandate.
- **Drift** — contradicts, or adds a constraint not supported by, stakeholder intent.
- **Invention** — fills a genuine stakeholder *silence* (legitimate, but flag it as
  unmandated so it is held as a proposal, not a contract).
- **Over-constraint** — pins more than intent requires (forecloses options the
  stakeholders left open).

**Adjudicate the pivotal question explicitly:** does the derived chain treat the
widget as a dispatch-altering first-class entity, and if so, is that grounded in
intent or is it an artifact of the current implementation? Cite the specific tier-1/2
lines that settle it.

### Phase 3 — Test the sealed hypotheses

**Read this section only after Phase 1 is written to disk.** Two hypotheses are in
play; your job is to report whether your **already-recorded** Phase-1 reading supports
each — not to retrofit Phase 1 to them:

- **Hypothesis A (owner's):** stakeholders want the input widget demoted to a purely
  *operational* collector — it gathers user input and invokes context-specific
  callbacks (console / editor / project plug in their own validators), while **not**
  disrupting normal event flow and **not** swallowing events it does not know how to
  handle.
- **Hypothesis B (a prior working session's):** routing is **route-centric** — every
  keyboard/text event reaches exactly one *active route* (chosen by mode/context),
  never the widget by virtue of merely existing; the widget changes only
  *intra-route* handling, never *inter-route* dispatch.

For each: **Supported / Partially supported / Not supported / Intent is silent**, with
the tier-1/2 evidence. Be explicitly willing to return "the original widget-as-router
reading was in fact closer to intent" if that is what the sources say — confirming a
hypothesis because it is appealing would defeat the audit.

---

## Output

Write one report to **`doc/development/wip/77-new-input-api/notes/intent-fidelity-audit.md`**
(the owner may relocate it into `status/archive/` afterward). Structure:

1. **Phase 1 — recorded intent model** (written before Phases 2–3; never edited after).
2. **Phase 2 — fidelity diff:** a table of material claims × {Faithful / Drift /
   Invention / Over-constraint} with the tier-1/2/3 trace (or the silence) for each,
   then the explicit adjudication of the pivotal widget question.
3. **Phase 3 — hypothesis verdicts** (A and B) with evidence.
4. **Bottom line:** is the derived chain a faithful encoding of intent? List the
   **specific** drifts/inventions/over-constraints that need an owner decision, each
   tagged with severity (does it change the architecture, or only wording?). This is a
   findings report — **do not** propose or write chain edits; surface the decisions.

Severity discipline: separate "the contracts misstate intent and the architecture is
affected" (high) from "wording/altitude issue" (low). The owner needs that cut to
decide scope.

---

## Boundaries / discipline

- **Do not rewrite the chain.** Findings only; the owner decides remediation.
- Stay anchored to the sources. Where intent is silent, **say "silent"** — do not
  manufacture a mandate, and do not import any external session's framing as if it
  were stakeholder voice.
- No rabbit holes: if a question needs the actual stakeholders, name it as an open
  question rather than guessing.
- Tone per `agents/rules.md`: analytic, no blame, senior audience.

<!-- ───────────────────────────────────────────────────────────────────── -->
<!-- OWNER: confirm/adjust the authority tiers and the two hypotheses above   -->
<!-- before launch. Augment with any verbatim stakeholder context not on disk.-->
<!-- ───────────────────────────────────────────────────────────────────── -->
