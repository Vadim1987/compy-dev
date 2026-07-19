# session12 — prompt (validation-phase: plan-refinement judgement)

_Handover from session11 (Opus, 2026-07-19). Boot per `agents/validation.md` ritual: read it,
create `session12/track.md`, confirm baseline **815/0/0/4**, read predecessor
`session11/track.md` end-to-end._

## Model & role

**Run this session on Fable.** Per the owner (2026-07-19), plan architecture is the judgement
tier — the expensive wisdom oracle, not mechanical work. Your job is **cognitive**: read
evidence, exercise judgement, propose a plan revision on disk. **No code edits, no test
edits, no sub-agent sweeps** this session. (Standing model economy still holds for anything
mechanical you might delegate — Sonnet, explicit `model`, hygiene a/b/c — but you likely won't
need to spawn at all.)

## Your mandate — a judgement, not execution

Session11 ran **Phase A** of `validation/plan.md` (mechanical integrity) and stopped there on
owner ruling ("do not rampage into Phase B"). You **inspect the Phase A outcomes + the owner's
attestations and decide how to refine `validation/plan.md`** — its expansion/adjustment is your
deliverable. You do **not** execute the new phases; you design them for owner ratification.

### Read first (evidence)

1. `validation/notes/2026-07-19-owner-post-phaseA.md` — the owner's attestations and proposed
   plan direction. **This is your primary input.**
2. `validation/outcomes/A1-spec-ref-sweep.md` — the ~55-reference inventory (what has no
   persistent home; "doc A" dominates).
3. `validation/outcomes/A2-test-fidelity.md` — the 1 fix + 2 judgement-required findings.
4. `validation/plan.md` — the plan of record you are refining (Phases A–G). A2's judgement
   findings are Phase-C-bound; don't lose them.
5. The current `doc/input_api.md`, `doc/development/internals/user_input.md`, and the target
   `doc/development/wip/77-new-input-api/notes/input-contracts.md` ("doc A") — enough to judge
   whether promoting doc A is sound and what "validate it first" concretely entails.

### The owner's proposed direction (to evaluate & materialize, not rubber-stamp)

The owner proposes **gating the current Phase B (convergence check) behind a new
doc-integrity + test-fidelity sequence**. Candidate phases (owner's, in order):

1. Check status/fidelity of **doc A** vs shipped code; **consider promotion** to persistent corpus.
2. **Re-run the A1 comment sweep** to retarget the inventoried refs at the promoted doc (if promoted).
3. **Split the big spec** (`tests/input/input_contracts_spec.lua`) for human review.
4. **Owner human-review** of the split suite for further infidelity hints.
5. Evaluate hints → **re-run the test-fidelity check** over them.
6. **Triage any escalations** discovered.
7. Only once **doc-integrity AND test-fidelity** are achieved → proceed to (current) Phase B.

Your judgement: is this the right shape? Right ordering (note the owner's own coupling —
split *after* comment normalization; promotion *before* re-sweep)? Are steps missing, mergeable,
or over-elaborate (the "more predictable vs more elaborate" test applies to the *plan* too)?
Where does doc-A validation actually belong relative to the existing Phase B convergence check
(overlap? is convergence-check partly the same work)? What are the owner-gated decision points?

### Deliverable

A **plan-revision proposal** materialized on disk: either amend `validation/plan.md` in place
(preferred if the change is clean) or write a superseding revision under
`implementation/reviews/` cross-linked from `plan.md` (per the FOUNDATION convention). Present
it to the owner as a proposal — **the owner ratifies plan changes** (design/plan revisions are
owner-gated). Record your reasoning; capture any Fable-consult verbatim on disk if you spawn one.

## Standing facts / cautions

- Suite baseline **815/0/0/4** — the only unprompted re-check. Do NOT re-run the sweep or
  re-verify the feature.
- **Git:** commit locally at discretion (owner grant, bottom of `agents/validation.md`) —
  unit-sized, conventional-commits, noted in track. NEVER push. Never sweep the owner's
  unrelated working-tree changes (e.g. `compose.yml`, in-code `REVIEW:` remarks) into commits.
- **Artifact locations (new rule, `agents/validation.md`):** session dir = prompt/track/report
  only; notes → `validation/notes/`, sub-agent prompts → `validation/prompts/`, sub-agent
  outcomes → `validation/outcomes/`; cross-session judgement docs → `implementation/reviews/`.
- **Sequence sub-agents; no parallel worktree isolation** (rule d, `agents/validation.md`) — it
  polluted the lua-lsp workspace and triggered luarocks self-provisioning. Serial in `/repo`.
- Verify factual claims (any oracle's, any sheet cell's, doc A's) **in code** before relying:
  LSP for symbols (`sleep 1` after `.lua` edits before refs/diagnostics), grep as completeness
  backstop. Two verdicts were overturned this way already.
- `design/` frozen (history); design challenges go through Phase C/D as proposals. `wip/77`
  deletion owner-gated.
- **Do NOT start Phase D** (interactive owner sitting) unprompted. And per this handover, do NOT
  start Phase B execution — your output is the refined *plan*, for the owner to approve first.
