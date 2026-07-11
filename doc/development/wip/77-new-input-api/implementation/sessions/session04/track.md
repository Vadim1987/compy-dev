# session04 — track (M7 → M8, autonomous sweep)

_opus-sweeper PM running track. Carryover in full = [`../session03/track.md`](../session03/track.md).
Standing authorization (human, 2026-07-10, carried verbatim in `session04/prompt.md`): run **M7 → M8
autonomously**, committing after each chunk, human reviews post-factum in git. Per-chunk scheduling gate
lifted; the design-authority gate is NOT — a genuine spec gap / corpus contradiction / irreversible
design call still stops-by-documentation (surprise-first ledger + conservative-reversible choice),
Fable-5 advisor for genuinely hard calls only. lua-lsp MCP RESTORED — sub-agents use it for correctness,
grep as backstop._

- [project] **Boot (opus-sweeper PM, session04).** Re-entrance guardrail: session04 track was **absent**
  on boot → fresh start, no interrupted work to resume. Read mandate + session04 prompt + session03 track
  (carryover) + frozen `spec/M7-02-recut.md` end-to-end. **Baseline confirmed at boot:** HEAD `e0664d1`
  (session03 wrap), tree clean of feature changes (untracked = pre-existing nested checkouts + scratch,
  none mine), **suite 779 / 0 / 0 / 5**. Matches session03's closing count exactly.
- [project] **M7 carve written + validated** → `implementation/M7-chunk-plan.md`. Two chunks along the
  frozen spec's Contract + ACs (schedule, not design; the one design question — M7-01 re-target boundary
  — is PRE-RATIFIED Option B in the spec, closed *by* chunk M7-02, not re-litigated):
  - **M7-01 cursor-text** — `get_cursor`/`set_cursor`/`set_text` on `compy.input` + the **one flagged
    model fix** (`UserInputModel:set_text` keep_cursor). AC-6/7/8/9/10, D-8. First = de-risk the single
    behaviour-changing edit.
  - **M7-02 reconfigure-boundary** — `configure`/`clear` on `compy.input`. AC-1/2/3/4/5, AC-9/10, **AC-11**
    (boundary doc + strike F-5), **AC-12** close-out. Blocked by M7-01.
- [reference] **Key landscape facts confirmed live in code before commissioning M7-01** (so the
  commission pins real seams, not guesses):
  - `compy.input` surface built in `consoleController.lua`: `get_compy_input()` `methods` table (has
    `show`/`hide`) + `build_input_surface` R3 boundary. **New callables go in `methods` → non-assignable
    for free (AC-10); adding to `INPUT_CALLBACKS` would be a regression.**
  - Model already gives AC-6/D-8 (`get_cursor_pos` → 1-based `(l,c)`) and AC-7 clamp (`move_cursor`
    clamps y/x, falls back to previous on out-of-range).
  - **The flagged model fix is real and located:** `UserInputModel:set_text` (`userInputModel.lua:125-143`)
    calls `jump_end()` **unconditionally** at the tail → truthy `keep_cursor` silently ineffective. Fix =
    gate the tail jump on `not keep_cursor`.
  - **Only ONE m7-family pending row exists** (`input_contracts_spec.lua` @1681 anchor). The other four
    pendings (@101/@153/@161/@222) are documented routing-gap cells outside #77's blast radius — they
    **stay pending**. AC-12's "m7-family pending rows" = the @1681 anchor (retired in M7-02).
- [project] **M7-01 commissioned.** `prompts/M7-01-cursor-text.md` (self-contained: authority chain,
  landed surface, test-first order, scope fence, report-don't-fix, ledger spec) + `prompts/M7-01-review.md`
  (reviewer trap note). Committing the commission next, then spawning the Sonnet implementor.
