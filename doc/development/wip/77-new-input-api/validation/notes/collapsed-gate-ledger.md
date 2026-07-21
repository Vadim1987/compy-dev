# Pre-B/C/D collapse-gate ledger — the agenda the collapsed sitting rules over

**What this is.** A *living* forward-agenda for the collapse gate proposed by
`post-R-replan-hypothesis.md` and made living by
`../reviews/S18-post-R-replan-reconciliation.md`. The hypothesis: once Phase R landed,
`plan.md`'s **Phase B (convergence) + C (principle sheet/disposition) + D (owner sitting)**
can **collapse** into one short disposition-and-ruling pass — *if* both gap categories stay
fully enumerated and the probability of a new serious finding is small. This file is where the
enumeration is kept current: **rule the whole ledger out in one sitting → B/C/D dissolve; a
heavy new member appears → run B/C/D as `plan.md` writes them.**

**Gating.** The collapse is gated on **TF2 + TF3** (owner human review of the split suite +
hint triage) — `plan.md:160` requires DI + TF + R all owner-accepted before Phase B, and TF3's
leftover bucket is one place a new item could still surface. This ledger does **not** get ruled
until TF2/TF3 are done; it only *accumulates* candidates in the meantime.

**Not a ruling.** Every row below is a candidate with a *proposed* disposition. Nothing here is
decided until the owner rules it in the collapsed sitting.

---

## Already-enumerated (source of record — do not duplicate here)

- **Category (a) — code-vs-spec deviations:** the four rows **R2 / R4 / R5 / C1**, each with a
  drafted disposition and post-R re-verification in
  `../reviews/S18-post-R-replan-reconciliation.md` §"Category (a)". Not restated here.
- **Category (b) — scaffolding-suspects, CLOSED:** the dispatch/vocab cluster and the
  `app_state` fork — both dispositioned **and executed** by Phase R (`affc932`). Recorded in
  the reconciliation §"Category (b)"; they add no *open* work.
- **Postponed jargon cluster** (`overlay`, tier-N prose, etc. — `plan.md` "Owner decisions
  already made" #1): folds into the same sitting.

---

## OPEN items surfaced *after* R (this ledger's own additions)

Discovered during the **pre-TF2 noise-cleanup** (the improvised S19 `tests/` REVIEW-marker
triage the owner commissioned at TF2's opening to reduce review noise). The marker triage is a
*third* place a fifth item could hide, alongside TF3-leftover and the A1 no-home inventory.

| # | Item | Category | Charter / question | Status | Proposed disposition |
|---|---|---|---|---|---|
| **G-1** | Console-as-hidden-sink safety (S19 **D3**) | (b) design-safety | Master **RVW-111** + governed RVW-107/108/109/110/112. When a project runs and the input widget is hidden, does the **console silently consume/evaluate keystrokes**? RVW-111 argues that's dangerous-or-pointless and that an **active route** should own the fall-through, not a hidden console. | **OPEN** | Doc-first: cross-check `decisions/input.md` + `internals/user_input.md` for whether hidden-console consumption is intended. If settled → reword markers to a doc-reference + drop. If not → real design gap the owner rules (may feed a decision/tech-debt entry). Do **not** rule in the marker lane. |

---

## Explicitly NOT on this ledger

- **The `setup_callback_handlers` / `set_default_handlers` "handlers"/"callback" code-layer
  naming collision** (S19 D4 item 3). Owner ruling (2026-07-21): **not heavy** — the collision
  is already documented in `../../../internals/event_dispatch_layers.md`; the in-tree remark is
  **left in place for the owner's own eyes during the TF2 manual recheck**, judged there. Not a
  gate-ledger item. (Recorded here so a future reader doesn't re-promote it.)
