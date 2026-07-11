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
- [project] **M7-01 commissioned.** `prompts/M7-01-cursor-text.md` + `prompts/M7-01-review.md`; commit
  `cbbd591`.
- [project] **M7-01 (cursor-text) — LANDED + Opus-APPROVED (autonomous).** Sonnet implementor's first run
  was **cut off by an API error mid-work** (uncommitted changes survived; suite already 782); PM **resumed
  it from its transcript** via SendMessage (cheaper than a cold restart) → it finished the contract rows +
  ledger + commit. Feat `91e6e99` (three `compy.input` callables in the `methods` table — non-assignable
  for free; `UserInputModel:set_text` tail `jump_end()` gated on `not keep_cursor`). Opus reviewer
  **APPROVE** (`reviews/M7-01.md`, commit `e7857f7`): independent busted re-run, all 8 traps clear.
  **Suite 779 → 794 / 0 / 0 / 5** (+15 rows; 5 pending unchanged, incl. the m7 anchor now @1828). PM
  sanity-check (busted + scope-fence greps) passed before the Opus spend.
  - **AC-7 clamp finding (implementor, reviewer-confirmed):** `move_cursor` falls back to the *previous*
    col on out-of-range, not to the boundary — so a new controller method `set_cursor_pos` computes the
    clamp itself (`min(col,llen+1)`, `min(line,n)`); a discriminating test proves clamp-to-boundary.
    Conservative/reversible, within the spec Contract (not a design ruling).
  - **Carried debt (report-don't-fix):** `UserInputModel:set_text` body now **19 lines** (>14 limit; was
    17 pre-M7-01, +2 from the mandated keep_cursor gate) — captured in `reviews/M7-01.md`, model-file so
    out of M7-02 scope. The `set_text` multiline-**string** branch (`self.entered` not reassigned for
    `n_added>1`) noted, not fixed (pre-existing; AC-8 is whole-content / table-of-lines replacement).
- [project] **M7-02 (reconfigure-boundary) commissioned.** `prompts/M7-02-reconfigure-boundary.md`
  (`configure`/`clear`; AC-1..5/9/10/11/12; the **AC-3/AC-4 hidden-persist subtlety** pinned — today
  `show()` persists only the 4 output keys in `state`, so configure-while-hidden needs `prompt`/`text`/
  `cursor` to also persist + apply on next show; the **F-5 strike** both table row + detail section; the
  AC-11 internals-doc line **no milestone ids in prose**; AC-12 retires the m7 anchor → pending **5→4**,
  four routing-gap pendings survive) + `prompts/M7-02-review.md` (trap note); commit `1ed2ef0`.
- [project] **M7-02 (reconfigure-boundary) — LANDED + Opus-APPROVED (autonomous). ⇒ M7 COMPLETE.**
  Sonnet implementor feat `efc9b1d` (`configure`/`clear` in the `methods` table; active `configure` feeds
  a hard-coded 5-key filter to `UserInputController:configure` so text/cursor/eval/result can't reach a
  mutation path; hidden persist single-sourced through `state` — `merge_output_keys` for the 4 sticky
  output keys + `state.pending`/`PENDING_KEYS`/`consume_pending` for prompt/text/cursor, consumed **once**
  then cleared so a later bare `show()` doesn't re-inject a stale draft). Opus reviewer **APPROVE**
  (`reviews/M7-02.md`, commit `5974bf5`): independent busted, all traps clear, **M7 milestone certified —
  all 12 ACs green across M7-01+M7-02**. **Suite 794 → 806 / 0 / 0 / 4** (m7 anchor retired 5→4; the four
  routing-gap pendings @101/153/161/222 survive; legacy globals intact for M8). PM sanity-check (busted +
  F-5 double-strike + no-milestone-ids-in-prose + zero routing/dispatch diff) passed before the Opus spend.
  - **AC-11 boundary closed:** F-5 struck in both the summary row + detail section (`~~…~~`/`**closed**`);
    `configure` semantics + force-vs-configure distinction documented in `internals/user_input.md`
    (`### compy.input namespace`), no milestone ids in prose.
  - **Carried debt (report-don't-fix):** `apply_config` ~27-line body (pre-existing, >14 limit) — the
    implementor routed cursor through `open_fresh` to avoid growing it; reviewer confirmed clean. F-0
    (submit deliver-then-hide) traced — `configure` does NOT resolve it; stays open. `set_text` 19-line
    body (M7-01 carry) still open (model file).
- [reference] **M7 DONE** (cursor/text surface + live reconfigure + boundary close). Next: **M8** — the
  terminal slice. Per the mandate: **REVALIDATE `spec/M8-02-recut.md` against the M5c+M7 ledgers before
  carving** (it was authored pre-M5c/M7). M8 deletes the legacy globals + poll idiom and migrates the
  remaining consumers **tixy + balloons** (balloons = uncommitted nested checkout, guardrail 7). `keyboard`
  is pure-native, never migrated.
