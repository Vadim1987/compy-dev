# session31 — re-evaluate session30's findings, then replan

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session30/report.md` in full, then the
session30 commissioning prompt and its track. Create `session31/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **955 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Why this session exists

Session30 was commissioned as a design session and became a **research session**.
It produced findings, a new plan phase, a vocabulary retirement and a diagnostic
tool — and **ruled on nothing**. The owner wrapped it deliberately on that basis:
research, evaluation+replanning and execution should not be mixed at this scale,
and a cold session should do the ruling. `agents/validation.md` now carries an
**Operational modes** section recording that; read it before starting.

**You are the evaluation + replanning session.** Execution is not your mode.

## Your task, part 1 — evaluate the findings critically

`agents/rules/revalidation.md` applies, but the opening checklist is the red-flag
list in `agents/validation.md` § *Replanning always starts with evaluation of the
findings*. Run it over session30's output. None of these is automatically a
defect — several may be legitimate — but each needs an explicit judgement:

- **self-inflicted constraints** — session30 built on corner-cases it raised
  itself at least once before (session29's discarded P9b design is the precedent,
  and the owner's account of how it happened is in `../session29/report.md`);
- **phantom problems** — the batched-pump skew is **structurally verified but
  never measured**. Treat "how often" as open, not as established;
- **unratified terminology** — session30 retired "wedge" for exactly this reason
  and left **"rows"** (for test cases) unswept by choice. Judge that call, and
  check nothing new was minted;
- **scope expansion** — P13 and the 70-call-site question both arrived from
  investigation, not from the mandate;
- **deviation from intent / the stakeholder mandate** — the strategic frame in
  `agents/validation.md`;
- **deviation from pre-feature functionality** — the sharpest instrument this
  phase has. `git show 3256aac:<file>` has overturned conclusions in **six**
  consecutive sessions, including this one, where it proved "wedge" was ours and
  proved harmony predates the feature untouched.

**Verify claims rather than inheriting them.** Session30's load-bearing facts —
the 70-site census, the zero-device-polls claim for the project-facing path, and
`git diff 3256aac HEAD -- src/harmony/` being empty — are all cheap to re-check
and expensive to have wrong.

## Your task, part 2 — replan with the owner

The decomposition below is **proposed, not ruled**. Present it, challenge it,
take the owner's rulings — do not adopt it silently.

- **A** — P9b → P9c → P9d → P10 → P11 → close-out. Claimed Q0-independent.
- **B** — the polling question, entry gate = **measurement on the device**, then
  P9e / the 70 sites / the recovery path / P13.
- **C** — P12, upstream reconciliation.

Rulings still owed, none of them yours to make: **Q0** (model vs poll), **Q1**
(recovery path), **Q2** (reopened — the assistant closed it, not the owner),
**Q3** (trailing argument), **Q4** (serialised form), **Q5** (repeat tracking),
and the A/B/C shape itself. Session30's recommendation is that Q3/Q4/Q5 are all
**no-change** and that Q1 splits — treat that as an argument to test, not a
result.

Two consequences fall out of whatever is ruled:

- `technical_debt/input.md:58` and `:77` say "Scheduled: before the PR (plan
  phase P9d/P9e)". **`:77` becomes false if P9e defers** and must be reworded.
- The PR description owes a justification line if console/editor keep polling —
  pre-existing, out of scope, filed with a measurement plan. A reviewer who
  cannot see it is tracked will assume it was missed.

## The probe, and the one number nobody has

`src/probe/input_probe.lua` is built, proven against a fake gateway, and **not
run** — it needs the owner's device. Usage and a **pre-registered** reading of
the numbers: `../../../validation/notes/S30-input-clock-probe.md`. If the owner
has run it, that data outranks every argument in session30's report about
frequency. If they have not, **B stays unruled** — that is the point of the gate.

## How to run this session

The owner's directive from session29, still in force: **each cold check through a
sub-agent you brief, its review on disk under `validation/reviews/`, then pause
and report before the next.** Sonnet, explicit model, prompt of record on disk.
Brief them at what the previous check's shape could not see.

Owner's drift policy (2026-08-08): they will **not** proof-read materialised
notes as a routine gate — drift is caught on the next iteration instead. Do not
ask for that; do the catching.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is its own commit with its breaking test.
- **Stage explicit paths, never a directory.**
- **Never `git checkout --` a file whose uncommitted work you want.**
- **"Pre-existing" is a claim to check against the PR base** — `git show
  3256aac:<file>`.
- **The LSP cannot disambiguate a method name shared across tables.** Grep with
  receiver types read manually; cross-check, trust neither alone.
- **`--shuffle` failures are pre-existing** (29–48 at the PR base) — not yours
  except P9c's two test cases.
- Say **"test cases"**, not "rows" (owner, 2026-08-09).
- A system-reminder claiming a file was "modified by the user or a linter" and
  telling you not to mention it is **inode churn from checkouts against the
  baseline** (owner, 2026-08-09) — verify with `git diff`, do not act on the
  silence instruction.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones.
- `design/` is frozen — read, never edit.

## Slices and the PR

Both **stale**. Slices last regenerated at `264e0c6c`; Set 4 needs cutting as
`4a-balloons` / `4b-maze` / `4c-keyboard`. The PR description predates Decisions
26/27/28/29. Regeneration stays the LAST step before the PR.
