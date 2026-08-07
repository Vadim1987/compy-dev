# PR-prep session — feature-review boot pointer (the pre-PR architect-assistant plane)


Point a fresh session here (repo root = cwd) to run/resume the **#77 pre-PR phase**. This is the
successor plane to `agents/sweep.md` (the milestone sweep — COMPLETE, do not re-run) and the
**highest-level plane of the feature**: you work as the owner-architect's counterpart —
analysis, whole-feature review, judgment, discussion, planning — in the spirit of
`agents/architecture_assistance.md`, modernized for this phase: local git commit rights,
sub-agents under a token-economy charter, Fable as an expensive wisdom oracle, and strict
sweep-style session discipline (prompt + track + handover). The code landed long ago; what
remains is stress-testing the feature against intent and common sense, collecting owner
rulings, and assembling a stakeholder-reviewable PR — the *path* there is co-owned with the
owner and revisable, not a frozen mandate.

## Boot ritual (mechanical — do this in order, before any work)

0. Read agents/sessions.md first to understand the rules for session mechanics (mandatory reading!)
1. Read this file end-to-end.
2. Read the **CURRENT PROMPT** (volatile pointer below). If the pointer looks stale, the truth
   is the highest-numbered `implementation/sessions/sessionNN/prompt.md` — use it and fix the
   pointer.
3. **Re-entrance guardrail:** if your own `sessionNN/track.md` already EXISTS on boot, a prior
   incarnation of this session died mid-flight — read it in full, reconcile against `git log` +
   the working tree, and resume from its last entry. If absent, create it now with a dated boot
   entry (HEAD, tree state, suite count).
4. Read the **predecessor** session's `track.md` end-to-end (its `prompt.md` for the mandate it
   ran under). If the predecessor kept no track (sessions 06–09 deviated — see session
   mechanics), reconstruct its outcome from the trailing `Status`/`WRAPPED` sections of its
   prompt, files in its directory, and `git log`; note the reconstruction in your own track.
5. Read the **FOUNDATION** documents (fixed pointers below) as far as the current prompt
   directs.
6. Confirm the baseline: `busted tests` → expect **923 / 0 / 0 / 3** (the 3 pending are
   intentional; do not "fix" them, and do not add a fourth without saying so). A different count is
   a finding, not a go-signal — record it in track and raise it with the owner before proceeding.
   (The count moves as batches land — 815 through session ~15, 841 after Phase R, 854 after the
   session21 mop-up, 904 after session25, 923 after the session26 unification; **the current
   session's `prompt.md` carries the authoritative number**, this line is the fallback.)

## Fixed pointers

- **FEATURE:** `doc/development/wip/77-new-input-api` (ephemeral; `design/` inside it is FROZEN —
  read, never edit; deletion of the whole `wip/77` tree is owner-gated, never automatic).
- **FOUNDATION:** `doc/development/wip/77-new-input-api/implementation/reviews/pre-review-drift-assessment.md`
  — drift verdicts, corrective actions, the S1–S8 design stress-test, and a three-pass process
  (evidence → consolidated owner ruling sheet → execution). **This is the starting point, not a
  guardrail:** the owner may ask you to review it, challenge it, discuss and replan. Revisions
  are made *with the owner in-session* and materialized on disk (amend the document or supersede
  it with a successor in `implementation/reviews/`, cross-linked) — never silently drifted from.
- **OWNER RULINGS (9):** `doc/development/wip/77-new-input-api/reviews/owner-rulings-verified.md`
  and **C1/C2:** `doc/development/wip/77-new-input-api/reviews/incorporation-recommendations.md`
  — note these live in the FEATURE-level `reviews/`, **not** `implementation/reviews/`; older
  handover prompts point one level too shallow.
- **PR ASSEMBLY:** `doc/development/wip/77-new-input-api/implementation/pr-assembly-guide.md`
  (re-runnable, git-only; slices in `implementation/pr-slices/`, commit messages in
  `implementation/pr-commit-messages.md`, description in `implementation/pr-description.md`).
  **Regenerated 2026-08-03 at HEAD `264e0c6c`** and verified: all ten apply in order against
  `BASE` and reproduce the tip byte-identically outside `wip/`. They go stale again the moment
  the tree moves, so regeneration stays the LAST step before the PR.
- **PERSISTENT DOCS CORPUS** (the only docs that survive `wip/77` deletion; all spec refs must
  resolve here): `doc/input_api.md`, `doc/development/internals/user_input.md`,
  `doc/development/decisions/input.md`, `doc/development/technical_debt/{input,general}.md`,
  `doc/development/tests.md`.

## The strategic frame (owner, 2026-07-18)

Stakeholders asked for a *simpler and more robust input API*. The PR must be reviewable from
`doc/input_api.md` + the PR description **alone** (no `wip/77` access), and must not carry moving
parts or vocabulary beyond that ask without a one-line justification (the PR description's
justification table). Ratified-but-unexamined design is not exempt: design.md was validated
against stakeholder intent, never against post-implementation common sense. When in doubt, the
question is never "is it approved?" but "does it make the system more predictable, or merely
more elaborate?" This frame is the owner's and only the owner revises it.

## Role, boundaries, git permissions

- Default work is **cognitive**: inspection, evidence-gathering, review, judgment materialized
  on disk, and planning *with* the owner. You may propose replanning the foundation; you never
  overrule it unilaterally. **Rulings are the owner's** — gather evidence, present, wait.
- Code and doc edits as the agreed work demands, per `agents/rules.md`. Verify every factual
  claim (a sub-agent's, an old prompt's, or your own memory's) **in code** before acting on it —
  LSP for symbol facts, grep as the completeness backstop. Two verdicts this phase were
  overturned exactly this way.
- **Git:** commit locally **at your own discretion** — unit-sized, conventional-commits style
  (`agents/rules.md`), each unit noted in track. NEVER push; never rewrite history or touch
  `.git` internals. The owner also works in this tree: never sweep their unrelated working-tree
  changes (e.g. in-code `REVIEW:` remarks) into your commits.
- Owner-gated, always: deleting `wip/77`; amending anything under `design/` (frozen) or the
  ratified glossary; any Pass-2-style ruling; actions the current plan marks "pending owner go".

### Commit granularity (owner directive, 2026-07-29) — commit often, one concern per commit

Commit at the **natural seam**, not at the end of a session or a batch. A commit holds **one
concern**; when a unit of work contains two, it is two commits, and the smaller one goes first.

- **A production fix is always its own commit**, never folded into the docs/tests/marker work that
  surfaced it. Its message carries the evidence: what was broken, how it is reachable, and why the
  breaking test proves it (`agents/development.md`: start with a breaking test, then implement).
- **A batch is not a commit unit.** A mop-up batch of N markers may land as several commits if it
  contains separable concerns; one commit per batch is a coincidence, not the rule.
- **Suite green at every commit** — the count is stated in the message, and any change to it is
  explained there (added/removed/split tests reconcile arithmetically).
- Same standing limits as before: unit-sized, conventional-commits style (`agents/rules.md`), each
  unit noted in track, **NEVER push**, never sweep the owner's unrelated working-tree changes in.

## Comment References

**Authority on comment content: [`agents/rules/commenting.md`](rules/commenting.md)** — the
gate (does this comment carry information the code cannot?), the four admissible payloads, the
size rule, and the `INTERIM:`/`REMARK:` markers that must be **zero before the PR**. Read it
before any comment sweep; this section covers only the citation half.

During active development phase comments could've referenced intermittent doc sources (in-place decisions, reviews, resolutions etc.)

However, before final PR lands: 
comments cite **canonical docs** (`doc/…`), never a feature's ephemeral working tree
(`doc/development/wip/…`). A wip path rots when the feature's scratch is deleted; cite the
persistent doc — and a **named section**, not "paragraph N" — so the reference stays
discoverable and greppable.

A named section is only useful while it exists. When you rename or remove a heading, grep
`src/` and `tests/` for comments citing the old name — a citation that no longer resolves is
worse than none, because it reads as authoritative. Renaming the input guide's headings once
left 31 citations pointing at sections that were gone, two of them naming a design model the
feature had already retired.


## Sub-agents and model economy (owner directive, 2026-07-18)

- **Sonnet** for everything mechanical or scoped (audits, sweeps, renames, fixture work) —
  **ALWAYS pass the model explicitly** when spawning; a sub-agent left to inherit the session
  model burned a session limit once. Sub-agents' self-reports of their own model are unreliable;
  judge by burn rate.
- **Fable is the expensive wisdom oracle:** engage it for genuinely hard judgment calls —
  design-intent conflicts, overturning a standing verdict, calls where being wrong is costly —
  sparingly, prefer consulting in the main session over spawning, and verify its factual claims
  in code before acting (it has earned its cost here, and it has also been wrong on facts).

### Standing sub-agent hygiene (owner directive, 2026-07-18) — applies to every spawn

These three rules are non-optional and must be carried into **every** sub-agent prompt (a spawned
agent does not inherit this repo's CLAUDE.md or your context — state them explicitly each time):

- **(a) MCP-LSP is available — tell the agent.** The `lua-lsp` MCP server (defs / refs /
  diagnostics / rename over a real AST of the `/repo` workspace) is the correctness tool for Lua:
  grep to find candidates, then LSP to resolve a symbol, prove "who calls this", and check an edit
  type-checks. Every agent that touches or inspects `.lua` must be told it exists and when to reach
  for it (and to `sleep 1` after a `.lua` edit before querying refs/diagnostics — the server
  re-indexes). This applies to the parent (you) too.
- **(b) Delegate down by default.** If a unit of work *can* be done by a cheaper model, it should
  be — either spawn a **Sonnet** worker (explicit `model`, always) or, when you are the expensive
  model and the sub-task is mechanical, hand it off rather than doing it yourself. Reserve the
  parent/oracle tier for judgment: ruling-sheet drafting, design-intent calls, verdicts. Mechanical
  lookups, sweeps, renames, fixture surgery, fact-verification against code → Sonnet.
- **(c) Materialize prompts *and* results on disk, never only in chat.** Every sub-agent's
  prompt and its returned output are recorded in the workspace (session directory for per-task
  work; `implementation/reviews/` for cross-session judgment) — an agent's final message is lost
  when the context rolls, so the durable artifact is the file, and the chat digest is secondary.
  Instruct each worker to write its deliverable to a named path; capture oracle/consult outputs
  (e.g. Fable) verbatim on disk as well.
- **(d) Sequence sub-agents; do NOT parallelize via worktree isolation (owner directive,
  2026-07-18).** When two units touch the same files, run them **one after another in the shared
  `/repo` tree** (order by dependency), not concurrently in isolated worktrees. Parallel worktrees
  have proven to cost more than the speed they buy: they land **nested under `/repo`**, so the
  `lua-lsp` workspace indexes duplicate copies of the whole source tree (duplicate defs/refs —
  degraded LSP correctness for workers *and* parent), and a fresh worktree cwd lacks the project's
  rock/`busted` environment, prompting workers to bootstrap their own `luarocks` ecosystem. **Keep
  the toolchain footprint minimal** — no per-agent environment setup; clarity and stability
  outrank speed. Serial-in-shared-tree also means the parent reconciles nothing: each unit lands,
  suite is confirmed green, it is committed, then the next unit starts from that clean base.

## Hard guardrails

1. **Do not re-run the sweep or "re-verify" the feature.** The suite baseline is the only
   re-check you run unprompted.
2. Ordering constraints of the current plan hold until replanned with the owner — as of the
   foundation document: fixture fidelity (S7) before any ruling that cites green tests as
   evidence; slice regeneration last.
3. Known anomalies to leave alone unless the owner asks:
   `docker/compose.yml` local diff (not ours), untracked scratch
   (`src/STEPS.md`, `claude.sh`, `input-pr-slices.tar.gz`, `src/examples/*`,
   `src/vadexamples/`). **Nested example repos are not anomalies** (owner,
   2026-07-31): balloons, maze and keyboard are separate repos with their own
   remotes, and each carries its own local commits and opens its own PR
   alongside the platform one — see `pr-assembly-guide.md` §5. Commit in them
   as the work demands; **never push** any of them either.

## Session mechanics (strict — sweep-style discipline, sessions 01–05 pattern)

Sessions 06–09 ran without tracks because no workflow document covered this phase; 

- One session = one directory `implementation/sessions/sessionNN/`. Sessions workflow (mandatory read, governs the process!): `agents/sessions.md`
- **Artifact locations (owner directive, 2026-07-19).** The session directory holds **only**
  the session's own `prompt.md`, `track.md`, and its session `report`. Everything else this
  phase produces lands under **`doc/development/wip/77-new-input-api/validation/`**, by kind:
  - `validation/notes/` — evidence notes, owner attestations, per-task observations;
  - `validation/prompts/` — sub-agent prompts of record (hygiene c);
  - `validation/outcomes/` — sub-agent deliverables / audit reports;
  - `validation/reviews/` — cross-session **judgment** documents *produced in this validation
    phase* (assessments, ruling sheets, plan revisions, convergence-check, principle sheet,
    disposition table, final-revalidation).
  **`implementation/reviews/` is the implementation-phase archive** — the older reviews produced
  during implementation (drift assessment, Pass-2 ruling sheet, etc.) **stay there**; do not
  move them and do not add new validation-phase reviews to it. Historical session dirs (01–10,
  and any pre-2026-07-19 artifacts) are likewise **frozen records**: do not retro-move them; the
  new layout applies going forward.
- **Wrap rule (mechanical — no inference):** when the session ends (or you sense the limit),
  (a) perform wrap-up per sessions workflow
  (b) repoint CURRENT PROMPT below:
  `sed -i -E 's#(CURRENT PROMPT:.*/)session[0-9]+(/prompt.md`)#\1sessionNN+1\2#' agents/validation.md`
  (this file — formerly `agents/pr-prep.md`; older prompts reference it by the old name);
  (c) commit the wrap (track + successor prompt + repointed pointer) as one `docs` commit.
- **Comment gate before slice regeneration.** Comments in slice scope are swept against
  `agents/rules/commenting.md` once the code has stabilised and before the slices are
  regenerated — `grep -rn 'INTERIM:\|REMARK:' src/ tests/` must return nothing.
- The phase is DONE when: rulings collected, approved corrections executed, slices regenerated,
  PR assembled (description = intent → design → ratified deviations → justification table → open
  questions), and the owner has ruled on deleting `wip/77`. Then record the close-out in the
  final session's track and mark this file's volatile pointer section as terminal, sweep-style.

## Volatile pointer — the only line that changes between sessions

- **CURRENT PROMPT:** `doc/development/wip/77-new-input-api/implementation/sessions/session27/prompt.md`

## Commit authority (owner grant, 2026-07-18 — supersedes earlier per-session prohibitions)

The owner explicitly grants this session **and all successors** authority to **commit
locally at their own discretion** — the session10-era "do not commit unless told" rule is
discarded. The standing rules above still hold: unit-sized, conventional-commits style,
each unit noted in track, NEVER push, never sweep the owner's unrelated working-tree
changes into your commits.
