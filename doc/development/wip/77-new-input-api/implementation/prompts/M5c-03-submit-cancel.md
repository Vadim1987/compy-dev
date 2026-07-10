# Implement — M5c-03: submit / cancel (chunk 3 of the M5c carve)

_Commissioned by the opus-sweeper PM (`agents/sweep.md`), session03, 2026-07-10, under
[`M5c-M8-sweep-mandate.md`](M5c-M8-sweep-mandate.md). This is **chunk 3** of the M5c carve — the
submit/cancel path (Scope 3), built on the landed chunk-1 dispatch chain and chunk-2 widget outputs.
It is **not** the whole slice: the route-connection lifecycle (Scope 5) and the turtle/maze migration
(Scope 6) are **later chunks** (see Boundaries). Target executor: **Claude Sonnet**, in the M0 dev
image._
_Autonomous sweep: the per-chunk human gate is lifted (human reviews post-factum in git). You still
**STOP and report** on a genuine spec gap / corpus contradiction / in-slice design decision — that is
a design-authority gate, not a scheduling gate (mandate guardrail 1)._

## You are

A one-shot implementation agent in the **compy** LÖVE2D codebase (this repo, root = your cwd), running
the **dev charter** (`agents/dev.md`). You implement **exactly this chunk**, test-first, commit locally
(Conventional Commits, **no push, this repo only**), record the outcome ledger, then report back a
per-item summary + commit hashes + before/after busted counts. Mid-chunk, if you hit a genuine **spec
gap, corpus contradiction, or any in-slice design decision, STOP and report it** (an in-slice design
ruling is a gate failure). Resolve scope by the authority chain, never by inventing.

## What this chunk delivers (Scope item 3 — submit / cancel)

After this chunk, Enter and Escape on a **shown** widget are real framework entries with full
call-order chains, the validator gates submit, delivery flows through `on_text_entered(text)`, the
widget deactivates unconditionally at submit, Escape genuinely dismisses, and the legacy `oneshot` /
`push('userinput')` machinery is **gone**:

1. **Tier-1 framework entries for `return` / `escape`** (AC-17/19/20/21/22). Populate the
   `framework_handlers.keypressed['return']` / `['escape']` slots (`projectInputController.lua:38-42`,
   left empty by chunk 1 — its header comment L10-11 names exactly this chunk). They **engage only
   while the widget is shown**; hidden, Enter/Escape are ordinary keys that fall down the chain
   (AC-20). Framework entries run **first, unconditionally** — project handlers cannot shadow them
   (AC-21). **Shift+Return is NOT intercepted** (AC-22) — it reaches the sink and inserts a newline
   when `multiline`.
2. **Submit call-order chain (AC-17):** Enter (widget shown) runs
   `before_submit(keys_pressed)` → **validator** → on accept: `on_text_entered(text)` with the full
   **assembled** text → the widget **deactivates** → `after_submit(text)`.
3. **Validator gate (AC-18, AC-42(b)):** on reject the error is displayed and input **locks** until
   acknowledged (Enter/Space/arrows); `on_text_entered` and `after_submit` do **not** fire; the session
   stays active for correction or Escape. A custom `validator` is invoked with the assembled text and
   its verdict gates delivery (AC-42(b) — the behaviour half of the slot chunk 2 made settable).
4. **Cancel call-order chain (AC-19):** Escape (widget shown) runs `before_cancel(keys_pressed)` →
   content cleared + widget hidden → `after_cancel()`. **Escape genuinely dismisses** — the old
   clears-but-does-not-dismiss behaviour is gone.
5. **`hide()` fires no cancel chain (AC-23).** `show()` while a session is active is a no-op + warning;
   `{force=true}` reconfigures in place (content replaced iff `text` given), still no cancel chain.
6. **Continuous-session idiom (AC-24):** `after_submit = function() compy.input.show{…} end`
   re-activates within the same submit sequence, before the frame draws; fresh activation without
   `text` starts empty; callbacks and `handlers.*` **persist** across deactivation (only project stop
   resets them — that reset is **chunk 4**, do not build it here).
7. **`oneshot` deleted (AC-25) + M6-01 rides.** Remove `oneshot` from the codebase: model field + ctor
   param + the `not self.oneshot` read (`userInputModel.lua:15/45-49/412/816`),
   `UserInputController:is_oneshot()` + the `input.oneshot` submit guard
   (`userInputController.lua:29-30/497`), and — **M6-01 supplementary slice, rides here** — the
   vestigial view snapshot `self.oneshot = ctrl.model.oneshot` + `@field oneshot` annotation + the live
   `is_oneshot()` read in `draw()` (`userInputView.lua:19/28/289`). **Both jobs `oneshot` did move out
   of the widget** into the submit chain. *(`profiler.lua` and `lib/metalua` `oneshot` are a
   **different, unrelated symbol** — never touch them.)*
8. **`push('userinput')` producer dissolved (AC-25).** Delete the `love.event.push('userinput')` /
   `love.harmony.utils.love_event('userinput')` producer under `if self.oneshot`
   (`userInputModel.lua:816-824`). The observable order is fixed: `on_text_entered` sees the session
   **still active**, `after_submit` sees it **deactivated** (unless the hook re-activated it). **The
   polling *consumer* idiom survives to M8** (E32 producer-m5c / consumer-m8 split — do **not**
   re-couple or remove the consumer here).
9. **All four hooks default to noop + debug log (AC-26)** — `before_/after_submit`,
   `before_/after_cancel` — mirroring the AC-10/AC-26 default-callback shape chunk 1/2 established.

## The AC-39 retirement lifecycle (READ — this is the trap)

Two green rows are already `#deprecated`-tagged (E32, done in the design plane) and exercise the
machinery you delete:

- `a submit fills the handle and closes #deprecated` (`input_contracts_spec.lua:365`) — asserts the
  `push('userinput')` close via a `love.event.push` spy.
- `a oneshot submit deactivates the widget #deprecated` (`input_contracts_spec.lua:477`) — calls
  `F.session.handlers.userinput()` directly (nil after AC-25 ⇒ error).

**AC-39 / AC-43 lifecycle — follow it exactly, do NOT silently delete:** (1) they are already
`#deprecated`; (2) they go **red** when your AC-25 deletion lands; (3) demote each to **`pending()`**
(busted has no xfail — `pending()` is its skipped state) once red; (4) **delete** only once the
**equivalent new behaviour is green through the new chain** (submit → validator → `on_text_entered(text)`
→ deactivate). The new chain **MUST have a live red acceptance row first** (test-first) — that green row
is the precondition for deleting the deprecated one. A row leaves the suite only by replacement-proven-
green (AC-43). `a refused solicitation warns` (`:380`) rides `input_text` (a legacy global surviving to
M8) — it **stays**, untouched.

## The chunk-3 / chunk-4 deactivate seam (READ — do not cross it)

Chunks 3 and 4 both touch deactivate; the split is drawn by scope, not by you:

- **Chunk 3 (you)** owns the **submit-time** deactivate step (AC-17: the widget deactivates as part of
  the submit sequence) and the **Escape-dismiss** hide (AC-19). That is a **widget/session-level**
  operation inside the submit/cancel chains.
- **Chunk 4 (not you)** owns **route-level** connect/teardown lifecycle (Scope 5): slots occupied only
  while `'running'`, restore-to-console on `project_open`, **removal of the M4 ruling-1 forwarding**
  (`projectInputController.lua:143-168`, the `app_state ~= 'running'` → `Controller._defaults`
  branches), stop = full teardown, and the `compy.before_exit` hook (M6-02). **Leave all of that
  alone.** In particular: do **not** remove the `app_state ~= 'running'` guards; do **not** build the
  project-stop reset that clears `handlers.*`/callbacks (AC-24 only requires they *persist across
  deactivation* — the reset is chunk 4); do **not** touch the projectInputController REVIEW markers
  (L66/70/76/97/117/141/142) — chunk-4/final-pass.

If wiring the submit-time deactivate **forces** you to also rework route-level teardown (a genuine
collision), that is the seam colliding — **STOP and report**, do not pull chunk-4 work in.

## Read first (authority chain — all frozen/ratified)

1. **`design/spec/M5c-dispatch-chain.md`** — the slice. Read **Scope 3** and **AC-17 … AC-26**,
   **AC-39, AC-42(b), AC-43** verbatim; re-read the "Chief semantic traps" in `## Risk` (R12 sink
   return, R13 consuming≠removing). Your red rows transcribe the in-scope ACs; your ledger cites them
   by id.
2. **`design/notes/ratified-model.md`** — canonical; on divergence it wins. Binding glossary (mint no
   new architectural nouns). Anchors: **R1** (`on_text_entered` = widget output, submit-time, assembled
   text — NOT per-char; the per-char callback is `on_text_input`), **R12** (sink/widget-output return
   carries no chain meaning), **R13** (consuming never removes a tier).
3. **`design/spec.md` §5 (submit/cancel + the mechanism note dissolving `push('userinput')`)** — the
   contract for AC-17–AC-25. Also §2 (chain/signatures) for the tier-1 entries.
4. **`design/spec/M6-01-oneshot-snapshot.md`** — the supplementary slice that rides your `oneshot`
   removal (view snapshot + `@field`). Frozen; read it, deliver its cleanup **in the same pass** as the
   model/controller `oneshot` deletion (AC-25).
5. **`agents/rules.md` + `agents/development.md`** (auto-loaded) — hard limits (line ≤64, fn body ≤14,
   params ≤4, nesting ≤4), **no string-tag dispatch**, KISS, **tests-first**, report-don't-fix,
   Conventional Commits, no push.
6. **`notes/input-contracts.md` (doc A)** — current-behaviour contracts (esp. §5 submit, §6.5 legacy
   solicitation, §6.6 activation/reset); cite by `§N`.
7. **The live code you rework:**
   - `src/controller/projectInputController.lua` — `framework_handlers` (L38-42, populate the tier-1
     return/escape entries); `_dispatch` (L98-107, tier-1 runs first). The "engage only while shown"
     gate: the framework entry checks widget-shown state (the sink's internal hidden-check already
     exists — mirror the condition, don't duplicate the sink). **Do NOT touch L143-168 forwarding.**
   - `src/controller/userInputController.lua` — the current `submit()`/`cancel()` locals (L490-536) and
     `is_oneshot()` (L29-30): where the submit/cancel chains + validator gate + `on_text_entered`
     delivery + submit-time deactivate land, and where `oneshot` is removed.
   - `src/model/input/userInputModel.lua` — `evaluate()`/`cancel()`/`handle()` (L795-825): the
     `push('userinput')` producer (L816-824) + `oneshot` field/param/read (L15/45-49/412/816) to
     delete; the assembled-text source `on_text_entered(text)` delivers; the validator invocation +
     error/lock path (`set_error`, L826+).
   - `src/view/input/userInputView.lua` — M6-01: drop `self.oneshot` snapshot (L19), `@field` (L28),
     reconcile the live `is_oneshot()` read (L289) with `oneshot` gone.
   - `tests/input/input_contracts_spec.lua` — the contract suite. AC-39 deprecated rows (L365/477),
     the on_text_entered pending row (~L730), the AC-40 on_text_input-vs-on_text_entered split (the
     L806-area draft), AC-41 combo rows (L834/844/855, already green — assert they still pass). **Human
     `-- REVIEW:` markers are non-blocking design inputs** — reconcile only those homed in the
     submit/cancel surface; leave L401 (M7 prompt-labelling), L495/508-510 (chunk-4 console-as-sink),
     L536 (editor block-nav, kept-OPEN) for their owners. Reconcile-or-escalate, never silent-delete.
8. **`implementation/outcomes/M5c-01-dispatch-chain.md` + `M5c-02-widget-outputs.md`** — what chunks
   1/2 landed (the chain shape, the settable-but-inert `on_text_entered`/`validator` slots you now make
   fire/gate).

## Do — in this order

1. **Red suite first (test-first).** Under `tests/input/`, transcribe the in-scope ACs into acceptance
   rows and run them **red for the right reasons** before implementing:
   - **AC-17** full submit order (before_submit → validator → on_text_entered(assembled text) →
     deactivate → after_submit); **AC-18/42(b)** validator reject locks, no on_text_entered/after_submit;
     **AC-19** cancel order + Escape dismisses; **AC-20** Enter/Escape hidden = ordinary keys; **AC-21**
     framework entries not shadowable; **AC-22** Shift+Return → newline, not intercepted; **AC-23**
     hide()/show() no cancel chain, `{force=true}`; **AC-24** continuous-session idiom + persistence
     across deactivation; **AC-25** `oneshot` gone, `push('userinput')` gone, observable order; **AC-26**
     four hooks default noop+log.
   - **AC-40 (on_text_input vs on_text_entered):** re-draft the L806-area row to the **split** — assert
     `on_text_input` fires **per character** `(text, keys_pressed)` AND `on_text_entered` fires **once**
     at Enter with the **full assembled** text (R1). A naive greening that keeps a per-character
     `on_text_entered` body is **forbidden** (re-encodes the R1 trap).
   - **AC-42(b)** validator functionally gates (accept→deliver, reject→lock, no delivery).
   - Only after these are red do you implement. Keep the AC-39 deprecated rows red-then-`pending()` per
     the lifecycle above; do **not** green them.
2. **Tier-1 return/escape entries (AC-17/19/20/21/22).** Populate `framework_handlers.keypressed`
   `['return']`/`['escape']`; gate on widget-shown; Shift+Return exempt; framework-first (already the
   `_dispatch` order). Prefer table-driven set-up over duplicated blocks (C2/C5 QUALITY).
3. **Submit chain + validator gate + delivery + deactivate (AC-17/18/42(b)).** Wire
   `before_submit` → validator → accept: `on_text_entered(assembled text)` → deactivate →
   `after_submit`; reject: error/lock, no delivery. The assembled text is the full widget content
   (R1) — not a per-char capture.
4. **Cancel chain + Escape dismiss (AC-19/23).** `before_cancel` → clear + hide → `after_cancel`;
   Escape genuinely dismisses; `hide()` and `show()` fire **no** cancel chain; `{force=true}`
   reconfigure-in-place.
5. **Delete `oneshot` (AC-25) + M6-01.** Remove every `oneshot` reader in the input model/controller/
   view (per file pointers above); reconcile the view's live `is_oneshot()` read. Verify by
   `grep -n oneshot src/` that only the **unrelated** profiler/metalua occurrences remain (LSP
   `references` on the model field + `is_oneshot` before deleting — confirm no live caller left).
6. **Dissolve the `push('userinput')` producer (AC-25).** Delete it; the polling **consumer** idiom
   **survives** (M8). Fix the observable order (on_text_entered active, after_submit deactivated).
7. **AC-39 lifecycle close-out.** Once your new-chain submit rows are green, demote the two
   `#deprecated` rows to `pending()` (red first when AC-25 lands), then delete them citing the green
   replacements (AC-39/AC-43). `a refused solicitation warns` stays.
8. **QUALITY / `>> REVIEW` dispositions (Scope 8/9, this chunk's surface only).** Each pinned remark
   whose home is the submit/cancel machinery gets an explicit disposition (`fixed` /
   `dissolved-by-rework` / `note-only`, with remark id); later-chunk remarks are `note-only` + pointer.
   Remove any `>> REVIEW` marker in code this chunk reshapes, each with a ledger line citing the
   resolving contract point; leave the rest.
9. **Run the full suite** (`busted tests`). This chunk's ACs green; the two deprecated rows end
   `pending()`-or-deleted (never red at the boundary — AC-35); m7 rows still pending; **everything else
   green**.
10. **Manual check (record exactly what you exercised; if you cannot run a mode, say so).** At minimum:
    type into a shown widget and submit with Enter (observe on_text_entered fires with the full text,
    widget deactivates, after_submit sees it deactivated); Escape dismisses; a rejecting validator locks
    without delivery; Shift+Return inserts a newline in `multiline`. (Full 4-mode + turtle/maze hand-play
    is chunk 5.)
11. **Commit locally** — Conventional Commits (`feat(input):` / `refactor(input):` for the oneshot
    removal), independently revertible commits, pre-commit hook green, **in-repo files only**. No
    `src/examples/*` edits in this chunk.

## Record the outcome — `implementation/outcomes/M5c-03-submit-cancel.md`

Open with the mandatory **"what will surprise the architect"** section (guardrail 3 — deviations,
reconciliations, the `oneshot`/`push` removal blast radius, anything already partly present, any
conservative-reversible call you had to make), **before** the file list. Then: commit refs · files
changed · verification (**real** busted counts before/after; the manual-check record) · **per-AC
checklist** for every in-scope AC (each `met` with its test name, or the stop that blocked it) · the
**AC-39/AC-43 retirement ledger** (each deprecated row: red-when → pending-when → deleted-with-which-
green-replacement, or why it still stands) · the **per-pinned-remark disposition table** · the **suite
`-- REVIEW:` reconciliation ledger** (this chunk's rows only) · the **`>> REVIEW`-marker removal
ledger** · surfaced gaps or "none". **Every non-obvious decision bullet cites its source**
(`M5c-dispatch-chain.md §…` / `spec.md §…` / `ratified-model.md` R-id / doc A §N / remark id) —
**uncitable = a judgment call = you should have stopped** (guardrail 2).

## Boundaries — what is NOT in this chunk

- **No route-connection lifecycle (Scope 5 → chunk 4):** do NOT remove the `app_state ~= 'running'`
  forwarding (`projectInputController.lua:143-168`), build the project-stop teardown/reset of
  `handlers.*`/callbacks, restore-to-console, or the `active_keyboard_route()` chunk-1 deferral. AC-24
  only needs persistence *across deactivation*; the stop-reset is chunk 4.
- **No `compy.before_exit` (M6-02 → chunk 4):** that stop hook rides the Scope-5 stop-path, not
  submit/cancel. Do not add it.
- **No M7 surface** (`configure`/`clear`/`get_cursor`/`set_cursor`/`set_text`) — later milestone; the
  L401 `-- REVIEW:` prompt-labelling item is M7. Do not pre-stub.
- **No example migration (Scope 6 → chunk 5):** do NOT touch `src/examples/*`; never commit inside a
  nested checkout or touch its `.git` (guardrail 7).
- **The `push('userinput')` polling CONSUMER survives** (M8, E32 split): dissolve only the *producer*.
- **Never edit `doc/development/wip/77-new-input-api/design/`** — frozen input you read.
