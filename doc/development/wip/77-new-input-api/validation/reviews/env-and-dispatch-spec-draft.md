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

## 1. Purpose, and the problem

**The purpose is to make the user's own code a first-class part of the console.** Today a project's
code is reachable only by running it: you cannot call one of its functions, inspect what it built,
or replace a piece of it and try again. The goal is that loading a project's file makes its
definitions ordinary console vocabulary — callable, inspectable, extendable — for debugging and for
enhancement.

Running the game this way should be *possible*, because a model that forbids it would be a special
case pretending to be a rule, but it is **not the point**: `run()` remains the way to play. The two
verbs express two intents — **`run()` is the reproducible path** (it starts from a clean
environment, so the result does not depend on your session), **loading is the exploratory path** (it
keeps everything, so the session accumulates).

**None of this is a new principle.** `doc/development/conventions/code.md` already states it:
*"**File = console equivalence.** Code in a `.lua` file and the same code typed into the Compy
console must have identical effect. This guides how modules and scripts are structured."* — and
directly above it, *"Do not use local variables outside their block."* The two rules are a fossil of
this exact intent: the second exists because of the first. **The request is therefore not for a new
requirement but for a documented one to be made true**, and the whole of this specification follows
from taking that one sentence seriously.

The problem is what stands in the way. The relationship between the console's environment and a
running program is unspecified, the equivalence rule is not honoured anywhere, and the behaviour
that fills the gap is inconsistent:

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

### 3.1 Interaction is claimed by ordinary assignment; the framework lifts its machinery above it

**The engine's callback slots stay writable.** A program — or a typed line — claims interaction the
way any LÖVE program does: by assigning `love.keypressed`, `love.draw`, `love.update` and their
siblings. There is no interception and no shadowed view of the engine table.

**One table is off-limits, by contract: the raw event table (`love.handlers`).** It is the fixed
pump that runs before anything is forwarded to a callback, and where the reserved keys live — quit,
stop, restart, reset. Leaving it alone is what keeps disarm reachable after a program has taken the
keyboard. Not a style preference: it is the cheap half of the recovery story, and it should be
stated as a contract rather than left as an expectation.

**The shape of the change is a lift, not a guard** (owner, 2026-09-01): the framework's own
machinery — error containment, the canvas binding, the shortcut and widget walk, view compositing —
moves **into the layer between the raw event table and the user's callback slot**, where the user is
not expected to reach, though nothing protects it. What remains in `love.<event>` is a plain
handler, and the console's own is an ordinary occupant of the same slot a program would take. The
layer already exists for events, because the pump forwards through it; for the frame callbacks it
exists only if the framework owns the run loop, which it already does in one mode today.

**Nothing inspects or rewrites what was assigned.** *(Ruled by the owner, 2026-08-31, against two
earlier drafts of this section — one proposing a guard on the write, one a normalization sweep after
a load. Both made assigned code special, which is what the equivalence rule forbids.)* A modified
slot is simply the loop's occupant and behaves as written. **Disarm** overwrites the slots again,
without caring who changed them or when. If user code breaks the engine's state irreparably, the
backstop is restarting the application — an accepted answer, not a failure of the model.

Two responsibilities do need to sit where a claimed slot cannot take them with it. Neither inspects
the user's value, so neither is an exception to the rule above:

- **Errors are contained at the call site, not by owning the value.** The pump already forwards to
  whatever occupies a slot; forwarding inside an error boundary treats every occupant identically —
  typed, loaded, project — and never touches what was assigned. Without this, a raise inside a
  handler reaches the engine's own error screen, and since `run()` is reset-plus-load under this
  model, **`run()` loses the containment it has today**. That is a regression to decide on, not a
  gap to discover.
- **The framework's own per-frame work belongs to the run loop, not to the frame callback.** Today
  the click timer, the draw re-check, the snapshot step and the timer tick all live inside the frame
  callback, so claiming that slot silently takes them along — and single- and double-click detection
  stops for the very program that claimed it. Moving that work into the loop, which then calls the
  user's frame function, makes claiming a slot mean claiming *that* slot and nothing else. The run
  loop is already replaced in one mode today, so this is not a new capability.

One consequence stands either way: **"is something running" is derivable by comparing the slots
against the defaults** — a read, with no installation and no bookkeeping. *(Implementation note: the
framework keeps a defaults table today, but it holds three entries and is used for exactly this kind
of comparison, while restoration works by re-running the console's installers. Either can be
disarm's source; the existing table is not complete.)*

### 3.2 Disarm must be a real operation with a name

Today the teardown of interaction exists but is welded into "stop the project", together with
concerns that belong to the environment. The model needs it separated and callable, idempotent, and
safe when nothing is armed — because it is what a user reaches for when a program has taken the
screen, and what a loaded file's author reaches for when they are done.

**Given the purpose (§1), this is the most-used verb of the three, not an edge case.** The debugging
workflow is: load a project, let it claim what it claims, disarm to get the console back, then call
its functions with everything it defined still in place. Disarm is what makes the environment
persist while the interaction does not — which is the whole affordance.

**It is called from both directions** (owner, 2026-09-01): automatically whenever a program exits —
so the ordinary path costs no extra call — and by name from the console, when a user wants the
console back from a program that has not finished. It is the one piece of the current teardown worth
keeping; the rest of that sequence maintains structures this model does not have.

**It should stay reachable when a program has taken the input, and that is a convenience rather than
a guarantee** (owner, 2026-08-31): the ultimate backstop is restarting the application. Reserved
keys give it for free — they live in the raw event table that the contract puts off-limits, so they
run before anything is forwarded. Such a key already exists; keeping and documenting it costs
nothing and saves a restart.

### 3.3 The factory default must include the console's own vocabulary

Factory reset returns the environment to a defined baseline. That baseline has to contain the
console's own verbs — a reset that leaves the user unable to type `run` is not a reset.

### 3.4 Loaded modules need a teardown path

Modules a program requires are cached, and today the cache is cleared only when a program stops, and
only for files at the top level of the project. Under a shared environment this becomes visible:
load a project's modules, switch to another project, and the second project can receive the first
one's modules. The model needs a stated rule for when the module cache is cleared — at minimum when
the environment is reset and when the open project changes.

### 3.5 What the debugging affordance reaches — and what it does not

Since calling and amending a project's code is the *purpose*, its two natural limits should be
documented rather than met by surprise:

- **Only globals become console vocabulary** — and the project already legislates for this. A file's
  outermost `local` declarations are private to that file (Lua, not a design choice), so a project
  written entirely in outer locals would expose nothing to the console. `conventions/code.md` has
  ruled outer locals out since before this discussion, immediately above the equivalence rule they
  serve. Nothing new is needed here; the rule's *reason* should simply be written next to it, since
  today it reads as style.
- **Redefinition reaches name lookups, not values already handed over.** Replacing a function at the
  console changes what a later `foo()` resolves to, but not a copy of the old function that
  something is already holding — an installed callback, a registered shortcut, a stored handler.
  So a program's *live* behaviour changes on redefinition only where it calls the global by name.
  If live-editable handlers are wanted, that is a small authoring convention (register a thin
  function that looks the global up when it fires), and it belongs in the user documentation.

### 3.6 The accepted trade

A shared environment means a program can overwrite the console's own symbols, including ones the
console needs. That is inherent in *"code in a file and the same code typed at the console must have
identical effect"*, and it is accepted deliberately. There are two answers rather than a guard:
factory reset restores the baseline (§3.3), and — for a program that has broken the engine's state
past that — restarting the application. Both should be stated in the user documentation, not
discovered.

## 4. What this means for the input feature (`#77`)

The input feature is at release-candidate stage. For a reader unfamiliar with it, the parts that
matter here:

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

- **Two Compy-specific surfaces are candidates for retirement in favour of standard LÖVE ones, and
  both are decisions for *now*.** Neither exists at the PR base — both are new surfaces of the
  unreleased feature, so this is not deprecating a public API, it is **choosing one before it
  becomes public**. The cost today is an example, a guide section, tests and a decision entry;
  after the candidate ships it is that plus a migration.
  - **`compy.input.hooks` versus the engine's own callbacks.** Hooks exist so a program's event
    handlers have a slot the *program's* dispatcher owns. With one shared dispatch and the framework
    machinery lifted above it, that slot can simply be `love.<event>` again — which is what "code in
    a file and the same code typed at the console" implies anyway, since it is what a user would
    naturally write.
  - **`compy.before_exit` versus `love.quit`.** Same direction, with one semantic to settle: in
    LÖVE, `love.quit` returning true **aborts** the quit, while this hook deliberately ignores its
    return — a program is not permitted to refuse to stop, which is the guarantee the reserved keys
    exist to protect. Reusing the name means either honouring the veto (not recommended) or keeping
    a name that promises what it does not do. There is also a scope difference — application exit
    versus program stop — though the framework already redirects the former to the latter while a
    program runs.
- **One dispatcher, and containment.** If the console runs the same chain, the boundary between
  "the program is receiving input" and "the console is receiving input" cannot disappear — it
  becomes a rule about who participates while a program is armed. Without that rule, a key the
  program does not consume falls through to a console that is not even visible.
- **Two input surfaces.** The console's own input line and a program's widget are the same kind of
  object. If both can exist at once, exactly one must be the one that receives keys, and that has to
  be stated.

**The feature needs no rework to ship.** What the model changes is mostly the *reason* behind
several of its internals — a number of them exist to bridge the private environment copy and become
unnecessary once there is one environment. Those are documentation edits, made after the release.
The exception is the pair of surface questions above: they are naming decisions on an unreleased
surface, and they are cheapest now.

## 5. What becomes of the existing modes

The application has an app-state enumeration — *ready, project open, running, snapshot, inspect,
editor, shutdown* — plus a separate launch mode. The model touches them unevenly.

**`play` is not one of these states: it is a launch mode.** Started pointed at a project, the
application mounts it and runs it as a standalone game, and the console-management reserved keys
deliberately no-op there (only restart and profiling stay live). The purpose in §1 does not apply —
nobody is typing — and it is the one context where **restarting really is the only recovery**, since
the reserved-key escape is switched off by design. Nothing in the model changes it.

**`suspend` / `inspect` is where the model pays off most.** Suspending today freezes a screenshot,
saves the program's handlers, restores the console's, and — the load-bearing part — **switches the
console to evaluate in the program's environment**. That switch is the entire reason the mode
exists, and with one shared environment it evaporates: the console can already see the program's
symbols, at any time, without suspending anything.

What remains is purely interaction: **suspend = disarm, remembering what was armed; continue =
re-arm from that memory.** That is the disarm primitive plus a saved set, and both halves already
exist in the framework. The screenshot is a *view* affordance, orthogonal to either, and is
unaffected.

**So the machine reduces to three independent facts** rather than an enumeration:

- is a project open?
- is anything armed — and if not, is there a saved set to re-arm? *(armed / stopped / suspended)*
- is the editor up?

*Ready* and *project open* then differ only by the first; *running* and *project open* only by the
second; *inspect* is "disarmed with memory, snapshot painted"; *snapshot* is a one-frame view
transition; *shutdown* is terminal.

**The recommendation is to derive the state from those facts, not to delete the enumeration.** It is
read widely — including by the input feature and the reserved keys — and the editor route has not
been examined. Deriving is the same move as "what is running is a question you answer by looking",
applied to the whole machine; deleting is a separate decision that needs the editor looked at first.

## 6. Non-goals

- Not a sandbox. The model deliberately trades isolation for predictability, and it does not guard
  the interaction surface at all — a claimed slot is a claimed slot.
- Not a change to how events reach the application, nor to the reserved keys.
- Not an editor redesign. The editor's own environment has not been examined and is out of scope
  until it is.

## 7. Decisions still owed by the project owner

Answered in discussion and recorded above: the purpose (§1), a shared environment, free assignment
with disarm by overwrite, `run` = reset + load with the reset automatic, and automatic disarm on
exit. What remains:

1. **The two surface names** (§4) — `compy.input.hooks` versus `love.<event>`, and
   `compy.before_exit` versus `love.quit`, the latter needing the veto semantics settled. These are
   the only decisions that touch the release.
2. **Error containment.** With nothing wrapping a handler's value, a raise inside one reaches the
   engine's error screen — including for `run()`, which has containment today. Containing it in the
   lifted layer (§3.1) keeps the behaviour without touching what the user assigned; not doing so is
   a deliberate regression. Which?
3. **Failure during a load** — a file that raises halfway leaves its definitions and whatever it
   claimed. Disarm on failure, definitions kept, is the assumed answer.
4. **Vocabulary** — `dofile`, `run`, and the user-facing names of disarm and factory reset. The
   current set is inconsistent about "quit" and "stop".
5. **Is `dofile` still restricted to files of the open project?**
6. **Does a load that claims nothing report anything, or is silence correct?**

## 8. Sequencing

This work follows the input feature's release; it should not be folded into it. It is naturally two
tickets — the environment model (§2–§3) and the dispatch unification (§4, §5) — which are coupled but
separately deliverable. The environment model is what makes a single dispatcher natural; it is not
what makes it possible.
