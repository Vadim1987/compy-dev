# session13 — track

## Boot — 2026-07-19

- HEAD: `6afd9ed` (session12 wrap chain: plan.md amended + ratified, DI/TF gate inserted).
  Tree carries the known owner scratch + anomalies (`agents/validation.md` guardrail 3) —
  not swept.
- Suite baseline confirmed: **815 / 0 / 0 / 4**, pendings at lines 118/172/185/246 — exact
  match to the mandated baseline. Go-signal.
- Model: **Opus** (orchestrator). No prior `session13/track.md` — clean boot, no mid-flight
  death (fresh start per `agents/sessions.md` §2).
- Read in order: `agents/validation.md`, `session13/prompt.md`, `session12/track.md`,
  `validation/plan.md` (amended, DI/TF ratified), the plan-revision review
  (`validation/reviews/plan-revision-2026-07-19-doc-test-gate.md`), owner post-Phase-A note,
  A1/A2 outcomes, the validation map (`notes/input-suite-validation-map.md`), doc A
  (`notes/input-contracts.md`, all 859 lines), the corpus heading map (`input_api.md`,
  `internals/user_input.md`, `decisions/input.md`, `technical_debt/input.md`, `tests.md`),
  and `agents/sessions.md` (owner-mandated this session).
- **Mandate:** orchestrate **DI1** — the doc-A fidelity audit (first executable phase of the
  amended plan). Sonnet does the mechanical per-section evidence gathering (code checks via
  LSP+grep + corpus-coverage cross-ref); Opus consolidates the per-section verdict table and
  spot-checks load-bearing facts in code. Output: `validation/outcomes/DI1-docA-fidelity.md`.
  Verify doc A against **CODE, never the suite** (circularity guard — the suite's own fidelity
  is Phase TF's question). Leverage + refresh `notes/input-suite-validation-map.md`. Fold in
  the `tests.md` drift (says 808 + stale pending line numbers; real 815/0/0/4, pendings
  118/172/185/246). DI1 audits the doc's claims, NOT the feature (no re-sweep, guardrail 1).

## Blocker cleared — 2026-07-19

- session13/ was created root-owned (owner placed prompt.md as root); first track.md write hit
  EACCES. Surfaced to owner; owner chowned to agent:agent. Dir now writable. Owner also flagged
  `agents/sessions.md` as a mandatory read this session — done (see boot list).

## Orchestration plan (DI1)

- Two **sequential** Sonnet evidence workers (hygiene-d: serial in shared /repo tree, not
  parallel worktrees). Read-only on source; each writes a dossier to `validation/outcomes/`.
  - DI1-a → §1–§5 (premise, channels, routing vocab, completeness table, per-event contract
    table 5.1–5.9). Code-verification-heavy.
  - DI1-b → §6–§9 (cross-cutting 6.1–6.7, forward 7.1–7.4, out-of-radius §8, open Qs §9).
    Corpus-coverage-heavy; reuses DI1-a's established mechanism facts, does not recontest them.
- Opus then consolidates into `validation/outcomes/DI1-docA-fidelity.md` (per-section verdict
  table) + refreshes the validation map + spot-checks the load-bearing code facts in code.
- Prior expectation to be TESTED, not assumed: much of doc A looks already superseded by the
  corpus written after it (decisions/input.md 13 decisions + "where shipped differs from
  intent"; technical_debt/input.md already carries §8's out-of-radius items). Evidence toward
  DI2 option (b) merge — let the audit prove it.

## DI1-a returned (Sonnet, §1–§5) — 2026-07-19

Dossier: `validation/outcomes/DI1-a-evidence.md`. High quality. Verdict shape for §1–§5:
- OUTCOME contracts (§3 invariant, §5.1/5.2/5.3 exclusivity, glossary, reset semantics, §5.4–5.8)
  overwhelmingly **still-true**; the "(current realization)" MECHANISM notes on §5.1/5.2/5.3.1 are
  **superseded-by-shipped** (overlay-gate-on-project → PIC-occupies-slot landed, as anchored).
- Corpus home: almost everything **already-covered**, dominantly by `internals/user_input.md`
  (§5.8 search, §5.3.2 keyreleased fork, §5.4 inspect are near-verbatim) + `decisions/input.md`
  Decisions 1/2/12. Genuinely **unique-no-home** is thin: the provenance/tag methodology (§1),
  the mode×channel completeness-table *shape* (§4), the "free show_widget() is incoherent"
  negative framing (§3), and the §5.9 rule-of-five digest.
- **Fidelity finding worth DI2 attention:** doc A §5.4 asserts "not currently documented in
  internals/user_input.md; this pass is its first record" — now **FALSE**; `user_input.md:168`
  documents the inspect mechanism near-verbatim. Content still-true, novelty claim stale.
- Worker notes: doc A's own file:line citations have drifted (content resolves at new lines); LSP
  had to be ToolSearch-loaded mid-session, used for spot-checks (get_user_input caller set
  confirmed), not exhaustively. → I will spot-check load-bearing facts myself before finalizing.
- Strong early signal toward **DI2 option (b) merge** (thin unique residue, no 6th overlapping
  doc). Let DI1-b + my consolidation confirm.

## Anchor facts I verified in code (before spawning workers) — 2026-07-19

Pivotal mechanism reality, so workers don't recontest and I have ground truth to spot-check:
- `get_user_input` **survives** (`controller.lua:21-24`): `if app_state=='inspect' then return;
  return love.state.user_input`. Now the **console route's** intra-route widget forward
  (`forward_keypressed/textinput/keyreleased` at :40-60, plus mouse/touch handlers
  :1022-1117 all gate on `get_user_input()`). Comment at :30-37 cites decisions/input.md
  Decision 9 & 13.
- `ProjectInputController` real: `Controller.project_input = ProjectInputController()`
  (`controller.lua:1192`); on a run, `occupy_keyboard` (:234-259) sets
  `love.keypressed/textinput/keyreleased = pic:...` — **PIC occupies the keyboard/text slots**,
  overlay gate removed for the project route. Deactivated on stop (:799,:815).
- **Consequence for doc A:** its §5.1/§5.2/§7.1 "today = overlay gate on project keys / forward =
  ProjectInputController" temporal frame is INVERTED — the forward world shipped. §5.1's
  "today's mechanism [CHARACTERIZE-PROVISIONAL]" overlay-gate-on-project note is STALE; the
  gate now lives only on the console route's own widget forward. This is the dominant staleness
  genre to expect throughout §5/§7.

## DI1-b returned + orchestrator spot-checks + consolidation — 2026-07-19

- DI1-b (Sonnet, §6–§9): `validation/outcomes/DI1-b-evidence.md`. High quality, LSP-backed.
  Same pattern as §1–§5: outcomes still-true, mechanism/forward tags superseded-by-shipped,
  content already-covered (dominantly `internals/user_input.md`). Surfaced 4 doc-A claims now
  FALSE (§6.1/6.2 "zero consumers"; §5.4 novelty; §6.6 "compy: nothing yet"; §6.6 pushed-
  userinput-event). §9-item-2 ('starting') now resolvable NO. §8's four items homed in
  internals/, NOT technical_debt (corrects the brief's hint).
- **Orchestrator spot-checks (verified in code myself, not trusting dossiers):**
  (1) `projectInputController.lua:198-207` `_dispatch` DOES consume `combo_string(trigger,
  Controller.keys_pressed)` + threads `held_keys()` → §6.1/6.2 "zero consumers" confirmed FALSE.
  (2) grep `src/**`: legacy globals gone from tracked source (only untracked vadexamples scratch
  + a local var `user_input.C`); `git log b4d96ec` = M8-03 removal → §6.5 confirmed removed.
  (3) `main.lua:272/286/319`: 'starting'→'ready' same synchronous load() → §9-item-2 NO.
  (4) `internals/user_input.md:~168` documents inspect near-verbatim → §5.4 novelty claim FALSE.
  (5) `tests.md:69` says "808" + pendings 101/153/161/222 (real 815; 118/172/185/246) — drift
  confirmed; recorded as DI1 finding, fix is a DI3 action.
- **Deliverable written:** `validation/outcomes/DI1-docA-fidelity.md` — consolidated per-section
  verdict table (Axis-1 fidelity + Axis-2 corpus home), the 4 FALSE-claim findings, §9 status,
  tests.md drift fold-in, spot-check log, and an evidence-only DI2 section (owner decides).
- **Validation map refreshed** (`notes/input-suite-validation-map.md`): DI1 status banner only;
  suite rows untouched (TF scope / circularity guard). 3 open findings carried to Phase TF.
- **DI1 verdict → DI2 evidence:** supports **(b) merge** (session12 prior CONFIRMED). No case
  for promoting doc A whole (option a) — would import inverted tags + 4 false claims. Unique-no-
  home residue is thin: §9-item-3 (sink-as-default silent-disable → technical_debt) + §9-item-2
  one-liner → internals; rest is doc-scaffolding not to be promoted. Option (c) largely collapses
  into (b) since content is already homed. **DI2 is owner-gated — presented, not ruled.**
- Gate status: DI1 (my task) complete; awaiting owner review before wrap. DI2/DI3 = next session
  per recommended layout (S14).

## Wrap — 2026-07-19

- Owner accepted DI1 and ruled: **go with the ratified recommended layout** (DI2 sitting + DI3
  execution → S14); **wrap S13 now**. No changes requested to the audit — DI1 stands as approved.
- DI1 unit committed `0628087` (docs, local). Wrap artifacts: `session13/report.md` (distilled
  outcome + non-obvious points), `session14/prompt.md` (successor). DI1 was cognitive-heavy →
  successor framed as **revalidate DI1** (per `agents/rules/revalidation.md`) **then** DI2+DI3,
  reconciling the sessions.md revalidation rule with the plan's S14=DI2+DI3 layout (revalidation
  is the natural first step before ruling on DI1's evidence).
- Created session14/ as `agent` (not root) to avoid the boot chown repeat. Repointed CURRENT
  PROMPT → session14. Wrap committed as one docs commit.
- Handover essentials for S14: DI1 confirms DI2 option **(b) merge**; the four FALSE doc-A claims
  and the `unique-no-home` residue (§9-item-3 → technical_debt; §9-item-2 one-liner → internals)
  are what DI3 acts on; `tests.md` 808→815 drift fix is a DI3 action; doc A stays unedited in
  place; design/ frozen.
