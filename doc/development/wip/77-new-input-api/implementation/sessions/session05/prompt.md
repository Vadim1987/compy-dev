# session05 — prompt (M8, autonomous sweep — the terminal milestone)

_Handover from session04 (opus-sweeper PM), 2026-07-11. Read the mandate first
(`../../prompts/M5c-M8-sweep-mandate.md`; the `agents/sweep.md` boot pointer routes you through it),
then the authority chain, then this prompt. Predecessor running track:
[`../session04/track.md`](../session04/track.md) — read it in full, it is your carryover. **M7 is
COMPLETE; only M8 remains — when it lands, the whole sweep is COMPLETE.**_

## What you are

You are the **opus-sweeper PM** continuing the sweep on its **final milestone, M8**. You **orchestrate**;
you do not implement or review with your own hands. You spawn a **Sonnet implementor** and an **Opus
reviewer** per chunk, hold the seam between them, and commit after each chunk. The sub-agent mechanism +
per-chunk cycle are in the mandate and in `session04/prompt.md` — reuse them verbatim (they worked all of
M5c and M7). A practical note from session04: **a long synchronous implementor run can hit a mid-response
API error**; the changes survive on disk, and you can **`SendMessage` the same agent to resume from its
transcript** (cheaper than a cold restart) — session04 did exactly this on M7-01. Always PM-sanity-check
(`busted tests` + the scope-fence greps + read the ledger) **before** spending the Opus reviewer.

## Standing authorization — carried verbatim (human, 2026-07-10; still in force)

1. **Run autonomously through M8** without stopping for a human go/no-go between chunks. The human reviews
   **post-factum in git**.
2. **You and your sub-agents may commit locally after each chunk or corrective take** (Conventional
   Commits, **no push, this repo only**). Never commit inside a nested checkout (`src/examples/*/.git`) —
   guardrail 7.
3. **Fable-5 advisor is available for genuinely hard calls only** (see the mandate / session04 prompt for
   the invocation shape). **The M8 revalidation surfacing real drift is a listed legitimate trigger** —
   but session04 already did most of the revalidation and the one open drift (`astv_input`, below) leans
   clearly conservative, so a consult is *available*, likely not needed. Your call.
4. **The "no silent in-slice design ruling" guardrail still holds** (mandate guardrail 1). On a real spec
   gap / corpus contradiction / irreversible design decision: consult Fable; then if still a genuine
   ruling, make the **most conservative, most reversible** choice, **flag it loudly** surprise-first in the
   chunk's outcome ledger, and continue. Never quietly re-architect; never edit `design/` (frozen).

## Carryover — where the corpus stands (2026-07-11, end of session04)

- **M5c COMPLETE** (session03) · **M7 COMPLETE** (session04, both chunks landed + Opus-APPROVED, fully
  autonomous):
  - **M7-01 cursor-text** — feat `91e6e99` (`get_cursor`/`set_cursor`/`set_text` on `compy.input` in the
    `methods` table = non-assignable for free; `UserInputModel:set_text` tail `jump_end()` gated on
    `not keep_cursor`; AC-7 clamp via a new `set_cursor_pos` because `move_cursor` falls back to previous,
    not to the boundary). Review APPROVE `e7857f7`.
  - **M7-02 reconfigure-boundary** — feat `efc9b1d` (`configure`/`clear`; active `configure` feeds a
    hard-coded 5-key filter to `UserInputController:configure` so text/cursor/eval/result can't reach a
    mutation path; hidden persist single-sourced through `state` — sticky output keys + a `state.pending`
    consumed once then cleared). Review APPROVE `5974bf5`, **M7 milestone certified — all 12 ACs green.**
  - **Suite: 806 / 0 / 0 / 4** — the 4 pending are the routing-gap cells @101/@153/@161/@222 (console
    key-release, editor pointer, editor-search, touch), **outside #77's blast radius — they stay pending
    and are NOT M8's to touch.** The m7 anchor pending was retired at M7-02.
- **Authority chain (binding, in order):** `design/notes/ratified-model.md` (canonical — R1–R14, five
  rulings, binding glossary) → `design/design.md` + `design/spec.md` (Gate-2 contract) → the slice spec.
  For **M8**: `design/spec/M8-02-recut.md` (frozen; **carries a REVALIDATE-AT-COMMISSIONING flag** — see
  below). Higher authority wins; mint no architectural nouns outside the ratified glossary. `design/` is
  frozen — read, never edit.
- **INFRA — lua-lsp MCP is UP** (restored session03 `08a3d93`; session04's M7-01/M7-02 implementors +
  reviewers used it live). Use the LSP for correctness (`definition`/`references`/`hover`/`diagnostics`);
  `sleep 1` after any `.lua` edit before an MCP call (re-index); **grep as the completeness backstop** —
  note LSP `references` on **qualified** method names (`UserInputModel:set_text`) came back thin/empty in
  session04, so grep was authoritative there. Cross-check.

## M8 — the terminal slice (REVALIDATE, then carve, then commission)

`spec/M8-02-recut.md` deletes the legacy globals + the poll-a-reftable idiom and migrates the remaining
consumers. It was authored **before M5c/M7 landed** and **must be revalidated against the M5c+M7 ledgers
before carving** (its own Gate-3 flag; mandate). **session04 did most of the revalidation — findings are
in `session04/track.md` (the "M8 REVALIDATION" entry). Read that entry; it is ground truth verified live
in code.** Summary of what it established + what it left open for YOU:

**Established (carry, don't redo):**
- **Five legacy globals** in `src/controller/consoleController.lua` (~L826-895): `user_input` (returns
  the legacy reftable `input_ref`), `input_code`, `input_text`, `write_to_input`, `validated_input`. Spec's
  "five" is correct (an earlier summary said "four", dropping `input_code`).
- **`text_input` dead write** (`consoleController.lua:887`) has **no reader** (grep-clean) — removes
  cleanly (M8-01 fold-in, AC-2).
- **Nested checkouts** = `balloons` / `keyboard` / `maze`. tixy = in-repo (commits normally); **balloons =
  uncommitted working-tree patch** (guardrail 7, ledger file-by-file); keyboard pure-native (skip); maze
  already migrated.
- **controller.lua footprint ≈ nil:** `get_user_input()` returns `love.state.user_input` (the overlay
  handle, which STAYS — it IS AC-7's "activation reflects widget only"), NOT the legacy reftable. The L925
  `REVIEW: why interact with user_input here?` marker is pre-existing, not M8's.
- **The poll surface to delete** = `input_ref` + `create_input_handle()` + the `input()` helper in
  consoleController (~L790-835). **Evaluators** (validator/highlighter mechanism): `InputEvalText`,
  `InputEvalLua`, `ValidatedTextEval(filters)`, `LuaEditorEval`.

**OPEN — finish these two reads BEFORE writing `M8-chunk-plan.md`:**
1. **Read `consoleController.lua` ~L790-835 in full** — the `input()` / `create_input_handle()` /
   `input_ref` machinery — to scope the removal precisely (session04 was interrupted right here).
2. **Gather the example census** — grep `src/examples/{tixy,balloons,repl,guess,valid}/` for
   `user_input|input_text|input_code|validated_input|write_to_input|astv_input` (session04 was interrupted
   before this grep). It sizes the tixy chunk, the balloons chunk, and the repl/guess/valid
   convert-or-exclude call (AC-5).

**⚠ ONE REAL DRIFT ITEM YOU OWN — `astv_input`:** `consoleController.lua:~873`, under `if love.debug`, is
a **sixth** input global (`return input(LuaEditorEval)`) using the **same `input()`/reftable machinery**
M8 removes — it is **not in the spec's five-global census** and will **break mechanically** when the
machinery goes. Session04's leading call: **remove it with the machinery** (debug-only dev tooling, same
dead poll idiom; re-plumbing it onto `compy.input` has no release value). Conservative + reversible +
mechanically forced + debug-only → **remove-and-flag surprise-first** in the carve + ledger; Fable consult
available if you disagree. **This is a design-shaped call — do not let an implementor make it silently;
decide it in the carve and pin it in the commission.**

## Proposed M8 carve (session04 PM sketch — VALIDATE against your two open reads, then write it up)

Write it as a first-class `implementation/M8-chunk-plan.md` (like `M5c-chunk-plan.md` / `M7-chunk-plan.md`)
**before** commissioning, validated against the finished revalidation. A plausible 3-chunk shape (the spec
orders removal-then-migration, but migration must precede removal per-consumer or the examples break — so
**migrate consumers first, remove globals last**):

- **M8-01 — tixy migration** (in-repo, commits normally). `input_code` + `write_to_input` + `user_input`
  → `compy.input.show{…highlighter/validator=Lua…}` + `set_text` + `on_text_entered`. AC-3. Test-first.
- **M8-02 — balloons migration** (uncommitted nested-checkout patch, guardrail 7, ledger file-by-file).
  The continuous-session idiom: `show` once + `configure{prompt=…}` from the submit hook +
  `on_text_entered`/`after_submit` (no re-show-per-hint, no per-frame poll). AC-4. Same discipline as maze
  (M5c-05): headless smoke-load only in-container; **human hand-play is the final gate** (report, don't
  overclaim). Also decide repl/guess/valid here or as a sub-step (AC-5 convert-or-exclude — owner's call,
  recorded, no third state).
- **M8-03 — legacy removal + M8-01 fold-in + close-out.** Delete the five globals + `input_ref`/`input()`/
  `create_input_handle()` + the `text_input` dead write + **`astv_input`** (per your drift decision).
  AC-1/AC-2/AC-7; AC-6 (pure-natives still work); AC-8 (edge cases on migrated examples); AC-9 (nested
  `.git` untouched); AC-10 (full suite green, `nil`-call asserted, priority examples exercised). This is
  the terminal chunk — when it lands green with the globals gone, **the sweep is COMPLETE.**

Carve order rationale: **do NOT remove a global before its consumer is migrated** (the dev-build window
where text-input examples don't run is real — the spec accepts it but keep it minimal). Removal last means
the suite's `nil`-call assertions (AC-1) go green only in the final chunk.

## Pinned seams / debts to carry

- **Carried debt (report-don't-fix, M7 lineage):** `UserInputModel:set_text` 19-line body (>14 limit;
  model file) — `reviews/M7-01.md`. `apply_config` ~27-line body (pre-existing >14) — the M7-02 reviewer
  confirmed clean; cursor was routed through `open_fresh` to avoid growing it. **Tech-debt F-0** (submit
  deliver-then-hide ordering) traced in M7-02 and **still open** — `configure` did not resolve it; M8 does
  not touch it unless an AC forces it. F-5 was **struck** at M7-02 (do not re-open it).
- **Human hand-play gates still open (report-don't-block):** turtle input + maze show→Escape→reopen
  (M5c-05) await interactive human confirmation. balloons/tixy will add to this list — flag, don't block.
- **Guardrail 7:** `src/examples/balloons/` migrates as **uncommitted working-tree changes**, listed
  file-by-file in the outcome ledger — never `git add`/`commit` inside `src/examples/*/.git`. maze
  (M5c-05) already delivered this way and its patch is **still uncommitted awaiting upstream carry**;
  balloons joins it.

## Per-chunk cycle + sub-agent mechanism

Identical to session04 / the mandate: (1) carve if needed (M8 = write `M8-chunk-plan.md` after finishing
the revalidation) → (2) write the commission to disk `prompts/<id>-<slug>.md` (+ an `<id>-review.md` trap
note — it sharpened every review) + commit it → (3) spawn **Sonnet implementor** (`Agent`, model `sonnet`,
boot from `agents/dev.md`, resolve `prompts/<id>.md` by id, test-first, commit locally, record
`outcomes/<id>.md`) → (4) PM sanity-check → (5) spawn **Opus reviewer** (`Agent`, model `opus`, boot from
`agents/review.md`, follow `prompts/<id>-review.md`, verify-don't-trust, verdict only) → (6) act on the
verdict (APPROVE → commit review, next chunk; CORRECTIVE-TAKE → commission a targeted red-then-green fix;
ESCALATE → Fable + conservative-reversible + surprise-first) → (7) commit review artifacts. Run sub-agents
`run_in_background: false` for a serial pipeline (or accept the background/notify flow — either works; the
pipeline is strictly serial regardless). One cold run per role per chunk; `SendMessage`-resume is for
continuing a *cut-off* agent, not for reusing an implementor as its own reviewer.

## Wrap (when the sweep completes)

Keep `session05/track.md` current as you go (`[project]`/`[behavioural]`; behavioural raw). **When M8-03
lands and the full suite is green with the five legacy globals + the poll idiom + `astv_input` gone: the
sweep is COMPLETE.** Say so plainly in the final track entry, write a crisp "what remains" for the human
— the **open human hand-play gates** (turtle, maze, tixy, balloons) and the **uncommitted nested-checkout
patches** (maze + balloons) awaiting upstream carry — and, since there is no session06, **do not** write a
successor prompt; instead repoint `agents/sweep.md` to a DONE state (or leave a final note there). If you
must pause mid-M8 instead, follow the normal wrap: write `session06/prompt.md`, repoint the sweep pointer
(`sed -i -E 's#(CURRENT PROMPT:.*/)session[0-9]+(/prompt.md`)#\1session06\2#' agents/sweep.md`), commit.
