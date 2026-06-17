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
