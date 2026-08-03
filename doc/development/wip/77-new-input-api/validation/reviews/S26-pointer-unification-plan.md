# S26 — plan: unify pointer into the project route

**Status:** owner-ruled 2026-08-03, executing in session26.
**Commissioned by:** *"if (b) was invented inside this feature its not a dogma
set-in-stone… so I'd decide to unify completely."*

## Why (the findings this rests on)

All verified in code this session; details in `../../implementation/sessions/session26/track.md`.

1. **The keyboard/pointer lifecycle asymmetry is feature-invented.** At the PR
   base `3256aac`, `set_default_handlers` is called from exactly two sites —
   `suspend()` and `stop_project_run()` — and `run_project`'s success branch
   releases nothing. Both channels stayed installed until suspend or stop.
   `release_keyboard_route` arrived with `386cfe1d`, keyboard-only.
   Decision 11's "this is the established platform behaviour" is not accurate
   for that clause.
2. **The asymmetry is vacuous.** Release fires only when
   `not user_is_blocking() and not user_is_interactive()`, and
   `user_is_interactive()` is `love.state.user_input ~= nil or user_pointer`.
   At that moment the project has no pointer handlers to exempt.
3. **The chain has no error boundary.** `dispatch` contains no pcall/xpcall.
   Only handlers *seeded* from `userlove` are protected; `shortcuts[...]` and
   directly-assigned `hooks[...]` — the documented API — escape entirely.
4. **A protected raise still lets the walk continue**: measured, the widget
   received the character that crashed the project.
5. **Consume semantics are free today.** No example pointer handler returns a
   value (`life`, `sapper`, `tixy`, `paint`, `pong`), and the return is
   discarded anyway.
6. **No grammar change is needed for pointer combos** — the trigger token is
   just a string, so a button name serialises through `combo_string`
   unchanged.
7. **`compy.singleclick` predates the PR base.** The synthesis block and
   `get_compy_handler` are byte-identical at `3256aac`.
   `Controller._defaults.singleclick`/`.doubleclick` are dead vestiges of its
   `love.*` past — nothing reads them.

Owner's governing principle, recorded: no contract was formalized
pre-feature — all contracts here are de-facto behaviour canonicalized — so if
no current code notices, nothing is violated; and **not adding complexity to
the pre-feature engine is itself the win.** Feature-era limits are not an
argument for keeping feature-era limits.

## Steps

Each step is independently green, committed, and suite-stated.

1. **One canvas/error boundary at the invocation sites.** `guarded(CC, fn)` in
   `controller.lua`; wrap the three `pic:*` closures in `occupy_keyboard` and
   the pointer installs in `hook_pointer`. Strip per-participant wrapping —
   `project_handler` becomes pure adoption and stops needing `CC`. Tests
   first for the two unprotected tiers and for chain-abort-on-raise.
2. **Extend the tiers to pointer events.** `HOOK_EVENTS`, `seed_hooks`'s
   `EVENTS`, and the `shortcuts` tables gain the pointer channels; `dispatch`
   gets a nil-safe shortcuts lookup.
3. **Route pointer through PIC.** Replace the `handlers.mouse*`/`touch*`
   broadcast with a dispatch call. Delivery order changes — widget was first,
   becomes last — and gets pinned. Lifecycle made uniform in the same step
   (see step 4) so pointer is never released out from under a live project.
4. **Drop the keyboard-only release**, returning the route lifecycle to the
   pre-feature "nothing released until suspend or stop". Correct Decision 11's
   rationale in the ledger; retire the row that pins the vacuous asymmetry.
5. **`singleclick`/`doubleclick` become ordinary events.** Emitted as
   `love.handlers.singleclick(x, y)` exactly like a native LÖVE event, whose
   only job is to hand the event to the active route; the console/editor
   default skips when no project route is active. The click *synthesis*
   (timer, count, drift) stays where it is and simply emits instead of
   resolving a compy member.
6. **Retire `compy.singleclick` / `compy.doubleclick`.** Migrate the two
   consumers — `examples/paint` and `examples/sapper` — onto
   `compy.input.hooks.singleclick` / `.doubleclick`; delete the dead
   `_defaults` stubs and `get_compy_handler`'s click use; update
   `doc/input_api.md`, `internals/user_input.md`,
   `internals/examples/{paint,sapper,index}.md`, and the ledger entries that
   describe clicks as "direct compy callbacks".
7. **`src/types.lua`** — audit and upgrade for `compy.input` (it currently
   declares `singleclick`/`doubleclick` on the compy class and knows nothing
   of the input surface).

## Scope notes

- Steps 1–4 are internal: no project-visible change beyond pointer delivery
  order and the new ability to consume a pointer event.
- Steps 5–6 are a **public API change** and the only part a stakeholder reads.
  Ruled by the owner; needs a decision entry, a guide section and a migration
  row.
- This lands **before** the owner's smoke test, by their instruction.

## Delegation (owner's sub-agent policy)

- Steps 1–5 are judgment work and stay in the main session.
- **Step 7 (`types.lua`) → Sonnet**, explicit model, prompt and outcome
  materialized under `validation/prompts/` and `validation/outcomes/`.
- Step 6's doc sweep → Sonnet if it grows past a handful of files; otherwise
  inline.
