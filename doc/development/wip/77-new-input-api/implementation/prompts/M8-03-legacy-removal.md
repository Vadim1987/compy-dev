# M8-03 — legacy removal + close-out (chunk 3 of 3, THE TERMINAL CHUNK of the sweep)

_Implementor commission (`agents/dev.md`). Milestone id `M8-03`. Final chunk of the M8 carve
(`implementation/M8-chunk-plan.md`), validated against the frozen `design/spec/M8-02-recut.md` (Gate-3
CLOSED). Deletes the legacy text-input globals + the poll-a-reftable machinery + the dead write +
`astv_input`, converts the last legacy-behaviour tests to the new reality, and syncs the surface docs.
**When this lands green with the globals gone, the WHOLE #77 sweep is COMPLETE.** All four in-repo
examples (M8-01) + balloons (M8-02) are already migrated onto `compy.input.*`, so nothing consumes these
globals anymore. Suite baseline entering this chunk: **809 / 0 / 0 / 4**._

## Read first (authority chain — higher wins)

1. `design/notes/ratified-model.md` — canonical model (binding glossary).
2. `design/spec.md` §8/§9 — the Gate-2 authority; §9 is the migration mapping (now fully applied).
3. **`design/spec/M8-02-recut.md`** — the frozen target. Your ACs: **AC-1, AC-2, AC-7, AC-10** (primary) +
   **AC-6, AC-8, AC-9** (regression). Read them verbatim (lines 90-111) + the **Files** list (113-118) +
   the **Test strategy** (120-125). The Files list scopes the code change to **`consoleController.lua`
   only** (five entry points + the M8-01 dead write) — heed it.
4. `implementation/M8-chunk-plan.md` — the carve; its **PINNED `astv_input` RULING** (§, lines 51-60) is
   binding: remove `astv_input` with the machinery, flag surprise-first. You do NOT re-decide it.
5. `implementation/outcomes/M8-01.md` + `outcomes/M8-02.md` — proof the consumers are migrated.

`design/` is **frozen** — read, never edit. Rules (auto-loaded via `CLAUDE.md`): line ≤64 chars, fn body
≤14 lines, params ≤4, nesting ≤4, KISS, **tests-first**, **report-don't-fix**, Conventional Commits,
**commit locally NEVER push**. **lua-lsp MCP is UP — use it** (`definition`/`references`/`hover`/
`diagnostics`) for the completeness-critical removal sweep; `sleep 1` after any `.lua` edit before an MCP
call; **grep as the completeness backstop** (Lua is dynamically typed — LSP refs can be thin; cross-check).

## What to remove — ALL in `src/controller/consoleController.lua` (line refs — confirm live before editing)

Inside the project-env builder (the function around L784-897):
1. **L788-793** — the `input_ref` local + `create_input_handle` closure (+ their comment L788-789).
2. **L795-830** — the `input(eval, prompt, init)` helper (+ its doc-comment L795-801). This is the poll
   surface itself (it builds the `show{ result = input_ref }` call).
3. **L832-835** — `project_env.user_input`.
4. **L837-846** — `project_env.input_code` + `project_env.input_text` (with their `@param` comments).
5. **L848-864** — `project_env.write_to_input` (with its doc-comment).
6. **L866-870** — `project_env.validated_input`.
7. **L872-876** — the `if love.debug then project_env.astv_input = function() return input(LuaEditorEval)
   end end` block (**the PINNED RULING** — the SIXTH global on the same dead machinery; remove it here,
   flag surprise-first in the ledger).
8. **L887** — `compy_namespace.text_input = input_text` (the dead write — **zero readers**, grep-confirmed:
   the only reference in the whole tree is this write site itself).

**After removal, `input`, `input_ref`, `create_input_handle` must have ZERO remaining references** (they
existed only to serve the six globals). Verify with lua-lsp `references` + grep. Everything else in that
function stays (`close_project`, `edit`, `gfx`, the `terminal`/`compy_namespace` setup **minus L887**,
`eval`/`print_eval`, the `base`/`project` clones).

## What must NOT change (the evaluators + the overlay handle STAY)

- **`evaluator.lua` — DO NOT TOUCH.** `InputEvalLua`/`ValidatedTextEval`/`InputEvalText`/`LuaEditorEval`
  are `_G` globals that **stay**: `InputEvalText` (main.lua:363), `LuaEditorEval` (editorController.lua:55),
  and `InputEvalLua`/`ValidatedTextEval` are now consumed by the **migrated examples** (tixy/guess/valid).
  Removing them would break both the console and the examples.
- **`love.state.user_input` (the overlay handle) STAYS — this IS AC-7.** It is set by the widget's
  `show()`/`hide()` (activation), NOT by the legacy reftable. `src/controller/controller.lua` (`get_user_input()`
  + the mouse/touch handlers L929-1026) and `src/types.lua:144` reference this **overlay handle**, not the
  removed globals — **do NOT touch them.** After removal, `love.state.user_input` must still reflect
  widget activation only (AC-7) — verify no legacy path drives it (there won't be one; the `result=input_ref`
  passthrough is gone with `input()`).
- **Routing/dispatch** (`projectInputController.lua`, `controller.lua`) — untouched (consumer chunk done).

## The legacy tests to convert (tests/input/input_contracts_spec.lua) — AC-1/AC-10

Two blocks pin the OLD wiring and will go RED when the globals vanish — that is expected; convert them:

1. **`describe('legacy text solicitation #legacy', …)` (~L354-377)** — its one test drives
   `env.user_input()`/`env.input_text('p')`. Its own comment says the WIRING "retires at 0.1.0-m8".
   **Replace this block with the AC-1 nil-call assertion**: activate a project, get `F.cc:get_project_env()`,
   assert **each** of `user_input`/`input_code`/`input_text`/`write_to_input`/`validated_input` **and**
   `astv_input` is `nil` (an ordinary nil field — no shim, no deprecation path). This is AC-1's core proof.
2. **`'a legacy solicitation still fills the reftable on submit'` (~L1490-1501)** — drives
   `env.user_input()`/`env.input_text()` + asserts `ref()`. Its subject (the reftable) **no longer exists**
   → **delete it.** Its surviving half (submit deactivates the widget → `love.state.user_input` nil) is
   already covered by the adjacent `'submit and cancel complete with no hooks set'` (AC-26) row — confirm
   that coverage still holds; if deleting leaves a real gap, add a minimal replacement, else just delete.

Record each disposition (converted / deleted, with why) in the ledger. Grep the spec for any OTHER live
`env.user_input`/`input_text`/… caller you might have missed (I found only these two blocks; the
`buffer_spec.lua` `'input_text(r)'` hits are **string literals** = editor buffer content, not calls —
leave them; the `keys_pressed_spec`/`input_fixture` `user_input = nil` set the **overlay handle** state
field, not the global — leave them).

## Doc sync (bounded — AC / spec Files list)

The spec Files list requires the **input docs reflect the final surface**. In scope, proportionate:
- **`doc/development/internals/user_input.md`** — the primary input-internals doc. Remove/retire the
  legacy-global API documentation (`user_input`/`input_text`/`input_code`/`validated_input`/`write_to_input`
  poll idiom); state `compy.input.*` (show/hide/configure/set_text/clear + the callback slots) as the
  **sole** project-facing input surface. This is the required doc deliverable.
- **`doc/development/internals/project_sandbox_env.md`** + **`console.md`** — if they document the legacy
  globals as part of the project env, retire those mentions the same way (usually a small mechanical edit).
- **Per-example docs** (`internals/examples/{tixy,repl,guess,valid,balloons}.md`) — these describe the now-
  migrated examples. Update them to the `compy.input.*` idiom **if the edit is small/mechanical**; if the
  sweep is larger than this terminal chunk should carry, **update user_input.md (required) and FLAG the
  example-doc drift as a noted follow-up** in the ledger rather than ballooning the chunk. Use judgment;
  don't overreach, don't silently skip the required surface doc.

## Do in this order (test-first — red before green; this is a REMOVAL, so the dance is specific)

1. **Reproduce the baseline.** `busted tests` → **809 / 0 / 0 / 4** (the 4 pending = routing-gap cells
   @101/@153/@161/@222 — leave them).
2. **RED: write the AC-1 nil-call assertions FIRST** (the converted `#legacy`→nil-call block). While the
   globals still exist, these assertions are **RED** (the fields are non-nil). This pins AC-1 before you cut.
3. **GREEN: remove the machinery + the six globals + the dead write** (the 8 edits above). Now the nil-call
   assertions go **GREEN** — and the two legacy WIRING tests go **RED** (they call now-nil globals).
4. **Resolve the legacy tests** (convert #1 already done in step 2; delete #2). Suite back to green.
5. **Doc sync** (user_input.md required; the rest per the bounded rule above).
6. **Full verification.** `sleep 1`; lua-lsp `diagnostics` on `consoleController.lua` (+ the spec); lua-lsp
   `references` on `input`/`input_ref`/`create_input_handle` → **zero**. `busted tests` → green
   (809 − deleted-legacy-rows + new-nil-call-rows / 0 / 0 / 4; the 4 pending unchanged). **Smoke-load the
   migrated examples headless** (`xvfb-run -a love src play src/examples/<name>` for tixy/repl/guess/valid
   **and** balloons) → traceback-free, confirming they still run with the globals GONE (they use
   `compy.input.*` now — this is the AC-8/AC-10 "priority examples exercised" proof; honest ceiling: no
   keystroke injection → real submit stays a human hand-play gate). Spot-check one pure-native example
   (AC-6). Grep the whole tree for any remaining **live** caller of the six globals → only
   **`src/vadexamples/`** should remain (see scope fence — it is untracked scratch, OUT OF SCOPE).
7. **Record the outcome ledger + commit** (below).

## Scope fence (overreach = STOP + record, do not silently do)

- **Code change is `consoleController.lua` ONLY** (per the spec Files list). If you find yourself needing
  to edit `evaluator.lua`, `userInputController.lua`, `projectInputController.lua`, or `controller.lua`,
  **STOP + record** — the removal is designed to be self-contained in consoleController; a forced edit
  elsewhere is a finding.
- **`src/vadexamples/` is UNTRACKED SCRATCH — DO NOT migrate it, DO NOT worry that removal "breaks" it.**
  It is a parallel experimental copy outside the shipped `src/examples/` tree (git-untracked), not a
  deliverable and not in the census/spec. Note its existence in the ledger (it will nil-call-crash if ever
  run), but leave it — migrating or deleting untracked scratch is out of scope.
- **Do NOT chase the controller-side `result`/reftable delivery path** (in `userInputController`): with
  `input()`'s `show{ result = … }` gone, that path may become dead code. It is `src/controller/*` =
  **outside** the spec's consoleController-only Files scope → **report-don't-fix** (log it as discovered
  tech debt for a future cleanup), do not remove it in this chunk.
- **Do NOT touch the migrated examples** (tixy/repl/guess/valid — M8-01; balloons — M8-02, its detached
  `.git` stays as-is: AC-9). **Do NOT touch pure-natives / maze / turtle / keyboard.**
- **Expected files:** `src/controller/consoleController.lua`, `tests/input/input_contracts_spec.lua`,
  `doc/development/internals/user_input.md` (+ optionally `project_sandbox_env.md`/`console.md`/example
  docs per the bounded doc rule), `outcomes/M8-03.md`. Anything beyond = stop + record why.

## Report-don't-fix (log, do NOT fix)

- The controller-side dead `result`/reftable path (above) — log as tech debt.
- `src/vadexamples/` legacy-global usage — note, don't touch.
- Any pre-existing wrinkle you trip over — log, don't fix, unless an AC provably needs it.
- Any surface friction vs. `internals/user_input.md`: flag surprise-first; if it forces a **design**
  choice, **STOP and report** (do not rule in-slice — Fable advisor is available for genuinely hard calls).

## Outcome ledger — write to `outcomes/M8-03.md`

Open with the mandatory **"what will surprise the architect"** (surprise-first): the **`astv_input`
removal** (the sixth global, per the pinned ruling — state it plainly); the legacy-test dispositions
(what was converted vs deleted); the **`src/vadexamples/` untracked-scratch** finding; the controller-side
dead `result` path (report-don't-fix tech debt); the doc-sync scope you took vs flagged; any conservative
call. Then: per-AC (**AC-1** each global nil — how asserted; **AC-2** dead write + poll surface gone, no
reader/writer; **AC-7** `love.state.user_input` widget-only — how verified; **AC-6** natives; **AC-8**
edge cases; **AC-9** nested `.git` untouched — you touched no example, trivially held; **AC-10** full suite
green + nil-call asserted + priority examples smoke-exercised); the removal diff summary; the
`input`/`input_ref`/`create_input_handle` zero-references proof (lua-lsp + grep); before/after busted
counts; headless smoke-load results for **all five** migrated examples (tixy/repl/guess/valid/balloons)
with the honest human-hand-play ceiling; the scope-fence confirmation (only consoleController + tests +
docs touched; evaluator.lua/controllers/examples/vadexamples untouched); tech debt discovered. **This is
the terminal chunk — end the ledger with a one-line "the #77 sweep is COMPLETE" only if the suite is green
with all six globals gone.** Commit locally (Conventional Commits, no push, this repo only). If anything
forces a genuine **design** choice, **STOP and report** — do not rule in-slice.
