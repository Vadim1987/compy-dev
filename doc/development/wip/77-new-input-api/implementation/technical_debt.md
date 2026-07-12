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
| ~~F-5~~ | ~~open boundary~~ | ~~**closed**~~ | ~~`configure()` landed the live-reconfigure surface; `result`/`eval` stay fixed at `show()` by design, documented, no partial/silent path~~ |
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
| ~~M4-0 `input_session.lua` driver unused~~ | ~~dead code / inconsistency~~ | ~~**closed**~~ | ~~M4-0-01 landed: `input_routing_spec.lua:113` requires the helper; inline copy removed (commit `38b8710`)~~ |
| ~~M4-0 keyboard-debounce reimplemented in-test~~ | ~~test coverage~~ | ~~**closed**~~ | ~~M4-0-01 deleted the in-test reimpl (commit `38b8710`); example's own debounce = M8 / M5a forward acceptance~~ |
| editor sets input-widget cursor outside the project API | API consistency / open design Q | **anticipated** | route the editor's cursor-set through `compy.input.set_cursor` (M7 surface) **or** keep separate — **placement undecided** (may ride M7 or be postponed); decide when M7's cursor API is built |
| M4-0 `mock.keystroke` isrepeat/scancode opts unexercised | test coverage | **anticipated** | path goes live when M4 converts the isrepeat `pending` → live |
| M4-0 maze Lua-command path not black-box characterizable | scope boundary | **anticipated** | M8 scope; routing + `is_empty` covered, so not blocking M4 |
| M4-0 `tests.md` not updated for new emitters | docs | **open** | document `mock.textinput` + `keystroke` opts at M4-0 closure or M4 |
| M4-0-03 P5 touch not black-box expressible | test coverage | **anticipated** | greens when a touch consumer lands (carried `pending` in the suite) |
| M4-0-03 "force does not warn" (C2) coverage dropped | test coverage | **accepted** | inverse of the kept warn-on-suppress P10 row; restore only if the C2 force-path needs an explicit guard |
| M4-0-04 fixture-ergonomics (bootstrap refs / naming) | test coverage / ergonomics | **anticipated** | non-blocking; revisit if the fixture's standup grows harder to follow |
| M4-0-04 editor keypressed EXCLUSIVE sibling missing | test coverage | **open** | add the missing editor `keypressed` sibling test + retitle the mislabeled one (review `M4-0-04.md` Finding 1) |
| M4-0-04 `F.reset()` exceeds 14-line body limit | rules (hard limit) | **open** | extract native-slot restore into a helper (review `M4-0-04.md` Finding 2) |
| `implementation/prompts/M4.md` names the pre-rename suite + superseded Group vocabulary | docs | **open** | reconcile file name (`input_contracts_spec.lua`) + Bucket A-D vocabulary before M4 is commissioned (review `M4-0-04.md`) |
| M5c-01 `active_keyboard_route()` accessor + `stop names the console` row kept green (E30 Scope-10(a) said drop the C23 assertion + retarget to AC-29) | spec deviation / test scope | **planned** | route-connection-lifecycle chunk (chunk 4, AC-29): drop the accessor + its assertion, retarget the row to the full teardown contract. Behaviour independently covered green by the PRESERVE row `the console receives after stop` |
| M5c-01 AC-29 full teardown (participants unwired on stop) not implemented | anticipated gap | **planned** | route-connection-lifecycle chunk (chunk 4). `F.reset()`/`reset_chain()` clears the route at fixture scope so tests isolate; production teardown lands with chunk 4 |
| M5c-01 AC-33 allowlist admits only `handlers.*` + three `on_*` | intentional incremental | **planned** | chunk 3 will widen to include `before_*`/`after_*` submit/cancel callbacks |
| M5c-01 `keys_pressed` proxy: `pairs()` yields nothing under LuaJIT/5.1 (`__pairs` unsupported) | platform caveat | **accepted** | read-index + write-raise (the load-bearing AC-8 contract) hold; `__pairs` kept for 5.2+. Revisit only if a consumer must iterate the held set on this host |
| M5c-01 `combo_string` does not lower-case the trigger token | edge | **anticipated** | an upper-case *textinput* combo would not match a normalised lower-case registration; textinput combos are "rarely useful" (spec §2). Revisit if a real consumer appears |
| ~~M5c-02 `UserInputModel:is_at_limit` exceeds 14-line body limit~~ | ~~rules (hard limit)~~ | ~~**closed**~~ | ~~M5c-02c-corrective refactored the body to 14 lines, AC-15 matrix kept green~~ |
| ~~M5c-02 `show(config) and fields share one output slot` test is incomplete~~ | ~~test coverage~~ | ~~**closed**~~ | ~~M5c-02c-corrective added sibling slot-sharing rows for `on_text_entered` and `validator`~~ |
| ~~M5c-02 line length limit violations in code and comments~~ | ~~rules (hard limit)~~ | ~~**closed**~~ | ~~M5c-02c-corrective: the 322 REVIEW comment was resolved (noop default installed, marker deleted); the 65-char test declaration shortened~~ |

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

### ~~F-5 — `force` / `configure()` cannot re-target an active session's `result`/`eval`~~ — **Closed**

- **Where:** `src/controller/userInputController.lua` — `force` re-applies only `text`; a fresh
  activation runs `apply_config` (eval, prompt, text, result); the new
  `UserInputController:configure` feeds `apply_config` a filtered table (`prompt`,
  `highlighter`, `validator`, `on_text_entered`, `on_limit_reached` only).
- **State:** Closed. The live-reconfigure surface (`compy.input.configure`/`clear`) landed with the
  boundary **deliberately not extended**: `result`/`eval` stay fixed at `show()` — `configure()`
  never reaches them, on an active session or a hidden one. This is the Contract's one-rule
  reading (live-updatable = prompt/highlighter/validator/widget-output callbacks, full stop), not a
  special case for `result`/`eval`.
- **Closure:** Documented in `doc/development/internals/user_input.md` (`### compy.input namespace`
  → `configure(config)`): the live-updatable set is named explicitly, and "no partial application"
  is stated as a standing rule — every path either applies a field in full or drops it in full,
  never a half-applied config. No path re-targets `result`/`eval` mid-session, by design.

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

### ~~M4-0 — `tests/helpers/input_session.lua` exists but the net does not use it~~ — **Closed**

- **Where:** was `tests/input/characterization_spec.lua` (inlined a verbatim copy of the driver).
- **State:** Closed by M4-0-01. The rewritten `tests/input/input_routing_spec.lua` consumes the
  helper via `require('tests.helpers.input_session')` (`:113`, `:130`); the inline copy is gone with
  the deleted char-net file. Reviewer-verified (commit `38b8710`).
- **Residual (minor, not reopened):** the helper was **not** trimmed to the methods the reduced suite
  uses — `release` and `repeat_press` have no live consumer yet. The implementer's judgement call
  (outcome ledger): keep the cohesive driver intact because the M4 gate-rewrite converts the
  `isrepeat` / restoration pendings, which `repeat_press` / `release` exist to drive; trimming then
  re-adding is churn. Accepted — it is a consumed helper, not dead-copy; the DRY breach is resolved.

### ~~M4-0 — keyboard once-per-press "debounce" is reimplemented in-test, not characterized~~ — **Closed**

- **Where:** was `tests/input/characterization_spec.lua` `keyboard once-per-press debounce` (a
  test-local `held_keys` edge-tracker asserting its own logic, not the example's).
- **State:** Closed by M4-0-01 — the in-test reimplementation was deleted with the char-net file
  (commit `38b8710`); `grep held_keys tests/` finds no consumer. The once-per-press *intent* is not
  lost: it is the M5a `on_key_pressed` forward-acceptance thread, and the real `keyboard` example's
  own debounce is characterized when it migrates at M8 (driven from the example's code, not in-test).

### M4-0 — overlay-mechanism collapse + uncharacterized maze Lua path

- **Where:** tixy/balloons/turtle/editor-REPL/maze-`is_empty` all drive the **same**
  `make_overlay(InputEvalText, …)` path (generic `UserInputController` + `InputEvalText`), differing
  only by typed string — they characterize the overlay submit/cancel mechanism, not the individual
  example projects' wiring (root shared with the *overlay test vs. stub* entry above).
- **State + maze:** The mechanism-collapse half is now **moot** — M4-0-01 deleted the per-example
  overlay rows (the char-net no longer pins example submit behaviour, which product-BC withdrew). The
  maze `ctrl_update` / Lua-command path remains **not** black-box characterizable without loading the
  project (outcome "Surfaced gaps"); that is M8 scope and does not block M4 (routing is now covered by
  the front-tests' real-controller assertions).
- **Revisit:** M8 (full-project characterization) when examples migrate.

### Editor's input-widget cursor is set outside the project cursor API — open design Q (placement undecided)

- **Where:** the editor sets the cursor *inside the input widget* via its own path; the project-facing
  cursor surface is `compy.input.get_cursor` / `set_cursor` (FR-8/9, D-8), scheduled at **M7**.
- **State:** Two code paths can move the same widget cursor — the editor's internal one and (once built)
  the project API. Surfaced in the session-24 M4-0 review. **Not a dropped requirement** — the
  project-facing cursor API is fully in the chain (requirements/design/M7); this is about whether the
  editor's own cursor-setting should *consolidate onto* that API or stay separate.
- **Why it stands:** It's an M7-era consistency call, not M4 scope. **Placement deliberately left open:**
  it may ride M7 when the cursor API is implemented, or be postponed past it — no final decision now.
- **Revisit:** When M7's `set_cursor`/`get_cursor` surface is built — decide consolidate-vs-separate and
  record it; commission an adjacent spec only if M7 forces the call.

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

### M4-0-03 — touch not black-box expressible today — anticipated

- **Where:** `tests/input/input_contracts_spec.lua:259` (renamed from `input_routing_spec.lua` by
  M4-0-04) — the `pointer exclusive to the active route` block carries
  `pending('touch reaches the active route')`. (Updated by the M4-0-04 review: the row's framing moved
  from the retired inter-route "BOTH" model to active-route EXCLUSIVE, tracking the
  `input-contracts.md` correction; the underlying gap is unchanged.)
- **State:** Both the widget and the route touch handlers are no-op TODO stubs
  (`userInputController` / `consoleController`), so touch delivery mutates no observable state
  anywhere; a delivery probe would be the method-name spy Bucket A forbids. The §3.6 *delivery*
  contract is therefore not expressible on the current public surface. The contract record's own §3.6
  frames touch as delivery-only with no-op handlers, so this is consistent with the record, not a
  contradiction. Surfaced by the implementer; logged here per the review process.
- **Why it stands:** No observable seam exists until a touch consumer lands; carrying it `pending`
  keeps the contract visible without a mechanism spy.
- **Revisit:** Green the row when a real touch consumer is wired (the mouse EXCLUSIVE rows already guard
  the pointer-delivery shape M4 must not break).

### M4-0-04 — fixture-ergonomics debt not previously logged — anticipated

- **Where:** `tests/helpers/input_fixture.lua` — the standup boilerplate (`require_modules` /
  `build_console` block) and the `F` table name.
- **State:** The owner's `-- REVIEW:` symptoms asked whether the ~35-line standup should reference exact
  `main.lua` bootstrap lines or be wrapped as a named `mock_compy_bootloading`-style seam, and whether
  `F` / `compy_input` naming risks confusion with the real `compy` namespace. M4-0-04 resolved the
  symptoms it could resolve structurally (removed the stale comments) but left the naming/traceability
  question itself unresolved — reported, not fixed (report-don't-fix).
- **Why it stands:** Cosmetic/ergonomic; does not affect correctness or coverage.
- **Revisit:** If the fixture's standup grows harder to trace to `main.lua`, or the `F`/`compy_input`
  naming causes real confusion, address opportunistically.

### M4-0-04 — editor keypressed EXCLUSIVE has no sibling test — open

- **Where:** `tests/input/input_contracts_spec.lua:87-93` — `it('editor mode routes keys to the
  editor', ...)` drives `F.session.type('q')` (`textinput`), not `F.session.press` (`keypressed`).
- **State:** The keypressed EXCLUSIVE contract (§3.1) has sibling coverage for console (`:80`) and
  project (`:95`) but **not** editor — despite `ConsoleController:keypressed` genuinely branching to
  `self.editor:keypressed(k)` in editor mode (`consoleController.lua:1033-1034`), so the sibling is both
  meaningful and missing. The suite's own banner comment and the outcome ledger both claim full
  3-route sibling coverage for §3.1-3.3; that claim overstates what is asserted for keypressed. Full
  detail in review `M4-0-04.md`, Finding 1.
- **Why it stands:** Not blocking merge of the corrected-content rewrite itself, but this is exactly the
  regression net M4's gate-removal will lean on.
- **Revisit:** Add the missing test + retitle the mislabeled one before M4 begins.

### M4-0-04 — `F.reset()` exceeds the 14-line function-body hard limit — open

- **Where:** `tests/helpers/input_fixture.lua:198-217`.
- **State:** Was 10 code lines pre-M4-0-04; this slice added 5 native-slot restores +
  `CC.editor.input:clear()`, bringing it to 16 code lines against `agents/rules.md`'s 14-line hard
  limit. Full detail in review `M4-0-04.md`, Finding 2.
- **Why it stands:** Mechanical, not a design question — `rules.md`: "redesign, don't raise the limit."
- **Revisit:** Extract the native-slot restores into a small helper; trivial, test-only fix.

### `implementation/prompts/M4.md` names the pre-rename suite + superseded vocabulary — open

- **Where:** `implementation/prompts/M4.md` §"Read first" item 5 and "Boundaries" — names
  `tests/input/input_routing_spec.lua` (renamed to `input_contracts_spec.lua` by M4-0-04) and the
  "Group 1"/"Group 2" vocabulary from the `M4-0-01`/`M4-0-02` era, superseded by M4-0-03/M4-0-04's
  Bucket A-D model.
- **State:** Not a defect of M4-0-04 (out of its boundaries to edit another milestone's prompt); found
  by the M4-0-04 review, not the implementer.
- **Why it stands:** Will mislead the M4 cold-implementer (grepping for a file that no longer exists) if
  handed out as-is.
- **Revisit:** Reconcile file name + vocabulary before `prompts/M4.md` is commissioned to an executor.

### M4-0-03 — singleton_spec's "force does not warn" (C2 boundary) not re-homed — accepted

- **Where:** old `tests/input/singleton_spec.lua` had a `force=true ⇒ warned == 0` row (the sanctioned
  override must **not** warn). The re-authored P10 block keeps the warn-on-suppression assertion
  (non-force re-show warns once) and the force-reapplies-text assertion, but does **not** re-assert the
  zero-warn boundary on the force path.
- **Why it stands:** It is the inverse of a kept contract and low-risk; the C2 "warn-on-suppression,
  never silent" guarantee is still covered by the kept non-force row.
- **Revisit:** Restore an explicit force-path no-warn assertion only if the force/reconfigure surface
  evolves (M7 `configure()`) and the boundary needs re-pinning.

### ~~M5c-02 — `UserInputModel:is_at_limit` exceeds the 14-line function-body hard limit~~ — **Closed**

- **Where:** `src/model/input/userInputModel.lua:559-573`.
- **State:** Closed by M5c-02c-corrective. `is_at_limit` was refactored to a
  14-line body (`get_cursor_pos()` replaces the two separate getter calls,
  the horizontal branches collapsed to `cc == 1 and (req == 'line' or cl ==
  1)` / the `elseif` mirror). No assertion was added or loosened; the AC-15
  boundary matrix (`tests/input/input_contracts_spec.lua`) and the full
  suite stayed green before and after.

### ~~M5c-02 — `show(config) and fields share one output slot` test is incomplete~~ — **Closed**

- **Where:** `tests/input/input_contracts_spec.lua:1118-1131` (original),
  extended with four sibling rows.
- **State:** Closed by M5c-02c-corrective. Added `show(config) shares
  on_text_entered slot`, `field write shares on_text_entered slot`,
  `show(config) shares validator slot`, `field write shares validator
  slot` — each drives `F.compy_input()` (real production ingestion), not a
  stub, and asserts identity through both the config-key and the direct
  field-write path, matching the existing `on_limit_reached`/`highlighter`
  pattern. Both remain settable-only here (no firing/gating assertion) —
  that is chunk 3.

### ~~M5c-02 — line length limit violations in code and comments~~ — **Closed**

- **Where:** `src/controller/userInputController.lua:322` and
  `tests/input/input_contracts_spec.lua:1229` (the trap-relevant sibling at
  `:1245` was already ≤64 chars and untouched).
- **State:** Closed by M5c-02c-corrective. The test declaration was
  shortened to `'left at first-line start has input scope'` (61 chars),
  same assertion, unchanged behaviour under test. The 322 REVIEW comment
  was resolved rather than just wrapped: `UserInputController`'s
  constructor now seeds `on_limit_reached = noop` (the existing global
  `util.lua` noop, `require("util.lua")` added), so `emit_limit` no longer
  needs the `if on_limit then …` guard and became an unconditional alias —
  the marker's own suggestion, applied. The default is set once at
  construction (the overlay controller is a true singleton, `main.lua:364`)
  so `apply_config`'s existing `if cfg.field ~= nil then self.field =
  cfg.field end` pattern — which preserves a prior field/config write
  across a hide()/re-show() cycle — is untouched; only the pre-any-write
  starting value changed from `nil` to a no-op function.



### `submit()` deliver-then-hide ordering forces example-side deferral of any reshow — API-ergonomics observation (M5c-05 review)

- **Where:** `src/controller/userInputController.lua:341-342` (`submit()` calls
  `deliver(self, text)` then `self:hide()`); re-entry guard at `:254-259`.
- **What:** `on_text_entered` fires while the overlay is still active, and
  `submit()` unconditionally `hide()`s right after. So an example that wants to
  "reshow with the same text on invalid input" cannot call `compy.input.show{...}`
  synchronously inside its callback (the re-entry guard suppresses it, then the
  trailing `hide()` wipes it). maze (M5c-05) had to defer the reshow one frame
  (`need_reopen`/`reopen_text` picked up by `rearm_input`). Works, but it is a
  non-obvious trap any project author reshowing on reject will re-hit.
- **Kind:** API ergonomics — the landed submit sequencing is frozen chunk-3
  behaviour; **not** a bug and **not** to be changed in M5c.
- **Disposition:** report-don't-fix. Candidate to address when the M7 live-
  reconfigure surface lands (a first-class "reject keeps the widget open with
  the rejected text" path would remove the need for example-side deferral).
- **State:** open / anticipated (no committed closure yet).



### Controller-side dead `result`/reftable delivery path — unreachable after M8-03 global removal (M8-03 review, report-don't-fix)

- **Where:** `src/controller/userInputController.lua:223-224`
  (`apply_config` sets `self.result` from `cfg.result`) and `:364-366`
  (`deliver()`'s `if type(res) == 'table' then res(text) end`).
- **What:** The removed `input()` helper in `consoleController.lua` was the
  ONLY call site tree-wide that ever passed `result = input_ref` into
  `show()`/`configure()`. With M8-03 deleting it, nothing ever populates
  `self.result`, so the `type(res) == 'table'` reftable-delivery branch in
  `deliver()` is now permanently unreachable dead code.
- **Kind:** dead code (benign) — the removal was designed self-contained in
  `consoleController.lua`; `userInputController.lua` is `src/controller/*`,
  outside the M8-03 spec Files scope.
- **Disposition:** report-don't-fix per the M8-03 commission's scope fence.
  Confirmed by the reviewer (grep: zero remaining `result =`/`input_ref`
  producers; the field is write-once-from-config with no config writer left).
- **State:** open — a natural cleanup for a future controller pass.

### Per-example internals-doc drift — 7 files still describe the retired poll idiom (M8-03 review)

- **Where:** `doc/development/internals/examples/{tixy,balloons,turtle,valid,
  repl,guess,index}.md`.
- **What:** M8-03 synced the required surface docs (`internals/user_input.md`,
  `internals/console.md`) to `compy.input.*` but the per-example internals docs
  still carry multi-paragraph prose + literal `r = user_input()` poll-loop code
  blocks. Each is a real per-file rewrite, not a mechanical edit — correctly
  FLAGGED (not silently skipped) and left out of the bounded terminal chunk.
  `turtle.md`'s drift predates M8 (turtle migrated in M5c, doc never updated
  then) — a standing gap, not newly introduced by M8-03.
- **Kind:** doc drift.
- **Disposition:** report-don't-fix; a natural follow-up doc pass after #77.
- **State:** open / flagged.

### `src/vadexamples/` untracked scratch still calls the removed globals (M8-03 review)

- **Where:** `src/vadexamples/{guess,repl,turtle,tixy,valid}/main.lua` (+ their
  READMEs) — git-untracked scratch, parallel to the shipped `src/examples/` tree.
- **What:** These still call `user_input()`/`input_text()`/`input_code()`/
  `write_to_input()`/`validated_input()`; they will nil-crash if ever run now.
  Not a deliverable, not in the census/spec — correctly LEFT ALONE per the
  M8-03 scope fence (migrating or deleting untracked scratch is out of scope).
- **Kind:** untracked scratch (not shipped).
- **Disposition:** note-don't-touch; the owner can delete or migrate the scratch
  at will outside the #77 sweep.
- **State:** open / noted.
