# Feature #77 — interim debt & open boundaries

_Feature-scoped ledger. Tracks debt and unresolved boundaries **surfaced during #77 implementation**
that are tied to this feature's own milestones — to be **resolved or consciously accepted before the
feature closes**, not carried into the project at large._

> Distinct from [`/doc/development/technical_debt.md`](../../../technical_debt.md), which holds only
> **persistent** debt that survives beyond #77. Anything here is expected to be swept (or formally
> accepted) by the time the new input API ships. When an entry is settled, strike it and fold the
> decision into the relevant milestone's spec/outcome.
>
> **Closure is planned, not just anticipated.** Where a debt item is committed to close at a
> milestone, that closure is **commissioned by an adjacent `MN-NN-<why>.md` spec** (never by editing
> the frozen design-time `MN.md`). Items with no committed closure are marked *accepted* or
> *anticipated*.

## Dispatch map

| Item | Kind | Disposition | Closure |
|---|---|---|---|
| ~~M2-01 approval scope~~ | ~~record accuracy~~ | ~~**closed**~~ | ~~Status line corrected; M2-01 formally signed off~~ |
| F-5 | open boundary | **planned** | adjacent spec [`../design/spec/M7-01-retarget.md`](../design/spec/M7-01-retarget.md) (decided at M7) |
| G-1 | dead code | **planned** | adjacent spec [`../design/spec/M8-01-dead-text-input.md`](../design/spec/M8-01-dead-text-input.md) (M8 legacy removal) |
| G-2 | dead code | **planned** | adjacent spec [`../design/spec/M6-01-oneshot-snapshot.md`](../design/spec/M6-01-oneshot-snapshot.md) (M6 oneshot removal) |
| F-4 | spec deviation | **accepted** | none — ships as a documented deviation |
| `combo_string` alloc | perf | **anticipated** | evaluate at M5 dispatch; close only if hot |
| `gui_k` no consumer | API shape | **anticipated** | decide when `gui`'s modifier status is settled |
| design-doc path mismatch | docs | **anticipated** | opportunistic; or at feature wrap when docs unfreeze |
| overlay test vs. stub | test coverage | **anticipated** | when the real `set_love_update` overlay path is driven (≈M4 dispatch) |
| ~~C-2 empty re-prompt~~ | ~~acceptance gap~~ | ~~**closed**~~ | ~~runtime **confirmed** (turtle, 2026-06-17); unit-test half closed via M2-02~~ |
| turtle `Esc` clears input in place | behaviour / needs-investigation | **anticipated** | characterise intended `Esc` semantics; reconcile with G-B (editor `Esc` does *not* clear) |
| G-A tixy shift+click sequence | UX / needs-investigation | **anticipated** | characterise before the input surface is called author-stable |
| G-B editor buffer not cleared on Escape | possible defect / needs-investigation | **anticipated** | branch-level search first; file as a defect only if confirmed |
| M4-0 `input_session.lua` driver unused | dead code / inconsistency | **open** | M4 test-first step should adopt it as the net's driver, or the net's inline copy is redundant |
| M4-0 keyboard-debounce reimplemented in-test | test coverage | **open** | revisit at M8 keyboard migration; pin the example's own debounce, not a test-local copy |
| M4-0 `mock.keystroke` isrepeat/scancode opts unexercised | test coverage | **anticipated** | path goes live when M4 converts the isrepeat `pending` → live |
| M4-0 maze Lua-command path not black-box characterizable | scope boundary | **anticipated** | M8 scope; routing + `is_empty` covered, so not blocking M4 |
| M4-0 `tests.md` not updated for new emitters | docs | **open** | document `mock.textinput` + `keystroke` opts at M4-0 closure or M4 |

> The **planned** rows have a commissioned closure spec; pick them up with their milestone. The
> **anticipated** rows are deliberately *not* commissioned — they may never need action; revisit at
> the named point and decide then. (Detail blocks for the **planned** items live in their specs; the
> non-spec items are detailed below.)

---

## Open boundaries

### ~~M2-01 outcome ledger overstates the scope of the human approval — **open**~~ **Closed**

- **Where:** `implementation/outcomes/M2-01-restore-mvc.md` — Status line originally read
  "✅ approved by human (2026-06-17)"; now corrected to a scoped statement.
- **State:** Closed. M2-01 code is approved and the C-2 acceptance gap has been closed via M2-02 unit tests.
- **Closure:** M2-01 is formally signed off in session 08.

### ~~M2-01 — C-2 (empty re-prompt): runtime confirmed, unit-test half outstanding — **open (narrowed)**~~ **Closed**

- **Where:** C-2 acceptance; `tests/input/overlay_spec.lua` (the empty-on-reprompt test) and the
  runtime check.
- **State:** C-2's real trigger is a successful `UserInputModel:handle(true)` leaving `entered`
  populated, so the *next* prompt re-opens it pre-filled. The M2-01 fix clears on fresh activation.
  - **runtime → DONE.** Human re-check 2026-06-17 (turtle): submit → terminal closes → reopen with
    `i` → input is **empty**. That submit → close → reopen-empty *is* the C-2 path. Confirmed (see the
    review's runtime addendum). tixy is **not** a usable vehicle — it keeps the terminal always on, so
    no clean submit→reopen cycle; turtle is canonical.
  - **suite → DONE.** Driven by `tests/input/overlay_spec.lua` via a real submit test (M2-02).
- **Why it still stands:** Closed.
- **Closure:** M2-01 + M2-02 jointly closed C-2.

### turtle `Esc` clears the input in place without hiding the terminal — needs-investigation

- **Where:** turtle (oneshot `input_text`) runtime; observed 2026-06-17. Likely the controller
  `cancel()` path (`userInputController.lua:153`).
- **State:** Pressing `Esc` empties the input buffer but leaves the terminal open. Not a C-2
  contradiction (it is neither `hide()` nor `force`, both of which preserve content per `M2.md`), but
  it is the **opposite** of G-B (editor `Esc` does **not** clear) — the two surfaces disagree on what
  `Esc` means.
- **Why it stands:** Intent unverified; may be deliberate (clear-in-place to retype) or incidental.
  Off the M2-01/M2-02 critical path.
- **Revisit:** Characterise the intended `Esc` semantics for the input surface and reconcile with G-B;
  decide whether the editor/oneshot `Esc` behaviours should converge. Commission a spec only if a
  milestone forces the decision.

### F-5 — `force` / `configure()` cannot re-target an active session's `result`/`eval` — **planned → M7-01**

- **Where:** `src/controller/userInputController.lua` — `force` re-applies only `text`; a fresh
  activation runs `apply_config` (eval, prompt, text, result).
- **State:** A running session's `result` sink and evaluator are fixed at `show()`. `M2.md` frames
  `force` purely in terms of content, and `M7.md`'s `configure()` no-ops non-`prompt`/highlighter/
  validator fields while active — so no surface currently re-targets `result`/`eval` mid-session.
- **Closure:** **commissioned** by [`../design/spec/M7-01-retarget.md`](../design/spec/M7-01-retarget.md) — building
  M7's `configure()` forces the decision, so M7-01 commands it be made and written down (extend the
  surface, or document a deliberate fixed-at-`show()` constraint). Strike this entry when M7-01 lands.

---

## Accepted deviations (ship as-is)

### F-4 — `compy.input` is rebuilt per project-env, not "once at namespace setup"

- **Where:** `src/controller/consoleController.lua` — `get_compy_input()` is called from
  `get_compy_namespace()`, which `prepare_project_env()` invokes per project setup, so the
  `compy.input` table is reconstructed each time a project env is prepared.
- **Disposition:** **Accept, no action.** The `show`/`hide` closures resolve
  `love.state.user_input_controller` dynamically, so they always reach the live singleton regardless
  of when the table was built. A wording deviation from M2's "created once at namespace setup", not a
  defect — the dynamic-lookup design is the better call (resilient to the singleton being
  (re)assigned). Recorded so the deviation is understood as intentional, not an oversight.
- **Sweep:** nothing to do; closes with the feature as a documented, accepted deviation.

---

## Anticipated — revisit at the named point, close only if warranted

These are **not** commissioned for closure; they may never need action. No adjacent spec until a
concrete need appears.

### `combo_string` allocates a fresh table per call

- **Where:** `src/controller/controller.lua` — `combo_string` builds a `parts` table and
  `table.concat`s it on every call.
- **State:** Inert today — nothing calls it yet. M5 puts it on the per-keystroke dispatch path
  (`compy.input.handlers[combo]`).
- **Why it stands:** Keystroke dispatch is not a per-frame hot path, so the allocation is acceptable
  for now; `rules.md` flags allocation in `update`/`draw`, not per-event helpers.
- **Revisit:** When M5 wires the consumer — *if* dispatch lands anywhere hot, switch to a reused
  buffer or a concat-free comparison. Until then, leave it.

### `gui_k` modifier pair has no real consumer

- **Where:** `src/util/key.lua` — `gui_k = { "lgui", "rgui" }` (added in M2a). It feeds only
  `mod_triples`; there is no `gui()` / `is_gui()` accessor paralleling `shift()` / `is_shift()`.
- **State:** A defined modifier pair with no behavioural reader. Could be a deliberate constraint
  ("ignore gui keys" as a held modifier) or an expansion point left open for a future `gui()`
  accessor.
- **Why it stands:** Keeping it parallels the established `*_k` pattern and M2a called for the `gui`
  pair explicitly; the asymmetry is harmless and additive.
- **Revisit:** When the input API settles whether `gui` is a first-class modifier — add the
  `gui()` / `is_gui()` accessors, or record that gui is intentionally ignored. If a milestone ends up
  forcing that decision, commission it with an adjacent spec then.

### Design-doc path mismatch: `src/controller.lua`

- **Where:** `design/spec/M1.md`, `design/roadmap.md`, and other 77 design docs reference
  `src/controller.lua`; the real path is `src/controller/controller.lua`.
- **State:** Documentation only; implementation uses the correct path. Noted in the M1 prompt and
  outcomes.
- **Why it stands:** Cosmetic; the design docs are frozen reference for the sprint.
- **Revisit:** Correct opportunistically when those docs are next edited (e.g. at feature wrap, once
  the design slices are no longer frozen).

### M2-01 overlay-shape test runs against a stub, not the real wiring

- **Where:** `tests/input/overlay_spec.lua` — the overlay-shape test builds an ad-hoc `make_ctrl`
  controller with a `draw`-only stub view and asserts `love.state.user_input.V` is truthy and
  callable.
- **State:** Guards against a re-narrowing of the handle to `{ C }` (the take-1 regression), but does
  **not** exercise the `main.lua` startup-singleton wiring or the real `controller.lua:401`
  (`set_love_update`) overlay wrapper — the exact path that faulted at runtime. M2-01's spec set the
  stub level as the floor and named the real-wiring level only as the ideal, so the take is compliant;
  the residual is that the regression net is shape-level, not integration-level. Runtime confirmation
  on `turtle`/`tixy` covered it for this take.
- **Why it stands:** Driving the real `love.draw` overlay from a unit test needs `main.lua` wiring /
  love harness that the input suite does not currently stand up.
- **Revisit:** When a milestone next touches the overlay/dispatch wiring (≈M4, when the controller
  owns dispatch) — add a test that drives the actual `set_love_update` draw wrapper against the
  singleton, closing the slice take 1 first exposed.

### M4-0 — `tests/helpers/input_session.lua` exists but the net does not use it — **open**

- **Where:** `tests/helpers/input_session.lua` (new driver) vs.
  `tests/input/characterization_spec.lua` — the net **inlines a verbatim copy** of the driver
  (`local session = { press/release/type/repeat_press }`) instead of `require`-ing the helper.
  `grep -rn input_session` finds no consumer.
- **State:** The Acceptance bullet "a driver exists **and is used by the net**" is half-met: it
  exists, but the net duplicates it rather than consuming it. Harmless to the green suite, but it is
  dead code today and a DRY breach — and M4/M5/M6 are told to build their test-first steps on this
  driver.
- **Why it stands:** Reviewer does not edit feature code. Cheap to fix (delete the inline copy, add
  `local session = require('tests.helpers.input_session').new()` after the mock_love setup).
- **Revisit:** M4's test-first step — adopt the helper as the net's single driver, or remove it.

### M4-0 — keyboard once-per-press "debounce" is reimplemented in-test, not characterized

- **Where:** `tests/input/characterization_spec.lua` `keyboard once-per-press debounce` —
  `before_each` defines its own `love.keypressed`/`love.keyreleased` with a local `held_keys`
  edge-tracker; the 4 tests then assert against **that test-local logic**, not the `keyboard`
  example's code.
- **State:** The only *production* behaviour these tests pin is handler→`love.keypressed` routing
  (which already duplicates the D-9 tests — see outcome perturbation 2, where breaking routing reds
  both). A regression in the real `keyboard` example's debounce would **not** be caught. The spec
  named this the "best characterization showcase"; as written it does not characterize the example.
- **Why it stands:** Acceptable for guarding **M4–M7** (those rework controller dispatch/routing, and
  the routing teeth are real); the example itself is migrated at M8.
- **Revisit:** When `keyboard` migrates (M8), pin the example's own debounce, driven from its code.

### M4-0 — overlay-mechanism collapse + uncharacterized maze Lua path

- **Where:** tixy/balloons/turtle/editor-REPL/maze-`is_empty` all drive the **same**
  `make_overlay(InputEvalText, …)` path (generic `UserInputController` + `InputEvalText`), differing
  only by typed string — they characterize the overlay submit/cancel mechanism, not the individual
  example projects' wiring (root shared with the *overlay test vs. stub* entry above).
- **State + maze:** Defensible per spec/outcome (same mechanism), but coverage is mechanism-level not
  per-example. Maze's `ctrl_update` / Lua-command path is **not** black-box characterizable without
  loading the project (outcome "Surfaced gaps"). Input to the M4 escalate-vs-black-box call: **not
  blocking** — D-9 routing and `is_empty` polling are covered; the Lua-command path is M8 scope.
- **Revisit:** M8 (full-project characterization) when examples migrate.

### G-A — tixy shift+click example-sequence behaviour unclear

- **Where:** `tixy` running project; reported in
  [`outcomes/M2-01-restore-mvc.md`](outcomes/M2-01-restore-mvc.md) "Surfaced gaps".
- **State:** shift+click is expected to advance through the built-in example sequence, but the
  intended order is not obvious from the UI and may not match expectations. Observed during the
  M2-01 approval run; not reproduced or characterised. **Out of M2-01's scope** — reported, not fixed
  (per `development.md`).
- **Why it stands:** Uncharacterised; may be a UX wrinkle in an example project rather than an input-API
  defect. Not on the M2-01 critical path.
- **Revisit:** Investigate before the input API surface is considered stable for project authors;
  characterise reproducibly, then decide defect vs. expected.

### G-B — editor input buffer not cleared on Escape

- **Where:** the editor input buffer; reported in
  [`outcomes/M2-01-restore-mvc.md`](outcomes/M2-01-restore-mvc.md) "Surfaced gaps".
- **State:** After Escape in the editor, the buffer retains its content rather than emptying. A fix was
  *believed* to exist but is **not present** on this branch (`feature/77-newapi-analysis-s20260615`) —
  may live on another branch or may never have landed. **Out of M2-01's scope** — reported, not fixed.
- **Why it stands:** Surface is the editor, distinct from the oneshot-prompt surface C-2 governs;
  unconfirmed whether it is a regression or a missing-fix. Needs a branch-level search before filing.
- **Revisit:** `git log`/branch search for the believed fix first; if genuinely absent and reproducible,
  file as a defect and decide whether it blocks the feature or is independent of #77.

