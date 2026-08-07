# S27 — cold fact-check of the triage-and-plan

**Checked against:** `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`
(document under review) and `../outcomes/S27-remark-inventory.md` (R001–R187,
read in full — Part 1, all of Part 2, Part 3). Read-only; no source, test, or
doc file touched. `busted tests` run once, unmodified: **923 successes / 0
failures / 0 errors / 3 pending** — matches the number quoted in the prompt.

**Tool note:** the `lua-lsp` MCP server was unreachable for the whole session
(`broken pipe` on every call — `references`, `definition`, `hover` all
failed; the `mcp-language-server` process was alive but its `lua-language-server`
child was not responding). Every reference/dead-code claim below was checked
by `grep -rn` across `src/` instead, which is the prescribed backstop but not
the primary tool the task asked for. Flagging this as a limitation, not
silently substituting.

---

## 1. Verdict summary

The triage is **safe to build on**. Every claim I checked against the payload
signatures, `dispatch`, `find_shortcut`, `combo_string`, the callback/veto
asymmetry, `reset_compy_input`'s wipe list, `EVENTS` vs. the pointer-channel
loop, `always_shown`'s pre-feature absence, and the click-drift "swallowed"
behaviour came back **CONFIRMED**, generally with the exact line the triage
implies. Coverage is exactly right (187/187, no gaps, no duplicates) and the
phase table has no backward dependency.

But it is not error-free, and two of the misses are real, not nitpicks:

1. **R135 is filed as a doc-accuracy fix and it is wrong to file it that
   way** — the doc text projects can't install evaluator *objects* is true
   and not contradicted by projects being able to set a validator *callback*;
   the same sentence already says both. "Stale" is the wrong word; nothing
   needs correcting here.
2. **R088 is filed as W10-editorial (S4) and reads more like a live
   contradiction inside `decisions/input.md` itself** — Decision 3's "Why"
   argues for a single shared instance for memory reasons; the
   "Implementation note" later in the same file states multiple instances
   are required and always were. Four separate `UserInputController`
   instances exist in `src/` today. This is at minimum the same class of
   finding as R086 (which the triage *did* correctly split out to S3) and
   was not given the same treatment.

Neither of these changes the plan's ordering or gates — they are corrections
to two entries' severity/verdict, not structural objections.

---

## 2. Claim table

| # | Claim (as stated by the triage) | Verdict | Evidence |
|---|---|---|---|
| 1 | W1: hooks/shortcuts receive `(k, keys_pressed, isr)` on keyboard | **CONFIRMED** | `src/controller/projectInputController.lua:174-177` — `function ProjectInputController:keypressed(k, sc, isr) return self:_dispatch('keypressed', k, k, Controller.held_keys(), isr) end` |
| 2 | W1: `(t, keys_pressed)` on text | **CONFIRMED** | `projectInputController.lua:180-183` — `textinput(t)` dispatches `'textinput', t, t, Controller.held_keys()` |
| 3 | W1: pointer channels receive LÖVE's own arguments untouched | **CONFIRMED** | `projectInputController.lua:202-205` — `pointer_channel`: `self:_dispatch(event, nil, ...)`, no held-key view appended (comment at :30-39 states this explicitly) |
| 4 | W1: `ignore_repeat` reads `(k, keys, isr)` | **CONFIRMED** | `src/controller/consoleController.lua:450-455` — `ignore_repeat = function(fn) return function(k, keys, isr) ... end end` |
| 5 | W2: `find_shortcut` returns nil for a missing table | **CONFIRMED** | `projectInputController.lua:80-83` — `local function find_shortcut(tbl, trigger) if not tbl then return end ...` |
| 6 | W2: pointer channels pass `trigger = nil` | **CONFIRMED** | `projectInputController.lua:204` — `self:_dispatch(event, nil, ...)` |
| 7 | W2 (load-bearing): `combo_string('*', keys)` already builds a triggerless combo key, i.e. the machinery for a keyless combo exists | **CONFIRMED, with a wording nuance** | `src/controller/controller.lua:431-440` — `combo_string(k, keys_pressed)` prepends held modifiers then appends `k` verbatim; called as `Controller.combo_string('*', keys)` in `find_shortcut` (`projectInputController.lua:87`) to build the `alt+*`-style class key. It is not literally "triggerless" — `'*'` is a placeholder trigger character, not an absent one — but the claim's substance holds: the serialiser already produces a combo string that names only modifiers plus a fixed sentinel, which is exactly the shape a modifier-only pointer combo needs. The triage's own prose ("triggerless class key") slightly overstates the mechanism; the underlying architectural point is sound. |
| 8 | W2: doc's argument ("a combo needs a key to name") is the current text | **CONFIRMED** | `doc/input_api.md:293` — `There are no pointer *shortcuts* — a combo needs a key to name, so...` |
| 9 | W3: `singleclick`/`doubleclick` dispatched by the generic pointer loop but absent from `EVENTS` | **CONFIRMED** | `EVENTS` at `projectInputController.lua:41-45` lists 10 native events, no click derivatives; the generic `pointer_channel` install loop at `:212-218` explicitly includes `'singleclick', 'doubleclick'` alongside the native ones — two separate lists, exactly as claimed |
| 10 | W3: `seed_hooks` never seeds them | **CONFIRMED (follows from #9)** | `seed_hooks` (`projectInputController.lua:56-62`) iterates `EVENTS` only, which does not contain the click names |
| 11 | W3: `reset_compy_input` wipes exactly three hand-listed keyboard shortcut tables | **CONFIRMED** | `controller.lua:369-371` — `wipe_table(input.shortcuts.keypressed)` / `.keyreleased` / `.textinput`, nothing else |
| 12 | W3: drift drops the derived click entirely rather than degrading to two singleclicks, matching `doc/input_api.md`'s "invalidates both" | **CONFIRMED** | `controller.lua:707-719` — `love.handlers[derived](x, y)` is only called inside `if no_drift(...)`; on drift nothing fires. `doc/input_api.md:285` — "Moving the pointer between the presses invalidates both." |
| 13 | W4: `occupy_keyboard`/`hook_pointer` split "no longer distinguishes anything," `hook_pointer` "reads as a leftover" | **CONFIRMED, but the phrase undersells what `hook_pointer` still does** | `controller.lua:247-278` (`occupy_keyboard`) now installs *all* channels including pointer (comment at :265-268 admits this); `hook_pointer` (`:290-303`) no longer installs any handler — but it still sets the `user_pointer` liveness flag, which is live, load-bearing logic, not dead code. "Leftover" is fair for the *installation* half of its job, not for the whole function. |
| 14 | W4: `handlers.userinput` needs a reference check before deletion (R033/R171) | **CONFIRMED as the right caution — and the check comes back clean** | `grep -rn "handlers\.userinput\|\.userinput\b" src/ --include=*.lua` returns only the definition site, `controller.lua:1143`. No other file reads or calls it. (LSP `references` unavailable this session — see tool note above; grep is the only cross-check I could run.) |
| 15 | W5: `submit()` calls `run_callback(self, 'before_submit', …)` and discards the return, while `cancel()` honours `before_cancel`'s truthy return as a veto | **PARTLY — behaviour confirmed, method names are wrong** | There is no `UserInputController:submit()`. The behaviour described lives in `submit_flow` (`userInputController.lua:413-414`, return of `run_callback(...)` not checked) and `cancel_flow` (`:430-432`, `if run_callback(self, 'before_cancel', keys_pressed) then return end`). A *separate* `UserInputController:cancel()` (`:205-208`) exists and does **not** call `before_cancel` at all — it is described in its own comment as "console's own debug/test-mode cancel," unconditional clear+hide. Citing this as "`cancel()` honours before_cancel" risks a reader finding the wrong function. The architectural conclusion (asymmetry is real, S1) is unaffected. |
| 16 | W5: `before_submit`/`before_cancel` absent from `default_callbacks()` while `after_*` default to noop | **CONFIRMED** | `userInputController.lua:12-19` — `default_callbacks()` returns only `on_limit_reached`, `after_submit`, `after_cancel` |
| 17 | W5: `before_exit`'s return value is ignored, cannot suppress/defer the stop | **CONFIRMED** | `consoleController.lua:1286` — `compy.before_exit()` called, return value not captured anywhere in `stop_project_run` |
| 18 | W5/R127 (declines section is silent on this, but it's the same code path): a raise inside `before_exit` would abort the rest of teardown | **CONFIRMED as a real, unguarded gap** | `consoleController.lua:1282-1294` — `compy.before_exit()` at line 1286 is **not** wrapped in `pcall`; `set_default_handlers`, `hide_overlay`, `clear_user_handlers`, and the `before_exit` reset at :1287-1293 all sit *after* it in the same unguarded sequence. If the call raises, none of them run. This is exactly what R127 describes and the triage correctly declines to silently fix it in this workstream — but it is worth being explicit in my own words: this is not merely a stale doc claim, it is a live, reproducible teardown gap. |
| 19 | W6/R080: the widget has no return value to give, consumes on `is_shown()` alone | **CONFIRMED** | `projectInputController.lua:109-119` (`dispatch`) — `if widget and widget:is_shown() then widget[event](widget, ...); return true end`: the call's own return is discarded, only a hardcoded `true` is returned. `userInputController.lua:485-499` — `keypressed`'s own doc-comment states "No return value: the old limit-flag return channel is retired." |
| 20 | W7/R044: `always_shown()` "did not exist pre-feature" | **CONFIRMED** | `git show 3256aac:src/controller/userInputController.lua \| grep -i "shown\|always_shown"` — zero hits; a repo-wide sweep of every file at `3256aac` for the string `always_shown` also returns nothing |
| 21 | W7/R044 (implicit): nothing structurally guarantees the flag can't be reset elsewhere | **CONFIRMED as a real, undischarged concern** | `userInputController.lua:331-334` — `hide()` unconditionally sets `self.shown = false`; nothing marks the console's instance as hide-immune. The invariant holds today only because `hide()` is never called on that specific instance (`love.state.user_input_controller`, set once in `main.lua:378`, is a *different* object from `consoleController.lua`'s own `self.input`, confirmed via `main.lua:370-378`, `consoleController.lua:43`, `editorController.lua:12,16` — four separate `UserInputController` instances exist total). It is a convention, not an enforced contract — the S0 framing is right. |
| 22 | W8/R068: the reconfigure test "may now assert nothing" given stay-open-by-default | **CONFIRMED** | `tests/input/input_reconfigure_spec.lua:276-292` — the test's own explicit `input.callbacks.after_submit = function() input.show({}) end` is redundant if the widget already stays shown by default after submit (default `after_submit` is `noop`, confirmed at `userInputController.lua:16`, and `submit_flow` never calls `hide`, confirmed `:413-422`); `assert.is_true(F.widget:is_shown())` would pass whether or not the re-show call does anything |
| 23 | W9/R109: Decision 16 ("keep the existing asymmetry... do not add click entries to the hooks table") is stale/wrong given current code | **CONFIRMED, and worth stating plainly: this is a real code/doc divergence, not editorial** | `doc/development/decisions/input.md:652-654` says "Do not add click entries to the hooks table"; `projectInputController.lua:212-218` shows `singleclick`/`doubleclick` *are* wired through the same generic `hooks[event]` mechanism as every other channel. Decision 16's own status line even reads "not implemented in 1.0.0-rc20260712" (`decisions/input.md:649`) |
| 24 | W9/R168: `gfx` is the house alias convention, not an undeclared free variable | **CONFIRMED** | `agents/rules.md:61` — "Standard aliases at module top: `local gfx = love.graphics`, `local sfx = compy.audio`." |
| 25 | W9/R135: "projects cannot install evaluator objects" is stale because projects can configure a validator | **WRONG** | `doc/development/internals/user_input.md:91-92` already says, in the *same sentence* the remark is attached to: "the internal plain evaluator plus project callbacks for validation and display. Projects cannot install evaluator objects." A validator callback (`cfg.validator` → `self.callbacks.validator`, `userInputController.lua:251-252`, run through `gate()` at `:380-382,417`) is a plain predicate function; an `Evaluator` (`LuaEval`/`LuaEditorEval`, `userInputModel.lua:17,43,864` — has an `:apply()` method) is a different, heavier object a project genuinely cannot substitute. The doc is precise, not stale — the remark conflates two distinct mechanisms. See §3. |
| 26 | W9/R110: "a note calling `dispatch` non-reusable when it is" | **PARTLY WRONG characterization** | The doc section (`decisions/input.md:697-706`) does **not** currently call `dispatch` non-reusable — it says, in past tense, that the dispatch "that had shipped" (mid-feature, never released) was not reusable, and describes the fix. Code confirms `dispatch` genuinely is a free function today (`projectInputController.lua:109`, operates on plain `shortcuts`/`hooks`/`widget` args, no `self`). R110's own text agrees dispatch *is* reusable now — its actual ask is whether the whole section is stale intra-feature history that should be cut, which is the same "no historical contrast" pattern as R103/R104 (W10), not a "check this claim and correct it" doc-accuracy bug (W9). See §3. |
| 27 | W2 prose: "Six remarks in two docs and one source file" | **WRONG, minor** | The six (R037, R115, R131, R145, R152, R177) span **three** doc files — `decisions/input.md:1063` (R115), `internals/user_input.md:14,250,509` (R131/R145/R152), and `doc/input_api.md:292` (R177) — plus `projectInputController.lua:194` (R037). "Two docs" undercounts by one. Does not affect the workstream's substance. |
| 28 | §C: every id R001–R187 assigned to exactly one workstream | **CONFIRMED** | Programmatic check of Appendix A: 187 unique ids, 0 duplicates, 0 gaps in the 1–187 range |
| 29 | §4: no phase in the table depends on a later phase | **CONFIRMED** | P0 (—) → P1 (P0) → P2 (P1) → P3 (P2) → P4 (P1,P3) → P5 (P1) → P6 (P2–P5) → P7 (P6) → P8 (P2–P7) → P9 (P2–P5) → P10 (P2–P9) → P11 (P10): every dependency cites a strictly earlier phase number |

---

## 3. Misfiled severity

I read all 92 W10 (editorial/S4) ids in full while transcribing the inventory
for this check — not a sample, the actual complete set, since Part 2 had to
be read end-to-end anyway to build the claim table above. That is a stronger
basis than a spot-check, so I'm reporting it as a full pass, not a sample.

**Under-rated (should not be S4/W10):**

- **R088** (`decisions/input.md:192`, filed W10) — flags that "same code"
  does not mean "same instance" and that the doc's singleton framing may be
  pre-implementation vision that didn't survive contact with reality. On
  inspection this is close to true and internally contradicted: Decision 3's
  "Why" (`decisions/input.md:185-189`) argues for one shared instance on
  memory grounds ("forbids allocating a fresh object graph per input
  session... a shared instance also makes 'hide and bring back with state
  intact' fall out for free"), while the same file's later "Implementation
  note" (`:713-715`) states plainly: "Multiple `UserInputController`
  instances remain required... and would be clobbered by a single shared
  instance." Four instances exist in `src/`: `main.lua:371`
  (project-facing), `consoleController.lua:43`, `editorController.lua:12`
  and `:16` (input + search). Decision 3's title ("one boot-provisioned
  shared widget, **not per-session construction**") and its "Consequence"
  paragraph ("same widget **code**") can be read as scoped to "not
  reconstructed per show/hide," which would make it consistent — but the
  "Why" paragraph's NFR framing ("forbids allocating a fresh object graph
  per input session") is genuinely ambiguous between "per prompt" and "per
  host," and a reader who takes it the second way hits a real contradiction
  with the Implementation note. **Recommended: S3**, same bucket as R086
  (which got exactly this treatment for a materially similar contradiction).
  It is not editorial vocabulary drift; it's two paragraphs of the same
  permanent doc disagreeing about the architecture.
- **R081** (`decisions/input.md:120`, filed W10) — "now its more than three
  components, we are sending pointer events the same way!" Decision 2's text
  says "every keyboard/text event runs one chain of three components" and
  "the same three-component shape runs on all three channels (keypressed,
  textinput, keyreleased)" (`:105-106,119-120`) — deliberately scoped to
  keyboard/text. But pointer channels run through the *same* `dispatch()`
  function (`projectInputController.lua:109-119`, `_dispatch` at `:126-130`
  is shared by every channel, pointer included via `pointer_channel` at
  `:202-206`) — 2 of the same 3 tiers (hooks, widget), missing only
  shortcuts. Decision 2 as written lets a reader believe pointer is outside
  this chain shape entirely, when it is the same machinery minus one tier.
  Borderline, but I'd rate this **S3, not S4** — it's a completeness gap in
  what a "permanent doc" claims about the routing architecture, not a
  wording preference.
- **R127** (`project_sandbox_env.md:72`, filed W9/S3 — correctly, but I want
  to flag it is not merely a doc gap): see claim #18 above. The teardown
  sequence in `stop_project_run` is unguarded against a raising
  `before_exit`. The triage's own framing ("identified, registered, not
  implemented — precisely the counter-measure this failure mode needs") is
  accurate and I don't think the severity is wrong (S3, correctly filed,
  blocks on doc truth) — but I'd flag to the owner that this reads as one
  step from an S0 the moment someone decides the "proposed robust fix"
  should ship in this PR rather than stay a doc note.

**Over-rated (S0/S1 items that read as cosmetic once checked):** none found.
Every S0/S1 item I checked (R044, R068, R080, R109-adjacent Decision-16
claim, the before_submit veto) turned out to be a real behavioural or
contract question when read against the code, not a false alarm.

**Misclassified in kind, not severity:**

- **R110** (filed W9(b) "doc accuracy... check in code and correct") — see
  claim #26. Its actual ask is "cut this stale intra-feature history,"
  which is the same shape as R103/R104 (W10's "no historical contrast"
  batch), not a false-claim-to-fix. Low stakes — the section will get
  trimmed either way — but worth knowing before someone goes looking in
  code for something to "correct" and finds nothing wrong.

## 4. Coverage and internal consistency

- **Coverage:** confirmed programmatically — every id R001–R187 appears
  exactly once across Appendix A's W1–W11 lists plus the explicit "every id
  not listed above" W10 tail. No duplicates, no gaps.
- **Workstream membership vs. description:** spot-checked members against
  their inventory text for every workstream (not just W10) while building
  the claim table; found no id whose actual remark contradicts its
  workstream's stated theme. R086's cross-listing (counted once, under W6,
  with an explicit "(from W6)" note under W9) is handled correctly, not a
  duplicate.
- **Count claims in prose:** W7 says "Twenty remarks" — R004-R006, R008,
  R011-R012, R014-R020, R039-R045 is exactly 20 ids, confirmed. W2 says "Six
  remarks in two docs and one source file" — six ids confirmed, but **three**
  docs, not two (see claim #27).
- **Phase table:** no backward dependency (see claim #29).

## 5. Declines

- **R080 (widget as an ordinary chain element) — agree with the decline.**
  Verified independently at `projectInputController.lua:109-119` and
  `userInputController.lua:485-499` (see claim #19). The widget's own
  `keypressed`/`textinput`/etc. genuinely return nothing; `dispatch` gates
  its participation purely on `is_shown()` and discards whatever the call
  returns. Making it return a boolean would only ever mirror `is_shown()` —
  there is no other signal available to return. The triage's self-doubt
  ("I may be wrong, want a cold advisor") is answered: the code supports the
  decline as stated.
- **R121/R122 (removing `after_submit` or forbidding config-set callbacks) —
  reasonable decline, not independently checkable as right/wrong.** Confirmed
  the premise is real: `apply_config` (`userInputController.lua:250-259`)
  does set `validator`/`on_text_entered`/`on_limit_reached` from `show{}`'s
  config, so both callback-installation paths genuinely coexist today. Which
  one should win is a design preference, not a fact — no verdict to render
  beyond "the premise is accurate."
- **R017 ("why not a separate file at all?") — same: a judgment call, not a
  checkable fact.** No code basis to contest "file moves make every slice
  harder to review."
- **R030 (re-firing clicks after drift) — agree with "answered as
  documented behaviour."** Confirmed at `controller.lua:707-719`: on drift,
  `love.handlers[derived]` is simply never called — the event is fully
  swallowed, not degraded to two singleclicks — matching
  `doc/input_api.md:285`'s "invalidates both" exactly (see claim #12).
- **R181 (`before_exit` suppressing the stop) — agree with "no," and the
  code backs it up harder than the triage states.** Confirmed at
  `consoleController.lua:1286`: the return value isn't merely ignored, the
  call itself is unguarded — a raise there would abort the rest of teardown
  outright (see claim #18). The triage's "I recommend no, and fix the doc
  that calls it deferred" is right; I'd add that this makes the case for
  *not* adding a suppress/defer return even stronger — the surrounding
  machinery isn't robust enough yet to hand a project that much power over
  the stop sequence.

## 6. Anything else that alarmed you

- **Nothing structural.** I went in cold specifically to find a wrong load-
  bearing claim, and the one genuine miss (R135, claim #25) is contained —
  it doesn't change any workstream's verdict or the plan's ordering, just
  one doc-fix item that should be dropped rather than actioned.
- **The `submit()`/`cancel()` naming looseness (claim #15) is worth fixing
  before this triage is handed to whoever implements W5.** A future reader
  grepping for `UserInputController:cancel()` will land on the *wrong*
  function — the unconditional debug-mode one, not `cancel_flow` — and could
  easily "fix" the wrong veto path. Small, but exactly the kind of slip that
  turns into a real bug during implementation of a phase this consequential.
- **The `before_exit` teardown gap (claim #18) deserves a harder look before
  P5/W5 ships**, even though the triage correctly keeps it out of scope for
  now. If `before_submit`'s veto lands as recommended, the codebase will have
  two different "callback that can abort a lifecycle step" mechanisms with
  two different robustness levels (one wrapped, one not) — worth a single
  sentence in the doc fix so it isn't rediscovered from scratch later.
- **Tool availability:** the `lua-lsp` MCP server never came up this session
  (see header). Every "is this still called" answer here rests on grep
  across `src/` only. I'm confident in the specific greps I ran (they're
  narrow, exact-string, low-false-negative-risk substrings), but this is
  weaker than the reference-resolution the task asked for, and I want that
  on the record rather than silently presented as equivalent.
