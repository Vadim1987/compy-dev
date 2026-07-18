# Fable sequencing consultation — feat #77 pre-PR phase (2026-07-18, session09)

_Oracle consult requested by the owner: re-evaluate the whole pre-PR sequencing rather than
accept the foundation's three-pass framing at face value. Fable spawned with explicit model,
full context + reading list, asked for a layered plan tagged by intelligence + human-intervention
level, and invited to challenge the plan. Materialized here per the on-disk rule; a condensed
digest also lives in `track.md`. Fable agent id `aaffd36d2a2e4507d` (resumable via SendMessage)._

---

## Part A — the prompt given to Fable

> You are Fable, engaged as the expensive wisdom oracle for a strategic sequencing decision on
> the compy LÖVE2D project's feature #77 (new input API). Repo root = /repo = cwd. Your job here
> is **judgment and planning**, not execution — produce a sequencing guide the Opus orchestrator
> will turn into a step-by-step plan and present to the human owner. Read the foundation before
> advising; verify any factual claim you make in code (LSP/grep), don't infer.
>
> ### The situation
> The input-API feature is BUILT and green (`busted tests` → 815/0/0/4). Code landed long ago.
> The remaining phase is **pre-PR**: stress-test the shipped feature against intent + common
> sense, collect owner rulings, and assemble a **stakeholder-reviewable PR**.
>
> **The strategic gate (the owner's, non-negotiable):** stakeholders asked for a *simpler and
> more robust input API*. The PR must be reviewable from `doc/input_api.md` + the PR description
> ALONE (no wip/77 access), and must not carry any moving part or vocabulary beyond that ask
> without a one-line justification. Ratified design is NOT exempt: design.md was validated against
> stakeholder intent but never against post-implementation common sense / simplicity /
> inspectability.
>
> ### What you must read (in order)
> 1. `agents/pr-prep.md`; 2. the FOUNDATION
> `implementation/reviews/pre-review-drift-assessment.md` (drift verdicts A–E, corrective actions
> 1–8, stress-test S1–S8, three-pass process); 3. session08/09 prompts; 4. the FEATURE-level
> `reviews/owner-rulings-verified.md` (9 rulings) + `reviews/incorporation-recommendations.md`
> (C1/C2); 5. skim `doc/input_api.md`, frozen `design/design.md`, persistent corpus.
>
> ### The question
> The owner is skeptical of the current framing (front-loads "Pass-1 evidence audits" as
> mechanical). The owner's instinct: outstanding work stratifies into **layers requiring
> different levels of intelligence and human intervention** — wants your read on ORDER. Address
> head-on: (1) mechanical work first? (doc/test cleanup, badspecref mapping, tier3→generic_callback
> rename, splitting the big spec file); (2) test strengthening second? (fixture infidelity E,
> missing project-mode non-leak test, A1 audit of Decision-2 "no external gate"); (3) is (1)+(2) a
> sufficient base to then stress-test design integrity (S1–S8) for simplicity/inspectability/intent?
>
> ### Deliverable
> A **layered sequencing guide** — per layer: what it contains (mapped to corrective actions 1–8
> and S1–S8), intelligence level (mechanical/analytical/oracle), human-intervention level
> (autonomous/surface-for-review/owner-ruling), and why it sits in that position incl. hard
> ordering constraints (do you agree with the assessment's two?). Then a one-paragraph bottom
> line: single next action + why. Challenge the plan where it's wrong/over-engineered/mis-sequenced.
> Do not edit files.

---

## Part B — Fable's returned guide (verbatim)

### Facts Fable verified before advising (not inferred)

- Suite baseline confirmed by running it: **815/0/0/4**.
- **A1's factual core is already answerable:** `UserInputController:_is_hidden_overlay()`
  (userInputController.lua:437) is called only from inside UIC's own handlers → Decision 2's
  letter ("no external gate") holds. But the predicate is
  `self == love.state.user_input_controller and not love.state.user_input`: hiddenness is
  *derived from global placement*, not an internal flag. Remark C is therefore not a drift
  correction but a real encapsulation-quality question with a cheap, concrete fix candidate
  (internal shown/hidden flag toggled by show/hide — the owner's own proposal at lines 422–423).
- **A2's console-mode question is already answerable:** the flagged hidden-widget tests
  (input_contracts_spec.lua:472–499) run with `app_state = 'ready'` (fixture reset,
  input_fixture.lua:291) — the console *is* the active route there; fall-through is correct and
  user-visible. The genuinely open fact is the missing **project-mode** non-leak test.
- **S1's visibility sub-question is already answerable:** `framework_handlers` appears **nowhere**
  in `doc/input_api.md` — purely internal mechanism, invisible to projects.
- **S2 is smaller than the plan implies:** `doc/input_api.md` (357 lines, the doc the PR is
  reviewed from) carries exactly **one** jargon leak — "callback slots"/"tier-3 callbacks" at
  lines 20–21. The stakeholder-facing surface is otherwise already role-named; the glossary load
  lives in code comments and internal docs.
- **The tier3 rename is tiny:** 21 occurrences, all in `src/controller/projectInputController.lua`,
  plus the input_api.md line-21 leak and one hit in `technical_debt/input.md`. Safe under any
  later S2 outcome (generic_callback is the target name regardless of whether 'tier' shrinks).
- **The fixture (verdict E) is a hybrid, not fake:** `activate_project` already calls the
  production `Controller.set_user_handlers`; the infidelity is localized — `running_project`
  installs bare `love[name]` instead of sandboxed `project_env.love` (input_fixture.lua:193),
  `show_widget` bypasses `compy.input.show` (:184), and `reset`/`reset_chain` re-implement teardown
  that the framework really provides (`stop_project_run`/`quit_project`,
  consoleController.lua:1060/1075 — the owner's suspicion is correct;
  `ConsoleController:suspend_run` also exists at :971).
- The big spec file is `tests/input/input_contracts_spec.lua`, **2210 lines**; the owner's own
  remark (line 49) frames splitting as a question, not a directive.

### The layer model

The owner's stratification instinct is right, but the current plan's "Pass-1 evidence audits,
mechanical, first" framing has two errors: (a) "mechanical" is not one layer — it splits into
mechanical-and-independent (safe now) vs mechanical-but-downstream-of-rulings (execution pass);
and (b) the opening layers are **parallel tracks, not a sequence** — the critical path runs
through the owner's one ruling sitting, and everything else should be arranged to make that
sitting happen as early and as complete as possible.

**Layer 0 — mechanical and ruling-independent (parallel track, start anytime).**
Contains: `tier3 → generic_callback` rename incl. the input_api.md line-21 leak (item 4);
ledger entries for the open design/debt questions (item 5). Intelligence: mechanical — Sonnet
with grep+LSP sweep. Human intervention: autonomous (the rename is a standing owner instruction
acknowledged and ignored — the "go" already exists; executing it is compliance, not a new
decision). Why here: zero dependency on any ruling; safe under every S2 outcome; removes the
single jargon leak from the stakeholder-facing doc. **Not in this layer despite being
mechanical:** the badspecref mapping application (item 7 — needs mapping approval, and its
targets include `internals/user_input.md`, which is provably stale and pending a rewrite-or-
supersede ruling) and the spec-file split (see Layer 3).

**Layer 1 — evidence completion (parallel track, analytical/Opus, days not weeks).**
Contains: the *residue* of A1/A2/S1/S7 after this consultation — much less than the plan
budgets: A2's project-mode non-leak probe (write it against the already-real `activate_project`
path, not `running_project`); the S1 fold-into-UIC impact sketch (hook ordering, R9 veto, D-a's
"deactivate is route policy" — the visibility half is done); the S7 fixture census as a
helper→real-path mapping table. Do **not** hand A1 to Sonnet as a binary audit — the answer is
"letter satisfied, spirit violated," and a Sonnet pass reporting "no Decision-2 violation found"
would bury the owner's actual point. A1's deliverable is a ruling-sheet row with the internal-flag
fix as a costed option. Human intervention: autonomous execution, output surfaced for review.

**Layer 2 — THE RULING SITTING (the human apex; single event, not drips).**
Contains: one consolidated sheet, one sitting: S1 (keep-with-justification vs fold — the
visibility fact makes "keep, internal mechanism" cheap; folding is a design.md §9 amendment plus
rework of green code); S2 scope (now mostly a code-comment question); the A1 internal-flag fix
(recommend approve — dissolves remark C with a tiny testable change); S6 concept (should
hidden-widget input fall through to console in *project* mode — evidence from Layer 1); the 9
standing rulings + C1/C2; the badspecref mapping approval; the `user_input.md` rewrite-now-vs-
mark-stale scope call (input_api.md's "See also" points stakeholders at a doc that still describes
the deleted mechanism — touches the reviewability gate directly); fixture-mapping approval; the
spec-file split yes/no; disposition of the stale REVIEW remarks below the L604 stop-boundary.
Intelligence: oracle-scale preparation, owner decision. Human intervention: owner-ruling-required
— the phase's entire human bottleneck, concentrated in one place. Every row pre-formatted so the
ruling text flows verbatim into the PR justification table.

**Layer 3 — execution (Sonnet-dominant, internally ordered).**
In order: (1) fixture-fidelity pass per the approved mapping (item 6); (2) test
additions/deletions from rulings — project-mode non-leak test, A1 flag fix + its test, any
S6-driven rewrite of the "console as hidden sink" prose/cases; (3) approved simplifications as
focused commits; (4) badspecref mapping application (item 7) — after any corpus doc changes;
(5) **spec-file split now, if approved** — this late, because splitting first would scatter the
conceptual REVIEW remarks that are Layer-2 inputs and double the churn; (6) slice regeneration
(item 8) — **last**, agreed unconditionally. Intelligence: mechanical with analytical
review-gates on (1) and (3). Human intervention: surface-for-review on fixtures and
simplifications; autonomous for the rest.

### The three questions, head-on

1. **Mechanical first?** Only the ruling-independent half (rename, ledger) — and as a *parallel*
   Sonnet track, not a prerequisite. The badspecref application and the file split are mechanical
   but ruling-downstream; front-loading them is the mistake the owner smelled. The split
   specifically is a distraction now and a good idea later.
2. **Tests second?** The assessment's constraint — fixture fidelity before rulings that *cite
   green tests as evidence* — is correctly scoped and kept. But it gates less than it appears: S2,
   S4, S5, S8 need no tests; S1/S6 *rulings* rest on design judgment plus evidence sketches, only
   their *validation* legs need the scaffold. So fixtures go early in Layer 3, not before Layer 2.
   Write A2's project-mode test against `activate_project` (already real) so it doesn't inherit
   the infidelity it exists to rule out.
3. **Sufficient base for the stress-test?** Yes — more than sufficient: half the stress-test's
   evidence is already in hand, which is exactly why the ruling sitting should be pulled *earlier*.

### Where Fable would amend the three-pass plan

Keep the skeleton (evidence → one ruling sheet → execution) — the consolidated single sitting is
its best idea. Amend three things: (1) Pass 1 is over-budgeted and mis-typed — A1/S1/S2 answerable
by direct inspection (done), A1 is analytical not a Sonnet audit; (2) "mechanical first" should be
dissolved into a parallel track (rename/ledger) plus a late execution slot (badspecref, split);
(3) add two missing ruling-sheet rows: the `user_input.md` staleness/scope call and the below-L604
stale-remark disposition. Both hard ordering constraints (fixtures before test-citing rulings;
slices last) are correct as stated.

### Bottom line

The single next action is to **draft the Pass-2 consolidated ruling sheet now** — embedding the
evidence already verified (A1, S1, S2, A2 above) and marking only the genuinely pending items
(project-mode probe, S1 fold-cost sketch, fixture census table), while a Sonnet agent runs the
tier3 rename in parallel. The owner's sitting is the critical-path bottleneck of this entire
phase; the current plan defers it behind an evidence pass that is one-third already done and
one-third mis-classified, and every day the sheet doesn't exist is a day the Layer-3 execution
queue can't start.
