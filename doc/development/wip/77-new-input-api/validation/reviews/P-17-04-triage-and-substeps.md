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
- **Comments stay verbose while the work is live**; compaction is **`P11`**'s late pass, not this
  step's (`P-17-00-shape-and-plan.md` §5, and the owner's removal of `P-17-13`, 2026-08-13).
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

**Why it is a gate and not a footnote:** the declines rest on three different arguments, not one — a
correction of this document's first draft, made while preparing the walkthrough — and two of them
were weak enough to expect an overrule.

### The walkthrough's outcome (owner, 2026-08-13)

**Five declines upheld, on a better reason than the one I gave.** Owner: *"early translation from
keyboard coordinates into game semantics is exactly what I advocated for. Provided examples **are**
game semantics, already decoupled from triggering input events — i.e. a good thing."*

That reframes M6/D6, M18, M19/D8 — and M9/M10, M14 by extension — from *"nothing worth converting"*
to ***"already in the desired end state"***. A key-to-meaning table is **Q7 being satisfied**, not Q8
being ignored. Carried into `doc/development/conventions/input_adoption.md` as a clause under **Q8**,
so the next reader of the checklist does not mistake every key-keyed table for a combo demultiplexer.

**M7/D7 overruled, M3/D3 upheld — by a new universal ruling, not by taste.** Owner:

> *"We should use `compy.input.hooks` **when** the project uses `compy.input.shortcuts` **on the same
> channel**. Otherwise it's unobvious to users that what they consider to be a native `love.*`
> callback (= receiving all events) is instead a hook that could be guarded by shortcuts (= some
> events not reaching)."*

Applied here, the condition splits the pair I had bundled:

- **`love.keypressed` → `compy.input.hooks.keypressed`, in both programs.** `G1` puts
  `shift+escape` on that channel and `E5` puts eight `tab` combos there, so the handler becomes
  guardable and must say so. **This is `P-17-14`.**
- **`love.mousepressed` stays as it is.** No shortcut exists on any pointer channel in either
  program, so nothing guards it and the confusion the rule prevents cannot arise. *Flagged because
  the owner named "1+3" as a pair: their own rule, applied faithfully, leaves #1 declined.*

**The platform-wide recheck the ruling calls for: done, and nothing is in breach.** Every tracked
example plus the three nested ones, cross-tabulated (shortcuts per channel x captured `love.*` per
channel):

| repo | shortcuts | captured `love.*` | verdict |
|---|---|---|---|
| `turtle` | `textinput` | `keypressed`, `keyreleased` | compliant — **different channels** |
| `keyboard` | `keypressed` | none — `hooks.keypressed/keyreleased/textinput` | **already compliant** |
| `clock`, `life`, `paint`, `pong`, `sapper`, `tixy`, `balloons` | none | various | the rule does not bite |

`paint` and `sapper` keep `hooks.singleclick`/`doubleclick` beside a captured `love.mousepressed`,
but those are **hooks, not shortcuts**, so the rule is silent on them. **`keyboard` arriving already
compliant is the ruling's best evidence** — it is what we did when we thought hardest about it.

**Q11** in `input_adoption.md` now carries the rule.

---

## 2. Execution substeps

Ordered by dependency. Each is one commit unless stated.

### `P-17-06` — `E1`: `core_editor.lua` onto `compy.input`  ✅ **DONE `ca7210d`**

Six legacy calls in one CORE file, shared by both programs. Without it **neither program's editor
runs at all** — this is repair, not adoption.

- `arm_editor` → `compy.input.show{ prompt, text, on_text_entered }`; `GS.input = user_input()` and
  the `ctrl_update = process_user_input` poll both go.
- `reject_program` → **`configure{ prompt = input_prompt() }` + `set_text`**, never a re-`show`
  (`R3`: a re-show cannot change the prompt, and a syntax error *is* the prompt).
- `rearm_input` → **its re-arm half leaves the tick entirely** (see the ruling below); **its
  `finish_run()` half stays on `ctrl_update`**, because that is a genuine per-tick *game* state poll
  (has the queue drained?) and not editor business.

**RULED (owner, 2026-08-13): update the prompt only on a genuine state change, and let the call site
be the signal — no per-tick prompt call at all.** Their reasoning overturns my "keep the tick"
recommendation on a point I had missed:

> *"Updating the prompt on timeout has no choice but maintain its own time counter. Updating the
> prompt because new input landed would require maintaining `lastInput` and tracking its changes. If
> we do **not** use `lastInput` for another purpose (the way keyboard uses glyph claims), a shortcut
> provides the same effect — fire on state change — without maintaining another state."*

The trap was hiding in my own words *"only on an actual state change"*: a per-tick updater that acts
only on a change **must store the previous value to compare against**, and that stored value is new
state — precisely what this migration exists to delete. `keyboard` could afford such a sentinel
because its claim table earned its keep on other grounds; here it would exist solely to answer *"has
anything changed since last frame?"*, which the call sites already know.

**So the prompt is written at exactly three sites, each already an event:**

| when | where | what |
|---|---|---|
| a level arms its editor | `arm_editor` | `show{ prompt = "Commands:", text, on_text_entered }` |
| a submitted program is rejected | `reject_program`, reached from the submit callback | `configure{ prompt = bad.msg }` + `set_text` |
| a run finishes | `finish_run` | `configure{ prompt = "Commands:" }` + `set_text(GS.program)` |

**And `R3`'s hazard disappears with it.** No `show{}` or `configure` is ever issued per frame, so
there is nothing to warn about — the failure our own `790ac19` hit becomes unreachable by
construction rather than avoided by care.

**What stays on `ctrl_update` is the game's own state poll**, not the prompt's: *has the queue
drained?* → `finish_run()`. That is animation state with no event behind it, it is upstream's own
structure, and only the prompt work moves out of the tick.

**Owes the checklist:** type a valid program → it runs; type an invalid one → the error becomes the
prompt and **the text stays for correction**; run to completion → the prompt returns empty.

### `P-17-07` — `G1` + `R2`: `shift+escape` + the teardown  ✅ **DONE `522d860`**

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

### `P-17-08` — `E2`: the two `is_shift_down` copies  ✅ **DONE `3468f1f`** — deleted, not converted: `P-17-07` orphaned both, as the plan asked us to check rather than assume

`maze_main.lua:145-148`, `draw_main.lua:305-308`. Behaviour identical. After `P-17-07` the only
caller left is whatever `G1` did not absorb — **check before deleting the function**, do not assume
it is dead.

### `P-17-09` — `E3`: the `shift_held` mirror → `Key.shift()`  ✅ **DONE `e2dacb0`** (+ the `Key.is_shift` doc gap into P10)

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

### `P-17-10` — `E4`: `plan_held` → `isrepeat`  ✅ **DONE `569204e`**

Deletes a wedge-able held-key set (a lost release kills one direction for the session). **Cost, and
it is visible:** `love.keypressed(k)` must thread `isrepeat` through `game_key(k)` → `ctrl_pressed(k)`
— two call sites in `maze_main.lua`. `plan_key_up` then has no body left, and `love.keyreleased`
shrinks to `release_shift(k)`.

**Owes the checklist:** hold a direction key on a Track-2 level → **one** tile is appended, not a run
of them.

### `P-17-11` — `E5`: the two Tab pollers → 8 combos each  ✅ **DONE `bef4258`**

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

### `P-17-12` — the smoke checklist for `maze` and `draw`  ✅ **DONE `1ac4398f`**

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

### `P-17-14` — `Q11`: `love.keypressed` → `hooks.keypressed`  ✅ **DONE `37b996a`**

From the walkthrough's universal ruling. **Sequenced after `G1` and `E5`**, because the rule's
trigger is *"the project registers shortcuts on that channel"* — before those two land, it does not.
Mechanical: the function body is unchanged, only its binding site. **`love.mousepressed` is left
alone**, deliberately, with the reason in a comment: no shortcut guards the pointer channel, so the
ambiguity the rule exists to remove is not there.

**Owes the checklist:** nothing new — same handler, same channel. `verify.sh` and both smokes gate it.

### `P-17-15` — a cold review of the whole step  · **the last thing this container can do**

Added on the owner's instruction, 2026-08-13. **Id 15, not 13** — `P-17-13` is a tombstone and ids
are not reused.

**Why it earns its cost, from this step's own record rather than from principle:** three claims of
mine were wrong on first writing and every one was caught by *measuring*, never by re-reading — the
PR base's widget dismissal, the `show`-over-shown bug I had predicted an hour before writing it, and
the triage's own "four declines rest on one argument". Session38's four passes found a live
regression each time until the fourth built an instrument instead of inspecting.

**Shape**, following the P-18 model: a cold reviewer, model passed explicitly, **read-only**, given
the delta `dsent/dsent/dev..HEAD` as a whole rather than commit by commit, told to form its own view
**before** reading this step's documents, and told to **measure rather than reason** — it can run
`verify.sh`, build and play both programs, and write its own throwaway drivers.

**What it must not take on trust:** the platform claims this step rests on (the overlay gate, that a
`show` over a shown field cannot change the prompt, that the base dismissed the widget on submit,
that a load-time shortcut registration survives activation), and the harness I wrote — a stub I
built from reading the runtime will agree with me if I read it wrong.

Prompt of record: `../prompts/P-17-15-cold-review.md`. Deliverable:
`../reviews/S39-P17-cold-review.md`.

### `P-17-16` — preserve the Shift+Escape modifier family

P-17-15 found an unstated, player-visible narrowing: the old
`is_shift_down()` accepted Escape with Shift held alongside Ctrl or Alt, while
the exact `shift+escape` shortcut accepts only Shift. The key hook then consumes
the unmatched Escape, so three modifier variants cannot exit.

**Owner ruling, 2026-08-13:** register the variants so their supported gestures
are visible and the author can rule on them. In both `maze_main.lua` and
`draw_main.lua`, add `alt+shift+escape` and `ctrl+shift+escape` registrations
and `ctrl+alt+shift+escape`, all using the same consuming `on_escape` handler.
This restores the old predicate; it does not decide which variants the author
should retain later.

**Owes the checklist:** each Shift+Escape modifier variant leaves a direct-control
level just as Shift+Esc does; with a live editor field it exits without clearing the
draft.

### ~~`P-17-13` — the comment-compaction pass~~ · **REMOVED from this step (owner, 2026-08-13)**

Compaction is not P-17's to do. It belongs to the sprint's own late pass, **`P11`**, which exists
precisely so comments are cut **after the code stops moving** — and P-17's code cannot be called
final while the human smoke pass can still send it back.

**Where it went, so it is not lost:** `S27-triage-and-plan.md`'s `P11` row now names the example
repos' comment compaction explicitly, with `maze`/`draw` as the outstanding one (`keyboard`'s was
done inside its own step as `P-18-10`, which is the model). The marker gate
(`grep -rniE 'INTERIM|REMARK'` over `src/` and `tests/`, which reaches the nested repos) was already
P11's.

**What P-17 leaves for it:** the comments this step wrote are deliberately full — mid-development
verbosity is the owner's ruling of 2026-08-13 — so there is real work here, not a formality.

## 3. Sequencing, and what is independent

```
P-17-05  gate: the seven no-gain sites            [CLOSED 2026-08-13]
   └── P-17-06  E1   editor onto compy.input        [required; unblocks all smoke]
         ├── P-17-07  G1+R2  shift+escape + hide()
         ├── P-17-08  E2     is_shift_down ×2        ─┐
         ├── P-17-09  E3     shift_held mirror        ├─ independent of each other
         ├── P-17-10  E4     plan_held → isrepeat     │  (08+09 share macro/maze_main;
         └── P-17-11  E5     tab pollers             ─┘   10+11 share maze_main)
               └── P-17-14  Q11  love.keypressed → hooks.keypressed
                     │            [AFTER 07 and 11 — that is what makes the rule bite]
                     └── P-17-12  smoke checklist          [written; a HUMAN must now run it]
                           └── P-17-15  cold review of the whole step
```

**P-17-13 was removed** (owner, 2026-08-13): comment compaction is `P11`'s, and it runs after the
code stops moving — which it has not, while the smoke pass can still send code back.

`P-17-08`…`P-17-11` are mutually independent; run them **adjacently by file** to reduce churn
(`08`+`09` touch `macro.lua`/`maze_render.lua`/`maze_main.lua`; `10`+`11` touch `maze_main.lua` and
`maze_plan.lua`).

## 4. Rulings still owed

1. ~~The seven no-gain sites~~ — **closed 2026-08-13** (`P-17-05`): five upheld, `M7/D7` overruled
   into `P-17-14`, `M3/D3` upheld by the new rule's own condition.
2. ~~`P-17-06`'s re-arm question~~ — **closed 2026-08-13**: no per-tick prompt call; the three call
   sites are the signal.
3. **Anything a substep turns up that a player would notice.** By standing rule that stops the
   substep, it does not get absorbed into it. **The only one still open.**

## 5. What this plan deliberately does NOT contain

- **No test work.** The suite does not grow (owner). `verify.sh` is a fence, not a target.
- **No deletion of upstream code**, including `<` and `drawGameKey`'s dead fallback branch. Their
  code, their call; ours is at most a line in the PR body.
- **Nothing about `.compy/build` as a platform convention.** Promoted, not answered
  (`P-17-00-shape-and-plan.md` §4.3).
- **No fix for upstream's pre-existing stuck-overlay paths** beyond the ones `G1` makes deliberate
  (`P-17-03` §R2). We do not ship a worse version of their defect; we also do not adopt it.
