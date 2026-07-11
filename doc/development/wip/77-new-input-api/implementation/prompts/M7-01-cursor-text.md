# M7-01 — cursor + text surface + model fix (chunk 1 of the M7 carve)

_Implementor commission (`agents/dev.md`). Milestone id `M7-01`. First chunk of the M7 carve
(`implementation/M7-chunk-plan.md`), validated against the frozen `design/spec/M7-02-recut.md`
(Gate-3 CLOSED, human-approved 2026-07-07 — the implementation target). Delivers three new
`compy.input` callables — **`get_cursor` / `set_cursor` / `set_text`** — plus the **one flagged model
fix** (`UserInputModel:set_text` must honour `keep_cursor`). **Purely additive; no routing/dispatch
change.** Suite baseline entering this chunk: **779 / 0 / 0 / 5**._

## Read first (authority chain — higher wins)

1. `design/notes/ratified-model.md` — the canonical ratified model (R1–R14, binding glossary). Mint no
   architectural nouns outside its glossary.
2. `design/spec.md` §3/§6 (+ §7 boundary context) — Gate-2 contract, the **authority** the M7 spec
   derives from. §7: the mutable boundary — callable API raises loudly on assignment.
3. **`design/spec/M7-02-recut.md`** — the frozen implementation target. Your ACs are **AC-6, AC-7,
   AC-8, AC-9, AC-10** (verbatim in that file's "Acceptance criteria"). Read the **Contract** section's
   `get_cursor` / `set_cursor` / `set_text` bullets + the **Model fix** bullet + the **Mutable boundary**
   bullet word-for-word — they are self-contained and precise.
4. `doc/development/internals/user_input.md` — the runtime picture (namespace + lifecycle) of the input
   singleton and the `compy.input` surface.

`design/` is **frozen** — read, never edit. Repo-root `CLAUDE.md` auto-loads `rules.md` +
`development.md`: hard limits (line ≤64 chars, fn body ≤14 lines, params ≤4, nesting ≤4), no string-tag
dispatch, KISS, **tests-first** (red rows before implementation), **report-don't-fix** (log discovered
debt, don't fix it), Conventional Commits, **commit locally, NEVER push**. **lua-lsp MCP is RESTORED —
use it** for correctness (`definition` / `references` / `hover` / `diagnostics`); `sleep 1` after any
`.lua` edit before an MCP call (re-index); grep as the completeness backstop.

## Your ACs (verbatim from `spec/M7-02-recut.md`)

- **AC-6** `get_cursor()` returns `line, col` in 1-based source-line coordinates on an active session,
  and `nil` when hidden.
- **AC-7** `set_cursor(line, col)` moves the cursor; out-of-range values clamp to the valid range; while
  hidden it is a no-op + warning. Single-line callers pass `line = 1`.
- **AC-8** `set_text(t)` replaces the active session's content and puts the cursor at the end;
  `set_text(t, true)` replaces content and **preserves the cursor position** (clamped if the new text is
  shorter); while hidden it is a no-op + warning; the view reflects the change **without a re-show**.
- **AC-9** Every refused call above produces a **visible warning** (log), never a silent return.
- **AC-10** Assigning to any of these functions (`compy.input.set_text = …` etc.) raises a **loud
  error** — the mutable boundary is unchanged.

**D-8 (from spec):** cursor coordinates are 2D `(line, col)`, **1-based**, **source-line** (not
wrapped/apparent) — the model's own `get_cursor_pos()` already returns exactly this shape.

## The landed surface you build ON (confirmed live in code)

- **`compy.input` namespace assembly** — `src/controller/consoleController.lua`:
  - `get_compy_input()` (L~407-435) builds `state` + a `methods` table currently holding **`show` /
    `hide`**, then returns `build_input_surface(state, methods)`.
  - `build_input_surface(state, methods)` (L~371-406) is the R3 boundary: `__index` resolves
    `handlers` / `INPUT_CALLBACKS[k]` (the assignable tier-3 slots) / else `methods[k]`; `__newindex`
    **errors** unless `k ∈ INPUT_CALLBACKS`.
  - **➜ Your three new callables go in the `methods` table** (alongside `show`/`hide`). Because they
    are *not* in `INPUT_CALLBACKS`, they are read-resolved and **already raise "not assignable" on
    write — that is AC-10, for free**. Do **NOT** add them to `INPUT_CALLBACKS` (that would make them
    assignable — a scope-fence break and an AC-10 regression).
  - The methods resolve the singleton from `love.state.user_input_controller` (call it `ui`). "Shown"
    ⟺ `love.state.user_input` is truthy (the overlay CONTRACT flag; `hide()` nils it, `open_fresh` sets
    it). Use that flag (or a controller predicate — your call, but keep it single-sourced) to decide
    the hidden branch.
- **Controller internal singleton API** — `src/controller/userInputController.lua`: the
  project-facing `compy.input` methods wrap **controller methods** (never the model directly). `show`
  (L~248-278) / `hide` (L~280-284) are the pattern. Add **thin controller methods** for the three new
  operations (e.g. `UserInputController:get_cursor()` / `:set_cursor(line, col)` / `:set_text(text,
  keep_cursor)`) that delegate to the model, plus a `:update_view()` where the view must reflect a
  change (AC-8 "without a re-show"). `update_view()` already exists and is what `show`'s force-text
  subset path calls after `model:set_text` (L~272-274) — reuse that pattern.
- **Model** — `src/model/input/userInputModel.lua`:
  - `get_cursor_pos()` (L~538-541) → `self.cursor.l, self.cursor.c` — **1-based source-line
    `(line, col)`**. This IS the AC-6 / D-8 read. `get_cursor()` returns exactly these two.
  - `move_cursor(y, x, selection)` (L~509-536) **already clamps** `y` to `[1, n_lines+1]` and `x` to
    `[1, llen+1]` (out-of-range falls back to the previous coord — see the guard). This IS the AC-7
    clamp. `set_cursor(line, col)` should route through `move_cursor(line, col)` (not the raw
    `set_cursor(Cursor)` primitive, which does NOT clamp). **Verify** the fallback-to-previous behaviour
    satisfies "clamp to valid range" for your test inputs; if a caller passes e.g. `col = 999`, confirm
    it lands at the line end, not silently no-ops. If clamp-to-range and fallback-to-previous diverge
    observably for an AC-7 case, that is a real finding — **flag it**, choose the spec's "clamp to the
    valid range" wording, and test the clamped landing.
  - **`set_text(text, keep_cursor)` (L125-143) — THE MODEL FIX.** It currently calls
    `self:jump_end()` **unconditionally** at the tail, so a truthy `keep_cursor` is silently
    ineffective (the tail jump overrides the guarded `not keep_cursor` branches above it). **Fix:** gate
    the tail `jump_end()` behind `if not keep_cursor then …`. Then `set_text(t, true)` preserves
    position (clamped if the new content is shorter — `move_cursor`/`_update_cursor` clamping applies),
    and `set_text(t)` still jumps to end. **De-risk this first** (see order below).

## Do in this order (test-first — red before green)

1. **Reproduce the baseline.** `busted tests` → confirm **779 / 0 / 0 / 5**. Read the frozen spec ACs +
   `M7-chunk-plan.md` "Test seed" section. The m7-family anchor pending row is
   `tests/input/input_contracts_spec.lua` **@1681** (`pending('configure/set_text/cursor,
   force-vs-configure')`) — **leave that anchor pending in place** (M7-02 retires it at AC-12); you add
   your cursor/text rows **alongside** it (a new `describe` for the cursor/text surface, or fleshed rows
   near the existing input-contract blocks — match the file's existing structure/naming).
2. **Red: the model fix.** Write a failing model-level (or contract-level) test that pins
   `set_text(t, true)` **preserves the cursor** while `set_text(t)` jumps to end (AC-8). It fails today
   (unconditional `jump_end`). Then apply the one-line-ish model gate; row goes green. This isolates the
   single behaviour-changing edit first.
3. **Red: the three callables' contract rows.** Transcribe AC-6/7/8/9/10 as failing `it()` rows against
   `compy.input` (resolve the surface the way the existing input-contract tests do — see how
   `F`/the fixture activates a project and reaches `compy.input`). Cover, per the ACs:
   - AC-6: active → `(line, col)` 1-based; **hidden → `nil`**.
   - AC-7: move; out-of-range **clamps**; hidden → **no-op + warn**.
   - AC-8: `set_text(t)` → content replaced, cursor at **end**; `set_text(t, true)` → cursor
     **preserved** (clamped); hidden → **no-op + warn**; **view updates without re-show**.
   - AC-9: each hidden-refusal **logs a warning** (assert the log — match how existing tests assert
     `Log.warn`, e.g. the `show`-over-active warn row).
   - AC-10: `compy.input.set_text = fn` (and `get_cursor`/`set_cursor`) **raises** (assert error, like
     the existing `INPUT_CALLBACKS`-boundary rows).
4. **Green: implement.** Add the three controller methods + wire the three `methods`-table callables.
   Keep each function body ≤14 lines, ≤4 params, nesting ≤4. Reuse `apply_config`/`update_view`
   patterns; do not duplicate model logic into the controller. `sleep 1` then run lua-lsp
   `diagnostics` on the two edited `.lua` files + `references` on any method you touch to confirm no
   caller regressions. Re-run `busted tests` → all new rows green, **suite 779 + N / 0 / 0 / 5** (the 5
   pending unchanged — the four routing-gap pendings stay; the @1681 anchor stays for M7-02).
5. **Record the outcome ledger** (below) and **commit locally** (Conventional Commits, no push, this
   repo only — never inside a nested `src/examples/*/.git`).

## Scope fence (overreach = STOP + record, do not silently do)

- **Do NOT** implement `configure` or `clear` — those are **M7-02**.
- **Do NOT** strike F-5 from `technical_debt.md`, **do NOT** edit the internals doc for the boundary
  decision, **do NOT** retire the @1681 anchor pending row — all three are **M7-02 (AC-11/AC-12)**.
- **Do NOT** add any key to `INPUT_CALLBACKS` — the new callables are non-assignable methods (AC-10).
- **Do NOT** remove or alter any legacy global (`input_text` / `user_input` / `validated_input` /
  `write_to_input`) or the poll idiom — those die in **M8**.
- **Do NOT** touch routing/dispatch (projectInputController, controller.lua route wiring) — M7 is
  additive; no routing behaviour changes (AC-12 is verified in M7-02, but do not perturb it here).
- **Expected files** (anything beyond = stop + record why): `src/controller/userInputController.lua`
  (three thin methods), `src/model/input/userInputModel.lua` (the `set_text` keep_cursor gate),
  `src/controller/consoleController.lua` (three entries in the `methods` table), `tests/input/*`.

## Report-don't-fix (log in the ledger, do NOT fix)

- **`set_text` multiline-string branch** (`userInputModel.lua:126-135`): a multi-line **string** arg
  (`n_added > 1`) never reassigns `self.entered` — only `n_added == 1` and the `table` branch do.
  Pre-existing. AC-8 is whole-content replacement; a `table` of lines is the multiline path. Note it if
  your tests brush it; **do not fix** unless an AC provably needs multiline-**string** replacement (it
  does not).
- Any other latent wrinkle you trip over: log it in the ledger's "tech debt discovered" section (and
  `technical_debt.md` if it warrants a row), don't fix.

## Outcome ledger — write to `outcomes/M7-01.md`

Include: per-AC summary (AC-6/7/8/9/10 — how each was proven, which test row); the **model fix**
before/after (what `jump_end` did, what you gated, why it is behaviour-safe for existing `set_text`
callers — **enumerate them via lua-lsp `references` on `UserInputModel:set_text` and confirm none
relied on the old unconditional jump-when-keep_cursor**); the AC-7 clamp finding (did
`move_cursor` fallback-to-previous satisfy "clamp to range" for your inputs, or did you need
anything more?); commit hashes; before/after busted counts (expect `779 → 779+N / 0 / 0 / 5`); the
scope-fence confirmation (what you did NOT touch); tech debt discovered; and a **"what will surprise
the architect"** (surprise-first) section if you made any conservative-reversible call. If anything
forces a genuine **design** choice (a spec gap, a corpus contradiction, a need to diverge from the
spec Contract), **STOP and report** — do not rule in-slice.
