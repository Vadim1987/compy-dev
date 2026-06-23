# Feature #77 — Implementation Roadmap

*Scoped to this feature only. Milestones in
implementation-dependency order, matching the section
order in `notes/solution_sketch.md`. Per-milestone estimates
live in [`estimates.md`](estimates.md) (first-class derived
node); the `## Estimates` section below carries only the
frozen design-phase total + the total-estimated log.*

> **Status — derived proposal document.** This roadmap is a derived
> part of the feature-#77 proposal chain, pre-built on the
> assumption the design is endorsed rather than vetoed. Milestone
> boundaries and estimates are provisional: stakeholders may review
> or adjust parts without blocking implementation — there is no
> requirement to freeze the plan before work starts.

---

## Summary — milestones at a glance

*(Full per-milestone detail and file lists are below; three-point estimates live in
[`estimates.md`](estimates.md). Per-milestone **specs** — what each sprint consumes — are in
[`spec/`](spec/). The old M3 (facade) was discarded by D-1; its roadmap slot now carries the
**`M4-0`** characterization-net precondition slice — not a revived M3 (see that section).)*

| # | Name | Deliverable | Key files |
|---|---|---|---|
| M1 | `keys_pressed` table | Live modifier set + `combo_string()` (modifier-first, l/r folded); no behaviour change | `controller.lua` |
| M2 | Singleton extraction | Widget created once; `compy.input.show`/`hide` on namespace; `oneshot` stays | `main.lua`, `consoleController.lua`, `userInputController.lua`, `compy_namespace.lua` |
| M2a | M1 follow-up hygiene | Drop dead profiler test stub; single source of truth for l/r modifier fold; no behaviour change | `controller.lua`, `util/key.lua`, M1 test |
| M4-0 | Characterization net + harness extension (precondition slice) | Tier-1 feature-global safety net pinning current input-path behaviour + keypress-level driver/mock emitters; guards M4 | `tests/helpers/input_session.lua` (new), `tests/mock.lua`, `tests/input/characterization_spec.lua` (new) |
| M4 | ProjectInputController + gate removal | New controller owns project input; overlay gate removed; all 4 modes verified | `controller.lua`, `projectInputController.lua` (new) |
| M5 | Three-level dispatch | `handlers[combo]` + `on_key_pressed`; return-value bubbling | `projectInputController.lua`, `compy_namespace.lua` |
| M6 | Before/after chains | Submit/cancel hooks; Escape dismisses; `on_limit_reached(direction,scope)`; `framework_handlers['return']` owns submit; `oneshot` deleted | `projectInputController.lua`, `userInputController.lua`, `userInputModel.lua` |
| M7 | Extended singleton API | `configure`/`clear`/`get_cursor`/`set_cursor`/`set_text` | `userInputController.lua`, `compy_namespace.lua` |
| M8 | Legacy removal + migration | Globals removed; `tixy`/`balloons` migrated (priority), others convert-or-exclude; native examples unaffected (D-9) | `consoleController.lua`, `src/examples/*` |

**Estimates** are a first-class derived node — full per-milestone PERT lives in
[`estimates.md`](estimates.md) (+ [`estimates.versions/`](estimates.versions/)). This roadmap keeps
only the **frozen design-phase total** and an **append-only log** of recalculated totals; see
[`## Estimates`](#estimates) below. (Design-phase total: **≈ 66 h** without LLM, **≈ 39 h** with;
widest tail M4, then M8.)

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
startup (lazily). The widget is no longer created on each
input call. `compy.input.show()` and `compy.input.hide()` are
available on the namespace (required before later milestones
use them). `show()` on an already-active singleton is a no-op
unless called with `{ force = true }` (round 2 — D-2). Existing examples still work at this point (the
legacy globals are untouched until M8); allocation-per-session
is gone. Existing tests pass. The `oneshot` flag is **not**
removed in this milestone — it continues to drive submit
through M2–M5.

**Files created or modified:**
- `src/main.lua` — create singleton instance at startup
- `src/consoleController.lua` — remove per-call
  construction; wire to singleton
- `src/userInputController.lua` — `show()`/`hide()` state
  change methods added
- `src/compy_namespace.lua` (or equivalent) — create the
  `compy.input` table once at namespace setup; mount
  `compy.input.show` and `compy.input.hide` on it

**Risk:** Care needed to preserve `love.state.user_input`
set/clear behaviour. Existing tests exercise this path;
run all before and after.

---

### M2a — M1 follow-up hygiene

**Description:** Two cleanups surfaced by the M1 review,
scoped on their own rather than folded into M2 (which touches
none of these files). Zero behaviour change.

**Input:** M1 complete. Independent of M2 — can run in
either order.

**Output:** The dead `controller.profiler` stub is removed
from the M1 test (verified unnecessary: suite is 685/685
without it). The l/r modifier fold has a single source of
truth — `util/key.lua` exports the `(left, right, generic)`
triples (gaining a `gui` pair) and `combo_string` consumes
them, dropping its duplicate `COMBO_MODS` literal. All
existing tests pass; `combo_string` output unchanged.

**Files created or modified:**
- `tests/input/keys_pressed_spec.lua` — remove the
  `controller.profiler` preload block
- `src/util/key.lua` — add the `gui` pair; export modifier
  triples in precedence order
- `src/controller/controller.lua` — replace the local
  `COMBO_MODS` with the exported triples

**Risk:** None. Refactor plus test cleanup; run the full
suite before and after.

Spec: [`spec/M2a.md`](spec/M2a.md).

---

### M4-0 — feature-global characterization net + harness extension (precondition slice)

*(This is the roadmap's old **M3 slot**. The original M3 — backward-compatible facade wrappers — was
**discarded by D-1** (`input.md`, SR1, 2026-06-06): no backward compatibility, so no facades; the legacy
globals are **removed** and examples migrated instead — that work moved to **M8**. The slot is **not**
left empty and is **not** a revived M3: reusing a dead id for a live test-net would overload it. It now
carries the **`M4-0` precondition slice** — the Tier-1 characterization net, authored *before* M4. The
`-0` suffix = precondition/pre-net, vs the `-01+` corrective/closure slices that ride *after* a milestone
(`agents/process.md §9`). Cross-refs that pointed at "the M3 slot" now resolve here.)*

**Description:** Tier-1 of the two-tier test strategy — a feature-global **characterization safety net**
pinning the existing, organically-grown input-path behaviour (oracle = **current runtime**, no spec)
*before* M4 touches the path, plus the **harness extension** that makes driving a project-level input
flow possible at all. Protects M4–M7 by contract; evolves at M8 (baselines re-pinned).

**Input:** M2 complete (stable singleton) + the existing busted harness. **Precedes M4** — it is M4's
guardrail (what makes the black-box M4 safe).

**Output:** A keypress-level driver (`tests/helpers/input_session.lua`) drives the real
`love.handlers.{keypressed,textinput,keyreleased}` slots — the raw-handler pattern per
`keys_pressed_spec`, **not** an `EditorSession` generalisation (that helper is editor-block-nav-specific
and bypasses the love slots). `mock.lua` can emit `textinput` **independently of** `keypressed`
(order-independent — P1) and emit a **repeat** (`isrepeat`/`scancode`). The characterization suite is
**green against current code** for the example flows (tixy/balloons/turtle + Esc/editor REPL), the
`keyboard` example, editor `is_at_limit` vertical block-nav, D-9 (`pong`) and `maze`. One **forward**
assertion — *`isrepeat` reaches the keypressed path* — is **red until M4 threads it** (the regression-undo
guardrail), and is the only red assertion against current code.

**Files created or modified:**
- `tests/helpers/input_session.lua` — **new**; keypress-level driver over the installed
  `love.handlers.*` slots (raw-handler pattern)
- `tests/mock.lua` — extend: order-independent `textinput` emission, `isrepeat`/`scancode` emission
- `tests/input/characterization_spec.lua` (+ as needed) — **new**; the feature-global net
- (reuse, **unchanged**) `tests/helpers/editor_session.lua` — used **only** for the editor block-nav
  coverage item, not as the harness base

**Risk:** Medium-infra, low-design — the work is harness capability, not new feature logic. Chief trap:
a synchronous harness baking in a keypressed→textinput order the device doesn't honour (P1) → false-green;
the net must **not** encode that ordering as an invariant.

Spec: [`spec/M4-0-characterization-net.md`](spec/M4-0-characterization-net.md). Sizing: [`estimates.md`](estimates.md).

---

### M4 — `ProjectInputController` introduction and overlay gate removal

**Description:** New controller for the project-running
context. The `if user_input then` gate in `controller.lua`
is removed. Routing becomes symmetric.

**Input:** M2 complete (singleton stable) **and `M4-0` green** — the
characterization net is M4's guardrail (it is what makes the black-box
M4 safe; escalate only if M4-0 proves the integration can't be
characterized). The old M3 facade was never a functional dependency.

**Test guardrail:** M4 runs **black-box** against the `M4-0` net + manual
4-mode verification (REPL / editor / project+overlay / project no-overlay).
M4 also **threads `isrepeat`/`scancode`** through the harvest wrapper
(`controller.lua:554`), flipping M4-0's one red assertion green.

**Output:** `ProjectInputController:keypressed` and
`:textinput` occupy `love.keypressed` and `love.textinput`
when a project runs. Overlay input works as before (via
the sink). Project key events are no longer silently dropped
while the singleton is active. Existing tests pass.

**Files created or modified:**
- `src/projectInputController.lua` — new file; implements
  `ProjectInputController` class with `keypressed`, `textinput`,
  `keyreleased` methods; basic sink delegation only (M5
  adds the full dispatch)
- `src/controller.lua` — remove overlay gate; wire
  ProjectInputController into `set_handlers()` / `love.keypressed`
  slot for project-running states

**Risk:** Largest integration step. The overlay gate
removal touches the main dispatch path. Run full test suite
and manually verify all four app modes (REPL, editor,
project with overlay, project without overlay) before
marking complete.

---

### M5 — Three-level dispatch in `ProjectInputController`

**Description:** `compy.input.handlers`, `compy.input.on_key_pressed`,
and return-value bubbling implemented in
`ProjectInputController:keypressed`.

**Input:** M4 complete (ProjectInputController exists; sink
delegation works).

**Test-first (Tier 2):** acceptance tests authored from the frozen
[`spec/M5.md`](spec/M5.md) run **before** implementation — red suite first,
implementation turns it green. The test step may run on a **cheaper model**
(it transcribes a fixed spec into assertions). See `agents/process.md §9`.

**Output:** `compy.input.handlers['ctrl+s'] = fn` works.
`compy.input.on_key_pressed` fires for unregistered keys.
Returning truthy from a handler prevents the sink from
running. The shared `dispatch()` function is written and
used by ProjectInputController.

**Files created or modified:**
- `src/projectInputController.lua` — add three-level dispatch;
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
`framework_handlers['return']` here).

**Input:** M4 complete (M5 is independent of M6).

**Test-first (Tier 2):** acceptance tests authored from the frozen
[`spec/M6.md`](spec/M6.md) run **before** implementation — red suite first,
implementation turns it green. Test step may run on a **cheaper model**.
See `agents/process.md §9`.

**Output:** All six named hooks fire at correct points.
Escape dismisses the overlay and fires `before_cancel` /
`after_cancel`. Submit fires `before_submit` / `after_submit`
with correct arguments. `on_limit_reached(direction, scope)`
fires when the cursor hits a boundary — `direction` up/down/left/
right, `scope` input/line (round 2; was up/down whole-input only).
The `oneshot` flag is gone.

**Files created or modified:**
- `src/projectInputController.lua` — add `framework_handlers`
  table; add `'return'` and `'escape'` entries with
  before/after chain logic
- `src/userInputController.lua` — expose limit signal to
  caller (now carrying `direction` + `scope`); remove submit-path
  code that reads `model.oneshot`
- `src/userInputModel.lua` — remove `oneshot` field
  (lines ~15, ~49); **extend `is_at_limit`** (line ~558) from
  vertical-only to also report horizontal (`'left'`/`'right'`,
  first/last character) and line-scope vs input-scope boundaries
  (round 2 — D-5); the existing vertical whole-input case is
  unchanged

**Risk:** Escape dismiss: ensure `push('userinput')` fires
in the cancel path (it currently fires only on successful
submit with `oneshot`). Boundary extension: the horizontal /
line-scope cases are new `is_at_limit` logic; keep the existing
vertical whole-input semantics (the editor's block navigation
depends on them) intact.

---

### M7 — Extended singleton API

**Description:** `compy.input.configure()`, `compy.input.clear()`,
`compy.input.get_cursor()`, `compy.input.set_cursor()`, and
`compy.input.set_text()` implemented. Live reconfiguration of
validator and highlighter works. Cursor and text can be
programmatically read and written while active (FR-8/9/10).

**Input:** M2 complete. M5/M6 are not required (this is an
API surface extension, not a dispatch change).

**Test-first (Tier 2):** acceptance tests authored from the frozen
[`spec/M7.md`](spec/M7.md) run **before** implementation — red suite first,
implementation turns it green. Test step may run on a **cheaper model**.
See `agents/process.md §9`.

**Output:** `compy.input.configure({prompt='new prompt'})` updates
the displayed prompt without tearing down the session.
`compy.input.clear()` resets content and cursor. `compy.input.get_cursor()`
returns `line, col`; `compy.input.set_cursor(line, col)` moves the
cursor. `compy.input.set_text(text [, keep_cursor])` replaces live
content. All work while the singleton is active and when hidden.
`compy.input.set_text` is the live-write surface that replaces the
removed `write_to_input` (see M8).

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

### M8 — Legacy text-input removal and example migration

**Description:** Remove the legacy text-input globals and migrate
the in-repo examples that use them to the `compy.input.*` callback
API. D-1 discarded — no backward compatibility (`input.md`,
feedback round 1).

**Input:** M6 and M7 complete. This milestone needs the **full**
`compy.input.*` surface — `show()` with `validator`/`highlighter`
config (M2 + M7), the submit/cancel callbacks (M6), and
`set_text`/cursor (M7) — because migrating the examples depends
on all of it. It is therefore the last milestone.

**Output:**
- `input_text()`, `input_code()`, `validated_input()`,
  `user_input()`, and `write_to_input()` are removed from the
  project environment. `love.state.user_input` is driven solely
  by `compy.input.show()`/`hide()`.
- **Priority examples migrated (release-blocking):** `tixy`
  (uses `input_code` + `write_to_input` + `user_input`) and
  `balloons` (uses `input_text` + `user_input`). `maze` is named
  by stakeholders as a showcase but is not in this repo; it is
  migrated on arrival (out of current repo scope).
- **Convert-or-exclude (owner's release call, per `input.md`):**
  `repl`, `guess`, `valid` (trivial REPL conversions) and
  `turtle` (its `input_text` use migrates; its native
  `love.keypressed` movement keeps working under D-9). Any not
  converted in time are excluded from the next release rather
  than blocking it.
- **Unaffected:** examples that use only native
  `love.keypressed`/`love.textinput` (`pong`, `life`, `paint`,
  `sapper`, `sine`, `clock`, `drawdebug`) — D-9 coexistence
  applies; "only text fields" break.

**Files created or modified:**
- `src/consoleController.lua` — remove the five legacy entry
  points (`user_input`, `input_text`, `input_code`,
  `validated_input`, `write_to_input`)
- `src/examples/tixy/`, `src/examples/balloons/` — migrate to
  `compy.input.*` (priority); `src/examples/{repl,guess,valid,turtle}/`
  — migrate or mark excluded

**Risk:** The examples are the only consumers, so the blast
radius is contained. There is a window (M4 onward) where
the text-input examples do not run on the in-development build;
this is internal and acceptable (the work is unreleased and old
releases remain available — `input.md`). The reftable / polling
idiom disappears from the example corpus.

---

## Additional Scope

### Documentation updates

- Update `doc/development/internals/` input subsystem docs
  to reflect the new singleton lifecycle, routing model, and
  API surface.
- Update `doc/development/overview.md` architecture section
  if the controller listing or app_state machine description
  needs to account for `ProjectInputController`.
- Archive or annotate stale wip notes after release
  (primarily `notes/design.md`, `notes/plan.md`).

### Test coverage

Busted tests for:
- `keys_pressed` table: key add/remove, combo serialisation,
  multi-modifier ordering
- Singleton lifecycle: show/hide state, configure fields,
  clear, show-while-active (no-op by default; `force=true`
  reconfigures)
- Dispatch chain (each level): handler registration,
  return-value bubbling, default callback fires when no
  handler matches
- `on_limit_reached`: all four directions (up/down/left/right)
  at both scopes (input/line); single-line collapses line→input
  (round 2)
- Example migration (M8): the priority examples (`tixy`,
  `balloons`) run on the `compy.input.*` callback API; the legacy
  globals are gone (calling `input_text` etc. is now a `nil`
  call); native-handler examples still work via D-9
- Edge cases from `spec.md §7`: stop-while-active, show
  while active, evaluation failure locking behaviour

---

## Estimates

*Estimates are a **first-class derived node** of this lifecycle — the full per-milestone PERT
(both bases, deltas, confidence, methodology) lives in [`estimates.md`](estimates.md), versioned
under [`estimates.versions/`](estimates.versions/). This section is deliberately thin: it carries
only the frozen design-phase total and the running total-estimated log, never a re-derived table
(`agents/process.md` §7).*

### Design-phase total — FROZEN (historical artifact)

The project total as sized **at design convergence** (session-10 baseline, carried verbatim into
`estimates.md version01`). This figure is a **historical artifact — it is never recalculated in
place.** Later sizing changes are recorded in the log below, not by editing this number.

| Basis | Design-phase total (PERT) |
|---|---|
| Without LLM assistance | **≈ 66 h** |
| With LLM assistance | **≈ 39 h** |

> Provenance: PERT = (O+4M+P)/6 over the per-milestone three-point estimates. Discarding D-1
> *raised* the total (the ≈ 4 h facade layer → ≈ 8 h M8); round-2 D-5 boundary work added ≈ 2–3 h.
> Full derivation: [`estimates.md`](estimates.md).

### Total estimated — log (append-only)

The **current** derived total, recomputed whenever the milestone set changes (a milestone added or
pivoted — e.g. `M3-01`) or on periodic review. Each estimates recalc writes an
`estimates.versions/` baseline and **appends one line here** — the latest line is the live total.
This log is *derived* (a dated transcription of `estimates.md`'s total at each version), not an
independently maintained figure. Maintenance is operational entrypoint **E11**.

| Date | Total (no-LLM / LLM) | Baseline | Trigger |
|---|---|---|---|
| 2026-06-18 | ≈ 66 h / ≈ 39 h | [`version01`](estimates.versions/version01.md) | Genesis — extraction (E10). Equals the frozen design-phase total; no milestone change since convergence. |
| 2026-06-23 | ≈ 74 h / ≈ 44 h | [`version02`](estimates.versions/version02.md) | E16 propagation — **`M4-0`** characterization net + harness extension added (E9 sizing: modest harness + suite). M5/M6/M7 gain test-first acceptance steps (re-sequenced from the existing Test-coverage bucket — no volume delta). Delta +≈ 8 h / +≈ 5 h = M4-0. |
