# Feature #77 — interim debt & open boundaries

_Feature-scoped ledger. Tracks debt and unresolved boundaries **surfaced during #77 implementation**
that are tied to this feature's own milestones — to be **resolved or consciously accepted before the
feature closes**, not carried into the project at large._

> Distinct from [`/doc/development/technical_debt.md`](../../../technical_debt.md), which holds only
> **persistent** debt that survives beyond #77. Anything here is expected to be swept (or formally
> accepted) by the time the new input API ships. When an entry is settled, strike it and fold the
> decision into the relevant milestone's spec/outcome.
>
> **Closure is planned, not just anticipated.** Where a debt item is committed to close at a
> milestone, that closure is **commissioned by an adjacent `MN-NN-<why>.md` spec** (never by editing
> the frozen design-time `MN.md`). Items with no committed closure are marked *accepted* or
> *anticipated*.

## Dispatch map

| Item | Kind | Disposition | Closure |
|---|---|---|---|
| F-5 | open boundary | **planned** | adjacent spec [`../design/spec/M7-01-retarget.md`](../design/spec/M7-01-retarget.md) (decided at M7) |
| G-1 | dead code | **planned** | adjacent spec [`../design/spec/M8-01-dead-text-input.md`](../design/spec/M8-01-dead-text-input.md) (M8 legacy removal) |
| G-2 | dead code | **planned** | adjacent spec [`../design/spec/M6-01-oneshot-snapshot.md`](../design/spec/M6-01-oneshot-snapshot.md) (M6 oneshot removal) |
| F-4 | spec deviation | **accepted** | none — ships as a documented deviation |
| `combo_string` alloc | perf | **anticipated** | evaluate at M5 dispatch; close only if hot |
| `gui_k` no consumer | API shape | **anticipated** | decide when `gui`'s modifier status is settled |
| design-doc path mismatch | docs | **anticipated** | opportunistic; or at feature wrap when docs unfreeze |

> The **planned** rows have a commissioned closure spec; pick them up with their milestone. The
> **anticipated** rows are deliberately *not* commissioned — they may never need action; revisit at
> the named point and decide then. (Detail blocks for the **planned** items live in their specs; the
> non-spec items are detailed below.)

---

## Open boundaries

### F-5 — `force` / `configure()` cannot re-target an active session's `result`/`eval` — **planned → M7-01**

- **Where:** `src/controller/userInputController.lua` — `force` re-applies only `text`; a fresh
  activation runs `apply_config` (eval, prompt, text, result).
- **State:** A running session's `result` sink and evaluator are fixed at `show()`. `M2.md` frames
  `force` purely in terms of content, and `M7.md`'s `configure()` no-ops non-`prompt`/highlighter/
  validator fields while active — so no surface currently re-targets `result`/`eval` mid-session.
- **Closure:** **commissioned** by [`../design/spec/M7-01-retarget.md`](../design/spec/M7-01-retarget.md) — building
  M7's `configure()` forces the decision, so M7-01 commands it be made and written down (extend the
  surface, or document a deliberate fixed-at-`show()` constraint). Strike this entry when M7-01 lands.

---

## Accepted deviations (ship as-is)

### F-4 — `compy.input` is rebuilt per project-env, not "once at namespace setup"

- **Where:** `src/controller/consoleController.lua` — `get_compy_input()` is called from
  `get_compy_namespace()`, which `prepare_project_env()` invokes per project setup, so the
  `compy.input` table is reconstructed each time a project env is prepared.
- **Disposition:** **Accept, no action.** The `show`/`hide` closures resolve
  `love.state.user_input_controller` dynamically, so they always reach the live singleton regardless
  of when the table was built. A wording deviation from M2's "created once at namespace setup", not a
  defect — the dynamic-lookup design is the better call (resilient to the singleton being
  (re)assigned). Recorded so the deviation is understood as intentional, not an oversight.
- **Sweep:** nothing to do; closes with the feature as a documented, accepted deviation.

---

## Anticipated — revisit at the named point, close only if warranted

These are **not** commissioned for closure; they may never need action. No adjacent spec until a
concrete need appears.

### `combo_string` allocates a fresh table per call

- **Where:** `src/controller/controller.lua` — `combo_string` builds a `parts` table and
  `table.concat`s it on every call.
- **State:** Inert today — nothing calls it yet. M5 puts it on the per-keystroke dispatch path
  (`compy.input.handlers[combo]`).
- **Why it stands:** Keystroke dispatch is not a per-frame hot path, so the allocation is acceptable
  for now; `rules.md` flags allocation in `update`/`draw`, not per-event helpers.
- **Revisit:** When M5 wires the consumer — *if* dispatch lands anywhere hot, switch to a reused
  buffer or a concat-free comparison. Until then, leave it.

### `gui_k` modifier pair has no real consumer

- **Where:** `src/util/key.lua` — `gui_k = { "lgui", "rgui" }` (added in M2a). It feeds only
  `mod_triples`; there is no `gui()` / `is_gui()` accessor paralleling `shift()` / `is_shift()`.
- **State:** A defined modifier pair with no behavioural reader. Could be a deliberate constraint
  ("ignore gui keys" as a held modifier) or an expansion point left open for a future `gui()`
  accessor.
- **Why it stands:** Keeping it parallels the established `*_k` pattern and M2a called for the `gui`
  pair explicitly; the asymmetry is harmless and additive.
- **Revisit:** When the input API settles whether `gui` is a first-class modifier — add the
  `gui()` / `is_gui()` accessors, or record that gui is intentionally ignored. If a milestone ends up
  forcing that decision, commission it with an adjacent spec then.

### Design-doc path mismatch: `src/controller.lua`

- **Where:** `design/spec/M1.md`, `design/roadmap.md`, and other 77 design docs reference
  `src/controller.lua`; the real path is `src/controller/controller.lua`.
- **State:** Documentation only; implementation uses the correct path. Noted in the M1 prompt and
  outcomes.
- **Why it stands:** Cosmetic; the design docs are frozen reference for the sprint.
- **Revisit:** Correct opportunistically when those docs are next edited (e.g. at feature wrap, once
  the design slices are no longer frozen).
