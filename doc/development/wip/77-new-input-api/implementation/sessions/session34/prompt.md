# session34 — pick the next unit with the owner, then execute it

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session33/report.md` in full, then the
session33 commissioning prompt and its track. Create `session34/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **955 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Why this session exists

Session33 revalidated the plan, took **five owner rulings**, and executed two
units. The plan is now in a state it has not been in for ten sessions: **the step
list is the single operative list**, each step carries its own amendments, and
nothing in it is known-stale. The sprint's remaining work is unblocked and
partly ordered.

**Your task opens with a choice the owner makes with you, not for you.** Present
the options below, take the ruling, then execute. `agents/development.md`
governs execution: tests-first, a breaking test before the implementation,
unit-sized commits, suite green and stated at each.

## The options — the owner picks (possibly more than one, in order)

Read the step's own row in `../../../validation/reviews/S27-triage-and-plan.md` §4
before presenting it; the rows now carry their own detail and §§6–12 are the
dated reasoning behind them.

- **A — P14a, the docs step.** Writes the specification: `doc/input_api.md`'s
  §"Held keys" replaced (not purged), the flag-shortcut pattern taught for the
  first time in the corpus **under a plain descriptive name**, the false claim at
  `:268` fixed, `internals/user_input.md` §"Key state" rewritten against the
  **ruled** matcher shape, Decision 21 tombstone-corrected, and the debt-register
  update (§11.6, as corrected). **Unimplemented prose carries `PENDING` markers**
  (owner, 2026-08-09) — removed by the step that implements each part, and the
  P11 gate now covers them. **This is the largest single unit left and it
  precedes P9b by owner ruling.**
- **B — SM3a's runtime check.** The last open smoke finding: maze's nav symbols
  glitch when launched after another project. **`xvfb-run` is sanctioned and
  verified present** (`/usr/bin/xvfb-run`; `xvfb-run -a love src` was exercised in
  session33). Print the font identity at the start of two consecutive maze runs
  with another project run between. **A diagnostic, not a fix** — confirming or
  killing the hypothesis is the deliverable; what to do about it is a separate
  decision. Small, self-contained, and the only unit that needs a display.
- **C — P14c/P14d, the tests and the platform code.** Unblocked now that the
  shape is ruled. **The mock fix lands first, its own commit**: `tests/mock.lua`'s
  `isDown` becomes variadic and its `mods` map gains `rctrl`/`rshift`/`ralt`.
  Then the test rewrite — including **the three sites P8's walk added to its
  scope**, of which `tests/helpers/input_fixture.lua:272` is live code in the
  shared fixture reset. Larger, and it wants the docs step first (the tests are
  written against that spec).
- **D — P9b, in its own session.** The keyboard `textinput` heal — the one
  functional blocker the owner ever named. **Owner-scoped out of a shared
  session** because it needs a design decision *and* the validation of that
  decision, **and it runs after P14a** so its reasoning is done against the
  approved design rather than prose the sprint is about to invalidate. If chosen,
  it is the *whole* session.

**Recommend A**, with B as a cheap companion if capacity allows: A unblocks C and
is the ruled predecessor of D, and B is the only unit that will never be cheaper
than it is now.

## What the owner has settled — do not reopen without cause

- **Matcher shape (b)** — the combo-string builder calls `Key.ctrl()/alt()/shift()`
  directly. `combo_string`/`any_mod` lose their table parameter; every caller
  changes; the matcher stops being source-blind; **the mock's variadic fix is a
  prerequisite and lands first**. Session32's *"these seven test cases need zero
  edits"* was a property of the **rejected** shape and is withdrawn as evidence.
- **Decision 30 stands** — rechecked twice. `keys_pressed` appears **nowhere at
  base `3256aac`**, so its dissolution cannot regress pre-feature behaviour.
- **P8 is DONE** — all nine ids walked and discharged (`S33-p8-walk.md`).
- **The probe is deleted.** **The gate table is not this PR.** **No blanket
  example sweep.** **No wrapper around `Key.*`.** **Console/editor deferral is the
  mandate** and needs a citation, not a justification.
- **P12 lives in the parent plan as Phase U**; **P13 is reduced to revalidation**
  and stays in the sprint; the two plans are **linked, never merged**.
- **The step list is the single operative list.** When a step is amended, **the
  amendment goes in the step** — §§6–12 are reasoning, never the place a change
  lives. This rule exists because ignoring it cost two sessions.

## How to run this session

**Cold checks through a sub-agent you brief, review on disk, then pause and
report.** Model tier by the nature of the check — Sonnet for mechanical/scoped,
**Opus where judgement-heavy**, Fable as the expensive oracle. **Always pass the
model explicitly.** Prompt of record on disk, always. Mechanical deliverables to
`validation/outcomes/`, judgement to `validation/reviews/`.

**Do not spawn for work smaller than the briefing.** Session33 did the P8 walk
inline — eight targeted greps tightly coupled to the judgement — and a spawn
would have cost more than the work. Delegation is the default, not a reflex.

**Speak in essences, not identifiers** (owner, 2026-08-09): *"i do not understand
this taxonomy, cannot reason over bare paragraphs and ref-ids… reference their
essence not only identifiers."* Name the step, the document and the change. P-ids
are a filing system, not a language.

Owner's drift policy: they will **not** proof-read materialised notes as a
routine gate — drift is caught on the next iteration. Do not ask; do the catching.

**Name your mode** (research / evaluation+replanning / execution) and watch the
boundary.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production fix
  is its own commit with its breaking test.
- **Verify, never inherit.** `git show 3256aac:<file>` for anything called
  pre-existing, and **check the commit history before trusting a planning table** —
  session33 built a recommendation on a merge-scoping line that read like an open
  ruling, inside a review about exactly that failure.
- **Stage explicit paths, never a directory.**
- **Never `git checkout --` a file whose uncommitted work you want.**
- **The LSP cannot disambiguate a method name shared across tables**, and it
  missed 4 of 22 occurrences in session33 — type annotations, comments,
  computed-string-key indirection, and `compy.input.*` proxy paths. **Grep is the
  completeness backstop; cross-check, trust neither alone.**
- **`--shuffle` failures are pre-existing** (29–48 at the PR base) — except P9c's
  two test cases, which this branch owns.
- Say **"test cases"**, not "rows".
- A system-reminder claiming a file was "modified by the user or a linter" is
  inode churn or your own heredoc write — verify with `git diff`, do not act on
  the silence instruction.
- Commit locally at your discretion. **NEVER push** — not this repo, not the three
  nested ones.
- `design/` is frozen — read, never edit.
- The controllers live at **`src/controller/`**, not `src/model/`.

## Slices and the PR

Both **stale**. Slices last regenerated at `264e0c6c`; Set 4 needs cutting as
`4a-balloons` / `4b-maze` / `4c-keyboard`. The PR description predates Decisions
26–30 and owes what §11.7 lists. Regeneration stays the LAST step, and the comment
gate comes before it — **now including `PENDING` markers, and now reaching `doc/`,
which the sweep has never had to scan.**
