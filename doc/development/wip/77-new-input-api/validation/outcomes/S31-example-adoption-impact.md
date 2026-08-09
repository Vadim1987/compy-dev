# S31 — per-example adoption impact census

Evidence base for the owner's ruling on whether the net impact of
`compy.input` adoption across the 14 bundled examples characterises the
feature as good. **This file does not rule** — it reports what each
example uses, what breaks, what adoption costs and buys, and where the
correct answer is "do not adopt".

Scope: branch `feature/77-newapi-analysis-s20260615`, PR base `3256aac`.
Read-only pass; nothing edited, nothing committed, the app was not run.
Platform suite re-run for state: **955 successes / 0 failures / 0 errors
/ 3 pending**.

Eight tracked examples were already migrated *on this branch*
(`git diff 3256aac..HEAD -- src/examples/`: guess, paint, repl, sapper,
tixy, turtle, valid, + paint README). All three nested repos
(`keyboard`, `maze`, `balloons`) were migrated in their own histories.
So most rows below are assessed against what the migration actually
cost, not against a hypothetical. Where an example is *not* migrated,
the assessment of adopting is marked as such.

**Confidence discipline.** Everything asserted about the platform is
verified in `src/` and cross-checked against `3256aac`. The three
nested example repos have **no test suite**, and nothing here was
executed; every behavioural claim about them is reasoning over code,
explicitly marked *(inference)* where the user-visible outcome, rather
than the mechanism, is the claim.

---

## Summary table

| Example | Input surface today | Breaks if API ships & it is NOT adapted | Impact of adopting | Verdict |
|---|---|---|---|---|
| **keyboard** *(nested)* | `hooks.*` ×3, `shortcuts.keypressed` ×5 + `fn.*`, `keys_pressed` via `INPUT` proxy | **No** — pre-adoption used only `love.*` handlers, which seed | **Positive (strongest)**: deletes a whole hand-rolled subsystem, −19 code lines | adopt *(done)* |
| **maze** *(nested)* | `compy.input.show/is_shown/hide`; `love.keypressed/keyreleased/mousepressed/resize`; 2 device polls | **Yes, hard** (base used `user_input()`/`input_text()`); **and a live regression remains at HEAD** | **Positive**: −12 lines net, kills hand-rolled edge detection, closes a Tab-into-prompt hole; but an `is_shown()` guard is mandatory overhead | adopt — **unfinished** |
| **balloons** *(nested)* | `compy.input.show/configure/callbacks` only; no key/pointer handlers at all | **Yes, hard** (`user_input()`, `input_text()`) | **Overhead → mild negative**: line-neutral, added an indirection the author flagged, needed 2 follow-up fixes | adopt *(done)*, unhappily |
| **guess** | `compy.input.show` + `LineValidators` + `after_submit` | **Yes, hard** (`user_input()` at base:2) | **Positive**: −14 code lines; the whole `love.update` poll loop gone | adopt *(done)* |
| **tixy** | `show{highlighter,validator}`, `set_text`, `after_cancel`; `love.mousepressed` + `Key.shift()` | **Yes, hard** (`user_input()`, `input_code`, `write_to_input`) | **Positive on correctness, +6 lines**: Escape no longer empties the code strip; mouse handler is a further clean 11→3 | adopt *(done)*; finish the mouse |
| **repl** | `show` + `after_submit` | **Yes, hard** | **Positive, tiny**: 8 → 6 code lines, poll loop gone | adopt *(done)* |
| **valid** | `show` + `LineValidators` | **Yes, hard** | **Overhead**: −1 line, functionally identical; value is as `LineValidators` documentation | adopt *(done)* |
| **turtle** | `shortcuts.textinput['i']`, `after_submit`, `show`, `is_shown`; `love.keypressed/keyreleased` | **Yes, hard** (`user_input()` at base:12); **and a live regression remains at HEAD** | **Mild negative**: **+13 code lines**, adds echo-guard ceremony a beginner example now has to explain | adopt *(done)*, but it got worse |
| **paint** | `hooks.singleclick/doubleclick`; `love.mousemoved`, `love.keypressed`; `Key.shift()` | **Yes — SILENTLY** (`compy.singleclick` assignment becomes inert; no error) | **Overhead**: 2-line rename, 0 net lines, bought nothing | rename only; leave the rest |
| **sapper** | `hooks.singleclick/doubleclick`; `love.mousepressed`; `Key.*` ×4 | **Yes — SILENTLY** (same mechanism) | **Overhead so far**; one clean win left on the table (9 → 2 lines via `mousepressed` shortcuts) | rename done; **adopt-later** the shortcuts |
| **clock** | `love.keyreleased`; `love.keyboard.isDown` (event-time) | **No** — handler seeds; no widget | **Positive, small**: 21 → ~7 lines via 4 `shortcuts.keyreleased` entries | adopt-later (low priority) |
| **life** | `love.keypressed/mousepressed/mousereleased`; `love.mouse.isDown` (frame-time) | **No** | **Neutral**: ~5 lines saved on the key dispatcher; its held-*button* poll has **no API equivalent** | leave as-is |
| **pong** | `love.keypressed/mousemoved`; `love.keyboard.isDown` ×3 (frame-time) | **No** | **Negative**: level-triggered paddle movement on the wrong clock; state-keyed bindings do not fit static shortcuts | **do not adopt** |
| **sine** | none — 30 lines of top-level `love.graphics`, no handlers at all | **No** | **Unnecessary** | leave as-is |

Breakage tally: **9 of 14 break** at base — 7 raise loudly, **2 fail
silently** (paint, sapper). 5 are untouched by the change (keyboard,
clock, life, pong, sine).

---

## Backward compatibility: `seed_hooks` confirmed, and where it is not true

**Mechanism, confirmed.** `seed_hooks`
(`/repo/src/controller/projectInputController.lua:65-71`) walks `EVENTS`
(`:34-39`) and fills `hooks[event]` from the project's own handler where
the project set none. It is fed by `project_handlers`
(`/repo/src/controller/controller.lua:207-213`), which takes any
`userlove[k]` that differs from the console default, over `_bindable`
(`/repo/src/controller/controller.lua:92-100` — keyboard + pointer +
the two derived clicks, exactly the list `EVENTS` dispatches on). Every
bundled example's `love.keypressed` / `keyreleased` / `textinput` /
`mousepressed` / `mousereleased` / `mousemoved` is picked up.

**Refuted as "keeps working untouched", in three distinct ways.**

1. **Ordering — the one that actually bites.** A seeded hook runs
   *before* the widget and runs **unconditionally**
   (`projectInputController.lua:132-142`: hook first, widget only after).
   At base, keyboard events went to the widget **instead of** the
   project handler:

   ```
   -- git show 3256aac:src/controller/controller.lua, handlers.keypressed tail
   local user_input = get_user_input()
   if user_input then
     user_input.C:keypressed(k)
   else
     if love.keypressed then return love.keypressed(k) end
   end
   ```

   So any example that both defines a keyboard `love.*` handler **and**
   shows the input widget changes behaviour without touching a line.
   Two bundled examples are in that set, and **both are broken on this
   branch right now** — see turtle and maze below. Pointer events are
   *not* affected: the base gateway already delivered them to the widget
   **and** the project (`3256aac`, `handlers.mousepressed`), so only the
   order flipped.

2. **Consume-on-truthy.** A seeded handler that returns a truthy value
   now swallows the event before the widget. I checked all fourteen
   examples: none currently returns truthy from a keyboard/pointer
   handler, so nothing breaks today. It remains a silent semantic
   change applied to code its author never wrote as a chain
   participant.

3. **Seed timing.** Seeding happens once, at `activate`, after the
   project's top-level code (`projectInputController.lua:60-62`), and a
   project runs against a sandboxed *clone* of `love`. A handler
   assigned later — from `update`, or on a scene switch — is written to
   the clone and never seen. No bundled example does this (maze's
   `love.mousepressed = SYSTEM_KEYS.menu`, `maze/main.lua:561`, is
   top-level), but it is the shape that would fail silently.

**And seeding says nothing about the retired globals.** `user_input`,
`input_text`, `input_code`, `validated_input`, `write_to_input` no
longer exist anywhere outside `src/examples/` (grep over `src/`), so a
call raises `attempt to call a nil value` at load. `compy.singleclick` /
`compy.doubleclick` are worse: `wrap_handler` and `get_compy_handler`
were removed together (`consoleController.lua:272-278`; base had
`get_compy_handler` at `3256aac:consoleController.lua:216`), and the
`compy` namespace's `__newindex`
(`consoleController.lua:861-871`) `rawset`s any key other than
`before_exit`/`input`. So `function compy.singleclick(x, y)` **is
accepted and read by nobody** — no error, just dead clicks.

---

## Timing classification, resolved by following callers

The four cases the briefing flagged, re-derived from call sites rather
than definitions:

| Site | Class | Chain that settles it |
|---|---|---|
| `clock/main.lua:68` | **event-time** | `shift()` has exactly two call sites — `color_cycle` (`:72`) and `love.keyreleased` (`:81`); `color_cycle`'s only caller is `love.keyreleased` (`:80`). |
| `maze/main.lua:564` | **event-time** | `is_shift_down` has exactly one reference, `maze/main.lua:569`, inside `love.keypressed` (LSP `references` + grep agree). |
| `pong/strategy.lua:35,37` | **frame-time** | `strategy.manual` is reached as `S.strategy.fn` (bound at `pong/main.lua:149`), called at `:373` in `step_game` ← `update_fixed` `:378` / `love.update` `:388`. |
| `maze/main.lua:517` | **frame-time** | `poll_tab_progression` called at `maze/main.lua:536`, first statement of `love.update`. |

Others resolved the same way:

- `pong/main.lua:330` — **frame-time**: `update_player` called at
  `:372` inside `step_game`. Under `USE_FIXED` it runs up to
  `MAX_STEPS` times per frame.
- `turtle/main.lua:34` — **event-time** (`love.keypressed` body);
  `turtle/main.lua:92` — **event-time** (`love.keyreleased` body).
- `paint/main.lua:407` (`Key.shift()`) — **event-time**
  (`love.keypressed` body). `paint/main.lua:369`
  (`love.mouse.isDown`) — **event-time** (`love.mousemoved` body).
  `paint/main.lua:282` (`love.mouse.getPosition`) — **draw-time**
  (`drawTarget` ← `love.draw` `:290`).
- `tixy/main.lua:197` (`Key.shift()`) — **event-time**
  (`love.mousepressed` body).
- `life/main.lua:101` (`love.mouse.isDown(1)`) — **frame-time**
  (`love.update` body).
- `sapper/main.lua:672,690` — **frame-time, and up to 0.4 s late**.
  These sit inside the *derived* click hooks, which the click timer
  synthesises from `love.update` (`controller.lua:561-587`) after
  `click_delay = 0.4` (`controller.lua:353`; the same value at base,
  `3256aac:controller.lua:109`). `sapper/main.lua:697,701` are
  event-time (`love.mousepressed` body).
- `keyboard`: `INPUT.shift` at `keyboard_view.lua:171,178` and
  `alt.lua:230,240` — **draw-time** (`love.draw` → `drawStep` →
  `sceneDraw` (`scene.lua:70-73`) → `fkDraw` → `drawKeyboard`
  (`findkey.lua:212`, `intro.lua:128`, `alt.lua:284`)).
  `help.lua:11` (`helpHeld`) — **both**: event-time via
  `helpOverlayShown` in `input.lua:173,194`, and draw-time via
  `drawHelpLayer`. `alt.lua:203` — event-time (`altKeypressed`).

**Which clock is right** is settled by the repo's own debt entry
(`doc/development/technical_debt/input.md`, "The held-key set is never
cleared on focus loss"): *"The event-tracked set is the temporally
correct source for an event-time question, and the device poll is
correct for a frame-time one."* That single rule sorts most of the
verdicts below.

One caveat that cuts the other way, and belongs in any adoption advice:
`compy.input.keys_pressed` is maintained purely from events
(`controller.lua:788`, `:906`) with **no focus handler**, so it can go
stale with a key stuck `true`; `love.keyboard.isDown` cannot. Same debt
entry, "Scheduled: before the PR". Until that lands, moving a read onto
`keys_pressed` trades a small wrong-clock error for a small
stuck-key error.

`keys_pressed` is **keyboard-only** — it is written only in
`handlers.keypressed`/`keyreleased`. There is no held-*button* set, so
`love.mouse.isDown` has no API replacement at all. That is load-bearing
for life and paint.

---

## Per-example detail

### keyboard *(nested repo — no test suite)*

The deepest and the best case for the feature.

**Surface today.** `compy.input.hooks.keypressed/keyreleased/textinput`
(`keyboard/input.lua:102-104`); five `compy.input.shortcuts.keypressed`
entries wrapped in `compy.input.fn` combinators (`:84-95`:
`shift+escape`, `ctrl+alt+up`, `ctrl+alt+down`, `alt+*`, `alt+p`);
`compy.input.keys_pressed` read through the `INPUT` proxy (`:54-62`,
`:108-114`); `love.keyboard.setTextInput(true)` (`:99`).

**Breaks if unadapted? No.** At `4814407^` the game used only
`love.keypressed`/`keyreleased`/`textinput` (verified: `git grep` for
every retired global over that tree returns nothing). Those seed. **Its
adoption was voluntary** — which makes it the cleanest measure of what
the API is worth on merit rather than under duress.

**What adoption subtracted** (`git diff 4814407^..HEAD`):

- the `INPUT.held` mirror plus `inputUpdateMods()` (5 lines) and its two
  call sites in press/release → the framework's held set;
- `reservedChord()` (17 lines of hand-folded `INPUT.shift and not
  INPUT.ctrl` tests) → five `shortcuts.keypressed` registrations;
- `appChord()` (6 lines encoding "every Alt+x is a chord, unless Ctrl")
  → `sc['alt+*']` + `sc['alt+p']`. The modifier-*class* vocabulary says
  in two lines what the file wrote out by hand, including the "and not
  Ctrl" test — a class is its modifier set exactly, so `ctrl+alt+h`
  falls outside `alt+*` for free;
- three `love.*` wrapper functions in `main.lua` (9 code lines) that
  existed only to satisfy LÖVE's naming convention;
- repeat filtering inferred from a mirrored held set → LÖVE's real
  `isrepeat`, arriving as the third hook argument.

**Size.** Code lines (blank and comment-only excluded): `input.lua`
98 → 88, `main.lua` 96 → 87, `alt.lua` 189 → 189. **−19 code lines**;
raw diff is +141/−111 because the comments grew substantially.

**What adoption could NOT subtract — and this refutes part of the
briefing's premise.** `spendGlyph`, `GLYPH_CLAIMED`, `INPUT.upRecent`
and `INPUT_UP_GRACE` (`input.lua:64-66,147-160,180-181`) are *not*
duplicated platform machinery. They survive adoption because the
`textinput` channel carries **no `isrepeat`** — the API delivers it on
`keypressed` only. `spendGlyph` has exactly one caller, `alt.lua:173`
(LSP `references` and grep agree), and its whole job is to answer "has
this key's glyph been judged since its last release" without depending
on keypressed/textinput arrival order, which the platform explicitly
does not fix. **This is the API's one uncovered gap that a real example
still pays for.**

**What only `keys_pressed` could do.** The draw-time *modifier* reads
(`keyboard_view.lua:171,178`) were always expressible with `Key.shift()`
— a device poll from `draw` is a "now" question and legitimate. What
`Key.*` cannot express is `help.lua:11`'s `INPUT.held.h` — an
*arbitrary* key read outside an event. Before adoption that needed the
project's own mirror. That is the honest accounting of the held-set
surface's unique value here.

**Costs, on the record in this repo's own history.**

- `5de5a6d` then `f938fbc`: the hook signature changed under the project
  mid-flight (`(k, _, isr)` → `(k, isr)` → back). Two commits that
  cancel out — in-flight platform churn, not a property of the shipped
  API, but real adoption cost paid.
- `3a9d48c`: the Alt-keys scene showed a target and ignored it on
  desktop LÖVE. *(inference, and the important one to get right:)*
  reading `4814407^:input.lua`, the pre-adoption `inputStale` consulted
  the project's own `INPUT.held`, which `appKeypressed` set before the
  glyph arrived — so the same drop existed pre-adoption on any build
  that delivers keypressed first. The migration **preserved** the bug
  rather than introducing it; what the migration did was force the
  ordering assumption to be written down and re-examined. Unproven by
  construction — this repo has no suite and the game cannot be driven
  headlessly.

**Verdict: adopt (done). Positive, and the single strongest case** —
the only example where the API removes an entire hand-rolled subsystem
rather than renaming one.

### maze *(nested repo — no test suite)*

**Surface today.** `compy.input.show` (`maze/main.lua:480`),
`is_shown` (`:503`), `hide` (`:505`); seeded handlers
`love.keypressed` (`:568`), `love.keyreleased` (`:580`),
`love.mousepressed = SYSTEM_KEYS.menu` (`:561`), `love.resize` (`:583`);
two device polls (`:517` frame-time, `:564` event-time); and its own
shift mirror `macro_state.shift_held` (`macro.lua:12,74,87`, read at
`graphics.lua:345` at draw time).

**Breaks if unadapted? Yes, hard.** At `790ac19^` it called
`user_input()` (`controls.lua:20`) and `input_text()`
(`controls.lua:21`, `main.lua:458,474`) — the moment a level entered
editor mode the run would raise. Already migrated (`790ac19`,
`d2ce7a0`, `aeabb73`).

**Live regression still present at HEAD.** Because the seeded
`love.keypressed` now runs *before* and *regardless of* the widget,
while the "Commands:" prompt is up:

```lua
-- maze/main.lua:568-577
function love.keypressed(k)
  if k == "escape" and not is_shift_down() then
    return
  end
  local fn = SYSTEM_KEYS[k]      -- SYSTEM_KEYS.escape = love.event.quit  (:552)
  if fn then fn() end
  ...
```

**Shift+Escape typed into the command prompt now quits the game.** At
base the widget received the key and the project handler was never
called. The `menu` key likewise now toggles the grid while typing.
Mechanism verified in code; user-visible outcome is *(inference)* —
not run, no suite.

**What adoption would still subtract.**

- `poll_tab_progression` (`main.lua:516-526` plus `tab_was_down` at
  `:514` and the call at `:537`) hand-rolls edge detection over a
  frame-time device poll. `compy.input.shortcuts.keypressed['tab'] =
  fn.stop_here(fn.ignore_repeat(...))` replaces 13 lines with ~6, and
  fixes two things: a Tab press+release inside one frame is currently
  missed entirely, and the poll sits **outside** the dispatch chain, so
  Tab typed into the prompt resets or advances the level today.
- `is_shift_down` (`:563-566`) → `compy.input.keys_pressed`: 4 lines
  → 1, and the modifier question moves onto the event's own clock.
- `macro_state.shift_held`: the *level* read (`graphics.lua:345`, draw
  time) can come from `keys_pressed`, but the *release edge*
  (`finish_recording`, `macro.lua:87-90`) still needs `keyreleased`. So
  only ~3 lines go. Marginal — do not oversell this one.
- **Required, not optional:** an `is_shown()` guard (or moving the
  reserved keys onto `shortcuts`) in `love.keypressed`, +2-4 lines, to
  restore "the widget owns the keyboard while it is up".

**Size.** Migration so far: `main.lua` 452 → 459 code lines (+7),
`controls.lua` 20 → 19. Finishing the above lands roughly **−12 net**.

**Verdict: adopt — and it is unfinished.** Adoption deletes hand-rolled
edge detection and closes a real hole; but the mandatory `is_shown()`
guard is overhead the feature created, and shipping without it leaves a
primary student-facing example with Shift+Escape quitting mid-typing.

### balloons *(nested repo — no test suite)*

**Surface today.** `compy.input.configure({prompt = msg})`
(`terminal.lua:26`), `callbacks.after_submit` (`:35-37`),
`show({on_text_entered = deliver})` (`:38`). **No keyboard or pointer
handlers at all** — the entire UI is the text terminal plus `love.draw`
/ `love.update` routed through the project's own `hooks` table
(`main.lua:97-103`). No non-event reads anywhere; nothing to classify.

**Breaks if unadapted? Yes, hard** — `user_input()`
(`56347d0^:terminal.lua:20`) and `input_text(msg, nil)` (`:16`).

**Impact of adoption** (`56347d0`, `94a5f02`, `cc0dbd7`, `cb1dd26`).
Removed: the per-frame `terminal_read` poll, the `ui_read_input` alias
(`ui.lua`, −3), and the poll call from `hooks.update` — which is now a
wrapper that does nothing but call `state_updater`. Added: a
`current_handler` upvalue plus `terminal_set_handler`, wired from
`game_init`. Roughly line-neutral. The author's own REMARK is left in
the file:

> `can we somehow simplify setup of the deliver handler? now its
> literally 3 functions juggling each other`

Two follow-up corrections were needed after the migration commit —
`94a5f02` (`after_submit` must be assigned through
`compy.input.callbacks`, not passed to `show`, which *raises* on an
unrecognised key) and `cc0dbd7` (submit delivers **lines**, not a
command string). Both are exactly the friction points `doc/input_api.md`
documents; both were nevertheless got wrong first.

**Verdict: adopt (done) — overhead trending mild negative.** Mandatory,
line-neutral, introduced an indirection the author flagged as worse,
and cost two corrections.

### guess

**Surface today.** `compy.input.callbacks.after_submit` (`:42-44`),
`compy.input.show{prompt, validator = LineValidators({is_natural}),
on_text_entered}` (`:51-55`). No non-event reads.

**Breaks if unadapted? Yes, hard** — `r = user_input()` at
`3256aac:guess/main.lua:2`, top-level, so the run dies at load.

**Impact.** The `love.update` poll loop (base `:50-58`, 9 lines) is
gone, and a duplicate dead `is_natural` (14 lines, removed separately
in `9c8061b1`) with it. Code lines **52 → 38 (−14)**. The project no
longer hooks `update` at all, so it is non-blocking and stays live
through the `project_open` interactivity ruling
(`technical_debt/input.md`, ruling (a)).

Residual, flagged in-file as a TODO: feedback still goes through
`print()` to the console terminal. In `project_open` the console is on
screen, so the text is visible — a polish item, not breakage
*(inference; not run)*.

**Verdict: adopt (done) — positive.** Strictly simpler, and the clearest
demonstration of `LineValidators`.

### tixy

**Surface today.** `compy.input.set_text` (`:39`), `after_cancel`
(`:187-189`), `show{prompt, text, highlighter = LuaHighlighter,
validator = LuaSyntaxValidator, on_text_entered}` (`:210-216`);
`love.mousepressed` (`:195`) with `Key.shift()` (`:197`, event-time).

**Breaks if unadapted? Yes, hard** — `user_input()` (base `:171`),
`input_code` (base `:176`), `write_to_input` (base `:39`).

**Impact.** Code lines **174 → 180 (+6)**: `love.update` shrank to a
one-line `time = time + dt`, but three callback blocks appeared.
Correctness **gained**: `after_cancel` restores the last-good body, so
Escape can no longer leave the code strip empty — new behaviour the old
idiom did not have. Correctness lost: none found.

Left on the table: `love.mousepressed` (`:195-205`, 11 lines) maps
exactly onto three shortcuts — `shortcuts.mousepressed['mouse1'] =
advance`, `['shift+mouse1'] = retreat`, `['mouse2'] = randomize` — for
3 lines, because `combo_string` (`controller.lua:395-404`) builds the
**exact** held-modifier set, which is precisely what `Key.shift()` at
`:197` tests.

**Verdict: adopt (done) — positive on correctness, neutral on size;
finish the mouse handler for a clean 11 → 3.**

### repl

**Surface today.** `after_submit` (`:5-7`), `show{on_text_entered}`
(`:9-11`). No non-event reads.

**Breaks if unadapted? Yes, hard** (`user_input()` base `:1`,
`input_text()` base `:5`).

**Impact.** 8 → 6 code lines; the `is_empty()` poll in `love.update`
gone; project no longer blocking.

**Verdict: adopt (done) — positive, tiny.** It is a five-line example
whose whole job is to show the idiom, and the new idiom reads better.

### valid

**Surface today.** `after_submit` (`:78-80`), `show{validator =
LineValidators({min_length(2), is_lower}), on_text_entered}` (`:82-88`).

**Breaks if unadapted? Yes, hard** (`user_input()` base `:1`,
`validated_input` base `:77`).

**Impact.** 76 → 75 code lines. The filter list moved across verbatim;
behaviour identical.

**Verdict: adopt (done) — overhead.** It had to change and it is one
line shorter for it. Its remaining value is documentary.

### turtle

**Surface today.** `arm_echo_guard` one-shot on
`compy.input.shortcuts.textinput['i']` (`:53-59`, re-armed at `:70`);
`callbacks.after_submit` (`:68-71`); `show` (`:83-88`) behind an
`is_shown()` guard (`:82`); seeded `love.keypressed` (`:33`) and
`love.keyreleased` (`:78`); `love.keyboard.isDown` at `:34` and `:92`,
both **event-time**.

**Breaks if unadapted? Yes, hard** — `local r = user_input()` at
`3256aac:turtle/main.lua:12`.

**Impact.** Code lines **58 → 71 (+13)**. What was bought: a working
one-shot prompt. What was paid: a seven-line `arm_echo_guard` plus a
re-arm inside `after_submit`, and an `is_shown()` guard — both existing
*only* because the hook now runs ahead of the widget and because
keypressed/textinput have no ordering guarantee. The file now carries
25 lines of comment explaining LÖVE event ordering to the reader of a
beginner example.

**Live regression still present at HEAD.** `love.keypressed`
(`:33-45`) is a seeded hook, so it fires while the TURTLE prompt is up:
typing a **space** toggles `debug`, and **Shift+R** recentres the turtle
while typing an "R". At base the widget received keypresses *instead of*
the project handler. It needs the same `is_shown()` guard
`love.keyreleased` already has (+2 lines). Mechanism verified;
user-visible outcome *(inference; not run)*.

Note the file's own claim — *"turtle is the example that demonstrates
that path [love.\* seeded as hooks]"* (`:73-77`) — is currently
demonstrating it wrongly.

**Verdict: adopt (done), but mild negative.** The example got 22%
longer, acquired ceremony a beginner cannot be expected to derive, and
still leaks keys into its own prompt.

### paint

**Surface today.** `compy.input.hooks.singleclick` (`:356`) /
`doubleclick` (`:360`); `love.mousemoved` (`:364`); `love.keypressed`
(`:387`); `Key.shift()` (`:407`, event-time);
`love.mouse.isDown(btn)` (`:369`, event-time inside `mousemoved`);
`love.mouse.getPosition()` (`:282`, draw-time).

**Breaks if unadapted? Yes — and silently.** Base had
`function compy.singleclick(x, y)` at `3256aac:paint/main.lua:356` and
`doubleclick` at `:360`. Post-feature that assignment is `rawset` onto
`compy` and read by nobody. Clicking is the entire program; the failure
mode is a dead canvas with no error message.

**Impact of adopting.** The rename is 2 lines and **0 net code lines**
(342 → 342). Going further is not worth it: the eight `colorkeys`
entries plus one `Key.shift()` test would need **16** shortcut
registrations to express what a table lookup and one `if` do in 8 lines.
And two of its three device polls have **no API equivalent at all** —
there is no held-button set and no pointer position in `keys_pressed`.

**Verdict: rename only (done) — mild negative / pure overhead.**
Changed solely to stop breaking; bought nothing.

### sapper

**Surface today.** `compy.input.hooks.singleclick` (`:671`) /
`doubleclick` (`:689`); `love.mousepressed` (`:696`); `Key.shift/alt/
ctrl` at `:672`, `:690`, `:697`, `:701`.

**Breaks if unadapted? Yes — silently**, same mechanism as paint
(base `:671`, `:689`). Sapper is entirely mouse-driven.

**Impact.** The rename: 2 lines, **0 net code lines** (606 → 606).

One clean win is still on the table. `love.mousepressed`
(`:696-704`, 9 lines) is exactly two shortcuts:

```lua
compy.input.shortcuts.mousepressed['shift+mouse1'] = function(x, y) single(x, y) end
compy.input.shortcuts.mousepressed['ctrl+mouse1']  = function(x, y) doppel(x, y) end
```

because `combo_string` builds the exact held set, so `'shift+mouse1'`
matches shift-and-nothing-else — literally what `Key.shift() and not
Key.alt() and not Key.ctrl()` tests. **−9/+2**, and the modifier
question moves onto the event's clock.

The guards inside the two *click* hooks do **not** map. A triggerless
channel takes modifier **classes** only (`find_shortcut`,
`projectInputController.lua:101-111`), and a class is its modifier set
exactly — so expressing "no modifier at all" would mean enumerating all
seven non-empty subsets. Leave those as `Key.*` reads. (They are also
the worst-timed reads in the whole census: 0.4 s late, by construction
of the click timer. That latency is pre-existing — `click_delay = 0.4`
is unchanged from `3256aac:controller.lua:109` — and adoption does not
fix it, since `keys_pressed` at emission time is equally late.)

**Verdict: rename done (overhead); adopt-later the two mouse
shortcuts** — the best unclaimed simplification in the tracked set.

### clock

**Surface today.** `love.keyreleased` (`:79-87`, seeded);
`love.keyboard.isDown("lshift","rshift")` inside `local shift()`
(`:67-69`) — **event-time**, per the caller chain above.

**Breaks if unadapted? No.** No retired global; the handler seeds; the
widget is never shown, so the ordering change is moot.

**Impact of adopting** *(not migrated; this is a projection)*. Lines
`:67-87` (21 lines: `shift()`, `color_cycle()`, `love.keyreleased`)
collapse to four declarations:

```lua
local sc = compy.input.shortcuts.keyreleased
sc['space']       = function() color    = cycle(color)    end
sc['shift+space'] = function() bg_color = cycle(bg_color) end
sc['shift+r']     = setTime
sc['p']           = function() pause("STOP THE CLOCKS!") end
```

≈ **21 → 7 lines**, and the modifier cascade disappears entirely
(`'space'` and `'shift+space'` are distinct exact combos, so the
if/else vanishes without a behaviour change). Correctness: removes a
device poll answering an event-time question — the same class as the
standing debt entry "The gateway asks the device a question about an
event". Correctness risk introduced: held-set staleness, so a stuck
`lshift` after focus loss would cycle the background instead of the
foreground until a real shift press/release. Both are edge cases.

**Verdict: adopt-later, low priority** — a genuine simplification that
turns a hand-written modifier cascade into four declarations, but
nothing is broken and nobody is waiting on it.

### life

**Surface today.** `love.keypressed` (`:109-119`), `love.mousepressed`
(`:121`), `love.mousereleased` (`:128`); `love.mouse.isDown(1)`
(`:101`) — **frame-time**, accumulating `hold_time` for the
hold-to-reset gesture.

**Breaks if unadapted? No.**

**Impact of adopting** *(not migrated)*. The three-key dispatcher could
become four shortcut entries (`'r'`, `'-'`, `'+'`, `'='`), saving ~5
lines with no correctness change either way. The held-button
accumulator **cannot** move: `keys_pressed` is keyboard-only
(`controller.lua:788`, `:906`), so there is no held-button surface, and
the gesture is level-triggered anyway.

**Verdict: leave as-is.** Nothing to gain, and its most interesting
input read has no replacement.

### pong

**Surface today.** `love.keypressed` (`:315-320`) dispatching through a
state-keyed `key_actions[S.state][k]` table; `love.mousemoved`
(`:337`); `love.keyboard.isDown(k)` (`:330`) and
`strategy.lua:35,37` — all three **frame-time**, verified through
`love.update` → `update_fixed` → `step_game`.

**Breaks if unadapted? No.**

**Impact of adopting: negative.** Two independent reasons:

1. Paddle movement is **continuous and level-triggered** — "while Q is
   held, move up". Events give edges; reconstructing a level from edges
   means the project re-implements the held set the framework already
   has, and moving the read to `keys_pressed` puts a frame-time question
   on the event clock, which the repo's own debt entry names as the
   wrong direction and which can go stale on focus loss — leaving a
   paddle gliding with no key held. Under `USE_FIXED` the read happens
   up to `MAX_STEPS` times per frame; a device poll is exactly right
   there.
2. The keypressed bindings are **state-keyed** (`key_actions.play.r`,
   `key_actions.gameover.space`, an `escape` installed into every
   group at `:310-312`). Shortcuts are static registrations, so
   expressing this means re-registering the combo tables on every state
   transition — more code, plus a new lifecycle to leak.

**Verdict: DO NOT ADOPT.** This is the example the documentation should
point at when it says device polling is still correct. It is a finding,
not a gap.

### sine

**Surface today: none.** 30 lines of top-level `love.graphics` calls;
no `love.draw`, no `love.update`, no handler of any kind. Nothing to
classify.

**Breaks if unadapted? No.** **Impact of adopting: unnecessary.**

**Verdict: leave as-is.**

---

## Closing: what the census says about the feature

### Examples that make the feature look good (3)

- **keyboard** — the only example where the API removes an entire
  hand-rolled subsystem: a held-key mirror, a reserved-chord cascade,
  an Alt-class test written out by hand, three `love.*` wrappers, and
  repeat inference. −19 code lines, and — decisively — its adoption was
  **not forced**: nothing in it would have broken. It also justifies
  `keys_pressed` being readable outside an event, via `help.lua:11`'s
  arbitrary-key read that `Key.*` cannot express.
- **guess** — −14 code lines, the poll loop deleted, and the project
  stops hooking `update`.
- **maze**, *once finished* — hand-rolled edge detection over a device
  poll (`poll_tab_progression`) is exactly what the shortcut layer is
  for, and adoption also closes a Tab-into-the-prompt hole. Today it is
  a promise, not a result.

### Examples that make it look like overhead (5)

**paint** and **sapper** changed two lines each for **zero** net code,
purely to avoid a *silent* break — the worst kind, since
`compy.singleclick = f` is still accepted by the namespace and simply
never read. **valid** is one line shorter. **balloons** is
line-neutral, gained an indirection its own author flagged as worse
("3 functions juggling each other"), and needed two follow-up fixes.
**turtle** is the sharpest: **+13 lines** on a 58-line beginner example,
and the added ceremony (a self-unregistering `textinput` one-shot,
re-armed on every close) exists only to work around LÖVE's unordered
keypressed/textinput delivery — a platform fact the API surfaces to the
project rather than absorbing.

### The example whose correct answer is "do not adopt" (1, plus 2 near-misses)

**pong** — unambiguously. Continuous, level-triggered paddle movement
polled from a fixed-timestep loop is the case device polling serves and
events serve badly, and its state-keyed bindings do not fit static
shortcut registration. The API's documentation is stronger for being
able to point at it.

Near-misses worth the same paragraph: **life**'s hold-to-reset gesture
and **paint**'s draw-time cursor position have **no** API equivalent —
`keys_pressed` is keyboard-only — so device polling is not merely
tolerated there, it is required. And **sine** needs nothing at all.

### Two things the ruling should weigh that are not in the table

1. **Two examples are broken right now, on this branch, and both are
   the "primary student-facing" tier or adjacent to it.** `turtle`
   (Space toggles debug while typing into the prompt) and `maze`
   (Shift+Escape quits while typing) both regress because a seeded
   `love.keypressed` now runs ahead of, and regardless of, the widget —
   where the base gateway gave the widget the key *instead*. Each needs
   an `is_shown()` guard of 2-4 lines. Under the owner's categories
   this is currently the **"bad outcome"** cell: the API ships and two
   examples are left broken. It is cheap to fix, and it is not visible
   from the migration diffs, because neither example's migration
   touched those handlers.

2. **The API has one gap a real example still pays for.** `isrepeat` is
   delivered on `keypressed` but not on `textinput`, and the platform
   makes no promise about the two channels' order — so `keyboard` must
   keep `spendGlyph`/`GLYPH_CLAIMED`/`upRecent`/`INPUT_UP_GRACE`
   (~20 lines) after full adoption. The briefing's premise that this
   machinery duplicates a platform mechanism does not hold; nothing in
   the API replaces it. That is the one place where "adoption did not
   simplify" is the API's fault rather than the example's.

### Tally against the owner's four categories

| Category | Examples |
|---|---|
| **Positive** | keyboard, guess, tixy (correctness), repl, maze *(conditional on finishing)* |
| **Mild negative / overhead** | paint, sapper, valid, balloons |
| **Negative** | turtle (+13 lines and a live regression), pong *if adopted* |
| **Bad outcome (shipped broken)** | turtle and maze **as they stand today** |
| **Unnecessary** | sine, life |

Weighted the owner's way — `keyboard` and `maze` are the primary
student-facing features — the feature earns its keep on `keyboard`,
and `maze` is the swing vote: finished, it is the second-strongest
positive; left as it is, it is the strongest argument against.
