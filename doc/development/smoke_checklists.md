# Manual smoke checklists

Checklists a **human** runs, for the parts of this project no automated suite can reach: the nested
example repos have no tests, and nothing in CI can press a key. Each list is written to be run
top-to-bottom in one sitting, with the expected result stated so a failure is unambiguous.

**Referenced from:** `doc/development/tests.md` (what is and is not covered),
`wip/77-new-input-api/validation/plan.md` Phase G (the PR's own gate) and its §16.3 (each detached
example repo's PR gate is a human smoke pass), and the step that last changed the code.

**Which examples owe a list** (measured 2026-08-13; Phase G carries the full reasoning): this
feature changed code in twelve examples — nine tracked and three detached. **Written so far:
`keyboard`, `maze`+`draw`.** **Owed: `balloons`** (detached, so its PR's only gate is this pass) and
**`sapper`** (tracked, but its input mechanism changed materially and it carries a live defect —
P19's). The remaining tracked examples ride the platform PR's review pass.

**Keep this document current with the code.** A checklist that tests a mechanism the code no longer
has is worse than none, because it passes.

---

## keyboard

**Repository:** `src/examples/keyboard` (separate remote, own PR). **Last mechanism change:**
2026-08-12, the way a typed character is accepted, and the teacher chord `Ctrl+Alt+H` becoming a
registered shortcut instead of a hand-matched combo — see `internals/examples/keyboard.md`. Cases marked **[new]** exercise that mechanism and have never been
run by a human; the rest are regression checks against behaviour the example already had.

### The four commits a result should be reported against

A smoke result is only investigable if the four states it ran on are named. Quote these with any
finding, and **refresh them (`git -C <repo> rev-parse --short HEAD`) if the tree has moved before you
run** — a row that fails against a state nobody recorded costs a bisect.

| what | ref | commit |
|---|---|---|
| `keyboard`, the branch under test | `newinput` (local, unpushed) | **`e568961`** |
| `keyboard` upstream it is diffed against | `origin/dsent/dev` | **`025e858`** |
| platform repo running it | `feature/77-newapi-analysis-s20260615` | **`5128a4bf`** |
| platform edge upstream, for comparison | `dsent/dsent/dev` | **`9ed375d4`** |

*(Re-pinned 2026-08-12 after P-18-19/20 — the last three behavioural differences against upstream
closed, and the tidy batch. **At this head the gesture-parity diff against upstream is zero** across
108 fresh-press stimuli and 108 repeats. The platform id is this pin's parent; the pin commit changes
nothing but this table.)*

### How to launch

- **Desktop / nodejs:** from the repo root, `love src play src/examples/keyboard`.
- **Device:** the assembled `.apk`.
- **The exit rows (D9, G1) need the IDE, not play mode.** Under `love src play …` the console is
  disabled (`consoleController.lua`, the `cfg.mode == 'play'` branches), so `Ctrl+Esc` has nothing to
  return to and neither row can be *observed* — the code under test runs either way. Start the
  console with `love src`, launch the game from it (`run(<project>)`), and come back to it.
- The **menu** lists eight games in this order: **1** Press the key · **2** Find the key ·
  **3** Asteroids · **4** Alt characters · **5** Words & phrases · **6** Blow the bubble ·
  **7** Hide and seek · **8** Load the train. Press the digit to enter; `Shift+Esc` returns.
- A game's difficulty is `Ctrl+Alt+Up` / `Ctrl+Alt+Down` ("the notch"). **Alt characters** reaches
  its symbol and capital targets at the higher notches; **Words** adds capitals at rung 3 and
  punctuation at rung 4.

### A — the intro and the menu

| | do | expect |
|---|---|---|
| A1 | launch; while the intro is still typing, press a **letter** | the typewriter jumps to the end |
| A2 | relaunch; while it types, press **Alt alone** (nothing else) | **[new]** it keeps typing — Alt does *not* skip it |
| A3 | relaunch; while it types, press **Shift alone** | it *does* skip. Known asymmetry, deliberate: upstream behaves this way |
| A4 | from the menu press `4` to enter Alt characters; `Shift+Esc` back; press `5` to enter Words | **[new]** neither entry knocks — the first target of each is untouched, and Words' first word keeps its gauge unit. *(The digit used to be judged by the game it opened.)* |

### B — Alt characters (game 4): the main judging scene

| | do | expect |
|---|---|---|
| B1 | enter game 4, press the character shown above the board | accepted — sound, burst on that key, next target |
| B2 | **tap the target character as fast as you physically can** | **[new]** it registers. Every earlier version of this game dropped a fast tap |
| B3 | press and **hold** the correct key for ~2 seconds | exactly one hit; when you let go, the *next* target is untouched — no knock, no miss |
| B4 | press and **hold** a wrong key for ~2 seconds | one knock, not a stream of them |
| B5 | press the target, release, press it again immediately | both presses count as their own answer |
| B6 | raise the notch to reach a **symbol** target (`!`, `?`, `:`) and type it with Shift | **[new]** accepted; the burst lands on the *unshifted* key (`1`, `/`, `;`) |
| B7 | at a `backspace`, `tab` or `return` target, **hold Shift** then press the target | no knock from Shift; the target still matches |
| B8 | press `Ctrl+Alt+H`, then type the letter the hint points at | the hint re-arms and the letter registers |
| B9 | press `Ctrl+Alt+H`, then **release Ctrl and Alt while keeping H down** | **[new]** nothing happens: no knock, no miss, the target is not fumbled. *(This is the case the mechanism was rebuilt for.)* |
| B10 | press `Alt+Shift+`*any letter* | **[new]** ignored — no knock, no miss |
| B11 | **hold** `Ctrl+Alt+H` for ~2 seconds | **[new]** the hint re-arms **once** — one blip, one finger sweep from the start, not one per repeat frame |
| B12 | `Alt+P` to pause, press `Ctrl+Alt+H`, then `Alt+P` again | **[new]** the pause screen ignores it: no blip while paused |
| B13 | press `Ctrl+Alt+Shift+H` | **[new]** re-arms the hint exactly as `Ctrl+Alt+H` does. *(It stopped working during the migration and was restored — the sixth gesture of that family.)* |

### C — Words & phrases (game 5): the second judging scene

| | do | expect |
|---|---|---|
| C1 | enter game 5 and type the line shown, left to right | each correct character greens and advances; the gauge fills per finished word |
| C2 | find a line with a **doubled letter** (`all`, `been`, `little`) and type it | **[new]** *both* letters register. This was impossible under the design this replaced |
| C3 | type a **wrong** character | a knock; the cursor does **not** advance; the word loses its gauge unit; typing the right character continues normally |
| C4 | press and **hold** a wrong key for ~2 seconds | one knock per press, not one per frame |
| C5 | type `~` or `\|` (Shift + backtick, Shift + backslash) | **[new]** a knock and nothing else. **It must not crash** — this crashed the game before 2026-08-12 |
| C6 | raise the notch to rung 4 and type a line with `,` and `.` | both accepted |

### D — the reserved chords and the help overlay

| | do | expect |
|---|---|---|
| D1 | in any game, **hold** `Alt+H` | the help overlay appears and the game freezes behind it |
| D2 | release **H** first | the overlay disappears |
| D3 | hold `Alt+H`, then release **Alt** first, keeping H down | **[new]** the overlay disappears **and** no stray `h` is typed into the game — no knock, no miss |
| D4 | `Shift+Esc` | leaves the game for the menu |
| D5 | `Alt+Shift+Esc` | **[new]** also leaves. *(It stopped working during the migration and was restored.)* |
| D6 | `Ctrl+Alt+Up`, `Ctrl+Alt+Down` | the notch moves one step per press — **not** repeatedly while held |
| D7 | `Ctrl+Alt+Shift+Up` | **[new]** also moves the notch |
| D8 | in a timed game, `Alt+P`, then `Alt+P` again | pause on, pause off — once per press, and the pause survives a held key |
| D8b | in a timed game, `Alt+Shift+P`, then `Alt+Shift+P` again | **[new]** also pauses and resumes. *(It stopped working during the migration and was restored — the fifth gesture of that family.)* |
| D9 | `Ctrl+Esc` | quits the project back to the console (the framework's own chord). **Needs the IDE launch** — see "How to launch" |
| D10 | in game 1 or 6 (no `onHint`), press `Ctrl+Alt+H` | **[new]** nothing happens: no knock, no miss, no sound |

### E — Caps Lock and the decals

| | do | expect |
|---|---|---|
| E1 | in game 1 or 2, press `Caps Lock`, then type a letter | the **Caps** decal and the keycap case agree with what was typed |
| E2 | toggle `Caps Lock` while the window is **not** focused, then return and type a letter | the decal corrects itself on that letter |
| E3 | **hold** `Caps Lock` for ~2 seconds | **[new]** watch the decal. If it *flickers*, say so — it settles an open question and is not a regression |
| E4 | type capitals with Shift held, releasing Shift at various moments | the decal never contradicts the letters that appeared |

### F — the untouched scenes (regression only)

| | do | expect |
|---|---|---|
| F1 | game 6, hold the glowing key and release while the bubble's edge is inside the ring | success. Holding past the ring, or letting go early, pops it |
| F2 | games 1, 2, 3, 7, 8 — play each for a few seconds | nothing misbehaves; a modifier pressed alone never counts as a wrong key |

### G — on the way out

| | do | expect |
|---|---|---|
| G1 | leave the game with `Ctrl+Esc` and use the console (**IDE launch**, as D9) | **[new]** the pointer behaves as it did before the game was started — the project puts relative mode back in `compy.before_exit`. *(Stop paths only: if the project ever crashes to the error screen the mode stays set, which is known platform debt, not this fix's scope.)* |

### What a failure here means

- **A2, A4, B2, B6, B9, B10, B11, B12, B13, C2, C5, D3, D5, D7, D8b, D10, G1** are the new mechanism and its restorations. A failure is
  a defect in the 2026-08-12 work — report it against
  `wip/77-new-input-api/validation/reviews/P-18-00-triage-and-plan.md`.
- **E3** is a question, not a test: either answer closes it.
- Everything else is a regression check. A failure there means the migration changed behaviour it was
  not supposed to touch, which is the thing that ruling exists to prevent.

---

## maze (and draw)

**Repository:** `src/examples/maze` (separate remote, own PR). **Last mechanism change:** 2026-08-13
— the command editor moved onto the project input API, `Shift+Esc` became a registered combo, and
three pieces of remembered keyboard state were replaced by asking the keyboard. Plan and reasoning:
`wip/77-new-input-api/validation/reviews/P-17-04-triage-and-substeps.md`.

**This repo now ships TWO programs**, `maze` and `draw`, built from one source tree. Both share the
command editor, so **section C must be run in both**.

**Everything in this section is [new].** Nothing in this work has been run by a human, in either
program, at any commit — no level has been reached and no key pressed. The automated suite covers the
command *core* (42 assertions) and does not touch input at all, by ruling: this list is the only gate.

### The four commits a result should be reported against

Quote these with any finding, and refresh them (`git -C <repo> rev-parse --short HEAD`) if the tree
moved before you run.

| what | ref | commit |
|---|---|---|
| `maze`, the branch under test | `newinput-edge` (local, unpushed) | **`ca59903`** |
| `maze` upstream it is diffed against | `dsent/dsent/dev` | **`b8cc436`** |
| platform repo running it | `feature/77-newapi-analysis-s20260615` | **`5128a4bf`** |
| platform edge upstream, for comparison | `dsent/dsent/dev` | **`9ed375d4`** |

### How to launch — this changed, and the old command no longer works

The source root **is not a runnable project** any more: it emits `maze/` and `draw/` as separate
projects (`BUILD.md`). `love src play src/examples/maze` now fails with *"main.lua does not exist"*.

```sh
cd src/examples/maze && ./.compy/build /abs/path/out
cd <repo root> && love src play /abs/path/out/maze     # and .../draw
```

- **The exit row (E1) needs the IDE, not play mode** — under `play` the console is disabled, so
  `Ctrl+Esc` has nothing to return to. Start with `love src`, open the project from the console.
- **maze's menu** offers three tracks: **1** Drive the robot (direct keys) · **2** Plan a path (tile
  buffer) · **3** All mazes (the sandbox, which is where the **command editor** levels are).
- **draw's menu** offers Free draw and the picture tasks. **Free draw keeps its command field open
  the whole time**, which is what makes section C and row B1 matter there.

### A — the command editor (run in **maze track 3** and in **draw**)

| | do | expect |
|---|---|---|
| A1 | enter an editor level | the command field is open, **empty**, prompting `Commands:` |
| A2 | type a valid program and press Enter | it runs; the robot moves |
| A3 | after that run ends without winning | the prompt returns **once**, with the program still in the field to edit |
| A4 | type an invalid command (e.g. `FFX`) and Enter | the **error message replaces the prompt** and the typed text stays for correction |
| A5 | correct it and Enter | it runs; the prompt goes back to `Commands:` |
| A6 | in maze: crash into a wall, then press Tab | the robot goes home and the **kept program** is back in the field |
| A7 | type a long command, watching each character | each character appears **once** — the game now also sees every keystroke, and should do nothing with it |

### B — Shift+Esc, the gesture this work adds

| | do | expect |
|---|---|---|
| B1 | on an **editor level with the field active**, press `Shift+Esc` | you return to the menu. **This is the new capability** — it previously could not reach the program at all |
| B2 | look at the screen after B1 | **no command field is left over the menu** |
| B3 | immediately press a menu digit | the track starts, and **the digit does not also land in a field** |
| B4 | on a **direct-control** level, press `Shift+Esc` | returns to the menu, as before |
| B5 | at the menu, press `Shift+Esc` | **nothing happens** — the menu is the top level; `Ctrl+Esc` is how you leave to the console |
| B6 | type a draft, then `Shift+Esc` | you leave — the draft is not silently wiped *and then* the game left, which is what one keystroke doing both would look like |
| B7 | in **draw**, `<` typed as a command | still exits to the draw menu. **It was deliberately kept** |
| B8 | on an editor level, `Alt+Shift+Esc` | **[new]** also leaves for the menu |
| B9 | on an editor level, `Ctrl+Shift+Esc` | **[new]** also leaves — and the run is **not** stopped back to the console behind it |
| B10 | on an editor level, `Ctrl+Alt+Shift+Esc` | **[new]** same as B9 |

**B8–B10 have never been pressed by anyone.** The game registers all four
members of the family, but two of them — the Ctrl-bearing ones — used to reach
the platform's gate first, which read them as `Ctrl+Esc` and tore the project
down on the release. That is what Decision 33 changed (a reservation now matches
its modifiers exactly), and `da9d1c2` restored the family on the maze side. The
two halves have never been exercised together on a device.

### C — the menu digit and its echo (run in **maze**, entering track 3)

| | do | expect |
|---|---|---|
| C1 | from the menu press `3` to enter the sandbox | the command field opens **empty** — no stray `3` in it |

*(If a `3` appears, the fix is the documented one-shot `textinput` guard, and the row becomes a
defect against `P-17-03` §5, not a mystery.)*

### D — the keyboard state that stopped being remembered

| | do | expect |
|---|---|---|
| D1 | on a **direct-control** level, hold `Shift` | the screen dims — "you are about to name a macro" |
| D2 | still holding `Shift`, press a letter, then release `Shift` | a macro is recorded under that letter, as before |
| D3 | hold `Shift`, then **click away to another window and back**, then press a letter | the letter **runs as a command** and the screen is **not** stuck dim. *(Before this work the lost release wedged it: every key started a recording and the dim never cleared until restart.)* |
| D4 | hold **both** Shift keys, release one, press a letter | it names a macro. **Stated widening**: this used to run as a command |
| D5 | on a **Track 2 (plan)** level, hold a direction key | **one** tile is appended, not a run of them |
| D6 | on a **direct-control** level, hold a direction key | the robot queues a **run** of moves — unchanged, this one is supposed to repeat |
| D7 | on a plan level, hold a direction, click away and back, press it again | it still works. *(A lost release used to kill that direction for the session.)* |

### E — Tab, and on the way out

| | do | expect |
|---|---|---|
| E1 | leave with `Ctrl+Esc` (**IDE launch**) | you are back in the console |
| E2 | win a level, press `Tab` | the next level starts |
| E3 | **hold** `Tab` | the level advances **once**, not repeatedly |
| E4 | press `Shift+Tab`, then `Ctrl+Tab` | each still advances/resets as a bare Tab does — these were preserved deliberately, one registration each |
| E5 | on an **editor level**, press `Tab` | the level acts **and** a tab reaches the field, as it did before. *(Odd, pre-existing, deliberately not changed.)* |
| E6 | in **draw**, complete a picture and press `Tab` | the next picture starts |

### What a failure here means

- **A1–A5, B1–B3, D3–D5, D7, E3** are the new mechanisms. A failure is a defect in the 2026-08-13
  work — report it against `wip/77-new-input-api/validation/reviews/P-17-04-triage-and-substeps.md`.
- **D4** is a **stated behaviour change**, not a bug: confirm it reads acceptably rather than whether
  it differs.
- **E5** and **B7** are deliberate preservations. A failure there means the migration changed
  something it promised not to.
- Everything else is a regression check against behaviour the example already had.
