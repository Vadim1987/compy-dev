# S18 — post-R replan reconciliation (the sealed hypothesis vs. actual closed-R state)

**Purpose.** Phase R closed this session (commit `affc932`). The standing carryover requires
reading the sealed `../notes/post-R-replan-hypothesis.md` (written 2026-07-20, *before* the UIC
`app_state` issue surfaced) and reconciling it against the tree as it actually is now — then
handing the owner a decision, not pre-empting it. This is that reconciliation. **Nothing here is a
ruling.**

## The hypothesis, restated
The note claims plan.md's **Phase B (convergence) + C (principle sheet/disposition) + D (owner
sitting)** can collapse to a short disposition-and-ruling pass, because once R lands, both gap
categories are already fully enumerated: (a) known code-vs-spec deviations = four rows R2/R4/R5/C1;
(b) scaffolding-suspects = the dispatch/vocab cluster, already dispositioned+executed by R. Its
falsification condition: *any new deviation or scaffolding-suspect surfacing during R that isn't
accounted for.*

## Verdict: the hypothesis SURVIVES, amended — not falsified
The `app_state` fork was exactly the kind of new scaffolding-suspect the note's falsifier
anticipated. But reconciling *how it was resolved* strengthens the note rather than breaking it:

- **It was NOT small-and-mechanical (unlike R5).** It was a genuine Phase-B-shaped architectural
  item — an abstraction leak (a reusable widget branching on global app-mode) requiring
  owner-involved design across A/B/C/D/E options, landing on **option E** (editor consumes
  Enter/Escape upstream via `block_input()`; uniform `submit_flow`/`cancel_flow`; `allow_modify`
  constructor flag). It also surfaced de-facto contracts that had to be pinned (Decision 14).
- **But it is now RESOLVED + EXECUTED, not parked** (commit `affc932`): code landed, suite green
  841/0/0/4, discoveries documented (Decision 14 + the `technical_debt/input.md` de-facto block),
  and the R3 fold-in consolidated the whole redesign into `decisions/input.md`.
- **Net:** it does not add an *open* item to B/C/D. It adds a **second heavy CLOSED member to
  category (b)** — so the note's "R already absorbed the heaviest scaffolding-suspect" claim is now
  truer, not weaker. Category (b)'s two heaviest members (dispatch/vocab cluster + `app_state`
  fork) are both dispositioned and executed.

## Category (a) — the four rows re-verified against the post-R tree
| Row | Status now (code-checked) |
|---|---|
| **R2** — `eval`/`result` keys | Still accepted (`userInputController.lua:242,255`). **Partially advanced:** `eval` is now thoroughly documented as public API in `doc/input_api.md` (config table :71, detail :183+, quick-ref :358, migration :399). Residual: the legacy `result` key + the PR deviation-table line. |
| **R4** — `multiline` | Holds. `userInputModel.lua:503` still `-- TODO multiline`; no code reads a `multiline` config key; Shift+Enter newline unconditional. Doc-only strike / backlog. |
| **R5** — silent config-key drop | Holds. `apply_config` (`userInputController.lua:241`) still has no warn branch for unrecognized `show{}` keys. The one real (small) code change. Now also recorded in `decisions/input.md`'s deviation section. |
| **C1** — `design/spec.md` disposition | Holds. `design/` frozen; `doc/input_api.md` is the live surface. Archive-as-history. |
No **new** category-(a) deviation surfaced from R.

## The genuine remaining unknowns (why the collapse can't be *ratified* yet)
1. **TF2 + TF3 have not run.** Per plan.md line 160, **Phase B starts only when the owner declares
   DI + TF + R accepted**, and the S16 revision deferred **TF2 (owner human review of the split
   suite) to resume after R**, with TF3 (hint triage) following. My prompt explicitly bars starting
   TF2. TF3's leftover triage is one of the two places the note itself says a fifth item could hide
   — so B/C/D-collapse is **gated on TF2/TF3**, even though the plan already predicts TF3's bucket
   is "near-empty since Phase R executes ahead" (plan.md:76-78).
2. **Phase A's "no persistent home" inventory** (`../outcomes/A1-spec-ref-sweep.md`): ~55
   process/version labels (`0.1.0-m7`, `ratified-model ruling 3`, …) rolled to Phase C evidence —
   minor, not new scaffolding-suspects, but some live in the TF1-split test files (line numbers now
   stale) and still need a Phase-C disposition pass.

## R-gate status (for the owner's formal acceptance)
Met: suite green **841/0/0/4**; ten delta-spec ACs pass as tests; vocabulary/rename sweep
**grep-clean** on retired terms; `app_state` read gone from the input widget; wip-refs swept from
the persistent corpus + tests (zero dangling). **Caveat:** the gate text names *LSP* zero-hits, but
`lua-lsp` has returned phantom/out-of-range refs all session — grep is the ground-truth backstop
and is clean. The REVIEW-remark that asked for the un-fork (`:724`) is retired.

## Recommendation (the decision is the owner's)
1. **Formally accept Phase R** (gate met) — this is the trigger that lets TF2 resume.
2. **Run TF2 next, owner-paced, as planned** — it is the immediate next phase and the last real
   source of category-(b) findings before B/C/D. I cannot start it (prompt bar); it needs the
   owner in the loop.
3. **After TF2/TF3, adopt the note's collapsed B→C→D pass** over a known short list — the four
   category-(a) rows (each with a drafted disposition in the note) + the postponed jargon cluster +
   whatever small TF3 leftover appears — rather than the full multi-phase sitting. The evidence
   strongly favors collapse; only TF2/TF3 remain to confirm it.
   - *Alternative the owner may prefer:* if the owner judges TF2/TF3's remaining bucket trivial
     (the plan already predicts near-empty), fold TF2/TF3 + B/C/D into **one** collapsed sitting.
     This is a fresh-eyes call for the owner, not something to pre-empt here.

*— reconciliation by the S18 orchestrator, 2026-07-21. Do NOT start TF2 without the owner.*
