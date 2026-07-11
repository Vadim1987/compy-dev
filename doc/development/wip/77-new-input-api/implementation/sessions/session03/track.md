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
- [project] **Chunk 3 (submit-cancel) — LANDED + Opus-APPROVED (autonomous).** Commission `126ad09`;
  Sonnet implementor `2a7a26b`(red tests)/`9bb6d29`(feat+oneshot deletion)/`adaf701`(outcome); Opus
  reviewer APPROVE `reviews/M5c-03.md` (`88dc783`). **Suite 759 → 771 / 0 / 0 / 5.** All in-scope ACs
  (17–26/39/42(b)/43) met; `oneshot` deleted end-to-end + M6-01 view snapshot; `push('userinput')`
  producer dissolved, `handlers.userinput` consumer survives (E32 split honored); no chunk-4 over-reach
  (forwarding intact, REVIEW markers preserved). Reviewer independently verified the two implementor-
  flagged substitutions (`keep_history()→true`, view identity-check) behaviour-safe.
- [project] **Documented deviations carried for the architect (from the chunk-3 ledger — the human
  reviews post-factum):** (1) submit/cancel **hooks live on the route (`compy_input`), field-only, no
  `show()` config-key sugar** — taken literally from spec §5 scope note; reads as a second settability
  shape vs the four widget outputs (AC-16). (2) The sink-level `cancel()` escape-clear local was **kept**
  for console/editor (routes with no tier-1 layer yet — console/editor migration is out-of-slice
  follow-on); the project widget's framework tier-1 escape intercepts first, so no collision. Both are
  conservative/reversible and flagged surprise-first, not silent rulings.
- [project] **INFRA DRIFT — lua-lsp MCP server is DOWN this session** (persistent broken-pipe on every
  `definition`/`references`/`diagnostics` call; PM re-confirmed directly post-chunk-3). Both sub-agents
  fell back to the rules' own sanctioned backstop: `grep -rn` with comment-exclusion cross-checked
  against every construction/call site. Completeness-critical refactor sweeps this session lean on grep,
  not the AST — acceptable per `agents/rules.md` LSP-usage guidance ("grep as a backstop"), but worth
  the human knowing. **Instruct remaining sub-agents to expect LSP-down and use the grep backstop.**
- [project] **Chunk 4 (route-lifecycle, Scope 5) — LANDED + Opus-reviewed + corrective
  applied (autonomous).** Commission `eed9f5a`; Sonnet implementor `072fe6d`(red rows)/
  `386cfe1`(feat: route connect/disconnect + teardown + `compy.before_exit`)/`74ab55a`
  (outcome). Opus reviewer **corrective-take** `fbbef86` (`reviews/M5c-04.md`) — one
  confirmed AC-29 gap: `reset_widget_outputs` reset 3/4 widget outputs but not the
  `highlighter`, which mirrors onto the module-global `InputEvalText` evaluator and so
  survived stop → leaked into the next project's widget (empirically proven by the
  reviewer). Corrective `d3c2adb` (Sonnet, test-first: row went 778/1 red → green):
  nil the mirrored `ui.model.evaluator.highlighter` in `reset_widget_outputs` + 4th
  assertion on the teardown row. **Suite 771 → 779 / 0 / 0 / 5.** AC-27/28/29/30 +
  M6-02 all met; the M4 ruling-1 `app_state ~= 'running'` forwarding removed (slots
  restored at the transition via new `Controller.release_keyboard_route`); pointer
  slots left hooked (AC-28); `active_keyboard_route` dropped (C23), suite row retargeted
  to AC-29 teardown; `compy.before_exit` on the `compy` namespace, fires once before
  cleanup, reset on stop. **Scope fence HELD** — route-equivalence REVIEW markers
  (`controller.lua` occupy/PIC/wrap-vs-assign) left untouched; only the L213-214
  `_defaults`/TODO dissolved *by* the forwarding removal. **Impact flagged for human:**
  untracked `src/tests/autotest.lua:133/212` still calls the dropped
  `active_keyboard_route()` — human-owned, must update.
- [project] **INFRA RESTORED — lua-lsp MCP server is BACK UP** (commit `08a3d93`
  `fix MCP-lsp-lua`; the chunk-4 reviewer + corrective implementor both used it live:
  `references` on `reset_widget_outputs` → exactly one caller, clean `diagnostics`).
  Supersedes the session's earlier lua-lsp-DOWN note. **All successor sub-agents: USE
  the LSP for correctness** (definition/references/hover/diagnostics), `sleep 1` after
  any `.lua` edit before MCP calls (re-index), grep as completeness backstop — per the
  global CLAUDE.md MCP↔LSP guidance.
- [project] **Carried tech debt (report-don't-fix, from chunk-3 ledger — none blocking):**
  (a) `multiline` config field accepted but **not gated** anywhere — Shift+Enter inserts a newline
  unconditionally (pre-existing; may home in M7 or a config slice). (b) `emit_limit`'s `dir` typed
  `VerticalDir` but called with `'left'`/`'right'` (chunk-2 boundary work — LSP hint). (c) tests-vs-prod
  dual modifier-tracking split (`Controller.keys_pressed` vs `mock.lua` `held`) — test-harness structure.
