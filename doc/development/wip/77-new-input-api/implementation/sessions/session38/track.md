# session38 — track

## 2026-08-12 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: `session38/` held only
  `prompt.md`, no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `3979151d` "docs(session37): correct the report — the capslock comment, and the tree line",
  branch `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked modifications**; only
  the known untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `doc/tall_blocks.md`, `worklog.md`, `repos.txt`) and the three nested example repos.
- **Baseline confirmed: `busted tests` → 946 / 0 / 0 / 10.** Matches the prompt; the 10 pending are
  the sanctioned count (3 routing-grid + 7 reserved-combo outlines), not drift.
- Nested `keyboard` at **`1f415c8`**, clean — matches the session37 report's corrected tree line.
- Read at boot: `agents/validation.md`, `agents/sessions.md`, this session's `prompt.md`,
  session37's `report.md` (including the addendum) and its `track.md` end-to-end.
- **Task as commissioned:** the last three P-18 children — **P-18-04** (`Ctrl+Alt+H` becomes a real
  shortcut dispatched through a new `onHint` descriptor entry), **P-18-05** (`compy.before_exit`
  restores the pointer mode), **P-18-06** (two comments: `bubble.lua`'s focus-loss caution, the
  Shift/Alt asymmetry note) — each its own commit, all in the nested `keyboard` repo, then **stop
  and ask**. Smoke-checklist rows must be updated in the same commits as 04 and 05.
- Reported the task to the owner before proceeding, as instructed.

## 2026-08-12 — owner reset the branch (force-push); then P-18-04 lands

- Owner: the branch was rewritten by rebase because an earlier commit had absorbed untracked files
  it should not have; **content unchanged, only commit ids moved** for the top three. HEAD is now
  `eec610b1` (was `3979151d`). Nested repos untouched, `keyboard` still `1f415c8`. Re-verified the
  tree myself rather than trusting the note: same working set, same suite.
- **P-18-04 landed — `e6c8f97` (keyboard) + `d4f628fa` (platform docs).** `sc["ctrl+alt+h"]`
  dispatched through a new `onHint` descriptor entry that only `alt.lua` defines; the hand-matched
  three-key test leaves `altKeypressed`. `fn.ignore_repeat` wraps the action (a shortcut sees every
  repeat; the hand match got that filter free from the hook), the trigger claim sits outside it.
- **Two behaviour changes I did not assume away, both recorded in the design of record and the
  comments** — the deviation rule says a commit message is not the workspace:
  - **A shortcut is swallowed in EVERY scene.** The hand match let a bare `h` reach the key-target
    games (press, find, bubble), where the teacher chord knocked as a wrong key. This is the one
    item in the step that touches §1.1's *"would a player notice a difference?"* test. Judged
    incidental — the other reserved chords already behave this way — but stated, not absorbed.
    **Owner's to overturn if they disagree.**
  - **The dispatcher keeps the pause gate** (`hintReenable` returns while `PAUSED`), because the
    hand match sat below `appKeypressed`'s PAUSED check. The notch does NOT, and that asymmetry is
    upstream's own: `reservedChord` ran above its `PAUSED` check there. Preserving each gesture's
    inherited gating beat making the two dispatchers look alike.
- **Measured, not assumed:** the app loads and runs under the line-buffered smoke command with no
  raise, which also proves the combo string registers (assignment normalises and errors on a bad
  combo). `ctrl+alt+h` is not a framework-reserved combo — the reserved set is `ctrl+alt+r`,
  `ctrl+alt+p`(`+shift`), `f10`, `ctrl+escape`, read in `controller.lua:817-843,885`.
- **A naming wart to flag:** `alt.lua`'s descriptor now carries both `noHint` (suppress the help
  hint/overlay) and `onHint` (re-arm the teacher hint). One letter apart, unrelated meanings. The
  owner ruled the name `onHint`; raising it rather than renaming.
- No game scene reached — as always. Rows `B11`/`B12` added to the checklist and owed by a human.

## 2026-08-12 — P-18-05 and P-18-06 land; P-18 is complete

- **P-18-05 — `6e58419` (keyboard) + `7f810d1e` (platform docs).** `compy.before_exit` restores the
  pointer mode. It restores **what the project found at boot**
  (`POINTER_RELATIVE_WAS = love.mouse.getRelativeMode()`), not a hardcoded `false` — and I measured
  `getRelativeMode` in real LÖVE before leaning on it (present, initial `false`, round-trips),
  because this sprint has now paid twice for library claims written from expectation.
- **The promoted question is promoted, not answered**, as the prompt required: whether the platform
  should tear down device modes a project changed lives in `technical_debt/input.md`, against the
  entry that already describes the framework-owned force-reset.
- **A FINDING while writing that up, and it is a third instance of the same fault:** that debt entry
  named `examples/keyboard`'s `setKeyRepeat(false)` as the canonical mutation. **The call has never
  existed in that repo** — `git log -S setKeyRepeat --all` returns nothing across all refs, and the
  platform's `src/main.lua:297` is the only caller, turning repeat **on**. Corrected to the two calls
  the project actually makes. Cost nothing this time because nothing was built on it.
- **P-18-06 — `c076e5f` (keyboard) + `86618f13` (platform docs).** `bubble.lua`'s hold judge gets the
  focus-loss caution and the reason it is allowed to stay on the release channel (it measures a
  duration; no poll answers that). The Shift/Alt asymmetry went into **`intro.lua`**, not `input.lua`
  — the hook already carried it at the guard, and the file whose behaviour it is said nothing. The
  bubble ruling also went into the design of record, which mentioned the judge without saying it was
  a decision.
- **State at stop:** platform HEAD `86618f13`, suite **946 / 0 / 0 / 10**; `keyboard` at `c076e5f`,
  clean; nothing pushed in any repo. The single `REMARK:` left in `input.lua:130` is the owner's
  (`setTextInput`), untouched.
- **Verification limit, unchanged and stated in every commit:** the app loads and runs; no game scene
  was reached. Rows `B11`, `B12` and `G1` join the checklist's `[new]` set and are owed by a human.
  `G1` in particular cannot be checked here at all — a timeout kill is not a stop path, so
  `before_exit` never fired in any run I made.

## 2026-08-12 — owner corrects the bubble reason; the four-commit pin; the cold pass runs

- **Owner: *"poll could measure duration same way as event-tracking does. But we let bubble stay on
  event-tracking path to let author make informed decision (they could have their reasons)."*** They
  are right and I was wrong: a poll accumulates while the device reports the key down — which is what
  `bubbleGrow` already does with its own clock. **I stated a capability limit that does not exist**,
  and it went into the comment *and* the document the comment cites — the exact two-artifact fault
  session37 ended on. Both corrected: `646674b` (keyboard) and `fd0e2c21` (platform).
- **The real reason is better than the one I invented:** the judging channel is the author's decision,
  they may have their reasons, and a migration should not quietly redesign what it was asked to carry
  across. That reads as respect for the author rather than as a technical excuse.
- **The four-commit pin (`073fb46c`)** — the smoke section now opens with the states any result must
  be quoted against: branch under test `646674b`, its upstream `origin/dsent/dev` `025e858`, platform
  `fd0e2c21`, platform edge upstream `dsent/dsent/dev` `9ed375d4`. Owner's reason: when smoke results
  land, four ids place any regression without a bisect. The table says to refresh them if the tree
  moved before the run — three of the four are living branches.
- **Cold Opus revalidation commissioned (owner):** the whole delta `025e858..646674b`, not the
  individual commits, against the P-18 mandate and intent. Model passed explicitly, read-only, told
  about the `lua-lsp` MCP server and told to MEASURE rather than reason (the previous cold pass found
  a live crash exactly there). Prompt of record `../../../validation/prompts/P-18-final-revalidation.md`;
  deliverable `../../../validation/reviews/S38-P18-final-revalidation.md`. Running.

## 2026-08-12 — the cold pass returns: mechanism SOUND, adoption NOT CLEAN (4 defects, 7 observations)

Deliverable `../../../validation/reviews/S38-P18-final-revalidation.md` (356 lines). It measured
against a harness driving the real `ProjectInputController` + `util/key` over the real `input.lua`.
**Verified each headline claim myself in code before relaying, per the charter:**

- **D1 (high) — CONFIRMED and it is the serious one.** `menuKeypressed` calls `gotoScene`
  **synchronously**, so on a keypress-first build the digit's own `textinput` lands on the scene it
  just opened and is judged as a wrong character: a knock on entry to games 4 and 5, every time.
  **Upstream was protected by accident** — `appKeypressed` set `INPUT.held[k]` *before* dispatching
  to the menu, so `inputStale` ate the digit. Our claim is taken only when Ctrl or Alt is down, so
  the protection went with the held set and nobody noticed. Verified: upstream `input.lua`'s
  handler order, `menu.lua:81-89`, and `gaugeStartLevel` → `phase = "glow"` at entry, so the gauge
  IS live. The order it needs is the one the owner attested for desktop Linux.
- **D2 (medium-low) — CONFIRMED against upstream.** `appChord` was *"Alt and not Ctrl"* and ran
  `if k == "p" then pauseToggle()`, so **Alt+Shift+P paused**. It now falls to `alt+shift+*`, which
  only claims. **Fifth member of the family** `c1ee63c` and `42d1a8b` restored four of — the one
  carrying an action, missed three times because `alt+p` is the one gesture NOT double-bound while
  the comment above says every gesture is.
- **D3 (low) — CONFIRMED.** `doc/input_api.md`'s "Held keys" rung 3 **is** `Key.any_pressed`, for
  exactly a non-modifier key, and says using `Key` for both kinds keeps one surface instead of two
  spellings in one expression — which is what `helpHeld` writes. The comment claiming *"Key has no
  answer for it"* is false. **The code is the owner's ruling** (keep the poll plain LÖVE so the heal
  can be offered upstream standalone); only the stated reason is wrong.
- **D4 (medium) — CONFIRMED in platform source.** `consoleController.lua:1420` — in `play` mode the
  console is disabled, so rows `D9`/`G1` cannot be *observed* under the launch the checklist itself
  gives. The hook does fire; the observation is impossible. Remedy is the checklist's, not the code's:
  run `love src`, open the project from the console, then Ctrl+Esc back to it.
- **O4 — the reviewer is right that a `REMARK:` sits in a third-party file, and WRONG about whose.**
  `git log -S` says `input.lua:130` came from `6eb7919 human(TF2): code review feedback`, authored by
  the owner. **Not mine to delete** — but the marker gate (`grep -rn 'INTERIM:\|REMARK:' src/ tests/`
  must be empty before the PR) covers nested repos, so it needs the owner's disposition.
- **O2 — verified independently:** upstream keeps **0** lines over 64 columns across these files; the
  branch has **26** (19 in `input.lua`, 3 `alt.lua`, 3 `main.lua`, 1 `intro.lua`), all comments. The
  author's convention, and the platform's own rule. Cheap; should not be left for them to find.
- **O7 is the sharpest of the observations and it is about MY choice:** restoring the value found at
  boot means that if a run ever ends by raising, the next run records the dirty `true` and faithfully
  restores `true` at its own clean stop — the mode never recovers. The reviewer would keep the
  measured restore (so would I) and wants the consequence named in the comment.
- **The verdict's other half, worth keeping:** +16 net code lines in `input.lua` retire an
  order-dependent stale filter, a frame counter and two bookkeeping handlers. **The apparatus bought
  predictability** — the strategic frame's question, answered by the reviewer independently.
  Its counter-charge is prose: 114 code / 177 comment in a file owned by someone else.
- **Nothing was landed from this.** Presented to the owner with dispositions; the sequencing is
  theirs.

## 2026-08-12 — owner reopens P-18 with three rulings; the plan is written before any work

Owner, on the cold pass: create substeps addressing **all named defects and critical observations**,
ending in a **new cold review under the same framing** with the four-tip anchor re-pinned to the new
`keyboard` head first. Plus three things:

- **One step must be reformatting + compaction of the new comments** in `keyboard`, against
  `agents/rules/commenting.md`.
- **"My remark should be reviewed and removed if it's resolved — otherwise escalated."** So the
  `REMARK:` at `input.lua:130` is disposed of by judgement, not swept.
- **"No comment should link to platform docs, it's a violation of integrity (different repo)."**

- **The citation ruling is the one with reach**, and I had it wrong in both directions: the standing
  rule (`commenting.md`, "Citations") says *cite a canonical `doc/…`*, which is right for platform
  sources and **wrong inside a repository that does not contain `doc/`**. Eight such citations exist
  in `keyboard`, **all introduced by this branch** (measured: upstream has zero `doc/` references;
  its own `docs/…` ones are the author's and stay). The rule file itself is amended by the plan, so
  the constraint binds every example repo — not just the one that got caught.
- **Written and committed BEFORE any of the work** (`db5377da`), as instructed: §9 of the step's
  triage carries the seven children, their ordering (07 → 08 → 11 → 10, then 09/12, **13 last**),
  and the three rulings; §15.4 of the parent plan gains an [S38] block saying the step is **not
  closed**. The cold pass's report is committed alongside them.
- **One decline recorded rather than dropped:** O5 (`claimChord` as a wrapper). It names intent at
  four call sites where the bare call reads as a discarded return value — unlike `isMod`, which hid
  a platform predicate for no gain. Owner's to overturn.
- **Not planned, deliberately:** nothing reopens the mechanism. The pass measured it in both delivery
  orders and reached the strategic frame's answer independently.

## 2026-08-12 — the batch executes: P-18-07 … P-18-13, seven children, all landed

- **P-18-07 (`4d2c881` + `74df3533`) — the menu digit claims its key.** MEASURED, fault and fix, in a
  throwaway harness under real LÖVE driving the **real** `menu.lua`/`scene.lua`/`input.lua` with the
  platform surface stubbed: keypressed-first order judged `"5"` before the fix and nothing after;
  textinput-first was harmless both ways. That harness is the "breaking test first" this repo cannot
  express as a test.
- **P-18-08 (`8a7b120` + `6545d633`) — `Alt+Shift+P` pauses again.** Also measured before/after by
  registering through `inputInit` and invoking the entries: `alt+shift+p` was **NOT REGISTERED**.
  Corrected the comment that hid it for three passes — *"each gesture is bound twice"* was true of
  every gesture except the one described two lines above it.
- **P-18-11 (`4983454` + `6725af9a`) — the owner's `REMARK:`, resolved rather than swept.** The
  `setTextInput(true)` it questions is **upstream's own line**; text input is already on where this
  is developed (**measured**); and the IDE makes the same call at boot under a block its authors
  label *"Android specific settings"* (`src/main.lua:296`). So the line is for running standalone on
  a device. **The Android half rests on the framework's comment, not on a measurement**, and says so.
- **P-18-10 (`1498f46`) — the comment sweep.** Comments only (verified by filtering the patch).
  Eight platform-doc citations gone, plus one platform decision number; 26 over-64 lines wrapped
  (only upstream's own remains); `input.lua` 177 comment lines → **101**, file 306 → **232**.
  What went: history git already holds, derivations, and second phrasings. What stayed: the reasons.
- **P-18-09 (`eb798ce0`)** — the exit rows get the IDE launch; `play` mode disables the console, so
  the rows were unobservable, not broken.
- **P-18-12 (`8a22ed24`)** — the citation ruling into `agents/rules/commenting.md` (binds every
  example repo, not just the one that got caught); the sub-frame re-press residue into the design of
  record; `Key.is_alt` joins `Key.is_mod` in P10's doc gap.
- **P-18-13 (`f267d7d1`, `ccd184c4`)** — anchor re-pinned to `1498f46` / `8a22ed24`, and the
  revalidation prompt records that it runs twice, with the second report a separate file so the first
  stays as the reason the children exist. **Second cold pass commissioned** against
  `025e858..1498f46`, told to form its own view BEFORE reading the first report, and told that the
  two new fixes deserve adversarial attention.
- **A process failure of mine, corrected within the minute:** `git add -A doc/` swept
  `doc/tall_blocks.md` — the owner's untracked scratch — into the P-18-07 docs commit. Exactly the
  defect the owner rebased the branch for this morning. `git reset --soft HEAD~1`, unstaged it and
  the session track, recommitted clean (`74df3533`). **The lesson is the rule I already had: name
  the paths, never `-A` at a directory the owner also works in.**
- Suite **946 / 0 / 0 / 10** at every commit; nothing pushed in either repo.

## 2026-08-12 — owner retires the "standalone" justification; the second batch lands

Owner, on my proposed F2 wording: *"the whole point of sprint is adoption so I would not consider
'dragging new API' a sin. The concern is softer -- merely renaming all function calls into their api
equivalents would be a migration without gain. But artificial preserving of old syntax where
replacement is justified also makes no sense."*

- **This retires the session37 ruling** that the release poll stays `love.keyboard.isDown` "for
  minimising the change". That ruling's ground was that the example is a standalone LÖVE program —
  **and it is not**: `config.lua:42` reads the platform global `Color`, in this branch **and in
  upstream**. I verified that before planning on it. So the test is no longer "can the game avoid the
  API" but **"is this replacement justified on its own terms"**.
- **P-18-14 (`7b0d542`)** — `ctrl+alt+shift+h`, the **sixth** dropped gesture, measured before/after.
  F3 dissolved with it. The uncomfortable part is mine: `8a7b120` restored the fifth member and I did
  not ask whether the binding I had written a commit earlier had the same hole.
- **P-18-15 (`d9ecdb0`)** — `inputTick`, the `pollable` probe and `helpHeld` ask `Key.any_pressed`.
  **Measured against the real platform `Key` module over the real `input.lua`**: accept, drop repeat,
  poll releases, re-claim works, `spendGlyph('~')` claims nothing and raises nothing.
- **P-18-16 (`1033252`)** — `words.lua` swept (14 comment lines over an 11-line function, all
  history) and the header stops calling the device build "standalone". **O1 was my sweep failing its
  own gate on the seventh file.**
- **P-18-17 (`a05a3829`)** — O2 into the design of record with the trade that justifies it; **O5 as a
  new debt entry**: a tolerant gesture costs one registration per variant and a missing variant is
  *silent*. Six were dropped in eleven lines and it took **three cold reviews** to converge — four,
  then one, then one. That is the entry's whole argument for the next project's migration.
- **P-18-18 (`ce6c3dcd`)** — anchor re-pinned to `1033252` / `a05a3829`; third cold pass commissioned
  against `025e858..1033252`, told about the dropped-gesture class explicitly and asked whether a
  seventh exists.
- **O4 declined** in the plan with its reason (Ctrl held, then Alt, no longer skips the intro), owner
  to overturn. Suite **946 / 0 / 0 / 10** throughout; nothing pushed.

## 2026-08-12 — third cold pass: SOUND, and it answers the question it was commissioned for

Deliverable `../../../validation/reviews/S38-P18-final-revalidation-3.md`.

- **No seventh dropped gesture, and this is the first pass that PROVED it rather than looked.** It
  built a parity harness — real `util/key.lua` + real `projectInputController.lua` driving the game's
  real `input.lua`, against **upstream's `input.lua` unmodified** — and diffed **105 fresh-press
  stimuli** (8 modifier subsets × 15 triggers) and the same 105 as OS repeats. All six shift-tolerant
  gestures reproduce, `ctrl+alt+shift+h` included; on repeats the only effect any stimulus produces is
  `capsToggle` for capslock, matching upstream's exemption exactly. **The whole parity diff is three
  lines, all bare-modifier presses, all observable only in the intro typewriter.**
- **Everything the second pass raised is fixed** (F1, F2, F3, O1, O2 verified from the code, not from
  my commit messages), O3 partly (B13 landed; the swallow row still missing), O5 recorded as debt.
- **One defect, low, and it is mine — `words.lua:144-146`.** `wordsBaseKey`'s comment still says
  *"else the glyph itself"* while the body forwards to `glyphBaseKey`, which inverts `SHIFT_MAP` —
  the branch that stops smoke row C5 crashing. **The commit that swept `words.lua` walked past the one
  comment in that file that had gone stale.** Verified.
- **My debt entry was stale on arrival:** it says the example pays **eleven** registrations; the code
  has **twelve**, because P-18-14 added the twelfth in the same batch. Verified by count. The entry's
  argument is unaffected and its number is wrong, which is the exact failure it warns about.
- **A behaviour delta for the owner, sibling of the declined O4:** with **Alt held, pressing Shift**
  now reaches the scene where upstream swallowed it. `intro.lua`'s comment says the Shift/Alt
  asymmetry is left as it is — true for lone presses, false for modified ones, in both directions.
  **Not decided here.**
- Comment economy nits: `bubble.lua`'s block ships five lines of review dialogue into a third party's
  file (the caution is the payload); `main.lua`'s trailing comment repeats its own header;
  `input.lua:11` has a ragged wrap and a `setTextInput` rationale that says the line is needed and
  then that it is not.
- **The limit, restated by the reviewer and worth keeping in the report:** nothing in this work has
  ever run in a game scene, at any head, by anyone. Everything about what a player sees is inference
  from driven paths. **The human smoke pass is the only gate left that can change that.**

## 2026-08-12 — owner: close the deltas, delegate the tidy, review narrowly

Three instructions, all executed after the plan was written and committed (`89623c1a`).

- **P-18-19 (`80bca7b`) — the parity diff is now ZERO, and that is measured with the reviewer's own
  instrument.** One line: the unconditional `if Key.is_alt(k) then return end` becomes
  `if Key.alt() and not Key.ctrl() and Key.is_mod(k) then return end` — which is exactly what
  upstream's `appChord` did (swallow everything while Alt is held without Ctrl) minus what the combo
  classes already take (every non-modifier trigger). It closes **all three** deltas at once: Ctrl+Alt
  and Ctrl+Shift+Alt reach the scene again, and Alt+Shift is swallowed again.
  **Re-ran the third pass's harness: 3 differing rows → 0, over 105 fresh-press stimuli; on 105
  repeats the only effect any stimulus produces is `capsToggle` for capslock, as upstream.**
  This overturns my own declined O4 — the owner ruled the deltas closed rather than documented, and
  they were right: one condition removed three exceptions and made `intro.lua`'s note true without a
  qualifier.
- **P-18-20 (`f09f1e7` + `7e009536`) — delegated, and the supervision earned its keep.** Sonnet,
  model explicit, prompt of record `../../../validation/prompts/P-18-20-tidy.md`, report in
  `outcomes/`, no git state touched. The four corrections are good. **One edit I moved:** the worker
  trimmed `main.lua`'s trailing comment to one line; I deleted it and folded its only real claim
  (love.* would work — the framework captures it) into `input.lua`'s header, where the registration
  choice is actually described. An orphan comment at end of file is not where a reader looks.
- **P-18-21** — narrow review commissioned: **only** `1033252..f09f1e7` and the doc commits, judged
  against the third pass's stated dispositions, with the parity claim to verify itself. Explicitly
  told not to re-audit what the third pass already cleared.
- Anchor re-pinned (`255c83be`) with the fact that is new at this head: **parity with upstream is
  zero**. Suite 946 / 0 / 0 / 10 throughout; nothing pushed in either repo.

## 2026-08-12 — P-18-21: the narrow review clears the batch, and corrects three counts of mine

- **Verdict: the batch discharges the third pass's findings; the parity closure is sound; no
  defects.** Its dispositions: D1 fixed, O1 closed rather than documented (correctly), O2 fixed,
  O3(b) fixed, O4/O5/O6a/b fixed, O6c untouched and harmless.
- **It measured better than the claim it was checking**, which is the point of a narrow review done
  well: it verified the harness's upstream copy **byte-identical to `025e858:input.lua`** before
  trusting it, **wrote its own upstream repeat driver** (the previous pass had reasoned that half),
  and **widened the sweep to 385 stimuli** including right-hand and mixed l/r modifier holds the
  fixed harness never exercised. Zero differences in every sweep; the pre-fix head reproduces exactly
  the three rows.
- **Its one substantive finding is the thing the closure genuinely introduced, and it is landed
  (`e568961`):** my guard asked `Key.alt()` even for Alt's own press, so the swallow depended on the
  device already reporting Alt down inside Alt's own `keypressed`. **That is exactly the class of
  assumption this whole mechanism exists to remove**, and the guard it replaced was order-free. Now
  the name answers for Alt's own press and the device answers for the rest. Parity re-measured: still
  zero, repeats byte-identical.
- **Three counts of mine were wrong**, and the batch had just fixed a count error of the same shape:
  the sweep is **108** stimuli, not 105 (I repeated the reviewer's number into two documents); the
  smoke pass owes **eighteen** `[new]` rows, not thirteen; and the delegated worker's outcome report
  quotes a `main.lua` comment that does not exist, because I moved that edit and recorded the move
  only in a commit message. All three corrected, the last one **in the report itself**, since that is
  the artifact a reader opens.
- **The step is closed to this container** (`84b6e0c5`): four independent passes, every finding
  dispositioned, parity with upstream **zero**, suite unmoved at 946 / 0 / 0 / 10, nothing pushed.
  Anchor pinned at `e568961` / `534bd174`. **What remains is the human smoke pass and only that.**

## 2026-08-12 — WRAP

- Report written (`session38/report.md`), successor prompt written (`session39/prompt.md`), pointer
  repointed to session39 in `agents/validation.md`.
- **The successor's task is the owner's, and it is about METHOD:** P-17 (`maze`), performed the way
  session37 performed P-18-00 — find that session, read its report and track, read the artifacts its
  pass produced, then apply the same sequence: **upstream input assessment written BEFORE any merge**,
  the merge with its defect corrected in its own commit, then analysis/design, then a triage that
  decomposes the step into numbered children with the owner's rulings named first.
- Deviation from `agents/sessions.md` §5 recorded **in the successor prompt itself**: a judgment-heavy
  session's successor would default to a revalidation task, and that revalidation happened *inside*
  this session — four independent cold passes, the last narrow. The owner named the task instead.
- `maze` facts verified at wrap and written into the prompt as *"verify, do not trust"*: `newinput`
  at `a045fdb`, clean; upstream `dsent/dsent/dev` (the `dsent` remote, not `origin`); **4 ahead / 26
  behind**, merge-base `12f675f`, delta 37 files / +4920 −1208; `origin/v3.4` is its PR base today
  and `pr-assembly-guide.md` §5.1 says the slice ref moves only when P-17-00 merges.
- Final state: platform `84b6e0c5` + this wrap; `keyboard` `e568961`, clean; `maze` `a045fdb`,
  untouched. Suite **946 / 0 / 0 / 10**. **Nothing pushed in any repo.**
