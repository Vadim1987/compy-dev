# Technical Debt Register

A running list of known debt — discovered during work but deliberately not addressed in
the milestone that surfaced it. Entries are matter-of-fact context, not defects to fix on
sight; each notes where it lives, why it stands, and when it is worth revisiting. Remove an
entry when the debt is paid.

Tone and intent follow [`conventions/architecture_principles.md`](conventions/architecture_principles.md)
and the analytic-notes guidance in [`../../agents/rules.md`](../../agents/rules.md).

---

## Input API (issue 77)

### `combo_string` allocates a fresh table per call

- **Where:** `src/controller/controller.lua` — `combo_string` builds a `parts` table and
  `table.concat`s it on every call.
- **State:** Inert today — nothing calls it in M1. M4/M5 will put it on the per-keystroke
  dispatch path (`compy.input.handlers[combo]`).
- **Why it stands:** Keystroke dispatch is not a per-frame hot path, so the allocation is
  acceptable for now; `rules.md` flags allocation in `update`/`draw`, not per-event helpers.
- **Revisit:** When M4/M5 wire the consumer — if dispatch lands anywhere hot, switch to a
  reused buffer or a concat-free comparison.

### `gui_k` modifier pair has no real consumer

- **Where:** `src/util/key.lua` — `gui_k = { "lgui", "rgui" }` (added in M2a). It feeds only
  `mod_triples`; there is no `gui()` / `is_gui()` accessor paralleling `shift()` / `is_shift()`,
  and `combo_string` is itself not yet consumed (see the allocation entry above).
- **State:** A defined modifier pair with no behavioural reader. The other `*_k` pairs are read
  by `love.keyboard.isDown` accessors; `gui_k` is not. Could be a deliberate unspoken constraint
  ("ignore gui keys" — never expose them as a held modifier), or an expansion point left open
  for a future `gui()` accessor.
- **Why it stands:** Keeping it as a named local parallels the established `*_k` pattern and the
  M2a spec called for the `gui` pair explicitly; the asymmetry is harmless and additive.
- **Revisit:** When the input API decides whether `gui` is a first-class modifier — either add
  the `gui()` / `is_gui()` accessors to give it a consumer, or, if gui is intentionally ignored,
  record that decision so the unused pair is understood as policy rather than an oversight.

### `keys_pressed` can go stale on focus loss

- **Where:** `src/controller/controller.lua` — `keys_pressed` is maintained from
  `keypressed`/`keyreleased` only.
- **State:** If the window loses focus with a key held, `keyreleased` may never fire and the
  entry lingers (a general LÖVE limitation of any held-key mirror).
- **Why it stands:** Out of M1 scope; no consumer reads the set until M4/M5.
- **Revisit:** The M4/M5 consumer must not assume the set is leak-free across focus changes;
  if it matters, clear the set on `love.focus(false)`.

### Design-doc path mismatch: `src/controller.lua`

- **Where:** `design/spec/M1.md`, `design/roadmap.md`, and other 77-new-input-api design docs
  reference `src/controller.lua`; the real path is `src/controller/controller.lua`.
- **State:** Documentation only; implementation uses the correct path. Noted in the M1 prompt
  and outcomes.
- **Why it stands:** Cosmetic; the design docs are frozen reference for the sprint.
- **Revisit:** Correct opportunistically when those docs are next edited.

### `compy.input` table is rebuilt per project-env, not once at namespace setup

- **Where:** `src/controller/consoleController.lua` — `get_compy_input()` is called from
  `get_compy_namespace()`, which `prepare_project_env()` invokes per project setup, so the
  `compy.input` table is reconstructed each time a project env is prepared.
- **State:** No functional impact. The `show`/`hide` closures on the table resolve
  `love.state.user_input_controller` dynamically, so they always reach the live singleton regardless
  of when the table was built. A wording deviation from the singleton spec ("created once at namespace
  setup"), not a defect — the dynamic-lookup design is the right call and keeps `compy.input`
  resilient to the singleton being (re)assigned. Surfaced by the M2 review.
- **Why it stands:** Reconciling the wording to a literal once-only build buys nothing and risks the
  resilience the dynamic lookup gives.
- **Revisit:** Only if a single-build invariant ever becomes load-bearing (it currently is not).

### `show({ force = true })` re-applies only `text`

- **Where:** `src/controller/userInputController.lua` — the `force` branch of `show()` sets only
  `text`, whereas a fresh activation runs `apply_config` (eval, prompt, text, result).
- **State:** A `show({ force = true })` on an already-active session cannot re-target `result` or swap
  the evaluator — only its text can be replaced. This matches the singleton spec, which frames `force`
  purely in terms of content; flagged by the M2 review as a known boundary, not a defect.
- **Why it stands:** Correct for the single-consumer model; broadening `force` now would pre-empt a
  decision that belongs to the extended-configure surface.
- **Revisit:** When the extended singleton API (`configure`) lands — decide there whether an active
  session can be re-targeted (eval/result), and align `force` with that.

---

## Pre-existing (surfaced during issue 77, predates it)

### `gfx` implicit global in `controller.lua`

- **Where:** `src/controller/controller.lua` — `set_love_update` / `set_love_draw` use `gfx`,
  a free variable not set in the file or any of its requires; it must exist at call time
  (set by the app's load sequence).
- **State:** Pre-existing; M1 did not touch these paths. Works because of load order.
- **Why it stands:** Long-standing wiring assumption; changing it risks the load sequence for
  no behavioural gain.
- **Revisit:** When the controller's load/aliasing is next reworked — prefer a module-top
  `local gfx = love.graphics` per the standard-aliases convention.

### `table.protect(love.handlers)` is a no-op on the passed table

- **Where:** `src/controller/controller.lua` — end of `setup_callback_handlers`.
- **State:** `table.protect` returns a read-only proxy but does not mutate the original; the
  call's return is unused, so `love.handlers` is not actually protected.
- **Why it stands:** Pre-existing; no observed breakage, and the proxy-vs-mutate semantics are
  a broader `util/table` question.
- **Revisit:** If/when read-only enforcement on `love.handlers` is actually wanted — either
  consume the returned proxy or change `table.protect` semantics.
