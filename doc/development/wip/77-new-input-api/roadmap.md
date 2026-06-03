# Feature #77 — Implementation Roadmap

*Scoped to this feature only. Milestones in
implementation-dependency order, matching the section
order in `notes/solution_sketch.md`. Estimates are in
the `## Estimates` section at the bottom.*

> **Status — derived proposal document.** This roadmap is a derived
> part of the feature-#77 proposal chain, pre-built on the
> assumption the design is endorsed rather than vetoed. Milestone
> boundaries and estimates are provisional: stakeholders may review
> or adjust parts without blocking implementation — there is no
> requirement to freeze the plan before work starts.

---

## Milestones

---

### M1 — `keys_pressed` table

**Description:** Framework-level live set of currently-held
key names. Zero behaviour change.

**Input:** Nothing. This milestone has no dependencies and
can begin immediately.

**Output:** `Controller.keys_pressed` is maintained
correctly. Combo serialisation helper (`combo_string`)
exists and is tested. All existing tests continue to pass.
No behavioural change observable in any app mode.

**Files created or modified:**
- `src/controller.lua` — add `keys_pressed` table
  maintenance in `love.handlers.keypressed` and
  `love.handlers.keyreleased`; add `combo_string` helper

**Risk:** None. Purely additive; existing handlers are
unchanged.

---

### M2 — `UserInputController` singleton extraction

**Description:** Move widget construction from inside
`ConsoleController` to framework startup. Widget created
once, never destroyed. Zero behaviour change.

**Input:** M1 complete (keys_pressed table exists).

**Output:** `UserInputController` is instantiated once at
startup (lazily). `ConsoleController` no longer creates
the widget on each `input_text()` call. `compy.input.show()` and
`compy.input.hide()` are available on the namespace (required before
M3 facades can call them). All existing examples work;
allocation-per-session is gone. Existing tests pass. The
`oneshot` flag is **not** removed in this milestone — it
continues to drive submit through M2–M5.

**Files created or modified:**
- `src/main.lua` — create singleton instance at startup
- `src/consoleController.lua` — remove per-call
  construction; wire to singleton
- `src/userInputController.lua` — `show()`/`hide()` state
  change methods added; `result` repointing setter added so
  each facade call can wire the current reftable
- `src/compy_namespace.lua` (or equivalent) — create the
  `compy.input` table once at namespace setup; mount
  `compy.input.show` and `compy.input.hide` on it

**Risk:** Care needed to preserve `love.state.user_input`
set/clear behaviour. Existing tests exercise this path;
run all before and after.

---

### M3 — Legacy API facade wrappers

**Description:** Rewire `input_text()`, `input_code()`,
`validated_input()`, `user_input()`, and `write_to_input()`
as facades over the new singleton API.

**Input:** M2 complete (singleton exists; `compy.input.show` and
`compy.input.hide` are on the namespace).

**Output:** All existing examples (repl, tixy, guess,
turtle, valid, balloons) work without modification. Polling
pattern (`if r:is_empty()`) continues to work. `write_to_input`
is rewired as a facade over `compy.input.set_text` (keeping the tixy
example green). Deprecation warnings emitted in debug mode. The
reftable fill continues via the existing oneshot submit path —
M3 does not depend on `after_submit` from M6.

**Files created or modified:**
- `src/consoleController.lua` — rewire the five entry points
  as facade functions (`user_input`, `input_text`,
  `input_code`, `validated_input`, `write_to_input`)

**Risk:** Edge cases in reftable lifecycle. Ensure that
cancel (Escape) leaves reftable empty, matching current
behaviour.

---

### M4 — `ProjectController` introduction and overlay gate removal

**Description:** New controller for the project-running
context. The `if user_input then` gate in `controller.lua`
is removed. Routing becomes symmetric.

**Input:** M3 complete (legacy API works; singleton stable).

**Output:** `ProjectController:keypressed` and
`:textinput` occupy `love.keypressed` and `love.textinput`
when a project runs. Overlay input works as before (via
the sink). Project key events are no longer silently dropped
while the singleton is active. Existing tests pass.

**Files created or modified:**
- `src/projectController.lua` — new file; implements
  `ProjectController` class with `keypressed`, `textinput`,
  `keyreleased` methods; basic sink delegation only (M5
  adds the full dispatch)
- `src/controller.lua` — remove overlay gate; wire
  ProjectController into `set_handlers()` / `love.keypressed`
  slot for project-running states

**Risk:** Largest integration step. The overlay gate
removal touches the main dispatch path. Run full test suite
and manually verify all four app modes (REPL, editor,
project with overlay, project without overlay) before
marking complete.

---

### M5 — Three-level dispatch in `ProjectController`

**Description:** `compy.input.handlers`, `compy.input.on_key_pressed`,
and return-value bubbling implemented in
`ProjectController:keypressed`.

**Input:** M4 complete (ProjectController exists; sink
delegation works).

**Output:** `compy.input.handlers['ctrl+s'] = fn` works.
`compy.input.on_key_pressed` fires for unregistered keys.
Returning truthy from a handler prevents the sink from
running. The shared `dispatch()` function is written and
used by ProjectController.

**Files created or modified:**
- `src/projectController.lua` — add three-level dispatch;
  add `dispatch()` function (shared; ConsoleController and
  EditorController will migrate to it later)
- `src/compy_namespace.lua` (or equivalent) — expose
  `compy.input.handlers` table; expose `compy.input.on_key_pressed`
  and `compy.input.on_text_entered` callback slots

**Risk:** Combo serialisation must match registration format
exactly. Test with multi-modifier combos and with a handler
that returns truthy to verify chain stops.

---

### M6 — Before/after chains for submit and cancel

**Description:** `before_submit`, `after_submit`,
`before_cancel`, `after_cancel` hooks. Escape dismisses
the overlay (current limitation resolved). `on_limit_reached`
fires. `framework_handlers['return']` takes ownership of
submit. **`oneshot` flag deleted** (both its jobs are now
covered — activation by `show()`/`hide()` from M2, submit by
`framework_handlers['return']` here). The reftable fill moves
onto the `after_submit` callback.

**Input:** M4 complete (M5 is independent of M6).

**Output:** All six named hooks fire at correct points.
Escape dismisses the overlay and fires `before_cancel` /
`after_cancel`. Submit fires `before_submit` / `after_submit`
with correct arguments. `on_limit_reached('up'/'down')`
fires when cursor hits boundary. The `oneshot` flag is gone.
Legacy `after_submit` callback fills the reftable correctly.

**Files created or modified:**
- `src/projectController.lua` — add `framework_handlers`
  table; add `'return'` and `'escape'` entries with
  before/after chain logic
- `src/userInputController.lua` — expose limit signal to
  caller; remove submit-path code that reads `model.oneshot`
- `src/userInputModel.lua` — remove `oneshot` field
  (lines ~15, ~49); this is the field's home (the submit-path
  code that reads it is in `userInputController.lua`)

**Risk:** Escape dismiss: ensure `push('userinput')` fires
in the cancel path (it currently fires only on successful
submit with `oneshot`). Verify legacy `after_submit` callback
fills the reftable correctly when the `after_submit` chain runs.

---

### M7 — Extended singleton API

**Description:** `compy.input.configure()`, `compy.input.clear()`,
`compy.input.get_cursor()`, `compy.input.set_cursor()`, and
`compy.input.set_text()` implemented. Live reconfiguration of
validator and highlighter works. Cursor and text can be
programmatically read and written while active (FR-8/9/10).

**Input:** M2 complete. M5/M6 are not required (this is an
API surface extension, not a dispatch change).

**Output:** `compy.input.configure({prompt='new prompt'})` updates
the displayed prompt without tearing down the session.
`compy.input.clear()` resets content and cursor. `compy.input.get_cursor()`
returns `line, col`; `compy.input.set_cursor(line, col)` moves the
cursor. `compy.input.set_text(text [, keep_cursor])` replaces live
content. `write_to_input` (already wired in M3 as a direct
`set_text` call) is re-pointed to `compy.input.set_text` when M7
lands. All work while the singleton is active and when hidden.

**Files created or modified:**
- `src/userInputController.lua` — add `configure()`,
  `clear()`, `get_cursor()`, `set_cursor()`, `set_text()`
  methods; fix `UserInputModel:set_text` to honour
  `keep_cursor` (skip unconditional `jump_end()`)
- `src/compy_namespace.lua` — expose `compy.input.configure`,
  `compy.input.clear`, `compy.input.get_cursor`, `compy.input.set_cursor`,
  `compy.input.set_text`

**Risk:** None. Additive; no routing changes.

---

## Additional Scope

### Documentation updates

- Update `doc/development/internals/` input subsystem docs
  to reflect the new singleton lifecycle, routing model, and
  API surface.
- Update `doc/development/overview.md` architecture section
  if the controller listing or app_state machine description
  needs to account for `ProjectController`.
- Archive or annotate stale wip notes after release
  (primarily `notes/design.md`, `notes/plan.md`).

### Test coverage

Busted tests for:
- `keys_pressed` table: key add/remove, combo serialisation,
  multi-modifier ordering
- Singleton lifecycle: show/hide state, configure fields,
  clear, show-while-active reconfiguration
- Dispatch chain (each level): handler registration,
  return-value bubbling, default callback fires when no
  handler matches
- Legacy API compatibility: reftable filled on submit,
  stays empty on cancel, deprecation warning in debug mode
- Edge cases from `spec.md §7`: stop-while-active, show
  while active, evaluation failure locking behaviour

---

## Estimates

*Implementor assumed: senior engineer, solo. Familiar with Lua
and LÖVE2D. Has read the design and spec documents. Three-point
estimates per line; PERT = (O + 4M + P) / 6, where O = optimistic,
M = most-likely, P = pessimistic. Hours.*

### Without LLM assistance

| Item | O | M | P | PERT |
|---|---|---|---|---|
| M1 `keys_pressed` table | 2 | 3 | 4 | 3.0 |
| M2 Singleton extraction | 3 | 6 | 9 | 6.0 |
| M3 Legacy facades | 2 | 4 | 6 | 4.0 |
| M4 ProjectController + gate removal | 4 | 8 | 14 | 8.3 |
| M5 Three-level dispatch | 3 | 5 | 8 | 5.2 |
| M6 Before/after chains (+ `oneshot` deletion) | 4 | 7 | 11 | 7.2 |
| M7 Extended API (+ cursor surface, model fix) | 3 | 6 | 9 | 6.0 |
| Documentation updates | 4 | 8 | 12 | 8.0 |
| Test coverage | 7 | 11 | 16 | 11.2 |
| **Total** | **32** | **58** | **89** | **≈ 59 h** |

Project PERT (O=32, M=58, P=89): `(32 + 4×58 + 89) / 6 ≈ 59 h`.

Confidence: moderate. M4 is the main uncertainty — the gate
removal touches the central dispatch path, so its pessimistic tail
is the widest; integration surprises drive the spread.

### With LLM assistance

LLM helps most with boilerplate wiring (M1, M3, M7), new-file
scaffolding (M5), test scaffolding, and doc updates. It saves
least on M2 (cross-component refactor verified by hand), M4
(integration; the engineer must trace the dispatch paths), and M6
(ordering semantics).

| Item | O | M | P | PERT | LLM value |
|---|---|---|---|---|---|
| M1 `keys_pressed` table | 1 | 2 | 3 | 2.0 | High |
| M2 Singleton extraction | 2 | 4 | 6 | 4.0 | Low |
| M3 Legacy facades | 1 | 2 | 3 | 2.0 | High |
| M4 ProjectController + gate removal | 3 | 5 | 9 | 5.3 | Medium |
| M5 Three-level dispatch | 2 | 3 | 5 | 3.2 | High |
| M6 Before/after chains (+ `oneshot` deletion) | 2 | 5 | 8 | 5.0 | Low–medium |
| M7 Extended API (+ cursor surface, model fix) | 2 | 4 | 6 | 4.0 | High |
| Documentation updates | 2 | 3 | 5 | 3.2 | High |
| Test coverage | 4 | 6 | 9 | 6.2 | High |
| **Total** | **19** | **34** | **54** | **≈ 35 h** |

Project PERT (O=19, M=34, P=54): `(19 + 4×34 + 54) / 6 ≈ 35 h`.

Confidence: moderate. The saving is largest for well-specified
generative work (M1, M3, M5, M7, tests, docs); the integration
milestones (M2, M4) are serial and verification-heavy, so LLM code
generation speeds them up but the manual verification cost is
largely fixed.
