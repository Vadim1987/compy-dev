# R4/U3 — resolved callback model (owner ruling 2026-07-20 + execution plumbing)

**Owner ruling (2026-07-20, verbatim intent):** *"the compy.input.callbacks ARE the
widget's self.callbacks — literally the same table. This way a project (or other consumer of
the API) can set their own callbacks that would be called by the widget, without modifying
anything in the widget itself."* This resolves the U3 crux (how project-set submit/cancel +
output callbacks reach the widget's submit/cancel path) — see the superseded consult
`validation/prompts/R4-U3-fable-consult.md` (Opus's Q1/Q2, now answered directly by the owner
rather than via Fable).

## The model (Q1 resolved)
- **The widget owns `self.callbacks`** — one table per `UserInputController`, created at
  construction, seeded with `DEFAULT_CALLBACKS` (`after_submit`/`after_cancel` = stay-open
  no-ops; others absent). It holds ALL eight widget-invoked callbacks (outputs
  on_text_entered/on_limit_reached/validator/highlighter + lifecycle before/after
  submit/cancel).
- **`compy.input.callbacks` IS the overlay widget's own `self.callbacks` — literally the same
  table, captured once** in `get_compy_input` (`state.callbacks =
  love.state.user_input_controller.callbacks`). **OWNER RULING (2026-07-20, AskUserQuestion):
  reorder boot so the singleton is provisioned BEFORE the console** — verified nothing between
  `ConsoleController(...)` (main.lua:357) and the current singleton creation (372/381) touches
  the widget, so moving singleton creation ahead of the console is safe. This removes the
  timing fragility (the eager `get_compy_input` at CC-construction now sees a live singleton)
  and lets the capture be literal, not a per-access global lookup. Fixture mirrors: build the
  singleton before `build_console`.
- **OWNER RULING (2026-07-20): callbacks are set by DIRECT leaf-write** (`compy.input.callbacks
  .X = fn`), uniform with `shortcuts.keypressed[combo]=fn` / `hooks.event=fn` — the ratified
  delta-spec shape (AC9), not routed through `configure()`. `configure()` stays for live
  prompt/text/cursor reconfigure only. (Direct-vs-configure was flagged as un-analyzed; ruled
  in favour of the uniform leaf-write per the "more predictable, not more elaborate" frame.)
- Project writes `compy.input.callbacks.X = fn` → proxy → the overlay widget's own table
  (literally, per the ruling). The widget reads its own `self.callbacks.X`. No copy, no
  apply_config bridging for these — one table.
- **Console/editor** are trusted host code: they set their OWN widget's `self.callbacks.X`
  directly (§6: `console_widget.callbacks.on_limit_reached = fn`). Consistent shape with the
  overlay; no compy.input involved for them.
- **Sticky-output delivery is preserved for free (Q1c):** the widget's callbacks table
  persists across hide/show inherently (only teardown clears it), so the old
  merge_output_keys / OUTPUT_KEYS sticky machinery for callbacks becomes redundant and is
  removed. `show{on_text_entered=fn}` config → `apply_config` writes into `self.callbacks`.
  `highlighter` keeps its evaluator bridge (its consumer is the evaluator at render; synced
  from `self.callbacks.highlighter` at show).
- **Teardown (AC10):** `reset_compy_input` clears + re-seeds `DEFAULT_CALLBACKS` on the
  overlay widget's callbacks (via the proxy) — a nil'd `after_cancel` must not silently mean
  "stays open forever" for the next project.

## Overlay scoping of submit/cancel (Q2 resolved — Opus decision)
Console/editor call their own `IC:keypressed` DIRECTLY (verified: ConsoleController →
`input:keypressed` + own `evaluate_input`; editor → own `submit()` + conditional
`input:keypressed`). The old submit/cancel lived at the ROUTE's tier-1, never touching them.
`Widget:keypressed` will handle `return`/`escape` → `_submit_default`/`_cancel_default`
**gated on `self:_is_overlay()`** (`self == love.state.user_input_controller`) — reusing the
existing overlay-identity predicate already in `_is_hidden_overlay`/`is_shown` (adds NO new
leak — that global reference already exists and cleaning it is an out-of-scope still-open
REVIEW; adds no constructor flag). Console/editor widgets are never the published overlay, so
they never trigger submit/cancel-default — their behavior is provably unchanged. `shift+return`
falls through to the editing branch (line_feed); `ctrl+escape` is not a cancel.

## Blast radius (U3)
- `projectInputController.lua`: free-function `dispatch`; delete framework_handlers/
  install_tier1/framework_submit/framework_cancel/shown_widget/run_hook/_generic_callback/
  _sink/log_branch; thin `_dispatch`.
- `userInputController.lua`: `self.callbacks` + DEFAULT_CALLBACKS at new(); `_is_overlay`;
  `_submit_default`/`_cancel_default`/`run_callback`; keypressed return/escape gate; deliver/
  gate/emit_limit read self.callbacks; apply_config writes self.callbacks (+ highlighter→ev);
  remove flat output fields.
- `consoleController.lua`: callbacks leaf-proxy → live overlay widget; remove
  merge_output_keys/OUTPUT_KEYS sticky-for-callbacks; §6 console on_limit_reached patch,
  dropping the `local limit = input:keypressed(k)` return-channel branch.
- `controller.lua`: reset_compy_input re-seeds DEFAULT_CALLBACKS; reset_widget_outputs shrinks.
- Tests: rewrite the OLD-behavior assertions in input_widgets_callbacks_spec (auto-close,
  non-shadowable) to the new ACs; add AC1-7 + AC10 to input_redesign_ac_spec.

Tests-first per house rule (write failing AC test → implement). If a genuine spec
contradiction surfaces mid-implementation, consult Fable then (owner-sanctioned).
