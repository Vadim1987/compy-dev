# R4/U4 — vocabulary sweep + example migration + docs (Sonnet worker prompt of record)

**Model:** sonnet (explicit). **Phase:** #77 input-API redesign, Phase R4, final unit U4.
**Nature:** mostly-mechanical sweep + doc updates against an ALREADY-SETTLED model. The
behavioral redesign (U1-U3) is landed and committed; the suite is green at **827 successes /
0 failures / 0 errors / 4 pending**. Your job is to make the comments, examples, and docs
consistent with the shipped code — NOT to change any behavior. **The suite must stay green
(827/0/0/4) throughout; run `busted tests` after each sub-step.**

## Standing hygiene (you do NOT inherit repo CLAUDE.md — stated explicitly)
- **lua-lsp MCP server is available** (`mcp__lua-lsp__references`/`definition`/`diagnostics`).
  Use it for the gate (proving zero references to retired code symbols). `sleep 1` after any
  `.lua` edit before querying it (it re-indexes).
- Materialize your report at the path in "Deliverable".
- Work serially in the shared /repo tree; do not create worktrees.

## Authoritative sources (READ FIRST, in full — mirror these; do NOT invent)
- `doc/development/wip/77-new-input-api/validation/reviews/delta-design-input-api.md`
  (Decisions D2/D5/D6/D7/D10 revised + the **Vocabulary table** + the "Migration hazard" note)
- `doc/development/wip/77-new-input-api/validation/reviews/delta-spec-input-api.md` (§1-§6)
- `doc/development/wip/77-new-input-api/validation/reviews/R4-U3-callback-model.md` (the
  owner-ruled final model: dumb route, widget-owned submit/cancel, callbacks IS the widget's
  own table, internal `shown` flag, love.state.user_input kept only as the draw handle)
- The shipped code: `src/controller/{projectInputController,userInputController,
  consoleController,controller,editorController}.lua`, `src/main.lua`.

## The shipped model in one paragraph (so you can spot stale prose)
The project route is a DUMB 3-consumer walk: `shortcuts[event][combo] → hooks[event] →
widget`, stopping at the first truthy; the widget consumes whenever `is_shown()`. There is NO
framework tier, NO "sink", NO "tier-1/2/3/4". Submit/cancel are the WIDGET's own default
behaviour (Enter→`_submit_default`, Escape→`_cancel_default`) signalled via `self.callbacks`;
auto-close is OFF by default (widget stays open); `before_cancel` may veto; Enter/Escape are
shadowable by a shortcut. `compy.input.callbacks` IS the overlay widget's own `self.callbacks`
table (same object). `is_shown()` is a strictly internal `self.shown` flag (no love.state
reach); `love.state.user_input` remains ONLY as the {M,C,V} draw handle / paint gate.

## Sub-step 1 — Migrate the tracked examples (BEHAVIORAL, not just rename)
Files: `src/examples/guess/main.lua`, `src/examples/tixy/main.lua`,
`src/examples/valid/main.lua`, `src/examples/repl/main.lua`. **Do NOT touch**
`src/examples/balloons/*` or `src/examples/maze/*` (untracked/sanctioned scratch).
Two changes per example:
- **(a) Surface rename (leaf-writes only):** `compy.input.after_submit = fn` →
  `compy.input.callbacks.after_submit = fn` (same for before/after_cancel, on_text_entered,
  on_limit_reached, validator, highlighter when written as DIRECT FIELD ASSIGNMENTS). **Do
  NOT** rename config-table keys inside `compy.input.show{ ... }` / `configure{ ... }` — those
  stay flat (e.g. `show{ on_text_entered = fn }` is unchanged; the surface bridges them).
- **(b) Idiom fix:** these examples use the OLD "prompt-once then re-show from after_submit"
  pattern (`compy.input.callbacks.after_submit = function() compy.input.show{...} end`). Under
  the new model the widget STAYS OPEN by default, so a bare re-show is redundant and a
  `show()` over an already-shown widget is suppressed (warns). Replace the re-show idiom with
  the new continuous-session idiom that preserves each example's observable behaviour:
  - if the example wants a FRESH empty line per submit → `after_submit = function()
    compy.input.clear() end` (clears content, stays open);
  - if it re-shows only to change the prompt → `configure{ prompt = ... }` from
    `on_text_entered`/`after_submit` (live), no re-show;
  - if the re-show was purely to "stay open" → the callback can be removed entirely (staying
    open is now the default).
  Read each example's intent (its comments say what it wants) and pick the matching shape. **If
  an example's intent is unclear, STOP and flag it in your report rather than guess.**
  Examples are not in the busted suite, so verify by (i) `luac -p <file>` / load-parse if
  available, and (ii) careful reading against the new API — note in your report that they are
  not suite-covered.

## Sub-step 2 — Vocabulary/prose sweep in src COMMENTS (complete-or-nothing)
Per the delta-design Vocabulary table, retire the old wording in `src/**/*.lua` COMMENTS (code
symbols were already renamed in U2/U3; this is prose only). Mapping:
- `singleton` → **widget** (the shared instance is an implementation fact, not the role name)
- `sink` / `terminal sink` → **widget** (the terminal consumer IS the widget)
- `tier-1`/`tier-2`/`tier-3`/`tier-4`/`tier N`/`four-tier chain` → the redesign has NO tiers:
  describe the **three consumers** (shortcuts / hooks / widget) or say "consumer"
- `framework handlers` / `framework tier` → **retired** (the tier is gone; no replacement)
- `generic callback` (old tier-3) → **hook** (`hooks[event]`)
- `proxy` (the held-key read-only view) → **"read-only pressed-keys view"**
- **`native` — DISAMBIGUATE (do NOT blind-replace all 43):** where prose names the tier-3
  *participant's role* ("the native fires", "native as tier-3"), it is now a **seeded hook**
  (`hooks[event]`). But the love-handler *capture path* keeps its names — `project_natives`,
  `keyboard_native`, the `natives` parameter — those genuinely capture the project's native
  `love.*` handlers and are correct; leave them and prose that refers to them as "the
  project's captured native love.* handlers".
- **Migration hazard (delta-design): "hook" now means ONLY the chain-injected `hooks[event]`
  tier.** The submit/cancel `before_/after_` functions are **callbacks**, never "hooks" — fix
  any comment calling them "hooks" (e.g. `run_hook` is gone; its successor is `run_callback`).
**Never touch `love.handlers`** (LÖVE's own event table) — that word stays.
This is comments only → the suite stays green; confirm with `busted tests`.

## Sub-step 3 — Dispositon the remaining "resolved" REVIEW (gate requirement)
`src/main.lua` (~line 355) still carries: *"REVIEW: why could not (or should not)
Console/Editor be rewired to use the same singleton?..."* The R4-1 inventory tagged this
**resolved-by-redesign** (rides obligations 6a/6b). The answer (per R4-U3-callback-model /
delta-design Implementation note): the reusable seam now exists (free-function `dispatch` +
`build_widget_api` factory), but multiple `UserInputController` instances remain REQUIRED —
console's `inspect`-mode REPL state must persist independently of the project's (Decision 12) —
so migration stays deliberately deferred (Decision 1). Replace the bare REVIEW with a short
dispositioned note stating that answer (2-4 lines), so no un-dispositioned "resolved" REVIEW
remains in code.

## Sub-step 4 — Update the persistent docs to match the shipped model
Mirror the ratified model (sources above). Keep each doc's existing structure/voice; update
only what the redesign changed. These are the PR-facing docs — be precise, do NOT invent
behavior not in the code/sources.
- `doc/development/internals/user_input.md`: the dispatch chain (4-tier → 3-consumer dumb
  walk); submit/cancel now widget-owned via callbacks (stays-open default, veto, shadowable);
  `is_shown()` internal flag; hooks seeding (one-shot, no resurrection); `compy.input.callbacks`
  IS the widget's table; console history via `on_limit_reached`.
- `doc/input_api.md`: the three sub-tables (`shortcuts`/`hooks`/`callbacks`) and how a project
  sets them (direct leaf-write); submit/cancel behaviour + the opt-in auto-close one-liner;
  the vocabulary (no "sink"/"tier").
- `doc/development/technical_debt/input.md`: mark RESOLVED the entries the redesign fixed
  (e.g. "`_generic_callback` re-resolves precedence per event" — gone; the widget-sink-via-
  love.state-global concern — the sink is gone / dispatch takes the widget as a parameter).
  Do not delete history; mark resolved with a one-line pointer to Phase R. Add any NEW debt
  only if the code clearly shows it (e.g. the capture-once-never-reassign coupling of
  compy.input.callbacks to the widget table).

## Sub-step 5 — Gate self-check (report all results; do NOT claim done without them)
- `busted tests` → must be **827/0/0/4**.
- Retired-symbol references gone (code): via lua-lsp `references` AND grep, confirm ZERO
  references to the deleted code symbols `framework_handlers`, `install_tier1`,
  `framework_submit`, `framework_cancel`, `shown_widget`, `run_hook`, `_generic_callback`,
  `_sink`, `_is_hidden_overlay` anywhere in `src/`.
- Retired PROSE terms: grep `src/` (excluding `love.handlers`, `project_natives`,
  `keyboard_native`, `natives`) for `singleton`, `\bsink\b`, `tier`, `framework handler`,
  `generic callback`, `\bproxy\b` — report remaining counts and justify any you intentionally
  left (e.g. a genuinely different meaning).
- Confirm no un-dispositioned REVIEW from the R4-1 inventory's "resolved" list remains in code.

## Deliverable
Write a report to
`doc/development/wip/77-new-input-api/validation/outcomes/R4-U4-sweep-docs.md`: files touched,
the example idiom-fixes chosen (per example) + any flagged-unclear, the vocab-sweep counts
before/after, the doc sections updated, and the full Sub-step 5 gate results (suite tally,
LSP+grep zero-hit proof, remaining prose-term counts with justification). Do NOT edit any
`src/` behavior or any test file. Return a 5-8 line summary + anything you flagged.
