# M5-01 — M5 strategic split: M5a callbacks / M5b handlers sugar

_LLM(Claude Sonnet 4.6): 2026-06-24 (session 23). Approved by human?: YES (session 23)._
_Adjacent spec slice — frozen [`M5.md`](M5.md) is not edited._
_In-doc id: M5-01. Derives from design decision session 23 (`notes/talk/session23-insights.md §5`)._

> **Purpose.** Documents the approved strategic resequencing of milestone M5: split
> into M5a (non-sugar callbacks, ships next after M4) and M5b (combo handler table,
> deferred). This slice governs the commissioning of M5a and the deferral of M5b;
> frozen `M5.md` remains the canonical contract for the full M5 surface.

---

## Decision

M5 is split into two independent sub-milestones:

| Sub-milestone | Surface | Status |
|---|---|---|
| **M5a — callbacks** | `compy.input.on_key_pressed` + `compy.input.on_text_entered` exposed; `framework_handlers` tier slot established (empty; M6 populates `['return']`/`['escape']`) | Next after M4 |
| **M5b — handlers sugar** | `compy.input.handlers[combo]` dispatch table + normalisation (`__newindex`) + `__matcher` seam + return-propagate `or`-chain + `handlers[isrepeat][combo]` fresh-only keying | Deferred — after M6/M7, or concurrent |

**Rationale.** No current project uses combo handlers (new surface, not exposed pre-#77).
With `on_key_pressed(k, keys_pressed, isrepeat)` available, projects can implement their
own combo detection (`combo_string(k, keys_pressed)` builds the string). The
`handlers[combo]` table is syntactic sugar over that pattern. Deferring M5b lets M6's
submit/cancel chains and M7's extended API ship without waiting for the dispatch table;
and it decouples the keyboard forward-acceptance showcase (which exercises isrepeat
suppression, not the handlers table) from M5b's timeline.

---

## M5a — scope and contract

Derive the M5a implementor prompt from **frozen `M5.md`** with this scope exclusion:

**In scope (M5a):**
- Expose `compy.input.on_key_pressed(k, keys_pressed, isrepeat)` as a settable callback
  slot; default value = text-editing sink (`UserInputController:keypressed`).
- Expose `compy.input.on_text_entered(text, keys_pressed)` as a settable callback slot;
  default value = text-editing sink (`UserInputController:textinput`).
- Establish `framework_handlers` as an empty table reachable from
  `ProjectInputController:keypressed` (M6 inserts `['return']` and `['escape']`).
- Both slots reset to defaults on project stop (`clear_user_handlers`).
- The D-9 native-coexistence wrapper from M4 checks `compy.input.on_key_pressed` for
  the "has the project set any compy.* surface?" heuristic — this surface must be
  queryable at M4 load time. *(M4 stubs the check; M5a makes it real.)*

**Out of scope (M5b):**
- `compy.input.handlers[combo]` table and its metatable (`__newindex` normalisation,
  `__matcher` seam, `__index` noop).
- Return-propagate `or`-chain dispatch through `handlers`.
- `handlers[isrepeat][combo]` structural keying (fresh-only vs. repeat dispatch).
- `combo_string` is already live (M1) — M5a does not need to add it.

**Files (M5a):**
- `src/projectInputController.lua` — wire the two callback slots into the dispatch path
  (check `framework_handlers` tier first, then call `compy.input.on_key_pressed` /
  `compy.input.on_text_entered`).
- `src/compy_namespace.lua` (or equivalent) — expose both slots + `framework_handlers`
  table.

**Acceptance (M5a):**
- `compy.input.on_key_pressed = fn` fires for every keypressed event during project run;
  replacing it removes the text-editing sink.
- `compy.input.on_text_entered = fn` fires for every textinput event; replacing it removes
  the text-editing sink.
- Both channels fire independently for a character key (no suppression).
- `framework_handlers` table is reachable and checked first by the dispatch; populating it
  manually causes the registered entry to fire before `on_key_pressed` (M6 uses this).
- Both slots reset to defaults on project stop.

---

## M5b — scope summary (for future commissioning)

Derive the M5b implementor prompt from frozen `M5.md` with M5a excluded:

- `compy.input.handlers[combo]` table (metatable-backed `__newindex` normalisation,
  `__index` noop, `__matcher` default exact-lookup seam).
- Dispatch insert: between `framework_handlers` and `on_key_pressed` in `ProjectInputController:keypressed`.
- Return-propagate `or`-chain: handler returning truthy stops the chain (sink does not run).
- `handlers[isrepeat][combo]` structural keying: fresh presses look up `handlers[false][combo]`;
  repeat events skip to `on_key_pressed` (implementing fresh-only handler dispatch per E9 §A6).

**When to commission M5b.** After M6/M7 are green, or in parallel with M7 if the team
has capacity. M5b is never on the critical path for M8 (legacy removal and example migration
do not require the combo table — keyboard forward-acceptance can scaffold without it).

---

## Test-first step (Tier 2 — M5a)

Before implementing M5a, author acceptance tests from this slice (same rule as M5/M6/M7).
The test-first prompt may use a cheaper model. Tests go red first (callbacks not yet exposed),
then green after implementation.

Red canaries:
- `compy.input.on_key_pressed` is settable and fires.
- `compy.input.on_text_entered` is settable and fires.
- `framework_handlers` table is checked first by dispatch.

The keyboard Tier-2 forward acceptance scaffold (isrepeat suppression thread) is a natural
fit for the M5a test-first prompt — it exercises `on_key_pressed` with `isrepeat` without
needing the handlers table.

---

## Estimates impact (E11 recalc → version03)

Splitting M5 adds modest commissioning overhead (two prompts + two reviews instead of one).
Net volume change is minimal because the surface area is the same. See `estimates.md`
`version03` for the revised per-line PERT.
