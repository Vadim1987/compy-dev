# session03 — track (M5c-03 → M8, autonomous sweep)

_opus-sweeper PM running track. Carryover in full = [`../session02/track.md`](../session02/track.md).
Standing authorization (human, 2026-07-10): run M5c-03 → M5c-04 → M5c-05 → M7 → M8 **autonomously**,
committing after each chunk, human reviews post-factum in git. Per-chunk scheduling gate lifted; the
design-authority gate is NOT — a genuine spec gap / corpus contradiction / irreversible design call
still stops-by-documentation (surprise-first ledger + conservative-reversible choice), Fable-5 advisor
for genuinely hard calls only._

- [project] Boot (opus-sweeper PM, session03). Re-entrance guardrail: this session's own track was
  **absent** on boot → fresh start, no interrupted work to resume. Read the mandate + authority chain +
  the frozen `spec/M5c-dispatch-chain.md` end-to-end + session02 carryover. Baseline confirmed at boot:
  `git log` shows chunks 1/2/2c landed (`b9bcc16` … `fc9d9ca`), tree clean of feature changes
  (untracked = pre-existing nested checkouts + scratch, none mine), **suite 759 / 0 / 0 / 6**.
- [project] **Chunk order (from `M5c-chunk-plan.md`):** 1 dispatch-chain ✅ · 2 widget-outputs ✅ ·
  2c corrective ✅ · **3 submit-cancel (running)** → 4 route-lifecycle → 5 example-migration → M7 → M8.
- [project] **Chunk-3 orientation (submit-cancel, Scope 3 — the heaviest remaining chunk).** Delivers
  ACs 17–26 + 39/40/41/42(b). Landscape confirmed from live code before commissioning:
  - **Tier-1 return/escape slots exist but are empty** — `projectInputController.lua:38-42`
    `framework_handlers.{keypressed,keyreleased,textinput}` populated `{}` at construction; chunk-1
    header comment L10-11 explicitly says "return/escape land here in a later chunk; the slot exists
    now and is non-overridable." **That later chunk is chunk 3.**
  - **The current submit path** is the `submit()` local in `userInputController.lua:495-511` (guarded
    by `input.oneshot`, calls `input:evaluate()` → `self.result`), plus `cancel()` L490-494. The model
    side: `evaluate()`→`handle(true)` (`userInputModel.lua:795-825`), where the **`push('userinput')`
    producer** lives (L816-824, under `if self.oneshot`).
  - **`oneshot` refs to delete** (chunk 3 owns Scope-3 `oneshot` deletion): model `.oneshot` field +
    ctor param (`userInputModel.lua:15/45-49/412/816`), `UserInputController:is_oneshot()`
    (`userInputController.lua:29-30`), the `input.oneshot` submit guard (L497), and **M6-01 rides** —
    the vestigial view snapshot `self.oneshot = ctrl.model.oneshot` + `@field` + the live
    `is_oneshot()` read (`userInputView.lua:19/28/289`). (profiler.lua / metalua `oneshot` are
    **unrelated** — different symbol; leave them.)
  - **Riding adjacents split:** **M6-01** (view oneshot snapshot removal) rides chunk 3. **M6-02**
    (`compy.before_exit` stop hook) rides **Scope-5 stop-path → chunk 4**, NOT chunk 3 (M5c spec
    L139-141: "rides the stop-path work, item 5"). Do not pull M6-02 into chunk 3.
  - **AC-39 deprecated rows already tagged** in the suite (`#deprecated`, E32): `a submit fills the
    handle and closes` (L365) + `a oneshot submit deactivates the widget` (L477). Lifecycle: red on
    AC-25 delete → `pending()` → delete once new-chain equivalent green. `a refused solicitation warns`
    (L380) rides `input_text` → **stays** (M8). AC-40 re-draft target = the L806-area on_text_entered
    row; AC-41 combo-dispatch three-channel rows already present green (L834/844/855).
  - **Chunk-3/4 deactivate seam (pinned):** chunk 3 owns the *submit-time* deactivate step (Scope 3);
    chunk 4 owns *route-level* teardown + removal of the `app_state ~= 'running'` forwarding
    (`projectInputController.lua:143-168`) + the `active_keyboard_route()` chunk-1 deferral + M6-02.
    Neither commission may silently re-scope the other. The projectInputController REVIEW markers
    (L66/70/76/97/117/141/142) are chunk-4/final-pass — chunk 3 leaves them.
