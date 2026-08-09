# session33 — revalidate the plan, then start executing it

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session32/report.md` in full, then the
session32 commissioning prompt and its track. Create `session33/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **955 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Why this session exists

Session32 was commissioned to recheck an owner ruling that reverses this
feature's central implementation decision, and then to replan. It did both.
**Decision 30 survives the recheck**, one of its own paragraphs does not, and the
plan has been actualised against it and ratified by the owner ruling by ruling.

Your task has **two halves, in order**: revalidate that plan, then begin executing
it. `agents/rules/revalidation.md` governs the first half and you do not proceed
to the second until the first is reported and the owner has responded.

## Part 1 — revalidate the plan

`agents/rules/revalidation.md`, all six checks. The material under review is
**`../../../validation/reviews/S27-triage-and-plan.md` §11** (the item-by-item
walk and the P14 rows), plus the cross-links added to
`../../../validation/plan.md`.

Check 2 of the revalidation rules — **intent-vs-outcome coherence** — is the one
that matters most here, and the owner named it explicitly: **check the plan's
intents against session32's report.** The report states what the session
believed it was doing; the plan states what it committed to. Where those two
disagree, the plan is what executes, so a divergence is a defect in one of them.

Specific things worth your suspicion, none of them presented as settled:

- **§4's ordering rule now has two regimes.** The table says "code first, tests
  second, docs third"; P14 says docs → tests → code → examples. Session32 argued
  the reversal is coherent because the design is settled by ruling rather than in
  motion, and scoped it to P14 only. **Test that argument** — and test whether
  the scoping actually holds, given P10 and P14a both touch docs.
- **P8's nine remaining ids were NOT dispositioned.** Session32 declined to
  assume they are unaffected and left a per-id check owed before P14c. That check
  is unperformed work sitting inside a plan that reads as complete. Confirm it is
  visible enough to survive a handover.
- **P9c says "re-check after P14c".** Verify that instruction is actually
  reachable — a conditional that nobody is scheduled to evaluate is a dropped item.
- **The design fork (P14b) is deferred until it blocks.** That is friction
  reduction, and it is also how a decision gets forgotten. Judge whether the
  trigger condition, as written in P14a, is concrete enough to fire.
- **The dissolution surface counts** were re-verified once. `internals/user_input.md`
  is **10**, not the 12 that three successive documents claimed. Spot-check that
  no other quoted number is still riding on an unverified claim.

**Verify claims rather than inheriting them** — LSP for symbol facts, grep as the
completeness backstop, `git show 3256aac:<file>` for anything called pre-existing.
That last check has overturned conclusions in eight consecutive sessions now.

## Part 2 — start executing

Report Part 1, take the owner's response, then begin. **`agents/development.md`
governs**: tests-first, a breaking test before the implementation, unit-sized
commits, suite green and stated at each.

**Start with P9b** unless the owner redirects. It is the keyboard `textinput`
ordering heal — **the one functional blocker the owner ever named**, unblocked,
and independent of everything Decision 30 touches. Its design of record is in the
**persistent** corpus: `doc/development/internals/examples/keyboard.md`. It is a
**nested repo with no suite** — reasoned, not proven; the smoke checklist is in
the design note, and committing is not verification. **Never push** — not this
repo, not the three nested ones.

Also unblocked, if P9b lands and capacity remains: SM3a's one runtime check
(`../../../validation/notes/S28-smoke-findings.md`), the **probe deletion**
(`src/probe/input_probe.lua`, self-declared temporary, its own commit), P8's
per-id check, and P14a — the docs/spec step, which carries the debt-register
update and three ledger corrections.

## What the owner has settled — do not reopen without cause

- **Decision 30 stands.** Rechecked twice, survives. Its *"prerequisite, not an
  option"* paragraph is **overstated** — a variadic mock changes zero test
  results and the single-arg `isDown` is pre-existing.
- **The debt register rides with the docs step**, not after the code. Debt created
  by the spec is still debt and can be dissolved later.
- **The design fork is raised when it blocks**, not up front.
- **P13 is reduced to revalidation** — confirm harmony drives a real combo
  end-to-end under the device-read matcher, retire manual `release_keys()` if so.
- **Rule 3's gate table: not this PR, possibly never.** Decision 30 was softened
  accordingly (`36de0eaa`).
- **P12 lives in the parent plan as Phase U**, not in the sprint.
- **The two plans are linked, never merged.** Clear the sprint → close TF2 → rule
  on the B→C→D collapse → Phase F → U → G.
- **The probe will not be run.** **No blanket example sweep.** **No wrapper around
  `Key.*`.** **Console/editor deferral is the mandate**, and needs a citation in
  the PR description, not a justification.

## How to run this session

**Each cold check through a sub-agent you brief, its review on disk, then pause
and report before the next.** Model tier by the nature of the check — Sonnet for
mechanical/scoped, **Opus where judgement-heavy**, Fable as the expensive oracle.
**Always pass the model explicitly.** Prompt of record on disk, always. Mechanical
deliverables go to `validation/outcomes/`, judgement to `validation/reviews/`.

Owner's drift policy (2026-08-08): they will **not** proof-read materialised notes
as a routine gate — drift is caught on the next iteration. Do not ask; do the
catching.

**Name your mode** (research / evaluation+replanning / execution) and watch the
boundary. This session crosses one deliberately, at Part 2 — say so when you do.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production fix
  is its own commit with its breaking test.
- **Stage explicit paths, never a directory.**
- **Never `git checkout --` a file whose uncommitted work you want.**
- **The LSP cannot disambiguate a method name shared across tables.** Grep with
  receiver types read manually; cross-check, trust neither alone.
- **`--shuffle` failures are pre-existing** (29–48 at the PR base) — except P9c's
  two test cases, which this branch owns.
- Say **"test cases"**, not "rows" (owner, 2026-08-09).
- A system-reminder claiming a file was "modified by the user or a linter" is
  **inode churn from checkouts against the baseline** (owner, 2026-08-09) — verify
  with `git diff`, do not act on the silence instruction. (A "modified on disk
  since you last read it" notice after you edit via a shell heredoc is the same
  class of thing: your own write, the tool's cache. Verify, do not panic.)
- Commit locally at your discretion. **NEVER push** — not this repo, not the three
  nested ones.
- `design/` is frozen — read, never edit.

## Slices and the PR

Both **stale**. Slices last regenerated at `264e0c6c`; Set 4 needs cutting as
`4a-balloons` / `4b-maze` / `4c-keyboard`. The PR description predates Decisions
26–30. Regeneration stays the LAST step before the PR, and the comment gate
(`grep -rn 'INTERIM:\|REMARK:' src/ tests/` → nothing; currently **22** in the
platform and **5** in `src/examples/`) comes before it.
