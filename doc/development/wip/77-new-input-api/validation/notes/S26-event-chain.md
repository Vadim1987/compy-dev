# S26 — the full keyboard event chain, generation to consumer

Traced from code 2026-08-03 at HEAD `22ba5b07`. Every line reference is
verified, not recalled. Written because the console-route gate
(`forward_*`) only makes sense against the whole path.

Scope: the three keyboard/text channels (`keypressed`, `keyreleased`,
`textinput`). Pointer is a different shape and is contrasted at the end.

---

## Tier 0 — the pump. compy owns `love.run`.

`src/harmony/init.lua:104` replaces LÖVE's main loop with
`harmonius_run`. There is exactly one pump; the only other one in the
tree is the crash explorer, which never reaches `love.handlers`.

```
OS / SDL event
  └─ love.event.pump()                       harmony/init.lua:49
     for name, a,b,c,d,e,f in love.event.poll() do    :50
        ├─ name == 'die'        → return           :51
        ├─ Harmony lock on?     → strip the 'sazed_' prefix,  :57
        │                         then love.handlers[n](...)  :67
        └─ otherwise            → the unprefixed path
```

Then per frame: `love.update(dt)` → `love.draw()` → `present()`. All
event delivery happens in the poll loop, **before** update — so no
handler runs mid-frame.

---

## Tier 1 — `love.handlers.*`: global, always runs, route-independent

`controller.lua:889` (`set_love_handlers`). This tier is installed once
and never swapped. It is above the route split, so nothing here can be
shadowed by a widget or a project.

```lua
handlers.keypressed = function(k, sc, isr)          -- :889
  Controller.keys_pressed[k] = true                 -- :890  held-set bookkeeping
  quickswitch()          -- ctrl+t: run <-> editor  -- :892
  project_state_change() -- ctrl+pause, ctrl+q, ctrl+s  :914
  restart(); profile(); playback ...

  -- :987-995 the comment that states the design:
  -- "Widgets are reached inside the route, never gated here."
  if love.keypressed then
    return love.keypressed(k, sc, isr)              -- :996
  end
end

handlers.textinput = function(t)                    -- :1001
  if love.textinput then return love.textinput(t) end
end

handlers.keyreleased = function(k)                  -- :1007
  Controller.keys_pressed[k] = nil                  -- :1008
  if Key.ctrl() and k == 'escape' then love.event.quit() end  -- :1010
  if love.keyreleased then return love.keyreleased(k) end
end
```

`love.handlers` is frozen at `:1144` (`table.protect`).

**Consequence worth holding on to:** ctrl+t, ctrl+pause, ctrl+q, ctrl+s
and ctrl+escape live HERE. They fire whatever route is active and
whatever widget is up. They are structurally un-shadowable.

---

## The route split

`love.keypressed` is the slot. Exactly one route occupies it:

| route | installer | `love.keypressed` becomes |
|---|---|---|
| console (default) | `set_love_keypressed` `:455` | the local `keypressed` at `:456` |
| project | `occupy_keyboard` `:243` | `function(k,sc,isr) return pic:keypressed(k,sc,isr) end` `:249` |

The editor is **not** a slot occupant — it is reached as a fork inside
the console route (see Tier 2A). `occupy_keyboard`'s own comment
(`:236`) says so: "the three routes are not yet fully symmetric".

Lifecycle: `set_user_handlers` → `occupy_keyboard` runs at
`consoleController.lua:124`, **after** `pcall(f)` at `:118` — i.e. after
the project's top-level code has already returned, and only if it did
not raise. `stop_project_run` (`:1268`) reinstalls the console defaults
(`:1272`) and hides the overlay (`:1274`).

---

## Tier 2A — the CONSOLE route

```lua
local function keypressed(k, _, isr)                -- controller.lua:456
  if Key.ctrl() and Key.shift() and love.DEBUG then -- :461
    -- 1/2/3/5 → toggle terminal, snapshot, canvas, input overlays
  end
  if Key.ctrl() and Key.alt() and love.DEBUG then   -- :478
    -- d → Log.debug(termdebug)
  end

  if forward_keypressed(k, isr) then return end     -- :491   <<< THE GATE
  CC:keypressed(k)                                  -- :492
end
```

```lua
local function forward_keypressed(k, isr)           -- :38
  local ui = get_user_input()                       -- :39
  if not ui then return false end
  ui.C:keypressed(k, Controller.held_keys(), isr)
  return true                                       -- "the widget was the surface"
end

local get_user_input = function()                   -- :21
  if love.state.app_state == 'inspect' then return end   -- Decision 12 gate
  return love.state.user_input
end
```

`love.state.user_input` is set in exactly one place —
`UserInputController:show()` (`userInputController.lua:287`), reachable
only via `compy.input.show` (`consoleController.lua:638`). So it is a
**project overlay**. The console's own prompt line is a *different*
instance (`consoleController.lua:44`, `always_shown()`), and
`always_shown()` sets only `self.shown` (`userInputController.lua:454`)
— it never registers in `love.state.user_input`.

The fallback:

```lua
function ConsoleController:keypressed(k)            -- consoleController.lua:1366
  if love.state.app_state == 'editor' then
    self.editor:keypressed(k)                       -- :1387   the EDITOR FORK
  else
    terminal-test gate (love.state.testing)         -- :1389
    if input:has_error() then                       -- :1397   the error lock
      space / enter / up / down → clear_error; return
    end
    pageup / pagedown → history                     -- :1405
    input:keypressed(k)                             -- :1417   console's own line
    Enter (no shift) → self:evaluate_input()         -- :1418
    ctrl+L → output:reset();  ctrl+alt+t → terminal_test()  -- :1425
  end
  input:update_view()
end
```

**The gate's effect:** when a project overlay is up on this route, every
line of `CC:keypressed` above is skipped. That is widget presence acting
as a routing condition — see the finding at the end.

---

## Tier 2B — the PROJECT route (the chain this feature built)

```lua
love.keypressed = function(k, sc, isr)              -- controller.lua:249
  return pic:keypressed(k, sc, isr)                 -- wrapped, not assigned,
end                                                 -- to bind `self`

function ProjectInputController:keypressed(k, sc, isr)  -- pic.lua:153
  return self:_dispatch('keypressed', k,  k, Controller.held_keys(), isr)
end                                    -- event  trigger | ---- payload ----

function ProjectInputController:_dispatch(event, trigger, ...)  -- :108
  return dispatch(
    self.compy_input.shortcuts,                     -- tier 1
    self.compy_input.hooks,                         -- tier 2
    love.state.user_input_controller,               -- tier 3
    event, trigger, ...)
end
```

The walk itself — `pic.lua:90`:

```lua
local function dispatch(shortcuts, hooks, widget, event, trigger, ...)
  -- 1. SHORTCUTS — combo table lookup
  local sc = find_shortcut(shortcuts[event], trigger)
  if sc and sc(...) then return true end            -- truthy = consumed

  -- 2. HOOKS — the raw per-channel handler
  local hk = hooks[event]
  if hk and hk(...) then return true end            -- truthy = consumed

  -- 3. WIDGET — consumes whenever SHOWN, skipped when hidden
  if widget and widget:is_shown() then
    widget[event](widget, ...)
    return true
  end

  return false     -- nobody consumed. Silent by Decision 23.
end
```

```lua
local function find_shortcut(tbl, trigger)          -- pic.lua:64
  local keys = Controller.keys_pressed
  local sc = tbl[Controller.combo_string(trigger, keys)]   -- exact: 'ctrl+s'
  if sc or Key.is_mod(trigger) then return sc end   -- a modifier's own press
  return tbl[Controller.combo_string('*', keys)]    -- is NOT in its class
end                                                 -- class: 'alt+*'
```

Notes that matter:

- The nil guards are **deliberate** (Decision 23): a hook's nil-ness is
  information a project reads, so an unset hook stays nil rather than
  defaulting to a callable noop. Nothing is logged on a full fall-through
  either — that would be a line per ordinary keystroke.
- `hooks` is seeded once at `activate()` from the project's own `love.*`
  handlers (Decision 10, `seed_hooks` `:42`), and only where the project
  set no explicit hook. After that the hooks table is the single source
  of truth.
- The widget consumes by **being shown**, not by returning truthy — it is
  the terminal step.
- `dispatch`'s boolean travels back up to `love.handlers.keypressed`,
  which returns it to the poll loop, which **ignores it**. LÖVE ignores
  handler returns. The consume contract is internal to the chain.
- `isrepeat` reaches every consumer; dispatch does **not** gate on it
  (Decision 22). A binding wanting once-per-press wraps itself in
  `compy.input.fn.ignore_repeat`.

---

## The whole thing on one page

```
                       OS event
                          │
              love.event.pump / poll            harmony/init.lua:49
                          │
              love.handlers[name](...)          harmony/init.lua:67
                          │
   ┌──────────────────────▼───────────────────────────────────┐
   │ TIER 1  handlers.keypressed        controller.lua:889     │
   │  keys_pressed[k] = true                                   │
   │  ctrl+t quickswitch · ctrl+pause · ctrl+q · ctrl+s        │
   │  (keyreleased tier also holds ctrl+escape → quit)         │
   │  UN-SHADOWABLE — above the route split                    │
   └──────────────────────┬───────────────────────────────────┘
                          │  love.keypressed(k, sc, isr)
              ┌───────────┴────────────┐
              │                        │
     CONSOLE / DEFAULT           PROJECT ROUTE
     controller.lua:456          occupy_keyboard :249
              │                        │
   ctrl+shift+1/2/3/5 debug            ▼
   ctrl+alt+d termdebug         PIC:_dispatch          pic.lua:108
              │                        │
              ▼                 ┌──────▼─────────────────────────┐
   forward_keypressed :38       │ 1. shortcuts[event][combo]     │
              │                 │      exact, then 'mod+*' class │
     ┌────────┴────────┐        │      truthy → CONSUMED         │
     │                 │        ├────────────────────────────────┤
  widget up?       no widget    │ 2. hooks[event]                │
     │                 │        │      truthy → CONSUMED         │
     ▼                 ▼        ├────────────────────────────────┤
 ui.C:keypressed  CC:keypressed │ 3. widget, if is_shown()       │
 return true      consoleC:1366 │      always CONSUMES           │
     │                 │        ├────────────────────────────────┤
     │            ┌────┴────┐   │ 4. return false — silent       │
   RETURN         │         │   └────────────────────────────────┘
   (route's own   editor   console line
    handling      fork     history · error lock · Enter→eval
    SKIPPED)               ctrl+L · ctrl+alt+t
```

---

## Where the two routes disagree

| | console route | project route |
|---|---|---|
| shape | boolean presence gate | three-tier walk |
| widget position | **first**, and exclusive | **last**, terminal step |
| consume signal | "a widget existed" | handler return truthy |
| shortcuts tier | none (ad-hoc `if` blocks) | `shortcuts[event][combo]` |
| hooks tier | none | `hooks[event]` |
| hidden widget | n/a (presence is the test) | skipped, walk continues |

The console route is the pre-feature shape. At the PR base `3256aac`
that shape lived at **Tier 1** (`love.handlers.*`), above both routes —
`if user_input then ui.C:keypressed(k) else love.keypressed(k) end` —
and the console's own default had no widget test at all. The feature
removed it from Tier 1 (`:987-995` states this) and the same gate
reappears inside the console route at `:491`.

`decisions/input.md:88` — *"Widget visibility is state on the widget,
never a routing condition"*; `:95` — *"the overlay gate is gone."* On the
project route it is. On the console route it was relocated.

**Reachability is narrow.** The console route only owns the slot while a
project overlay exists in one case: top-level code called
`compy.input.show{}` and then raised, so `set_user_handlers` at
`consoleController.lua:124` never ran. A clean stop hides the overlay
before restoring defaults. The editor fork is not reachable behind the
gate either — ctrl+t runs `stop_project_run` → `hide_overlay()` first.

---

## Pointer is a different shape — do not conflate

```lua
handlers.mousepressed = function(x, y, btn, touch, presses)  -- :1036
  local user_input = get_user_input()
  if user_input then
    user_input.C:mousepressed(x, y, btn, touch, presses)     -- no bounds check,
  else                                                       -- no consume,
  end                                                        -- return discarded
  if love.mousepressed then                                  -- :1042
    return love.mousepressed(x, y, btn, touch, presses)      -- ALWAYS also fires
  end
end
```

This is a **broadcast**, not a gate: widget *and* slot occupant both
receive it. Pointer never had the lockout, so it was deliberately left as
pre-existing behaviour — ratified as owner ruling 9, logged as
`technical_debt/input.md` "Pointer delivery is an unstructured
broadcast". Also note the empty `else` branch at `:1040-1041`, which is
dead syntax.

Pointer also installs differently: `hook_pointer` (`:262`) assigns the
project's wrapped handler straight onto `love[k]`, with the return
discarded — no chain participation.

---

## Addendum — four questions the diagram raised (owner, 2026-08-03)

### 1. The console's own widget is NOT the one in "widget up"

There are **two** `UserInputController` instances and the diagram only
showed one.

| instance | created | registered in `love.state.user_input`? | reached how |
|---|---|---|---|
| the console line | `consoleController.lua:44`, `UserInputController(M.input):always_shown()` | **no** — `always_shown()` sets only `self.shown` (`userInputController.lua:454`) | inside `CC:keypressed` → `input:keypressed(k)` (`:1417`) |
| a project overlay | `UserInputController:show()` → `love.state.user_input = {M,C,V}` (`userInputController.lua:287`) | **yes** | the `forward_*` gate |

So on the diagram the console line sits *below* `CC:keypressed`, inside
tier 2A — it is not a chain participant at all. The gate is only ever
about a **project** overlay.

### 2. Pre-feature, who installed the checked widget? Also the project.

At `3256aac` the setter was a local `input(eval, prompt, init)`
(`consoleController.lua:562-580`), which built M/C/V and assigned
`love.state.user_input = { M, C, V }`. Its only callers were the legacy
project-facing polling API — `project_env.input_code` (`:589`),
`project_env.input_text` (`:594`), `project_env.validated_input`
(`:609`), plus `project_env.user_input` (`:582`) for the handle.

And the console's own line was already a separate unregistered instance
(`local IC = UserInputController(M.input)`, old `:44`).

**So the actor never changed** — a project installs the widget, then and
now. What changed is the API it uses (`input_text()` polling →
`compy.input.show{}` + callbacks) and where the gate lives (tier 1 →
inside the console route).

### 3. What sits behind the gate — the five things named on the diagram

All inside `ConsoleController:keypressed` (`consoleController.lua:1366`):

- **editor fork** (`:1386`) — `app_state == 'editor'` delegates the whole
  event to `self.editor:keypressed(k)`. This is why the editor is not a
  slot occupant: it is a branch of the console route, not a sibling.
- **error lock** (`:1397`) — while `input:has_error()`, everything is
  swallowed except space / enter / up / down, which call `clear_error()`
  and return. This is the lock recorded in the ledger as "correct,
  documented, and hostile", and it is what `suspend()` arms (see 4).
- **history** (`:1405`) — pageup / pagedown walk the console's command
  history (`input:history_back()` / `history_fwd()`).
- **console line** (`:1417`) — `input:keypressed(k)`, the editing side
  effects on the console's own widget. Its return is unused (Decision 5
  retired it; vertical-boundary navigation goes through the widget's
  `on_limit_reached` callback instead).
- **enter→eval** (`:1418`) — Enter without Shift, and no error pending,
  runs `self:evaluate_input()` — the console REPL actually evaluating.
- **ctrl+L / ctrl+alt+t** (`:1425`) — clear the output buffer; run the
  terminal test under `love.DEBUG`.

### 4. How the console takes the route back on suspend / raise

Two different paths, and only one of them suspends.

**A raise inside a `love.*` handler or hook** → `wrap` →
`user_error_handler` → `CC:suspend_run(msg)`:

```
suspend_run(msg)                     consoleController.lua:1164
  guard: only from 'running'
  app_state = 'snapshot';  suspend_msg = msg

  ... next frame, inside love.update:              controller.lua:715
  app_state == 'snapshot' → gfx.captureScreenshot(...)
      └─ in the capture callback:  CC:suspend()    controller.lua:719

suspend()                            consoleController.lua:1144
  app_state = 'inspect'                            :1150
  self.input:set_error({ msg })   ← ARMS THE ERROR LOCK on the console line
  save_user_handlers(runner_env['love'])           :1159  remember the project's
  set_default_handlers(self, self.view)            :1160  CONSOLE TAKES THE SLOT
```

Note what this does to the gate: under `'inspect'`, `get_user_input()`
returns nil (`controller.lua:22`, Decision 12). So `forward_*` reports
false and the console gets the **full** `CC:keypressed` — including the
error lock that `suspend()` just armed one line earlier. The suspended
project's overlay is unhonoured for draw too, by the same gate
(`set_love_draw`'s comment, `:747`).

Resume is the mirror: `restore_user_handlers` (`controller.lua:1180`)
feeds the saved `_userhandlers` back through `set_handlers`.

**A raise in project top-level code** does NOT take this path.
`run_user_code`'s `pcall` (`consoleController.lua:118`) returns false,
`run_project` prints one console line and drops to `project_open` — no
snapshot, no suspend, no error window. That asymmetry is the ledger's
"A raise from project top-level and from a handler surface differently",
deferred to stakeholders post-PR. It is also the only case that leaves
an orphaned project overlay under the console route's gate.

---

## Addendum 2 — when can the gate actually fire? (owner, 2026-08-03)

The owner's reasoning: if a project runs it owns the slot, and if no
project runs no project widget can be up — so what does the console
check? Enumerated rather than argued.

| app_state | owns the slot | overlay possible? | gate fires? |
|---|---|---|---|
| `ready` (boot) | console | no — nothing has run | no |
| `running` | **project (PIC)** | yes | n/a — console route not installed |
| `project_open`, interactive | **project (PIC)** | yes | n/a |
| `project_open`, not interactive | console | **no** — see interlock (a) | no |
| `snapshot` → `inspect` | console (`suspend:1160`) | flag may persist | **no** — see interlock (b) |
| after `stop_project_run` | console (`:1272`) | no — `hide_overlay()` `:1274` | no |
| `editor` | console + fork | no — ctrl+t stops the run first | no |
| **top-level `show{}` then raise** | console | **yes** | **YES** |

Two interlocks make the ordinary rows dead, and they were not designed
as a pair:

- **(a)** `run_project:278` hands the route back only when
  `user_is_interactive()` is false, and that predicate
  (`controller.lua:1157`) is `love.state.user_input ~= nil or
  user_pointer`. So the console gets the slot **precisely when no overlay
  is up**. The two conditions are complementary by construction.
- **(b)** `suspend()` never hides the overlay — but `get_user_input()`'s
  `'inspect'` gate (`controller.lua:22`, Decision 12) makes it invisible
  anyway, to input and to draw alike.

**The single live path.** Project top-level calls `compy.input.show{}`
and then raises. `run_user_code`'s `pcall` (`consoleController.lua:118`)
returns false, so `set_user_handlers` at `:124` never runs;
`run_project:265` calls `release_keyboard_route`, which deactivates PIC
and reinstalls the console handlers (`controller.lua:814`) but **does
not touch `love.state.user_input`**; app_state becomes `'project_open'`,
not `'inspect'`, so the Decision 12 gate does not apply.

Result: the console owns the slot with a live orphaned overlay, and
`forward_keypressed` routes the user's keystrokes into the overlay of a
project that failed to load — while the user is looking at a console
that, per the ledger, "gave no signal they were still inside a project".

**So the gate's only reachable behaviour is a contribution to a known
defect.** Everywhere else it is dead code.

## Addendum 3 — why the editor forks instead of occupying a slot

Ratified deferral, not oversight. `decisions/input.md:97`:

> **Consequence.** The three routes are siblings. Today the editor is
> still reached through the console route's internal fork rather than as
> a fully independent third sibling; converging the console and editor
> onto the same chain the project route already uses is **deliberately
> left as a follow-on**, not attempted in the pass that introduced this
> model. **The project route is the proving ground for the shape.**

`occupy_keyboard`'s own comment (`controller.lua:236`) repeats it: "the
three routes are not yet fully symmetric (the editor is still reached
via the console fork), so PIC is wired explicitly here."

The reuse seams for that follow-on are already cut and currently unused:
`dispatch` is a free function over plain tables + a widget reference
(`pic.lua:84`), and `build_widget_api` is parameterized by resolvers
(`consoleController.lua:618`) — which has exactly **one** adopter today,
the project overlay (`:746`).
