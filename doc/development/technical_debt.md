# Technical Debt Register

A running list of known debt — discovered during work but deliberately not addressed in
the milestone that surfaced it. Entries are matter-of-fact context, not defects to fix on
sight; each notes where it lives, why it stands, and when it is worth revisiting. Remove an
entry when the debt is paid.

Tone and intent follow [`conventions/architecture_principles.md`](conventions/architecture_principles.md)
and the analytic-notes guidance in [`../../agents/rules.md`](../../agents/rules.md).

---

## Input API (issue 77)

> Most debt surfaced *during* the #77 implementation is **interim** — tied to this feature's own
> milestones and expected to be swept (or formally accepted) before it ships. That lives in the
> feature-scoped ledger
> [`wip/77-new-input-api/implementation/technical_debt.md`](wip/77-new-input-api/implementation/technical_debt.md),
> **not** here. Only the entry below survives the feature as a standing property of the codebase.

### `keys_pressed` can go stale on focus loss

- **Where:** `src/controller/controller.lua` — `keys_pressed` is maintained from
  `keypressed`/`keyreleased` only.
- **State:** If the window loses focus with a key held, `keyreleased` may never fire and the
  entry lingers (a general LÖVE limitation of any held-key mirror). This persists beyond #77 — it
  is a property of the mechanism, not of the feature work.
- **Why it stands:** No cheap, fully-correct fix; the consumer can defend against it.
- **Revisit:** Any consumer of `keys_pressed` must not assume the set is leak-free across focus
  changes; if it matters, clear the set on `love.focus(false)`.

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
