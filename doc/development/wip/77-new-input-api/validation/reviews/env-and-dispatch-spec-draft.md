# Console, projects and interaction — a high-level specification

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

**Status:** DRAFT for the owner and the project owner. Nothing here is ratified, and nothing in the
persistent documentation has been changed. **Scope:** the shape of the transformation, not its
implementation. **Origin:** the project owner's inquiry of 2026-08-31 and the discussion that
followed — [`../notes/owner-inquiry-console-env-lifecycle.md`](../notes/owner-inquiry-console-env-lifecycle.md),
[`env-lifecycle-inquiry-assessment.md`](env-lifecycle-inquiry-assessment.md),
[`../notes/unified-dispatch-proposal.md`](../notes/unified-dispatch-proposal.md).

---

## 1. The problem

The relationship between the console's environment and a running program is unspecified, and the
behaviour that fills the gap is inconsistent:

- A project's globals live in a private copy of the console's environment, so the console cannot see
  them after the program stops — but the *copy* is refreshed only when a project is closed, so
  running the same project twice is not a clean start.
- `dofile` is not a project operation at all. It reads a file from the open project and evaluates it
  in the console's environment, with no policy about what the file is allowed to take over.
- The console itself is **not** sandboxed. A single typed line can take the screen or the keyboard,
  the framework's own bookkeeping is not updated when it happens, and the only way back is an
  undocumented key.
- Whether a typed line takes effect at all depends on which state the application is in — in one
  state it is silently stored and fires at the *next* run.

The complaint is therefore as much *"not properly specified"* as *"wrong"*. The deliverable is a
model small enough to state in a paragraph, plus the changes that make it true.

## 2. The model

> **There is one environment.** The console and any program a user runs share it. Symbols a program
> defines stay visible to the console afterwards; the console's symbols are visible to a program.
>
> **A program is not a mode you enter — it is a set of claims on interaction.** A file that assigns
> nothing to the interaction surface is just declarations, and the console carries on. A file that
> claims the keyboard, the mouse or the frame becomes the interactive occupant, and the application
> knows it because the claims were made, not because a particular verb was typed.
>
> **Three operations**, and every user-facing verb is expressed in them:
>
> 1. **Load** — evaluate a file in the shared environment. Its definitions persist. Its claims on
>    interaction, if any, take effect through the framework's own installation path.
> 2. **Disarm** — restore the default interaction: the framework's callbacks, the console's own
>    input, no leftover shortcuts or hooks. **The general environment is untouched** — definitions
>    and data survive. This is what ends a program.
> 3. **Factory reset** — return the environment to its defined default, forgetting everything the
>    session accumulated. Input history is preserved.
>
> `dofile(f)` = **load**. `run(p)` = **factory reset**, then open, then load `main.lua`. Stopping a
> program = **disarm**.

That is the whole model. Everything below either enables it or protects it.

## 3. What the model requires

### 3.1 Interaction is claimed by ordinary assignment; the framework normalizes and can restore

**The engine's callback slots stay writable.** A program — or a typed line — claims interaction the
way any LÖVE program does: by assigning `love.keypressed`, `love.draw`, `love.update` and their
siblings. There is no interception and no shadowed view of the engine table. *(An earlier draft of
this section proposed a guard; the owner ruled against it, 2026-08-31.)*

Two things make that safe enough:

- **One slot is off-limits, by contract: the raw event table (`love.handlers`).** It is the fixed
  pump that runs before anything is forwarded to a callback, and it is where the reserved keys live
  — quit, stop, restart, reset. Leaving it alone is what keeps **disarm reachable** after a program
  has taken the keyboard. This is not a style preference; it is the whole recovery story, and it
  should be stated as a contract rather than an expectation.
- **Disarm restores the slots from a known-good source** — the framework's own defaults. *(Note for
  whoever implements it: the framework keeps a defaults table today, but it holds three entries and
  serves as a **comparison baseline** — "did the user change this slot?" — while restoration works
  by re-running the console's installers. Either is a fine source; the existing table is not
  complete.)*

**What the model does need is a normalization step at the end of a load**, not a guard on the write.
Without it, two invariants are lost:

- a program that assigns the frame callback **displaces the framework's own frame loop**, and with
  it the click timer — so single- and double-click detection stops working, *including for that
  program*. This is why a project's frame callback is currently never installed into the slot: the
  framework keeps it aside and calls it from within its own loop;
- directly assigned handlers run **outside the framework's error boundary**, so a raise inside one
  does not surface the way a project's does.

So: assignment is free, and when a load returns the framework **harvests what was assigned and
re-installs it its own way** — wrapped, with the frame loop still framework-owned, and with the
claims recorded. Two consequences follow, and both are the point:

- the same normalization covers a typed line, a loaded file and a project, because it is attached to
  *loading* rather than to one verb;
- "is something running" becomes a question the framework answers by looking at what is installed —
  which is how it already decides whether a non-drawing project is still live.

*(A program that swaps its own handlers mid-run is not covered by a one-time sweep — true today as
well. There is precedent for continuous normalization: the draw slot is re-checked every frame.)*

### 3.2 Disarm must be a real operation with a name

Today the teardown of interaction exists but is welded into "stop the project", together with
concerns that belong to the environment. The model needs it separated and callable, idempotent, and
safe when nothing is armed — because it is what a user reaches for when a program has taken the
screen, and what a loaded file's author reaches for when they are done.

**It must be reachable when the environment is wrecked.** With a single shared environment, disarm
and factory reset are the only alternatives to restarting the application, so at least one of them
keeps a reserved key that no program can override. Such a key already exists; it needs to be kept
and documented.

### 3.3 The factory default must include the console's own vocabulary

Factory reset returns the environment to a defined baseline. That baseline has to contain the
console's own verbs — a reset that leaves the user unable to type `run` is not a reset.

### 3.4 Loaded modules need a teardown path

Modules a program requires are cached, and today the cache is cleared only when a program stops, and
only for files at the top level of the project. Under a shared environment this becomes visible:
load a project's modules, switch to another project, and the second project can receive the first
one's modules. The model needs a stated rule for when the module cache is cleared — at minimum when
the environment is reset and when the open project changes.

### 3.5 The accepted trade

A shared environment means a program can overwrite the console's own symbols, including ones the
console needs. That is inherent in *"as if the commands were typed at the console"*, and it is
accepted deliberately, with two mitigations: the interaction surface is guarded (3.1), and factory
reset restores the baseline (3.3). It should be stated in the user documentation, not discovered.

## 4. What this means for the input feature (`#77`)

The input feature is about to ship. For a reader unfamiliar with it, the parts that matter here:

- **The widget** — the text-input field a program can show to ask the user for input. It is created
  when a program starts and destroyed when it stops, so it never outlives the program that used it.
- **Shortcuts** — key combinations a program registers (`ctrl+s`, `alt+*`) that run a function.
- **Hooks** — per-event functions a program registers to receive raw keyboard or text events.
- **The chain** — when a program is interactive, each event is offered to its shortcuts, then its
  hook, then the widget; the first that consumes it stops the walk. A separate component performs
  this walk for programs; the console does its own, narrower dispatch.

**Nothing in the model contradicts this.** The feature's boundary is *which participants receive an
event*, and the model changes *where symbols live* — different axes. The widget, shortcuts, the
callbacks a program attaches to the widget, and the reserved keys all survive unchanged.

Three points do need decisions, and one of them is genuinely open:

- **Hooks versus the engine's own callbacks — open, and worth reopening before release.** Hooks
  exist so that a program's event handlers have a slot that the *program's* dispatcher owns. If the
  console performs one shared dispatch instead, that slot can simply be the engine's own callback
  again — which is also what "as if typed at the console" implies, since that is what a user would
  naturally write. The feature currently documents hooks as the recommended form. **Whether to keep
  recommending them is a live question**, and it is cheaper to settle before release than after: the
  surface is documented and already has one external consumer.
- **One dispatcher, and containment.** If the console runs the same chain, the boundary between
  "the program is receiving input" and "the console is receiving input" cannot disappear — it
  becomes a rule about who participates while a program is armed. Without that rule, a key the
  program does not consume falls through to a console that is not even visible.
- **Two input surfaces.** The console's own input line and a program's widget are the same kind of
  object. If both can exist at once, exactly one must be the one that receives keys, and that has to
  be stated.

**The feature needs no rework to ship.** What the model changes is the *reason* behind several of
its internals — a number of them exist to bridge the private environment copy, and become
unnecessary once there is one environment. Those are documentation edits, made after the release,
except for the hooks question above, which is a surface decision and belongs before it.

## 5. Non-goals

- Not a sandbox. The model deliberately trades isolation for predictability; the guard on the
  interaction surface is a guard, not a security boundary.
- Not a change to how events reach the application, nor to the reserved keys.
- Not an editor redesign. The editor's own environment has not been examined and is out of scope
  until it is.

## 6. Decisions still owed by the project owner

1. Does a load that claims nothing print or report anything, or is silence correct?
2. On failure — a file that raises halfway — is the environment left as the file left it, with
   interaction disarmed? (Disarm on failure, definitions kept, is the assumed answer.)
3. Do `dofile` and `run` keep those names, and what is the user-facing name of disarm and of factory
   reset? The current vocabulary is inconsistent about "quit" and "stop".
4. Is `dofile` still restricted to files of the open project?
5. Hooks versus the engine's callbacks (§4), which is the one decision that affects the release.

## 7. Sequencing

This work follows the input feature's release; it should not be folded into it. It is naturally two
tickets — the environment model (§2–§3) and the dispatch unification (§4) — which are coupled but
separately deliverable. The environment model is what makes a single dispatcher natural; it is not
what makes it possible.
