# session39 — track

## 2026-08-12 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: `session39/` held only
  `prompt.md`, no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `dd7a7548` "docs(session38): wrap — P-18 closed, report, session39 prompt for P-17, repointed
  pointer", branch `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked
  modifications**; only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, `worklog.md`, `repos.txt`) and the three nested
  example repos.
- **Baseline confirmed: `busted tests` → 946 / 0 / 0 / 10.** Matches the prompt; the 10 pending are
  the sanctioned count (3 routing-grid + 7 reserved-combo outlines), not drift.
- Read at boot: `agents/validation.md`, `agents/sessions.md`, this `prompt.md`, `session38/report.md`
  in full, the session38 commissioning `prompt.md`, and `session38/track.md` end-to-end.
- **`maze` facts from the wrap re-verified myself rather than trusted** (prompt says verify, do not
  trust): `newinput` at **`a045fdb`**, clean; remotes `dsent` (`dsent/compy.maze`) and `origin`
  (`nagydani/Compy-maze`); **4 ahead / 26 behind `dsent/dsent/dev`**; **4 ahead / 0 behind
  `origin/v3.4`**. All four numbers match the successor prompt.
- **Task as commissioned:** **P-17-00 — `maze`'s merge, evaluation and plan**, performed by the
  *method* session37 used for `P-18-00`, not merely to the same outcome: (1) read session37's report
  and track and the artifacts its pass produced; (2) write the **upstream input assessment BEFORE any
  merge**; (3) the merge only if the owner rules it, with any defect it introduces corrected in its
  own commit — expect the same class of invisible breakage `keyboard` had (upstream code calling a
  function this branch deleted, no hunk touching both files); (4) analysis-and-design pass, then a
  triage decomposing into `P-17-01`, `P-17-02`, … with the owner's rulings named explicitly first.
- **Stop-and-raise boundaries:** whether the merge happens and its shape are the owner's; so is every
  behaviour question the assessment turns up.
- Reported the task to the owner before proceeding, as instructed. Owner: **yes**, proceed with the
  method study and then the assessment, and come back before any merge.

## 2026-08-12 — the method study, then the maze upstream assessment (research + analysis)

**Mode named and held: research + analysis.** Nothing checked out, merged or edited in `maze`; the
trial merge was computed **in memory only**. The one thing run was the pre-merge smoke, as a baseline.

- **Read first, per the prompt's insistence on method:** `session37/report.md` and `track.md`
  end-to-end (897 lines — the *sequence* is the payload: prerequisite at boot → upstream input
  assessment **before** any merge → merge + correction as separate commits → analysis/design →
  triage into numbered children), then `S37-keyboard-upstream-input-assessment.md` in full and the
  headings/structure of the two P-18-00 documents.
- **Deliverable written:** `../../../validation/reviews/S39-maze-upstream-input-assessment.md`,
  mirroring S37's shape (what was examined → the two questions → the merge measured → what it means
  for the step → sequencing recommendation → confidence and limits).
- **Did NOT delegate.** Same call session37 made and for the same reason: every fact here is one I
  would have had to re-verify before recommending a merge shape on it. Noted because the charter's
  default is to delegate down.

### The findings, in the order they change the plan

- **Q1 — new mechanisms: two.** `maze_plan.lua`'s tile buffer is **`keyboard`'s `INPUT.held` again**,
  independently written by a different author: an event-derived held-key set whose only job is to
  filter OS repeat, wedge-able by a lost `keyreleased`. `isrepeat` answers it. And `draw` is a whole
  second program whose Free-draw mode keeps the input field up **permanently**.
- **Q2 — reconsidered practices: YES, and this is the opposite of `keyboard`'s answer.** The author
  moved *towards* the platform convention (`9911a27`: Shift+Esc no longer quits) and then wrote a
  **TEMPORARY workaround with its removal condition in the source** (`b8cc436`, the typed `<` exit):
  *"Shift+Esc cannot reach a program while the editor input field is active … Remove `<` when
  Shift+Esc works in the editor."*
- **THE HEADLINE, measured at the PR base and at HEAD:** that premise was true and **this feature is
  what makes it false.** Base `3256aac:controller.lua:625-630` routed the keyboard to the widget
  whenever one was shown and **never called the project's handler**; at HEAD the gateway forwards
  unconditionally and the project route walks **shortcuts → hooks → widget**, widget last. So the
  feature closes a gap the author named with two issue refs and asked to have closed. **This is
  `maze`'s counterpart of `keyboard`'s "the author's header lists the platform's gaps" — and it is
  better testimony, because it names its own deletion.**
- **THE MERGE DOES NOT APPLY.** Two conflicts: `controls.lua` (content) and **`main.lua`
  modify/delete** — upstream deleted the 554-line `main.lua` and split it; our whole migration lives
  in it. Git's default resolution (keep ours) is the trap: **our `main.lua` defines 53 globals and 48
  of them are redefined by upstream's split files**, `rearm_input` among them with *different
  semantics*. Nothing raises; require order decides. **`keyboard`'s "clean merge, broken tree" class,
  one turn nastier — there a name was missing, here a name is doubled.**
- **So the merge obsoletes our migration rather than carrying it.** The five globals of ours with no
  upstream counterpart are exactly the migration (`open_editor_input`, `handle_editor_submit`,
  `player_is_idle`) plus `record_echo` and the `SYSTEM_KEYS.escape` upstream deleted.
- **The legacy surface is small and well-placed:** upstream's new shared `core_editor.lua` runs the
  retired poll idiom — `user_input()` ×1, `input_text()` ×3, the reftable poll ×2 — **6 sites in 1
  file**, and that file is CORE, copied into *both* emitted programs. `b4d96eca` removed those
  globals with *"no shim, no deprecation path"*, so **upstream's tip cannot run its editor on this
  platform at all**, in either program. That is not a merge defect; it is why P-17 exists.
- **Structural, and it breaks this session's own smoke command:** `.compy/build` emits `maze/` and
  `draw/` from one source root, and `BUILD.md` says **"the source root has no `main.lua`, so it is not
  itself a runnable project"**. `love src play src/examples/maze` will not work post-merge. The
  `.compy/build` convention appears **nowhere** in `/repo/src` or `/repo/doc` — it is upstream's, or
  the `dsent` platform fork's.
- **Carry-overs the merge would decide by accident:** the repo's **only** platform-doc citation is
  ours (`main.lua:565` cites `doc/input_api.md`), violating the 2026-08-12 ruling; and the two
  `REMARK:`s are the **owner's** (`aeabb73`), one of them — *"can we try using shortcuts/hooks and
  callbacks more actively?"* — is answered by this very step. Both live in the file the merge deletes.
- **Two assets `keyboard` never had:** three headless `spec/` suites + `verify.sh` (so a **breaking
  test first** is possible here), and the author's own `TEST-PLAN.md`.
- **Pre-merge smoke baseline measured:** *"Project play opened" / "Running 'play'"*, no raise, killed
  by timeout (124). No level reached, no keystroke injected.

**Presented to the owner with five rulings named and nothing decided:** whether the merge happens and
its shape; what replaces the smoke command / whether `.compy/build` is wanted; whether `draw` is in
scope; the `keyboard`-D1-class menu-digit question (raised as *needs driving*, not asserted); and the
disposition of the two `REMARK:`s.

## 2026-08-12 — owner reshapes P-17-00: NO merge, fork the edge, adopt by checklist

**Owner correction first, and it is a fact I got wrong:** *"dsent is author of this version, so it's
the same author as in keyboard upstream."* Verified: 15 of the 26 commits are dsent, 11 are Vadim,
and the split is clean by kind — **dsent owns the input behaviour** (plan mode, the Shift+Esc
convention, the `<` workaround), **Vadim owns the restructure** (`core_editor`, the split,
`.compy/build`, the specs). **So `plan_held` is not independent corroboration of `INPUT.held`; it is
one author's recurring idiom.** Weaker as evidence, stronger as practice — the debt entry is
addressed to a known correspondent. Corrected in the assessment in place, with the error named.

**The owner's alternative shape, ratified, written to
`../../../validation/reviews/P-17-00-shape-and-plan.md`:**

- **A** — inventory our four commits *and* what P-18 already learned, as a **catalogue of practices
  that may be used… or not**. Explicitly not a mandate, and explicitly not re-derived from scratch:
  P-18's review material already holds it.
- **B** — **fork a brand-new branch off maze's dsent edge; it becomes the working branch.** *"I
  especially ratify that move."*
- **C** — analyse on that branch against **`doc/development/conventions/input_adoption.md`** (Q1–Q10 +
  the rules of restraint), with the catalogue as a **secondary** source. Ordered: regressions the new
  platform may introduce → locally-duplicated machinery → migrations where the gain is real, **and a
  written report where it is not**.
- **D** — triage into `P-17-01…`, using the suite as a regression fence. **Open, named by the owner:**
  whether the platform's behavioural-observable testing preference transfers to a project suite.

**Why the shape is better and not merely different:** the merge was never the useful part. And the
fork dissolves `pr-assembly-guide.md` §5.1 — a branch *forked from* the ref has it as an ancestor by
construction, so the slice is exactly our change from day one.

**Executed immediately (step B):**

- **`newinput-edge` forked from `dsent/dsent/dev` @ `b8cc436`.** `newinput` @ `a045fdb` and its backup
  untouched. Ancestor check **safe**, `diff dsent/dsent/dev..HEAD` empty. Guide §5.1 + the Set-4
  command updated to the new ref; `S27-triage-and-plan.md` §15.3 gains an **[S39]** block marking the
  [S37] paragraph superseded and its two stale facts ("no suite", the `REMARK:`s' file).
- **The smoke question answered by measurement, not prediction:** `love src play src/examples/maze`
  now prints `[string "main.lua does not exist"]:1: '=' expected near 'does'`. `BUILD.md` was right —
  the source root is not a runnable project. **This sprint's maze smoke command is dead** until the
  owner rules. (Side finding, not ours: the platform feeds the *message* into the Lua compiler and
  reports the syntax error of that sentence.)
- **The suite runs here, and it is a real fence: `verify.sh` → `== OK: build verified ==`.** Specs
  **29 + 10 + 3 = 42 / 0 / 0**. Two environment facts recorded so nobody rediscovers them: this
  container has **`luajit` only** (shim `lua`/`luac` on PATH, and **not** in the scratchpad — it is
  `noexec`), and **`BUILD.md`'s own counts are stale** (8/2 vs the actual 10/3), which is theirs and
  harmless but reads as a regression to the next person.

## 2026-08-12 — step C's evidence half (mine), then the catalogue returns and is corrected

**Mine, while the worker ran** — deliberately on files it does not touch, and written up as
`../../../validation/notes/P-17-00-platform-facts-for-the-editor-migration.md` (`143c067a`):

- **`show()` over a shown widget is a no-op that WARNS, and cannot change the prompt** even with
  `force` (only `text` applies). Upstream's `reject_program` and per-tick `rearm_input` call
  `input_text(input_prompt(), …)` **precisely to change the prompt** — a syntax error *is* the
  prompt. So the replacement is `configure{prompt}` + `set_text`. **This repo already paid for it
  once**: `790ac19`'s message records `show()` re-issued every tick, warning each time.
- **At the PR base a second `input_text()` while shown was a SILENT no-op** (*"there can be only
  one"*), so the behaviour to reproduce is *leave the field alone*, not *re-open it*.
- **The overlay gate is the one real change**, and it lands both ways: `shift+escape` can now reach
  the program (the author's request), and **`to_menu()`/`toDrawMenu()` hide nothing**, so they owe a
  teardown they never needed.
- **The menu-digit question has a documented answer** — `doc/input_api.md`, "Opening the overlay from
  a key": a one-shot `shortcuts.textinput` guard. **A ruling turned into a lookup.**
- **A correction I made before asserting it, not after:** I nearly filed *"the overlay no longer
  closes on submit"* as a platform regression. It is not — that claim is from `d2ce7a0`'s message
  describing an **intermediate state of the feature's own development**, not the PR base, where
  submit did not hide either. Same trap as session37 §2.1: judge against the PR base.

**The catalogue returned (276 lines) and I reviewed it against its sources rather than its report.**
Substantively sound — 9 rulings, 11 mechanism practices, 5 process traps, and a *"what this does NOT
establish"* section that is the most useful part (it names the `keyboard` mechanisms that have no
maze analogue, which is exactly the anchoring risk the shape doc worried about). **Two defects, both
in the binding-ruling section**, both the same class:

- **§1.4 truncated an owner quotation before its operative half** — *"just leave a comment with a
  warning"*. The ruling does not say *do nothing*; it says *comment instead*. Restored.
- **§1.5 attributed the triage's own prose to the owner as a quotation.** The ruling is right, the
  words are not theirs. Replaced with what they actually said. **An assistant's paraphrase promoted
  to an owner quotation is how a ruling drifts**, and this catalogue is written to be cited.

Both corrected in place with the error named, per the standing practice. The worker was otherwise
clean: read-only, no git state touched, and it **declined to invent** a trap the prompt had offered
as an example when it could not find the attestation — which is the behaviour the prompt asked for.

## 2026-08-12 — the cold inventory returns; verified, and it found something I had missed

Second worker (Sonnet, model explicit, **sequential — launched only after the first finished**),
prompt of record `../../../validation/prompts/P-17-00-adoption-inventory.md`, deliverable
`../../../validation/outcomes/P-17-00-adoption-inventory.md` (987 lines). Told to be **cold**:
forbidden from reading the catalogue, the assessment or the shape doc, so the checklist got its say
before the sprint's own history did.

- **29 sites: 2 CORE, 19 MAZE, 8 DRAW.** Matches only in Q1/Q2/Q4/Q6/Q7/Q8; **Q3, Q5, Q9, Q10 are
  zero** in both programs. Counts recomputed from its own table, with the double-matching caveat
  stated rather than hidden.
- **Its best find, and I had missed it: `ctrl_pressed` is structurally always `nil` in DRAW**, so
  `drawGameKey`'s fallback is **dead code**. **Verified two ways** before relaying: `ctrl_pressed`
  is assigned non-`nil` in exactly two places, both in `controls.lua`; and `controls.lua` is neither
  in `draw_main.lua`'s requires nor in `.compy/build`'s DRAW set — it is MAZE-only. So **draw's whole
  in-game keyboard surface is the editor field, the Escape branch and the Tab poll**, nothing else.
- **`Key.*` is used nowhere in the repo** — confirmed independently.
- **Read-only honoured**: `maze` still on `newinput-edge`, clean, no commits.
- **My one addition, appended as a marked parent-review section rather than edited into its
  entries:** the `shift_held` mirror has a **third** consumer and it is a **display** —
  `maze_render.lua:221`'s `draw_macro_ui` dims the screen while Shift is held. The inventory files
  `maze_render.lua` under "swept, no site", which is defensible (one mirror = one site) but
  **understates the conversion**: the two consumers ask different questions (*was it down when this
  key arrived* vs *is it down now*), and the failure differs — a lost `keyreleased` leaves the screen
  **permanently dimmed**, a stuck visible UI state rather than a missed event. That weakens
  calibration (a)'s "just leave a comment" answer for this site specifically. **Evidence, not a
  verdict.**

## 2026-08-12 — owner: compact once at the end, refine the citation ban, and number the substeps

Three instructions, all materialized rather than left in chat.

- **Comments stay verbose while the work is live; compaction is its own substep at the end**, on the
  `P-18-10` model. Owner's reason, and it is the part worth keeping: *"mid-development, verbose
  comments help assistants to get oriented in a fragile and unstable codebase; it's only before
  release we need to compact them, drying up history/obituaries and intermediate rulings."* Landed as
  §5 of the shape doc **and** in `agents/rules/commenting.md` ("Where this is enforced"), so it binds
  beyond this step — the file previously said this only about `INTERIM:`/`REMARK:` markers, never
  about verbosity.
- **The citation ban is NARROWED, and I had over-read it.** *"What is prohibited are links to files
  not reachable from detached repos. Merely referencing the platform guide by header is tolerable if
  it happens only in places where it's really needed."* So a `doc/…` **path** and platform-internal
  identifiers stay banned; **naming the guide and its section is tolerable where the alternative is
  restating a contract the platform owns.** This **revises my own §4.5 instruction from an hour ago**:
  the old `main.lua` block committed one fault (length), not two — its *"Compy Input API, 'Submit
  lifecycle'"* reference is exactly the tolerated form. Corrected in both documents.
- **The substeps get ids**, so a crash mid-session costs a successor nothing: **`P-17-01`** catalogue
  [done] · **`P-17-02`** fork [done] · **`P-17-03`** analysis writeup · **`P-17-04`** triage · then
  **`P-17-05…`** execution, ending in compaction. A/B/C/D are retired. **The ids honour what is
  already on disk** — the catalogue was delivered as `P-17-01-practice-catalogue.md` before the
  numbering existed, so `P-17-01` is assigned to it rather than reused, and nothing is renamed.
  §15.3's [S39] block carries the same list.

## 2026-08-12 — P-17-03: the adoption analysis, written

`../../../validation/reviews/P-17-03-adoption-analysis.md`. Ordered as the owner specified —
**regressions the new platform introduces → duplicated machinery → gains, with the no-gain sites
reported rather than converted.**

- **Three regressions named ahead of any adoption**, because a migration landing on top of an
  unnoticed one buries it. **R1** the overlay gate is gone, so the game's handlers now run while the
  field is up (inert by reading in both programs; owed a smoke row, because *inert by reading is not
  inert by measurement*). **R2** `to_menu`/`toDrawMenu` hide nothing, so an exit that leaves the
  field shown is now a two-consumer collision on the menu — **and it is doubly required once `G1`
  lands**. **R3** a naive per-tick re-`show()` warns every frame and *cannot change the prompt*,
  which is what upstream's reject path calls it for.
- **Five conversions with the gain stated on its own terms:** `E1` the editor onto `compy.input`
  (required — without it the editor does not run at all, in either program), `E2` the two
  `is_shift_down` copies, `E3` the `shift_held` mirror, `E4` `plan_held` → `isrepeat`, `E5` the two
  Tab pollers. Plus **`G1`**, `shift+escape` as a shortcut — the capability the author asked for,
  with `<` kept per the owner.
- **`E3` is the strongest case in the step and it is not the one I expected.** The mirror's third
  consumer is a *display* (`maze_render.lua:221` dims the screen while Shift is held), so a lost
  release does not merely drop an event — it leaves the screen **permanently dimmed until restart**.
  That is a stuck visible UI state, which is a different animal from calibration (a)'s
  focus-shaped risk, and it is what makes the conversion justified rather than tidy.
- **A correction of the cold inventory, stated rather than silently applied:** it called M12/M13 a
  Q6 pair *needing restructuring*. That rests on assuming a shortcut must bind the closing half — but
  `release_shift` is reached from the game's own `love.keyreleased`, which does receive modifier
  releases. Remove the mirror and **no Q6 shape remains**; nothing is restructured.
- **`E5` carries the step's one narrowing and it is stated, not smuggled:** a bare `tab` binding
  stops matching `Shift+Tab`/`Ctrl+Tab`, which advance the level today. Neither is documented nor in
  `TEST-PLAN.md`, but *"nobody meant it"* is not *"nobody does it"* — `P-17-04` gets the option of
  binding the `'*+tab'` class instead.
- **Seven sites reported as NO GAIN** with reasons, so the omissions are not read as oversights —
  chiefly the pointer binding (the framework already seeds captured `love.*` handlers as hooks, so
  rewriting it changes the spelling and nothing else) and the four key→meaning dispatch tables, which
  have Q8's shape but not its problem: they demultiplex by game mode, not by combo.
- **The echo guard is a lookup, not a ruling:** `doc/input_api.md`, "Opening the overlay from a key",
  documents the one-shot `textinput` shortcut and its two constraints, both satisfied here.
- **`Key.is_shift` exists and is exported but is UNDOCUMENTED** — the same P-10 gap `Key.is_mod` and
  `Key.is_alt` sit in. Precedent (session37, owner): use the platform predicate; the doc gap is
  P-10's problem, not a reason to keep a local copy. It should join that list.

## 2026-08-13 — owner's two corrections, then P-17-04

**(1) "Are the three named regressions recoverable?" — the question found a misfiling of mine.**

- **R1**: no manifestation in either program (inert by construction); if one existed it would be one
  stray action per keystroke — recoverable. Static reading only, hence the smoke row.
- **R2**: **NOT recoverable inside the run**, and **not ours**. Verified in code: `cancel_flow`
  (`userInputController.lua:421-427`) clears the model and runs `after_cancel` but **never touches
  `self.shown`** — only `hide()` closes a project-opened overlay and **no built-in gesture calls
  it**. Escape clears the field and leaves it up. The only ways out are the framework's project
  exits. By calibration (b) that is a **harmful degradation, not an inconvenience**.
  **But I had filed it as a regression WE introduce, and that was wrong.** The stuck overlay is
  upstream's and predates us: `<` → `exit_to_menu` → `to_menu()` and `next_level()` running off the
  end of a track both reach it from an editor level on the base platform. What R1 changes is the
  **severity, downward**: at the base the widget ate the whole keyboard so the menu was unusable; at
  HEAD the game's hook runs first, so the menu works and the digit merely also lands in the leftover
  field. **R1 partially masks an upstream defect rather than creating one.** Our obligation is
  narrower and firmer: `G1` routes a new gesture into that path deliberately, so we ship the
  `hide()`. Corrected in place, with the superseded sentence struck rather than deleted.
- **R3**: not player-facing at all — a log warning per frame, and a constraint on how E1 is written
  rather than a defect that can ship if we obey it.

**(2) The `'*+tab'` idea was invalid, not merely inferior.** Owner: the platform has no such class,
and that is why `keyboard` multiplied its combos. **Verified in `src/util/key.lua`:** `check_combo`
allows `*` **only in the trigger position and only with modifiers** (`alt+*`); `'*+tab'` splits into
two triggers and **raises** at registration, and a bare `'*'` is refused outright because it is what
`hooks[event]` already is. The wildcard means *"these modifiers, any key"* — never *"any modifiers,
this key"*. **Ruled: multiply the registrations, the `keyboard` way** — *"it looks ugly but may
clearly hint author about which combos they are really supporting (and maybe deciding to suppress or
ignore some)."* Faithful preservation of the Tab poll is therefore **8 combos**, in both programs;
`alt+tab` is registered **and** commented as usually taken by the window manager, rather than quietly
omitted.

**(3) P-17-04 written** — `../../../validation/reviews/P-17-04-triage-and-substeps.md`.

- **`P-17-05` is a GATE, per the owner's instruction**: walk them through the seven no-gain sites,
  one at a time, before any execution. *"I may overrule or contest, and it may lead to replanning,
  but having base plan first is more important."* Named as a gate rather than a footnote because
  **four of the seven decline on the same argument** — Q8's shape but not Q8's problem — so if that
  argument is wrong it is wrong four times, and each is a substep this plan does not contain.
- Then `P-17-06` (E1, required first — nothing smokes before it), `P-17-07` (G1+R2 as **one** commit,
  because the gesture and the teardown it makes necessary are one concern), `P-17-08`…`P-17-11`
  (E2–E5, mutually independent, ordered adjacently by file), `P-17-12` the smoke section — **the
  step's only gate with the suite frozen** — and `P-17-13` compaction, last.
- **Three rulings left open and named**, including E1's re-arm question (event-driven vs tick), with
  a recommendation rather than a decision.
- **§5 says what the plan deliberately does NOT contain**, so a successor does not read an omission
  as an oversight: no test work, no deletion of upstream code (`<`, and draw's dead fallback), nothing
  about `.compy/build` as a platform convention, and no fix for upstream's pre-existing stuck-overlay
  paths beyond the one `G1` makes deliberate.

## 2026-08-13 — P-17-05: the walkthrough runs, and it produces a UNIVERSAL ruling

Ran as a conversation, seven sites, code in front of us. **First I corrected my own triage claim**
that four of the seven declined on one argument — preparing the walkthrough showed they rest on
**three** arguments, two of them weak. The gate was still worth having, for a better reason than I
gave.

- **Five upheld, and the owner's reason is better than mine.** *"Early translation from keyboard
  coordinates into game semantics is exactly what I advocated for. Provided examples **are** game
  semantics, already decoupled from triggering input events — i.e. a good thing."* That reframes the
  dispatch tables from *"nothing worth converting"* to ***"already in the desired end state"*** — a
  key-to-meaning table is **Q7 being satisfied**, not Q8 being ignored. Carried into
  `doc/development/conventions/input_adoption.md` as a clause under Q8, so the next reader does not
  mistake every key-keyed table for a combo demultiplexer.
- **A NEW UNIVERSAL RULING, and it decides 1 and 3 differently from each other:** *"we should use
  `compy.input.hooks` **when** the project uses `compy.input.shortcuts` **on the same channel**.
  Otherwise it's unobvious to users that what they consider to be a native `love.*` callback
  (= receiving all events) is instead a hook that could be guarded by shortcuts (= some events not
  reaching)."* Landed as **Q11** in the checklist.
  - `love.keypressed` **converts** (G1 and E5 put shortcuts on that channel) → new substep
    **`P-17-14`**, sequenced *after* 07 and 11 because that is what makes the rule bite.
  - `love.mousepressed` **stays** — no shortcut on any pointer channel, so nothing guards it.
    **Flagged to the owner**: they named "1+3" as a pair, and their own rule applied faithfully
    leaves #1 declined. Their call to widen it if that was not the intent.
- **The platform-wide recheck the ruling calls for: done, nothing in breach.** Cross-tabulated
  shortcuts-per-channel against captured `love.*`-per-channel across every tracked example and the
  three nested repos. `turtle` has `shortcuts.textinput` with captured `keypressed`/`keyreleased` —
  **different channels, compliant**. `paint`/`sapper` pair `hooks.singleclick/doubleclick` with a
  captured `love.mousepressed`, but those are hooks, not shortcuts, so the rule is silent.
  **`keyboard` is already fully compliant** — `shortcuts.keypressed` + `hooks.keypressed`, zero
  captured `love.*` — which is the ruling's best evidence: it is what we did when we thought hardest.
- **E1 ruled, and it overturns my recommendation on a point I had missed.** Owner: update the prompt
  **only on a genuine state change, with the call site as the signal** — a timeout needs its own
  counter, and a "did input land?" test needs a `lastInput` sentinel, which is new state kept solely
  to answer *"has anything changed since last frame?"*. **The trap was in my own words** *"only on an
  actual state change"*: a per-tick updater that acts only on a change must **store the previous
  value to compare against**. `keyboard` could afford such a sentinel because its claim table earned
  its keep elsewhere; here it would earn nothing.
  **So the prompt is written at exactly three sites, each already an event** — `arm_editor`,
  `reject_program` (from the submit callback), `finish_run`. `ctrl_update` keeps only the *game*
  state poll (has the queue drained?). **`R3`'s hazard disappears by construction**: nothing is
  issued per frame, so there is nothing to warn about.

## 2026-08-13 — EXECUTION: P-17-06 … P-17-14, seven commits, all landed

All in the nested repo on `newinput-edge`; **nothing pushed**. Gate at every commit: `verify.sh`
(**42 assertions, unchanged — no test added or removed**) plus a build-and-play smoke of **both**
emitted programs.

- **`ca7210d` P-17-06 — the editor onto `compy.input`.** Preceded by a **correction of my own note**
  (`cc0e1870`): the PR base **destroyed the widget on every successful submit** (oneshot → a
  `'userinput'` event → the gateway nils `love.state.user_input`), so upstream's per-tick re-arm was
  never dead code — it was re-creating the prompt after every run. My §2 had read `input()`'s early
  return and stopped. **Third instance this session of the same fault: a mechanism read at one end is
  not a mechanism.** The owner's ruling survived and was strengthened.
  **The throwaway harness earned its keep immediately** — driving the real file against a recording
  stub caught a bug I had *just written and had predicted in the correction an hour earlier*:
  `rearm_editor` called `show{}` over a shown field, which warns and drops both text and prompt. Now
  every prompt write goes through one branch. Five paths measured, all correct after the fix.
- **`522d860` P-17-07 — `shift+escape` as a combo + `hide()` on the menu exits.** The capability the
  author asked for; `<` kept per the owner. **Verified rather than assumed** that a load-time
  registration survives: the runtime runs the project's top level inside `pcall(f)` *first*, then
  `set_user_handlers` → `occupy_input`, which seeds **hooks** and never touches **shortcuts**.
- **`3468f1f` P-17-08 — `is_shift_down` deleted, not converted.** `P-17-07` orphaned both copies. The
  plan said *check before deleting*; the check said dead.
- **`e2dacb0` P-17-09 — the `shift_held` mirror → polls**, plus `SHIFT_KEYS` → `Key.is_shift`, plus
  the render consumer. **One stated widening**: both Shift keys held, release one, next key now names
  a macro where it used to run. Platform-side, `Key.is_shift` joined P10's undocumented-members gap.
- **`569204e` P-17-10 — `plan_held` → `isrepeat`**, threading the press through `game_key`.
  Direct-control levels keep repeating deliberately — that is how holding a direction queues moves.
- **`bef4258` P-17-11 — the Tab pollers → 8 combos each**, per the owner's ruling. `side_run` not
  `stop_here`, so the press still reaches the field as before; `ignore_repeat` mandatory or a held
  Tab walks the levels. **No `love.keyboard.isDown` remains anywhere in either program.**
- **`37b996a` P-17-14 — `love.keypressed` → `hooks.keypressed`**, both programs, because combos now
  guard that channel. **Only that channel** — key releases and mouse presses keep their callbacks,
  and the distinction is the rule, not an oversight.
- **`1ac4398f` P-17-12 — the smoke checklist**, 27 rows in six sections, **all `[new]`**. It carries
  the new launch commands (the old one now fails: the source root is not a runnable project) and
  names three rows that are questions rather than tests.

**What is left: `P-17-13`, the comment compaction — and I am NOT doing it yet.** Raised to the owner:
the plan orders it last, but the human smoke pass is the gate that can still send code back, and
compacting comments the gate's findings would rewrite wastes the pass. Sequencing is theirs.

## 2026-08-13 — P-17-13 removed, and both successors checked rather than assumed

Owner: drop `P-17-13`, and **make sure comment compaction and the smoke pass of all examples are
still carried by the sprint plan or the release plan.** Neither would have survived the removal
cleanly, so both were amended rather than confirmed.

- **`P-17-13` removed** from `P-17-04`, struck in place with where the work went. The reason is the
  one I raised: compaction runs **after the code stops moving**, and P-17's code is not final while
  the human smoke pass can still send it back.
- **`P11` did NOT already own the example repos' comment compaction** — it owns the *marker* sweep
  (27 markers, unambiguous gate) and the doc-corpus prose is explicitly the *parent's*. Example-repo
  comment **bloat** was carried inside each example's own step (`P-18-10` for `keyboard`). So
  removing `P-17-13` would have dropped `maze`/`draw`'s compaction on the floor. **P11's row and
  §16.3 item 7 now name it**, with `P-18-10` as the model and `balloons` + the tracked examples in
  the same pass.
- **Phase G's smoke coverage was narrower than "all examples"** — it named the detached repos'
  gate and said *"`maze` and `sapper` owe theirs"*. **Measured the real scope** rather than
  restating it: `git diff 3256aac..HEAD -- src/examples/` gives **nine tracked** examples with code
  changes (`clock`, `guess`, `paint`, `pong`, `repl`, `sapper`, `tixy`, `turtle`, `valid`; `life`
  untouched) plus **three detached** (`keyboard`, `maze`→also `draw`, `balloons`) = **twelve**.
  Phase G now states that all twelve are smoked and that **the gate differs, not the requirement**:
  the three detached each need a written list because their PR has no other gate — **`balloons` is
  OWED** — while the nine tracked ride the platform PR's review pass, with a written list where the
  mechanism changed materially (**`sapper`**, P19's, and `turtle` as the other candidate, being the
  only tracked example that registers a shortcut).
- The closing line is the one that matters and it is now in the release plan: **nothing in this work
  has been run in a game scene by anyone, at any commit, in any example.** For input behaviour this
  pass is not a formality on top of testing — it *is* the testing.

## 2026-08-13 — P-17-15 commissioned: a cold review of the whole step

Owner: add a P-17 substep for a cold review and run it. **Id 15, not 13** — `P-17-13` is a tombstone
and ids are not reused.

- **Commissioned on the P-18 model:** Opus, **model passed explicitly**, read-only, given the delta
  `dsent/dsent/dev..HEAD` **as a whole** rather than commit by commit, and told to **form its own
  view before reading any of this step's documents** — it is run separately precisely so its reading
  is independent, and a disagreement is the output, not a problem.
- **Told to measure, not reason**, with the recipes: `verify.sh` (and the `luajit`-only shim, and
  that the scratchpad is `noexec`), `.compy/build` + `love src play <out>/maze|draw`, why `stdbuf`
  matters, and that it may write its own throwaway drivers.
- **Given four platform claims it must NOT take on trust** — the overlay gate, `show`-over-shown
  being unable to change the prompt, the base destroying the widget on submit, and a load-time
  shortcut surviving activation — each to be checked in `/repo/src` and at the PR base where the
  claim is about a change.
- **And pointed at the weakest link in my own evidence, explicitly:** the editor flow was verified
  against a **stub of `compy.input` I wrote from reading the runtime**, so if I read it wrong the
  stub agrees with me. Told to attack that directly.
- Told what NOT to report: comment verbosity is deliberate until `P11`'s pass (owner ruling), so a
  verbose comment is not a defect — a *wrong* one is.

Prompt of record `../../../validation/prompts/P-17-15-cold-review.md`; deliverable
`../../../validation/reviews/S39-P17-cold-review.md`. Running.

## 2026-08-13 — P-17-15 returns one narrowing; P-17-16 restores it

- Cold Terra review delivered S39-P17-cold-review.md: one medium, player-visible narrowing. The
  exact Shift+Escape combo omitted Shift held with Alt, Ctrl, or both; upstream accepted all three.
- Owner ruled as for keyboard: make every supported variant visible, so the author can rule on it.
  P-17-16 was recorded before code, then corrected before execution when I verified that the
  Ctrl+Alt+Shift form was also in the upstream predicate.
- da9d1c2 (nested maze): all three exact variants registered in both emitted programs. verify.sh
  42 / 0 / 0, platform busted tests 946 / 0 / 0 / 10, and both emitted-program smokes reached
  Project play opened before their expected timeouts. Nothing pushed.

## 2026-08-13 — wrap

- User requested a successor to clear the remaining sprint with human smoke and comment compaction
  postponed to its end. Wrote report and session40 prompt: it carries both plan locations and the
  recommended order P16 → P19 → P13 → P10 → P11; P9 is closure/accounting, not new code.
