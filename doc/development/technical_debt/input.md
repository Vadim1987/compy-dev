---
description: Input subsystem debt — standing properties, open decisions, and anticipated items with their revisit conditions
status: active
audience: developer
authored: llm
reviewed: none
---

> REVIEW: drop everything resolved, actualize the list, and maybe make it a bit more comprehensive (less prose, more facts). ToC (list) at the beginning would also help
> REVIEW: absolutely no mentioning of particular commits is allowed, they will be reassembled for the PR

# Input subsystem

Keyboard/text/pointer routing, the console and project input controllers
(`src/controller/controller.lua`, `userInputController.lua`,
`projectInputController.lua`, `consoleController.lua`), and the project-facing
`compy.input` surface. Cross-reference: `internals/user_input.md`,
`../input_api.md`. "The input API" below means the `compy.input` surface
introduced in **1.0.0-rc20260712**.

Three groups below: standing properties (settled, just noted), open decisions
(the framework owner has not yet ruled), and anticipated items (may never need
action; revisit at the named point).

---

## Standing

### The Web build has no coverage, and carried a feature-era regression unseen

- **State:** nothing in `busted tests` exercises the `_G.web` branch, and the
  suite runs on LuaJIT, where the desktop branch works. A defect reachable
  only on the Web build is therefore invisible to every check this project
  runs.
- **The worked example, found 2026-08-03:** the dispatch chain introduced by
  `56c4284f` wrapped project keyboard handlers in a **bare**
  `xpcall(fn, handler, unpack(args))`, with no web branch. On PUC Lua 5.1 —
  what the Web build runs — `xpcall` drops the trailing arguments, so every
  adopted `love.keypressed` / `textinput` / `keyreleased` would have been
  called with nil for `key`, the held-key view and `isrepeat`. Before the
  feature there was exactly **one** `xpcall` in `controller.lua`, inside
  `wrap`'s guarded branch; the feature added a second, unguarded one. The
  wrapper collapse (`f1dc6aee`) removed it again, so the count is back to one
  — the regression is fixed, but it lived undetected for the whole feature
  because no check could see it.
- **Why it stands:** running the suite against PUC Lua 5.1, or building and
  driving love.js in CI, is infrastructure this project does not have, and
  neither is in this feature's scope.
- **Shape:** cheapest useful step is a lint or a review checklist item —
  **no bare `xpcall` with arguments in `src/`**; argument-forwarding goes
  through `wrap`. A grep is enough to enforce it and would have caught this.
- **Revisit:** if a Web build is released, or when CI grows a second
  interpreter.

### `wrap`'s error handler is called with the wrong arity, so project raises vanish (RESOLVED, 2026-08-03)

- **Resolution:** `wrap` binds CC in a closure used by both branches
  (`2554d2e3`), so a raise anywhere in project code now reaches
  `user_error_handler` and suspends the run. Three rows pin it — pointer,
  `love.update`, and a keyboard hook as the control that the other two are not
  asserting something impossible. Owner ruling: a certainly-wrong behaviour is
  not preserved on the grounds that changing it was never approved, even
  though it is pre-feature.
- **Where it was:** `src/controller/controller.lua`, `wrap` — the non-web
  branch was
  `return xpcall(f, user_error_handler, ...)`. `xpcall` invokes a message
  handler with exactly **one** argument (the error), but the signature is
  `user_error_handler(CC, msg)`. So `CC` binds to the error string, `msg` is
  nil, and `'user error: ' .. msg` raises *inside* the message handler, where
  `xpcall` swallows it. Nothing reaches `suspend_run`.
- **Measured effect** (probe run 2026-08-03, asserting the handler executed
  before the raise): a raise in a project's **pointer handler** or in its
  **`love.update`** runs the handler, then vanishes — no error window, no
  console line, `app_state` still `'running'`. A raise in a **keyboard hook**
  suspends correctly, because that path goes through `chain_native`, which
  binds CC in a closure (`xpcall(fn, function(m) user_error_handler(CC, m)
  end, ...)`) and gets the arity right.
- **`_G.web` is falsy on the desktop build, so the broken branch was the live
  one.** The web branch passed both arguments and never had the arity
  problem. Its own flaw — returning bare `r` where the other branch returned
  `xpcall`'s `ok, res...` tuple, so the `@return` annotation described only
  one of them — was fixed alongside the wrapper collapse (`f1dc6aee`).
- **Why the web branch exists at all, established 2026-08-03:** it is not a
  stylistic duplicate. `xpcall(f, h, ...)` forwarding arguments to `f` is a
  LuaJIT / Lua 5.2 extension; PUC Lua 5.1 takes exactly two arguments and
  drops the rest, so on that runtime every handler would be invoked with nil
  for all of its parameters. `pcall(f, ...)` forwards on both. Measured here:
  LuaJIT gives `1, 2`; 5.1 semantics give `nil, nil`. The branch is therefore
  **load-bearing and must not be collapsed away** — a warning to that effect
  now sits on it in code.
- **Reach at the time:** `wrap` had three call sites — `wrapped_native`
  (pointer handlers), the loader, and the project `update` wrapper — plus
  `CC:wrap_handler`, which took `wrap` as its error handler, for the compy
  click handlers. All of those except the loader and the update wrapper have
  since been replaced by `guarded`.
- **Pre-feature, verified:** `wrap` and `user_error_handler` are
  byte-identical at the PR base `3256aac`. The input API neither introduced
  nor worsened this; it only made the contrast visible, because the keyboard
  chain's own wrapper does it correctly.
- **Consequence for the docs:** "A raise from project top-level and from a
  handler surface differently" (below) describes the handler path as
  reaching the error window. That holds for keyboard hooks only.
- **Kept as a closed entry** because two things in it are still live
  knowledge: why the web branch exists (above), and the fact that this
  subsystem's error path had a defect no test could see for the length of the
  feature — the argument for the Web-coverage entry that opens this section.

### A project that raises leaves global device state dirty; no force-reset exists

- **State:** the sandbox deep-clones the `love` table but shares leaf C
  functions, so a project's imperative `love.*` calls — `setKeyRepeat`,
  `setTextInput`, `setRelativeMode`, raw audio — mutate real SDL/LÖVE state.
  The only mechanism that restores any of it is the project's own
  `compy.before_exit`, and by ratified contract that hook fires on **stop**
  paths only; crash is explicitly out of its scope. A project that mutates
  global state in top-level code and then raises therefore never restores it:
  `run_project`'s failed-run branch drops to `project_open` without ever
  calling `stop_project_run`, so nothing fires, and the dirty state bleeds
  into the next run. `examples/keyboard` is the canonical mutator — it calls
  `love.keyboard.setTextInput(true)` and `love.mouse.setRelativeMode(true)`
  at startup. *(This entry used to name `setKeyRepeat(false)` there; that
  call has never existed in that repo's history — checked with `git log -S`
  across all refs. The platform's `src/main.lua:297` is the only
  `setKeyRepeat` caller and it turns repeat **on**, corrected 2026-08-12.)*
- **Why it stands:** two separate rulings, both deliberate. The hook is scoped
  to stop paths by design — crash/hard-kill was called out as a later layer,
  not an oversight. And firing a *partially initialised* project's teardown
  was ruled against (owner, 2026-08-03): no proper start, no contract is
  expected to run. Resetting the slot is a different question and IS done —
  a dead project's hook must not survive to fire against the next project's
  state (fixed 2026-08-03, `226628ae`).
- **Shape:** a framework-owned **force-reset** of the global surfaces the
  sandbox shares, run on every run-ending path including the crash ones, and
  independent of `compy.before_exit` — a project that crashed cannot be
  trusted to clean up after itself, which is exactly why its own hook is the
  wrong instrument here.
- **Revisit:** owner ruled 2026-08-03 to record it and implement the
  force-reset later; revisit when that work is scheduled.
- **The stop path is project-by-project until then (2026-08-12).**
  `examples/keyboard` now restores relative mode in its own
  `compy.before_exit` (P-18-05), which closes the leak for that project on
  every stop path and for no other. The framework-side question — should the
  platform tear down device modes a project changed, rather than trusting
  each project to — is the "Shape" bullet above, and is not answered by that
  fix. It is worth noting that the example's comment asserted for months that
  *"the runner restores it on exit"*: a project author's reasonable
  assumption about a platform that in fact restores nothing.
- **Where it goes when built (2026-08-07):** `framework_before_exit`
  (`consoleController.lua`) is now the framework's own teardown function and
  the only caller of a project's hook (Decision 28). It is the seam this entry
  has been describing — a framework-owned step, adjacent to but independent of
  `compy.before_exit`. Note the crash path still does not reach it: it calls
  `reset_before_exit` only, deliberately, since a partially initialised project
  runs no teardown. Wiring the force-reset means calling the framework half on
  the crash path too, which is a decision this entry does not pre-empt.

### `compy.before_exit` is absent from the persistent API docs (RESOLVED, 2026-08-03)

- **Resolution:** documented as `doc/input_api.md`, "Stop hook —
  `compy.before_exit`" (owner ruled 2026-08-03), covering signature, ignored
  return, timing before framework teardown, which stop paths fire it, that a
  raise is **not** one of them, and the reset. Every clause is pinned in
  `tests/input/input_route_lifecycle_spec.lua`; the not-fired-on-raise claim
  was mutation-checked rather than read.
- **What it was:** a public, project-settable lifecycle slot whose only
  specification lived in the feature's ephemeral working tree, which is
  scheduled for deletion — while the PR is meant to be reviewable from
  `doc/input_api.md` plus the description alone. The entry above also depends
  on that contract being findable.

### Future input unification (RESOLVED, 2026-08-03)

- **Resolution:** done, and in the direction this entry doubted. Every
  channel — keyboard, text, pointer, and the derived singleclick/doubleclick
  events — routes through one chain with one error boundary and one lifetime
  (`../decisions/input.md`, Decision 25). The derived clicks did fold into
  hooks: `compy.singleclick` is gone and `compy.input.hooks.singleclick`
  replaces it.
- **Where this entry was wrong, worth keeping:** it recorded the asymmetry as
  predating the input API. It did not. At the PR base every event installed
  through one path and none was released before stop; the split was
  introduced by this feature (Decision 11, amended). The entry then reasoned
  from the false premise to "folding clicks into hooks would falsely imply" a
  shared contract — when a shared contract was in fact the pre-existing state.
- **What genuinely remains unproven** and is recorded separately: pointer
  combos, and whether a shown widget should consume clicks within its bounds.
  See "Pointer delivery is an unstructured broadcast" below.

### Project-handler wrapping: dedup the guard, drop the misleading `keyboard_` name (RESOLVED, 2026-08-03)

- **Resolution:** the two builders are one. `chain_project_handler(CC, fn)`
  wraps, `project_handler(userlove, CC, key)` guards, and both the keyboard
  participants (`project_handlers`) and the pointer installs (`hook_pointer`)
  use it. The guard exists once. `wrapped_native` / `keyboard_native` /
  `chain_native` are gone, and with them the `native` label and the
  keyboard-specific name on a function that was never keyboard-specific.
- **What made the collapse possible:** the split was justified by return
  policy — `CC:wrap_handler` discards the return by construction, and a chain
  participant's return is its consume signal. That was never a real
  constraint: a returning wrapper is usable where the return is ignored,
  which is exactly what a pointer handler installed on `love.*` does. The
  genuine obstacle was that the two paths had *different error handling*, one
  of which was broken — see the arity entry above, fixed first so the
  collapse could be behaviour-preserving rather than a fix in disguise.
- `CC:wrap_handler` survived this step for the compy single/double click
  handlers, then went with them when the clicks became ordinary events
  (Decision 25). Nothing wraps project code any other way now: `guarded`
  (`controller.lua`), applied where a route is entered, is the only one.
- **Verified behaviour-preserving:** suite 911/0/0/3 across the change, and
  the pointer path now propagates a return value that both `love.handlers`
  and the poll loop discard.
- **What it was:** two builders adapting a project's own `love.*` handlers —
  `wrapped_native` (via `CC:wrap_handler`, return discarded, installed
  straight onto `love.*` by `hook_pointer`) and `keyboard_native` (via
  `chain_native`, return propagated, seeded as `hooks[event]` by
  `occupy_keyboard`) — carrying the **identical** guard
  (`orig and new and orig ~= new`) and differing only in the wrapper they
  called. `keyboard_native` was misnamed: nothing about it was
  keyboard-specific. Deferred out of the D5 vocabulary rename (2026-07-21)
  on the reasoning that renaming under a mechanical sweep would either bless
  the smell with fresh names or smuggle a behaviour-touching refactor into a
  rename commit — which is why it waited for a pass of its own.

### `love.handlers.userinput` is dead code (RESOLVED, 2026-08-07)

Deleted, with the local `clear_user_input` that existed only to feed it. Both
`love.event.push('userinput')` sites were present at the PR base
(`3256aac:userInputModel.lua`) and were removed by this feature, leaving the
consumer installed — the same shape as `wrap_handler`. Kept as a resolved entry
because the pattern recurs: when a producer goes, grep for its consumer.

### `compy.before_exit` is a closure slot

- **Where:** `src/controller/consoleController.lua`, `get_compy_namespace` —
  `before_exit` is a metatable-intercepted upvalue rather than a field of the
  namespace table.
- **State:** `table.clone` copies with `pairs` and reuses the metatable **by
  reference**, so a closure-captured slot is invisible to the copy and every
  clone of the namespace shares one variable. `base_env.compy.before_exit` and
  `project_env.compy.before_exit` are therefore the same slot, permanently. A
  plain field would be deep-copied per clone instead.
- **Why it stands:** Nothing tests, documents or depends on the sharing, and
  the suite passes with a plain field — so on its own it reads accidental. But
  `compy.input` survives cloning by the *same* mechanism, so a plain field
  would make `before_exit` the odd member of the namespace, and the sharing may
  be load-bearing for a path not yet identified.
- **Revisit:** Decide whether the sharing is intended. If it is, say so where
  the slot is built; if not, a plain field is simpler. Evidence, with probe
  transcripts: the frozen-surface audit run in session27.
- **Not to be confused with** the crashes fixed on 2026-08-07: the call site is
  now guarded against both an absent hook and a raising one, which is orthogonal
  to how the slot is stored.

### A truthy `hooks[event]` return silently disables `on_limit_reached`

- **Where:** `src/controller/projectInputController.lua` (the free-function
  `dispatch`) — `hooks[event]` runs before the widget; `userInputController.lua`
  (`emit_limit`) fires `on_limit_reached` only from inside the widget itself.
- **State:** A project that sets `compy.input.hooks.keypressed` (or the
  text/release siblings) and returns truthy consumes the event at the
  hooks step, so `dispatch` never reaches the widget and the widget's
  `on_limit_reached` callback never fires for that keystroke — no
  error, warning, or other signal marks the drop. Carried through the
  input-API redesign unchanged — renamed from the old tier-3/tier-4
  vocabulary to hooks/widget, but the underlying coupling is the same.
- **Why it stands:** The truthy-consume shape (decisions/input.md,
  Decision 2) is working as designed; it just wasn't checked against
  this specific hooks/widget interaction. No dedicated guard exists.
- **Revisit:** Note the coupling wherever `on_limit_reached` is
  documented for project authors, or decide it needs a guard.

### Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)

- **Where:** `consoleController.lua` `run_project`
  (`consoleController.lua:260-269`), `controller.lua`
  `user_is_interactive` (`controller.lua:1112-1113`),
  `user_pointer` / `hook_pointer` (`controller.lua:68`,
  `:238-249`), `set_default_handlers`
  (`controller.lua:778-824`, resets `user_pointer`), and
  `love.quit` (`controller.lua:733-758`).
- **State (old, broken behaviour):** A non-blocking project (no
  `update`/`draw` hooked) always dropped to `'project_open'` with
  the project route unconditionally released
  (`release_keyboard_route`). For a project whose entire UI was
  the input widget (`examples/guess`) or a pointer handler
  (`examples/sapper`), this meant (1) submit was dead — typing
  still reached the widget but Enter never fired, because
  submit/cancel (then a non-overridable framework tier, since
  retired — Decision 2) lives in the *project*
  route, which `project_open` disconnected — and (2) Ctrl+Esc quit the whole
  app instead of returning to the console, because `love.quit`
  only stopped-to-console while `app_state == 'running'`.
- **Confirmed pre-existing:** this was verified byte-identical on
  `master` (pre-`0022004`) — not an input-API regression. The
  `release_keyboard_route` call site is new in 1.0.0-rc20260712
  (route-lifecycle rework, AC-27/28), but the lifecycle split it
  slots into predates the feature.
- **Resolution:** owner ruled (a) — an input-only / pointer-only
  project is "live" without hooking `update`/`draw`. New
  predicate `Controller.user_is_interactive()` returns
  `love.state.user_input ~= nil or user_pointer`, where the
  module-local `user_pointer` flag is set in `hook_pointer` when
  a project installs any pointer/click handler and reset in
  `set_default_handlers`. `run_project` now releases the keyboard
  route only when `not user_is_interactive()` — an interactive
  non-blocking project keeps the project route, so submit/cancel
  keep working (`app_state` still becomes `'project_open'`
  either way, since quickswitch relies on that). `love.quit` now
  stops-to-console for `app_state == 'running'` OR
  (`'project_open'` AND `user_is_interactive()`); an idle console
  (`'project_open'`, nothing interactive) still lets the app
  quit.
- **Carried-forward limitation:** a non-blocking project with
  *no* interaction surface at all (no widget shown, no pointer
  handler, no update/draw) still gets `release_keyboard_route` —
  the keyboard goes back to the console. This is intended, not a
  gap: such a project has nothing left to be interactive with.

---

## Open decisions

The framework owner has not yet ruled on these; each is recorded as an open
question, not resolved here.

### `compy.keys_pressed` is not exposed to projects (RESOLVED, 2026-08-03)

- **Where:** the project-facing `compy` namespace (`consoleController.lua`,
  the function that assembles it) exposes `terminal`, `audio`, `graphics`,
  `fonts`, `input`, and a `before_exit` slot — no `keys_pressed`. Held-key
  access exists framework-side (`Controller.keys_pressed`, the `held_keys()`
  read-only pressed-keys view) and via the per-event callback argument, but a project cannot poll
  currently-held keys from inside its own `update()`.
- **Why it stands:** Open design question — expose a read-only held-key view
  to projects, or treat callback-arg access as the sanctioned shape and amend
  the documented contract to say so explicitly.
- **A real consumer now exists, and it rules out the second option**
  (2026-08-03): the `keyboard` example maintains its own `INPUT.held` /
  `INPUT.shift` mirror and reads it **during draw**, to decide whether to
  render shifted key labels. A per-event argument cannot serve a per-frame
  renderer, so callback-arg access alone is insufficient for any project that
  *renders* held state rather than reacting to it.
- **Resolution:** owner ruled to expose it — `compy.input.keys_pressed`
  (`../decisions/input.md`, Decision 20), the same read-only view the chain
  hands participants, resolved per access so it cannot go stale. Placed on
  `compy.input` rather than at the top of `compy`: it is input state, and the
  input guide is where a reader looks for it.
- **Resolution superseded** (`../decisions/input.md`, Decision 30): the view is
  dissolved and no held-key surface is exposed. **The need this entry recorded
  is still met, by a different answer** — the renderer that ruled out
  callback-arg access asks the device instead (`love.keyboard.isDown`), which a
  per-frame draw can do as freely as a handler can. The entry stays RESOLVED;
  only what resolves it has changed.

### Shortcuts key-repeat semantics are shipped unsettled (RESOLVED, 2026-08-03)

- **Where:** `src/controller/projectInputController.lua`, `:keypressed` —
  `isrepeat` is threaded through to `hooks[event]` dispatch only; `shortcuts`
  fire on every OS key-repeat with no `isrepeat` gate.
- **Why it stands:** Whether shortcuts dispatch should also gate on
  `isrepeat` (fire once per physical press) or intentionally fire on every
  repeat is an open behavioural call, shipped open by design.
- **The first real consumer wants once-per-press** (2026-08-03): `keyboard`'s
  reserved chords (`shift+escape`, `ctrl+alt+up`/`down`) are now shortcuts,
  and each wraps itself in a `if not isr then … end` gate — otherwise holding
  `ctrl+alt+up` ramps the notch every frame. The flag *is* delivered to
  shortcuts, so the workaround is three lines; the question is whether every
  consumer should have to write them.
- **Resolution:** owner ruled that dispatch keeps firing on every repeat and a
  binding opts out for itself — `compy.input.fn.ignore_repeat(fn)`
  (`../decisions/input.md`, Decision 22), with `fn.stop_here` alongside it
  when the binding also claims the key (Decision 24). Filtering inside the shortcut tier
  was rejected for two reasons: it suppresses with no way to recover a
  hold-to-act binding, and it would leave the same hand-written check in
  `hooks.keypressed`, where commands are equally idiomatically bound. The
  wrapper has one signature and composes across all three tiers.

### No public `is_active()`-shaped visibility query (RESOLVED, 2026-07-31)

- **Where:** the `compy.input` project surface (`consoleController.lua`) had
  no `is_shown`/`is_active`/`is_visible`, though an internal
  `UserInputController:is_shown()` existed.
- **State (old), and worse than this entry recorded:** the entry said example
  projects read `love.state.user_input` directly, as if that were a working
  workaround. **It is not.** A project's `love` is a sandboxed deep clone
  (`../internals/project_sandbox_env.md`), so `love.state.user_input` read
  from inside a project is always `nil` — the framework writes the real
  global, the project sees its copy. `examples/maze/main.lua:497` guards a
  re-show with exactly that read: dead code that never fires, which is why
  maze re-shows the widget on every tick.
- **Resolution:** owner ruled to expose it —
  `compy.input.is_shown()` (`../decisions/input.md`, Decision 18), returning
  the widget's own flag so it cannot drift from the one the dispatch walk
  reads. Used by `examples/turtle` for its open-only-if-closed guard.

### On the console route, a hidden widget's input falls to the console line (RESOLVED, 2026-08-03)

- **Resolution:** settled by construction — the console route no longer has a
  widget step at all. The three `forward_*` functions that implemented it were
  deleted, so every keyboard/text event on that route goes to `CC:keypressed` /
  `CC:textinput` (the console line, or the editor fork), hidden widget or
  shown. Decision 1's "widget visibility is never a routing condition" now
  holds on both routes. The two routes still read differently — the project
  route ends an unclaimed event in the chain, the console route ends it in its
  own input surface — but that is each route's own terminal, not two answers
  to one question.
- **The rows that pinned it are re-sited, not deleted** (2026-08-03). They had
  gone vacuous: with no widget step on the console route, a *shown* widget
  would have satisfied them there too. On the project route a hidden widget is
  a real decision — the walk skips it and reports not-consumed — so they now
  discriminate on the widget's own text, with a third row as the control that
  the same keystroke edits a shown widget. The `#disputable` tag is gone: the
  question it marked is answered, not merely pinned.
- **Where it was:** `src/controller/controller.lua` — `forward_keypressed` /
  `forward_textinput` / `forward_keyreleased` handed the event to the widget
  only while `love.state.user_input` was set, which `hide()` clears; the
  console-route defaults then fell back to `CC:keypressed` / `CC:textinput`.
- **Why it stands:** The general principle — *input the widget declined
  should have no effect* — was ruled for the **project** route only:
  Decision 11 ("Changed baseline behaviour", `../decisions/input.md`) gives
  a running project's route every keyboard/text event, so an event no
  shortcut, hook, or shown widget takes simply ends there, instead of
  accumulating in the console behind the project's screen. The **console**
  route kept the old shape, and it is not obviously wrong there: the console
  line is that route's own input surface, so "the widget is down, type into
  the terminal" is arguably the correct reading, not a leak. What is unruled
  is whether the two routes should read the same way.
- **Reachability:** No leak path through a *running* project is known today
  — the running case is Decision 11's, and the `project_open` case is
  narrowed by ruling (a) above (`user_is_interactive`), which keeps the
  project route for any project with a widget or a pointer handler. The
  open question is therefore a contract question first: two routes, two
  answers to the same question, only one of them written down.
- **Revisit:** At the next ruling pass over route symmetry — either sanction
  the console fallback explicitly in the contract doc, or give the console
  route the project route's "declined means no effect" shape.

### A raise from project top-level and from a handler surface differently

- **Status:** owner ruled (2026-07-31) to leave the behaviour as-is and refer
  the question to stakeholders; recorded here with the options as ruled.
- **Where:** `consoleController.lua` `run_project` / `run_user_code` versus
  `controller.lua` `user_error_handler`.
- **State:** the same authoring error reaches the author two different ways,
  decided by which `pcall` catches it. Raised from **top-level project code**:
  `run_user_code`'s `pcall` returns, `run_project` prints `'Error: ' .. msg`
  and drops to `project_open` — one console line, the project still open,
  nothing else on screen. Raised from a **`love.*` handler or hook**: `wrap`
  → `user_error_handler` → `suspend_run(msg)` → the error window over the
  project's last frame.
- **Why it matters:** balloons (smoke report 5) passed a lifecycle callback
  inside `show{}`, which Decision 15 makes a raise. The raise printed its line
  and left the user "in a console that gave no signal they were still inside a
  project" — which is the failure mode Decision 15's own rationale ("explicit
  failure mode") is meant to prevent.
- **Options:** (a) route a top-level raise through the same suspend/error
  window path as a handler raise — one failure surface for one class of
  failure; (b) keep the console line but make the state legible (name the open
  project and how to leave it); (c) leave as is. **Recommended: (a)** — the
  asymmetry is an accident of which `pcall` caught it, not a decision anyone
  took, and (b) preserves the accident while adding words to it.
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### The error lock is correct, documented, and hostile

- **Status:** owner ruled (2026-07-31): behaviour is pre-feature, so leave it;
  record the UX concern with options for stakeholder review.
- **Where:** `userInputController.lua` — while `model:has_error()` holds,
  `textinput` is dropped and `keypressed` is swallowed except Enter / Space /
  arrows, which clear the error.
- **State:** to a user this is a freeze with no stated exit. It is what
  smoke reports 1 (guess, "froze after entering a symbol") and 9 (valid,
  "entering '1' stops processing any input") describe. The error band itself
  IS rendered and, since the `input_widget_overlay` paint fix, IS visible; nothing in it says
  which keys resume.
- **Pre-feature check (asked for at the ruling):** nothing to reproduce. At
  the PR base `3256aac` the same lock exists and is **stricter** — only Enter,
  Up and Down cleared it, where today's also accepts Left, Right and Space.
  The band's invisibility was equally pre-existing (same render path, same
  unpainted `input_widget_overlay`). The input API neither introduced the lock nor narrowed
  its exits; it widened them.
- **Is the widening drift? No — it is the ratified behaviour, and it also
  matches what the docs already claimed.** The frozen design (`§10 Edge
  cases`) reads "input locked until acknowledged **(Enter/Space/arrows)**",
  and the widening landed under that AC with the reason in its commit message
  (`9bb6d29`, "Widen the sink's has_error() lock-clear gate to
  Space/Left/Right"). It is not a side effect of the 2D cursor/limit work —
  no other commit touches that key list. Independently, `internals/user_input.md`
  described the exit set as "Enter, space, or arrow keys" **at the PR base**,
  while the code did Enter/Up/Down: the change aligned code with both the spec
  and the doc. Narrowing it now would be a design change to a frozen document,
  not a drift fix.
- **The quirk worth naming:** an arrow key *acknowledges* the error and is
  then swallowed — it does not also move the caret to the offending character,
  which is what a user pressing Left after "not allowed" is trying to do. And
  `keyreleased` clears on Space as well, so Space acknowledges twice
  (harmless, but the two handlers duplicate the rule).
- **Options:** (a) append a hint line to the rendered error band ("Enter or
  Space to continue") — smallest change, no semantics touched;
  (b) clear the error on the next `textinput`, which makes a rejected line
  silently editable and drops what the lock is for; (c) leave it documented
  only. **Recommended: (a)**.
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### `repl` does not evaluate, and its name says it does

- **Status:** owner ruled (2026-07-31): behaviour is pre-feature, so keep it;
  record the UX concern for stakeholder review.
- **Where:** `src/examples/repl/main.lua`.
- **State:** the example prints each submitted line back — `on_text_entered`
  pipes lines to `print`, and the widget runs the plain-text evaluator
  (`InputEvalText`), which has no parser. `x = 2 + 3` returns the characters,
  not a binding.
- **Pre-feature check (asked for at the ruling):** the same. At `3256aac` the
  example is `r = user_input()` plus an update loop doing `input_text()` /
  `print(r())` — reprint, not evaluate. The migration preserved the behaviour
  exactly.
- **Why it is a concern anyway:** evaluating Lua and printing a result is what
  the **console** does, and until the two fixes of 2026-07-31 (a refused
  widget after a project stop, and an `input_widget_overlay` that was never painted at all)
  a project's input surface was visually indistinguishable from the console —
  same input line, no signal. An author testing `repl` could reasonably
  believe it evaluated, having been typing at the console. Both causes are
  fixed, so the modes now look different; the name still promises a
  read-**eval**-print loop the example does not provide.
- **Options:** (a) make it evaluate — the project env already exposes `eval`,
  so it is one line in `on_text_entered`; (b) keep the echo and rename the
  example (`echo`); (c) keep both, documented as-is (today's state).
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### A widget opened from a key can receive that key's own echo

- **Status:** answered by a **documented project idiom**, not by a framework
  mechanism (owner, 2026-08-03) — `../../input_api.md`, *"Opening the input widget
  from a key"*, pinned by `tests/input/input_widget_control_spec.lua`, group
  *"the documented echo guard"*, and used by `src/examples/turtle`. A
  framework fix was implemented and then reverted (2026-08-01) because its
  design had never been ruled. What remains open is whether the framework
  should ever take this over; the entry stays for that question.
- **Where:** `src/controller/controller.lua` (the `keypressed` / `textinput` /
  `keyreleased` gateways) and `src/controller/userInputController.lua` (the
  show path and the three widget handlers).
- **State:** LÖVE delivers a `keypressed` **and** a `textinput` for one
  physical key and guarantees nothing about their order. A project that opens
  the widget from a key therefore races its own trigger: measured — open on
  `keypressed('i')`, and the `textinput('i')` of the same press lands in the
  field, so the widget comes up already containing `i`. Opening on
  `keyreleased` (what `examples/turtle` does) is safe only because the echo
  usually arrives first; with the `textinput` delivered last it fails
  identically.
- **Why a project cannot fix it for itself:** it would have to consume a
  `textinput` whose text it cannot derive from the key name (`space` → `" "`,
  `shift+i` → `"I"`, anything an IME emits), and every project that opens a
  widget from a key would re-implement it.
- **Options:** (a) seal the widget for the rest of the event batch that
  opened it, released at the start of `love.update` — order-independent and
  needs no key→text mapping, but it also swallows an unrelated key typed
  within the same frame and assumes the stock run loop is the only pump;
  (b) match the trigger key's echo specifically — narrower, but needs the
  key→text mapping (a) avoids; (c) arm only on `keypressed`, leaving
  open-on-`keyreleased` projects racing; (d) no framework change, and the API
  documents an idiom projects follow instead — the workable one being a
  **paired shortcut**: register the trigger on both channels, where
  `shortcuts.keypressed[combo]` opens and `shortcuts.textinput[combo]`
  swallows the echo and unregisters itself, re-armed by whatever closes the
  widget. Verified in both delivery orders. Its two limits: the re-arm has no
  single home (Escape clears without hiding, and there is no close callback),
  and it is confined to **bare** combos by the case defect recorded under
  *"`combo_string` does not normalise the case of a textinput token"*.
- **Revisit:** a design pass on the run loop's event-batch guarantees — the
  choice between (a)–(d) turns on what the framework is willing to promise
  about batch boundaries, which is a design question, not a bug fix.

---

### Combo triggers are key-name-only; positional bindings have no vocabulary

- **Where:** `src/controller/controller.lua`, `combo_string` — a combo's
  trigger is the LÖVE **key name**, which is layout-dependent, and the
  scancode is discarded at the gateway (`set_love_keypressed`:
  `local function keypressed(k, _, isr)`), so it reaches neither the routes
  nor the dispatch chain.
- **State:** compy has both audiences and serves only one. *Mnemonic*
  bindings — `ctrl+s` for save, `examples/turtle`'s `i` for input — want the
  key name, because the user's keycap says S. *Positional* bindings — a
  game's WASD — want the scancode, because on AZERTY `w` bound by name lands
  under the player's little finger. LÖVE exposes both for exactly this
  reason; the input API exposes only the first.
- **Why it stands (owner ruling, 2026-08-03):** not now, and **never as a
  swap** — a swap fixes one audience by breaking the other. No layout
  complaint exists in the record; this is a hypothesis about non-QWERTY
  users, not a report from one. Any future answer is **additive**: a second
  registration vocabulary (`shortcuts.scancode.*`, or an `sc:` prefix inside
  the combo string), never a change to what an existing combo means.
- **Also note it cannot help the textinput channel at all:**
  `love.textinput(text)` carries no scancode — one string, the character
  produced after layout, modifiers and IME. So scancodes cannot unify the
  keyboard and text channels; they would widen the gap between them.
- **Cost, if it is ever taken:** threading the scancode from the gateway
  through `forward_*` and the routes to the chain, and a scancode-keyed held
  set — `combo_string` builds its modifier prefixes from key names, so a
  scancode combo would otherwise be a hybrid (modifiers by name, trigger by
  position).
- **Revisit:** when a project needs layout-independent positional keys.


### A bare `*` shortcut is legal, and ruled that it should not be (RESOLVED, 2026-08-03)

- **Resolution:** `check_combo` (`src/util/key.lua`) now raises on a `*`
  trigger with no modifiers, naming the alternative in the message ("for every
  key, use `compy.input.hooks`"). Decision 21 and `doc/input_api.md` carry the
  rule, and two rows pin it — the raise, and the control that `shift+*` is
  still accepted, so the check cannot pass by rejecting classes generally.
- **What it was (measured 2026-08-03):** `shortcuts.keypressed['*']`
  registered without raising and caught every **unmodified** key — `q` fired
  it, `ctrl+s` did not, that belonging to the `ctrl+*` class. Coherent with
  Decision 21 (a class is its modifier set exactly, and the empty set is a
  class), but undocumented, untested, and a second spelling for what a hook
  already expresses.
- The entry was kept here rather than in `../decisions/input.md` while it was
  unimplemented, deliberately: a ratified entry describing behaviour the code
  lacks is the exact error this phase spent a session undoing.
- Corrected while closing: the session25 claim that the multi-trigger raise
  "settles whether a bare `*` is legal" was wrong. It permitted it.


## Anticipated — revisit at the named point, close only if warranted

Not commissioned for closure; each may never need action.

### A multi-trigger combo is silently truncated at registration (RESOLVED, 2026-08-03)

- **Where:** `src/util/key.lua`, `normalize_combo` / `split_combo` — the
  trigger is "the last non-modifier token wins", with no complaint about the
  earlier ones.
- **State (measured 2026-08-03):** `ctrl+a+b` is stored as `ctrl+b`, and
  `a+b+*` is stored as **`*`** — a string an author wrote to mean the
  narrowest possible binding registers the widest possible one. Nothing warns.
  The grammar is *modifiers plus exactly one trigger*: `combo_string` prepends
  only the four modifier classes, so a held non-modifier key never enters the
  combo string at all (measured: `a` and `b` held, `b` pressed → `ctrl+alt+b`,
  no trace of `a`). Multi-key chords are outside the grammar; a project that
  wants "a and b held together" asks the device for the second key inside the
  hook or shortcut that handles the first (`doc/input_api.md`, "Choosing the
  mechanism"). Reconstructing it from a pair of flag-setting shortcuts is
  **not** the answer — that shape is now named as an antipattern there.
- **Resolution:** registration now **raises** on a combo naming more than one
  trigger, or none (`../decisions/input.md`, Decision 21) — the same treatment
  `show`/`configure` give an unrecognised key. `a+b+*` no longer registers the
  widest possible binding; it is refused with the legal shape in the message.

### A combo table cannot express a modifier-class rule (RESOLVED, 2026-08-03)

- **Where:** `compy.input.shortcuts[event]` (`../decisions/input.md`,
  Decision 8) — `Key.new_handler_table`, an exact canonical lookup keyed by
  one full combo string.
- **State:** every binding names one combo, and dispatch is one exact lookup
  of `combo_string`'s output. A project that wants "**every** `alt+x` is a
  chord, swallow it whatever `x` is" has no sanctioned way to say so; it needs
  an entry per key, or it keeps that rule in a hook and tests the modifiers by
  hand. Found by the `keyboard` migration (2026-08-03), which moved its three
  named chords to shortcuts and kept `appChord` — its Alt-class rule — as a
  hook for exactly this reason.
- **The table is not sealed, though** (measured 2026-08-03):
  `Key.new_handler_table` sets no `__metatable`, so a project can reach the
  metatable and add an `__index`, and dispatch's plain lookup then consults it
  on a miss — a working wildcard, in three lines. It is undocumented, it would
  break the moment the table is sealed, and a reader would take it for a bug.
  Recorded because it shows the mechanism exists, **not** as an idiom.
- **A wildcard would have to answer more than it looks:** precedence against
  an exact binding, whether the matched trigger is passed to the handler, and
  the modifier's own press — holding Alt and pressing nothing else dispatches
  the combo **`alt+lalt`**, since `combo_string` prepends the held modifier to
  a trigger that *is* that modifier. A naive `^alt%+` pattern matches it.
- **Resolution:** owner ruled a sanctioned form — a trailing `*` binds the
  modifier class (`../decisions/input.md`, Decision 21). `alt+*` is every Alt
  chord; exact bindings win, the class is consulted only on a miss, and it
  never matches the modifier's own press. The three questions above are
  answered by it: precedence is exact-first; the trigger is already the
  handler's first argument; and a class does not match when the trigger is
  itself a modifier. The unsealed-metatable route above is superseded — do
  not use it.
- **Still true, and now documented rather than implicit:** the class form is
  about a *modifier* class. Combos of ordinary keys (`a+b`) remain outside the
  grammar by design, since including held non-modifiers would make every
  binding conditional on nothing else being held. That case is a hook that
  asks the device for the rest of the chord (`doc/input_api.md`, "Choosing the
  mechanism").

### A keyboard-hooks-only project does not count as interactive

- **Where:** `src/controller/controller.lua`, `user_is_blocking()` /
  `user_is_interactive()`, consulted by `ConsoleController:run_project` after
  the project's top-level code runs.
- **State:** the route is kept when the project replaced `love.update` or
  `love.draw` (blocking), or when it has a widget or a pointer handler
  (interactive). Keyboard hooks are neither. So a project whose only
  interaction surface is `love.keypressed`/`keyreleased`/`textinput` — no
  draw, no update, no widget, no pointer — hands the keyboard back to the
  console, and the hooks the framework captured for it (Decision 10) can
  never fire. `examples/keyboard` is *not* an instance: it defines
  `love.update` and `love.draw`, so it is blocking and keeps the route.
- **Why it stands:** hypothetical. No such project exists in the tree, and one
  would be invisible by construction — its only outputs would be sound or
  console text.
- **Revisit:** if a keyboard-only project appears, or when ruling (a)'s
  "interaction surface" definition is next revisited; the fix would be to
  count seeded hooks alongside the widget and pointer tests.

### Combo-string dispatch allocates a table per call — RESOLVED 2026-08-16

- **Where:** `src/controller/controller.lua` — `combo_string` built a `parts`
  table and `table.concat`ed it on every call, on the per-keystroke dispatch
  path.
- **Resolved** (`737d8316`): it now accumulates the string directly, so no table
  is allocated. A reused module-level buffer was the other candidate and was
  **declined** — it trades the allocation for shared mutable state in a function
  that would then have to never be called re-entrantly.
- **What remains, and it is smaller:** `find_shortcut`
  (`src/controller/projectInputController.lua`) calls `combo_string` **twice** on
  a miss — once for the exact combo, once for the `'*'` class — so one event can
  ask the device six times instead of three. Reusing the first walk needs either
  a parameter on `combo_string`, cached state, or a second copy of Decision 8's
  precedence logic; all three were judged worse than the cost.
- **Revisit:** with the `'*'`-class lookup, if combo dispatch ever lands
  somewhere genuinely hot.

### `combo_string` does not normalise the case of a textinput token

- **Where:** `src/controller/controller.lua`, `combo_string`; the
  registration side is `Key.new_handler_table`'s normalising `__newindex`
  (`src/util/key.lua`), which lower-cases through `normalize_combo`.
- **State:** An upper-case *textinput* combo token cannot match a
  registration, because registration lower-cases and dispatch does not.
  Measured (2026-08-03) with `shift` held and `I` typed: dispatch looks up
  `shift+I`, while `shortcuts.textinput['shift+I']` is stored as `shift+i`.
  The slot is therefore **unreachable**, not merely awkward — the handler can
  be written but can never fire. Bare lower-case tokens are unaffected.
- **Why it stands:** No *adopted* consumer yet — but the revisit condition
  below has now fired. The paired-shortcut idiom recorded under *"A widget
  opened from a key can receive that key's own echo"* is a real textinput-combo
  consumer, and this defect is exactly what confines it to bare triggers.
- **Revisit:** now — together with the ruling on that entry. If the idiom is
  adopted as the documented answer, this becomes blocking for any modified
  trigger; if a framework mechanism is adopted instead, a wildcard one-shot
  needs no combo lookup and this stays a corner.

### `gui` is supportable as a modifier, and deliberately not supported

- **Not a defect, and not deferred work.** `gui` (super / cmd / win) is outside
  the modifier set by decision (`../decisions/input.md`, **Decision 31**), which
  carries the rationale: never requested, added only for symmetry with the
  table-driven builder Decision 30 dissolves. This entry exists so the option is
  discoverable from the debt side; the decision is the authority.
- **What it costs today:** nothing observable. No shipped project or example
  registers a `gui` combo. `gui+s` is refused at registration (it names two
  triggers, Decision 21) and `lgui` is bindable as an ordinary trigger.
- **What re-adding takes:** a `gui()` accessor beside `ctrl()`/`alt()`/`shift()`
  in `src/util/key.lua`, the pair restored to `mod_triples` and the fold table,
  and the precedence list extended. Bounded and additive.
- **Revisit: when a requirement asks for it** — not for symmetry, which is what
  put it there the first time. Whether the answer is a modifier at all is the
  wider question in "Service keys have no special treatment" below; this entry
  states only what re-adding `gui` *as a modifier* would cost.

### Service keys have no special treatment: `capslock`, `tab`, `lgui`/`rgui`

- **Where:** `src/util/key.lua` — `Key.is_mod` recognises exactly the `ctrl`,
  `alt` and `shift` pairs, and the combo grammar (`split_combo`/`check_combo`)
  treats every other token as a trigger. Verified: **no code outside
  `src/examples/` mentions `capslock` or `tab` at all**, and `lgui`/`rgui`
  appear nowhere in the framework's own dispatch.
- **State:** these keys therefore bind and dispatch exactly like `a` or `f5`.
  Each of them is unlike an ordinary key on real hardware, in a different way:
  `capslock` carries a lock state the framework cannot query and whose release
  is not reliably delivered; `tab` is a traversal key that a UI layer may want
  to claim before a binding sees it; `lgui`/`rgui` are owned in part by the
  desktop environment, which may consume a chord before the app is told.
- **Why it stands:** nothing is broken by it, and nothing has needed it. No
  shipped project or example binds any of the three as anything but a plain
  key.
- **Why it is written down:** the framework has **no vocabulary** for this
  group — they are neither modifiers nor ordinary character keys, and the
  input model currently has only those two categories. That is the observation;
  the shape of any answer is deliberately left open.
- **Revisit: worth one review, at no scheduled point.** At least three
  directions are open and this entry favours none of them — widen the modifier
  set, keep it deliberately narrow (which is the standing position,
  `../decisions/input.md`, Decision 31), or introduce a distinct class for
  service keys with its own rules.

### The `input_widget_overlay` shape test exercises a stub, not the real draw wiring

- **Where:** the `input_widget_overlay` handle is asserted only for shape — that
  `love.state.user_input` is set and callable while the widget is shown
  (e.g. `tests/input/input_widget_callbacks_spec.lua`). The dedicated
  `overlay_spec.lua` that built an ad-hoc controller over a `draw`-only
  stub view was removed when the suite was re-authored; the gap below is
  what survived it, not the file.
- **State:** Guards against the handle being re-narrowed, but does not
  exercise the app's startup widget-instance wiring or the real
  `set_love_draw` `input_widget_overlay` wrapper in `controller.lua` — the exact path a
  past regression faulted at. Runtime spot-checks have covered that path
  manually; the automated suite has not.
- **Why it stands:** Driving the real `input_widget_overlay` draw wrapper from a unit
  test needs app-bootstrap wiring the input suite does not currently stand
  up.
- **Revisit:** When a change next touches the widget/dispatch wiring — add
  a test that drives the actual draw wrapper against the widget instance.

### `Esc` clears the input in place without hiding the terminal (turtle)

- **Where:** the turtle example's input surface; likely the controller's
  `cancel()` path (`userInputController.lua`).
- **State:** Pressing `Esc` empties the input buffer but leaves the
  terminal open. This is the opposite of the editor's own `Esc` behaviour
  (below), so the two surfaces disagree on what `Esc` means.
- **Why it stands:** Intent unverified; may be deliberate (clear-in-place
  to retype) or incidental.
- **Revisit:** Characterise the intended `Esc` semantics for the input
  surface and reconcile with the editor's behaviour; decide whether they
  should converge.

### Editor input buffer not cleared on Escape

- **Where:** the editor input buffer.
- **State:** After Escape in the editor, the buffer retains its content
  rather than emptying. A fix was believed to exist at one point but is not
  present in the current tree — may live elsewhere or may never have
  landed.
- **Why it stands:** Unconfirmed whether this is a regression or a
  missing fix; needs a history search before filing as a defect.
- **Revisit:** Search history for the believed fix; if genuinely absent and
  reproducible, file as a defect.

### tixy shift+click example-sequence behaviour unclear

- **Where:** the tixy example project, running.
- **State:** Shift+click is expected to advance through the built-in
  example sequence, but the intended order is not obvious from the UI and
  may not match expectations. Observed once; not reproduced or
  characterised.
- **Why it stands:** Uncharacterised; may be a UX wrinkle in the example
  rather than an input-API defect.
- **Revisit:** Investigate before the input surface is considered stable
  for project authors; characterise reproducibly, then decide defect vs.
  expected.

### Touch delivery is not black-box expressible today

- **Where:** `tests/input/input_routing_spec.lua` — the pointer
  exclusivity block carries `pending('touch reaches the active route')`.
- **State:** Both the widget's and the route's touch handlers are no-op
  TODO stubs, so touch delivery mutates no observable state anywhere; a
  delivery probe would have to spy on method names, which the suite's own
  conventions forbid.
- **Why it stands:** No observable seam exists until a touch consumer
  lands; carrying it `pending` keeps the gap visible without a mechanism
  spy.
- **Revisit:** Green the row when a real touch consumer is wired.

### maze's Lua-command path is not black-box characterizable

- **Where:** `src/examples/maze` — the project's own `ctrl_update` /
  Lua-command dispatch.
- **State:** This path is not exercised by the input contract suite
  without loading the full project; routing to the project route in
  general is covered by other tests, but maze's own command interpretation
  is not.
- **Why it stands:** Would need project-loading scaffolding the contract
  suite does not currently have.
- **Revisit:** When example-project behaviour is next characterised as a
  body of work.

### `F.reset()` test helper exceeds the 14-line function-body limit (RESOLVED, 2026-07-31)

- **Where:** `tests/helpers/input_fixture.lua`, `F.reset()`.
- **State (old):** Around 18 code lines — native-slot restores plus several
  state-clearing assignments — against the project's 14-line function-body
  hard limit.
- **Resolution:** The native-slot restores the entry names are gone: the
  helper delegates to production teardown (`CC:stop_project_run()`) and clears
  only what production does not own. Nine code lines as of the widget-shown
  fix, which removed the last compensating assignment (`widget.shown = false`).
  Nothing to extract.

### Test-fixture standup boilerplate / naming

- **Where:** `tests/helpers/input_fixture.lua` — the module-standup
  boilerplate and the `F` table name.
- **State:** Open question whether the standup should reference exact
  bootstrap lines directly or be wrapped in a named seam, and whether `F` /
  `compy_input`-style names risk confusion with the real `compy` namespace.
- **Why it stands:** Cosmetic/ergonomic; does not affect correctness or
  coverage.
- **Revisit:** If the fixture's standup grows harder to trace, or the
  naming causes real confusion, address opportunistically.

### Force-path "does not warn" coverage gap

- **Where:** the config-suppression warning test coverage
  (`tests/input/input_widget_control_spec.lua`, the `show(): activation and reset` group).
- **State:** The suite covers "a non-forced re-show while active warns
  once", but there is no explicit assertion that the sanctioned `force`
  override path warns zero times. That guarantee is the inverse of the
  kept row and is currently only implied, not directly pinned.
- **Why it stands:** Low risk; the warn-don't-swallow guarantee is still
  covered by the kept non-force row.
- **Revisit:** Restore an explicit force-path no-warn assertion if the
  reconfigure surface evolves and the boundary needs re-pinning.

### Editor sets its input-widget cursor outside the project cursor API

- **Where:** the editor sets the cursor inside its input widget via its
  own internal path; the project-facing cursor surface is
  `compy.input.get_cursor`/`set_cursor`.
- **State:** Two code paths can move the same widget cursor — the
  editor's internal one, and the project-facing API. Not a dropped
  requirement; the question is whether the editor's own cursor-setting
  should consolidate onto the public API or stay separate.
- **Why it stands:** An open consistency call with no forcing deadline.
- **Revisit:** When the cursor API surface is next touched — decide
  consolidate-vs-separate and record it.

### `submit()`'s deliver-then-hide ordering forced example-side deferral of any reshow (RESOLVED by the input-API redesign)

- **Where:** `src/controller/userInputController.lua` — was `submit()` (calls
  `deliver(self, text)` then unconditionally `hide()`s); now `submit_flow`.
- **Old state:** `on_text_entered` fired while the widget was still active, and
  a trailing `hide()` ran right after (auto-close). A project wanting to "reshow with
  the same text on invalid input" could not call `compy.input.show{...}`
  synchronously from inside its own callback — a re-entry guard
  suppressed it, then `hide()` wiped it. One example project worked around
  this by deferring the reshow a frame.
- **Resolution:** Auto-close on submit is gone (Decision 6):
  `after_submit` DEFAULTS to a
  no-op and the widget stays open. A rejected validator locks the field with the
  rejected text still showing — there is nothing to reshow, so the one-frame
  deferral workaround this entry described no longer has a reason to exist.
- **Revisit:** None needed; carried here as resolved history, not deleted.

### Per-example internals docs still describe a retired polling idiom

- **Where:** `doc/development/internals/examples/{tixy,balloons,turtle,
  valid,repl,guess,index}.md`.
- **State:** The cross-cutting input docs (`internals/user_input.md`,
  `internals/console.md`) were synced to the current `compy.input.*`
  surface, but the per-example internals docs still carry prose and code
  blocks describing the retired `r = user_input()` poll-loop idiom. Each
  needs a real per-file rewrite, not a mechanical find/replace.
- **Why it stands:** Doc drift; does not affect running code.
- **Revisit:** A follow-up documentation pass across the example docs.

### Untracked scratch examples call removed input globals

- **Where:** `src/vadexamples/{guess,repl,turtle,tixy,valid}/main.lua` (and
  their READMEs) — git-untracked, parallel to the shipped `src/examples/`
  tree.
- **State:** These still call `user_input()`/`input_text()`/`input_code()`/
  `write_to_input()`/`validated_input()`, globals that no longer exist;
  they will fail if ever run as-is.
- **Why it stands:** Not part of the shipped example set; nobody currently
  runs them.
- **Revisit:** Migrate or delete at will; not blocking anything.

### An `update_prompt` endpoint was asked for and declined; `configure` already is one

- **Where:** `src/examples/balloons/terminal.lua` — an in-file remark asks the API to expose an
  *"update-prompt"* endpoint so a game can write its own welcome message when its mode switches.
- **Declined, 2026-08-11 (owner).** It is sugar over `compy.input.configure{ prompt = … }`, and a
  second path to a decorative change costs the surface's orthogonality, which is not ideal
  already. *At best it is a pattern to recommend, not a function to add.*
- **And the project already has it**, which is the part worth recording: `terminal_write(msg)` in
  that same file is one line over one `configure` call, exposed to the game as `write`. So the
  recommended shape is not hypothetical — it exists, in the example that asked for the endpoint.
- **The remark's other half — "three functions juggling each other" — is not the win it looks.**
  Two of the three are load-bearing: the handler slot is late-bound because `ui.lua` requires this
  file, and so activates the session, before `main.lua`'s router exists. Inlining the third
  (`deliver`, which joins submitted lines into the one string the game's handlers take) saves a
  function and costs the comment explaining why the join happens. Left alone deliberately.

### PROPOSAL: if event-sourced held state is ever needed, it belongs to the framework

- **Status:** owner's direction, 2026-08-11. **Not a commitment**, and explicitly not this
  release; recorded so that the day someone needs it, they do not each build their own.
- **The rule it follows from** (`../decisions/input.md`, Decision 32.5): a project does not
  reconstruct "what is held" from `keypressed`/`keyreleased`, nor the mouse equivalent, unless it
  is a deliberate decision taken in awareness of the drift — virtual mutable state with no path
  back to the truth, wrong after a focus change or a processing hiccup, and silently so.
- **The shape, if the need is ever demonstrated.** One **event-sourced** view maintained
  centrally by the framework and **exposed for reads** to projects — so the bookkeeping, and its
  reconciliation problem, exists once rather than per project.
- **The constraint that matters most: it stays SEPARATE from the physical polling surface.** A
  reader must always know which question they are asking — *what the event stream says is held*,
  or *what the device says is held*. The two answers legitimately differ, and conflating them is
  the "two clocks" problem this feature spent its length removing (Decisions 29 → 30). One
  surface answering both, or silently switching between them, would rebuild it under a new name.
- **What would have to be true first.** A real consumer that cannot be served by a device poll —
  which is *not* what the example corpus showed: every held-state read in it is a "right now"
  question the device answers. Until such a consumer exists, this stays a direction.

### PROPOSAL: `compy.input.keys`, a held-state surface that hides its implementation

- **Status:** owner's proposal, 2026-08-10. **Not this release** — recorded so the shape is not
  re-derived, and because it reframes a question this feature spent a long time on.
- **The shape.** A proxy table on the input surface answering *"is this key held"*:
  `compy.input.keys.h` resolves to `love.keyboard.isDown('h')`, and the foldable names —
  `keys.shift` / `keys.ctrl` / `keys.alt` — resolve to `Key.shift()` / `Key.ctrl()` /
  `Key.alt()`, so the left/right pair folds exactly as it does in a combo string. One vocabulary,
  read the same way from a handler and from `love.draw`.
- **Why it is worth having, in evidence rather than in principle.** Every input-heavy project
  re-derives this. The keyboard example built a proxy of exactly this shape **twice** — first over
  a mirror it maintained itself, then over the framework's tracked set — `maze` wrote
  `is_shift_down()` by hand, and `turtle`, `clock` and `sapper` each spell out
  `love.keyboard.isDown` or `Key.*` at their call sites. The convergence is the argument.
- **The property that matters most: it makes polling-versus-tracking an implementation detail.**
  Today it proxies straight to the device. If a mirror populated from `keypressed`/`keyreleased`
  is ever genuinely needed, it can be swapped in **behind the same surface**, transparently to
  every project — which is precisely what a bare `keys_pressed` table could not do, because the
  table *was* the contract. Decision 30 removed a model kept beside the device; this proposal
  removes the need to ever expose which one is in use.
- **Two optional extensions, later and only if a need appears:**
  - **An enumerator** — "list every key currently held". This is the one capability a device poll
    genuinely cannot provide (you can ask about a key, not for the set), and providing it centrally
    is cheaper than each project keeping its own bookkeeping to get it.
  - **`compy.states`, a writable surface** — a project registers an arbitrary state-polling
    function under a name and gets **on/off callbacks at the transitions** of that condition,
    centrally evaluated. That generalises the held-chord gap below from keys to *any* condition,
    and moves the evaluation loop out of project machinery into the framework.

    **[Owner's remark, 2026-08-10] This half is not an input mechanism and should not be scoped
    as one.** *"State-polling can be generally useful in a wider class of situations than just
    key-state queries."* The pattern it replaces — *evaluate a predicate every frame, keep a
    boolean mirroring it, and act on the moments it flips* — is what an input-heavy project
    happens to need most visibly, but nothing about it is specific to keys: a pointer entering a
    region, a value crossing a threshold, a game predicate becoming true are all the same shape,
    and each is written out by hand today with its own mirrored flag. That is why the owner named
    it **`compy.states`** rather than `compy.input.states`, and the naming should be read as the
    scoping decision it is. It also means the mirrored-flag bug class this sprint spent its
    length removing from the framework is, in projects, a *general* pattern with no vocabulary —
    the keys case is one instance of it, not the whole of it.
- **Design questions it would have to answer, named so they are not discovered late:**
  - **Name space.** `keys.shift` means the fold, but `lshift`/`rshift` are also real LÖVE key
    names — the surface must say which names are folds and which are keys, or the two collide.
  - **Silent nil.** A proxy that returns nothing for an unknown name turns a typo (`keys.shfit`)
    into "not held", with no error, in a value used directly in conditionals. A fixed key-name
    vocabulary exists, so raising on an unknown name is available and probably right.
  - **Property or call.** `keys.shift` reads as state, which is what makes it pleasant, and also
    what hides that each read is a device call.
- **Revisit:** when a project needs held-state vocabulary that today it must build for itself —
  which, on the evidence above, is most input-heavy projects. See also the entry below, whose
  on/off transition problem the `compy.states` half of this proposal is the general answer to.
- **CONDITION — this proposal carries something for another decision, and dropping it silently
  would leave that unanswered.** Decision 30 (`../decisions/input.md`) dissolved the framework's
  tracked held-key set. It was challenged on the ground that the biggest input-heavy example had
  *independently* grown a model of the same shape, which is evidence of an unmet need. The
  challenge was examined and the decision stands: what that example's model was actually reaching
  for was **edge detection** — answered by the `isrepeat` flag the API delivers, and its own fix
  reached for no held-state at all — plus **foldable held-state convenience**, which a stateless
  device poll answers and which *this proposal* is the durable answer to.
  **So if this proposal is dropped, deferred indefinitely, or replaced by something that does not
  answer the convenience half, that convergence evidence stops being addressed and Decision 30's
  standing should be re-examined at that point.** Recorded here rather than in a review document
  because reviews are transient and this is the condition, not the argument.

### A chord that gates a state while it is held has no vocabulary

- **Where:** the shortcuts mechanism generally (`src/controller/projectInputController.lua`,
  `find_shortcut`; `src/controller/controller.lua`, `combo_string`), and
  `doc/input_api.md`, "Choosing the mechanism".
- **The rule this rests on, stated because the API does not state it (owner, 2026-08-10):**
  **a combo can only reliably serve an atomic transition — a one-off shot, stateless in
  itself. It must not be used to toggle a long-lived state that depends on the combo still
  being held.** The reason is mechanical, not stylistic: a combo is serialised from its
  trigger plus the modifiers held **at that instant**, so the event that would *end* the
  state may serialise differently from the one that began it, and the ending binding is
  simply missed.
- **The two ways it bites, both real:**
  - *A modifier released first.* `keypressed['alt+h']` sets a flag; the player lets go of Alt
    before `h`, so `keyreleased('h')` serialises as plain `'h'` and the `'alt+h'` binding never
    fires. **No second binding closes it** — a modifier's own release has no expressible combo
    at all (Decision 21: one trigger, so `'alt+lalt'` and bare `'lalt'` both raise).
  - *An unrelated modifier pressed mid-hold.* The guide's own flag example binds bare
    `'space'` on both channels; press Space, then press Ctrl, then release Space, and the
    release serialises as `'ctrl+space'`, missing the `'space'` clearing binding. **The
    documented pattern has the defect it is documented to solve.**
  - Both leak the same way on focus loss, where no release is delivered at all.
- **What is missing, sketched (owner, 2026-08-10):** an abstraction for *"this chord is
  currently held"* — evaluated on update, with **two callbacks, on and off**, fired when the
  condition starts and stops being true. Machinery and syntax could mirror shortcuts; only the
  integration differs — instead of one callback on an event channel, a pair on a transition of
  a *condition*. It would replace held-state `if` cascades sprawling through project code, and
  the same shape serves *"Ctrl held during a drag"*, which today every project re-derives.
- **Why it stands:** **not this release.** It is new API surface, and the feature's mandate is a
  simpler and more robust input API, not a larger one. Recorded so the idea is not re-derived,
  and so the rule above is available to anyone reaching for a combo to hold a state.
- **Revisit:** when a project needs held-chord state and the honest answer is still a poll —
  which is what the keyboard example's help overlay does today, deliberately.

### sapper's modifier click path is a touch fallback, and converting it needs the platform's help

- **Where:** `src/examples/sapper/main.lua` — the two guarded click hooks and `love.mousepressed`.
- **What it is.** Shift+press flags and Ctrl+press unlocks, each guarded as *this modifier and
  none of the other two*; the plain click hooks act only when nothing is held. **Its purpose is
  the timing** (author, 2026-08-10): on touch devices a single tap is often accidental and a
  double tap unreliable, so the modifier-held **press** is the dependable route to both actions.
  That rationale is not written in the code, and its absence already caused one wrong change.
- **The obvious conversion is wrong, and was made and reverted (2026-08-10).** Moving the two
  variants to `shortcuts.singleclick['shift+*']` / `['ctrl+*']` is faithful to the *shape* — a
  class key means exactly "this modifier set and no other" — and destroys the *purpose*: derived
  clicks are button 1 only, counted on release, resolved only after the double-click window, and
  **discarded if the pointer drifts**, which is the mechanism the press path exists to bypass.
- **What a correct conversion looks like, and the hole it still has.** Keep the press path as
  `shortcuts.mousepressed['shift+*']` / `['ctrl+*']` — on a channel *with* a trigger the class key
  falls back correctly, so this reproduces "any button, at press time" exactly — and **swallow the
  derived echo** with `shortcuts.singleclick['shift+*'] = fn.stop_here()`, because **consuming a
  press does not prevent the derived click**: the gateway counts clicks in its own
  `mousereleased` handler, before and regardless of anything the project consumed.
  **The residual hole:** a derived click's modifiers are sampled **at synthesis time**, after the
  double-click window — so releasing the modifier during that window makes the echo serialise
  unmodified, miss the swallow, reach the plain hook, and act a second time. On a touch device,
  where the modifier is a key held in the other hand, that is a realistic sequence.
- **THE HOLE IS ALREADY IN THE SHIPPED EXAMPLE — it is not a property of any conversion**
  (verified 2026-08-11). Shift+press flags the cell immediately; the gateway synthesises the
  single click **0.4 s later** (`controller.lua`, `click_delay`); if Shift is released inside that
  window the derived click serialises with **no modifiers**, passes the hook's own *"nothing
  held"* guard, and runs the action a second time — and because flagging **toggles**
  (`actionFlag` → `flowToggleFlag`), the second run **un-flags the cell**. **Net effect:
  shift-click appears to do nothing if the player lets go of Shift promptly.** A live,
  user-visible defect in the example as written, predating this feature entirely.
- **Ruling, 2026-08-15:** retain the fallback. The rare delayed echo is
  accepted without a project-side guard: the damage is negligible and a flag
  would add more machinery than it removes.
- **Revisit:** only if user reports show the echo is material. A platform
  change preserving the originating press's modifiers remains outside this
  feature's scope.

### Modified shortcut families need explicit fall-through policy

- **Where:** project `compy.input.shortcuts` beside ordinary hooks or captured
  `love.keypressed` / `love.textinput` handlers.
- **State:** shortcuts match one exact modifier set. A project that wants a
  shortcut family to claim every modified form must register every meaningful
  and meaningless combination; otherwise an unclaimed combination reaches its
  ordinary keyboard or text-input handling.
- **Why it stands:** the explicit registrations make every claimed combo
  visible, but example grooming has shown that redundant no-op combinations
  quickly become noise.
- **Revisit:** after embedded-example grooming. Evaluate an opt-in wrapper
  such as `compy.input.fn.if_no_modkeys(fn)` that suppresses an event whenever
  a modifier is held, against the risk of hiding a deliberately modified input.

### Examples are not onboarded onto the new input API

- **Where:** `src/examples/{maze,keyboard,turtle,clock}` — the sites listed
  below. The three detached repos (`keyboard`, `maze`, `balloons`) have
  their own remotes and no test suite; `balloons` reads no held state at
  all and appears nowhere here.
- **State:** The examples were reconciled with the removal of the tracked
  held-key set and with the guide's recommendation ladder
  (`doc/input_api.md`, "Held keys"): every read now sits at a rung that is
  correct rather than one that is gone. Several of them are still a rung
  below the one the API offers — a poll answering a question `shortcuts`
  answers directly, or a modifier test that is a combo written out. Each
  conversion below was **considered and declined during the reconciliation**
  because it is a behaviour change, a control-flow restructure, or both, in
  a repo where the only gate is running the app by hand.
- **The sites, and what each would become:**
  - `maze/main.lua:568` — `k == "escape" and not Key.shift()` inside
    `love.keypressed` is two bindings: Shift+Escape quits, bare Escape is
    ignored. The combo form moves `escape` out of `SYSTEM_KEYS` and depends
    on shortcut-before-hook ordering.
  - `maze/main.lua:514-526` — `poll_tab_progression` polls `tab` every
    frame and keeps a `tab_was_down` mirror to derive an edge;
    `shortcuts.keypressed['tab']` is the edge. It also carries the bug
    class the platform just removed: a flag mirroring a key, with nothing
    to reconcile it. The edge feeds two different actions depending on
    game state, so the restructure is not a one-liner. **A bare-key combo
    is legal** — modifiers are optional and only a bare `'*'` is refused —
    **but it narrows the trigger, and that is a behaviour change to state
    rather than discover.** The poll fires on Tab whatever else is held;
    a `'tab'` binding is an exact match on the serialised combo, so
    Ctrl+Tab and Shift+Tab serialise as `'ctrl+tab'` / `'shift+tab'`,
    miss it, and fall through to the hook. Probably an improvement here —
    a stray modified Tab should not skip a level — but it is a decision,
    not a detail.
  - `maze/macro.lua:74,89` — `macro_state.shift_held` is a held-modifier
    mirror maintained across `keypressed`/`keyreleased`, the same shape.
    **Listed by adjacency, not by the same trigger as the rest:** it reads
    no device and never touched the framework's set — the flag is set from
    the event's own key name against a static table (`SHIFT_KEYS`) — so it
    was outside the reconciliation's mandate and is here because it is the
    pattern that mandate kept meeting. It is also not a pure read: the
    release runs `finish_recording()`, so replacing the mirror with
    `Key.shift()` is not behaviour-preserving on its own.
  - `keyboard/alt.lua:203` — `k == "h" and INPUT.ctrl and INPUT.alt`
    hand-matches the combo its own comment calls "Ctrl+Alt+H". Its natural
    form is a shortcut registration; the scene's key routing is what the
    `textinput` heal rewrites, so it waits for that.
  - ~~`keyboard/help.lua:16-19`~~ — **RESOLVED 2026-08-11: the poll is
    correct and stays.** This entry previously called the flag-shortcut shape
    its top rung; the usage principles invert that. The overlay is up while a
    chord is *held*, which is continuous state, and a mirrored
    press/release pair cannot close reliably here at all — a modifier's own
    release has no bindable combo. See `doc/input_api.md`, "Choosing the
    mechanism".
  - `keyboard/input.lua:109` — `isMod` re-implements `Key.is_mod`. Not a
    held-state read, so outside the reconciliation's sweep, but the same
    duplication: it is used in `alt.lua`, `findkey.lua` and `hunt.lua`.
  - `turtle/main.lua:34` — `Key.shift()` inside `love.keypressed` guards
    `shift+r`. It remains because turtle demonstrates captured callbacks.
  - ~~`clock/main.lua:69,78`~~ — **RESOLVED 2026-08-11 by deciding not to
    convert, with the reason written into the file.** `space`,
    `shift+space` and `shift+r` name themselves like combos, but a
    shortcut matches its modifier set exactly, so a `'space'` binding
    would stop firing while any unrelated modifier is held, where the
    hook fires regardless. The narrowing is invisible in the diff that
    would introduce it and nobody asked for it.
- **Why it stands:** Deliberate scope. The reconciliation's mandate was two
  named platform changes; converting an example to the API's better shape is
  a different job, and doing both at once turns a reconciliation into a
  rewrite. Nothing here is broken — each site works as written.
- **Revisit:** This section is the work list for the example onboarding work
  that follows, which reads it entry by entry. That work is split by weight:
  the in-repo examples are a sweep, while `keyboard` and `maze` each get their
  own pass, since each holds conversions that need planning rather than
  applying. A site may be declined again with
  fuller reasoning; what it may not do is disappear silently.

### `compy.input` is rebuilt per project environment, not once at namespace setup

- **Where:** `src/controller/consoleController.lua` — the function that
  builds `compy.input` is called every time a project environment is
  prepared, so the table is reconstructed each time rather than built once.
- **Disposition:** Accepted, no action expected. The `show`/`hide` closures
  resolve the live widget instance dynamically at call time, so they
  reach the current widget regardless of when the table was built —
  arguably more resilient than a build-once table would be, since it holds
  up if the widget instance is ever reassigned.

### Console debug hotkeys are ad-hoc `if`-navigation

- **Where:** `src/controller/controller.lua`, `set_love_keypressed` — the
  `Ctrl+Shift+<n>` / `Ctrl+Alt+d` debug toggles are a nest of `if k == …`
  branches ahead of the route forward.
- **State:** These branches are exactly the shape combos exist to replace —
  falsey-return, fall-through participants keyed on a serialised combo. They
  predate the combo mechanism and were left in place.
- **Why it stands:** Cosmetic; the branches work and run only under
  `love.DEBUG`. Not worth a behavioural change on its own.
- **Revisit:** When this handler is next touched — lift the debug toggles
  onto the combo-table mechanism (Decision 8), or a `toggle_debug(k)` helper.

### `userlove` does not convey its semantics (CLOSED — ruled to keep, 2026-08-03)

- **Ruling:** the name stays. Owner, 2026-08-03: *"I'd not rename userlove,
  its nice and makes no harm itself."* The rename was the last item of the
  deferred naming cluster; the rest of that cluster resolved by deletion
  rather than renaming (see the entries above).
- **What the reader needs instead, and now has in the code comment:**
  `userlove` is *a table indexed by love-event name holding the project's
  handlers*. Both callers pass one — `set_user_handlers` the sandboxed `love`
  table, `restore_user_handlers` the saved `Controller._userhandlers`. That
  second caller is why the once-proposed `project_love` was dropped: it would
  have been true at only one of the two entry points.
- **Kept as a closed entry rather than deleted** because the wrong candidate
  is the useful part of the record: anyone re-proposing `project_love` should
  find the reason it was refused.
- **Note (2026-08-03):** this entry used to also cover `forward_keypressed` /
  `forward_keyreleased` / `forward_textinput`. Those were **deleted, not
  renamed** — they implemented the console route's widget gate, which
  Decision 1 rules out ("widget visibility is state on the widget, never a
  routing condition"), and which was unreachable once the failed-run teardown
  was fixed. Its description here was also wrong on fact: it routed to the
  console route's active *widget*, not to "the currently-active keyboard
  route".

### Per-event `set_love_*` installers are lexically isomorphic

- **Where:** `src/controller/controller.lua`, `set_default_handlers` — ten
  near-identical `Controller.set_love_<event>(CC)` calls, each backed by an
  equally near-identical `set_love_<event>` installer.
- **State:** The installers differ only by event name; the repetition invites
  a table of per-event entries driven by one iterator. Flagged inline as a
  code-hygiene concern, not a correctness one.
- **Why it stands:** The explicit form is readable and predates this note;
  collapsing it is a refactor with no behavioural payoff.
- **Revisit:** If the installer set grows or is next restructured — drive it
  from a `{ event → installer }` table.

### `_generic_callback` re-resolves the callback precedence on every event (RESOLVED by the input-API redesign)

- **Where:** was `src/controller/projectInputController.lua`, `_generic_callback` — computed
  `compy_input[chan] or natives[event]` per dispatched event, then branched
  on whether a callback existed.
- **Old state:** The precedence (explicit `on_*` wins, else captured native, else
  noop) was fixed at `activate` but re-resolved on every dispatched event
  instead of once.
- **Resolution:** `_generic_callback` is gone. Decision 10
  replaced the two-store precedence rule with one table (`hooks[event]`), seeded once at
  `activate` (`seed_hooks`, `projectInputController.lua:43-49`) — there is
  no per-event resolution left to memoise; `dispatch` (`:74-86`) just reads
  `hooks[event]` directly.
- **Revisit:** None needed; carried here as resolved history, not deleted.

### Pointer delivery is an unstructured broadcast, not a chain (RESOLVED, 2026-08-03)

- **Resolution:** pointer joined the existing chain rather than getting a
  mirror of it (`../decisions/input.md`, Decision 25). The gateway's pointer
  entries no longer deliver to the widget themselves; they hand the event to
  the active route like every other channel, and the widget is the chain's
  terminal. A pointer hook consumes on a truthy return, so a shown widget
  *can* now be starved of a click aimed past it — the capability this entry
  asked about.
- **What made it cheap in the end:** the owner's ruling that the
  keyboard/pointer split was self-inflicted rather than inherited (Decision 11,
  amended). The consume contract itself cost nothing: measured across
  `life`, `sapper`, `tixy`, `paint` and `pong`, no project pointer handler
  returns a value, and the return was discarded in any case. So this was never
  the "two symmetrically mirrored chains" it was estimated as — one chain
  already existed and pointer simply entered it.
- **Still open, deliberately:** whether a shown widget should consume clicks
  **within its bounds** automatically. Nothing does bounds checks today; the
  chain gives a project the means to decide, which is a different answer from
  the framework deciding for it.
- **Also still open:** a pointer *combo* vocabulary (a modifier-only shortcut
  such as `ctrl` plus a button). Pointer has no shortcuts tier and enters the
  walk at the hook tier; Decision 25 records the question as not-decided.

### Widget sink reaches the singleton via `love.state` global + nil-guard (RESOLVED-IN-PART by the input-API redesign)

- **Where:** was `src/controller/projectInputController.lua`, `_sink` — read
  `love.state.user_input_controller` on each call and guarded it with
  `if ui then …`.
- **Old state:** The old tier-4 `_sink` reached the widget through a global
  rather than an injected instance field (`self.input`), and defended with
  a nil-check against a value the singleton convention said was always
  present.
- **Resolution:** The sink is gone. `dispatch` (the free-function extraction
  recorded as an implementation note in `decisions/input.md`,
  `projectInputController.lua:74-86`) is now a free function that takes the
  widget **as a parameter** rather than reaching for a global itself — the
  concern moves one level up, to `ProjectInputController:_dispatch`
  (`:93-97`), which is the one remaining place that resolves
  `love.state.user_input_controller`. The nil-guard (`if widget and
  widget:is_shown()`) is carried at that boundary, not inside the reusable
  mechanism.
- **Revisit:** Whether `_dispatch` itself should inject `self.input` at
  construction instead of reading the global, and turn its nil-guard into
  an assertion, remains open — the same question, one layer up.

### `UserInputController:keypressed` forked on `love.state.app_state == 'editor'` (RESOLVED — the `app_state` fork was removed, 2026-07-21)

- **Where:** was `src/controller/userInputController.lua:keypressed`, an
  `if love.state.app_state == 'editor' then … else … end` branch.
- **Old state:** A reusable input widget read global app-mode to change its own
  behaviour — both the editing keymap (order + Ctrl+D `modify`) and whether its
  Enter/Escape submit/cancel ran. Flagged by the owner (2026-07-20) as an
  abstraction leak: the widget could not be reasoned about — or migrated onto the
  new API by the editor later — without knowing it was "the editor." See
  `doc/development/decisions/input.md` Decision 6.
- **Resolution:** The branch is deleted; `keypressed` runs one uniform path. The
  two real differences moved to honest homes: (1) `modify` (Ctrl+D) is a
  per-instance `allow_duplicate_line` constructor flag, set only by the editor's input,
  mirroring `disable_selection`; (2) the editor consumes Enter/Escape **upstream**
  (`block_input()` in `EditorController:_normal_mode_keys`' `submit()`/`load()`),
  so the widget's uniform `submit_flow`/`cancel_flow` never runs for the keys the
  editor owns. No instance reads global mode. Suite green
  (`tests/input/input_widget_callbacks_spec.lua`, the `the same lifecycle on every route` group).
- **Revisit:** `allow_duplicate_line` is a one-off flag; the widget owning its own
  **combo table** (Ctrl+D and the lifecycle keys as registered combos an editor or
  project extends) is the better end-state the owner named — deferred with the
  console/editor migration (Decision 1), not this pass. The former inline question
  at `:724` is retired (its concern is resolved
  in shape; the combo-table refinement is what remains).

### Discovered, de-facto behaviours pinned during the un-fork (rationale note)

The un-fork's preservation tests froze several behaviours that are **not designed
contracts** but were **discovered as existing behaviour with no mandate to alter**
— treated as de-facto standards per the implementation and pinned so they can't
be silently narrowed later (any change is a separate, owner-gated decision):

- **Non-shift Enter submits** — Ctrl+Enter and Alt+Enter submit, not only bare
  Enter (guard is `is_enter and not shift`; also consistent with
  `doc/development/decisions/input.md` Decision 6). Pinned for widget + console.
- **`SearchController:keypressed` returns a jump target** (`{block, line}`) up its
  caller on Enter — the same "keypress return carries a domain result" shape the
  shared widget's limit-flag return was retired for (Decision 5). Left as
  is because `SearchController` is a different class, out of scope here.
- **The `input_widget_overlay`'s view skips the per-frame `update_view()` workaround by
  widget *identity*** (`userInputView.lua:draw`, `self.controller ~=
  love.state.user_input_controller`) — an identity check standing in for the old
  `oneshot` flag. Its survival under a console/editor re-plug remains a
  tracked future concern, out of the input API's scope.

### Comment wip-citation cleanup (RESOLVED, 2026-07-30)

Comments citing the feature's ephemeral wip tree instead of a canonical doc, in violation of
the `doc/development/conventions/code.md` "Comment References" rule. This entry recorded the
residue as two `src/controller/` comments; a pre-PR revalidation found **thirteen** comment
blocks across seven tracked files, four of them shipped examples under `src/examples/`.

All are rehomed: the controller comments to the `decisions/input.md` decisions they already
cited alongside the wip path, the examples to `doc/input_api.md`, "Submit lifecycle". Kept as
a resolved entry rather than deleted, because the undercount is the lesson — a debt row's
stated scope is a claim like any other, and this one was never re-measured after the tree
moved under it.

### The console's prompt is drawn under a project that never takes over `love.draw` (DISPUTABLE, ruled to keep 2026-08-07)

`ConsoleView:draw` paints the console's own input strip whenever the screen mode is not
`editor` (`src/view/consoleView.lua`, `drawConsole`). A project that replaces `love.draw`
never reaches that path — the gateway's draw wrapper calls the project's own draw instead
(`src/controller/controller.lua`, `set_love_update`). A project that draws **through the
console terminal** and defines no `love.draw` of its own does reach it, so the console's
prompt stays on screen for the whole run, inert: the input route belongs to the project, so
anything typed at that strip goes to the project, not to the prompt it appears to offer.

`src/examples/sapper` is the case in hand — it renders the minefield as terminal output and
binds only the derived clicks, so the strip sits under the game field for the entire session.
Surfaced by the owner's smoke test as *"any chance to not show inactive console input at the
bottom?"*.

**Ruled to keep as-is (owner, 2026-08-07):** the console's drawing logic is not to be
conditioned on what a project happens to draw, for the cosmetic benefit of one pen-and-paper
example. The gate would have to distinguish "a project owns the input route" from "the console
is interactive again" — `inspect` being the second — which puts project-lifecycle knowledge
into a view whose job is to paint the console.

**Cost of leaving it:** the strip reads as an available prompt while it is not one. **Cost of
fixing it:** a state test in the view, invisible to the suite — the input fixture stubs the
`view.view` module wholesale, so `ConsoleView:draw` is not exercised by any row, and the fix
would be verifiable only by a human smoke test. Revisit if a project owner asks.

### paint's `useCanvas(btn)` means a mouse button on one path and a click count on the other (pre-existing)

`src/examples/paint/main.lua` calls `useCanvas(x, y, btn)` from two places, and `btn` means
something different in each:

- **the drag path** — `compy.input.hooks.mousemoved` polls `love.mouse.isDown(btn)` for `btn = 1, 2` and
  passes the held button through. Here `btn` is a real LÖVE mouse button.
- **the click path** — `point(x, y, btn)`, reached from `hooks.singleclick` and
  `hooks.doubleclick`. Here the number is **paint's own action selector, written as a literal
  in each binding**: `1` for the primary gesture, `2` for the secondary. The framework passes
  the two hooks `(x, y)` and nothing else — no button, no count — so nothing hands paint a `2`
  to misread. Paint picks it.

So the function reads as button-aware, and half its callers cannot supply a button.

**This is not a case of a receiver misinterpreting a value it was sent** — the question is
worth stating because the coincidence invites it. `doubleclick` does not deliver "button 2";
it delivers `(x, y)`, and paint's handler body chooses to call the secondary action `2`. Had
the framework been passing a click count into a button parameter, that would be a defect; it
never did, at the PR base or now. What is left is a latent trap: one parameter, a real LÖVE
button on the drag path and a hand-picked constant on the click path, with the two meanings
agreeing by luck (`2` = "secondary" in both readings). The
consequences a user meets: right-**drag** on the canvas paints with the background colour,
right-**click** does nothing, and double-click paints with the background colour — one effect,
two unrelated gestures, plus a third gesture that looks like it should work and does not. The
same conflation runs through `setColor`, whose `btn > 1` branch is reachable only by double
click, so "secondary colour" is bound to double-click rather than to the secondary button.

**Pre-existing, not a migration artefact.** At the PR base (`3256aac`) the drag path is
byte-identical and the click path bound `compy.singleclick` / `compy.doubleclick` with the same
hardcoded 1 and 2. This feature renamed the bindings (`compy.X` →
`compy.input.hooks.X`) and changed nothing about the meaning.

**Why it cannot simply be fixed by binding the button.** The derived clicks name no button by
ratified decision (`../decisions/input.md`, Decision 27, "The derived clicks keep `(x, y)` and
name no button"): they are not LÖVE events and the click timer synthesises them from
left-button releases only. A project that needs to know which button produced a click binds
`mousereleased` and does its own timing — which is exactly what the framework's timer does on
the project's behalf for the left button.

**Ruled not to change paint (owner, 2026-08-07):** the example never intended a secondary-button
gesture, secondary-button availability is not uniform across environments, and mapping the
secondary action onto a double-click may well be deliberate. Recorded because the parameter's
double meaning is a trap for the next person to edit this example, not because the behaviour is
wrong today.

**Recommendation, for whenever paint is next opened.** Nothing here is urgent — the example
works, and this is about how easy it is to keep working.

1. **Name the two layers.** `1` and `2` appear as bare literals in the two click bindings and
   again as branch conditions in `setColor` and `useCanvas`, so the meaning lives in the
   reader's head rather than in the code. `local FOREGROUND, BACKGROUND = 1, 2` — or better, a
   value that cannot be confused with a button at all, such as the strings `'fg'` / `'bg'` —
   makes each site say what it does. This is the cheap half and it removes most of the risk on
   its own.
2. **Stop using a button number as the layer identifier.** Even named, `btn` is fragile
   precisely because one of its two call paths really is a LÖVE button: a future edit that
   passes a genuine `3` (middle click) or that reads `btn` as a button on the click path will
   be wrong in a way nothing catches. Splitting the parameter — the drag path translating the
   held button into a layer before calling — keeps the button at the edge, where it belongs.
3. **A modifier may be the better metaphor for "background".** Ctrl-draw or Alt-draw is a
   conventional secondary-action gesture, it reads the same on a trackpad and on hardware with
   no reliable second button, and the input API expresses it directly:
   `shortcuts.mousepressed['ctrl+mouse1']` is a ctrl-click and `shortcuts.mousemoved['ctrl+*']`
   a ctrl-drag (`../decisions/input.md`, Decision 27). That would also let double-click go back
   to meaning something double-click-shaped, instead of standing in for a button paint cannot
   observe.

Points 1 and 3 are independent: naming the layers is worth doing even if the gesture never
changes.

### A modifier accessor answers truthy/falsy, not a boolean

- **Where:** `src/util/key.lua` — `ctrl`/`alt`/`shift` return
  `love.keyboard.isDown(...)` straight through, and are annotated
  `@return boolean`. Real LÖVE honours that; the annotation is **not enforced**
  for anything that replaces `isDown`.
- **The one known offender is fixed (2026-08-16).** Harmony's lock-mode patch
  used to fall off its own end for an unheld key, returning **no value** rather
  than `false`, and Lua adjusts that to `nil` at a call site. It now returns a
  boolean on every path (`src/harmony/init.lua`, `patch_isDown`), on the ground
  that a mock matches the signature of the thing it mocks. What remains is the
  general exposure below, not a live instance.
- **State:** harmless to every `if Key.ctrl() then` in the tree, since `nil` and
  `false` are both falsy. It bites the moment a device read is **compared**
  rather than tested: `Key.ctrl() == false` is `false` under harmony, and
  `Key.ctrl()` spliced as a call's last argument contributes **no argument at
  all**. The live exposure is the second, at six call sites that pass a modifier
  read as a trailing argument (`editorController.lua:466,470,772,776`,
  `searchController.lua:101,105`), none of which is affected today because the
  callee only tests the value for truthiness. The comparison form was observed
  once, in the gate's `only_mods` helper, which normalised with `not not`; that
  helper no longer exists (Decision 34 replaced the predicate cascade with a
  combo-string table), so **no site in the tree compares a modifier read today**.
- **Why it stands:** nothing is wrong under a real device, no patcher offends
  today, and no caller compares. Changing the accessors is a small edit with a
  wide blast radius — every caller's return type would become guaranteed, which
  is desirable but wants its own pass and its own tests.
- **Shape, if it is answered:** normalise inside `Key` — `return not not
  love.keyboard.isDown(...)` in each of the three accessors — so the
  `@return boolean` annotation becomes true for every consumer, and no future
  caller has to remember `not not` to compare safely.
- **Revisit:** when `Key`'s accessors are next touched, or the first time a site
  compares a modifier read rather than testing it.

### A gesture that tolerates a modifier costs one registration per variant

- **Where:** `compy.input.shortcuts` and the combo grammar (`src/util/key.lua`,
  `split_combo`/`check_combo`). A combo is its modifier set **exactly**
  (Decision 21), and the `'*'` class key is a class of one modifier set too —
  `'alt+*'` does not match `alt+shift+key`.
- **State:** a project that wants *"Ctrl+Alt+Up, and I do not care whether
  Shift is also down"* must register `ctrl+alt+up` **and**
  `ctrl+alt+shift+up`. `examples/keyboard` needs six such tolerant gestures
  and pays **twelve** registrations for them (`input.lua`,
  `register_reserved`). Nothing is broken by this and every binding is
  explicit, which is the model's virtue.
- **Why it is written down (2026-08-12):** the cost is not the typing, it is
  that *a missing variant is silent and looks exactly like the code being
  right*. Converting this one example's hand-written modifier tests to combos
  dropped **six** gestures; four were caught by one cold review, the fifth by
  a second, and the sixth by a third — each time after a fix for the previous
  one had been written by someone who had just read the rule and the bindings
  together. That is three independent reviews to converge on one file's
  twelve lines, and the register should say so before the next project
  migrates.
- **Shape, if it is ever answered:** a tolerance marker in the combo grammar
  (something like `'ctrl+alt+shift?+up'`), or a registration helper that
  expands one gesture into its variants. **Neither is proposed here** — the
  explicitness of the current model is a deliberate property and a tolerance
  syntax trades it away.
- **Revisit:** when a second project hits it, or when the input guide gains
  its reserved-combo section (P10) and has to explain the double binding
  anyway.
