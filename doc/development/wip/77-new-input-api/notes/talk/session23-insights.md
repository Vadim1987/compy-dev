# Session 23 — Architecture insights & roadmap pivots

_LLM(Claude Sonnet 4.6) + human(Hleb): 2026-06-24 (session 23). Materialized per
§D materialization rule._

---

## 1. Overlay-mechanism collapse — accepted, non-issue

**What it is.** The M4-0 characterization net's [low] finding: tixy, balloons,
turtle, editor-REPL, and maze's `is_empty` all exercise the same underlying
`make_overlay` code path. Coverage is mechanism-level, not per-example. A
regression specific to one project's overlay usage (e.g. tixy's `input_code`
call vs. balloons' `input_text` call) wouldn't necessarily be caught.

**Decision.** Accept as-is. The mechanism is what M4–M7 actually touch; per-example
divergence risk is low pre-M8. maze's `is_empty` is part of this collapsed path,
but that polling idiom is what gets deleted at M8 — it's irrelevant to forward
coverage. Not worth reworking the characterization suite over this.

---

## 2. maze API coverage — mapped to show() + after_submit

**What the human asked.** Does the planned API address maze's REPL case? Does
`on_text_entered` need to be hooked with maze's own validator/evaluator/highlighter?

**Resolution.** `on_text_entered` is NOT overridden by maze. That hook is the raw
D-6 textinput channel callback (character-by-character as the user types). Maze
uses submitted text, not character-by-character interception. The framework's
default sink (text insertion) handles typing inside the widget as-is.

**The correct mapping for maze's new API use:**

```lua
-- Activate the input widget with maze's processing:
compy.input.show({
  prompt    = "> ",
  multiline = true,
  validator  = validate_input,   -- DSL grammar: is_valid_line
  highlighter = expand_with_refs, -- col_from / col_to markup
})

-- Handle submit → evaluate → re-arm:
compy.input.after_submit = function(command)
  process_input(command)        -- enqueue_commands etc.
  compy.input.show({ prompt = "> " })  -- re-arm for next command
end
```

`show(validator, highlighter)` is already in spec.md §2 (M2) and `after_submit`
is in §3 (M6). The migration is fully addressed; maze is the canonical Tier-2
acceptance scenario for the textinput channel.

**Note.** maze is not currently in the repo ("on arrival" in M8 spec). The mapping
above is the authoritative guide when it arrives.

---

## 3. keyboard — reframed as forward Tier-2 acceptance (two threads)

**Prior state.** keyboard was charted as a Tier-1 characterization anchor, but
M4-0's keyboard debounce tests reimplemented the debounce logic test-locally,
characterizing only routing (a D-9 duplicate). The review flagged this as [med]
severity.

**Human correction (session 23).** keyboard implements a workaround for the very
features this release ships. Characterizing the workaround would fossilize it.
Ruling: **exclude keyboard from the Tier-1 characterization net entirely**.
keyboard becomes the positive Tier-2 forward acceptance showcase of the new API,
DEFERRED until M4/M5 flip green.

**keyboard's two forward acceptance threads:**

| Thread | Showcase | When it turns green |
|---|---|---|
| Once-per-press / isrepeat suppression | fresh-only handler dispatch (`handlers[isrepeat][combo]`); `on_key_pressed` sees repeats | M4 threads `isrepeat`; M5b ships `handlers` dispatch |
| Device-state cleanup on exit | `compy.before_exit` re-enables key-repeat (T3 restore) | M6-02 ships the hook |

**Impact on M4-0 tests.** The keyboard rows in `characterization_spec.lua`
(`:195-231`) are now wrong-tier artifacts. Options at M4 test-first time: strip to
routing-only rows (which are D-9 dups and can also be removed), or replace with a
`pending` scaffold for the forward Tier-2 suite. Not a blocking call for M4 run —
captured as E22.

---

## 4. maze as dual anchor — forward textinput-channel acceptance

**Track.md refinement (carried from mid-session, now confirmed).**
maze = custom REPL on the D-6 textinput channel.
keyboard = keypressed channel demo.
Together they showcase both D-6 channels.

**Backward characterization (M4–M7 guardrail):**
- Native `love.keypressed` in maze → D-9 coexistence row in char net ✔
- `is_empty` poll → overlay mechanism row in char net ✔ (acceptable collapse)
- maze Lua-command path → NOT characterized (black-box, M8 scope; this is intentional)

**Forward Tier-2 acceptance (DEFERRED to M8):**
- validate → evaluate → echo → highlight → re-arm on `on_text_entered` / `after_submit`
- generalizable WITHOUT having to boot maze (can be expressed as an integration test
  against the API surface once M6 is green)

---

## 5. M5 split — confirmed roadmap pivot

**Human confirmed.** M5 is split into two sub-milestones:

| Sub-milestone | Content | When |
|---|---|---|
| **M5a** (callbacks) | `compy.input.on_key_pressed` + `compy.input.on_text_entered` exposed as project-accessible slots; `framework_handlers` tier established (empty; M6 fills it) | Next after M4 |
| **M5b** (handlers sugar) | `compy.input.handlers[combo]` dispatch table + normalisation + `__matcher` seam + return-propagate `or`-chain + fresh-only `handlers[isrepeat][combo]` keying | Deferred — after M6 or concurrent |

**Rationale.** No current project uses combo handlers (new surface). With `keys_pressed`
exposed via `on_key_pressed`, projects can implement their own combo detection.
`handlers[combo]` is syntactic sugar. M5b can ship after M6/M7 without blocking
anything — the `framework_handlers['return']`/`['escape']` tier that M6 fills is
structural (established in M5a), not the project-facing `handlers` table.

**Frozen M5.md is not edited.** The split is expressed via adjacent spec slice
`design/spec/M5-01-split.md`. Estimates recalculated: `version03`
(≈ 77 h / ≈ 45 h — see `estimates.md`).

---

## 6. before_exit hook (M6-02) — planned, now slotted

**Prior state.** E9 §8 Layer 1 planned a project-bindable `before_exit()` hook as
"M6-family, near-term" but it was not yet in any spec slice or in `spec.md`.

**Decision (session 23).** Slot it explicitly as adjacent spec slice
`design/spec/M6-02-before-exit.md`. keyboard is the canonical consumer (T3 cleanup
— re-enable key-repeat on project exit). It folds into the M6 commissioning cycle
(ride M6 or as M6-02 adjacent, human's call at commission time).

**Spec addition needed.** `spec.md §3` event callbacks section needs `compy.before_exit`
added. Not done in this session (awaits M6 commissioning to keep atomic).

---

## 7. API demo — developer-facing sketch

**Decision.** `notes/talk/api-demo.md` authored this session: developer-facing
document showing how to consume the new API. Nice-to-have, not mandatory. Evolves
alongside M5a/M6 acceptance test authoring. Serves as the implicit spec-gap test
(if the demo looks awkward, the API needs work).

---

## 8. M4-0 tests rework — open decision (E22)

Not resolved this session. Human flagged wanting to review
`tests/input/characterization_spec.lua` and possibly provide nitpicks.
Three items outstanding:

1. keyboard debounce rows (`:195-231`) — wrong-tier, rework decision deferred
2. `input_session.lua` driver unused — M4's test-first step must consume it
3. `tests.md` not updated — should document `mock.textinput` + `keystroke opts`

Captured as **E22**. Non-blocking against M4 run, but prefer resolution before
M5a test-first authoring.
