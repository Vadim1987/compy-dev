# S39 — the maze upstream, read for input: what 26 commits did to the input model

**Session:** 39 (validation phase). **Mode:** research + analysis. **Date:** 2026-08-12.
**Author:** assistant, at the owner's instruction, **before any merge is performed**.
**Gates:** **P-17-00** (`S27-triage-and-plan.md` §15.3 / the parent plan's Phase U example half), which
in turn gates the maze slice's ref change in `pr-assembly-guide.md` §5.1.

**The owner's question, in their words** (carried into this session's prompt from session37): *"what's
new in the origin commits since merge-base — did the author invent new input mechanisms, reconsider
old input practices? This validation is important to do before any merges."* This document answers
that, and reports the merge facts that answering it turned up.

**The sibling document** is `S37-keyboard-upstream-input-assessment.md`, which did this for
`keyboard`. Where the two differ materially, this one says so — the differences are the point.

---

## 1. What was examined, and how

- **Refs.** Ours: `newinput` @ `a045fdb`. Upstream: `dsent/dsent/dev` @ `b8cc436` (per `repos.txt`:
  *"maze: dsent/dsent/dev"* — the **`dsent`** remote, not `origin`, which is `nagydani/Compy-maze`).
  Merge-base: **`12f675f`**, which is **also exactly `origin/v3.4` and `dsent/v3.4`** (verified:
  all three resolve to the same object), so the current slice base and the merge-base are one commit
  and there is no third-party divergence to reason about.
- **Divergence:** `newinput` is **4 ahead / 26 behind**. Upstream since the base is **37 files,
  +4920 / −1208**. Ours since the base is **2 files, +52 / −20**.
- **Two authors, and the split matters when a question needs asking.** 15 of the 26 commits are
  **dsent** — *the same author as `keyboard`'s upstream* — and 11 are **Vadim**. The division is
  clean by kind: **dsent owns the input behaviour** (the plan mode, the Shift+Esc convention
  alignment, the `<` workaround, the level/navigation commands); **Vadim owns the restructure** (the
  `main.lua` split, `core_editor.lua`, `.compy/build`, the `spec/` suites). So §2.1(a) and §2.2 are
  addressed to the author this sprint has already been reading for two sessions, and §2.3 is not.
- **Method.** All 26 commit messages read in full; then the code, on the ref rather than a checkout
  (`git show dsent/dsent/dev:<file>`, `git grep … dsent/dsent/dev`) — nothing was checked out,
  merged or modified. Every claim below is from a tree, not from a commit message; where a commit
  message is the source it is named as such. Platform-side claims were read in `/repo/src`, and the
  two that matter were also read **at the PR base `3256aac`**, because the interesting ones are about
  what *changed*.
- **A trial merge was computed in memory only** (`git merge-tree --write-tree HEAD
  dsent/dsent/dev`). Unlike `keyboard`'s, **it does not succeed** — see §3.
- **One thing was run:** the pre-merge smoke, to establish a baseline —
  `timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/maze` → *"Project play opened"*,
  *"Running 'play'"*, no raise, killed by the timeout (exit 124). **No game level was reached and no
  keystroke was injected**; this container cannot.
- **Not examined:** the merged tree's runtime behaviour (there is no merged tree — §3), the author's
  *game* design, and the three `spec/` suites upstream added (noted as an asset in §4.4, not run).

---

## 2. The answer to the two questions

### 2.1 New input mechanisms — **yes, two**, and neither is a held-key mirror of the whole keyboard

**(a) The plan-a-path tile buffer** (`6121349`, `maze_plan.lua`, 257 lines, and a whole 20-level
track behind it). Direction keys no longer execute; they **collect** as keycap tiles in an on-screen
strip, Enter runs the pending tail, per-tile colour shows execution state, Backspace edits. It is a
third control mode beside `keys` and `editor`, wired the existing way — `controls.lua`'s `plan()`
sets `ctrl_pressed = plan_key` and `ctrl_update = plan_update`.

Its input machinery is one table and two handlers:

```lua
-- maze_plan.lua:137-152 (upstream)
-- A held key repeats keypresses; act on the edge only.

function plan_key(k)
  if plan_held[k] then
    return
  end
  plan_held[k] = true
  ...
end

function plan_key_up(k)
  plan_held[k] = nil
end
```

**Assessment — this is `keyboard`'s `INPUT.held` again, in a second repository, and it is the SAME
author's recurring idiom** (owner, 2026-08-12: *dsent* authored this version of `maze` and is
`keyboard`'s upstream author; `git log` confirms `6121349` is theirs). **An earlier draft of this
document called it independent corroboration and that was wrong** — it is not two authors converging,
it is one author reaching for the same construction twice. That weakens it as *evidence* and
strengthens it as *practice*: the pattern is this author's default, so the debt entry
(`technical_debt/input.md`, the tolerant-gesture / held-set family) is addressed to a known
correspondent, and the conversion is a conversation rather than a discovery.

It is an event-derived held-key set whose only job is to **filter OS key
repeat**, because the pre-feature platform stripped `isrepeat` before calling a project
(verified at the PR base: `3256aac:src/controller/controller.lua:162` is `local function
keypressed(k)`, one parameter). It has the same failure mode as the set this feature deleted from
`keyboard`: a `keyreleased` that never arrives — focus loss, a swallowed event — **wedges that key
for the rest of the session**, and in this game that means one direction silently stops working
mid-track with no player-side recovery but a restart.

**The feature already answers it exactly:** `isrepeat` is delivered end to end now
(`doc/input_api.md`, "Event hooks and shortcuts": *"Every shortcut, hook and callback receives
exactly the arguments LÖVE delivers for that event"*; the forwarding was verified in code —
`controller.lua:245-249` forwards varargs into the walk, and `projectInputController.lua:135-145`
passes them to the hook). The conversion is not free, though, and the cost is honest: the game's
`love.keypressed(k)` forwards **one** argument into `game_key(k)` → `ctrl_pressed(k)`, so `isrepeat`
has to be threaded through two call sites that currently do not carry it. **Raised, not recommended
here.**

**(b) The `draw` program's always-active editor field** (`656c1e1`, `5ee1bc9`). A second complete
program now lives in this repo (`draw_main.lua`, 344 lines, plus `draw_levels/menu/render/constants`
— a command-driven drawing canvas). Its Free-draw mode **keeps the command input field shown for the
entire session**. That is not a new *mechanism* so much as a new *duty cycle* for the existing one,
and it is what makes §2.2's finding matter: a program whose field is never down has no other channel
to the framework.

**Not new, and worth recording because it is the same anti-pattern one rung down:**
`macro.lua`'s `macro_state.shift_held` is an event-derived mirror of the Shift key (set in
`handle_key` when the trigger *is* `lshift`/`rshift`, cleared in `release_shift`). It predates the
merge-base — it is **not** something upstream invented — and our own migration did not touch it.
`Key.shift()` answers the question it asks, and cannot wedge; the release edge stays genuinely
useful there, because `release_shift` is also what **ends** a macro recording. Split cleanly, and
raised, not recommended.

### 2.2 Reconsidered old practices — **yes, twice; and one of them is a request addressed to this feature**

This is the sharpest difference from `keyboard`, where the answer was *"no — the retired practice was
propagated"*. Here the author reconsidered input practice deliberately, in the direction the platform
wants, and then **wrote down the thing the platform would not let them do**.

**(a) `9911a27` — *"align ux with the convention: Shift-Esc only exits mini-games"*.** Shift+Esc at
the top-level menu used to call `love.event.quit()`; now it is a no-op, and leaving the program to
the console is the framework's `Ctrl+Esc`. The comment states the convention it is aligning to. This
is the example moving **towards** the platform's contract without being asked.

**(b) `b8cc436` — a TEMPORARY typed `<` command, with the removal condition written into the
source.** Verbatim, from `draw_constants.lua:40-46`:

```lua
-- TEMPORARY: Shift+Esc cannot reach a program while the
-- editor input field is active (compy-maze-shift-esc-exit /
-- compy-ide-input-esc-dataloss, gated on the editor API), so
-- "<" exits to the drawing-game menu in the meantime. Both
-- mini-games register it: Free draw keeps its field active
-- throughout, so it has no other way out. Remove "<" when
-- Shift+Esc works in the editor.
```

and again at its handler (`draw_main.lua:118-120`): *"Removed together with `<` when Shift+Esc
reaches a program from an active editor field."* The same constraint is stated in `maze_main.lua`'s
own comment — *"On editor levels the text modal consumes keys, so this reaches us only on
direct-control levels and the menu"* — and `<` is registered in **both** programs
(`maze_constants.lua:45`, `draw_constants.lua:49`).

**The premise was true at the PR base, and this feature is what makes it false.** Measured, not
argued — the base's gateway routed the whole keyboard to the widget whenever one was shown, and the
project's handler was *not called at all*:

```lua
-- 3256aac:src/controller/controller.lua:625-630
local user_input = get_user_input()
if user_input then
  user_input.C:keypressed(k)
else
  if love.keypressed then return love.keypressed(k) end
end
```

At feature HEAD the gateway forwards unconditionally to the active route
(`controller.lua:872-874`), and the project route runs a three-consumer walk —
**shortcuts → hooks → widget**, the widget last and only if nobody consumed
(`projectInputController.lua:135-145`; `internals/user_input.md`: *"the gateway no longer routes on
widget presence — the overlay gate is removed"*). `shift+escape` is **not** framework-reserved: every
gesture the gateway keeps for itself needs Ctrl, or is `f10` (`controller.lua:766-844`), and
`Ctrl+Escape` is taken on `keyreleased`.

**So the feature closes, by construction, the gap the author documented and asked to have closed.**
This is the `maze` counterpart of `keyboard`'s *"the example's header is a list of six gaps in the
pre-feature platform, four of them closed by this feature"* — and it is stronger testimony, because
the author wrote a removal condition rather than a complaint. **It is also literally the same
witness**: dsent wrote both (§1), so the sprint now has one informed author documenting the
pre-feature platform's input gaps across two independent examples, in two different registers. **It is also the best single line the
PR description can carry about the examples**, and it costs the sprint nothing to claim: the code to
delete is the author's own workaround.

**Two cautions, both real, neither fatal:**

- The second issue ref, **`compy-ide-input-esc-dataloss`**, is about what *Escape itself* does to a
  field's contents. Nothing in this assessment establishes that this feature addresses it. Do not let
  the good half carry the other one into the PR description unexamined.
- **Removing the overlay gate is a behaviour change for exactly this project**, and it cuts both
  ways: on an editor level, every keystroke the child types now *also* reaches the game's
  `love.keypressed` (seeded as a hook) before the field sees it. Read statically, it is harmless in
  both programs — on editor levels `editor()` sets `ctrl_pressed = nil`, and `SYSTEM_KEYS` holds only
  a `menu` entry that no key name can reach. **Read statically is not measured**, and this is a thing
  to drive in the merged tree rather than reason about, because it is the first time this project's
  handler and its field are live at the same instant.

### 2.3 A third reconsideration, structural: one source root now emits **two** projects

`656c1e1` introduced `.compy/build` and split the tree. `BUILD.md` states the consequence in one
sentence: **"The source root has no `main.lua`, so it is not itself a runnable project"** — `maze/`
and `draw/` are produced by the build step, each a flat self-contained folder, with the shared
command core (`core_*`, `player`, `script`) **physically copied into both**.

Three consequences, all of them the owner's to rule on and none of them mine:

1. **The smoke command in this session's prompt stops working after the merge.**
   `love src play src/examples/maze` needs a `main.lua` at that path and there will not be one. What
   replaces it — build to a scratch dir and play that, or keep a root entry — is a decision.
2. **`.compy/build` is not a platform convention here.** Searched: the string appears nowhere in
   `/repo/src` or `/repo/doc` outside the nested repo. It is upstream's proposal (or a convention of
   the `dsent` platform fork, which is where this branch comes from). The example would arrive in the
   platform repo as a source root the IDE cannot run.
3. **The maze slice becomes a slice of a two-program repo.** `pr-assembly-guide.md` §5.1 already says
   the ref moves to `dsent/dsent/dev` when P-17-00 merges; what it does not yet say is that the diff
   then covers a program (`draw`) that did not exist when the sprint scoped "the maze example".

### 2.4 What did **not** happen — checked, and worth recording

- **Upstream adopted nothing from `compy.input`.** `git grep` over the whole upstream tree finds
  `compy.` only in `compy.graphics.shape2d` (the sprite files) and `sfx = compy.audio`. **No
  `compy.input`, no `Key`, no hooks, no shortcuts, no `before_exit`.** The author is developing
  against the pre-feature platform, and the game reaches the framework through raw `love.*` callbacks
  exactly as it did at the merge-base.
- **No new `love.*` input callbacks beyond the split.** `love.keypressed`, `love.keyreleased`,
  `love.mousepressed` and `love.resize` exist once per program (`maze_main.lua`, `draw_main.lua`) and
  are the same handlers the deleted `main.lua` had. `love.keyreleased` gained one line
  (`plan_key_up(k)` beside `release_shift(k)`).
- **`is_shift_down` is still hand-folded — and there are now TWO copies of it**
  (`maze_main.lua:145-148`, `draw_main.lua:305-308`), because the split duplicated it into both
  programs. This is precisely the fold our `a045fdb` replaced with `Key.shift()`, and §3 explains why
  the merge silently un-replaces it.
- **The Tab progression is still a hand-rolled edge over a poll**, also now in two copies
  (`poll_tab_progression` / `pollPictureProgression`): `love.keyboard.isDown("tab")` compared against
  a `tab_was_down` global, once per frame. It predates the merge-base. A keypressed hook or shortcut
  *is* the edge, so this is an adoption candidate — with the same caveat as §2.1(a): it is polled
  rather than handled almost certainly **because** of the gate §2.2 describes, since the levels it
  serves include editor levels where no keypress used to arrive.
- **No hand-matched modifier chords appeared.** The only modifier test in the whole upstream tree is
  the `is_shift_down` pair above and `macro.lua`'s `SHIFT_KEYS`.

---

## 3. The merge, measured — and unlike `keyboard`, **it does not apply**

```
$ git merge-tree --write-tree HEAD dsent/dsent/dev
CONFLICT (content): Merge conflict in controls.lua
CONFLICT (modify/delete): main.lua deleted in dsent/dsent/dev and modified in HEAD.
EXIT=1
```

**The two files our branch touched are the two files that conflict**, which is not a coincidence:
our migration's entire footprint is `main.lua` (+67/−20-ish) and `controls.lua` (5 lines), and
upstream **deleted `main.lua`** (554 lines, split into `maze_main.lua` + `core_anim.lua` +
`maze_logic.lua`) and **moved `editor()` out of `controls.lua`** into the new shared `core_editor.lua`
while adding `plan()` in its place.

### 3.1 The modify/delete is the whole story, and resolving it "conservatively" is the trap

Git's default leaves our `main.lua` in the tree. **That resolution is worse than either extreme**,
and it is measurable: our `main.lua` defines **53 globals, and 48 of them are redefined by upstream's
split files** — `love.update`, `love.draw`, `love.keypressed`, `love.keyreleased`, `love.resize`,
`SYSTEM_KEYS.menu`, `poll_tab_progression`, `ensure_init`, `next_level`, `reset_level`,
`start_level`, `advance_anim`, `execute_next`, `init_grid`, and **`rearm_input`** among them.

Keeping both files does not raise. It resolves by **require order**, silently, with half the game
coming from a stale copy — and `rearm_input` in particular exists in both with **completely different
semantics** (ours: sync the overlay to player idleness; upstream's: detect run completion and re-arm
with the last program text). **This is `keyboard`'s "clean merge, broken tree" class, one turn
nastier: there, a name was missing and the game raised at the first glyph; here a name is *doubled*
and nothing raises at all.**

The five globals of ours with no upstream counterpart are exactly our migration and the UX line it
sat next to: `open_editor_input`, `handle_editor_submit`, `player_is_idle` (the migration),
`record_echo` (absorbed upstream into `core_editor.lua`'s direct `echo_lines = lines`), and
`SYSTEM_KEYS.escape` (deleted upstream by `9911a27`, §2.2a).

### 3.2 The legacy surface the merge would carry in, and it is small and well-placed

Upstream's `core_editor.lua` — the file `dcdf740` extracted so **both** programs could share the
editor flow — runs the **poll-a-reftable idiom this feature removed**:

```lua
-- core_editor.lua:43-48, 59, 91, 100-102 (upstream)
function process_user_input()
  if GS.input:is_empty() then rearm_input() return end
  start_program(string.unlines(GS.input()))
end
...
  input_text(input_prompt(), lines)                      -- reject path
  input_text(input_prompt(), string.lines(GS.program or ""))  -- re-arm
...
  ctrl_update = process_user_input
  GS.input = user_input()
  input_text("Commands:", string.lines(text))
```

`user_input()` and `input_text()` were **deleted from the project environment** by `b4d96eca`
*"refactor(input)!: remove legacy text-input globals + poll machinery (M8-03)"*, whose own message
says: *"calling any of them is now an ordinary nil call, no shim, no deprecation path (D-1)."*
Verified independently: neither name is defined anywhere in `/repo/src` (only `love.state.user_input`,
a field, and a file-local `get_user_input`), and `doc/input_api.md`'s migration table maps both to
their `compy.input` replacements.

**So the upstream tip, as it stands, cannot run its editor on this platform at all** — in either
program. That is not a merge defect; it is the migration debt the merge makes visible, and it is
**the reason P-17 exists**. The good news is its shape: **6 call sites in 1 file**, and that file is
CORE, copied into both emitted projects — so one migration fixes both games.

### 3.3 Two carry-overs the merge decides the fate of

- **The only platform-doc citation in the whole repo is ours**, in the line the merge deletes:
  `main.lua:565` cites `doc/input_api.md, "Held keys"`. That violates the owner's ruling of
  2026-08-12 (`agents/rules/commenting.md`, "Citations" — a `doc/…` path cannot be followed from a
  repository that does not contain it). Whatever else happens, that citation must not be re-applied
  in its current form.
- **The two `REMARK:` markers are the owner's**, from `aeabb73 human(TF2): code review`, and both sit
  in `main.lua`: *"comment tooo verbose. simplify/compress"* and — directly on this step's subject —
  ***"can we try using shortcuts/hooks and callbacks more actively?"*** The marker gate
  (`grep -rn 'INTERIM:\|REMARK:' src/ tests/` empty before the PR) reaches nested repos, so these need
  **disposition by judgement, not deletion by merge**. Upstream carries no markers of its own.

---

## 4. What this means for P-17

### 4.1 The merge does not carry our migration forward — it obsoletes it

State it plainly, because every downstream decision follows from it: **none of our four commits'
*text* survives the merge, and all of their *intent* has to be re-applied to different code.**

| our change | where it lived | where it must go after the merge |
|---|---|---|
| `compy.input.show` / `on_text_entered` / `is_shown` / `hide` (3 new functions) | `main.lua` | `core_editor.lua` — a **different and richer** flow (invalid-message prompt, program persistence, `finish_run`) |
| `ctrl_update = rearm_input`, `open_editor_input()` | `controls.lua:editor()` | `core_editor.lua:arm_editor` — `editor()` moved out of `controls.lua` entirely |
| `Key.shift()` for the Escape fold | `main.lua:love.keypressed` | `maze_main.lua` **and** `draw_main.lua` — **two** copies now (§2.4) |

The honest framing for the owner is therefore **not** *"merge, then correct the defect it introduces"*
— which is what `keyboard` needed — but ***"take upstream's structure wholesale, then re-do the
migration on it."*** The re-do is not larger in principle (6 legacy call sites in 1 shared file), but
it is a **fresh design pass**, not a replay: upstream's editor flow has states ours never had.

### 4.2 The adoption inventory, as it stands after a merge

Required, or the game does not run:

- **E1 — `core_editor.lua`'s six legacy call sites** → `compy.input.show{ prompt, text,
  on_text_entered }` / `is_shown` / `hide`. Touches `arm_editor`, `process_user_input`,
  `reject_program`, `rearm_input`. **One file, both programs.**

Justified on their own terms (the owner's 2026-08-12 test — *"is the replacement justified on its own
terms"*, not *"can the project avoid the API"*), and each one **raised, not decided**:

- **E2 — `is_shift_down` ×2 → `Key.shift()`.** Exactly what `a045fdb` already ruled once; the merge
  just makes it two sites.
- **E3 — `plan_held` → `isrepeat`** (§2.1a). Deletes a wedge-able held-key set; costs threading one
  argument through `game_key`/`ctrl_pressed`.
- **E4 — `macro_state.shift_held` → `Key.shift()`** (§2.1), keeping `release_shift`'s
  `finish_recording` edge, which is a genuine event use.
- **E5 — `poll_tab_progression` / `pollPictureProgression` → a keypressed hook or shortcut** (§2.4).
- **E6 — `sc['shift+escape']` and the retirement of `<`** (§2.2b) — the one item that *removes*
  upstream code rather than converting it, and the one the author asked for.

Explicitly **not** on the list: converting `love.keypressed`/`keyreleased`/`mousepressed` to declared
hooks for its own sake. The framework seeds a project's captured `love.*` handlers as hooks already
(`controller.lua:239`, Decision 10), so those calls work as written; renaming them buys nothing that
the owner's adoption ruling recognises.

### 4.3 Behaviour questions this turns up — all of them the owner's

1. **Does the merge happen at all, and in what shape?** (§5.)
2. **What replaces the smoke command** once the source root stops being a runnable project (§2.3.1),
   and does the platform want the `.compy/build` convention at all (§2.3.2)?
3. **Is `draw` in scope for this sprint?** It did not exist when P-17 was scoped. It shares
   `core_editor.lua`, so E1 fixes it whether or not anyone decides it is in scope — but E2/E5 and its
   whole slice are a deliberate widening.
4. **The menu-digit question, from `keyboard`'s D1.** `menu_key(k)` matches a track key (`"1"`,
   `"2"`, `"3"`) and `start_track` → `start_level` can call `editor()` **synchronously**, which shows
   the field. The digit's own `textinput` then arrives with the field already up. In `keyboard` this
   exact shape was a live defect. **Not asserted here** — it needs driving in a merged tree, and it
   may well predate us.
5. **The two owner `REMARK:`s** (§3.3), one of which asks for more shortcuts/hooks and is answered by
   E5/E6.

### 4.4 What P-17 must **not** inherit uncritically

The merge brings ~4900 lines of *game* code, a second program, and three headless `spec/` suites. The
step is an **input migration**, not an adoption sweep of two games and not a review of the author's
game design (`§1.1`'s standing ruling: *would a player notice a difference?* → out of scope, raise it).

Two upstream assets change what is possible, and both are worth naming because `keyboard` had
neither:

- **maze now has tests.** `spec/script_spec.lua`, `spec/draw_levels_spec.lua`,
  `spec/draw_mode_spec.lua`, run by plain `lua` from the repo root, plus `verify.sh` (compile check +
  the three specs + a self-containment check per emitted project). The command core is
  characterization-tested. **A breaking test before the implementation is possible here**, which
  `agents/development.md` asks for and `keyboard` could not offer.
- **the author's own `TEST-PLAN.md`** — section A is the maze regression, section B the draw
  acceptance. `doc/development/smoke_checklists.md` should point at it rather than duplicate it, on
  the same principle that made `keyboard`'s design note a pointer.

---

## 5. Recommendation on sequencing (for the owner to rule)

1. **Merge, in the shape ruled for `keyboard`** — snapshot upstream onto its own branch, then a real
   `--no-ff` merge onto a new branch so later re-merges stay cheap. The trial says there is no
   textual fight worth having: two conflicts, one of them a single function.
2. **Resolve the modify/delete by DELETING our `main.lua`** and taking upstream's structure whole
   (§3.1), with the deletion's consequence stated in the merge commit: *the migration is not carried,
   it is re-applied*. Resolve `controls.lua` as upstream's (our `editor()` edit has no home there any
   more). **This leaves the merge commit with a tree that does not run the editor** — exactly the
   `keyboard` situation, and the same two honest options apply: record the break as the merge's known
   outcome, or land E1 immediately after as its own commit. Given that the break here is *total* for
   both programs rather than one scene, **E1 as the very next commit** is the better of the two, and
   it is the smallest useful unit anyway.
3. **Then the analysis-and-design pass**, on `core_editor.lua`'s flow specifically — it has states our
   migration never saw (`GS.invalid` as the live prompt, `GS.program` persistence across re-arms,
   `finish_run`), and getting those wrong is a rule change the child would notice.
4. **Then the triage** into `P-17-01 …`, with §4.3's five rulings named before any child starts.
5. **Do not switch the slice ref** (`pr-assembly-guide.md` §5.1) until the merge lands; check with
   `git -C src/examples/maze merge-base --is-ancestor dsent/dsent/dev HEAD` rather than by memory.

---

## 6. Confidence and limits

- **High confidence, verified in a tree:** everything in §2.1–§2.4, §3 and §4.1–§4.2. Each claim was
  read at the ref; the conflict and the 48-name collision were computed, not inferred; the legacy
  globals' removal was read in the platform *and* in the commit that removed them.
- **Verified at the PR base, not only at HEAD:** the overlay gate (§2.2). This is the load-bearing
  claim of the document and the one most worth re-checking, because it is what turns the author's
  workaround into a deletion.
- **Not verified — nothing was run beyond the pre-merge load.** No merged tree exists, no game level
  was reached, no keystroke was injected. The menu-digit question (§4.3.4), the overlay-gate side
  effect (§2.2, second caution) and every claim about what a child sees are **read from code paths,
  not observed**. The three upstream `spec/` suites were **not run**.
- **Out of scope, stated so it is not mistaken for a clean bill:** the author's game design; whether
  `draw` belongs to this sprint; `compy-ide-input-esc-dataloss`; and the platform-side question of
  whether `.compy/build` is a convention this repo wants.
