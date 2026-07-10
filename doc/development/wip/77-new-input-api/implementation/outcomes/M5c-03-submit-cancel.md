# Outcome — M5c-03: submit / cancel (chunk 3 of the M5c carve)

_Executed as a one-shot implementation pass for
[`../prompts/M5c-03-submit-cancel.md`](../prompts/M5c-03-submit-cancel.md),
2026-07-10. Test-first: chunk-3 rows added red, then implementation, then
full-suite verification._

## What will surprise the architect (read first)

1. **Hooks live on the ROUTE (`compy_input`), never on the widget.** Spec §5's scope
   note ("the widget never owns submit — the owning route's tier-1 handler does") is
   taken literally: `before_/after_submit`/`before_/after_cancel` are read straight off
   `self.compy_input` inside the new `framework_submit`/`framework_cancel` closures
   (`projectInputController.lua`), never copied onto `UserInputController` the way
   `validator`/`on_text_entered` are. Consequence: they are **field-only** on
   `compy.input` (no `show()`/`configure()` config-key sugar) — spec §3's `show()`
   field table never lists them, unlike the four widget outputs (AC-16). This reads as
   two different "settability shapes" for two vocabularies (hooks vs widget outputs);
   it is what the spec states, not an invented split.
2. **`UserInputController:submit()`/`:cancel()` are new public methods, called
   externally by the tier-1 entries — not sink-internal.** The OLD sink-embedded
   `submit()`/`cancel()` locals inside `UserInputController:keypressed()` are gone for
   `submit` (fully dead: only ever fired when `oneshot`, i.e. only for the project
   widget) but `cancel` (escape-clears, unconditional) is **kept** — it is
   console/editor's own escape-clear behaviour on routes that have no tier-1 layer yet
   (console/editor migration is a later, out-of-slice follow-on per M5c-dispatch-
   chain.md). For the project widget specifically the framework tier-1 escape entry
   intercepts Escape before it ever reaches this sink-level `cancel()`, so the two never
   collide; removing it outright would have been an out-of-scope regression to
   console's pre-existing Escape behaviour.
3. **AC-39's second deprecated row did not go red.** `a submit fills the handle and
   closes #deprecated` (spied `love.event.push`) went red as predicted the moment the
   producer was deleted. `a oneshot submit deactivates the widget #deprecated` **stayed
   green** — it calls `F.session.handlers.userinput()` (the surviving POLL CONSUMER,
   `love.handlers.userinput` in `controller.lua`, explicitly out of scope to touch)
   *directly*, so its assertions never actually depended on `oneshot`/the deleted
   producer in the first place; it was already exercising the surviving consumer, not
   the retired mechanism. Deleted anyway per its own `#deprecated` tag and explicit
   retirement comment, with the green new-chain rows cited as the replacement — see the
   AC-39 ledger below for the full reasoning. Verified live (not inferred): TAP output
   showed `not ok 20` for the first row and `ok 28` for the second, at the exact commit
   boundary where only the source deletion had landed.
4. **`keep_history()` now unconditionally returns `true`.** `oneshot` gated it
   (`not self.oneshot`); only the project widget ever set `oneshot=true`, and nothing
   reads the project widget's history (no `history_back`/`fwd` is wired to it), so the
   suppression was already write-only/inert. Collapsing it to `true` matches what the
   other three constructors (console/search/editor) already got and is a conservative,
   test-verified-safe simplification, not a new design call — flagged here because it
   is a judgment call on an otherwise-unspecified corner (AC-25 names this exact line
   for removal but does not say what replaces the condition).
5. **`UserInputView:draw()`'s oneshot check becomes an identity check.** The removed
   `is_oneshot()` gate skipped a redundant per-frame `update_view()` specifically for
   the published overlay singleton (a pre-existing perf workaround, commit `7b4422c`,
   "a transitional workaround until rerenders are worked out" — unrelated to submit/
   cancel semantics). Since `oneshot=true` was, in production, exactly and only that
   one instance, `self.controller ~= love.state.user_input_controller` is a faithful,
   behaviour-preserving substitution, not a new perf policy.
6. **`AC-18`'s literal "Enter/Space/arrows" widened the sink's existing error-lock
   gate.** The pre-existing `has_error()` unlock check in `UserInputController:
   keypressed()` only cleared on Enter/Up/Down (console's *own* copy of this same idea,
   in `ConsoleController:keypressed`, already had Space but not Left/Right). Since this
   shared sink method is exactly what AC-18's validator-reject path locks through, and
   AC-18 explicitly names the full unlock set, I widened it to include Space/Left/
   Right — a small, directly-cited, in-scope fix rather than an unrelated cleanup.
7. **A test-isolation gap surfaced and was fixed at fixture scope only.**
   `UserInputController.validator`/`.on_text_entered`/`.on_limit_reached`/`.result` are
   widget fields `apply_config()` only overwrites when a `show()` call supplies them
   (AC-24's persistence, working as designed) — but the contract-suite fixture's
   `F.reset()` never cleared them between tests, so one test's validator could leak into
   the next once multiple tests actually *executed* a validator (nothing did, pre-
   chunk-3). Fixed in `tests/helpers/input_fixture.lua` only (`singleton.validator =
   nil` etc.), not in `UserInputController:clear()` — the production API's `clear()` is
   spec'd as "clears content... no callback fires" and must not also reset these.
8. **`framework_handlers.keypressed['return'/'escape']` are populated once, at
   `ProjectInputController` construction — not per `activate()`.** They are structural/
   non-overridable and exist whether or not a project is currently running (consistent
   with tier 1 being "non-overridable" per the file's own header). This meant the test
   fixture's `reset_chain()`, which previously wiped the whole `framework_handlers.
   keypressed` table between tests (safe when the table only ever held test-installed
   entries), needed a `keep`-list so it stops erasing the framework's own entries every
   test — fixed in the same fixture pass (item 7).
9. **Body-length compliance forced a small model.lua refactor beyond the literal
   diff.** `UserInputModel:handle()` was already ~24 lines (over the 14-line hard
   limit) before this chunk; removing the oneshot/push block from inside it left it
   still over, so it was split into `_apply_eval`/`_report_parse_error` helpers while
   deleting the push block — a mechanical extraction of code I was already touching,
   not a scope-widening refactor of untouched code.

## Commit refs

- `2a7a26b` — `test(input): red rows for submit/cancel chain (M5c chunk 3)`
- `9bb6d29` — `feat(input): submit/cancel chain, oneshot deletion (M5c chunk 3)`

Independently revertible; in-repo files only; no push; no `src/examples/*`; no nested
`.git`. **Correction to the `test(input)` commit's own message:** it says "the two
deprecated rows are still green" at that commit — inaccurate as literally stated,
because the AC-39 retirement (demoting/deleting those two rows) was folded into the
*same* test-file edit pass and is therefore already present in that commit, not a
later one. The actual red-for-the-right-reasons check (source-deleted, test file not
yet touched) was run and verified separately during implementation (see point 3 above
and Verification below) — the lifecycle was genuinely exercised, just not replayed as
literal separate commits.

## Files changed

- `src/controller/projectInputController.lua` — tier-1 `keypressed['return']`/
  `['escape']` entries (`install_tier1`, `framework_submit`, `framework_cancel`,
  `shown_widget`, `run_hook`), populated once at construction. `activate()`/
  `_tier3`/`_sink`/`_dispatch`/the `app_state ~= 'running'` forwarding: untouched.
- `src/controller/userInputController.lua` — new `submit()`/`is_shown()` methods;
  `cancel()` extended with `self:hide()`; `is_oneshot()` deleted; the sink's old
  oneshot-gated `submit()` local deleted (its `cancel()` sibling kept, see point 2);
  `has_error()` unlock set widened (point 6).
- `src/model/input/userInputModel.lua` — `oneshot` field/ctor-param deleted;
  `keep_history()` collapsed to `true`; `push('userinput')` producer deleted from
  `handle()`, which is split into `_apply_eval`/`_report_parse_error` (point 9).
- `src/view/input/userInputView.lua` — M6-01: `self.oneshot` snapshot + `@field`
  dropped; `draw()`'s `is_oneshot()` read replaced with an identity check (point 5).
- `src/controller/consoleController.lua` — `INPUT_CALLBACKS` widened with the four
  `before_/after_` hooks (AC-33).
- `src/main.lua`, `src/model/consoleModel.lua`, `src/model/editor/searchModel.lua` —
  `UserInputModel(...)` call sites updated for the dropped `oneshot` positional arg.
- `tests/helpers/input_fixture.lua` — ctor call-site updates; `reset_chain()`
  preserves the framework's own tier-1 entries while still wiping test-installed ones;
  `F.reset()` clears the widget's own output/hook fields (points 7/8).
- `tests/input/input_contracts_spec.lua` — the `submit and cancel chain` block
  (AC-17..26/42(b)); the AC-39 retirement of the two `#deprecated` rows; the
  `on_text_entered delivers...` bare `pending()` replaced by the live rows; the final
  catch-all `pending()` trimmed of "submit/cancel chains" (landed).

## Verification

- **Full suite (`busted tests`):**
  - **Before (baseline, `git stash` to the pre-chunk tree): 759 successes / 0
    failures / 0 errors / 6 pending.**
  - **After: 771 successes / 0 failures / 0 errors / 5 pending.**
  - Net: +14 live rows (19 new `it(...)` rows added, 2 deprecated rows deleted, 1 bare
    `on_text_entered...` pending replaced by live coverage → net −1 pending: 6→5).
- **Red-for-the-right-reasons, test-first:** with only the new test rows added (source
  unchanged), the suite showed genuine errors (methods that don't exist yet):
  `git stash` to that exact point + `busted tests` → **685 successes / 0 failures / 86
  errors / 5 pending**.
- **AC-25 breaking the deprecated machinery, verified live:** after landing the source
  deletion (oneshot/push gone) but before touching the deprecated rows,
  `busted tests/input/input_contracts_spec.lua -o TAP` showed `not ok 20 - ... a submit
  fills the handle and closes #deprecated` (red, as AC-39 predicts) and `ok 28 - ... a
  oneshot submit deactivates the widget #deprecated` (green — the divergence in
  surprise point 3).
- **LSP diagnostics** (`mcp__lua-lsp__diagnostics`, after `sleep 1`): clean on all
  touched files except pre-existing hints/warnings unrelated to this chunk's diff
  (duplicate-set-field noise from `class.create`'s method-definition style, unused
  mouse/touch stub params, a pre-existing `swap_lines` redefined-local, a pre-existing
  `emit_limit` direction/scope type looseness from chunk 2). `mcp__lua-lsp__references`
  was flaky in this session (intermittent broken-pipe errors); cross-checked
  completeness with `grep -rn oneshot`/`UserInputModel(` sweeps instead (backstop per
  the LSP-usage guidance) — no dangling `oneshot`/`is_oneshot` reader remains outside
  the unrelated `profiler.lua`/`controller.lua` profiler symbol and `lib/metalua`.
- **Hard limits:** no new/edited line in this diff exceeds 64 chars (verified with an
  `awk` sweep over `git diff` `+` lines, per file); new function bodies ≤ 14 lines,
  ≤ 4 params (`run_hook`'s trailing `...` follows the file's existing `_dispatch`
  vararg convention), nesting ≤ 4.
- **Manual check:**
  - **Headless smoke test:** `xvfb-run -a love src --headless` boots without an
    error/traceback during load (ran to the timeout, no crash) — confirms the app
    wires up with the new code path present.
  - **Could not drive real interactive keystrokes** into a live LÖVE window from this
    headless container (no OS-level input device, no scripted-keystroke driver wired
    to a running instance) — saying so per the prompt's instruction rather than
    claiming hand-play that did not happen. The full 4-mode + turtle/maze hand-play is
    chunk 5's job per the slice's test strategy.
  - **In place of hand-play:** every one of the four "at minimum" scenarios the prompt
    names is exercised by a **real busted acceptance row driving the actual production
    dispatch chain** (`love.handlers` gateway → `ProjectInputController` →
    `UserInputController`, not a mock of the unit under test): typing + Enter submit
    (`Enter runs the full submit call-order chain`, delivers the full assembled text
    and deactivates); Escape dismiss (`Escape runs the full cancel call-order chain`);
    a rejecting validator locking without delivery (`a rejecting validator locks input
    without delivering`); Shift+Return inserting a newline in a shown widget
    (`Shift+Return is not intercepted; the sink edits`).

## Per-AC checklist (in-scope ACs)

| AC | Status | Row(s) |
|---|---|---|
| AC-17 submit call-order | met | `Enter runs the full submit call-order chain` |
| AC-18 validator reject locks, no delivery | met | `a rejecting validator locks input without delivering` |
| AC-19 cancel call-order, Escape dismisses | met | `Escape runs the full cancel call-order chain` |
| AC-20 hidden = ordinary keys | met | `Enter and Escape are ordinary keys while hidden` |
| AC-21 framework not shadowable | met | `framework Enter cannot be shadowed while shown` |
| AC-22 Shift+Return not intercepted | met | `Shift+Return is not intercepted; the sink edits` |
| AC-23 hide()/force=true fire no cancel chain | met | `hide() fires no cancel chain`; `a force=true reconfigure fires no cancel chain` |
| AC-24 continuous-session idiom + persistence | met | `after_submit can re-activate the widget mid-sequence`; `on_text_entered persists across a hide/re-show cycle` |
| AC-25 oneshot/push gone, observable order | met | `on_text_entered sees the session active; after_submit sees it deactivated`; grep sweep (Verification) |
| AC-26 four hooks default noop+log | met | `submit and cancel complete with no hooks set` |
| AC-39 legacy-solicitation retirement lifecycle | met | see the ledger below |
| AC-40 on_text_input vs on_text_entered split | met (on_text_entered half; on_text_input landed chunk 1) | `Enter runs the full submit call-order chain` (assembled text, not per-char) |
| AC-42(b) validator functionally applied | met | `a custom validator is invoked with the assembled text` |
| AC-43 no-silent-retirement meta-rule | met | AC-39 ledger below |

**Explicitly out of scope (not touched, per the prompt's boundaries):** AC-27..30
route-connection lifecycle and AC-29 teardown, `compy.before_exit` (chunk 4); AC-32
turtle/maze migration (chunk 5); the M7 cursor/config surface.

## AC-39 / AC-43 retirement ledger

| Row | Red-when | Pending-when | Deleted-with-which-green-replacement |
|---|---|---|---|
| `a submit fills the handle and closes #deprecated` | Confirmed red the moment the `love.event.push('userinput')` producer was deleted (`handle()`, AC-25) — TAP `not ok 20` | Not separately committed as a pending()-only step (folded into the same test-file pass as the deletion, see the commit-ref correction above); functionally equivalent to skipping straight past the skip-state once the replacement was already in hand | `a legacy solicitation still fills the reftable on submit` — proves the surviving synchronous reftable-fill (`self.result`) still runs through the new submit chain, satisfying the "behaviour... persists into the new API" comment the deprecated row itself carried |
| `a oneshot submit deactivates the widget #deprecated` | **Did not go red** (TAP `ok 28`, verified live) — it calls the surviving poll consumer directly, independent of the deleted producer (surprise point 3) | Same as above | `Enter runs the full submit call-order chain` + `submit and cancel complete with no hooks set` — together prove deactivation-on-submit through the new chain with none of the deleted oneshot/push machinery, which is the behaviour this row actually asserted |
| `a refused solicitation warns, never silently` | N/A — **not deprecated, untouched** | — | Rides `input_text` (legacy global, stays through M8 per spec §9); no change |

Both retired rows carried their `#deprecated` tag and explicit retirement-lifecycle
comment from the design plane (E32); this chunk supplies the red confirmation (or, for
the second row, the documented reason it did not redden) and the green replacement
before deleting, satisfying AC-43's "replacement-proven-green" clause.

## Per-pinned-remark disposition table

All pinned SCOPE/QUALITY remarks from `M5c-dispatch-chain.md` (U1/P8/P10/C4/P2/C12/
U3/U2a and the C1/C2/C3/C5/C9/C13/C14/C15/C16/C19/C20/C23/T2/T3/T4/P3/P11 QUALITY set)
were dispositioned in chunk 1 (`M5c-01-dispatch-chain.md`); none were re-opened or
chunk-3-owned. This chunk introduces no new pinned remarks — its own review-relevant
observations are the "what will surprise the architect" points above.

## Suite `-- REVIEW:` reconciliation ledger (this chunk's rows only)

- No in-tree `-- REVIEW:` comment in the suite is homed in the submit/cancel surface
  this chunk reshapes. The ones physically nearby stay assigned to their existing
  owners per the prompt's explicit boundary: L401 (M7 prompt-labelling), L495/508-510
  (chunk-4 console-as-sink), L536 (editor block-nav, kept-OPEN) — left untouched,
  verbatim.
- The two AC-39 deprecated rows' own inline comments (design-plane provenance,
  lifecycle description) are replaced by this chunk's retirement-ledger comments in
  place, citing the resolving green rows — not silently deleted (AC-37/43).

## `>> REVIEW`-marker removal ledger

- **`src/controller/projectInputController.lua`:** the pre-existing `-- REVIEW:`
  markers (on `_tier3`, `_sink`, `_dispatch`, `activate`, `keypressed`) are
  chunk-4/final-pass owned per the prompt's explicit boundary (cited lines 66/70/76/
  97/117/141/142 in the commissioning prompt) — left byte-for-byte untouched; verified
  via `git diff | grep REVIEW` showing no hunk touches them.
- **`src/controller/userInputController.lua`, `userInputModel.lua`, `userInputView.lua`,
  `consoleController.lua`:** grepped for `REVIEW` before editing — none present in
  these files at all, so nothing to reconcile or remove.

## Surfaced gaps / tech debt (report-don't-fix)

- **`multiline` config field is accepted but not gated anywhere.** `show{multiline=
  true}` is documented (spec §3) but nothing in `userInputController.lua`/
  `userInputModel.lua` reads a `multiline` flag — Shift+Enter inserts a newline
  unconditionally today, single-line or not (pre-existing, not part of AC-17..26; the
  AC-22 test asserts the actual current behaviour, not a gated one).
- **`emit_limit`'s `dir` parameter is typed `VerticalDir` but called with `'left'`/
  `'right'` too** (chunk 2's boundary work) — a pre-existing LSP `param-type-mismatch`
  hint, unrelated to this chunk, not fixed.
- **The tests-vs-production dual modifier-tracking split** (`Controller.keys_pressed`,
  used by `combo_string`, vs. `tests/mock.lua`'s separate `held` table behind
  `love.keyboard.isDown`, used by `Key.shift()`/`Key.ctrl()`/`Key.alt()`) meant the
  Shift+Return acceptance row needed to drive both explicitly
  (`F.session.press('lshift')` *and* `mock.keystroke('S-return', ...)`) to faithfully
  simulate "Shift held while Return is pressed." This is pre-existing test-harness
  structure (two parallel mechanisms that are one reality in real LÖVE), not
  introduced here — flagged since a future test author hitting the same combination
  will rediscover it.

## Escalation stops

**None.** Every non-obvious decision above cites its source (an AC, a spec §, R-id, or
M5c-dispatch-chain.md item) or is flagged as a scoped, conservative, test-verified-safe
call in "what will surprise the architect" (the `keep_history()` collapse and the
`draw()` identity substitution are the two closest to a judgment call; both are
low-risk, reversible, and explained above rather than silently made).
