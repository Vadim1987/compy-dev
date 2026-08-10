# S36 P14e Cold Revalidation

**Verdict: SOUND-WITH-FINDINGS.** The examples reconciliation did what §11.4.3 required, in every
enumerated site I could check against the tree; nothing behaviour-changing was swept in beyond
the mandate; the code, `doc/input_api.md`, the internals docs and the debt register agree with
each other about what the examples now do; and the deferred work is honestly recorded and, where
checked, cited accurately (exact file:line matches). The findings below are calibration/process
observations, not defects in the shipped behaviour.

## Method

Read in full: the commission, `S27-triage-and-plan.md` §11.4.3 (the operative step), §14.1–14.4
(reasoning/ladder/hint), §11.6 (register instructions), §15.1–15.2 (the P16 addition),
`agents/validation.md` "The strategic frame". Read `git show` for all 9 platform commits
(`7c08230c..HEAD`) and the two detached-repo commits in place (`cd src/examples/{keyboard,maze}
&& git show <sha>`). Verified `balloons` independently (grep, not just re-read the claim). Cross-checked
every debt-register entry's file:line against the actual current file content. Ran `busted tests`.
Ran `lua-lsp` diagnostics on the three touched in-repo files. Grepped the whole `src/examples`
tree for residual `keys_pressed`/`modHeld`/`is_shift_down`/raw `lshift`+`rshift`-style folds as a
completeness backstop against the LSP (which cannot see the metatable `__index` dispatch the
keyboard example uses).

## Q1 — Did it do what the step says?

Every site §11.4.3 names is either converted as specified or explicitly recorded as needing
nothing, and I found no gaps:

- **`keyboard` (`05cedec`, detached repo).** `input.lua`'s `INPUT.__index` `held` branch removed;
  `shift`/`ctrl`/`alt` branches now call `Key.shift()/ctrl()/alt()` (`input.lua:56-61` post-edit).
  `modHeld` deleted (was `:108-114`). `help.lua:16-19`'s `helpHeld` now asks
  `love.keyboard.isDown("h")` directly, matching the "not a modifier" last-rung case. Header prose
  re-reasoned (no longer describes a framework-kept set). Confirmed the claimed "9 of 11 reads need
  no edit" pattern directly: `alt.lua:203,230,240`, `input.lua:188,189,191,193`,
  `keyboard_view.lua:171,178` all still read `INPUT.shift/.ctrl/.alt` unedited and are insulated by
  the proxy fix.
- **`maze` (`a045fdb`, detached repo).** `is_shift_down()` deleted, `main.lua:568` now
  `not Key.shift()`. Exact line match.
- **`balloons`.** Independently grepped (`isDown|keys_pressed|held|INPUT\.` across all `.lua`) —
  zero hits. No commit touched it. "Clean and closed" confirmed, not merely re-asserted.
- **Platform `turtle`/`clock` (`5c3ca84b`).** `turtle/main.lua:34,92` and `clock/main.lua:69,78`
  (both call sites, including the one the step didn't originally name) now call `Key.shift()`/
  `Key.ctrl()`. `lua-lsp` diagnostics clean on both files.
- **Platform `sapper` (`cc434f9b`).** The four-site modifier cascade collapsed into
  `shortcuts.singleclick['shift+*']`/`['ctrl+*']` plus bare hooks; `love.mousepressed` removed.
  Verified the technical claim directly in `src/controller/projectInputController.lua:104-114`
  (`find_shortcut`'s no-trigger branch: guarded by `any_mod()`, then
  `combo_string('*')` folds every held modifier) — `'shift+*'` really does mean "shift and only
  shift". `lua-lsp` diagnostics clean.
- **Docs.** `doc/input_api.md` "Held keys" already taught the corrected 3-rung ladder (predates
  this step, from P14a) and needed no P14e edit; `gui` removed from its combo-order sentence
  (`5d342bbe`) — confirmed against `Key.mod_triples`/`COMBO_MODS` in `controller.lua:382` (3 rows:
  ctrl/alt/shift), so the docs fix matches the code exactly. `internals/examples/sapper.md` and
  `index.md` updated to describe the new shape and the two deviations (`f71f5630`);
  `internals/examples/turtle.md` corrected to quote `Key.ctrl()` instead of the removed
  `isDown("lctrl","rctrl")` and to fix a channel mislabel (`bd3ad646`) — verified against
  `turtle/main.lua`: `shift+r` is genuinely on `love.keypressed` (`:34`), `ctrl+escape` genuinely
  on `love.keyreleased` (`:92`), matching the corrected prose exactly.
- **Debt register (`3e8d6a5c`).** New section "Examples are not onboarded onto the new input API"
  with 8 site entries. **Every entry's file:line was checked against the live file and matched
  exactly** (not approximately): `maze/main.lua:568`, `maze/main.lua:514-526`, `maze/macro.lua:74,89`,
  `keyboard/alt.lua:203`, `keyboard/help.lua:16-19`, `keyboard/input.lua:109`,
  `turtle/main.lua:34,92`, `clock/main.lua:69,78`. The `turtle` Ctrl+Escape "deletion, not rung"
  question was independently verified: `controller.lua:883-892`'s `handlers.keyreleased` checks
  `Key.ctrl()` + `k=="escape"` and calls `love.event.quit()` **without returning** — it falls
  through to call the project's own `love.keyreleased` unconditionally, so both really do fire to
  the same end, exactly as claimed.
- **Suite.** `busted tests` → **942 successes / 0 failures / 0 errors / 10 pending**, matching the
  claim exactly, run cold by me.

## Q2 — Did it do anything the step does NOT authorise?

- **No `REMARK:`/`INTERIM:` marker was touched.** Checked all 9 platform commits' diffs plus both
  detached-repo commits for added/removed `REMARK:`/`INTERIM:` lines — none. (One context line
  containing the literal word `REMARK` appears unmodified inside a quoted plan-table row in two
  commits; it is not a diff hunk touching a marker.)
- **No unrelated owner working-tree change was absorbed**, as far as I can tell: `git status` on
  the platform repo and all three detached repos shows nothing beyond the reviewed commits and
  pre-existing, unrelated untracked scratch (this session's own track/prompt files, `balloons`'
  pre-existing untracked docs). Neither `keyboard` nor `maze` shows uncommitted residue now.
- **`keyboard`'s "half-finished uncommitted comment reword" claim.** I can't independently
  reconstruct the pre-commit working-tree diff (it's already folded into `05cedec`), so I can't
  verify from git alone that this really was sitting uncommitted rather than being new prose the
  author wrote. What I *can* say: the reworded passage (the capslock-exemption paragraph explaining
  what can go stale) is on-topic for the step's own prose work (re-reasoning the header/proxy
  commentary after the removal), is disclosed in the commit message rather than hidden, and reads
  as one coherent edit rather than two concerns awkwardly stitched — so if it was absorbed, it was
  absorbed openly and on-topic. **Listed under "what I could not determine" below, not as a
  finding**, since nothing in the evidence contradicts the claim.
- **Minor scope-boundary observation (not a violation): `maze/macro.lua:74,89`.** The debt-register
  entry for `macro_state.shift_held` extends the sweep to a site that reads neither the dissolved
  `keys_pressed` set nor `Key`/`love.keyboard.isDown` — it's a project-maintained boolean mirrored
  across `keypressed`/`keyreleased` via a static `SHIFT_KEYS` name table
  (`maze/macro.lua:6-7`), never polling the device at all. Strictly, this site isn't "triggered" by
  either of the two named platform changes (removal of the tracked set; the ladder) — the two
  changes that define the mandate's boundary. It resembles the *pattern* the step keeps meeting
  (a hand-rolled mirror of what the framework now offers), which is presumably why it got listed,
  and I don't think listing it in the debt register (no code changed, nothing declared "clean and
  closed" incorrectly) does real harm — but it is technically a documentation-only widening of the
  sweep's reach beyond its own stated trigger, worth naming per the commission's "however sensible
  it looks" instruction. Low severity: no code or behaviour was touched, and the entry is honestly
  reasoned in place, not smuggled in.
- **`855b4ef5`** amends `agents/validation.md` (a process/rules file) with a standing commit-granularity
  rule following an owner directive surfaced *during* this very step. This is outside "examples
  reconciliation" in subject matter, but it is (a) explicitly an owner directive, (b) its own
  isolated commit touching no example code, and (c) exactly the kind of governance amendment
  `agents/validation.md`'s own rules anticipate. Not a mandate violation; noted for completeness.

## Q3 — Is what landed appropriate and internally consistent?

- **Sapper's two deviations, checked against the matcher, not just the commit prose:**
  confirmed both — the "unclaimed modified click now acts as plain click" via
  `find_shortcut`'s fallthrough when `combo_string('*')` matches neither registered class key, and
  "derived clicks are button-1-only, on release, after the double-click window" via
  `controller.lua:913-922`'s `handlers.mousereleased` (`if btn == 1 then ... click_timer =
  click_delay`).
  Both deviations are recorded in **three** places, satisfying the "not commit-message-only" rule
  the author retroactively wrote into `agents/validation.md` in `855b4ef5`: the code comment
  (`sapper/main.lua:690-698`), the internals doc (`internals/examples/sapper.md`, "Click
  handling"), and the commit message.
- **`gui` doc fix matches code exactly**: `Key.mod_triples`/`COMBO_MODS` (`controller.lua:380-382`)
  has exactly 3 rows (ctrl, alt, shift); the corrected `doc/input_api.md` sentence says the same.
  `Decision 31` in `doc/development/decisions/input.md:1349` independently confirms the set is
  closed to those three.
- **No stale references to the dissolved API remain** anywhere under
  `doc/development/internals/examples/` or `doc/input_api.md` (grepped for `keys_pressed` and
  `INPUT.held` — zero hits).
- **`Key` global reachability, verified rather than assumed** (per the commission's explicit ask):
  `Key = {...}` is a true global (no `local`) in `src/util/key.lua:164`; `require("util.key")` runs
  in `src/main.lua` ahead of `ConsoleController.new`'s `getfenv()` capture
  (`doc/development/internals/project_sandbox_env.md`), so every project sandbox env's clone
  carries a (deep-cloned table, shared-by-reference function leaves) `Key`. The commission's claim
  holds.

## Q4 — Is the deferred work honestly recorded?

Yes. All 8 debt-register site entries were checked against the live file at the cited line and
matched exactly (see Q1). Each carries what it would become, and why it was declined (behaviour
change / control-flow restructure / both), consistent with §11.4.3's cap. The `keyboard/input.lua:109`
`isMod` entry is explicitly self-labelled inside the register as "not a held-state read... outside
the reconciliation's sweep" — the author is transparent about it being adjacent information, not a
declined conversion, which is the right way to disclose a borderline inclusion (same category as
the `macro.lua` observation above, but here it's caveated in-line rather than presented as a peer
entry).

## Findings, ranked

1. **(Low) `maze/macro.lua:74,89` debt-register entry sits outside the mandate's own stated
   trigger.** No code was touched and the reasoning is disclosed in place, so this is a
   documentation-only widening, not a behavioural or process violation. Worth a note to whoever
   works P16, since the entry's "why it belongs here" leans on pattern resemblance rather than the
   two named changes the mandate itself uses as the filter.
2. **(Informational) The keyboard repo's "completed rather than reverted" uncommitted comment
   claim cannot be independently verified from git alone** — see "what I could not determine".
   Nothing contradicts it; it's a gap in what's checkable, not a discrepancy.

No finding rises to "unsound." I found zero cases where a commit's technical claim about matcher
or dispatch behaviour didn't hold up against the actual code (`combo_string`, `find_shortcut`,
`stop_here`, `handlers.mousereleased`, `handlers.keyreleased` were all read directly, not taken on
faith), and zero cases where a debt-register or internals-doc citation was wrong.

## What I could not determine

- **Whether the keyboard example's "half-finished uncommitted comment reword" genuinely predated
  this session's work**, as opposed to being new prose folded into the same commit. Git history
  only shows the final commit; there is no separate artifact of the claimed pre-existing
  uncommitted state to diff against.
- **The interactive/smoke-test claims** (`love src play` boots all five touched examples; a
  deliberately bad combo registration raises visibly under `stdbuf -oL` but was silently swallowed
  before that; the keyboard example's held-state paths were exercised by loading the real files
  against a fake device) — I did not re-run the app. This container's constraints (no display
  without `xvfb-run`, no keystroke injection into a running LÖVE process) are exactly what the
  step's own track notes cite for not doing this themselves interactively either, and the
  commission does not ask me to drive the app by hand. I did independently confirm the **static**
  claims these smoke passes were meant to support (code correctness, matcher semantics, doc
  agreement), which is the part reachable without a display.
- **Whether any commit history exists in the detached repos' reflogs or stashes that I'm not
  seeing** — I checked `git status`/`git log`/branch tracking only; I did not attempt to enumerate
  dangling objects or stashes in `keyboard`/`maze`/`balloons`.
- I did not attempt to independently re-derive the full "11 read sites in `keyboard`" count from
  scratch (a fresh, from-nothing grep of the whole file), since the commission frames the LSP+grep
  toolset as a cross-check on specific claims rather than a re-audit of the earlier enumeration
  (`S35-dissolution-site-enumeration.md`) that number comes from; I did directly re-verify that the
  9 cited "no edit needed" sites still read `INPUT.shift/.ctrl/.alt` unedited, which is the part
  that matters for this step's correctness.
