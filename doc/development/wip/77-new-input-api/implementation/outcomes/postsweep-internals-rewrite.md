---
description: Outcome ledger for the post-sweep rewrite of
  `internals/user_input.md` to the landed input system — every
  place the code contradicted `input-contracts.md`, the change
  summary, and the hygiene-sweep confirmations.
status: done
audience: owner
---
# Post-sweep — `internals/user_input.md` rewrite (outcome)

_Cold implementor pass (Sonnet 5, `agents/dev.md` charter), 2026-07-13. Commission:
`implementation/prompts/postsweep-internals-rewrite.md`._

## What will surprise the reviewer

Every mechanism sentence in the rewritten doc was checked against `src/` before being written.
The following are the places the code disagreed with `input-contracts.md` / the pre-sweep doc,
in descending order of how much they change the reader's mental model:

1. **`ProjectInputController` does not forward events to the console in `'project_open'`.** The
   pre-sweep doc claimed "`ProjectInputController` forwards events to the console default
   handlers" once a project stops blocking. This is false today: `ConsoleController:run_project`
   calls `Controller.release_keyboard_route(CC)` (`controller.lua:730-735`,
   `consoleController.lua:256`/`:261`), which deactivates the project route and **reinstalls the
   console's own `love.keypressed`/`keyreleased`/`textinput`** — a slot reassignment, not
   internal forwarding. `ProjectInputController:keypressed`'s own doc comment
   (`projectInputController.lua:205-213`) is explicit that the old per-event
   `app_state ~= 'running'` forward this description was based on is gone, precisely because the
   slots are now actually restored at the transition. This is the single biggest correction in
   the doc.

2. **`Controller.active_keyboard_route()` does not exist.** The pre-sweep doc cited this function
   as reporting the slot occupant on project stop. Grepped repo-wide: zero matches. What exists
   is a plain field, `Controller._keyboard_route`, set at two call sites (`controller.lua:209`,
   `:434`) and read nowhere — inert bookkeeping, not a queryable API. Replaced the claim with an
   accurate description of the field.

3. **FR-7 "limit reached" is not lost at the project level — it's a live widget output, not a
   return-value concern at all.** The pre-sweep doc's FR-7 trace said the project route "has no
   `on_limit_reached` callback to hand it to yet." Landed: `on_limit_reached` fires directly from
   inside the sink (`emit_limit`, `userInputController.lua:448-449`, called from `vertical()`/
   `horizontal()`) whenever a project sets it via `show()`/`configure()`/direct field assignment —
   entirely independent of the chain's return-value plumbing (which is real, but is a separate,
   console-only mechanism used for history navigation). The "signal genuinely lost" framing no
   longer applies; rewrote as two independent notification paths that happen to share one
   boundary check.

4. **FR-1 "initial cursor position" is implemented — at the controller layer, not the model's.**
   The pre-sweep doc called this "a confirmed gap, not a stub to extend." Landed:
   `UserInputController:show(cfg)`'s fresh-activation path (`open_fresh`,
   `userInputController.lua:252-272`) applies `cfg.cursor = {line, col}` via `set_cursor_pos`
   right after `text`. Separately, `compy.input.get_cursor()`/`set_cursor()`/`set_text()`
   (`consoleController.lua:487-510`) now give the project route the programmatic cursor access
   the pre-sweep doc said it had "no way to yet." Also caught in passing: the doc cited
   `UserInputModel.new(cfg, eval, oneshot, custom_label)` — the actual signature is
   `(cfg, eval, custom_label)`, no `oneshot` parameter at all.

5. **`isrepeat` threading is real but not uniform** — worth stating precisely rather than as a
   blanket "now threaded through." It reaches every tier of the project route's chain and the
   widget sink whenever a widget is shown (via `forward_keypressed`), but the console-route
   default handler's fallback call (`CC:keypressed(k)`, and from there
   `EditorController:keypressed(k)`) still drops it — console/editor's own mode dispatch never
   sees `isrepeat`. The old doc's "stripped at the very first hop" framing was simply wrong for
   the current gateway (`controller.lua:797`, which keeps all three LÖVE arguments); the new
   framing is "threaded, but not to every consumer."

6. **The `oneshot`/`push('userinput')` mechanism is fully gone, and one vestige is dead code.**
   Confirmed via grep: zero `oneshot` constructor parameters, zero `love.event.push('userinput')`
   calls anywhere in `src/`. `UserInputController:submit()` now runs the whole validate → deliver
   → hide sequence synchronously within one keypress, off the project route's tier-1 `return`
   entry. One artifact remains: `love.handlers.userinput` (`controller.lua:976-981`) is still
   installed and would clear `love.state.user_input` if that LÖVE event were ever dispatched, but
   nothing pushes it any more — this handler is now unreachable. Noted in the doc as a vestige,
   not fixed (report-don't-fix; see "Code bug" below).

7. **Citation drift.** Several `file:line` citations carried in the pre-sweep doc had shifted by
   tens of lines since they were written (the file grew under later milestones) and needed
   re-verification, not just carrying forward: `userInputController.lua` `:387-393` → `:568-574`
   (`newline()`), `:456-479` → `:633-653` (the editor-mode `cancel()` fork), `:481-482` → `:656`
   (`return ret`); `consoleController.lua` `:1058` → `:1171` (console's `local limit =`),
   `:1090-1093` → `:1203-1206` (`ConsoleController:keyreleased`). All citations in the rewritten
   doc were checked against the current file, not copied from the source material.

## Code bug spotted while fact-checking (report, not fixed)

`love.handlers.userinput` (`controller.lua:976-981`) is dead code: it exists to null
`love.state.user_input` when a queued `'userinput'` LÖVE event arrives, but the only producer of
that event (`love.event.push('userinput')`, gated by the now-removed `oneshot` flag) was deleted
along with `oneshot`. The handler can never fire. Harmless — it's a no-op path, not a live bug —
but it's dead weight worth a cleanup pass whenever `controller.lua` is next touched. Not fixed
here per the report-don't-fix charter (`agents/development.md`); noted in the rewritten doc
("Submit and cancel" section) as a vestige so a future reader who greps `userinput` isn't
puzzled by it.

Separately (not a bug, just an observation): `Controller._keyboard_route` (item 2 above) is
written at two sites and read at none — dead-ish bookkeeping rather than a defect, since nothing
depends on it being correct. Noted inline in the doc rather than flagged as a bug.

## Change summary

- **Rewrote for the landed system** (oneshot/`push('userinput')` fully removed, `isrepeat`
  threading, the `'running'`↔`'project_open'` slot-reinstallation boundary, `inspect` mode's
  mechanism trace, `Controller.keys_pressed`/`combo_string`/held-key proxy now having a real
  consumer, the FR-1/FR-7 gaps closing, the four-tier chain's submit/cancel tier-1 hooks) in:
  Data flow, Multiline input, Cursor manipulation, the global-shortcuts paragraph, the
  route-restoration paragraph, the `inspect` paragraph, Key state, Console-specific keys,
  Editor-specific keys, UserInputController keypressed (shared), the entire "user_input Overlay"
  section (Singleton lifecycle / Dispatch while active / the old `'userinput'` event section
  replaced by "Submit and cancel — the framework tier-1 chains" / `compy.input` namespace).
- **Absorbed inline** (from `input-contracts.md` §5.4, §5.8, §6.6, verified against code, since
  `wip/77` is going away): the `inspect`-mode mechanism trace (§5.4); a new "Search — a third
  widget instance" subsection describing the `SearchController`/`Search` MVC triad that the whole
  design corpus never names (§5.8); the four-incompatible-`reset()` summary folded into "Cursor
  manipulation" (§6.6).
- **Noted the 7 didn't-land gaps inline**, each in its natural section rather than a bolted-on
  list: `compy.keys_pressed` not exposed (Key state); `eval`/`result` config keys outside the
  frozen spec table (`show(config)` subsection); combo-tier repeat-fires-on-every-repeat, unruled
  (Key state); `multiline` not a config key (Multiline input); no project-facing
  `is_active()`/`is_shown()` (`compy.input` namespace); held-key proxy index-only on LuaJIT (Key
  state); `show{}` silently dropping unknown/field-write-only keys vs. `set_cursor`/`set_text`
  warning (`show(config)` subsection).
- **Added** a `projectInputController.lua` row to the Key Files table (previously absent despite
  being central to the four-tier chain) plus a short "who uses what" paragraph.
- **Left intact**: the Mouse Input sections in full (no `>` or wip content was inside them); the
  already-correct "Key release" and "FR-6" paragraphs (verified against code, unchanged in
  substance — only stale citations and dangling "the review below" phrasing fixed nearby).
- **Removed**: two dangling "the review below asked for" references (the review text itself had
  already been stripped as an author-question block; the phrasing was orphaned) — reworded to
  plain descriptive prose.

## Hygiene confirmations

```
$ grep -c "wip/77" doc/development/internals/user_input.md
0
$ grep -c "^> " doc/development/internals/user_input.md
0
```

Both zero, as required. `wip/77-new-input-api` itself was not touched (no source files edited,
not deleted); only `internals/user_input.md` was edited plus this ledger.
