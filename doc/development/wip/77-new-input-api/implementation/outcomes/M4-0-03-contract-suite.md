# Outcome — M4-0-03: contract-shaped input suite

_Executor: Claude Opus 4.8 — 2026-06-29._

The input suite is re-authored top-down from the contract record
into the four buckets. Test-only slice; no `src/` change.

## Commit(s)

| Hash | Subject |
|---|---|
| _(pending human approval)_ | `test: re-author input suite from the contract record` |

## Files changed (all under `tests/`)

- `tests/input/input_routing_spec.lua` — **re-authored** as the
  behavioural-contract suite (Buckets A–D + forward stubs), one
  file, organised by orthogonal behaviour with bucket labels.
- `tests/helpers/input_fixture.lua` — **new.** The whole MVC/gfx/
  font standup + real gate + singleton widget + click/update wiring
  + driver. A test stands up the gate and a route in ~1 line.
- `tests/helpers/input_session.lua` — **thickened** to one emitter
  per gateway entry (press/repeat_press/release/type/mouse*/touch*)
  plus the live `handlers` table for combo drivers.
- `tests/input/singleton_spec.lua` — **removed** (re-homed).
- `tests/input/overlay_spec.lua` — **removed** (re-homed).
- `tests/helpers/editor_session.lua`, `tests/mock.lua` — unchanged
  (consumed as-is).

## Bucket-by-bucket disposition

### Bucket A — PRESERVE (P1–P11), green now

Driven through the public entry / `love.handlers.*`, asserting
observable outcomes (text/selection/state changed) or receipt at a
public framework seam.

- **P1 keypressed EXCLUSIVE (§3.1)** — `backspace` deletes a char
  from the route when no widget is up; with a widget up the char
  leaves the widget at `x` and the console **unchanged** (one-and-
  only-one receipt, fully observable, no spy).
- **P2 textinput EXCLUSIVE (§3.2)** — char appends to the route
  (console + an editor-route variant through a real editor buffer);
  with a widget up it appends to the widget and the console stays
  empty.
- **P3 keyreleased EXCLUSIVE (§3.3)** — release carries no text
  mutation, so exclusivity is observed at the route's public
  framework slot (`love.keyreleased`): received with no widget,
  bypassed under a widget.
- **P6 held-key lifecycle (§4.1)** — the pressed key is in
  `keys_pressed` when the route slot runs (added before dispatch);
  the released key is already gone when the release slot runs;
  l/r names stay raw (no folded `ctrl`).
- **P7 shortcuts non-consuming (§4.3)** — Ctrl+Pause fires its
  effect (`app_state → snapshot`) **and** the key still reaches the
  route; play-mode narrows the active set (restart/profile live,
  quit not) on an isolated save/restore'd play-mode gate.
- **P4 mouse BOTH (§3.5)** — press+release lands an observable
  selection on the route, and on **both** widget and route when a
  widget is up. _(supersession: none.)_
- **P5 touch BOTH (§3.6)** — **carried `pending`** — surfaced gap
  (below).
- **P11 click detection (§4.7)** — single click confirmed only
  after the debounce window; suppressed on pointer drift; double
  click invokes the project handler. Asserted against the project-
  defined `compy.singleclick`/`doubleclick`; constants not asserted.
- **P8 slot restoration (§4.4)** — after `stop_project_run` the
  keypressed slot is the default again and the console owns input
  (observable backspace). _(tag: form renamed to console-named at
  m4 / I2; end state identical.)_
- **P9 legacy solicitation (§4.5)** — one Enter fills the poll
  handle (`ref() == '42'`) and emits the close (`userinput`)
  event; a guarded refusal warns. _(tag: retired at m8.)_
- **P10 widget activation/reset (§4.6)** — driven through
  `compy.input.show/hide`: no-force re-show warns + no-ops;
  force reapplies the text subset; force without text keeps
  content; fresh-no-text starts empty; hide deactivates; oneshot
  submit deactivates. _(tag: the no-cancel-chain facts flip at m6.)_
- Editor block-nav at-limit row kept **unchanged** (editor_session).

### Bucket B — IMPLEMENT (forward, `pending`)

Seven `pending` rows with greppable `DEFERRED (0.1.0-mN)` markers
at the greening milestone (m4: I1–I4; m5a: I5; m5: I6; m5b: I7);
each body documents the target assertion on the **public API**
(`ProjectInputController` receipt, `compy.input.on_key_pressed`,
`handlers[combo]`). Per D-α the isrepeat rows assert the uniform
`(k, keys_pressed, isrepeat)` triple, the **sink included**. I8
(combo serialisation format) is noted as already green in
`keys_pressed_spec`, load-bearing only when its dispatch lands.

### Bucket C — MECHANISM-GUARD (labelled)

`describe('mechanism / NFR guards — not behaviour')`: MG1 singleton
controller identity across show/hide; MG2 the backing model is not
reallocated per session.

### Bucket D — CHARACTERIZE-PROVISIONAL (factual)

`describe('provisional — expected to change, no mandate')`: CP1
inspect (console owns input, widget bypassed, input not dead) and
CP2 wheel (no gate entry → widget bypassed by omission; route slot
present, no-op by default). Each asserts only present behaviour;
the intended future shapes are comments, never assertions.

### Later forward stub

One `pending` naming the not-yet-authored m6/m7 contracts
(submit/cancel chains, `on_limit_reached`, `configure`/`set_text`/
cursor, force-vs-`configure`), pointing at the §5 scope note.

## Mechanism → outcome rewrites

- The `record_calls(obj, name)` method-name spy is **gone**.
  Keyboard/text rows now assert `get_text()` deltas on the real
  console/editor/widget; exclusivity is "target changed **and**
  the other route unchanged" — no spy at all.
- `singleton_spec`'s show/hide/force/no-op/warn rows → P10 through
  `compy.input.show/hide`, asserted on the widget's observable
  content (`get_text`/`is_empty`) + the `Log.warn` contract.
- The `love.state.user_input` / `.C` internals assertions that
  masqueraded as behaviour are **dropped**; identity survives only
  in Bucket C, labelled.
- `overlay_spec`'s reprompt-empty rows → P10 fresh/oneshot rows;
  the drawable-handle (`user_input.V`) mechanism row → dropped
  (draw wiring is not an input-routing contract).

## Verification

- `busted tests`: **716 successes / 0 failures / 0 errors /
  9 pending** (9 = P5 touch + 7 Bucket B + 1 later-forward stub).
- Teeth (perturb → red → restore, working tree only, never
  committed):

  | Row | Perturbation (controller.lua) | Result |
  |---|---|---|
  | P2 EXCLUSIVE | drop `user_input.C:textinput(t)` | `…reaches only the widget` **red** (widget empty) |
  | P4 BOTH | drop `user_input.C:mousepressed(…)` | `…widget and the route both` **red** (widget no selection) |

  `git checkout src/controller/controller.lua` after each;
  `git diff --stat src/` clean before the final green run.

## Surfaced gaps

- **P5 touch BOTH is not black-box expressible today.** Both the
  widget and the route touch handlers are no-op `TODO` stubs
  (`userInputController`/`consoleController`), so touch delivery
  changes no observable state anywhere, and a delivery probe would
  be the method-name spy Bucket A forbids. Carried `pending` with
  that reason; greens when a touch consumer lands. _(The spec's
  own §3.6 frames touch as delivery-only with no-op handlers, so
  this is consistent with the record, not a contradiction of it.)_
- **P4 widget-half observability** required a deliberate test
  instrument: the production singleton disables selection (its
  pointer handler is a no-op, §3.6), so a selection-enabled widget
  instance is used to witness delivery via an observable selection.
  Noted so a reader does not mistake it for production config.
- No `§3`/`§4` stable-now row was found unobservable beyond P5, and
  no contract was contradicted by code. No findings for the
  orchestrator on the contract record itself.
