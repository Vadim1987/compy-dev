# session36 — reconcile the examples with the removal (P14e)

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session35/report.md` in full, then the
session35 commissioning prompt and its track. Create `session36/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **942 / 0 / 0 / 10**. A different count is a finding,
not a go-signal — **with one exception you must understand before you run it**:
the pending count is 10 by owner ruling, not by drift. Three are long-standing
routing-grid gaps; seven are the reserved-combo effects named in
`tests/input/input_global_shortcuts_spec.lua`. `doc/development/tests.md` records
the distinction. An **eleventh** pending is a finding.

## Where you are — two plans at two altitudes, and you are inside the lower one

This matters because it is the difference between "finish the task" and "know
what finishing it is for".

- **The release plan** is `../../../validation/plan.md` — the validation-phase
  plan for feature #77, ending in PR assembly. Its **Phase TF2** was the owner's
  human review of the split test suite. That review produced **187 remarks**
  rather than the near-empty bucket the plan expected.
- **Those 187 remarks are being cleared through a spinoff sprint**, and the
  spinoff's plan is a **separate document**:
  `../../../validation/reviews/S27-triage-and-plan.md`. Its §0 states the
  relationship in the owner's own words. **The two plans are linked, never
  merged** — they sit at different altitudes.
- **So TF2 is not finished; it is being cleared through this sprint**, whose
  purpose is exactly that: **clearing known defects before release**. Nothing
  downstream of TF2 in the parent plan has started. When this sprint closes,
  TF2 closes with it and the parent returns to a gated question about collapsing
  some of its later phases.
- Anything you meet that is **release-shaped rather than remark-shaped** is
  **promoted up** to the parent plan, not carried here. That has happened once
  already (upstream reconciliation became the parent's Phase U).

**§4 of the spinoff plan is the single operative step list.** Two rules govern
it, both bought with real damage:

1. **When a step is amended, the amendment goes IN the step.** §§6–14 are dated
   reasoning and are never where a change lives. Ignoring this cost two
   sessions; session35 found the rule broken *again*, in the session that wrote
   it — a hint about `find_shortcut` had been filed under the examples step.
2. **You must update step progress as you go.** Mark your step done in its §4
   row *and* in its operative section, with the commits and the suite count, the
   way P14a, P14c and P14d are marked. A successor reads the table, not your
   memory.

## What has already happened, in essence

The framework used to maintain a table of held keys and match combos against it.
**It no longer exists** — the matcher asks the keyboard directly (Decision 30),
the modifier set is closed to ctrl/alt/shift (Decision 31), and the whole
surface is gone from the platform: bookkeeping, field, read-only view, sandbox
exposure, type declaration. The tests, the docs, the debt register and the
decision ledger have all been brought into line. Detail: `../session35/report.md`.

**The consequence that is now yours:** `src/examples/keyboard` reads that
surface through its own proxy, so **it is broken at this HEAD**. That is not an
accident — the ordering was ruled deliberately, and repairing it is where your
step starts.

## Your task — P14e, the examples reconciliation

**The step is `../../../validation/reviews/S27-triage-and-plan.md` §11.4.3**,
which is operative and enumerated: per-repo and per-example scope, what converts
and what stays, and the leads. Read it, and the §4 P14a–e row, before touching a
file. What follows is orientation, not a substitute.

**The mandate is two named changes, and nothing else:** the removal of the
held-key surface, and the corrected recommendation ladder (shortcuts and combos
first; `Key.*` in project code is permitted but a symptom; `love.keyboard` is the
last resort, legitimate where `Key` has no answer — a key that is not a
modifier). **Held-state reads are what you sweep.** An example with none is
recorded as clean and closed, **not searched**. This is not the blanket example
sweep the owner ruled out.

**The three detached repos** (`src/examples/{keyboard,maze,balloons}`) are
separate repositories with their own remotes and their own local commits. Each
commits on its own; **none is ever pushed**. They carry **no test suite** — a
smoke re-pass is the gate, so budget for running the app.

**The in-repo examples** are enumerated in the step: two conversions, several
already correct, one that stays at the last rung legitimately, and several with
no held-state read at all. Do not re-derive the sweep; it was done and recorded
so you would not have to.

**One conversion is bigger than the others and was ruled in by the owner:**
`sapper` repeats "this modifier and none of the others" across four call sites,
which is precisely what a class key already means, so the cascade becomes combos
on the click channels. The step names the two behaviour deviations that
conversion accepts. **State them in the commit rather than discovering them in
the smoke pass.**

**The hint has a cap, and the cap is the point.** Some example reads are combos
or events written out by hand; the step lists leads. Take one **only** where the
conversion is small and obviously behaviour-preserving. Anything larger goes to
the debt register with its reasoning. **This must not turn a reconciliation into
an example rewrite.**

## What is settled — do not reopen without cause

- **Ordering is ruled:** `P14a → P14c → P14d → P14e → P9b`. The keyboard
  `textinput` heal runs **after** you, in its own session, because it rewrites
  the very file you are reconciling.
- **The heal is a defect in its own right, not part of this dissolution.** It
  predates Decision 30 and would need fixing anyway. It blocks this sprint's
  closure, not the dissolution's.
- **`modHeld` is DELETED, not converted** — it re-implements `Key.ctrl()`'s
  folding over the dissolved table.
- **The proxy is the seam.** A cold enumeration counted 11 read sites in the
  keyboard example and **9 need no edit at all** once the three proxy branches
  call `Key.*`. Do not open eleven files.
- **`held` has three unrelated meanings in this tree** — the dissolved set, the
  device mocks, and a text-selection drag state. **Do not sweep on the word.**

## After you

**P9b** (the keyboard `textinput` heal) is next and needs its own session. Then
the sprint still owes: the remaining docs and ledger work (**including a new
member: the project guide never says which combos the framework has already
reserved** — see the P10 row), the comment sweep (which now also scans `doc/`),
the two order-dependent test cases this branch owns, and finally slice
regeneration and the PR. **Regeneration stays last.**

## How to run this session

**Name your mode** (research / evaluation+replanning / execution) and watch the
boundary. Yours is execution; a design question appearing is a reason to stop
and raise it, not to decide it.

**Speak in essences, not identifiers** (owner, 2026-08-09): name the step, the
document and the change, not a bare id.

**Delegate down by default, and always pass the model explicitly** — Sonnet for
mechanical and scoped work, the parent tier for judgement, Fable only where being
wrong is expensive. **Do not spawn for work smaller than the briefing.** Prompt
of record on disk always; mechanical deliverables to `../../../validation/outcomes/`,
judgement to `../../../validation/reviews/`.

**Sub-agent hygiene learned the hard way (session35):** instruct every worker to
**write its deliverable early and update it as it goes**. One died mid-review to
an infrastructure failure holding a full pass of findings and nothing on disk.

Owner's drift policy: they will **not** proof-read materialised notes as a
routine gate. Do not ask; do the catching.

## Standing constraints

- Suite green and stated at every commit; **one concern per commit**; a
  production fix is its own commit with its breaking test.
- **Verify, never inherit.** `git show 3256aac:<file>` for anything called
  pre-existing. Session35 found a planned deletion range that would have removed
  two live contracts — a range a previous session had "re-verified".
- **Grep is the completeness backstop.** The LSP misses occurrences routed
  through metatable `__index` on string keys, and returned phantom references
  after a `git mv` in this very session. Trust neither alone.
- **Stage explicit paths, never a directory.** Never `git checkout --` a file
  whose uncommitted work you want.
- Say **"test cases"**, not "rows". The controllers live at `src/controller/`.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones. `design/` is frozen: read, never edit.
- The owner works in this tree: never sweep their unrelated changes or their
  in-code `REMARK:` markers into your commits.
