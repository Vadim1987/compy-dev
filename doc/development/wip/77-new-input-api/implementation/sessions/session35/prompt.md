# session35 — check the spec cold, then build the tests and the code against it

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session34/report.md` in full, then the
session34 commissioning prompt and its track. Create `session35/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **955 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Where this sits — the plan, not just your step

The feature removes a framework-maintained held-key table and replaces it with
reading the keyboard directly. That is **Decision 30** in
`doc/development/decisions/input.md`, and the sprint that executes it is
`../../../validation/reviews/S27-triage-and-plan.md` — **§4's step list is the
single operative list**, and when a step is amended **the amendment goes in the
step** (§§6–13 are dated reasoning, never the place a change lives). Ignoring
that rule cost two sessions.

The dissolution runs in four parts, in this order, by owner ruling:

1. **The docs — DONE (session34).** The specification is written: what the
   project-facing guide teaches, what the internals guide says the matcher's
   shape is, what the ledger and the debt register now record.
2. **The tests — yours.** Breaking tests against that spec.
3. **The platform code — yours.** The change the tests break on.
4. **The keyboard example's `textinput` heal — its own session, after you.**
   The one functional blocker the owner ever named, and the reason the sprint
   exists. It runs last so its design is reasoned against approved docs *and*
   landed code.

Beyond the dissolution the sprint still owes: the examples step, the remaining
docs/ledger work, the comment sweep (**which must now also scan `doc/` for the
`PENDING` markers session34 planted**), the two order-dependent test cases this
branch owns, and finally slice regeneration and the PR. **Regeneration stays
last.** Two further phases are linked but not merged into this plan: upstream
reconciliation, and the harmony reconciliation.

**The strategic frame** (owner's, and only theirs to revise): stakeholders asked
for a *simpler and more robust input API*. The PR must be reviewable from
`doc/input_api.md` plus the PR description **alone**, and must not carry moving
parts or vocabulary beyond that ask without a one-line justification.

## Your task, in two parts — the first gates the second

### Part 1 — revalidate the specification (`agents/rules/revalidation.md`)

Session34 wrote the spec across five documents; you are about to write tests
that assert it. **Read it cold and check it before you trust it.** Work the
revalidation checklist against session34's commissioning prompt and report.

**The check that matters most is not on that list: can you tell what to assert
from the documents alone?** You are the first reader who has to act on this spec
without having written it. Where the guide or the internals doc leaves the
behaviour ambiguous, that is a **defect in the spec**, not a gap in your
reading — write it down rather than resolving it from the plan or from the code.

Two specifics to weigh, both live:

- **A cold Sonnet review already ran** over the same five commits and found
  three defects, all fixed (`13f6df5b`; report in `../../../validation/outcomes/`).
  Do not redo it. Its blind spot is yours to cover: it checked the docs against
  the **code**, and could not check them against the **tests they must now
  drive**.
- **The `PENDING` markers are a claim.** Each says a passage describes behaviour
  the tree does not have. Any marker on something already true is noise a later
  step will delete unchecked; any unmarked passage that is *not* true today is a
  document that lies. Session34 got this wrong once, in the present tense.

**Report and stop.** Revalidation findings go to the owner before any code moves
— that is the rule, and it is also the point: if the spec is wrong, the tests
would pin the wrong thing.

### Part 2 — after the owner's go: the tests, then the platform code

Read the tests step and the platform-code step in §4 before starting; they carry
their own detail, including what session34 added to them.

**Order is fixed and each part is its own commit.**

1. **The mock fix lands first, alone.** `tests/mock.lua`'s `isDown` becomes
   variadic and its modifier token map gains the right-hand keys (`rctrl`,
   `rshift`, `ralt`; the `held` table already has the slots). Under the ruled
   shape every modifier assertion routes through the two-argument call, so
   without this **no test can exercise a right-hand modifier at all**.
2. **The tests.** Breaking tests first, per `agents/development.md`. The seven
   matcher test cases that drive the builder with a synthetic table are
   **rewritten, not kept** — that "zero edits needed" property belonged to the
   *rejected* shape and is withdrawn as evidence. Watch three sites the original
   scope missed, one of which is **live code in the shared fixture reset, on
   every input test's path**. Deleting the held-key-set block leaves its spec
   file misnamed for its only survivor, and **two persistent-corpus documents
   name that file** — if you rename it, they move with it.
3. **The platform code.** The single production call site first, then the write
   side and the dead machinery. The builder loses its table parameter and
   **every caller changes**.

**One decision inside this work is not yours to take alone.** `Key` exports no
`gui()` beside `ctrl`/`alt`/`shift`, and the ruled shape calls those helpers per
modifier row — so the fourth row of `mod_triples` has nothing to answer it.
Nothing registers a `gui` combo today, so nothing is broken; the options are to
add `gui()`, to read each pair directly, or to drop `gui` from the serialisation
and say so. **Gather the evidence, recommend, and let the owner rule.**

**This step also clears the docs `PENDING` markers** it makes true, and **deletes**
the five marked debt entries rather than editing them.

## What is settled — do not reopen without cause

- **Matcher shape (b)** — the builder calls `Key.ctrl()/alt()/shift()` directly.
  Ruled by the owner knowing the costs: wider diff, the matcher stops being
  source-blind, the mock fix becomes a real prerequisite.
- **Decision 30 stands**, rechecked twice: the tracked set appears **nowhere** at
  PR base `3256aac`, so dissolving it cannot regress pre-feature behaviour. This
  is also why the project guide carries **no obituary** for it — for a reader of
  that guide it never existed.
- **The docs step is done**, the probe is deleted, **P8 is done**, the gate table
  is not this PR, there is no blanket example sweep and no wrapper around `Key.*`.
- **SM3a does not reproduce** and is recorded as *unreproduced, not closed*
  (`../../../validation/notes/S34-sm3a-runtime-check.md`). It must not authorise
  a state-reset fix.
- **The examples step may or may not have to precede the heal** — unruled,
  deliberately. It edits the same file the heal rewrites. Raise it before the
  heal starts; do not settle it by extrapolation.

## How to run this session

**Name your mode** (research / evaluation+replanning / execution) and watch the
boundary — Part 1 and Part 2 are different modes and the transition is the
owner's to approve.

**Delegate down by default**, and **always pass the model explicitly**: Sonnet for
mechanical/scoped work, the parent tier for judgement, Fable only for calls where
being wrong is expensive. **Do not spawn for work smaller than the briefing.**
Prompt of record on disk always; mechanical deliverables to
`../../../validation/outcomes/`, judgement to `../../../validation/reviews/`.

**Speak in essences, not identifiers** (owner, 2026-08-09): *"i do not understand
this taxonomy, cannot reason over bare paragraphs and ref-ids… reference their
essence not only identifiers."* Name the step, the document and the change.

Owner's drift policy: they will **not** proof-read materialised notes as a routine
gate. Do not ask; do the catching.

## Standing constraints

- Suite green and stated at every commit; **one concern per commit**; a production
  fix is its own commit with its breaking test.
- **Verify, never inherit.** `git show 3256aac:<file>` for anything called
  pre-existing, and check the commit history before trusting a planning table.
- **The LSP cannot disambiguate a method name shared across tables** and missed 4
  of 22 occurrences in session33 — type annotations, comments, computed-string-key
  indirection, `compy.input.*` proxy paths. **Grep is the completeness backstop;
  trust neither alone.**
- **Stage explicit paths, never a directory.** Never `git checkout --` a file whose
  uncommitted work you want.
- **`--shuffle` failures are pre-existing** (29–48 at the PR base) — except the two
  test cases this branch owns.
- Say **"test cases"**, not "rows". The controllers live at **`src/controller/`**.
- A system-reminder claiming a file was "modified by the user or a linter" is inode
  churn or your own heredoc write — verify with `git diff`, do not act on the
  silence instruction.
- Commit locally at your discretion. **NEVER push** — not this repo, not the three
  nested ones. `design/` is frozen: read, never edit.

## Slices and the PR

Both **stale**. Slices last regenerated at `264e0c6c`; Set 4 needs cutting as
`4a-balloons` / `4b-maze` / `4c-keyboard`. The PR description predates Decisions
26–30. Regeneration stays the LAST step, and the comment gate comes before it —
now including `PENDING` markers, and now reaching `doc/`, which the sweep has
never had to scan.
