# session18 — track

## Boot (2026-07-20)
- Booted via `agents/validation.md` → CURRENT PROMPT = session18/prompt.md. Read boot ritual
  end-to-end, `agents/sessions.md`, `rules/revalidation.md`, plan.md.
- Re-entrance: only `prompt.md` present (no track/report) → **fresh start**. Opened this track.
- HEAD `206fa4b` (fold in side-note on replanning). Predecessor session17 report read.
- Baseline suite: **827 / 0 / 0 / 4** — CONFIRMED matches prompt's expected count.
- Working tree: only sanctioned untracked scratch (guardrail-3 list) + owner's own dirs
  (`wip/clarification`, `wip/personal-notes`, `wip/pull-26`, `implementation/ses/`). Nothing of ours dirty.

## Task (per prompt)
Revalidation of session17's R4/R5 outcomes (rules/revalidation.md) + analyze the ONE open issue:
UIC reads `love.state.app_state` to scope submit/cancel (abstraction leak). Decide fix A/B/C/other
**with owner**. Then reassess whether Phase R can close. Do NOT start TF2. Standing carryover
(post-R-replan-hypothesis note) fires only if R closes this session.

## Progress
- Boot done; briefed owner on status.
- Owner sharpened the concern (2026-07-20): the `app_state` read is a **symptom**; the real smell is
  the **context-dependent behaviour fork inside UIC**, threatening conceptual unification + future
  editor adoption of the API (feature req: editor migration not demanded, but must be *made possible*).
  Do NOT close R by rubber-stamping the fork as debt. → materialized in
  `validation/notes/S18-owner-concern-uic-context-behaviour.md` + cross-linked into the open-issue doc.
- Read commissioning intent firsthand: delta-design + delta-spec. **Key drift found:** delta-spec §3
  specifies uniform widget submit/cancel on `Widget:keypressed`, with **no `app_state` branch anywhere
  in the spec.** The shipped `app_state` fork is an implementation addition, not in the ratified intent.
- Read the crux code (`userInputController.lua:533-759`). **Critical finding:** the `if love.state.
  app_state == 'editor'` at :725 wraps TWO forks: (axis 1) editing-key ORDER + `modify()` — PRE-#77,
  flagged by standing REVIEW at :724; (axis 2) submit/cancel `_submit_default`/`_cancel_default` in the
  `else` branch — the R4 ADDITION. **Option B (flag for submit/cancel only) would NOT remove the global
  read** — axis 1 keeps `app_state` at :725. Removing the read requires addressing the whole branch.
- Reframed options around Q1 (R4's narrow submit/cancel addition — cheaply fixable) vs Q2 (pre-existing
  whole-fork — full fix = editor migration = deferred by Decision 1). Deciding lens = owner's bar:
  does the API *make editor migration possible* via a clean owner-config seam (precedent: `always_shown()`
  at :495 / editorController:12,16)?
- Spawned Sonnet worker (bg) for mechanical evidence sweep (deletions, vocab, ACs, docs, open-issue code
  facts incl. app_state sites + editor load() constraint). Prompt: `validation/prompts/S18-revalidation-
  evidence.md`; output → `validation/outcomes/S18-revalidation-evidence.md`.
- Wrote options doc `validation/reviews/S18-uic-fork-options.md` (A / B-narrow / B-proper⭐ / C / D),
  recommending **B-proper**. Presented options to owner; awaiting direction + flag-granularity ruling.
- **Worker returned (96k tok, clean).** Verdicts: deletions zero (grep; LSP returned PHANTOM refs —
  tooling-bug flag, not a code issue), vocab clean in src + 3 resynced docs, ACs 12/0/0/0, suite
  827/0/0/4, crux code facts verbatim. TWO items:
  (1) **`decisions/input.md` NOT resynced** — still describes four-tier/sink/singleton as CURRENT.
      By-design per delta-design preamble ("unedited until addendum ratified") — but means delta-
      design/spec are still status "PROPOSED pending R3", and folding the addendum into
      decisions/input.md is an unresolved step gated on R3 ratification. Real R-close item, not a defect.
  (2) **Worker's E.3 interpretation BACKWARDS** — claimed editor "relies on _cancel_default firing";
      verified in code it relies on it NOT firing (app_state=='editor' → editor branch, no lifecycle
      keys; :1166/:1188 confirm app_state stays 'editor' during edit). Annotated correction appended to
      the evidence file. Net: this STRENGTHENS B-proper — the flag is behaviour-PRESERVING (editor
      instances defer; console+overlay don't; only editor runs under app_state=='editor').
- LSP `references`/`definition` unreliable in this repo right now (phantom out-of-range hits) — grep is
  ground truth for completeness checks this session. Carry.
- **Owner inspected code, asked a/b/c/d/e + gave 3 steers (re:2/3/4/5). Verified all in code:**
  - re:2 (branch minimize): agree — shared helpers can run unconditionally; `horizontal/vertical` swap
    is COINCIDENTAL (disjoint key sets, one acts per keypress — no functional order dependence).
  - re:3 ("default" is itself a leak — widget shouldn't know events can be intercepted): agree; drop
    "default". Rename `_submit_default`/`_cancel_default` → `submit_flow`/`cancel_flow` (NOT submit/cancel:
    `UserInputController:cancel()` already exists at :200). 2 call sites, grep-backed.
  - re:4/5 (are Enter/Esc intercepted before UIC in editor?): **verified per-mode.** Reorg: YES (no
    passthrough). Search: Esc YES (returns :489), Enter→separate search widget (editor-branch no-ops).
    **Normal: NO** — `submit()` :610 and `load()` :716 do NOT call `block_input()`, so plain Enter,
    Ctrl+Enter, Esc fall through at :803-804 to `input:keypressed`; the app_state branch is the SOLE
    guard. So problem doesn't dissolve TODAY but WOULD if normal-mode submit()/load() blocked_input.
    Nuance: Shift+Enter non-empty must keep falling through (UIC line_feed; UIC submit guarded to
    non-shift, so safe).
- **New leading option E** (owner's re:4/5 path): editor intercepts Enter/Esc (block_input) → delete
  UIC's app_state lifecycle branch → UIC uniform submit/cancel. Removes the FORK itself (owner's real
  bar), not just the global read. Supersedes B-proper (now fallback). Axis-1 full-unify = also move
  Ctrl+D modify to editor. Updated `S18-uic-fork-options.md` (option E + revised recommendation + rename).
  Cost: touch editor submit()/load(); tests-first for suppressed fall-through side-effects (selection
  release / update_view). Awaiting owner go on E vs B-proper + scope (include axis-1 Ctrl+D? decisions/
  input.md fold-in this session?).
- Deep-dive Q&A with owner (verified all in code):
  - **Search/reorg never call UIC:keypressed.** `input:keypressed` callers: consoleController:1269 +
    editorController:804 ONLY. SearchController:keypressed (:81) owns keys, never delegates to its UIC.
    → E's editor footprint = normal-mode `submit()`/`load()` block_input ONLY. Search/reorg untouched.
  - **Editor does NOT expect Enter/Esc to fall through semantically.** Under app_state=='editor' branch,
    fall-through runs ZERO lifecycle; only incidental byproducts: trailing update_view() (REDUNDANT —
    UserInputView:draw() :298-301 calls update_view every frame for non-overlay instances) + selection()
    release_selection (redundant vs set_text/clear; test-pin). → "forgot to prevent," not "relies on."
  - Escape in editor = `load()` → `load_selection` → reloads selected block into input (set_text) / shift
    appends. "code is reloaded" = yes.
  - **oneshot archaeology:** userInputView.lua:294-297 — widget IDENTITY check (`~= love.state.user_input_
    controller`) "stands in for what oneshot used to flag"; its own REVIEW asks owner's exact questions.
    Same transient-vs-persistent concept encoded 3× (shown / always_shown / draw identity-check).
- **OWNER DECISION: follow option E.** 2 editor lines = acceptable merge risk (resolves cleanly).
  Test-pin discovered/preserved behavior. Retrofit discovered paradigms (search/reorg-not-to-UIC,
  preserved fall-through byproducts, uniform lifecycle, modify-flag) into persistent docs to justify the
  preservation tests. modify() stays widget-level, flag-gated (owner ruling, NOT lifted to editor).
- **Owner confirmed FULL branch deletion (both axes). Executing E.** Precise spec written to
  `validation/prompts/S18-optionE-execution.md`; delegated to Sonnet worker (bg). 4 units, tests-first:
  U1 preservation+breaking tests (`tests/input/input_lifecycle_unfork_spec.lua`); U2 editor block guard
  `(is_enter and not shift) or (escape and not ctrl)` in `_normal_mode_keys` (matches UIC triggers
  EXACTLY — scattering in submit()/load() would miss Alt+Enter → regression); U3 delete app_state fork,
  uniform lifecycle + `allow_modify` per-instance flag (`:allow_line_modify()` chained, editor:12 sets
  it) + unify order + drop REVIEW:724; U4 rename `_submit_default`/`_cancel_default`→`submit_flow`/
  `cancel_flow` (submit/cancel unavailable — `:cancel()` exists at :200). Worker NOT committing; I review
  diff+suite per unit then commit. Docs retrofit (U5) I do myself after.
- Verified for preservation: console (consoleController:1269-1273) runs submit_flow as no-op then
  evaluate_input → preserved, no console change; overlay (main.lua:382) transient, flows fire as designed.
- **Owner corrected the spec mid-flight (both adopted):** (1) editor block = plain block_input() in
  submit()/load() handled branches, NOT a combined guard (which re-encoded UIC triggers = cross-layer
  leak); unhandled Enter variants (Alt+Enter) fall through to a no-op submit_flow (editor sets no
  callbacks — verified). (2) allow_modify = constructor param, not fluent method. STOPPED the worker
  (it had done U2/U3 under old spec), reset the 2 formulation points + finished U3/U4 + test fixes myself.
- **E LANDED (uncommitted), suite 838/0/0/4** (827+11). app_state gone from userInputController; rename
  complete; allow_modify constructor param wired (editorController:12 passes true). Fixed worker's test
  #4 (Alt+Enter): original only passed via empty-guard accident; rewrote to load non-empty selection +
  assert input untouched (honest no-op guard). Record: `validation/outcomes/S18-optionE-execution.md`.
- Presenting to owner before commit (gate) + before docs retrofit (U5).
- Owner: non-shift Enter breadth (Ctrl/Alt+Enter submit) is ratified/de-facto — DON'T narrow, test-pin
  + document for console+overlay. Added 3 Enter-breadth tests (overlay C-return/M-return submit;
  console C-return evaluates) → suite **841/0/0/4**.
- Owner rationale directive: for identified+pinned discovered behaviour, doc rationale = "discovered as
  existing behaviour, no mandate to alter — de-facto standard per implementation" (+ narrowing =
  separate owner-gated change). Woven into test header + technical_debt/input.md.
- **Docs retrofit (U5) DONE** across persistent corpus:
  - `internals/user_input.md`: inner app_state fork rewritten as REMOVED; uniform keypressed +
    non-shift Enter breadth + editor-consumes-upstream + modify allow_modify flag; search owns its keys
    (never delegates keypressed to its UIC) + jump-return de-facto note; submit/cancel section renamed
    submit_flow/cancel_flow + guard breadth.
  - `technical_debt/input.md`: new RESOLVED entry for the app_state fork (option E) + a "discovered
    de-facto behaviours pinned" rationale block (Enter breadth / search jump-return / per-frame-draw
    identity check); fixed stale `_submit_default` ref at :384.
  - `input_api.md`: public submit-lifecycle now states which keys (Enter w/o Shift incl Ctrl/Alt;
    Escape w/o Ctrl; Shift+Enter = newline).
  - Persistent corpus grep-clean of old names; wip/ historical records left frozen.
- E is CODE-COMPLETE + GREEN + DOCUMENTED (uncommitted).
- **Owner directive (important): NO persistent doc/test may reference `wip/` — it's deleted pre-PR and
  not in it.** So: (1) tests reference persistent docs for rationale; (2) anything only in ephemeral
  docs → incorporate into persistent; (3) add a `decisions/input.md` decision "preservation/
  formalization of de-facto contracts" as umbrella rationale for reverse-engineered behaviours;
  (4) this IS the R3 question (fold delta-design/spec into decisions/input.md) → owner says GO.
  Recheck recent tests+docs, then commit (SINGLE) + R-close (no direct code review = TF2, postponed).
- Sized the problem: 33 wip-refs across 7 persistent-doc + test files. decisions/input.md still
  describes OLD design (four-tier/sink/singleton) as current — must fold in delta-design (revises
  D2/5/6/7/8/10 + vocab + impl note) + E outcome into D6 + new umbrella **Decision 14**.
- Drafted Decision 14 (umbrella, verbatim in spec). Delegated R3 fold-in + ref-repoint sweep to Sonnet
  (bg): `validation/prompts/S18-r3-foldin-refsweep.md` → `validation/outcomes/S18-r3-foldin.md`.
  DOCS-ONLY (test comments only, no assertions); suite must stay 841. I review fold-in accuracy
  section-by-section vs delta-design + spot-check repointing before commit.
- After review+commit: R CLOSES → open the sealed `post-R-replan-hypothesis.md`, reconcile vs closed-R
  state, present to owner. Do NOT start TF2.

## Re-entrance (2026-07-21, fresh incarnation — predecessor died mid-flight)
- Booted, re-entrance guardrail: `track.md` present, no `report.md` → interrupted-before-wrap; resume.
  Owner said "continue what it was doing." HEAD still `206fa4b`; nothing committed since.
- **Reconstructed worker state:** the R3-foldin Sonnet worker (bg) was killed with the predecessor
  session. It landed **Job A** (fold-in into `decisions/input.md`) in the tree but **never wrote its
  deliverable** (`S18-r3-foldin.md` absent) and **did NOT complete Job B** (ref-sweep). TaskList empty
  → no bg task running.
- **Job A verified by me (section-by-section vs delta-design + option-E outcome):** Decisions 2/5/6/7/8/
  10 revised correctly; Decision 14 inserted verbatim; implementation note added; option-E folded into
  D6 (uniform keypressed, no app_state, editor upstream block, allow_modify constructor flag); vocab
  sweep clean (retired terms only in explicit past-tense); deviation section correctly left intact (no
  row resolved by redesign). Suite **841/0/0/4** — Job A broke nothing (docs-only). Job A = GOOD.
- **Job B remaining (~20 dangling refs):** `technical_debt/input.md` (:530/:539/:555/:563 — "option E",
  `validation/reviews/S18-uic-fork-options.md`, "delta-spec §3"); `internals/project_sandbox_env.md:57`
  (wip note path); `input_api.md:11` ("Phase R4"); `tests/input/input_lifecycle_unfork_spec.lua`
  (:1-3 wip prompt path + "S18 option-E", :261 delta-spec §3); `input_redesign_ac_spec.lua`
  (:1-2 delta-spec §7 path + many "delta-spec §N" AC refs); `input_widgets_callbacks_spec.lua`
  (:280/339/383/454/488 delta-spec §N); `input_routing_spec.lua` (:18 meta-note, :113 wip/77 path).
- Plan: delegate Job-B-only sweep to Sonnet (mechanical), review output, then SINGLE commit + R-close.
- **Job B done (Sonnet, 81k tok, clean).** Prompt `validation/prompts/S18-jobB-refsweep-resume.md`;
  deliverable `validation/outcomes/S18-jobB-refsweep.md`. Verified by me:
  - Independent grep across all 9 files → ZERO wip/delta-spec/option-E/Phase-R4 refs; broader
    S18/unit-N/pre-unit sweep also clean. Suite **841/0/0/4**.
  - Diffs reviewed: technical_debt (Phase R4→"input-API redesign", delta-spec §N → Decision N,
    dispatch impl-note repoint — all correct); project_sandbox_env (dropped dead wip path, T1/T2/T3
    model is documented in the same file body — no claim lost); input_api ("Phase R4" dropped);
    AC spec header rewritten + all 10 AC→Decision remaps correct by content (AC1-5→D6, AC6→D2,
    AC7→D5, AC8→D10, AC9→D7, AC10→D11); widgets_callbacks + routing comment repoints correct;
    routing :18 meta-note reworded present-tense (avoids literal wip/77 substring).
  - Worker's flagged out-of-scope edit (lifecycle_unfork ~:217 modify-flag "unit 3"→Decision 6):
    same staleness species, factually correct — APPROVED.
  - NOTE: nothing committed all session → `git diff` shows CUMULATIVE S18 change set (predecessor's
    option-E code+U5 docs + Job A fold-in + Job B sweep). The big technical_debt append + input_api
    "Which keys" para are U5 (predecessor), not Job B.
- **REVIEW COMPLETE. Ready for the SINGLE commit + R-close.** Holding at the owner gate (I told the
  owner I'd show them before committing/closing R). Commit scope = all S18 uncommitted work as one
  unit; then R closes → open sealed post-R-replan-hypothesis.md, reconcile, present. Do NOT start TF2.
- **Owner gate answered: single commit + close R + include the validation trail.** Plus a pre-commit
  directive: the stakeholder-3 E20 assessment (`wip/.../notes/stakeholder-3-input/assessment.md`, the
  source `project_sandbox_env.md` cited) — salvage any persistent-worthy fact before wip/ deletion.
  - Read it. Load-bearing conclusions ALREADY persistent: P4/T3 sandbox-leak model → project_sandbox_env
    (assessment names it as its home); combo-tier repeat semantics + provisional fresh-only leaning →
    Decision 9 + internals:229 + technical_debt:150. Nothing lost there.
  - ONE residual not persistent: P1 — "no cross-channel (keypressed vs textinput) ordering guarantee;
    order-independent by design; tests mustn't bake canonical order as invariant." I initially judged it
    marginal/out-of-scope; **owner overruled** — folding it is R-phase coherence work, not scope creep,
    and avoids later ceremony. Framed as a **recognized external constraint (not a decision)**, grounded
    in LÖVE/SDL documenting no order, added as a bolded remark inside **Decision 2** (which I cited; it
    establishes the independent-channel shape that implies the constraint). Suite still 841/0/0/4.
- **COMMITTED `affc932`** (refactor(input): un-fork + fold-in, R-close). Staged 22 files by explicit
  path; owner's dirs + guardrail-3 scratch left untouched. **PHASE R IS CLOSED.**
- **Standing carryover FIRED** (R closed this session). Read sealed `post-R-replan-hypothesis.md`,
  reconciled vs actual state → `validation/reviews/S18-post-R-replan-reconciliation.md`. Verdict:
  hypothesis SURVIVES amended — the app_state fork was a genuine Phase-B-shaped scaffolding-suspect
  (NOT small like R5) but is now RESOLVED+EXECUTED, so it strengthens category (b) (2nd heavy closed
  member) rather than falsifying the note. Four category-(a) rows (R2/R4/R5/C1) still hold; R2
  partially advanced (eval now documented in input_api.md; result + PR-line remain). Genuine
  unknowns: TF2+TF3 not run (B gated on owner accepting DI+TF+R; TF2 resumes next, owner-paced,
  prompt bars me starting it) + Phase A's ~55 no-home process labels (minor, Phase C evidence).
  R-gate met by grep (LSP unreliable all session — phantom refs; grep is ground truth).
- Recommendation to owner: (1) formally accept R; (2) run TF2 next (owner-paced); (3) after TF2/TF3
  adopt the note's collapsed B→C→D over the known short list. Decision is owner's. Do NOT start TF2.
- Presenting to owner; awaiting the accept-R + next-step ruling before any wrap.
- **OWNER RULING (2026-07-21): Accept R; TF2 next as planned.** Phase R formally accepted. Standing
  carryover FIRED + discharged → retired from successor prompt.
- **WRAP:** wrote `session18/report.md`; successor `session19/prompt.md` (task = TF2, owner-paced,
  interactive; carryover retired; grep>LSP caveat carried; references report + reconciliation).
  Dated R-ACCEPTED note appended to plan.md Phase R gate. CURRENT PROMPT repointed → session19.
  Wrap commit = track + report + session19 prompt + plan note + reconciliation doc + repointed pointer.
- session18 DONE. Next: session19 runs TF2.
