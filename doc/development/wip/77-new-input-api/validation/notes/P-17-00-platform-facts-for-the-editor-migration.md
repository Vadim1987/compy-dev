# P-17-00 — platform facts the maze editor migration turns on (measured)

**Session:** 39, 2026-08-12. **Status:** evidence note, feeding step C of
`../reviews/P-17-00-shape-and-plan.md`. Not a plan and not a verdict.

These are the platform behaviours the `core_editor.lua` migration depends on. Each was read in code
or in `doc/input_api.md`, and the two that matter were checked **at the PR base `3256aac`** as well,
because the question is what *changed*.

---

## 1. A `show()` over a shown widget is a no-op that WARNS — this repo has been bitten already

`userInputController.lua:266-279, 316-320`:

```lua
function UserInputController:show(config)
  if self.shown then return re_show(self, cfg) end
  open_widget(self, cfg)
end

local re_show = function(self, cfg)
  if not cfg.force then
    Log.warn('UserInputController:show ignored — widget already active …')
    return
  end
  if cfg.text ~= nil then self.model:set_text(cfg.text) … end
end
```

Two consequences, both load-bearing for the migration:

- **A re-show cannot change the prompt.** Even with `force`, only `text` applies. Upstream's
  `reject_program` and `rearm_input` both call `input_text(input_prompt(), …)` **to change the
  prompt** — that is how a syntax error is shown (`input_prompt()` returns `GS.invalid.msg`). The
  replacement is **`compy.input.configure{ prompt = … }`** plus `set_text`/`clear`, not `show`
  (`doc/input_api.md`, "`configure(config)`": same keys except `force`, and *"active `text` and
  `cursor` are not changed by `configure`, so use `set_text`, `set_cursor`, or `clear`"*).
- **A per-tick `show()` logs a warning per tick.** This is not hypothetical: our own maze migration
  hit it and recorded it — `790ac19`'s message, *"the guard as first written never fired, and show()
  was re-issued on every tick, warning each time"*. Upstream's `rearm_input` runs from `ctrl_update`
  **every tick** and calls `input_text` unconditionally on the not-running branch. **At the base that
  was silent** (§2); under `compy.input` a naive port is a warning per frame.

## 2. At the PR base, a second `input_text()` while one was shown was a SILENT no-op

`3256aac:consoleController.lua:562-566`:

```lua
local input = function(eval, prompt, init)
  if love.state.user_input then
    return -- there can be only one
  end
```

So upstream's per-tick `input_text` re-arm has always been a no-op **while the field was up**; the
field persisted, and so did its contents. The behaviour the migration must reproduce is therefore
*"leave the field alone"*, not *"re-open it"* — and reproducing it literally with `show{}` would be
correct-but-noisy (§1), which is why `configure`/`set_text` is the right shape and not a flourish.

**A correction to a claim I nearly asserted.** I began by reading our own `d2ce7a0` commit message —
*"submit used to hide the overlay and clear the field"* — as a statement about the PR base, and was
about to file "the overlay no longer closes on submit" as a **regression the new platform
introduces**. It is not. That message describes an **intermediate state of the feature's own
development** (its M5c era). At the base, submit did not hide either: `submit()`
(`3256aac:userInputController.lua:343-359`) evaluates and fills the reftable, and nothing clears
`love.state.user_input`. So a `<`-command exit leaving the field shown over the menu is
**pre-existing upstream behaviour**, not ours to fix under the regression heading.
*Baseline discipline, again: judge against the PR base, not against the feature's own history.*

## 3. What DID change, and it is the enabling change

At the base, a shown widget meant the project's handler was **not called at all**
(`3256aac:controller.lua:625-630`). At HEAD the gateway forwards unconditionally and the project
route walks **shortcuts → hooks → widget** (`projectInputController.lua:135-145`). So:

- **`shift+escape` can now reach the program while the field is active** — the capability
  `b8cc436`'s `TEMPORARY` comment asks for, and the reason the typed `<` exists.
- **Every key typed into the field now also reaches the game's `love.keypressed` first.** Read
  statically it is inert in both programs — on editor levels `arm_editor` sets `ctrl_pressed = nil`,
  and `SYSTEM_KEYS` holds only a `menu` entry no key name can reach — but **inert-by-reading is not
  inert-by-measurement**, and this is the first time this project's handler and its field are live at
  the same instant.
- **Neither `to_menu()` nor `toDrawMenu()` hides the overlay** (`maze_main.lua:92-96`,
  `draw_main.lua:219-228`); they drop `ctrl_update`/`ctrl_pressed` only. That was complete when the
  only way to reach them from an editor level was the typed `<`. It is **not** complete once
  `shift+escape` reaches them, so whatever lands E6 owes those two functions a teardown. This is a
  consequence of the change we are making, not a defect of theirs.

## 4. The menu-digit question has a documented answer, so it is a technique, not an open ruling

`doc/input_api.md`, "Opening the overlay from a key", states the problem exactly — *"a prompt opened
from `i` can come up with an `i` already in the field … the `is_shown()` guard does not help: it is
about the next press, not this one"* — and gives the pattern: a **one-shot shortcut on the
`textinput` channel**, which runs before the overlay and unregisters itself. Two constraints come
with it: **re-arm wherever you close the overlay yourself** (Escape *clears without closing*, so the
spent one-shot is still correct), and **the trigger must be a bare key** — a modified combo cannot be
guarded, because the two channels do not share a combo string for it.

`menu_key(k)` matches `"1"`/`"2"`/`"3"` and `start_track` → `start_level` can call `editor()`
synchronously, so track 3 (`sandbox`, the two editor levels) is exactly the shape. **Still to be
driven rather than asserted** — but the ruling it needed has turned into a lookup.

## 5. The whole legacy surface, for the record

`core_editor.lua` only — 6 sites, and the file is CORE (copied into **both** emitted programs):

| line | call | replacement |
|---|---|---|
| 44 | `GS.input:is_empty()` | — (the poll disappears) |
| 47 | `GS.input()` | `on_text_entered(lines)` |
| 59 | `input_text(input_prompt(), lines)` — reject path | `configure{ prompt }` + `set_text` |
| 91 | `input_text(input_prompt(), lines(GS.program or ""))` — per-tick re-arm | see §1/§2 |
| 100-101 | `ctrl_update = process_user_input`, `GS.input = user_input()` | — |
| 102 | `input_text("Commands:", lines(text))` | `show{ prompt, text, on_text_entered }` |

`rearm_input` does **two** jobs and only one of them is the editor's: it also detects run completion
(`if GS.running then finish_run() end`). That half is a genuine per-tick state poll and stays.
