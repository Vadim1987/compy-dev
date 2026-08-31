# Assessment — the project owner's console/project environment inquiry

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

**Session:** 62 · **Date:** 2026-08-31 · **Mode:** research + analysis (architecture assistance).
**Subject:** [`../notes/owner-inquiry-console-env-lifecycle.md`](../notes/owner-inquiry-console-env-lifecycle.md)
(the inquiry verbatim; R1/R2/R3 labels are defined there).
**Evidence:** first-hand code reads, cited `file:line` below; a systematic map was commissioned in
parallel — [`../outcomes/session62-env-lifecycle-code-map.md`](../outcomes/session62-env-lifecycle-code-map.md).
Claims here marked **(unconfirmed)** await that map.

**No ruling is made here.** Two questions were asked — *does this collide with `#77`, and what would
it cost*, and *is the request sound on its own terms*. They are answered in that order, and the
outputs are: a blast-radius verdict, a design fork the ticket cannot avoid, and fourteen questions
worth answering **before** the ticket is filed, which is what the project owner actually asked for.

---

## Part 0 — what the code does today, in the terms the inquiry uses

Six facts, each verified directly, because the inquiry's premise ("not even properly specified") is
correct and the documentation of this machinery has already drifted.

1. **The console's environment is (almost certainly) the real `_G`.** `ConsoleController.new` takes
   `local env = getfenv()` (`consoleController.lua:40`) — the file's own global environment, and
   nothing `setfenv`s that module — and keeps it as `main_env` (`:60`). So a REPL assignment is an
   assignment to the process's global table. **(Confirmed by the code map's runtime probe, 2026-08-31.)**
2. **The project's environment descends from a deep clone of that table taken at boot**, not at run
   time: `pre_env = table.clone(env)` (`:41`), then `prepare_project_env` builds a template from
   `get_pre_env_c()` (`:1117`) and clones it twice — `base` and `project` are **siblings** of one
   intermediate table (`:1217-1220`), not parent and child. A REPL assignment made after boot
   therefore cannot reach a project.
   **But R2 does not hold today, and the reason is finding 7 below.** *(Corrected 2026-08-31 after
   the code map: an earlier draft of this document claimed R2 was already satisfied. That is true
   only of console-typed assignments, and only for the first run.)*
3. **`dofile` is two different functions.** From the console it is
   `project_dofile(cc, name)` with **no env argument** (`:991-995`); from inside a project it is
   `project_dofile(cc, name, cc:get_project_env())` (`:1122-1123`). `project_dofile` only
   `setfenv`s `if env` (`:394-409`), and the chunk arrives from `Project:load_file` →
   `codeload(content, nil, filename)` (`project.lua:109-113`), which likewise skips `setfenv` when
   the env is nil (`util/lua.lua:17-29`). A chunk built by `loadstring` runs in the **global**
   environment. So the console's `dofile` **already** runs the file in the console's own environment
   and already leaves its globals behind — **R1's substance is mostly present today and unwritten**.
   What is absent is R1's other half: nothing restores the interaction callbacks on return, so a
   file that assigns `love.draw` hijacks the console with no way back short of running and stopping
   a project.
4. **The console has a `compy` namespace of its own**, built by a *second* call to
   `get_compy_namespace` (`:1090` for the console, `:1192` for the project template). Since
   `get_compy_input()` is invoked inside it (`:941`) and is not memoised, **there are two
   `compy.input` surfaces**, each with its own `shortcuts`/`hooks` tables (`:895-911`).
5. **The project route dispatches on the project env's surface, resolved at activation:**
   `pic:activate(project_handlers(userlove, CC), compy.input)` where
   `local compy = CC:get_project_env().compy` (`controller.lua:228-231`). The console's surface is
   never dispatched on. It survives cloning correctly because `input` is metatable-resolved rather
   than a field (`consoleController.lua:928-941`) — the piercing practice working as intended.
6. **`compy.input.show()` with no widget is a silent no-op** — `local ui = get_widget(); if ui then
   ui:show(next_cfg) end` (`:749-757`). Between runs `love.state.user_input_controller` is nil, so
   the call does nothing and logs nothing. Its siblings warn in the comparable case
   (`set_text`/`set_cursor`, `:848-853`, `:764-768`). See Part 2, finding **C4**.
7. **Whether a run starts clean depends on whether you named a different project.**
   `_reset_executor_env` — the only thing that replaces `project_env` with a fresh clone of
   `base_env` (`:1277-1278`) — has **exactly one caller**: `close_project` (`:1428`). Therefore:
   - `run()` on the project already open → `run_project` takes `self:get_project_env()` as-is and
     resets nothing (`:320`). **The previous run's globals are still there.**
   - `run("another")` → `open_project` → `close_project` (`:1421-1423`) → reset. **Clean.**
   - `Ctrl+Alt+R` restart is `stop_project_run` + `run_project` (`:1286-1289`) — **not clean**;
     `stop_project_run` (`:1459-1474`) never touches the environment.

   So R2 holds against *console* assignments and against *other projects*, and fails against **the
   project's own previous run** — which is the case a user meets while iterating, and is a
   mechanism for the "mystery and frustration" the inquiry names.

### Part 0b — four further facts from the code map, each re-verified here

- **`base_env` is not write-protected**, though `internals/console.md:44` says it is.
  `_set_base_env` calls `table.protect(t)` and **discards the return value** (`:1329-1332`), and
  `table.protect` builds a *proxy* without mutating the original (`util/table.lua:72-74`). This is
  the same defect already registered for `love.handlers` in `technical_debt/general.md`
  (*"`table.protect(love.handlers)` is a no-op on the passed table"*) — a **second site of a filed
  entry**, not a new phenomenon.
- **`internals/console.md`'s rationale for `base_env` is inverted.** It says `project_env` is reset
  to `base_env` *"when a project is stopped without closing"* and that the split exists so that
  **restarting** gives a clean table while **reopening** does not. The code does the opposite on
  both counts (finding 7). The doc is in the persistent corpus and is the natural first read for
  anyone approaching this ticket.
- **`evacuate_required` evicts only top-level `.lua` files** from `package.loaded` (`:1443-1457`,
  over `open:contents()`); modules required from subdirectories are never evicted by any path.
  R2's clean slate has to name the module cache explicitly for this reason (§1.5).
- **A project's `love` is a one-time deep clone taken at construction and never refreshed**, so
  `love.state.app_state` read from inside a project is frozen at `'ready'` forever. This is the same
  hazard as Decision 18's `love.state.user_input`, one field over, and it is why "the project sees a
  `love`" is a weaker statement than it looks.

*(Map: [`../outcomes/session62-env-lifecycle-code-map.md`](../outcomes/session62-env-lifecycle-code-map.md).
Its remaining claims — the editor's own execution env, PUC-Lua parity for the metatable findings,
`FS.dir` recursion on disk — are not relied on here.)*

---

## Part 1 — the essence, independent of `#77`

### 1.1 The request is sound, and the strongest thing in it is not a behaviour

The three expectations are individually reasonable and jointly coherent with the product's own
stated character (`conventions/architecture_principles.md`, *"The Pedagogical Test"*): a teaching
instrument should be **predictable before it is isolated**. "As if the same commands were typed at
the console" is a mental model a learner can hold; "a deep clone of the global table taken at
construction time, from which a per-open snapshot is re-cloned on reset" is not, and no amount of
documentation makes it one.

The load-bearing sentence is *"not even properly specified"*. R1 is already close to what the code
does (Part 0.3), and R2 holds in two of its three cases while failing in the one a user meets most
— iterating on the same project (Part 0.7) — so this ticket's primary deliverable is **a
specification with a name, in the persistent docs**, and the code changes are what it takes to make
the specification true without exceptions. Any ticket framed as "change the environment behaviour"
and not as "state the environment contract, then honour it" will reproduce the present condition
one refactor later.

### 1.2 The fork the ticket cannot avoid: one environment, or two with a transfer

**R2 says a project must not see prior console state. R3 says the console must see the project's
state afterwards.** Both can hold, but only under an explicit choice, and the inquiry does not make
it:

- **(A) One environment, saved and restored.** The project runs in the console's own environment;
  `run()` swaps in a clean default and the previous contents are set aside; at the end the project's
  assignments are simply *there*, because they were written where the console reads.
  R3 is free. The question this shape must answer is **what happens to what the console had
  before** — under the plain reading, `x = 5` typed before `run()` is gone afterwards, since the run
  reset the environment and the project's leftovers replaced it. That may be exactly right (it is
  "the console is now what the project made"), but a user will meet it on day one.
- **(B) Two environments and a defined transfer.** The project runs in a separate table; at the end
  its new symbols are merged into the console's. Prior console state survives, but merge semantics
  must be specified: **collisions** (project assigns a name the console already uses — who wins?),
  **deletions** (project sets `foo = nil`), **in-place mutation of shared tables** (not an
  assignment at all, so no merge sees it), and **identity** (see 1.3).

These are not equivalent and the difference is user-visible on the first afternoon. **This is
question 1 of the fourteen, and everything else is downstream of it.**

### 1.3 The identity trap — (B) multiplies the very hazard that was just paid off

If the console adopts or merges from a cloned project environment, it acquires **clones of live
platform tables** — a `love` whose identity is not the framework's, a `compy` that is not the
console's. Every subsequent console assignment into one of them lands in a copy that no dispatcher
reads: *nothing is nil, nothing raises, the handler simply never runs*. That is precisely
`T-NAMESPACE-CLONE` (`technical_debt/general.md`, RETIRED — "PAID by a written practice"), the
entry the owner folded days ago, and it cost an hour of on-device debugging the first time.

The practice that pays it — *"A Namespace Hands Out Live Tables by Reference, Never by Value"*
(`conventions/architecture_principles.md`) — is a **discipline applied per member**. It holds only
as long as every future namespace member remembers it. Shape (A), or any shape with **one identity
per table for the whole process**, removes the hazard *structurally* rather than by discipline.

A third shape deserves naming because it delivers all three expectations with one mechanism and no
cloning at all:

- **(C) Overlay by `__index`.** The project runs in a fresh empty table whose `__index` falls back
  to a frozen default. Nothing is copied; there is one `love`, one `compy`, one identity for
  everything. R2 is free (a fresh overlay sees no prior assignment). R3 is free and *precise* — the
  set of symbols the project assigned is literally the overlay's own keys, so "keep what the project
  defined" is a table you already hold, no diffing. R1 is free (run with no overlay).
  **What (C) gives up is nested-table isolation**: a project mutating a shared table is seen by the
  console, where a deep clone would have hidden it. That trade should be made deliberately — but
  note the present isolation is already partial by construction, since `table.clone` shares every
  leaf, so every engine function and all device state is shared today anyway
  (`internals/project_sandbox_env.md`, T3).

**Recommendation, offered as input to the owner's ruling, not as a ruling:** (C) is the shape that
matches the inquiry's own mental model, it is the only one that makes the specification a paragraph,
and it deletes rather than disciplines the copy hazard. It is also the largest change of the three.

### 1.4 What "the interaction callbacks" must become

Both R1 and R3 are stated in terms of a set — "the interaction callbacks" — that has no definition
in the docs and, since `#77`, more than one member class. The ticket must **enumerate it once, by
name**, because two of the three expectations are unimplementable without it. Today it spans:

- the `love.*` event handlers plus `update`/`draw`/`quit` — harvested from the project's env
  (`save_user_handlers`, `controller.lua:1050`, called at `consoleController.lua:1349`;
  `set_user_handlers`, `:124`) and reset by `Controller.set_default_handlers`;
- **since `#77`:** `compy.input.hooks[event]` and `compy.input.shortcuts[event][combo]`, which are
  not `love.*` and not environment globals but *do* determine interactivity, and the widget's own
  shown-ness.

One favourable consequence: **the callbacks do not live among the environment's globals** — they are
fields of a `love` table and of the input surface. So "keep every symbol except the interaction
callbacks" needs no filtering of the environment at all; it needs a reset of two known places. That
makes R1 and R3 considerably cheaper than they sound.

### 1.5 Where the expectations stop short (feeds the question list)

- **"Upon return" is not the failure path.** A `dofile`'d file that raises never returns; a project
  that raises mid-run never reaches its stop path (registered: `technical_debt/input.md`, *"A
  project that raises leaves global device state dirty"*). Restoration must be *finally*, not
  *on return*, or the mess survives in exactly the case a learner hits most.
- **`package.loaded` is part of the environment for R2's purposes**, or R2 is a half-guarantee: a
  module cached by a previous run is a prior assignment affecting this one. Today `evacuate_required`
  clears project modules at stop; the ticket should say so as a rule rather than leave it as an
  implementation detail.
- **Non-Lua state.** "Reset to a well-defined default" reads as `_G`-scoped, but the frustration it
  names is not: cursor visibility, key repeat, relative mouse mode, audio still playing, canvas and
  terminal state all survive a run today and nothing restores them (T3). Deciding this in scope
  would pay a registered debt entry; deciding it out of scope is fine, but it should be *decided*.
- **`inspect`/suspend is unaddressed** — and it is the one place where "the console reads the
  project's environment" is already the intended behaviour (`internals/console.md`, *"Console Input
  Evaluation"*). It is a miniature of R3 and should be specified with it, not after it.
- **`restart` and quickswitch are runs.** `Ctrl+Alt+R` and `Ctrl+T` call stop + run directly and
  never re-open (`internals/user_input.md`, *"Widget lifecycle"*) — so "running a project" for R2's
  purposes must name them, or the clean-slate guarantee has two silent exceptions.
- **Console `dofile` is gated on an open project** (`check_open_pr`, `:981-995`) and resolves the
  filename through the project's mount. Whether R1's `dofile` is project-scoped or general is a
  scope question the ticket should answer explicitly.
- **Naming.** The inquiry's `quit()` does not exist inside a project: the project env exposes
  `stop`, `pause`, `continue`, `run`, `close_project` (`:1156-1185`), while the console's `quit`
  quits the *application* (`:1104-1106`). A contract stated in terms of a symbol that means
  something else is a specification defect on day one.

---

## Part 2 — collision with `#77`, blast radius, cost

### 2.1 Verdict: no rework of `#77`. Nothing here overturns a shipped decision

The three expectations constrain a layer **below** the input feature — environment identity and
lifetime — while `#77`'s machinery is written against the **run boundary** (build at `run_project`,
destroy at `stop_project_run`; Decision 11), which every candidate shape preserves. Checked against
the feature's own load-bearing pieces:

| `#77` asset | Under (A)/(C) one identity | Under (B) two + transfer |
|---|---|---|
| `compy.input` behind `__index`, assignment refused (Decision 7) | still correct; its *rationale* (surviving clones) becomes moot | unchanged, still required |
| Widget run lifetime, `love.state.user_input_controller` nil between runs (Decision 11) | unchanged | unchanged |
| `is_shown()` existing because a project's `love.state` read is always nil (Decision 18) | the hazard disappears; the accessor stays as convenience, its *reason* changes | unchanged |
| Callback harvest / re-install / reset (T1) | unchanged mechanically; becomes the ticket's named "interaction callbacks" set | unchanged |
| `compy.before_exit` closure slot (BACKLOG, *"is it intended?"*) | **answered** — one env, one slot, trivially | must be ruled deliberately |
| T3 device leak + crash path (BACKLOG) | candidate scope of R2's "well-defined default" | same |

**Cost to `#77`, in the three sizes asked about: not "no change", not "rebuilding half" — a small,
focused, documentation-only change**, and only *if and when* the ticket lands. Specifically: the
*reasons* attached to Decisions 7 and 18 and to the architecture principle would need restating
(the pattern stays right; its justification stops being "because of the clone"), plus
`internals/project_sandbox_env.md`, whose entire framing is the clone. **No production code of the
input feature is implicated**, and no test of it asserts environment identity as far as the reads
above go (to be confirmed against the map).

### 2.2 Four concrete intersections — these are the deliverables of Part 2

- **C1 — R3 legitimises calling project functions from the console, and `#77` made half of them
  dead.** A "console-extending" project (R3's stated purpose) that leaves behind
  `function ask() compy.input.show{...} end` produces a function the user can now call at the REPL —
  where the widget no longer exists (destroyed at stop) and, per Part 0.6, **the call silently does
  nothing**. This is not a defect in either design; it is an intersection nobody has ruled on. Three
  honest answers, cheapest first: (i) the surface warns when there is no widget; (ii) the spec says
  run-scoped surfaces are unavailable to console-extending projects, in writing; (iii) the console
  gets a widget binding of its own — much larger, and it would resurrect the application-lifetime
  widget `ARC-01` deliberately dissolved.
- **C2 — "changing the interaction callbacks" must include the `#77` channels.** R3's predicate, read
  narrowly as `love.*`, misclassifies a project whose only interactivity is `compy.input.hooks` or
  registered shortcuts — a class `#77` explicitly ruled on (`technical_debt/input.md`, *"Input-only /
  pointer-only projects stay live in `project_open`"*, RESOLVED, ruling (a)). See 1.4.
- **C3 — two `compy.input` surfaces exist, and one of them is not wired to anything** (Part 0.4/0.5).
  A `compy.input.shortcuts.keypressed['x'] = f` typed at the console mutates a table the dispatcher
  never reads. Harmless today because nobody types it; under R3 the console becomes a place where
  people *do* extend input behaviour, and this becomes the silent-divergence failure again — one
  namespace-instance level above the one the practice covers.
- **C4 — `compy.input.show()` silently no-ops with no widget**, while `set_text`/`set_cursor` warn in
  the comparable case (Part 0.6). This is a deviation from the feature's own warn-don't-swallow
  convention, it is **independent of the ticket**, and it is a candidate `BUG` row: one guard plus a
  test. *Not filed — raised for the owner's ruling.*

### 2.2c SUPERSEDING §2.2b — the owner ruled the interactive reading (2026-08-31)

**Q15 is answered: `dofile` must be able to run an example's `main.lua` and have it work** — all
conventions, the dispatch chain, single/double-click detection included. §2.2b below argued the
opposite line (*"a console extension extends the vocabulary, not the interaction"*); it is kept as
the argument that was weighed and rejected, not as advice.

**R1 contradicts itself under this reading, and that is the first thing the ticket must fix.** An
example's `main.lua` defines its callbacks and **returns immediately** — that is the shape of a LÖVE
program. "Restore the interaction callbacks **upon return**" therefore kills the example on the
frame it starts. The restore must bind to the program's **end** — stopped by the user or by
`stop()`, *or* returned without ever claiming a callback, which is R3's case, where the two
coincide. With that amendment the three expectations collapse into one machine, which is what makes
the specification a paragraph:

> **`dofile` and `run` are the same lifecycle, differing in exactly one axis: which environment the
> program runs in** — the caller's (`dofile`) or a fresh default (`run`). A program may claim the
> interaction callbacks; when it ends they are restored; its symbols stay where it wrote them.

**Correction to §2.2b's sizing claim: this does *not* depend on Decision 1's console/editor
convergence.** An interactive `dofile`'d program takes the **project route**, exactly as a `run()`
program does — it claims the callbacks, the route walks `shortcuts → hooks → widget`, and the
console route is untouched. Verified for the owner's own example: click synthesis is
**route-agnostic framework machinery** — presses counted in the Layer-1 raw handler
(`controller.lua:947-951`), `singleclick`/`doubleclick` emitted through the gateway from
`set_love_update` (`:547-563`), whose comment states *"Who receives it … is the route's business,
not this timer's."*

The real dependency is different, and smaller than a new subsystem: **the run lifecycle must become
env-parameterized.** Four items, all in the lifecycle functions of one file:

1. **`occupy_input` is hardwired to the project env** — `local compy = CC:get_project_env().compy`
   (`controller.lua:229`). A program running in the console env would write its hooks and shortcuts
   into the console's `compy.input` object while dispatch reads the project's. **C3 stops being
   latent and becomes a guaranteed silent failure**, so memoising `get_compy_input` (one surface per
   process) is a **prerequisite**, not hygiene. *(Base check: the two-instance shape is
   pre-existing — `get_compy_namespace` is called twice at base `3256aac` too, `:461`/`:627`.)*
2. **The widget seam** — `build_input_widget`/`destroy_input_widget` move from
   `run_project`/`stop_project_run` to the generalized start/stop. Mechanical.
3. **Callback save/restore survives the loss of the copy.** `save_user_handlers` does **not** rely on
   the sandbox being private: it diffs against a recorded baseline (`save_if_differs` vs
   `Controller._defaults`, `controller.lua:1050-1065`), and `set_default_handlers` is already the
   restore. Two caveats: a program assigning `love.draw` in the console env writes the **live** slot
   at once, so a raw unwrapped handler is briefly active before the harvest re-installs it wrapped
   (`with_canvas_and_errors`); and the console's defaults must be recorded before the file runs —
   they are.
4. **Program-control verbs and the loader.** `stop`/`pause`/`continue` exist only in the project env
   (`:1156-1185`); a console-env program needs them reachable. The project's `package.loader`
   resolves through `get_effective_env()` (`:1312-1320`), which must follow the program's env or
   `require` inside a `dofile`'d example loads into the wrong table.

**The consequence to accept deliberately:** running an example in the console environment runs it in
the real `_G`, where it can clobber `print`, `run`, `dofile` — anything. That is inherent in "as if
typed at the console", and examples were not written with it in mind. The payoff is the one the
project owner wants: when the program stops, its state is at the REPL — the `inspect` experience,
permanently, without suspending. It should be an accepted trade in the ticket, not a discovery.

**Sizing, restated:** not a console input subsystem (§2.2b was wrong about that), but the run
lifecycle generalized over an env parameter, plus the single-surface prerequisite. `#77`'s shipped
behaviour still does not change; the pieces being generalized are its own.

#### The sentence the ticket turns on: environment transparency ≠ installation transparency

Both literal readings of R1 are broken, and the owner reached this by asking what `dofile`ing an
example's `main.lua` does **today** (2026-08-31):

- **Transparency with no restore** (today's behaviour): the file's `love.*` assignments go straight
  into the live slots. No route is activated, so there is **no `shortcuts`/`hooks` dispatch and no
  widget**; `user_update`/`user_draw` are never set and `app_state` never changes; and — the
  sharpest part — `love.update = f` **displaces the framework's own frame loop**, taking the draw
  re-wrap, the click timer (**so no `singleclick`/`doubleclick` synthesis**), `pass_time`, the
  snapshot/suspend path and the harmony timers with it. Only `love.draw` gets error-wrapped, and
  only by accident, via the update loop's re-wrap — which is gone too if `update` was taken. The way
  back is `Ctrl+Shift+R`, undocumented.
- **Restore literally "upon return"**: the example dies on the frame it starts, because `main.lua`
  returns as soon as it has defined its callbacks.

The reason `run()` does not have this problem is **not** the environment clone — it is the
installation path. `hook_update` never lets a project's `update` reach the real slot: it stashes it
in `Controller._userhandlers.update` and the framework's own update calls it wrapped
(`controller.lua:~300`, `:586-592`). `hook_draw` installs a composed draw, `occupy_input` activates
the route, `build_input_widget` provides the widget, `with_canvas_and_errors` is the error boundary,
and `stop_project_run` is the way back.

**So the ticket's content is: `dofile` must *start a program* through the same lifecycle as `run()`,
differing only in which environment it runs in.** A `dofile` that merely executes a chunk
transparently — which is what "as if typed at the console" says literally — delivers a program
runner with no dispatch, no widget, no error boundary and no frame loop. Environment transparency is
the requirement; installation transparency is the bug.

It follows that the ticket must also fix the console's own exposure (§ the behaviours note,
["3b"](../notes/console-env-observable-behaviours.md)), because "as if typed at the console" is only
a safe specification once typing at the console is itself safe.

### 2.2b (SUPERSEDED by §2.2c) The same intersection reached from R1 — and the line that answers it

The owner reached C1 independently from the `dofile` side (2026-08-31): under R1 a file run at the
console gets the **console** environment, where `compy.input` exists but is inert — no widget
outside a run, and **no dispatch at all**, since `ConsoleController:keypressed`
(`consoleController.lua:1516`) runs its own narrow dispatch rather than the project route's
`shortcuts → hooks → widget` chain (`technical_debt/input.md`, *"Decision 1 — console/editor
convergence onto the shared chain is unimplemented"*, BACKLOG, scoped out on filing). C3 makes it
worse: a `shortcuts` write at the console lands on the console's own surface object, which nothing
dispatches on.

**Proposed line, offered for the project owner's confirmation:** *a console extension extends the
vocabulary, not the interaction.* It is derived from their own model rather than imposed on it —
R1 restores the callbacks on return and R3 restores them at stop, so **the console-extension
category is non-interactive by construction**. Such a file may define functions, data and commands,
print, use `compy.terminal`, draw through `gfx`, and do file I/O; it may *define* a function that
drives the widget, which then works when called during a run.

The alternative — giving the console the full chain — is not merely larger, it is semantically
unsettled: the console **is already an input surface** (its REPL line is its own controller instance
with its own callbacks, `:49-52`), so a widget shown outside a run means two text fields with two
cursors both claiming Enter; and a console-registered shortcut has no run boundary to bound its
lifetime. That work belongs to Decision 1's convergence entry, not to the environment ticket —
letting the env question grow an input subsystem is the *"solution significantly expands commitment
scope"* flag from `agents/validation.md`'s replanning checklist.

**Cost of the recommended line:** two pieces of hygiene instead of a subsystem — memoise
`get_compy_input` so the process has **one** surface (closes C3), and warn rather than no-op when a
run-scoped method is called with no widget (closes C4). A few lines and a test or two.

### 2.2e Design direction taken by the owner (2026-08-31) — three protections

Recorded as decisions-in-progress, with the consequences verified in code. Q5 of the owner's own
seven was **discarded** (its premise was false: `compy` *is* provisioned in the console env). The
remaining questions were ruled to be details of a solution that exists, not open questions.

**(1) The console's evaluation environment holds a shadowed `love`, so an assignment is
intercepted.** Not only `dofile` — the console itself. This is one surgical change: `evaluate_input`
already *chooses* the env per evaluation (`consoleController.lua:1250-1256`), so REPL chunks compile
into an overlay `{ love = <proxy> }` whose `__index`/`__newindex` fall through to the console env.
`_G` itself is untouched, so framework modules — whose fenv *is* `_G` — keep the real table and keep
installing handlers normally.

- **A proxy beats a clone for the shadow.** `__index` → the real `love` (so `love.graphics.*` works
  and `love.state` is **live**), `__newindex` → a capture table (so `love.draw = f` is caught and can
  be harvested by the same `set_handlers` path a run uses — which notably never lets `update` reach
  the real slot). Today's project `love` is a one-time boot clone: its `app_state` is frozen at
  `'ready'` and its `love.state.user_input` is permanently nil, which is the whole reason
  `compy.input.is_shown()` exists (Decision 18). Accepted regression: `pairs(love)` sees only
  captured writes.
- **It should apply in every state, not only after a project is opened.** Today the same typed line
  has three outcomes (takes effect / inert / dormant-then-live in `inspect` — behaviours note §3b);
  a state-dependent guard keeps that incoherence, an unconditional one removes it. In `inspect` the
  REPL already compiles into an env with a shadowed `love`, so unconditional is also the *smaller*
  rule.
- **The protection lives in the environment — but `dofile` does *not* inherit it for free.**
  *(Corrected 2026-08-31: an earlier draft of this section claimed it did.)* Console `dofile` passes
  **no env** to `project_dofile` (`:991-995`), and the chunk comes from `codeload(content, nil, …)`
  → `loadstring`, whose returned function gets **the global environment**, not the caller's fenv
  (Lua 5.1 semantics). It runs in the console env today only because that env *is* `_G`. The moment
  the REPL compiles into an overlay, the two diverge and `dofile` keeps using raw `_G` — escaping
  the guard entirely. Fix is one line — pass the env down, as the project-side `dofile` already does
  (`:1122-1123`) — but it must be *done*, not assumed.
- **Stated limits, so they are not discovered later:** the proxy guards `love.<key>` assignment, not
  mutation of nested tables reached through it (`love.state.x = …` still writes through); `_G.love`
  remains reachable as a deliberate escape hatch; and **`love.handlers` needs the same treatment or
  it is the open door** — `love.handlers.keypressed = f` reaches Layer 1 itself. Note
  `technical_debt/general.md` already records that `table.protect(love.handlers)` is a no-op, i.e.
  someone intended exactly this guard and it never took effect.

**(2) The input widget is provisioned at project *open*, not at run — even if unused.** This is the
first proposal that **reopens a shipped `#77` decision**, and it must cite rather than silently move
it: `ARC-01` chose the run seam **over** the open seam because `restart()` and the Ctrl+T
quickswitch call stop+run directly and **never re-open**, so a widget built at open survives into a
restart carrying the previous run's callbacks, text, config and shown-ness
(`internals/user_input.md`, *"Widget lifecycle"*). Moving the seam therefore needs a companion
**per-run state reset with the instance persisting**, against Decision 11's teardown invariant.
Second consequence: it makes question 6 **live** — with a widget existing while the console is
interactive, `compy.input.show()` from the REPL genuinely puts a second input surface beside the
console line, which is itself a `UserInputController` constructed `:always_shown()`
(`consoleController.lua:44`). Q6 must be answered as part of this change, not after it.

**(3) Required modules get a teardown path** (e.g. reset when another project is opened). Verified
defect this closes: `close_project` removes the project's loader from `package.loaders` but **never
touches `package.loaded`** (`:1417-1435`), and only `stop_project_run` evacuates. Since `require`
consults the cache before any loader, the sequence *open A → load modules without running → open B*
leaves B's `require('helpers')` returning **A's** module. Worse, `evacuate_required` is
non-recursive — `Project:contents()` → `FS.dir` → `getDirectoryItems` (`project.lua`,
`util/filesystem.lua:86-98`) — so **subdirectory modules are never evicted by any path**, stop
included. Coherence point to write down: under this design module caches are reset while console
symbols persist — two policies for one load, justifiable (a stale cache silently returns *wrong
code*; symbols are the user's stated intent) but it should be stated, not inferred.

**Assumption to record rather than ask:** a `run()` after a `dofile()` does not see the loaded
symbols — they are separate tables and nothing exchanges between them.

**Effect on the `#77` verdict:** unchanged for shipping — none of this lands before the PR. The
collision line moves from *documentation-only* to *documentation-only plus one shipped decision
(`ARC-01` / Decision 11) that the successor ticket must cite and amend*.

### 2.3 Sequencing — the real risk is not collision, it is overlap in time

`#77` is at PR assembly: the slices are cut and regeneration is deliberately last, because a tree
that moves invalidates them (`ROADMAP.md`, `PR-01`). The env work would touch
`consoleController.lua` — the single largest file in the input feature's diff — so **work landing on
this branch before the PR is cut re-cuts the slices**. There is also a downstream consumer standing
on this build (the platform's `serial` API, owner 2026-08-30).

Recommended order, for the owner's decision: **`#77` ships first; the env ticket is designed in
parallel and lands after.** The design pass costs nothing to start now and its main input — the
fourteen questions — is desk work. If urgency wins instead, the env work should start on a separate
branch that rebases after the merge, never interleaved into `#77`'s remaining rows.

### 2.4 Roadmap disposition — hand over, do not absorb

Per `agents/rules/roadmap.md` and session62's own mandate: a lifecycle question genuinely bigger
than `#77` must not be absorbed into `#77`'s plan to make it actionable. This one is bigger — it
touches environment construction, both `dofile` paths, the module cache, the state machine's
stop/restart/inspect transitions, and every document that describes them. It is **its own ticket**.

What `#77` should carry, at most, and only if the owner agrees:

1. **C4** as a `BUG` row (one guard + one test) — it stands on its own merits, ticket or no ticket.
2. A **pointer**, not a row: a line in the debt register's `compy.before_exit` entry and in the
   architecture principle recording that a filed ticket will settle the question they leave open —
   so a later reader does not re-derive it. **Omission is not a ruling**; if the owner declines, the
   reasoning is written down instead.
3. Two items the map surfaced that are **not** the input feature's and are cheap to record where
   they belong, for the owner to accept or decline:
   - the second site of the already-filed `table.protect` no-op — one sentence appended to the
     existing `technical_debt/general.md` entry, naming `_set_base_env` (`:1329-1332`);
   - `internals/console.md`'s two factual errors about `base_env` (protected; reset on stop /
     restart-is-clean) — a persistent-corpus doc stating the opposite of the code, on exactly the
     point this ticket turns on. Correcting it is a few lines and makes the ticket's first read
     trustworthy; leaving it is defensible only if the ticket will rewrite that section anyway.
4. Nothing else. In particular **no re-opening of `ARC-01`** (widget lifetime) — C1 is answered by
   spec or by a warning, not by giving the widget an application lifetime again.

---

## Part 3 — the fourteen questions to answer before the ticket is filed

This is the direct answer to *"Do you have any other requirements/expectations before a formal
ticket is filed?"*. Ordered: the first is the fork, 2–6 are load-bearing, the rest are edges that
will otherwise be discovered by users.

1. **One environment with save/restore, or two with a defined transfer?** (§1.2 — everything else
   depends on it. A third shape, the `__index` overlay, gets all three expectations from one
   mechanism and removes the copy hazard structurally; §1.3.)
2. **What exactly is "the interaction callbacks"?** Enumerate the set by name, once. Does it include
   `compy.input.hooks`, registered shortcuts, and widget shown-ness? (§1.4, C2)
3. **If the console keeps the project's symbols, what happens to the console's own prior symbols?**
   Replaced, or merged — and on a merge, what wins on a collision, what does a project's `foo = nil`
   mean, and what about tables mutated in place rather than assigned? (§1.2)
4. **Is `package.loaded` / `require` part of "the environment"** that R2 resets? (§1.5)
5. **Is non-Lua run state in scope** — cursor, key repeat, relative mouse, audio, canvas, terminal?
   Answering *yes* pays a registered debt entry; answering *no* is fine, but should be recorded.
   (§1.5)
6. **What happens on failure?** A `dofile`'d file that raises, and a project that raises mid-run:
   does the restoration still happen? ("upon return" vs *finally* — §1.5.)
7. **Which of these count as "running a project"** for R2's clean slate: a second `run()` on the
   project already open, `run("another")`, `Ctrl+Alt+R` restart, `Ctrl+T` quickswitch? Today they
   answer differently, and only the second is clean (Part 0.7) — the ticket should make one rule
   cover all four.
8. **What does the console read while a project is suspended (`inspect`), and after `continue`?**
   (§1.5)
9. **Is console `dofile` project-scoped or general?** Today it refuses without an open project and
   resolves through the project's mount. (§1.5)
10. **Is there one `love` table and one `compy` table per process after this, or still per-run
    copies?** This is the identity question the piercing practice exists for. (§1.3)
11. **What *is* the "well-defined default"** — a table frozen at boot, or re-derived per run? Does it
    include the project's own previously-loaded modules?
12. **Naming:** the contract refers to `quit()`; inside a project the symbol is `stop()`, and the
    console's `quit` quits the application. Settle the vocabulary in the ticket. (§1.5)
13. **May a console-extending project use run-scoped surfaces afterwards** — concretely, what should
    `compy.input.show()` typed at the REPL do? (C1)
14. **Is the specification itself a deliverable of the ticket** — a named section in the persistent
    docs that a user can be pointed at? (§1.1. The inquiry says "not even properly specified"; if the
    ticket closes without that section, the complaint outlives the fix.)
15. **Is "a console extension extends the vocabulary, not the interaction" the intended reading of
    R1 and R3** — or does the project owner picture `dofile`-loaded *interactive* helpers? *(Added
    2026-08-31, from the owner's reading of R1.)* This is the **largest sizing question on the
    list**: the second answer gives the ticket a hard dependency on Decision 1's unbuilt
    console/editor convergence, and that dependency should be stated at filing rather than
    discovered in implementation. (§2.2b)
