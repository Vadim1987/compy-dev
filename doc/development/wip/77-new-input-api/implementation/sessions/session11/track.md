# session11 — track

## Boot — 2026-07-18

- HEAD: `01351c7` (session10 wrap — pivot to principle-level plan, grant commit authority).
  Tree carries owner scratch + known anomalies (`agents/validation.md` guardrail 3).
- Suite baseline confirmed: **815 / 0 / 0 / 4** (4 pending intentional). Go-signal.
- Model: Opus. No prior `session11/track.md` existed — clean boot, no mid-flight death.
- Read in order: `agents/validation.md`, `session11/prompt.md`, `session10/track.md`,
  `validation/plan.md`. Mandate: execute `validation/plan.md` from Phase A.
- Re-entrance guardrail: N/A (fresh boot).

## Plan of record

`validation/plan.md`, Phases A→G. Start Phase A (A1 spec-ref sweep, A2 test-fidelity audit —
Sonnet workers, explicit model, hygiene a/b/c). B = convergence check (Opus, no code edits).
C = principle sheet + disposition table. **D = interactive owner sitting — do NOT start
unprompted; notify owner when C is ready.**

## Units of work

### Phase A — spawned 2026-07-18 (Sonnet workers, worktree-isolated, parallel)

Ran A1 + A2 in parallel but **worktree-isolated** (not shared-tree): both write under
`tests/`, so a shared `/repo` would race. Each in its own git worktree off HEAD `01351c7`;
Opus reconciles the two diffs back (A1 = comment lines, A2 = test bodies → different lines,
merges cleanly). Both Sonnet, explicit `model`, hygiene a/b/c. Prompts of record:
`subagent-A1-prompt.md`, `subagent-A2-prompt.md`.

- **A1** spec-reference sweep → report `spec-ref-sweep.md` (edits + inventory of no-home refs).
- **A2** test-fidelity audit → report `test-fidelity.md` (mechanical fixes + Phase C list).

Status: **ABORTED before completion (owner directive, 2026-07-18).** Parallel worktrees landed
nested under `/repo` (`/repo/.claude/worktrees/...`) → lua-lsp workspace indexed duplicate
source copies (degraded refs/defs), and the fresh worktree cwd lacked the rock/busted env, so
the Sonnet workers tried to self-provision `luarocks` (owner refused two such requests).

Owner ruling: **sequence sub-agents in the shared tree; do not parallelize via worktree
isolation.** Clarity/stability > speed. Written into `agents/validation.md` hygiene rule **(d)**.

Actions taken: stopped both agents (TaskStop); `git worktree remove --force` both; deleted
their `worktree-agent-*` branches; `git worktree prune`. Tree back to single worktree
`/repo` @ `01351c7`; suite re-confirmed **815/0/0/4**. No edits from either agent were kept
(their worktrees discarded) — A1/A2 re-run from scratch, **serially in `/repo`**.

### Phase A — re-plan (serial in shared tree)

Next: run A1 (spec-ref sweep) as a single Sonnet worker in `/repo`; land + verify + commit;
then A2 (test-fidelity) from that clean base. Prompts of record already on disk
(`subagent-A1-prompt.md`, `subagent-A2-prompt.md`) — reuse, minus the worktree framing.

**A1 spawned (serial, shared `/repo`, Sonnet)** — 2026-07-18, after commit `0056e28`.
Added an explicit "do not self-provision luarocks / do not git add/commit" clause. Report →
`spec-ref-sweep.md`. Status: **DONE + committed `801ad4f`**.

**A1 outcome** — ~150 comment citations retargeted to real corpus sections; ~55 inventoried
as having no persistent home (**dominated by "doc A" = the frozen wip contract record
`wip/77-.../notes/input-contracts.md`, no persistent mirror** — key Phase C evidence), plus
milestone marks / review-doc / process-artifact refs. Verified before commit: diff is
comment-only in all 13 `.lua` files (grep found zero non-comment added lines); added lines
≤64 chars; sampled cited sections resolve; `{jargon:}` tags + owner `REVIEW:` remarks left
untouched; owner `compose.yml` + scratch excluded from the commit. Suite 815/0/0/4 throughout.
Report: `validation/outcomes/A1-spec-ref-sweep.md` (moved from session dir — see reorg below).

**A2 spawned (serial, shared `/repo`, Sonnet)** from clean base `801ad4f` — test-fidelity
audit. Report → `test-fidelity.md`. Status: **DONE + committed `912a2cd`**.

**A2 outcome** — 1 mechanical fix: `input_contracts_spec.lua:468` `hide deactivates the
widget` asserted only the routing side-effect, not the widget's own state → added
`assert.is_false(F.singleton:is_shown())` via the real `UserInputController:is_shown()`
(confirmed real at `userInputController.lua:451`). Verified diff is exactly +1 line. Suite
815/0/0/4 (assertion into existing test, no new test). 2 judgment-required findings → Phase C
(the `#disputable` global-shortcut tests: they DO drive real production code, so the issue is
fixture architecture — ad hoc state manipulation vs a fixture-provided path — not
reimplementation smell; each needs an owner ruling). Also closed a REVIEW (line 321): click
detection is `app_state`-independent (`controller.lua:646-680`), so the existing
`F.set_compy_handler` path is correct, `running_project` would be wrong. Report:
`validation/outcomes/A2-test-fidelity.md` (moved from session dir — see reorg below).

## Phase A — COMPLETE (2026-07-18)

Both mechanical-integrity units landed serially in shared `/repo`, each verified + committed:
A1 `801ad4f`, A2 `912a2cd`. Suite green 815/0/0/4. Phase C evidence accumulating:
- A1 inventory: ~55 no-persistent-home refs (chiefly "doc A" = frozen wip contract record).
- A2 judgment queue: 2 fixture-architecture rulings on the `#disputable` global-shortcut tests.

## Post-Phase-A owner ruling + reorg (2026-07-19) — Phase B NOT started

Owner reviewed A1/A2 and ruled **do not rampage into Phase B**. Instead:

1. **Artifact reorg (committed `8888d7d`).** New rule in `agents/validation.md`: session dir =
   prompt/track/report only; notes/prompts/outcomes → `validation/{notes,prompts,outcomes}/`.
   Moved A1/A2 prompts → `validation/prompts/`, reports → `validation/outcomes/`.
2. **Owner attestations recorded** → `validation/notes/2026-07-19-owner-post-phaseA.md`:
   - "doc A" (`notes/input-contracts.md`) likely belongs in the persistent corpus, but was
     built as *pre-implementation evidence of undocumented behaviour* — must be checked for
     fidelity vs shipped code **before** promotion.
   - Only 1 test-fidelity fix ⇒ smells likely **missed**; owner will personally re-inspect the
     suite, but that needs the big spec **split** first, ideally **after** comment normalization.
3. **Successor commissioned (Fable).** Not execution — a **judgement on refining `plan.md`**:
   evaluate inserting doc-integrity + test-fidelity phases (doc-A validate→promote; re-run A1
   sweep to the promoted doc; split big spec; owner human-review; re-run fidelity on new hints;
   triage escalations) as a **gate before the current Phase B**. Deliverable = plan
   expansion/adjustment proposal. Handover: `session12/prompt.md`.

## Close-out (session11, Opus, 2026-07-19)

- **Done:** Phase A (A1 `801ad4f`, A2 `912a2cd`); artifact reorg + rule (`8888d7d`); owner
  attestations note; this wrap.
- **Suite:** 815/0/0/4 (unchanged; last confirmed post-A2).
- **Carryover (all in `session12/prompt.md` + `validation/notes/2026-07-19-owner-post-phaseA.md`):**
  Fable plan-refinement judgement → then the gated doc-integrity/test-fidelity sequence → then
  Phase B convergence check (still pending; known shipped-API deviations to confirm live:
  `eval`/`result` keys, `multiline` promised-not-shipped, silent config-key drop) → C/D/E/F/G.
- **Owner-gated queue unchanged:** Phase D sitting; any design-tweak/jargon rulings; `wip/77`
  deletion.

WRAPPED 2026-07-19 → handover: ../session12/prompt.md
