# session30 — report

**Commissioned:** answer the four held-key design questions with the owner
(Q1 recovery, Q3 trailing argument, Q4 serialised form, Q5 repeat tracking), then
resume the plan at P9b. **Part 2 never started.** The owner reframed part 1 twice,
the thread became a research session, and it was wrapped deliberately on that
basis rather than pushed into execution.

Suite **955 / 0 / 0 / 3** throughout — the baseline, unchanged, since no
production code moved. Three commits, all docs plus one diagnostic module.
Nothing pushed.

**This session was analysis-heavy. Its successor's job is evaluation and
replanning, not execution** — the owner's ruling, and the reason
`agents/validation.md` now carries an "Operational modes" section.

## What the owner changed about the question

1. **Q2 was closed by the assistant, not by them.** It sat in the agenda note as
   `[ANSWERED IN SESSION]` and session30's own prompt instructed "do not
   re-open it". The owner spotted the gap from its absence alone. **Reopened.**
2. **Decision 26 is ours, not an external constraint.** It reverted an earlier
   decision and can be overridden. That dissolves Q2's closing argument (which
   reasoned about jurisdiction between two ratified decisions) and retires Q3's
   framing as an amend-or-supersede question.
3. **The agenda had a question underneath it — Q0:** *should we model held keys
   at all, or is that unfeasible?* Q1 and Q5 are downstream of it.
4. **The original motive for event tracking was structure, not correctness** —
   stopping `if Key.shift()` cascades from sprawling everywhere. Centralised
   polling would have satisfied it equally, so the source had to be decided on
   reliability alone.

## Findings (all code-verified unless marked)

- **The seam the owner is looking for already exists.** The project-facing
  dispatch path (`projectInputController.find_shortcut`) reads only
  `Controller.keys_pressed` and `Key.is_mod` (a pure name lookup) — **zero device
  polls**. All 70 `Key.ctrl/alt/shift()` sites are console/editor internals,
  unchanged since before the feature. Letting them keep polling cannot make
  things worse than today, because it *is* today.
- **Every one of those 70 sites is in an event-handling path** — `navigate`,
  `selection`, `copypaste`, `quickswitch`, `EditorController:keypressed` and so
  on. **Not one is a frame-time or draw-time poll.** Consequence: Decision 29
  clause 3 preserves direct reads for "a per-frame draw with no event in hand",
  and the platform contains **zero** such keyboard instances. That justification
  is theoretical.
- **The batched-pump mechanism is real, and its structural half is
  code-verified.** This project overrides `love.run` (`harmony/init.lua:104`);
  the loop pumps the whole batch, then dispatches one event at a time. So a poll
  during event 1 of N reports the state after event N. *SDL's own state-array
  timing is documented contract, not measured here.*
- **Polling has a failure mode event tracking does not: false positives** — tap
  `s`, then press Ctrl for the next action in the same batch, and a plain `s`
  executes as Ctrl+S. Non-reproducible, frame-boundary dependent, fires an action
  the user never typed. A better match for the unrecorded *"weird reaction to
  keyboard sometimes"* complaints than anything event tracking does. Lower
  framerate widens the window, so the Android target is the **worst** case.
- **The decisive asymmetry:** event tracking's failure is repairable *using the
  device*; polling's failure is repairable using nothing, because a value from
  the future is indistinguishable from a correct one.

## `src/harmony` — a whole subsystem nobody's context carried

Found by following the owner's question *"did this shadow table predate the
feature?"*. It did — verbatim at the PR base, by **aldum**, Apr–Nov 2025, and
`git diff 3256aac HEAD -- src/harmony/` is **empty**.

It is a scripted automation and screenshot harness, **not** part of `busted` and
**not** in CI, hand-run via `just one-harmony`. It replaces `love.run`, drops real
input when locked, and injects its own events — **except modifiers, which it fakes
by patching `love.keyboard.isDown` and never puts in the event stream at all**.

Two things follow. First, it is a **symptom of the polling architecture**, not a
precedent for the feature's model: faking the poll sufficed because polling was
all anyone did. Second — the owner's generalisation, and the real finding — it is
a **second implementation of the input surface**, so every system-wide input
change either breaks it or needs matching changes in it. Filed as **P13** (§10 of
the plan), with P9e amended in place to warn that it is the row that breaks it.

## What landed on disk

- **P13 + plan §9/§10** (`10793d52`) — the new phase, the P9e warning, and an
  assistant recommendation the owner overturned: deleting `patch_isDown` was
  wrong, because physical querying is a permitted project channel and the sandbox
  hands projects the real `love` table. The phase is additive.
- **"wedge" retired** (`bc8b5b28`) — zero occurrences at the PR base, so
  assistant-minted; already in three persistent-corpus sites; and carrying **two
  meanings** (stuck-with-nothing-to-clear vs blocked-from-completing). Replaced
  with the owner's own "stale" and with "block". Frozen artifacts and sub-agent
  deliverables deliberately untouched; the one record quoting a renamed test case
  got an appended `[S30]` citation note.
- **The input clock probe** (`f8c15c4e`) — `src/probe/input_probe.lua` plus
  `../../../validation/notes/S30-input-clock-probe.md`. Installs from the app's
  own console, so no source edit and no launch argument — the constraint the
  Android target imposes. Measures multi-event frames, self-skew and
  modifier-skew. **Behaviour proven on a fake gateway under LuaJIT**, including
  that its `love.update` wrapper re-applies itself when a route change reassigns
  `love.update`. The note pre-registers how to read the numbers, written before
  data exists.

## Intents recorded, and the scoping proposal awaiting a ruling

The owner's stated goal: **deliver the new input API for projects without
expanding the change surface uncontrollably.** The whole sprint grew inside-out
from one specific problem — the keyboard example rebuilt input functionality
in-project and depended on a `keypressed`/`textinput` delivery order.

Proposed decomposition, **not ruled on**:

- **A — the deliverable this sprint exists for.** P9b → P9c → P9d → P10 → P11 →
  close-out. **Q0-independent**: the rewritten keyboard design has no held read,
  no clock, no grace window.
- **B — the polling question.** Entry gate is **measurement on the device**, not
  argument. Then P9e, the 70 sites, the recovery path, P13.
- **C — moving upstream target.** P12.

Under that shape **P9e defers, and P13 defers with it** — and once P9e is gone,
P13 is a *capability gap, not a regression*, since harmony never could drive
project shortcuts (shortcuts did not exist pre-feature). **P9d stays in A**: a
stale set breaks project-facing combos, and a backgrounded Android app is the
real case.

**Q3, Q4 and Q5 all resolve to no-change** on the assistant's reading, so the
design agenda can close without adding surface. **Q1 splits**: P9d closes the
known cause in A; the general recovery path defers to B as debt.

## Open, and the successor's business

- **Nothing above is ruled.** Q0–Q5 and the A/B/C decomposition are all
  presented, not decided.
- **Two debt entries go stale if P9e defers** — `technical_debt/input.md:58` and
  `:77` both say "Scheduled: before the PR (plan phase P9d/P9e)"; `:77` becomes
  false. Not yet rewritten, pending the ruling.
- **A vocabulary sweep offered, not done:** "rows" for test cases — the owner
  ruled the word vague and costly to decode. ~19 uses in the persistent corpus
  (`technical_debt/input.md` 9, `tests.md` 7, `general.md` 3) plus many in `wip/`.
  Unlike "wedge" it may be inherited rather than assistant-minted, so it was left
  for judgement.
- **The probe has not been run.** It needs the device, i.e. the owner.
