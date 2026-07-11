# session05 — track (M8, terminal milestone, autonomous sweep)

_opus-sweeper PM running track. Carryover in full = [`../session04/track.md`](../session04/track.md)
(read in full at boot). Standing authorization (human, 2026-07-10, carried verbatim in
`session05/prompt.md`, **re-confirmed + broadened 2026-07-11**): run **M8 autonomously**, committing after
each chunk, human reviews post-factum in git. **Broadened grant (human, 2026-07-11):** sub-agents +
PM have full autonomy for any sane command in this container; **local git commits inside detached
example sub-repos are now permitted** (no push) — see the balloons note under the carve, where this
interacts with frozen spec AC-9. Design-authority gate NOT lifted: genuine spec gap / corpus
contradiction / irreversible design call still stops-by-documentation (surprise-first ledger +
conservative-reversible choice); Fable-5 advisor for genuinely hard calls only. lua-lsp MCP UP._

- [project] **Boot (opus-sweeper PM, session05).** Re-entrance guardrail: `session05/track.md` was
  **absent** on boot → fresh start, no interrupted work. Read mandate + session05 prompt + session04
  track (carryover) + frozen `spec/M8-02-recut.md` end-to-end. **Baseline confirmed at boot:** HEAD
  `60d3c2a` (session04 wrap), tree clean of feature changes (only untracked scratch/nested-checkouts +
  the pre-existing `docker/compose.yml` mod, none mine), **suite 806 / 0 / 0 / 4** — matches session04's
  closing count exactly.
- [project] **M8 REVALIDATION — COMPLETE (the two open reads + census + astv_input decision).** Finished
  session04's carryover reads; all verified live in code. Findings (ground truth for the carve):
  1. **Machinery to remove (OPEN READ #1 done)** — `consoleController.lua` L788-897: `input_ref` (L790),
     `create_input_handle()` (L791-793), the `input()` helper (L795-830), and the five project_env
     entries `user_input`/`input_code`/`input_text`/`write_to_input`/`validated_input` (L832-870), plus
     the `compy_namespace.text_input = input_text` dead write (L887, grep-clean no reader → M8-01 fold-in).
  2. **Example census (OPEN READ #2 done)** — consumers of the six globals:
     - **tixy** (in-repo): `write_to_input` (L39), `user_input` (L171), `input_code` (L176).
     - **balloons** (nested checkout, `terminal.lua`): `input_text` (L16), `user_input` (L20).
     - **repl** (in-repo): `user_input` (L1), `input_text` (L5).
     - **guess** (in-repo): `user_input` (L2), `validated_input` (L52).
     - **valid** (in-repo): `user_input` (L1), `validated_input` (L77).
     - **maze**: only reads `love.state.user_input` (the overlay handle, STAYS) — already migrated, NOT a
       consumer. keyboard: pure-native, none. Confirms carryover.
  3. **`astv_input` DISPOSITION — DECIDED: remove with the machinery.** `consoleController.lua:873`, under
     `if love.debug`, is the SIXTH input global (`return input(LuaEditorEval)`) on the same `input()`/
     reftable machinery — **not in the spec's five-global census**, breaks mechanically when the machinery
     goes. Census confirms **zero example consumers** (grep-clean). Debug-only dev tooling, dead poll idiom,
     no release value in re-plumbing → conservative + reversible + mechanically-forced. **Remove-and-flag
     surprise-first** in the M8-03 ledger. Pinned in the carve; the implementor does not decide it. (Fable
     consult available but this leans clearly conservative — declined.)
  4. **Evaluators STAY, are NOT orphaned.** `InputEvalText`/`InputEvalLua`/`ValidatedTextEval`/
     `LuaEditorEval` are `_G` globals in `evaluator.lua`. After removal: `InputEvalText` still used
     (`main.lua:363`), `LuaEditorEval` still used (`editorController.lua:55`), and `InputEvalLua` +
     `ValidatedTextEval(filters)` become referenced by the **migrated examples** (tixy / guess+valid). None
     orphaned → M8 does NOT touch `evaluator.lua`. Reachability from the project sandbox is plausible
     (`pre_env = table.clone(getfenv())` snapshots `_G`); implementor verifies test-first.
  5. **Submit lifecycle established (governs every migration).** Enter → `before_submit` → `ui:submit()`
     = `deliver()` (fires `on_text_entered(text)` **while active**) then `hide()` → `after_submit(text)`
     (**after** hide). **Continuous-session idiom** (replaces the poll-re-arm loop): consume in
     `on_text_entered`; **re-`show{}` in `after_submit`** (a `show()` inside `on_text_entered` warns —
     still active; sticky widget-outputs mean a bare re-show re-arms). This is AC-4's sanctioned pattern
     and applies to tixy/repl/guess/valid too (all use the same `if r:is_empty() then <show> else <consume>`
     poll loop). F-0 (deliver-then-hide) stays open; M8 does not touch it (no AC forces it).
  6. **tixy Lua highlighting** → migrate via `eval = InputEvalLua` through `show{}` (`show`'s cfg passes
     wholesale to `apply_config`, which reads `cfg.eval`). Reconstructing it via `highlighter=` on the
     plain default eval is NOT equivalent. Flag surprise-first (uses the `eval` mechanism key, sanctioned
     by the spec's de-bound-helper-names note, not the documented highlighter/validator keys). Implementor
     verifies the highlighter renders; reviewer checks.
