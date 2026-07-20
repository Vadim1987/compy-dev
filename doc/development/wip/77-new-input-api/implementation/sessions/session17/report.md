# session17 — report

**Task:** Phase R4/R5 execution — implement the ratified input-API redesign (delta-design +
delta-spec) tests-first, unit-sized, suite-green per unit. Cognitive-heavy: the design was
refined live by the owner mid-execution (three steers), so this was execution *and* judgment.

## Outcome — R4/R5 implemented; suite green; **Phase R NOT closed**
Five commits (`e856760` U1 → `55135b4`), suite **827 / 0 / 0 / 4** throughout (815 baseline +
12 acceptance-criteria anchors, AC1–10, in `tests/input/input_redesign_ac_spec.lua`):

- **U1 (`e856760`)** — `build_widget_api` factory (obligation 6b). Pure refactor.
- **U2 (`41cbe87`)** — `compy.input` reshaped into frozen `shortcuts`/`hooks`/`callbacks`;
  hooks unified + seeded once (no resurrection); D7 guard replaces the 11-name allowlist.
  AC8, AC9.
- **U3 (`f1050d8`)** — the behavioral core: the project route is a **dumb** 3-consumer walk
  (`shortcuts → hooks → widget`, free-function `dispatch`, obligation 6a); tier-1 and all its
  helpers deleted; submit/cancel are the **widget's own** business via callbacks (stays-open
  default, `before_cancel` veto, Enter/Escape shadowable); `is_shown()` is a **strictly
  internal flag** (no `love.state` reach); console history moves to `on_limit_reached`
  (return-channel retired). AC1–7, AC10.
- **docs (`3c7d6ef`)** — R4 process artifacts.
- **U4 (`6157222`) + `55135b4`** — vocabulary sweep (retired `sink`/`singleton`/`tier`/
  `framework handler`/`generic callback`/`proxy` from src comments and the persistent docs;
  `native` disambiguated), example migration (`guess`/`tixy`/`valid`/`repl`), persistent docs
  resynced (`input_api.md`, `internals/user_input.md`, `technical_debt/input.md`),
  `main.lua`'s Console/Editor-singleton REVIEW dispositioned.

**Three owner design rulings, incorporated (materialized in
`validation/reviews/R4-U3-callback-model.md`):** (1) `compy.input.callbacks` IS the overlay
widget's own `self.callbacks` — literally one table (which forced a boot reorder so the
singleton exists before the console); (2) callbacks are set by direct leaf-write, not via
`configure()`; (3) the route is dumb and submit/cancel + shown-ness are the widget's own
concern with no global reach.

## Why R is NOT closed — one open architectural issue
`UserInputController:keypressed` reads `love.state.app_state == 'editor'` to scope
submit/cancel (my U3 placed it in that pre-existing branch). The owner flagged it as an
abstraction leak (UIC changing behavior by global context) and wants it analyzed separately.
**Nothing is functionally broken** — suite green, all three widgets (overlay/console/editor)
behave correctly; the only smell is the console widget running a harmless no-op
`_submit_default` on Enter. Full write-up, exact line numbers, blast radius, and options
(A uniform+editor-migrate / B internal flag / C leave+document / or move-it-out-of-UIC):
[`../../../validation/reviews/R4-open-issue-uic-mode-leak.md`](../../../validation/reviews/R4-open-issue-uic-mode-leak.md).

## Non-obvious points
- **Delegation:** two Sonnet workers used (`model: sonnet` explicit) — REVIEW-remarks
  reconnaissance and the U2 test rename sweep; a third (U4 sweep+docs) after a session-limit
  reset. A Fable consult was spawned for the U3 callback-plumbing crux but the **owner
  rejected the spawn and answered directly.** Owner feedback mid-session: I under-delegated U3
  (kept the whole behavioral unit in-session) — justified while the design was shifting, but
  the post-settling execution could have gone to Sonnet. Carried forward.
- **Execution decomposition** deviated from plan.md's literal 8-step order (owner-approved):
  green-to-green units, because tier-1 removal and submit/cancel-flip are one atomic behavioral
  change and the surface reshape must precede the new dispatch's reads. See
  `validation/notes/R4-execution-decomposition.md`.
- **`R4-U3-callback-model.md` was corrected post-hoc:** its first draft described an
  `_is_overlay()` gate that the owner's later "dumb route / no global reach" steer superseded;
  the shipped code uses the `app_state` branch instead (which is exactly the open issue above).
  The U4 worker caught the drift and documented actual behavior per code-wins-on-facts.
- **Two non-blocking flags:** `balloons` (untracked nested-repo example) was migrated in its
  own working tree (owner to commit there); the cosmetic console no-op noted above.

## Verification of record
Suite green after every committed unit (827/0/0/4). Deleted symbols grep-verified zero;
retired prose zero in the input domain; LSP diagnostics clean on all touched files (a transient
LSP-index flakiness during U4 was backstopped by grep, per charter). Ten ACs pass as tests.
