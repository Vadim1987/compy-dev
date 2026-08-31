# Owner proposal — one shared dispatcher, `love.<event>` as the hook slot

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

**Session:** 62 · **Date:** 2026-08-31 · **Status:** proposal under discussion, nothing ruled.
Successor of the environment-lifecycle thread
([`owner-inquiry-console-env-lifecycle.md`](owner-inquiry-console-env-lifecycle.md),
[`../reviews/env-lifecycle-inquiry-assessment.md`](../reviews/env-lifecycle-inquiry-assessment.md)).
**Nothing in the persistent corpus is touched by this note.**

## The proposal

If `dofile('main.lua')` must equal typing the file at the console, the `run()` entry point stops
being the thing that switches dispatching. So: **the console performs the same shared dispatch**,
and the chain queries **`love.<event>`** instead of `compy.input.hooks[event]` — which eliminates
`ProjectInputController`, since `ConsoleController` would do the same walk over shared
shortcuts/callbacks tables, and PIC does nothing more.

## Verification — is "PIC does nothing more" true?

Substantially yes (`src/controller/projectInputController.lua`, 200 lines). It holds: `EVENTS` /
`TRIGGER`; `find_shortcut` (exact combo, then modifier class — Decision 21, plus the guards that
keep a modifier from naming a shortcut and stop an unmodified `mousemoved` allocating a combo
string); the three-consumer `dispatch`; `seed_hooks`; `activate`/`deactivate`; and the generated
per-event channel methods.

**The file already anticipates the move.** `dispatch` is deliberately written as a free function
over plain tables plus a widget reference — *"so any adopter (not only the project widget) can reuse
it over its own instance"* (`:118-130`). Reuse by another controller is stated design intent, not a
retrofit.

**What disappears** under "query `love.<event>`": `seed_hooks` and with it Decision 10's seeding
step (hooks exist precisely to hold a copy of the project's `love.*` handlers); `activate` /
`deactivate` membership state, if one dispatcher is always on reading live tables; and the `hooks`
table itself as a public surface.

**What does not move for free:** `with_canvas_and_errors` in `occupy_input`
(`controller.lua:228-243`) — the error boundary *and* the **project canvas** binding, applied at the
route boundary because "route IS the boundary". A unified dispatcher must rule on which canvas is
bound for a handler that a console-typed line installed.

## The mechanism that makes it work

The dispatcher cannot both occupy `love.<event>` and read it as the user slot. The existing
two-layer wiring already resolves this: put the shared walk in **Layer 1**
(`love.handlers[event]`, the fixed pump installed once at boot) and leave **`love.<event>` as the
user slot** — which is stock LÖVE's own shape and what
[`internals/event_dispatch_layers.md`](../../../internals/event_dispatch_layers.md) describes.
Reserved combos already run there, ahead of everything.

## Three sub-decisions this forces

1. **Containment — the largest.** `occupy_input` today installs *even with no project handlers*, on
   purpose: *"an unhandled event must stop in the project route, never reach the hidden console"*
   (`controller.lua:224-227`). With one always-on chain that includes the console line, an
   unconsumed key **falls through to a REPL that is hidden during a run** — WASD would type into an
   invisible console. So the mode boundary **cannot be dissolved, only relocated**: it comes back as
   a *chain-membership* rule (while a program runs, the console line is not a participant). Worth
   stating plainly, because the proposal reads as "the boundary goes away" and it does not.
2. **Focus between two widgets.** The console's REPL line is itself a `UserInputController`
   constructed `:always_shown()` (`consoleController.lua:44`); the project widget is another
   instance of the same class. A chain has one terminal consumer, so exactly one must be focused.
   This is question 6 of the owner's seven, now unavoidable and central.
3. **Return-value semantics.** A hook consumes by returning truthy; stock LÖVE ignores handler
   returns. Making `love.<event>` the hook gives a standard name a new meaning. And pointer
   handlers currently **discard** returns (`hook_pointer`) — the asymmetry recorded in
   `technical_debt/input.md` (*"Pointer delivery is an unstructured broadcast, not a chain"*).
   Unification is the moment to settle it, or the moment it becomes glaring.

## Consequence for the shipped feature

This is the **first proposal in this thread that supersedes a shipped `#77` surface**: it retires
`compy.input.hooks` (documented in `doc/input_api.md`, ratified as Decision 10) and deletes a
component. It is a *successor direction*, not a defect — but it is breaking, and the `serial` surface
is a live consumer.

A reviewer will ask why the feature moved projects **off** `love.*` onto hooks and would now move
them back. The answer is available and should be written down when the time comes: hooks existed to
give the project a slot the **route** could own; once one shared chain is owned by the console, the
slot can be `love.<event>` again, and shortcuts, widget, callbacks and `auto_hide` all stay.

Recommendation: record it as a successor direction in the ledgers **after** the merge. Speculation
does not belong in the PR description.

## The three primitives (owner, 2026-08-31) — and what already exists

The owner's decomposition: **(1)** env shared between console and project, so declarations outlive
the program; **(2)** a function that restores the default `love` callbacks and dispatch state
(keyboard, mouse, default shortcuts) while leaving the general env modified — *disarm*, implicitly
called at the end of a run; **(3)** a function that clears the console back to a factory env,
forgetting declarations but **preserving history**.

**(2) already exists — it just has no name and no front door.** It is spread across three functions
and welded into `stop_project_run`:

- `release_keyboard_route` (`controller.lua:725-738`) — deactivates the route, re-points the
  keyboard/text channels at the console, empties the derived click slots;
- `set_default_handlers` (`:741+`) — the full restore of every `love.<event>` to the console;
- `clear_user_handlers` (`:1070-1084`) — empties `_userhandlers` and calls `reset_compy_input(CC)`
  (`:319`), which wipes the surface's `shortcuts` and `hooks`.

**(3) is close to `_reset_executor_env`** (`consoleController.lua:1277-1278`), but today's
`ConsoleController:reset()` **clears the input history** (`self.input:reset(true)`) — the opposite
of what is asked — so (3) is a new function, not the existing one.

### Two corrections to "the only difference is error handling + auto-disarm"

- **`run()` must also call (3) at the *start*.** That is R2 — a run begins from a well-defined
  default. Dropping it drops R2. So: **`run(p) ≡ (3); open(p); dofile('main.lua')`**, with the stop
  path implicitly calling (2).
- **Error handling should not be a difference either.** If handlers are wrapped by the *install*
  path rather than by the verb, a console-installed handler is wrapped exactly like a project's. The
  difference then reduces to **(3) at the start — one line**, which is a stronger claim than the
  original.

### A fourth concern the list implies but does not name

There is a *disarm* and no *arm*: arming is just assigning `love.<event>`. The consequence is that
**"running" becomes a derived predicate rather than a mode you enter** — and the codebase already
works this way in miniature: `user_is_blocking()` = `user_update or user_draw`, and
`user_is_interactive()` = `love.state.user_input ~= nil or user_pointer` (`controller.lua:1038-1046`).
`app_state` must be derived from what is installed, or the result is today's bug where the framework
believes nothing is running while a `dofile`'d program owns the screen.

### Two traps in (3)

- **What "factory" contains.** `pre_env` is cloned at `consoleController.lua:41`, *before*
  `prepare_env` adds the console's own verbs. In a merged env, "factory" must include `run`,
  `dofile`, `project`, `edit`, `quit`… or (3) leaves the user with no way to type `run`.
- **(3) must be reachable when the env is wrecked.** With one shared env it is the only thing
  between "a project broke my console" and restarting the app, so it needs a reserved key.
  `Ctrl+Shift+R` is already exactly that (`reserved_reset`) — it must keep working, and it should
  finally be documented.

### Is the input API fully rewirable onto this? Yes

`#77` put project-owned interaction state in exactly **two** places, and (2) reaches both: the
surface's own tables (`reset_compy_input` already wipes `shortcuts` and `hooks`) and the widget
(Decision 11 already says re-seed the callbacks, never nil them). What survives unchanged:
`shortcuts`, the widget methods, `callbacks`, `auto_hide`, `is_shown()`, the reserved combos and
Decision 33's narrow reservations. One retirement: `hooks`. One addition: (2) as a named,
idempotent front door — safe to call when nothing is armed, which today's `stop_project_run` is not
(it has no state guard and sets `app_state = 'project_open'` unconditionally).

## Scope

Two tickets, not one — coupled but separable, and neither belongs to `#77`:

- **Environment lifecycle** (the original inquiry).
- **Input convergence** — which is *Decision 1's convergence, executed*: already on the books as
  `technical_debt/input.md`, "Decision 1 — console/editor convergence onto the shared chain is
  unimplemented", **BACKLOG**, deferred by the ruling that created it.

Either could ship without the other; the env merge is what makes one dispatcher *natural*, not what
makes it possible.
