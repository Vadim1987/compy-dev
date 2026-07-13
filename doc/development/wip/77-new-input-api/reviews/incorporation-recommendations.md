---
description: Pre-deletion doc-curation recommendation for `wip/77-new-input-api/` — what,
  if anything, must be promoted into the permanent docs corpus before the wip dir is
  deleted. Read-only analysis; recommends, does not rule.
status: active
audience: owner / PM
---
# Feature #77 — Incorporation recommendations (pre-deletion curation)

_Cold analyst pass (Claude Opus 4.8), 2026-07-13, over Task 4b. Worklist: the "Likely
incorporation candidates" shortlist in `WIP-DOC-INDEX.md`, candidates read in full as weighed.
Read-only: this file is the only write. Recommends targets; every keep/drop names its evidence.
The owner rules on the judgment calls, which are collected in §Controversies._

---

## Top-line

- **14 shortlist keep-candidates** weighed (Tier-1 ×5, Tier-2 ×3, Tier-3 ×4, Tier-4 ×2).
  My assessment promotes **2 as must-do**, folds **1 more by distillation**, treats the rest as
  **owner-judgment / archive-or-drop**.
- **The single most important thing not to lose: `notes/input-contracts.md`** (+ its applied
  `input-contracts-correction.md` / `input-contracts-revalidation.md`). It is the **only** durable
  record of the current input-routing *internals* — the `inspect`-mode console override (§5.4), the
  undocumented `search` MVC triad (§5.8), the `ConsoleController:keyreleased` console-only fork
  (§5.3.2), the four-incompatible-`reset()` split (§6.6), and the "out of #77 blast radius"
  foundation map (§8). None of that is in the permanent corpus, and none of it is obvious from the
  code (these are precisely the findings the sweep did *not* touch). It also self-nominates for
  `internals/` (header) and is the designated source material for repairing the stale
  `internals/user_input.md` (sub-question A). Lose it and the next console/editor-migration engineer
  rediscovers all of it from scratch.

---

## Keep-candidate table

Action vocabulary: **distill-then-promote** (rewrite/trim into a permanent doc, don't move
verbatim) · **archive-frozen** (move as-is into a clearly-historical location, no upkeep) ·
**merge-into-existing** · **drop** (safe to die with the wip dir). "keep-in-place" is not available —
the whole tree is being deleted.

| # | Candidate | What it is | Recommended target | Action | Rationale (cite) |
|---|-----------|-----------|--------------------|--------|------------------|
| 1 | `notes/input-contracts.md` (+ `-correction`, `-revalidation`) | Current-behaviour input-routing internals + blast-radius map; self-nominated for `internals/` | `doc/development/internals/user_input.md` (as the routing/internals half) | **distill-then-promote** | Only home for inspect/search/keyreleased-fork/reset-split facts (its §5.4/5.8/5.3.2/6.6/8); header names `internals/` as its promotion target. Forward-framing ("the rewrite will…") must be re-tensed to landed. This action *is* sub-question A. |
| 2 | `design/notes/ratified-model.md` | The one-page RATIFIED canonical model (Gate 1, human-approved 2026-07-05) | `doc/development/internals/` (design-rationale note) or a frozen `design/` archive | **archive-frozen** | Index Tier-1 "strongest single keep"; the authority `design.md`/`spec.md` derive from. Durable *why*, but permanent corpus has **no design-rationale home** — target is an owner call (§Controversies C4). |
| 3 | `design/notes/input.md` | Verbatim original stakeholder ticket + owner clarification | Frozen `design/` archive alongside #2 | **archive-frozen** | Index Tier-1; canonical ground-truth ask, immutable. Value is provenance, not live reference — archive, don't maintain. |
| 4 | `design/spec.md` | Cross-cutting API contract (Gate 2 APPROVED) | Frozen archive **only** (not a live contract) | **archive-frozen** *(contested)* | Index Tier-1 "the API reference", BUT the intent-alignment verdict found the landed code **drifts from it** on ≥3 axes (`eval` key unspecced, `multiline` promised-not-shipped, `compy.keys_pressed` not exposed). `doc/input_api.md` is now the live surface reference. Promote spec.md as *history*, never as the current contract, until reconciled. (§Controversies C1.) |
| 5 | `design/design.md` | Re-derived design; ratified model verbatim in §0 | Frozen archive with #2/#3 | **archive-frozen** | Index Tier-1. Overlaps #2 (opens with the ratified model). Design-history value only; same "no rationale home" problem. |
| 6 | `design/requirements.md` | Normalized FR/NFR set | Frozen archive with #2/#3 | **archive-frozen** | Index Tier-1 "durable what & why". FR/NFR are traceability, not runtime reference; the verdict maps FR-coverage to code already. Archive. |
| 7 | `notes/stakeholder-3-input/compy-input-quirks.md` | Developer-facing catalogue of Compy input quirks | `doc/development/` (dev reference) — after reconciliation | **distill-then-promote** *(contested)* | Index Tier-2 "reference-grade, audience-facing". BUT it catalogues the exact pains **#77 dissolves** and frames them as *unfixed*; promoting as-is is misleading. Needs a "dissolved by #77 / status" pass. Also links sibling docs (`compy-ide-design-patterns.md`, `dev/docs/…`) not present in this repo. (§Controversies C2.) |
| 8 | `notes/stakeholder-3-input/compy-lua-game-patterns.md` | Lua game/example design-pattern guide | `doc/examples/` or top-level `doc/` (not the input corpus) | **distill-then-promote** *(contested)* | Index Tier-2 "reference-grade". Genuinely useful, but **not input-specific** (general game skeleton/draw-decomposition) and references non-existent sibling docs. Home + self-containedness are owner calls. (§Controversies C2.) |
| 9 | `design/spec/M5c-dispatch-chain.md` | Gate-3 frozen dispatch-chain impl spec | Frozen archive, or **drop** | **drop** *(lean)* | Index Tier-3 "keep only if per-milestone spec history is wanted; else shipped code + spec.md suffice". Code is now the source of truth; the design *why* lives in #2/#4. (§Controversies C3.) |
| 10 | `design/spec/M7-02-recut.md` | Gate-3 frozen M7 (configure/clear/cursor/set_text) | Frozen archive, or **drop** | **drop** *(lean)* | Same as #9. |
| 11 | `design/spec/M8-02-recut.md` | Gate-3 frozen M8 (legacy removal/migration) | Frozen archive, or **drop** | **drop** *(lean)* | Same as #9; carries a "REVALIDATE AT COMMISSIONING" caution that is now spent (M8 landed). |
| 12 | `design/roadmap.md` | Milestone roadmap (Gate-3 frozen) | **drop** | **drop** | Index Tier-3 by association. Pure process sequencing; fully spent post-sweep. |
| 13 | `notes/retro-contract-provenance.md` | Standing "who decided this must hold?" methodology retro | `doc/development/` (or a process/retro home) | **merge-into-existing** *(optional)* | Index Tier-4 "candidate for a process/retro home, not the input corpus"; self-marked `status: reference`. Cross-cutting SDLC lesson — keep only if the owner wants method retros in-repo. (§Controversies C5.) |
| 14 | `notes/talk/two-tier-test-strategy.md` | Settled two-tier test-strategy decision | `doc/development/tests.md` (fold as a short note) | **merge-into-existing** *(optional)* | Index Tier-4. `tests.md` already documents the #77 suite; the safety-net-vs-test-first rationale could be one paragraph there. Owner call whether the SDLC lesson is wanted. (§Controversies C5.) |

**Net must-do:** #1 (distill into `internals/user_input.md`) and, tied to it, the sub-question A
rewrite. Everything else is archive-or-drop or optional-merge — no other single doc is load-bearing
for the permanent corpus.

---

## Safe to let die with the wip dir

Affirmatively no durable doc value; delete with confidence. (Everything in the 253-doc corpus *not*
on the shortlist is process ephemera by default per the index; these are the notable confirmations.)

- **All `implementation/` process-bulk** — `prompts/` (48), `outcomes/` (24), `reviews/` (23),
  `sessions/` (10), the chunk-plans, `technical_debt.md`, `review-prompt.md`, `README.md`. SDLC
  bookkeeping; `session05/track.md` already records the sweep COMPLETE. (Index §implementation.)
- **All `design/` process scaffolding** — `prompts/` (12), every `*.versions/` snapshot dir,
  `status/archive/**`, `agents/`, `status.md`, `estimates.md`, `context.md`, `README.md`, and the
  `design/notes/*` analysis/ingest notes (routing_unification, solution_sketch, decisions(-record),
  concerns, event_*, textinput_routing, love2d_handler_layers, requirements, plan, index, the
  `input/` round-2 processing set). Historical derivation; superseded by the ratified model + code.
- **Superseded specs** — `design/spec/{M1,M2*,M4*,M5,M5-01,M6,M6-*,M7,M7-01,M8,M8-01}.md`: all
  explicitly superseded/folded per the index supersession map. (M6-02-before-exit landed and is in
  the code + design.md; the spec slice itself is disposable.)
- **All `notes/` working analysis** except the #1 contract family and the Tier-4 pair — including
  `input-contracts-inventory.md` / `-revalidation.md` / `-correction.md` **once their content is
  folded into #1** (they are the audit trail *behind* the contract record, not separately durable),
  `input-routing-model.md` (explicit DRAFT), `intent-fidelity-audit.md`, `late-input-register.md`,
  the whole `assessment/` set (their findings are captured in input-contracts.md §5–§8),
  `migration/`, and effectively all of `notes/talk/**` (materialized chat insights, session logs,
  SDLC-enrollment decisions — `sdlc-provenance-and-layered-pipelines.md` is the one with any
  standing-record flavour but is not input-system knowledge).
- **`notes/talk/api-demo.md`** — explicitly "Draft — API surface not yet shipped"; superseded by
  the shipped `doc/input_api.md` (index §Tier-note; manifest cites commit `ced38bd`).
- **`reviews/synthetic-system-diff.patch` + `synthetic-diff-manifest.md`** — a diff, not a doc;
  reconstructable from git (`3256aac..HEAD`). Useful for cross-check *now*, no reason to keep after
  the PR. (Index §Flags.)
- **`entrypoints.md` / `entrypoints/E*.md`** — ratified decision records, spent post-landing.
- **Docker/infra + anomalies** — `implementation/docker/**`, `implementation/ses/SWEEP.tgz`
  (root-owned binary — do NOT extract, just delete), `implementation/notes/.gitkeep`. Note the
  `compose.yml` working-tree diff is flagged pre-existing / not-this-feature's (index §Flags) — a
  glance before `git rm`, but not doc-corpus material.

---

## Sub-question A — the fate of `doc/development/internals/user_input.md`

**Recommendation: (a) rewrite it to the landed system, with `notes/input-contracts.md` (§2–§6) as
the primary source material.** This is the same action as keep-candidate #1 — the two docs already
declare themselves companions (each links the other), so distilling the contract record *into* a
re-tensed `user_input.md` resolves both at once.

Why (a) over (b)-supersede or (c)-defer:

- **The doc is provably stale in a way that misleads.** It still presents the deleted
  `oneshot`/`push('userinput')` auto-hide as the *current* mechanism (lines ~418–428) and asserts
  the `compy.input.*` callbacks "do not exist in `src/` yet … M4–M6 design vocabulary, not current
  implementation" (lines ~429–432) — false post-sweep. `owner-rulings-verified.md` independently
  flagged this same drift.
- **It must survive in some form regardless:** the shipped `doc/input_api.md` "See also" (line 356)
  points a project author at `development/internals/user_input.md` for the how-it-works narrative.
  Option (b) would orphan that link. Keeping the file and rewriting its body preserves the contract.
- **Deletion timing forces the issue:** `user_input.md` currently links **into** wip/77
  (`input-contracts.md`, `notes/keyreleased-isrepeat-events.md`) — those links break the moment the
  wip dir is deleted. So the rewrite (which absorbs that content inline) must land *before* deletion,
  or the doc ships with dead links.
- The source material is ready: `input-contracts.md` §2 (channel convention), §3 (route/sink/widget
  vocabulary), §5.4 (inspect), §5.8 (search), §6 (cross-cutting contracts) are exactly the "how it
  works today" narrative user_input.md is supposed to be — already corrected and cold-revalidated.

**Caveat (route to owner):** this is a **rewrite, not a targeted fix** — realistically its own small
commission, and it needs one design input the curation can't supply: the `input-contracts.md`
**forward contracts** (§7) must be re-tensed from "the rewrite will…" to "the system does…", and a
few of those (e.g. `compy.keys_pressed` reaching projects, §7.4 keyreleased dispatch) **did not land
as written** per the intent-alignment verdict — so the rewrite can't be purely mechanical. I
recommend (a) as the destination; the owner should decide whether to do it now (before deletion) or
snapshot input-contracts.md into `internals/` first and rewrite in a follow-up. Do **not** pick
(c)-leave-for-later without at least snapshotting input-contracts.md out — deferral + deletion loses
the source.

---

## Sub-question B — the two committed review artifacts

`reviews/intent-alignment-verdict.md` (Fable's landed-implementation intent verdict) and
`reviews/owner-rulings-verified.md` (the PM fact-check of its 8 "for the owner" rulings).

**Recommendation: do NOT let them die silently — extract the 8 open rulings into the PR description
(or a tracking issue) before deletion; the verdict docs themselves can then die with the wip dir.**

Reasoning:

- **The 8 rulings are genuinely OPEN** (confirmed by owner-rulings-verified.md: 7/8 verified real,
  1 count-corrected; all still unresolved). They are actionable owner decisions the sweep shipped
  open — `compy.keys_pressed` exposure, the `eval` config-key deviation, combo-tier key-repeat
  semantics, `multiline`, silent config-key drops, LuaJIT proxy iteration, an `is_active()` query,
  and the 31 in-code `REVIEW:` annotations to sweep. Deleting the wip dir would drop this punch-list.
- But they are a **point-in-time review verdict + fact-check**, not durable *doc-corpus* knowledge —
  they don't belong in `internals/`. Their right home is wherever open follow-ups for this PR live:
  the **PR body's "known gaps / follow-ups" section**, or a GitHub issue.
- **Preferred concrete form:** lift `owner-rulings-verified.md`'s table + "Bottom line" three
  buckets (contract/spec reconciliation · API-surface additions · behaviour ruling) into the PR
  description. That doc is the tighter, code-verified artifact; the fuller `intent-alignment-verdict.md`
  can be linked from the PR (or its narrative summarized) and then allowed to die.
- **Cross-linkage worth surfacing:** three of the open rulings (item 2 `eval` deviation, item 4
  `multiline`, item 6 proxy iteration) are exactly the *spec-vs-code drift* that makes promoting
  `design/spec.md` as a live contract unsafe (candidate #4 / C1). So B and the spec-promotion call
  are the same reconciliation, seen from two ends.

**Route to owner:** the choice of vessel — PR body vs a tracking issue vs keeping the verdict as a
transient review artifact attached to the PR — is the owner's. My recommendation is *extract to PR
body, let the source docs die.* Do not simply delete without extracting.

---

## Controversies / gaps — owner rules, I do not auto-resolve

- **C1 — `design/spec.md`: promote as history or as a live contract?** The index calls it "the API
  reference," but the intent-alignment verdict documents real code-vs-spec drift (`eval`/`result`
  keys unspecced, `multiline` promised-not-shipped, `compy.keys_pressed` not exposed to projects,
  proxy iteration inert on LuaJIT). Promoting spec.md as the *current* contract would import stale
  claims. My lean: **archive-frozen as design history**, and let `doc/input_api.md` be the live
  surface reference — but whether to instead *reconcile spec.md and keep it live* is a design call
  bound up with the 8 open rulings (sub-question B). Owner's.

- **C2 — the two stakeholder-3 reference docs are partly stale / not self-contained.**
  `compy-input-quirks.md` catalogues the pains **#77 dissolves** but frames them as unfixed (needs a
  "dissolved by #77" status pass before it's safe to promote), and both docs link sibling docs
  (`compy-ide-design-patterns.md`, `compy-lua-runtime.md`, `dev/docs/…`) that **do not exist in this
  repo** — they read as imported from another project's doc set. And `compy-lua-game-patterns.md`
  is general game-authoring guidance, not input-specific, so its home (`doc/examples/` vs `doc/` vs
  the input corpus) is itself a question. Genuine reference value, but neither is drop-in. Owner
  decides: reconcile-and-promote, or drop.

- **C3 — Tier-3 milestone specs (M5c/M7-02/M8-02) + roadmap: archive or drop?** Pure "do you want
  per-milestone spec history?" judgment (the index says so explicitly). My lean is **drop** — the
  landed code is the source of truth and the design *why* is preserved in the ratified model /
  design.md. But if the owner wants a frozen implementation-history trail, archive them together.
  Not a knowledge-loss risk either way; purely the owner's taste for history.

- **C4 — there is no "design rationale" home in the permanent corpus.** `doc/development/` has
  `internals/` (how it works), `conventions/`, `overview.md`, `drawing_system.md`, `tests.md` — but
  no place for *why the input system is shaped this way*. Candidates #2/#3/#5/#6 (ratified-model,
  input ticket, design, requirements) all need such a home if kept. Options: a new
  `doc/development/internals/user_input_design.md`, a frozen `doc/development/design/77-input/`
  archive, or folding the essential "why" into the rewritten `user_input.md` (sub-question A) and
  dropping the rest. This target choice is unresolved and is the owner's to set.

- **C5 — Tier-4 method retros: do SDLC lessons live in this repo at all?** `retro-contract-provenance.md`
  and `two-tier-test-strategy.md` are cross-cutting process lessons, explicitly *not* input-system
  knowledge (the index says "process/retro home, not the input corpus"). If the repo keeps method
  retros, merge them (test-strategy → `tests.md`; provenance → a process doc); if not, drop. Owner's
  call on whether the repo carries methodology at all.

- **C6 — index/doc agreement.** No material disagreement found between the index and the docs I
  opened; the index's status flags matched the doc bodies. One nuance the index already anticipates:
  many wip docs are headered "human-approved NOT YET" while their content landed — treat body/Gate
  markers as authoritative, headers as advisory (index §Flags), which I did throughout.
