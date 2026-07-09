# Implement — M5c-01: the dispatch chain (chunk 1 of the M5c carve)

_Commissioned by the opus-sweeper PM (`agents/sweep.md`), session02, 2026-07-07, under
[`M5c-M8-sweep-mandate.md`](M5c-M8-sweep-mandate.md). This is **chunk 1** of the M5c carve — the
core four-tier dispatch chain. It is **not** the whole slice: submit/cancel, widget outputs, the
route-connection lifecycle changes, and the turtle/maze migration are **later chunks** (see
Boundaries). Target executor: **Claude Sonnet**, in the M0 dev image._
_Approved by human?: **PENDING** (pre-run prompt gate — the PM presents this file before executing)._

## You are

A one-shot implementation agent in the **compy** LÖVE2D codebase (this repo, root = your cwd),
running the **dev charter** (`agents/dev.md`). You implement **exactly this chunk**, test-first,
commit locally (Conventional Commits, no push, this repo only), record the outcome ledger, then
**present a summary and wait for the human to approve** — do **not** blindly exit; he may contest
and demand fixes. Mid-chunk, if you hit a genuine **spec gap, corpus contradiction, or any
in-slice design decision, STOP and report it as an escalation** (mandate guardrail 1 — an in-slice
design ruling is a gate failure). You resolve scope by the authority chain, never by inventing.

## What this chunk delivers (scope — Scope items 1, 2, 6[native-mechanism], 7)

The **complete four-tier dispatch chain** on all three keyboard/text channels in the project
route, replacing the M4-landed routing. After this chunk, a keyboard/text event in the project
route traverses, in order:

```
framework_handlers.<event>[combo]      (tier 1 — slot exists; return/escape entries are chunk 3)
  → compy.input.handlers.<event>[combo] (tier 2 — per-event sub-tables, R14; normalising assign)
    → per-event generic callback         (tier 3 — on_key_pressed / on_text_input / on_key_released)
      → the sink (widget)                (tier 4 — terminal; INTERNAL hidden-check, no gating wrapper)
```

Truthy return at any tier **consumes** (stop, sink included); falsey **falls through**; consuming
**never removes** a tier (R13). `keyreleased` runs the **same shape** (ruling 4). This chunk
**deletes** the M4 `native_split` if-governed wrapper and the external gating wrapper, and rebuilds
`ProjectInputController` as the unified chain — directly resolving its pinned `-- REVIEW:` markers.

**In scope for this chunk (ACs it must satisfy):**

- **AC-1…AC-5** — the chain order; truthy-consumes / falsey-falls-through / consume≠remove;
  assigning a generic callback replaces only that callback, sink still runs for unconsumed events.
- **AC-6, AC-7** — combo handlers in **three per-event sub-tables** (`handlers.keypressed`,
  `.keyreleased`, `.textinput`); **no flat combined table** (R14); keys **normalise on assignment**
  (`'Ctrl+S'` stored/matched as `'ctrl+s'`, modifier-first, l/r folded, `+`-joined). Overloadable
  matcher lives in the serialisation surface (`spec.md` §1; `src/util/key.lua` if it lands there).
- **AC-8, AC-9** — uniform signatures at **every** tier incl. sink: keypressed `(k, keys_pressed,
  isrepeat)`, textinput `(text, keys_pressed)`, keyreleased `(k, keys_pressed)`; `keys_pressed` is a
  **read-only proxy** (`__newindex` raises). `keyreleased` consumers see the key **already absent**
  from `keys_pressed`.
- **AC-10** — default generic callbacks are **noop + debug log**; they never edit text, never consume.
- **AC-11, AC-13** — event with no participant (widget hidden, no handlers, default callbacks) falls
  through every tier to the sink's **internal** no-op: debug-log only, **nothing mutates** (no model,
  view, history, cursor, selection). The hidden-check is **inside the sink**, not an external gate.
- **AC-31, AC-36 (both install paths + precedence), AC-38** — tier-3 is populated by **one of two
  mutually-exclusive paths**: a direct `compy.input.on_*` assignment, **or** — only when no `on_*`
  is set — a legacy `love.*` native **captured once at load** as the default participant (R7 pure
  wrap). **Precedence, not replace**: explicit `on_*` > captured native > noop; the native seeds
  tier-3 only when no `on_*`, never overrides one, and `love.*` is read **once at load** (reassigning
  it after load does nothing). For **whichever** populates the slot, on **each** channel: (a) invoked
  **regardless of widget-shown state**; (b) truthy **intercepts** (sink skipped); (c) present-but-
  falsey **falls through** to the sink; (d) no project callback (default noop) ≡ non-intercepting.
  **AC-38 travel:** a tier-1 framework handler consumes before lower tiers (assert via a **test**
  framework handler — the real return/escape entries are chunk 3); an unconsumed event descends
  tier-1→4 to the sink; truthy at any tier stops descent. `isrepeat` asserted **passed through to
  tier 3** only; whether combo tiers fire on repeat is **DEFERRED (0.1.0-m5)** — leave an in-code
  marker, do **not** assert, do **not** design a mechanism for it.
- **AC-33 (mutable boundary — the guard mechanism + this chunk's slots)** — assigning anything on
  `compy.input` other than the allowed slots **raises a loud error** (never a silent swallow, C2).
  This chunk installs the guard covering the slots that exist **as of chunk 1**: the `handlers.*`
  sub-tables and `on_key_pressed`/`on_text_input`/`on_key_released`. **Later chunks extend the
  allowlist** as they introduce `before_*`/`after_*` and the widget-output fields — note this
  explicitly in the ledger (it is an intentional incremental, not a partial AC).
- **AC-40** — `on_text_input` is the **tier-3 textinput** callback (per-character, `(text,
  keys_pressed)`); it is **distinct** from `on_text_entered` (the submit output — **chunk 3**, do
  NOT build it here). The landed pending row `on_key_pressed and on_text_entered exist` (L829) is
  re-drafted so its `on_text_input` half is a real per-char tier-3 assertion; the `on_text_entered`
  half stays **pending** (chunk 3 owns it) — mark it so, do not fake it.
- **AC-41** — the pending `combo handlers dispatch on the combo` row (L871), drafted with the
  R14-**forbidden flat** table, is **expanded to three rows**, one per per-event sub-table, each
  asserting dispatch on the normalised combo (AC-6/AC-7).

## Read first (authority chain — all frozen/ratified)

1. **`doc/development/wip/77-new-input-api/design/spec/M5c-dispatch-chain.md`** — the slice. Your
   authority. Read **Scope 1, 2, 6, 7, 10**, the pinned SCOPE table, and **AC-1…AC-11, AC-31, AC-33,
   AC-36, AC-38, AC-40, AC-41** verbatim. Your red rows transcribe these; your ledger cites them by id.
2. **`design/notes/ratified-model.md`** — canonical; **on any divergence it wins**. Glossary is
   **binding** — mint no architectural nouns outside it (route / chain / tier / sink / widget /
   participant / slot). Anchors: **R7** (native pure wrap / precedence), **R12** (sink return carries
   no chain meaning), **R13** (consume ≠ remove; no replace-semantics), **R14** (per-event sub-tables).
3. **`design/spec.md` §1 (keys_pressed + combo serialisation/proxy), §2 (four-tier chain +
   per-channel signatures + the DEFERRED repeat note), §7 (mutable boundary), §8 (native pure-wrap
   R7).** The §2 signature table is the contract for AC-8.
4. **`agents/rules.md` + `agents/development.md`** (auto-loaded) — hard limits (line ≤64, fn body ≤14,
   params ≤4, nesting ≤4), **no string-tag dispatch**, KISS, **tests-first**, report-don't-fix,
   Conventional Commits, no push.
5. **`notes/input-contracts.md` (doc A)** — current-behaviour contracts; cite by `§N`.
6. **The live code you rewrite** (M4-landed to a *superseded* spec — expect to delete/reshape):
   - `src/controller/projectInputController.lua` — the M4 `sink_keypressed` / `native_split` /
     per-event-divergent methods. **This chunk rebuilds it as the unified chain.** Its `-- REVIEW:`
     markers (L33/42/47/51/71/93/115/120/131/147) are **design inputs** demanding exactly this
     unification (guardrail 4) — resolve each with a ledger line citing the contract point.
   - `src/controller/controller.lua` — `set_love_keypressed/keyreleased/textinput` (L300–363),
     `forward_*` helpers (L34–54), `occupy_keyboard`/`set_handlers` (L156–216), `setup_callback_handlers`
     (L677), `active_keyboard_route` (L937). The tier-1 `framework_handlers` slot lives here.
   - `src/model/input/userInputModel.lua`, `src/view/input/userInputView.lua` — the sink (widget);
     you touch these only to make the sink honour uniform signatures + the internal hidden-check.
     **Do not** remove `oneshot` or touch submit internals (chunk 3).
   - `src/util/key.lua` — combo normalisation/matcher, if it lands there.
   - `tests/input/input_contracts_spec.lua` (893 lines) — the contract suite you evolve.
7. **`implementation/outcomes/M4.md`** — what M4 built and **why it is being reshaped** (the day-one
   suppress-while-shown mutation E29 reversed; the `active_keyboard_route` accessor is C23 —
   test-scoped unless a real consumer lands, drop it if none).

## Do — in this order

1. **Red suite first (test-first — mandate + `agents/process.md` §9.2).** Under `tests/input/`,
   transcribe the in-scope ACs into acceptance rows and **convert the relevant pending/landed rows**;
   run them **red for the right reasons** before implementing:
   - Convert `pending` rows to live: the chain/callback/combo forwards in the m5/m5a/m5b families
     that this chunk's ACs cover (`on_key_pressed`/`on_text_input` tier-3, combo dispatch AC-41,
     signature/proxy travel AC-38). Rows whose behaviour is a **later chunk** stay pending
     (`on_text_entered`, submit/cancel, widget outputs, route-restore) — do not green them here.
   - **Re-derive the M4-landed green Bucket-B interception rows to AC-36 (Scope 10) — do NOT
     preserve them.** `a native handler coexists with the sink` (L775) currently green-asserts the
     **reversed suppress-while-shown** mutation (`-- STALE (E29 …)` L767) — **flip it** to AC-31/AC-36:
     the tier-3 participant (native or `on_*`) is invoked **regardless of widget-shown state** and a
     falsey return **falls through to the sink**. Assert the **four cases** (a/b/c/d) on **each**
     channel and **both** install paths, plus the **precedence** (both defined ⇒ `on_*` wins, native
     never seeds). Rename rows to the generic-callback vocabulary. **No green row anywhere may still
     encode replace/suppress semantics** (R13) — this is the chief semantic trap of the slice.
   - **AC-37 reconciliation (this chunk's rows only):** every `-- REVIEW:` comment in the suite rows
     you touch is reconciled — removed with a ledger line citing the AC it resolves to, **or**
     escalated as a stop if it names a genuine contradiction. None silently deleted, none left dangling.
2. **Build the chain (AC-1…AC-11).** Rebuild `ProjectInputController` as the four-tier dispatch on
   all three channels: per-event `handlers.<event>[combo]` sub-tables (R14 — **flat table
   forbidden**) with normalising assignment (AC-6/7); per-event generic callback (default **noop +
   debug log**); the sink as the terminal tier with an **internal** hidden-check (delete the external
   gating wrapper). Truthy at any tier = consumed/stop; falsey = fall through; **consuming never
   removes a tier** (R13). Uniform signatures per channel + read-only `keys_pressed` **proxy** (AC-8);
   `keyreleased` same shape, key already removed (AC-9). **No replace-semantics (R13); the sink's
   return carries no chain meaning (R12).** Prefer a **table-driven** per-channel setup over three
   near-duplicate blocks (resolves C5/C16/P11; C12 debug-combos table-driven).
3. **Tier-3 both install paths + precedence (AC-31/AC-36/R7).** `compy.input.on_*` direct assignment
   populates tier-3. A project's native `love.keypressed`/`textinput`/`keyreleased` is **captured
   once at load** as the tier-3 **default participant** — **only when no `on_*` is set** (precedence).
   **Delete `native_split`** and the lifecycle-split branch. The native is a plain participant seeing
   events even while the widget is shown; falsey falls to the sink. There is **no "replace the wrapped
   native"** relationship. *(Optional, only if trivially ~3 lines and NO test: `Log.warn` when both a
   native and an `on_*` are defined for a channel. Marginal — skip if not trivial.)*
4. **Mutable boundary guard (AC-33).** Install the loud-error-on-unknown-assignment guard on
   `compy.input`, allowlisting this chunk's slots (`handlers.*` + the three `on_*`). Record in the
   ledger that later chunks extend the allowlist.
5. **QUALITY dispositions (Scope 8, the remarks this chunk touches).** Give each an explicit
   disposition (`fixed` / `dissolved-by-rework` / `note-only`, with remark id) in the ledger:
   **C1/C15/P3** warn-on-silent-drop; **C2/C5/C16/P11** naming + per-event de-dup (table-driven);
   **C3/C14** return-propagation (now the chain contract); **C9/C13** dispatch legibility; **C12**
   debug Ctrl+Shift → table-driven combos; **U3** keyreleased routing landed+documented; **C23**
   `active_keyboard_route` → test-scoped or dropped (no unconsumed public surface); **T2/T3/T4** suite
   comments cite doc A/spec + live assertions; **U1/P8/P10** (SCOPE) end-to-end chain visible/testable.
   Remarks whose home is a later chunk (submit/cancel, widget outputs, route lifecycle, migration)
   are **note-only here** with a pointer to the owning chunk.
6. **`>> REVIEW` markers (project tree).** Remove those in `projectInputController.lua` /
   `controller.lua` that **this chunk's rebuild resolves**, each with a ledger line citing the
   resolving contract point. Markers this chunk does not resolve stay in place.
7. **Repeat semantics — park, do not invent (spec §2 DEFERRED 0.1.0-m5).** Ship the pre-authorised
   default (combos keep current behaviour; `on_key_pressed` sees repeats via `isrepeat`); leave an
   in-code `DEFERRED (0.1.0-m5)` marker. Not a new ruling — do not escalate, do not design.
8. **Run the full suite** (`busted tests` or `just ut_all`). This chunk's ACs green; later-chunk rows
   still pending; **everything else green** (no red at the chunk boundary — AC-35 discipline). If a
   row you retired would stand red, route it through the lifecycle (`#deprecated` → pending), never
   loosen a green row.
9. **Manual check (record exactly what you exercised; if you cannot run a mode, say so).** At minimum
   the project-route dispatch: a combo handler fires; a `on_key_pressed` returning truthy intercepts
   (sink skipped) and returning falsey falls through; a native handler participates while the widget is
   shown; hidden widget mutates nothing. (Full 4-mode + ruling-3 + turtle/maze hand-play are the
   later closeout chunk — not required here.)
10. **Commit locally** — Conventional Commits (`feat(input):`), independently revertible commits,
    pre-commit hook green, **in-repo files only**. No `src/examples/*` migration in this chunk.

## Record the outcome — `implementation/outcomes/M5c-01-dispatch-chain.md`

Open with the mandatory **"what will surprise the architect"** section (guardrail 3 — deviations,
reconciliations, new names, new public surface, the M4-code reshape, the AC-33-incremental note),
**before** the file list. Then: commit refs · files changed · verification (**real** busted counts;
the manual-check record) · **per-AC checklist** for every in-scope AC (each `met` with the test
name, or the stop that blocked it; later-chunk ACs marked deferred-to-chunk-N) · the **per-pinned-
remark disposition table** · the **suite `-- REVIEW:` reconciliation ledger** (this chunk's rows) ·
the **`>> REVIEW`-marker removal ledger** · surfaced gaps or "none". **Every non-obvious decision
bullet cites its source** (`M5c-dispatch-chain.md §…` / `spec.md §…` / `ratified-model.md` /
ruling/remark id) — **uncitable = a judgment call = you should have stopped** (guardrail 2).

## Approval loop

Present a short summary and **stop for human review**. Revise on contest; done only when the human
explicitly approves. Mid-chunk stops (decide **with** the human, never paper over): scope ambiguity,
a spec gap, an irreversible choice, the suite won't converge, or a `-- REVIEW:` comment that names a
real contradiction with the ratified model.

## Boundaries — what is NOT in this chunk

- **No submit/cancel** (Scope 3 → chunk 3): do **not** build `on_text_entered`, the `before_/after_`
  chains, the validator gate, Escape-dismiss, or delete `oneshot`/`push('userinput')`. Enter/Escape
  reach the sink and keep their **current** widget behaviour for now.
- **No widget outputs** (Scope 4 → chunk 2): `on_limit_reached`, `validator`, `highlighter`,
  `on_text_entered` config-key/field — none here.
- **No route-connection lifecycle changes** (Scope 5 → chunk 4): keep the existing activate/deactivate
  + `app_state` handling as-is; do **not** remove the M4 ruling-1 forwarding or rework stop-teardown
  here. You rebuild **what the chain does when consuming**, not **when the route is connected**.
  (You *do* rewrite `activate` enough to wire native-capture-as-tier-3 — that is the tier-3 mechanism,
  not the route-lifecycle change.)
- **No example migration** (Scope 6 examples → chunk 5): do **not** touch `src/examples/*`. Never
  commit inside a nested checkout or touch its `.git` (guardrail 7).
- **No M7/M8 work.** Do not "unify" the pointer disconnect into the keyboard/text scope (forbidden,
  spec §8). Stay within the Files list; on overreach, **stop** and record it under gaps.
- **Never edit `doc/development/wip/77-new-input-api/design/`** — frozen input you read.
- **Do not re-green the M4 suppress-while-shown assertion — flip it** (AC-31/AC-36).
