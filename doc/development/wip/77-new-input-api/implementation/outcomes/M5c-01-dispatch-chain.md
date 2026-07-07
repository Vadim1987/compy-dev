# Outcome — M5c-01: the dispatch chain (chunk 1 of the M5c carve)

_Executed by LLM (Claude Opus 4.8) as a one-shot implementation sub-agent under the
opus-sweeper PM, 2026-07-07. Commission:
[`../prompts/M5c-01-dispatch-chain.md`](../prompts/M5c-01-dispatch-chain.md). Test-first,
committed locally (no push). Sub-agent handoff to the PM — not blocking on human approval._

## What will surprise the architect (read first)

1. **Tier-3 "default noop + debug log" is realised in the dispatch, not stored on
   `compy.input`.** `compy.input.on_*` reads `nil` when the project set none; the pic resolves
   tier 3 as `on_* or native or (noop + debug-log)`. A stored-noop default would defeat the R7
   precedence (`on_* or native` would always pick the noop and the native could never seed).
   Observably identical to AC-10 — the tier never edits, never consumes, and debug-logs when
   empty (`M5c-dispatch-chain.md` AC-10; spec §2 tier-3; R7 precedence).
2. **The internal hidden-check keys on the _published overlay singleton_, not a blanket guard.**
   `UserInputController:_is_hidden_overlay()` is `self == love.state.user_input_controller and
   not love.state.user_input`. It must be this narrow because the **console REPL is also a
   `UserInputController`** (`CC.input`) driven by `ConsoleController:keypressed`; a blanket
   top-of-method guard would kill REPL typing (spec §2 tier-4 "Hidden → internal no-op"; AC-11/13).
3. **Natives can now consume — a new `chain_native` wrapper.** `wrap_handler` (used for
   pointer/click) discards its handler's return, and `wrap` returns `(ok, result)`; neither can
   carry a native's truthy/falsey into the chain. Added `chain_native(CC, fn)` (controller.lua):
   error-wrapped, canvas-scoped, and **propagates the native's single return**. This is the
   `C3/C14` return-propagation remark made load-bearing, and it enables AC-36(b) on the native
   path. M4 silently swallowed native returns.
4. **The legacy `if not self.result and running then return` gate in `textinput` is removed.** A
   shown widget now edits regardless of the legacy poll reftable — visibility is decided solely by
   the internal hidden-check (spec §2 tier-4 "Visible → text editing"; AC-12). The `#deprecated`
   legacy-submit rows stay green because they set `result` via `input_text`; no green row asserted
   the old suppression.
5. **New project-facing surface** (spec §2/§7): `compy.input.handlers.{keypressed,keyreleased,
   textinput}` (normalising tables, R14), `compy.input.on_{key_pressed,text_input,key_released}`,
   behind the **R3 mutable-boundary guard** — assigning any other key on `compy.input` raises
   loudly (AC-33). New internal surface: `Controller.held_keys()` (memoised read-only proxy) and
   `ProjectInputController.framework_handlers` (tier-1 slot, empty this chunk).
6. **AC-33 allowlist is intentionally incremental.** Chunk 1 admits only `handlers.*` + the three
   `on_*`. `before_*`/`after_*` and the widget-output fields (`on_text_entered`, `on_limit_reached`,
   `validator`, `highlighter`) **raise** until the submit/cancel and widget-output chunks widen the
   allowlist. This is the commissioned incremental, not a partial AC (commission AC-33 note).
7. **`keys_pressed` proxy — platform caveat.** Read-through + write-raise hold. Under
   **LuaJIT/Lua 5.1** (what `busted` runs on) `pairs` ignores `__pairs`, so `pairs(proxy)` yields
   nothing on this host; the load-bearing contract (read-index + write-raise, spec §1/AC-8) is
   satisfied and `__pairs` is kept for 5.2+ hosts. Surfaced, not escalated.
8. **The M4 code deleted:** `native_split`, `sink_keypressed`, and the provision-onto-
   `compy.input.on_key_pressed` assignment in `activate`. **Kept:** `active_keyboard_route()` /
   `_keyboard_route` (C23 → test-scoped: the uncommitted `src/tests/autotest.lua` manual driver and
   the `stop names the console…` row consume it). The `stop names the console…` row stays green;
   its full retarget to AC-29 teardown rides the route-lifecycle chunk (AC-29 is not in this
   chunk's scope).
9. **Edge note:** `combo_string` (controller.lua) does not lower-case the trigger token
   (keypressed keys are already lower-case); an upper-case _textinput_ combo would not match a
   normalised lower-case registration. Textinput combos are "rarely useful" (spec §2 note); noted,
   not fixed.

## Commits

- `17f6f7e` — `test(input): red rows for the four-tier dispatch chain (M5c chunk 1)`
- `56c4284` — `feat(input): the four-tier project-route dispatch chain (M5c chunk 1)`

Independently revertible; in-repo files only; no push; no `src/examples/*`; no nested `.git`.

## Files changed

- `src/controller/projectInputController.lua` — **rebuilt** as the four-tier chain
  (`_dispatch`/`_tier3`/`_sink`, table-driven `CHANNELS`); `activate` captures natives as tier-3
  seeds only (no provisioning); `native_split`/`sink_keypressed` deleted; all `-- REVIEW:` markers
  resolved by the rebuild.
- `src/controller/controller.lua` — `Controller.held_keys()` read-only proxy; `chain_native` +
  `keyboard_native` (return-propagating native wrapper); `forward_*` hand the proxy; forward_*
  `-- REVIEW:` markers removed.
- `src/controller/consoleController.lua` — `get_compy_input` rebuilt: three normalising handler
  sub-tables + tier-3 callback slots behind the R3 `build_input_surface` guard (AC-33).
- `src/controller/userInputController.lua` — uniform channel signatures + `_is_hidden_overlay`
  internal hidden-check; legacy textinput result-gate removed; A2 DEFERRED comments resolved.
- `src/util/key.lua` — `Key.normalize_combo`, `Key.new_handler_table` (normalising per-event table).
- `doc/development/internals/user_input.md` — dispatch diagram + prose to the four-tier model;
  project-route `>> REVIEW` markers resolved (U3).
- `tests/input/input_contracts_spec.lua`, `tests/helpers/input_fixture.lua` — see test commit.

## Verification

- **Full suite (`busted tests`): 744 successes / 0 failures / 0 errors / 6 pending** (baseline
  M4: 723/0/0/8). Net +21 live rows; pending 8→6 (three pendings went live: `on_text_input`,
  isrepeat, combo-dispatch; one new pending added: `on_text_entered` for the submit chunk).
- **Test-first proof:** with the src changes stashed (M4 code, new tests), the `#m5c` block runs
  **59 errors / 0 successes** (feature absent) — red for the right reasons; green after the feat
  commit. `test(input)` committed before `feat(input)`.
- **LSP diagnostics:** clean on all five changed src files (the six M4 `redundant-parameter`
  suppressions are gone — the rebuild no longer needs them).
- **Hard limits:** no new code line > 64 chars; new function bodies ≤ 14 lines, ≤ 4 params,
  ≤ 4 nesting. Remaining >64 lines in touched files are pre-existing comments / legacy code.
- **Manual (live LÖVE) check: NOT run** — the container is headless and the PM directed no
  xvfb/LÖVE multimedia runs. The project-route dispatch is instead exercised end-to-end through
  the **real `love.handlers` gateway** by the headless acceptance rows (the same production path a
  keystroke takes): a combo handler fires; `on_*`/native truthy intercepts (sink skipped) and
  falsey falls through to the sink; a native participates while the widget is shown; a hidden
  widget mutates nothing. The full 4-mode + turtle/maze hand-play is the later closeout chunk.

## Per-AC checklist (in-scope ACs)

| AC | Status | Row(s) |
|---|---|---|
| AC-1 order | met | `a framework handler consumes before lower tiers`; `an unconsumed event descends every tier to the sink` |
| AC-2 truthy consumes / falsey falls | met | `a truthy combo handler stops the descent`; `assigning a callback replaces only it; sink still runs` |
| AC-3 empty tier falls through | met | `an unconsumed event descends every tier to the sink`; `the default callback neither edits nor consumes` |
| AC-4 consume ≠ remove (R13) | met | `consuming never removes a tier (R13)` |
| AC-5 assign replaces only that callback | met | `assigning a callback replaces only it; sink still runs` |
| AC-6 three per-event tables (R14) | met | `the combo tables are per-event, not one flat table` |
| AC-7 normalise on assignment | met | `a keypressed combo fires on the normalised combo` (`Ctrl+S`→`ctrl+s`) + textinput/keyreleased rows |
| AC-8 uniform sigs + read-only proxy | met | `keypressed carries (k, keys_pressed, isrepeat)`; `the keys_pressed proxy is read-only`; `the sink receives the uniform keypressed triple` |
| AC-9 keyreleased key already gone | met | `a keyreleased participant sees the key already gone` |
| AC-10 default noop + debug log | met | `the default callback neither edits nor consumes` |
| AC-11 / AC-13 no participant + hidden = no mutation | met | `no participant + hidden widget mutates nothing` |
| AC-31 native = default participant, seen while shown, precedence | met | `a native fires whether or not the widget is shown`; `an explicit on_* takes precedence over the native` |
| AC-33 mutable boundary guard | met (incremental allowlist) | `assigning an unknown slot raises`; `assigning an allowed callback slot is accepted` |
| AC-36 four cases × both paths × 3 channels + precedence | met | native: `…fires whether or not…`, `…truthy intercepts the sink`, `a falsey native textinput falls through…`, `a native keyreleased fires while the widget is shown`; on_*: `a truthy on_text_input intercepts; falsey reaches sink`; precedence: `an explicit on_* takes precedence…` |
| AC-38 signature/proxy + full tier-1→4 travel | met | `a framework handler consumes before lower tiers`; `an unconsumed event descends every tier to the sink`; `isrepeat threads to the tier-3 callback`; proxy row |
| AC-40 on_text_input (per-char) vs on_text_entered | met (input) / deferred (entered) | `on_text_input fires per character as text arrives`; `on_text_entered` → pending `on_text_entered delivers the submitted text` (**submit/cancel chunk**) |
| AC-41 combo dispatch, 3 channels | met | the three `…combo fires on the normalised combo` rows |

**Explicitly deferred (later chunks, marked so, not faked):** AC-12 full editing set, AC-14 R12
surfacing via widget outputs (structurally held — sink return discarded), AC-15/16 widget outputs
(chunk 2), AC-17..26 submit/cancel + `on_text_entered` (chunk 3), AC-27..30 route-connection
lifecycle & AC-29 teardown (chunk 4), AC-32 turtle/maze migration (chunk 5), AC-42 highlighter/
validator functional application (chunk 2), AC-39/AC-43 legacy-solicitation retirement lifecycle
(the `#deprecated` rows stay green here — `oneshot`/`push('userinput')` deletion is AC-25 / chunk 3).

## Per-pinned-remark disposition

| Remark | Disposition | Note |
|---|---|---|
| U1 / P8 / P10 (SCOPE) | fixed | end-to-end chain visible + testable (`#m5c` block); keypressed handlers + truthy chain (P8); textinput same chain via `on_text_input` (P10) |
| C4 / P2 (SCOPE) | fixed | project wiring is `compy.input.*`; the sink is reached via `love.state.user_input_controller`, not cross-layer `ui.C` from the route |
| C12 (SCOPE) | note-only | the combo tier now exists, but the framework's own debug Ctrl+Shift shortcuts live in the **console-route gateway** (`set_love_keypressed`), outside the project-route rebuild — table-driving them is a follow-on, not chunk-1 scope |
| U3 (SCOPE) | fixed | keyreleased routing landed + documented (routing doc updated to the four-tier model) |
| U2a (SCOPE) | note-only | console still checks `love.state.user_input`; console migration is the named follow-on |
| C1 / C15 / P3 | dissolved-by-rework | the M4 `sink_keypressed` silent swallow is gone; the chain always reaches the sink or debug-logs at the empty tier |
| C2 / C5 / C16 / P11 | fixed | table-driven per-channel dispatch (`CHANNELS` + `_dispatch`); no per-event divergent blocks; `native_split`/`occupy`-era naming removed from the pic |
| C3 / C14 | fixed | return propagation is the chain contract; `chain_native` propagates the native's return (was swallowed) |
| C9 / C13 | fixed | dispatch legibility — one readable `_dispatch`, no C-accent string-tag dispatch |
| C23 | note-only (kept, test-scoped) | `active_keyboard_route()` retained — consumed by `src/tests/autotest.lua` + the `stop names…` row; not dropped |
| T2 | fixed | new-block comments cite spec §/AC ids, not session lore |
| T3 / T4 | fixed | live assertions: downstream propagation-without-swallowing (fall-through rows) + same `keys_pressed` proxy end-to-end |
| C19 / C20 | note-only | `set_love_*` table+iterator TODO and the `love.handlers` section comment are console-route/gateway hygiene, outside the project-route rebuild — deferred to the console migration |

## Suite `-- REVIEW:` reconciliation ledger

Reconciled (in rows re-derived/removed this chunk):

- Bucket-D `a release under a widget…` REVIEWs (L588/L599-era) — **row deleted**; superseded by the
  AC-36 keyreleased rows (Scope-10(c)). A pointer note replaces it.
- Bucket-B `project keys reach the project sink`, `a native handler coexists with the sink`, `the
  keypressed path carries the triple` REVIEWs — **rows removed/replaced** by the `#m5c` block;
  their green replacements cover the surviving behaviour (AC-43 replacement-proven-green).
- `stop names the console…` REVIEWs — retained with the row (C23 test-scoped); the RESOLVED note
  now points at AC-29/route-lifecycle chunk.

Left in place (rows this chunk did **not** re-derive — commission scope is "rows you touch"):

- L498-500 (`a hidden widget does not consume`) — the concern (console secretly processing input
  while a project is active) **is** answered by this chunk's model: during a run the pic is the
  active route and the sink no-ops when hidden — the console is never reached. The kept rows assert
  the **ready-mode** case (console *is* the active route), which is correct; row not re-derived, so
  the comment stays.
- L526 (editor block-nav relocate), L618/L648/L660 (Bucket-C mechanism guards) — untouched
  mechanism/editor rows; out of chunk-1 scope.

No REVIEW was silently deleted; none left dangling in a row this chunk re-derived.

## `>> REVIEW`-marker removal ledger

- **Project tree (`src/`):** no `>> REVIEW` markers existed. The inline `-- REVIEW:` markers in
  `projectInputController.lua` (L33/42/47/51/71/93/115/120/131/147) are **all removed** — the
  file was rebuilt as the unified chain the markers demanded (guardrail 4). The `forward_*`
  `-- REVIEW:` markers in `controller.lua` are removed (forward now hands the proxy and the
  return-propagation question is answered by the chain). Remaining `-- REVIEW:` in `controller.lua`
  are on console-route / route-lifecycle / gateway code this chunk does not rebuild — left in place.
- **Routing doc (`internals/user_input.md`):** the project-route `>> REVIEW` markers (the "widget
  swallows keypressed" flow-design marker and the keyreleased "else falls to" marker) are
  **removed** — the four-tier chain implements exactly the flow they asked for (resolving line cited
  in the doc). The console-route/gateway `>> REVIEW START…END` block stays (not this chunk's rebuild).

## Surfaced gaps / tech debt (report-don't-fix)

- **`combo_string` trigger casing** (edge): upper-case textinput combos won't match normalised
  lower-case registrations. Textinput combos are rarely useful (spec §2); flagged, not fixed.
- **`keys_pressed` proxy `pairs`** under LuaJIT/5.1 yields nothing (no `__pairs`); read + write-raise
  hold. If a consumer ever needs to iterate the held set on this host, revisit (a snapshot copy
  would trade the "same table end-to-end" property for iterability).
- **AC-29 full teardown** (participants unwired on stop) is **not** implemented here (route-lifecycle
  chunk). `F.reset()` clears the project route at fixture scope so tests are isolated; production
  teardown of `compy.input.handlers`/`on_*` lands with the route-connection chunk.
- **C12 / C19 / C20 / U2a** console-route hygiene deferred to the console migration (dispositions
  above).

## Escalation stops

**None.** No in-slice design ruling was made; every decision cites the corpus (above). No spec gap
or corpus contradiction required a stop.
