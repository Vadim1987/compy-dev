# OPEN ISSUE (R4, unresolved) — UIC reads `app_state` to scope submit/cancel

**Status: OPEN — deferred to a fresh session for separate analysis (owner, 2026-07-20).
Phase R is NOT closed pending this.** Logged so the R4 gate is not declared clean while a
known architectural concern stands.

## Sharpened concern (owner, 2026-07-20 session18) — see `../notes/S18-owner-concern-uic-context-behaviour.md`
The state read is a **symptom**; the real smell is the **context-dependent behaviour fork inside
UIC**, which may block *conceptual* unification of input management and future editor adoption of
the new API (a feature requirement: editor migration not demanded, but must be *made possible*).
Any option is judged on "does UIC become concept-uniform?", not "is the global read gone?" — R must
not close by rubber-stamping the fork as debt.

## The concern (owner, 2026-07-20)
`UserInputController:keypressed` decides *its own behaviour* by reading the global
`love.state.app_state`. The owner's read: *"a clear abstraction leak which mixes concerns —
UIC altering its behavior depending on the context it runs. Should probably be a feature flag
toggled by the parent… or the whole code belongs in the wrong place."* It is the same class
of leak we deliberately removed from `is_shown()` in U3 (which now reads a strictly-internal
`self.shown`), reappearing on the submit/cancel path.

## Exactly where (current tree)
- `src/controller/userInputController.lua:725` — `if love.state.app_state == 'editor' then …
  else … end`. **This branch is PRE-EXISTING** (before #77): it selects editor-vs-normal
  editing-key *order* + the `modify` block. It is already flagged by a standing REVIEW at
  `userInputController.lua:724` ("UIC should not be aware if application is in editor/non-editor
  mode — it should be editor that configures it accordingly").
- `src/controller/userInputController.lua:752`/`:754` — `self:_submit_default(...)` /
  `self:_cancel_default(...)`, sitting in the **`else` (non-editor) side** of that branch.
  **This placement is NEW — introduced in R4/U3** (commit `f1050d8`) to scope submit/cancel
  away from the editor widget. It is an **unratified rule** ("submit/cancel only outside
  editor mode") not present in delta-design/delta-spec, and it reaches global state to do it.
- `src/controller/userInputController.lua:450`/`:467` — `_submit_default` / `_cancel_default`
  (the behaviour being scoped).

## Why it exists (the constraint that forced it)
The editor's widget genuinely must NOT run the widget submit/cancel default:
`editorController.lua:716` `load()` handles plain Escape by `load_selection()` (loads a document
block *into* the input widget) and does **not** `block_input()`, so Escape falls through
(`:803-804` `if passthrough then input:keypressed(k)`) to the widget. If the widget then ran
`_cancel_default`, `model:cancel()` would wipe the just-loaded selection. Editor also has
Enter/Escape in three modes (`_normal_mode_keys:507`, `_reorg_mode_keys:440`,
`_search_mode_keys:485`). So *some* scoping is required as long as console/editor share the
`UserInputController` class and their migration is deferred (Decision 1). U3 achieved it the
cheap-but-leaky way (read `app_state`); the owner wants it reconsidered.

## Blast radius — NOTHING is functionally broken today
Suite green **827/0/0/4**; all three widgets behave correctly at runtime:
- **Overlay** (`app_state=='running'` → else branch): submit/cancel works as designed. ✓
- **Console** (else branch): runs `_submit_default` on Enter = **harmless no-op** (no submit
  callbacks set; its own `evaluate_input` does the work); `_cancel_default` on Escape clears
  the console line = **matches prior behaviour**. ✓
- **Editor** (`editor` branch): submit/cancel-default skipped; editor keeps its own handling. ✓

This is **latent design debt, not a live defect.** The single concrete smell is cosmetic:
the console widget runs a no-op `_submit_default` on every Enter. Risk is latent — if
`app_state` semantics change, a new mode is added, or the overlay is ever shown during editor
mode (it is not today), the coupling could surprise.

## Options on the table (for the fresh session to weigh with the owner)
- **(A) Full uniform, migrate editor:** submit/cancel becomes uniform widget code (no
  `app_state` read); the editor's controller consumes its own Enter/Escape across all three
  modes so its widget never reaches submit/cancel. Reaches the clean end-state but does
  **deferred editor-migration work now** — more editor surface, more regression risk.
- **(B) Internal per-widget flag:** uniform widget code gated on an internal flag (default ON;
  editor's two widgets opt out at construction, mirroring the `always_shown()` pattern at
  `userInputController.lua:495` / `editorController.lua:12,16`). Removes the global read;
  editor untouched behaviourally; deferred migration respected. Adds one honest flag
  ("editor's widgets defer lifecycle keys").
- **(C) Leave + document:** keep the `app_state` scoping, carry it as deferred-migration
  tech-debt adjacent to the standing REVIEW at `:724`. No code change.
- **The owner's own framing** suggests a fourth angle: maybe the submit/cancel (and the
  pre-existing editing-order fork) *don't belong in `UserInputController` at all* — the parent
  (route/controller) should configure the widget, or the behaviour should move out. Worth
  evaluating alongside A/B/C rather than treating the three as exhaustive.

## For the next session
Re-evaluate R4's outcomes and project status with fresh eyes, analyze THIS issue
specifically, decide A/B/C/other **with the owner**, then re-assess whether Phase R can close.
The R4 code (U1–U4) is committed and green; this is the one known-open thread plus two
non-blocking flags (balloons example — fixed in its own nested repo, owner to commit there;
and the cosmetic console no-op above).
