# session37 — report

**Commissioned as:** execute P18, the keyboard deepfix, *blocked on a prerequisite you do not own*.
**Ran as:** that prerequisite (the upstream merge, ruled to this session), then the step's analysis
and design pass with the owner, then execution of four of the six children it produced.

**Tree at wrap:** platform `HEAD` after this wrap commit; suite **946 / 0 / 0 / 10** throughout — no
platform code was touched this session. Nested repos: `keyboard` at **`c3388de`**, clean;
`maze` at `a045fdb`, clean. **Nothing pushed, in any repo.**

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
dissolution and `isMod` (that one by a supervised Sonnet worker, diff reviewed site by site).

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
