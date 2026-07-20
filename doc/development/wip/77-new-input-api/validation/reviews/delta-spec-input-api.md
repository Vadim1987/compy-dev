# Input API — delta spec (mechanism-level, redesign execution basis)

**Status: PROPOSED, pending R3 confirmation.** Companion to
[`delta-design-input-api.md`](delta-design-input-api.md) (read that first for the
*why*; this is the *how* — concrete shapes, signatures, call order, acceptance
criteria). Written at the altitude of `design/spec.md`'s existing style so it can
drive tests-first execution directly. All facts below are grounded in the verified
code citations in
[`S16-fable-redesign-pressure-test.md`](../outcomes/S16-fable-redesign-pressure-test.md);
this document adds no new claims, only executable shape. **Revision note (this
pass):** the project's own combo table is `shortcuts`, not `handlers` — see the
delta-design's vocabulary table for why (a verified collision with LÖVE's own
`love.handlers`, `controller.lua:871`).

---

## §1 `compy.input` surface shape

```
compy.input = {
  shortcuts = {
    keypressed  = { [combo] = fn },   -- Key.new_handler_table(), unchanged (D8)
    keyreleased = { [combo] = fn },
    textinput   = { [combo] = fn },
  },
  hooks = {
    keypressed  = fn?,
    keyreleased = fn?,
    textinput   = fn?,
  },
  callbacks = {
    on_text_entered   = fn?,   -- (text) -> nil
    on_limit_reached  = fn?,   -- (direction, scope) -> nil
    validator         = fn?,   -- (text) -> ok:boolean, err_msg:string?
    highlighter       = fn?,   -- (text) -> ... (unchanged from today)
    before_submit     = fn?,   -- (keys_pressed) -> veto:boolean?  (reserved, unbuilt — R9)
    after_submit      = fn?,   -- (text) -> nil; DEFAULT: no-op (was: implicit hide)
    before_cancel     = fn?,   -- (keys_pressed) -> veto:boolean  (NEW: honoured)
    after_cancel      = fn?,   -- () -> nil; DEFAULT: no-op (was: implicit hide)
  },
  -- methods: show, hide, configure, clear, get_cursor, set_cursor, set_text
  -- (§4) — unchanged call signatures from today.
}
```

**Guard (replaces the 11-entry `INPUT_CALLBACKS` allowlist):**

```
__newindex(t, k, v):
  if k == 'shortcuts' or k == 'hooks' or k == 'callbacks' then
    error("compy.input: '" .. k .. "' is not assignable", 2)
  end
  -- k is a leaf write inside one of the three sub-tables; sub-tables get
  -- their OWN __newindex enforcing the same container-frozen rule one
  -- level down (shortcuts.keypressed = {} must also refuse).
```

Each of `shortcuts.<event>`, `hooks`, `callbacks` needs a `__newindex` refusing
identity replacement of *their own* nested tables (`shortcuts.keypressed = {}` must
still error) while allowing leaf writes (`shortcuts.keypressed['ctrl+s'] = fn`
succeeds, going through `Key.new_handler_table`'s existing normalisation,
unchanged). `hooks[event] = fn` and `callbacks[name] = fn` are flat leaf writes,
no nesting to protect.

---

## §2 Dispatch (obligation 6a — extracted as a free function)

```
-- shortcuts, hooks: the two compy.input sub-tables (or console/editor's own,
-- future use). widget: an object responding to widget[event](widget, ...)
-- and widget:is_shown(). Returns: consumed:boolean.
function dispatch(shortcuts, hooks, widget, event, trigger, ...)
  local combo = Controller.combo_string(trigger, Controller.keys_pressed)
  local h = shortcuts[event][combo]
  if h and h(...) then return true end
  local hk = hooks[event]
  if hk and hk(...) then return true end
  if widget:is_shown() then
    widget[event](widget, ...)
    return true
  end
  return false
end
```

`ProjectInputController:_dispatch` becomes a thin caller: `return dispatch(self.
compy_input.shortcuts, self.compy_input.hooks, love.state.user_input_controller,
event, trigger, ...)`. No `framework_handlers` tier; no `_generic_callback`;
no `_sink`. `_generic_callback`, `_sink`, `framework_handlers`, `install_tier1`,
`shown_widget`, `run_hook`, `framework_submit`, `framework_cancel` are **deleted**.

**Consumption rule, explicit:** the widget branch returns `true` whenever shown,
**regardless of whether the specific key did anything** — matching today's
terminal-sink semantics (always invoked, internal no-op when nothing to do).
"Only true when it acted" is explicitly rejected (would require per-branch
bookkeeping the widget doesn't have today).

### Considered alternative (deferred, not adopted) — an OR-chain with default-noop
### slots and an internal widget shown-check

Owner-proposed, marked here for future consideration rather than built:

```
return shortcuts[event](...) or hooks[event](...) or widget:dispatch(event, ...)
```

with `shortcuts[event]`/`hooks[event]` never nil (defaulted to a noop-returning-
`false` stand-in, installed via metatable `__index`) and `widget:dispatch` deciding
its own truthy/falsy return internally from its own shown/hidden state, rather than
the caller checking `widget:is_shown()` externally as §2 does above.

**Worth noting, not just filing away:** this echoes an existing standing REVIEW
note almost verbatim — `projectInputController.lua:197`: *"it was told multiple
times that more tier-agnostic chain is to run 'OR' combination, while nillable
elements are secured by default noop… mark potential improvement as a tech debt or
just TODO:consider note."* It is also, arguably, a **more faithful** reading of
original Decision 2's own clause ("a load-bearing decision about the sink: its
hidden-check is internal") than §2's approach above, which moves the shown-check
*out* to the caller.

**Why not adopted here (the owner's own caveat, confirmed on inspection):**
`shortcuts[event]` is a **table** keyed by combo, not a single function — so
`shortcuts[event](...)` only works if the default-noop stand-in is itself smart
enough to resolve the current combo internally (compute `combo_string`, look up
the matching entry, call it or fall through) rather than being a flat "always
returns false" default. That is meaningfully more machinery than a plain
default-noop, for a debugging-elegance payoff — exactly the "elegance-for-itself"
risk flagged when this was raised. §2's explicit-caller-checks-shownness shape
stays the spec's baseline; this is recorded as a marked, deliberately-deferred
alternative for whoever next touches this chain, cross-referenced against the
in-code REVIEW it independently reproduces.

---

## §3 Submit / cancel sequence (widget-owned default, callback-driven)

Lives on the widget (today's `UserInputController`), invoked as the terminal chain
step (§2) when the trigger combo is `'return'`/`'escape'` and no `shortcuts`/`hooks`
entry consumed first:

```
function Widget:keypressed(k, keys_pressed, isr)
  if k == 'return' and not shift_held then
    return self:_submit_default(keys_pressed)
  end
  if k == 'escape' then
    return self:_cancel_default(keys_pressed)
  end
  -- ... existing per-key editing logic, unchanged ...
end

function Widget:_submit_default(keys_pressed)
  run_callback(self, 'before_submit', keys_pressed)   -- veto reserved, unbuilt (R9)
  if self.model:get_text():is_empty() then return end
  local text = string.unlines(self.model:get_text())
  if not gate(self.model, self.callbacks.validator, text) then return end
  deliver(self, text)                                  -- fires on_text_entered
  run_callback(self, 'after_submit', text)              -- DEFAULT: no-op (stays open)
end

function Widget:_cancel_default(keys_pressed)
  if run_callback(self, 'before_cancel', keys_pressed) then return end  -- veto
  self.model:cancel()                                   -- clear, hardwired
  run_callback(self, 'after_cancel')                     -- DEFAULT: no-op (stays open)
end
```

`run_callback(self, name, ...)`: looks up `self.callbacks[name]`; absent →
no-op+debug-log (today's shape, unchanged); for `before_cancel` specifically, the
**return value is honoured** (truthy = veto, skip the clear step) — the one
asymmetry versus `run_hook`'s current always-ignore-return behaviour.

**Default callbacks, installed at construction (not per-activate):**

```
DEFAULT_CALLBACKS = {
  after_submit = function() end,   -- stays open
  after_cancel = function() end,   -- stays open
}
```

A project wanting the pre-existing project-overlay behaviour (auto-close) opts in:

```
compy.input.callbacks.after_submit = function() compy.input.hide() end
compy.input.callbacks.after_cancel = function() compy.input.hide() end
```

**Teardown (D11) must re-seed, not wipe.** `reset_compy_input`'s equivalent for
`callbacks` must reset to `DEFAULT_CALLBACKS`, not `nil` every key — a nil'd
`after_cancel` on the NEXT project would silently mean "the widget stays open
forever" rather than "use the default," which is a behaviour change the project
never asked for.

---

## §4 Widget-method surface (obligation 6b — parameterized factory)

```
-- Was: get_compy_input() with methods closing over the global
-- love.state.user_input_controller. Now:
function build_widget_api(get_widget, get_active_flag)
  return {
    show = function(cfg) ... get_widget():show(cfg) ... end,
    hide = function() ... get_widget():hide() ... end,
    get_cursor = function() if not get_active_flag() then return nil end ... end,
    set_cursor = function(l, c) ... end,
    set_text = function(t, kc) ... end,
    configure = function(cfg) ... end,
    clear = function() ... end,
  }
  -- CONSIDERED, DEFERRED (owner, S16): unify further — one instance-record
  -- holding shortcuts/hooks/callbacks/widget-ref TOGETHER with these methods,
  -- so `dispatch` (§2) becomes a method on this same object instead of a free
  -- function taking three separate arguments. Appealing: matches how
  -- compy.input already looks from a project's side (one object, everything
  -- hanging off it) — a console/editor adopter would build "the same kind of
  -- thing" for itself, not a different shape.
  -- Two reasons this spec keeps them separate instead: (1) this codebase
  -- states a preference for functional style over classes (`agents/
  -- rules.md:67`, "closures, iterators, and immutable-by-convention data are
  -- preferred") — a plain dispatch(shortcuts, hooks, widget, ...) function
  -- fits that better than a dispatch method on a fatter class; (2) the D7
  -- guard is specifically an untrusted-PROJECT-code concern — console/editor
  -- are trusted host code and need none of it (confirmed: they already call
  -- UIC's raw methods directly, bypassing compy.input entirely). Folding
  -- methods + mechanism into one reusable class would either drag the guard
  -- into console/editor's path or make it conditional inside the shared
  -- class — re-coupling a concern this split deliberately kept out of the
  -- reusable core. Left as the executor's call if/when console/editor
  -- migration is actually picked up, not decided here.
end
```

`get_widget`/`get_active_flag` are closures, not the raw `love.state.
user_input_controller`/`love.state.user_input` globals directly — for the project
overlay's `compy.input`, they close over exactly those globals (behaviour-identical
to today); a future console/editor adopter would close over its own instance and
its own "always active" flag instead. **No call site changes for the project case**
— this is a pure internal refactor of `get_compy_input`, zero observable
difference.

---

## §5 `hooks[event]` seeding (obligation revised-D10)

```
-- At activation (ProjectInputController:activate), once:
function seed_hooks(hooks, natives)
  for event, native in pairs(natives) do
    if hooks[event] == nil then
      rawset(hooks, event, native)   -- bypasses the D7 guard deliberately —
    end                              -- this is framework-internal seeding, not
  end                                -- a project write.
end
```

Runs **after** the project's `main.lua` top-level code has executed (today's
`occupy_keyboard` ordering, unchanged) — so an explicit `compy.input.hooks.
keypressed = fn` set at top level is already in place and is correctly skipped by
the `hooks[event] == nil` check. After seeding, `hooks[event]` is read directly by
§2's `dispatch` — no separate `self.natives` field, no per-event precedence
re-resolution. `ProjectInputController.natives` field is **deleted**.

---

## §6 Console patch (the one console-facing change)

`consoleController.lua`, `ConsoleController:keypressed`, replacing the
`local limit = input:keypressed(k); if limit then ... end` block:

```
-- at console-widget construction (once):
console_widget.callbacks.on_limit_reached = function(dir, scope)
  if dir == 'up' then input:history_back() end
  if dir == 'down' then input:history_fwd() end
end

-- ConsoleController:keypressed loses the `local limit = ...` branch entirely;
-- input:keypressed(k) is still called for its editing side effects, return
-- value simply unused now (matches editor's existing usage).
```

No other console/editor code changes. Editor's `SearchController:keypressed`'s own
`jump` return contract is untouched — different class, different contract,
verified out of scope.

---

## §7 Acceptance criteria (tests-first anchors)

Each maps to one obligation in the delta-design; write the breaking test before
touching implementation, per house convention.

1. **Cancel default.** Widget shown, arbitrary content, Escape pressed, no
   callbacks configured → content cleared, `after_cancel` (default no-op) leaves
   the widget **shown**. (Pins the auto-close flip; the OLD assumption — hidden
   after Escape — must now fail.)
2. **Cancel veto.** `before_cancel` returns truthy → content is **not** cleared,
   widget remains exactly as it was, `after_cancel` does not fire.
3. **Submit default stays open.** Valid text, Enter pressed, no callbacks
   configured → `on_text_entered` fires with the text, widget remains **shown**,
   content is NOT auto-cleared by the default `after_submit`. (A project that
   wants clear-and-continue does so from its own `after_submit`; not the
   platform's job.)
4. **Opt-in auto-close.** `after_submit = function() compy.input.hide() end`
   configured → identical externally-observable behaviour to today's shipped
   auto-close.
5. **Enter/Escape shadowable.** `shortcuts.keypressed['return'] = function()
   return true end` configured, widget shown, text present, Enter pressed → no
   submit occurs (shortcut wins). Ctrl+Q pressed in the same state → the project
   still quits (gateway pre-tap unaffected by any shortcut).
6. **Consumption via shownness.** Widget hidden, arbitrary key → chain reports
   not-consumed (falls through past the widget). Widget shown, arbitrary key
   (including ones the widget does nothing with) → chain reports consumed.
7. **`on_limit_reached` retirement.** Console: cursor at top line, Up pressed →
   history navigates back; no reliance on `UIC:keypressed`'s return value in
   `ConsoleController` remains (grep-verified post-change, not just behaviourally).
8. **Hook seeding, one-shot.** Native `love.keypressed` set, no explicit
   `compy.input.hooks.keypressed` → native fires via the seeded hook. Explicit hook
   set, then set to `nil` → **no** native resurrection (differs from today —
   this is the deliberate semantic change, must be asserted, not merely allowed).
9. **D7 guard, frozen identities.** `compy.input.shortcuts = {}`,
   `compy.input.hooks = {}`, `compy.input.callbacks = {}`,
   `compy.input.shortcuts.keypressed = {}` each raise loudly. `compy.input.hooks.
   keypressed = fn`, `compy.input.callbacks.validator = fn`,
   `compy.input.shortcuts.keypressed['ctrl+s'] = fn` each succeed.
10. **Teardown re-seeds, doesn't wipe.** Project A sets `after_cancel = fn`,
    stops. Project B activates, never touches `after_cancel`. Escape in project B
    → default no-op behaviour (stays open), not project A's leftover `fn`, and not
    a hard nil-call error either.
