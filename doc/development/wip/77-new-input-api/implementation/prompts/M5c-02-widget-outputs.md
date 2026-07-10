# Implement — M5c-02: widget outputs (chunk 2 of the M5c carve)

_Commissioned by the opus-sweeper PM (`agents/sweep.md`), session02, 2026-07-09, under
[`M5c-M8-sweep-mandate.md`](M5c-M8-sweep-mandate.md). This is **chunk 2** of the M5c carve — the
widget-output surface (Scope 4), built on top of the landed chunk-1 dispatch chain. It is **not** the
whole slice: the submit/cancel path that *fires* `on_text_entered` and *gates* on the validator, the
route-connection lifecycle, and the turtle/maze migration are **later chunks** (see Boundaries).
Target executor: **Claude Sonnet**, in the M0 dev image._
_Approved by human?: **PENDING** (pre-run prompt gate — the PM presents this file before executing)._

## You are

A one-shot implementation agent in the **compy** LÖVE2D codebase (this repo, root = your cwd),
running the **dev charter** (`agents/dev.md`). You implement **exactly this chunk**, test-first,
commit locally (Conventional Commits, no push, this repo only), record the outcome ledger, then
**present a summary and wait for the human to approve** — do **not** blindly exit; he may contest and
demand fixes. Mid-chunk, if you hit a genuine **spec gap, corpus contradiction, or any in-slice
design decision, STOP and report it as an escalation** (mandate guardrail 1 — an in-slice design
ruling is a gate failure). You resolve scope by the authority chain, never by inventing.

## What this chunk delivers (scope — Scope item 4, the non-submit half; + Scope 7 allowlist)

The **four widget outputs become a live, functionally-applied surface** — settable two ways, and
the two that act **without** the submit path (`on_limit_reached`, `highlighter`) genuinely fire /
transform. After this chunk:

- All four widget outputs — `on_text_entered`, `on_limit_reached`, `validator`, `highlighter` — are
  settable **both** as a `show()` config key **and** as an assignable `compy.input.<field>` (one
  underlying slot, two ergonomics — AC-16, D-b). The mutable-boundary allowlist
  (`INPUT_CALLBACKS`, `consoleController.lua:353`, left deliberately narrow by chunk 1) is **widened**
  to admit these four fields — chunk 1's own comment (L349–352) points here.
- `on_limit_reached(direction, scope)` **fires** when the caret attempts to cross a boundary:
  `direction ∈ up/down/left/right`, `scope ∈ input/line`; single-line inputs collapse the two scopes;
  it is **observational** — its return value is ignored (AC-15). This **extends** `is_at_limit`
  (`userInputModel.lua:558`, today vertical-only `up`/`down`) to the **horizontal + line** scope (D-5).
- A `highlighter` is **functionally applied** to the live composed text — the widget's queried
  highlight reflects `highlighter(text)`, not merely that the slot was stored (AC-42 case **(a)**).

Widget outputs **never chain return values** (R12 — AC-14): a boundary condition surfaces **only**
through the output callback, never through a sink/tier return. `on_limit_reached`'s return is ignored.

### In scope for this chunk (ACs it must satisfy)

- **AC-16** — every widget output settable as a `show()` config key **and** an assignable
  `compy.input` field; one slot, two ergonomics. Extends the `INPUT_CALLBACKS` allowlist to the four
  output fields (loud-error boundary preserved for everything else — AC-33 stays intact).
- **AC-15** — `on_limit_reached(direction, scope)` fires on a boundary-cross attempt; `direction ∈
  up/down/left/right`, `scope ∈ input/line`; single-line collapses the scopes; return ignored.
  Requires the `is_at_limit` horizontal + line extension (D-5).
- **AC-42 case (a)** — a custom `highlighter` **transforms the composed text**: as the user types,
  the queried highlight (`get_highlight()` / the viewdata) reflects `highlighter(text)` — invoked on
  live text, output surfaces, not merely stored. (Case **(b)**, the *validator gate*, is **chunk 3** —
  it needs the submit path. Do not build it here.)
- **AC-14** (boundary half) — widget outputs carry the boundary condition; a widget output's return
  value has **no** chain meaning (R12). (The *submit* half of AC-14 — `on_text_entered` as the
  submit-condition surface — rides chunk 3.)

### The chunk-2 / chunk-3 seam — settable here, behaviour there (READ THIS)

`validator` and `on_text_entered` are **installed as settable slots here** (AC-16: config key +
field, allowlisted) but their **behaviour is chunk 3**:

- **`on_text_entered`** — settable/stored here; it **does not fire** in this chunk (submit delivery =
  AC-17, chunk 3). Assert it is accepted on the boundary and stored; do **not** assert it is called.
- **`validator`** — settable/stored here; it **does not gate** anything in this chunk (validator gate
  = AC-18 / AC-42(b), chunk 3). Assert settability only; a red row asserting reject-locks-the-session
  belongs to chunk 3 and must **stay pending** if you transcribe it.

This split is a **scheduling** decision (AC-16 settability vs AC-17/AC-42(b) behaviour), not a design
ruling — it is already drawn by the spec's own AC boundaries. If implementing settability forces you
to also wire firing/gating (e.g. you cannot store `on_text_entered` without a submit path referencing
it), that is a genuine seam collision — **stop and escalate**, do not quietly pull chunk-3 work in.

## Read first (authority chain — all frozen/ratified)

1. **`design/spec/M5c-dispatch-chain.md`** — the slice. Read **Scope 4** and **Scope 7**, and
   **AC-14, AC-15, AC-16, AC-42** verbatim; skim AC-17–AC-26 to see exactly where chunk 3 begins so
   you don't cross into it. Your red rows transcribe the in-scope ACs; your ledger cites them by id.
2. **`design/notes/ratified-model.md`** — canonical; on any divergence it wins. Glossary binding
   (mint no new architectural nouns). Anchors: **R12** (widget-output / sink return carries no chain
   meaning), **D-5** (`on_limit_reached` two scopes; `is_at_limit` horizontal + line), **D-b** (config
   key AND assignable field — one slot). **R3** (the mutable/immutable boundary you widen).
3. **`design/spec.md` §4 (widget outputs)** and **§7 (mutable boundary)** — the contract for AC-16 and
   the allowlist widening.
4. **`agents/rules.md` + `agents/development.md`** (auto-loaded) — hard limits (line ≤64, fn body ≤14,
   params ≤4, nesting ≤4), **no string-tag dispatch**, KISS, **tests-first**, report-don't-fix,
   Conventional Commits, no push.
5. **`notes/input-contracts.md` (doc A)** — current-behaviour contracts; cite by `§N`.
6. **The live code you extend** (chunk 1 landed the chain; you add the output surface on top):
   - `src/controller/consoleController.lua` — `build_input_surface` + the `INPUT_CALLBACKS` allowlist
     (L353) you widen; the chunk-1 comment at L349–352 names exactly the four fields to add.
   - `src/controller/userInputController.lua` — `show(config)` / `open_fresh` (L233+): the config-key
     ingestion path where the four outputs must be accepted; `is_at_limit` proxy (L69).
   - `src/model/input/userInputModel.lua` — `is_at_limit(dir)` (L558, extend to horizontal + line
     scope, D-5); the `highlighter` application already present at L385–392 (AC-42(a) proves it runs
     on live text — extend/assert, don't duplicate); the caret-move path where `on_limit_reached`
     must fire on a cross attempt.
   - `src/view/input/userInputView.lua` — `is_at_limit` (L308) and `get_highlight`/viewdata: the
     surface AC-42(a) queries.
   - `tests/input/input_contracts_spec.lua` — the contract suite you evolve. **Human `-- REVIEW:`
     markers are non-blocking design inputs (guardrail 4)** — reconcile only those whose home is the
     widget-output surface (e.g. L401 prompt-labelling is **M7**, not this chunk — leave it); the rest
     stay for their owning chunk. Reconcile-or-escalate, never silently delete.
7. **`implementation/outcomes/M5c-01-dispatch-chain.md`** — what chunk 1 landed and the AC-33
   allowlist it left **intentionally narrow** (three `on_*` only); this chunk widens it by four.

## Do — in this order

1. **Red suite first (test-first).** Under `tests/input/`, transcribe **AC-14/15/16/42(a)** into
   acceptance rows and run them **red for the right reasons** before implementing. Rows whose
   behaviour is chunk 3 (`on_text_entered` firing, validator gate, submit/cancel) stay **pending** —
   do not green them here. If you convert any landed/pending row, keep the retirement lifecycle
   (`#deprecated` → red-on-delete → `pending()`), never loosen a green row.
2. **Widen the mutable boundary (AC-16, Scope 7).** Add `on_text_entered`, `on_limit_reached`,
   `validator`, `highlighter` to the `INPUT_CALLBACKS` allowlist (or the appropriate output-field
   set) so assignment is accepted and reads resolve to the slot; everything else still raises loudly
   (AC-33 intact). Update the chunk-1 comment (L349–352) to reflect that chunk 2 landed these four.
3. **One slot, two ergonomics (AC-16, D-b).** Wire the four outputs through the `show()`/config-key
   path **and** the assignable-field path to the **same** underlying slot — a field write and a
   config key set the same thing; prefer a table-driven set-up over four near-duplicate blocks.
4. **`is_at_limit` → two scopes (AC-15, D-5).** Extend `is_at_limit` from vertical-only to
   `direction ∈ up/down/left/right` × `scope ∈ input/line`; single-line collapses the scopes. Keep
   the existing vertical callers (`editorController.lua:511-512`, view L308) working — **verify no
   regression** (LSP `references` on `is_at_limit` before you change its signature).
5. **`on_limit_reached` fires (AC-15).** On a caret-move that attempts to cross a boundary, invoke
   `on_limit_reached(direction, scope)`; its return is **ignored** (observational — R12/AC-14). Default
   is noop + debug log (mirror the AC-10/AC-26 default-callback shape chunk 1 established).
6. **`highlighter` functional application (AC-42(a)).** Assert the queried highlight reflects
   `highlighter(text)` on the live composed text (the model already applies it at L385–392 — make it
   reachable via the config-key/field surface and prove it through `get_highlight()`/viewdata, don't
   re-implement).
7. **QUALITY / `>> REVIEW` dispositions (Scope 8/9, this chunk's surface only).** Give each pinned
   remark whose home is the widget-output surface an explicit disposition (`fixed` /
   `dissolved-by-rework` / `note-only`, with remark id); remarks homed in a later chunk are
   `note-only` with a pointer. Remove any `>> REVIEW` marker in the code this chunk reshapes, each with
   a ledger line citing the resolving contract point; leave the rest.
8. **Run the full suite** (`busted tests` or `just ut_all`). This chunk's ACs green; chunk-3+ rows
   still pending; **everything else green** (no red at the chunk boundary — AC-35 discipline).
9. **Manual check (record exactly what you exercised; if you cannot run a mode, say so).** At minimum:
   set a `highlighter` via both a config key and a field and observe the queried highlight transform;
   drive the caret to a boundary and observe `on_limit_reached` fire with the right `(direction,
   scope)`. (Full 4-mode + turtle/maze hand-play are the later closeout chunk — not required here.)
10. **Commit locally** — Conventional Commits (`feat(input):`), independently revertible commits,
    pre-commit hook green, **in-repo files only**. No `src/examples/*` edits in this chunk.

## Record the outcome — `implementation/outcomes/M5c-02-widget-outputs.md`

Open with the mandatory **"what will surprise the architect"** section (guardrail 3 — deviations,
reconciliations, the allowlist widening, the `is_at_limit` signature change and its callers, anything
that was already partly present), **before** the file list. Then: commit refs · files changed ·
verification (**real** busted counts; the manual-check record) · **per-AC checklist** for every
in-scope AC (each `met` with the test name, or the stop that blocked it; chunk-3 ACs marked
deferred-to-chunk-3) · the **per-pinned-remark disposition table** · the **suite `-- REVIEW:`
reconciliation ledger** (this chunk's rows only) · the **`>> REVIEW`-marker removal ledger** ·
surfaced gaps or "none". **Every non-obvious decision bullet cites its source**
(`M5c-dispatch-chain.md §…` / `spec.md §…` / `ratified-model.md` / ruling/remark id) — **uncitable =
a judgment call = you should have stopped** (guardrail 2).

## Approval loop

Present a short summary and **stop for human review**. Revise on contest; done only when the human
explicitly approves. Mid-chunk stops (decide **with** the human, never paper over): scope ambiguity,
a spec gap, an irreversible choice, the suite won't converge, the settable-here/behaviour-in-chunk-3
seam collides, or a `-- REVIEW:` comment that names a real contradiction with the ratified model.

## Boundaries — what is NOT in this chunk

- **No submit/cancel** (Scope 3 → chunk 3): do **not** build the `before_/after_submit` +
  `before_/after_cancel` chains, the Enter/Escape framework entries, the validator **gate** (AC-18 /
  AC-42(b)), Escape-dismiss, or fire `on_text_entered` at submit. `validator`/`on_text_entered` are
  **settable** here (AC-16); their **behaviour** is chunk 3.
- **No `oneshot`/`push` removal** (Scope 3 → chunk 3): leave `oneshot` and `push('userinput')` alone.
- **No route-connection lifecycle changes** (Scope 5 → chunk 4): keep the M4 ruling-1 forwarding and
  activate/deactivate as-is.
- **No M7 surface** (`configure`/`clear`/`get_cursor`/`set_cursor`/`set_text`) — those are a later
  **milestone** (DEFERRED 0.1.0-m7 note in `consoleController.lua`); the L401 `-- REVIEW:`
  prompt-labelling item is M7, not this chunk. Do not pre-stub them.
- **No example migration** (Scope 6 examples → chunk 5): do **not** touch `src/examples/*`. Never
  commit inside a nested checkout or touch its `.git` (guardrail 7).
- **Never edit `doc/development/wip/77-new-input-api/design/`** — frozen input you read.
