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

- [project] **CRASH RECOVERY — predecessor PM died mid-M8-01-implementor-run (new PM boot, 2026-07-11).**
  Re-entrance guardrail: on this boot `session05/track.md` was PRESENT and HEAD was `b81b116` ("open M8 —
  revalidation done, carve written, M8-01 commissioned") — so the predecessor got as far as committing the
  M8-01 commission, then spawned the Sonnet implementor, which **crashed mid-run**. Reconstructed the stop
  point from the working tree (the implementor's output survives uncommitted, per the session05 prompt's
  "changes survive on disk" note):
  - **DONE + green on disk (uncommitted):** the test-first `#m8` continuous-session tests
    (`tests/input/input_contracts_spec.lua`, 2 rows) + the **tixy** migration
    (`src/examples/tixy/main.lua`: `write_to_input`→`set_text`, `input_code`/`user_input` poll loop →
    `show{ eval=InputEvalLua, on_text_entered=submit_body }` + field-write `after_submit` re-show). Suite
    **808 / 0 / 0 / 4** (baseline 806 + the 2 new rows; the 4 pending unchanged) — verified live at boot.
  - **NOT done (the crash cut here):** repl / guess / valid migrations (AC-5); `outcomes/M8-01.md` ledger;
    the chunk commit. No `outcomes/M8-01.md` exists → confirms the implementor never reached its wrap.
  - **REAL FINDING the crashed implementor surfaced (confirmed live by this PM):** `after_submit` is in
    `INPUT_CALLBACKS` (field-write-assignable) but **NOT in `OUTPUT_KEYS`** (`consoleController.lua:403-408`,
    the only keys merged/stickied through `show{}`/`configure{}` = `on_text_entered`/`on_limit_reached`/
    `validator`/`highlighter`). So `show{ after_submit=… }` is **silently dropped** — the recipe in the
    commission + `M8-chunk-plan.md` illustrating `after_submit` inside `show{}` is WRONG on that point; the
    wired form is a direct field-write (`input.after_submit = fn`, same as the existing AC-17 test). This is
    a genuine surprise-first item (not a design gap — the callback mechanism exists, the recipe just named
    the wrong delivery for it), applies to **all four** migrations, and MUST be pinned in the M8-01 ledger.
  - **PM DECISION: keep the surviving work, spawn a FRESH Sonnet implementor to COMPLETE M8-01** (cannot
    `SendMessage`-resume the dead predecessor's sub-agent — its transcript died with the predecessor PM).
    Resume commission `prompts/M8-01-resume.md` written: verify-don't-redo tixy + tests, migrate the three
    remaining examples with the **field-write `after_submit`** form, verify the re-armed tixy still
    highlights (eval is NOT in OUTPUT_KEYS → confirm stickiness at the model layer or re-pass `eval`),
    record the ledger surprise-first, commit. Original `prompts/M8-01-in-repo-migrations.md` stays authority.

- [project] **M8-01 LANDED + APPROVED (fresh implementor completed the crash recovery, fully autonomous).**
  feat `5966bfe` — repl/guess/valid migrated onto the corrected field-write `after_submit` recipe (tixy +
  the 2 `#m8` tests verified-not-redone). guess/valid wire validation via `eval = ValidatedTextEval(filters)`
  (reuses the exact legacy `validated_input`→`ValidatedTextEval` path); repl is a bare `show{}` (default
  `InputEvalText` = legacy `input_text`). **Suite 808 / 0 / 0 / 4** (unchanged — the `#m8` pair already
  pins the recipe the three trivial migrations reuse). All four smoke-load traceback-free; real
  keystroke submit/re-prompt is a human hand-play gate (joins the open list). Scope fence held: no legacy
  global removed, `evaluator.lua`/`src/controller/*`/balloons untouched.
  - **PM sharpened the review note** (`4e9361a`) with two crash-recovery traps before spending the reviewer:
    trap 9 (`after_submit` field-write, not a `show{}` key) + trap 10 (prompt/text persistence across the
    bare re-show — a *suspected* fidelity regression I flagged: bare `show{}` drops the non-sticky
    `prompt`).
  - **Review APPROVE `c12155b`** (Opus, verify-don't-trust: re-ran suite, smoke-loaded all four, traced
    the sticky-eval + validator-wiring claims via lua-lsp). **Trap 10 DISPROVEN** — `model.custom_label`
    is written only on `cfg.prompt ~= nil` and nilled nowhere (`clear_input` leaves it intact), so `prompt`
    is **model-sticky exactly like `eval`**; guess keeps "Guess a number:" and tixy keeps its signature
    label every round. No corrective needed. Reviewer non-blocking note for M8-02/M8-03 handoff: the M8-01
    ledger traced eval-stickiness but not prompt/`custom_label`-stickiness (got the right result by omission).
  - **M8-01 CERTIFIED.** Next: **M8-02 balloons** (nested checkout; delivery = uncommitted patch per frozen
    AC-9 unless the human redirects at the gate — see chunk-plan balloons note). Then M8-03 (removal) closes
    the sweep.
