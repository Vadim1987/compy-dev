# P-23-00b — pen-and-paper projects, and the canvas/error boundary

Owner, 2026-08-16: before moving Ctrl+S, analyse how it affects projects that
are *technically never running*, and the canvas / error-catching tradeoffs.
Precedes P-23-01. (The feasibility pass is P-23-00a, committed as P-23-00.)

**Two findings, one of which changes the shape of P-23-01.**

---

## 1. Pen-and-paper projects — the scope is load-bearing, not a detail

A pen-and-paper project has no `update` and no `draw`. Its top-level code runs,
finishes, and `user_is_blocking()` is false, so `run_project` sets
`app_state = 'project_open'` and **deliberately keeps the route**
(`consoleController.lua:326-338`; Decision 11). It is alive — its widget and
pointer handlers still receive events — but it is never in `running` again.

**What Ctrl+S does for such a project today:** nothing at the framework level.
The gate's `k == "s"` block acts on `running` and `editor` only, so in
`project_open` the key falls straight through to the route — where the project's
own `ctrl+s` shortcut fires if it has one.

That is worth stating plainly, because it is the pre-existing rule the move must
preserve: **Ctrl+S is the framework's while a project runs, and the project's
once it is open.** The way out of a pen-and-paper project is Ctrl+Escape, via
the release gate (`controller.lua:895-899` → `love.quit` → `stop_project_run`
when `user_is_interactive`), which this step does not touch.

**The risk this creates for P-23-01.** The obvious implementation — "PIC owns
the keyboard, so put the reservation check at the top of the walk" — would apply
it in `project_open` too, because PIC owns the route in *both* states. That
would **take `ctrl+s` away from every pen-and-paper project** and stop them on a
key that currently belongs to them. Silent, and exactly the class of regression
this whole sprint has been finding. The `app_state == 'running'` scope is
therefore not a detail carried over from the gate — it is the thing that keeps
this class of project working.

**Where the scope should live** — three options, because "PIC reads
`love.state.app_state`" is not free:

- **(a) PIC reads the state.** One line, and it works. Cost: PIC is currently a
  pure walker over tables with no knowledge of app lifecycle; this gives it
  some.
- **(b) The lifecycle tells PIC.** `occupy_input` installs the run's
  reservations; the transition to `project_open` (`consoleController.lua:324,
  337`) narrows them. No state reads in the dispatcher, and "what the platform
  claims right now" becomes inspectable — the shape Decision 30 point 3
  gestures at without committing to. Cost: two more call sites, and a table
  whose lifetime must match the route's.
- **(c) Leave the scope in the gate and only the *action* moves.** Rejected:
  it keeps the thing the owner is removing.

**Recommendation: (a) for this step, with (b) named as the shape if a second
reservation ever moves.** One state read is honest and reviewable; building the
table for a single entry is the more elaborate answer, not the more predictable
one.

---

## 2. The canvas/error boundary — this one argues against the obvious shape

Today the gate runs **outside** `with_canvas_and_errors`. Moving the *action*
into PIC runs it **inside**. Three consequences, in descending severity.

**(a) Errors would be routed to the project's error handler — and that handler
suspends the run.** `with_canvas_and_errors` → `wrap` → `on_error` →
`user_error_handler` → **`CC:suspend_run(user_msg)`**
(`controller.lua:100-126`). So if anything in `stop_project_run` raised while
running inside the boundary, the framework would respond by *suspending the run
it was in the middle of tearing down*, and report it to the user as a project
error. The user pressed the escape hatch, and the outcome is a half-torn-down
suspended state with someone else's name on the failure. Today the same raise
propagates out of `handlers.keypressed` and is visible as what it is.

This is not hypothetical severity: **the entire purpose of this reservation is
recovery**, and recovery paths are exactly where swallowing an error is
unaffordable.

**(b) `use_canvas` does not nest.** It binds, calls, then unbinds
unconditionally (`consoleController.lua:1641-1650`) — no save/restore. Nothing
in `stop_project_run`'s chain calls it today (the only three call sites are
`run_user_code`, `with_canvas_and_errors`, and the user-update hook), so this is
latent rather than live. But running teardown inside the boundary makes it a
hazard the next person can trip: add one `use_canvas` inside teardown and the
outer binding silently disappears mid-way.

**(c) Teardown would run with the project's canvas bound** while it re-points
`love.draw` to the console's. Benign as the code stands — nothing in the chain
draws — but it means teardown executes in a graphics context that belongs to the
thing being destroyed.

**What is *not* a problem:** the project's own `before_exit` hook is already
`pcall`ed separately inside `framework_before_exit`
(`consoleController.lua:168-178`), so its error handling is unaffected either
way.

### The shape this argues for

**Decide inside the controller; act outside the boundary.**
`ProjectInputController` detects the platform reservation and consumes the event
— which is exactly what the owner asked for, since the decision is what belongs
to the controller — but it does not itself run the teardown. It reports that a
platform action is due, and the gateway performs it after `love.keypressed(...)`
returns, i.e. where the teardown runs today, outside the canvas and outside the
project's error handler.

The cost is one channel for "the route asked for a platform action". That is
genuinely more machinery than calling `stop_project_run` in place, and it should
be judged as such — but the alternative pays for its simplicity in the one path
that must not fail quietly.

If the owner prefers the direct call anyway, the step owes a test that a raise
inside `stop_project_run` does **not** become a suspended run, and the tradeoff
belongs in the debt register rather than only in a commit message.

---

## What P-23-01 should carry out of this

1. Scope to `app_state == 'running'`, with the pen-and-paper case as a **live
   test**: a project with no update/draw, in `project_open`, binding `ctrl+s`,
   fires its own binding and is not stopped.
2. Decide in PIC, act outside the boundary — or take the direct call knowingly,
   with the error-path test and a debt entry.
3. Leave Ctrl+Escape alone; it is the pen-and-paper exit and nothing here
   touches it.
