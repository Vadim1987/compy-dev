# P-17-03 — the adoption analysis: what to do with maze, site by site

**Session:** 39, 2026-08-12. **Branch under analysis:** `src/examples/maze` @ `newinput-edge`
(`b8cc436`). **Status:** analysis complete; **no code has been written**. `P-17-04` turns this into
execution substeps.

**Instrument:** `doc/development/conventions/input_adoption.md` (Q1–Q10 + Rules of restraint).
**Inputs:** the cold site inventory (`../outcomes/P-17-00-adoption-inventory.md`, 29 sites, its ids
used verbatim here), the measured platform facts
(`../notes/P-17-00-platform-facts-for-the-editor-migration.md`), the practice catalogue
(`P-17-01-practice-catalogue.md`, consulted **after** the checklist), and the upstream reading
(`S39-maze-upstream-input-assessment.md`).

**Order is the owner's** (2026-08-12): *regressions the new platform may introduce → locally
duplicated machinery → focused migrations where the gain is real, **and a report where it is not***.

---

## 1. Regressions the new platform may introduce

These are not adoption choices. They are things that **change under this project's feet** because
the platform it runs on is no longer the platform it was written against, and they are first because
a migration that lands on top of an unnoticed regression buries it.

### R1 — the overlay gate is gone, so the game's handlers now run while the field is up

**The change, measured at both ends.** At the PR base a shown widget meant the project's keyboard
handler was **not called at all** (`3256aac:controller.lua:625-630`). At HEAD the gateway forwards
unconditionally and the project route walks **shortcuts → hooks → widget**
(`projectInputController.lua:135-145`).

**Affected sites:** M7, M8 (`maze_main.lua`'s `love.keypressed` / `love.keyreleased`), D7
(`draw_main.lua`'s `love.keypressed`).

**What it does to this game, read statically:** on an editor level, every character typed into the
field now enters `love.keypressed` first. In **maze** it dies harmlessly — `GS.mode == "game"`, so
`game_key(k)` runs, `SYSTEM_KEYS[k]` has only a `menu` entry no key name can reach, and
`ctrl_pressed` is `nil` because `arm_editor` set it so. In **draw** it dies even more thoroughly:
`ctrl_pressed` is *structurally* always `nil` there (`controls.lua` is MAZE-only), so `drawGameKey`'s
fallback is dead code.

**Verdict: no code change required, and a smoke row is required.** Inert-by-reading is not
inert-by-measurement, and this is the first time this project's handler and its field are live in the
same instant. `P-17-04` owes a checklist row: *type a long command on an editor level; every
character appears once and nothing else happens.*

### R2 — with R1, an exit that leaves the field shown is now a two-consumer collision

`to_menu()` (`maze_main.lua:92-96`) and `toDrawMenu()` (`draw_main.lua:219-228`) drop
`ctrl_update`/`ctrl_pressed` and **hide nothing** — there is no `compy.input.hide()` in either. That
was survivable while the only route to them from an editor level was the typed `<`, because the
menu that came up could not receive keys anyway. Under R1 it is not: on the menu, with a leftover
field shown, `menu_key(k)` **and** the field both receive the digit — the track starts *and* the
digit lands in a field the player cannot see the purpose of.

**Verdict: the exit paths owe `compy.input.hide()`.** This is a consequence of a change *we* are
making, not a defect of theirs, so it lands in our patch with its reason in a comment. Note it is
**doubly required** once G1 lands, because `shift+escape` makes those paths reachable from inside the
field deliberately.

**Honest limit:** the pre-existing half — that `<` already left the field shown on the base — is
**upstream's** and predates us. We are not fixing their bug; we are not allowed to introduce a worse
version of it.

### R3 — a naive port of the per-tick re-arm warns once per frame

Not a platform regression so much as a trap with this project's name already on it. At the base a
second `input_text()` while one was shown was a **silent** no-op (*"there can be only one"*,
`3256aac:consoleController.lua:562-566`). `compy.input.show{}` over a shown widget is a no-op **that
logs a warning**, and even with `force` only `text` applies — **it cannot change the prompt**
(`userInputController.lua:266-279`).

`core_editor.lua`'s `rearm_input` runs every tick from `ctrl_update` and calls `input_text` on its
not-running branch; `reject_program` calls it **precisely to change the prompt**, because a syntax
error *is* the prompt (`input_prompt()` returns `GS.invalid.msg`).

**Verdict: the replacement is `configure{ prompt = … }` + `set_text`/`clear`, never a re-`show`.**
Our own `790ac19` already paid for the naive version once — *"show() was re-issued on every single
tick, warning each time"*. That is E1's single most important design constraint.

### R4 — `isrepeat` is delivered now, and nothing breaks by ignoring it

At the base the platform stripped it. Now hooks receive LÖVE's own arguments. Upstream's handlers
take one parameter and simply ignore the rest, so **no regression** — but it is what makes D3 below
possible.

---

## 2. Locally-duplicated machinery — replace with the platform's

### E2 — `is_shift_down` ×2 → `Key.shift()`  · Q2 · **convert**

**Sites:** M4 (`maze_main.lua:145-148`), D4 (`draw_main.lua:305-308`) — two near-identical copies of
`isDown("lshift") or isDown("rshift")`, one per program, because the split duplicated the function.

**Gain, on its own terms:** the fold ships, and a local copy also hard-codes *which keys count as
Shift* — a set the platform has changed once. This is the one conversion this repo has already ruled
correct, in `a045fdb`, before upstream's rework deleted the file it was in. **Behaviour identical:**
`Key.shift()` is the same two-key poll.

### E3 — `macro_state.shift_held` → `Key.shift()`  · Q1 + Q6 · **convert**

**Sites:** M11 (`SHIFT_KEYS`), M12 (`handle_key` sets it), M13 (`release_shift` clears it), **plus a
third consumer the inventory did not list as a site: `maze_render.lua:221`**, where `draw_macro_ui`
dims the whole screen while Shift is held.

**Why the gain is real, and it is the strongest case in the step.** A lost `keyreleased` — focus
change, a swallowed event — leaves the mirror `true` forever. That does not merely break macro
naming: it leaves the screen **permanently dimmed**. Under owner calibration (a), a focus-shaped risk
whose only cost is a missed event earns a comment, not a change; a **stuck visible UI state** is a
different animal, and this one is cleared only by a restart.

**And the Q6 antipattern dissolves without restructuring** — a correction to the cold inventory,
which concluded this pair *"would need restructuring, not a mechanical swap"*. That conclusion
assumed the replacement had to be a shortcut, and Q6 rightly notes a modifier's own release has no
bindable combo. But `release_shift` is not reached through a shortcut: it is called from the game's
own `love.keyreleased`, which **does** receive `lshift`/`rshift`. So:

- the two **reads** of `shift_held` (M12's `elseif`, and `draw_macro_ui`) become `Key.shift()`;
- the two **writes** disappear with the field;
- `release_shift`'s `finish_recording()` **stays exactly as it is** — recording is opened by
  `start_recording` on a *different* key's press and closed on the Shift release, which is not a
  mirrored open/close pair at all. Once the mirror is gone, no Q6 shape remains.

**`SHIFT_KEYS` (M11) → `Key.is_shift(k)`**, which exists and is exported. **Stated cost:**
`Key.is_shift` is **not documented** in `doc/input_api.md` (only `shift/ctrl/alt` and `any_pressed`
are) — the same P-10 gap `Key.is_mod` and `Key.is_alt` are already recorded under. Precedent is the
owner's ruling in session37: use the platform predicate; the documentation gap is P-10's problem, not
a reason to keep a local copy. **`Key.is_shift` should join that gap's list.**

### E4 — `plan_held` → `isrepeat`  · Q1 + Q4 · **convert, with one argument threaded**

**Sites:** M15 (`plan_held = {}`), M16 (`plan_key` consults and sets it), M17 (`plan_key_up` clears
it). The file's own comment says what it is for: *"A held key repeats keypresses; act on the edge
only."*

**This is `keyboard`'s `INPUT.held`, by the same author** (dsent wrote both; the practice catalogue's
§2 material applies almost verbatim). Same failure: a lost `keyreleased` wedges that key for the
session — here, one direction silently stops working mid-track.

**Gain:** an authoritative flag replaces an inferred one, and a wedge-able table disappears. **Cost,
stated:** the game's `love.keypressed(k)` passes **one** argument into `game_key(k)` → `ctrl_pressed(k)`,
so `isrepeat` must be threaded through those two call sites. That is a small, mechanical, visible
change to two functions in `maze_main.lua` — not a restructuring, but not zero either.

**`plan_key_up` (M17) then has no body left**, and `love.keyreleased` (M8) shrinks to
`release_shift(k)` alone.

### E5 — the Tab pollers → a keypressed binding  · Q1 + Q4 · **convert, and say the narrowing**

**Sites:** M1 (`maze_main.lua:73-88`), D1 (`draw_main.lua:261-270`) — `love.keyboard.isDown("tab")`
compared against a `tab_was_down` global, once per frame, deriving an edge. Q4 names this exactly:
*"That is an event. Use the channel."*

**Why it was written as a poll, and why that reason is gone.** This is the interesting one. Tab
serves *editor* levels among others, and at the base a shown field meant `love.keypressed` never
fired — so an event binding **could not have worked**. R1 removes that. The workaround's premise
expired with the platform change, which is the same shape as the `<` finding in the assessment.

**The narrowing, and it must be stated or not done** (Rules of restraint): a **bare-key** binding
matches only when no modifier is held, where the poll fired regardless. So `Shift+Tab` and
`Ctrl+Tab`, which advance the level today, would stop. Neither is a documented gesture and neither
appears in `TEST-PLAN.md`, but *"nobody meant it"* is not the same as *"nobody does it"*.
**Recommended: convert, state the narrowing in the comment, and give `P-17-04` the option of also
binding the `'*+tab'` class if the owner would rather lose nothing.**

---

## 3. Migrations where the gain is real

### E1 — `core_editor.lua` onto `compy.input`  · **required, and it is the step**

**Sites:** C1 (`arm_editor`, `reject_program`), C2 (`process_user_input`). Six calls to globals
`b4d96eca` deleted *"with no shim, no deprecation path"*. **Without this the editor does not run at
all, in either program** — this is not adoption, it is the repair that makes the branch work.

The shape, constrained by R3:

| upstream | replacement |
|---|---|
| `arm_editor`: `GS.input = user_input()`, `input_text("Commands:", lines)` | `compy.input.show{ prompt = "Commands:", text = …, on_text_entered = … }` |
| `ctrl_update = process_user_input` (per-tick poll) | the callback; the poll disappears |
| `process_user_input`'s `GS.input:is_empty()` / `GS.input()` | — |
| `reject_program`: `input_text(input_prompt(), lines)` | `configure{ prompt = input_prompt() }` + `set_text(lines)` |
| `rearm_input`: `input_text(input_prompt(), lines(GS.program or ""))` | `configure`/`set_text` **only when the state actually changed** — never an unconditional per-tick call |

**One thing `P-17-04` must not lose:** `rearm_input` does **two** jobs, and only one is the editor's.
Its `if GS.running then finish_run() end` branch is a genuine per-tick state poll (has the queue
drained?) and **stays on `ctrl_update`**. Only the re-arm half moves.

**And a design question this raises rather than settles:** upstream's flow re-arms *from a poll*, so
"the program finished, put the prompt back" is currently expressed as a tick that notices. With
`on_text_entered` the submit is an event again. Whether the re-arm becomes event-driven or stays a
tick is a real choice with a behavioural edge (a run that ends mid-frame), and it belongs in
`P-17-04` with the owner's eye on it, not in this document as a decision.

### G1 — `shift+escape` as a shortcut  · **convert; this is the headline**

**Sites:** M5/M7 (`on_escape` and its call site), D5/D7.

Today the game hand-matches `k == "escape"` then asks `is_shift_down()`. Registering
`compy.input.shortcuts.keypressed['shift+escape']` is the platform's form — and, because shortcuts
run **before the widget**, it is what makes the gesture reach the program **while the editor field is
active**, which is exactly what `b8cc436`'s `TEMPORARY` comment asks for.

**`<` stays** (owner, 2026-08-12): it is a command in the game's language, and deleting it is a
change a child would notice. We add the capability and report to the author that their stated
condition is met. **The deletion is theirs to make.**

**Two things this must get right:**

1. **The handler must consume** (return truthy), or the walk continues and the widget also receives
   the Escape — which *clears the field* (`doc/input_api.md`: Escape clears and calls `after_cancel`,
   staying shown). Exiting to the menu and wiping the draft in one keystroke is not a gesture anyone
   designed.
2. **R2's teardown lands with it**, or the field survives the exit.

**Behaviour delta to state:** bare Escape is unchanged (the game ignores it; the widget clears the
field, as before). Shift+Escape **gains** reach it did not have. Nothing that worked stops working.

---

## 4. No gain — reported, not converted

The owner's test is *"is the replacement justified on its own terms"*, and for these it is not. Each
is recorded so a later reader does not mistake the omission for an oversight.

- **M3 / D3 — `love.mousepressed = SYSTEM_KEYS.menu`.** The framework **seeds a project's captured
  `love.*` handlers as hooks** (`controller.lua:239`, and `_bindable` includes the pointer channels),
  so this already runs through the new surface. Rewriting it as `compy.input.hooks.mousepressed`
  changes the spelling and nothing else — the definition of a migration without gain.
- **M6 / D6 — `game_key` / `drawGameKey`.** Q8's shape (a hand dispatch) but not Q8's problem: this
  demultiplexes by *game mode*, not by combo. Shortcuts decompose combos; there are none here.
  *(D6's `ctrl_pressed` fallback is dead code in DRAW. It is the author's, it is harmless, and
  deleting third-party dead code is not our errand — worth a line in the PR body at most.)*
- **M7 / D7 — the rest of `love.keypressed`.** After G1 takes the Escape branch, what remains is a
  mode router. It stays a hook, seeded as it already is.
- **M9 / M10 — `keys()` / `plan()`.** Control-mode initialisers. They assign handlers; they do not
  read input.
- **M14 — `start_recording`.** A `PRIMITIVES` lookup. Not input.
- **M18 — `PLAN_ACTS` / `plan_dispatch`.** Q8 shape, keyed by *command meaning*. Same answer as M6.
- **M19 / D8 — `menu_key` / `drawMenuKey`.** A key→track lookup. Converting each digit to a shortcut
  is renaming for its own sake, **and it would make things worse**: the echo problem below is a
  property of *opening the field*, not of how the digit was dispatched, so a shortcut per digit buys
  nothing and multiplies the registrations.

---

## 5. The echo guard — a known technique, and where it belongs

`menu_key("3")` → `start_track` → `start_level` → `editor()` opens the field **synchronously**, so
the digit's own `textinput` can land in the field it just opened. This is `keyboard`'s D1 defect by
shape, and `doc/input_api.md` ("Opening the overlay from a key") documents both the problem and the
fix: a **one-shot shortcut on the `textinput` channel**, which runs before the overlay and
unregisters itself.

Two constraints ride with it, from the same section: **re-arm wherever we close the overlay
ourselves** (Escape clears without closing, so a spent one-shot stays correct), and **the trigger
must be a bare key** — a modified combo cannot be guarded, because the channels do not share a combo
string for it. Both are satisfied here: the triggers are `1`/`2`/`3` and the only close we add is
R2's.

**Not asserted as a live defect.** It needs driving in the emitted project, and it may predate us —
on the base, `input_text` was called from the same synchronous path. `P-17-04` owes it a smoke row
either way.

---

## 6. What `P-17-04` has to sequence

Dependency order, with the reason:

1. **E1** first — nothing else can be smoked until the editor runs. **Its own commit.**
2. **R2 + G1 together** — the teardown and the gesture that makes it necessary are one concern.
3. **E2, E3, E4, E5** — independent of each other; E4 touches `maze_main.lua`'s two call sites, E5
   touches the same file, so ordering them adjacently reduces churn.
4. **The smoke checklist section** — R1, R2, G1, E5's narrowing and §5's echo each owe a row, and
   with the suite frozen (owner) **this is the step's only gate**.
5. **The comment-compaction pass, last** (`P-17-00-shape-and-plan.md` §5).

**Regression fence at every commit:** `./verify.sh` (42 assertions) plus a build-and-play smoke of
both emitted programs. The suite does not grow.

## 7. Confidence and limits

- **Verified in code:** every site location and its reachability (the inventory's, spot-checked by
  the parent); the platform behaviours in §1 and §3, read at HEAD **and** at the PR base where the
  claim is about a change; `Key.is_shift`'s existence and its absence from the guide.
- **A correction of the cold inventory, stated rather than silently applied:** its Q6 verdict on
  M12/M13 (*needs restructuring*) rests on assuming a shortcut must bind the closing half. The game's
  own `love.keyreleased` already receives modifier releases, so the mirror can go without
  restructuring anything (§E3).
- **Not measured — nothing here has been run in a game scene.** No level was reached, no keystroke
  injected; this container cannot. Every claim about what a player sees is read from code paths.
  §1's R1/R2, §5's echo, and E5's narrowing are the three that most deserve a human's eye.
- **Out of scope, so it is not mistaken for a clean bill:** the author's game design; whether the
  platform should adopt `.compy/build`; `compy-ide-input-esc-dataloss`; and upstream's pre-existing
  behaviour where `<` leaves the field shown.
