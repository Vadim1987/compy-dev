# Code review — M4-0 characterization net + harness extension

## Fill these in

- **Milestone under review:** `M4-0 — characterization net + harness extension`
- **Spec (authoritative):** `doc/development/wip/77-new-input-api/design/spec/M4-0-characterization-net.md`
- **Outcome to review:** `doc/development/wip/77-new-input-api/implementation/outcomes/M4-0-characterization-net.md`
- **Commits:** the hashes the outcome lists (review the **diff**, not just the prose).

## Milestone-specific review notes (read before the generic checklist)

M4-0 is a **characterization + test-harness** slice, not a behaviour-changing one — adjust the generic
"re-verify red-before" expectation accordingly:

- **Oracle = current runtime behaviour** (organically grown, no spec). Characterization tests are
  **green against current code**, *not* red-first. So instead of "red-before", verify **teeth** the
  M4-0 way: confirm the outcome's **perturb→red→restore** records are real — re-do at least one
  yourself (temporarily break the pinned behaviour, see the test go red, restore). A characterization
  test that stays green when its pinned behaviour is broken is toothless — flag it.
- **The one forward test must be `pending`, not failing.** Confirm the `isrepeat`-arrives assertion is
  carried as a busted `pending(...)` with a greppable `DEFERRED (0.1.0-m4)` marker (it flips to live in
  M4). If it is a hard-failing test (reds the suite), that is a finding.
- **P1 — order independence.** Confirm **no** test encodes keypressed→textinput *ordering* as an
  invariant, and that `textinput` is driven through the installed `love.handlers.textinput` (not a
  direct `controller:textinput(...)` call — the A8 anti-pattern).
- **Harness base.** Confirm `tests/helpers/input_session.lua` is built on the **raw-handler pattern**
  (`keys_pressed_spec`: real handlers via `setup_callback_handlers`, driving `love.handlers.*`), **not**
  an `EditorSession` generalisation; and that `tests/helpers/editor_session.lua` is **unchanged**.
- **No production code change.** The diff must touch only `tests/`. Any `src/` change is a scope breach
  (and a signal the behaviour wasn't characterizable black-box) — flag it.

## You are

An independent reviewer of one implementation slice in the **compy** LÖVE2D codebase (this repo, root =
your cwd). You did **not** write this code. Judge the **diff + the outcome ledger** against the spec,
the project rules, and reality (run what you can). You **do not** rewrite feature code; you produce a
verdict and findings. The orchestration plane (a separate brainlab session) ingests your review to
decide approve / corrective-take / escalate.

## Read first

1. The **spec** (filled above) — **authoritative**: its Scope, Part A/B, the one forward assertion, and
   Acceptance are the bar.
2. The **outcome ledger** (filled above) — what the implementer claims (commits, files, harness shape,
   coverage, verification, surfaced gaps). Treat claims as **to be verified**, not trusted.
3. **`agents/rules.md`** + **`agents/development.md`** — the repo's compiled ruleset (hard limits:
   64-char lines, 14-line bodies, 4 params, 4 nesting; formatting; "no C accent"; conventional commits)
   and working rules (tests-first; KISS; **report-don't-fix** discovered debt). Auto-loaded via the
   repo-root `CLAUDE.md`.
4. The **diff** — `git show <hash>` / `git diff <base>..<head>` for each commit. Read the actual change.

## Do — verify, don't trust

1. **Spec compliance, item by item.** Part A (driver + the two `mock` emitters), Part B (each pinned
   flow/example), the one forward `pending`, and each Acceptance bullet — met or not? Cite file:line.
   Where coverage was claimed, confirm the assertion actually drives the real surface, not a stub.
2. **Re-run the tests yourself.** `busted tests` (or `just ut_all`). Confirm the counts the outcome
   claims (green + exactly one pending). Re-do at least one **perturb→red→restore** teeth check (see the
   milestone-specific notes above). Note any characterization test that passes for the wrong reason.
3. **Scope fence.** Diff touches only `tests/` (driver, mock, characterization spec, outcome ledger).
   Flag any `src/` change or reach into downstream milestones. Confirm `editor_session.lua` unchanged.
4. **Rules check.** Hard limits, formatting, "no C accent", commit hygiene (conventional subjects;
   committer identity unchanged).
5. **Tech-debt tracking — check AND correct it.** Every gap the outcome surfaced (and every one you
   find — e.g. a flow that could **not** be characterized) must be logged in
   `doc/development/wip/77-new-input-api/implementation/technical_debt.md` with a disposition
   (**planned** → adjacent spec / **accepted** / **anticipated** / **open**). Note especially any
   un-characterizable flow — it is an input to the M4 black-box-vs-escalate call. You may edit this
   ledger directly. Keep the persistent/interim boundary honest.
6. **Dev documentation — check it was updated.** If the harness adds a reusable capability (the driver,
   the new `mock` emitters), `doc/development/tests.md` should reflect it. If not updated where it
   should be, that is a finding. Keep milestone ref-ids out of doc prose.

## Write the review

Write **`doc/development/wip/77-new-input-api/implementation/reviews/M4-0.md`**:

- **Verdict** — *approve* / *corrective-take needed* / *escalate*; plus an explicit **approval-scope
  note** (what the evidence establishes vs. what remains an open gate).
- **Spec compliance** — per Part A/B item + the forward pending + Acceptance, with file:line and ✔/⚠/✗.
- **Teeth** — the perturb→red→restore re-checks you ran.
- **Scope fence** / **Rules check** / **Coverage gaps** — findings with severity; call out any
  un-characterizable flow explicitly (it feeds the M4 escalate-vs-black-box decision).
- **Tech-debt + docs** — what you logged/corrected, and the doc-update verdict.

## Boundaries

- **Do not edit feature code or the design specs.** You may edit only the **review** you write and the
  **interim debt ledger** (`implementation/technical_debt.md`) — and only to keep tracking honest.
- If you cannot run the suite (no dev image), say so explicitly and scope your verdict to static
  review; do not fabricate a test result.
- When done, present a short verdict summary and stop — the orchestration plane decides the next move.
