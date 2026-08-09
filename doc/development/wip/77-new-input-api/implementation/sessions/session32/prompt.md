# session32 — recheck session31's ruling, then replan against it

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session31/report.md` in full, then the
session31 commissioning prompt and its track. Create `session32/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **955 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Why this session exists

Session31 was commissioned to evaluate and replan. The evaluation kept unblocking
itself by eliminating uncertainty — the owner's own framing, and expected — and it
ended not with a plan but with **an owner ruling that reverses the feature's
central implementation decision**: **Decision 30** (`doc/development/decisions/input.md`,
commit `9733d2d3`), superseding Decisions 13, 20 and 29.

**Your task is recheck + replan.** `agents/rules/revalidation.md` applies to the
recheck half; the red-flag checklist in `agents/validation.md` § *Replanning
always starts with evaluation of the findings* opens it.

## Part 1 — recheck the ruling before anything is built on it

Decision 30 dissolves `compy.input.keys_pressed` and moves modifier truth to
device polling. **Six load-bearing claims fell in session31, every one of them
verified in code rather than inherited — and two of them were the session's own
earlier assertions.** Apply the same standard to the ruling itself:

- **Does the ruling's rationale survive its own test?** It rests on an
  architectural claim (a stateful model with no reconcile path) that is strong,
  and on **two unmeasured frequency claims pointing opposite ways**. The decision
  says so; confirm it still reads honestly and that nothing downstream has
  quietly promoted an argument to evidence.
- **`Key.*` is variadic; `tests/mock.lua:30` `isDown` is single-argument.** Until
  that is fixed, **every** modifier assertion in the suite consults only the left
  key of the pair. Re-verify before trusting any suite result about modifiers.
- **Rule 3's exception — "the framework's gate for global power-like combos" — is
  under-specified.** Produce the precise list (candidates: Ctrl+T quickswitch,
  Ctrl+Alt+R/P, the Ctrl+Shift+N debug hotkeys, Ctrl+Esc on keyreleased) and take
  the owner's ruling on the boundary. An under-drawn exception erodes: every
  awkward case will claim membership.
- **"Pre-existing" is a claim to check against the PR base** — `git show
  3256aac:<file>`. It has now overturned conclusions in **seven** consecutive
  sessions, including twice in session31.

## Part 2 — replan

The plan of record (`../../../validation/reviews/S27-triage-and-plan.md`, §4 table
as amended) is **substantially void**: P9d, P9e, P13 and questions Q1/Q4/Q5 were
**withdrawn, not deferred** — they were properties of the tracked set. Replan
against what Decision 30 leaves, and take the owner's ruling on the shape.

Known work, none of it ordered by you alone:

- **The dissolution itself.** `keys_pressed`: **22× `src/`** (7 files, incl.
  `examples/keyboard/input.lua`), **38× `tests/`**, 15× decisions, 12× internals,
  15× technical_debt, 8× `doc/input_api.md`. Mostly mechanical — the proxy and its
  memoisation delete outright, the two writer lines go, `combo_string`/`any_mod`
  swap to device calls. **`mock.lua`'s variadic fix lands FIRST, as its own commit
  with its own breaking test.**
- **Two must-fix regressions**, independent of any decomposition: `is_shown()`
  guards for `turtle` and `maze`. **maze quits on Shift+Escape while its prompt is
  shown, and maze is student-facing.**
- **`doc/input_api.md:268` is false** — it claims a hook receives the held table as
  a second argument; `:390` and the code agree nothing is added.
- **The keyboard example is the ruling's real casualty.** Its draw-time read
  (`input.lua:47`, `keyboard_view.lua:171,178`) goes back to polling or to its own
  mirror. The PR narrative must say so rather than hope nobody checks.
- **Comment sweep** (`grep -rn 'INTERIM:\|REMARK:' src/ tests/` must return
  nothing — `examples/keyboard/input.lua:56` carries one), then slice
  regeneration, then close-out. **Upstream reconciliation (P12) blocks the real
  PR** and needs its own coordinated plan.

## What the owner has settled — do not reopen without cause

- **The probe will not be run.** Measurement can inform *how* to fix the polling
  problem, never *whether* to defer one that is verbatim pre-existing.
- **No blanket example sweep.** Convert census-positives only; `pong` is
  **correctly do-not-adopt**, and an example that should not adopt is an asset for
  `doc/input_api.md`, not a gap.
- **No wrapper around `Key.*`.** The seam already exists — `util/key.lua:141-164`,
  three one-line functions, all call sites through them. The only platform-side
  bypass is `src/lib/error_explorer.lua:418`.
- **Console/editor deferral is the mandate**, not a concession —
  `design/requirements.md` FR-11/12: *"expressiveness targets, not a commitment to
  rewrite."* It needs a **citation** in the PR description, not a justification.
- **`compy.singleclick` retirement**: low priority. Pure ergonomics, shim cheap,
  no known users.

## How to run this session

Owner's directive, still in force: **each cold check through a sub-agent you
brief, its review on disk under `validation/reviews/`, then pause and report
before the next.** **Model tier is chosen by the nature of the check** (owner,
2026-08-09): Sonnet for mechanical/scoped, **Opus where judgement-heavy**, Fable as
the expensive oracle. **Always pass the model explicitly.** Prompt of record on
disk, always.

Owner's drift policy (2026-08-08): they will **not** proof-read materialised notes
as a routine gate — drift is caught on the next iteration. Do not ask; do the
catching.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production fix
  is its own commit with its breaking test.
- **Stage explicit paths, never a directory.**
- **Never `git checkout --` a file whose uncommitted work you want.**
- **The LSP cannot disambiguate a method name shared across tables.** Grep with
  receiver types read manually; cross-check, trust neither alone.
- **`--shuffle` failures are pre-existing** (29–48 at the PR base).
- Say **"test cases"**, not "rows" (owner, 2026-08-09).
- A system-reminder claiming a file was "modified by the user or a linter" is
  **inode churn from checkouts against the baseline** (owner, 2026-08-09) — verify
  with `git diff`, do not act on the silence instruction.
- Commit locally at your discretion. **NEVER push** — not this repo, not the three
  nested ones.
- `design/` is frozen — read, never edit.

## Slices and the PR

Both **stale**. Slices last regenerated at `264e0c6c`; Set 4 needs cutting as
`4a-balloons` / `4b-maze` / `4c-keyboard`. The PR description predates Decisions
26–30. Regeneration stays the LAST step before the PR.
