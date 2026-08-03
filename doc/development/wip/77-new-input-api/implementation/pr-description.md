# PR description — the new input API

Draft for the Main feature PR. Written to the strategic frame: a reviewer with
**only this text and `doc/input_api.md`** should be able to judge it. Nothing
below cites `wip/77`, and no term is used that the guide does not define.

---

## Intent

Stakeholders asked for a **simpler and more robust input API**.

The old one had three structural faults, and every project in the repo worked
around at least one:

1. **Polling, not events.** A project called `input_text()` and then re-checked
   a variable every frame to notice a submission. There was no way to be *told*.
2. **Keyboard lockout.** While a prompt was on screen the project's own
   `love.keypressed` was not called at all — routing asked "is a widget shown?".
   Reacting to a hotkey *while* soliciting text was impossible.
3. **No show/hide without teardown.** Dismissing a prompt meant destroying it
   and rebuilding.

The replacement is event-driven and consistent with LÖVE's own callback style:
a project shows a prompt and gets the result through one callback, with no
framework internals in view.

```lua
compy.input.show{
  prompt = 'name?',
  on_text_entered = function(lines) greet(lines[1]) end,
}
```

## Design

**One route owns input at a time.** The application mode — console, editor, or
project — selects the route. A widget never selects the route; its visibility
is state on the widget, not a routing condition. That single change is what
removes the lockout.

**Inside the route, one chain of three, in order:**

```
shortcuts[event][combo]  →  hooks[event]  →  the widget
```

A truthy return at any step consumes the event; a falsey one falls through. The
widget is the terminal step and consumes by *being shown*. The same shape runs
on every channel — key presses, releases, text, pointer, and the framework's
derived click events.

**One lifetime.** The route holds every channel from the moment a project
starts until it stops. Nothing a project installed survives it.

**One error boundary**, at the point the route is entered: project input code
runs with its canvas bound and its errors routed to the project error handler,
so a raise in a shortcut surfaces the same way as a raise anywhere else.

## What a reviewer will notice, and why

| Member | Why it exists |
|---|---|
| `compy.input.show / hide / configure / clear` | The prompt itself, without the teardown. Replaces four polling globals with one call plus a callback. |
| `compy.input.is_shown` | The one state question a project cannot answer for itself — its `love` is a sandboxed clone. |
| `compy.input.set_text / get_cursor / set_cursor` | Editing an *active* prompt, which the old API could only do by rebuilding it. |
| `compy.input.callbacks` | The submit/cancel lifecycle. This is what replaces polling. |
| `compy.input.hooks[event]` | One function per event. A project's own `love.<event>` is seeded here automatically, so existing code keeps working — and now runs *while a prompt is up*, which is the lockout fix. |
| `compy.input.shortcuts[event][combo]` | Bind `ctrl+s` without hand-testing modifiers. Removes the commonest hand-rolled block in the examples. |
| combo classes — `alt+*` | "Every Alt chord is ours." Without it a project writes one entry per key, or hand-tests modifiers and gets the exclusions subtly wrong. One example did exactly that. |
| `compy.input.keys_pressed` | Held keys, readable **outside** an event. The callback argument cannot serve a per-frame renderer; a real project needed this and had been maintaining its own mirror. |
| `compy.input.fn.ignore_repeat / stop_here / side_run` | Three declarations a binding can make about repeats and propagation, so the handler does not have to know its own context. Without them every handler ends in `return true` and carries that knowledge wherever it is reused. |
| `compy.before_exit` | A project that changed global device state (key-repeat, text input) gets one chance to put it back. Nothing else restores it. |

**Deliberately absent**, and worth stating because a reviewer may look for them:

- **No pointer shortcuts.** A combo names a key; a pointer event has none.
  Pointer starts at the hook tier.
- **No framework tier above shortcuts.** An earlier draft had one, claiming
  Enter/Escape while a widget was shown. It is gone: a project shortcut can bind
  Enter and win, like any other combo.
- **No compatibility shim** for the retired globals. They are ordinary nil
  fields; the guide's migration table gives the replacement for each.
- **No "A and B held together" combos.** Every binding would become conditional
  on nothing else being held, so holding a movement key would silently break
  unrelated shortcuts.

## Ratified deviations from the original design

Recorded because each was decided *against* an earlier ratified position, and a
reviewer comparing to the design will notice.

| Deviation | Why |
|---|---|
| The four-tier chain became three | The framework tier existed only to give Enter/Escape special handling. The widget's own defaults do that job, with no carve-out in the propagation rule. |
| Hook resolution became a one-time seed, not per-event precedence | The old rule re-resolved on every event and resurrected a captured handler when an explicit hook was nil'd. One table, one truth: nil means nil. |
| Pointer joined the chain | It had been left out on the grounds that its separate lifecycle was inherited platform behaviour. Checking the pre-feature baseline showed the opposite — the asymmetry was introduced by this work, and the exemption existed only to protect projects from a release this work had added. |
| The route is no longer released mid-run | Same finding. Every channel now has the pre-feature lifetime: held until stop. |
| `compy.singleclick` / `.doubleclick` retired | They were a bespoke surface for two events the framework derives. They are now ordinary events on the same chain, bound as `compy.input.hooks.singleclick`. Two examples migrated with them. |
| Unhandled events are not logged | A log line per unbound keystroke is 60/second under debug. Silence is the decision, not an omission. |

## Open questions

Recorded, not blocking. Each is in the debt ledger with options.

1. **Should a shown widget consume clicks within its bounds?** Nothing does
   bounds checks today. The chain now gives a project the means to decide, which
   is a different answer from the framework deciding for it.
2. **Should pointer gain a combo vocabulary** — a modifier-only binding such as
   `ctrl` plus a button? Cheap now that pointer is on the chain, but it is new
   vocabulary and nobody has asked for it.
3. **Three usability defects predating this work**, deliberately left alone to
   keep this PR to the ask, and because each may have a reason not visible from
   here: a top-level raise and a handler raise surface differently; the error
   lock is a freeze with no stated exit; `repl` does not evaluate despite its
   name. Each is recorded with a suggested fix for stakeholders to accept or
   contest **after** this merges.
4. **The console and editor still share a route**, with the editor reached as a
   fork inside it. Converging them onto the chain the project route uses is the
   natural next step and was deliberately not attempted here — the project route
   is the proving ground.
5. **The Web build has no test coverage.** The suite runs on LuaJIT; a defect
   reachable only on love.js is invisible to every check this project runs. One
   such defect existed during development and was found by reading, not testing.

## Verification

- `busted tests` → **923 passing, 0 failures, 3 pending** (the three are
  documented gaps awaiting a consumer, not skipped work).
- The contract suite drives the **real** production path throughout: the real
  `love.handlers` gateway, a real `ConsoleController`, and the real route
  installer — not a simulation of them.
- Every claim in `doc/input_api.md` is pinned by at least one row.
- **Not covered by tests, and needing a human at a screen:** anything that
  reaches the screen or a game — the overlay paint, the migrated examples, and
  the click paths. A smoke-test plan accompanies this PR.
