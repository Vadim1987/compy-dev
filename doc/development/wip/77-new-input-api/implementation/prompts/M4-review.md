# Code review — M4: `ProjectInputController` + overlay-gate removal

## Fill these in

- **Milestone under review:** `M4 — ProjectInputController + overlay-gate removal`
- **Spec (authoritative):** `doc/development/wip/77-new-input-api/design/spec/M4.md`
- **Outcome to review:** `doc/development/wip/77-new-input-api/implementation/outcomes/M4.md`
- **Commits:** the hashes the outcome lists (review the **diff**, not just the prose).

## Milestone-specific review notes (read before the generic checklist)

M4 is the **highest-risk integration milestone** (main dispatch path). Weight these:

- **Four-mode runtime acceptance is mandatory, not optional.** The suite does **not** cover live
  integration. The outcome must record manual verification of **REPL / editor / project+overlay /
  project no-overlay**. State precisely what each mode exercised and what it did **not**. Do not tick
  "all four modes" on a claim the evidence doesn't reach.
- **The M4-0 net must have stayed green**, and the **one forward test must have flipped `pending` →
  live green** (proof the `isrepeat`/`scancode` threading at `controller.lua:554` actually landed).
  Re-run the net; confirm. If the forward test is still pending, the regression-undo did not land.
- **Scope:** M4 is **sink delegation + gate removal + isrepeat availability** only. **Flag as a breach**
  any **M5 dispatch** work: the `handlers[isrepeat][combo]` fresh-only keying, `combo_string`
  scratch-buffer, noop-`__index`/`or`-chain. Threading `isrepeat` is in scope; *dispatching* on it is M5.
- **`{ M, C, V }` scaffolding** (read `notes/talk/build-continuity-vs-product-bc.md`): if M4 reworked
  the handle, confirm it was a **coordinated consumer sweep in this same slice** — **not** a
  narrow-ahead change (the M2 take-1 failure). If left as-is, confirm it is logged as debt.
- **D-9 native coexistence:** confirm a native-`love.keypressed` example with no `compy.*` surfaces
  (e.g. `pong`) still behaves as today via the lifecycle-split wrapper — ideally checked against the
  M4-0 D-9 characterization test.

## You are

An independent reviewer of one implementation slice in the **compy** LÖVE2D codebase (this repo, root =
your cwd). You did **not** write this code. Judge the **diff + the outcome ledger** against the spec,
the project rules, and reality (run what you can). You **do not** rewrite feature code; you produce a
verdict and findings. The orchestration plane (a separate brainlab session) ingests your review to
decide approve / corrective-take / escalate.

## Read first

1. The **spec** (filled above) — **authoritative**: Contract (activation/deactivation, gate removal,
   D-9) and Acceptance are the bar. Cross-ref `design/spec.md` §6 for the full contract.
2. The **outcome ledger** (filled above) — claims (commits, files, four-mode verification, `{M,C,V}`
   disposition, surfaced gaps). Treat as **to be verified**, not trusted.
3. **`agents/rules.md`** + **`agents/development.md`** — the repo's compiled ruleset (hard limits:
   64-char lines, 14-line bodies, 4 params, 4 nesting; formatting; "no C accent"; conventional commits)
   and working rules (tests-first; KISS; **report-don't-fix** discovered debt). Auto-loaded via the
   repo-root `CLAUDE.md`.
4. The **diff** — `git show <hash>` / `git diff <base>..<head>` for each commit. Read the actual change,
   especially the gate removal and the `:554` wrapper change.

## Do — verify, don't trust

1. **Spec compliance, item by item.** Each Contract item (activation, deactivation/restore, gate
   removed, D-9 wrapper) — met? Cite file:line. For the **runtime** acceptance, check the four-mode
   verification was actually exercised; do not tick a mode the evidence does not reach.
2. **Re-run the tests yourself.** `busted tests` (or `just ut_all`). Confirm counts. **Re-run the M4-0
   net** — it must be green and the forward test now live-green. Confirm the `isrepeat`/`scancode`
   thread reaches the keypressed path.
3. **Scope fence.** Diff touches only M4's files (new `projectInputController.lua`, `controller.lua`,
   the one M4-0 test conversion, warranted docs, M4's own new tests). **Flag any M5/M6/M7 dispatch
   work** and any unrequested tidying (the recurring failure mode on this feature).
4. **Rules check.** Hard limits, formatting, "no C accent", commit hygiene (conventional subjects;
   committer identity unchanged).
5. **Tech-debt tracking — check AND correct it.** Every gap surfaced (and every one you find) goes in
   `doc/development/wip/77-new-input-api/implementation/technical_debt.md` with a disposition. Confirm
   the `{M,C,V}` disposition is logged if not resolved. Keep the persistent/interim boundary honest.
   You may edit this ledger directly.
6. **Dev documentation — check it was updated.** M4 changes routing / the controller set / an internal
   contract — `doc/development/internals/` (user input) and related docs must reflect it. If not
   updated where they should be, that is a finding. Keep milestone ref-ids out of doc prose.

## Write the review

Write **`doc/development/wip/77-new-input-api/implementation/reviews/M4.md`**:

- **Verdict** — *approve* / *corrective-take needed* / *escalate*; plus an explicit **approval-scope
  note** (what the evidence establishes vs. what remains an open gate — the four-mode runtime check is
  the usual gap to be honest about).
- **Spec compliance** — per Contract item, with file:line and ✔/⚠/✗.
- **Runtime acceptance** — the four-mode verification, each ticked only where the evidence reaches it.
- **Scope fence** / **Rules check** / **Residual coverage** — findings with severity.
- **Tech-debt + docs** — what you logged/corrected, and the doc-update verdict.
- **Acceptance checklist** — the spec's Acceptance, each ticked only where evidence reaches it.

## Boundaries

- **Do not edit feature code or the design specs.** You may edit only the **review** you write and the
  **interim debt ledger** (`implementation/technical_debt.md`) — and only to keep tracking honest.
- If you cannot run the suite or a mode (no dev image / no display), say so explicitly and scope your
  verdict to what you could check; do not fabricate a test or runtime result.
- When done, present a short verdict summary and stop — the orchestration plane decides the next move.
