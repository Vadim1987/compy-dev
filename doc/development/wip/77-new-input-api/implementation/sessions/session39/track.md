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
