# M6-02 — `compy.before_exit` project-stop hook

_LLM(Claude Sonnet 4.6): 2026-06-24 (session 23). Approved by human?: YES (session 23)._
_Adjacent spec slice — frozen [`M6.md`](M6.md) is not edited._
_In-doc id: M6-02. Derives from E9 §8 Layer 1 + session 23 (`notes/talk/session23-insights.md §6`)._

> **Purpose.** Specifies the `compy.before_exit` project-stop hook — the Layer 1 mechanism
> from E9's A1/P4 two-layer resolution. Planned at E9 as "M6-family, near-term" and now
> explicitly slotted. This slice adds one hook to the existing M6 named-chain family; it may
> fold into the M6 implementor prompt or ride as a separate M6-02 adjacent slice — human's
> call at commissioning time.

---

## Background

**The T3 leak.** The framework sandbox deep-clones the `love` table but shares leaf C
functions, so a project's imperative `love.*` calls (`setKeyRepeat`, `setTextInput`,
`setRelativeMode`, raw audio) hit real SDL/LÖVE state. Nothing restores it on stop.

**Two-layer resolution (E9 §8).** Layer 2 (framework-guaranteed snapshot/restore) is
deferred — it needs device-state serialize and is outside #77's scope. Layer 1 is what
this slice delivers: a project-bindable hook that fires on stop, enabling the *project
itself* to restore its own T3 state.

**keyboard as canonical consumer.** keyboard disables key-repeat at startup
(`love.keyboard.setKeyRepeat(false)`) and must restore the default (`true`) on exit.
Without `compy.before_exit`, that device state bleeds into the next project run.

---

## Contract

### `compy.before_exit()`

A settable callback slot on the `compy` namespace (not `compy.input`; this is a
project-run lifecycle hook, not an input-channel callback).

- **Fires:** on project stop — whether triggered by user action (`Ctrl+Esc`),
  framework-controlled stop, or normal exit. Guaranteed to fire for framework-invoked
  stop paths; crash/hard-kill is not covered (Layer 2 scope).
- **Default value:** a no-op (with a debug log entry, consistent with the other
  before/after hooks).
- **Reset:** cleared to default when the project stops (same lifecycle as
  `compy.input.on_key_pressed` et al., via `clear_user_handlers` or equivalent).
- **Return value:** ignored; cannot suppress the stop.
- **Timing:** fires *before* the framework's own cleanup — so the project's teardown
  runs while `love.*` calls are still safe.
- **Signature:** `compy.before_exit()` — no args. The project knows its own state.

### Usage pattern

```lua
-- keyboard: opt-in T3 restore
love.keyboard.setKeyRepeat(false)  -- disabled at project load

compy.before_exit = function()
  love.keyboard.setKeyRepeat(true) -- restore default on exit
end
```

---

## Spec addition required

`design/spec.md §3` (Event Callbacks) must be extended with a `compy.before_exit`
entry, parallel to the `before_submit`/`after_submit` etc. rows. Not done in this
session — to be added atomically when M6 or M6-02 is commissioned (frozen spec.md is
not edited out of turn).

---

## Files (M6-02)

- `src/projectInputController.lua` (or `consoleController.lua`) — fire `compy.before_exit`
  from the project-stop path before clearing user handlers.
- `src/compy_namespace.lua` — expose `compy.before_exit` slot with no-op default.

---

## Acceptance

- `compy.before_exit = fn` — assigning fires `fn` on the next project stop.
- Fires before framework cleanup; `love.*` calls inside it are safe.
- Does **not** fire when the project was never started or when the slot was not set
  (no-op default is silent).
- Reset to no-op default after the stop cycle (next `show()` gets a clean slate).
- The keyboard forward Tier-2 acceptance test (device-state thread) can be authored
  from this slice once the hook is green.

---

## Commission timing

This slice is small (one slot, one fire point). It shares the named-hook infrastructure
with M6's `before_submit`/`after_submit`/`before_cancel`/`after_cancel` chains. The
natural commissioning options:

1. **Fold into M6** — add this surface to the M6 implementor prompt directly. Saves a
   separate cycle; appropriate if M6 is not yet commissioned.
2. **Ride M6-02** — a separate adjacent implementor + reviewer pair, run after M6.
   Appropriate if M6 is already being implemented and adding scope is disruptive.

Either way, the keyboard Tier-2 forward-acceptance test for `before_exit` is authored
as part of the M5a or M6 test-first step (whichever comes first that can observe the
hook slot).
