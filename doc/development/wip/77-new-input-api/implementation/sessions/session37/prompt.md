# session37 — execution resumes: the keyboard deepfix (P18)

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session36/report.md` in full, then the
session36 commissioning prompt and its track. Create `session37/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **946 / 0 / 0 / 10**. It was 942 for the whole of
session35; the four new cases are `Key.any_pressed`'s own spec
(`tests/util/key_spec.lua`). The pending count of 10 remains sanctioned — three
routing-grid gaps, seven reserved-combo outlines. An **eleventh** is a finding.

## Read this before anything else: the mode discipline was relaxed, and now is not

Session36 ran research, evaluation, ratification and execution in one continuous
context. The owner named that as a violation of their own discipline, justified
at the time by integral context — and it produced the session's two worst
moments, both of them execution proceeding on an assumption formed many turns
earlier. **Your session is execution. Name the mode and hold it.** A design
question appearing is a reason to stop and raise it, not to decide it.

## Where the work stands

- **The dissolution is finished.** The framework tracks no held keys; the
  matcher asks the keyboard; the modifier set is closed.
- **Decision 32 is ratified and promoted** — how the API is meant to be *used*:
  shortcuts for one-off transitions, polling for continuous state, no mirrored
  press/release pairs, no reconstruction of held state from events. Its
  operational form is `doc/development/conventions/input_adoption.md`, a
  question→action checklist. **Read that checklist; it is what governs your
  edits**, and it is written to be reused when the console and editor are
  evaluated later.
- **The examples are dispositioned**, not pending. `paint` is the one named
  ready item left in the sweep (P16) and is small.
- **The two plans are separate and must stay so**: the sprint
  (`../../../validation/reviews/S27-triage-and-plan.md`) removes defects and
  drives adoption; the parent (`../../../validation/plan.md`) is the release.
  §16.3 splits ownership explicitly. Do not fold one into the other.

## Your task — P18, the keyboard deepfix

**The step is `S27-triage-and-plan.md` §15.4**, which is operative. Read it, and
the §4 row, before touching a file. It absorbs **P9b, the `textinput` heal** —
the defect that blocks this sprint's closure — because both halves rewrite
`examples/keyboard/input.lua`.

**One planning pass covers both halves, and no order is imposed between them**
(owner, 2026-08-10). The heal's design of record,
`doc/development/internals/examples/keyboard.md`, is an **input, not a mandate**:
this step **may revise it**, and the owner has said so explicitly. What it may
not do is drift from it silently — a revision lands **in that document, with its
reasoning, before the code that assumes it**.

**Its onboarding half shrank** under Decision 32: `helpHeld`'s poll is now
*correct* and stays. What remains is `alt.lua`'s hand-matched Ctrl+Alt+H, the
`isMod` duplication of `Key.is_mod`, and the owner's intent to **dissolve the
`INPUT` proxy**, which is a pure alias for `Key` now — ten mechanical sites,
enumerated in §15.4, with `INPUT.upRecent` the one genuinely-own member that the
heal may delete anyway.

**BLOCKED ON A PREREQUISITE YOU DO NOT OWN.** The owner intends to pull the
detached repos' current upstream versions and reconcile them **before** this
step, each into **its own branch** so the merges can be ruled deliberately
(parent plan, Phase U). A deepfix planned against a stale base is planned twice,
and upstream is most likely to have moved in the very file you are rewriting.
**Confirm with the owner that the pull has happened before you design anything.**

## Standing constraints

- **Smoke with `stdbuf -oL`** — `timeout 20 xvfb-run -a stdbuf -oL -eL love src play <path>`.
  Without line buffering the output is discarded on kill and a raising project
  looks exactly like a healthy one. This was proven, not guessed.
- The keyboard example has **no suite**; the interactive checklist in its design
  note is owed by a human. Say what you could not verify.
- Suite green and stated at every commit; **one concern per commit**; a
  production fix is its own commit with its breaking test.
- **A deviation is documented in the workspace** — a doc or a code comment — not
  only in the commit message (owner directive).
- **Verify, never inherit.** `git show 3256aac:<file>` for anything called
  pre-existing; grep is the completeness backstop where the LSP misses metatable
  `__index` dispatch, which this example is built on.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones. `design/` is frozen.
- The owner works in this tree: never sweep their unrelated changes or their
  in-code `REMARK:` markers into your commits.

## After you

`P17` (maze deepfix) and `P19` (sapper — which owns a **live defect** older than
this feature: shift-click un-flags itself if Shift is released inside the 0.4 s
click window). Then P16's one ruling and `paint`, P10's docs, the probe
deletion, the two order-dependent cases, harmony revalidation, and the comment
sweep. The parent then runs Phase L and Phase G. **The sprint closes on its own
steps, not on the PR.**
