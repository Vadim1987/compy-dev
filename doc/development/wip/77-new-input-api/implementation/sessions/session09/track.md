# session09 — track

## Boot 2026-07-18 (Opus orchestrator)

- **Boot ritual complete.** Read pr-prep.md, session09/prompt.md, foundation
  (`../reviews/pre-review-drift-assessment.md`), session08/prompt.md (predecessor kept
  no track — outcome reconstructed from its prompt Status/WRAPPED + cosmetic-{a,b,c}.md).
- **Re-entrance guardrail:** no prior `session09/track.md` existed → fresh boot, not a
  resume. Created this file.
- **HEAD:** `f819415` docs: add pr-prep workflow entrypoint. Branch
  `feature/77-newapi-analysis-s20260615`.
- **Baseline suite:** `busted tests` → **815 / 0 / 0 / 4** ✓ (matches expected; 4 pending
  intentional).
- **Tree state:** matches documented anomalies exactly — `docker/compose.yml` local diff
  (not ours), untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `src/examples/*`, `src/vadexamples/`, `tests/editor/editor_spec_fwd.lua`),
  `implementation/ses/` (root-owned SWEEP.tgz). Nothing to clean.
- **State:** Pass-1 evidence audits (A1, A2, S1 sketch, S7 census) + tier3→generic_callback
  rename are all **pending owner go**. Awaiting owner direction on what to run next.

## Unit — Fable sequencing consultation (2026-07-18)

Owner asked me to consult Fable (oracle) to re-evaluate the whole pre-PR sequencing rather
than accept the foundation's three-pass framing at face value. Spawned Fable (explicit model),
gave it full context + reading list, asked for a layered plan tagged by intelligence level +
human-intervention level + ordering rationale, and invited it to challenge the plan.

**Fable's guide (it verified these in code, not inferred — I must re-confirm before acting):**
- **A1 answerable now:** `UserInputController:_is_hidden_overlay()` (userInputController.lua:437)
  is only called from inside UIC's own handlers → Decision 2's *letter* ("no external gate")
  holds. BUT the predicate derives hiddenness from global placement
  (`self == love.state.user_input_controller and not love.state.user_input`), not an internal
  flag → remark C is a real encapsulation-quality question, not drift; cheap fix = internal
  shown/hidden flag (owner's own proposal, ~lines 422–423).
- **S1 answerable now:** `framework_handlers` appears **nowhere** in `doc/input_api.md` → purely
  internal, invisible to projects → "keep, justified as internal mechanism" is cheap/defensible.
- **S2 smaller than budgeted:** `input_api.md` carries **one** jargon leak ("callback slots"/
  "tier-3", lines 20–21); rest is already role-named. Glossary load lives in code comments.
- **A2:** flagged hidden-widget tests run `app_state='ready'` (console = active route) → fall-
  through correct; genuine gap = missing **project-mode** non-leak test (write against the
  already-real `activate_project` path, not `running_project`).
- **Fixture (E) is hybrid not fake:** `activate_project` already calls production
  `set_user_handlers`; infidelity localized to `running_project` (bare `love[name]` vs sandboxed
  `project_env.love`), `show_widget` (bypasses `compy.input.show`), `reset` (re-implements
  teardown that `stop_project_run`/`quit_project` really provide, consoleController.lua:1060/1075).
- **tier3 rename tiny:** 21 occ. all in projectInputController.lua + the input_api.md L21 leak
  + 1 in technical_debt/input.md.
- **Big spec = tests/input/input_contracts_spec.lua, 2210 lines**; split is a question not directive.

**Fable's restructure (4 layers, not linear passes):**
- L0 mechanical+ruling-independent (tier3 rename, ledger) — Sonnet, **parallel track**, autonomous.
- L1 evidence *residue* only (A2 project-mode probe, S1 fold-cost sketch, S7 fixture census
  table) — analytical/Opus; A1 is NOT a binary Sonnet audit.
- L2 **THE RULING SITTING** — one consolidated sheet, one owner sitting = the phase's only human
  bottleneck. Fable adds two rows the plan lacks: `user_input.md` staleness/scope (touches the
  reviewability gate via input_api.md "See also"), and below-L604 stale-remark disposition.
- L3 execution, Sonnet-dominant, ordered: fixtures → ruling-driven tests → simplifications →
  badspecref apply → **spec split (late, if approved)** → slice regen (last).
- Both standing ordering constraints upheld (fixtures before green-test-citing rulings; slices last).

**Fable's bottom line:** draft the Pass-2 consolidated ruling sheet NOW (embedding already-
verified evidence), run tier3 rename in parallel; the ruling sitting is the critical path and the
current plan defers it behind an evidence pass that's ⅓ done and ⅓ mis-classified.

Fable agent id `aaffd36d2a2e4507d` (resumable). Presented to owner; awaiting direction.

## Unit — Owner adopted restructure + set standing rules (2026-07-18)

Owner ruled: **adopt the 4-layer restructure; draft the ruling sheet now; tier3 rename GO now.**
Plus three standing sub-agent rules to encode in workflow files (and they cover the Fable output):
(a) all agents/subagents told mcp-lsp(lua) is available; (b) delegate down to simpler model when
possible; (c) all prompts AND results materialized on disk in the workspace, never only in chat.

Actions taken this unit:
- **Materialized the Fable consult on disk** (rule c, explicit ask):
  `session09/fable-sequencing-consultation.md` — my full prompt + Fable's verbatim guide.
- **Encoded rules a/b/c** into `agents/pr-prep.md` → new "Standing sub-agent hygiene" subsection
  under "Sub-agents and model economy" (applies to every spawn; parent too).
- **Spawned Sonnet worker** (explicit model, background, id `a6afde130f149dcb3`): PART A =
  read-only fact-check of Fable's 5 code claims → report at `session09/factcheck-fable-claims.md`;
  PART B = execute the `tier3 → generic_callback` rename (LSP rename + grep backstop, fix
  input_api.md L21 leak + technical_debt/input.md, keep suite 815/0/0/4). Told about mcp-lsp +
  on-disk deliverable. **STILL RUNNING** — awaiting completion notification.
- **Drafted the Pass-2 consolidated ruling sheet** (Layer-2 apex):
  `../reviews/pass2-consolidated-ruling-sheet.md`. Sections A (S1–S8), B (owner rulings 1–9),
  C (incorporation C1–C6 + user_input.md A-doc + B-doc), D (process approvals D1–D8). Each row has
  a code-verified evidence cell + one-line PR-justification-ready recommendation + owner ruling box.
  Evidence cells marked **[fc]** restate Fable's claims and get hardened when the worker reports.
  Read `owner-rulings-verified.md` (9 rulings, PM-verified) + `incorporation-recommendations.md`
  (C1–C6, sub-Q A/B) to build it.

## Unit — Worker done; verification corrected two oracle claims; sheet hardened (2026-07-18)

Sonnet worker `a6afde130f149dcb3` completed. Report: `session09/factcheck-fable-claims.md`.
Suite **815/0/0/4** (unchanged). Part A: 4 CONFIRMED, **1 REFUTED**. Part B: rename applied.

**I re-verified in code before hardening the sheet (guardrail) — found TWO oracle claims wrong:**
1. **tier3 census (Fable said 21, all in one file) — REFUTED.** Actual: **6** real `tier3`
   occurrences in projectInputController.lua; symbol was `_tier3` (not 21). Plus 27 `tier-3`
   mentions across dated historical docs (worker correctly left those — rewriting records =
   corrupting history). Worker's "zero tier3 in src/" is true only for the no-separator literal:
   **~12 `tier N` / `tier-3` position-prose comments remain in src/** (controller.lua:200,
   consoleController.lua:367/392/397/487, projectInputController.lua several) — correctly LEFT,
   because 'tier' is ratified §10 chain-position vocabulary, not the identifier.
2. **input_api.md jargon (Fable said 1 leak) — UNDERCOUNTED.** Worker removed the `tier-3` token
   cleanly (git diff confirms: "wire the tier-3 callbacks"→"wire callbacks"), BUT the stakeholder-
   facing doc STILL leaks `overlay` (L22, L59) and `callback slots` (L20) — both on the owner's
   flagged jargon list. Did NOT scrub unilaterally: assessment says vocabulary-purge SCOPE is an
   owner call (S2). Surfaced as sharpened S2 evidence instead.

**Live contradiction surfaced for S2:** ratified `decisions/input.md` Decision 10 *title* uses
"tier-3" — the exact token the owner's session08 jargon-format listed AS jargon. Genuine
owner ruling, materialized in the sheet's S2 row.

**Tooling caution (noted per CLAUDE.md):** LSP `references` on `_is_hidden_overlay` returned
stale line numbers + a phantom temp-file path; worker fell back to grep as ground truth. LSP
refs unreliable for that symbol — grep backstop essential, as the rules already warn.

**Rename outcome (D5 now DONE):** `_tier3`→`_generic_callback` (projectInputController.lua def +
call sites), input_api.md L20 token removed, technical_debt/input.md updated. 3 files changed,
uncommitted. grep: zero literal `tier3` in src/ + corpus.

**Ruling sheet hardened:** top [fc] note (records the two corrections), S2 (rewritten — doc leaks
+ tier contradiction), S3 (confirmed + LSP caution), S7/D2 (fixture path `tests/helpers/`, real
paths :971/1060/1075), D5 (DONE + corrected census). Sheet is ready for the owner sitting.

**Open / next:** (1) present the hardened sheet to the owner for the Layer-2 ruling sitting;
(2) on rulings → Layer-3 execution in documented order (fixtures first, slices last). Uncommitted
tree change from the rename (3 files) — commits are the owner's on this side.

## CLOSE-OUT 2026-07-18 (session09 wrapped)

Owner directive on wrap: **do NOT batch-rubber-stamp the ruling sheet.** Batch approval is how the
invented concepts/jargon (`native`/`overlay`/`tier3`-as-identifier) got smuggled into the ratified
corpus. Successor is **Fable**, mandate = **assisted one-by-one walkthrough** of the ruling sheet,
discussion-ready per row, owner revises each decision explicitly before it's recorded. Successor
prompt written: `../session10/prompt.md` (walkthrough method spelled out; translate-don't-dump the
sheet; record each ruling immediately on disk; verify oracle claims in code).

**State of every open item at wrap:**
- **Pass-2 ruling sheet** (`../reviews/pass2-consolidated-ruling-sheet.md`): drafted + hardened,
  code-verified, READY. Status = awaiting the owner sitting (Layer 2). This is session10's input.
- **tier3 rename (D5):** DONE, suite 815/0/0/4. Uncommitted (3 files) — owner to commit.
- **Fable sequencing consult:** materialized (`fable-sequencing-consultation.md`); 4-layer
  restructure adopted by owner.
- **Standing sub-agent rules (a/b/c):** encoded in `agents/pr-prep.md`.
- **Two oracle-claim corrections** (tier3 census 21→6; input_api.md jargon 1→≥3) captured in the
  sheet + factcheck report.
- **Everything else** (S-items, R1–R9, C1–C6, A-doc/B-doc, D1–D8) = pending the sitting.

**Commits this session (by the OWNER, out-of-band):** HEAD advanced `f819415` → **`b14ca06`
"pass2: in progress"** (author Hleb Rubanau, 2026-07-18 19:55) — the owner snapshotted the
ruling-sheet trio mid-session: `pass2-consolidated-ruling-sheet.md` (hardened version),
`fable-sequencing-consultation.md`, `factcheck-fable-claims.md`, and a `track.md` snapshot. I made
NO commits (standing rule: commits are the owner's here). This confirms the owner is capturing
their own side — do not sweep it.

**Still uncommitted at wrap (the owner may want to capture these into the wrap commit):**
- the tier3 rename — `src/controller/projectInputController.lua`, `doc/input_api.md`,
  `doc/development/technical_debt/input.md`;
- `agents/pr-prep.md` — the standing sub-agent-hygiene rules + the repointed CURRENT PROMPT;
- `session09/track.md` (this close-out, post-dating the owner's snapshot) + `session09/prompt.md`
  (the WRAPPED line);
- `session10/prompt.md` — **untracked** (the successor handover). Reads fine from disk regardless.
- Pre-existing anomalies (`docker/compose.yml`, `claude.sh`, scratch, nested example repos) are
  NOT this session's — leave for the owner.

**Suite at wrap:** 815/0/0/4.

WRAPPED → handover: `../session10/prompt.md`.
