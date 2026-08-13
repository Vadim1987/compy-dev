# P-17-04 — the triage: the analysis turned into execution substeps

**Session:** 39, 2026-08-13. **Branch:** `src/examples/maze` @ `newinput-edge` (`b8cc436`), no
commits yet. **Status:** plan written; **nothing executed**. `P-17-05` is a gate before any of it.

**Input:** `P-17-03-adoption-analysis.md` — five conversions (`E1`–`E5`), one capability (`G1`),
three platform-behaviour findings (`R1`–`R3`), seven sites reported as **no gain**.
**Shape and rulings:** `P-17-00-shape-and-plan.md`.

---

## 0. Standing conditions for every substep below

- **One concern per commit**, conventional-commits style, in the **nested repo**. **Never push.**
- **The gate at every commit:** `./verify.sh` (**42 assertions**, unchanged — the suite does **not**
  grow, owner 2026-08-12) **plus** a build-and-play smoke of **both** emitted programs:
  ```sh
  cd src/examples/maze && ./.compy/build /abs/scratch/emit
  cd /repo && timeout 25 xvfb-run -a stdbuf -oL -eL love src play /abs/scratch/emit/maze   # and /draw
  ```
- **Comments stay verbose while the work is live**; compaction is `P-17-13`, once, at the end
  (`P-17-00-shape-and-plan.md` §5).
- **Citations:** no `doc/…` path and no platform-internal identifier inside this repo; naming the
  guide and its section is tolerable where it is really needed
  (`agents/rules/commenting.md`, "Citations", as refined 2026-08-13).
- **A deviation lives in the workspace**, not only in a commit message.
- **The game's rules are not ours.** Any *"would a player notice?"* answer of *yes* stops the
  substep and comes back to the owner.

---

## 1. The gate

### `P-17-05` — walk the owner through the seven "no gain" sites  · **BLOCKS everything below**

**Owner's instruction, 2026-08-13:** *"after it plan the step P17-05 of walking me through 'seven
sites with no gain' — I may overrule or contest, and it may lead to replanning, but having base plan
first is more important."*

The seven, with the reason each was declined, are `P-17-03` §4: **M3/D3** the pointer binding (the
framework already seeds captured `love.*` handlers as hooks, so a rewrite changes the spelling only);
**M6/D6** `game_key`/`drawGameKey`; **M7/D7** what remains of `love.keypressed` after `G1`;
**M9/M10** the control-mode initialisers; **M14** `start_recording`; **M18** `PLAN_ACTS`/
`plan_dispatch`; **M19/D8** `menu_key`/`drawMenuKey`.

**Form:** a walkthrough with the owner, one site at a time, each with its code, its checklist shape,
and the specific reason the replacement is not justified on its own terms. **Not a document to
approve — a conversation to have.** Its outcome is recorded here as an amendment.

**Why it is a gate and not a footnote:** four of the seven are declined on the same argument (*"Q8's
shape but not Q8's problem — they demultiplex by game mode or command meaning, not by combo"*). If
that argument is wrong, it is wrong four times, and every one of them is a substep this plan does not
currently contain.

---

## 2. Execution substeps

Ordered by dependency. Each is one commit unless stated.

### `P-17-06` — `E1`: `core_editor.lua` onto `compy.input`  · **first, and nothing can be smoked before it**

Six legacy calls in one CORE file, shared by both programs. Without it **neither program's editor
runs at all** — this is repair, not adoption.

- `arm_editor` → `compy.input.show{ prompt, text, on_text_entered }`; `GS.input = user_input()` and
  the `ctrl_update = process_user_input` poll both go.
- `reject_program` → **`configure{ prompt = input_prompt() }` + `set_text`**, never a re-`show`
  (`R3`: a re-show cannot change the prompt, and a syntax error *is* the prompt).
- `rearm_input` → its re-arm half becomes `configure`/`set_text` **only on an actual state change**;
  **its `finish_run()` half stays on `ctrl_update`**, because that is a genuine per-tick state poll
  (has the queue drained?) and not editor business.

**The one open design choice inside this substep** — whether the re-arm becomes event-driven (from
`on_text_entered`) or stays a tick that notices — **is named here rather than decided**: it has a
behavioural edge on a run that ends mid-frame. Recommendation: keep the tick, because that is what
upstream does and this substep is already the largest change in the step; revisit only if smoke shows
a visible lag.

**Owes the checklist:** type a valid program → it runs; type an invalid one → the error becomes the
prompt and **the text stays for correction**; run to completion → the prompt returns empty.

### `P-17-07` — `G1` + `R2`: `shift+escape` as a shortcut, with the teardown it makes necessary

**One commit, because they are one concern:** the gesture and the cleanup that gesture requires.

- Register `compy.input.shortcuts.keypressed['shift+escape']` in both programs; `on_escape`'s body
  moves behind it and the hand-match leaves `love.keypressed`.
- **The handler must return truthy**, or the walk continues to the widget and the same keystroke
  *also clears the draft* (`doc/input_api.md`, Escape clears and stays shown).
- **`to_menu()` and `toDrawMenu()` call `compy.input.hide()`.** Mandatory: verified in code that
  **no built-in gesture closes a project-opened overlay** — `cancel_flow` never touches `shown` —
  so without it the exit strands an overlay for the rest of the run.
- **`<` STAYS** (owner, 2026-08-12). The PR reports to the author that their stated removal condition
  is now met; the deletion is theirs.

**Owes the checklist:** Shift+Esc from inside an active editor field returns to the menu, the field
is gone, and the draft was not silently wiped on the way.

### `P-17-08` — `E2`: the two `is_shift_down` copies → `Key.shift()`

`maze_main.lua:145-148`, `draw_main.lua:305-308`. Behaviour identical. After `P-17-07` the only
caller left is whatever `G1` did not absorb — **check before deleting the function**, do not assume
it is dead.

### `P-17-09` — `E3`: the `shift_held` mirror → `Key.shift()`  · **the strongest case in the step**

Reads become polls: `handle_key`'s `elseif`, and **`maze_render.lua:221`'s `draw_macro_ui`**, which
is a *display* consumer — a lost release leaves the screen **permanently dimmed until restart**, a
stuck visible UI state rather than a dropped event. `SHIFT_KEYS` → `Key.is_shift(k)`.
`release_shift`'s `finish_recording()` **stays exactly as it is**; once the mirror is gone no Q6
shape remains and nothing is restructured.

**Stated cost:** `Key.is_shift` is exported but **undocumented** — the same `P-10` gap `Key.is_mod`
and `Key.is_alt` sit in. Precedent is the owner's session37 ruling: use the platform predicate; the
gap is `P-10`'s problem. **This substep adds `Key.is_shift` to that gap's list** (a platform-side doc
edit, so it is a second commit in `/repo`, not in the example).

**Owes the checklist:** hold Shift → the screen dims; release → it undims; Shift+key names a macro as
before.

### `P-17-10` — `E4`: `plan_held` → `isrepeat`

Deletes a wedge-able held-key set (a lost release kills one direction for the session). **Cost, and
it is visible:** `love.keypressed(k)` must thread `isrepeat` through `game_key(k)` → `ctrl_pressed(k)`
— two call sites in `maze_main.lua`. `plan_key_up` then has no body left, and `love.keyreleased`
shrinks to `release_shift(k)`.

**Owes the checklist:** hold a direction key on a Track-2 level → **one** tile is appended, not a run
of them.

### `P-17-11` — `E5`: the two Tab pollers → explicit combo registrations

**Ruled (owner, 2026-08-13): multiply the combos, the `keyboard` way** — *"it looks ugly but may
clearly hint author about which combos they are really supporting (and maybe deciding to suppress or
ignore some)."* And the alternative I had floated does not exist: **`'*+tab'` raises at
registration** — `*` is legal only in the trigger position and only with modifiers (`alt+*`), so the
wildcard means *"these modifiers, any key"*, never *"any modifiers, this key"*.

The poll fired regardless of modifiers, so faithful preservation is **8 registrations**: `tab`,
`shift+tab`, `ctrl+tab`, `alt+tab`, `ctrl+shift+tab`, `ctrl+alt+tab`, `alt+shift+tab`,
`ctrl+alt+shift+tab` — in **both** programs. The `tab_was_down` globals and both pollers go.

**Two things to write down rather than absorb:** `alt+tab` is usually taken by the window manager
before any application sees it (register it, say so in the comment, do not pretend it works); and the
explicit list is the deliverable's *point* — it shows the author exactly which gestures this game
claims, and invites them to drop the ones they never meant.

**Owes the checklist:** Tab advances as before; Shift+Tab and Ctrl+Tab still advance.

### `P-17-12` — the smoke checklist section for `maze` and `draw`

`doc/development/smoke_checklists.md` (platform-side, persistent — outlives `wip/77`). **With the
suite frozen, this is the step's only gate**, so it is a substep and not a nicety.

Rows owed by the substeps above, plus three from `P-17-03` that no code change covers:

- **`R1`** — type a long command on an editor level: every character appears **once** and nothing
  else happens (the game's hook now sees every keystroke; inert by reading, never measured).
- **§5, the echo** — pick track 3 from the menu with `3`: the command field opens **empty**, with no
  stray `3` in it. If it is there, the one-shot `textinput` guard is owed
  (`doc/input_api.md`, "Opening the overlay from a key").
- **`R2`'s pre-existing half** — reach the menu by finishing the last level of a track, not by
  Shift+Esc: is the field gone there too?

**Launch commands go in the section**, because the old one no longer works: the source root is not a
runnable project; build, then play the emitted folder.

### `P-17-13` — the comment-compaction pass  · **last, always**

One pass over stabilised code, on the `P-18-10` model: dry up history, obituaries, intermediate
rulings and second phrasings; keep the reasons. Also the marker gate
(`grep -rn 'INTERIM:\|REMARK:' src/ tests/` empty) and the citation rule as refined.

---

## 3. Sequencing, and what is independent

```
P-17-05  (gate: the seven no-gain sites, with the owner)
   └── P-17-06  E1   editor onto compy.input        [required; unblocks all smoke]
         ├── P-17-07  G1+R2  shift+escape + hide()
         ├── P-17-08  E2     is_shift_down ×2        ─┐
         ├── P-17-09  E3     shift_held mirror        ├─ independent of each other
         ├── P-17-10  E4     plan_held → isrepeat     │  (08→09 share macro/maze_main;
         └── P-17-11  E5     tab pollers             ─┘   10→11 share maze_main)
               └── P-17-12  smoke checklist
                     └── P-17-13  comment compaction
```

`P-17-08`…`P-17-11` are mutually independent; run them **adjacently by file** to reduce churn
(`08`+`09` touch `macro.lua`/`maze_render.lua`/`maze_main.lua`; `10`+`11` touch `maze_main.lua` and
`maze_plan.lua`).

## 4. Rulings still owed

1. **The seven no-gain sites** — `P-17-05`, the gate above.
2. **`P-17-06`'s re-arm question** — event-driven or tick. Recommendation stated, not taken.
3. **Anything a substep turns up that a player would notice.** By standing rule that stops the
   substep, it does not get absorbed into it.

## 5. What this plan deliberately does NOT contain

- **No test work.** The suite does not grow (owner). `verify.sh` is a fence, not a target.
- **No deletion of upstream code**, including `<` and `drawGameKey`'s dead fallback branch. Their
  code, their call; ours is at most a line in the PR body.
- **Nothing about `.compy/build` as a platform convention.** Promoted, not answered
  (`P-17-00-shape-and-plan.md` §4.3).
- **No fix for upstream's pre-existing stuck-overlay paths** beyond the ones `G1` makes deliberate
  (`P-17-03` §R2). We do not ship a worse version of their defect; we also do not adopt it.
