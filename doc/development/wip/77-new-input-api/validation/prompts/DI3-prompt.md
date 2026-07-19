# DI3 — mechanical execution of the DI2 (b)-merge ruling (Sonnet worker prompt of record)

You are a Sonnet worker in the compy LÖVE2D project (`/repo`, your cwd). This is a **mechanical
execution** task under an Opus orchestrator. Do exactly the three units below, nothing more. Do
**not** commit — the orchestrator reviews your diff and commits. Write a deliverable report when done.

## Standing hygiene (non-optional)
- **(a) MCP-LSP available.** The `lua-lsp` MCP server (defs/refs/diagnostics over the real AST) is a
  **deferred** tool — you must `ToolSearch` it (`select:mcp__lua-lsp__diagnostics` etc.) before use.
  This task edits only **comments** in `.lua` and prose in `.md`, so no code semantics change; still,
  after any `.lua` edit `sleep 1` then run diagnostics on that file to confirm you didn't break it.
  Use grep to confirm markdown target headings exist.
- **(b) You are the mechanical tier** — just execute; no redesign, no scope creep.
- **(c) Materialize:** write your deliverable to `doc/development/wip/77-new-input-api/validation/outcomes/DI3-execution.md`
  (what changed, file:line, old→new text, suite result per unit).
- **(d) Serial in shared `/repo` tree** — no worktrees.

## The map you execute against (READ FIRST, it is authoritative)
`doc/development/wip/77-new-input-api/validation/notes/DI2-ruling-and-resolution-index.md` — the
owner ruling (option b: merge survivors, doc A frozen in place) + the per-citation retarget table
with concrete corpus destinations (all headings pre-verified to exist). Also skim
`validation/outcomes/A1-spec-ref-sweep.md` "## Fixed" for the **style** to match: a retarget
rewords `{badspecref: doc A §N}` to cite behaviour + a named corpus section (e.g.
`internals/user_input.md "Dispatch chain"`), it does **not** invent clause numbers in the corpus.

## Hard constraints
- **Doc A (`notes/input-contracts.md`) stays UNEDITED in place.** `design/` stays frozen.
- **Only the doc-A citation family** is retargeted. Leave the ~25 non-doc-A refs ALONE (milestone
  marks `M#`/`0.1.0-m#`, `M2-human-review.md` review-doc pointers, ratified-model/scope-item process
  artifacts) — they are Phase-C evidence.
- Suite must stay **815 / 0 / 0 / 4** (`busted tests`) after every unit. If a count changes, STOP and
  report — do not "fix" it.

## Unit 1 — merge the two survivor facts
1a. **§9-3 → `doc/development/technical_debt/input.md`:** add a new tech-debt item (a few lines):
    a project that overrides `on_key_pressed` and returns truthy **silently disables**
    `on_limit_reached`, because a tier-3 truthy consume short-circuits `ProjectInputController:_dispatch`
    (`src/controller/projectInputController.lua:205`) before the tier-4 `_sink` where the limit fires
    (`userInputController.lua:495`). Match the file's existing item style/heading level. Verify the
    coupling in code before writing (LSP/read).
1b. **§9-2 → `doc/development/internals/user_input.md` "Dispatch chain" (:130):** add ONE clarifying
    line that `app_state == 'starting'` is never observed by an input path (`main.lua` sets
    `'starting'` then `'ready'` inside the same synchronous `love.load()`, before the event pump).
`busted tests` → confirm 815/0/0/4.

## Unit 2 — retarget the ~30 doc-A citations
Per the index table, in `tests/helpers/input_fixture.lua` and `tests/input/input_contracts_spec.lua`,
reword each `{badspecref: doc A §N}` (and the `design.md §4` sibling at `input_contracts_spec.lua:1657`)
to cite the mapped corpus section by behaviour + named heading. The `input_fixture.lua:9-11` "doc A"
**definition** comment: retarget to name the corpus (or drop the definition) so no live comment points
at the wip file. Keep edits comment-only; do not alter test code or assertions. Match A1's style.
`busted tests` → confirm 815/0/0/4.

## Unit 3 — refresh `tests.md` facts
`doc/development/tests.md:69` "Input Contract Suite": change **"808 successes"** → the live count,
and the four pending-row line numbers. **Derive the pending line numbers from the FINAL `busted tests`
run output** (it prints `input_contracts_spec.lua @ NNN` for each pending) AFTER Units 1-2 land, so any
comment-line shift from Unit 2 is already reflected — do not copy 118/172/185/246 blindly, read them
from the run. Confirm the count is 815.

## Deliverable
Write `validation/outcomes/DI3-execution.md`: per unit, the exact edits (file:line, old→new), the
`busted` result, and any anomaly. Do NOT commit. Report back to the orchestrator when done.
