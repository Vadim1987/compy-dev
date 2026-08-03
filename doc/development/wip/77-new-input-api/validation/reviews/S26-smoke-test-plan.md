# Smoke test plan — what a human has to check

Nothing below can be checked by `busted`: every item either reaches the screen
or needs a real input device. The suite covers the rest (923 rows, green).

**Launch:** `love src` from the repo root. (`xvfb-run love src` is the headless
form used for CI-ish checks — no good here, you need to see it.)

**Console commands you will need:**

| command | effect |
|---|---|
| `list_projects()` | what is available |
| `run('name')` | run a project |
| `project('name')` | open without running |
| `Ctrl+Esc` | stop the project, back to console |
| `Ctrl+Q` | quit the project |
| `Ctrl+T` | quickswitch project ↔ editor |
| `Ctrl+Pause` | break into the running project (inspect) |

**If something is wrong,** the useful report is: which item, what you did, what
you saw, and whether the console showed anything. A screenshot of a wrong frame
is worth more than a description.

---

## A. Highest risk — changed under you this session, never seen running

### A1. Clicks still work in `paint`

`run('paint')`. Click a palette colour, then draw on the canvas. Right-click a
palette colour and draw again.

- **Expect:** left click selects the primary colour and paints with it; right
  click sets the background colour and paints with that. Drawing follows a held
  drag.
- **Why it is here:** `compy.singleclick` no longer exists. paint now binds
  `compy.input.hooks.singleclick` / `.doubleclick`. If the migration is wrong,
  clicks do nothing at all — which is the *likely* failure, not a subtle one.

### A2. Clicks still work in `sapper`

`run('sapper')`. Single-click a cell to flag it. Double-click a cell to open
it. Shift-click and Ctrl-click a cell.

- **Expect:** single = flag, double = open, and the modifier variants do what
  they always did. After a game over, double-click restarts.
- **Why:** same migration, and sapper is the pen-and-paper case — no `love.draw`
  of its own, so it also exercises A5 below.

### A3. A wheel scroll does not break anything

In any running project, scroll the wheel.

- **Expect:** nothing happens. No crash, no error window.
- **Why:** compy now declares its own `wheelmoved` gateway entry where it
  previously borrowed LÖVE's. No project consumes wheel, so "nothing happens"
  is the correct outcome — the test is that it is *silently* nothing.

### A4. An error in a project now shows up

Easiest from the console: `run('turtle')`, then in the overlay type something
that makes the project raise — or edit an example to `error('boom')` inside its
`love.update`.

- **Expect:** the error window over the project's last frame, with the message.
- **Why:** raises inside `love.update` and inside pointer handlers used to
  **vanish silently** — the handler ran, the error disappeared, the project kept
  going. This is a real fix and its whole point is being visible.

### A5. A pen-and-paper project stays alive after its code returns

`run('sapper')` (or `guess`). Let it finish loading, then keep clicking / typing.

- **Expect:** it stays interactive. `Ctrl+Esc` returns to the console.
- **Why:** the project route is no longer released when a non-blocking project's
  `main.lua` returns. This is the behaviour change with the widest blast radius.
  **Watch for the opposite failure too:** the console must NOT be usable while
  the project is still open — keystrokes should go to the project, not the
  console line.

### A6. The console comes back cleanly

From any running project, `Ctrl+Esc`. Then type at the console and run something
else.

- **Expect:** the console prompt takes keystrokes immediately; a second `run(...)`
  works and its overlay comes up with its own text.
- **Why:** teardown now clears more than it used to — hooks for every channel,
  the derived clicks, `compy.before_exit`. If teardown over-clears or
  under-clears, this is where it shows.

---

## B. Carried from the previous session, never smoke-tested

### B1. The overlay is painted at all

`run('guess')` or `run('turtle')` and press `i`.

- **Expect:** the input line is visible, with its prompt.
- **Why:** an overlay that was never painted was fixed but never seen.

### B2. `turtle`'s echo guard

`run('turtle')`, press `i` to open the prompt.

- **Expect:** the prompt opens **empty** — no stray `i` in it.
- **Why:** the key that opens an overlay used to land in it as text.

### B3. `maze` prompts only while idle

`run('maze')`. Enter a movement command, watch the move play out.

- **Expect:** the prompt disappears while the player moves and returns, empty,
  once the move lands. It should not sit there mid-move.

### B4. `balloons` runs a typed command

`run('balloons')`. Type a game command and press Enter.

- **Expect:** the command *runs*. Previously every command silently re-prompted.

### B5. `keyboard` — the largest untested migration

`run('keyboard')`. Exercise: the reserved chords, an `Alt+<key>` chord, held
keys (does a held key repeat where it should?), and `Ctrl+Esc` to leave.

- **Expect:** as before the migration. This project hand-rolled four things the
  framework now provides, so it is the acceptance case for the whole API.
- **Note:** `keyboard`, `maze` and `balloons` are separate repos under
  `src/examples/`; each opens its own PR.

---

## C. Cheap confirmations, if you have the patience

### C1. A bare `*` shortcut raises

In a project, or at the console against a project env:
`compy.input.shortcuts.keypressed['*'] = function() end`

- **Expect:** an error naming the alternative — "a class needs modifiers to be a
  class of… for every key, use compy.input.hooks".

### C2. A modifier class still works

`compy.input.shortcuts.keypressed['alt+*'] = function() return true end`, then
press some Alt chords.

- **Expect:** registers fine, and swallows the whole Alt class.

### C3. Break into a running project

`run` something with a draw loop (`pong`, `clock`), then `Ctrl+Pause`.

- **Expect:** the project freezes on its last frame; the console REPL is live
  and bound to the *paused project's* environment, so reading its globals works.
  A project overlay, if one was up, is not painted and not typed into.

---

## What I would look at first

If time is short: **A1, A2, A5, B5**. A1/A2 are the migration that would fail
loudly, A5 is the widest behaviour change, and B5 is the biggest body of code
nobody has run since it changed.
