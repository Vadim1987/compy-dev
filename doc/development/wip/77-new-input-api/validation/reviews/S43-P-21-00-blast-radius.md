# P-21-00 — Decision 33: blast radius, regressions, and the implementation steps

Owner ruled option A on 2026-08-16 and asked for **all** framework cases, with the
reasoning recorded as a decision — done: `doc/development/decisions/input.md`,
**Decision 33 — a framework reservation matches its modifier set exactly**.

This step evaluates what tightening actually touches, before anything is edited.
**No code changed by this step.**

## The reservations, and what each becomes

All in `src/controller/controller.lua`. "Extensions lost" = chords the reservation
claims today and would stop claiming.

| # | Reservation | Today | Exact form | Extensions lost |
|---|---|---|---|---|
| 1 | quickswitch | `Key.ctrl() and not Key.alt() and k == 't'` (`:769`) | add `not Key.shift()` | Ctrl+Shift+T |
| 2 | suspend | `Key.ctrl()` + `k == 'pause'` (`:791,792`) | + `not alt, not shift` | Ctrl+Alt+Pause, Ctrl+Shift+Pause, Ctrl+Alt+Shift+Pause |
| 3 | quit project | `Key.ctrl()` + `k == 'q'` (`:795`) | + `not alt, not shift` | Ctrl+Shift+Q, Ctrl+Alt+Q, Ctrl+Alt+Shift+Q |
| 4 | stop run / close buffer | `Key.ctrl()` + `k == 's'` (`:798`) | + `not alt`; **shift stays meaningful** | Ctrl+Alt+S, Ctrl+Alt+Shift+S |
| 4b | finish edit | `…and Key.shift()` in the editor branch (`:802`) | + `not alt` | as above |
| 5 | reset | `Key.ctrl() and Key.shift()` + `k == 'r'` (`:791,809,811`) | + `not alt` | Ctrl+Alt+Shift+R |
| 6 | restart | `Key.ctrl() and Key.alt() and k == 'r'` (`:818`) | + `not shift` | Ctrl+Alt+Shift+R |
| 7 | profiler | `Key.ctrl() and Key.alt() and k == 'p'`, shift selects start/stop (`:823-828`) | **already exact** — the three modifiers are all named | none |
| 8 | FPS overlay | `k == 'f10'`, no modifier test at all (`:831`) | no modifier held | F10 with any modifier |
| 9 | quit / back to console | `Key.ctrl()` + `k == 'escape'`, **on release** (`:884-885`) | + `not alt, not shift` | Ctrl+Shift+Escape, Ctrl+Alt+Escape, Ctrl+Alt+Shift+Escape |

**Rows 5 and 6 are the defect**, not merely looseness: Ctrl+Alt+Shift+R satisfies both
and fires `restart` **and** `reset` in one event (`../notes/S43-ctrl-alt-shift-r-probe.lua`).
Exactness fixes it as a side effect; nothing else needs to.

**Row 7 needs no change** — worth stating so the sweep does not "fix" it.

**Out of scope by Decision 33's own scope clause:** the console debug hotkeys at
`:493` (Ctrl+Shift+digit) and `:510` (Ctrl+Alt+D). They sit in `set_love_keypressed`,
which is route-level, not the pre-dispatch gate — they compete with no project, and they
already carry a debt entry for migration onto combos. **Flagged for the owner: if "all
framework cases" was meant to include these, say so and they become a fourth substep.**

## Regressions — what could break

- **The suite: nothing visible.** Every existing test drives these gates with **exact**
  combos — `C-pause` (`input_shortcuts_click_spec.lua:47`), `C-M-r` and `C-q` (`:79-80`).
  No test asserts the tolerant behaviour, so no test should need rewriting. That is a
  prediction, and the sweep proves it by running green.
- **Projects and examples: only maze/draw, and in their favour.** The only registrations
  in the tree that extend a reserved combo are maze's and draw's two Ctrl variants, which
  today are overridden and would start working. Their risk note becomes removable.
- **Harmony: unaffected.** `shortcuts.toggle = 'C-t'` sends Ctrl+T with no other modifier.
  (Harmony is separately broken by P13 and is being reverted under P-13-01.)
- **The real behavioural risk is muscle memory**, not code: anyone in the habit of
  Ctrl+Shift+Escape or Ctrl+Shift+T to get out of a run will find it no longer works,
  because it will belong to the project. Plain Ctrl+Escape and Ctrl+T are untouched, so
  the recovery path is never lost — but the change is user-visible and belongs in the PR
  description's justification line.
- **Play-mode asymmetry to keep in mind while editing:** in `play` mode the same quit
  path exits the app rather than dropping to the console (`:653-684`), so row 9's
  behaviour differs by mode. Exactness applies identically; only the consequence differs.

## Shape of the edit

Nine conditions across two handlers, each gaining one or two `not Key.*()` terms. The
repetition is the design question:

- **A local predicate in `controller.lua`** — e.g. `only(ctrl, alt, shift)` returning
  whether exactly that set is held — reads better than nine hand-written exclusions and
  keeps the fold in one place. It is also one more name in a file the feature already
  restructured for size.
- **Hand-written exclusions** match the idiom already at `:769` and add no vocabulary.

Recommendation: **the predicate**, because nine sites is exactly where the hand-written
form starts to drift, and drift here is silent — a missing `not` looks like the code
being right. Its name should say "exactly these", not "no others".

## Proposed substeps

| Step | Content | Gate |
|---|---|---|
| **P-21-01** | The predicate + **row 9** (the release gate) — the case that motivated the decision | breaking test first; suite green |
| **P-21-02** | Rows 1–6 and 8, the `keypressed` gate, one commit | includes a live case for the Ctrl+Alt+Shift+R double-fire, which is a defect fix and states so in its message |
| **P-21-03** | Remove maze/draw's risk note and confirm the four-variant family end to end; the note's own removal condition is now met | nested repo commit, never pushed |
| **P-21-04** | Docs: the reserved-combo section owed by P10 states what a reservation claims; the debt entry "The gate reserves tolerantly…" is closed and points at Decision 33; PR justification line drafted | last, after behaviour settles |

Sequenced, not parallel: 01 and 02 touch the same handler block.

**Correction to an earlier draft of this step (S43, before execution):** it proposed
converting the `ctrl+escape` **pending** outline
(`tests/input/input_global_shortcuts_spec.lua:95`) into a live case. That is wrong and
would breach P15's ruling — those seven pendings name *each reserved combo's own effect*,
which is the framework's contract and explicitly **not** this PR's duty, and the count of
10 is an owner ruling the boot ritual checks. What Decision 33 makes ours is the
**boundary**, not the effect: that a reservation does **not** claim an extension of
itself. So the new cases are **additive and live**, the pendings stay untouched, and the
pending count stays **10**.

## What this step did not decide

Whether the console/editor route handlers (`:493`, `:510`, and the `Key.*` tests
throughout `editorController.lua`) should be exact too. Decision 33 explicitly leaves it
open. It is a larger surface, it has no non-overridable power to justify least-privilege,
and folding it in would grow this PR well past its mandate.
