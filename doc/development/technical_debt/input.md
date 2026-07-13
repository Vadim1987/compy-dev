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
  `held_keys()` read-only proxy) must not assume the set is leak-free across
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

---

## Open decisions

The framework owner has not yet ruled on these; each is recorded as an open
question, not resolved here.

### `compy.keys_pressed` is not exposed to projects

- **Where:** the project-facing `compy` namespace (`consoleController.lua`,
  the function that assembles it) exposes `terminal`, `audio`, `graphics`,
  `fonts`, `input`, and a `before_exit` slot — no `keys_pressed`. Held-key
  access exists framework-side (`Controller.keys_pressed`, the `held_keys()`
  proxy) and via the per-event callback argument, but a project cannot poll
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

### Combo-tier key-repeat semantics are shipped unsettled

- **Where:** `src/controller/projectInputController.lua`, `:keypressed` —
  `isrepeat` is threaded through to tier-3 dispatch only; the combo tiers
  (below tier 3) fire on every OS key-repeat with no `isrepeat` gate.
- **Why it stands:** Whether combo dispatch should also gate on
  `isrepeat` (fire once per physical press) or intentionally fire on every
  repeat is an open behavioural call, shipped open by design.
- **Revisit:** Rule one way or the other when combo dispatch gets its next
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

### Held-key proxy iteration is index-only on the shipping runtime

- **Where:** `src/controller/controller.lua`, the `held_keys()` read-only
  proxy over `Controller.keys_pressed`.
- **State:** Under LuaJIT (the shipping Lua runtime), `pairs()` ignores
  `__pairs`, so `pairs(proxy)` yields nothing; only indexed reads
  (`proxy['a']`) work. The read-through/write-raise contract holds; only
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

### In-code `REVIEW:` annotations awaiting triage

- **Where:** `src/controller/controller.lua` and
  `src/controller/projectInputController.lua` — 31 `REVIEW:` markers between
  the two files (grep-verified).
- **State:** Each marker is the original author's own open question,
  written inline and shipped as part of the landed code rather than
  resolved or filed separately.
- **Why it stands:** Open — each marker needs a read-through to decide
  keep/resolve/discard; none has been triaged yet.
- **Revisit:** A dedicated pass reading each marker in place and either
  resolving it or promoting it to its own recorded item.

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
  exercise the app's startup-singleton wiring or the real
  `set_love_draw` overlay wrapper in `controller.lua` — the exact path a
  past regression faulted at. Runtime spot-checks have covered that path
  manually; the automated suite has not.
- **Why it stands:** Driving the real overlay draw wrapper from a unit
  test needs app-bootstrap wiring the input suite does not currently stand
  up.
- **Revisit:** When a change next touches the overlay/dispatch wiring — add
  a test that drives the actual draw wrapper against the singleton.

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

- **Where:** `tests/input/input_contracts_spec.lua` — the pointer
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
  (`tests/input/input_contracts_spec.lua`).
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

### `submit()`'s deliver-then-hide ordering forces example-side deferral of any reshow

- **Where:** `src/controller/userInputController.lua`, `submit()` — calls
  `deliver(self, text)` then unconditionally `hide()`s; a re-entry guard
  suppresses any synchronous re-show from inside the delivery callback.
- **State:** `on_text_entered` fires while the overlay is still active, and
  the trailing `hide()` runs right after. A project wanting to "reshow with
  the same text on invalid input" cannot call `compy.input.show{...}`
  synchronously from inside its own callback — the re-entry guard
  suppresses it, then `hide()` wipes it. One example project works around
  this by deferring the reshow a frame. It works, but is a non-obvious trap
  any author reshowing on rejection will hit.
- **Why it stands:** API ergonomics on frozen sequencing behaviour; not a
  bug.
- **Revisit:** A first-class "reject keeps the widget open with the
  rejected text" path would remove the need for the one-frame deferral
  workaround, if the live-reconfigure surface is extended further.

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
  resolve the live controller singleton dynamically at call time, so they
  reach the current singleton regardless of when the table was built —
  arguably more resilient than a build-once table would be, since it holds
  up if the singleton is ever reassigned.
