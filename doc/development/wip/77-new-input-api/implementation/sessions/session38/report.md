# session38 — report

**Commissioned as:** finish P-18's last three children (`P-18-04`, `P-18-05`, `P-18-06`), then stop
and ask.

**Ran as:** that, and then three further batches the owner opened on the back of **four independent
cold revalidations** — which reopened the step twice, produced two live regressions to fix, and ended
with the game's gesture behaviour **provably identical to upstream**.

**Tree at wrap:** platform suite **946 / 0 / 0 / 10** at every commit — no platform code was touched
this session. `keyboard` at **`e568961`**, clean; `maze` untouched at `a045fdb`. **Nothing pushed, in
any repo.** The smoke anchor pins `keyboard e568961` / `upstream 025e858` / `platform 84b6e0c5` /
`edge dsent/dsent/dev 9ed375d4`.

**P-18 is closed to this container.** What remains cannot be settled here.

---

## What landed

**The three commissioned children.** `Ctrl+Alt+H` became a real shortcut dispatched through a new
`onHint` descriptor entry (the shape `onNotch` already had, so no `leave` hook); `compy.before_exit`
restores the pointer mode the project found at boot; and the two comments the step still owed.

**Then the owner commissioned a cold pass over the whole delta against upstream, and it reopened the
step.** Three more batches followed — `P-18-07 … P-18-13`, `P-18-14 … P-18-18`, `P-18-19 … P-18-21` —
each planned on disk **before** any work, each ending in another independent review. The execution
record is §§8-11 of `../../../validation/reviews/P-18-00-triage-and-plan.md`; the four reports are
`S38-P18-final-revalidation{,-2,-3}.md` and `S38-P18-narrow-review.md`.

**Two live regressions against upstream, both found by cold passes, both mine:**

- **The menu digit was judged by the game it opened.** `gotoScene` runs inside `menuKeypressed`, so
  on a keypress-first build the digit's own `textinput` lands on the scene just opened and knocks.
  Upstream was protected **by accident** — its held set was written before the menu dispatch — and
  that protection left with the set. Fixed by the design's own rule one level up: *whoever consumes a
  key owns it*.
- **Six gestures that tolerate an extra modifier had been dropped by the combo conversion.** Four
  were restored before this session, the fifth and sixth here — `Alt+Shift+P` and
  `Ctrl+Alt+Shift+H`. Each was found *after* a fix for the previous one had been written by someone
  who had just read the rule and the bindings together.

**And the last three behavioural differences of any kind were closed** (`80bca7b`, refined by
`e568961`): one condition in `appKeypressed` replaced an unconditional bare-Alt guard with what
upstream's `appChord` actually did. **Measured, not argued** — the third review's parity harness
replays every (modifier subset × trigger) press through the real dispatcher against upstream's
unmodified `input.lua`: **3 differing rows → 0**, and the narrow review re-measured it at 108 and
then 385 stimuli, including right-hand and mixed l/r holds, still zero.

---

## The five things a successor should not have to rediscover

1. **Every cold pass paid for itself, and the class of finding changed each time.** Pass 1: four
   defects including a live regression. Pass 2: one regression, plus a false reason I had written to
   replace a false reason it had just removed. Pass 3: **proved a negative** — a parity harness, no
   seventh dropped gesture. Pass 4 (narrow, over the fix batch only): no defects, but it caught the
   one assumption the fix introduced. **A review that only inspects converges slower than one that
   builds an instrument.**
2. **The combo model's cost is now a debt entry, and it is the session's most transferable finding.**
   A gesture that tolerates a modifier needs **one registration per variant**, and a missing variant
   is *silent* — it looks exactly like correct code. Six were lost inside twelve registrations, and
   it took three independent reviews to converge. `technical_debt/input.md`, *"A gesture that
   tolerates a modifier costs one registration per variant"*.
3. **No comment in an example repo may cite a platform doc** (owner ruling). `src/examples/*` are
   separate repositories; a `doc/…` path cannot be followed from a tree that does not contain it, and
   shipping one into a third party's file is an integrity problem, not a broken link. Eight had crept
   in, all ours. The rule is in `agents/rules/commenting.md` and binds every example repo.
4. **"Adoption is the point of the sprint"** (owner ruling, and it retired an earlier one). The test
   for a remaining `love.*` call is not *"can the game avoid the API"* but *"is the replacement
   justified on its own terms"* — renaming for its own sake and preserving old syntax where
   replacement is justified are equally pointless. The polls now ask `Key.any_pressed`.
5. **The example never ran standalone.** `config.lua` reads the platform global `Color`, in this
   branch and in upstream alike. Two justifications rested on the opposite and both were false.

## Things a successor will otherwise misread

- **A count in a document is a claim like any other.** Three of mine were wrong this session
  (eleven-vs-twelve registrations; 105-vs-108 stimuli; thirteen-vs-eighteen `[new]` rows), and one of
  them was stale *the moment it was written*, in the very entry that warns about silent miscounts.
- **A delegated worker's report is not the tree.** One edit was moved after review, and the outcome
  file quoted a comment that no longer existed until a reviewer caught it. The move is now recorded
  in the report, not only in a commit message.
- **`git add -A` in a directory the owner also works in swept an untracked file of theirs into a
  commit** — the exact defect they had rebased the branch to remove that morning. Caught and
  corrected within the minute (`git reset --soft`, unstage, recommit). **Name the paths.**
- **Nothing in this work has ever run in a game scene, at any head, by anyone.** Every claim about
  what a player sees is inference from driven paths. `doc/development/smoke_checklists.md` now has
  **eighteen `[new]` rows** and is the only gate that can change that.
