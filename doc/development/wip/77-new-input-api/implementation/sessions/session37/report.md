# session37 — report

**Commissioned as:** execute P18, the keyboard deepfix, *blocked on a prerequisite you do not own*.
**Ran as:** that prerequisite (the upstream merge, ruled to this session), then the step's analysis
and design pass with the owner, then execution of four of the six children it produced.

**Tree at wrap:** suite **946 / 0 / 0 / 10** throughout — no platform code was touched this session.
Nested repos: `keyboard` at **`ece2c1b`**, clean; `maze` at `a045fdb`, clean. **Nothing pushed, in
any repo.**

**This session was wrapped once and then reopened** — the owner questioned one of the landed edits and
commissioned a cold revalidation, which found a crash. Everything after the first wrap is the
**addendum at the end of this report**, and it matters more than most of what preceded it.

---

## What landed

**The upstream merge for `keyboard` (`17289e9`)** — 36 commits, 24 files, +5227/−804, a true merge
with ancestry preserved so later re-merges stay cheap; the upstream snapshot sits on
`upstream-dsent-dev-20260811` and the pre-merge state is `05cedec`. The owner ruled the shape after
asking whether a merge backfills history; it does not.

**The merge's known defect, corrected in its own commit (`ca6d5df`)** — the clean merge produced a
*broken tree*. Upstream's new `words.lua` judges typing with `inputStale`, the held-key filter this
branch deleted, and no hunk touches both files, so git could not see it: Words raised on the first
character typed.

**P-18-00, the analysis and design pass** — two documents. `P-18-00-keyboard-deepfix-design.md` holds
the exposition, the requirements R1–R5, an impossibility result, and the mechanism. `P-18-00-triage-and-plan.md`
holds a cold Opus inventory of what upstream needs (26 sites), set against what this branch had
already landed, four owner rulings and the six children.

**Four children executed** — `c60b818` the heal, `c1ee63c` the restorations, `c3388de` the proxy
dissolution (by a supervised Sonnet worker, diff reviewed site by site). Then the addendum below.

---

## The five things a successor should not have to rediscover

1. **The merge vindicated the ordering ruling in a way nobody predicted.** The stale-base argument
   was aimed at `input.lua`; upstream never touched it. What it actually broke was a *second*
   `textinput` consumer that did not exist when the heal was designed — so the ratified design's
   central premise ("one judge") was false before a line of it was written.
2. **The design of record predicted its own violation and named the trigger.** Its precondition
   section says *"if a later stage ever asks the player to type a word, this design must be
   revisited — `lastText` would be deduplicating the letters of the answer against each other"*.
   Words is that stage. `"all"` was untypeable under the ratified rule.
3. **The mechanism ended up smaller than the design it replaced, and the owner's corrections are why.**
   Their release-clear, then their filter/judgement split, then the poll — each step deleted
   something: the grace window, the frame stamp borrowed from the debug logger, the `blocked` field,
   the content test, and finally `keyreleased` as a judgement channel. **A claim is taken by the
   character and released by the device.**
4. **Two behaviour narrowings had been sitting in the tree unruled since `ced8f40`**, found by the
   cold pass, not by us: combos are exact modifier sets, so Alt+Shift+Esc and Ctrl+Alt+Shift+Up had
   stopped working. Both are restored (`c1ee63c`), not accepted.
5. **The example's own header is a list of six gaps in the pre-feature platform** — the author
   documented each workaround and why. **Four are closed by this feature.** That is the PR
   description's best sentence and it is the author's testimony, not ours.

## Things a successor will otherwise misread

- **The heal is NOT arguable from focus loss.** The owner ruled that focus-shaped risks are
  tolerable and that a risk cleared by repeating a chord is an inconvenience. The heal's case is
  ordinary typing: clearing a claim on `keyreleased` admits a trailing repeat as a character nobody
  typed — which is what `INPUT_UP_GRACE` existed to swallow.
- **`bubble.lua` is deliberately untouched**, and that is a ruling, not an omission: its only failure
  is a lost release and its own timeout absorbs it. P-18-06 owes it a comment.
- **The capslock exemption is identical to upstream's**, so there is no deviation to accept — only a
  comment stating a reason that died with the held set.
- **`love.keyboard.isDown` in the poll is deliberate** (owner, for minimising the change), with the
  comment naming `Key.any_pressed` as the platform's form.
- **Nothing was verified in a game scene.** Every smoke pass reached the intro; the container cannot
  inject keystrokes. Three items are owed by a human and are listed in the triage's §4.
- **`agents/validation.md`'s baseline line is still right at 946** — the suite never moved, because
  the whole session's code work was in a nested repo with no tests.


---

# Addendum — after the first wrap

The wrap was undone by two owner interventions, in this order.

## 1. The `isMod` wrapper — `9a20433`

The owner asked why `isMod` was left as a one-line function whose body is `Key.is_mod(k)`. It was an
**inconsistency in my own reasoning**: I had deleted the `INPUT` proxy *because* it was a pure alias
for `Key`, then kept a pure alias for `Key.is_mod`. The wrapper is gone and the six call sites ask the
platform predicate. The only real argument for keeping it — confining a member that
`doc/input_api.md` does not document — is a documentation gap (P10's), not a reason to keep an alias.

## 2. A cold Opus revalidation of the landed work — **sound in design, unsound as landed**

Commissioned by the owner before handover, *"asking you because you would be able to handle
objections/corrections if they arise"*. Prompt `../../../validation/prompts/P-18-revalidation.md`,
report `../../../validation/reviews/S37-P18-revalidation.md`. **Nine findings; the three that
mattered were mine.** Full record: §7 of `../../../validation/reviews/P-18-00-triage-and-plan.md`.

**I disclosed one thing to it up front rather than let it find it:** §15.4 requires the design of
record to be revised *before* the code that assumes it, and I had landed the code without doing so.
That is discharged now — the note is rewritten.

- **A live crash, and its root cause was a sentence I wrote.** The design document asserted that the
  claim poll "rescues" a key it cannot name because `isDown` returns false for it. **`isDown`
  raises** — `"Invalid key constant: ~"`. `wordsBaseKey` returned the produced character itself, so a
  shifted symbol typed in Words claimed `"~"` and the next `love.update` errored outside any `pcall`:
  **one keystroke dropped the child to an error screen.** Fixed in **`52a8d69`** — `glyphBaseKey`
  moves to `input.lua` (the one item of the design's own "diff, in full" that had not landed) and a
  claim that cannot be polled is never taken.
- **A false claim in my own commit message**, concealing a gap: `c60b818` called the trailing-character
  leak one the game "has always had". Upstream had none — its held set suppressed those characters for
  *every* chord. The leak is this branch's, and my fix covered only the swallowed Alt class.
  **`42d1a8b`** claims the trigger whenever Ctrl or Alt is down, and registers `alt+shift+*` for a
  **fourth** narrowing of the family `c1ee63c` restored three of.
- **`ece2c1b`** — `indicators.lua`'s comment said the Shift state is *"edge-tracked, not isDown"* when
  its caller now passes exactly `isDown`.

## 3. The documents the code had outrun

- **`doc/development/internals/examples/keyboard.md` rewritten** (`4efff4b4`). It described a
  recommended design that was never implemented and that the merge had falsified. It now describes the
  shipped mechanism, both consumers, why the release is a poll, the chord rule, the
  unpollable-character residue, and the capslock exemption's true reason.
- **The design document's false sentence corrected in place**, with the error named.
- **`doc/development/smoke_checklists.md` created** (`d239c62c`) — the human gate had no written form.
  Persistent, so it outlives `wip/77`; `keyboard`'s section is a literal run sheet with the eight menu
  entries by number, and **ten cases marked `[new]`** that have never been run by a human. Referenced
  from `tests.md`, Phase G, the P-18 step, and the design note — whose own checklist became a pointer,
  so there is one list to keep current rather than two that drift.

## What the addendum changes about the handover

**`keyboard` is at `ece2c1b`, not `c3388de`.** P-18-06 **shrank** — the capslock comment and
`indicators.lua` are done. The remaining children are unchanged: **P-18-04**, **P-18-05**, and
P-18-06's two remaining comments.

## The lesson, because it happened twice in one session

Both times, a claim about library or platform behaviour was written **from expectation rather than
measurement**, propagated into a document, and then into code. The first cost a stale platform
sentence in the persistent corpus. The second cost a crash. **Measuring took one throwaway LÖVE
script and twenty seconds** — and that script, run against the real file, is also what proved the fix.
