# Sonnet worker prompt — R3 fold-in + wip-reference sweep (persistent-corpus consolidation)

You are a Sonnet worker under the session18 orchestrator, feat #77, LÖVE2D at `/repo` (cwd `/repo`).
**Docs-only task** — do NOT touch any `.lua` under `src/`, and in tests touch ONLY comments (never
an assertion or any code). Purpose: make the **persistent** doc corpus self-contained, because the
whole `doc/development/wip/77-new-input-api/` tree (all `delta-*`, `validation/*`, session dirs) is
**deleted before the PR and not included in it** — so every reference from a persistent doc or a test
into `wip/` will dangle. Two jobs: (A) fold the ratified redesign into `decisions/input.md`; (B)
repoint every wip-reference in persistent docs + tests to a persistent home.

## Standing rules (you do NOT inherit repo CLAUDE.md)
- (a) `lua-lsp` MCP exists but is not needed here (docs). 
- (b) Follow this spec exactly; do not invent design. If a source and the target genuinely conflict,
  STOP and report rather than guessing.
- (c) Write a deliverable to `doc/development/wip/77-new-input-api/validation/outcomes/S18-r3-foldin.md`
  (what you changed per file, and the final ref-sweep grep proof). Do NOT commit.
- After edits, run `busted tests` — must stay **841 / 0 / 0 / 4** (you're only touching doc prose and
  test *comments*; any count change means you touched code — STOP and report).

## Sources (read fully first)
- `doc/development/wip/77-new-input-api/validation/reviews/delta-design-input-api.md` — the ratified
  decision-level redesign, **written in `decisions/input.md`'s own voice specifically to fold in
  verbatim**. It revises Decisions 2, 5, 6, 7, 10, touches 8, and adds a vocabulary table + an
  implementation note (dispatch free function + `build_widget_api` factory).
- `doc/development/wip/77-new-input-api/validation/reviews/delta-spec-input-api.md` — mechanism detail
  (already reflected in `internals/user_input.md`; use it only to get names/signatures right).
- `doc/development/wip/77-new-input-api/validation/reviews/S18-uic-fork-options.md` +
  `.../validation/outcomes/S18-optionE-execution.md` — the option-E refinement (the `app_state` fork
  was removed 2026-07-21; `submit_flow`/`cancel_flow`; editor consumes lifecycle keys upstream via
  `block_input()`; `modify` gated on the `allow_modify` constructor flag). Fold this into Decision 6.

## JOB A — fold the redesign into `doc/development/decisions/input.md`
This file currently still describes the OLD (pre-redesign) design as current (four-tier chain, sink,
singleton, framework-tier submit/cancel, tier-3 native wrapping). Update it to the SHIPPED design by
folding in the delta-design, decision by decision. Keep the numbering 1-13; replace the *body* of
each revised decision with its delta-design "revised/touched" form, in the same Decision/Why/
Consequence voice already used. Specifically:

- **Decision 2** (`:56`, "four-tier dispatch chain") → the three-component chain
  `shortcuts[event][combo] → hooks[event] → widget` with truthy-consume; **no framework tier**
  (tier-1 deleted). Retitle away from "four-tier".
- **Decision 5** (`:125`) → keep its substance; fold in the one relocation: the `keypressed` return
  value no longer carries a vertical-limit flag — `on_limit_reached` is the sole channel.
- **Decision 6** (`:155`, "framework-tier submit/cancel") → submit and cancel are the **widget's own
  callback-driven flows**, not a framework tier: `submit_flow` (Enter-without-Shift) and `cancel_flow`
  (Escape-without-Ctrl); stays-open default (`after_submit`/`after_cancel` default to no-op);
  `before_cancel` may veto; Enter/Escape are shadowable by a project shortcut. **Then fold in the
  option-E refinement:** `UserInputController:keypressed` runs one uniform path (no
  `love.state.app_state` branch); a context that must not run the flows arranges it itself — the
  editor consumes Enter/Escape upstream (`block_input()` in its own `submit()`/`load()`), console sets
  no callbacks (no-op), the overlay runs them for real. The editor-only Ctrl+D duplicate-line
  (`modify`) is a per-instance `allow_modify` **constructor flag**, not a mode read. Retitle away from
  "framework-tier". Note the withdrawn guarantee (nothing-stops-Enter/Escape) is deliberate; the
  gateway power keys remain the real escape hatch.
- **Decision 7** (`:192`) → freeze the container and the identity of its three sub-tables
  (`shortcuts`/`hooks`/`callbacks`); leaves are writable. `callbacks` has eight members (the five
  lifecycle + `on_limit_reached` + `validator` + `highlighter`) under "a callback is any function the
  widget itself invokes". Replaces the old 11-name allowlist.
- **Decision 8** (`:208`) → substance unchanged; the combo table is named **`shortcuts`** (was
  `handlers` — renamed to avoid colliding with LÖVE's own `love.handlers`).
- **Decision 10** (`:246`, "tier-3 native wrapping") → one `hooks[event]` table, seeded once at
  activation from any captured native `love.*` handler; no per-event precedence re-resolution, no
  resurrection-on-nil. Retitle away from "tier-3".

Also in `decisions/input.md`:
- **Vocabulary sweep** per the delta-design's vocabulary table: retire `sink`, `singleton`, `tier`/
  four-tier/tier-3/tier-4, `framework handler(s)`, `generic callback`, `proxy` (→ "read-only
  pressed-keys view"), and `handlers` (the combo table → `shortcuts`) **as current-tense terms**. Use
  the shipped vocabulary (`shortcuts`/`hooks`/`callbacks`/`widget`) throughout. Where the old term is
  named to say it was retired, use explicit past-tense framing ("was … ; now …").
- **Implementation note** (from the delta-design's non-normative note): add a short subsection
  recording that `dispatch` is a free function over `(shortcuts, hooks, widget, event, trigger, ...)`
  and `build_widget_api(get_widget, get_active_flag)` is an instance-parameterized factory — both pure
  refactors enabling future console/editor reuse; migration itself deferred (Decision 1).
- **Insert the new Decision 14 VERBATIM** (text below), after Decision 13.
- **Reconcile the "Where the shipped system differs from the design intent" section** (`:341`) only
  where a listed deviation is now plainly resolved by the redesign — if unsure whether a row still
  stands, LEAVE IT and note it in your deliverable for the orchestrator to judge. Do not invent new
  deviation rows.
- Update the top-of-file framing if it calls the design "four-tier" or otherwise stale.

### Decision 14 — insert this text verbatim (after Decision 13)

```
## Decision 14 — de-facto contracts: reverse-engineered behaviour is preserved and formalised, not silently changed

**Decision.** Where post-implementation validation of this subsystem discovered behaviour that no
design document mandated — behaviour that fell out of how the code was built rather than from a
ruling — the standing rule is to **preserve it and record it as a contract**, not to "fix" it in
passing. Such behaviour is treated as a **de-facto standard set by the implementation**; documenting
and test-pinning it makes the implicit explicit. Changing any of it is a **separate, owner-gated
decision**, never a side effect of a refactor or cleanup.

**Why.** This subsystem reached its shipped shape partly by accretion — successive consumers (the
project overlay, console, editor, inspect) were integrated by local additions rather than by
extending a shared abstraction, so real, live behaviours existed that no decision named.
Reverse-engineering during validation surfaced them. Altering them opportunistically while "tidying"
would smuggle behaviour changes in under the banner of cleanup — the exact failure mode this
validation phase exists to prevent. Freezing and documenting them instead cleanly separates *what the
system does* (now pinned and reviewable) from *what we choose to change* (explicit rulings).

**Consequence.** Doc entries and tests that record a reverse-engineered behaviour carry this rationale
explicitly ("discovered as existing behaviour, no mandate to alter — de-facto standard per the
implementation"). Current members include: the submit guard being *Enter-without-Shift* (so Ctrl+Enter
and Alt+Enter submit, not only bare Enter); `SearchController:keypressed` returning a jump target up
its caller; and the overlay input view's per-frame-render workaround keyed by widget identity. Each is
individually revisable — but only by a named ruling, not by drift. See
[`../technical_debt/input.md`](../technical_debt/input.md) for the live list.
```

## JOB B — repoint every wip-reference in persistent docs + tests
After Job A, `decisions/input.md` holds the shipped decisions, so references can resolve there. Sweep
these files and repoint every reference that points into `wip/` (paths containing `wip/77`,
`validation/reviews/`, `validation/outcomes/`, `delta-spec`, `delta-design`) or uses ephemeral
process vocabulary ("option E", "unit N", "Pre-unit-3", "S18", "Phase R4", "delta-spec §N"):

Files: `doc/development/internals/user_input.md`, `doc/development/technical_debt/input.md`,
`doc/development/internals/project_sandbox_env.md`, `doc/input_api.md`, and the **comments only** in
`tests/input/input_lifecycle_unfork_spec.lua`, `tests/input/input_redesign_ac_spec.lua`,
`tests/input/input_widgets_callbacks_spec.lua`, `tests/input/input_routing_spec.lua`.

Repointing rules:
- `validation/reviews/delta-spec-input-api.md §N` and `delta-design-input-api.md` and `Decision N
  revised` → `doc/development/decisions/input.md` **Decision N** (now folded in) for the *why*, and/or
  `doc/development/internals/user_input.md` for mechanism. Pick whichever the sentence is actually
  citing (rationale → decisions; mechanism → internals).
- `validation/reviews/S18-uic-fork-options.md` / "option E" (rationale for the un-fork) →
  `decisions/input.md` Decision 6 (and Decision 14 for the de-facto framing).
- `delta-spec §7` / "AC N" acceptance-criteria citations in tests → the tests already ARE the ACs;
  replace a wip path with a plain-English description or a pointer to `decisions/input.md`/
  `internals/user_input.md`. Do not delete the test's own intent comment.
- Ephemeral process words ("option E", "unit 3", "Pre-unit-3", "S18", "the worker") → rephrase to
  timeless persistent framing (e.g. "the un-fork", "the redesign"), or drop, so the comment reads
  correctly to someone who never saw the `wip/` process.
- `{badspecref: …}` markers and `commit 7b4422c`-style pointers may stay (they're existing markers,
  not wip-tree paths) — leave them.
- If a reference genuinely has no persistent home even after Job A, STOP and report it (do not invent
  one).

Do NOT touch `wip/` files themselves (they are frozen records), except your own deliverable.

## Final
Deliverable + `busted tests` count (must be 841/0/0/4) + a grep proving zero `wip/77` / `delta-spec` /
`delta-design` / `validation/reviews` / `option E` references remain in the persistent docs + tests
listed above. Report any deviation row you were unsure about, and any ref with no persistent home.
