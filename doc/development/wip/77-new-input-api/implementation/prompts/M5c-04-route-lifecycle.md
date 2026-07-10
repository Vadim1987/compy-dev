# Implement — M5c-04: route-connection lifecycle (chunk 4 of the M5c carve)

_Commissioned by the opus-sweeper PM (`agents/sweep.md`), session03, 2026-07-10, under
[`M5c-M8-sweep-mandate.md`](M5c-M8-sweep-mandate.md). This is **chunk 4** of the M5c carve — the
route-connection lifecycle (Scope 5), built on the landed chunk-1 dispatch chain, chunk-2 widget
outputs, and chunk-3 submit/cancel. It is **not** the whole slice: the turtle/maze migration (Scope 6)
is chunk 5. Target executor: **Claude Sonnet**, in the M0 dev image._
_Autonomous sweep: the per-chunk human gate is lifted (human reviews post-factum in git). You still
**STOP and report** on a genuine spec gap / corpus contradiction / in-slice design decision (mandate
guardrail 1). **This chunk sits amid the human's most pointed REVIEW markers about the whole route
model — the escalation boundary below is load-bearing; read it twice.**_

## Infra note (this session)

The **lua-lsp MCP server is DOWN** (broken-pipe on every call). Use the rules' sanctioned backstop:
`grep -rn` with comment-exclusion, cross-checked against every construction/call site, for the
completeness-critical caller sweeps (the forwarding-removal is exactly such a sweep). Do not fabricate
an LSP result.

## You are

A one-shot implementation agent in the **compy** LÖVE2D codebase (repo root /repo = your cwd), running
the **dev charter** (`agents/dev.md`). You implement **exactly this chunk**, test-first, commit locally
(Conventional Commits, **no push, this repo only**), record the outcome ledger, then report a per-AC
summary + commit hashes + before/after busted counts. Resolve scope by the authority chain, never by
inventing.

## What this chunk delivers (Scope item 5 — route connection lifecycle)

The keyboard/text route becomes **genuinely connected only while `'running'`** and **fully torn down at
stop**, and the **M4 ruling-1 per-event forwarding is removed** — replaced by real slot restoration at
the state transition:

1. **Connect / disconnect at the state boundary (AC-27).** The project route occupies the
   keyboard/text slots (`keypressed`/`textinput`/`keyreleased`) when `app_state` enters `'running'` —
   and only then. When a **non-blocking `main.lua` returns** (no `update`/`draw` hooked) the state
   drops to `'project_open'` and the **keyboard/text slots restore to the console route**, so typing
   reaches the REPL again. **Remove the M4 ruling-1 forwarding** — the three `if love.state.app_state
   ~= 'running' then return Controller._defaults.<event>(…)` branches in
   `projectInputController.lua:215-241` (keypressed/textinput/keyreleased) — because the slots are now
   actually restored at the transition, so the per-event guard is dead. **This resolves the human
   REVIEW+TODO at `projectInputController.lua:213-214`** (`what is _defaults and why the check is
   needed… TODO: refactor this part, _defaults should either be not used or handled ONCE`).
2. **Pointer slots are NOT part of the disconnect (AC-28).** Pointer natives stay hooked until project
   **stop**: a pen-and-paper example (`sapper`) stays clickable in `'project_open'`. **Do NOT unify
   pointer disconnection into ruling 3's keyboard/text scope** — this is a named forbidden move (spec
   §8, slice Risk). Leave `hook_pointer` / the `_pointer` slot wiring alone.
3. **Stop = full teardown (AC-29).** On project stop: all slots restore to framework defaults;
   `compy.input.handlers.*` tables **and every mutable field** (§7: `on_*`/`before_*`/`after_*` +
   the four widget outputs) reset to defaults; **no project participant stays wired** (doc A §6.4). A
   widget shown at stop → **silent hide, no cancel chain** (AC-19's cancel chain must NOT fire at
   teardown). Teardown invariant: nothing a project installed survives it — the next project/route
   starts from framework defaults.
4. **`inspect` (AC-30, R11).** The console route is active, bound over the project environment; the
   project route is disconnected; the project's widget goes **unhonoured** (owning route inactive). No
   special rules — verify current behaviour already satisfies this, or make it so.
5. **`active_keyboard_route()` — the chunk-1 deferral, resolved (E30 Scope-10(a), C23).** Drop the
   `active_keyboard_route() == CC` **assertion** in the suite (the `stop names the console as restored
   route` row, `input_contracts_spec.lua:699/703`) and **retarget that row to AC-29 teardown** — stop's
   distinctive contract is the full teardown (participants unwired, widget silently hidden), **not**
   "keyboard route == console" (that end-state is shared by project-exit and inspect, so it is not
   stop-specific). Per C23 (no unconsumed public surface), also drop the `active_keyboard_route`
   accessor + its REVIEW marker (`controller.lua:998-999`) — its **only** reader is the **untracked**
   `src/tests/autotest.lua` (L133/212), which this repo does not own. **Flag the autotest.lua impact
   loudly** in the ledger (the human carries that local driver and will update it).
6. **`compy.before_exit` project-stop hook (M6-02 rides here).** Add the settable
   **`compy.before_exit`** slot (on the `compy` namespace, **not** `compy.input` — it is a project-run
   lifecycle hook, not an input channel). Follow `design/spec/M6-01-oneshot-snapshot.md`'s sibling
   `design/spec/M6-02-before-exit.md` **verbatim**: fires on project stop **before** framework cleanup
   (so `love.*` device calls are still safe); default = noop + debug log; **reset to default on stop**
   (same lifecycle as `compy.input.on_*` — part of the AC-29 teardown); **return ignored** (cannot
   suppress stop); **no args**. Canonical consumer named in the spec: `keyboard` restoring key-repeat
   (that migration is not this chunk — just deliver the hook + its reset).

## The escalation boundary — READ TWICE (this is where chunk 4 can go wrong)

The route-connection machinery carries the human's **most pointed REVIEW markers**, and they are
**design-authority questions, not chunk-4 work**:

- `controller.lua:190/191/192` (`occupy_keyboard`): *"purpose unclear… design assumed little
  structural difference between console/editor/project controllers — considering them equivalent
  swappable routes. Having a separate function that treats PIC specifically contradicts this logic…
  I want to know WHY"*; *"we do not have concept of 'occupying'…"*; *"STRONGEST SEMANTICAL
  CONFUSION…"*.
- `controller.lua:695` (`set_default_handlers`): *"console and project input have ties… but beyond
  that I see no reason to treat them as pets not cattle."*
- `controller.lua:197/207` (wrap-vs-assign, `_keyboard_route` purpose).

**These question whether the route model should be unified / PIC de-specialised / `occupy` renamed.
That is the DEFERRED console/editor migration and is explicitly OUT OF SCOPE** (Gate-2 closing ruling:
no opportunistic architectural unification in-slice; slice Risk: do not "unify" routes). **Chunk 4
delivers only the concrete spec'd behaviour (AC-27/28/29/30 + M6-02) — it does NOT re-architect route
equivalence, does NOT rename `occupy_keyboard`, does NOT de-specialise PIC, does NOT change the
wrap-vs-assign shape.**

- **You MAY** resolve the L213-214 `_defaults`/TODO marker because AC-27 concretely removes that
  forwarding (that is the deliverable, not a redesign).
- **You must LEAVE** the route-equivalence markers (L190/191/192/195/197/207/695) in place, untouched —
  they are design inputs the human owns; note in the ledger that they remain, homed in the deferred
  migration.
- **If removing the forwarding cleanly *genuinely requires*** answering "should PIC be special / how do
  routes unify" — i.e. spec §8's mechanism does not close and you cannot restore slots at the
  transition without re-architecting — that is a **real seam collision**: **STOP and report it as an
  escalation** (do not invent a route-model ruling). Per the standing autonomous authorization, if it
  is a genuine but small/reversible design ambiguity, make the **most conservative, most reversible**
  choice, **flag it loudly surprise-first**, and continue — but a route-model redesign is neither small
  nor reversible, so that escalates hard.

## Read first (authority chain — all frozen/ratified)

1. **`design/spec.md` §8 (Route connection lifecycle) — the AUTHORITATIVE contract for this chunk.**
   Read it verbatim; also §10 (edge cases: project stops while widget shown → silent hide, callbacks
   reset). §8 gives the exact connect/disconnect/stop/inspect mechanism — implement to it.
2. **`design/spec/M5c-dispatch-chain.md`** — Scope 5, **AC-27 … AC-30**; the E30 Scope-10(a) resolution
   text (route-restoration lexicon, the `stop names the console` retarget, drop the C23 accessor).
   Re-read the slice **Risk** (do not unify pointer disconnect; teardown invariant).
3. **`design/notes/ratified-model.md`** — canonical; ruling 3 (slots occupied only while running),
   R11 (inspect), R13 (consuming ≠ removing), the binding glossary (mint no new nouns; "route",
   "teardown" are the words).
4. **`design/spec/M6-02-before-exit.md`** — the `compy.before_exit` hook contract (item 6), verbatim.
5. **`agents/rules.md` + `agents/development.md`** (auto-loaded) — hard limits (line ≤64, fn body ≤14,
   params ≤4, nesting ≤4), no string-tag dispatch, KISS, **tests-first**, report-don't-fix, Conventional
   Commits, no push.
6. **`notes/input-contracts.md` (doc A)** — §6.4 (project stop clears user handlers), §6.6; cite by §N.
7. **The live code you rework:**
   - `src/controller/projectInputController.lua:215-241` — **remove** the three `app_state ~=
     'running'` forwarding branches (keypressed/textinput/keyreleased) + resolve the L213-214 REVIEW+TODO.
     `activate()`/`deactivate()` (L190-201): the connect/disconnect entry points.
   - `src/controller/controller.lua` — `occupy_keyboard` (L193, **connect**; leave its name/shape),
     `set_default_handlers` (L692, the console-restore target — `project_input:deactivate()` + reinstall
     console love handlers), `clear_user_handlers` (L1031, today only resets `_userhandlers` — AC-29
     needs the `compy.input` participants reset too), `_defaults` (L346+), `active_keyboard_route`
     (L998-999, drop per C23). The `compy`/`compy.input` namespace setup for `compy.before_exit`.
   - `src/controller/consoleController.lua` — `stop_project_run` (L994, the **stop** path calling
     `set_default_handlers`/`clear_user_handlers`; where `compy.before_exit` fires **before** cleanup)
     and the `'project_open'` transitions (L940/1003; L256/260) — the **non-blocking-return** path AC-27
     restores slots at. `quit_project` (L1007). The `inspect` path (L891, AC-30).
   - `tests/input/input_contracts_spec.lua` — the `stop names the console as restored route` row
     (L699/703, **retarget to AC-29 teardown**, drop the accessor assertion); `the console receives
     after stop` (spec:332, the PRESERVE row already covering the behavioural end-state). The suite's
     `-- REVIEW:` markers homed here (L495/508-510 console-as-hidden-sink musings) — reconcile only if
     genuinely resolved by AC-29/AC-30, else leave for the console-migration follow-on. Reconcile-or-
     escalate, never silent-delete.
8. **`implementation/outcomes/M5c-01/02/03-*.md`** — the chain, outputs, and submit/cancel you build on;
   the chunk-1 `active_keyboard_route` deferral (its surprise #8) you now discharge; the chunk-3
   teardown boundary (chunk 3 did submit-time deactivate; you do route-level teardown — do not undo its
   work).

## Do — in this order

1. **Red suite first (test-first).** Transcribe **AC-27/28/29/30** + the M6-02 hook into acceptance rows
   run **red for the right reasons** before implementing:
   - **AC-27** non-blocking `main.lua` returns → `'project_open'` → typing reaches the REPL (slots
     restored; the forwarding is gone, not compensating). **AC-28** a pointer example stays clickable in
     `'project_open'` (pointer NOT disconnected). **AC-29** stop → `handlers.*` + every mutable field
     reset, a shown widget silently hidden with **no** cancel chain, nothing project-installed survives.
     **AC-30** inspect → project route disconnected, widget unhonoured. **M6-02** `compy.before_exit`
     fires once on stop before cleanup, default noop, reset on stop, return ignored.
   - Retarget the `stop names the console as restored route` row to **AC-29 teardown** (assert the
     teardown, not `active_keyboard_route() == CC`).
2. **Restore slots at the `'running'→'project_open'` transition (AC-27).** At the non-blocking-return
   transition, reinstall the console keyboard/text handlers (the `set_love_keypressed/textinput/
   keyreleased` machinery, or the appropriate subset of `set_default_handlers` that does NOT tear down
   pointer/update/draw — AC-28) and `project_input:deactivate()` the keyboard route. Keep pointer slots
   hooked.
3. **Remove the forwarding (AC-27).** Delete the three `app_state ~= 'running'` branches in
   `projectInputController.lua`; the route now only runs while genuinely connected. Grep-sweep for any
   other reader of that guard/`_defaults` fallback before deleting (LSP is down — grep backstop).
4. **Full teardown at stop (AC-29).** Extend the stop path so `compy.input.handlers.*` and every mutable
   field reset to defaults and a shown widget is silently hidden (no cancel chain). Reconcile with what
   `clear_user_handlers`/`set_default_handlers`/`project_input:deactivate()` already do — extend, don't
   duplicate. Verify the teardown invariant (nothing survives).
5. **`inspect` (AC-30).** Confirm/ensure the project route is disconnected and the widget unhonoured
   under `inspect`; add the covering row.
6. **`compy.before_exit` (M6-02).** Add the hook per its spec: settable on `compy`, default noop+log,
   fires before cleanup on stop, reset on stop, return ignored.
7. **`active_keyboard_route` (C23).** Drop the accessor + REVIEW marker (`controller.lua:998-999`); the
   suite row is retargeted in step 1. Flag the untracked `src/tests/autotest.lua:133/212` impact loudly.
8. **QUALITY / `>> REVIEW` dispositions (Scope 8/9, this chunk's surface only).** Disposition each
   pinned remark homed in the route-lifecycle machinery (`fixed`/`dissolved-by-rework`/`note-only`, with
   remark id). **Resolve** the L213-214 `_defaults`/TODO REVIEW (AC-27 removes the forwarding it names)
   with a ledger line. **Leave** the route-equivalence REVIEW markers (L190/191/192/195/197/207/695) —
   they are the deferred migration's, note they remain.
9. **Run the full suite** (`busted tests`). This chunk's ACs green; m7 rows still pending; **everything
   else green** (no red at the boundary — AC-35).
10. **Manual check (record exactly what you exercised; say so if you cannot run a mode).** At minimum a
    headless smoke boot; the interactive route transitions (non-blocking-return → REPL typing; stop →
    teardown) are ideally exercised by acceptance rows driving the real gateway (the chunk-3 pattern).
    Full 4-mode + the ruling-3 non-blocking case + turtle/maze hand-play is chunk 5.
11. **Commit locally** — Conventional Commits (`feat(input):` / `refactor(input):` for the forwarding
    removal), independently revertible commits, pre-commit hook green, **in-repo files only**. No
    `src/examples/*` edits.

## Record the outcome — `implementation/outcomes/M5c-04-route-lifecycle.md`

Open with the mandatory **"what will surprise the architect"** (guardrail 3 — the forwarding-removal
blast radius, the slot-restore-at-transition mechanism you chose, the AC-29 teardown reconciliation,
the `active_keyboard_route`/autotest.lua impact, any conservative-reversible call, and — explicitly —
that the route-equivalence REVIEW markers were **left in place, not resolved**). Then: commit refs ·
files changed · verification (**real** busted counts before/after; the manual-check record) · **per-AC
checklist** (27/28/29/30 + M6-02, each `met` with its test name, or the stop that blocked it) · the
**per-pinned-remark disposition table** (incl. the L213-214 resolution + the left-in-place route-
equivalence markers) · the **suite `-- REVIEW:` reconciliation ledger** · the **`>> REVIEW`-marker
removal ledger** · surfaced gaps or "none". **Every non-obvious decision bullet cites its source**
(`spec.md §8` / `M5c-dispatch-chain.md §…` / `ratified-model.md` R-id / `M6-02-before-exit.md` / doc A
§N / remark id) — **uncitable = a judgment call = you should have stopped** (guardrail 2).

## Boundaries — what is NOT in this chunk

- **No route-model redesign** (Gate-2 no-opportunistic-unification): do NOT unify console/editor/project
  routes, de-specialise PIC, rename `occupy_keyboard`, or change wrap-vs-assign. Deliver AC-27/28/29/30
  + M6-02 only. The route-equivalence REVIEW markers stay untouched.
- **No pointer-disconnect unification (AC-28):** pointer slots stay hooked until stop. Named forbidden.
- **No example migration (Scope 6 → chunk 5):** do NOT touch `src/examples/*`; never commit inside a
  nested checkout or touch its `.git` (guardrail 7). (`src/tests/autotest.lua` is untracked — do not
  commit it; you only *note* the accessor-drop impact on it.)
- **No M7 surface** (`configure`/`clear`/`get_cursor`/`set_cursor`/`set_text`) — later milestone.
- **Do not undo chunk 3:** the submit-time deactivate + Escape-dismiss are chunk 3's; you add
  route-level teardown around them, not instead of them.
- **The `push('userinput')` polling CONSUMER survives** (M8) — untouched here.
- **Never edit `doc/development/wip/77-new-input-api/design/`** — frozen input you read.
