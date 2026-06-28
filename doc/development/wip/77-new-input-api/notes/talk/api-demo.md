# Feature #77 — API consumption guide (demo sketches)

_LLM(Claude Sonnet 4.6): 2026-06-24 (session 23). Developer-facing. Sketches how
projects consume the new `compy.input.*` surface. Evolves alongside acceptance
tests during M5a–M6. Canonical contract lives in `design/spec.md`._

> **Status.** Draft — API surface not yet shipped. Sketches are based on the frozen
> spec and design decisions. Handlers syntax (§2.3) is M5b sugar, deferred. All
> other patterns below are M5a/M6 scope.

---

## Overview — two channels, one widget

```
love.keypressed → compy.input.on_key_pressed(k, keys, isrepeat)
                      ↳ default: text-editing sink (M4/M5a wires this)

love.textinput  → compy.input.on_text_entered(text, keys)
                      ↳ default: text-editing sink

compy.input.show({validator, highlighter, ...})   — activate the widget
compy.input.after_submit(result)                  — receive submitted text
compy.input.before_exit / compy.before_exit       — project stop cleanup
```

Both channels fire independently for a character key. No suppression, no
classification. Modifiers are ordinary keys; `keys_pressed` is the live set.

---

## 1. Text-input widget (simplest case)

A project that just wants a text-entry prompt — no custom key handling:

```lua
-- Activate with a prompt and optional validator:
compy.input.show({
  prompt    = "Enter name: ",
  validator = function(text)
    if #text > 0 then return true end
    return false, "Name cannot be empty"
  end,
})

-- Receive the submitted result:
compy.input.after_submit = function(name)
  player_name = name
end
```

The text-editing sink handles all typing. The project never touches
`on_key_pressed` or `on_text_entered`.

---

## 2. REPL / command loop (maze pattern — textinput channel)

A project with its own DSL validator, highlighter, and evaluator. The widget
re-arms after each submitted command.

```lua
local function start_repl()
  compy.input.show({
    prompt      = "> ",
    multiline   = true,
    validator   = validate_input,    -- DSL grammar check (is_valid_line)
    highlighter = highlight_command, -- markup: col_from / col_to refs
  })
end

-- Evaluate → re-arm:
compy.input.after_submit = function(command)
  process_input(command)   -- your evaluator (enqueue_commands etc.)
  start_repl()             -- re-arm for the next command
end

-- On load:
start_repl()
```

**What `on_text_entered` does here:** nothing special. The default sink inserts
typed characters into the widget as usual. maze never overrides it.

---

## 3. Raw key handling (keyboard pattern — keypressed channel)

A project that processes key events directly, without the text widget:

```lua
-- Replace the default sink with a custom handler:
compy.input.on_key_pressed = function(k, keys_pressed, isrepeat)
  if isrepeat then return end      -- fresh presses only

  if k == "space" then
    trigger_action()
  elseif k == "escape" then
    exit_mode()
  end
  -- keys_pressed is the full live set (read-only proxy):
  -- keys_pressed["lshift"] → true/nil
end
```

The text-editing sink is replaced entirely. `on_text_entered` still fires for
character keys but the replaced `on_key_pressed` means text won't be inserted
(the sink is gone) — this is intentional when the project owns the input
completely.

---

## 4. Device-state cleanup on exit (keyboard / before_exit pattern)

A project that sets LÖVE device state (e.g. disables key-repeat) and must restore
it when the project stops:

```lua
-- Disable key-repeat at project start:
love.keyboard.setKeyRepeat(false)

-- Restore on project stop (T3 cleanup):
compy.before_exit = function()
  love.keyboard.setKeyRepeat(true)
end
```

`compy.before_exit` fires on project stop including `Ctrl+Esc`. This is the
opt-in, project-owned cleanup path (Layer 1 from E9 §8). The framework does not
enforce it; a project that skips it leaks device state until the next project run.

---

## 5. Combo handler table — M5b sugar (future)

After M5b ships, projects can register per-combo handlers instead of an
`if/elseif` chain inside `on_key_pressed`:

```lua
-- Save with Ctrl+S (consumes the event; sink won't run):
compy.input.handlers['ctrl+s'] = function(k, keys_pressed)
  save_project()
  return true   -- truthy = consume; chain stops here
end

-- Show help with F1 (doesn't consume; sink still runs):
compy.input.handlers['f1'] = function(k, keys_pressed)
  show_help()
  -- return nothing / nil = pass through
end
```

`handlers` normalises keys on assignment: `'Ctrl+S'` and `'ctrl+s'` resolve to
the same entry. Dispatch is exact-match by default; the `__matcher` seam allows
override for glob/prefix matching.

**Without M5b (M5a only),** the same behaviour via `on_key_pressed`:

```lua
compy.input.on_key_pressed = function(k, keys_pressed, isrepeat)
  local combo = combo_string(k, keys_pressed)  -- "ctrl+s", "f1", etc.
  if combo == 'ctrl+s' then save_project(); return end
  if combo == 'f1' then show_help() end
  -- fall through to custom sink logic
end
```

---

## 6. Native handler coexistence (D-9 — pong / turtle / life)

Projects that define native `love.keypressed` and never touch `compy.input`
continue to work unchanged:

```lua
-- This project uses native LÖVE directly — no compy.input setup:
function love.keypressed(key, scancode, isrepeat)
  if key == "up"   then move_up()   end
  if key == "down" then move_down() end
end
```

`ProjectInputController` detects the absence of any `compy.*` surfaces and
auto-provisions a lifecycle-split wrapper: the text-editing sink is active when
the widget is shown, the native handler resumes when it is hidden. Zero example
changes required.

---

## Channel summary

| Channel | Callback | Default value | Replaces default when… |
|---|---|---|---|
| `keypressed` | `on_key_pressed(k, keys, isrepeat)` | text-editing sink | project assigns a function |
| `textinput` | `on_text_entered(text, keys)` | text-editing sink | project assigns a function |
| submit | `after_submit(result)` | no-op (debug log) | project assigns a function |
| cancel | `after_cancel()` | no-op (debug log) | project assigns a function |
| project stop | `compy.before_exit()` | no-op | project assigns a function |

Both channels reset to defaults when the project stops.
