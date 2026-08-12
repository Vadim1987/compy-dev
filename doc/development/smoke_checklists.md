# Manual smoke checklists

Checklists a **human** runs, for the parts of this project no automated suite can reach: the nested
example repos have no tests, and nothing in CI can press a key. Each list is written to be run
top-to-bottom in one sitting, with the expected result stated so a failure is unambiguous.

**Referenced from:** `doc/development/tests.md` (what is and is not covered),
`wip/77-new-input-api/validation/plan.md` Phase G (the PR's own gate) and its §16.3 (each detached
example repo's PR gate is a human smoke pass), and the step that last changed the code.

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
| `keyboard`, the branch under test | `newinput` (local, unpushed) | **`1033252`** |
| `keyboard` upstream it is diffed against | `origin/dsent/dev` | **`025e858`** |
| platform repo running it | `feature/77-newapi-analysis-s20260615` | **`a05a3829`** |
| platform edge upstream, for comparison | `dsent/dsent/dev` | **`9ed375d4`** |

*(Re-pinned 2026-08-12 after P-18-14 … P-18-17 — the sixth restored gesture, the polls adopting
`Key.any_pressed`, the comments the first sweep missed, and the docs. The platform id is this pin's
parent; the pin commit changes nothing but this table. The same range is what the third cold review
reads.)*

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
