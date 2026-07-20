# Input subsystem

Keyboard/text/pointer routing, the console and project input controllers
(`src/controller/controller.lua`, `userInputController.lua`,
`projectInputController.lua`, `consoleController.lua`), and the project-facing
`compy.input` surface. Cross-reference: `internals/user_input.md`,
`../input_api.md`.

Three groups below: standing properties (settled, just noted), open decisions
(the framework owner has not yet ruled), and anticipated items (may never need
action; revisit at the named point).

---

## Standing

### `keys_pressed` can go stale on focus loss

- **Where:** `src/controller/controller.lua` — `keys_pressed` is maintained
  from `keypressed`/`keyreleased` only.
- **State:** If the window loses focus with a key held, `keyreleased` may
  never fire and the entry lingers — a general limitation of any held-key
  mirror built purely from press/release events.
- **Why it stands:** No cheap, fully-correct fix; the consumer can defend
  against it.
- **Revisit:** Any consumer of `keys_pressed` (directly or via the
  `held_keys()` read-only pressed-keys view) must not assume the set is leak-free across
  focus changes; if it matters, clear the set on `love.focus(false)`.

### `love.handlers.userinput` is dead code

- **Where:** `src/controller/controller.lua` (the `handlers.userinput`
  assignment, immediately following `handlers.mousemoved`).
- **State:** Unreachable — nothing in the tree pushes a `'userinput'` LÖVE
  event since the mechanism that used to trigger it was removed.
- **Why it stands:** Benign; never invoked, so it costs nothing at runtime.
- **Revisit:** Safe to delete outright whenever this file is next touched.

### Controller-side dead `result`/reftable delivery path

- **Where:** `src/controller/userInputController.lua` — `apply_config` sets
  `self.result` from `cfg.result`, and `deliver()` has a
  `if type(res) == 'table' then res(text) end` branch for it.
- **State:** Nothing anywhere in the tree ever passes a table as `result`
  (grep finds zero producers), so `self.result` is always non-table and the
  reftable-delivery branch in `deliver()` is unreachable.
- **Why it stands:** A natural cleanup, not urgent — the field is
  write-once-from-config with no writer left.
- **Revisit:** Next controller-focused pass; remove the branch and the
  `result` config key together if nothing is expected to resurrect them.

### A truthy `hooks[event]` return silently disables `on_limit_reached`

- **Where:** `src/controller/projectInputController.lua` (the free-function
  `dispatch`) — `hooks[event]` runs before the widget; `userInputController.lua`
  (`emit_limit`) fires `on_limit_reached` only from inside the widget itself.
- **State:** A project that sets `compy.input.hooks.keypressed` (or the
  text/release siblings) and returns truthy consumes the event at the
  hooks step, so `dispatch` never reaches the widget and the widget's
  `on_limit_reached` callback never fires for that keystroke — no
  error, warning, or other signal marks the drop. Carried through the
  Phase R redesign unchanged — renamed from tier-3/tier-4 to
  hooks/widget, but the underlying coupling is the same.
- **Why it stands:** The truthy-consume shape (decisions/input.md,
  Decision 2 revised) is working as designed; it just wasn't checked against
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
  the input overlay (`examples/guess`) or a pointer handler
  (`examples/sapper`), this meant (1) submit was dead — typing
  still reached the overlay but Enter never fired, because
  submit/cancel (then a non-overridable framework tier, since
  retired by Phase R4 — Decision 2 revised) lives in the *project*
  route, which `project_open` disconnected — and (2) Ctrl+Esc quit the whole
  app instead of returning to the console, because `love.quit`
  only stopped-to-console while `app_state == 'running'`.
- **Confirmed pre-existing:** this was verified byte-identical on
  `master` (pre-`0022004`) — not a #77 regression. The
  `release_keyboard_route` call site is new on the #77 branch
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
  *no* interaction surface at all (no overlay shown, no pointer
  handler, no update/draw) still gets `release_keyboard_route` —
  the keyboard goes back to the console. This is intended, not a
  gap: such a project has nothing left to be interactive with.

---

## Open decisions

The framework owner has not yet ruled on these; each is recorded as an open
question, not resolved here.

### `compy.keys_pressed` is not exposed to projects

- **Where:** the project-facing `compy` namespace (`consoleController.lua`,
  the function that assembles it) exposes `terminal`, `audio`, `graphics`,
  `fonts`, `input`, and a `before_exit` slot — no `keys_pressed`. Held-key
  access exists framework-side (`Controller.keys_pressed`, the `held_keys()`
  read-only pressed-keys view) and via the per-event callback argument, but a project cannot poll
  currently-held keys from inside its own `update()`.
- **Why it stands:** Open design question — expose a read-only held-key view
  to projects, or treat callback-arg access as the sanctioned shape and amend
  the documented contract to say so explicitly.
- **Revisit:** Decide, then either add the surface or update the contract
  doc to rule out polling by design.

### `eval`/`result` config keys are an undocumented deviation

- **Where:** `apply_config` in `userInputController.lua` accepts `eval` and
  `result` as `show{}`/`configure{}` config keys; several example projects
  pass `eval =`.
- **State:** Neither key is part of the documented public config-key set
  (`validator` is the documented equivalent shape).
- **Why it stands:** Open — bless `eval`/`result` as public API and record
  the deviation, or steer callers onto the documented key(s) instead.
- **Revisit:** Decide when the public config-key set is next reconciled with
  actual usage.

### Shortcuts key-repeat semantics are shipped unsettled

- **Where:** `src/controller/projectInputController.lua`, `:keypressed` —
  `isrepeat` is threaded through to `hooks[event]` dispatch only; `shortcuts`
  fire on every OS key-repeat with no `isrepeat` gate.
- **Why it stands:** Whether shortcuts dispatch should also gate on
  `isrepeat` (fire once per physical press) or intentionally fire on every
  repeat is an open behavioural call, shipped open by design.
- **Revisit:** Rule one way or the other when shortcuts dispatch gets its next
  real consumer or complaint.

### `multiline` is unimplemented

- **Where:** `src/model/input/userInputModel.lua` carries a `-- TODO
  multiline` marker; there is no `multiline` config key anywhere in the
  input path. Shift+Enter newline insertion is unconditionally on.
- **Why it stands:** Open — implement a `multiline` toggle as originally
  intended, or strike the promise and document that newline insertion is
  always available.
- **Revisit:** Decide the next time the input config surface is revisited.

### Silent config-key drop in `show{}`

- **Where:** `apply_config` (`userInputController.lua`) reads only the keys
  it knows; an unrecognised key (a typo, or a field-write-only key passed
  through `show{}`) is silently ignored — no error, no warning.
- **State:** Inconsistent with the rest of the surface: `set_cursor` /
  `set_text` in `consoleController.lua` do log a warning when a call is
  ignored because the widget is hidden. The silent-drop behaviour here is an
  inconsistency in an otherwise warn-don't-swallow surface, not a blanket
  policy.
- **Why it stands:** Open — accept silent drops, or add a
  warn-on-unrecognised-key path to match the sibling functions.
- **Revisit:** Decide alongside any future audit of the config-key surface.

### Held-key pressed-keys view iteration is index-only on the shipping runtime

- **Where:** `src/controller/controller.lua`, the `held_keys()` read-only
  pressed-keys view over `Controller.keys_pressed`.
- **State:** Under LuaJIT (the shipping Lua runtime), `pairs()` ignores
  `__pairs`, so `pairs()` over this view yields nothing; only indexed reads
  (`view['a']`) work. The read-through/write-raise contract holds; only
  iteration is inert. `__pairs` is kept for a 5.2+ host, which this project
  does not currently run on.
- **Why it stands:** Open — accept indexing-only access as the permanent
  shape, or add an explicit iteration helper (e.g. a snapshot-to-array
  function) for consumers that need to enumerate held keys.
- **Revisit:** If a real consumer needs to iterate the held set on the
  shipping runtime.

### No public `is_active()`-shaped visibility query

- **Where:** the `compy.input` project surface (`consoleController.lua`)
  exposes `handlers`/`show`/`hide`/`get_cursor`/`set_cursor`/`set_text`/
  `configure`/`clear`/… — no `is_shown`/`is_active`/`is_visible`. An
  internal `UserInputController:is_shown()` exists but is not part of the
  project-facing surface, so at least one example project reads
  `love.state.user_input` directly and keeps its own per-tick re-arm poll.
- **Why it stands:** Open — sanction a public visibility-query accessor, or
  leave direct `love.state` reads as the (undocumented) way projects do
  this today.
- **Revisit:** Decide when another project author hits the same need.

---

## Anticipated — revisit at the named point, close only if warranted

Not commissioned for closure; each may never need action.

### Combo-string dispatch allocates a table per call

- **Where:** `src/controller/controller.lua` — `combo_string` builds a
  `parts` table and `table.concat`s it on every call; it runs on the
  per-keystroke combo-dispatch path.
- **Why it stands:** Keystroke dispatch is not a per-frame hot path, so the
  allocation is acceptable for now.
- **Revisit:** If combo dispatch ever lands somewhere genuinely hot, switch
  to a reused buffer or a concat-free comparison.

### `combo_string` does not normalise the case of a textinput token

- **Where:** `src/controller/controller.lua`, `combo_string`.
- **State:** An upper-case *textinput* combo token would not match a
  normalised lower-case registration. Textinput combos are a rarely-used
  corner of the combo surface.
- **Why it stands:** No real consumer has hit this yet.
- **Revisit:** If a real textinput-combo consumer appears.

### `gui_k` modifier pair has no consumer

- **Where:** `src/util/key.lua` — `gui_k = { "lgui", "rgui" }` feeds only
  `mod_triples`; there is no `gui()`/`is_gui()` accessor paralleling
  `shift()`/`is_shift()`.
- **State:** A defined modifier pair with no behavioural reader — could be
  a deliberate "ignore gui keys as a modifier" choice, or an expansion
  point left open for a future accessor.
- **Why it stands:** Harmless and additive; parallels the established
  `*_k` pattern.
- **Revisit:** When it is decided whether `gui` is a first-class modifier —
  add `gui()`/`is_gui()`, or record that `gui` is intentionally ignored.

### Overlay-shape test exercises a stub, not the real draw wiring

- **Where:** `tests/input/overlay_spec.lua` — the overlay-shape test builds
  an ad-hoc controller with a `draw`-only stub view and asserts
  `love.state.user_input` is truthy and callable.
- **State:** Guards against the handle being re-narrowed, but does not
  exercise the app's startup widget-instance wiring or the real
  `set_love_draw` overlay wrapper in `controller.lua` — the exact path a
  past regression faulted at. Runtime spot-checks have covered that path
  manually; the automated suite has not.
- **Why it stands:** Driving the real overlay draw wrapper from a unit
  test needs app-bootstrap wiring the input suite does not currently stand
  up.
- **Revisit:** When a change next touches the overlay/dispatch wiring — add
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

### `F.reset()` test helper exceeds the 14-line function-body limit

- **Where:** `tests/helpers/input_fixture.lua`, `F.reset()`.
- **State:** Currently around 18 code lines (native-slot restores plus
  several state-clearing assignments), against the project's 14-line
  function-body hard limit.
- **Why it stands:** Mechanical, not a design question — the convention is
  to redesign, not raise the limit.
- **Revisit:** Extract the native-slot restores into a small helper;
  trivial, test-only fix.

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
  (`tests/input/input_widget_lifecycle_spec.lua`, the widget activation/reset block).
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

### `submit()`'s deliver-then-hide ordering forced example-side deferral of any reshow (RESOLVED by Phase R4)

- **Where:** `src/controller/userInputController.lua` — was `submit()` (calls
  `deliver(self, text)` then unconditionally `hide()`s); now
  `_submit_default` (`:451-460`).
- **Old state:** `on_text_entered` fired while the overlay was still active, and
  a trailing `hide()` ran right after (auto-close). A project wanting to "reshow with
  the same text on invalid input" could not call `compy.input.show{...}`
  synchronously from inside its own callback — a re-entry guard
  suppressed it, then `hide()` wiped it. One example project worked around
  this by deferring the reshow a frame.
- **Resolution:** Auto-close on submit is gone (Decision 6 revised,
  validation/reviews/delta-spec-input-api.md §3): `after_submit` DEFAULTS to a
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

### `forward_*` / `userlove` names do not convey their semantics

- **Where:** `src/controller/controller.lua` — `forward_keypressed` /
  `forward_keyreleased` / `forward_textinput`, and the `userlove` parameter
  threaded through `occupy_keyboard` / `set_handlers`.
- **State:** `forward_*` reads as "forward where/why?" (it routes to the
  currently-active keyboard route and returns whether that route consumed);
  `userlove` is the project's sandboxed `love` table. Both are correct but
  under-named — the reason they carried inline `REVIEW:` markers.
- **Why it stands:** Pure rename; no behavioural content. Deferred to avoid
  churn on a landing branch.
- **Revisit:** Next time this file is edited — rename to intent-revealing
  names (e.g. `route_keypressed`, `project_love`) in one sweep.

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

### `_generic_callback` re-resolves the callback precedence on every event (RESOLVED by Phase R4)

- **Where:** was `src/controller/projectInputController.lua`, `_generic_callback` — computed
  `compy_input[chan] or natives[event]` per dispatched event, then branched
  on whether a callback existed.
- **Old state:** The precedence (explicit `on_*` wins, else captured native, else
  noop) was fixed at `activate` but re-resolved on every dispatched event
  instead of once.
- **Resolution:** `_generic_callback` is gone. Decision 10 revised
  (validation/reviews/delta-spec-input-api.md §5) replaced the two-store
  precedence rule with one table (`hooks[event]`), seeded once at
  `activate` (`seed_hooks`, `projectInputController.lua:43-49`) — there is
  no per-event resolution left to memoise; `dispatch` (`:74-86`) just reads
  `hooks[event]` directly.
- **Revisit:** None needed; carried here as resolved history, not deleted.

### Pointer delivery is an unstructured broadcast, not a chain

- **Where:** `src/controller/controller.lua` — the gateway `handlers.mouse*`
  / `handlers.touch*` handlers (e.g. `handlers.mousepressed`).
- **State:** Each pointer handler delivers to the input widget whenever one is
  present — no bounds check, no consume semantics, the widget's return
  discarded — and *then* forwards unconditionally to the slot occupant (the
  project's native handler). Both fire: a shown widget cannot swallow a click
  aimed at it, and a project's click handler fires even for clicks inside the
  widget. The keyboard three-consumer chain (Decision 2 revised) has **no pointer mirror**.
  Pointer never had the #77 widget-lockout, so its delivery was left as
  pre-existing behaviour, deliberately out of #77 scope.
- **Why it stands:** Works for today's consumers; building a pointer chain was
  explicitly not in #77 scope.
- **Owner ruling needed:** should pointer get a mirrored consume-chain (the
  "two symmetrically mirrored chains" idea, analogous to Decision 1's deferred
  console/editor convergence), and should a shown widget consume pointer
  events within its bounds? Until ruled, the broadcast stands.
- **Revisit:** When pointer routing gets a real second consumer, or the
  owner rules on the mirror-chain question.

### Widget sink reaches the singleton via `love.state` global + nil-guard (RESOLVED-IN-PART by Phase R4)

- **Where:** was `src/controller/projectInputController.lua`, `_sink` — read
  `love.state.user_input_controller` on each call and guarded it with
  `if ui then …`.
- **Old state:** The old tier-4 `_sink` reached the widget through a global
  rather than an injected instance field (`self.input`), and defended with
  a nil-check against a value the singleton convention said was always
  present.
- **Resolution:** The sink is gone. `dispatch` (obligation 6a,
  validation/reviews/delta-spec-input-api.md §2,
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
