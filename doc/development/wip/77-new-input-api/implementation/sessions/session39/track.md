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
