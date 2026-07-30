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
  `../reviews/S18-post-R-replan-reconciliation.md` §"Category (a)". **C1 is CLOSED (S22):**
  persistent docs are the authoritative #77 contract; `wip/77` is non-shipping working evidence.
  Before TF2, a cold provenance inventory and owning-session canonical-doc pass will retrospectively
  mark decision authority/status where useful and ensure the shipping docs stand alone. **R4 is
  CLOSED (S22):** unconditional Shift+Enter newline insertion is the retained established
  contract; the unrequested public toggle and its stale debt/marker were removed. **R2 is
  RULED (S22), execution deferred:** retire result/eval config keys in favour of the minimal
  highlighter/validator callback contract recorded in S22-R2 input-contract plan. **R5 is
  RULED (S22), execution deferred:** unknown show keys warn rather than silently drop, per
  Decision 15 and S22-R5 unknown-show-keys plan. The rows are otherwise not restated here.
- **Category (b) — scaffolding-suspects, CLOSED:** the dispatch/vocab cluster and the
  `app_state` fork — both dispositioned **and executed** by Phase R (`affc932`). Recorded in
  the reconciliation §"Category (b)"; they add no *open* work.
- **Postponed jargon cluster** (`overlay`, tier-N prose, etc. — `plan.md` "Owner decisions
  already made" #1): folds into the same sitting.

---

## OPEN items surfaced *after* R (this ledger's own additions)

Discovered during the **pre-TF2 noise-cleanup** (the improvised S19 `tests/` REVIEW-marker
triage the owner commissioned at TF2's opening to reduce review noise). The marker triage is a
*third* place further items can hide, alongside TF3-leftover and the A1 no-home inventory —
**two** surfaced (G-1, G-2), both category (b); G-1 closed in S22.

| # | Item | Category | Charter / question | Status | Proposed disposition |
|---|---|---|---|---|---|
| **G-1** | Console-as-hidden-sink safety (S19 **D3**) | (b) design-safety | `updev` left the console callback installed for a running project with no keyboard/text handler; unhandled events could reach the hidden console. #77's project route now owns all running-project keyboard/text input. | **CLOSED (S22)** | Owner ruled the inherited fallback an accidental and insecure behaviour. #77 deliberately removes it; inspect remains the pre-feature debugger route. |
| **G-2** | Project-handler API asymmetry: `compy.<event>` callback vs `compy.input.hooks[event]` hook (S19 **RVW-003**) | (b) API-coherence | Surfaced during B-I/1. **Mouse** handlers are bare callbacks the project sets directly on the compy namespace (`compy.singleclick`/`doubleclick`), pulled at click time via `get_compy_handler` (`controller.lua:262/659/671`). **Keyboard/text** handlers are hooks under `compy.input.hooks[event]`, *seeded* from the project's sandboxed `love.<event>` (`seed_hooks`, `projectInputController.lua:42/108`; `HOOK_EVENTS`, `controller.lua:303`). Same conceptual act ("project reacts to input"), **two public shapes + two sourcing paths** — a user who sets `compy.singleclick` then `compy.input.hooks.keypressed` reasonably asks why one is a callback and the other a hook. Delivery works; **coherence doesn't.** In-tree echo: `input_shortcuts_click_spec.lua:96` (RVW-101) already asks "why not set up via `running_project`? … or does it not work with mouse events?". | **OPEN** | Design review at the collapsed sitting. Unifying seam the owner named: make `compy.{singleclick,doubleclick}` a **hook source** too (fold mouse into the hooks model). Caveat (owner): the mouse-side API was **not** examined during #77 and the keyboard path is more granular — needs real judgement, not a mechanical merge. Decide **unify vs document the intentional split**; may feed a `decisions/`+tech-debt entry. Do **not** rename the fixture `set_compy_handler` (RVW-003) until ruled — its name/role depends on the outcome; marker reworded in-tree to point here. |

**G-1 disposition (S22).** The earlier check compared only the shipped tree. The `updev`
baseline shows the actual issue: its project setup replaced a keyboard/text callback only when
the project supplied one, otherwise leaving the console callback installed; the raw dispatcher
called it when no widget was shown. #77's unconditional project-route installation closes that
fallback. `tests/input/input_events_spec.lua` now guards the change directly. Inspect is
unchanged pre-feature debugger behaviour: console input evaluates in the paused project's env.

**G-2 disposition (S22, revised after Sol consultation).** Retain the
pre-feature mouse/click versus keyboard/text API asymmetry. Do not add click
hooks or a shared dispatcher in #77: pointer input lacks a demanded, proven,
and designed common dispatch contract. Decision 16 and the future-input-
unification technical-debt entry record the rationale and future trigger.

---

## Explicitly NOT on this ledger

- **The `setup_callback_handlers` / `set_default_handlers` "handlers"/"callback" code-layer
  naming collision** (S19 D4 item 3). Owner ruling (2026-07-21): **not heavy** — the collision
  is already documented in `../../../internals/event_dispatch_layers.md`; the in-tree remark is
  **left in place for the owner's own eyes during the TF2 manual recheck**, judged there. Not a
  gate-ledger item. (Recorded here so a future reader doesn't re-promote it.)
