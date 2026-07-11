# M7 — chunk carve (PM planning artifact)

_Written by the opus-sweeper PM (`agents/sweep.md`), session04, 2026-07-11, on entering the
**autonomous** M7→M8 sweep. Promotes the session04 prompt's proposed 2-chunk carve to a
first-class, reviewable artifact and **validates it against the frozen
`design/spec/M7-02-recut.md`** (Gate-3 CLOSED, human-approved 2026-07-07 — the implementation
target; `M7.md` / `M7-01-retarget.md` are frozen history, folded in). This is a **schedule, not a
design** — it makes no architectural rulings; it only orders the spec's Contract + ACs into two
independently-gated chunks. The one design question M7 raises (M7-01 re-target boundary) is **already
ratified in the spec** (Option B, KISS) and is closed *by* chunk M7-02, not re-litigated here._

## Scope of this carve — M7 ONLY

Both chunks are **inside the M7 slice** (`spec/M7-02-recut.md`). M8 (legacy removal + tixy/balloons
migration) is the next milestone, carved separately after M7 lands and **after revalidating the M8
spec against the M5c+M7 outcome ledgers** (session04 prompt / mandate). M7 is **purely additive** —
five new `compy.input` callables + one model fix + a doc line + the M7-01 boundary close. No routing
or dispatch behaviour changes (AC-12).

## The carve — 2 chunks

| Chunk | Slug | Contract surface | In-scope ACs | Status |
|-------|------|------------------|--------------|--------|
| **M7-01** | cursor-text | `get_cursor` / `set_cursor` / `set_text` on `compy.input` **+ the `UserInputModel:set_text` `keep_cursor` model fix** | AC-6, AC-7, AC-8; AC-9 + AC-10 (for these three); D-8 2D `(line,col)` 1-based source-line contract | ⬜ in progress |
| **M7-02** | reconfigure-boundary | `configure` / `clear` on `compy.input` | AC-1, AC-2, AC-3, AC-4, AC-5; AC-9 + AC-10 (for these two); **AC-11** (M7-01 boundary close: doc the decided `configure` semantics in `doc/development/internals/`, strike **F-5** from `technical_debt.md`); **AC-12** milestone close-out | ⬜ blocked by M7-01 |

## Why this order (de-risking, not a hard dependency)

The spec itself says both methods in each chunk are **independent** of the other chunk — the order is a
**de-risking choice**, not a dependency:

- **M7-01 first because it carries the one flagged risk.** The spec's only non-additive change is the
  `UserInputModel:set_text` `keep_cursor` fix ("Risk: One model fix"). Landing it first, test-first,
  isolates the single place M7 touches existing behaviour. Confirmed live in code: `set_text`
  (`src/model/input/userInputModel.lua:125-143`) calls `self:jump_end()` **unconditionally** at the tail
  even when `keep_cursor` is truthy — so today `keep_cursor` is silently ineffective. The fix = gate the
  tail `jump_end()` (and the other `not keep_cursor` guards already present) so a truthy `keep_cursor`
  preserves position. `set_text(t, true)` is the only M7 surface that depends on it (AC-8 second half).
- **M7-02 second because AC-11/AC-12 are the milestone close-out.** The boundary-close doc + F-5 strike +
  "all m7-family pending rows green / full suite green / no routing change observable" naturally land last,
  once the full surface exists. `configure`/`clear` are the live-reconfigure half and reuse the existing
  internal `apply_config` (`userInputController.lua:191-220`) — the machinery already exists; M7-02 exposes
  it as a live path + adds the accepted-but-inert `text`/`cursor` rule (AC-3).

## Test seed — the m7-family pending row

The frozen spec's AC-12 says "the contract suite's m7-family `pending` rows convert to live green." At
baseline (session04 boot, suite **779 / 0 / 0 / 5**) there is exactly **one** m7-family pending row:

- **`tests/input/input_contracts_spec.lua` @1681** — `pending('configure/set_text/cursor,
  force-vs-configure')`, inside the `describe('later forward contracts — not yet authored')` block.

The **other four** pending rows (@101 console key-release, @153 editor pointer, @161 editor-search,
@222 touch-reaches-route) are **documented routing-gap cells outside #77's blast radius** (doc A §7/§8
scope note) — they are *not* m7-family and **stay pending**. Each chunk transcribes its ACs as red
`it()` rows (fleshing out / adjacent to the @1681 anchor), red-before-green; when the full m7 surface is
green the @1681 anchor row is replaced by the live rows. M7-01 does the cursor/text rows; M7-02 does the
configure/clear rows + retires the anchor pending (AC-12).

## Seams / boundaries the commissions must pin (so neither chunk silently re-scopes the other)

- **Assignment-protection is free for the new methods (AC-10).** The `compy.input` surface
  (`consoleController.lua:build_input_surface` L371-406) refuses any write whose key is **not** in
  `INPUT_CALLBACKS`. The five new callables live in the `methods` table (like `show`/`hide`), so they are
  read-resolved and **already** raise "not assignable" on write. Neither chunk adds a new assignable
  slot; AC-10 is satisfied by placing the callables in `methods`, **not** by new guard code. A commission
  that adds a callable to `INPUT_CALLBACKS` is a scope-fence break.
- **The `methods` closures resolve the singleton from `love.state.user_input_controller`** and act only
  when it exists / the overlay is shown (`love.state.user_input`). "Hidden" = `love.state.user_input`
  falsy → each new method's hidden branch is **warn + no-op** (AC-9), except `configure` which is
  *safe-and-applies-next-show* (AC-4) and `get_cursor` which returns **nil** (AC-6) — read the spec
  Contract per-method, do not blanket "warn on hidden."
- **M7-01 owns the model `set_text` fix; M7-02 must not touch the model.** The keep_cursor change is a
  single-place model edit; M7-02 is controller + namespace + doc only.
- **M7-02 owns AC-11 (F-5 strike + boundary doc) and AC-12 (anchor-row retire + close-out).** M7-01 must
  **not** strike F-5, must **not** retire the @1681 anchor row, must **not** edit the internals doc for
  the boundary decision. M7-01 leaves the anchor pending in place and adds its cursor/text rows alongside.
- **The M7-01 re-target decision is PRE-RATIFIED (Option B).** Implementing `configure` as live-updating
  `validator` + widget-output callbacks (M7-02) is **not** an in-slice ruling — it is the spec Contract.
  Only a *concrete need to diverge* (e.g. code makes Option B impossible without re-architecture)
  stops-and-gates (mandate guardrail 1 / Fable advisor). Report, don't silently rule.
- **`force` stays as-is (out of M7 scope for change).** The existing `show(force=true)` text-only subset
  path (`userInputController.lua:265-275`) is untouched; M7 adds `configure` as the *documented* live
  path. AC references to "force-vs-configure" (the @1681 row name) are about **documenting the
  distinction**, not reworking `force`.

## Report-don't-fix wrinkles to carry into the commissions (pre-existing, non-blocking)

- **`set_text` multiline-string branch (`userInputModel.lua:126-135`):** for a multi-line `string`
  argument (`n_added > 1`) `self.entered` is **never reassigned** — only the `n_added == 1` and the
  `table` branches set it. Pre-existing; M7's `set_text(t)` is predominantly single-line/whole-content
  replacement. The implementor should **note it in the ledger** if AC-8's coverage brushes it, but
  **not fix it** unless an AC provably requires multiline-string replacement (it does not — AC-8 says
  "replaces the active session's content"; a `table` of lines is the multiline path).
- **Tech debt F-0 (M5c-05):** `submit()` deliver-then-hide ordering (`userInputController.lua:~341-342`)
  forces projects to defer an invalid-input reshow one frame — flagged in the sweep as an M7
  live-reconfigure *candidate*. If M7-02's `configure` naturally makes a reject-keeps-open flow
  expressible, **note it**; do **not** scope-creep to fix the ordering (no AC requires it).

## Milestone map (where M7 sits)

- **M5c** — COMPLETE (dispatch chain, widget outputs, submit/cancel, route lifecycle, turtle+maze
  migration). The full four-tier dispatch + widget-output + submit surface M7 configures live.
- **M7 (this carve)** — additive live-reconfigure + cursor/text surface. Unblocks M8 (the example
  migration needs the full `compy.input.*` surface).
- **M8** — legacy-global removal (`input_text` / `user_input` / `validated_input` / `write_to_input` +
  poll-a-reftable idiom) + tixy/balloons migration. **Revalidate `spec/M8-02-recut.md` against the
  M5c+M7 ledgers before carving** (it was authored pre-M5c/M7). `keyboard` is pure-native, never migrated.
