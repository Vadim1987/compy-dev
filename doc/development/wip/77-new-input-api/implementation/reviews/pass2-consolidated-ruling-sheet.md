---
description: Pass-2 consolidated owner ruling sheet for feat #77 pre-PR — every stress-test
  question, standing API/behaviour ruling, doc-incorporation call, and process approval as one
  row with a code-verified evidence cell and a one-line PR-justification-ready recommendation.
  DRAFT for the owner's single ruling sitting; recommendations are the orchestrator's, decisions
  are the owner's.
status: DRAFT — awaiting owner ruling
audience: owner
---
# Feature #77 — Pass-2 consolidated ruling sheet (the single owner sitting)

_Drafted 2026-07-18 (session09, Opus orchestrator), per the foundation's three-pass process
(`pre-review-drift-assessment.md` §3.3) as amended by the Fable sequencing consult
(`../sessions/session09/fable-sequencing-consultation.md`). **This is Layer 2** — the phase's one
human bottleneck. Every row is pre-formatted so the ruling text flows verbatim into the PR
description's **justification table** (net-new moving part / vocabulary → stakeholder need it
serves) or its **decisions / open-questions** section._

## How to use this sheet

- **Recommendation** column = the orchestrator's lean, written as a one-line justification a
  stakeholder could read. **It is a proposal, not a decision.** Tick/annotate the **Ruling** column.
- Evidence cells marked **[fc]** were re-confirmed in code (fact-check worker
  `../sessions/session09/factcheck-fable-claims.md` + orchestrator spot-check). **Two of Fable's
  claims were corrected on verification** (this is the guardrail working): the tier3 census (21 →
  **6** real occurrences, and not confined to one file) and the input_api.md jargon count (1 →
  **≥3**: `overlay` ×2, `callback slots`). Cells citing `owner-rulings-verified.md` are a prior PM
  code-verification pass. Nothing here is acted on until you rule.
- The **strategic gate** governs every lean: *does this make the input API simpler / more robust /
  more inspectable for the stakeholder, or merely more elaborate?* Anything net-new that can't be
  justified in one line is a removal/demotion candidate.

---

## Section A — Design stress-test rulings (S1–S8)

| # | Question | Evidence (verified) | Recommendation (PR-justification-ready) | Ruling |
|---|----------|---------------------|-----------------------------------------|--------|
| **S1** | Is the `framework_handlers` tier a justified separate route-level mechanism for submit/cancel, or should it fold into the widget (UIC)? | **[fc]** `framework_handlers` appears **nowhere** in `doc/input_api.md` → purely internal, invisible to projects. Composition is spec.md §5 verbatim; ratified deviation **D-a** (design.md §9). Fold = §9 amendment + rework of green code. | **Keep; justify as internal route-level mechanism.** "Submit/cancel is route policy (deactivate is route behaviour, not widget nature — D-a), not a surface projects touch; folding trades no stakeholder-visible simplicity for real rework/risk." | ☐ keep ☐ fold ☐ defer |
| **S2** | Does the §10 vocabulary (route/chain/tier/sink/gateway/slot) raise the PR's reading cost, or is it load-bearing? | **[fc, corrected]** The `tier-3` token is now gone from `input_api.md` (L20), but the **stakeholder-facing doc still leaks** `overlay` (L22, L59) and `callback slots` (L20) — both on your flagged jargon list. **Live contradiction to rule:** the ratified `decisions/input.md` (Decision 10 *title*: "…pure-wrapped as **tier-3** participants") uses the same "tier-3" your session08 jargon-format listed AS jargon. ~12 `tier N` position-prose comments remain in `src/` (left deliberately — see D5). | **(a) Scrub the stakeholder-facing doc** (`overlay`→"shared input widget/session"; "callback slots"→"callback fields") — small, reviewability-gate-relevant, **but purge scope is your call per the assessment, so not done unilaterally**; (b) **rule the ratified-'tier' vs flagged-'tier-3' contradiction**: keep 'tier N' as internal chain-position vocabulary, purge identifier-flavored 'tier-3' from prose, or leave as-is; keep the §10 glossary internal — no Gate-2 shrink. "The doc the PR is reviewed from still leaks two minted nouns; deciding the purge line is the reviewability call." | ☐ scrub doc + purge tier-3 prose ☐ scrub doc only ☐ keep+justify |
| **S3** | Decision 2 "no external gate" — enforced in code? (= audit A1) | **[fc, confirmed]** `UserInputController:_is_hidden_overlay()` defined `userInputController.lua:437`, all **4 call sites inside UIC's own handlers** (grep-verified — LSP `references` returned stale lines + a phantom temp path here, grep was ground truth) → Decision 2's *letter* holds. BUT the predicate derives hiddenness from **global placement** (`self == love.state.user_input_controller and not love.state.user_input`), not an internal flag; the flag is only *proposed* in a REVIEW comment, not implemented. | **Approve the internal shown/hidden-flag fix** (your own proposal, ~L422–423). "Makes hidden-behaviour self-determined and inspectable — the property the decision was meant to guarantee — with a tiny, testable change; no external contract shifts." | ☐ fix ☐ confirm+cite as-is |
| **S4** | Chain mechanics: nil-checks + if-dispatch vs metatable-default noops; combo tables rebuilt per keypress vs compiled once. | Complexity/perf note only; no behaviour change. Owner already leaned "not now". | **Defer + ledger as focused post-PR refactors.** "Internal micro-structure, not stakeholder-visible; no correctness stake; belongs in `technical_debt/input.md`, not the PR." | ☐ defer+ledger ☐ do pre-PR |
| **S5** | Pointer routing asymmetry (broadcast, no consume — a widget can't swallow a click) vs the keyboard consume-chain. (= ruling 9) | Verified in `owner-rulings-verified.md` item 9: `handlers.mouse/touch*` deliver to widget with no bounds-check/consume, **then unconditionally** forward to the slot occupant. No decision ratifies pointer routing; pointer never had the #77 lockout. | **Document as a known, deliberate asymmetry in the PR; do NOT build the mirror consume-chain pre-PR.** "Pre-existing pointer behaviour, out of #77's keyboard-lockout scope; a mirror chain is a larger design change better ruled on separately." | ☐ document+defer ☐ mirror pre-PR |
| **S6** | Are hidden-route semantics uniform/predictable? (= audit A2 + project-mode non-leak test) | **[fc]** flagged hidden-widget tests run under `app_state='ready'` (console = active route) → fall-through correct & user-visible. **Gap:** no **project-mode** test asserting a hidden widget does not leak to the console. | **Add the project-mode non-leak test (against the real `activate_project` path) + rewrite the misleading "console as hidden sink" prose; fix if a leak surfaces.** "Proves the hidden-widget rule holds in the mode that matters and removes prose that reads as a security hole." | ☐ test+prose ☐ +bugfix if leak |
| **S7** | Does the test scaffold actually prove the design holds? (fixture fidelity — E) | **[fc, confirmed]** fixture (`tests/helpers/input_fixture.lua`) is a **hybrid, not fake**: `activate_project` calls production `set_user_handlers`; infidelity localized to `running_project` (bare `love[name]` vs sandboxed `project_env.love`, ~L193), `show_widget` (bypasses `compy.input.show`, ~L184), `reset` (re-implements teardown the framework provides — `suspend_run`:971 / `stop_project_run`:1060 / `quit_project`:1075 all exist). | **Do the fixture-fidelity pass (helpers call real paths; where impossible, comment which path is mimicked) — Layer-3 first item, before any ruling cited on green tests.** "The scaffold must be trustworthy before it counts as evidence." | ☐ do it ☐ scope down |
| **S8** | Unrecorded API deviations confusing reviewers (`eval`/`result`, `multiline`, config-drop, `is_active()`, `keys_pressed`, combo-repeat). | All verified in `owner-rulings-verified.md` (rulings 1–7). | **Fold the resolved 9 rulings into the PR's decisions/open-questions section** (Section B below is the vehicle). "Reviewers see every deviation and its disposition in one place." | ☐ fold into PR |

---

## Section B — Standing API / behaviour rulings (owner rulings 1–9)

_All facts from `../../reviews/owner-rulings-verified.md` (PM code-verification pass). These are
genuine open **design** decisions — the lean is advisory; each needs your yes/no. Whatever ships
gets one justification line in the PR._

| # | Ruling | Evidence | Recommendation | Ruling |
|---|--------|----------|----------------|--------|
| **R1** | `compy.keys_pressed` — expose held-key polling to projects, or keep callback-arg-only? | `get_compy_namespace` exposes no `keys_pressed`; only framework-side + callback-arg proxy. `maze/main.lua:497` polls `love.state` directly as a workaround. | **Keep callback-arg-only + document the contract; defer exposure unless a stakeholder needs `update()`-time polling.** "Fewer surfaces = simpler; the one internal workaround is a ledger item, not a public API." | ☐ keep+doc ☐ expose |
| **R2** | `eval`/`result` config keys — bless as public API + record deviation, or realign onto `validator`/`highlighter`? | `apply_config` accepts `cfg.eval`/`cfg.result`; examples pass `eval=`; neither in spec §3. | **Lean: bless + record the deviation in the PR table** (least churn, examples already rely on it) — *or* realign to one vocabulary if you prefer a single config lexicon. | ☐ bless+record ☐ realign |
| **R3** | Combo-tier key-repeat semantics — shipped unsettled (tiers 1–2 fire on every repeat; `isrepeat` threaded to tier 3 only). | `projectInputController.lua` DEFERRED marker. | **Ratify current behaviour + document, or add an `isrepeat` gate at tiers 1–2.** Lean: ratify + document (no reported problem; a gate is a behaviour change). | ☐ ratify+doc ☐ add gate |
| **R4** | `multiline` spec §3 flag — implement or strike? | Unimplemented; `userInputModel.lua:499` `-- TODO multiline`; Shift+Enter newline unconditionally on. | **Strike from the spec/contract.** "Promised-not-shipped; removing the dangling flag makes the contract match reality." | ☐ strike ☐ implement |
| **R5** | Silent config-key drop in `show{}` — accept, or mandate a warn? | `apply_config` has no `else`/warn; but `set_cursor`/`set_text` **do** `Log.warn(... ignored — hidden)` — warn-don't-swallow is already applied selectively. | **Add the `Log.warn` on unknown keys for consistency + inspectability.** "A mistyped config key should surface, not vanish — matches the existing selective warn." | ☐ warn ☐ accept silent |
| **R6** | Proxy iteration on LuaJIT — accept indexing-only, or add an iteration helper? | controller.lua:349-352 self-admits `pairs(proxy)` is inert on Lua 5.1/LuaJIT (shipping platform). | **Accept + document indexing-only.** "Iteration is inert on the shipping runtime; index-read/write-raise is tested and sufficient — a helper adds surface for no stakeholder need." | ☐ accept+doc ☐ add helper |
| **R7** | Widget-visibility query — sanction a public `is_active()`-shaped read? | No `is_shown/is_active/is_visible` on `compy.input`; internal `UserInputController:is_shown()` exists; `maze` reads `love.state` directly + re-arm poll. | **Lean: add the public predicate** (small, additive; removes the `love.state` workaround and the per-tick poll) — pairs naturally with S3's internal flag. | ☐ add ☐ keep internal |
| **R8** | Sweep in-code `REVIEW:` + `input_api.md` doc bug. | **DONE** (commit `6b70907`; doc bug `8b9820d`). | **No action** — closed; mention as completed in the PR if useful. | ☑ done |
| **R9** | Pointer routing — mirror the keyboard consume-chain? (= S5) | See S5. | **Same as S5: document the asymmetry, defer the mirror-chain.** | ☐ (see S5) |

---

## Section C — Doc-corpus & incorporation rulings (before `wip/77` deletion)

_From `../../reviews/incorporation-recommendations.md` (C1–C6 + sub-questions A/B) and Fable's two
added rows. These gate what survives the wip-tree deletion and whether the PR's "See also" links
resolve — i.e. the reviewability gate._

| # | Call | Evidence / stake | Recommendation | Ruling |
|---|------|------------------|----------------|--------|
| **A-doc** | Fate of `doc/development/internals/user_input.md` — rewrite to landed system, snapshot-then-defer, or supersede? | **Provably stale & misleading** (still presents deleted `oneshot`/`push('userinput')` auto-hide as current; claims `compy.input.*` callbacks "do not exist" — false). **`input_api.md` "See also" (L356) points stakeholders at it** → touches the reviewability gate directly. Source ready: `notes/input-contracts.md`. | **Rewrite to the landed system before deletion, with `input-contracts.md` as source (its forward contracts re-tensed; a few that didn't land per the rulings corrected).** "A stakeholder following the PR's own 'See also' must not land on a doc describing a deleted mechanism." Its own small commission — sequence in Layer 3. | ☐ rewrite-now ☐ snapshot+defer ☐ supersede |
| **B-doc** | The two committed review artifacts (`intent-alignment-verdict.md`, `owner-rulings-verified.md`) — where do the 8 open rulings go? | Rulings genuinely open; point-in-time verdict, not durable corpus. | **Extract the ruling table + buckets into the PR body (Section B is that vehicle); let the verdict docs die with the wip tree.** | ☐ extract→PR ☐ keep as attachment |
| **C1** | `design/spec.md` — promote as history or as a live contract? | Real code-vs-spec drift (`eval` unspecced, `multiline` not shipped, `keys_pressed` not exposed). | **Archive-frozen as design history; `input_api.md` is the live surface.** "Promoting a drifted spec as current would import stale claims." | ☐ archive-history ☐ reconcile-live |
| **C2** | The two stakeholder-3 reference docs — reconcile-and-promote or drop? | Catalogue pains **#77 dissolves** but frame them unfixed; link sibling docs absent from this repo. | **Lean: drop** (or reconcile with a "dissolved by #77" pass if you want the reference). "Not drop-in; promoting as-is misleads." | ☐ drop ☐ reconcile+promote |
| **C3** | Tier-3 milestone specs (M5c/M7-02/M8-02) + roadmap — archive or drop? | Landed code is source of truth; design *why* preserved in ratified model. | **Lean: drop.** Pure taste-for-history; no knowledge-loss risk either way. | ☐ drop ☐ archive-frozen |
| **C4** | No "design-rationale" home in the permanent corpus. | `internals/` = how it works, not *why*. Candidates #2/#3/#5/#6 need a home if kept. | **Pick a home or fold the essential "why" into the rewritten `user_input.md` and drop the rest.** Lean: fold-essential + drop. | ☐ fold+drop ☐ new archive dir |
| **C5** | Method retros in the repo at all? | `retro-contract-provenance.md`, `two-tier-test-strategy.md` — cross-cutting SDLC, not input knowledge. | **Owner taste: merge (test-strategy→`tests.md`) or drop.** No knowledge-loss risk. | ☐ merge ☐ drop |
| **C6** | Index/doc agreement. | No material disagreement found. | **No action.** | ☑ n/a |

---

## Section D — Process / execution approvals (unblock Layer 3)

| # | Item | Detail | Recommendation | Ruling |
|---|------|--------|----------------|--------|
| **D1** | Badspecref → corpus mapping (corrective item 7) | Consolidated proposals in `../sessions/session08/cosmetic-{a,b,c}.md`; targets include the possibly-rewritten `user_input.md`. | **Approve the mapping; apply in Layer 3 *after* any corpus doc (A-doc) settles.** | ☐ approve mapping ☐ revise |
| **D2** | Fixture-fidelity approach (corrective item 6 / S7) | Helper→real-path mapping in `tests/helpers/input_fixture.lua`: `running_project`→sandboxed `project_env.love`; `show_widget`→`compy.input.show`; `reset`→`suspend_run`/`stop_project_run`/`quit_project`. Review-gated. | **Approve the approach; execute as Layer-3 item 1, review-gated.** | ☐ approve ☐ adjust |
| **D3** | Split the 2210-line `input_contracts_spec.lua`? | Owner's own remark frames it as a question. | **Lean: yes, but LATE (Layer 3) — after conceptual REVIEW remarks are resolved, so the split doesn't scatter them.** | ☐ split-late ☐ split-now ☐ don't |
| **D4** | Stale REVIEW remarks below the L604 stop-boundary in `input_contracts_spec.lua` | Listed in `cosmetic-c.md`; desynchronized from prior runs. | **Re-review or discard — your call; nothing acts on them until you say.** | ☐ discard ☐ re-review |
| **D5** | `tier3 → generic_callback` rename (corrective item 4) | **DONE** (Sonnet worker, session09; suite still 815/0/0/4). Symbol `_tier3`→`_generic_callback` in `projectInputController.lua` (6 real occurrences — Fable's "21" was wrong); `input_api.md` L20 `tier-3` token removed; `technical_debt/input.md` updated. **Left deliberately (flag if you disagree):** ~12 `tier N` position-prose comments in `src/` (ratified 'tier' vocabulary — see S2) and 27 `tier-3` mentions in dated historical session/review docs (rewriting them would corrupt the record). Report: `factcheck-fable-claims.md`. | **Ratify as done; the two "left deliberately" sets fold into the S2 ruling.** | ☐ ratify ☐ revisit |
| **D6** | Ledger the open design/debt questions (corrective item 5) | Chain mechanics (S4), pointer asymmetry (S5/R9), history lifecycle, combo pre-compilation, name-list, etc. → `technical_debt/input.md`. | **Approve; mechanical, Layer-0/3.** | ☐ approve |
| **D7** | `wip/77` tree deletion | Owner-gated; after PR assembled and A-doc/B-doc extractions land. | **Do NOT delete until Section C extractions are on disk in the corpus + PR assembled.** | ☐ (defer to end) |
| **D8** | Slice regeneration (`pr-slices/3*.patch`, corrective item 8) | Stale vs tree. | **LAST step, after the tree settles** (unconditional ordering constraint). | ☐ (last) |

---

## Sequencing after this sitting (Layer 3 execution order)

Per the amended plan (Fable consult): (1) fixture-fidelity pass [D2/S7] → (2) ruling-driven test &
code changes (S3 flag + R7 predicate + S6 non-leak test + R4/R5 contract fixes) → (3) approved
simplifications as focused commits → (4) A-doc rewrite + D1 badspecref application → (5) D3 spec
split if approved → (6) ledger sweeps [D6] → (7) **slice regeneration last** [D8] → PR assembly
(intent → design → ratified deviations D-a..D-d → this sheet's rulings as the justification table →
open questions) → (8) D7 wip/77 deletion on owner go.

**Standing ordering constraints (upheld):** fixture fidelity (S7/D2) before any ruling cited on
green tests; slice regeneration (D8) last.
